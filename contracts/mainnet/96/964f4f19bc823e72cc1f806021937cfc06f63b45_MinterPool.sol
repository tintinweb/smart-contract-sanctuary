/**
 *Submitted for verification at Etherscan.io on 2021-11-04
*/

// File: contracts/ownership/Ownable.sol

pragma solidity <6.0 >=0.4.0;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
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
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}
// File: contracts/iotube/MinterPool.sol

pragma solidity <6.0 >=0.4.24;


interface IMintableToken {
    function mint(address, uint256) external returns(bool);
}

contract MinterPool is Ownable {
    function mint(address _token, address _to, uint256 _amount) public onlyOwner returns (bool) {
        return IMintableToken(_token).mint(_to, _amount);
    }
}