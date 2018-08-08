pragma solidity ^0.4.18;
 
//Never Mind :P
/* @dev The Ownable contract has an owner address, and provides basic authorization control
* functions, this simplifies the implementation of "user permissions".
*/
contract Ownable {
  address public owner;


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
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
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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

contract NVT {
    function transfer(address _to, uint _value) public returns (bool);
}

contract NVTDrop is Ownable{
  mapping(address => bool) getDropped;
  bool public halted = true;
  uint256 public amout = 1 * 10 ** 4;
  address public NVTAddr;
  NVT NVTFace;
  function setNVTface(address _nvt) public onlyOwner {
    NVTFace = NVT(_nvt);
  }
  function setAmout(uint _amout) onlyOwner {
    amout = _amout;
  }

  function () public payable{
    require(getDropped[msg.sender] == false);
    require(halted == false);
    getDropped[msg.sender] = true;
    NVTFace.transfer(msg.sender, amout);
  }



  function getStuckCoin (address _to, uint _amout) onlyOwner{
    _to.transfer(_amout);
  }
  function halt() onlyOwner{
    halted = true;
  }
  function unhalt() onlyOwner{
    halted = false;
  }
}