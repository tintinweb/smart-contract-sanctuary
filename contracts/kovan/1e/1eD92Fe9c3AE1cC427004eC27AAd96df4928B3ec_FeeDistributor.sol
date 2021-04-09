/**
 *Submitted for verification at Etherscan.io on 2021-04-09
*/

// File: contracts/lib/SafeMath.sol

/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.6.9;


/**
 * @title SafeMath
 * @author DODO Breeder
 *
 * @notice Math operations with safety checks that revert on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "MUL_ERROR");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "DIVIDING_ERROR");
        return a / b;
    }

    function divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 quotient = div(a, b);
        uint256 remainder = a - quotient * b;
        if (remainder > 0) {
            return quotient + 1;
        } else {
            return quotient;
        }
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SUB_ERROR");
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "ADD_ERROR");
        return c;
    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = x / 2 + 1;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}

// File: contracts/lib/DecimalMath.sol



/**
 * @title DecimalMath
 * @author DODO Breeder
 *
 * @notice Functions for fixed point number with 18 decimals
 */
library DecimalMath {
    using SafeMath for uint256;

    uint256 internal constant ONE = 10**18;
    uint256 internal constant ONE2 = 10**36;

    function mulFloor(uint256 target, uint256 d) internal pure returns (uint256) {
        return target.mul(d) / (10**18);
    }

    function mulCeil(uint256 target, uint256 d) internal pure returns (uint256) {
        return target.mul(d).divCeil(10**18);
    }

    function divFloor(uint256 target, uint256 d) internal pure returns (uint256) {
        return target.mul(10**18).div(d);
    }

    function divCeil(uint256 target, uint256 d) internal pure returns (uint256) {
        return target.mul(10**18).divCeil(d);
    }

    function reciprocalFloor(uint256 target) internal pure returns (uint256) {
        return uint256(10**36).div(target);
    }

    function reciprocalCeil(uint256 target) internal pure returns (uint256) {
        return uint256(10**36).divCeil(target);
    }
}

// File: contracts/intf/IERC20.sol

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

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
}

// File: contracts/lib/SafeERC20.sol


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts/lib/Ownable.sol

/**
 * @title Ownable
 * @author DODO Breeder
 *
 * @notice Ownership related functions
 */
contract Ownable {
    address public _OWNER_;
    address public _NEW_OWNER_;

    // ============ Events ============

    event OwnershipTransferPrepared(address indexed previousOwner, address indexed newOwner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // ============ Modifiers ============

    modifier onlyOwner() {
        require(msg.sender == _OWNER_, "NOT_OWNER");
        _;
    }

    // ============ Functions ============

    constructor() internal {
        _OWNER_ = msg.sender;
        emit OwnershipTransferred(address(0), _OWNER_);
    }

    function transferOwnership(address newOwner) external virtual onlyOwner {
        emit OwnershipTransferPrepared(_OWNER_, newOwner);
        _NEW_OWNER_ = newOwner;
    }

    function claimOwnership() external {
        require(msg.sender == _NEW_OWNER_, "INVALID_CLAIM");
        emit OwnershipTransferred(_OWNER_, _NEW_OWNER_);
        _OWNER_ = _NEW_OWNER_;
        _NEW_OWNER_ = address(0);
    }
}

// File: contracts/DODOFee/FeeDistributer.sol



contract FeeDistributor {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // ============ Storage ============

    address public _BASE_TOKEN_;
    address public _QUOTE_TOKEN_;
    uint256 public _BASE_RESERVE_;
    uint256 public _QUOTE_RESERVE_;

    address public _STAKE_VAULT_;
    address public _STAKE_TOKEN_;
    uint256 public _STAKE_RESERVE_;

    uint256 public _BASE_REWARD_RATIO_;
    mapping(address => uint256) internal _USER_BASE_REWARDS_;
    mapping(address => uint256) internal _USER_BASE_PER_SHARE_;
    
    uint256 public _QUOTE_REWARD_RATIO_;
    mapping(address => uint256) internal _USER_QUOTE_REWARDS_;
    mapping(address => uint256) internal _USER_QUOTE_PER_SHARE_;

    mapping(address => uint256) internal _SHARES_;
    
    bool internal _FEE_INITIALIZED_;

    // ============ Event ============
    event Stake(address sender, uint256 amount);
    event UnStake(address sender, uint256 amount);
    event Claim(address sender, uint256 baseAmount, uint256 quoteAmount);

    function init(
      address baseToken,
      address quoteToken,
      address stakeToken
    ) external {
        require(!_FEE_INITIALIZED_, "ALREADY_INITIALIZED");
        _FEE_INITIALIZED_ = true;
        
        _BASE_TOKEN_ = baseToken;
        _QUOTE_TOKEN_ = quoteToken;
        _STAKE_TOKEN_ = stakeToken;
        _STAKE_VAULT_ = address(new StakeVault());
    }

    function stake(address to) external {
      _updateGlobalState();
      _updateUserReward(to);
      uint256 stakeVault = IERC20(_STAKE_TOKEN_).balanceOf(_STAKE_VAULT_);
      uint256 stakeInput = stakeVault.sub(_STAKE_RESERVE_);
      _addShares(stakeInput, to);
      emit Stake(to, stakeInput);
    }

    function claim(address to) external {
      _updateGlobalState();
      _updateUserReward(msg.sender);
      _claim(msg.sender, to);
    }

    function unstake(uint256 amount, address to, bool withClaim) external {
      require(_SHARES_[msg.sender]>=amount, "STAKE BALANCE ONT ENOUGH");
      _updateGlobalState();
      _updateUserReward(msg.sender);

      if (withClaim) {
        _claim(msg.sender, to);
      }

      _removeShares(amount, msg.sender);
      StakeVault(_STAKE_VAULT_).transferOut(_STAKE_TOKEN_, amount, to);
      emit UnStake(msg.sender, amount);
    }

    // ============ Internal  ============

    function _claim(address sender, address to) internal {
      uint256 allBase = _USER_BASE_REWARDS_[sender];
      uint256 allQuote = _USER_QUOTE_REWARDS_[sender];
      IERC20(_BASE_TOKEN_).safeTransfer(to, allBase);
      IERC20(_QUOTE_TOKEN_).safeTransfer(to, allQuote);
      _USER_BASE_REWARDS_[sender] = 0;
      _USER_BASE_REWARDS_[sender] = 0;
      emit Claim(sender, allBase, allQuote);
    }

    function _updateGlobalState() internal {
      uint256 baseInput = IERC20(_BASE_TOKEN_).balanceOf(address(this)).sub(_BASE_RESERVE_);
      uint256 quoteInput = IERC20(_QUOTE_TOKEN_).balanceOf(address(this)).sub(_QUOTE_RESERVE_);
      _BASE_REWARD_RATIO_ = _BASE_REWARD_RATIO_.add(DecimalMath.divFloor(baseInput, _STAKE_RESERVE_));
      _QUOTE_REWARD_RATIO_ = _QUOTE_REWARD_RATIO_.add(DecimalMath.divFloor(quoteInput, _STAKE_RESERVE_));
      _BASE_RESERVE_ = _BASE_RESERVE_.add(baseInput);
      _QUOTE_RESERVE_ = _QUOTE_RESERVE_.add(quoteInput);
    }

    function _updateUserReward(address user) internal {
        _USER_BASE_REWARDS_[user] = DecimalMath.mulFloor(
          _SHARES_[user], 
          _BASE_REWARD_RATIO_.sub(_USER_BASE_PER_SHARE_[user])
        ).add(_USER_BASE_REWARDS_[user]);

        _USER_BASE_PER_SHARE_[user] = _BASE_REWARD_RATIO_;

        _USER_QUOTE_REWARDS_[user] = DecimalMath.mulFloor(
          _SHARES_[user], 
          _QUOTE_REWARD_RATIO_.sub(_USER_QUOTE_PER_SHARE_[user])
        ).add(_USER_QUOTE_REWARDS_[user]);

        _USER_QUOTE_PER_SHARE_[user] = _QUOTE_REWARD_RATIO_;
    }

    function _addShares(uint256 amount, address to) internal {
      _SHARES_[to] = _SHARES_[to].add(amount);
      _STAKE_RESERVE_ = IERC20(_STAKE_TOKEN_).balanceOf(_STAKE_VAULT_);
    }

    function _removeShares(uint256 amount, address from) internal {
      _SHARES_[from] = _SHARES_[from].sub(amount);
      _STAKE_RESERVE_ = IERC20(_STAKE_TOKEN_).balanceOf(_STAKE_VAULT_);
    }
}


contract StakeVault is Ownable {
    using SafeERC20 for IERC20;
    
    function transferOut(
        address token,
        uint256 amount,
        address to
    ) external onlyOwner {
        if (amount > 0) {
            IERC20(token).safeTransfer(to, amount);
        }
    }
}