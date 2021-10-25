pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Vesting.sol";

contract VestingRouter is Ownable, ReentrancyGuard {
    event VestingCreated(address indexed beneficiary, address indexed vestingAddress, uint256 tokenAmount);
    event VestingReleased(address indexed vestingAddress, uint256 amount);
    event VestingRevoked(address indexed vestingAddress);

    struct UserInfo {
        address activeVesting;
        address[] vestingHistory;
    }
   
    IERC20 immutable mxsToken;

    mapping(address => UserInfo) userVesting;
   
    constructor(address _token) {
        mxsToken = IERC20(_token);
    }
   
    function createVesting(address _beneficiary, uint256 _tokenAmount, uint256 _duration, uint256 _cliff, bool _revokable) external onlyOwner nonReentrant {
        require(userVesting[_beneficiary].activeVesting == address(0), "Address already has an active vesting contract");
        Vesting vestingContract = new Vesting(_beneficiary, block.timestamp, _cliff, _duration, _revokable, _tokenAmount, address(mxsToken));
        bool transferred = mxsToken.transfer(address(vestingContract), _tokenAmount);
        require(transferred, "Token transfer failed");
        userVesting[_beneficiary].activeVesting = address(vestingContract);
        userVesting[_beneficiary].vestingHistory.push(address(vestingContract));

        emit VestingCreated(_beneficiary, address(vestingContract), _tokenAmount);
    }
   
    function userInfo(address account) external view returns(address activeVesting, address[] memory vestingHistory) {
        UserInfo memory _userInfo = userVesting[account];
        return(_userInfo.activeVesting, _userInfo.vestingHistory);
    }
   
    function userVestingInfo(address _account) external view returns(
        address vestingAddress,
        uint256 releasedAmount,
        uint256 releasableAmount,
        uint256 vestedAmount,
        uint256 allocation,
        uint256 reflectionsReceived,
        uint256 timeRemaining,
        bool complete
    ) {
        return vestingInfo(userVesting[_account].activeVesting);
    }
   
    function vestingInfo(address _vestingAddress) public view returns (
        address vestingAddress,
        uint256 releasedAmount,
        uint256 releasableAmount,
        uint256 vestedAmount,
        uint256 allocation,
        uint256 reflectionsReceived,
        uint256 timeRemaining,
        bool complete
    ) {
        Vesting vestingContract = Vesting(_vestingAddress);
        vestingAddress = _vestingAddress;
        releasedAmount = vestingContract.released();
        releasableAmount = vestingContract.releasableAmount();
        vestedAmount = vestingContract.vestedAmount();
        allocation = vestingContract.initialAllocation();
        reflectionsReceived = vestingContract.reflections();
        timeRemaining = vestingContract.timeRemaining();
        complete = vestingContract.complete();
    }
   
    function revoke(address _vestingAddress) external onlyOwner {
        Vesting vestingContract = Vesting(_vestingAddress);
        require(address(vestingContract) != address(0), "Cannot release an invalid address");
        require(!vestingContract.complete(), "Vesting is already complete");
       
        vestingContract.revoke();
        userVesting[vestingContract.beneficiary()].activeVesting = address(0);
        emit VestingRevoked(_vestingAddress);
    }
   
    function release(address _vestingAddress) external {
        Vesting vestingContract = Vesting(_vestingAddress);
        require(address(vestingContract) != address(0), "Cannot release an invalid address");
        require(!vestingContract.complete(), "Vesting is already complete");
        require(vestingContract.beneficiary() == msg.sender, "Sender must be beneficiary");

        uint256 tokenAmount = vestingContract.release();
       
        if (vestingContract.complete()) {
            userVesting[vestingContract.beneficiary()].activeVesting = address(0);
        }
        emit VestingReleased(_vestingAddress, tokenAmount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
* @title TokenVesting
* @dev A token holder contract that can release its token balance gradually like a
* typical vesting scheme, with a cliff and vesting period. Optionally revocable by the
* owner.
*/
contract Vesting is Ownable, ReentrancyGuard {

  event Released(uint256 amount);
  event Revoked();

  // beneficiary of tokens after they are released
  address public immutable beneficiary;

  uint256 public immutable cliff;
  uint256 public immutable start;
  uint256 public immutable duration;
  uint256 public immutable initialAllocation;
 
  bool public immutable revokable;
  bool public revoked;
  bool public complete;

  uint256 public released;
  IERC20 public mxsToken;

  /**
   * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
   * _beneficiary, gradually in a linear fashion until _start + _duration. By then all
   * of the balance will have vested.
   * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
   * @param _cliff duration in seconds of the cliff in which tokens will begin to vest
   * @param _duration duration in seconds of the period in which the tokens will vest
   * @param _revokable whether the vesting is revocable or not
   ** @param _initialAllocation the initial allocation of tokens, used to find reflections
   */
  constructor(
    address _beneficiary,
    uint256 _start,
    uint256 _cliff,
    uint256 _duration,
    bool    _revokable,
    uint256 _initialAllocation,
    address _mxsToken
  ) {
    require(_beneficiary != address(0), "The beneficiary address is zero address");
    require(_cliff <= _duration, "The cliff is larger than duration");
   
    beneficiary = _beneficiary;
    start       = _start;
    cliff       = _start + _cliff;
    duration    = _duration;
    revokable   = _revokable;
    initialAllocation = _initialAllocation;
    mxsToken = IERC20(_mxsToken);

    bool approved = mxsToken.approve( owner(), type(uint256).max);
    require(approved, "Transfer token failed");
  }

  /**
   * @notice Transfers vested tokens to beneficiary.
   */
  function release() onlyOwner external returns(uint256 tokenAmount) {
    require(block.timestamp >= cliff, "Cliff has not been reached yet");
    tokenAmount = _releaseTo(beneficiary);
  }

  /**
   * @notice Transfers vested tokens to beneficiary.
   */
  function _releaseTo(address target) internal nonReentrant returns(uint256) {
    uint256 unreleased = releasableAmount();
    released = released + unreleased;
    
    bool transferred = mxsToken.transfer(target, unreleased);
    require(transferred, "Transfer token failed");

    if (mxsToken.balanceOf(address(this)) == 0) {
        complete = true;
    }
    emit Released(released);
    return(unreleased);
  }

  /**
   * @notice Allows the owner to revoke the vesting. Tokens already vested are sent to the beneficiary.
   */
  function revoke() onlyOwner external nonReentrant {
    require(revokable, "It's not revokable");
    require(!revoked, "It's already revoked");

    // Release all vested tokens
    _releaseTo(beneficiary);

    // Send the remainder to the owner
    bool transferred = mxsToken.transfer(owner(), mxsToken.balanceOf(address(this)));
    require(transferred, "Transfer token failed");

    revoked = true;
    complete = true;
    emit Revoked();
  }


  /**
   * @dev Calculates the amount that has already vested but hasn't been released yet.
   */
  function releasableAmount() public view returns (uint256) {
    return vestedAmount() - released;
  }

  /**
   * @dev Calculates the amount that has already vested.
   */
  function vestedAmount() public view returns (uint256) {
    if (block.timestamp < cliff) {
      return 0;
    } else if (block.timestamp >= start + duration || revoked) {
      uint256 vested = mxsToken.balanceOf(address(this)) + released;
      // vesting is complete, allocate all tokens
      return vested;
    } else {
      uint256 vested = initialAllocation * (block.timestamp - start) / duration;
      return vested;
    }
  }
 
    /**
   * @dev Calculates the amount of reflections the vesting contract has received.
   */
  function reflections() external view returns (uint256) {
    return mxsToken.balanceOf(address(this)) + released - initialAllocation;
  }

    /**
   * @dev Calculates the amount of time remaining in seconds.
   */
  function timeRemaining() external view returns (uint256) {
      return start + duration - block.timestamp;
  }
 
  /**
   * @notice Allow withdrawing any token other than the relevant one
   */
  function releaseForeignToken(IERC20 _token, uint256 amount) external onlyOwner {
    require(_token != mxsToken, "The token is mxsToken");
    bool transferred = _token.transfer(owner(), amount);
    require(transferred, "Transfer token failed");
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}