/**
 *Submitted for verification at BscScan.com on 2021-08-27
*/

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT


pragma solidity >0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
pragma solidity >0.8.0;



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
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
contract YourContract is Ownable {

  event SetPurpose(address sender, string purpose);
  event Deposit(address sender, uint256 amount);
  event Withdraw(address sender, uint256 amount);

  string public purpose = "Efereum DeFi";
  mapping(address => uint) public stakingBalance;
  mapping(address => bool) hasStaked;
  mapping(address => bool) isStaking;
  address[] public stakers;
  bool public isActive = false;
 
  uint256 public TotalBalance =0;
  
  uint256 constant public threshold = 1 ether;
  uint256 public deadline = block.timestamp + 5 minutes;

  function stake() public payable {
    require(msg.value > 0, "Amount cannot be 0");
    stakingBalance[msg.sender] += msg.value;
    TotalBalance +=msg.value;
    emit Deposit(msg.sender, msg.value);
    if(!hasStaked[msg.sender]) {
      stakers.push(msg.sender);
    }
    isStaking[msg.sender] = true;
    hasStaked[msg.sender] = true;
    if(TotalBalance > threshold && timeleft()>0){
      isActive = true;
    }

  }
  function timeleft() public view returns (uint256) {
    if(block.timestamp >= deadline) {
      return 0;
    }
    else return deadline - block.timestamp;
  }

  function withdraw(uint _amount) public {
    require(stakingBalance[msg.sender]>=_amount, "You don't have that much funds");
    require(timeleft()==0, "Deadline has not passed yet");
    stakingBalance[msg.sender] -= _amount;
    payable(msg.sender).transfer(_amount);
    emit Withdraw(msg.sender, _amount);

    
    
  }
}