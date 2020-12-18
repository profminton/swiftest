submodule(rmvs_classes) rmvs_step
contains
   module procedure rmvs_step_system
      !! author: David A. Minton
      !!
      !! Step massive bodies and and active test particles ahead in heliocentric coordinates
      !! 
      !! Adapted from Hal Levison's Swift routine rmvs3_step.f
      !! Adapted from David E. Kaufmann's Swifter routine rmvs_step.f90
      use swiftest
      implicit none
      logical, save :: lfirst = .true.
      logical :: lencounter
      real(DP) :: rts
      real(DP), dimension(:,:), allocatable :: xbeg, vbeg, xend
 
      associate(ntp => tp%nbody, npl => pl%nbody, t => config%t, dt => config%dt, &
         xh => pl%xh, vh => pl%vh, xj => pl%xj, vj => pl%vj, ah => pl%ah,  eta => pl%eta, & ! These two lines of associations aid in debugging with gdb
         xht => tp%xh, vht => tp%vh, aht => tp%ah, irij3 => tp%irij3) 

         ! ****** Check for close encounters ***** !
         allocate(xbeg, source=pl%xh)
         allocate(vbeg, source=pl%vh)
         rts = RHSCALE
         lencounter = rmvs_chk(pl, tp, xbeg, vbeg, dt, rts)
         call whm_step_system(cb, pl, tp, config)

      end associate

   end procedure rmvs_step_system 

end submodule rmvs_step
