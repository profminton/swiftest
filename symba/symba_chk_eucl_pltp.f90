!**********************************************************************************************************************************
!
!  Unit Name   : symba_chk_eucl
!  Unit Type   : subroutine
!  Project     : Swiftest
!  Package     : symba
!  Language    : Fortran 90/95
!
!  Description : Check for an encounter
!
!  Input
!    Arguments : xr         : position of body 2 relative to body 1
!                vr         : velocity of body 2 relative to body 1
!                rhill1     : Hill sphere radius of body 1
!                rhill2     : Hill sphere radius of body 2
!                dt         : time step
!                irec       : recursion level
!    Terminal  : none
!    File      : none
!
!  Output
!    Arguments : lencounter : logical flag indicating whether there is an encounter this time step
!                lvdotr     : logical flag indicating whether the two bodies are approaching
!    Terminal  : none
!    File      : none
!
!  Invocation  : CALL symba_chk(xr, vr, rhill1, rhill2, dt, irec, lencounter, lvdotr)
!
!  Notes       : Adapted from Hal Levison's Swift routine symba5_chk.f
!
!**********************************************************************************************************************************
SUBROUTINE symba_chk_eucl_pltp(num_encounters, k_plpl, xr, vr, rhill, dt, lencounter, lvdotr)

! Modules
     USE module_parameters
     USE module_swiftest
     USE module_helio
     USE module_symba
     USE module_interfaces, EXCEPT_THIS_ONE => symba_chk_eucl_pltp
     IMPLICIT NONE

! Arguments
     INTEGER(I4B), DIMENSION(num_encounters), INTENT(OUT) :: lencounter, lvdotr
     INTEGER(I4B), INTENT(IN)           :: num_encounters
     INTEGER(I4B), DIMENSION(num_encounters,2), INTENT(IN)     :: k_plpl
     REAL(DP), DIMENSION(:),INTENT(IN)  :: rhill
     REAL(DP), INTENT(IN)               :: dt
     REAL(DP), DIMENSION(NDIM,num_encounters), INTENT(IN) :: xr, vr

! Internals
     ! LOGICAL(LGT) :: iflag lvdotr_flag
     REAL(DP)     :: rcrit, r2crit, vdotr, r2, v2, tmin, r2min, term2, rcritmax, r2critmax
     INTEGER(I4B) :: k

! Executable code
     
     term2 = RHSCALE*(RSHELL**0)

     rcritmax = rhill(2) * term2
     r2critmax = rcritmax * rcritmax

!$omp parallel do default(none) schedule(static) &
!$omp private(k, rcrit, r2crit, r2, vdotr, v2, tmin, r2min) &
!$omp shared(num_encounters, lvdotr, lencounter, rhill, k_plpl, xr, vr, dt, term2, r2critmax)

     do k = 1,num_encounters
          r2 = DOT_PRODUCT(xr(:,k), xr(:,k)) 
          if (r2<r2critmax) then

               rcrit = rhill(k_plpl(k,1))*term2
               r2crit = rcrit*rcrit 

               vdotr = DOT_PRODUCT(vr(:,k), xr(:,k))

               IF (vdotr < 0.0_DP) lvdotr(k) = k

               IF (r2 < r2crit) THEN
                    lencounter(k) = k
               ELSE
                    IF (vdotr < 0.0_DP) THEN
                         v2 = DOT_PRODUCT(vr(:,k), vr(:,k))
                         tmin = -vdotr/v2
                         IF (tmin < dt) THEN
                              r2min = r2 - vdotr*vdotr/v2
                         ELSE
                              r2min = r2 + 2.0_DP*vdotr*dt + v2*dt*dt
                         END IF
                         r2min = MIN(r2min, r2)
                         IF (r2min <= r2crit) lencounter(k) = k
                    END IF
               END IF
          endif
     enddo

!$omp end parallel do

     RETURN

END SUBROUTINE symba_chk_eucl_pltp
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
