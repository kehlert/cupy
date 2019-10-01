from cupy.core.core cimport ndarray
from cupy.cuda cimport memory

from libc.stdint cimport intptr_t
from libcpp.pair cimport pair
from libcpp.vector cimport vector


cdef pair[Py_ssize_t, Py_ssize_t] _get_bound(ndarray array):
    cdef Py_ssize_t left = array.data.ptr
    cdef Py_ssize_t right = left
    cdef pair[Py_ssize_t, Py_ssize_t] ret
    cdef vector[Py_ssize_t] shape = array.shape
    cdef vector[Py_ssize_t] strides = array.strides
    cdef int i

    for i in range(array.ndim):
        right += (shape[i] - 1) * strides[i]

    if left > right:
        left, right = right, left

    ret.first = left
    ret.second = right + <Py_ssize_t>array.itemsize
    return ret


cpdef bint may_share_bounds(ndarray a, ndarray b):
    cdef memory.MemoryPointer a_data = a.data
    cdef memory.MemoryPointer b_data = b.data
    cdef pair[Py_ssize_t, Py_ssize_t] a_range, b_range

    if (a_data.device_id != b_data.device_id
            or a_data.mem.ptr != b_data.mem.ptr
            or a.size == 0 or b.size == 0):
        return False

    a_range = _get_bound(a)
    b_range = _get_bound(b)

    return a_range.first < b_range.second and b_range.first < a_range.second
