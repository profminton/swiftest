submodule(symba_classes) s_symba_util
   use swiftest
contains

   module subroutine symba_util_copy_pltpenc(self, source)
      !! author: David A. Minton
      !!
      !! Copies elements from the source encounter list into self.
      implicit none
      ! Arguments
      class(symba_pltpenc), intent(inout) :: self   !! SyMBA pl-tp encounter list 
      class(symba_pltpenc), intent(in)    :: source !! Source object to copy into

      associate(n => source%nenc)
         self%nenc = n
         self%lvdotr(1:n) = source%lvdotr(1:n) 
         self%status(1:n) = source%status(1:n) 
         self%level(1:n)  = source%level(1:n)
         self%index1(1:n) = source%index1(1:n)
         self%index2(1:n) = source%index2(1:n)
      end associate

      return
   end subroutine symba_util_copy_pltpenc


   module subroutine symba_util_copy_plplenc(self, source)
      !! author: David A. Minton
      !!
      !! Copies elements from the source encounter list into self.
      implicit none
      ! Arguments
      class(symba_plplenc), intent(inout) :: self   !! SyMBA pl-pl encounter list 
      class(symba_pltpenc), intent(in)    :: source !! Source object to copy into

      call symba_util_copy_pltpenc(self, source)
      associate(n => source%nenc)
         select type(source)
         class is (symba_plplenc)
            self%xh1(:,1:n) = source%xh1(:,1:n) 
            self%xh2(:,1:n) = source%xh2(:,1:n) 
            self%vb1(:,1:n) = source%vb1(:,1:n) 
            self%vb2(:,1:n) = source%vb2(:,1:n) 
         end select
      end associate

      return
   end subroutine symba_util_copy_plplenc


   module subroutine symba_util_fill_arr_char_info(keeps, inserts, lfill_list)
      !! author: David A. Minton
      !!
      !! Performs a fill operation on a single array of particle origin information types
      !! This is the inverse of a spill operation
      implicit none
      ! Arguments
      type(symba_particle_info), dimension(:), allocatable, intent(inout) :: keeps      !! Array of values to keep 
      type(symba_particle_info), dimension(:), allocatable, intent(in)    :: inserts    !! Array of values to insert into keep
      logical,                   dimension(:),              intent(in)    :: lfill_list !! Logical array of bodies to merge into the keeps

      if (.not.allocated(keeps) .or. .not.allocated(inserts)) return

      keeps(:) = unpack(keeps(:),   .not.lfill_list(:), keeps(:))
      keeps(:) = unpack(inserts(:),      lfill_list(:), keeps(:))
   
      return
   end subroutine symba_util_fill_arr_char_info


   module subroutine symba_util_fill_arr_char_kin(keeps, inserts, lfill_list)
      !! author: David A. Minton
      !!
      !! Performs a fill operation on a single array of particle kinship types
      !! This is the inverse of a spill operation   
      implicit none
      ! Arguments
      type(symba_kinship), dimension(:), allocatable, intent(inout) :: keeps      !! Array of values to keep 
      type(symba_kinship), dimension(:), allocatable, intent(in)    :: inserts    !! Array of values to insert into keep
      logical,             dimension(:),              intent(in)    :: lfill_list !! Logical array of bodies to merge into the keeps

      if (.not.allocated(keeps) .or. .not.allocated(inserts)) return

      keeps(:) = unpack(keeps(:),   .not.lfill_list(:), keeps(:))
      keeps(:) = unpack(inserts(:),      lfill_list(:), keeps(:))
   
      return
   end subroutine symba_util_fill_arr_char_kin


   module subroutine symba_util_fill_pl(self, inserts, lfill_list)
      !! author: David A. Minton
      !!
      !! Insert new SyMBA test particle structure into an old one. 
      !! This is the inverse of a fill operation.
      !! 
      implicit none
      ! Arguments
      class(symba_pl),       intent(inout) :: self       !! SyMBA masive body object
      class(swiftest_body),  intent(in)    :: inserts    !! Inserted object 
      logical, dimension(:), intent(in)    :: lfill_list !! Logical array of bodies to merge into the keeps

      associate(keeps => self)
         select type(inserts)
         class is (symba_pl)
            call util_fill(keeps%lcollision, inserts%lcollision, lfill_list)
            call util_fill(keeps%lencounter, inserts%lencounter, lfill_list)
            call util_fill(keeps%lmtiny, inserts%lmtiny, lfill_list)
            call util_fill(keeps%nplenc, inserts%nplenc, lfill_list)
            call util_fill(keeps%ntpenc, inserts%ntpenc, lfill_list)
            call util_fill(keeps%levelg, inserts%levelg, lfill_list)
            call util_fill(keeps%levelm, inserts%levelm, lfill_list)
            call util_fill(keeps%isperi, inserts%isperi, lfill_list)
            call util_fill(keeps%peri, inserts%peri, lfill_list)
            call util_fill(keeps%atp, inserts%atp, lfill_list)
            call util_fill(keeps%kin, inserts%kin, lfill_list)
            call util_fill(keeps%info, inserts%info, lfill_list)
            
            call util_fill_pl(keeps, inserts, lfill_list)
         class default
            write(*,*) 'Error! fill method called for incompatible return type on symba_pl'
         end select
      end associate

      return
   end subroutine symba_util_fill_pl


   module subroutine symba_util_fill_tp(self, inserts, lfill_list)
      !! author: David A. Minton
      !!
      !! Insert new SyMBA test particle structure into an old one. 
      !! This is the inverse of a fill operation.
      !! 
      implicit none
      ! Arguments
      class(symba_tp),       intent(inout) :: self       !! SyMBA test particle object
      class(swiftest_body),  intent(in)    :: inserts    !! Inserted object 
      logical, dimension(:), intent(in)    :: lfill_list !! Logical array of bodies to merge into the keeps

      associate(keeps => self)
         select type(inserts)
         class is (symba_tp)
            call util_fill(keeps%nplenc, inserts%nplenc, lfill_list)
            call util_fill(keeps%levelg, inserts%levelg, lfill_list)
            call util_fill(keeps%levelm, inserts%levelm, lfill_list)
            
            call util_fill_tp(keeps, inserts, lfill_list)
         class default
            write(*,*) 'Error! fill method called for incompatible return type on symba_tp'
         end select
      end associate

      return
   end subroutine symba_util_fill_tp


   module subroutine symba_util_resize_pltpenc(self, nrequested)
      !! author: David A. Minton
      !!
      !! Checks the current size of the encounter list against the required size and extends it by a factor of 2 more than requested if it is too small.
      !! Polymorphic method works on both symba_pltpenc and symba_plplenc types
      implicit none
      ! Arguments
      class(symba_pltpenc), intent(inout) :: self       !! SyMBA pl-tp encounter list 
      integer(I4B),         intent(in)    :: nrequested !! New size of list needed
      ! Internals
      class(symba_pltpenc), allocatable   :: enc_temp
      integer(I4B)                        :: nold
      logical                             :: lmalloc

      lmalloc = allocated(self%status)
      if (lmalloc) then
         nold = size(self%status)
      else
         nold = 0
      end if
      if (nrequested > nold) then
         if (lmalloc) allocate(enc_temp, source=self)
         call self%setup(2 * nrequested)
         if (lmalloc) then
            call self%copy(enc_temp)
            deallocate(enc_temp)
         end if
      else
         self%status(nrequested+1:nold) = INACTIVE
      end if
      self%nenc = nrequested

      return
   end subroutine symba_util_resize_pltpenc


   module subroutine symba_util_sort_pl(self, sortby, ascending)
      !! author: David A. Minton
      !!
      !! Sort a SyMBA massive body object in-place. 
      !! sortby is a string indicating which array component to sort.
      implicit none
      ! Arguments
      class(symba_pl), intent(inout) :: self      !! SyMBA massive body object
      character(*),    intent(in)    :: sortby    !! Sorting attribute
      logical,         intent(in)    :: ascending !! Logical flag indicating whether or not the sorting should be in ascending or descending order
      ! Internals
      integer(I4B), dimension(self%nbody) :: ind
      integer(I4B)                        :: direction

      if (self%nbody == 0) return

      if (ascending) then
         direction = 1
      else
         direction = -1
      end if

      associate(pl => self, npl => self%nbody)
         select case(sortby)
         case("nplenc")
            call util_sort(direction * pl%nplenc(1:npl), ind(1:npl))
         case("ntpenc")
            call util_sort(direction * pl%ntpenc(1:npl), ind(1:npl))
         case("levelg")
            call util_sort(direction * pl%levelg(1:npl), ind(1:npl))
         case("levelm")
            call util_sort(direction * pl%levelm(1:npl), ind(1:npl))
         case("peri")
            call util_sort(direction * pl%peri(1:npl), ind(1:npl))
         case("atp")
            call util_sort(direction * pl%atp(1:npl), ind(1:npl))
         case("lcollision", "lencounter", "lmtiny", "nplm", "nplplm", "kin", "info")
            write(*,*) 'Cannot sort by ' // trim(adjustl(sortby)) // '. Component not sortable!'
         case default ! Look for components in the parent class
            call util_sort_pl(pl, sortby, ascending)
            return
         end select

         call pl%rearrange(ind)

      end associate
      return
   end subroutine symba_util_sort_pl


   module subroutine symba_util_sort_tp(self, sortby, ascending)
      !! author: David A. Minton
      !!
      !! Sort a SyMBA test particle object in-place. 
      !! sortby is a string indicating which array component to sort.
      implicit none
      ! Arguments
      class(symba_tp), intent(inout) :: self      !! SyMBA test particle object
      character(*),    intent(in)    :: sortby    !! Sorting attribute
      logical,         intent(in)    :: ascending !! Logical flag indicating whether or not the sorting should be in ascending or descending order
      ! Internals
      integer(I4B), dimension(self%nbody) :: ind
      integer(I4B)                        :: direction

      if (self%nbody == 0) return

      if (ascending) then
         direction = 1
      else
         direction = -1
      end if

      associate(tp => self, ntp => self%nbody)
         select case(sortby)
         case("nplenc")
            call util_sort(direction * tp%nplenc(1:ntp), ind(1:ntp))
         case("levelg")
            call util_sort(direction * tp%levelg(1:ntp), ind(1:ntp))
         case("levelm")
            call util_sort(direction * tp%levelm(1:ntp), ind(1:ntp))
         case default ! Look for components in the parent class
            call util_sort_tp(tp, sortby, ascending)
            return
         end select

         call tp%rearrange(ind)
      end associate

      return
   end subroutine symba_util_sort_tp


   module subroutine symba_util_sort_rearrange_pl(self, ind)
      !! author: David A. Minton
      !!
      !! Rearrange SyMBA massive body structure in-place from an index list.
      !! This is a helper utility used to make polymorphic sorting work on Swiftest structures.
      implicit none
      ! Arguments
      class(symba_pl),               intent(inout) :: self !! SyMBA massive body object
      integer(I4B),    dimension(:), intent(in)    :: ind  !! Index array used to restructure the body (should contain all 1:n index values in the desired order)
      ! Internals
      class(symba_pl), allocatable :: pl_sorted  !! Temporary holder for sorted body
      integer(I4B) :: i, j

      associate(pl => self, npl => self%nbody)
         call util_sort_rearrange_pl(pl,ind)
         allocate(pl_sorted, source=self)
         pl%lcollision(1:npl) = pl_sorted%lcollision(ind(1:npl))
         pl%lencounter(1:npl) = pl_sorted%lencounter(ind(1:npl))
         pl%lmtiny(1:npl) = pl_sorted%lmtiny(ind(1:npl))
         pl%nplenc(1:npl) = pl_sorted%nplenc(ind(1:npl))
         pl%ntpenc(1:npl) = pl_sorted%ntpenc(ind(1:npl))
         pl%levelg(1:npl) = pl_sorted%levelg(ind(1:npl))
         pl%levelm(1:npl) = pl_sorted%levelm(ind(1:npl))
         pl%isperi(1:npl) = pl_sorted%isperi(ind(1:npl))
         pl%peri(1:npl) = pl_sorted%peri(ind(1:npl))
         pl%atp(1:npl) = pl_sorted%atp(ind(1:npl))
         pl%info(1:npl) = pl_sorted%info(ind(1:npl))
         pl%kin(1:npl) = pl_sorted%kin(ind(1:npl))
         do i = 1, npl
            do j = 1, pl%kin(i)%nchild
               pl%kin(i)%child(j) = ind(pl%kin(i)%child(j))
            end do
         end do
         deallocate(pl_sorted)
      end associate

      return
   end subroutine symba_util_sort_rearrange_pl


   module subroutine symba_util_sort_rearrange_tp(self, ind)
      !! author: David A. Minton
      !!
      !! Rearrange SyMBA test particle object in-place from an index list.
      !! This is a helper utility used to make polymorphic sorting work on Swiftest structures.
      implicit none
      ! Arguments
      class(symba_tp),               intent(inout) :: self !! SyMBA test particle object
      integer(I4B),    dimension(:), intent(in)    :: ind  !! Index array used to restructure the body (should contain all 1:n index values in the desired order)
      ! Internals
      class(symba_tp), allocatable :: tp_sorted  !! Temporary holder for sorted body

      associate(tp => self, ntp => self%nbody)
         call util_sort_rearrange_tp(tp,ind)
         allocate(tp_sorted, source=self)
         tp%nplenc(1:ntp) = tp_sorted%nplenc(ind(1:ntp))
         tp%levelg(1:ntp) = tp_sorted%levelg(ind(1:ntp))
         tp%levelm(1:ntp) = tp_sorted%levelm(ind(1:ntp))
         deallocate(tp_sorted)
      end associate
      
      return
   end subroutine symba_util_sort_rearrange_tp


   module subroutine symba_util_spill_arr_info(keeps, discards, lspill_list, ldestructive)
      !! author: David A. Minton
      !!
      !! Performs a spill operation on a single array of particle origin information types
      !! This is the inverse of a spill operation
      implicit none
      ! Arguments
      type(symba_particle_info), dimension(:), allocatable, intent(inout) :: keeps        !! Array of values to keep 
      type(symba_particle_info), dimension(:), allocatable, intent(inout) :: discards     !! Array of discards
      logical,                   dimension(:),              intent(in)    :: lspill_list  !! Logical array of bodies to spill into the discardss
      logical,                                              intent(in)    :: ldestructive !! Logical flag indicating whether or not this operation should alter the keeps array or not

      if (.not.allocated(keeps) .or. count(lspill_list(:)) == 0) return
      if (.not.allocated(discards)) allocate(discards(count(lspill_list(:))))

      discards(:) = pack(keeps(:), lspill_list(:))
      if (ldestructive) then
         if (count(.not.lspill_list(:)) > 0) then
            keeps(:) = pack(keeps(:), .not. lspill_list(:))
         else
            deallocate(keeps)
         end if
      end if

      return
   end subroutine symba_util_spill_arr_info


   module subroutine symba_util_spill_arr_kin(keeps, discards, lspill_list, ldestructive)
      !! author: David A. Minton
      !!
      !! Performs a spill operation on a single array of particle kinships
      !! This is the inverse of a spill operation
      implicit none
      ! Arguments
      type(symba_kinship), dimension(:), allocatable, intent(inout) :: keeps        !! Array of values to keep 
      type(symba_kinship), dimension(:), allocatable, intent(inout) :: discards     !! Array of discards
      logical,             dimension(:),              intent(in)    :: lspill_list  !! Logical array of bodies to spill into the discardss
      logical,                                        intent(in)    :: ldestructive !! Logical flag indicating whether or not this operation should alter the keeps array or not

      if (.not.allocated(keeps) .or. count(lspill_list(:)) == 0) return
      if (.not.allocated(discards)) allocate(discards(count(lspill_list(:))))

      discards(:) = pack(keeps(:), lspill_list(:))
      if (ldestructive) then
         if (count(.not.lspill_list(:)) > 0) then
            keeps(:) = pack(keeps(:), .not. lspill_list(:))
         else
            deallocate(keeps)
         end if
      end if

      return
   end subroutine symba_util_spill_arr_kin


   module subroutine symba_util_spill_pl(self, discards, lspill_list, ldestructive)
      !! author: David A. Minton
      !!
      !! Move spilled (discarded) SyMBA massive body particle structure from active list to discard list
      !! Adapted from David E. Kaufmann's Swifter routine whm_discard_spill.f90
      implicit none
      ! Arguments
      class(symba_pl),       intent(inout) :: self        !! SyMBA massive body object
      class(swiftest_body),  intent(inout) :: discards    !! Discarded object 
      logical, dimension(:), intent(in)    :: lspill_list !! Logical array of bodies to spill into the discards
      logical,               intent(in)    :: ldestructive !! Logical flag indicating whether or not this operation should alter body by removing the discard list
      ! Internals
      integer(I4B) :: i

      ! For each component, pack the discarded bodies into the discard object and do the inverse with the keeps
      !> Spill all the common components
      associate(keeps => self)
         select type(discards)
         class is (symba_pl)
            call util_spill(keeps%lcollision, discards%lcollision, lspill_list, ldestructive)
            call util_spill(keeps%lencounter, discards%lencounter, lspill_list, ldestructive)
            call util_spill(keeps%lmtiny, discards%lmtiny, lspill_list, ldestructive)
            call util_spill(keeps%nplenc, discards%nplenc, lspill_list, ldestructive)
            call util_spill(keeps%ntpenc, discards%ntpenc, lspill_list, ldestructive)
            call util_spill(keeps%levelg, discards%levelg, lspill_list, ldestructive)
            call util_spill(keeps%levelm, discards%levelm, lspill_list, ldestructive)
            call util_spill(keeps%isperi, discards%isperi, lspill_list, ldestructive)
            call util_spill(keeps%peri, discards%peri, lspill_list, ldestructive)
            call util_spill(keeps%atp, discards%atp, lspill_list, ldestructive)
            call util_spill(keeps%info, discards%info, lspill_list, ldestructive)
            call util_spill(keeps%kin, discards%kin, lspill_list, ldestructive)

            call util_spill_pl(keeps, discards, lspill_list, ldestructive)
         class default
            write(*,*) 'Error! spill method called for incompatible return type on symba_pl'
         end select
      end associate
     
      return
   end subroutine symba_util_spill_pl


   module subroutine symba_util_spill_tp(self, discards, lspill_list, ldestructive)
      !! author: David A. Minton
      !!
      !! Move spilled (discarded) SyMBA test particle structure from active list to discard list
      !! Adapted from David E. Kaufmann's Swifter routine whm_discard_spill.f90
      implicit none
      ! Arguments
      class(symba_tp),       intent(inout) :: self         !! SyMBA test particle object
      class(swiftest_body),  intent(inout) :: discards     !! Discarded object 
      logical, dimension(:), intent(in)    :: lspill_list  !! Logical array of bodies to spill into the discards
      logical,               intent(in)    :: ldestructive !! Logical flag indicating whether or not this operation should alter body by removing the discard list
      ! Internals
      integer(I4B) :: i

      ! For each component, pack the discarded bodies into the discard object and do the inverse with the keeps
      !> Spill all the common components
      associate(keeps => self)
         select type(discards)
         class is (symba_pl)
            call util_spill(keeps%nplenc, discards%nplenc, lspill_list, ldestructive)
            call util_spill(keeps%levelg, discards%levelg, lspill_list, ldestructive)
            call util_spill(keeps%levelm, discards%levelm, lspill_list, ldestructive)

            call util_spill_tp(keeps, discards, lspill_list, ldestructive)
         class default
            write(*,*) 'Error! spill method called for incompatible return type on symba_pl'
         end select
      end associate
     
      return
   end subroutine symba_util_spill_tp

end submodule s_symba_util