submodule (symba_classes) s_symba_fragmentation
   use swiftest

   integer(I4B), parameter :: NFRAG_DISRUPT = 12
   integer(I4B), parameter :: NFRAG_SUPERCAT = 20
contains

   module function symba_fragmentation_casedisruption(system, param, family, x, v, mass, radius, L_spin, Ip, mass_res, Qloss)  result(status)
      !! author: Jennifer L.L. Pouplin, Carlisle A. Wishard, and David A. Minton
      !!
      !! Create the fragments resulting from a non-catastrophic disruption collision
      !! 
      implicit none
      ! Arguments
      class(symba_nbody_system),       intent(inout) :: system           !! SyMBA nbody system object
      class(symba_parameters),         intent(in)    :: param            !! Current run configuration parameters with SyMBA additions
      integer(I4B),    dimension(:),   intent(in)    :: family           !! List of indices of all bodies inovlved in the collision
      real(DP),        dimension(:,:), intent(inout) :: x, v, L_spin, Ip !! Input values that represent a 2-body equivalent of a possibly 2+ body collision
      real(DP),        dimension(:),   intent(inout) :: mass, radius     !! Input values that represent a 2-body equivalent of a possibly 2+ body collision
      real(DP),        dimension(:),   intent(inout) :: mass_res         !! The distribution of fragment mass obtained by the regime calculation 
      real(DP),                        intent(inout) :: Qloss            !! Energy lost during collision
      ! Result
      integer(I4B)                                   :: status           !! Status flag assigned to this outcome
      ! Internals
      integer(I4B)                            :: i, istart, nfrag, ibiggest, nfamily, nstart, nend
      real(DP)                                :: mtot, avg_dens
      real(DP), dimension(NDIM)               :: xcom, vcom, Ip_new
      real(DP), dimension(2)                  :: vol
      real(DP), dimension(:, :), allocatable  :: vb_frag, xb_frag, rot_frag, Ip_frag
      real(DP), dimension(:), allocatable     :: m_frag, rad_frag
      integer(I4B), dimension(:), allocatable :: id_frag
      logical                                 :: lfailure
   
      ! Collisional fragments will be uniformly distributed around the pre-impact barycenter
      nfrag = NFRAG_DISRUPT 
      allocate(m_frag(nfrag))
      allocate(rad_frag(nfrag))
      allocate(xb_frag(NDIM, nfrag))
      allocate(vb_frag(NDIM, nfrag))
      allocate(rot_frag(NDIM, nfrag))
      allocate(Ip_frag(NDIM, nfrag))
      allocate(id_frag(nfrag))
   
      mtot = sum(mass(:))
      xcom(:) = (mass(1) * x(:,1) + mass(2) * x(:,2)) / mtot
      vcom(:) = (mass(1) * v(:,1) + mass(2) * v(:,2)) / mtot
   
      ! Get mass weighted mean of Ip and average density
      Ip_new(:) = (mass(1) * Ip(:,1) + mass(2) * Ip(:,2)) / mtot
      vol(:) = 4._DP / 3._DP * PI * radius(:)**3
      avg_dens = mtot / sum(vol(:))
   
      ! Distribute the mass among fragments, with a branch to check for the size of the second largest fragment
      m_frag(1) = mass_res(1)
      if (mass_res(2) > mass_res(1) / 3._DP) then
         m_frag(2) = mass_res(2)
         istart = 3
      else
         istart = 2
      end if
      ! Distribute remaining mass among the remaining bodies
      do i = istart, nfrag
         m_frag(i) = (mtot - sum(m_frag(1:istart - 1))) / (nfrag - istart + 1) 
      end do
   
      ! Distribute any residual mass if there is any and set the radius
      m_frag(nfrag) = m_frag(nfrag) + (mtot - sum(m_frag(:)))
      rad_frag(:) = (3 * m_frag(:) / (4 * PI * avg_dens))**(1.0_DP / 3.0_DP)
      id_frag(:) = [(i, i = system%maxid + 1, system%maxid + nfrag)]
   
      do i = 1, nfrag
         Ip_frag(:, i) = Ip_new(:)
      end do
   
      call fragmentation_initialize(system, param, family, x, v, L_spin, Ip, mass, radius, &
                                    nfrag, Ip_frag, m_frag, rad_frag, xb_frag, vb_frag, rot_frag, Qloss, lfailure)
   
      if (lfailure) then
         write(*,*) 'No fragment solution found, so treat as a pure hit-and-run'
         status = ACTIVE 
         nfrag = 0
      else
         ! Populate the list of new bodies
         write(*,'("Generating ",I2.0," fragments")') nfrag
         status = DISRUPTION
         call symba_fragmentation_mergeaddsub(system, param, family, id_frag, Ip_frag, m_frag, rad_frag, xb_frag, vb_frag, rot_frag, status)
      end if

      return
   end function symba_fragmentation_casedisruption


   module function symba_fragmentation_casehitandrun(system, param, family, x, v, mass, radius, L_spin, Ip, mass_res, Qloss)  result(status)
      !! author: Jennifer L.L. Pouplin, Carlisle A. Wishard, and David A. Minton
      !!
      !! Create the fragments resulting from a non-catastrophic hit-and-run collision
      !! 
      implicit none
      ! Arguments
      class(symba_nbody_system),       intent(inout) :: system           !! SyMBA nbody system object
      class(symba_parameters),         intent(in)    :: param            !! Current run configuration parameters with SyMBA additions
      integer(I4B),    dimension(:),   intent(in)    :: family           !! List of indices of all bodies inovlved in the collision
      real(DP),        dimension(:,:), intent(inout) :: x, v, L_spin, Ip !! Input values that represent a 2-body equivalent of a possibly 2+ body collision
      real(DP),        dimension(:),   intent(inout) :: mass, radius     !! Input values that represent a 2-body equivalent of a possibly 2+ body collision
      real(DP),        dimension(:),   intent(inout) :: mass_res         !! The distribution of fragment mass obtained by the regime calculation 
      real(DP),                        intent(inout) :: Qloss            !! Energy lost during collision
      ! Result
      integer(I4B)                                   :: status           !! Status flag assigned to this outcome
      ! Internals
      integer(I4B)                            :: i, nfrag, jproj, jtarg, idstart, ibiggest, nfamily
      real(DP)                                :: mtot, avg_dens
      real(DP), dimension(NDIM)               :: xcom, vcom
      real(DP), dimension(2)                  :: vol
      real(DP), dimension(:, :), allocatable  :: vb_frag, xb_frag, rot_frag, Ip_frag
      real(DP), dimension(:), allocatable     :: m_frag, rad_frag
      integer(I4B), dimension(:), allocatable :: id_frag
      logical                                 :: lpure
      logical,  dimension(system%pl%nbody)    :: lmask
   
      mtot = sum(mass(:))
      xcom(:) = (mass(1) * x(:,1) + mass(2) * x(:,2)) / mtot
      vcom(:) = (mass(1) * v(:,1) + mass(2) * v(:,2)) / mtot
      lpure = .false.
   
      ! The largest body will stay untouched
      if (mass(1) > mass(2)) then
         jtarg = 1
         jproj = 2
      else
         jtarg = 2
         jproj = 1
      end if
   
      if (mass_res(2) > 0.9_DP * mass(jproj)) then ! Pure hit and run, so we'll just keep the two bodies untouched
         write(*,*) 'Pure hit and run. No new fragments generated.'
         nfrag = 0
         lpure = .true.
      else ! Imperfect hit and run, so we'll keep the largest body and destroy the other
         nfrag = NFRAG_DISRUPT - 1
         lpure = .false.
         allocate(m_frag(nfrag))
         allocate(id_frag(nfrag))
         allocate(rad_frag(nfrag))
         allocate(xb_frag(NDIM, nfrag))
         allocate(vb_frag(NDIM, nfrag))
         allocate(rot_frag(NDIM, nfrag))
         allocate(Ip_frag(NDIM, nfrag))
         m_frag(1) = mass(jtarg)
         ibiggest = maxloc(system%pl%Gmass(family(:)), dim=1)
         id_frag(1) = system%pl%id(ibiggest)
         rad_frag(1) = radius(jtarg)
         xb_frag(:, 1) = x(:, jtarg) 
         vb_frag(:, 1) = v(:, jtarg)
         Ip_frag(:,1) = Ip(:, jtarg)
   
         ! Get mass weighted mean of Ip and average density
         vol(:) = 4._DP / 3._DP * pi * radius(:)**3
         avg_dens = mass(jproj) / vol(jproj)
         m_frag(2:nfrag) = (mtot - m_frag(1)) / (nfrag - 1) 
         rad_frag(2:nfrag) = (3 * m_frag(2:nfrag) / (4 * PI * avg_dens))**(1.0_DP / 3.0_DP)
         m_frag(nfrag) = m_frag(nfrag) + (mtot - sum(m_frag(:)))
         id_frag(2:nfrag) = [(i, i = system%maxid + 1, system%maxid + nfrag - 1)]
   
         do i = 1, nfrag
            Ip_frag(:, i) = Ip(:, jproj)
         end do
   
         ! Put the fragments on the circle surrounding the center of mass of the system
         call fragmentation_initialize(system, param, family, x, v, L_spin, Ip, mass, radius, &
                           nfrag, Ip_frag, m_frag, rad_frag, xb_frag, vb_frag, rot_frag, Qloss, lpure)
         if (lpure) then
            write(*,*) 'Should have been a pure hit and run instead'
            nfrag = 0
         else
            write(*,'("Generating ",I2.0," fragments")') nfrag
         end if
      end if
      if (lpure) then
         status = ACTIVE
      else
         status = HIT_AND_RUN
         call symba_fragmentation_mergeaddsub(system, param, family, id_frag, Ip_frag, m_frag, rad_frag, xb_frag, vb_frag, rot_frag, status)
      end if

   return
   end function symba_fragmentation_casehitandrun


   module function symba_fragmentation_casemerge(system, param, family, x, v, mass, radius, L_spin, Ip)  result(status)
      !! author: Jennifer L.L. Pouplin, Carlisle A. Wishard, and David A. Minton
      !!
      !! Merge planets.
      !! 
      !! Adapted from David E. Kaufmann's Swifter routines symba_merge_pl.f90 and symba_discard_merge_pl.f90
      !!
      !! Adapted from Hal Levison's Swift routines symba5_merge.f and discard_mass_merge.f
      implicit none
      ! Arguments
      class(symba_nbody_system),       intent(inout) :: system           !! SyMBA nbody system object
      class(symba_parameters),         intent(in)    :: param            !! Current run configuration parameters with SyMBA additions
      integer(I4B),    dimension(:),   intent(in)    :: family           !! List of indices of all bodies inovlved in the collision
      real(DP),        dimension(:,:), intent(in)    :: x, v, L_spin, Ip !! Input values that represent a 2-body equivalent of a possibly 2+ body collision
      real(DP),        dimension(:),   intent(in)    :: mass, radius     !! Input values that represent a 2-body equivalent of a possibly 2+ body collision
      ! Result
      integer(I4B)                                   :: status           !! Status flag assigned to this outcome
      ! Internals
      integer(I4B)                              :: i, j, ibiggest, nfamily
      real(DP)                                  :: volume_new, pe
      real(DP), dimension(NDIM)                 :: xc, vc, xcrossv
      real(DP), dimension(2)                    :: vol
      real(DP), dimension(NDIM)                 :: L_orb_old, L_spin_old
      real(DP), dimension(NDIM)                 :: L_spin_new
      logical,  dimension(system%pl%nbody)      :: lmask
      real(DP), dimension(NDIM, 1)              :: vb_frag, xb_frag, rot_frag, Ip_frag
      real(DP), dimension(1)                    :: m_frag, rad_frag
      integer(I4B), dimension(1)                :: id_frag
   
      select type(pl => system%pl)
      class is (symba_pl)
         write(*, '("Merging bodies ",99(I8,",",:))') pl%id(family(:))

         ibiggest = maxloc(pl%Gmass(family(:)), dim=1)
         id_frag(1) = pl%id(family(ibiggest))

         m_frag(1) = sum(mass(:))
   
         ! Merged body is created at the barycenter of the original bodies
         xb_frag(:,1) = (mass(1) * x(:,1) + mass(2) * x(:,2)) / m_frag(1)
         vb_frag(:,1) = (mass(1) * v(:,1) + mass(2) * v(:,2)) / m_frag(1)
   
         ! Get mass weighted mean of Ip and 
         vol(:) = 4._DP / 3._DP * PI * radius(:)**3
         volume_new = sum(vol(:))
         rad_frag(1) = (3 * volume_new / (4 * PI))**(1._DP / 3._DP)

         L_orb_old(:) = 0.0_DP

         ! Compute orbital angular momentum of pre-impact system
         do i = 1, 2
            xc(:) = x(:, i) - xb_frag(:,1)
            vc(:) = v(:, i) - vb_frag(:,1)
            xcrossv(:) = xc(:) .cross. vc(:)
            L_orb_old(:) = L_orb_old(:) + mass(i) * xcrossv(:)
         end do
      
         if (param%lrotation) then
            Ip_frag(:,1) = (mass(1) * Ip(:,1) + mass(2) * Ip(:,2)) / m_frag(1)
            L_spin_old(:) = L_spin(:,1) + L_spin(:,2)

            ! Conserve angular momentum by putting pre-impact orbital momentum into spin of the new body
            L_spin_new(:) = L_orb_old(:) + L_spin_old(:) 
   
            ! Assume prinicpal axis rotation on 3rd Ip axis
            rot_frag(:,1) = L_spin_new(:) / (Ip_frag(3,1) * m_frag(1) * rad_frag(1)**2)
         else ! If spin is not enabled, we will consider the lost pre-collision angular momentum as "escaped" and add it to our bookkeeping variable
            system%Lescape(:) = system%Lescape(:) + L_orb_old(:) 
         end if
   
         ! Keep track of the component of potential energy due to the pre-impact family for book-keeping
         nfamily = size(family(:))
         pe = 0.0_DP
         do j = 1, nfamily
            do i = j + 1, nfamily
               pe = pe - pl%mass(i) * pl%mass(j) / norm2(pl%xb(:, i) - pl%xb(:, j))
            end do
         end do
         system%Ecollisions  = system%Ecollisions + pe 
         system%Euntracked = system%Euntracked - pe 

         status = MERGED
         call symba_fragmentation_mergeaddsub(system, param, family, id_frag, Ip_frag, m_frag, rad_frag, xb_frag, vb_frag, rot_frag, status)
         
      end select
   
      return 
   end function symba_fragmentation_casemerge


   module function symba_fragmentation_casesupercatastrophic(system, param, family, x, v, mass, radius, L_spin, Ip, mass_res, Qloss)  result(status)
      !! author: Jennifer L.L. Pouplin, Carlisle A. Wishard, and David A. Minton
      !!
      !! Create the fragments resulting from a supercatastrophic collision
      !! 
      implicit none
      ! Arguments
      class(symba_nbody_system),       intent(inout) :: system           !! SyMBA nbody system object
      class(symba_parameters),         intent(in)    :: param            !! Current run configuration parameters with SyMBA additions
      integer(I4B),    dimension(:),   intent(in)    :: family           !! List of indices of all bodies inovlved in the collision
      real(DP),        dimension(:,:), intent(inout) :: x, v, L_spin, Ip !! Input values that represent a 2-body equivalent of a possibly 2+ body collision
      real(DP),        dimension(:),   intent(inout) :: mass, radius     !! Input values that represent a 2-body equivalent of a possibly 2+ body collision
      real(DP),        dimension(:),   intent(inout) :: mass_res         !! The distribution of fragment mass obtained by the regime calculation 
      real(DP),                        intent(inout) :: Qloss            !! Energy lost during collision
      ! Result
      integer(I4B)                                   :: status           !! Status flag assigned to this outcome
      ! Internals
      integer(I4B)                            :: i, nfrag, ibiggest, nfamily, nstart, nend
      real(DP)                                :: mtot, avg_dens, min_frag_mass
      real(DP), dimension(NDIM)               :: xcom, vcom
      real(DP), dimension(2)                  :: vol
      real(DP), dimension(NDIM)               :: Ip_new
      real(DP), dimension(:, :), allocatable  :: vb_frag, xb_frag, rot_frag, Ip_frag
      real(DP), dimension(:), allocatable     :: m_frag, rad_frag
      integer(I4B), dimension(:), allocatable :: id_frag
      logical                                 :: lfailure
      logical,  dimension(system%pl%nbody)    :: lmask

      ! Collisional fragments will be uniformly distributed around the pre-impact barycenter
      nfrag = NFRAG_SUPERCAT
      allocate(m_frag(nfrag))
      allocate(rad_frag(nfrag))
      allocate(id_frag(nfrag))
      allocate(xb_frag(NDIM, nfrag))
      allocate(vb_frag(NDIM, nfrag))
      allocate(rot_frag(NDIM, nfrag))
      allocate(Ip_frag(NDIM, nfrag))
   
      mtot = sum(mass(:))
      xcom(:) = (mass(1) * x(:,1) + mass(2) * x(:,2)) / mtot
      vcom(:) = (mass(1) * v(:,1) + mass(2) * v(:,2)) / mtot
   
      ! Get mass weighted mean of Ip and average density
      Ip_new(:) = (mass(1) * Ip(:,1) + mass(2) * Ip(:,2)) / mtot
      vol(:) = 4._DP / 3._DP * pi * radius(:)**3
      avg_dens = mtot / sum(vol(:))
   
      ! If we are adding the first and largest fragment (lr), check to see if its mass is SMALLER than an equal distribution of 
      ! mass between all fragments. If so, we will just distribute the mass equally between the fragments
      min_frag_mass = mtot / nfrag
      if (mass_res(1) < min_frag_mass) then
         m_frag(:) = min_frag_mass
      else
         m_frag(1) = mass_res(1)
         m_frag(2:nfrag) = (mtot - mass_res(1)) / (nfrag - 1)
      end if
      ! Distribute any residual mass if there is any and set the radius
      m_frag(nfrag) = m_frag(nfrag) + (mtot - sum(m_frag(:)))
      rad_frag(:) = (3 * m_frag(:) / (4 * PI * avg_dens))**(1.0_DP / 3.0_DP)
      id_frag(:) = [(i, i = system%maxid + 1, system%maxid + nfrag)]
   
      do i = 1, nfrag
         Ip_frag(:, i) = Ip_new(:)
      end do

      call fragmentation_initialize(system, param, family, x, v, L_spin, Ip, mass, radius, &
                                    nfrag, Ip_frag, m_frag, rad_frag, xb_frag, vb_frag, rot_frag, Qloss, lfailure)
   
      if (lfailure) then
         write(*,*) 'No fragment solution found, so treat as a pure hit-and-run'
         status = ACTIVE 
         nfrag = 0
      else
         ! Populate the list of new bodies
         write(*,'("Generating ",I2.0," fragments")') nfrag
         status = SUPERCATASTROPHIC
         call symba_fragmentation_mergeaddsub(system, param, family, id_frag, Ip_frag, m_frag, rad_frag, xb_frag, vb_frag, rot_frag, status)
      end if

      return
   end function symba_fragmentation_casesupercatastrophic


   subroutine symba_fragmentation_mergeaddsub(system, param, family, id_frag, Ip_frag, m_frag, rad_frag, xb_frag, vb_frag, rot_frag, status)
      !! author:  David A. Minton
      !!
      !! Fills the pl_discards and pl_adds with removed and added bodies
      !!  
      implicit none
      ! Arguments
      class(symba_nbody_system),       intent(inout) :: system           !! SyMBA nbody system object
      class(symba_parameters),         intent(in)    :: param            !! Current run configuration parameters with SyMBA additions
      integer(I4B),    dimension(:),   intent(in)    :: family           !! List of indices of all bodies inovlved in the collision
      integer(I4B),    dimension(:),   intent(in)    :: id_frag          !! List of fragment ids
      real(DP),        dimension(:),   intent(in)    :: m_frag, rad_frag !! Distribution of fragment mass and radii
      real(DP),        dimension(:,:), intent(in)    :: Ip_frag          !! Fragment rotational inertia vectors
      real(DP),        dimension(:,:), intent(in)    :: xb_frag, vb_frag, rot_frag !! Fragment barycentric position, barycentric velocity, and rotation vectors
      integer(I4B),                    intent(in)    :: status           !! Status flag to assign to adds
      ! Internals
      integer(I4B) :: i, ibiggest, nstart, nend, nfamily, nfrag
      logical, dimension(system%pl%nbody)    :: lmask
      class(symba_pl), allocatable            :: plnew

      select type(pl => system%pl)
      class is (symba_pl)
         select type(pl_discards => system%pl_discards)
         class is (symba_merger)
            associate(pl_adds => system%pl_adds, cb => system%cb)

               ! Add the family bodies to the subtraction list
               nfamily = size(family(:))
               nfrag   = size(m_frag(:))
               lmask(:) = .false.
               lmask(family(:)) = .true.
               pl%status(family(:)) = MERGED
               nstart = pl_discards%nbody + 1
               nend = pl_discards%nbody + nfamily
               call pl_discards%append(pl, lmask)
               pl%ldiscard(family(:)) = .true.
               pl%lcollision(family(:)) = .true.

               ! Record how many bodies were subtracted in this event
               pl_discards%ncomp(nstart:nend) = nfamily 

               ! Setup new bodies
               allocate(plnew, mold=pl)
               call plnew%setup(nfrag, param)
               ibiggest = maxloc(pl%Gmass(family(:)), dim=1)

               plnew%id(:) = id_frag(:) 
               system%maxid = system%maxid + nfrag
               plnew%status(:) = ACTIVE
               plnew%lcollision(:) = .false.
               plnew%ldiscard(:) = .false.
               plnew%xb(:,:) = xb_frag(:, :) 
               plnew%vb(:,:) = vb_frag(:, :)
               do i = 1, nfrag
                  plnew%xh(:,i) = xb_frag(:, i) - cb%xb(:)
                  plnew%vh(:,i) = vb_frag(:, i) - cb%vb(:)
               end do
               plnew%mass(:) = m_frag(:)
               plnew%Gmass(:) = param%GU * m_frag(:)
               plnew%radius(:) = rad_frag(:)
               plnew%density(:) = m_frag(:) / rad_frag(:)

               select case(status)
               case(DISRUPTION)
                  plnew%info(:)%origin_type = "Disruption"
               case(SUPERCATASTROPHIC)
                  plnew%info(:)%origin_type = "Supercatastrophic"
               case(HIT_AND_RUN)
                  plnew%info(:)%origin_type = "Hit and run fragment"
               case(MERGED)
                  plnew%info(1) = pl%info(ibiggest)
               end select

               if (status /= MERGED) then
                  plnew%info(:)%origin_time = param%t
                  do i = 1, nfrag
                     plnew%info(i)%origin_xh(:) = plnew%xh(:,i)
                     plnew%info(i)%origin_vh(:) = plnew%vh(:,i)
                  end do
               end if

               if (param%lrotation) then
                  plnew%Ip(:,:) = Ip_frag(:,:)
                  plnew%rot(:,:) = rot_frag(:,:)
               end if
               if (param%ltides) then
                  plnew%Q = pl%Q(ibiggest)
                  plnew%k2 = pl%k2(ibiggest)
                  plnew%tlag = pl%tlag(ibiggest)
               end if
               call plnew%set_mu(cb)
               pl%lmtiny(:) = pl%Gmass(:) > param%GMTINY

               ! Append the new merged body to the list and record how many we made
               nstart = pl_adds%nbody + 1
               nend = pl_adds%nbody + plnew%nbody
               call pl_adds%append(plnew, lsource_mask=[(.true., i=1, plnew%nbody)])
               pl_adds%ncomp(nstart:nend) = plnew%nbody

               call plnew%setup(0, param)
               deallocate(plnew)
            end associate
         end select
      end select

      return
   end subroutine symba_fragmentation_mergeaddsub

end submodule s_symba_fragmentation