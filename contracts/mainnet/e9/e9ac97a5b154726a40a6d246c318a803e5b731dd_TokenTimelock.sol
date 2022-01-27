/**
 *Submitted for verification at Etherscan.io on 2022-01-25
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
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
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract ERC20
{
  function balanceOf(address account) public view virtual returns (uint256) {
    account;
    return 0;
  }
  function transfer(address recipient, uint256 amount) public virtual returns (bool) {
    recipient;
    amount;
    return true;
  }
}

contract TokenTimelock is Ownable {
  ERC20 public token = ERC20(0xE2d393a1b629D0b034F8e9976ED354f43718b31C);
  uint public ENTRY_PRICE = 0.5 ether;
  uint public INITIAL_UNLOCK_AMOUNT = 10 ether;
  uint public AMOUNT_PER_UNLOCK = 5 ether;
  uint public UNLOCK_COUNT = 4;

  mapping(uint8 => uint256) public unlock_time;
  mapping(address => bool) public is_beneficiary;
  mapping(address => mapping(uint => bool)) public beneficiary_has_claimed;

  mapping(uint => address) public initial_token_unlock_addresses;
  uint public initial_token_unlock_addresses_count;

  mapping(address => bool) public whitelist;

  // Public functions
  
  function claim(uint8 unlock_number) public {
    require(unlock_number < UNLOCK_COUNT, "Must be below unlock count.");
    require(block.timestamp >= unlock_time[unlock_number], "Must have reached unlock time.");
    require(is_beneficiary[msg.sender], "Beneficiary must be beneficiary.");
    require(beneficiary_has_claimed[msg.sender][unlock_number] == false, "Beneficiary should not have claimed.");
    require(whitelist[msg.sender],"Sender must be whitelisted");

    beneficiary_has_claimed[msg.sender][unlock_number] = true;

    token.transfer(msg.sender, AMOUNT_PER_UNLOCK);
  }

  function buy() public payable
  {
    require(whitelist[msg.sender], "You must be whitelisted.");
    require(!is_beneficiary[msg.sender], "You already are a beneficiary.");
    require(msg.value == ENTRY_PRICE, "Must pay the entry price.");
    
    initial_token_unlock_addresses[initial_token_unlock_addresses_count] = msg.sender;
    initial_token_unlock_addresses_count += 1;

    is_beneficiary[msg.sender] = true;
  }

  // Admin functions

  function releaseInitialUnlockAmount() public onlyOwner
  {
    for(uint i; i < initial_token_unlock_addresses_count; i++)
    {
      if(is_beneficiary[initial_token_unlock_addresses[i]])
      {
        token.transfer(initial_token_unlock_addresses[i], INITIAL_UNLOCK_AMOUNT);
      }
    }
    INITIAL_UNLOCK_AMOUNT = 0;
  }

  function setEntryPrice(uint entry_price) public onlyOwner
  {
    ENTRY_PRICE = entry_price;
  }

  function setInitialUnlockAmount(uint initial_unlock_amount) public onlyOwner
  {
    INITIAL_UNLOCK_AMOUNT = initial_unlock_amount;
  }

  function setAmountPerUnlock(uint amount_per_unlock) public onlyOwner
  {
    AMOUNT_PER_UNLOCK = amount_per_unlock;
  }

  function setUnlockCount(uint unlock_count) public onlyOwner
  {
    UNLOCK_COUNT = unlock_count;
  }

  function setUnlockTimes(uint[] memory unlock_times) public onlyOwner
  {
    setUnlockCount(unlock_times.length);
    for(uint8 i; i<unlock_times.length; i++)
    {
      unlock_time[i] = unlock_times[i];
    }
  }

  function editWhitelist(address[] memory addresses, bool value) public onlyOwner
  {
    for(uint i; i < addresses.length; i++){
      whitelist[addresses[i]] = value;
    }
  }

  function revokeBeneficiary(address beneficiary) public onlyOwner
  {
    whitelist[beneficiary] = false;
    is_beneficiary[beneficiary] = false;
  }

  function withdrawETH() public onlyOwner
  {
    (bool sent, bytes memory data) = address(owner()).call{value: address(this).balance}("");
    require(sent, "Failed to send Ether");
    data;
  }

  function withdrawTokens() public onlyOwner
  {
    token.transfer(address(owner()), token.balanceOf(address(this)));
  }
}