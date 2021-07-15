// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

/*
  ___                      _   _
 | _ )_  _ _ _  _ _ _  _  | | | |
 | _ \ || | ' \| ' \ || | |_| |_|
 |___/\_,_|_||_|_||_\_, | (_) (_)
                    |__/

*
* MIT License
* ===========
*
* Copyright (c) 2020 BunnyFinance
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

import '@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol';
import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol';
import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol';
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../interfaces/IBunnyMinterV2.sol";
import "../interfaces/IBunnyChef.sol";
import "../interfaces/IStrategy.sol";

contract BunnyChef is IBunnyChef, OwnableUpgradeable {
    using SafeMath for uint;
    using SafeBEP20 for IBEP20;

    /* ========== CONSTANTS ============= */

    address public constant BUNNY = 0x4C16f69302CcB511c5Fac682c7626B9eF0Dc126a;

    /* ========== STATE VARIABLES ========== */

    address[] private _vaultList;
    mapping(address => VaultInfo) vaults;
    mapping(address => mapping(address => UserInfo)) vaultUsers;

    IBunnyMinterV2 public minter;

    uint public startBlock;
    uint public override bunnyPerBlock;
    uint public override totalAllocPoint;

    /* ========== MODIFIERS ========== */

    modifier onlyVaults {
        require(vaults[msg.sender].token != address(0), "BunnyChef: caller is not on the vault");
        _;
    }

    modifier updateRewards(address vault) {
        VaultInfo storage vaultInfo = vaults[vault];
        if (block.number > vaultInfo.lastRewardBlock) {
            uint tokenSupply = tokenSupplyOf(vault);
            if (tokenSupply > 0) {
                uint multiplier = timeMultiplier(vaultInfo.lastRewardBlock, block.number);
                uint rewards = multiplier.mul(bunnyPerBlock).mul(vaultInfo.allocPoint).div(totalAllocPoint);
                vaultInfo.accBunnyPerShare = vaultInfo.accBunnyPerShare.add(rewards.mul(1e12).div(tokenSupply));
            }
            vaultInfo.lastRewardBlock = block.number;
        }
        _;
    }

    /* ========== EVENTS ========== */

    event NotifyDeposited(address indexed user, address indexed vault, uint amount);
    event NotifyWithdrawn(address indexed user, address indexed vault, uint amount);
    event BunnyRewardPaid(address indexed user, address indexed vault, uint amount);

    /* ========== INITIALIZER ========== */

    function initialize(uint _startBlock, uint _bunnyPerBlock) external initializer {
        __Ownable_init();

        startBlock = _startBlock;
        bunnyPerBlock = _bunnyPerBlock;
    }

    /* ========== VIEWS ========== */

    function timeMultiplier(uint from, uint to) public pure returns (uint) {
        return to.sub(from);
    }

    function tokenSupplyOf(address vault) public view returns (uint) {
        return IStrategy(vault).totalSupply();
    }

    function vaultInfoOf(address vault) external view override returns (VaultInfo memory) {
        return vaults[vault];
    }

    function vaultUserInfoOf(address vault, address user) external view override returns (UserInfo memory) {
        return vaultUsers[vault][user];
    }

    function pendingBunny(address vault, address user) public view override returns (uint) {
        UserInfo storage userInfo = vaultUsers[vault][user];
        VaultInfo storage vaultInfo = vaults[vault];

        uint accBunnyPerShare = vaultInfo.accBunnyPerShare;
        uint tokenSupply = tokenSupplyOf(vault);
        if (block.number > vaultInfo.lastRewardBlock && tokenSupply > 0) {
            uint multiplier = timeMultiplier(vaultInfo.lastRewardBlock, block.number);
            uint bunnyRewards = multiplier.mul(bunnyPerBlock).mul(vaultInfo.allocPoint).div(totalAllocPoint);
            accBunnyPerShare = accBunnyPerShare.add(bunnyRewards.mul(1e12).div(tokenSupply));
        }
        return userInfo.pending.add(userInfo.balance.mul(accBunnyPerShare).div(1e12).sub(userInfo.rewardPaid));
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function addVault(address vault, address token, uint allocPoint) public onlyOwner {
        require(vaults[vault].token == address(0), "BunnyChef: vault is already set");
        bulkUpdateRewards();

        uint lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(allocPoint);
        vaults[vault] = VaultInfo(token, allocPoint, lastRewardBlock, 0);
        _vaultList.push(vault);
    }

    function updateVault(address vault, uint allocPoint) public onlyOwner {
        require(vaults[vault].token != address(0), "BunnyChef: vault must be set");
        bulkUpdateRewards();

        uint lastAllocPoint = vaults[vault].allocPoint;
        if (lastAllocPoint != allocPoint) {
            totalAllocPoint = totalAllocPoint.sub(lastAllocPoint).add(allocPoint);
        }
        vaults[vault].allocPoint = allocPoint;
    }

    function setMinter(address _minter) external onlyOwner {
        require(address(minter) == address(0), "BunnyChef: setMinter only once");
        minter = IBunnyMinterV2(_minter);
    }

    function setBunnyPerBlock(uint _bunnyPerBlock) external onlyOwner {
        bulkUpdateRewards();
        bunnyPerBlock = _bunnyPerBlock;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function notifyDeposited(address user, uint amount) external override onlyVaults updateRewards(msg.sender) {
        UserInfo storage userInfo = vaultUsers[msg.sender][user];
        VaultInfo storage vaultInfo = vaults[msg.sender];

        uint pending = userInfo.balance.mul(vaultInfo.accBunnyPerShare).div(1e12).sub(userInfo.rewardPaid);
        userInfo.pending = userInfo.pending.add(pending);
        userInfo.balance = userInfo.balance.add(amount);
        userInfo.rewardPaid = userInfo.balance.mul(vaultInfo.accBunnyPerShare).div(1e12);
        emit NotifyDeposited(user, msg.sender, amount);
    }

    function notifyWithdrawn(address user, uint amount) external override onlyVaults updateRewards(msg.sender) {
        UserInfo storage userInfo = vaultUsers[msg.sender][user];
        VaultInfo storage vaultInfo = vaults[msg.sender];

        uint pending = userInfo.balance.mul(vaultInfo.accBunnyPerShare).div(1e12).sub(userInfo.rewardPaid);
        userInfo.pending = userInfo.pending.add(pending);
        userInfo.balance = userInfo.balance.sub(amount);
        userInfo.rewardPaid = userInfo.balance.mul(vaultInfo.accBunnyPerShare).div(1e12);
        emit NotifyWithdrawn(user, msg.sender, amount);
    }

    function safeBunnyTransfer(address user) external override onlyVaults updateRewards(msg.sender) returns (uint) {
        UserInfo storage userInfo = vaultUsers[msg.sender][user];
        VaultInfo storage vaultInfo = vaults[msg.sender];

        uint pending = userInfo.balance.mul(vaultInfo.accBunnyPerShare).div(1e12).sub(userInfo.rewardPaid);
        uint amount = userInfo.pending.add(pending);
        userInfo.pending = 0;
        userInfo.rewardPaid = userInfo.balance.mul(vaultInfo.accBunnyPerShare).div(1e12);

        minter.mint(amount);
        minter.safeBunnyTransfer(user, amount);
        emit BunnyRewardPaid(user, msg.sender, amount);
        return amount;
    }

    function bulkUpdateRewards() public {
        for (uint idx = 0; idx < _vaultList.length; idx++) {
            if (_vaultList[idx] != address(0) && vaults[_vaultList[idx]].token != address(0)) {
                updateRewardsOf(_vaultList[idx]);
            }
        }
    }

    function updateRewardsOf(address vault) public override updateRewards(vault) {
    }

    /* ========== SALVAGE PURPOSE ONLY ========== */

    function recoverToken(address _token, uint amount) virtual external onlyOwner {
        require(_token != BUNNY, "BunnyChef: cannot recover BUNNY token");
        IBEP20(_token).safeTransfer(owner(), amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.0;

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
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
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
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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

pragma solidity ^0.6.0;

import './IBEP20.sol';
import '../../math/SafeMath.sol';
import '../../utils/Address.sol';

/**
 * @title SafeBEP20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBEP20 for IBEP20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            'SafeBEP20: approve from non-zero to non-zero allowance'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            'SafeBEP20: decreased allowance below zero'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, 'SafeBEP20: low-level call failed');
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), 'SafeBEP20: BEP20 operation did not succeed');
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IBunnyMinterV2 {
    function isMinter(address) view external returns(bool);
    function amountBunnyToMint(uint bnbProfit) view external returns(uint);
    function withdrawalFee(uint amount, uint depositedAt) view external returns(uint);
    function performanceFee(uint profit) view external returns(uint);
    function mintFor(address flip, uint _withdrawalFee, uint _performanceFee, address to, uint depositedAt) external payable;
    function mintForV2(address flip, uint _withdrawalFee, uint _performanceFee, address to, uint depositedAt) external payable;

    function bunnyPerProfitBNB() view external returns(uint);
    function WITHDRAWAL_FEE_FREE_PERIOD() view external returns(uint);
    function WITHDRAWAL_FEE() view external returns(uint);

    function setMinter(address minter, bool canMint) external;

    // V2 functions
    function mint(uint amount) external;
    function safeBunnyTransfer(address to, uint256 amount) external;
    function mintGov(uint amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

/*
  ___                      _   _
 | _ )_  _ _ _  _ _ _  _  | | | |
 | _ \ || | ' \| ' \ || | |_| |_|
 |___/\_,_|_||_|_||_\_, | (_) (_)
                    |__/

*
* MIT License
* ===========
*
* Copyright (c) 2020 BunnyFinance
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

interface IBunnyChef {

    struct UserInfo {
        uint balance;
        uint pending;
        uint rewardPaid;
    }

    struct VaultInfo {
        address token;
        uint allocPoint;       // How many allocation points assigned to this pool. BUNNYs to distribute per block.
        uint lastRewardBlock;  // Last block number that BUNNYs distribution occurs.
        uint accBunnyPerShare; // Accumulated BUNNYs per share, times 1e12. See below.
    }

    function bunnyPerBlock() external view returns (uint);
    function totalAllocPoint() external view returns (uint);

    function vaultInfoOf(address vault) external view returns (VaultInfo memory);
    function vaultUserInfoOf(address vault, address user) external view returns (UserInfo memory);
    function pendingBunny(address vault, address user) external view returns (uint);

    function notifyDeposited(address user, uint amount) external;
    function notifyWithdrawn(address user, uint amount) external;
    function safeBunnyTransfer(address user) external returns (uint);
    function updateRewardsOf(address vault) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
  ___                      _   _
 | _ )_  _ _ _  _ _ _  _  | | | |
 | _ \ || | ' \| ' \ || | |_| |_|
 |___/\_,_|_||_|_||_\_, | (_) (_)
                    |__/

*
* MIT License
* ===========
*
* Copyright (c) 2020 BunnyFinance
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

import "../library/PoolConstant.sol";
import "./IVaultController.sol";

interface IStrategy is IVaultController {
    function deposit(uint _amount) external;
    function depositAll() external;
    function withdraw(uint _amount) external;    // BUNNY STAKING POOL ONLY
    function withdrawAll() external;
    function getReward() external;                  // BUNNY STAKING POOL ONLY
    function harvest() external;

    function totalSupply() external view returns (uint);
    function balance() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function sharesOf(address account) external view returns (uint);
    function principalOf(address account) external view returns (uint);
    function earned(address account) external view returns (uint);
    function withdrawableBalanceOf(address account) external view returns (uint);   // BUNNY STAKING POOL ONLY
    function priceShare() external view returns (uint);

    /* ========== Strategy Information ========== */

    function pid() external view returns (uint);
    function poolType() external view returns (PoolConstant.PoolTypes);
    function depositedAt(address account) external view returns (uint);
    function rewardsToken() external view returns (address);

    event Deposited(address indexed user, uint amount);
    event Withdrawn(address indexed user, uint amount, uint withdrawalFee);
    event ProfitPaid(address indexed user, uint profit, uint performanceFee);
    event BunnyPaid(address indexed user, uint profit, uint performanceFee);
    event Harvested(uint profit);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, 'Address: insufficient balance');

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}('');
        require(success, 'Address: unable to send value, recipient may have reverted');
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, 'Address: low-level call failed');
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, 'Address: insufficient balance for call');
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), 'Address: call to non-contract');

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/*
  ___                      _   _
 | _ )_  _ _ _  _ _ _  _  | | | |
 | _ \ || | ' \| ' \ || | |_| |_|
 |___/\_,_|_||_|_||_\_, | (_) (_)
                    |__/

*
* MIT License
* ===========
*
* Copyright (c) 2020 BunnyFinance
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


library PoolConstant {

    enum PoolTypes {
        Bunny,
        BunnyToBunny,
        BunnyETH,
        FlipToFlip,
        FlipToToken,
        TokenToToken
    }

    struct PoolInfo {
        address pool;
        uint balance;
        uint principal;
        uint available;
        uint tvl;
        uint pBASE;
        uint pBUNNY;
        uint depositedAt;
        uint feeDuration;
        uint feePercentage;
        uint portfolio;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/*
  ___                      _   _
 | _ )_  _ _ _  _ _ _  _  | | | |
 | _ \ || | ' \| ' \ || | |_| |_|
 |___/\_,_|_||_|_||_\_, | (_) (_)
                    |__/

*
* MIT License
* ===========
*
* Copyright (c) 2020 BunnyFinance
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

interface IVaultController {
    function minter() external view returns (address);
    function bunnyChef() external view returns (address);
    function stakingToken() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
  ___                      _   _
 | _ )_  _ _ _  _ _ _  _  | | | |
 | _ \ || | ' \| ' \ || | |_| |_|
 |___/\_,_|_||_|_||_\_, | (_) (_)
                    |__/

*
* MIT License
* ===========
*
* Copyright (c) 2020 BunnyFinance
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

import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol";
import "@openzeppelin/contracts/math/Math.sol";

import {PoolConstant} from "../library/PoolConstant.sol";
import "../interfaces/IUniswapV2Pair.sol";
import "../interfaces/IUniswapV2Factory.sol";
import "../interfaces/IStrategy.sol";
import "../interfaces/ISushiMiniChefV2.sol";
import "../interfaces/IZap.sol";

import "./VaultController.sol";

contract VaultSushiFlipToFlip is VaultController, IStrategy {
    using SafeBEP20 for IBEP20;
    using SafeMath for uint256;

    /* ========== CONSTANTS ============= */

    IBEP20 private constant SUSHI = IBEP20(0x0b3F868E0BE5597D5DB7fEB59E1CADBb0fdDa50a);
    IBEP20 private constant WMATIC = IBEP20(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
    PoolConstant.PoolTypes public constant override poolType = PoolConstant.PoolTypes.FlipToFlip;
    ISushiMiniChefV2 private constant SUSHI_MINI_CHEF = ISushiMiniChefV2(0x0769fd68dFb93167989C6f7254cd0D766Fb2841F);
    IZap private constant zap = IZap(0x93bCE7E49E26AF0f87b74583Ba6551DF5E4867B7);

    uint private constant DUST = 1000;

    /* ========== STATE VARIABLES ========== */

    uint public override pid;

    address private _token0;
    address private _token1;

    uint public totalShares;
    mapping (address => uint) private _shares;
    mapping (address => uint) private _principal;
    mapping (address => uint) private _depositedAt;

    uint public sushiHarvested;
    uint public wmaticHarvested;


    /* ========== MODIFIER ========== */

    modifier updateSushiHarvested {
        uint _before = SUSHI.balanceOf(address(this));
        uint _beforeWmatic = WMATIC.balanceOf(address(this));
        _;
        uint _after = SUSHI.balanceOf(address(this));
        uint _afterWmatic = WMATIC.balanceOf(address(this));
        sushiHarvested = sushiHarvested.add(_after).sub(_before);
        wmaticHarvested = wmaticHarvested.add(_afterWmatic).sub(_beforeWmatic);
    }

    /* ========== INITIALIZER ========== */

    function initialize(uint _pid, address _token) external initializer {
        __VaultController_init(IBEP20(_token));
        _stakingToken.safeApprove(address(SUSHI_MINI_CHEF), uint(- 1));
        pid = _pid;

        SUSHI.safeApprove(address(zap), uint(- 1));
        WMATIC.safeApprove(address(zap), uint(- 1));
    }

    /* ========== VIEW FUNCTIONS ========== */

    function totalSupply() external view override returns (uint) {
        return totalShares;
    }

    function balance() public view override returns (uint amount) {
        (amount,) = SUSHI_MINI_CHEF.userInfo(pid, address(this));
    }

    function balanceOf(address account) public view override returns(uint) {
        if (totalShares == 0) return 0;
        return balance().mul(sharesOf(account)).div(totalShares);
    }

    function withdrawableBalanceOf(address account) public view override returns (uint) {
        return balanceOf(account);
    }

    function sharesOf(address account) public view override returns (uint) {
        return _shares[account];
    }

    function principalOf(address account) public view override returns (uint) {
        return _principal[account];
    }

    function earned(address account) public view override returns (uint) {
        if (balanceOf(account) >= principalOf(account) + DUST) {
            return balanceOf(account).sub(principalOf(account));
        } else {
            return 0;
        }
    }

    function depositedAt(address account) external view override returns (uint) {
        return _depositedAt[account];
    }

    function rewardsToken() external view override returns (address) {
        return address(_stakingToken);
    }

    function priceShare() external view override returns(uint) {
        if (totalShares == 0) return 1e18;
        return balance().mul(1e18).div(totalShares);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function deposit(uint _amount) public override {
        _depositTo(_amount, msg.sender);
    }

    function depositAll() external override {
        deposit(_stakingToken.balanceOf(msg.sender));
    }

    function withdrawAll() external override {
        uint amount = balanceOf(msg.sender);
        uint principal = principalOf(msg.sender);
        uint depositTimestamp = _depositedAt[msg.sender];

        totalShares = totalShares.sub(_shares[msg.sender]);
        delete _shares[msg.sender];
        delete _principal[msg.sender];
        delete _depositedAt[msg.sender];

        amount = _withdrawTokenWithCorrection(amount);
        uint profit = amount > principal ? amount.sub(principal) : 0;

        uint withdrawalFee = canMint() ? _minter.withdrawalFee(principal, depositTimestamp) : 0;
        uint performanceFee = canMint() ? _minter.performanceFee(profit) : 0;
        if (withdrawalFee.add(performanceFee) > DUST) {
            _minter.mintForV2(address(_stakingToken), withdrawalFee, performanceFee, msg.sender, depositTimestamp);

            if (performanceFee > 0) {
                emit ProfitPaid(msg.sender, profit, performanceFee);
            }
            amount = amount.sub(withdrawalFee).sub(performanceFee);
        }

        _stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount, withdrawalFee);
    }

    function harvest() external override onlyKeeper {
        _harvest();

        uint before = _stakingToken.balanceOf(address(this));
        zap.zapInToken(address(SUSHI), sushiHarvested, address(_stakingToken));
        zap.zapInToken(address(WMATIC), wmaticHarvested, address(_stakingToken));
        uint harvested = _stakingToken.balanceOf(address(this)).sub(before);

        SUSHI_MINI_CHEF.deposit(pid, harvested, address(this));
        emit Harvested(harvested);

        sushiHarvested = 0;
        wmaticHarvested = 0;
    }

    function _harvest() private updateSushiHarvested {
        SUSHI_MINI_CHEF.harvest(pid, address(this));
    }

    function withdraw(uint shares) external override onlyWhitelisted {
        uint amount = balance().mul(shares).div(totalShares);
        totalShares = totalShares.sub(shares);
        _shares[msg.sender] = _shares[msg.sender].sub(shares);

        amount = _withdrawTokenWithCorrection(amount);
        _stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount, 0);
    }

    // @dev underlying only + withdrawal fee + no perf fee
    function withdrawUnderlying(uint _amount) external {
        uint amount = Math.min(_amount, _principal[msg.sender]);
        uint shares = Math.min(amount.mul(totalShares).div(balance()), _shares[msg.sender]);
        totalShares = totalShares.sub(shares);
        _shares[msg.sender] = _shares[msg.sender].sub(shares);
        _principal[msg.sender] = _principal[msg.sender].sub(amount);

        amount = _withdrawTokenWithCorrection(amount);
        uint depositTimestamp = _depositedAt[msg.sender];
        uint withdrawalFee = canMint() ? _minter.withdrawalFee(amount, depositTimestamp) : 0;
        if (withdrawalFee > DUST) {
            _minter.mintForV2(address(_stakingToken), withdrawalFee, 0, msg.sender, depositTimestamp);
            amount = amount.sub(withdrawalFee);
        }

        _stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount, withdrawalFee);
    }

    // @dev profits only (underlying + bunny) + no withdraw fee + perf fee
    function getReward() external override {
        uint amount = earned(msg.sender);
        uint shares = Math.min(amount.mul(totalShares).div(balance()), _shares[msg.sender]);
        totalShares = totalShares.sub(shares);
        _shares[msg.sender] = _shares[msg.sender].sub(shares);
        _cleanupIfDustShares();

        amount = _withdrawTokenWithCorrection(amount);
        uint depositTimestamp = _depositedAt[msg.sender];
        uint performanceFee = canMint() ? _minter.performanceFee(amount) : 0;
        if (performanceFee > DUST) {
            _minter.mintForV2(address(_stakingToken), 0, performanceFee, msg.sender, depositTimestamp);
            amount = amount.sub(performanceFee);
        }

        _stakingToken.safeTransfer(msg.sender, amount);
        emit ProfitPaid(msg.sender, amount, performanceFee);
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _depositTo(uint _amount, address _to) private notPaused updateSushiHarvested {
        uint _pool = balance();
        uint _before = _stakingToken.balanceOf(address(this));
        _stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
        uint _after = _stakingToken.balanceOf(address(this));
        _amount = _after.sub(_before); // Additional check for deflationary tokens
        uint shares = 0;
        if (totalShares == 0) {
            shares = _amount;
        } else {
            shares = (_amount.mul(totalShares)).div(_pool);
        }

        totalShares = totalShares.add(shares);
        _shares[_to] = _shares[_to].add(shares);
        _principal[_to] = _principal[_to].add(_amount);
        _depositedAt[_to] = block.timestamp;

        SUSHI_MINI_CHEF.deposit(pid, _amount, address(this));
        emit Deposited(_to, _amount);
    }

    function _withdrawTokenWithCorrection(uint amount) private updateSushiHarvested returns (uint) {
        uint before = _stakingToken.balanceOf(address(this));
        SUSHI_MINI_CHEF.withdraw(pid, amount, address(this));
        return _stakingToken.balanceOf(address(this)).sub(before);
    }

    function _cleanupIfDustShares() private {
        uint shares = _shares[msg.sender];
        if (shares > 0 && shares < DUST) {
            totalShares = totalShares.sub(shares);
            delete _shares[msg.sender];
        }
    }

    /* ========== SALVAGE PURPOSE ONLY ========== */

    // @dev stakingToken must not remain balance in this contract. So dev should salvage staking token transferred by mistake.
    function recoverToken(address token, uint amount) external override onlyOwner {
        if (token == address(SUSHI)) {
            uint sushiBalance = SUSHI.balanceOf(address(this));
            require(amount <= sushiBalance.sub(sushiHarvested), "VaultFlipToFlip: cannot recover lp's harvested sushi");
        }
        if (token == address(WMATIC)){
            uint wmaticBalance = WMATIC.balanceOf(address(this));
            require(amount <= wmaticBalance.sub(wmaticHarvested));
        }

        IBEP20(token).safeTransfer(owner(), amount);
        emit Recovered(token, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

// https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/interfaces/IUniswapV2Pair.sol

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint);

    function permit(
        address owner,
        address spender,
        uint value,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
    external
    view
    returns (
        uint112 reserve0,
        uint112 reserve1,
        uint32 blockTimestampLast
    );

    function price0CumulativeLast() external view returns (uint);

    function price1CumulativeLast() external view returns (uint);

    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);

    function burn(address to) external returns (uint amount0, uint amount1);

    function swap(
        uint amount0Out,
        uint amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function createPair(address tokenA, address tokenB) external returns (address pair);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface ISushiMiniChefV2 {
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    struct PoolInfo {
        uint128 accSushiPerShare;
        uint64 lastRewardTime;
        uint64 allocPoint;
    }

    function poolLength() external view returns (uint256);
    function updatePool(uint256 pid) external returns (ISushiMiniChefV2.PoolInfo memory);
    function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256);
    function deposit(uint256 pid, uint256 amount, address to) external;
    function withdraw(uint256 pid, uint256 amount, address to) external;
    function harvest(uint256 pid, address to) external;
    function withdrawAndHarvest(uint256 pid, uint256 amount, address to) external;
    function emergencyWithdraw(uint256 pid, address to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IZap {
    function covers(address _token) external view returns (bool);

    function zapOut(address _from, uint amount) external;
    function zapIn(address _to) external payable;
    function zapInToken(address _from, uint amount, address _to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
  ___                      _   _
 | _ )_  _ _ _  _ _ _  _  | | | |
 | _ \ || | ' \| ' \ || | |_| |_|
 |___/\_,_|_||_|_||_\_, | (_) (_)
                    |__/

*
* MIT License
* ===========
*
* Copyright (c) 2020 BunnyFinance
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

import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/BEP20.sol";

import "../interfaces/IPancakeRouter02.sol";
import "../interfaces/IPancakePair.sol";
import "../interfaces/IStrategy.sol";
import "../interfaces/IMasterChef.sol";
import "../interfaces/IBunnyMinterV2.sol";
import "../interfaces/IBunnyChef.sol";
import "../library/PausableUpgradeable.sol";
import "../library/WhitelistUpgradeable.sol";

abstract contract VaultController is IVaultController, PausableUpgradeable, WhitelistUpgradeable {
    using SafeBEP20 for IBEP20;

    /* ========== CONSTANT VARIABLES ========== */

    BEP20 private constant BUNNY = BEP20(0x4C16f69302CcB511c5Fac682c7626B9eF0Dc126a);

    /* ========== STATE VARIABLES ========== */

    address public keeper;
    IBEP20 internal _stakingToken;
    IBunnyMinterV2 internal _minter;
    IBunnyChef internal _bunnyChef;

    /* ========== VARIABLE GAP ========== */

    uint256[49] private __gap;

    /* ========== Event ========== */

    event Recovered(address token, uint amount);


    /* ========== MODIFIERS ========== */

    modifier onlyKeeper {
        require(msg.sender == keeper || msg.sender == owner(), 'VaultController: caller is not the owner or keeper');
        _;
    }

    /* ========== INITIALIZER ========== */

    function __VaultController_init(IBEP20 token) internal initializer {
        __PausableUpgradeable_init();
        __WhitelistUpgradeable_init();

        keeper = 0x898Ae1562E8C1e9b9ADe052AA9c966df1Cf09452;
        _stakingToken = token;
    }

    /* ========== VIEWS FUNCTIONS ========== */

    function minter() external view override returns (address) {
        return canMint() ? address(_minter) : address(0);
    }

    function canMint() internal view returns (bool) {
        return address(_minter) != address(0) && _minter.isMinter(address(this));
    }

    function bunnyChef() external view override returns (address) {
        return address(_bunnyChef);
    }

    function stakingToken() external view override returns (address) {
        return address(_stakingToken);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setKeeper(address _keeper) external onlyKeeper {
        require(_keeper != address(0), 'VaultController: invalid keeper address');
        keeper = _keeper;
    }

    function setMinter(address newMinter) virtual public onlyOwner {
        // can zero
        _minter = IBunnyMinterV2(newMinter);
        if (newMinter != address(0)) {
            require(newMinter == BUNNY.getOwner(), 'VaultController: not bunny minter');
            _stakingToken.safeApprove(newMinter, 0);
            _stakingToken.safeApprove(newMinter, uint(- 1));
        }
    }

    function setBunnyChef(IBunnyChef newBunnyChef) virtual public onlyOwner {
        require(address(_bunnyChef) == address(0), 'VaultController: setBunnyChef only once');
        _bunnyChef = newBunnyChef;
    }

    /* ========== SALVAGE PURPOSE ONLY ========== */

    function recoverToken(address _token, uint amount) virtual external onlyOwner {
        require(_token != address(_stakingToken), 'VaultController: cannot recover underlying token');
        IBEP20(_token).safeTransfer(owner(), amount);

        emit Recovered(_token, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.0;

import '../../access/Ownable.sol';
import '../../GSN/Context.sol';
import './IBEP20.sol';
import '../../math/SafeMath.sol';
import '../../utils/Address.sol';

/**
 * @dev Implementation of the {IBEP20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {BEP20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-BEP20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of BEP20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IBEP20-approve}.
 */
contract BEP20 is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external override view returns (address) {
        return owner();
    }

    /**
     * @dev Returns the token name.
     */
    function name() public override view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token decimals.
     */
    function decimals() public override view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the token symbol.
     */
    function symbol() public override view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {BEP20-totalSupply}.
     */
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {BEP20-balanceOf}.
     */
    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {BEP20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {BEP20-allowance}.
     */
    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {BEP20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {BEP20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {BEP20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, 'BEP20: transfer amount exceeds allowance')
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(subtractedValue, 'BEP20: decreased allowance below zero')
        );
        return true;
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `msg.sender`, increasing
     * the total supply.
     *
     * Requirements
     *
     * - `msg.sender` must be the token owner
     */
    function mint(uint256 amount) public onlyOwner returns (bool) {
        _mint(_msgSender(), amount);
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), 'BEP20: transfer from the zero address');
        require(recipient != address(0), 'BEP20: transfer to the zero address');

        _balances[sender] = _balances[sender].sub(amount, 'BEP20: transfer amount exceeds balance');
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), 'BEP20: mint to the zero address');

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), 'BEP20: burn from the zero address');

        _balances[account] = _balances[account].sub(amount, 'BEP20: burn amount exceeds balance');
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), 'BEP20: approve from the zero address');
        require(spender != address(0), 'BEP20: approve to the zero address');

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(
            account,
            _msgSender(),
            _allowances[account][_msgSender()].sub(amount, 'BEP20: burn amount exceeds allowance')
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

import './IPancakeRouter01.sol';

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IMasterChef {
    function cakePerBlock() view external returns(uint);
    function totalAllocPoint() view external returns(uint);

    function poolInfo(uint _pid) view external returns(address lpToken, uint allocPoint, uint lastRewardBlock, uint accCakePerShare);
    function userInfo(uint _pid, address _account) view external returns(uint amount, uint rewardDebt);
    function poolLength() view external returns(uint);

    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function emergencyWithdraw(uint256 _pid) external;

    function enterStaking(uint256 _amount) external;
    function leaveStaking(uint256 _amount) external;
}

/*
   ____            __   __        __   _
  / __/__ __ ___  / /_ / /  ___  / /_ (_)__ __
 _\ \ / // // _ \/ __// _ \/ -_)/ __// / \ \ /
/___/ \_, //_//_/\__//_//_/\__/ \__//_/ /_\_\
     /___/

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";


abstract contract PausableUpgradeable is OwnableUpgradeable {
    uint public lastPauseTime;
    bool public paused;

    event PauseChanged(bool isPaused);

    modifier notPaused {
        require(!paused, "PausableUpgradeable: cannot be performed while the contract is paused");
        _;
    }

    function __PausableUpgradeable_init() internal initializer {
        __Ownable_init();
        require(owner() != address(0), "PausableUpgradeable: owner must be set");
    }

    function setPaused(bool _paused) external onlyOwner {
        if (_paused == paused) {
            return;
        }

        paused = _paused;
        if (paused) {
            lastPauseTime = now;
        }

        emit PauseChanged(paused);
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/*
  ___                      _   _
 | _ )_  _ _ _  _ _ _  _  | | | |
 | _ \ || | ' \| ' \ || | |_| |_|
 |___/\_,_|_||_|_||_\_, | (_) (_)
                    |__/

*
* MIT License
* ===========
*
* Copyright (c) 2020 BunnyFinance
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

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract WhitelistUpgradeable is OwnableUpgradeable {
    mapping (address => bool) private _whitelist;
    bool private _disable;                      // default - false means whitelist feature is working on. if true no more use of whitelist

    event Whitelisted(address indexed _address, bool whitelist);
    event EnableWhitelist();
    event DisableWhitelist();

    modifier onlyWhitelisted {
        require(_disable || _whitelist[msg.sender], "Whitelist: caller is not on the whitelist");
        _;
    }

    function __WhitelistUpgradeable_init() internal initializer {
        __Ownable_init();
    }

    function isWhitelist(address _address) public view returns(bool) {
        return _whitelist[_address];
    }

    function setWhitelist(address _address, bool _on) external onlyOwner {
        _whitelist[_address] = _on;

        emit Whitelisted(_address, _on);
    }

    function disableWhitelist(bool disable) external onlyOwner {
        _disable = disable;
        if (disable) {
            emit DisableWhitelist();
        } else {
            emit EnableWhitelist();
        }
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

import '../GSN/Context.sol';

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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
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
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
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
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
  ___                      _   _
 | _ )_  _ _ _  _ _ _  _  | | | |
 | _ \ || | ' \| ' \ || | |_| |_|
 |___/\_,_|_||_|_||_\_, | (_) (_)
                    |__/

*
* MIT License
* ===========
*
* Copyright (c) 2020 BunnyFinance
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

import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol";
import "@openzeppelin/contracts/math/Math.sol";

import "../interfaces/IStrategy.sol";
import "../interfaces/IMasterChef.sol";
import "../interfaces/IBunnyMinter.sol";
import "./VaultController.sol";
import {PoolConstant} from "../library/PoolConstant.sol";


contract VaultCakeToCake is VaultController, IStrategy {
    using SafeBEP20 for IBEP20;
    using SafeMath for uint;

    /* ========== CONSTANTS ============= */

    IBEP20 private constant QUICK = IBEP20(0x831753DD7087CaC61aB5644b308642cc1c33Dc13);
    IMasterChef private constant QUICK_MASTER_CHEF = IMasterChef(0x73feaa1eE314F8c655E354234017bE2193C9E24E);    // TODO Chef

    uint public constant override pid = 0;
    PoolConstant.PoolTypes public constant override poolType = PoolConstant.PoolTypes.TokenToToken;

    uint private constant DUST = 1000;

    /* ========== STATE VARIABLES ========== */

    uint public totalShares;
    mapping (address => uint) private _shares;
    mapping (address => uint) private _principal;
    mapping (address => uint) private _depositedAt;

    /* ========== INITIALIZER ========== */

    function initialize() external initializer {
        __VaultController_init(QUICK);
        QUICK.safeApprove(address(QUICK_MASTER_CHEF), uint(- 1));

        setMinter(0x8cB88701790F650F273c8BB2Cc4c5f439cd65219);  // TODO minter
    }

    /* ========== VIEW FUNCTIONS ========== */

    function totalSupply() external view override returns (uint) {
        return totalShares;
    }

    function balance() public view override returns (uint amount) {
        (amount,) = QUICK_MASTER_CHEF.userInfo(pid, address(this));
    }

    function balanceOf(address account) public view override returns(uint) {
        if (totalShares == 0) return 0;
        return balance().mul(sharesOf(account)).div(totalShares);
    }

    function withdrawableBalanceOf(address account) public view override returns (uint) {
        return balanceOf(account);
    }

    function sharesOf(address account) public view override returns (uint) {
        return _shares[account];
    }

    function principalOf(address account) public view override returns (uint) {
        return _principal[account];
    }

    function earned(address account) public view override returns (uint) {
        if (balanceOf(account) >= principalOf(account) + DUST) {
            return balanceOf(account).sub(principalOf(account));
        } else {
            return 0;
        }
    }

    function priceShare() external view override returns(uint) {
        if (totalShares == 0) return 1e18;
        return balance().mul(1e18).div(totalShares);
    }

    function depositedAt(address account) external view override returns (uint) {
        return _depositedAt[account];
    }

    function rewardsToken() external view override returns (address) {
        return address(_stakingToken);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function deposit(uint _amount) public override {
        _deposit(_amount, msg.sender);

        if (isWhitelist(msg.sender) == false) {
            _principal[msg.sender] = _principal[msg.sender].add(_amount);
            _depositedAt[msg.sender] = block.timestamp;
        }
    }

    function depositAll() external override {
        deposit(QUICK.balanceOf(msg.sender));
    }

    function withdrawAll() external override {
        uint amount = balanceOf(msg.sender);
        uint principal = principalOf(msg.sender);
        uint depositTimestamp = _depositedAt[msg.sender];

        totalShares = totalShares.sub(_shares[msg.sender]);
        delete _shares[msg.sender];
        delete _principal[msg.sender];
        delete _depositedAt[msg.sender];

        uint cakeHarvested = _withdrawStakingToken(amount);

        uint profit = amount > principal ? amount.sub(principal) : 0;
        uint withdrawalFee = canMint() ? _minter.withdrawalFee(principal, depositTimestamp) : 0;
        uint performanceFee = canMint() ? _minter.performanceFee(profit) : 0;

        if (canMint()) {
            if (withdrawalFee.add(performanceFee) > DUST) {
                _minter.mintFor(address(QUICK), withdrawalFee, performanceFee, msg.sender, depositTimestamp);
                if (performanceFee > 0) {
                    emit ProfitPaid(msg.sender, profit, performanceFee);
                }
                amount = amount.sub(withdrawalFee).sub(performanceFee);
            }
        }

        QUICK.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount, withdrawalFee);

        _harvest(cakeHarvested);
    }

    function harvest() external override {
        uint cakeHarvested = _withdrawStakingToken(0);
        _harvest(cakeHarvested);
    }

    function withdraw(uint shares) external override onlyWhitelisted {
        uint amount = balance().mul(shares).div(totalShares);
        totalShares = totalShares.sub(shares);
        _shares[msg.sender] = _shares[msg.sender].sub(shares);

        uint cakeHarvested = _withdrawStakingToken(amount);
        QUICK.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount, 0);

        _harvest(cakeHarvested);
    }

    // @dev underlying only + withdrawal fee + no perf fee
    function withdrawUnderlying(uint _amount) external {
        uint amount = Math.min(_amount, _principal[msg.sender]);
        uint shares = Math.min(amount.mul(totalShares).div(balance()), _shares[msg.sender]);
        totalShares = totalShares.sub(shares);
        _shares[msg.sender] = _shares[msg.sender].sub(shares);
        _principal[msg.sender] = _principal[msg.sender].sub(amount);

        uint cakeHarvested = _withdrawStakingToken(amount);
        uint depositTimestamp = _depositedAt[msg.sender];
        uint withdrawalFee = canMint() ? _minter.withdrawalFee(amount, depositTimestamp) : 0;
        if (canMint()) {
            if (withdrawalFee > DUST) {
                _minter.mintFor(address(QUICK), withdrawalFee, 0, msg.sender, depositTimestamp);
                amount = amount.sub(withdrawalFee);
            }
        }

        QUICK.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount, withdrawalFee);

        _harvest(cakeHarvested);
    }

    function getReward() external override {
        uint amount = earned(msg.sender);
        uint shares = Math.min(amount.mul(totalShares).div(balance()), _shares[msg.sender]);
        totalShares = totalShares.sub(shares);
        _shares[msg.sender] = _shares[msg.sender].sub(shares);
        _cleanupIfDustShares();

        uint cakeHarvested = _withdrawStakingToken(amount);
        uint depositTimestamp = _depositedAt[msg.sender];
        uint performanceFee = canMint() ? _minter.performanceFee(amount) : 0;
        if(canMint()) {
            if (performanceFee > DUST) {
                _minter.mintFor(address(QUICK), 0, performanceFee, msg.sender, depositTimestamp);
                amount = amount.sub(performanceFee);
            }
        }

        QUICK.safeTransfer(msg.sender, amount);
        emit ProfitPaid(msg.sender, amount, performanceFee);

        _harvest(cakeHarvested);
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _depositStakingToken(uint amount) private returns(uint cakeHarvested) {
        uint before = QUICK.balanceOf(address(this));
        QUICK_MASTER_CHEF.enterStaking(amount);
        cakeHarvested = QUICK.balanceOf(address(this)).add(amount).sub(before);
    }

    function _withdrawStakingToken(uint amount) private returns(uint cakeHarvested) {
        uint before = QUICK.balanceOf(address(this));
        QUICK_MASTER_CHEF.leaveStaking(amount);
        cakeHarvested = QUICK.balanceOf(address(this)).sub(amount).sub(before);
    }

    function _harvest(uint cakeAmount) private {
        if (cakeAmount > 0) {
            emit Harvested(cakeAmount);
            QUICK_MASTER_CHEF.enterStaking(cakeAmount);
        }
    }

    function _deposit(uint _amount, address _to) private notPaused {
        uint _pool = balance();
        QUICK.safeTransferFrom(msg.sender, address(this), _amount);
        uint shares = 0;
        if (totalShares == 0) {
            shares = _amount;
        } else {
            shares = (_amount.mul(totalShares)).div(_pool);
        }

        totalShares = totalShares.add(shares);
        _shares[_to] = _shares[_to].add(shares);

        uint cakeHarvested = _depositStakingToken(_amount);
        emit Deposited(msg.sender, _amount);

        _harvest(cakeHarvested);
    }

    function _cleanupIfDustShares() private {
        uint shares = _shares[msg.sender];
        if (shares > 0 && shares < DUST) {
            totalShares = totalShares.sub(shares);
            delete _shares[msg.sender];
        }
    }

    /* ========== SALVAGE PURPOSE ONLY ========== */

    // @dev _stakingToken(CAKE) must not remain balance in this contract. So dev should be able to salvage staking token transferred by mistake.
    function recoverToken(address _token, uint amount) virtual external override onlyOwner {
        IBEP20(_token).safeTransfer(owner(), amount);

        emit Recovered(_token, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IBunnyMinter {
    function isMinter(address) view external returns(bool);
    function amountBunnyToMint(uint bnbProfit) view external returns(uint);
    function amountBunnyToMintForBunnyBNB(uint amount, uint duration) view external returns(uint);
    function withdrawalFee(uint amount, uint depositedAt) view external returns(uint);
    function performanceFee(uint profit) view external returns(uint);
    function mintFor(address flip, uint _withdrawalFee, uint _performanceFee, address to, uint depositedAt) external;
    function mintForBunnyBNB(uint amount, uint duration, address to) external;

    function bunnyPerProfitBNB() view external returns(uint);
    function WITHDRAWAL_FEE_FREE_PERIOD() view external returns(uint);
    function WITHDRAWAL_FEE() view external returns(uint);

    function setMinter(address minter, bool canMint) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
  ___                      _   _
 | _ )_  _ _ _  _ _ _  _  | | | |
 | _ \ || | ' \| ' \ || | |_| |_|
 |___/\_,_|_||_|_||_\_, | (_) (_)
                    |__/

*
* MIT License
* ===========
*
* Copyright (c) 2020 BunnyFinance
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

import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol";
import "@openzeppelin/contracts/math/Math.sol";

import {PoolConstant} from "../library/PoolConstant.sol";
import "../interfaces/IPancakePair.sol";
import "../interfaces/IPancakeFactory.sol";
import "../interfaces/IStrategy.sol";
import "../interfaces/IMasterChef.sol";
import "../interfaces/IBunnyMinter.sol";
import "../interfaces/IQuickStakingRewards.sol";
import "../interfaces/IZap.sol";

import "./VaultController.sol";

contract VaultQuickFlipToFlip is VaultController, IStrategy {
    using SafeBEP20 for IBEP20;
    using SafeMath for uint256;

    /* ========== CONSTANTS ============= */

    IBEP20 private constant QUICK = IBEP20(0x831753DD7087CaC61aB5644b308642cc1c33Dc13);
    PoolConstant.PoolTypes public constant override poolType = PoolConstant.PoolTypes.FlipToFlip;
    IZap public constant zap = IZap(0x663462430834E220851a3E981D0E1199501b84F6);
    uint public constant override pid = 9999;

    uint private constant DUST = 1000;

    /* ========== STATE VARIABLES ========== */

    address private _token0;    // unused
    address private _token1;    // unused

    uint public totalShares;
    mapping (address => uint) private _shares;
    mapping (address => uint) private _principal;
    mapping (address => uint) private _depositedAt;

    IQuickStakingRewards private qVault;

    /* ========== INITIALIZER ========== */

    function initialize(address _token, address _qVault) external initializer {
        __VaultController_init(IBEP20(_token));

        qVault = IQuickStakingRewards(_qVault);
        _stakingToken.safeApprove(address(_qVault), uint(- 1));
        QUICK.safeApprove(address(zap), uint(- 1));
    }

    /* ========== VIEW FUNCTIONS ========== */

    function totalSupply() external view override returns (uint) {
        return totalShares;
    }

    function balance() public view override returns (uint amount) {
        amount = qVault.balanceOf(address(this));
    }

    function balanceOf(address account) public view override returns(uint) {
        if (totalShares == 0) return 0;
        return balance().mul(sharesOf(account)).div(totalShares);
    }

    function withdrawableBalanceOf(address account) public view override returns (uint) {
        return balanceOf(account);
    }

    function sharesOf(address account) public view override returns (uint) {
        return _shares[account];
    }

    function principalOf(address account) public view override returns (uint) {
        return _principal[account];
    }

    function earned(address account) public view override returns (uint) {
        if (balanceOf(account) >= principalOf(account) + DUST) {
            return balanceOf(account).sub(principalOf(account));
        } else {
            return 0;
        }
    }

    function depositedAt(address account) external view override returns (uint) {
        return _depositedAt[account];
    }

    function rewardsToken() external view override returns (address) {
        return address(_stakingToken);
    }

    function priceShare() external view override returns(uint) {
        if (totalShares == 0) return 1e18;
        return balance().mul(1e18).div(totalShares);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function deposit(uint _amount) public override {
        _depositTo(_amount, msg.sender);
    }

    function depositAll() external override {
        deposit(_stakingToken.balanceOf(msg.sender));
    }

    function withdrawAll() external override {
        uint amount = balanceOf(msg.sender);
        uint principal = principalOf(msg.sender);
        uint depositTimestamp = _depositedAt[msg.sender];

        totalShares = totalShares.sub(_shares[msg.sender]);
        delete _shares[msg.sender];
        delete _principal[msg.sender];
        delete _depositedAt[msg.sender];

        amount = _withdrawTokenWithCorrection(amount);
        uint profit = amount > principal ? amount.sub(principal) : 0;

        uint withdrawalFee = canMint() ? _minter.withdrawalFee(principal, depositTimestamp) : 0;
        uint performanceFee = canMint() ? _minter.performanceFee(profit) : 0;
        if (canMint()) {
            if (withdrawalFee.add(performanceFee) > DUST) {
                _minter.mintForV2(address(_stakingToken), withdrawalFee, performanceFee, msg.sender, depositTimestamp);

                if (performanceFee > 0) {
                    emit ProfitPaid(msg.sender, profit, performanceFee);
                }
                amount = amount.sub(withdrawalFee).sub(performanceFee);
            }
        }

        _stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount, withdrawalFee);
    }

    function harvest() external override onlyKeeper {
        uint quickHarvested = _harvest();

        uint before = _stakingToken.balanceOf(address(this));
        zap.zapInToken(address(QUICK), quickHarvested, address(_stakingToken));
        uint harvested = _stakingToken.balanceOf(address(this)).sub(before);

        qVault.stake(harvested);
        emit Harvested(harvested);
    }

    function _harvest() private returns(uint) {
        uint before = QUICK.balanceOf(address(this));
        qVault.getReward();
        return QUICK.balanceOf(address(this)).sub(before);
    }

    function withdraw(uint shares) external override onlyWhitelisted {
        uint amount = balance().mul(shares).div(totalShares);
        totalShares = totalShares.sub(shares);
        _shares[msg.sender] = _shares[msg.sender].sub(shares);

        amount = _withdrawTokenWithCorrection(amount);
        _stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount, 0);
    }

    // @dev underlying only + withdrawal fee + no perf fee
    function withdrawUnderlying(uint _amount) external {
        uint amount = Math.min(_amount, _principal[msg.sender]);
        uint shares = Math.min(amount.mul(totalShares).div(balance()), _shares[msg.sender]);
        totalShares = totalShares.sub(shares);
        _shares[msg.sender] = _shares[msg.sender].sub(shares);
        _principal[msg.sender] = _principal[msg.sender].sub(amount);

        amount = _withdrawTokenWithCorrection(amount);
        uint depositTimestamp = _depositedAt[msg.sender];
        uint withdrawalFee = canMint() ? _minter.withdrawalFee(amount, depositTimestamp) : 0;
        if (canMint()){
            if (withdrawalFee > DUST) {
                _minter.mintForV2(address(_stakingToken), withdrawalFee, 0, msg.sender, depositTimestamp);
                amount = amount.sub(withdrawalFee);
            }
        }

        _stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount, withdrawalFee);
    }

    // @dev profits only (underlying + bunny) + no withdraw fee + perf fee
    function getReward() external override {
        uint amount = earned(msg.sender);
        uint shares = Math.min(amount.mul(totalShares).div(balance()), _shares[msg.sender]);
        totalShares = totalShares.sub(shares);
        _shares[msg.sender] = _shares[msg.sender].sub(shares);
        _cleanupIfDustShares();

        amount = _withdrawTokenWithCorrection(amount);
        uint depositTimestamp = _depositedAt[msg.sender];
        uint performanceFee = canMint() ? _minter.performanceFee(amount) : 0;
        if (canMint()) {
            if (performanceFee > DUST) {
                _minter.mintForV2(address(_stakingToken), 0, performanceFee, msg.sender, depositTimestamp);
                amount = amount.sub(performanceFee);
            }
        }
        _stakingToken.safeTransfer(msg.sender, amount);
        emit ProfitPaid(msg.sender, amount, performanceFee);
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _depositTo(uint _amount, address _to) private notPaused {
        uint _pool = balance();
        uint _before = _stakingToken.balanceOf(address(this));
        _stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
        uint _after = _stakingToken.balanceOf(address(this));
        _amount = _after.sub(_before); // Additional check for deflationary tokens
        uint shares = 0;
        if (totalShares == 0) {
            shares = _amount;
        } else {
            shares = (_amount.mul(totalShares)).div(_pool);
        }

        totalShares = totalShares.add(shares);
        _shares[_to] = _shares[_to].add(shares);
        _principal[_to] = _principal[_to].add(_amount);
        _depositedAt[_to] = block.timestamp;

        qVault.stake(_amount);
        emit Deposited(_to, _amount);
    }

    function _withdrawTokenWithCorrection(uint amount) private returns (uint) {
        uint before = _stakingToken.balanceOf(address(this));
        qVault.withdraw(amount);
        return _stakingToken.balanceOf(address(this)).sub(before);
    }

    function _cleanupIfDustShares() private {
        uint shares = _shares[msg.sender];
        if (shares > 0 && shares < DUST) {
            totalShares = totalShares.sub(shares);
            delete _shares[msg.sender];
        }
    }

    /* ========== SALVAGE PURPOSE ONLY ========== */

    // @dev stakingToken must not remain balance in this contract. So dev should salvage staking token transferred by mistake.
    function recoverToken(address token, uint amount) external override onlyOwner {
        IBEP20(token).safeTransfer(owner(), amount);
        emit Recovered(token, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface IQuickStakingRewards {
    // Views
    function lastTimeRewardApplicable() external view returns (uint256);
    function periodFinish() external view returns (uint256);
    function rewardRate() external view returns (uint256);
    function rewardPerToken() external view returns (uint256);
    function earned(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);

    // Mutative
    function stake(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function getReward() external;
    function exit() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/*
  ___                      _   _
 | _ )_  _ _ _  _ _ _  _  | | | |
 | _ \ || | ' \| ' \ || | |_| |_|
 |___/\_,_|_||_|_||_\_, | (_) (_)
                    |__/

*
* MIT License
* ===========
*
* Copyright (c) 2020 BunnyFinance
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

import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {IUniswapV2Pair  as ISushiswapV2Pair} from"../interfaces/IUniswapV2Pair.sol";
import {IUniswapV2Router02  as ISushiswapV2Router02} from "../interfaces/IUniswapV2Router02.sol";
import "../interfaces/IZap.sol";
import "../interfaces/IWMATIC.sol";

contract ZapSushi is IZap, OwnableUpgradeable {
    using SafeMath for uint;
    using SafeBEP20 for IBEP20;

    /* ========== CONSTANT VARIABLES ========== */

    address private constant WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

    address private constant DAI = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;
    address private constant USDT = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
    address private constant USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address private constant SUSHI = 0x0b3F868E0BE5597D5DB7fEB59E1CADBb0fdDa50a;

    address private constant BTC = 0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6;
    address private constant ETH = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
    address private constant AAVE = 0xD6DF932A45C0f255f85145f286eA0b292B21C90B;
    address private constant LINK = 0x53E0bca35eC356BD5ddDFebbD1Fc0fD03FaBad39;
    address private constant IBBTC = 0x4EaC4c4e9050464067D673102F8E24b2FccEB350;
    address private constant FRAX = 0x104592a158490a9228070E0A8e5343B499e125D0;

    ISushiswapV2Router02 private constant ROUTER = ISushiswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);

    /* ========== STATE VARIABLES ========== */

    mapping(address => bool) public notFlip;
    mapping(address => address) private routePairAddresses;
    address[] public tokens;

    /* ========== INITIALIZER ========== */

    function initialize() external initializer {
        __Ownable_init();
        require(owner() != address(0), "Zap: owner must be set");

        setNotFlip(WMATIC);
        setNotFlip(DAI);
        setNotFlip(USDC);
        setNotFlip(USDT);
        setNotFlip(BTC);
        setNotFlip(ETH);
        setNotFlip(SUSHI);
        setNotFlip(AAVE);
        setNotFlip(IBBTC);
        setNotFlip(LINK);
        setNotFlip(FRAX);


        setRoutePairAddress(BTC, ETH);
        setRoutePairAddress(USDC, ETH);
        setRoutePairAddress(USDT, ETH);
        setRoutePairAddress(DAI, ETH);
        setRoutePairAddress(AAVE, ETH);
        setRoutePairAddress(SUSHI, ETH);
        setRoutePairAddress(IBBTC, BTC);
        setRoutePairAddress(FRAX, USDC);
    }

    receive() external payable {}


    /* ========== View Functions ========== */

    function isFlip(address _address) public view returns (bool) {
        return !notFlip[_address];
    }

    function covers(address _token) public override view returns (bool) {
        return notFlip[_token];
    }

    function routePair(address _address) external view returns (address) {
        return routePairAddresses[_address];
    }

    /* ========== External Functions ========== */

    function zapInToken(address _from, uint amount, address _to) external override {
        IBEP20(_from).safeTransferFrom(msg.sender, address(this), amount);
        _approveTokenIfNeeded(_from);

        if (isFlip(_to)) {
            ISushiswapV2Pair pair = ISushiswapV2Pair(_to);
            address token0 = pair.token0();
            address token1 = pair.token1();
            if (_from == token0 || _from == token1) {
                // swap half amount for other
                address other = _from == token0 ? token1 : token0;
                _approveTokenIfNeeded(other);
                uint sellAmount = amount.div(2);
                uint otherAmount = _swap(_from, sellAmount, other, address(this));
                ROUTER.addLiquidity(_from, other, amount.sub(sellAmount), otherAmount, 0, 0, msg.sender, block.timestamp);
            } else {
                uint maticAmount;
                if (_from == WMATIC) {
                    IWMATIC(WMATIC).withdraw(amount);
                    maticAmount = amount;
                } else {
                    maticAmount = _swapTokenForMATIC(_from, amount, address(this));
                }

                _swapMATICToFlip(_to, maticAmount, msg.sender);
            }
        } else {
            _swap(_from, amount, _to, msg.sender);
        }
    }

    function zapIn(address _to) external payable override {
        _swapMATICToFlip(_to, msg.value, msg.sender);
    }

    function zapOut(address _from, uint amount) external override {
        IBEP20(_from).safeTransferFrom(msg.sender, address(this), amount);
        _approveTokenIfNeeded(_from);

        if (!isFlip(_from)) {
            _swapTokenForMATIC(_from, amount, msg.sender);
        } else {
            ISushiswapV2Pair pair = ISushiswapV2Pair(_from);
            address token0 = pair.token0();
            address token1 = pair.token1();
            if (token0 == WMATIC || token1 == WMATIC) {
                ROUTER.removeLiquidityETH(token0 != WMATIC ? token0 : token1, amount, 0, 0, msg.sender, block.timestamp);
            } else {
                ROUTER.removeLiquidity(token0, token1, amount, 0, 0, msg.sender, block.timestamp);
            }
        }
    }

    /* ========== Private Functions ========== */

    function _approveTokenIfNeeded(address token) private {
        if (IBEP20(token).allowance(address(this), address(ROUTER)) == 0) {
            IBEP20(token).safeApprove(address(ROUTER), uint(- 1));
        }
    }

    function _swapMATICToFlip(address flip, uint amount, address receiver) private {
        if (!isFlip(flip)) {
            _swapMATICForToken(flip, amount, receiver);
        } else {
            // flip
            ISushiswapV2Pair pair = ISushiswapV2Pair(flip);
            address token0 = pair.token0();
            address token1 = pair.token1();
            if (token0 == WMATIC || token1 == WMATIC) {
                address token = token0 == WMATIC ? token1 : token0;
                uint swapValue = amount.div(2);
                uint tokenAmount = _swapMATICForToken(token, swapValue, address(this));

                _approveTokenIfNeeded(token);
                ROUTER.addLiquidityETH{value : amount.sub(swapValue)}(token, tokenAmount, 0, 0, receiver, block.timestamp);
            } else {
                uint swapValue = amount.div(2);
                uint token0Amount = _swapMATICForToken(token0, swapValue, address(this));
                uint token1Amount = _swapMATICForToken(token1, amount.sub(swapValue), address(this));

                _approveTokenIfNeeded(token0);
                _approveTokenIfNeeded(token1);
                ROUTER.addLiquidity(token0, token1, token0Amount, token1Amount, 0, 0, receiver, block.timestamp);
            }
        }
    }

    function _swapMATICForToken(address token, uint value, address receiver) private returns (uint) {
        address[] memory path;

        if (routePairAddresses[token] != address(0)) {
            path = new address[](3);
            path[0] = WMATIC;
            path[1] = routePairAddresses[token];
            path[2] = token;
        } else {
            path = new address[](2);
            path[0] = WMATIC;
            path[1] = token;
        }

        uint[] memory amounts = ROUTER.swapExactETHForTokens{value : value}(0, path, receiver, block.timestamp);
        return amounts[amounts.length - 1];
    }

    function _swapTokenForMATIC(address token, uint amount, address receiver) private returns (uint) {
        address[] memory path;
        if (routePairAddresses[token] != address(0)) {
            path = new address[](3);
            path[0] = token;
            path[1] = routePairAddresses[token];
            path[2] = WMATIC;
        } else {
            path = new address[](2);
            path[0] = token;
            path[1] = WMATIC;
        }

        uint[] memory amounts = ROUTER.swapExactTokensForETH(amount, 0, path, receiver, block.timestamp);
        return amounts[amounts.length - 1];
    }

    function _swap(address _from, uint amount, address _to, address receiver) private returns (uint) {
        address intermediate = routePairAddresses[_from];
        if (intermediate == address(0)) {
            intermediate = routePairAddresses[_to];
        }

        address[] memory path;
        if (intermediate != address(0) && (_from == WMATIC || _to == WMATIC)) {
            // [BTC, ETH, USDC] or [USDC, ETH, BTC]
            path = new address[](3);
            path[0] = _from;
            path[1] = intermediate;
            path[2] = _to;
        } else if (intermediate != address(0) && (_from == intermediate || _to == intermediate)) {
            // [BTC, ETH] or [ETH, BTC]
            path = new address[](2);
            path[0] = _from;
            path[1] = _to;
        } else if (intermediate != address(0) && routePairAddresses[_from] == routePairAddresses[_to]) {
            // [BTC, ETH, USDC] or [USDC, ETH, BTC]
            path = new address[](3);
            path[0] = _from;
            path[1] = intermediate;
            path[2] = _to;
        } else if (routePairAddresses[_from] != address(0) && routePairAddresses[_to] != address(0) && routePairAddresses[_from] != routePairAddresses[_to]) {
            // routePairAddresses[xToken] = xRoute
            // [IBBTC, BTC, ETH, USDC, FRAX]
            path = new address[](5);
            path[0] = _from;
            path[1] = routePairAddresses[_from];
            path[2] = WMATIC;
            path[3] = routePairAddresses[_to];
            path[4] = _to;
        } else if (intermediate != address(0) && routePairAddresses[_from] != address(0)) {
            // [USDC, ETH, WMATIC, LINK]
            path = new address[](4);
            path[0] = _from;
            path[1] = intermediate;
            path[2] = WMATIC;
            path[3] = _to;
        } else if (intermediate != address(0) && routePairAddresses[_to] != address(0)) {
            // [LINK, WMATIC, ETH, USDC]
            path = new address[](4);
            path[0] = _from;
            path[1] = WMATIC;
            path[2] = intermediate;
            path[3] = _to;
        } else if (_from == WMATIC || _to == WMATIC) {
            // [WMATIC, LINK] or [LINK, WMATIC]
            path = new address[](2);
            path[0] = _from;
            path[1] = _to;
        } else {
            // [LINK, WMATIC, X] or [X, WMATIC, LINK]
            path = new address[](3);
            path[0] = _from;
            path[1] = WMATIC;
            path[2] = _to;
        }

        uint[] memory amounts = ROUTER.swapExactTokensForTokens(amount, 0, path, receiver, block.timestamp);
        return amounts[amounts.length - 1];
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setRoutePairAddress(address asset, address route) public onlyOwner {
        routePairAddresses[asset] = route;
    }

    function setNotFlip(address token) public onlyOwner {
        bool needPush = notFlip[token] == false;
        notFlip[token] = true;
        if (needPush) {
            tokens.push(token);
        }
    }

    function removeToken(uint i) external onlyOwner {
        address token = tokens[i];
        notFlip[token] = false;
        tokens[i] = tokens[tokens.length - 1];
        tokens.pop();
    }

    function sweep() external onlyOwner {
        for (uint i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            if (token == address(0)) continue;
            uint amount = IBEP20(token).balanceOf(address(this));
            if (amount > 0) {
                _swapTokenForMATIC(token, amount, owner());
            }
        }
    }

    function withdraw(address token) external onlyOwner {
        if (token == address(0)) {
            payable(owner()).transfer(address(this).balance);
            return;
        }

        IBEP20(token).transfer(owner(), IBEP20(token).balanceOf(address(this)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IWMATIC {
    function approve(address spender, uint value) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);

    function deposit() external payable;
    function withdraw(uint amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/*
  ___                      _   _
 | _ )_  _ _ _  _ _ _  _  | | | |
 | _ \ || | ' \| ' \ || | |_| |_|
 |___/\_,_|_||_|_||_\_, | (_) (_)
                    |__/

*
* MIT License
* ===========
*
* Copyright (c) 2020 BunnyFinance
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

import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../interfaces/IPancakePair.sol";
import "../interfaces/IPancakeRouter02.sol";
import "../interfaces/IZap.sol";
import "../interfaces/IWMATIC.sol";

contract ZapPolygon is IZap, OwnableUpgradeable {
    using SafeMath for uint;
    using SafeBEP20 for IBEP20;

    /* ========== CONSTANT VARIABLES ========== */

    address private constant BUNNY = 0x4C16f69302CcB511c5Fac682c7626B9eF0Dc126a;
    address private constant WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

    address private constant DAI = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;
    address private constant USDT = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
    address private constant USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address private constant QUICK = 0x831753DD7087CaC61aB5644b308642cc1c33Dc13;
    address private constant BTC = 0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6;
    address private constant ETH = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
    address private constant AAVE = 0xD6DF932A45C0f255f85145f286eA0b292B21C90B;


    IPancakeRouter02 private constant ROUTER = IPancakeRouter02(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);

    /* ========== STATE VARIABLES ========== */

    mapping(address => bool) private notFlip;
    mapping(address => address) private routePairAddresses;
    address[] public tokens;

    /* ========== INITIALIZER ========== */

    function initialize() external initializer {
        __Ownable_init();
        require(owner() != address(0), "Zap: owner must be set");

        setNotFlip(WMATIC);
        setNotFlip(BUNNY);
        setNotFlip(DAI);
        setNotFlip(USDC);
        setNotFlip(USDT);
        setNotFlip(BTC);
        setNotFlip(ETH);
        setNotFlip(QUICK);
        setNotFlip(AAVE);

        setRoutePairAddress(BTC, ETH);
        setRoutePairAddress(USDC, ETH);
        setRoutePairAddress(USDT, ETH);
        setRoutePairAddress(DAI, ETH);
        setRoutePairAddress(AAVE, ETH);
        setRoutePairAddress(BUNNY, ETH);
    }

    receive() external payable {}


    /* ========== View Functions ========== */

    function isFlip(address _address) public view returns (bool) {
        return !notFlip[_address];
    }

    function covers(address _token) public view override returns (bool) {
        return notFlip[_token];
    }

    function routePair(address _address) external view returns (address) {
        return routePairAddresses[_address];
    }

    /* ========== External Functions ========== */

    function zapInToken(address _from, uint amount, address _to) external override {
        IBEP20(_from).safeTransferFrom(msg.sender, address(this), amount);
        _approveTokenIfNeeded(_from);

        if (isFlip(_to)) {
            IPancakePair pair = IPancakePair(_to);
            address token0 = pair.token0();
            address token1 = pair.token1();
            if (_from == token0 || _from == token1) {
                // swap half amount for other
                address other = _from == token0 ? token1 : token0;
                _approveTokenIfNeeded(other);
                uint sellAmount = amount.div(2);
                uint otherAmount = _swap(_from, sellAmount, other, address(this));
                ROUTER.addLiquidity(_from, other, amount.sub(sellAmount), otherAmount, 0, 0, msg.sender, block.timestamp);
            } else {
                uint maticAmount;
                if (_from == WMATIC) {
                    IWMATIC(WMATIC).withdraw(amount);
                    maticAmount = amount;
                } else {
                    maticAmount = _swapTokenForMATIC(_from, amount, address(this));
                }

                _swapMATICToFlip(_to, maticAmount, msg.sender);
            }
        } else {
            _swap(_from, amount, _to, msg.sender);
        }
    }

    function zapIn(address _to) external payable override {
        _swapMATICToFlip(_to, msg.value, msg.sender);
    }

    function zapOut(address _from, uint amount) external override {
        IBEP20(_from).safeTransferFrom(msg.sender, address(this), amount);
        _approveTokenIfNeeded(_from);

        if (!isFlip(_from)) {
            _swapTokenForMATIC(_from, amount, msg.sender);
        } else {
            IPancakePair pair = IPancakePair(_from);
            address token0 = pair.token0();
            address token1 = pair.token1();
            if (token0 == WMATIC || token1 == WMATIC) {
                ROUTER.removeLiquidityETH(token0 != WMATIC ? token0 : token1, amount, 0, 0, msg.sender, block.timestamp);
            } else {
                ROUTER.removeLiquidity(token0, token1, amount, 0, 0, msg.sender, block.timestamp);
            }
        }
    }

    /* ========== Private Functions ========== */

    function _approveTokenIfNeeded(address token) private {
        if (IBEP20(token).allowance(address(this), address(ROUTER)) == 0) {
            IBEP20(token).safeApprove(address(ROUTER), uint(- 1));
        }
    }

    function _swapMATICToFlip(address flip, uint amount, address receiver) private {
        if (!isFlip(flip)) {
            _swapMATICForToken(flip, amount, receiver);
        } else {
            // flip
            IPancakePair pair = IPancakePair(flip);
            address token0 = pair.token0();
            address token1 = pair.token1();
            if (token0 == WMATIC || token1 == WMATIC) {
                address token = token0 == WMATIC ? token1 : token0;
                uint swapValue = amount.div(2);
                uint tokenAmount = _swapMATICForToken(token, swapValue, address(this));

                _approveTokenIfNeeded(token);
                ROUTER.addLiquidityETH{value : amount.sub(swapValue)}(token, tokenAmount, 0, 0, receiver, block.timestamp);
            } else {
                uint swapValue = amount.div(2);
                uint token0Amount = _swapMATICForToken(token0, swapValue, address(this));
                uint token1Amount = _swapMATICForToken(token1, amount.sub(swapValue), address(this));

                _approveTokenIfNeeded(token0);
                _approveTokenIfNeeded(token1);
                ROUTER.addLiquidity(token0, token1, token0Amount, token1Amount, 0, 0, receiver, block.timestamp);
            }
        }
    }

    function _swapMATICForToken(address token, uint value, address receiver) private returns (uint) {
        address[] memory path;

        if (routePairAddresses[token] != address(0)) {
            path = new address[](3);
            path[0] = WMATIC;
            path[1] = routePairAddresses[token];
            path[2] = token;
        } else {
            path = new address[](2);
            path[0] = WMATIC;
            path[1] = token;
        }

        uint[] memory amounts = ROUTER.swapExactETHForTokens{value : value}(0, path, receiver, block.timestamp);
        return amounts[amounts.length - 1];
    }

    function _swapTokenForMATIC(address token, uint amount, address receiver) private returns (uint) {
        address[] memory path;
        if (routePairAddresses[token] != address(0)) {
            path = new address[](3);
            path[0] = token;
            path[1] = routePairAddresses[token];
            path[2] = WMATIC;
        } else {
            path = new address[](2);
            path[0] = token;
            path[1] = WMATIC;
        }
        uint[] memory amounts = ROUTER.swapExactTokensForETH(amount, 0, path, receiver, block.timestamp);
        return amounts[amounts.length - 1];
    }

    function _swap(address _from, uint amount, address _to, address receiver) private returns (uint) {
        address intermediate = routePairAddresses[_from];
        if (intermediate == address(0)) {
            intermediate = routePairAddresses[_to];
        }

        address[] memory path;
        if (intermediate != address(0) && (_from == WMATIC || _to == WMATIC)) {
            // [WMATIC, QUICK, X] or [X, QUICK, WMATIC]
            path = new address[](3);
            path[0] = _from;
            path[1] = intermediate;
            path[2] = _to;
        } else if (intermediate != address(0) && (_from == intermediate || _to == intermediate)) {
            // [BTC, ETH] or [ETH, BTC]
            path = new address[](2);
            path[0] = _from;
            path[1] = _to;
        } else if (intermediate != address(0) && routePairAddresses[_from] == routePairAddresses[_to]) {
            // [BTC, ETH, DAI] or [DAI, ETH, BTC]
            path = new address[](3);
            path[0] = _from;
            path[1] = intermediate;
            path[2] = _to;
        } else if (routePairAddresses[_from] != address(0) && routePairAddresses[_to] != address(0) && routePairAddresses[_from] != routePairAddresses[_to]) {
            // routePairAddresses[xToken] = xRoute
            // [X, BTC, ETH, USDC, Y]
            path = new address[](5);
            path[0] = _from;
            path[1] = routePairAddresses[_from];
            path[2] = WMATIC;
            path[3] = routePairAddresses[_to];
            path[4] = _to;
        } else if (intermediate != address(0) && routePairAddresses[_from] != address(0)) {
            // [BTC, ETH, WMATIC, QUICK]
            path = new address[](4);
            path[0] = _from;
            path[1] = intermediate;
            path[2] = WMATIC;
            path[3] = _to;
        } else if (intermediate != address(0) && routePairAddresses[_to] != address(0)) {
            // [QUICK, WMATIC, ETH, BTC]
            path = new address[](4);
            path[0] = _from;
            path[1] = WMATIC;
            path[2] = intermediate;
            path[3] = _to;
        } else if (_from == WMATIC || _to == WMATIC) {
            // [WMATIC, QUICK] or [QUICK, WMATIC]
            path = new address[](2);
            path[0] = _from;
            path[1] = _to;
        } else {
            // [QUICK, WMATIC, X] or [X, WMATIC, QUICK]
            path = new address[](3);
            path[0] = _from;
            path[1] = WMATIC;
            path[2] = _to;
        }

        uint[] memory amounts = ROUTER.swapExactTokensForTokens(amount, 0, path, receiver, block.timestamp);
        return amounts[amounts.length - 1];
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setRoutePairAddress(address asset, address route) public onlyOwner {
        routePairAddresses[asset] = route;
    }

    function setNotFlip(address token) public onlyOwner {
        bool needPush = notFlip[token] == false;
        notFlip[token] = true;
        if (needPush) {
            tokens.push(token);
        }
    }

    function removeToken(uint i) external onlyOwner {
        address token = tokens[i];
        notFlip[token] = false;
        tokens[i] = tokens[tokens.length - 1];
        tokens.pop();
    }

    function sweep() external onlyOwner {
        for (uint i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            if (token == address(0)) continue;
            uint amount = IBEP20(token).balanceOf(address(this));
            if (amount > 0) {
                _swapTokenForMATIC(token, amount, owner());
            }
        }
    }

    function withdraw(address token) external onlyOwner {
        if (token == address(0)) {
            payable(owner()).transfer(address(this).balance);
            return;
        }

        IBEP20(token).transfer(owner(), IBEP20(token).balanceOf(address(this)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/Math.sol";
import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol";

import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "../library/RewardsDistributionRecipientUpgradeable.sol";
import "../library/PausableUpgradeable.sol";

import "../interfaces/legacy/IStrategyHelper.sol";
import "../interfaces/IPancakeRouter02.sol";
import "../interfaces/legacy/IStrategyLegacy.sol";
import "../interfaces/IPriceCalculator.sol";


contract BunnyPool is IStrategyLegacy, RewardsDistributionRecipientUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    /* ========== CONSTANTS ========== */

    address public constant ETH = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;

    IBEP20 public constant stakingToken = IBEP20(0x4C16f69302CcB511c5Fac682c7626B9eF0Dc126a);
    IPancakeRouter02 private constant QUICK_ROUTER = IPancakeRouter02(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);
    IPriceCalculator public constant priceCalculator = IPriceCalculator(0xE3B11c3Bd6d90CfeBBb4FB9d59486B0381D38021);

    /* ========== STATE VARIABLES ========== */

    IBEP20 public rewardsToken; // bunny/bnb flip
    uint256 public periodFinish;
    uint256 public rewardRate;
    uint256 public rewardsDuration;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;


    /* ========== INITIALIZER ========== */

    function initialize() external initializer {
        __RewardsDistributionRecipient_init();
        __ReentrancyGuard_init();
        __PausableUpgradeable_init();

        periodFinish = 0;
        rewardRate = 0;
        rewardsDuration = 90 days;

        rewardsDistribution = msg.sender;

        IBEP20(ETH).safeApprove(address(QUICK_ROUTER), uint(- 1));
        stakingToken.safeApprove(address(QUICK_ROUTER), uint(- 1));
    }

    /* ========== VIEWS ========== */

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balance() override external view returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address account) override external view returns (uint256) {
        return _balances[account];
    }

    function principalOf(address account) override external view returns (uint256) {
        return _balances[account];
    }

    function profitOf(address account) override public view returns (uint _usd, uint _bunny, uint _bnb) {
        _usd = 0;
        _bunny = 0;
        (_bnb,) = priceCalculator.valueOfAsset(address(rewardsToken), earned(account));
    }

    function tvl() override public view returns (uint) {
        (uint priceInBNB,) = priceCalculator.valueOfAsset(address(stakingToken), _totalSupply);
        return priceInBNB;
    }

    function apy() override public view returns (uint _usd, uint _bunny, uint _bnb) {
        uint tokenDecimals = 1e18;
        uint __totalSupply = _totalSupply;
        if (__totalSupply == 0) {
            __totalSupply = tokenDecimals;
        }

        uint rewardPerTokenPerSecond = rewardRate.mul(tokenDecimals).div(__totalSupply);
        (uint bunnyPrice,) = priceCalculator.valueOfAsset(address(stakingToken), 1e18);
        (uint flipPrice,) = priceCalculator.valueOfAsset(address(rewardsToken), 1e18);

        _usd = 0;
        _bunny = 0;
        _bnb = rewardPerTokenPerSecond.mul(365 days).mul(flipPrice).div(bunnyPrice);
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
        rewardPerTokenStored.add(
            lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(_totalSupply)
        );
    }

    function earned(address account) public view returns (uint256) {
        return _balances[account].mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
    }

    function getRewardForDuration() external view returns (uint256) {
        return rewardRate.mul(rewardsDuration);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */
    function _deposit(uint256 amount, address _to) private nonReentrant notPaused updateReward(_to) {
        require(amount > 0, "amount");
        _totalSupply = _totalSupply.add(amount);
        _balances[_to] = _balances[_to].add(amount);
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(_to, amount);
    }

    function deposit(uint256 amount) override public {
        _deposit(amount, msg.sender);
    }

    function depositAll() override external {
        deposit(stakingToken.balanceOf(msg.sender));
    }

    function withdraw(uint256 amount) override public nonReentrant updateReward(msg.sender) {
        require(amount > 0, "amount");
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function withdrawAll() override external {
        uint _withdraw = _balances[msg.sender];
        if (_withdraw > 0) {
            withdraw(_withdraw);
        }
        getReward();
    }

    function getReward() override public nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            reward = _flipToWETH(reward);
            IBEP20(ETH).safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function _flipToWETH(uint amount) private returns (uint reward) {
        (uint rewardBunny,) = QUICK_ROUTER.removeLiquidity(
            address(stakingToken), ETH,
            amount, 0, 0, address(this), block.timestamp);
        address[] memory path = new address[](2);
        path[0] = address(stakingToken);
        path[1] = ETH;
        QUICK_ROUTER.swapExactTokensForTokens(rewardBunny, 0, path, address(this), block.timestamp);

        reward = IBEP20(ETH).balanceOf(address(this));
    }

    function harvest() override external {}


    /* ========== RESTRICTED FUNCTIONS ========== */

    function setRewardsToken(address _rewardsToken) external onlyOwner {
        require(address(rewardsToken) == address(0), "set rewards token already");

        rewardsToken = IBEP20(_rewardsToken);
        IBEP20(_rewardsToken).safeApprove(address(QUICK_ROUTER), uint(- 1));
    }

    function notifyRewardAmount(uint256 reward) override external onlyRewardsDistribution updateReward(address(0)) {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(rewardsDuration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(rewardsDuration);
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint _balance = rewardsToken.balanceOf(address(this));
        require(rewardRate <= _balance.div(rewardsDuration), "reward");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardAdded(reward);
    }

    function recoverBEP20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        require(tokenAddress != address(stakingToken) && tokenAddress != address(rewardsToken), "tokenAddress");
        IBEP20(tokenAddress).safeTransfer(owner(), tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    function setRewardsDuration(uint256 _rewardsDuration) external onlyOwner {
        require(periodFinish == 0 || block.timestamp > periodFinish, "period");
        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    }

    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }


    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
    event Recovered(address token, uint256 amount);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

/*
   ____            __   __        __   _
  / __/__ __ ___  / /_ / /  ___  / /_ (_)__ __
 _\ \ / // // _ \/ __// _ \/ -_)/ __// / \ \ /
/___/ \_, //_//_/\__//_//_/\__/ \__//_/ /_\_\
     /___/

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract RewardsDistributionRecipientUpgradeable is OwnableUpgradeable {
    address public rewardsDistribution;

    modifier onlyRewardsDistribution() {
        require(msg.sender == rewardsDistribution, "PausableUpgradeable: caller is not the rewardsDistribution");
        _;
    }

    function __RewardsDistributionRecipient_init() internal initializer {
        __Ownable_init();
    }

    function notifyRewardAmount(uint256 reward) virtual external;

    function setRewardsDistribution(address _rewardsDistribution) external onlyOwner {
        rewardsDistribution = _rewardsDistribution;
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/*
  ___                      _   _
 | _ )_  _ _ _  _ _ _  _  | | | |
 | _ \ || | ' \| ' \ || | |_| |_|
 |___/\_,_|_||_|_||_\_, | (_) (_)
                    |__/

*
* MIT License
* ===========
*
* Copyright (c) 2020 BunnyFinance
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

import "../IBunnyMinter.sol";

interface IStrategyHelper {
    function tokenPriceInBNB(address _token) view external returns(uint);
    function cakePriceInBNB() view external returns(uint);
    function bnbPriceInUSD() view external returns(uint);

    function flipPriceInBNB(address _flip) view external returns(uint);
    function flipPriceInUSD(address _flip) view external returns(uint);

    function profitOf(IBunnyMinter minter, address _flip, uint amount) external view returns (uint _usd, uint _bunny, uint _bnb);

    function tvl(address _flip, uint amount) external view returns (uint);    // in USD
    function tvlInBNB(address _flip, uint amount) external view returns (uint);    // in BNB
    function apy(IBunnyMinter minter, uint pid) external view returns(uint _usd, uint _bunny, uint _bnb);
    function compoundingAPY(uint pid, uint compoundUnit) view external returns(uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
  ___                      _   _
 | _ )_  _ _ _  _ _ _  _  | | | |
 | _ \ || | ' \| ' \ || | |_| |_|
 |___/\_,_|_||_|_||_\_, | (_) (_)
                    |__/

*
* MIT License
* ===========
*
* Copyright (c) 2020 BunnyFinance
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

interface IStrategyLegacy {
    struct Profit {
        uint usd;
        uint bunny;
        uint bnb;
    }

    struct APY {
        uint usd;
        uint bunny;
        uint bnb;
    }

    struct UserInfo {
        uint balance;
        uint principal;
        uint available;
        Profit profit;
        uint poolTVL;
        APY poolAPY;
    }

    function deposit(uint _amount) external;
    function depositAll() external;
    function withdraw(uint256 _amount) external;    // BUNNY STAKING POOL ONLY
    function withdrawAll() external;
    function getReward() external;                  // BUNNY STAKING POOL ONLY
    function harvest() external;

    function balance() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function principalOf(address account) external view returns (uint);
//    function withdrawableBalanceOf(address account) external view returns (uint);   // BUNNY STAKING POOL ONLY (deprecated)
    function profitOf(address account) external view returns (uint _usd, uint _bunny, uint _bnb);
//    function earned(address account) external view returns (uint);
    function tvl() external view returns (uint);    // in USD
    function apy() external view returns (uint _usd, uint _bunny, uint _bnb);

    /* ========== Strategy Information ========== */
//    function pid() external view returns (uint);
//    function poolType() external view returns (PoolTypes);
//    function isMinter() external view returns (bool, address);
//    function getDepositedAt(address account) external view returns (uint);
//    function getRewardsToken() external view returns (address);

//    function info(address account) external view returns (UserInfo memory);   // deprecated
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/*
  ___                      _   _
 | _ )_  _ _ _  _ _ _  _  | | | |
 | _ \ || | ' \| ' \ || | |_| |_|
 |___/\_,_|_||_|_||_\_, | (_) (_)
                    |__/

*
* MIT License
* ===========
*
* Copyright (c) 2020 BunnyFinance
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


interface IPriceCalculator {
    struct ReferenceData {
        uint lastData;
        uint lastUpdated;
    }

    function priceOfMATIC() view external returns (uint);
    function priceOfBunny() view external returns (uint);
    function priceOfETH() view external returns (uint);
    function pricesInUSD(address[] memory assets) external view returns (uint[] memory);
    function valueOfAsset(address asset, uint amount) external view returns (uint valueInBNB, uint valueInUSD);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
  ___                      _   _
 | _ )_  _ _ _  _ _ _  _  | | | |
 | _ \ || | ' \| ' \ || | |_| |_|
 |___/\_,_|_||_|_||_\_, | (_) (_)
                    |__/

*
* MIT License
* ===========
*
* Copyright (c) 2020 BunnyFinance
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

import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../library/SafeDecimal.sol";

import "../interfaces/IStrategy.sol";
import "../interfaces/ILockedStrategy.sol";
import "../interfaces/IBunnyMinter.sol";
import "../interfaces/IBunnyChef.sol";
import "../interfaces/IPriceCalculator.sol";


contract Dashboard is OwnableUpgradeable {
    using SafeMath for uint;
    using SafeDecimal for uint;

    IPriceCalculator public constant priceCalculator = IPriceCalculator(0xE3B11c3Bd6d90CfeBBb4FB9d59486B0381D38021);

    address public constant WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address public constant ETH = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
    address public constant BUNNY = 0x4C16f69302CcB511c5Fac682c7626B9eF0Dc126a;

    IBunnyChef private constant bunnyChef = IBunnyChef(0x3048d5B8EC1B034Ae947597a6A30a42F2e1fd82F);

    /* ========== STATE VARIABLES ========== */

    mapping(address => PoolConstant.PoolTypes) public poolTypes;
    mapping(address => bool) public perfExemptions;

    /* ========== INITIALIZER ========== */

    function initialize() external initializer {
        __Ownable_init();
    }

    /* ========== Restricted Operation ========== */

    function setPoolType(address pool, PoolConstant.PoolTypes poolType) public onlyOwner {
        poolTypes[pool] = poolType;
    }

    function setPerfExemption(address pool, bool exemption) public onlyOwner {
        perfExemptions[pool] = exemption;
    }

    /* ========== View Functions ========== */

    function poolTypeOf(address pool) public view returns (PoolConstant.PoolTypes) {
        return poolTypes[pool];
    }

    /* ========== Profit Calculation ========== */

    function calculateProfit(address pool, address account) public view returns (uint profit, uint profitInETH) {
        PoolConstant.PoolTypes poolType = poolTypes[pool];
        profit = 0;
        profitInETH = 0;

        if (poolType == PoolConstant.PoolTypes.BunnyETH) {
            // profit as bunny
            profit = bunnyChef.pendingBunny(pool, account);
            (profitInETH,) = priceCalculator.valueOfAsset(BUNNY, profit);
        }
        else if (poolType == PoolConstant.PoolTypes.FlipToFlip || poolType == PoolConstant.PoolTypes.BunnyToBunny) {
            // profit as underlying
            IStrategy strategy = IStrategy(pool);
            profit = strategy.earned(account);
            (profitInETH,) = priceCalculator.valueOfAsset(strategy.stakingToken(), profit);
        }
    }

    function profitOfPool(address pool, address account) public view returns (uint profit, uint bunny) {
        (uint profitCalculated, uint profitInETH) = calculateProfit(pool, account);
        profit = profitCalculated;
        bunny = 0;

        if (!perfExemptions[pool]) {
            IStrategy strategy = IStrategy(pool);
            if (strategy.minter() != address(0)) {
                profit = profit.mul(70).div(100);
                bunny = IBunnyMinter(strategy.minter()).amountBunnyToMint(profitInETH.mul(30).div(100));
            }

            if (strategy.bunnyChef() != address(0)) {
                bunny = bunny.add(bunnyChef.pendingBunny(pool, account));
            }
        }
    }

    /* ========== TVL Calculation ========== */

    function tvlOfPool(address pool) public view returns (uint tvl) {
        IStrategy strategy = IStrategy(pool);
        (, tvl) = priceCalculator.valueOfAsset(strategy.stakingToken(), strategy.balance());
    }

    /* ========== Pool Information ========== */

    function infoOfPool(address pool, address account) public view returns (PoolConstant.PoolInfo memory) {
        PoolConstant.PoolInfo memory poolInfo;

        IStrategy strategy = IStrategy(pool);
        (uint pBASE, uint pBUNNY) = profitOfPool(pool, account);

        poolInfo.pool = pool;
        poolInfo.balance = strategy.balanceOf(account);
        poolInfo.principal = strategy.principalOf(account);
        poolInfo.available = withdrawableOf(pool, account);
        poolInfo.tvl = tvlOfPool(pool);
        poolInfo.pBASE = pBASE;
        poolInfo.pBUNNY = pBUNNY;

        if (strategy.minter() != address(0)) {
            IBunnyMinter minter = IBunnyMinter(strategy.minter());
            poolInfo.depositedAt = strategy.depositedAt(account);
            poolInfo.feeDuration = minter.WITHDRAWAL_FEE_FREE_PERIOD();
            poolInfo.feePercentage = minter.WITHDRAWAL_FEE();
        }

        poolInfo.portfolio = portfolioOfPoolInUSD(pool, account);
        return poolInfo;
    }

    function poolsOf(address account, address[] memory pools) public view returns (PoolConstant.PoolInfo[] memory) {
        PoolConstant.PoolInfo[] memory results = new PoolConstant.PoolInfo[](pools.length);
        for (uint i = 0; i < pools.length; i++) {
            results[i] = infoOfPool(pools[i], account);
        }
        return results;
    }

    /* ========== Withdrawable Calculation ========== */

    function withdrawableOf(address pool, address account) public view returns (uint) {
        PoolConstant.PoolTypes poolType = poolTypes[pool];

        if (poolType == PoolConstant.PoolTypes.BunnyToBunny
            || poolType == PoolConstant.PoolTypes.BunnyETH) {
            return ILockedStrategy(pool).withdrawablePrincipalOf(account);
        }

        return IStrategy(pool).withdrawableBalanceOf(account);
    }

    /* ========== Portfolio Calculation ========== */

    function stakingTokenValueInUSD(address pool, address account) internal view returns (uint tokenInUSD) {
        if (IStrategy(pool).stakingToken() == address(0)) return 0;
        (, tokenInUSD) = priceCalculator.valueOfAsset(IStrategy(pool).stakingToken(), IStrategy(pool).principalOf(account));
    }

    function portfolioOfPoolInUSD(address pool, address account) internal view returns (uint) {
        uint tokenInUSD = stakingTokenValueInUSD(pool, account);
        (, uint profitInETH) = calculateProfit(pool, account);
        uint profitInBUNNY = 0;

        if (!perfExemptions[pool]) {
            IStrategy strategy = IStrategy(pool);
            if (strategy.minter() != address(0)) {
                profitInETH = profitInETH.mul(70).div(100);
                profitInBUNNY = IBunnyMinter(strategy.minter()).amountBunnyToMint(profitInETH.mul(30).div(100));
            }

            if ((poolTypes[pool] == PoolConstant.PoolTypes.BunnyETH || poolTypes[pool] == PoolConstant.PoolTypes.FlipToFlip)
                && strategy.bunnyChef() != address(0)) {
                profitInBUNNY = profitInBUNNY.add(bunnyChef.pendingBunny(pool, account));
            }
        }

        (, uint profitETHInUSD) = priceCalculator.valueOfAsset(ETH, profitInETH);
        (, uint profitBUNNYInUSD) = priceCalculator.valueOfAsset(BUNNY, profitInBUNNY);
        return tokenInUSD.add(profitETHInUSD).add(profitBUNNYInUSD);
    }

    function portfolioOf(address account, address[] memory pools) public view returns (uint deposits) {
        deposits = 0;
        for (uint i = 0; i < pools.length; i++) {
            deposits = deposits.add(portfolioOfPoolInUSD(pools[i], account));
        }
    }
}

/*
   ____            __   __        __   _
  / __/__ __ ___  / /_ / /  ___  / /_ (_)__ __
 _\ \ / // // _ \/ __// _ \/ -_)/ __// / \ \ /
/___/ \_, //_//_/\__//_//_/\__/ \__//_/ /_\_\
     /___/

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";


library SafeDecimal {
    using SafeMath for uint;

    uint8 public constant decimals = 18;
    uint public constant UNIT = 10 ** uint(decimals);

    function unit() external pure returns (uint) {
        return UNIT;
    }

    function multiply(uint x, uint y) internal pure returns (uint) {
        return x.mul(y).div(UNIT);
    }

    // https://mpark.github.io/programming/2014/08/18/exponentiation-by-squaring/
    function power(uint x, uint n) internal pure returns (uint) {
        uint result = UNIT;
        while (n > 0) {
            if (n % 2 != 0) {
                result = multiply(result, x);
            }
            x = multiply(x, x);
            n /= 2;
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface ILockedStrategy {
    function withdrawablePrincipalOf(address account) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
  ___                      _   _
 | _ )_  _ _ _  _ _ _  _  | | | |
 | _ \ || | ' \| ' \ || | |_| |_|
 |___/\_,_|_||_|_||_\_, | (_) (_)
                    |__/

*
* MIT License
* ===========
*
* Copyright (c) 2020 BunnyFinance
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

import "@openzeppelin/contracts/math/Math.sol";
import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import "../interfaces/IStrategy.sol";
import "../interfaces/IBunnyMinter.sol";
import "../interfaces/IBunnyChef.sol";
import "../interfaces/IPresale.sol";
import "./VaultController.sol";
import {PoolConstant} from "../library/PoolConstant.sol";
import "../interfaces/legacy/IStrategyLegacy.sol";
import "../interfaces/IZap.sol";

contract VaultBunnyMaximizer is VaultController, IStrategy, ReentrancyGuardUpgradeable {
    using SafeMath for uint;
    using SafeBEP20 for IBEP20;

    /* ========== CONSTANTS ============= */

    address private constant BUNNY = 0x4C16f69302CcB511c5Fac682c7626B9eF0Dc126a;
    address private constant WETH = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
    address private constant presaleContract = 0x172B554118ecd915C5F046819cA225351566566E;
    address private constant deadAddress = 0x000000000000000000000000000000000000dEaD;
    address private constant TIMELOCK = 0xf36eC1522625b2eBD0b4071945F3e97134653F8f;

    PoolConstant.PoolTypes public constant override poolType = PoolConstant.PoolTypes.BunnyToBunny;
    address public constant BUNNY_POOL = 0x10C8CFCa4953Bc554e71ddE3Fa19c335e163D7Ac;

    IZap public constant zap = IZap(0x663462430834E220851a3E981D0E1199501b84F6);

    uint private constant timestampPresaleEnds = 1625097600;
    uint private constant timestamp2HoursAfterPresaleEnds = timestampPresaleEnds + (2 hours);
    uint private constant timestamp90DaysAfterPresaleEnds = timestampPresaleEnds + (90 days);

    uint private constant DUST = 1000;

    uint public constant override pid = 9999;

    /* ========== STATE VARIABLES ========== */

    uint private totalShares;
    mapping (address => uint) private _shares;
    mapping (address => uint) private _principal;
    mapping (address => uint) private _depositedAt;
    mapping(address => bool) private _stakePermission;

    /* ========== PRESALE ============== */

    mapping(address => uint256) private _presaleBalance;

    /* ========== MODIFIERS ========== */

    modifier canStakeTo() {
        require(_stakePermission[msg.sender], 'VaultBunnyMaximizer: auth');
        _;
    }

    /* ========== INITIALIZER ========== */

    function initialize() external initializer {
        __VaultController_init(IBEP20(BUNNY));
        __ReentrancyGuard_init();

        _stakePermission[msg.sender] = true;
        _stakePermission[presaleContract] = true;
        IBEP20(WETH).approve(address(zap), uint(- 1));

        _stakingToken.approve(BUNNY_POOL, uint(- 1));
    }

    /* ========== VIEWS ========== */

    function totalSupply() external view override returns (uint) {
        return totalShares;
    }

    function balance() public view override returns (uint) {
        return IStrategyLegacy(BUNNY_POOL).balanceOf(address(this));
    }

    function balanceOf(address account) public view override returns (uint) {
        if (totalShares == 0) return 0;
        return balance().mul(sharesOf(account)).div(totalShares);
    }

    function sharesOf(address account) public view override returns (uint) {
        return _shares[account];
    }

    function presaleBalanceOf(address account) public view returns (uint) {
        return _presaleBalance[account];
    }

    function principalOf(address account) public view override returns (uint) {
        return _principal[account];
    }

    function earned(address account) public view override returns (uint) {
        if (balanceOf(account) >= principalOf(account) + DUST) {
            return balanceOf(account).sub(principalOf(account));
        } else {
            return 0;
        }
    }

    function depositedAt(address account) external view override returns (uint) {
        return _depositedAt[account];
    }

    function rewardsToken() external view override returns (address) {
        return BUNNY;
    }

    function priceShare() external view override returns (uint) {
        if (totalShares == 0) return 1e18;
        return balance().mul(1e18).div(totalShares);
    }

    function withdrawableBalanceOf(address account) override public view returns (uint) {
        if (block.timestamp > timestamp90DaysAfterPresaleEnds) {
            // unlock all presale bunny after 90 days from presale End
            return balanceOf(account);
        } else if (block.timestamp < timestamp2HoursAfterPresaleEnds) {
            // only withdrawable balance of after presale
            return balanceOf(account).sub(presaleBalanceOf(account));
        } else {
            // bunny in presale * 150%
            uint soldInPresale = IPresale(presaleContract).totalBalance().mul(3).div(2);
            uint bunnySupply = _stakingToken.totalSupply().mul(100).div(115);

            if (soldInPresale >= bunnySupply) {
                return balanceOf(account).sub(presaleBalanceOf(account));
            }

            // new bunny minted after presale
            uint bunnyNewMint = bunnySupply.sub(soldInPresale);
            if (bunnyNewMint >= soldInPresale) {
                return balanceOf(account);
            }

            uint lockedRatio = (soldInPresale.sub(bunnyNewMint)).mul(1e18).div(soldInPresale);
            uint lockedBalance = presaleBalanceOf(account).mul(lockedRatio).div(1e18);
            return balanceOf(account).sub(lockedBalance);
        }
    }

    function withdrawablePrincipalOf(address account) public view returns (uint) {
        if (block.timestamp > timestamp90DaysAfterPresaleEnds) {
            // unlock all presale bunny after 90 days from presale End
            return balanceOf(account);
        } else if (block.timestamp < timestamp2HoursAfterPresaleEnds) {
            // only withdrawable balance of after presale
            return balanceOf(account).sub(presaleBalanceOf(account));
        } else {
            // bunny in presale * 150%
            uint soldInPresale = IPresale(presaleContract).totalBalance().mul(3).div(2);
            uint bunnySupply = _stakingToken.totalSupply().mul(100).div(115);

            if (soldInPresale >= bunnySupply) {
                return principalOf(account).sub(presaleBalanceOf(account));
            }

            // new bunny minted after presale
            uint bunnyNewMint = bunnySupply.sub(soldInPresale);
            if (bunnyNewMint >= soldInPresale) {
                return balanceOf(account);
            }

            uint lockedRatio = (soldInPresale.sub(bunnyNewMint)).mul(1e18).div(soldInPresale);
            uint lockedBalance = presaleBalanceOf(account).mul(lockedRatio).div(1e18);
            return principalOf(account).sub(lockedBalance);
        }
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function deposit(uint amount) public override {
        _deposit(amount, msg.sender);
    }

    function depositAll() external override {
        deposit(_stakingToken.balanceOf(msg.sender));
    }

    function withdrawAll() external override {
        uint amount = balanceOf(msg.sender);
        uint principal = principalOf(msg.sender);
        uint depositTimestamp = _depositedAt[msg.sender];

        require(amount <= withdrawableBalanceOf(msg.sender), "VaultBunnyMaximizer: locked");

        totalShares = totalShares.sub(_shares[msg.sender]);
        delete _shares[msg.sender];
        delete _principal[msg.sender];
        delete _depositedAt[msg.sender];

        IStrategyLegacy(BUNNY_POOL).withdraw(amount);

        uint withdrawalFee = _minter.withdrawalFee(principal, depositTimestamp);
        if (withdrawalFee > 0) {
            _stakingToken.safeTransfer(TIMELOCK, withdrawalFee);
            amount = amount.sub(withdrawalFee);
        }

        _stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount, withdrawalFee);
    }

    function harvest() public override onlyKeeper {
        IStrategyLegacy(BUNNY_POOL).getReward();

        uint before = IBEP20(BUNNY).balanceOf(address(this));
        zap.zapInToken(WETH, IBEP20(WETH).balanceOf(address(this)), BUNNY);
        uint harvested = IBEP20(BUNNY).balanceOf(address(this)).sub(before);
        emit Harvested(harvested);

        IStrategyLegacy(BUNNY_POOL).deposit(harvested);
    }

    function withdraw(uint shares) external override onlyWhitelisted {
        uint amount = balance().mul(shares).div(totalShares);
        require(amount <= withdrawableBalanceOf(msg.sender), "VaultBunnyMaximizer: locked");
        totalShares = totalShares.sub(shares);
        _shares[msg.sender] = _shares[msg.sender].sub(shares);

        IStrategyLegacy(BUNNY_POOL).withdraw(amount);

        _stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount, 0);
    }

    // @dev underlying only + withdrawal fee + no perf fee
    function withdrawUnderlying(uint _amount) external {
        uint amount = Math.min(_amount, _principal[msg.sender]);
        require(amount <= withdrawablePrincipalOf(msg.sender), "VaultBunnyMaximizer: locked");
        uint shares = Math.min(amount.mul(totalShares).div(balance()), _shares[msg.sender]);
        totalShares = totalShares.sub(shares);
        _shares[msg.sender] = _shares[msg.sender].sub(shares);
        _principal[msg.sender] = _principal[msg.sender].sub(amount);

        IStrategyLegacy(BUNNY_POOL).withdraw(amount);

        uint depositTimestamp = _depositedAt[msg.sender];
        uint withdrawalFee = _minter.withdrawalFee(amount, depositTimestamp);
        if (withdrawalFee > 0) {
            _stakingToken.safeTransfer(TIMELOCK, withdrawalFee);
            amount = amount.sub(withdrawalFee);
        }

        _stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount, withdrawalFee);
    }

    function getReward() public override nonReentrant {
        uint amount = earned(msg.sender);
        require(amount <= withdrawableBalanceOf(msg.sender), "VaultBunnyMaximizer: locked");
        uint shares = Math.min(amount.mul(totalShares).div(balance()), _shares[msg.sender]);
        totalShares = totalShares.sub(shares);
        _shares[msg.sender] = _shares[msg.sender].sub(shares);
        _cleanupIfDustShares();

        IStrategyLegacy(BUNNY_POOL).withdraw(amount);

        _stakingToken.safeTransfer(msg.sender, amount);
        emit ProfitPaid(msg.sender, amount, 0);
    }

    function _cleanupIfDustShares() private {
        uint shares = _shares[msg.sender];
        if (shares > 0 && shares < DUST) {
            totalShares = totalShares.sub(shares);
            delete _shares[msg.sender];
        }
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setStakePermission(address _address, bool permission) public onlyOwner {
        _stakePermission[_address] = permission;
    }

    function setMinter(address newMinter) public override onlyOwner {
        setStakePermission(address(_minter), false);
        VaultController.setMinter(newMinter);
        setStakePermission(newMinter, true);
    }

    function setBunnyChef(IBunnyChef _chef) public override onlyOwner {
        require(address(_bunnyChef) == address(0), "VaultBunnyMaximizer: setBunnyChef only once");
        VaultController.setBunnyChef(IBunnyChef(_chef));
    }

    function stakeTo(uint256 amount, address _to) external canStakeTo {
        _deposit(amount, _to);
        if (msg.sender == presaleContract) {
            _presaleBalance[_to] = _presaleBalance[_to].add(amount);
        }
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _deposit(uint _amount, address _to) private nonReentrant notPaused {
        uint _pool = balance();
        _stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
        uint shares = totalShares == 0 ? _amount : (_amount.mul(totalShares)).div(_pool);

        totalShares = totalShares.add(shares);
        _shares[_to] = _shares[_to].add(shares);
        _principal[_to] = _principal[_to].add(_amount);
        _depositedAt[_to] = block.timestamp;

        IStrategyLegacy(BUNNY_POOL).deposit(_amount);
        emit Deposited(_to, _amount);
    }

    /* ========== SALVAGE PURPOSE ONLY ========== */

    function recoverToken(address tokenAddress, uint tokenAmount) external override onlyOwner {
        IBEP20(tokenAddress).safeTransfer(owner(), tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IPresale {
    function totalBalance() view external returns (uint);
    function flipToken() view external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
  ___                      _   _
 | _ )_  _ _ _  _ _ _  _  | | | |
 | _ \ || | ' \| ' \ || | |_| |_|
 |___/\_,_|_||_|_||_\_, | (_) (_)
                    |__/

*
* MIT License
* ===========
*
* Copyright (c) 2020 BunnyFinance
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

import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol";
import "@openzeppelin/contracts/math/Math.sol";

import {PoolConstant} from "../library/PoolConstant.sol";
import "../interfaces/IPancakePair.sol";
import "../interfaces/IPancakeFactory.sol";
import "../interfaces/IStrategy.sol";
import "../interfaces/IMasterChef.sol";
import "../interfaces/IBunnyMinter.sol";
import "../interfaces/IQuickStakingRewards.sol";
import "../interfaces/IPresale.sol";
import "../interfaces/IZap.sol";

import "./VaultController.sol";

contract VaultQuickBunnyETH is VaultController, IStrategy {
    using SafeBEP20 for IBEP20;
    using SafeMath for uint256;

    /* ========== CONSTANTS ============= */

    address private constant BUNNY = 0x4C16f69302CcB511c5Fac682c7626B9eF0Dc126a;      // BUNNY
    address private constant ETH = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;      // ETH
    address private constant BUNNY_ETH = 0x62052b489Cb5bC72a9DC8EEAE4B24FD50639921a;    // QUICK Swap
    address private constant presaleContract = 0x172B554118ecd915C5F046819cA225351566566E;

    IBEP20 private constant QUICK = IBEP20(0x831753DD7087CaC61aB5644b308642cc1c33Dc13);
    IZap public constant zap = IZap(0x663462430834E220851a3E981D0E1199501b84F6);
    PoolConstant.PoolTypes public constant override poolType = PoolConstant.PoolTypes.FlipToFlip;

    uint private constant DUST = 1000;
    uint private constant timestamp2HoursAfterPresaleEnds = 1625097600 + (2 hours);
    uint private constant timestamp90DaysAfterPresaleEnds = 1625097600 + (90 days);

    /* ========== STATE VARIABLES ========== */

    uint public totalShares;
    uint public totalBalance;
    mapping (address => uint) private _shares;
    mapping (address => uint) private _principal;
    mapping (address => uint) private _depositedAt;

    IQuickStakingRewards private qVault;

    uint public override pid;    // unused

    /* ========== PRESALE ============== */

    mapping(address => uint256) private _presaleBalance;

    /* ========== EVENTS ========== */

    event RewardAdded(uint reward);
    event RewardsDurationUpdated(uint newDuration);

    /* ========== INITIALIZER ========== */

    function initialize() external initializer {
        __VaultController_init(IBEP20(BUNNY_ETH));

        QUICK.safeApprove(address(zap), uint(- 1));

    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setMinter(address newMinter) public override onlyOwner {
        VaultController.setMinter(newMinter);
    }

    function setBunnyChef(IBunnyChef _chef) public override onlyOwner {
        require(address(_bunnyChef) == address(0), "VaultBunnyETH: setBunnyChef only once");
        VaultController.setBunnyChef(IBunnyChef(_chef));
    }

    function stakeTo(uint amount, address _to) external {
        if (msg.sender == presaleContract) {
            _depositTo(amount, _to);
            _presaleBalance[_to] = _presaleBalance[_to].add(amount);
        }
    }

    function setQuickVault(address _qVault) public onlyOwner {
        require(address(qVault) == address(0), "VaultBunnyETH: qVault already set");
        qVault = IQuickStakingRewards(_qVault);
        _stakingToken.safeApprove(_qVault, uint(- 1));

        qVault.stake(totalBalance);
    }

    /* ========== VIEW FUNCTIONS ========== */

    function totalSupply() external view override returns (uint) {
        return totalShares;
    }

    function balance() public view override returns (uint amount) {
        if (address(qVault) == address(0)) {
            amount = totalBalance;
        } else {
            amount = qVault.balanceOf(address(this));
        }
    }

    function balanceOf(address account) public view override returns(uint) {
        if (totalShares == 0) return 0;
        return balance().mul(sharesOf(account)).div(totalShares);
    }

    function withdrawableBalanceOf(address account) public view override returns (uint) {
        if (block.timestamp > timestamp90DaysAfterPresaleEnds) {
            // unlock all presale bunny after 90 days of presale
            return balanceOf(account);
        } else if (block.timestamp < timestamp2HoursAfterPresaleEnds) {
            return balanceOf(account).sub(_presaleBalance[account]);
        } else {
            uint soldInPresale = IPresale(presaleContract).totalBalance().mul(3).div(2);
            uint bunnySupply = IBEP20(BUNNY).totalSupply().mul(100).div(115);

            if (soldInPresale >= bunnySupply) {
                return balanceOf(account).sub(_presaleBalance[account]);
            }

            uint bunnyNewMint = bunnySupply.sub(soldInPresale);
            if (bunnyNewMint >= soldInPresale) {
                return balanceOf(account);
            }

            uint lockedRatio = (soldInPresale.sub(bunnyNewMint)).mul(1e18).div(soldInPresale);
            uint lockedBalance = _presaleBalance[account].mul(lockedRatio).div(1e18);
            return balanceOf(account).sub(lockedBalance);
        }
    }

    function withdrawablePrincipalOf(address account) public view returns (uint) {
        if (block.timestamp > timestamp90DaysAfterPresaleEnds) {
            // unlock all presale bunny after 90 days from presale End
            return balanceOf(account);
        } else if (block.timestamp < timestamp2HoursAfterPresaleEnds) {
            // only withdrawable balance of after presale
            return balanceOf(account).sub(_presaleBalance[account]);
        } else {
            // bunny in presale * 150%
            uint soldInPresale = IPresale(presaleContract).totalBalance().mul(3).div(2);
            uint bunnySupply = IBEP20(BUNNY).totalSupply().mul(100).div(115);

            if (soldInPresale >= bunnySupply) {
                return principalOf(account).sub(_presaleBalance[account]);
            }

            // new bunny minted after presale
            uint bunnyNewMint = bunnySupply.sub(soldInPresale);
            if (bunnyNewMint >= soldInPresale) {
                return balanceOf(account);
            }

            uint lockedRatio = (soldInPresale.sub(bunnyNewMint)).mul(1e18).div(soldInPresale);
            uint lockedBalance = _presaleBalance[account].mul(lockedRatio).div(1e18);
            return principalOf(account).sub(lockedBalance);
        }
    }

    function sharesOf(address account) public view override returns (uint) {
        return _shares[account];
    }

    function principalOf(address account) public view override returns (uint) {
        return _principal[account];
    }

    function earned(address account) public view override returns (uint) {
        if (balanceOf(account) >= principalOf(account) + DUST) {
            return balanceOf(account).sub(principalOf(account));
        } else {
            return 0;
        }
    }

    function depositedAt(address account) external view override returns (uint) {
        return _depositedAt[account];
    }

    function rewardsToken() external view override returns (address) {
        return address(_stakingToken);
    }

    function priceShare() external view override returns(uint) {
        if (totalShares == 0) return 1e18;
        return balance().mul(1e18).div(totalShares);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function deposit(uint _amount) public override {
        _depositTo(_amount, msg.sender);
    }

    function depositAll() external override {
        deposit(_stakingToken.balanceOf(msg.sender));
    }

    function withdrawAll() external override {
        uint amount = balanceOf(msg.sender);
        require(amount <= withdrawableBalanceOf(msg.sender), "VaultBunnyETH: locked");
        uint principal = principalOf(msg.sender);
        uint depositTimestamp = _depositedAt[msg.sender];

        uint shares = _shares[msg.sender];
        _bunnyChef.notifyWithdrawn(msg.sender, shares);
        totalShares = totalShares.sub(shares);
        delete _shares[msg.sender];
        delete _principal[msg.sender];
        delete _depositedAt[msg.sender];

        amount = _withdrawTokenWithCorrection(amount);

        uint profit = amount > principal ? amount.sub(principal) : 0;

        uint withdrawalFee = canMint() ? _minter.withdrawalFee(principal, depositTimestamp) : 0;
        uint performanceFee = canMint() ? _minter.performanceFee(profit) : 0;

        if (address(qVault) == address(0)) {
            totalBalance = totalBalance.sub(amount);
        }

        if (canMint()) {
            if (withdrawalFee.add(performanceFee) > DUST) {
                _minter.mintForV2(address(_stakingToken), withdrawalFee, performanceFee, msg.sender, depositTimestamp);

                if (performanceFee > 0) {
                    emit ProfitPaid(msg.sender, profit, performanceFee);
                }
                amount = amount.sub(withdrawalFee).sub(performanceFee);
            }
        }

        _stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount, withdrawalFee);

        uint bunnyAmount = _bunnyChef.safeBunnyTransfer(msg.sender);
        emit BunnyPaid(msg.sender, bunnyAmount, 0);
    }

    function harvest() external override onlyKeeper {
        if (address(qVault) == address(0)) return;

        uint quickHarvested = _harvest();

        uint before = _stakingToken.balanceOf(address(this));
        zap.zapInToken(address(QUICK), quickHarvested, address(_stakingToken));
        uint harvested = _stakingToken.balanceOf(address(this)).sub(before);

        qVault.stake(harvested);
        emit Harvested(harvested);
    }

    function _harvest() private returns(uint) {
        if (address(qVault) == address(0)) {
            return 0;
        } else {
            uint before = QUICK.balanceOf(address(this));
            qVault.getReward();
            return QUICK.balanceOf(address(this)).sub(before);
        }
    }

    function withdraw(uint shares) external override onlyWhitelisted {
        uint amount = balance().mul(shares).div(totalShares);
        require(amount <= withdrawableBalanceOf(msg.sender), "VaultBunnyETH: locked");
        _bunnyChef.notifyWithdrawn(msg.sender, shares);
        totalShares = totalShares.sub(shares);
        _shares[msg.sender] = _shares[msg.sender].sub(shares);

        amount = _withdrawTokenWithCorrection(amount);

        if (address(qVault) == address(0)) {
            totalBalance = totalBalance.sub(amount);
        }

        _stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount, 0);
    }

    // @dev underlying only + withdrawal fee + no perf fee
    function withdrawUnderlying(uint _amount) external {
        uint amount = Math.min(_amount, _principal[msg.sender]);
        require(amount <= withdrawablePrincipalOf(msg.sender), "VaultBunnyETH: locked");
        uint shares = Math.min(amount.mul(totalShares).div(balance()), _shares[msg.sender]);
        _bunnyChef.notifyWithdrawn(msg.sender, shares);
        totalShares = totalShares.sub(shares);
        _shares[msg.sender] = _shares[msg.sender].sub(shares);
        _principal[msg.sender] = _principal[msg.sender].sub(amount);

        amount = _withdrawTokenWithCorrection(amount);

        if (address(qVault) == address(0)) {
            totalBalance = totalBalance.sub(amount);
        }

        uint depositTimestamp = _depositedAt[msg.sender];
        uint withdrawalFee = canMint() ? _minter.withdrawalFee(amount, depositTimestamp) : 0;

        if (canMint()){
            if (withdrawalFee > DUST) {
                _minter.mintForV2(address(_stakingToken), withdrawalFee, 0, msg.sender, depositTimestamp);
                amount = amount.sub(withdrawalFee);
            }
        }

        _stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount, withdrawalFee);
    }

    // @dev profits only (underlying + bunny) + no withdraw fee + perf fee
    function getReward() external override {
        if (address(qVault) != address(0)) {
            uint amount = earned(msg.sender);
            uint shares = Math.min(amount.mul(totalShares).div(balance()), _shares[msg.sender]);
            _bunnyChef.notifyWithdrawn(msg.sender, shares);
            totalShares = totalShares.sub(shares);
            _shares[msg.sender] = _shares[msg.sender].sub(shares);
            _cleanupIfDustShares();

            amount = _withdrawTokenWithCorrection(amount);
            uint depositTimestamp = _depositedAt[msg.sender];
            uint performanceFee = canMint() ? _minter.performanceFee(amount) : 0;

            if (canMint()) {
                if (performanceFee > DUST) {
                    _minter.mintForV2(address(_stakingToken), 0, performanceFee, msg.sender, depositTimestamp);
                    amount = amount.sub(performanceFee);
                }
            }
            _stakingToken.safeTransfer(msg.sender, amount);
            emit ProfitPaid(msg.sender, amount, performanceFee);
        }

        uint bunnyAmount = _bunnyChef.safeBunnyTransfer(msg.sender);
        emit BunnyPaid(msg.sender, bunnyAmount, 0);
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _depositTo(uint _amount, address _to) private notPaused {
        if (_amount == 0) return;

        uint _pool = balance();
        uint _before = _stakingToken.balanceOf(address(this));
        _stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
        uint _after = _stakingToken.balanceOf(address(this));
        _amount = _after.sub(_before); // Additional check for deflationary tokens
        uint shares = 0;
        if (totalShares == 0) {
            shares = _amount;
        } else {
            shares = (_amount.mul(totalShares)).div(_pool);
        }

        _bunnyChef.updateRewardsOf(address(this));

        totalShares = totalShares.add(shares);
        _shares[_to] = _shares[_to].add(shares);
        _principal[_to] = _principal[_to].add(_amount);
        _depositedAt[_to] = block.timestamp;

        if (address(qVault) != address(0)){
            qVault.stake(_amount);
        } else {
            totalBalance = totalBalance.add(_amount);
        }
        _bunnyChef.notifyDeposited(_to, shares);
        emit Deposited(_to, _amount);
    }

    function _withdrawTokenWithCorrection(uint amount) private returns (uint) {
        if (amount == 0) return 0;

        if (address(qVault) == address(0)){
            return amount;
        } else {
            uint before = _stakingToken.balanceOf(address(this));
            qVault.withdraw(amount);
            return _stakingToken.balanceOf(address(this)).sub(before);
        }
    }

    function _cleanupIfDustShares() private {
        uint shares = _shares[msg.sender];
        if (shares > 0 && shares < DUST) {
            _bunnyChef.notifyWithdrawn(msg.sender, shares);
            totalShares = totalShares.sub(shares);
            delete _shares[msg.sender];
        }
    }

    /* ========== SALVAGE PURPOSE ONLY ========== */

    // @dev stakingToken must not remain balance in this contract. So dev should salvage staking token transferred by mistake.
    function recoverToken(address token, uint amount) external override onlyOwner {
        require(token != address(_stakingToken), "VaultBunnyETH: cannot recover underlying token");

        IBEP20(token).safeTransfer(owner(), amount);
        emit Recovered(token, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
  ___                      _   _
 | _ )_  _ _ _  _ _ _  _  | | | |
 | _ \ || | ' \| ' \ || | |_| |_|
 |___/\_,_|_||_|_||_\_, | (_) (_)
                    |__/

*
* MIT License
* ===========
*
* Copyright (c) 2020 BunnyFinance
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

import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol";
import "@openzeppelin/contracts/math/Math.sol";

import {PoolConstant} from "../library/PoolConstant.sol";
import "../interfaces/IPancakePair.sol";
import "../interfaces/IPancakeFactory.sol";
import "../interfaces/IStrategy.sol";
import "../interfaces/IMasterChef.sol";
import "../interfaces/IBunnyMinter.sol";
import "../interfaces/IQuickStakingRewards.sol";
import "../interfaces/IZap.sol";

import "./VaultController.sol";

contract VaultQuickBunnyLP is VaultController, IStrategy {
    using SafeBEP20 for IBEP20;
    using SafeMath for uint256;

    /* ========== CONSTANTS ============= */

    address private constant BUNNY = 0x4C16f69302CcB511c5Fac682c7626B9eF0Dc126a;      // polyBUNNY

    IBEP20 private constant QUICK = IBEP20(0x831753DD7087CaC61aB5644b308642cc1c33Dc13);
    IZap public constant zap = IZap(0x663462430834E220851a3E981D0E1199501b84F6);
    PoolConstant.PoolTypes public constant override poolType = PoolConstant.PoolTypes.FlipToFlip;

    uint private constant DUST = 1000;

    /* ========== STATE VARIABLES ========== */

    uint public totalShares;
    uint public totalBalance;
    mapping(address => uint) private _shares;
    mapping(address => uint) private _principal;
    mapping(address => uint) private _depositedAt;

    IQuickStakingRewards private qVault;

    uint public override pid;    // unused

    /* ========== EVENTS ========== */

    event RewardAdded(uint reward);
    event RewardsDurationUpdated(uint newDuration);

    /* ========== INITIALIZER ========== */

    function initialize(address token) external initializer {
        __VaultController_init(IBEP20(token));

        QUICK.safeApprove(address(zap), uint(- 1));

    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setMinter(address newMinter) public override onlyOwner {
        VaultController.setMinter(newMinter);
    }

    function setBunnyChef(IBunnyChef _chef) public override onlyOwner {
        require(address(_bunnyChef) == address(0), "VaultQuickBunnyLP: setBunnyChef only once");
        VaultController.setBunnyChef(IBunnyChef(_chef));
    }

    function setQuickVault(address _qVault) public onlyOwner {
        require(address(qVault) == address(0), "VaultQuickBunnyLP: qVault already set");
        qVault = IQuickStakingRewards(_qVault);
        _stakingToken.safeApprove(_qVault, uint(- 1));

        qVault.stake(totalBalance);
        delete totalBalance;
    }

    /* ========== VIEW FUNCTIONS ========== */

    function totalSupply() external view override returns (uint) {
        return totalShares;
    }

    function balance() public view override returns (uint amount) {
        if (address(qVault) == address(0)) {
            amount = totalBalance;
        } else {
            amount = qVault.balanceOf(address(this));
        }
    }

    function balanceOf(address account) public view override returns (uint) {
        if (totalShares == 0) return 0;
        return balance().mul(sharesOf(account)).div(totalShares);
    }

    function withdrawableBalanceOf(address account) public view override returns (uint) {
        return balanceOf(account);
    }

    function withdrawablePrincipalOf(address account) public view returns (uint) {
        return _principal[account];
    }

    function sharesOf(address account) public view override returns (uint) {
        return _shares[account];
    }

    function principalOf(address account) public view override returns (uint) {
        return _principal[account];
    }

    function earned(address account) public view override returns (uint) {
        if (balanceOf(account) >= principalOf(account) + DUST) {
            return balanceOf(account).sub(principalOf(account));
        } else {
            return 0;
        }
    }

    function depositedAt(address account) external view override returns (uint) {
        return _depositedAt[account];
    }

    function rewardsToken() external view override returns (address) {
        return address(_stakingToken);
    }

    function priceShare() external view override returns (uint) {
        if (totalShares == 0) return 1e18;
        return balance().mul(1e18).div(totalShares);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function deposit(uint _amount) public override {
        _depositTo(_amount, msg.sender);
    }

    function depositAll() external override {
        deposit(_stakingToken.balanceOf(msg.sender));
    }

    function withdrawAll() external override {
        uint amount = balanceOf(msg.sender);
        uint principal = principalOf(msg.sender);
        uint depositTimestamp = _depositedAt[msg.sender];

        uint shares = _shares[msg.sender];
        _bunnyChef.notifyWithdrawn(msg.sender, shares);
        totalShares = totalShares.sub(shares);
        delete _shares[msg.sender];
        delete _principal[msg.sender];
        delete _depositedAt[msg.sender];

        amount = _withdrawTokenWithCorrection(amount);

        uint profit = amount > principal ? amount.sub(principal) : 0;

        uint withdrawalFee = canMint() ? _minter.withdrawalFee(principal, depositTimestamp) : 0;
        uint performanceFee = canMint() ? _minter.performanceFee(profit) : 0;

        if (address(qVault) == address(0)) {
            totalBalance = totalBalance.sub(amount);
        }

        if (canMint()) {
            if (withdrawalFee.add(performanceFee) > DUST) {
                _minter.mintForV2(address(_stakingToken), withdrawalFee, performanceFee, msg.sender, depositTimestamp);

                if (performanceFee > 0) {
                    emit ProfitPaid(msg.sender, profit, performanceFee);
                }
                amount = amount.sub(withdrawalFee).sub(performanceFee);
            }
        }

        _stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount, withdrawalFee);

        uint bunnyAmount = _bunnyChef.safeBunnyTransfer(msg.sender);
        emit BunnyPaid(msg.sender, bunnyAmount, 0);
    }

    function harvest() external override onlyKeeper {
        if (address(qVault) == address(0)) return;

        uint quickHarvested = _harvest();

        uint before = _stakingToken.balanceOf(address(this));
        zap.zapInToken(address(QUICK), quickHarvested, address(_stakingToken));
        uint harvested = _stakingToken.balanceOf(address(this)).sub(before);

        qVault.stake(harvested);
        emit Harvested(harvested);
    }

    function _harvest() private returns (uint) {
        if (address(qVault) == address(0)) {
            return 0;
        } else {
            uint before = QUICK.balanceOf(address(this));
            qVault.getReward();
            return QUICK.balanceOf(address(this)).sub(before);
        }
    }

    function withdraw(uint shares) external override onlyWhitelisted {
        uint amount = balance().mul(shares).div(totalShares);

        _bunnyChef.notifyWithdrawn(msg.sender, shares);
        totalShares = totalShares.sub(shares);
        _shares[msg.sender] = _shares[msg.sender].sub(shares);

        amount = _withdrawTokenWithCorrection(amount);

        if (address(qVault) == address(0)) {
            totalBalance = totalBalance.sub(amount);
        }

        _stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount, 0);
    }

    // @dev underlying only + withdrawal fee + no perf fee
    function withdrawUnderlying(uint _amount) external {
        uint amount = Math.min(_amount, _principal[msg.sender]);

        uint shares = Math.min(amount.mul(totalShares).div(balance()), _shares[msg.sender]);
        _bunnyChef.notifyWithdrawn(msg.sender, shares);
        totalShares = totalShares.sub(shares);
        _shares[msg.sender] = _shares[msg.sender].sub(shares);
        _principal[msg.sender] = _principal[msg.sender].sub(amount);

        amount = _withdrawTokenWithCorrection(amount);

        if (address(qVault) == address(0)) {
            totalBalance = totalBalance.sub(amount);
        }

        uint depositTimestamp = _depositedAt[msg.sender];
        uint withdrawalFee = canMint() ? _minter.withdrawalFee(amount, depositTimestamp) : 0;

        if (canMint()) {
            if (withdrawalFee > DUST) {
                _minter.mintForV2(address(_stakingToken), withdrawalFee, 0, msg.sender, depositTimestamp);
                amount = amount.sub(withdrawalFee);
            }
        }

        _stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount, withdrawalFee);
    }

    // @dev profits only (underlying + bunny) + no withdraw fee + perf fee
    function getReward() external override {
        if (address(qVault) != address(0)) {
            uint amount = earned(msg.sender);
            uint shares = Math.min(amount.mul(totalShares).div(balance()), _shares[msg.sender]);
            _bunnyChef.notifyWithdrawn(msg.sender, shares);
            totalShares = totalShares.sub(shares);
            _shares[msg.sender] = _shares[msg.sender].sub(shares);
            _cleanupIfDustShares();

            amount = _withdrawTokenWithCorrection(amount);
            uint depositTimestamp = _depositedAt[msg.sender];
            uint performanceFee = canMint() ? _minter.performanceFee(amount) : 0;

            if (canMint()) {
                if (performanceFee > DUST) {
                    _minter.mintForV2(address(_stakingToken), 0, performanceFee, msg.sender, depositTimestamp);
                    amount = amount.sub(performanceFee);
                }
            }
            _stakingToken.safeTransfer(msg.sender, amount);
            emit ProfitPaid(msg.sender, amount, performanceFee);
        }

        uint bunnyAmount = _bunnyChef.safeBunnyTransfer(msg.sender);
        emit BunnyPaid(msg.sender, bunnyAmount, 0);
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _depositTo(uint _amount, address _to) private notPaused {
        if (_amount == 0) return;

        uint _pool = balance();
        uint _before = _stakingToken.balanceOf(address(this));
        _stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
        uint _after = _stakingToken.balanceOf(address(this));
        _amount = _after.sub(_before);
        // Additional check for deflationary tokens
        uint shares = 0;
        if (totalShares == 0) {
            shares = _amount;
        } else {
            shares = (_amount.mul(totalShares)).div(_pool);
        }

        _bunnyChef.updateRewardsOf(address(this));

        totalShares = totalShares.add(shares);
        _shares[_to] = _shares[_to].add(shares);
        _principal[_to] = _principal[_to].add(_amount);
        _depositedAt[_to] = block.timestamp;

        if (address(qVault) != address(0)) {
            qVault.stake(_amount);
        } else {
            totalBalance = totalBalance.add(_amount);
        }

        _bunnyChef.notifyDeposited(_to, shares);
        emit Deposited(_to, _amount);
    }

    function _withdrawTokenWithCorrection(uint amount) private returns (uint) {
        if (amount == 0) return 0;

        if (address(qVault) == address(0)) {
            return amount;
        } else {
            uint before = _stakingToken.balanceOf(address(this));
            qVault.withdraw(amount);
            return _stakingToken.balanceOf(address(this)).sub(before);
        }
    }

    function _cleanupIfDustShares() private {
        uint shares = _shares[msg.sender];
        if (shares > 0 && shares < DUST) {
            _bunnyChef.notifyWithdrawn(msg.sender, shares);
            totalShares = totalShares.sub(shares);
            delete _shares[msg.sender];
        }
    }

    /* ========== SALVAGE PURPOSE ONLY ========== */

    // @dev stakingToken must not remain balance in this contract. So dev should salvage staking token transferred by mistake.
    function recoverToken(address token, uint amount) external override onlyOwner {
        require(token != address(_stakingToken), "VaultQuickBunnyLP: cannot recover underlying token");

        IBEP20(token).safeTransfer(owner(), amount);
        emit Recovered(token, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
  ___                      _   _
 | _ )_  _ _ _  _ _ _  _  | | | |
 | _ \ || | ' \| ' \ || | |_| |_|
 |___/\_,_|_||_|_||_\_, | (_) (_)
                    |__/

*
* MIT License
* ===========
*
* Copyright (c) 2020 BunnyFinance
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

import "@openzeppelin/contracts/math/Math.sol";
import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import "../library/RewardsDistributionRecipientUpgradeable.sol";
import {PoolConstant} from "../library/PoolConstant.sol";

import "../interfaces/IStrategy.sol";
import "../interfaces/IMasterChef.sol";
import "../interfaces/IBunnyMinter.sol";
import "../interfaces/IQuickStakingRewards.sol";
import "../interfaces/IdQUICK.sol";

import "./VaultController.sol";
import "hardhat/console.sol";

contract VaultFlipToQuick is VaultController, IStrategy, RewardsDistributionRecipientUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMath for uint;
    using SafeBEP20 for IBEP20;

    /* ========== CONSTANTS ============= */

    IBEP20 private constant QUICK = IBEP20(0x831753DD7087CaC61aB5644b308642cc1c33Dc13);
    IdQUICK private constant dQUICK = IdQUICK(0xf28164A485B0B2C90639E47b0f377b4a438a16B1);

    PoolConstant.PoolTypes public constant override poolType = PoolConstant.PoolTypes.FlipToToken;

    /* ========== STATE VARIABLES ========== */

    IStrategy private _rewardsToken;    // TODO QUICK Vault

    uint public periodFinish;
    uint public rewardRate;
    uint public rewardsDuration;
    uint public lastUpdateTime;
    uint public rewardPerTokenStored;

    mapping(address => uint) public userRewardPerTokenPaid;
    mapping(address => uint) public rewards;        // dQUICK balance

    uint private _totalSupply;
    mapping(address => uint) private _balances;

    uint public override pid;
    mapping(address => uint) private _depositedAt;

    IQuickStakingRewards private qVault;


    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint reward);
    event RewardsDurationUpdated(uint newDuration);

    /* ========== INITIALIZER ========== */

    function initialize(address _token, address _stakingVault) external initializer {
        __VaultController_init(IBEP20(_token));
        __RewardsDistributionRecipient_init();
        __ReentrancyGuard_init();

        qVault = IQuickStakingRewards(_stakingVault);
        _stakingToken.safeApprove(_stakingVault, uint(- 1));
        QUICK.safeApprove(address(dQUICK), uint(- 1));

        rewardsDuration = 4 hours;

        rewardsDistribution = msg.sender;
//        setMinter(0x8cB88701790F650F273c8BB2Cc4c5f439cd65219);
//        setRewardsToken(0xEDfcB78e73f7bA6aD2D829bf5D462a0924da28eD);
    }

    /* ========== VIEWS ========== */

    function totalSupply() external view override returns (uint) {
        return _totalSupply;
    }

    function balance() override external view returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint) {
        return _balances[account];
    }

    function sharesOf(address account) external view override returns (uint) {
        return _balances[account];
    }

    function principalOf(address account) external view override returns (uint) {
        return _balances[account];
    }

    function depositedAt(address account) external view override returns (uint) {
        return _depositedAt[account];
    }

    function withdrawableBalanceOf(address account) public view override returns (uint) {
        return _balances[account];
    }

    function rewardsToken() external view override returns (address) {
        return address(_rewardsToken);
    }

    function priceShare() external view override returns (uint) {
        return 1e18;
    }

    function lastTimeRewardApplicable() public view returns (uint) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
        rewardPerTokenStored.add(
            lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(_totalSupply)
        );
    }

    function earned(address account) override public view returns (uint) {
        return _balances[account].mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
    }

    function getRewardForDuration() external view returns (uint) {
        return rewardRate.mul(rewardsDuration);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function deposit(uint amount) override public {
        _deposit(amount, msg.sender);
    }

    function depositAll() override external {
        deposit(_stakingToken.balanceOf(msg.sender));
    }

    function withdraw(uint amount) override public nonReentrant updateReward(msg.sender) {
        require(amount > 0, "VaultFlipToQuick: amount must be greater than zero");
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        uint quickHarvested = _withdrawStakingToken(amount);
        uint withdrawalFee;
        if (canMint()) {
            uint depositTimestamp = _depositedAt[msg.sender];
            withdrawalFee = _minter.withdrawalFee(amount, depositTimestamp);
            if (withdrawalFee > 0) {
                uint performanceFee = withdrawalFee.div(100);
                _minter.mintForV2(address(_stakingToken), withdrawalFee.sub(performanceFee), performanceFee, msg.sender, depositTimestamp);
                amount = amount.sub(withdrawalFee);
            }
        }

        _stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount, withdrawalFee);

        _harvest(quickHarvested);
    }

    function withdrawAll() external override {
        uint _withdraw = withdrawableBalanceOf(msg.sender);
        if (_withdraw > 0) {
            withdraw(_withdraw);
        }
        getReward();
    }

    // xxx WIP
    function getReward() public override nonReentrant updateReward(msg.sender) {
        uint reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            uint before = QUICK.balanceOf(address(this));
            // TODO check dQUICK share?
            dQUICK.leave(reward);
            uint quickBalance = QUICK.balanceOf(address(this)).sub(before);
            uint performanceFee;

            if (canMint()) {
                performanceFee = _minter.performanceFee(quickBalance);
                _minter.mintForV2(address(QUICK), 0, performanceFee, msg.sender, _depositedAt[msg.sender]);
            }

            QUICK.safeTransfer(msg.sender, quickBalance.sub(performanceFee));
            emit ProfitPaid(msg.sender, quickBalance, performanceFee);
        }
    }

    function harvest() public override {
        uint before = QUICK.balanceOf(address(this));
        qVault.getReward();
        uint quickHarvested = QUICK.balanceOf(address(this)).sub(before);
        _harvest(quickHarvested);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setMinter(address newMinter) override public onlyOwner {
        VaultController.setMinter(newMinter);
        if (newMinter != address(0)) {
            QUICK.safeApprove(newMinter, 0);
            QUICK.safeApprove(newMinter, uint(- 1));
        }
    }

    function setRewardsToken(address newRewardsToken) public onlyOwner {
        require(address(_rewardsToken) == address(0), "VaultFlipToCake: rewards token already set");

        _rewardsToken = IStrategy(newRewardsToken);
        QUICK.safeApprove(newRewardsToken, 0);
        QUICK.safeApprove(newRewardsToken, uint(- 1));
    }

    function notifyRewardAmount(uint reward) public override onlyRewardsDistribution {
        _notifyRewardAmount(reward);
    }

    function setRewardsDuration(uint _rewardsDuration) external onlyOwner {
        require(periodFinish == 0 || block.timestamp > periodFinish, "VaultFlipToCake: reward duration can only be updated after the period ends");
        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _deposit(uint amount, address _to) private nonReentrant notPaused updateReward(_to) {
        require(amount > 0, "VaultFlipToCake: amount must be greater than zero");
        _totalSupply = _totalSupply.add(amount);
        _balances[_to] = _balances[_to].add(amount);
        _depositedAt[_to] = block.timestamp;
        _stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        uint quickHarvested = _depositStakingToken(amount);
        emit Deposited(_to, amount);

        _harvest(quickHarvested);
    }

    function _depositStakingToken(uint amount) private returns (uint quickHarvested) {
        uint before = QUICK.balanceOf(address(this));
        qVault.stake(amount);
        quickHarvested = QUICK.balanceOf(address(this)).sub(before);
    }

    // xxx done
    function _withdrawStakingToken(uint amount) private returns (uint quickHarvested) {
        uint before = QUICK.balanceOf(address(this));
        qVault.withdraw(amount);
        quickHarvested = QUICK.balanceOf(address(this)).sub(before);
    }

    function _harvest(uint quickAmount) private {
        uint _before = dQUICK.QUICKBalance(address(this));
        dQUICK.enter(quickAmount);
        uint amount = dQUICK.QUICKBalance(address(this)).sub(_before);

        if (amount > 0) {
            _notifyRewardAmount(amount);
            emit Harvested(amount);
        }
    }

    function _notifyRewardAmount(uint reward) private updateReward(address(0)) {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(rewardsDuration);
        } else {
            uint remaining = periodFinish.sub(block.timestamp);
            uint leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(rewardsDuration);
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint _balance = dQUICK.QUICKBalance(address(this));
        require(rewardRate <= _balance.div(rewardsDuration), "VaultFlipToCake: reward rate must be in the right range");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardAdded(reward);
    }

    /* ========== SALVAGE PURPOSE ONLY ========== */

    // @dev rewardToken(dQuick) must not remain balance in this contract. So dev should be able to salvage reward token transferred by mistake.
    function recoverToken(address tokenAddress, uint tokenAmount) external override onlyOwner {
        require(tokenAddress != address(_stakingToken), "VaultFlipToCake: cannot recover underlying token");

        IBEP20(tokenAddress).safeTransfer(owner(), tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IdQUICK {
    function enter(uint256 _quickAmount) external;
    function leave(uint256 _dQuickAmount) external;

    // view
    function balanceOf(address account) external view returns (uint256);

    function QUICKBalance(address _account) external view returns (uint);
    function dQUICKForQUICK(uint256 _dQuickAmount) external view returns (uint);
    function QUICKForDQUICK(uint256 _quickAmount) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
  ___                      _   _
 | _ )_  _ _ _  _ _ _  _  | | | |
 | _ \ || | ' \| ' \ || | |_| |_|
 |___/\_,_|_||_|_||_\_, | (_) (_)
                    |__/

*
* MIT License
* ===========
*
* Copyright (c) 2020 BunnyFinance
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

import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol";
import "@openzeppelin/contracts/math/Math.sol";

import {PoolConstant} from "../../library/PoolConstant.sol";
import "../../interfaces/IPancakePair.sol";
import "../../interfaces/IPancakeFactory.sol";
import "../../interfaces/IStrategy.sol";
import "../../interfaces/IMasterChef.sol";
import "../../interfaces/IBunnyMinter.sol";

import "../../zap/ZapPolygon.sol";
import "./../VaultController.sol";
import "hardhat/console.sol";

contract VaultFlipToFlip is VaultController, IStrategy {
    using SafeBEP20 for IBEP20;
    using SafeMath for uint256;

    /* ========== CONSTANTS ============= */

    IBEP20 private constant CAKE = IBEP20(0xaAa5B9e6c589642f98a1cDA99B9D024B8407285A);  // TITAN
    PoolConstant.PoolTypes public constant override poolType = PoolConstant.PoolTypes.FlipToFlip;

    uint private constant DUST = 1000;

    /* ========== STATE VARIABLES ========== */

    uint public override pid;

    address private _token0;
    address private _token1;

    uint public totalShares;
    mapping (address => uint) private _shares;
    mapping (address => uint) private _principal;
    mapping (address => uint) private _depositedAt;

    uint public cakeHarvested;
    ZapPolygon public zap;
    IMasterChef private CAKE_MASTER_CHEF;

    /* ========== MODIFIER ========== */

    modifier updateCakeHarvested {
        uint before = CAKE.balanceOf(address(this));
        _;
        uint _after = CAKE.balanceOf(address(this));
        cakeHarvested = cakeHarvested.add(_after).sub(before);
    }

    /* ========== INITIALIZER ========== */

    function initialize(uint _pid, address _token, address _chef) external initializer {
        __VaultController_init(IBEP20(_token));

        CAKE_MASTER_CHEF = IMasterChef(_chef);
        _stakingToken.safeApprove(address(_chef), uint(- 1));
        pid = _pid;

    }

    /* ========== VIEW FUNCTIONS ========== */

    function setZap(address payable _zap) external onlyOwner {
        zap = ZapPolygon(_zap);
        CAKE.safeApprove(address(zap), uint(- 1));
    }

    /* ========== VIEW FUNCTIONS ========== */

    function totalSupply() external view override returns (uint) {
        return totalShares;
    }

    function balance() public view override returns (uint amount) {
        (amount,) = CAKE_MASTER_CHEF.userInfo(pid, address(this));
    }

    function balanceOf(address account) public view override returns(uint) {
        if (totalShares == 0) return 0;
        return balance().mul(sharesOf(account)).div(totalShares);
    }

    function withdrawableBalanceOf(address account) public view override returns (uint) {
        return balanceOf(account);
    }

    function sharesOf(address account) public view override returns (uint) {
        return _shares[account];
    }

    function principalOf(address account) public view override returns (uint) {
        return _principal[account];
    }

    function earned(address account) public view override returns (uint) {
        if (balanceOf(account) >= principalOf(account) + DUST) {
            return balanceOf(account).sub(principalOf(account));
        } else {
            return 0;
        }
    }

    function depositedAt(address account) external view override returns (uint) {
        return _depositedAt[account];
    }

    function rewardsToken() external view override returns (address) {
        return address(_stakingToken);
    }

    function priceShare() external view override returns(uint) {
        if (totalShares == 0) return 1e18;
        return balance().mul(1e18).div(totalShares);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function deposit(uint _amount) public override {
        _depositTo(_amount, msg.sender);
    }

    function depositAll() external override {
        deposit(_stakingToken.balanceOf(msg.sender));
    }

    function withdrawAll() external override {
        uint amount = balanceOf(msg.sender);
        uint principal = principalOf(msg.sender);
        uint depositTimestamp = _depositedAt[msg.sender];

        totalShares = totalShares.sub(_shares[msg.sender]);
        delete _shares[msg.sender];
        delete _principal[msg.sender];
        delete _depositedAt[msg.sender];

        amount = _withdrawTokenWithCorrection(amount);
        uint profit = amount > principal ? amount.sub(principal) : 0;

        uint withdrawalFee = canMint() ? _minter.withdrawalFee(principal, depositTimestamp) : 0;
        uint performanceFee = canMint() ? _minter.performanceFee(profit) : 0;
        if (withdrawalFee.add(performanceFee) > DUST) {
            _minter.mintForV2(address(_stakingToken), withdrawalFee, performanceFee, msg.sender, depositTimestamp);

            if (performanceFee > 0) {
                emit ProfitPaid(msg.sender, profit, performanceFee);
            }
            amount = amount.sub(withdrawalFee).sub(performanceFee);
        }

        _stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount, withdrawalFee);
    }

    function harvest() external override onlyKeeper {
        _harvest();

        uint before = _stakingToken.balanceOf(address(this));
        console.log("before", before);
        zap.zapInToken(address(CAKE), cakeHarvested, address(_stakingToken));
        uint harvested = _stakingToken.balanceOf(address(this)).sub(before);
        console.log("after ", harvested);

        CAKE_MASTER_CHEF.deposit(pid, harvested);
        emit Harvested(harvested);

        cakeHarvested = 0;
    }

    function _harvest() private updateCakeHarvested {
        CAKE_MASTER_CHEF.withdraw(pid, 0);
    }

    function withdraw(uint shares) external override onlyWhitelisted {
        uint amount = balance().mul(shares).div(totalShares);
        totalShares = totalShares.sub(shares);
        _shares[msg.sender] = _shares[msg.sender].sub(shares);

        amount = _withdrawTokenWithCorrection(amount);
        _stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount, 0);
    }

    // @dev underlying only + withdrawal fee + no perf fee
    function withdrawUnderlying(uint _amount) external {
        uint amount = Math.min(_amount, _principal[msg.sender]);
        uint shares = Math.min(amount.mul(totalShares).div(balance()), _shares[msg.sender]);
        totalShares = totalShares.sub(shares);
        _shares[msg.sender] = _shares[msg.sender].sub(shares);
        _principal[msg.sender] = _principal[msg.sender].sub(amount);

        amount = _withdrawTokenWithCorrection(amount);
        uint depositTimestamp = _depositedAt[msg.sender];
        uint withdrawalFee = canMint() ? _minter.withdrawalFee(amount, depositTimestamp) : 0;
        if (withdrawalFee > DUST) {
            _minter.mintForV2(address(_stakingToken), withdrawalFee, 0, msg.sender, depositTimestamp);
            amount = amount.sub(withdrawalFee);
        }

        _stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount, withdrawalFee);
    }

    // @dev profits only (underlying + bunny) + no withdraw fee + perf fee
    function getReward() external override {
        uint amount = earned(msg.sender);
        uint shares = Math.min(amount.mul(totalShares).div(balance()), _shares[msg.sender]);
        totalShares = totalShares.sub(shares);
        _shares[msg.sender] = _shares[msg.sender].sub(shares);
        _cleanupIfDustShares();

        amount = _withdrawTokenWithCorrection(amount);
        uint depositTimestamp = _depositedAt[msg.sender];
        uint performanceFee = canMint() ? _minter.performanceFee(amount) : 0;
        if (performanceFee > DUST) {
            _minter.mintForV2(address(_stakingToken), 0, performanceFee, msg.sender, depositTimestamp);
            amount = amount.sub(performanceFee);
        }

        _stakingToken.safeTransfer(msg.sender, amount);
        emit ProfitPaid(msg.sender, amount, performanceFee);
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _depositTo(uint _amount, address _to) private notPaused updateCakeHarvested {
        uint _pool = balance();
        uint _before = _stakingToken.balanceOf(address(this));
        _stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
        uint _after = _stakingToken.balanceOf(address(this));
        _amount = _after.sub(_before); // Additional check for deflationary tokens
        uint shares = 0;
        if (totalShares == 0) {
            shares = _amount;
        } else {
            shares = (_amount.mul(totalShares)).div(_pool);
        }

        totalShares = totalShares.add(shares);
        _shares[_to] = _shares[_to].add(shares);
        _principal[_to] = _principal[_to].add(_amount);
        _depositedAt[_to] = block.timestamp;

        CAKE_MASTER_CHEF.deposit(pid, _amount);
        emit Deposited(_to, _amount);
    }

    function _withdrawTokenWithCorrection(uint amount) private updateCakeHarvested returns (uint) {
        uint before = _stakingToken.balanceOf(address(this));
        CAKE_MASTER_CHEF.withdraw(pid, amount);
        return _stakingToken.balanceOf(address(this)).sub(before);
    }

    function _cleanupIfDustShares() private {
        uint shares = _shares[msg.sender];
        if (shares > 0 && shares < DUST) {
            totalShares = totalShares.sub(shares);
            delete _shares[msg.sender];
        }
    }

    /* ========== SALVAGE PURPOSE ONLY ========== */

    // @dev stakingToken must not remain balance in this contract. So dev should salvage staking token transferred by mistake.
    function recoverToken(address token, uint amount) external override onlyOwner {
        if (token == address(CAKE)) {
            uint cakeBalance = CAKE.balanceOf(address(this));
            require(amount <= cakeBalance.sub(cakeHarvested), "VaultFlipToFlip: cannot recover lp's harvested cake");
        }

        IBEP20(token).safeTransfer(owner(), amount);
        emit Recovered(token, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
  ___                      _   _
 | _ )_  _ _ _  _ _ _  _  | | | |
 | _ \ || | ' \| ' \ || | |_| |_|
 |___/\_,_|_||_|_||_\_, | (_) (_)
                    |__/

*
* MIT License
* ===========
*
* Copyright (c) 2020 BunnyFinance
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

import "@openzeppelin/contracts/math/Math.sol";
import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import "../../library/RewardsDistributionRecipientUpgradeable.sol";
import {PoolConstant} from "../../library/PoolConstant.sol";

import "../../interfaces/IStrategy.sol";
import "../../interfaces/IMasterChef.sol";
import "../../interfaces/IBunnyMinter.sol";

import "../VaultController.sol";


contract VaultFlipToCake is VaultController, IStrategy, RewardsDistributionRecipientUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMath for uint;
    using SafeBEP20 for IBEP20;

    /* ========== CONSTANTS ============= */

    address private constant CAKE = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    IMasterChef private constant CAKE_MASTER_CHEF = IMasterChef(0x73feaa1eE314F8c655E354234017bE2193C9E24E);
    PoolConstant.PoolTypes public constant override poolType = PoolConstant.PoolTypes.FlipToToken;

    /* ========== STATE VARIABLES ========== */

    IStrategy private _rewardsToken;

    uint public periodFinish;
    uint public rewardRate;
    uint public rewardsDuration;
    uint public lastUpdateTime;
    uint public rewardPerTokenStored;

    mapping(address => uint) public userRewardPerTokenPaid;
    mapping(address => uint) public rewards;

    uint private _totalSupply;
    mapping(address => uint) private _balances;

    uint public override pid;
    mapping(address => uint) private _depositedAt;

    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint reward);
    event RewardsDurationUpdated(uint newDuration);

    /* ========== INITIALIZER ========== */

    function initialize(uint _pid, address _token) external initializer {
        __VaultController_init(IBEP20(_token));
        __RewardsDistributionRecipient_init();
        __ReentrancyGuard_init();

        _stakingToken.safeApprove(address(CAKE_MASTER_CHEF), uint(- 1));
        pid = _pid;

        rewardsDuration = 4 hours;

        rewardsDistribution = msg.sender;
        setMinter(0x8cB88701790F650F273c8BB2Cc4c5f439cd65219);
        setRewardsToken(0xEDfcB78e73f7bA6aD2D829bf5D462a0924da28eD);
    }

    /* ========== VIEWS ========== */

    function totalSupply() external view override returns (uint) {
        return _totalSupply;
    }

    function balance() override external view returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint) {
        return _balances[account];
    }

    function sharesOf(address account) external view override returns (uint) {
        return _balances[account];
    }

    function principalOf(address account) external view override returns (uint) {
        return _balances[account];
    }

    function depositedAt(address account) external view override returns (uint) {
        return _depositedAt[account];
    }

    function withdrawableBalanceOf(address account) public view override returns (uint) {
        return _balances[account];
    }

    function rewardsToken() external view override returns (address) {
        return address(_rewardsToken);
    }

    function priceShare() external view override returns (uint) {
        return 1e18;
    }

    function lastTimeRewardApplicable() public view returns (uint) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
        rewardPerTokenStored.add(
            lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(_totalSupply)
        );
    }

    function earned(address account) override public view returns (uint) {
        return _balances[account].mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
    }

    function getRewardForDuration() external view returns (uint) {
        return rewardRate.mul(rewardsDuration);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function deposit(uint amount) override public {
        _deposit(amount, msg.sender);
    }

    function depositAll() override external {
        deposit(_stakingToken.balanceOf(msg.sender));
    }

    function withdraw(uint amount) override public nonReentrant updateReward(msg.sender) {
        require(amount > 0, "VaultFlipToCake: amount must be greater than zero");
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        uint cakeHarvested = _withdrawStakingToken(amount);
        uint withdrawalFee;
        if (canMint()) {
            uint depositTimestamp = _depositedAt[msg.sender];
            withdrawalFee = _minter.withdrawalFee(amount, depositTimestamp);
            if (withdrawalFee > 0) {
                uint performanceFee = withdrawalFee.div(100);
                _minter.mintForV2(address(_stakingToken), withdrawalFee.sub(performanceFee), performanceFee, msg.sender, depositTimestamp);
                amount = amount.sub(withdrawalFee);
            }
        }

        _stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount, withdrawalFee);

        _harvest(cakeHarvested);
    }

    function withdrawAll() external override {
        uint _withdraw = withdrawableBalanceOf(msg.sender);
        if (_withdraw > 0) {
            withdraw(_withdraw);
        }
        getReward();
    }

    function getReward() public override nonReentrant updateReward(msg.sender) {
        uint reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            uint before = IBEP20(CAKE).balanceOf(address(this));
            _rewardsToken.withdraw(reward);
            uint cakeBalance = IBEP20(CAKE).balanceOf(address(this)).sub(before);
            uint performanceFee;

            if (canMint()) {
                performanceFee = _minter.performanceFee(cakeBalance);
                _minter.mintForV2(CAKE, 0, performanceFee, msg.sender, _depositedAt[msg.sender]);
            }

            IBEP20(CAKE).safeTransfer(msg.sender, cakeBalance.sub(performanceFee));
            emit ProfitPaid(msg.sender, cakeBalance, performanceFee);
        }
    }

    function harvest() public override {
        uint cakeHarvested = _withdrawStakingToken(0);
        _harvest(cakeHarvested);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setMinter(address newMinter) override public onlyOwner {
        VaultController.setMinter(newMinter);
        if (newMinter != address(0)) {
            IBEP20(CAKE).safeApprove(newMinter, 0);
            IBEP20(CAKE).safeApprove(newMinter, uint(- 1));
        }
    }

    function setRewardsToken(address newRewardsToken) public onlyOwner {
        require(address(_rewardsToken) == address(0), "VaultFlipToCake: rewards token already set");

        _rewardsToken = IStrategy(newRewardsToken);
        IBEP20(CAKE).safeApprove(newRewardsToken, 0);
        IBEP20(CAKE).safeApprove(newRewardsToken, uint(- 1));
    }

    function notifyRewardAmount(uint reward) public override onlyRewardsDistribution {
        _notifyRewardAmount(reward);
    }

    function setRewardsDuration(uint _rewardsDuration) external onlyOwner {
        require(periodFinish == 0 || block.timestamp > periodFinish, "VaultFlipToCake: reward duration can only be updated after the period ends");
        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _deposit(uint amount, address _to) private nonReentrant notPaused updateReward(_to) {
        require(amount > 0, "VaultFlipToCake: amount must be greater than zero");
        _totalSupply = _totalSupply.add(amount);
        _balances[_to] = _balances[_to].add(amount);
        _depositedAt[_to] = block.timestamp;
        _stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        uint cakeHarvested = _depositStakingToken(amount);
        emit Deposited(_to, amount);

        _harvest(cakeHarvested);
    }

    function _depositStakingToken(uint amount) private returns (uint cakeHarvested) {
        uint before = IBEP20(CAKE).balanceOf(address(this));
        CAKE_MASTER_CHEF.deposit(pid, amount);
        cakeHarvested = IBEP20(CAKE).balanceOf(address(this)).sub(before);
    }

    function _withdrawStakingToken(uint amount) private returns (uint cakeHarvested) {
        uint before = IBEP20(CAKE).balanceOf(address(this));
        CAKE_MASTER_CHEF.withdraw(pid, amount);
        cakeHarvested = IBEP20(CAKE).balanceOf(address(this)).sub(before);
    }

    function _harvest(uint cakeAmount) private {
        uint _before = _rewardsToken.sharesOf(address(this));
        _rewardsToken.deposit(cakeAmount);
        uint amount = _rewardsToken.sharesOf(address(this)).sub(_before);
        if (amount > 0) {
            _notifyRewardAmount(amount);
            emit Harvested(amount);
        }
    }

    function _notifyRewardAmount(uint reward) private updateReward(address(0)) {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(rewardsDuration);
        } else {
            uint remaining = periodFinish.sub(block.timestamp);
            uint leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(rewardsDuration);
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint _balance = _rewardsToken.sharesOf(address(this));
        require(rewardRate <= _balance.div(rewardsDuration), "VaultFlipToCake: reward rate must be in the right range");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardAdded(reward);
    }

    /* ========== SALVAGE PURPOSE ONLY ========== */

    // @dev rewardToken(CAKE) must not remain balance in this contract. So dev should be able to salvage reward token transferred by mistake.
    function recoverToken(address tokenAddress, uint tokenAmount) external override onlyOwner {
        require(tokenAddress != address(_stakingToken), "VaultFlipToCake: cannot recover underlying token");

        IBEP20(tokenAddress).safeTransfer(owner(), tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
  ___                      _   _
 | _ )_  _ _ _  _ _ _  _  | | | |
 | _ \ || | ' \| ' \ || | |_| |_|
 |___/\_,_|_||_|_||_\_, | (_) (_)
                    |__/

*
* MIT License
* ===========
*
* Copyright (c) 2020 BunnyFinance
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

import "@openzeppelin/contracts/math/Math.sol";
import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import "../../library/RewardsDistributionRecipientUpgradeable.sol";
import "../../interfaces/IStrategy.sol";
import "../../interfaces/IBunnyChef.sol";
import "../../interfaces/IPresale.sol";

import "../VaultController.sol";
import {PoolConstant} from "../../library/PoolConstant.sol";

contract VaultBunnyETH is VaultController, IStrategy, RewardsDistributionRecipientUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMath for uint;
    using SafeBEP20 for IBEP20;

    /* ========== CONSTANTS ============= */

    address private constant BUNNY = 0x4C16f69302CcB511c5Fac682c7626B9eF0Dc126a;
    address private constant BUNNY_ETH = 0x62052b489Cb5bC72a9DC8EEAE4B24FD50639921a;    // QUICK Swap
    address private constant presaleContract = 0x172B554118ecd915C5F046819cA225351566566E;
    address private constant deadAddress = 0x000000000000000000000000000000000000dEaD;
    uint private constant timestamp2HoursAfterPresaleEnds = 1625097600 + (2 hours);
    uint private constant timestamp90DaysAfterPresaleEnds = 1625097600 + (90 days);
    uint public constant override pid = 9999;

    PoolConstant.PoolTypes public constant override poolType = PoolConstant.PoolTypes.BunnyETH;

    /* ========== STATE VARIABLES ========== */

    IStrategy private _rewardsToken;

    uint public periodFinish;
    uint public rewardRate;
    uint public rewardsDuration;
    uint public lastUpdateTime;
    uint public rewardPerTokenStored;

    mapping(address => uint) public userRewardPerTokenPaid;
    mapping(address => uint) public rewards;

    uint private _totalSupply;
    mapping(address => uint) private _balances;

    mapping(address => uint) private _depositedAt;

    /* ========== PRESALE ============== */

    mapping(address => uint256) private _presaleBalance;


    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint reward);
    event RewardsDurationUpdated(uint newDuration);

    /* ========== INITIALIZER ========== */

    function initialize() external initializer {
        __VaultController_init(IBEP20(BUNNY_ETH));
        __RewardsDistributionRecipient_init();
        __ReentrancyGuard_init();

        rewardsDuration = 4 hours;
        rewardsDistribution = msg.sender;

    }

    /* ========== VIEWS ========== */

    function totalSupply() external view override returns (uint) {
        return _totalSupply;
    }

    function balance() external view override returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint) {
        return _balances[account];
    }

    function sharesOf(address account) external view override returns (uint) {
        return _balances[account];
    }

    function principalOf(address account) external view override returns (uint) {
        return _balances[account];
    }

    function depositedAt(address account) external view override returns (uint) {
        return _depositedAt[account];
    }

    function withdrawableBalanceOf(address account) public view override returns (uint) {
        if (block.timestamp > timestamp90DaysAfterPresaleEnds) {
            // unlock all presale bunny after 90 days of presale
            return _balances[account];
        } else if (block.timestamp < timestamp2HoursAfterPresaleEnds) {
            return _balances[account].sub(_presaleBalance[account]);
        } else {
            uint soldInPresale = IPresale(presaleContract).totalBalance().mul(3).div(2);
            uint bunnySupply = IBEP20(BUNNY).totalSupply().mul(100).div(115);

            if (soldInPresale >= bunnySupply) {
                return _balances[account].sub(_presaleBalance[account]);
            }

            uint bunnyNewMint = bunnySupply.sub(soldInPresale);
            if (bunnyNewMint >= soldInPresale) {
                return _balances[account];
            }

            uint lockedRatio = (soldInPresale.sub(bunnyNewMint)).mul(1e18).div(soldInPresale);
            uint lockedBalance = _presaleBalance[account].mul(lockedRatio).div(1e18);
            return _balances[account].sub(lockedBalance);
        }
    }

    function rewardsToken() external view override returns (address) {
        return address(_rewardsToken);
    }

    function priceShare() external view override returns (uint) {
        return 1e18;
    }

    function lastTimeRewardApplicable() public view returns (uint) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
        rewardPerTokenStored.add(
            lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(_totalSupply)
        );
    }

    function earned(address account) override public view returns (uint) {
        return _bunnyChef.pendingBunny(address(this), account);
    }

    function getRewardForDuration() external view returns (uint) {
        return rewardRate.mul(rewardsDuration);
    }

    function pidAttached() public pure returns (bool) {
        return pid != 0;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function deposit(uint amount) override public {
        _deposit(amount, msg.sender);
    }

    function depositAll() override external {
        deposit(_stakingToken.balanceOf(msg.sender));
    }

    function withdraw(uint amount) override public nonReentrant updateReward(msg.sender) {
        require(amount > 0, "VaultBunnyBNB: amount must be greater than zero");
        require(amount <= withdrawableBalanceOf(msg.sender), "VaultBunnyETH: locked");

        _bunnyChef.notifyWithdrawn(msg.sender, amount);

        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);

        uint withdrawalFee;
        if (canMint()) {
            uint depositTimestamp = _depositedAt[msg.sender];
            withdrawalFee = _minter.withdrawalFee(amount, depositTimestamp);
            if (withdrawalFee > 0) {
                _minter.mintForV2(address(_stakingToken), withdrawalFee, 0, msg.sender, depositTimestamp);
                amount = amount.sub(withdrawalFee);
            }
        }

        _stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount, withdrawalFee);

    }

    function withdrawAll() external override {
        uint _withdraw = withdrawableBalanceOf(msg.sender);
        if (_withdraw > 0) {
            withdraw(_withdraw);
        }
        getReward();
    }

    function getReward() public override nonReentrant updateReward(msg.sender) {
        uint bunnyAmount = _bunnyChef.safeBunnyTransfer(msg.sender);
        emit BunnyPaid(msg.sender, bunnyAmount, 0);
    }

    function harvest() public override {
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setMinter(address newMinter) public override onlyOwner {
        VaultController.setMinter(newMinter);
    }

    function setBunnyChef(IBunnyChef _chef) public override onlyOwner {
        require(address(_bunnyChef) == address(0), "VaultBunnyBNB: setBunnyChef only once");
        VaultController.setBunnyChef(IBunnyChef(_chef));
    }

    function setRewardsToken(address newRewardsToken) public onlyOwner {
        require(address(_rewardsToken) == address(0), "VaultBunnyBNB: rewards token already set");

        _rewardsToken = IStrategy(newRewardsToken);
    }

    function notifyRewardAmount(uint reward) public override onlyRewardsDistribution {
        _notifyRewardAmount(reward);
    }

    function setRewardsDuration(uint _rewardsDuration) external onlyOwner {
        require(periodFinish == 0 || block.timestamp > periodFinish, "VaultBunnyBNB: reward duration can only be updated after the period ends");
        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    }

    function stakeTo(uint amount, address _to) external {       // TODO modifier?
        _deposit(amount, _to);
        if (msg.sender == presaleContract) {
            _presaleBalance[_to] = _presaleBalance[_to].add(amount);
        }
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _deposit(uint amount, address _to) private nonReentrant notPaused updateReward(_to) {
        require(amount > 0, "VaultBunnyBNB: amount must be greater than zero");
        _totalSupply = _totalSupply.add(amount);
        _balances[_to] = _balances[_to].add(amount);
        _depositedAt[_to] = block.timestamp;
        _stakingToken.safeTransferFrom(msg.sender, address(this), amount);

        _bunnyChef.notifyDeposited(_to, amount);

        emit Deposited(_to, amount);
    }

    function _notifyRewardAmount(uint reward) private updateReward(address(0)) {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(rewardsDuration);
        } else {
            uint remaining = periodFinish.sub(block.timestamp);
            uint leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(rewardsDuration);
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.

        // TODO check
//        uint _balance = _rewardsToken.sharesOf(address(this));
//        require(rewardRate <= _balance.div(rewardsDuration), "VaultBunnyBNB: reward rate must be in the right range");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardAdded(reward);
    }

    /* ========== SALVAGE PURPOSE ONLY ========== */

    // @dev rewardToken(CAKE) must not remain balance in this contract. So dev should be able to salvage reward token transferred by mistake.
    function recoverToken(address tokenAddress, uint tokenAmount) external override onlyOwner {
        require(tokenAddress != address(_stakingToken), "VaultBunnyBNB: cannot recover underlying token");

        IBEP20(tokenAddress).safeTransfer(owner(), tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
  ___                      _   _
 | _ )_  _ _ _  _ _ _  _  | | | |
 | _ \ || | ' \| ' \ || | |_| |_|
 |___/\_,_|_||_|_||_\_, | (_) (_)
                    |__/

*
* MIT License
* ===========
*
* Copyright (c) 2020 BunnyFinance
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

import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../../interfaces/IPancakePair.sol";
//import "../../interfaces/IPancakeFactory.sol";
import "../../interfaces/ISushiswapV2Factory.sol";
import "../../interfaces/AggregatorV3Interface.sol";
import "../../interfaces/IPriceCalculator.sol";
import "../../library/HomoraMath.sol";


contract SushiPriceCalculator is IPriceCalculator, OwnableUpgradeable {
    using SafeMath for uint;
    using HomoraMath for uint;

    address public constant BUNNY = 0x4C16f69302CcB511c5Fac682c7626B9eF0Dc126a;
    address private constant WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address private constant QUICK = 0x831753DD7087CaC61aB5644b308642cc1c33Dc13;
    address private constant AAVE = 0xD6DF932A45C0f255f85145f286eA0b292B21C90B;
    address private constant ETH = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
    address private constant USDT = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
    address private constant USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address private constant BTC = 0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6;
    address private constant DAI = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;
    address private constant SUSHI = 0x0b3F868E0BE5597D5DB7fEB59E1CADBb0fdDa50a;
    address private constant LINK = 0x53E0bca35eC356BD5ddDFebbD1Fc0fD03FaBad39;
    address private constant IBBTC = 0x4EaC4c4e9050464067D673102F8E24b2FccEB350;

    //IPancakeFactory private constant factory = IPancakeFactory(0x5757371414417b8C6CAad45bAeF941aBc7d3Ab32);
    ISushiswapV2Factory private constant factory = ISushiswapV2Factory(0xc35DADB65012eC5796536bD9864eD8773aBc74C4);


    /* ========== STATE VARIABLES ========== */

    address public keeper;

    mapping(address => address) private pairTokens;
    mapping(address => address) private tokenFeeds;
    mapping(address => ReferenceData) public references;

    /* ========== INITIALIZER ========== */

    function initialize() external initializer {
        __Ownable_init();

        setPairToken(BTC, ETH);
        setPairToken(AAVE, ETH);
        setPairToken(USDC, ETH);
        setPairToken(USDT, ETH);
        setPairToken(DAI, ETH);
        setPairToken(BUNNY, ETH);

    }

    /* ========== MODIFIERS ========== */

    modifier onlyKeeper {
        require(msg.sender == keeper || msg.sender == owner(), 'PriceCalculator: caller is not the owner or keeper');
        _;
    }

    /* ========== Restricted Operation ========== */

    function setKeeper(address _keeper) external onlyKeeper {
        require(_keeper != address(0), 'PriceCalculatorBSC: invalid keeper address');
        keeper = _keeper;
    }

    function setPairToken(address asset, address pairToken) public onlyOwner {
        pairTokens[asset] = pairToken;
    }

    function setTokenFeed(address asset, address feed) public onlyOwner {
        tokenFeeds[asset] = feed;
    }

    function setPrices(address[] memory assets, uint[] memory prices) external onlyKeeper {
        for (uint i = 0; i < assets.length; i++) {
            references[assets[i]] = ReferenceData({lastData : prices[i], lastUpdated : block.timestamp});
        }
    }

    /* ========== Value Calculation ========== */

    function priceOfMATIC() view public override returns (uint) {
        (, int price, , ,) = AggregatorV3Interface(tokenFeeds[WMATIC]).latestRoundData();
        return uint(price).mul(1e10);
    }

    function priceOfBunny() view public override returns (uint) {
        (, uint bunnyPriceInUSD) = valueOfAsset(BUNNY, 1e18);
        return bunnyPriceInUSD;
    }

    function priceOfETH() view public override returns (uint) {
        (, int price, , ,) = AggregatorV3Interface(tokenFeeds[ETH]).latestRoundData();
        return uint(price).mul(1e10);
    }

    function pricesInUSD(address[] memory assets) public view override returns (uint[] memory) {
        uint[] memory prices = new uint[](assets.length);
        for (uint i = 0; i < assets.length; i++) {
            (, uint valueInUSD) = valueOfAsset(assets[i], 1e18);
            prices[i] = valueInUSD;
        }
        return prices;
    }

    function valueOfAsset(address asset, uint amount) public view override returns (uint valueInETH, uint valueInUSD) {
        if (amount == 0) {
            return (0, 0);
        } else if (asset == address(0) || asset == WMATIC) {
            return _oracleValueOf(WMATIC, amount);
        } else if (asset == AAVE) {
            (, int price, , ,) = AggregatorV3Interface(tokenFeeds[AAVE]).latestRoundData();
            return _oracleValueOf(ETH, uint(price));
        } else if (keccak256(abi.encodePacked(IPancakePair(asset).symbol())) == keccak256("SLP")) {
            return _getPairPrice(asset, amount);
        } else {
            return _oracleValueOf(asset, amount);
        }
    }

    function unsafeValueOfAsset(address asset, uint amount) public view returns (uint valueInETH, uint valueInUSD) {
        valueInUSD = 0;
        valueInETH = 0;

        if (asset == ETH) {
            valueInETH = amount;
            valueInUSD = amount.mul(priceOfETH()).div(1e18);
        }
        else if (asset == address(0) || asset == WMATIC) {
            valueInUSD = amount.mul(priceOfMATIC()).div(1e18);
            valueInETH = valueInUSD.mul(1e18).div(priceOfETH());
        }
        else if (keccak256(abi.encodePacked(IPancakePair(asset).symbol())) == keccak256("SLP")) {
            if (IPancakePair(asset).totalSupply() == 0) return (0, 0);

            (uint reserve0, uint reserve1,) = IPancakePair(asset).getReserves();
            if (IPancakePair(asset).token0() == ETH) {
                valueInETH = amount.mul(reserve0).mul(2).div(IPancakePair(asset).totalSupply());
                valueInUSD = valueInETH.mul(priceOfETH()).div(1e18);
            } else if (IPancakePair(asset).token1() == ETH) {
                valueInETH = amount.mul(reserve1).mul(2).div(IPancakePair(asset).totalSupply());
                valueInUSD = valueInETH.mul(priceOfETH()).div(1e18);
            } else {
                (uint priceInETH,) = valueOfAsset(IPancakePair(asset).token0(), 1e18);
                if (priceInETH == 0) {
                    (priceInETH,) = valueOfAsset(IPancakePair(asset).token1(), 1e18);
                    valueInETH = amount.mul(reserve1).mul(2).mul(priceInETH).div(1e18).div(IPancakePair(asset).totalSupply());
                } else {
                    valueInETH = amount.mul(reserve0).mul(2).mul(priceInETH).div(1e18).div(IPancakePair(asset).totalSupply());
                }
                valueInUSD = valueInETH.mul(priceOfETH()).div(1e18);
            }

        }
        else {
            address pairToken = pairTokens[asset] == address(0) ? WMATIC : pairTokens[asset];
            address pair = factory.getPair(asset, pairToken);
            if (IBEP20(asset).balanceOf(pair) == 0) return (0, 0);
            (uint reserve0, uint reserve1,) = IPancakePair(pair).getReserves();
            if (IPancakePair(pair).token0() == pairToken) {
                valueInETH = reserve0.mul(amount).div(reserve1);
            } else if (IPancakePair(pair).token1() == pairToken) {
                valueInETH = reserve1.mul(amount).div(reserve0);
            } else {
                return (0, 0);
            }

            if (pairToken != ETH) {
                (uint pairValueInETH,) = valueOfAsset(pairToken, 1e18);
                valueInETH = valueInETH.mul(pairValueInETH).div(1e18);
            }
            valueInUSD = valueInETH.mul(priceOfETH()).div(1e18);
        }
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _oracleValueOf(address asset, uint amount) private view returns (uint valueInETH, uint valueInUSD) {
        valueInUSD = 0;
        if (tokenFeeds[asset] != address(0)) {
            (, int price, , ,) = AggregatorV3Interface(tokenFeeds[asset]).latestRoundData();
            valueInUSD = uint(price).mul(1e10).mul(amount).div(1e18);
        } else if (references[asset].lastUpdated > block.timestamp.sub(1 days)) {
            valueInUSD = references[asset].lastData.mul(amount).div(1e18);
        }
        valueInETH = valueInUSD.mul(1e18).div(priceOfETH());
    }

    function _getPairPrice(address pair, uint amount) private view returns (uint valueInETH, uint valueInUSD) {
        address token0 = IPancakePair(pair).token0();
        address token1 = IPancakePair(pair).token1();
        uint totalSupply = IPancakePair(pair).totalSupply();
        (uint r0, uint r1,) = IPancakePair(pair).getReserves();

        if (IBEP20(token0).decimals() < uint8(18)) {
            r0 = r0.mul(10 ** uint(uint8(18) - IBEP20(token0).decimals()));
        }

        if (IBEP20(token1).decimals() < uint8(18)) {
            r1 = r1.mul(10 ** uint(uint8(18) - IBEP20(token1).decimals()));
        }

        uint sqrtK = HomoraMath.sqrt(r0.mul(r1)).fdiv(totalSupply);
        (uint px0,) = valueOfAsset(token0, 1e18);
        (uint px1,) = valueOfAsset(token1, 1e18);
        uint fairPriceInETH = sqrtK.mul(2).mul(HomoraMath.sqrt(px0)).div(2 ** 56).mul(HomoraMath.sqrt(px1)).div(2 ** 56);

        valueInETH = fairPriceInETH.mul(amount).div(1e18);
        valueInUSD = valueInETH.mul(priceOfETH()).div(1e18);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface ISushiswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function setMigrator(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface AggregatorV3Interface {

    function decimals() external view returns (uint8);
    function description() external view returns (string memory);
    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
    external
    view
    returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
    function latestRoundData()
    external
    view
    returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );

}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";


library HomoraMath {
    using SafeMath for uint;

    function divCeil(uint lhs, uint rhs) internal pure returns (uint) {
        return lhs.add(rhs).sub(1) / rhs;
    }

    function fmul(uint lhs, uint rhs) internal pure returns (uint) {
        return lhs.mul(rhs) / (2**112);
    }

    function fdiv(uint lhs, uint rhs) internal pure returns (uint) {
        return lhs.mul(2**112) / rhs;
    }

    // implementation from https://github.com/Uniswap/uniswap-lib/commit/99f3f28770640ba1bb1ff460ac7c5292fb8291a0
    // original implementation: https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol#L687
    function sqrt(uint x) internal pure returns (uint) {
        if (x == 0) return 0;
        uint xx = x;
        uint r = 1;

        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }

        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }

        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint r1 = x / r;
        return (r < r1 ? r : r1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";


abstract contract BEP20Upgradeable is IBEP20, OwnableUpgradeable {
    using SafeMath for uint;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    uint256[50] private __gap;

    /**
     * @dev sets initials supply and the owner
     */
    function __BEP20__init(string memory name, string memory symbol, uint8 decimals) internal initializer {
        __Ownable_init();
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external override view returns (address) {
        return owner();
    }

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external override view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external override view returns (string memory) {
        return _symbol;
    }

    /**
    * @dev Returns the token name.
    */
    function name() external override view returns (string memory) {
        return _name;
    }

    /**
     * @dev See {BEP20-totalSupply}.
     */
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {BEP20-balanceOf}.
     */
    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {BEP20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {BEP20-allowance}.
     */
    function allowance(address owner, address spender) external override view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {BEP20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {BEP20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {BEP20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }

    /**
   * @dev Burn `amount` tokens and decreasing the total supply.
   */
    function burn(uint256 amount) public returns (bool) {
        _burn(_msgSender(), amount);
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "BEP20: burn amount exceeds allowance"));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol";

contract BulkSender {
    struct Receiver {
        address to;
        uint amount;
    }

    function send(address token, Receiver[] memory receivers) external {
        uint sum;
        for(uint i=0; i<receivers.length; i++) {
            sum += receivers[i].amount;
        }

        IBEP20(token).transferFrom(msg.sender, address(this), sum);
        for(uint i=0; i<receivers.length; i++) {
            IBEP20(token).transfer(receivers[i].to, receivers[i].amount);
        }
    }

    function recoverToken(address token) external {
        IBEP20(token).transfer(0xbC776ac3af4D993774A54af497055170C81c113F, IBEP20(token).balanceOf(address(this)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
  ___                      _   _
 | _ )_  _ _ _  _ _ _  _  | | | |
 | _ \ || | ' \| ' \ || | |_| |_|
 |___/\_,_|_||_|_||_\_, | (_) (_)
                    |__/

*
* MIT License
* ===========
*
* Copyright (c) 2020 BunnyFinance
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

import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../../interfaces/IPancakePair.sol";
import "../../interfaces/IPancakeFactory.sol";
import "../../interfaces/AggregatorV3Interface.sol";
import "../../interfaces/IPriceCalculator.sol";
import "../../library/HomoraMath.sol";
import "../../interfaces/IZap.sol";

contract PriceCalculator is IPriceCalculator, OwnableUpgradeable {
    using SafeMath for uint;
    using HomoraMath for uint;

    address public constant BUNNY = 0x4C16f69302CcB511c5Fac682c7626B9eF0Dc126a;
    address private constant WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address private constant QUICK = 0x831753DD7087CaC61aB5644b308642cc1c33Dc13;
    address private constant AAVE = 0xD6DF932A45C0f255f85145f286eA0b292B21C90B;
    address private constant ETH = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
    address private constant USDT = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
    address private constant USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address private constant BTC = 0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6;
    address private constant DAI = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;
    address private constant SUSHI = 0x0b3F868E0BE5597D5DB7fEB59E1CADBb0fdDa50a;
    address private constant LINK = 0x53E0bca35eC356BD5ddDFebbD1Fc0fD03FaBad39;
    address private constant IBBTC = 0x4EaC4c4e9050464067D673102F8E24b2FccEB350;
    address private constant FRAX = 0x104592a158490a9228070E0A8e5343B499e125D0;

    IPancakeFactory private constant factory = IPancakeFactory(0x5757371414417b8C6CAad45bAeF941aBc7d3Ab32);
    IPancakeFactory private constant sushiFactory = IPancakeFactory(0xc35DADB65012eC5796536bD9864eD8773aBc74C4);
    IZap private constant zapPolygon = IZap(0x663462430834E220851a3E981D0E1199501b84F6);

    /* ========== STATE VARIABLES ========== */

    address public keeper;

    mapping(address => address) private pairTokens;
    mapping(address => address) private tokenFeeds;
    mapping(address => ReferenceData) public references;

    /* ========== INITIALIZER ========== */

    function initialize() external initializer {
        __Ownable_init();

        setPairToken(BTC, ETH);
        setPairToken(AAVE, ETH);
        setPairToken(USDC, ETH);
        setPairToken(USDT, ETH);
        setPairToken(DAI, ETH);
        setPairToken(BUNNY, ETH);
        setPairToken(IBBTC, BTC);
        setPairToken(FRAX, USDC);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyKeeper {
        require(msg.sender == keeper || msg.sender == owner(), 'PriceCalculator: caller is not the owner or keeper');
        _;
    }

    /* ========== Restricted Operation ========== */

    function setKeeper(address _keeper) external onlyKeeper {
        require(_keeper != address(0), 'PriceCalculatorBSC: invalid keeper address');
        keeper = _keeper;
    }

    function setPairToken(address asset, address pairToken) public onlyOwner {
        pairTokens[asset] = pairToken;
    }

    function setTokenFeed(address asset, address feed) public onlyOwner {
        tokenFeeds[asset] = feed;
    }

    function setPrices(address[] memory assets, uint[] memory prices) external onlyKeeper {
        for (uint i = 0; i < assets.length; i++) {
            references[assets[i]] = ReferenceData({lastData : prices[i], lastUpdated : block.timestamp});
        }
    }

    /* ========== Value Calculation ========== */

    function priceOfMATIC() view public override returns (uint) {
        (, int price, , ,) = AggregatorV3Interface(tokenFeeds[WMATIC]).latestRoundData();
        return uint(price).mul(1e10);
    }

    function priceOfBunny() view public override returns (uint) {
        (, uint bunnyPriceInUSD) = valueOfAsset(BUNNY, 1e18);
        return bunnyPriceInUSD;
    }

    function priceOfETH() view public override returns (uint) {
        (, int price, , ,) = AggregatorV3Interface(tokenFeeds[ETH]).latestRoundData();
        return uint(price).mul(1e10);
    }

    function pricesInUSD(address[] memory assets) public view override returns (uint[] memory) {
        uint[] memory prices = new uint[](assets.length);
        for (uint i = 0; i < assets.length; i++) {
            (, uint valueInUSD) = valueOfAsset(assets[i], 1e18);
            prices[i] = valueInUSD;
        }
        return prices;
    }

    function valueOfAsset(address asset, uint amount) public view override returns (uint valueInETH, uint valueInUSD) {
        if (amount == 0) {
            return (0, 0);
        } else if (asset == address(0) || asset == WMATIC) {
            return _oracleValueOf(WMATIC, amount);
        } else if (asset == AAVE) {
            (, int price, , ,) = AggregatorV3Interface(tokenFeeds[AAVE]).latestRoundData();
            return _oracleValueOf(ETH, uint(price));
        } else if (keccak256(abi.encodePacked(IPancakePair(asset).symbol())) == keccak256("UNI-V2") ||
            keccak256(abi.encodePacked(IPancakePair(asset).symbol())) == keccak256("SLP")) {
            return _getPairPrice(asset, amount);
        } else {
            return _oracleValueOf(asset, amount);
        }
    }

    function unsafeValueOfAsset(address asset, uint amount) public view returns (uint valueInETH, uint valueInUSD) {
        valueInUSD = 0;
        valueInETH = 0;

        if (asset == ETH) {
            valueInETH = amount;
            valueInUSD = amount.mul(priceOfETH()).div(1e18);
        }
        else if (asset == address(0) || asset == WMATIC) {
            valueInUSD = amount.mul(priceOfMATIC()).div(1e18);
            valueInETH = valueInUSD.mul(1e18).div(priceOfETH());
        }
        else if (keccak256(abi.encodePacked(IPancakePair(asset).symbol())) == keccak256("UNI-V2") ||
            keccak256(abi.encodePacked(IPancakePair(asset).symbol())) == keccak256("SLP")) {
            if (IPancakePair(asset).totalSupply() == 0) return (0, 0);

            (uint reserve0, uint reserve1,) = IPancakePair(asset).getReserves();
            if (IPancakePair(asset).token0() == ETH) {
                valueInETH = amount.mul(reserve0).mul(2).div(IPancakePair(asset).totalSupply());
                valueInUSD = valueInETH.mul(priceOfETH()).div(1e18);
            } else if (IPancakePair(asset).token1() == ETH) {
                valueInETH = amount.mul(reserve1).mul(2).div(IPancakePair(asset).totalSupply());
                valueInUSD = valueInETH.mul(priceOfETH()).div(1e18);
            } else {
                (uint priceInETH,) = valueOfAsset(IPancakePair(asset).token0(), 1e18);
                if (priceInETH == 0) {
                    (priceInETH,) = valueOfAsset(IPancakePair(asset).token1(), 1e18);
                    reserve1 = reserve1.mul(10 ** uint(uint8(18) - IBEP20(IPancakePair(asset).token1()).decimals()));
                    valueInETH = amount.mul(reserve1).mul(2).mul(priceInETH).div(1e18).div(IPancakePair(asset).totalSupply());
                } else {
                    reserve0 = reserve0.mul(10 ** uint(uint8(18) - IBEP20(IPancakePair(asset).token0()).decimals()));
                    valueInETH = amount.mul(reserve0).mul(2).mul(priceInETH).div(1e18).div(IPancakePair(asset).totalSupply());
                }
                valueInUSD = valueInETH.mul(priceOfETH()).div(1e18);
            }

        }
        else {
            address pairToken = pairTokens[asset] == address(0) ? WMATIC : pairTokens[asset];

            address pair = zapPolygon.covers(asset) ? factory.getPair(asset, pairToken) : sushiFactory.getPair(asset, pairToken);
            address token0 = IPancakePair(pair).token0();
            address token1 = IPancakePair(pair).token1();

            if (IBEP20(asset).balanceOf(pair) == 0) return (0, 0);

            (uint reserve0, uint reserve1,) = IPancakePair(pair).getReserves();

            if (IBEP20(token0).decimals() < uint8(18)){
                reserve0 = reserve0.mul(10 ** uint(uint8(18) - IBEP20(token0).decimals()));
            }

            if (IBEP20(token1).decimals() < uint8(18)) {
                reserve1 = reserve1.mul(10 ** uint(uint8(18) - IBEP20(token1).decimals()));
            }

            if (token0 == pairToken) {
                valueInETH = reserve0.mul(amount).div(reserve1);
            } else if (token1 == pairToken) {
                valueInETH = reserve1.mul(amount).div(reserve0);
            } else {
                return (0, 0);
            }

            if (pairToken != ETH) {
                (uint pairValueInETH,) = valueOfAsset(pairToken, 1e18);
                valueInETH = valueInETH.mul(pairValueInETH).div(1e18);
            }

            valueInUSD = valueInETH.mul(priceOfETH()).div(1e18);

        }
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _oracleValueOf(address asset, uint amount) private view returns (uint valueInETH, uint valueInUSD) {
        valueInUSD = 0;
        if (tokenFeeds[asset] != address(0)) {
            (, int price, , ,) = AggregatorV3Interface(tokenFeeds[asset]).latestRoundData();
            valueInUSD = uint(price).mul(1e10).mul(amount).div(1e18);
        } else if (references[asset].lastUpdated > block.timestamp.sub(1 days)) {
            valueInUSD = references[asset].lastData.mul(amount).div(1e18);
        }
        valueInETH = valueInUSD.mul(1e18).div(priceOfETH());
    }

    function _getPairPrice(address pair, uint amount) private view returns (uint valueInETH, uint valueInUSD) {
        address token0 = IPancakePair(pair).token0();
        address token1 = IPancakePair(pair).token1();
        uint totalSupply = IPancakePair(pair).totalSupply();
        (uint r0, uint r1,) = IPancakePair(pair).getReserves();

        if (IBEP20(token0).decimals() < uint8(18)) {
            r0 = r0.mul(10 ** uint(uint8(18) - IBEP20(token0).decimals()));
        }

        if (IBEP20(token1).decimals() < uint8(18)) {
            r1 = r1.mul(10 ** uint(uint8(18) - IBEP20(token1).decimals()));
        }

        uint sqrtK = HomoraMath.sqrt(r0.mul(r1)).fdiv(totalSupply);
        (uint px0,) = valueOfAsset(token0, 1e18);
        (uint px1,) = valueOfAsset(token1, 1e18);
        uint fairPriceInETH = sqrtK.mul(2).mul(HomoraMath.sqrt(px0)).div(2 ** 56).mul(HomoraMath.sqrt(px1)).div(2 ** 56);

        valueInETH = fairPriceInETH.mul(amount).div(1e18);
        valueInUSD = valueInETH.mul(priceOfETH()).div(1e18);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/*
  ___                      _   _
 | _ )_  _ _ _  _ _ _  _  | | | |
 | _ \ || | ' \| ' \ || | |_| |_|
 |___/\_,_|_||_|_||_\_, | (_) (_)
                    |__/

*
* MIT License
* ===========
*
* Copyright (c) 2020 BunnyFinance
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

import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/BEP20.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol";
import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../interfaces/IBunnyMinterV2.sol";
import "../interfaces/IStakingRewards.sol";
import "../interfaces/IPriceCalculator.sol";
import "../interfaces/IPancakeRouter02.sol";
import "../interfaces/IPancakePair.sol";
import "../interfaces/IZap.sol";

import "../library/SafeToken.sol";

contract BunnyMinterV2 is IBunnyMinterV2, OwnableUpgradeable {
    using SafeMath for uint;
    using SafeBEP20 for IBEP20;

    /* ========== CONSTANTS ============= */

    address private constant TIMELOCK = 0xf36eC1522625b2eBD0b4071945F3e97134653F8f;
    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;

    address public constant DEPLOYER = 0xbC776ac3af4D993774A54af497055170C81c113F;

    address public constant BUNNY = 0x4C16f69302CcB511c5Fac682c7626B9eF0Dc126a;
    address public constant BUNNY_ETH = 0x62052b489Cb5bC72a9DC8EEAE4B24FD50639921a;
    address public constant BUNNY_POOL = 0x10C8CFCa4953Bc554e71ddE3Fa19c335e163D7Ac;
    address public constant BUNNY_MAXIMIZER = 0x4Ad69DC9eA7Cc01CE13A37F20817baC4bF0De1ba;
    IBEP20 public constant ETH = IBEP20(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);

    IZap private constant zapPolygon = IZap(0x663462430834E220851a3E981D0E1199501b84F6);
    IPriceCalculator private constant priceCalculator = IPriceCalculator(0xE3B11c3Bd6d90CfeBBb4FB9d59486B0381D38021);
    address private constant quickRouter = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
    address private constant sushiRouter = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;

    uint public constant FEE_MAX = 10000;

    /* ========== STATE VARIABLES ========== */

    address public bunnyChef;
    mapping(address => bool) private _minters;

    uint public PERFORMANCE_FEE;
    uint public override WITHDRAWAL_FEE_FREE_PERIOD;
    uint public override WITHDRAWAL_FEE;

    uint public override bunnyPerProfitBNB;

    uint private _floatingRateEmission;
    uint private _freThreshold;

    // TODO constant
    IZap public zapSushi;

    /* ========== MODIFIERS ========== */

    modifier onlyMinter {
        require(isMinter(msg.sender) == true, "BunnyMinterV2: caller is not the minter");
        _;
    }

    modifier onlyBunnyChef {
        require(msg.sender == bunnyChef, "BunnyMinterV2: caller not the bunny chef");
        _;
    }

    /* ========== EVENTS ========== */

    event PerformanceFee(address indexed asset, uint amount, uint value);

    receive() external payable {}

    /* ========== INITIALIZER ========== */

    function initialize() external initializer {
        __Ownable_init();
        WITHDRAWAL_FEE_FREE_PERIOD = 3 days;
        WITHDRAWAL_FEE = 50;
        PERFORMANCE_FEE = 3000;

        IBEP20(BUNNY).approve(BUNNY_POOL, uint(- 1));
        IBEP20(BUNNY).approve(BUNNY_MAXIMIZER, uint(- 1));
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function transferBunnyOwner(address _owner) external onlyOwner {
        Ownable(BUNNY).transferOwnership(_owner);
    }

    function setWithdrawalFee(uint _fee) external onlyOwner {
        require(_fee < 500, "wrong fee");
        // less 5%
        WITHDRAWAL_FEE = _fee;
    }

    function setPerformanceFee(uint _fee) external onlyOwner {
        require(_fee < 5000, "wrong fee");
        PERFORMANCE_FEE = _fee;
    }

    function setWithdrawalFeeFreePeriod(uint _period) external onlyOwner {
        WITHDRAWAL_FEE_FREE_PERIOD = _period;
    }

    function setMinter(address minter, bool canMint) external override onlyOwner {
        if (canMint) {
            _minters[minter] = canMint;
        } else {
            delete _minters[minter];
        }
    }

    function setBunnyChef(address _bunnyChef) external onlyOwner {
        require(bunnyChef == address(0), "BunnyMinterV2: setBunnyChef only once");
        bunnyChef = _bunnyChef;
    }

    function setFloatingRateEmission(uint floatingRateEmission) external onlyOwner {
        require(floatingRateEmission > 1e18 && floatingRateEmission < 10e18, "BunnyMinterV2: floatingRateEmission wrong range");
        _floatingRateEmission = floatingRateEmission;
    }

    function setFREThreshold(uint threshold) external onlyOwner {
        _freThreshold = threshold;
    }

    /* ========== VIEWS ========== */

    function isMinter(address account) public view override returns (bool) {
        if (IBEP20(BUNNY).getOwner() != address(this)) {
            return false;
        }
        return _minters[account];
    }

    function amountBunnyToMint(uint ethProfit) public view override returns (uint) {
        if (priceCalculator.priceOfBunny() == 0) {
            return 0;
        }
        return ethProfit.mul(priceCalculator.priceOfETH()).div(priceCalculator.priceOfBunny()).mul(floatingRateEmission()).div(1e18);
    }

    function withdrawalFee(uint amount, uint depositedAt) external view override returns (uint) {
        if (depositedAt.add(WITHDRAWAL_FEE_FREE_PERIOD) > block.timestamp) {
            return amount.mul(WITHDRAWAL_FEE).div(FEE_MAX);
        }
        return 0;
    }

    function performanceFee(uint profit) public view override returns (uint) {
        return profit.mul(PERFORMANCE_FEE).div(FEE_MAX);
    }

    function floatingRateEmission() public view returns (uint) {
        return _floatingRateEmission == 0 ? 200e16 : _floatingRateEmission;
    }

    function freThreshold() public view returns (uint) {
        return _freThreshold == 0 ? 500e18 : _freThreshold;
    }

    function shouldMarketBuy() public view returns (bool) {
        return priceCalculator.priceOfBunny().mul(freThreshold()).div(priceCalculator.priceOfETH()) < 1e18 - 1000;
    }

    /* ========== V1 FUNCTIONS ========== */

    function mintFor(address asset, uint _withdrawalFee, uint _performanceFee, address to, uint) public payable override onlyMinter {
        uint feeSum = _performanceFee.add(_withdrawalFee);
        _transferAsset(asset, feeSum);

        if (asset == BUNNY) {
            IBEP20(BUNNY).safeTransfer(TIMELOCK, feeSum);
            return;
        }

        bool marketBuy = shouldMarketBuy();
        if (marketBuy == false) {

            uint bunnyETHAmount = _zapAssets(asset, feeSum, BUNNY_ETH);
            if (bunnyETHAmount == 0) return;

            IBEP20(BUNNY_ETH).safeTransfer(BUNNY_POOL, bunnyETHAmount);
            IStakingRewards(BUNNY_POOL).notifyRewardAmount(bunnyETHAmount);
        } else {
            if (_withdrawalFee > 0) {

                uint bunnyETHAmount = _zapAssets(asset, _withdrawalFee, BUNNY_ETH);
                if (bunnyETHAmount == 0) return;

                IBEP20(BUNNY_ETH).safeTransfer(BUNNY_POOL, bunnyETHAmount);
                IStakingRewards(BUNNY_POOL).notifyRewardAmount(bunnyETHAmount);
            }

            if (_performanceFee == 0) return;

            uint bunnyAmount = _zapAssets(asset, _performanceFee, BUNNY);
            IBEP20(BUNNY).safeTransfer(to, bunnyAmount);

            _performanceFee = _performanceFee.mul(floatingRateEmission().sub(1e18)).div(floatingRateEmission());
        }

        (uint contributionInETH, uint contributionInUSD) = priceCalculator.valueOfAsset(asset, _performanceFee);

        uint mintBunny = amountBunnyToMint(contributionInETH);
        if (mintBunny == 0) return;
        _mint(mintBunny, to);

        if (marketBuy) {
            uint usd = contributionInUSD.mul(floatingRateEmission()).div(floatingRateEmission().sub(1e18));
            emit PerformanceFee(asset, _performanceFee, usd);
        } else {
            emit PerformanceFee(asset, _performanceFee, contributionInUSD);
        }
    }

    /* ========== PancakeSwap V2 FUNCTIONS ========== */

    function mintForV2(address asset, uint _withdrawalFee, uint _performanceFee, address to, uint timestamp) external payable override onlyMinter {
        mintFor(asset, _withdrawalFee, _performanceFee, to, timestamp);
    }

    /* ========== BunnyChef FUNCTIONS ========== */

    function mint(uint amount) external override onlyBunnyChef {
        if (amount == 0) return;
        _mint(amount, address(this));
    }

    function safeBunnyTransfer(address _to, uint _amount) external override onlyBunnyChef {
        if (_amount == 0) return;

        uint bal = IBEP20(BUNNY).balanceOf(address(this));
        if (_amount <= bal) {
            IBEP20(BUNNY).safeTransfer(_to, _amount);
        } else {
            IBEP20(BUNNY).safeTransfer(_to, bal);
        }
    }

    // @dev should be called when determining mint in governance. Bunny is transferred to the timelock contract.
    function mintGov(uint amount) external override onlyOwner {
        if (amount == 0) return;
        _mint(amount, TIMELOCK);
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _zapAssets(address asset, uint amount, address toAsset) private returns (uint toAssetAmount) {
        if (asset == toAsset) return amount;
        uint _initToAssetAmount = IBEP20(toAsset).balanceOf(address(this));

        if (asset == address(0)) {
            zapPolygon.zapIn{value : amount}(toAsset);
        }
        else if (keccak256(abi.encodePacked(IPancakePair(asset).symbol())) == keccak256("UNI-V2") ||
            keccak256(abi.encodePacked(IPancakePair(asset).symbol())) == keccak256("SLP")) {
            IPancakeRouter02 router = IPancakeRouter02(_getRouterAddress(asset));

            if (IBEP20(asset).allowance(address(this), address(router)) == 0) {
                IBEP20(asset).safeApprove(address(router), uint(- 1));
            }

            IPancakePair pair = IPancakePair(asset);
            address token0 = pair.token0();
            address token1 = pair.token1();

            if (IPancakePair(asset).balanceOf(asset) > 0) {
                IPancakePair(asset).burn(address(DEPLOYER));
            }
            (uint amountToken0, uint amountToken1) = router.removeLiquidity(token0, token1, amount, 0, 0, address(this), block.timestamp);

            _tokenToAsset(token0, amountToken0, toAsset);
            _tokenToAsset(token1, amountToken1, toAsset);
        }
        else {
            // default. zap single asset to other asset in quickswap
            if (IBEP20(asset).allowance(address(this), address(zapPolygon)) == 0) {
                IBEP20(asset).safeApprove(address(zapPolygon), uint(- 1));
            }

            zapPolygon.zapInToken(asset, amount, toAsset);
        }

        toAssetAmount = IBEP20(toAsset).balanceOf(address(this)).sub(_initToAssetAmount);
    }

    function _tokenToAsset(address _token, uint _amount, address _toAsset) private {
        if (zapPolygon.covers(_token)) {
            if (_token != _toAsset) {
                if (IBEP20(_token).allowance(address(this), address(zapPolygon)) == 0) {
                    IBEP20(_token).safeApprove(address(zapPolygon), uint(- 1));
                }

                zapPolygon.zapInToken(_token, _amount, _toAsset);
            }
        } else {
            if (IBEP20(_token).allowance(address(this), address(zapSushi)) == 0) {
                IBEP20(_token).safeApprove(address(zapSushi), uint(- 1));
            }

            uint initETHBalance = ETH.balanceOf(address(this));
            zapSushi.zapInToken(_token, _amount, address(ETH));

            if (ETH.allowance(address(this), address(zapPolygon)) == 0) {
                ETH.safeApprove(address(zapPolygon), uint(- 1));
            }
            zapPolygon.zapInToken(address(ETH), ETH.balanceOf(address(this)).sub(initETHBalance), _toAsset);
        }
    }

    function _transferAsset(address asset, uint amount) private {
        if (asset == address(0)) {
            // case) transferred BNB
            require(msg.value >= amount);
        } else {
            IBEP20(asset).safeTransferFrom(msg.sender, address(this), amount);
        }
    }

    function _mint(uint amount, address to) private {
        BEP20 tokenBUNNY = BEP20(BUNNY);

        tokenBUNNY.mint(amount);
        if (to != address(this)) {
            tokenBUNNY.transfer(to, amount);
        }

        uint bunnyForDev = amount.mul(15).div(100);
        tokenBUNNY.mint(bunnyForDev);
        IStakingRewards(BUNNY_MAXIMIZER).stakeTo(bunnyForDev, DEPLOYER);
    }

    function _getRouterAddress(address asset) private pure returns (address _routerAddress) {
        _routerAddress = keccak256(abi.encodePacked(IPancakePair(asset).symbol())) == keccak256("SLP") ? sushiRouter : quickRouter;
    }

    // TODO constant
    function setZapSushi(address _sushizap) external onlyOwner {
        zapSushi = IZap(_sushizap);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IStakingRewards {
    function stakeTo(uint256 amount, address _to) external;
    function notifyRewardAmount(uint256 reward) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface ERC20Interface {
    function balanceOf(address user) external view returns (uint256);
}

library SafeToken {
    function myBalance(address token) internal view returns (uint256) {
        return ERC20Interface(token).balanceOf(address(this));
    }

    function balanceOf(address token, address user) internal view returns (uint256) {
        return ERC20Interface(token).balanceOf(user);
    }

    function safeApprove(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeApprove");
    }

    function safeTransfer(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeTransfer");
    }

    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeTransferFrom");
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{ value: value }(new bytes(0));
        require(success, "!safeTransferETH");
    }
}

// Copyright 2020 Compound Labs, Inc.
// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
// Ctrl+f for XXX to see all the modifications.

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";


contract Timelock {
    using SafeMath for uint;

    event NewAdmin(address indexed newAdmin);
    event NewPendingAdmin(address indexed newPendingAdmin);
    event NewDelay(uint indexed newDelay);
    event CancelTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature, bytes data, uint eta);
    event ExecuteTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature, bytes data, uint eta);
    event QueueTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature, bytes data, uint eta);

    uint public constant GRACE_PERIOD = 14 days;

    uint public constant MINIMUM_DELAY = 12 hours;
    uint public constant MAXIMUM_DELAY = 30 days;

    address public admin;
    address public pendingAdmin;
    uint public delay;

    mapping(bytes32 => bool) public queuedTransactions;


    constructor(address admin_, uint delay_) public {
        require(delay_ >= MINIMUM_DELAY, "Timelock::constructor: Delay must exceed minimum delay.");
        require(delay_ <= MAXIMUM_DELAY, "Timelock::setDelay: Delay must not exceed maximum delay.");

        admin = admin_;
        delay = delay_;
    }

    // XXX: function() external payable { }
    receive() external payable {}

    function setDelay(uint delay_) public {
        require(msg.sender == address(this), "Timelock::setDelay: Call must come from Timelock.");
        require(delay_ >= MINIMUM_DELAY, "Timelock::setDelay: Delay must exceed minimum delay.");
        require(delay_ <= MAXIMUM_DELAY, "Timelock::setDelay: Delay must not exceed maximum delay.");
        delay = delay_;

        emit NewDelay(delay);
    }

    function acceptAdmin() public {
        require(msg.sender == pendingAdmin, "Timelock::acceptAdmin: Call must come from pendingAdmin.");
        admin = msg.sender;
        pendingAdmin = address(0);

        emit NewAdmin(admin);
    }

    function setPendingAdmin(address pendingAdmin_) public {
        require(msg.sender == address(this), "Timelock::setPendingAdmin: Call must come from Timelock.");
        pendingAdmin = pendingAdmin_;

        emit NewPendingAdmin(pendingAdmin);
    }

    function queueTransaction(address target, uint value, string memory signature, bytes memory data, uint eta) public returns (bytes32) {
        require(msg.sender == admin, "Timelock::queueTransaction: Call must come from admin.");
        require(eta >= getBlockTimestamp().add(delay), "Timelock::queueTransaction: Estimated execution block must satisfy delay.");

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        queuedTransactions[txHash] = true;

        emit QueueTransaction(txHash, target, value, signature, data, eta);
        return txHash;
    }

    function cancelTransaction(address target, uint value, string memory signature, bytes memory data, uint eta) public {
        require(msg.sender == admin, "Timelock::cancelTransaction: Call must come from admin.");

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        queuedTransactions[txHash] = false;

        emit CancelTransaction(txHash, target, value, signature, data, eta);
    }

    function executeTransaction(address target, uint value, string memory signature, bytes memory data, uint eta) public payable returns (bytes memory) {
        require(msg.sender == admin, "Timelock::executeTransaction: Call must come from admin.");

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        require(queuedTransactions[txHash], "Timelock::executeTransaction: Transaction hasn't been queued.");
        require(getBlockTimestamp() >= eta, "Timelock::executeTransaction: Transaction hasn't surpassed time lock.");
        require(getBlockTimestamp() <= eta.add(GRACE_PERIOD), "Timelock::executeTransaction: Transaction is stale.");

        queuedTransactions[txHash] = false;

        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        // solium-disable-next-line security/no-call-value
        // XXX: Using ".value(...)" is deprecated. Use "{value: ...}" instead.
        (bool success, bytes memory returnData) = target.call{value : value}(callData);
        require(success, "Timelock::executeTransaction: Transaction execution reverted.");

        emit ExecuteTransaction(txHash, target, value, signature, data, eta);

        return returnData;
    }

    function getBlockTimestamp() internal view returns (uint) {
        // solium-disable-next-line security/no-block-members
        return block.timestamp;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/*
  ___                      _   _
 | _ )_  _ _ _  _ _ _  _  | | | |
 | _ \ || | ' \| ' \ || | |_| |_|
 |___/\_,_|_||_|_||_\_, | (_) (_)
                    |__/

*
* MIT License
* ===========
*
* Copyright (c) 2020 BunnyFinance
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

import "@pancakeswap/pancake-swap-lib/contracts/access/Ownable.sol";


contract Whitelist is Ownable {
    mapping(address => bool) private _whitelist;
    bool private _disable;                      // default - false means whitelist feature is working on. if true no more use of whitelist

    event Whitelisted(address indexed _address, bool whitelist);
    event EnableWhitelist();
    event DisableWhitelist();

    modifier onlyWhitelisted {
        require(_disable || _whitelist[msg.sender], "Whitelist: caller is not on the whitelist");
        _;
    }

    function isWhitelist(address _address) public view returns (bool) {
        return _whitelist[_address];
    }

    function setWhitelist(address _address, bool _on) external onlyOwner {
        _whitelist[_address] = _on;

        emit Whitelisted(_address, _on);
    }

    function disableWhitelist(bool disable) external onlyOwner {
        _disable = disable;
        if (disable) {
            emit DisableWhitelist();
        } else {
            emit EnableWhitelist();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/*
  ___                      _   _
 | _ )_  _ _ _  _ _ _  _  | | | |
 | _ \ || | ' \| ' \ || | |_| |_|
 |___/\_,_|_||_|_||_\_, | (_) (_)
                    |__/

*
* MIT License
* ===========
*
* Copyright (c) 2020 BunnyFinance
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

import "../library/bep20/BEP20Upgradeable.sol";

contract BunnyToken is BEP20Upgradeable {

    /* ========== INITIALIZER ========== */

    function initialize(string memory name, string memory symbol, uint8 decimals) external initializer {
        __BEP20__init(name, symbol, decimals);
    }

    /* ========== RESTRICTED ========== */

    function mint(uint256 _amount) public onlyOwner returns (bool) {
        _mint(msg.sender, _amount);
        return true;
    }
}