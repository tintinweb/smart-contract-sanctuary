/**
 *Submitted for verification at Etherscan.io on 2020-12-18
*/

pragma solidity >=0.4.22 <0.8.0;

// SPDX-License-Identifier: MIT

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


/**
 * This is the deposit contract
 */
contract deposit is Ownable {
  bool public isDepositAllowed = true;

  // start and end timestamps when investments are allowed  (both inclusive)
  uint256 public startTime =  block.timestamp ; 
  uint256 public duration = 5 days;
  uint256 public endTime;

  mapping (address=> uint256) depositors;

  // amount of money deposited in wei
  uint256 public weiDeposited;

  // address where all funds deposited are stored
  address payable wallet;

  /**
    * event for funds received 
    * @param depositor who deposited value     
    */
  event depositReceived(address indexed depositor,uint256 value);


  constructor (address payable _wallet) public {        
    require(_wallet != address(0));   
    require(startTime >= block.timestamp); 
    endTime = (startTime + duration);    
    wallet = _wallet;
  }

  // This function is called when anyone sends ether to this contract

  receive() external payable {
    require(msg.sender != address(0));                      //Contributor's address should not be zero
    require(msg.value != 0);                                //Contributed  amount should be greater then zero
    require(isDepositAllowed);                              //Check if contracts can receive deposits

    //forward fund received to Platform's account
    forwardFunds();            

    // Add to investments with the investor
    depositors[msg.sender] += msg.value;
    weiDeposited += msg.value;

    //Notify server that an investment has been received
    emit depositReceived(msg.sender,msg.value); 
  }

  // send ether to the fund collection wallet  , this ideally would be an multisig wallet
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

  // Called by owner when preico token cap has been reached
  function updateisDepositAllowed(bool _value) public onlyOwner {
    isDepositAllowed = _value;
  }
}