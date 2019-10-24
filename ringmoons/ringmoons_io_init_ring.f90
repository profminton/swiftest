!**********************************************************************************************************************************
!
!  Unit Name   : ringmoons_io_init_ring
!  Unit Type   : subroutine
!  Project     : Swifter
!  Package     : io
!  Language    : Fortran 90/95
!
!  Description : Read in ring initial condition data
!
!  Input
!    Arguments : 
!                
!    Terminal  : none
!    File      : 
!
!  Output
!    Arguments : 
!    Terminal  : 
!    File      : 
!
!  Invocation  : CALL ringmoons_io_init_ring()
!
!  Notes       : Adapted from Andy Hesselbrock's ringmoons Python scripts
!
!**********************************************************************************************************************************
subroutine ringmoons_io_init_ring(swifter_pl1P,ring)

! Modules
      use module_parameters
      use module_ringmoons
      use module_ringmoons_interfaces, EXCEPT_THIS_ONE => ringmoons_io_init_ring
      implicit none

! Arguments
      type(swifter_pl),pointer            :: swifter_pl1P
      type(ringmoons_ring),intent(inout) :: ring

! Internals
      character(STRMAX)                  :: ringfile
      integer(I4B),parameter             :: LUN = 22
      integer(I4B)                       :: i,ioerr


! Executable code
      ringfile='ring.in'
      open(unit=LUN,file=ringfile,status='old',iostat=ioerr)
      read(LUN,*) ring%N
      read(LUN,*) ring%r_I, ring%r_F
      read(LUN,*) ring%r_pdisk,ring%Gm_pdisk
      call ringmoons_allocate(ring)
      do i = 1,ring%N
         read(LUN,*,iostat=ioerr) ring%Gsigma(i)
         if (ioerr /= 0) then 
            write(*,*) 'File read error in ',trim(adjustl(ringfile))
         end if
      end do

      call ringmoons_ring_construct(swifter_pl1P,ring)
      call ringmoons_viscosity(ring)
      call ringmoons_seed_construct(swifter_pl1P,ring)
   



      return

end subroutine ringmoons_io_init_ring
!**********************************************************************************************************************************
!
!  Author(s)   : David A. Minton  
!
!  Revision Control System (RCS) Information
!
!  Source File : $RCSfile$
!  Full Path   : $Source$
!  Revision    : $Revision$
!  Date        : $Date$
!  Programmer  : $Author$
!  Locked By   : $Locker$
!  State       : $State$
!
!  Modification History:
!
!  $Log$
!**********************************************************************************************************************************
