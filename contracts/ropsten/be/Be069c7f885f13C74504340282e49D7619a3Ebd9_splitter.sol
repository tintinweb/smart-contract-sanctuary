/**
 *Submitted for verification at Etherscan.io on 2021-09-25
*/

pragma solidity ^0.5.0;


library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b > 0);
    return a / b;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract splitter {
    
    uint public contractbalance;
    
    address payable[] twopeople = [0x7875aeF2932cc14b144f5836C046C2B3a44c2ABD,0xf05c849f78b93a839D167B8921c39572050Deefa];
        
    function deposit() public payable {
        contractbalance = SafeMath.add(contractbalance,msg.value);
    }
    
    function _split_() public payable {
        
        uint amount = SafeMath.div(address(this).balance, 2);
        
        contractbalance = SafeMath.sub(contractbalance,address(this).balance);
        
        twopeople[0].transfer(amount);
        twopeople[1].transfer(amount);
    }
    
    
    function() external payable {    }
        

    
}