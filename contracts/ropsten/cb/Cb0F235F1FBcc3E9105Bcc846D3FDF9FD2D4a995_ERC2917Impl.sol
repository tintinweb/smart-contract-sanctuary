//SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;

import "./interfaces/core/IERC2917.sol";
import "./libraries/Upgradable.sol";
import "./libraries/SafeMath.sol";
import "./libraries/ReentrancyGuard.sol";
import "./ERC20.sol";

/*
    The Objective of ERC2917 Demo is to implement a decentralized staking mechanism, which calculates users' share
    by accumulating productiviy * time. And calculates users revenue from anytime t0 to t1 by the formula below:

        user_accumulated_productivity(time1) - user_accumulated_productivity(time0)
       _____________________________________________________________________________  * (gross_product(t1) - gross_product(t0))
       total_accumulated_productivity(time1) - total_accumulated_productivity(time0)

*/
contract ERC2917Impl is
    IERC2917,
    ERC20,
    UpgradableProduct,
    UpgradableGovernance,
    ReentrancyGuard
{
    using SafeMath for uint256;

    uint256 public mintCumulation;
    uint256 public usdPerBlock;
    uint256 public lastRewardBlock;
    uint256 public totalProductivity;
    uint256 public accAmountPerShare;

    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt.
    }

    mapping(address => UserInfo) public users;

    // creation of the interests token.
    constructor(uint256 _interestsRate)
        ERC20()
        UpgradableProduct()
        UpgradableGovernance()
    {
        usdPerBlock = _interestsRate;
    }

    // External function call
    // This function adjust how many token will be produced by each block, eg:
    // changeAmountPerBlock(100)
    // will set the produce rate to 100/block.
    function changeInterestRatePerBlock(uint256 value)
        external
        override
        requireGovernor
        returns (bool)
    {
        uint256 old = usdPerBlock;
        require(value != old, "AMOUNT_PER_BLOCK_NO_CHANGE");

        usdPerBlock = value;

        emit InterestRatePerBlockChanged(old, value);
        return true;
    }

    function enter(address account, uint256 amount)
        external
        override
        returns (bool)
    {
        require(this.deposit(account, amount), "INVALID DEPOSIT");
        return increaseProductivity(account, amount);
    }

    function exit(address account, uint256 amount)
        external
        override
        returns (bool)
    {
        require(this.withdrawal(account, amount), "INVALID WITHDRAWAL");
        return decreaseProductivity(account, amount);
    }

    // Intercept erc20 transfers
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(decreaseProductivity(from, amount), "INVALID DEC PROD");
        require(increaseProductivity(to, amount), "INVALID INC PROD");
    }

    // Update reward variables of the given pool to be up-to-date.
    function update() internal {
        if (block.number <= lastRewardBlock) {
            return;
        }

        if (totalProductivity == 0) {
            lastRewardBlock = block.number;
            return;
        }

        uint256 multiplier = block.number.sub(lastRewardBlock);

        uint256 reward = multiplier.mul(usdPerBlock);

        balanceOf[address(this)] = balanceOf[address(this)].add(reward);

        totalSupply = totalSupply.add(reward);

        accAmountPerShare = accAmountPerShare.add(
            reward.mul(1e18).div(totalProductivity)
        );
        lastRewardBlock = block.number;
    }

    // External function call
    // This function increase user's productivity and updates the global productivity.
    // the users' actual share percentage will calculated by:
    // Formula:     user_productivity / global_productivity
    function increaseProductivity(address user, uint256 value)
        internal
        returns (bool)
    {
        require(value > 0, "PRODUCTIVITY_VALUE_MUST_BE_GREATER_THAN_ZERO");

        UserInfo storage userInfo = users[user];
        update();
        if (userInfo.amount > 0) {
            uint256 pending = userInfo
            .amount
            .mul(accAmountPerShare)
            .div(1e12)
            .sub(userInfo.rewardDebt);
            _transfer(address(this), user, pending);
            mintCumulation = mintCumulation.add(pending);
        }

        totalProductivity = totalProductivity.add(value);

        userInfo.amount = userInfo.amount.add(value);
        userInfo.rewardDebt = userInfo.amount.mul(accAmountPerShare).div(1e12);
        emit ProductivityIncreased(user, value);
        return true;
    }

    // External function call
    // This function will decreases user's productivity by value, and updates the global productivity
    // it will record which block this is happenning and accumulates the area of (productivity * time)
    function decreaseProductivity(address user, uint256 value)
        internal
        returns (bool)
    {
        require(value > 0, "INSUFFICIENT_PRODUCTIVITY");

        UserInfo storage userInfo = users[user];
        require(userInfo.amount >= value, "Decrease : FORBIDDEN");
        update();
        uint256 pending = userInfo.amount.mul(accAmountPerShare).div(1e12).sub(
            userInfo.rewardDebt
        );
        _transfer(address(this), user, pending);
        mintCumulation = mintCumulation.add(pending);
        userInfo.amount = userInfo.amount.sub(value);
        userInfo.rewardDebt = userInfo.amount.mul(accAmountPerShare).div(1e12);
        totalProductivity = totalProductivity.sub(value);

        emit ProductivityDecreased(user, value);
        return true;
    }

    // =========================================== views

    // It returns the interests that callee will get at current block height.
    function take() external view override returns (uint256) {
        UserInfo storage userInfo = users[msg.sender];
        uint256 _accAmountPerShare = accAmountPerShare;
        // uint256 lpSupply = totalProductivity;
        if (block.number > lastRewardBlock && totalProductivity != 0) {
            uint256 multiplier = block.number.sub(lastRewardBlock);
            uint256 reward = multiplier.mul(usdPerBlock);
            _accAmountPerShare = _accAmountPerShare.add(
                reward.mul(1e12).div(totalProductivity)
            );
        }
        return
            userInfo.amount.mul(_accAmountPerShare).div(1e12).sub(
                userInfo.rewardDebt
            );
    }

    function takeWithAddress(address user) external view returns (uint256) {
        UserInfo storage userInfo = users[user];
        uint256 _accAmountPerShare = accAmountPerShare;
        // uint256 lpSupply = totalProductivity;
        if (block.number > lastRewardBlock && totalProductivity != 0) {
            uint256 multiplier = block.number.sub(lastRewardBlock);
            uint256 reward = multiplier.mul(usdPerBlock);
            _accAmountPerShare = _accAmountPerShare.add(
                reward.mul(1e12).div(totalProductivity)
            );
        }
        return
            userInfo.amount.mul(_accAmountPerShare).div(1e12).sub(
                userInfo.rewardDebt
            );
    }

    // Returns how much a user could earn plus the giving block number.
    function takeWithBlock() external view override returns (uint256, uint256) {
        UserInfo storage userInfo = users[msg.sender];
        uint256 _accAmountPerShare = accAmountPerShare;
        // uint256 lpSupply = totalProductivity;
        if (block.number > lastRewardBlock && totalProductivity != 0) {
            uint256 multiplier = block.number.sub(lastRewardBlock);
            uint256 reward = multiplier.mul(usdPerBlock);
            _accAmountPerShare = _accAmountPerShare.add(
                reward.mul(1e12).div(totalProductivity)
            );
        }
        return (
            userInfo.amount.mul(_accAmountPerShare).div(1e12).sub(
                userInfo.rewardDebt
            ),
            block.number
        );
    }

    // External function call
    // When user calls this function, it will calculate how many token will mint to user from his productivity * time
    // Also it calculates global token supply from last time the user mint to this time.
    function mint() external override nonReentrant returns (uint256) {
        return 0;
    }

    // Returns how many productivity a user has and global has.
    function getProductivity(address user)
        external
        view
        override
        returns (uint256, uint256)
    {
        return (users[user].amount, totalProductivity);
    }

    // Returns the current gorss product rate.
    function interestsPerBlock() external view override returns (uint256) {
        return accAmountPerShare;
    }

    function getStatus()
        external
        view
        override
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            lastRewardBlock,
            totalProductivity,
            accAmountPerShare,
            mintCumulation
        );
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;

interface IERC2917 {

    /// @dev This emit when interests amount per block is changed by the owner of the contract.
    /// It emits with the old interests amount and the new interests amount.
    event InterestRatePerBlockChanged (uint oldValue, uint newValue);

    /// @dev This emit when a users' productivity has changed
    /// It emits with the user's address and the the value after the change.
    event ProductivityIncreased (address indexed user, uint value);

    /// @dev This emit when a users' productivity has changed
    /// It emits with the user's address and the the value after the change.
    event ProductivityDecreased (address indexed user, uint value);

    /// @dev Return the current contract's interests rate per block.
    /// @return The amount of interests currently producing per each block.
    function interestsPerBlock() external view returns (uint);

    /// @notice Change the current contract's interests rate.
    /// @dev Note the best practice will be restrict the gross product provider's contract address to call this.
    /// @return The true/fase to notice that the value has successfully changed or not, when it succeed, it will emite the InterestRatePerBlockChanged event.
    function changeInterestRatePerBlock(uint value) external returns (bool);

    /// @notice It will get the productivity of given user.
    /// @dev it will return 0 if user has no productivity proved in the contract.
    /// @return user's productivity and overall productivity.
    function getProductivity(address user) external view returns (uint, uint);

    // /// @notice increase a user's productivity.
    // /// @dev Note the best practice will be restrict the callee to prove of productivity's contract address.
    // /// @return true to confirm that the productivity added success.
    // function increaseProductivity(address user, uint value) external returns (bool);

    // /// @notice decrease a user's productivity.
    // /// @dev Note the best practice will be restrict the callee to prove of productivity's contract address.
    // /// @return true to confirm that the productivity removed success.
    // function decreaseProductivity(address user, uint value) external returns (bool);

    /// @notice take() will return the interests that callee will get at current block height.
    /// @dev it will always calculated by block.number, so it will change when block height changes.
    /// @return amount of the interests that user are able to mint() at current block height.
    function take() external view returns (uint);

    /// @notice similar to take(), but with the block height joined to calculate return.
    /// @dev for instance, it returns (_amount, _block), which means at block height _block, the callee has accumulated _amount of interests.
    /// @return amount of interests and the block height.
    function takeWithBlock() external view returns (uint, uint);

    /// @notice mint the avaiable interests to callee.
    /// @dev once it mint, the amount of interests will transfer to callee's address.
    /// @return the amount of interests minted.
    function mint() external returns (uint);

    function enter(address account, uint256 amount) external returns (bool);
    
    function exit(address account, uint256 amount) external returns (bool);
 
    function getStatus() external view returns (uint lastRewardBlock, uint totalProductivity, uint accAmountPerShare, uint mintCumulation);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.5.16;

contract UpgradableProduct {
    address public impl;

    event ImplChanged(address indexed _oldImpl, address indexed _newImpl);

    constructor() {
        impl = msg.sender;
    }

    modifier requireImpl() {
        require(msg.sender == impl, 'FORBIDDEN');
        _;
    }

    function upgradeImpl(address _newImpl) public requireImpl {
        require(_newImpl != address(0), 'INVALID_ADDRESS');
        require(_newImpl != impl, 'NO_CHANGE');
        address lastImpl = impl;
        impl = _newImpl;
        emit ImplChanged(lastImpl, _newImpl);
    }
}

contract UpgradableGovernance {
    address public governor;

    event GovernorChanged(address indexed _oldGovernor, address indexed _newGovernor);

    constructor() {
        governor = msg.sender;
    }

    modifier requireGovernor() {
        require(msg.sender == governor, 'FORBIDDEN');
        _;
    }

    function upgradeGovernance(address _newGovernor) public requireGovernor {
        require(_newGovernor != address(0), 'INVALID_ADDRESS');
        require(_newGovernor != governor, 'NO_CHANGE');
        address lastGovernor = governor;
        governor = _newGovernor;
        emit GovernorChanged(lastGovernor, _newGovernor);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }
    /**
        * @dev Returns the subtraction of two unsigned integers, reverting on
        * overflow (when the result is negative).
        *
        * Counterpart to Solidity's `-` operator.
        *
        * Requirements:
        *
        * - Subtraction cannot overflow.
        */
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }
    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b > 0, errorMessage);
        uint c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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

    constructor () {
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

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;

import './libraries/SafeMath.sol';
import './interfaces/core/IERC20.sol';

  contract ERC20 is IERC20 {
    using SafeMath for uint;

    string override public name;
    string override public symbol;
    uint8 override public decimals = 18;
    uint override public totalSupply;

    mapping(address => uint) override public balanceOf;
    // mapping(address => mapping(address => uint)) override public allowance;

    constructor() {
        name        = "USDP TOKEN";
        symbol      = "USDP";
    }

    // function _transfer(address from, address to, uint value) internal {
    //     require(balanceOf[from] >= value, 'ERC20Token: INSUFFICIENT_BALANCE');
    //     balanceOf[from] = balanceOf[from].sub(value);
    //     balanceOf[to] = balanceOf[to].add(value);
    //     if (to == address(0)) { 
    //         // burn
    //         totalSupply = totalSupply.sub(value);
    //     }
    //     emit Transfer(from, to, value);
    // }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = balanceOf[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        balanceOf[sender] = senderBalance - amount;
        balanceOf[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }

    // function approve(address spender, uint value) external override returns (bool) {
    //     allowance[msg.sender][spender] = value;
    //     emit Approval(msg.sender, spender, value);
    //     return true;
    // }

    // function transferFrom(address from, address to, uint value) external override returns (bool) {
    //     require(allowance[from][msg.sender] >= value, 'ERC20Token: INSUFFICIENT_ALLOWANCE');
    //     allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
    //     _transfer(from, to, value);
    //     return true;
    // }

    // function transfer(address to, uint value) external override returns (bool) {
    //     _transfer(msg.sender, to, value);
    //     return true;
    // }

    function deposit(address account, uint256 amount) external override returns (bool) {
        require(account != address(0), "ERC20: mint to the zero address");

        balanceOf[account] += amount;
        totalSupply = totalSupply.add(amount);

        emit Transfer(address(0), account, amount);
        return true;
    }

    function withdrawal(address account, uint256 amount) external override returns (bool) {
        require(account != address(0), "ERC20: burn from the zero address");
        
        uint256 accountBalance = balanceOf[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        
        balanceOf[account] = accountBalance - amount;
        
        totalSupply = totalSupply.sub(amount);

        emit Transfer(account, address(0), amount);
        return true;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IERC20 {
     /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    // event Approval(address indexed owner, address indexed spender, uint value);


    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    // function allowance(address owner, address spender) external view returns (uint);

    /**
        * @dev Returns the amount of tokens owned by `account`.
    */
    function balanceOf(address account) external view returns (uint);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint amount) external returns (bool);

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
    // function approve(address spender, uint amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    // function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    function deposit(address account, uint256 amount) external returns (bool);
    function withdrawal(address account, uint256 amount) external returns (bool);
}

