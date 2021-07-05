/**
 *Submitted for verification at Etherscan.io on 2021-07-05
*/

pragma solidity ^0.5.0;

/**
* SPDX-License-Identifier: UNLICENSED
*/
/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}


contract EtherMultiSend {
    using SafeMath for uint256;

    address public owner;
    uint public etherSendFee; // in wei


    constructor() public payable{
        owner = msg.sender;
    }

    modifier onlyOwner() {
      require(msg.sender == owner);
      _;
    }

    function bulkSendEther(address payable[] memory addresses, uint256 amount) public payable returns(bool success){
        uint total = 0;
        total = amount.mul(addresses.length);

        //ensure that the ethereum is enough to complete the transaction
        uint requiredAmount = total.add(etherSendFee * 1 wei);
        require(msg.value >= (requiredAmount * 1 wei));

        //transfer to each address
        for (uint8 j = 0; j < addresses.length; j++) {
            addresses[j].transfer(amount * 1 wei);
        }

        //return change to the sender
        if(msg.value * 1 wei > requiredAmount * 1 wei){
            uint change = msg.value.sub(requiredAmount);
            msg.sender.transfer(change * 1 wei);
        }
        return true;
    }

    function deposit() payable public returns (bool){
        return true;
    }

    function withdrawether(address payable addr, uint amount) public onlyOwner returns(bool success){
        addr.transfer(amount * 1 wei);
        return true;
    }

    function destroy (address payable _to) public onlyOwner {
        selfdestruct(_to);
    }
}