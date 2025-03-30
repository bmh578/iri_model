module example_module
    use, intrinsic :: iso_c_binding
    implicit none

    contains
        function add_numbers(a, b) result(c) bind(c, name='add_numbers')
            integer(c_int), value :: a, b
            integer(c_int) :: c
            c = a + b
        end function add_numbers
end module example_module 