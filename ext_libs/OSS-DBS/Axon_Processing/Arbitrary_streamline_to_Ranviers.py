# -*- coding: utf-8 -*-
"""
Created on Mon Jun 17 18:33:45 2019

@author: konstantin
"""
import numpy as np

#import math

#from scipy.interpolate import interp1d

def find_nearest(array, value):
    array = np.asarray(array)
    idx = (np.abs(array - value)).argmin()
    return idx,array[idx]


def length(xyz, along=False):                   # from Dipy (https://dipy.org/)
    ''' Euclidean length of track line

    This will give length in mm if tracks are expressed in world coordinates.

    Parameters
    ------------
    xyz : array-like shape (N,3)
       array representing x,y,z of N points in a track
    along : bool, optional
       If True, return array giving cumulative length along track,
       otherwise (default) return scalar giving total length.

    Returns
    ---------
    L : scalar or array shape (N-1,)
       scalar in case of `along` == False, giving total length, array if
       `along` == True, giving cumulative lengths.

    Examples
    ----------
    >>> from dipy.tracking.metrics import length
    >>> xyz = np.array([[1,1,1],[2,3,4],[0,0,0]])
    >>> expected_lens = np.sqrt([1+2**2+3**2, 2**2+3**2+4**2])
    >>> length(xyz) == expected_lens.sum()
    True
    >>> len_along = length(xyz, along=True)
    >>> np.allclose(len_along, expected_lens.cumsum())
    True
    >>> length([])
    0
    >>> length([[1, 2, 3]])
    0
    >>> length([], along=True)
    array([0])
    '''
    xyz = np.asarray(xyz)
    if xyz.shape[0] < 2:
        if along:
            return np.array([0])
        return 0
    dists = np.sqrt((np.diff(xyz, axis=0)**2).sum(axis=1))
    if along:
        return np.cumsum(dists)
    return np.sum(dists)

def length_fiber(streamlines, affine=None):   # from Dipy (https://dipy.org/)
    """
    Calculate the lengths of many streamlines in a bundle.

    Parameters
    ----------
    streamlines : list
        Each item in the list is an array with 3D coordinates of a streamline.
    affine : 4 x 4 array
        An affine transformation to move the fibers by, before computing their
        lengths.

    Returns
    -------
    Iterator object which then computes the length of each
    streamline in the bundle, upon iteration.
    """

    return map(length, streamlines)


def index_for_length(xyz,req_length, along=True): #from Dipy (https://dipy.org/)
    """ find streamline truncation point to match the given length

    Parameters
    ------------
    xyz : array-like shape (N,3)
       array representing x,y,z of N points in a track
    req_length: float
        required length after truncation
    along : bool, optional
       If True, return array giving cumulative length along track,
       otherwise (default) return scalar giving total length.

    Returns
    ---------
    int
        index of the streamline truncation point
    float
        length of the truncated streamline
    """
    xyz = np.asarray(xyz)
    if xyz.shape[0] < 2:
        if along:
            return np.array([0])
        return 0

    dists = np.sqrt((np.diff(xyz, axis=0)**2).sum(axis=1))

    if along:
        cummulated_lengths = np.cumsum(dists)
        idx,value = find_nearest(cummulated_lengths, req_length)
        if value > req_length:
            idx = idx - 1

        return idx, cummulated_lengths[idx]

    return idx, cummulated_lengths[idx]

def resample_streamline_for_Ranvier(streamline_array,estim_axon_length,n_Ranviers):

    """
    Resample arbitrary streamline to equidistantly spaced nodes of Ranvier

    Parameters
    ----------
    streamline_array:: list
        Each item in the list is an array with 3D coordinates of a streamline.
    estim_axon_length: float
        estimated length of axon for this streamline
    n_Ranviers: int
        Number of nodes of Ranviers at the seeded axon

    Returns
    -------
    list, streamline resampled to nodes of Ranvier
    """

    # after this index we cut the streamline (do not mix up with truncation to the actual axon!)
    cut_index, cummulated_length = index_for_length(streamline_array,estim_axon_length)

    # Don't mix up sums and positions. +1 for the last Ranvier node, +1 for the sum, +1 for index
    streamline_array_Ranvier = np.zeros((cut_index+1+1+1,3),float)
    last_segment_length = estim_axon_length - cummulated_length

    # adjust the last segment to match the estimated axon length exactly
    v = streamline_array[cut_index+1+1,:] - streamline_array[cut_index+1,:]
    v_hat = v / (v**2).sum()**0.5
    streamline_array_Ranvier[:cut_index+1+1,:] = streamline_array[:cut_index+1+1,:]
    streamline_array_Ranvier[cut_index+1+1,:] = last_segment_length * v_hat + streamline_array[cut_index+1,:]

    #from dipy.tracking.streamline import set_number_of_points
    from streamlinespeed import set_number_of_points

    streamline_resampled = set_number_of_points(streamline_array_Ranvier, nb_points=n_Ranviers)
    #streamline_resampled =seq_sampling(streamline_array_Ranvier, res=n_Ranviers)

    return streamline_resampled