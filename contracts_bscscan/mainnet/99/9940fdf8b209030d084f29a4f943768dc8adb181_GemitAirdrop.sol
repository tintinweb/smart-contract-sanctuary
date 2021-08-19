/**
 *Submitted for verification at BscScan.com on 2021-08-19
*/

// https://bscscan.com/address/0xec7ef713bcbea7179b2e7dbc88cb929fa17915a5#code

/**
 *Submitted for verification at BscScan.com on 2021-04-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface IERC20 {

    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


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
contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

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

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = now + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(now > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}


contract GemitAirdrop is Ownable {
  struct User {
    bool registered;

    bool isRejectedST2;

    uint256 balanceST1;
    uint256 balanceST2;
  }

  IERC20 public rewardsToken;

  bool isAirdropLive = false;
  bool isST2 = false;

  mapping (address => User) public users;
  event Withdraw(address user, uint256 amount);

  constructor(address _rewardsToken) public {
    rewardsToken = IERC20(_rewardsToken);
  }

  function register(address wallet, uint256 balanceST1, uint256 balanceST2) public onlyOwner {
    if(!users[wallet].registered){
          users[wallet].balanceST1 = balanceST1;
          users[wallet].balanceST2 = balanceST2;
          
          users[wallet].isRejectedST2 = false;

          users[wallet].registered = true;
    }
  }

  function registerMany(uint256 balance, address[] memory wallets) public onlyOwner {
    for (uint256 index = 0; index < wallets.length; index++) {
        address wallet = wallets[index];
        
        uint256 balanceST1 = balance / 4;
        uint256 balanceST2 = balance - balanceST1;

        register(wallet, balanceST1, balanceST2);
    }
  }

  function updateBalance(uint256 balanceST1, uint256 balanceST2, address[] memory wallets) public onlyOwner {
      for (uint256 index = 0; index < wallets.length; index++) {
        address wallet = wallets[index];
        
      if(users[wallet].registered){
          users[wallet].balanceST1 = balanceST1;
          users[wallet].balanceST2 = balanceST2;
      }
    }
  }

    function rejectFromST2(address[] memory wallets) public onlyOwner {
      for (uint256 index = 0; index < wallets.length; index++) {
        address wallet = wallets[index];
        
      if(users[wallet].registered){
          users[wallet].isRejectedST2 = true;
      }
    }
  }

  function toggleAirdrop(bool isLive) public onlyOwner {
      isAirdropLive = isLive;
  }

  function balanceOf(address user) public view returns (uint256) {
    return users[user].balanceST1 + users[user].balanceST2;
  }

  function isRejectedST2(address user) public view returns (bool) {
    return users[user].isRejectedST2;
  }

  function availabeBalance() public view returns (uint256) {
    return IERC20(rewardsToken).balanceOf(address(this));
  }

  function withdraw() external {
    User storage user = users[msg.sender];
    require(isAirdropLive, "Airdrop is not live");

    uint256 amount;

    if(isST2){
        require(!user.isRejectedST2, "Rejected from second part of airdrop");
        require(user.balanceST2 > 0, "Withdraw amount exceeds allowance");

        amount = user.balanceST2;

        require(IERC20(rewardsToken).transfer(msg.sender, amount * 10**9), 'Withdraw transfer failed');
        user.balanceST2 -= amount;
    }
    else{
        require(user.balanceST1 > 0, "Withdraw amount exceeds allowance");

        amount = user.balanceST1;

        require(IERC20(rewardsToken).transfer(msg.sender, amount * 10**9), 'Withdraw transfer failed');
        user.balanceST1 -= amount;
    }

    emit Withdraw(msg.sender, amount * 10**9);
  }

  function endAirdrop() public onlyOwner {
    isAirdropLive = false;
    require(IERC20(rewardsToken).transfer(msg.sender, IERC20(rewardsToken).balanceOf(address(this))), 'Withdraw transfer failed');
  }

  // Recover any ERC20 token from contract address
  function recoverERC20(address tokenAddress, uint256 tokenAmount) public virtual onlyOwner {
      IERC20(tokenAddress).transfer(owner(), tokenAmount);
  }

  // Recover BNB from contract balance
  function extractBNB() external onlyOwner {
      address payable _owner = payable(_msgSender());
      _owner.transfer(address(this).balance);
  }
}