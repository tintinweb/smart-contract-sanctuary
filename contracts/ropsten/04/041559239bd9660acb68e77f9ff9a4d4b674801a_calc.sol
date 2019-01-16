pragma solidity ^0.4.24;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract calc {
   using SafeMath for int256;
    
    uint256 a;
    uint256 b;
    
    function set(uint256 x , uint256 y ) public{
        a =  x ;
        b =  y ;
    }
    
    function addition() public view returns (uint256 o_sum)
    {
        o_sum = SafeMath.add(a,b);
    }
    
    
    
    function subtraction() public view returns (uint256 o_sub){
        o_sub = SafeMath.sub(a,b);
    }
    
    function multiplication() public view returns (uint256 o_mul){
          o_mul = SafeMath.mul(a,b);
    }
    
    function division() public view returns (uint256 o_div){
        o_div = SafeMath.div(a,b);
    }
    
}