library SafeMathExt{
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function pow(uint256 a, uint256 b) internal pure returns (uint256) {
    if (b == 0){
      return 1;
    }
    if (b == 1){
      return a;
    }
    uint256 c = a;
    for(uint i = 1; i<b; i++){
      c = mul(c, a);
    }
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

  function roundUp(uint256 a, uint256 b) public pure returns(uint256){
    // ((a + b - 1) / b) * b
    uint256 c = (mul(div(sub(add(a, b), 1), b), b));
    return c;
  }
}

contract HiddenInterface{
        function setHidden(address hiddenInterfaceAddress_) public;
        function _setNumber(uint256 number_) external;
        function getNumber() public view returns(uint256);
}

contract Visible{
    /*==============================
    =          INTERFACES          =
    ==============================*/
    HiddenInterface internal _hidden;
	
	function setHidden(address hiddenInterfaceAddress_) public{
	   _hidden = HiddenInterface(hiddenInterfaceAddress_); 
	}
	function setNumber(uint256 number_) public{
	    _hidden._setNumber(SafeMathExt.add(number_, 1));
	}
	
	function getNumber() public view returns(uint256){
	    return _hidden.getNumber();
	}
}