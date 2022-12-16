!! Copyright 2022 - David Minton, Carlisle Wishard, Jennifer Pouplin, Jake Elliott, & Dana Singh
!! This file is part of Swiftest.
!! Swiftest is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License 
!! as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
!! Swiftest is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty 
!! of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
!! You should have received a copy of the GNU General Public License along with Swiftest. 
!! If not, see: https://www.gnu.org/licenses. 

submodule(fraggle_classes) s_fraggle_set
   use swiftest
contains

   module subroutine fraggle_set_budgets_fragments(self)
      !! author: David A. Minton
      !!
      !! Sets the energy and momentum budgets of the fragments based on the collider values and the before/after values of energy and momentum
      implicit none
      ! Arguments
      class(fraggle_fragments), intent(inout) :: self      !! Fraggle fragment system object
      ! Internals
      real(DP) :: dEtot
      real(DP), dimension(NDIM) :: dL

      associate(fragments => self)

         dEtot = fragments%Etot_after - fragments%Etot_before 
         dL(:) = fragments%Ltot_after(:) - fragments%Ltot_before(:)

         fragments%L_budget(:) = -dL(:)
         fragments%ke_budget = -(dEtot - 0.5_DP * fragments%mtot * dot_product(fragments%vbcom(:), fragments%vbcom(:))) - fragments%Qloss 

      end associate
      return
   end subroutine fraggle_set_budgets_fragments


   module subroutine fraggle_set_mass_dist_fragments(self, impactors, param)
      !! author: David A. Minton
      !!
      !! Sets the mass of fragments based on the mass distribution returned by the regime calculation.
      !! This subroutine must be run after the the setup routine has been run on the fragments
      !!
      implicit none
      ! Arguments
      class(fraggle_fragments),     intent(inout) :: self      !! Fraggle fragment system object
      class(collision_impactors),     intent(inout) :: impactors !! Fraggle collider system object
      class(swiftest_parameters),   intent(in)    :: param     !! Current Swiftest run configuration parameters
      ! Internals
      integer(I4B)              :: i, jproj, jtarg, nfrag, istart
      real(DP), dimension(2)    :: volume
      real(DP), dimension(NDIM) :: Ip_avg
      real(DP) :: mfrag, mremaining, min_mfrag
      real(DP), parameter :: BETA = 2.85_DP
      integer(I4B), parameter :: NFRAGMAX = 100  !! Maximum number of fragments that can be generated
      integer(I4B), parameter :: NFRAGMIN = 7 !! Minimum number of fragments that can be generated (set by the fraggle_generate algorithm for constraining momentum and energy)
      integer(I4B), parameter :: NFRAG_SIZE_MULTIPLIER = 3 !! Log-space scale factor that scales the number of fragments by the collisional system mass
      integer(I4B), parameter :: iMlr = 1
      integer(I4B), parameter :: iMslr = 2
      integer(I4B), parameter :: iMrem = 3
     
      associate(fragments => self)
         ! Get mass weighted mean of Ip and density
         volume(1:2) = 4._DP / 3._DP * PI * impactors%radius(1:2)**3
         Ip_avg(:) = (impactors%mass(1) * impactors%Ip(:,1) + impactors%mass(2) * impactors%Ip(:,2)) / fragments%mtot
         if (impactors%mass(1) > impactors%mass(2)) then
            jtarg = 1
            jproj = 2
         else
            jtarg = 2
            jproj = 1
         end if
  
         select case(fragments%regime)
         case(COLLRESOLVE_REGIME_DISRUPTION, COLLRESOLVE_REGIME_SUPERCATASTROPHIC, COLLRESOLVE_REGIME_HIT_AND_RUN)
            ! The first two bins of the mass_dist are the largest and second-largest fragments that came out of encounter_regime.
            ! The remainder from the third bin will be distributed among nfrag-2 bodies. The following code will determine nfrag based on
            ! the limits bracketed above and the model size distribution of fragments.
            ! Check to see if our size distribution would give us a smaller number of fragments than the maximum number

            select type(param)
            class is (symba_parameters)
               min_mfrag = (param%min_GMfrag / param%GU) 
               ! The number of fragments we generate is bracked by the minimum required by fraggle_generate (7) and the 
               ! maximum set by the NFRAG_SIZE_MULTIPLIER which limits the total number of fragments to prevent the nbody
               ! code from getting an overwhelmingly large number of fragments
               nfrag = ceiling(NFRAG_SIZE_MULTIPLIER  * log(fragments%mtot / min_mfrag))
               nfrag = max(min(nfrag, NFRAGMAX), NFRAGMIN)
            class default
               min_mfrag = 0.0_DP
               nfrag = NFRAGMAX
            end select

            i = iMrem
            mremaining = fragments%mass_dist(iMrem)
            do while (i <= nfrag)
               mfrag = (1 + i - iMslr)**(-3._DP / BETA) * fragments%mass_dist(iMslr)
               if (mremaining - mfrag < 0.0_DP) exit
               mremaining = mremaining - mfrag
               i = i + 1
            end do
            if (i < nfrag) nfrag = max(i, NFRAGMIN)  ! The sfd would actually give us fewer fragments than our maximum
    
            call fragments%setup(nfrag, param)
         case (COLLRESOLVE_REGIME_MERGE, COLLRESOLVE_REGIME_GRAZE_AND_MERGE) 
            call fragments%setup(1, param)
            fragments%mass(1) = fragments%mass_dist(1)
            fragments%radius(1) = impactors%radius(jtarg)
            fragments%density(1) = fragments%mass_dist(1) / volume(jtarg)
            if (param%lrotation) fragments%Ip(:, 1) = impactors%Ip(:,1)
            return
         case default
            write(*,*) "fraggle_set_mass_dist_fragments error: Unrecognized regime code",fragments%regime
         end select

         ! Make the first two bins the same as the Mlr and Mslr values that came from encounter_regime
         fragments%mass(1) = fragments%mass_dist(iMlr) 
         fragments%mass(2) = fragments%mass_dist(iMslr) 

         ! Distribute the remaining mass the 3:nfrag bodies following the model SFD given by slope BETA 
         mremaining = fragments%mass_dist(iMrem)
         do i = iMrem, nfrag
            mfrag = (1 + i - iMslr)**(-3._DP / BETA) * fragments%mass_dist(iMslr)
            fragments%mass(i) = mfrag
            mremaining = mremaining - mfrag
         end do

         ! If there is any residual mass (either positive or negative) we will distribute remaining mass proportionally among the the fragments
         if (mremaining < 0.0_DP) then ! If the remainder is negative, this means that that the number of fragments required by the SFD is smaller than our lower limit set by fraggle_generate. 
            istart = iMrem ! We will reduce the mass of the 3:nfrag bodies to prevent the second-largest fragment from going smaller
         else ! If the remainder is postiive, this means that the number of fragments required by the SFD is larger than our upper limit set by computational expediency. 
            istart = iMslr ! We will increase the mass of the 2:nfrag bodies to compensate, which ensures that the second largest fragment remains the second largest
         end if
         mfrag = 1._DP + mremaining / sum(fragments%mass(istart:nfrag))
         fragments%mass(istart:nfrag) = fragments%mass(istart:nfrag) * mfrag

         ! There may still be some small residual due to round-off error. If so, simply add it to the last bin of the mass distribution.
         mremaining = fragments%mtot - sum(fragments%mass(1:nfrag))
         fragments%mass(nfrag) = fragments%mass(nfrag) + mremaining

         ! Compute physical properties of the new fragments
         select case(fragments%regime)
         case(COLLRESOLVE_REGIME_HIT_AND_RUN)  ! The hit and run case always preserves the largest body intact, so there is no need to recompute the physical properties of the first fragment
            fragments%radius(1) = impactors%radius(jtarg)
            fragments%density(1) = fragments%mass_dist(iMlr) / volume(jtarg)
            fragments%Ip(:, 1) = impactors%Ip(:,1)
            istart = 2
         case default
            istart = 1
         end select
         fragments%density(istart:nfrag) = fragments%mtot / sum(volume(:))
         fragments%radius(istart:nfrag) = (3 * fragments%mass(istart:nfrag) / (4 * PI * fragments%density(istart:nfrag)))**(1.0_DP / 3.0_DP)
         do i = istart, nfrag
            fragments%Ip(:, i) = Ip_avg(:)
         end do

      end associate

      return
   end subroutine fraggle_set_mass_dist_fragments


   module subroutine encounter_set_coordinate_system(self, impactors)
      !! author: David A. Minton
      !!
      !! Defines the collisional coordinate system, including the unit vectors of both the system and individual fragments.
      implicit none
      ! Arguments
      class(fraggle_fragments), intent(inout) :: self      !! Fraggle fragment system object
      class(collision_impactors), intent(inout) :: impactors !! Fraggle collider system object
      ! Internals
      integer(I4B) :: i
      real(DP), dimension(NDIM) ::  delta_r, delta_v, Ltot
      real(DP)   ::  L_mag
      real(DP), dimension(NDIM, self%nbody) :: L_sigma

      associate(fragments => self, nfrag => self%nbody)
         delta_v(:) = impactors%vb(:, 2) - impactors%vb(:, 1)
         delta_r(:) = impactors%rb(:, 2) - impactors%rb(:, 1)
   
         ! We will initialize fragments on a plane defined by the pre-impact system, with the z-axis aligned with the angular momentum vector
         ! and the y-axis aligned with the pre-impact distance vector.

         ! y-axis is the separation distance
         fragments%y_coll_unit(:) = .unit.delta_r(:) 
         Ltot = impactors%L_orbit(:,1) + impactors%L_orbit(:,2) + impactors%L_spin(:,1) + impactors%L_spin(:,2)

         L_mag = .mag.Ltot(:)
         if (L_mag > sqrt(tiny(L_mag))) then
            fragments%z_coll_unit(:) = .unit.Ltot(:) 
         else ! Not enough angular momentum to determine a z-axis direction. We'll just pick a random direction
            call random_number(fragments%z_coll_unit(:))
            fragments%z_coll_unit(:) = .unit.fragments%z_coll_unit(:) 
         end if

         ! The cross product of the y- by z-axis will give us the x-axis
         fragments%x_coll_unit(:) = fragments%y_coll_unit(:) .cross. fragments%z_coll_unit(:)

         fragments%v_coll_unit(:) = .unit.delta_v(:)

         if (.not.any(fragments%r_coll(:,:) > 0.0_DP)) return
         fragments%rmag(:) = .mag. fragments%r_coll(:,:)
  
         ! Randomize the tangential velocity direction. 
         ! This helps to ensure that the tangential velocity doesn't completely line up with the angular momentum vector, otherwise we can get an ill-conditioned system
         call random_number(L_sigma(:,:)) 
         do concurrent(i = 1:nfrag, fragments%rmag(i) > 0.0_DP)
            fragments%v_n_unit(:, i) = fragments%z_coll_unit(:) + 2e-1_DP * (L_sigma(:,i) - 0.5_DP)
         end do

         ! Define the radial, normal, and tangential unit vectors for each individual fragment
         fragments%v_r_unit(:,:) = .unit. fragments%r_coll(:,:) 
         fragments%v_n_unit(:,:) = .unit. fragments%v_n_unit(:,:) 
         fragments%v_t_unit(:,:) = .unit. (fragments%v_n_unit(:,:) .cross. fragments%v_r_unit(:,:))

      end associate

      return
   end subroutine encounter_set_coordinate_system


   module subroutine fraggle_set_natural_scale_factors(self, impactors)
      !! author: David A. Minton
      !!
      !! Scales dimenional quantities to ~O(1) with respect to the collisional system. 
      !! This scaling makes it easier for the non-linear minimization to converge on a solution
      implicit none
      ! Arguments
      class(fraggle_fragments), intent(inout) :: self      !! Fraggle fragment system object
      class(collision_impactors), intent(inout) :: impactors !! Fraggle collider system object
      ! Internals
      integer(I4B) :: i

      associate(fragments => self)
         ! Set scale factors
         fragments%Escale = 0.5_DP * (impactors%mass(1) * dot_product(impactors%vb(:,1), impactors%vb(:,1)) &
                               + impactors%mass(2)  * dot_product(impactors%vb(:,2), impactors%vb(:,2)))
         fragments%dscale = sum(impactors%radius(:))
         fragments%mscale = fragments%mtot 
         fragments%vscale = sqrt(fragments%Escale / fragments%mscale) 
         fragments%tscale = fragments%dscale / fragments%vscale 
         fragments%Lscale = fragments%mscale * fragments%dscale * fragments%vscale

         ! Scale all dimensioned quantities of impactors and fragments
         fragments%rbcom(:) = fragments%rbcom(:) / fragments%dscale
         fragments%vbcom(:) = fragments%vbcom(:) / fragments%vscale
         fragments%rbimp(:) = fragments%rbimp(:) / fragments%dscale
         impactors%rb(:,:) = impactors%rb(:,:) / fragments%dscale
         impactors%vb(:,:) = impactors%vb(:,:) / fragments%vscale
         impactors%mass(:) = impactors%mass(:) / fragments%mscale
         impactors%radius(:) = impactors%radius(:) / fragments%dscale
         impactors%L_spin(:,:) = impactors%L_spin(:,:) / fragments%Lscale
         impactors%L_orbit(:,:) = impactors%L_orbit(:,:) / fragments%Lscale

         do i = 1, 2
            impactors%rot(:,i) = impactors%L_spin(:,i) / (impactors%mass(i) * impactors%radius(i)**2 * impactors%Ip(3, i))
         end do

         fragments%mtot = fragments%mtot / fragments%mscale
         fragments%mass = fragments%mass / fragments%mscale
         fragments%radius = fragments%radius / fragments%dscale
         fragments%Qloss = fragments%Qloss / fragments%Escale
      end associate

      return
   end subroutine fraggle_set_natural_scale_factors


   module subroutine fraggle_set_original_scale_factors(self, impactors)
      !! author: David A. Minton
      !!
      !! Restores dimenional quantities back to the system units
      use, intrinsic :: ieee_exceptions
      implicit none
      ! Arguments
      class(fraggle_fragments), intent(inout) :: self      !! Fraggle fragment system object
      class(collision_impactors), intent(inout) :: impactors !! Fraggle collider system object
      ! Internals
      integer(I4B) :: i
      logical, dimension(size(IEEE_ALL))      :: fpe_halting_modes

      call ieee_get_halting_mode(IEEE_ALL,fpe_halting_modes)  ! Save the current halting modes so we can turn them off temporarily
      call ieee_set_halting_mode(IEEE_ALL,.false.)

      associate(fragments => self)

         ! Restore scale factors
         fragments%rbcom(:) = fragments%rbcom(:) * fragments%dscale
         fragments%vbcom(:) = fragments%vbcom(:) * fragments%vscale
         fragments%rbimp(:) = fragments%rbimp(:) * fragments%dscale
   
         impactors%mass = impactors%mass * fragments%mscale
         impactors%radius = impactors%radius * fragments%dscale
         impactors%rb = impactors%rb * fragments%dscale
         impactors%vb = impactors%vb * fragments%vscale
         impactors%L_spin = impactors%L_spin * fragments%Lscale
         do i = 1, 2
            impactors%rot(:,i) = impactors%L_spin(:,i) * (impactors%mass(i) * impactors%radius(i)**2 * impactors%Ip(3, i))
         end do
   
         fragments%mtot = fragments%mtot * fragments%mscale
         fragments%mass = fragments%mass * fragments%mscale
         fragments%radius = fragments%radius * fragments%dscale
         fragments%rot = fragments%rot / fragments%tscale
         fragments%r_coll = fragments%r_coll * fragments%dscale
         fragments%v_coll = fragments%v_coll * fragments%vscale
   
         do i = 1, fragments%nbody
            fragments%rb(:, i) = fragments%r_coll(:, i) + fragments%rbcom(:)
            fragments%vb(:, i) = fragments%v_coll(:, i) + fragments%vbcom(:)
         end do

         fragments%Qloss = fragments%Qloss * fragments%Escale

         fragments%Lorbit_before(:) = fragments%Lorbit_before * fragments%Lscale
         fragments%Lspin_before(:) = fragments%Lspin_before * fragments%Lscale
         fragments%Ltot_before(:) = fragments%Ltot_before * fragments%Lscale
         fragments%ke_orbit_before = fragments%ke_orbit_before * fragments%Escale
         fragments%ke_spin_before = fragments%ke_spin_before * fragments%Escale
         fragments%pe_before = fragments%pe_before * fragments%Escale
         fragments%Etot_before = fragments%Etot_before * fragments%Escale
   
         fragments%Lorbit_after(:) = fragments%Lorbit_after * fragments%Lscale
         fragments%Lspin_after(:) = fragments%Lspin_after * fragments%Lscale
         fragments%Ltot_after(:) = fragments%Ltot_after * fragments%Lscale
         fragments%ke_orbit_after = fragments%ke_orbit_after * fragments%Escale
         fragments%ke_spin_after = fragments%ke_spin_after * fragments%Escale
         fragments%pe_after = fragments%pe_after * fragments%Escale
         fragments%Etot_after = fragments%Etot_after * fragments%Escale
   
         fragments%mscale = 1.0_DP
         fragments%dscale = 1.0_DP
         fragments%vscale = 1.0_DP
         fragments%tscale = 1.0_DP
         fragments%Lscale = 1.0_DP
         fragments%Escale = 1.0_DP
      end associate
      call ieee_set_halting_mode(IEEE_ALL,fpe_halting_modes)
   
      return
   end subroutine fraggle_set_original_scale_factors


end submodule s_fraggle_set