/*
   ____            __   __        __   _
  / __/__ __ ___  / /_ / /  ___  / /_ (_)__ __
 _\ \ / // // _ \/ __// _ \/ -_)/ __// / \ \ /
/___/ \_, //_//_/\__//_//_/\__/ \__//_/ /_\_\
     /___/

* Synthetix: Unipool.sol
*
* Docs: https://docs.synthetix.io/
*
*
* MIT License
* ===========
*
* Copyright (c) 2020 Synthetix
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/

/// These contracts reward users for adding liquidity to Uniswap https://uniswap.org/
/// These contracts were obtained from Synthetix and added some minor changes.
/// You can find the original contracts here:
/// https://etherscan.io/address/0x48d7f315fedcad332f68aafa017c7c158bc54760#code

pragma solidity 0.5.17;

import "@keep-network/keep-core/contracts/KeepToken.sol";
import "@keep-network/keep-core/contracts/PhasedEscrow.sol";

import "openzeppelin-solidity/contracts/math/Math.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";

contract IRewardDistributionRecipient is Ownable {
    address rewardDistribution;

    function notifyRewardAmount(uint256 reward) external;

    modifier onlyRewardDistribution() {
        require(
            msg.sender == rewardDistribution,
            "Caller is not reward distribution"
        );
        _;
    }

    function setRewardDistribution(address _rewardDistribution)
        external
        onlyOwner
    {
        rewardDistribution = _rewardDistribution;
    }
}

contract LPTokenWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    IERC20 public wrappedToken; // Pairs: KEEP/ETH, TBTC/ETH, KEEP/TBTC

    constructor(IERC20 _wrappedToken) public {
        wrappedToken = _wrappedToken;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function stake(uint256 amount) public {
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        wrappedToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) public {
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        wrappedToken.safeTransfer(msg.sender, amount);
    }
}

contract LPRewards is
    LPTokenWrapper,
    IRewardDistributionRecipient,
    IStakingPoolRewards
{
    IERC20 public keepToken;
    uint256 public constant DURATION = 7 days;

    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    constructor(IERC20 _keepToken, IERC20 _wrappedToken)
        public
        LPTokenWrapper(_wrappedToken)
    {
        keepToken = _keepToken;
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    function exit() external {
        withdraw(balanceOf(msg.sender));
        getReward();
    }

    function notifyRewardAmount(uint256 reward)
        external
        onlyRewardDistribution
        updateReward(address(0))
    {
        keepToken.safeTransferFrom(msg.sender, address(this), reward);

        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(DURATION);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(DURATION);
        }
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(DURATION);
        emit RewardAdded(reward);
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(totalSupply())
            );
    }

    function earned(address account) public view returns (uint256) {
        return
            balanceOf(account)
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(rewards[account]);
    }

    // stake visibility is public as overriding LPTokenWrapper's stake() function
    function stake(uint256 amount) public updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        super.stake(amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        super.withdraw(amount);
        emit Withdrawn(msg.sender, amount);
    }

    function getReward() public updateReward(msg.sender) {
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            rewards[msg.sender] = 0;
            keepToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }
}

/// @title KEEP rewards for TBTC-ETH liquidity pool.
contract LPRewardsTBTCETH is LPRewards {
    constructor(KeepToken keepToken, IERC20 tbtcEthUniswapPair)
        public
        LPRewards(keepToken, tbtcEthUniswapPair)
    {}
}

/// @title KEEP rewards for KEEP-ETH liquidity pool.
contract LPRewardsKEEPETH is LPRewards {
    constructor(KeepToken keepToken, IERC20 keepEthUniswapPair)
        public
        LPRewards(keepToken, keepEthUniswapPair)
    {}
}

/// @title KEEP rewards for KEEP-TBTC liquidity pool.
contract LPRewardsKEEPTBTC is LPRewards {
    constructor(KeepToken keepToken, IERC20 keepTbtcUniswapPair)
        public
        LPRewards(keepToken, keepTbtcUniswapPair)
    {}
}

/// @title KEEP rewards for the tBTC Saddle liquidity pool.
contract LPRewardsTBTCSaddle is LPRewards {
    bool public gated = true;

    constructor(KeepToken keepToken, IERC20 tbtcSaddleLPToken)
        public
        LPRewards(keepToken, tbtcSaddleLPToken)
    {}

    // if the pool is gated, disallow tx's that didn't come from msg.sender.
    function stake(uint256 amount) public {
        require(
            // solium-disable-next-line security/no-tx-origin
            !gated || msg.sender == tx.origin,
            "Only Externally Owned Account can stake"
        );
        super.stake(amount);
    }

    function setGated(bool _gated) public onlyOwner {
        gated = _gated;
    }
}

/// @title KEEP rewards for the tBTC V2 Saddle liquidity pool.
/// @dev LP token: https://etherscan.io/address/0x122Eca07139EB368245A29FB702c9ff11E9693B7
///      Pool: https://saddle.exchange/#/pools/tbtc/deposit
contract LPRewardsTBTCv2Saddle is LPRewardsTBTCSaddle {
    constructor(KeepToken keepToken, IERC20 tbtcV2SaddleLPToken)
        public
        LPRewardsTBTCSaddle(keepToken, tbtcV2SaddleLPToken)
    {}
}

pragma solidity ^0.5.0;

/**
 * @dev Collection of functions related to the address type,
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * > It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

pragma solidity ^0.5.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
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
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
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
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.5.0;

import "./IERC20.sol";

/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * > Note that this information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * `IERC20.balanceOf` and `IERC20.transfer`.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

pragma solidity ^0.5.0;

import "./ERC20.sol";

/**
 * @dev Extension of `ERC20` that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
contract ERC20Burnable is ERC20 {
    /**
     * @dev Destoys `amount` tokens from the caller.
     *
     * See `ERC20._burn`.
     */
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    /**
     * @dev See `ERC20._burnFrom`.
     */
    function burnFrom(address account, uint256 amount) public {
        _burnFrom(account, amount);
    }
}

pragma solidity ^0.5.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the `IERC20` interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using `_mint`.
 * For a generic mechanism see `ERC20Mintable`.
 *
 * *For a detailed writeup see our guide [How to implement supply
 * mechanisms](https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226).*
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an `Approval` event is emitted on calls to `transferFrom`.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard `decreaseAllowance` and `increaseAllowance`
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See `IERC20.approve`.
 */
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See `IERC20.totalSupply`.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See `IERC20.balanceOf`.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See `IERC20.transfer`.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See `IERC20.allowance`.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See `IERC20.approve`.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev See `IERC20.transferFrom`.
     *
     * Emits an `Approval` event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of `ERC20`;
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `value`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to `transfer`, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a `Transfer` event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a `Transfer` event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

     /**
     * @dev Destoys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a `Transfer` event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an `Approval` event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Destoys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See `_burn` and `_approve`.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

pragma solidity 0.5.17;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";

import "./Escrow.sol";

interface IBeneficiaryContract {
    function __escrowSentTokens(uint256 amount) external;
}

/// @title PhasedEscrow
/// @notice A token holder contract allowing contract owner to set beneficiary of
///         tokens held by the contract and allowing the owner to withdraw the
///         tokens to that beneficiary in phases.
contract PhasedEscrow is Ownable {
    using SafeERC20 for IERC20;

    event BeneficiaryUpdated(address beneficiary);
    event TokensWithdrawn(address beneficiary, uint256 amount);

    IERC20 public token;
    IBeneficiaryContract public beneficiary;

    constructor(IERC20 _token) public {
        token = _token;
    }

    /// @notice Sets the provided address as a beneficiary allowing it to
    ///         withdraw all tokens from escrow. This function can be called only
    ///         by escrow owner.
    function setBeneficiary(IBeneficiaryContract _beneficiary)
        external
        onlyOwner
    {
        beneficiary = _beneficiary;
        emit BeneficiaryUpdated(address(beneficiary));
    }

    /// @notice Withdraws the specified number of tokens from escrow to the
    ///         beneficiary. If the beneficiary is not set, or there are
    ///         insufficient tokens in escrow, the function fails.
    function withdraw(uint256 amount) external onlyOwner {
        require(address(beneficiary) != address(0), "Beneficiary not assigned");

        uint256 balance = token.balanceOf(address(this));
        require(amount <= balance, "Not enough tokens for withdrawal");

        token.safeTransfer(address(beneficiary), amount);
        emit TokensWithdrawn(address(beneficiary), amount);

        beneficiary.__escrowSentTokens(amount);
    }

    /// @notice Funds the escrow by transferring all of the approved tokens
    ///         to the escrow.
    function receiveApproval(
        address _from,
        uint256 _value,
        address _token,
        bytes memory
    ) public {
        require(IERC20(_token) == token, "Unsupported token");
        token.safeTransferFrom(_from, address(this), _value);
    }

    /// @notice Withdraws all funds from a non-phased Escrow passed as
    ///         a parameter. For this function to succeed, this PhasedEscrow
    ///         has to be set as a beneficiary of the non-phased Escrow.
    function withdrawFromEscrow(Escrow _escrow) public {
        _escrow.withdraw();
    }
}

/// @title BatchedPhasedEscrow
/// @notice A token holder contract allowing contract owner to approve a set of
///         beneficiaries of tokens held by the contract, to appoint a separate
///         drawee role, and allowing that drawee to withdraw tokens to approved
///         beneficiaries in phases.
contract BatchedPhasedEscrow is Ownable {
    using SafeERC20 for IERC20;

    event BeneficiaryApproved(address beneficiary);
    event TokensWithdrawn(address beneficiary, uint256 amount);
    event DraweeRoleTransferred(address oldDrawee, address newDrawee);

    IERC20 public token;
    address public drawee;
    mapping(address => bool) private approvedBeneficiaries;

    modifier onlyDrawee() {
        require(drawee == msg.sender, "Caller is not the drawee");
        _;
    }

    constructor(IERC20 _token) public {
        token = _token;
        drawee = msg.sender;
    }

    /// @notice Approves the provided address as a beneficiary of tokens held by
    ///         the escrow. Can be called only by escrow owner.
    function approveBeneficiary(IBeneficiaryContract _beneficiary)
        external
        onlyOwner
    {
        address beneficiaryAddress = address(_beneficiary);
        require(
            beneficiaryAddress != address(0),
            "Beneficiary can not be zero address"
        );
        approvedBeneficiaries[beneficiaryAddress] = true;
        emit BeneficiaryApproved(beneficiaryAddress);
    }

    /// @notice Returns `true` if the given address has been approved as a
    ///         beneficiary of the escrow, `false` otherwise.
    function isBeneficiaryApproved(IBeneficiaryContract _beneficiary)
        public
        view
        returns (bool)
    {
        return approvedBeneficiaries[address(_beneficiary)];
    }

    /// @notice Transfers the role of drawee to another address. Can be called
    ///         only by the contract owner.
    function setDrawee(address newDrawee) public onlyOwner {
        require(newDrawee != address(0), "New drawee can not be zero address");
        emit DraweeRoleTransferred(drawee, newDrawee);
        drawee = newDrawee;
    }

    /// @notice Funds the escrow by transferring all of the approved tokens
    ///         to the escrow.
    function receiveApproval(
        address _from,
        uint256 _value,
        address _token,
        bytes memory
    ) public {
        require(IERC20(_token) == token, "Unsupported token");
        token.safeTransferFrom(_from, address(this), _value);
    }

    /// @notice Withdraws tokens from escrow to selected beneficiaries,
    ///         transferring to each beneficiary the amount of tokens specified
    ///         as a parameter. Only beneficiaries previously approved by escrow
    ///         owner can receive funds.
    function batchedWithdraw(
        IBeneficiaryContract[] memory beneficiaries,
        uint256[] memory amounts
    ) public onlyDrawee {
        require(
            beneficiaries.length == amounts.length,
            "Mismatched arrays length"
        );

        for (uint256 i = 0; i < beneficiaries.length; i++) {
            IBeneficiaryContract beneficiary = beneficiaries[i];
            require(
                isBeneficiaryApproved(beneficiary),
                "Beneficiary was not approved"
            );
            withdraw(beneficiary, amounts[i]);
        }
    }

    function withdraw(IBeneficiaryContract beneficiary, uint256 amount)
        private
    {
        token.safeTransfer(address(beneficiary), amount);
        emit TokensWithdrawn(address(beneficiary), amount);
        beneficiary.__escrowSentTokens(amount);
    }
}

// Interface representing staking pool rewards contract such as CurveRewards
// contract deployed for Keep (0xAF379f0228ad0d46bB7B4f38f9dc9bCC1ad0360c) or
// LPRewards contract from keep-ecdsa repository deployed for Uniswap.
interface IStakingPoolRewards {
    function notifyRewardAmount(uint256 amount) external;
}

/// @title StakingPoolRewardsEscrowBeneficiary
/// @notice A beneficiary contract that can receive a withdrawal phase from a
///         PhasedEscrow contract. Immediately stakes the received tokens on a
///         designated IStakingPoolRewards contract.
contract StakingPoolRewardsEscrowBeneficiary is Ownable, IBeneficiaryContract {
    IERC20 public token;
    IStakingPoolRewards public rewards;

    constructor(IERC20 _token, IStakingPoolRewards _rewards) public {
        token = _token;
        rewards = _rewards;
    }

    function __escrowSentTokens(uint256 amount) external onlyOwner {
        token.approve(address(rewards), amount);
        rewards.notifyRewardAmount(amount);
    }
}

/// @dev Interface of recipient contract for approveAndCall pattern.
interface IStakerRewards {
    function receiveApproval(
        address _from,
        uint256 _value,
        address _token,
        bytes calldata _extraData
    ) external;
}

/// @title StakerRewardsBeneficiary
/// @notice An abstract beneficiary contract that can receive a withdrawal phase
///         from a PhasedEscrow contract. The received tokens are immediately
///         funded for a designated rewards escrow beneficiary contract.
contract StakerRewardsBeneficiary is Ownable {
    IERC20 public token;
    IStakerRewards public stakerRewards;

    constructor(IERC20 _token, IStakerRewards _stakerRewards) public {
        token = _token;
        stakerRewards = _stakerRewards;
    }

    function __escrowSentTokens(uint256 amount) external onlyOwner {
        bool success = token.approve(address(stakerRewards), amount);
        require(success, "Token transfer approval failed");

        stakerRewards.receiveApproval(
            address(this),
            amount,
            address(token),
            ""
        );
    }
}

/// @title BeaconBackportRewardsEscrowBeneficiary
/// @notice Transfer the received tokens to a designated
///         BeaconBackportRewardsEscrowBeneficiary contract.
contract BeaconBackportRewardsEscrowBeneficiary is StakerRewardsBeneficiary {
    constructor(IERC20 _token, IStakerRewards _stakerRewards)
        public
        StakerRewardsBeneficiary(_token, _stakerRewards)
    {}
}

/// @title BeaconRewardsEscrowBeneficiary
/// @notice Transfer the received tokens to a designated
///         BeaconRewardsEscrowBeneficiary contract.
contract BeaconRewardsEscrowBeneficiary is StakerRewardsBeneficiary {
    constructor(IERC20 _token, IStakerRewards _stakerRewards)
        public
        StakerRewardsBeneficiary(_token, _stakerRewards)
    {}
}

pragma solidity 0.5.17;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20Burnable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol";

/// @dev Interface of recipient contract for approveAndCall pattern.
interface tokenRecipient {
    function receiveApproval(
        address _from,
        uint256 _value,
        address _token,
        bytes calldata _extraData
    ) external;
}

/// @title KEEP Token
/// @dev Standard ERC20Burnable token
contract KeepToken is ERC20Burnable, ERC20Detailed {
    string public constant NAME = "KEEP Token";
    string public constant SYMBOL = "KEEP";
    uint8 public constant DECIMALS = 18; // The number of digits after the decimal place when displaying token values on-screen.
    uint256 public constant INITIAL_SUPPLY = 10**27; // 1 billion tokens, 18 decimal places.

    /// @dev Gives msg.sender all of existing tokens.
    constructor() public ERC20Detailed(NAME, SYMBOL, DECIMALS) {
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    /// @notice Set allowance for other address and notify.
    /// Allows `_spender` to spend no more than `_value` tokens
    /// on your behalf and then ping the contract about it.
    /// @param _spender The address authorized to spend.
    /// @param _value The max amount they can spend.
    /// @param _extraData Extra information to send to the approved contract.
    function approveAndCall(
        address _spender,
        uint256 _value,
        bytes memory _extraData
    ) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(
                msg.sender,
                _value,
                address(this),
                _extraData
            );
            return true;
        }
    }
}

pragma solidity 0.5.17;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";

// @title Escrow
// @notice A token holder contract allowing contract owner to set beneficiary of
// all tokens held by the contract and allowing the beneficiary to withdraw
// the tokens.
contract Escrow is Ownable {
    using SafeERC20 for IERC20;

    event BeneficiaryUpdated(address beneficiary);
    event TokensWithdrawn(address beneficiary, uint256 amount);

    IERC20 public token;
    address public beneficiary;

    constructor(IERC20 _token) public {
        token = _token;
    }

    // @notice Sets the provided address as a beneficiary allowing it to
    // withdraw all tokens from escrow. This function can be called only
    // by escrow owner.
    function setBeneficiary(address _beneficiary) public onlyOwner {
        beneficiary = _beneficiary;
        emit BeneficiaryUpdated(beneficiary);
    }

    // @notice Withdraws all tokens from escrow to the beneficiary.
    // If the beneficiary is not set, caller is not the beneficiary, or there
    // are no tokens in escrow, function fails.
    function withdraw() public {
        require(beneficiary != address(0), "Beneficiary not assigned");
        require(msg.sender == beneficiary, "Caller is not the beneficiary");

        uint256 amount = token.balanceOf(address(this));
        require(amount > 0, "No tokens to withdraw");

        token.safeTransfer(beneficiary, amount);
        emit TokensWithdrawn(beneficiary, amount);
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "devdoc",
        "userdoc",
        "metadata",
        "abi"
      ]
    }
  }
}