!! Copyright 2022 - David Minton, Carlisle Wishard, Jennifer Pouplin, Jake Elliott, & Dana Singh
!! This file is part of Swiftest.
!! Swiftest is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License 
!! as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
!! Swiftest is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty 
!! of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
!! You should have received a copy of the GNU General Public License along with Swiftest. 
!! If not, see: https://www.gnu.org/licenses. 


module collision
   !! author: The Purdue Swiftest Team - David A. Minton, Carlisle A. Wishard, Jennifer L.L. Pouplin, and Jacob R. Elliott
   !!
   !! Definition of classes and methods used to determine close encounters
   use globals
   use base
   use encounter
   implicit none
   public

   !>Symbolic names for collisional outcomes from collresolve_resolve:
   integer(I4B), parameter :: COLLRESOLVE_REGIME_MERGE              =  1
   integer(I4B), parameter :: COLLRESOLVE_REGIME_DISRUPTION         =  2
   integer(I4B), parameter :: COLLRESOLVE_REGIME_SUPERCATASTROPHIC  =  3
   integer(I4B), parameter :: COLLRESOLVE_REGIME_GRAZE_AND_MERGE    =  4
   integer(I4B), parameter :: COLLRESOLVE_REGIME_HIT_AND_RUN        =  5
   character(len=*),dimension(5), parameter :: REGIME_NAMES = ["Merge", "Disruption", "Supercatastrophic", "Graze and Merge", "Hit and Run"] 

   !> Swiftest class for tracking pl-pl close encounters in a step when collisions are possible
   type, extends(encounter_list) :: collision_list_plpl
   contains
      procedure :: extract_collisions => collision_resolve_extract_plpl      !! Processes the pl-pl encounter list remove only those encounters that led to a collision
      procedure :: collision_check    => collision_check_plpl                !! Checks if a test particle is going to collide with a massive body
      procedure :: resolve_collision  => collision_resolve_plpl              !! Process the pl-pl collision list, then modifiy the massive bodies based on the outcome of the collision
   end type collision_list_plpl


   !> Class for tracking pl-tp close encounters in a step when collisions are possible
   type, extends(encounter_list) :: collision_list_pltp
   contains
      procedure :: extract_collisions => collision_resolve_extract_pltp !! Processes the pl-tp encounter list remove only those encounters that led to a collision
      procedure :: collision_check    => collision_check_pltp           !! Checks if a test particle is going to collide with a massive body
      procedure :: resolve_collision  => collision_resolve_pltp         !! Process the pl-tp collision list
   end type collision_list_pltp


   !> Class definition for the variables that describe the bodies involved in the collision
   type, extends(base_object) :: collision_impactors
      integer(I4B)                                 :: ncoll     !! Number of bodies involved in the collision
      integer(I4B), dimension(:),      allocatable :: id       !! Index of bodies involved in the collision
      real(DP),     dimension(NDIM,2)              :: rb        !! Two-body equivalent position vectors of the collider bodies prior to collision
      real(DP),     dimension(NDIM,2)              :: vb        !! Two-body equivalent velocity vectors of the collider bodies prior to collision
      real(DP),     dimension(NDIM,2)              :: rot       !! Two-body equivalent principal axes moments of inertia the collider bodies prior to collision
      real(DP),     dimension(NDIM,2)              :: Lspin     !! Two-body equivalent spin angular momentum vectors of the collider bodies prior to collision
      real(DP),     dimension(NDIM,2)              :: Lorbit    !! Two-body equivalent orbital angular momentum vectors of the collider bodies prior to collision
      real(DP),     dimension(NDIM,2)              :: Ip        !! Two-body equivalent principal axes moments of inertia the collider bodies prior to collision
      real(DP),     dimension(2)                   :: mass      !! Two-body equivalent mass of the collider bodies prior to the collision
      real(DP),     dimension(2)                   :: radius    !! Two-body equivalent radii of the collider bodies prior to the collision
      real(DP)                                     :: Qloss     !! Energy lost during the collision
      integer(I4B)                                 :: regime    !! Collresolve regime code for this collision
      real(DP),     dimension(:),      allocatable :: mass_dist !! Distribution of fragment mass determined by the regime calculation (largest fragment, second largest, and remainder)    
      real(DP)                                     :: Mcb       !! Mass of central body (used to compute potential energy in regime determination)

      ! Values in a coordinate frame centered on the collider barycenter and collisional system unit vectors 
      real(DP), dimension(NDIM) :: x_unit  !! x-direction unit vector of collisional system
      real(DP), dimension(NDIM) :: y_unit  !! y-direction unit vector of collisional system
      real(DP), dimension(NDIM) :: z_unit  !! z-direction unit vector of collisional system
      real(DP), dimension(NDIM) :: v_unit  !! z-direction unit vector of collisional system
      real(DP), dimension(NDIM) :: rbcom   !! Center of mass position vector of the collider system in system barycentric coordinates
      real(DP), dimension(NDIM) :: vbcom   !! Velocity vector of the center of mass of the collider system in system barycentric coordinates
      real(DP), dimension(NDIM) :: rbimp   !! Impact point position vector of the collider system in system barycentric coordinates

   contains
      procedure :: get_regime             => collision_regime_impactors         !! Determine which fragmentation regime the set of impactors will be
      procedure :: reset                  => collision_util_reset_impactors     !! Resets the collider object variables to 0 and deallocates the index and mass distributions
      final     ::                           collision_util_final_impactors     !! Finalizer will deallocate all allocatables
   end type collision_impactors


   !> Class definition for the variables that describe a collection of fragments in barycentric coordinates
   type, extends(base_multibody) :: collision_fragments
      real(DP)                                               :: mtot     !! Total mass of fragments       
      class(base_particle_info), dimension(:),   allocatable :: info     !! Particle metadata information
      integer(I4B),              dimension(nbody)            :: status   !! An integrator-specific status indicator 
      real(DP),                  dimension(NDIM,nbody)       :: rh       !! Heliocentric position
      real(DP),                  dimension(NDIM,nbody)       :: vh       !! Heliocentric velocity
      real(DP),                  dimension(NDIM,nbody)       :: rb       !! Barycentric position
      real(DP),                  dimension(NDIM,nbody)       :: vb       !! Barycentric velocity
      real(DP),                  dimension(NDIM,nbody)       :: rot      !! rotation vectors of fragments
      real(DP),                  dimension(NDIM,nbody)       :: Ip       !! Principal axes moment of inertia for fragments
      real(DP),                  dimension(nbody)            :: mass     !! masses of fragments
      real(DP),                  dimension(nbody)            :: radius   !! Radii  of fragments
      real(DP),                  dimension(nbody)            :: density  !! Radii  of fragments
      real(DP),                  dimension(NDIM,nbody)       :: rc       !! Position vectors in the collision coordinate frame
      real(DP),                  dimension(NDIM,nbody)       :: vc       !! Velocity vectors in the collision coordinate frame
      real(DP),                  dimension(nbody)            :: rmag     !! Array of radial distance magnitudes of individual fragments in the collisional coordinate frame 
      real(DP),                  dimension(nbody)            :: vmag     !! Array of radial distance magnitudes of individual fragments in the collisional coordinate frame 
      real(DP),                  dimension(nbody)            :: rotmag   !! Array of rotation magnitudes of individual fragments 
      real(DP),                  dimension(NDIM,nbody)       :: v_r_unit !! Array of radial direction unit vectors of individual fragments in the collisional coordinate frame
      real(DP),                  dimension(NDIM,nbody)       :: v_t_unit !! Array of tangential direction unit vectors of individual fragments in the collisional coordinate frame
      real(DP),                  dimension(NDIM,nbody)       :: v_n_unit !! Array of normal direction unit vectors of individual fragments in the collisional coordinate frame
   contains
      procedure :: reset => collision_util_reset_fragments !! Deallocates all allocatable arrays and sets everything else to 0
      final     ::          collision_util_final_fragments !! Finalizer deallocates all allocatables
   end type collision_fragments


   type :: collision_system
      !! This class defines a collisional system that stores impactors and fragments. This is written so that various collision models (i.e. Fraggle) could potentially be used
      !! to resolve collision by defining extended types of encounters_impactors and/or encounetr_fragments
      class(collision_fragments(:)), allocatable :: fragments !! Object containing information on the pre-collision system
      class(collision_impactors),    allocatable :: impactors !! Object containing information on the post-collision system
      class(base_nbody_system),      allocatable :: before    !! A snapshot of the subset of the system involved in the collision
      class(base_nbody_system),      allocatable :: after     !! A snapshot of the subset of the system containing products of the collision

      ! For the following variables, index 1 refers to the *entire* n-body system in its pre-collisional state and index 2 refers to the system in its post-collisional state
      real(DP), dimension(NDIM,2) :: Lorbit   !! Before/after orbital angular momentum 
      real(DP), dimension(NDIM,2) :: Lspin    !! Before/after spin angular momentum 
      real(DP), dimension(NDIM,2) :: Ltot     !! Before/after total system angular momentum 
      real(DP), dimension(2)      :: ke_orbit !! Before/after orbital kinetic energy
      real(DP), dimension(2)      :: ke_spin  !! Before/after spin kinetic energy
      real(DP), dimension(2)      :: pe       !! Before/after potential energy
      real(DP), dimension(2)      :: Etot     !! Before/after total system energy
   contains
      procedure :: generate_fragments         => abstract_generate_fragments               !! Generates a system of fragments 
      procedure :: set_mass_dist              => abstract_set_mass_dist                    !! Sets the distribution of mass among the fragments depending on the regime type
      procedure :: setup                      => collision_setup_system                    !! Initializer for the encounter collision system and the before/after snapshots
      procedure :: setup_impactors            => collision_setup_impactors_system          !! Initializer for the impactors for the encounter collision system. Deallocates old impactors before creating new ones
      procedure :: setup_fragments            => collision_setup_fragments_system          !! Initializer for the fragments of the collision system. 
      procedure :: add_fragments              => collision_util_add_fragments_to_system    !! Add fragments to system
      procedure :: construct_temporary_system => collision_util_construct_temporary_system !! Constructs temporary n-body system in order to compute pre- and post-impact energy and momentum
      procedure :: get_energy_and_momentum    => collision_util_get_energy_momentum        !! Calculates total system energy in either the pre-collision outcome state (lbefore = .true.) or the post-collision outcome state (lbefore = .false.)
      procedure :: reset                      => collision_util_reset_system               !! Deallocates all allocatables
      procedure :: set_coordinate_system      => collision_util_set_coordinate_system      !! Sets the coordinate system of the collisional system
      final     ::                               collision_util_final_system               !! Finalizer will deallocate all allocatables
   end type collision_system


   !! NetCDF dimension and variable names for the enounter save object
   type, extends(encounter_io_parameters) :: collision_io_parameters
      integer(I4B)       :: stage_dimid                                    !! ID for the stage dimension
      integer(I4B)       :: stage_varid                                    !! ID for the stage variable  
      character(NAMELEN) :: stage_dimname            = "stage"             !! name of the stage dimension (before/after)
      character(len=6), dimension(2) :: stage_coords = ["before", "after"] !! The stage coordinate labels

      character(NAMELEN) :: event_dimname = "collision" !! Name of collision event dimension
      integer(I4B)       :: event_dimid                 !! ID for the collision event dimension       
      integer(I4B)       :: event_varid                 !! ID for the collision event variable
      integer(I4B)       :: event_dimsize = 0           !! Number of events

      character(NAMELEN) :: Qloss_varname  = "Qloss"   !! name of the energy loss variable
      integer(I4B)       :: Qloss_varid                !! ID for the energy loss variable 
      character(NAMELEN) :: regime_varname = "regime"  !! name of the collision regime variable
      integer(I4B)       :: regime_varid               !! ID for the collision regime variable
   contains
      procedure :: initialize => collision_io_initialize_output !! Initialize a set of parameters used to identify a NetCDF output object
   end type collision_io_parameters


   type, extends(encounter_snapshot)  :: collision_snapshot
      logical                         :: lcollision !! Indicates that this snapshot contains at least one collision
      class(collision_system), allocatable :: collision_system  !! impactors object at this snapshot
   contains
      procedure :: write_frame => collision_io_write_frame_snapshot    !! Writes a frame of encounter data to file 
      procedure :: get_idvals  => collision_util_get_idvalues_snapshot !! Gets an array of all id values saved in this snapshot
      final     ::                collision_util_final_snapshot        !! Finalizer deallocates all allocatables
   end type collision_snapshot


   !> A class that that is used to store simulation history data between file output
   type, extends(encounter_storage) :: collision_storage
   contains
      procedure :: dump           => collision_io_dump            !! Dumps contents of encounter history to file
      procedure :: take_snapshot  => collision_util_snapshot      !! Take a minimal snapshot of the system through an encounter
      procedure :: make_index_map => collision_util_index_map     !! Maps body id values to storage index values so we don't have to use unlimited dimensions for id
      final     ::                   collision_util_final_storage !! Finalizer deallocates all allocatables
   end type collision_storage


   abstract interface 
      subroutine abstract_generate_fragments(self, system, param, lfailure)
         import collision_system, base_nbody_system, base_parameters
         implicit none
         class(collision_system),  intent(inout) :: self      !! Collision system object 
         class(base_nbody_system), intent(inout) :: system    !! Swiftest nbody system object
         class(base_parameters),   intent(inout) :: param     !! Current run configuration parameters 
         logical,                  intent(out)   :: lfailure  !! Answers the question: Should this have been a merger instead?
      end subroutine abstract_generate_fragments

      subroutine abstract_set_mass_dist(self, param)
         import collision_system, base_parameters
         implicit none
         class(collision_system), intent(inout) :: self  !! Collision system object
         class(base_parameters),  intent(in)    :: param !! Current Swiftest run configuration parameters
      end subroutine abstract_set_mass_dist
   end interface


   interface
      module subroutine collision_io_dump(self, param)
         implicit none
         class(collision_storage(*)), intent(inout) :: self  !! Collision storage object
         class(base_parameters),      intent(inout) :: param !! Current run configuration parameters 
      end subroutine collision_io_dump

      module subroutine collision_io_initialize_output(self, param)
         implicit none
         class(collision_io_parameters), intent(inout) :: self  !! Parameters used to identify a particular NetCDF dataset
         class(base_parameters),   intent(in)    :: param !! Current run configuration parameters  
      end subroutine collision_io_initialize_output

      module subroutine collision_io_write_frame_snapshot(self, history, param)
         implicit none
         class(collision_snapshot),   intent(in)    :: self    !! Swiftest encounter structure
         class(encounter_storage(*)), intent(inout) :: history !! Collision history object
         class(base_parameters),      intent(inout) :: param   !! Current run configuration parameters
      end subroutine collision_io_write_frame_snapshot

      module subroutine collision_regime_impactors(self, system, param)
         implicit none 
         class(collision_impactors), intent(inout) :: self   !! Collision system impactors object
         class(base_nbody_system),   intent(in)    :: system !! Swiftest nbody system object
         class(base_parameters),     intent(in)    :: param  !! Current Swiftest run configuration parameters
      end subroutine collision_regime_impactors

      module subroutine collision_check_plpl(self, system, param, t, dt, irec, lany_collision)
         implicit none
         class(collision_list_plpl), intent(inout) :: self           !!  encounter list object
         class(base_nbody_system),   intent(inout) :: system         !! SyMBA nbody system object
         class(base_parameters),     intent(inout) :: param          !! Current run configuration parameters 
         real(DP),                   intent(in)    :: t              !! current time
         real(DP),                   intent(in)    :: dt             !! step size
         integer(I4B),               intent(in)    :: irec           !! Current recursion level
         logical,                    intent(out)   :: lany_collision !! Returns true if any pair of encounters resulted in a collision 
      end subroutine collision_check_plpl

      module subroutine collision_check_pltp(self, system, param, t, dt, irec, lany_collision)
         implicit none
         class(collision_list_pltp), intent(inout) :: self           !!  encounter list object
         class(base_nbody_system),   intent(inout) :: system         !! SyMBA nbody system object
         class(base_parameters),     intent(inout) :: param          !! Current run configuration parameters 
         real(DP),                   intent(in)    :: t              !! current time
         real(DP),                   intent(in)    :: dt             !! step size
         integer(I4B),               intent(in)    :: irec           !! Current recursion level
         logical,                    intent(out)   :: lany_collision !! Returns true if any pair of encounters resulted in a collision 
      end subroutine collision_check_pltp
   
      module subroutine collision_resolve_extract_plpl(self, system, param)
         implicit none
         class(collision_list_plpl), intent(inout) :: self   !! pl-pl encounter list
         class(base_nbody_system),   intent(inout) :: system !! Swiftest nbody system object
         class(base_parameters),     intent(in)    :: param  !! Current run configuration parameters
      end subroutine collision_resolve_extract_plpl

      module subroutine collision_resolve_extract_pltp(self, system, param)
         implicit none
         class(collision_list_pltp), intent(inout) :: self   !! pl-tp encounter list
         class(base_nbody_system),   intent(inout) :: system !! Swiftest nbody system object
         class(base_parameters),     intent(in)    :: param  !! Current run configuration parameters
      end subroutine collision_resolve_extract_pltp

      module subroutine collision_resolve_make_impactors_pl(pl, idx)
         implicit none
         class(base_object),           intent(inout) :: pl  !! Massive body object
         integer(I4B), dimension(:), intent(in)    :: idx !! Array holding the indices of the two bodies involved in the collision
      end subroutine collision_resolve_make_impactors_pl

      module function collision_resolve_merge(system, param, t) result(status)
         implicit none
         class(base_nbody_system), intent(inout) :: system !! Swiftest nbody system object
         class(base_parameters),   intent(inout) :: param  !! Current run configuration parameters with SyMBA additions
         real(DP),                 intent(in)    :: t      !! Time of collision
         integer(I4B)                            :: status !! Status flag assigned to this outcome
      end function collision_resolve_merge


      module subroutine collision_resolve_plpl(self, system, param, t, dt, irec)
         implicit none
         class(collision_list_plpl), intent(inout) :: self   !! pl-pl encounter list
         class(base_nbody_system),   intent(inout) :: system !! Swiftest nbody system object
         class(base_parameters),     intent(inout) :: param  !! Current run configuration parameters with Swiftest additions
         real(DP),                   intent(in)    :: t      !! Current simulation time
         real(DP),                   intent(in)    :: dt     !! Current simulation step size
         integer(I4B),               intent(in)    :: irec   !! Current recursion level
      end subroutine collision_resolve_plpl
   
      module subroutine collision_resolve_pltp(self, system, param, t, dt, irec)
         implicit none
         class(collision_list_pltp), intent(inout) :: self   !! pl-tp encounter list
         class(base_nbody_system),   intent(inout) :: system !! Swiftest nbody system object
         class(base_parameters),     intent(inout) :: param  !! Current run configuration parameters with Swiftest additions
         real(DP),                   intent(in)    :: t      !! Current simulation time
         real(DP),                   intent(in)    :: dt     !! Current simulation step size
         integer(I4B),               intent(in)    :: irec   !! Current recursion level
      end subroutine collision_resolve_pltp

      module subroutine collision_util_set_coordinate_system(self)
         implicit none
         class(collision_system), intent(inout) :: self      !! Collisional system
      end subroutine collision_util_set_coordinate_system

      module subroutine collision_setup_system(self, nbody_system)
         implicit none
         class(collision_system),  intent(inout) :: self         !! Encounter collision system object
         class(base_nbody_system), intent(in)    :: nbody_system !! Current nbody system. Used as a mold for the before/after snapshots
      end subroutine collision_setup_system
   
      module subroutine collision_setup_impactors_system(self)
         implicit none
         class(collision_system), intent(inout) :: self   !! Encounter collision system object
      end subroutine collision_setup_impactors_system
   
      module subroutine collision_setup_fragments_system(self, nfrag)
         implicit none
         class(collision_system), intent(inout) :: self  !! Encounter collision system object
         integer(I4B),            intent(in)    :: nfrag !! Number of fragments to create
      end subroutine collision_setup_fragments_system

      module subroutine collision_util_add_fragments_to_system(self, system, param)
         implicit none
         class(collision_system),  intent(in)    :: self      !! Collision system system object
         class(base_nbody_system), intent(inout) :: system    !! Swiftest nbody system object
         class(base_parameters),   intent(in)    :: param     !! Current swiftest run configuration parameters
      end subroutine collision_util_add_fragments_to_system

      module subroutine collision_util_construct_temporary_system(self, nbody_system, param, tmpsys, tmpparam)
         implicit none
         class(collision_system),               intent(inout) :: self         !! Collision system object
         class(base_nbody_system),              intent(in)    :: nbody_system !! Original swiftest nbody system object
         class(base_parameters),                intent(in)    :: param        !! Current swiftest run configuration parameters
         class(base_nbody_system), allocatable, intent(out)   :: tmpsys       !! Output temporary swiftest nbody system object
         class(base_parameters),   allocatable, intent(out)   :: tmpparam     !! Output temporary configuration run parameters
      end subroutine collision_util_construct_temporary_system 

      module subroutine collision_util_reset_fragments(self)
         implicit none
         class(collision_fragments(*)), intent(inout) :: self
      end subroutine collision_util_reset_fragments

      module subroutine collision_util_final_fragments(self)
         implicit none
         type(collision_fragments(*)), intent(inout) :: self
      end subroutine collision_util_final_fragments

      module subroutine collision_util_final_impactors(self)
         implicit none
         type(collision_impactors), intent(inout) :: self !! Collision impactors storage object
      end subroutine collision_util_final_impactors

      module subroutine collision_util_final_storage(self)
         implicit none
         type(collision_storage(*)),  intent(inout) :: self !! Swiftest nbody system object
      end subroutine collision_util_final_storage

      module subroutine collision_util_final_snapshot(self)
         implicit none
         type(collision_snapshot), intent(inout) :: self !! Fraggle storage snapshot object
      end subroutine collision_util_final_snapshot

      module subroutine collision_util_final_system(self)
         implicit none
         type(collision_system), intent(inout) :: self !!  Collision system object
      end subroutine collision_util_final_system

      module subroutine collision_util_get_idvalues_snapshot(self, idvals)
         implicit none
         class(collision_snapshot),               intent(in)  :: self   !! Fraggle snapshot object
         integer(I4B), dimension(:), allocatable, intent(out) :: idvals !! Array of all id values saved in this snapshot
      end subroutine collision_util_get_idvalues_snapshot

      module subroutine collision_util_get_energy_momentum(self, system, param, lbefore)
         use base, only : base_nbody_system, base_parameters
         implicit none
         class(collision_system),  intent(inout) :: self    !! Encounter collision system object
         class(base_nbody_system), intent(inout) :: system  !! Swiftest nbody system object
         class(base_parameters),   intent(inout) :: param   !! Current swiftest run configuration parameters
         logical,                  intent(in)    :: lbefore !! Flag indicating that this the "before" state of the system, with impactors included and fragments excluded or vice versa
      end subroutine collision_util_get_energy_momentum

      module subroutine collision_util_index_map(self)
         implicit none
         class(collision_storage(*)), intent(inout) :: self  !! Collision storage object 
      end subroutine collision_util_index_map

      module subroutine collision_util_reset_impactors(self)
         implicit none
         class(collision_impactors),  intent(inout) :: self !! Collision system object
      end subroutine collision_util_reset_impactors

      module subroutine collision_util_reset_system(self)
         implicit none
         class(collision_system), intent(inout) :: self  !! Collision system object
      end subroutine collision_util_reset_system

      module subroutine collision_util_snapshot(self, param, system, t, arg)
         implicit none
         class(collision_storage(*)), intent(inout)        :: self   !! Swiftest storage object
         class(base_parameters),      intent(inout)        :: param  !! Current run configuration parameters
         class(base_nbody_system),    intent(inout)        :: system !! Swiftest nbody system object to store
         real(DP),                    intent(in), optional :: t      !! Time of snapshot if different from system time
         character(*),                intent(in), optional :: arg    !! "before": takes a snapshot just before the collision. "after" takes the snapshot just after the collision.
      end subroutine collision_util_snapshot
   end interface


end module collision

