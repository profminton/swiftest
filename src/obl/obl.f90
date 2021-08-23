submodule (swiftest_classes) s_obl
   use swiftest
contains
   module subroutine obl_acc_body(self, system)
      !! author: David A. Minton
      !!
      !! Compute the barycentric accelerations of bodies due to the oblateness of the central body
      !!      Returned values do not include monopole term or terms higher than J4
      !!
      !! Adapted from David E. Kaufmann's Swifter routine: obl_acc.f90 and obl_acc_tp.f90
      !! Adapted from Hal Levison's Swift routine obl_acc.f and obl_acc_tp.f
      implicit none
      ! Arguments
      class(swiftest_body),         intent(inout) :: self   !! Swiftest body object
      class(swiftest_nbody_system), intent(inout) :: system !! Swiftest nbody system object
      ! Internals
      integer(I4B) :: i
      real(DP)     :: r2, irh, rinv2, t0, t1, t2, t3, fac1, fac2

      if (self%nbody == 0) return

      associate(n => self%nbody, cb => system%cb)
         self%aobl(:,:) = 0.0_DP
         do concurrent(i = 1:n, self%lmask(i))
            r2 = dot_product(self%xh(:, i), self%xh(:, i))
            irh = 1.0_DP / sqrt(r2)
            rinv2 = irh**2
            t0 = -cb%Gmass * rinv2 * rinv2 * irh
            t1 = 1.5_DP * cb%j2rp2
            t2 = self%xh(3, i) * self%xh(3, i) * rinv2
            t3 = 1.875_DP * cb%j4rp4 * rinv2
            fac1 = t0 * (t1 - t3 - (5 * t1 - (14.0_DP - 21.0_DP * t2) * t3) * t2)
            fac2 = 2 * t0 * (t1 - (2.0_DP - (14.0_DP * t2 / 3.0_DP)) * t3)
            self%aobl(:, i) = fac1 * self%xh(:, i)
            self%aobl(3, i) = fac2 * self%xh(3, i) + self%aobl(3, i)
         end do
      end associate
      return

   end subroutine obl_acc_body


   module subroutine obl_acc_pl(self, system)
      !! author: David A. Minton
      !!
      !! Compute the barycentric accelerations of massive bodies due to the oblateness of the central body
      !!
      !! Adapted from David E. Kaufmann's Swifter routine: obl_acc.f90 and obl_acc_tp.f90
      !! Adapted from Hal Levison's Swift routine obl_acc.f and obl_acc_tp.f
      implicit none
      ! Arguments
      class(swiftest_pl),           intent(inout) :: self   !! Swiftest massive body object
      class(swiftest_nbody_system), intent(inout) :: system !! Swiftest nbody system object
      ! Internals
      integer(I4B) :: i

      if (self%nbody == 0) return

      associate(pl => self, npl => self%nbody, cb => system%cb)
         call obl_acc_body(pl, system)
         do i = 1, NDIM
            cb%aobl(i) = -sum(pl%Gmass(1:npl) * pl%aobl(i, 1:npl), pl%lmask(1:npl)) / cb%Gmass
         end do

         do concurrent(i = 1:npl, pl%lmask(i))
            pl%ah(:, i) = pl%ah(:, i) + pl%aobl(:, i) - cb%aobl(:)
         end do
      end associate

      return

   end subroutine obl_acc_pl


   module subroutine obl_acc_tp(self, system)
      !! author: David A. Minton
      !!
      !! Compute the barycentric accelerations of massive bodies due to the oblateness of the central body
      !!
      !! Adapted from David E. Kaufmann's Swifter routine: obl_acc.f90 and obl_acc_tp.f90
      !! Adapted from Hal Levison's Swift routine obl_acc.f and obl_acc_tp.f
      implicit none
      ! Arguments
      class(swiftest_tp),           intent(inout) :: self   !! Swiftest test particle object
      class(swiftest_nbody_system), intent(inout) :: system !! Swiftest nbody system object
      ! Internals
      real(DP), dimension(NDIM)                   :: aoblcb
      integer(I4B) :: i

      if (self%nbody == 0) return

      associate(tp => self, ntp => self%nbody, cb => system%cb)
         call obl_acc_body(tp, system)
         if (system%lbeg) then
            aoblcb = cb%aoblbeg
         else
            aoblcb = cb%aoblend
         end if

         do concurrent(i = 1:ntp, tp%lmask(i))
            tp%ah(:, i) = tp%ah(:, i) + tp%aobl(:, i) - aoblcb(:)
         end do

      end associate
      return

   end subroutine obl_acc_tp

   module subroutine obl_pot(npl, Mcb, Mpl, j2rp2, j4rp4, xh, irh, oblpot)
      !! author: David A. Minton
      !!
      !! Compute the contribution to the total gravitational potential due solely to the oblateness of the central body
      !!    Returned value does not include monopole term or terms higher than J4
      !!
      !!    Reference: MacMillan, W. D. 1958. The Theory of the Potential, (Dover Publications), 363.
      !!
      !! Adapted from David E. Kaufmann's Swifter routine: obl_pot.f90 
      !! Adapted from Hal Levison's Swift routine obl_pot.f 
      implicit none
      ! Arguments
      integer(I4B), intent(in) :: npl
      real(DP), intent(in) :: Mcb
      real(DP), dimension(:), intent(in) :: Mpl
      real(DP), intent(in) :: j2rp2, j4rp4
      real(DP), dimension(:), intent(in)         :: irh
      real(DP), dimension(:, :), intent(in)      :: xh
      real(DP), intent(out)                      :: oblpot
         
      ! Internals
      integer(I4B)              :: i
      real(DP)                  :: rinv2, t0, t1, t2, t3, p2, p4, mu
         
      oblpot = 0.0_DP
      mu = Mcb
      do i = 1, npl
         rinv2 = irh(i)**2
         t0 = mu * Mpl(i) * rinv2 * irh(i)
         t1 = j2rp2
         t2 = xh(3, i) * xh(3, i) * rinv2
         t3 = j4rp4 * rinv2
         p2 = 0.5_DP * (3 * t2 - 1.0_DP)
         p4 = 0.125_DP * ((35 * t2 - 30.0_DP) * t2 + 3.0_DP)
         oblpot = oblpot + t0 * (t1 * p2 + t3 * p4)
      end do
         
      return
   end subroutine obl_pot


end submodule s_obl