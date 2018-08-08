pragma solidity ^0.4.23;


library StringUtils {
  /// @dev Does a byte-by-byte lexicographical comparison of two strings.
  /// @return a negative number if `_a` is smaller, zero if they are equal
  /// and a positive numbe if `_b` is smaller.
  function compare(string _a, string _b) public pure returns (int) {
    bytes memory a = bytes(_a);
    bytes memory b = bytes(_b);
    uint minLength = a.length;
    if (b.length < minLength) minLength = b.length;
    //@todo unroll the loop into increments of 32 and do full 32 byte comparisons
    for (uint i = 0; i < minLength; i ++)
      if (a[i] < b[i])
        return -1;
      else if (a[i] > b[i])
        return 1;
    if (a.length < b.length)
      return -1;
    else if (a.length > b.length)
      return 1;
    else
      return 0;
  }
  /// @dev Compares two strings and returns true iff they are equal.
  function equal(string _a, string _b) public pure returns (bool) {
    return compare(_a, _b) == 0;
  }
  /// @dev Finds the index of the first occurrence of _needle in _haystack
  function indexOf(string _haystack, string _needle) public pure returns (int) {
   	bytes memory h = bytes(_haystack);
  	bytes memory n = bytes(_needle);
   	if(h.length < 1 || n.length < 1 || (n.length > h.length)) 
      return -1;
    else if(h.length > (2**128 -1)) // since we have to be able to return -1 (if the char isn&#39;t found or input error), this function must return an "int" type with a max length of (2^128 - 1)
      return -1;									
    else {
      uint subindex = 0;
      for (uint i = 0; i < h.length; i ++) {
        if (h[i] == n[0]) { // found the first char of b
    	  subindex = 1;
    	  while(subindex < n.length && (i + subindex) < h.length && h[i + subindex] == n[subindex]) {// search until the chars don&#39;t match or until we reach the end of a or b
    		subindex++;
    	  }	
    	  if(subindex == n.length) 
    		return int(i);
    	}
      }
      return -1;
    }	
  }
}