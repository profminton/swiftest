!**********************************************************************************************************************************
!
!  Unit Name   : helio_getacch_int_tp
!  Unit Type   : subroutine
!  Project     : Swifter
!  Package     : helio
!  Language    : Fortran 90/95
!
!  Description : Compute direct cross term heliocentric accelerations of test particles
!
!  Input
!    Arguments : npl          : number of planets
!                ntp          : number of active test particles
!                swifter_pl1P : pointer to head of Swifter planet structure linked-list
!                helio_tp1P   : pointer to head of active helio test particle structure linked-list
!                xh           : heliocentric planet positions
!    Terminal  : none
!    File      : none
!
!  Output
!    Arguments : helio_tp1P   : pointer to head of active helio test particle structure linked-list
!    Terminal  : none
!    File      : none
!
!  Invocation  : CALL helio_getacch_int_tp(npl, ntp, swifter_pl1P, helio_tp1P, xh)
!
!  Notes       : Adapted from Hal Levison's Swift routine getacch_ah3_tp.f
!
!**********************************************************************************************************************************
SUBROUTINE helio_getacch_int_tp(npl, ntp, swifter_plA, helio_tpA, xh)

! Modules
     USE module_parameters
     USE module_swiftest
     USE module_helio
     USE module_interfaces, EXCEPT_THIS_ONE => helio_getacch_int_tp
     IMPLICIT NONE

! Arguments
     INTEGER(I4B), INTENT(IN)                    :: npl, ntp
     REAL(DP), DIMENSION(NDIM, npl), INTENT(IN)  :: xh
     TYPE(swifter_pl), DIMENSION(:),INTENT(INOUT):: swifter_plA
     TYPE(helio_tp), DIMENSION(:),INTENT(INOUT)  :: helio_tpA

! Internals
     INTEGER(I4B)              :: i, j
     REAL(DP)                  :: r2, fac
     REAL(DP), DIMENSION(NDIM) :: dx

! Executable code
     DO i = 1, ntp
          IF (helio_tpA%swiftest%status(i) == ACTIVE) THEN
               DO j = 2, npl
                    dx(:) = helio_tpA%swiftest%xh(:,i) - helio_plA%swiftest%xh(:,j)
                    r2 = DOT_PRODUCT(dx(:), dx(:))
                    fac = helio_tpA%swiftest%mass(j)/(r2*SQRT(r2))
                    helio_tpA%ahi(:,i) = helio_tpA%ahi(:,i) - fac*dx(:)
               END DO
          END IF
     END DO

     RETURN

END SUBROUTINE helio_getacch_int_tp
!**********************************************************************************************************************************
!
!  Author(s)   : David E. Kaufmann
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
