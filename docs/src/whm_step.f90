submodule(whm_classes) s_whm_step
   use swiftest
contains

   module subroutine whm_step_system(self, param, t, dt)
      !! author: David A. Minton
      !!
      !! Step massive bodies and and active test particles ahead in heliocentric coordinates
      !! 
      !! Adapted from Hal Levison's Swift routine step_kdk.f
      !! Adapted from David E. Kaufmann's Swifter routine whm_step.f90
      implicit none
      ! Arguments
      class(whm_nbody_system),    intent(inout) :: self  !! WHM nbody system object
      class(swiftest_parameters), intent(inout) :: param !! Current run configuration parameters 
      real(DP),                   intent(in)    :: t     !! Current simulation time
      real(DP),                   intent(in)    :: dt    !! Current stepsize

      associate(system => self, cb => self%cb, pl => self%pl, tp => self%tp)
         tp%lfirst = pl%lfirst
         call pl%step(system, param, t, dt)
         call tp%step(system, param, t, dt)
         if (param%ltides) call system%step_spin(param, t, dt)
      end associate
      return
   end subroutine whm_step_system 


   module subroutine whm_step_pl(self, system, param, t, dt)
      !! author: David A. Minton
      !!
      !! Step planets ahead using kick-drift-kick algorithm
      !! 
      !! Adapted from Hal Levison's Swift routine step_kdk_pl.f
      !! Adapted from David E. Kaufmann's Swifter routine whm_step_pl.f90
      !logical, save :: lfirst = .true.
      implicit none
      ! Arguments
      class(whm_pl),                intent(inout) :: self   !! WHM massive body particle data structure
      class(swiftest_nbody_system), intent(inout) :: system !! Swiftest system object
      class(swiftest_parameters),   intent(inout) :: param  !! Current run configuration parameters 
      real(DP),                     intent(in)    :: t     !! Current simulation time
      real(DP),                     intent(in)    :: dt    !! Current stepsize
      ! Internals
      real(DP)                                    :: dth
      
      if (self%nbody == 0) return

      associate(pl => self, cb => system%cb)
         dth = 0.5_DP * dt
         call pl%kick(system, param, t, dth,lbeg=.true.)
         call pl%vh2vj(cb) 
         if (param%lgr) call pl%gr_pos_kick(param, dth)
         call pl%drift(system, param, dt)
         if (param%lgr) call pl%gr_pos_kick(param, dth)
         call pl%j2h(cb)
         call pl%kick(system, param, t + dt, dth, lbeg=.false.)
      end associate

      return
   end subroutine whm_step_pl


   module subroutine whm_step_tp(self, system, param, t, dt)
      !! author: David A. Minton
      !!
      !! Step active test particles ahead using kick-drift-kick algorithm
      !! 
      !! Adapted from Hal Levison's Swift routine step_kdk_tp.f
      !! Adapted from David E. Kaufmann's Swifter routine whm_step_tp.f90
      implicit none
      ! Arguments
      class(whm_tp),                intent(inout) :: self   !! WHM test particle data structure
      class(swiftest_nbody_system), intent(inout) :: system !! Swiftest system object
      class(swiftest_parameters),   intent(inout) :: param  !! Current run configuration parameters 
      real(DP),                     intent(in)    :: t     !! Current simulation time
      real(DP),                     intent(in)    :: dt    !! Current stepsize
      ! Internals
      real(DP)                                    :: dth

      if (self%nbody == 0) return

      select type(system)
      class is (whm_nbody_system)
         associate(tp => self, cb => system%cb, pl => system%pl)
            dth = 0.5_DP * dt
            call tp%kick(system, param, t, dth, lbeg=.true.)
            if (param%lgr) call tp%gr_pos_kick(param, dth)
            call tp%drift(system, param, dt)
            if (param%lgr) call tp%gr_pos_kick(param, dth)
            call tp%kick(system, param, t + dt, dth, lbeg=.false.)
         end associate
      end select

      return
   end subroutine whm_step_tp   

end submodule s_whm_step