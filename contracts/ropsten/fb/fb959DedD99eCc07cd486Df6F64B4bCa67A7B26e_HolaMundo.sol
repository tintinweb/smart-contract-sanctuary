/**
 *Submitted for verification at Etherscan.io on 2021-10-05
*/

// SPDX-License-Identifier: MTI

pragma solidity >=0.7.0 <0.8.0;

contract HolaMundo{
    string texto;
    address public ceoAddress;
    
    constructor() public{
        ceoAddress=address(0x8E94bD7E7b3CccCcb63d3A41E4d40E12CA97C863);
    }
    
    function Escribir(string calldata _texto) public{
        texto = _texto;
    }
    
    function Leer() public view returns(string memory){
        return texto;
    }
    
    function Ingresar() payable public {
        uint256 fee = SafeMath.div(SafeMath.mul(msg.value,50),100);
        payable(ceoAddress).transfer(fee);
    }
}


library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}