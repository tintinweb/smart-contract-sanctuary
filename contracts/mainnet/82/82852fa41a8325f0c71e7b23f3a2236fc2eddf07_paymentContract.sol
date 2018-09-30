pragma solidity ^0.4.24;
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
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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

///@title Dremabridge Payment contract
///@author Arq
///@notice Simple payment contract that checks an address for an "Operating Threshold" which is a set balance of ether, the remaining balance to another Address called Cold Storage.

contract paymentContract {

    using SafeMath for uint256;

    address operatingAddress;
    address coldStorage;

    uint public opThreshold;
    
///@author Arq
///@notice Constructor function determines the payment parties and threshold.
///@param _operatingAddress - The Address that will be refilled by payments to this contract.
///@param _coldStorage - The Address of the Cold Storage wallet, where overflow funds are sent.
///@param _threshold - The level to which this contract will replenish the funds in the operatingAddress wallet.
    constructor(address _operatingAddress, address _coldStorage, uint _threshold) public {
        operatingAddress = _operatingAddress;
        coldStorage = _coldStorage;
        opThreshold = _threshold * 1 ether;
    }
///@author Arq
///@notice The Fallback Function that accepts payments.
///@dev Contract can be used as a payment source.
    function () public payable {
        distribute();
    }

    ///@author Arq
    ///@notice Function that sends funds to either Cold Storage, Operating Address, or both based on the Operating Threshold.
    ///@dev opThreshold determines what the balance in the operatingAddress should be, at a minimum.
        function distribute() internal {
            if(operatingAddress.balance < opThreshold) {
                if(address(this).balance < (opThreshold - operatingAddress.balance)){
                    operatingAddress.transfer(address(this).balance);
                } else {
                    operatingAddress.transfer(opThreshold - operatingAddress.balance);
                    coldStorage.transfer(address(this).balance);
                }
            } else {
                coldStorage.transfer(address(this).balance);
            }
        }
}