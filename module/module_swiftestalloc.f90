!**********************************************************************************************************************************
!
!  Unit Name   : module_swiftestalloc
!  Unit Type   : module
!  Project     : SWIFTEST
!  Package     : module
!  Language    : Fortran 2003
!
!  Description : 
!
!  Input
!    Arguments : N/A
!    Terminal  : N/A
!    File      : N/A
!
!  Output
!    Arguments : N/A
!    Terminal  : N/A
!    File      : N/A
!
!  Invocation  : N/A
!
!  Notes       : 
!
!**********************************************************************************************************************************
!
!  Author(s)   : Jennifer Pouplin & Carlisle Wisahrd
!
!**********************************************************************************************************************************
MODULE module_swiftestalloc

	USE module_parameters
	IMPLICIT NONE

	CONTAINS 

		SUBROUTINE swiftest_pl_allocate(swiftest_plA, npl)
			USE module_parameters
			USE module_swiftest
			IMPLICIT NONE

			! Arguments
			INTEGER(I4B), INTENT(IN)			:: npl
			TYPE(swiftest_pl), INTENT(INOUT)	:: swiftest_plA

			ALLOCATE(swiftest_plA%id(npl))
         	ALLOCATE(swiftest_plA%status(npl))
         	ALLOCATE(swiftest_plA%mass(npl))
         	ALLOCATE(swiftest_plA%radius(npl))
         	ALLOCATE(swiftest_plA%rhill(npl))
         	ALLOCATE(swiftest_plA%xh(NDIM,npl))
         	ALLOCATE(swiftest_plA%vh(NDIM,npl))
         	ALLOCATE(swiftest_plA%xb(NDIM,npl))
         	ALLOCATE(swiftest_plA%vb(NDIM,npl))
        	return
        END SUBROUTINE swiftest_pl_allocate


        SUBROUTINE helio_pl_allocate(helio_plA, npl)
			USE module_parameters
			USE module_helio
			IMPLICIT NONE

			! Arguments
			INTEGER(I4B), INTENT(IN)			:: npl
			TYPE(helio_pl), INTENT(INOUT)		:: helio_plA

			ALLOCATE(helio_plA%ah(NDIM,npl))
         	ALLOCATE(helio_plA%ahi(NDIM,npl))
         	CALL swiftest_pl_allocate(helio_plA%swiftest,npl)
        	return
        END SUBROUTINE helio_pl_allocate


        SUBROUTINE symba_pl_allocate(symba_plA, npl)
			USE module_parameters
			USE module_symba
			IMPLICIT NONE

			! Arguments
			INTEGER(I4B), INTENT(IN)			:: npl
			TYPE(symba_pl), INTENT(INOUT)		:: symba_plA

			ALLOCATE(symba_plA%lmerged(npl))
			ALLOCATE(symba_plA%nplenc(npl))
			ALLOCATE(symba_plA%ntpenc(npl))
			ALLOCATE(symba_plA%levelg(npl))
			ALLOCATE(symba_plA%levelm(npl))
			ALLOCATE(symba_plA%nchild(npl))
			ALLOCATE(symba_plA%isperi(npl))
			ALLOCATE(symba_plA%peri(npl))
			ALLOCATE(symba_plA%atp(npl))
			CALL helio_pl_allocate(symba_plA%helio,npl)
			return
		END SUBROUTINE symba_pl_allocate

		SUBROUTINE symba_plplenc_allocate(plplenc_list, nplplenc)
			USE module_parameters
			USE module_symba
			IMPLICIT NONE

			! Arguments
			INTEGER(I4B), INTENT(IN)				:: nplplenc
			TYPE(symba_plplenc), INTENT(INOUT)		:: plplenc_list

			ALLOCATE(plplenc_list%lvdotr(nplplenc))
			ALLOCATE(plplenc_list%status(nplplenc))
			ALLOCATE(plplenc_list%level(nplplenc))
			ALLOCATE(plplenc_list%id1(nplplenc))
			ALLOCATE(plplenc_list%id2(nplplenc))
			return
		END SUBROUTINE symba_plplenc_allocate

		SUBROUTINE symba_merger_allocate(mergeadd_list, nmergeadd)
			USE module_parameters
			USE module_symba
			IMPLICIT NONE

			! Arguments
			INTEGER(I4B), INTENT(IN)				:: nmergeadd
			TYPE(symba_merger), INTENT(INOUT)		:: mergeadd_list

			ALLOCATE(mergeadd_list%id(nmergeadd))
			ALLOCATE(mergeadd_list%status(nmergeadd))
			ALLOCATE(mergeadd_list%ncomp(nmergeadd))
			ALLOCATE(mergeadd_list%xh(NDIM,nmergeadd))
			ALLOCATE(mergeadd_list%vh(NDIM,nmergeadd))
			ALLOCATE(mergeadd_list%mass(nmergeadd))
			ALLOCATE(mergeadd_list%radius(nmergeadd))
			return
		END SUBROUTINE symba_merger_allocate

		SUBROUTINE swiftest_tp_allocate(swiftest_tpA, ntp)
			USE module_parameters
			USE module_swiftest
			IMPLICIT NONE

			! Arguments
			INTEGER(I4B), INTENT(IN)			:: ntp
			TYPE(swiftest_tp), INTENT(INOUT)	:: swiftest_tpA

			ALLOCATE(swiftest_tpA%id(ntp))
         	ALLOCATE(swiftest_tpA%status(ntp))
         	ALLOCATE(swiftest_tpA%peri(ntp))
         	ALLOCATE(swiftest_tpA%atp(ntp))
         	ALLOCATE(swiftest_tpA%isperi(ntp))
         	ALLOCATE(swiftest_tpA%xh(NDIM,ntp))
         	ALLOCATE(swiftest_tpA%vh(NDIM,ntp))
         	ALLOCATE(swiftest_tpA%xb(NDIM,ntp))
         	ALLOCATE(swiftest_tpA%vb(NDIM,ntp))
        	return
        END SUBROUTINE swiftest_tp_allocate


        SUBROUTINE helio_tp_allocate(helio_tpA, ntp)
			USE module_parameters
			USE module_helio
			IMPLICIT NONE

			! Arguments
			INTEGER(I4B), INTENT(IN)			:: ntp
			TYPE(helio_tp), INTENT(INOUT)		:: helio_tpA

			ALLOCATE(helio_tpA%ah(NDIM,ntp))
         	ALLOCATE(helio_tpA%ahi(NDIM,ntp))
         	CALL swiftest_tp_allocate(helio_tpA%swiftest,ntp)

        	return
        END SUBROUTINE helio_tp_allocate


        SUBROUTINE symba_tp_allocate(symba_tpA, ntp)
			USE module_parameters
			USE module_symba
			IMPLICIT NONE

			! Arguments
			INTEGER(I4B), INTENT(IN)			:: ntp
			TYPE(symba_tp), INTENT(INOUT)		:: symba_tpA

			ALLOCATE(symba_tpA%nplenc(ntp))
			ALLOCATE(symba_tpA%levelg(ntp))
			ALLOCATE(symba_tpA%levelm(ntp))
			return
		END SUBROUTINE symba_tp_allocate

        SUBROUTINE symba_pltpenc_allocate(pltpenc_list, npltpenc)
			USE module_parameters
			USE module_symba
			IMPLICIT NONE

			! Arguments
			INTEGER(I4B), INTENT(IN)				:: npltpenc
			TYPE(symba_pltpenc), INTENT(INOUT)		:: pltpenc_list

			ALLOCATE(pltpenc_list%lvdotr(npltpenc))
			ALLOCATE(pltpenc_list%status(npltpenc))
			ALLOCATE(pltpenc_list%level(npltpenc))
			ALLOCATE(pltpenc_list%idpl(npltpenc))
			ALLOCATE(pltpenc_list%idtp(npltpenc))
			return
		END SUBROUTINE symba_pltpenc_allocate

!___________________________


        SUBROUTINE swiftest_pl_deallocate(swiftest_plA, npl)
			USE module_parameters
			USE module_swiftest
			IMPLICIT NONE

			! Arguments
			INTEGER(I4B), INTENT(IN)			:: npl
			TYPE(swiftest_pl), INTENT(INOUT)	:: swiftest_plA

			DEALLOCATE(swiftest_plA%id(npl))
         	DEALLOCATE(swiftest_plA%status(npl))
         	DEALLOCATE(swiftest_plA%mass(npl))
         	DEALLOCATE(swiftest_plA%radius(npl))
         	DEALLOCATE(swiftest_plA%rhill(npl))
         	DEALLOCATE(swiftest_plA%xh(NDIM,npl))
         	DEALLOCATE(swiftest_plA%vh(NDIM,npl))
         	DEALLOCATE(swiftest_plA%xb(NDIM,npl))
         	DEALLOCATE(swiftest_plA%vb(NDIM,npl))
        	return
        END SUBROUTINE swiftest_pl_deallocate


        SUBROUTINE helio_pl_deallocate(helio_plA, npl)
			USE module_parameters
			USE module_helio
			IMPLICIT NONE

			! Arguments
			INTEGER(I4B), INTENT(IN)			:: npl
			TYPE(helio_pl), INTENT(INOUT)		:: helio_plA

			DEALLOCATE(helio_plA%ah(NDIM,npl))
         	DEALLOCATE(helio_plA%ahi(NDIM,npl))
         	CALL swiftest_pl_deallocate(helio_plA%swiftest,npl)
        	return
        END SUBROUTINE helio_pl_deallocate


        SUBROUTINE symba_pl_deallocate(symba_plA, npl)
			USE module_parameters
			USE module_symba
			IMPLICIT NONE

			! Arguments
			INTEGER(I4B), INTENT(IN)			:: npl
			TYPE(symba_pl), INTENT(INOUT)		:: symba_plA

			DEALLOCATE(symba_plA%lmerged(npl))
			DEALLOCATE(symba_plA%nplenc(npl))
			DEALLOCATE(symba_plA%ntpenc(npl))
			DEALLOCATE(symba_plA%levelg(npl))
			DEALLOCATE(symba_plA%levelm(npl))
			DEALLOCATE(symba_plA%nchild(npl))
			DEALLOCATE(symba_plA%isperi(npl))
			DEALLOCATE(symba_plA%peri(npl))
			DEALLOCATE(symba_plA%atp(npl))
			CALL helio_pl_deallocate(symba_plA%helio,npl)
			return
		END SUBROUTINE symba_pl_deallocate

		SUBROUTINE symba_plplenc_deallocate(plplenc_list, nplplenc)
			USE module_parameters
			USE module_symba
			IMPLICIT NONE

			! Arguments
			INTEGER(I4B), INTENT(IN)				:: nplplenc
			TYPE(symba_plplenc), INTENT(INOUT)		:: plplenc_list

			DEALLOCATE(plplenc_list%lvdotr(nplplenc))
			DEALLOCATE(plplenc_list%status(nplplenc))
			DEALLOCATE(plplenc_list%level(nplplenc))
			DEALLOCATE(plplenc_list%id1(nplplenc))
			DEALLOCATE(plplenc_list%id2(nplplenc))
			return
		END SUBROUTINE symba_plplenc_deallocate

		SUBROUTINE symba_merger_deallocate(mergeadd_list, nmergeadd)
			USE module_parameters
			USE module_symba
			IMPLICIT NONE

			! Arguments
			INTEGER(I4B), INTENT(IN)				:: nmergeadd
			TYPE(symba_merger), INTENT(INOUT)		:: mergeadd_list

			DEALLOCATE(mergeadd_list%id(nmergeadd))
			DEALLOCATE(mergeadd_list%status(nmergeadd))
			DEALLOCATE(mergeadd_list%ncomp(nmergeadd))
			DEALLOCATE(mergeadd_list%xh(NDIM,nmergeadd))
			DEALLOCATE(mergeadd_list%vh(NDIM,nmergeadd))
			DEALLOCATE(mergeadd_list%mass(nmergeadd))
			DEALLOCATE(mergeadd_list%radius(nmergeadd))
			return
		END SUBROUTINE symba_merger_deallocate

		SUBROUTINE swiftest_tp_deallocate(swiftest_tpA, ntp)
			USE module_parameters
			USE module_swiftest
			IMPLICIT NONE

			! Arguments
			INTEGER(I4B), INTENT(IN)			:: ntp
			TYPE(swiftest_tp), INTENT(INOUT)	:: swiftest_tpA

			DEALLOCATE(swiftest_tpA%id(ntp))
         	DEALLOCATE(swiftest_tpA%status(ntp))
         	DEALLOCATE(swiftest_tpA%peri(ntp))
         	DEALLOCATE(swiftest_tpA%atp(ntp))
         	DEALLOCATE(swiftest_tpA%isperi(ntp))
         	DEALLOCATE(swiftest_tpA%xh(NDIM,ntp))
         	DEALLOCATE(swiftest_tpA%vh(NDIM,ntp))
         	DEALLOCATE(swiftest_tpA%xb(NDIM,ntp))
         	DEALLOCATE(swiftest_tpA%vb(NDIM,ntp))
        	return
        END SUBROUTINE swiftest_tp_deallocate


        SUBROUTINE helio_tp_deallocate(helio_tpA, ntp)
			USE module_parameters
			USE module_helio
			IMPLICIT NONE

			! Arguments
			INTEGER(I4B), INTENT(IN)			:: ntp
			TYPE(helio_tp), INTENT(INOUT)		:: helio_tpA

			DEALLOCATE(helio_tpA%ah(NDIM,ntp))
         	DEALLOCATE(helio_tpA%ahi(NDIM,ntp))
         	CALL swiftest_tp_deallocate(helio_tpA%swiftest,ntp)
        	return
        END SUBROUTINE helio_tp_deallocate


        SUBROUTINE symba_tp_deallocate(symba_tpA, ntp)
			USE module_parameters
			USE module_symba
			IMPLICIT NONE

			! Arguments
			INTEGER(I4B), INTENT(IN)			:: ntp
			TYPE(symba_tp), INTENT(INOUT)		:: symba_tpA

			DEALLOCATE(symba_tpA%nplenc(ntp))
			DEALLOCATE(symba_tpA%levelg(ntp))
			DEALLOCATE(symba_tpA%levelm(ntp))
			return
		END SUBROUTINE symba_tp_deallocate

        SUBROUTINE symba_pltpenc_deallocate(pltpenc_list, npltpenc)
			USE module_parameters
			USE module_symba
			IMPLICIT NONE

			! Arguments
			INTEGER(I4B), INTENT(IN)				:: npltpenc
			TYPE(symba_pltpenc), INTENT(INOUT)		:: pltpenc_list

			DEALLOCATE(pltpenc_list%lvdotr(npltpenc))
			DEALLOCATE(pltpenc_list%status(npltpenc))
			DEALLOCATE(pltpenc_list%level(npltpenc))
			DEALLOCATE(pltpenc_list%idpl(npltpenc))
			DEALLOCATE(pltpenc_list%idtp(npltpenc))
			return
		END SUBROUTINE symba_pltpenc_deallocate
		
END MODULE module_swiftestalloc




