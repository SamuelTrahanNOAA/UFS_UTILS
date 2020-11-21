!> @file
module utils

 private

 public :: netcdf_err
 public :: error_handler

 contains

 subroutine netcdf_err( err, string )

 use mpi
 use netcdf

 implicit none
 integer, intent(in) :: err
 character(len=*), intent(in) :: string
 character(len=256) :: errmsg
 integer :: ierr

 if( err.EQ.NF90_NOERR )return
 errmsg = NF90_STRERROR(err)
 print*,''
 print*,'FATAL ERROR: ', trim(string), ': ', trim(errmsg)
 print*,'STOP.'
 call mpi_abort(mpi_comm_world, 999, ierr)

 return
 end subroutine netcdf_err

 subroutine error_handler(string, rc)

 use mpi

 implicit none

 character(len=*), intent(in)    :: string

 integer, optional, intent(in)   :: rc

 integer :: ierr

 print*,"- FATAL ERROR: ", string
 if (present(rc)) print*,"- IOSTAT IS: ", rc
 call mpi_abort(mpi_comm_world, 999, ierr)

 end subroutine error_handler

 end module utils
