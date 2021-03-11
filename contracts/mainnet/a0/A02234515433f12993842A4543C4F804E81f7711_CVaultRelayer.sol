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
import "./BunnyToken.sol";


contract BunnyChef is IBunnyChef, OwnableUpgradeable {
    using SafeMath for uint;
    using SafeBEP20 for IBEP20;

    /* ========== CONSTANTS ============= */

    BunnyToken public constant BUNNY = BunnyToken(0xC9849E6fdB743d08fAeE3E34dd2D1bc69EA11a51);

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
        return userInfo.balance.mul(accBunnyPerShare).div(1e12).sub(userInfo.rewardPaid);
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

    function updateRewardsOf(address vault) public updateRewards(vault) {
    }

    /* ========== SALVAGE PURPOSE ONLY ========== */

    function recoverToken(address _token, uint amount) virtual external onlyOwner {
        require(_token != address(BUNNY), "BunnyChef: cannot recover BUNNY token");
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

import "../GSN/ContextUpgradeable.sol";
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IBunnyMinterV2 {
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
    function withdraw(uint256 _amount) external;    // BUNNY STAKING POOL ONLY
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
    function priceShare() external view returns(uint);

    /* ========== Strategy Information ========== */

    function pid() external view returns (uint);
    function poolType() external view returns (PoolConstant.PoolTypes);
    function depositedAt(address account) external view returns (uint);
    function rewardsToken() external view returns (address);

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount, uint256 withdrawalFee);
    event ProfitPaid(address indexed user, uint256 profit, uint256 performanceFee);
    event BunnyPaid(address indexed user, uint256 profit, uint256 performanceFee);
    event Harvested(uint256 profit);
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


// BunnyToken with Governance.
contract BunnyToken is BEP20('Bunny Token', 'BUNNY') {
    // @dev Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
        _moveDelegates(address(0), _delegates[_to], _amount);
    }

    // Copied and modified from YAM code:
    // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernanceStorage.sol
    // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernance.sol
    // Which is copied and modified from COMPOUND:
    // https://github.com/compound-finance/compound-protocol/blob/master/contracts/Governance/Comp.sol

    // @dev A record of each accounts delegate
    mapping (address => address) internal _delegates;


    // @dev A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }

    // @dev A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    // @dev The number of checkpoints for each account
    mapping (address => uint32) public numCheckpoints;

    // @dev The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    // @dev The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    // @dev A record of states for signing / validating signatures
    mapping (address => uint) public nonces;

    // @dev An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    // @dev An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    /**
     * @dev Delegate votes from `msg.sender` to `delegatee`
     * @param delegator The address to get delegatee for
     */
    function delegates(address delegator)
    external
    view
    returns (address)
    {
        return _delegates[delegator];
    }

    /**
     * @dev Delegate votes from `msg.sender` to `delegatee`
     * @param delegatee The address to delegate votes to
     */
    function delegate(address delegatee) external {
        return _delegate(msg.sender, delegatee);
    }

    /**
     * @dev Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(
        address delegatee,
        uint nonce,
        uint expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
    external
    {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name())),
                getChainId(),
                address(this)
            )
        );

        bytes32 structHash = keccak256(
            abi.encode(
                DELEGATION_TYPEHASH,
                delegatee,
                nonce,
                expiry
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                structHash
            )
        );

        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "BUNNY::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "BUNNY::delegateBySig: invalid nonce");
        require(now <= expiry, "BUNNY::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }

    /**
     * @dev Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account)
    external
    view
    returns (uint256)
    {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @dev Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint blockNumber)
    external
    view
    returns (uint256)
    {
        require(blockNumber < block.number, "BUNNY::getPriorVotes: not yet determined");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee)
    internal
    {
        address currentDelegate = _delegates[delegator];
        uint256 delegatorBalance = balanceOf(delegator); // balance of underlying BUNNYs (not scaled);
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                // decrease old representative
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint256 srcRepNew = srcRepOld.sub(amount);
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                // increase new representative
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint256 dstRepNew = dstRepOld.add(amount);
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    )
    internal
    {
        uint32 blockNumber = safe32(block.number, "BUNNY::_writeCheckpoint: block number exceeds 32 bits");

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
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
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
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
        BunnyStake, BunnyFlip, CakeStake, FlipToFlip, FlipToCake, Bunny, BunnyBNB, Liquidity
    }

    struct PoolInfoBSC {
        address pool;
        uint balance;
        uint principal;
        uint available;
        uint apyPool;
        uint apyBunny;
        uint tvl;
        uint pUSD;
        uint pBNB;
        uint pBUNNY;
        uint pCAKE;
        uint depositedAt;
        uint feeDuration;
        uint feePercentage;
    }

    struct PoolInfoETH {
        address pool;
        uint collateralETH;
        uint collateralBSC;
        uint bnbDebt;
        uint leverage;
        uint tvl;
        uint updatedAt;
        uint depositedAt;
        uint feeDuration;
        uint feePercentage;
    }

    struct LiquidityPoolInfo {
        address pool;
        uint balance;
        uint principal;
        uint holding;
        uint apyPool;
        uint apyBunny;
        uint apyBorrow;
        uint tvl;
        uint utilized;
        uint pBNB;
        uint pBUNNY;
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
import "../bunny/BunnyToken.sol";
import "./TokenTester.sol";

import "hardhat/console.sol";


contract BunnyChefTester is IBunnyChef, OwnableUpgradeable {
    using SafeMath for uint;
    using SafeBEP20 for IBEP20;

    /* ========== CONSTANTS ============= */

    BunnyToken public constant BUNNY = BunnyToken(0xC9849E6fdB743d08fAeE3E34dd2D1bc69EA11a51);

    /* ========== STATE VARIABLES ========== */

    address[] private _vaultList;
    mapping(address => VaultInfo) vaults;
    mapping(address => mapping(address => UserInfo)) vaultUsers;

    IBunnyMinterV2 public minter;

    uint public startBlock;
    uint public override bunnyPerBlock;
    uint public override totalAllocPoint;

    /* ========== TEST ========== */

    TokenTester public tokenTester;

    /* ========== MODIFIERS ========== */

    modifier onlyVaults {
        require(vaults[msg.sender].token != address(0), "BunnyChef: caller is not the vault");
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

    function initialize(uint _startBlock, uint _bunnyPerBlock, address _tokenTester) external initializer {
        __Ownable_init();

        startBlock = _startBlock;
        bunnyPerBlock = _bunnyPerBlock;
        tokenTester = TokenTester(_tokenTester);
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
            uint rewards = multiplier.mul(bunnyPerBlock).mul(vaultInfo.allocPoint).div(totalAllocPoint);
            accBunnyPerShare = accBunnyPerShare.add(rewards.mul(1e12).div(tokenSupply));
        }
        return userInfo.balance.mul(accBunnyPerShare).div(1e12).sub(userInfo.rewardPaid);
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

        /* ========== TEST ========== */

        if (amount > 0) {
            tokenTester.mint(amount);
            tokenTester.transfer(user, amount);
            emit BunnyRewardPaid(user, msg.sender, amount);
        }
        return amount;
    }

    function bulkUpdateRewards() public {
        for (uint idx = 0; idx < _vaultList.length; idx++) {
            if (_vaultList[idx] != address(0) && vaults[_vaultList[idx]].token != address(0)) {
                updateRewardsOf(_vaultList[idx]);
            }
        }
    }

    function updateRewardsOf(address vault) public updateRewards(vault) {
    }

    /* ========== SALVAGE PURPOSE ONLY ========== */

    function recoverToken(address _token, uint amount) virtual external onlyOwner {
        require(_token != address(BUNNY), "BunnyChef: cannot recover BUNNY token");
        IBEP20(_token).safeTransfer(owner(), amount);
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


contract TokenTester is BEP20('Token Tester', 'TEST') {
    constructor() public {

    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.8.0;

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

	function logByte(byte p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(byte)", p0));
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

import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/BEP20.sol";
import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";

import "../library/SafeDecimal.sol";

import "../cvaults/bsc/venus/IVToken.sol";
import "../cvaults/bsc/venus/IVenusDistribution.sol";
import "../interfaces/AggregatorV3Interface.sol";
import "../interfaces/IPancakePair.sol";
import "../interfaces/IDashboard.sol";
import "../cvaults/interface/IBankBNB.sol";
import "../cvaults/interface/ICPool.sol";

import "../cvaults/bsc/CVaultBSCFlipStorage.sol";

contract DashboardHelper is Ownable {
    using SafeMath for uint;
    using SafeDecimal for uint;

    uint private constant BLOCK_PER_DAY = 28800;

    IBEP20 private constant XVS = IBEP20(0xcF6BB5389c92Bdda8a3747Ddb454cB7a64626C63);
    IBEP20 private constant WBNB = IBEP20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    IBEP20 private constant CAKE = IBEP20(0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82);

    IVToken private constant vBNB = IVToken(0xA07c5b74C9B40447a954e1466938b865b6BBea36);
    IVenusDistribution private constant vComptroller = IVenusDistribution(0xfD36E2c2a6789Db23113685031d7F16329158384);
    AggregatorV3Interface private constant bnbPriceFeed = AggregatorV3Interface(0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE);

    uint private borrowDepth = 3;
    IDashboard private dashboardBSC;

    /* ========== INITIALIZER ========== */

    constructor(address _dashboardBSC, uint _borrowDepth) public {
        dashboardBSC = IDashboard(_dashboardBSC);
        borrowDepth = _borrowDepth;
    }

    /* ========== Venus APY Calculation ========== */

    function apyOfVenus() public view returns(
        uint borrowApy,
        uint supplyApy
    ) {
        borrowApy = vBNB.borrowRatePerBlock().mul(BLOCK_PER_DAY).add(1e18).power(365).sub(1e18);
        supplyApy = vBNB.supplyRatePerBlock().mul(BLOCK_PER_DAY).add(1e18).power(365).sub(1e18);
    }

    // Distribution APY
    // https://github.com/VenusProtocol/venus-protocol/issues/15#issuecomment-741292855
    function apyOfDistribution() public view returns(
        uint distributionBorrowAPY,
        uint distributionSupplyAPY
    ) {
        (uint valueInBNB,) = dashboardBSC.valueOfAsset(address(XVS), 1e18);
        uint totalSupply = vBNB.totalSupply().mul(vBNB.exchangeRateStored()).div(1e18);
        uint venusPerDay = vComptroller.venusSpeeds(address(vBNB)).mul(BLOCK_PER_DAY);

        distributionBorrowAPY = (uint(valueInBNB.mul(venusPerDay))/uint(vBNB.totalBorrows())).add(1e18).power(365).sub(1e18);
        distributionSupplyAPY = (uint(valueInBNB.mul(venusPerDay))/uint(totalSupply)).add(1e18).power(365).sub(1e18);
    }

    function calculateAPY(uint amount, uint venusBorrow, uint distributionBorrow, uint supplyAPY) public view returns(uint apyPool) {
        uint profit = 0;

        bool isNegative = venusBorrow > distributionBorrow;
        uint borrow;
        if (isNegative) {
            borrow = venusBorrow.sub(distributionBorrow);
        } else {
            borrow = distributionBorrow.sub(venusBorrow);
        }
        uint ratio = 585e15;

        uint calculatedAmount = amount.mul(supplyAPY).div(1e18);
        profit = profit.add(calculatedAmount);
        calculatedAmount = amount.mul(ratio).div(1e18);

        for (uint i = 0; i < borrowDepth; i++) {
            profit = profit.add(calculatedAmount.mul(supplyAPY).div(1e18));
            if (isNegative) {
                profit = profit.sub(calculatedAmount.mul(borrow).div(1e18));
            } else {
                profit = profit.add(calculatedAmount.mul(borrow).div(1e18));
            }
            calculatedAmount = calculatedAmount.mul(ratio).div(1e18);
        }

        apyPool = profit.mul(1e18).div(amount);
    }

    /* ========== Predict function ========== */

    function predict(address lp, address flip, address _account, uint collateralETH, uint collateralBSC, uint leverage, uint debtBNB) public view returns(
        uint newCollateralBSC,
        uint newDebtBNB
    ) {
        IBankBNB bankBNB = IBankBNB(dashboardBSC.bankBNBAddress());

        uint currentDebt = bankBNB.debtValOf(lp, _account);
        uint targetDebt = _calculateTargetDebt(lp, uint128(leverage), collateralETH);
        if (currentDebt <= targetDebt) {
            (uint bscFlip, uint debt) = _addLiquidity(flip, targetDebt.sub(currentDebt));
            newCollateralBSC = collateralBSC.add(bscFlip);
            newDebtBNB = debtBNB.add(debt);
        } else {
            uint flipAmount = convertToFlipAmount(address(WBNB), flip, currentDebt.sub(targetDebt));
            (newCollateralBSC, newDebtBNB) = _removeLiquidity(lp, _account, flipAmount, collateralBSC, debtBNB);
        }
    }

    function withdrawAmountToBscTokens(address lp, address _account, uint leverage, uint amount) public view returns(uint bnbAmount, uint pairAmount, uint bnbOfPair) {
        IBankBNB bankBNB = IBankBNB(dashboardBSC.bankBNBAddress());
        CVaultBSCFlipStorage flip = CVaultBSCFlipStorage(dashboardBSC.bscFlipAddress());
        address flipAddr = flip.flipOf(lp);

        uint currentDebt = bankBNB.debtValOf(lp, _account);
        uint targetDebt = _calculateTargetDebt(lp, uint128(leverage), amount);
        if (currentDebt > targetDebt) {
            uint flipAmount = convertToFlipAmount(address(WBNB), flipAddr, currentDebt.sub(targetDebt));
            (bnbAmount, pairAmount, bnbOfPair) = _withdrawAmountToBscTokens(lp, _account, flipAmount);
        }
    }

    function collateralRatio(address lp, uint lpAmount, address flip, uint flipAmount, uint debt) public view returns(uint) {
        ICVaultRelayer relayer = ICVaultRelayer(dashboardBSC.relayerAddress());
        return relayer.collateralRatioOnETH(lp, lpAmount, flip, flipAmount, debt);
    }

    /* ========== Convert amount ========== */

    // only BNB Pairs TODO all pairs
    function convertToBNBAmount(address flip, uint amount) public view returns(uint) {
        if (keccak256(abi.encodePacked(IPancakePair(flip).symbol())) == keccak256("Cake-LP")) {
            IPancakePair pair = IPancakePair(flip);
            (uint reserve0, uint reserve1,) = pair.getReserves();
            if (pair.token0() == address(WBNB)) {
                return amount.mul(reserve1).div(reserve0);
            } else {
                return amount.mul(reserve0).div(reserve1);
            }
        } else {
            return amount;
        }
    }

    function convertToFlipAmount(address tokenIn, address flip, uint amount) public view returns(uint) {
        if (keccak256(abi.encodePacked(IPancakePair(flip).symbol())) == keccak256("Cake-LP")) {
            IPancakePair pair = IPancakePair(flip);
            if (tokenIn == address(WBNB) || tokenIn == address(0)) {
                return amount.div(2).mul(pair.totalSupply()).div(WBNB.balanceOf(flip));
            } else {
                // TODO
                return 0;
            }
        } else {
            return amount;
        }
    }

    /* ========== Calculation ========== */

    function _calculateTargetDebt(address lp, uint128 leverage, uint collateral) private view returns(uint) {
        ICVaultRelayer relayer = ICVaultRelayer(dashboardBSC.relayerAddress());

        uint value = relayer.valueOfAsset(lp, collateral);
        return value.mul(leverage).div(dashboardBSC.priceOfBNB());
    }

    function _addLiquidity(address flip, uint debtDiff) private view returns(uint bscFlip, uint debtBNB) {
        IBankBNB bankBNB = IBankBNB(dashboardBSC.bankBNBAddress());
        (uint totalSupply, uint utilized) = bankBNB.getUtilizationInfo();
        uint amount = Math.min(debtDiff, totalSupply.sub(utilized));
        if (amount > 0) {
            bscFlip = convertToFlipAmount(address(WBNB), flip, amount);
            debtBNB = amount;
        }
    }

    function _removeLiquidity(address lp, address _account, uint amount, uint collateralBSC, uint debtBNB) private view returns(uint newCollateralBSC, uint newDebtBNB) {
        if (amount < collateralBSC) {
            newCollateralBSC = collateralBSC.sub(amount);
        } else {
            newCollateralBSC = 0;
        }

        (uint bnbAmount, , uint bnbOfPair) = _withdrawAmountToBscTokens(lp, _account, amount);
        // _repay
        uint repayDebtBNB = _repay(lp, _account, bnbAmount.add(bnbOfPair));

        if (repayDebtBNB < debtBNB) {
            newDebtBNB = debtBNB.sub(repayDebtBNB);
        } else {
            newDebtBNB = 0;
        }
    }

    function _repay(address lp, address _account, uint amount) private view returns(uint) {
        IBankBNB bankBNB = IBankBNB(dashboardBSC.bankBNBAddress());
        uint debtShare = Math.min(bankBNB.debtValToShare(amount), bankBNB.debtShareOf(lp, _account));
        if (debtShare > 0) {
            return debtShare;
        } else {
            return 0;
        }
    }

    function _withdrawAmountToBscTokens(address lp, address account, uint amount) private view returns(uint bnbAmount, uint pairAmount, uint bnbOfPair) {
        CVaultBSCFlipStorage flip = CVaultBSCFlipStorage(dashboardBSC.bscFlipAddress());
        address flipAddr = flip.flipOf(lp);

        if (keccak256(abi.encodePacked(IPancakePair(flipAddr).symbol())) == keccak256("Cake-LP")) {
            (uint _bnbBalance,) = dashboardBSC.valueOfAsset(flipAddr, amount);
            bnbAmount = _bnbBalance.div(2);

            bnbOfPair = bnbAmount;
            pairAmount = convertToBNBAmount(flipAddr, bnbAmount);

            ICPool cPool = ICPool(flip.cpoolOf(lp));
            uint rewardBalance = cPool.rewards(account);    // reward
            (uint _bnbOfReward,) = dashboardBSC.valueOfAsset(address(CAKE), rewardBalance);
            bnbAmount = bnbAmount.add(_bnbOfReward);
        } else {
            (bnbAmount, ) = dashboardBSC.valueOfAsset(lp, amount);
            pairAmount = 0;
            bnbOfPair = bnbAmount;
        }
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

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVToken is IERC20 {
    function underlying() external returns (address);

    function mint(uint256 mintAmount) external returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function borrow(uint256 borrowAmount) external returns (uint256);

    function repayBorrow(uint256 repayAmount) external returns (uint256);

    function balanceOfUnderlying(address owner) external returns (uint256);

    function borrowBalanceCurrent(address account) external returns (uint256);

    function decimals() external view returns(uint8);   // always 8
    function totalBorrows() external view returns(uint);
    function exchangeRateStored() external view returns (uint);

    function supplyRatePerBlock() external view returns(uint);
    function borrowRatePerBlock() external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IVenusDistribution {
    function claimVenus(address holder) external;

    function enterMarkets(address[] memory _vtokens) external;

    function exitMarket(address _vtoken) external;

    function getAssetsIn(address account)
    external
    view
    returns (address[] memory);

    function getAccountLiquidity(address account)
    external
    view
    returns (
        uint256,
        uint256,
        uint256
    );

    function venusSpeeds(address) external view returns (uint);
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

interface IDashboard {
    function bankBNBAddress() external view returns(address);
    function bscFlipAddress() external view returns(address);
    function relayerAddress() external view returns(address);
    function priceOfBNB() external view returns (uint);

    function valueOfAsset(address asset, uint amount) external view returns(uint, uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IBankBNB {
    function priceInBNB() external view returns (uint);

    function debtValOf(address pool, address user) external view returns(uint);
    function debtShareOf(address pool, address user) external view returns(uint);
    function debtShareToVal(uint debtShare) external view returns (uint debtVal);
    function debtValToShare(uint debtVal) external view returns (uint);
    function getUtilizationInfo() external view returns(uint liquidity, uint utilized);

    function accruedDebtValOf(address pool, address user) external returns(uint);
    function borrow(address pool, address borrower, uint debtVal) external returns(uint debt);
    function repay(address pool, address borrower) external payable returns(uint debtShares);

    function handOverDebtToTreasury(address pool, address borrower) external returns(uint debtShares);
    function repayTreasuryDebt() external payable returns(uint debtShares);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface ICPool {
    function deposit(address to, uint amount) external;
    function withdraw(address to, uint amount) external;
    function withdrawAll(address to) external;
    function getReward(address to) external;

    function rewards(address account) external view returns(uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../../library/PausableUpgradeable.sol";
import "./CVaultBSCFlipState.sol";
import "../interface/ICVaultRelayer.sol";

contract CVaultBSCFlipStorage is CVaultBSCFlipState, PausableUpgradeable {
    mapping (address => Pool) private _pools;

    uint public constant LEVERAGE_MAX = 15e17;  // 150%
    uint public constant LEVERAGE_MIN = 1e17;  // 10%
    ICVaultRelayer public relayer;

    modifier increaseNonceOnlyRelayer(address lp, address _account, uint nonce) {
        require(msg.sender == address(relayer), "CVaultBSCFlipStorage: not relayer");
        require(_pools[lp].cpool != address(0), "CVaultBSCFlipStorage: not pool");
        require(accountOf(lp, _account).nonce == nonce, "CVaultBSCFlipStorage: invalid nonce");
        _;
        increaseNonce(lp, _account);
    }

    modifier validLeverage(uint128 leverage) {
        require(LEVERAGE_MIN <= leverage && leverage <= LEVERAGE_MAX, "CVaultBSCFlipStorage: leverage range should be [10%-150%]");
        _;
    }

    // ---------- INITIALIZER ----------

    function __CVaultBSCFlipStorage_init() internal initializer {
        __PausableUpgradeable_init();
    }

    // ---------- VIEW ----------

    function cpoolOf(address lp) public view returns(address) {
        return _pools[lp].cpool;
    }

    function flipOf(address lp) public view returns(address) {
        return _pools[lp].flip;
    }

    function stateOf(address lp, address account) public view returns(State) {
        return _pools[lp].accounts[account].state;
    }

    function accountOf(address lp, address account) public view returns(Account memory) {
        return _pools[lp].accounts[account];
    }

    // ---------- RESTRICTED ----------

    function setCVaultRelayer(address newRelayer) external onlyOwner {
        relayer = ICVaultRelayer(newRelayer);
    }

    function _setPool(address lp, address flip, address cpool) internal onlyOwner {
        require(_pools[lp].cpool == address(0) && _pools[lp].flip == address(0), "CVaultBSCFlipStorage: set already");
        _pools[lp].flip = flip;
        _pools[lp].cpool = cpool;
    }

    function increaseNonce(address lp, address _account) private {
        _pools[lp].accounts[_account].nonce++;
    }

    function convertState(address lp, address _account, State state) internal {
        Account storage account = _pools[lp].accounts[_account];
        State current = account.state;
        if (current == state) {
            return;
        }

        if (state == State.Idle) {
            require(current == State.Farming, "CVaultBSCFlipStorage: can't convert to Idle");
        } else if (state == State.Farming) {

        } else {
            revert("CVaultBSCFlipStorage: invalid state");
        }

        account.state = state;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
pragma experimental ABIEncoderV2;

interface CVaultBSCFlipState {
    enum State {
        Idle, Farming
    }

    struct Account {
        uint nonce;
        State state;
    }

    struct Pool {
        address flip;
        address cpool;

        mapping (address => Account) accounts;
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


interface ICVaultRelayer {

    struct RelayRequest {
        address lp;
        address account;
        uint8 signature;
        uint8 validation;
        uint112 nonce;
        uint128 requestId;
        uint128 leverage;
        uint collateral;
        uint lpValue;
    }

    struct RelayResponse {
        address lp;
        address account;
        uint8 signature;
        uint8 validation;
        uint112 nonce;
        uint128 requestId;
        uint bscBNBDebtShare;
        uint bscFlipBalance;
        uint ethProfit;
        uint ethLoss;
    }

    struct RelayLiquidation {
        address lp;
        address account;
        address liquidator;
    }

    struct RelayUtilization {
        uint liquidity;
        uint utilized;
    }

    struct RelayHistory {
        uint128 requestId;
        RelayRequest request;
        RelayResponse response;
    }

    struct RelayOracleData {
        address token;
        uint price;
    }

    function requestRelayOnETH(address lp, address account, uint8 signature, uint128 leverage, uint collateral, uint lpAmount) external returns(uint requestId);

    function askLiquidationFromHandler(RelayLiquidation[] memory _candidate) external;
    function askLiquidationFromCVaultETH(address lp, address account, address liquidator) external;
    function executeLiquidationOnETH() external;

    function valueOfAsset(address token, uint amount) external view returns(uint);
    function priceOf(address token) external view returns(uint);
    function collateralRatioOnETH(address lp, uint lpAmount, address flip, uint flipAmount, uint debt) external view returns(uint);
    function utilizationInfo() external view returns (uint total, uint utilized);
    function isUtilizable(address lp, uint amount, uint leverage) external view returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./CVaultETHLPState.sol";
import "../../library/PausableUpgradeable.sol";
import "../interface/ICVaultRelayer.sol";


contract CVaultETHLPStorage is CVaultETHLPState, PausableUpgradeable {
    using SafeMath for uint;

    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    uint public constant EMERGENCY_EXIT_TIMELOCK = 72 hours;
    uint public constant COLLATERAL_RATIO_MIN = 18e17;  // 180%

    uint128 public constant LEVERAGE_MAX = 15e17;       // 150%
    uint128 public constant LEVERAGE_MIN = 1e17;        // 10%

    uint public constant LIQUIDATION_PENALTY = 5e16;    // 5%
    uint public constant LIQUIDATION_FEE = 30e16;       // 30%  *** 30% of 5% penalty goes to treasury
    uint public constant UNIT = 1e18;                   // 100%

    uint public constant WITHDRAWAL_FEE_PERIOD = 3 days;
    uint public constant WITHDRAWAL_FEE = 5e15;         // 0.5%

    ICVaultRelayer public relayer;
    mapping(address => Pool) private _pools;
    mapping(address => uint) private _unpaidETH;

    uint public totalUnpaidETH;

    uint[50] private _gap;

    modifier increaseNonceOnlyRelayers(address lp, address _account, uint112 nonce) {
        require(msg.sender == address(relayer), "CVaultETHLPStorage: not a relayer");
        require(accountOf(lp, _account).nonce == nonce, "CVaultETHLPStorage: invalid nonce");
        _;
        increaseNonce(lp, _account);
    }

    modifier onlyStateFarming(address lp) {
        require(stateOf(lp, msg.sender) == State.Farming, "CVaultETHLPStorage: not farming state");
        _;
    }

    modifier validLeverage(uint128 leverage) {
        require(LEVERAGE_MIN <= leverage && leverage <= LEVERAGE_MAX, "CVaultETHLPStorage: leverage range should be [10%-150%]");
        _;
    }

    modifier notPausedPool(address lp) {
        require(_pools[lp].paused == false, "CVaultETHLPStorage: paused pool");
        _;
    }

    receive() external payable {}

    // ---------- INITIALIZER ----------

    function __CVaultETHLPStorage_init() internal initializer {
        __PausableUpgradeable_init();
    }

    // ---------- RESTRICTED ----------

    function _setPool(address lp, address bscFlip) internal onlyOwner {
        require(_pools[lp].bscFlip == address(0), "CVaultETHLPStorage: setPool already");
        _pools[lp].bscFlip = bscFlip;
    }

    function pausePool(address lp, bool paused) external onlyOwner {
        _pools[lp].paused = paused;
    }

    function setCVaultRelayer(address newRelayer) external onlyOwner {
        relayer = ICVaultRelayer(newRelayer);
    }

    // ---------- VIEW ----------

    function bscFlipOf(address lp) public view returns (address) {
        return _pools[lp].bscFlip;
    }

    function totalCollateralOf(address lp) public view returns (uint) {
        return _pools[lp].totalCollateral;
    }

    function stateOf(address lp, address account) public view returns (State) {
        return _pools[lp].accounts[account].state;
    }

    function accountOf(address lp, address account) public view returns (Account memory) {
        return _pools[lp].accounts[account];
    }

    function unpaidETH(address account) public view returns (uint) {
        return _unpaidETH[account];
    }

    function withdrawalFee(address lp, address account, uint amount) public view returns (uint) {
        if (_pools[lp].accounts[account].depositedAt + WITHDRAWAL_FEE_PERIOD < block.timestamp) {
            return 0;
        }

        return amount.mul(WITHDRAWAL_FEE).div(UNIT);
    }

    // ---------- SET ----------
    function increaseUnpaidETHValue(address _account, uint value) internal {
        _unpaidETH[_account] = _unpaidETH[_account].add(value);
        totalUnpaidETH = totalUnpaidETH.add(value);
    }

    function decreaseUnpaidETHValue(address _account, uint value) internal {
        _unpaidETH[_account] = _unpaidETH[_account].sub(value);
        totalUnpaidETH = totalUnpaidETH.sub(value);
    }

    function increaseCollateral(address lp, address _account, uint amount) internal returns (uint collateral) {
        Account storage account = _pools[lp].accounts[_account];
        collateral = account.collateral.add(amount);
        account.collateral = collateral;

        _pools[lp].totalCollateral = _pools[lp].totalCollateral.add(amount);
    }

    function decreaseCollateral(address lp, address _account, uint amount) internal returns (uint collateral) {
        Account storage account = _pools[lp].accounts[_account];
        collateral = account.collateral.sub(amount);
        account.collateral = collateral;

        _pools[lp].totalCollateral = _pools[lp].totalCollateral.sub(amount);
    }

    function setLeverage(address lp, address _account, uint128 leverage) internal {
        _pools[lp].accounts[_account].leverage = leverage;
    }

    function setWithdrawalRequestAmount(address lp, address _account, uint amount) internal {
        _pools[lp].accounts[_account].withdrawalRequestAmount = amount;
    }

    function setBSCBNBDebt(address lp, address _account, uint bscBNBDebt) internal {
        _pools[lp].accounts[_account].bscBNBDebt = bscBNBDebt;
    }

    function setBSCFlipBalance(address lp, address _account, uint bscFlipBalance) internal {
        _pools[lp].accounts[_account].bscFlipBalance = bscFlipBalance;
    }

    function increaseNonce(address lp, address _account) private {
        _pools[lp].accounts[_account].nonce++;
    }

    function setUpdatedAt(address lp, address _account) private {
        _pools[lp].accounts[_account].updatedAt = uint64(block.timestamp);
    }

    function setDepositedAt(address lp, address _account) private {
        _pools[lp].accounts[_account].depositedAt = uint64(block.timestamp);
    }

    function setLiquidator(address lp, address _account, address liquidator) internal {
        _pools[lp].accounts[_account].liquidator = liquidator;
    }

    function setState(address lp, address _account, State state) private {
        _pools[lp].accounts[_account].state = state;
    }

    function resetAccountExceptNonceAndState(address lp, address _account) private {
        Account memory account = _pools[lp].accounts[_account];
        _pools[lp].accounts[_account] = Account(0, 0, 0, 0, account.nonce, 0, 0, address(0), account.state, 0);
    }

    function convertState(address lp, address _account, State state) internal {
        Account memory account = _pools[lp].accounts[_account];
        State currentState = account.state;
        if (state == State.Idle) {
            require(msg.sender == address(relayer), "CVaultETHLPStorage: only relayer can resolve emergency state");
            require(currentState == State.Withdrawing || currentState == State.Liquidating || currentState == State.EmergencyExited,
                "CVaultETHLPStorage: can't convert to Idle"
            );
            resetAccountExceptNonceAndState(lp, _account);
        } else if (state == State.Depositing) {
            require(currentState == State.Idle || currentState == State.Farming,
                "CVaultETHLPStorage: can't convert to Depositing");
            setDepositedAt(lp, _account);
        } else if (state == State.Farming) {
            require(currentState == State.Depositing || currentState == State.UpdatingLeverage,
                "CVaultETHLPStorage: can't convert to Farming");
        } else if (state == State.Withdrawing) {
            require(currentState == State.Farming,
                "CVaultETHLPStorage: can't convert to Withdrawing");
        } else if (state == State.UpdatingLeverage) {
            require(currentState == State.Farming,
                "CVaultETHLPStorage: can't convert to UpdatingLeverage");
        } else if (state == State.Liquidating) {
            require(currentState == State.Farming,
                "CVaultETHLPStorage: can't convert to Liquidating"
            );
        } else if (state == State.EmergencyExited) {
            require(_account == msg.sender, "CVaultETHLPStorage: msg.sender is not the owner of account");
            require(currentState == State.Depositing || currentState == State.Withdrawing || currentState == State.UpdatingLeverage, "CVaultETHLPStorage: unavailable state to emergency exit");
            require(account.updatedAt + EMERGENCY_EXIT_TIMELOCK < block.timestamp, "CVaultETHLPStorage: timelocked");
        } else {
            revert("Invalid state");
        }

        setState(lp, _account, state);
        setUpdatedAt(lp, _account);
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
        return sub(a, b, "SafeMath: subtraction overflow");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
        return mod(a, b, "SafeMath: modulo by zero");
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface CVaultETHLPState {
    enum State {
        Idle, Depositing, Farming, Withdrawing, UpdatingLeverage, Liquidating, EmergencyExited
    }

    struct Account {
        uint collateral;
        uint bscBNBDebt;         // BSC - Borrowing BNB shares
        uint bscFlipBalance;     // BSC - Farming FLIP amount
        uint128 leverage;
        uint112 nonce;
        uint64 updatedAt;
        uint64 depositedAt;
        address liquidator;
        State state;
        uint withdrawalRequestAmount;
    }

    struct Pool {
        address bscFlip;
        bool paused;
        uint totalCollateral;

        mapping (address => Account) accounts;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../library/PausableUpgradeable.sol";


contract UpgradeTesterSource is PausableUpgradeable {

    // 1. deploy proxy with hardhat
    // 2. proxyAdmin to Timelock
    // 3. prepareUpgrade with hardhat
    // 4. queueTransaction to upgradeProxy with Timelock
    // 5. advance evm time
    // 6. executeTransaction to upgradePoxy with Timelock
    // 7. check value updated

    /* ========== STATE VARIABLES ========== */

    uint public version;

    /* ========== INITIALIZER ========== */

    function initialize() external initializer {
        __PausableUpgradeable_init();
        version = 1;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setVersion(uint _version) external onlyOwner {
        version = _version;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../library/PausableUpgradeable.sol";


contract UpgradeTesterReject is PausableUpgradeable {

    // 1. deploy proxy with hardhat
    // 2. proxyAdmin to Timelock
    // 3. prepareUpgrade with hardhat
    // 4. queueTransaction to upgradeProxy with Timelock
    // 5. advance evm time
    // 6. executeTransaction to upgradePoxy with Timelock
    // 7. check value updated

    /* ========== STATE VARIABLES ========== */

    bool public reject;
    uint public version;

    /* ========== INITIALIZER ========== */

    function initialize() external initializer {
        __PausableUpgradeable_init();
        reject = true;
        version = 3;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setVersion(uint _version) external onlyOwner {
        version = _version;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../library/PausableUpgradeable.sol";


contract UpgradeTesterAccept is PausableUpgradeable {

    // 1. deploy proxy with hardhat
    // 2. proxyAdmin to Timelock
    // 3. prepareUpgrade with hardhat
    // 4. queueTransaction to upgradeProxy with Timelock
    // 5. advance evm time
    // 6. executeTransaction to upgradePoxy with Timelock
    // 7. check value updated

    /* ========== STATE VARIABLES ========== */

    uint public version;
    bool public accept;

    /* ========== INITIALIZER ========== */

    function initialize() external initializer {
        __PausableUpgradeable_init();
        version = 2;
        accept = true;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setVersion(uint _version) external onlyOwner {
        version = _version;
    }

    function setAccept(bool _accept) external onlyOwner {
        accept = _accept;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol";
import "@openzeppelin/contracts/math/Math.sol";

import "../../library/PausableUpgradeable.sol";

import "../../interfaces/IPancakePair.sol";
import "../../interfaces/IStrategy.sol";
import "../interface/ICVaultBSCFlip.sol";
import "../interface/IBankBNB.sol";
import "../interface/IBankETH.sol";
import "../interface/ICPool.sol";
import "../../zap/IZap.sol";

import "./CVaultBSCFlipState.sol";
import "./CVaultBSCFlipStorage.sol";


contract CVaultBSCFlip is ICVaultBSCFlip, CVaultBSCFlipStorage {
    using SafeMath for uint;
    using SafeBEP20 for IBEP20;

    /* ========== CONSTANTS ============= */

    address private constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address private constant CAKE = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;

    /* ========== STATE VARIABLES ========== */

    IBankBNB private _bankBNB;
    IBankETH private _bankETH;
    IZap private _zap;

    /* ========== EVENTS ========== */

    event Deposited(address indexed lp, address indexed account, uint128 indexed eventId, uint debtShare, uint flipBalance);
    event UpdateLeverage(address indexed lp, address indexed account, uint128 indexed eventId, uint debtShare, uint flipBalance);
    event WithdrawAll(address indexed lp, address indexed account, uint128 indexed eventId, uint profit, uint loss);
    event EmergencyExit(address indexed lp, address indexed account, uint128 indexed eventId, uint profit, uint loss);
    event Liquidate(address indexed lp, address indexed account, uint128 indexed eventId, uint profit, uint loss);

    /* ========== INITIALIZER ========== */

    receive() external payable {}

    function initialize() external initializer {
        __CVaultBSCFlipStorage_init();
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setPool(address lp, address flip, address cpool) external onlyOwner {
        require(address(_zap) != address(0), "CVaultBSCFlip: zap is not set");
        _setPool(lp, flip, cpool);

        if (IBEP20(flip).allowance(address(this), address(_zap)) == 0) {
            IBEP20(flip).safeApprove(address(_zap), uint(-1));
        }

        if (IBEP20(flip).allowance(address(this), cpool) == 0) {
            IBEP20(flip).safeApprove(cpool, uint(-1));
        }
    }

    function setBankBNB(address newBankBNB) public onlyOwner {
        require(address(_bankBNB) == address(0), "CVaultBSCFlip: setBankBNB only once");
        _bankBNB = IBankBNB(newBankBNB);
    }

    function setBankETH(address newBankETH) external onlyOwner {
        _bankETH = IBankETH(newBankETH);
    }

    function setZap(address newZap) external onlyOwner {
        _zap = IZap(newZap);
    }

    function recoverToken(address token, uint amount) external onlyOwner {
        IBEP20(token).safeTransfer(owner(), amount);
    }

    /* ========== VIEW FUNCTIONS ========== */

    function zap() public view returns(IZap) {
        return _zap;
    }

    function bankBNB() public override view returns(IBankBNB) {
        return _bankBNB;
    }

    function bankETH() public override view returns(IBankETH) {
        return _bankETH;
    }

    function getUtilizationInfo() public override view returns (uint liquidity, uint utilized) {
        return bankBNB().getUtilizationInfo();
    }

    /* ========== RELAYER FUNCTIONS ========== */

    function deposit(address lp, address _account, uint128 eventId, uint112 nonce, uint128 leverage, uint collateral) external override increaseNonceOnlyRelayer(lp, _account, nonce) validLeverage(leverage) returns (uint bscBNBDebtShare, uint bscFlipBalance) {
        convertState(lp, _account, State.Farming);
        _updateLiquidity(lp, _account, leverage, collateral);
        bscBNBDebtShare = bankBNB().debtShareOf(lp, _account);
        bscFlipBalance = IStrategy(cpoolOf(lp)).balanceOf(_account);
        emit Deposited(lp, _account, eventId, bscBNBDebtShare, bscFlipBalance);
    }

    function updateLeverage(address lp, address _account, uint128 eventId, uint112 nonce, uint128 leverage, uint collateral) external override increaseNonceOnlyRelayer(lp, _account, nonce) validLeverage(leverage) returns (uint bscBNBDebtShare, uint bscFlipBalance) {
        require(accountOf(lp, _account).state == State.Farming, "CVaultBSCFlip: state is not Farming");

        _updateLiquidity(lp, _account, leverage, collateral);
        bscBNBDebtShare = bankBNB().debtShareOf(lp, _account);
        bscFlipBalance = IStrategy(cpoolOf(lp)).balanceOf(_account);
        emit UpdateLeverage(lp, _account, eventId, bscBNBDebtShare, bscFlipBalance);
    }

    function withdrawAll(address lp, address _account, uint128 eventId, uint112 nonce) external override increaseNonceOnlyRelayer(lp, _account, nonce) returns(uint ethProfit, uint ethLoss) {
        convertState(lp, _account, State.Idle);

        _removeLiquidity(lp, _account, IStrategy(cpoolOf(lp)).balanceOf(_account));
        (ethProfit, ethLoss) = _handleProfitAndLoss(lp, _account);

        emit WithdrawAll(lp, _account, eventId, ethProfit, ethLoss);
    }

    function emergencyExit(address lp, address _account, uint128 eventId, uint112 nonce) external override increaseNonceOnlyRelayer(lp, _account, nonce) returns (uint ethProfit, uint ethLoss) {
        convertState(lp, _account, State.Idle);

        uint flipBalance = IStrategy(cpoolOf(lp)).balanceOf(_account);
        _removeLiquidity(lp, _account, flipBalance);
        (ethProfit, ethLoss) = _handleProfitAndLoss(lp, _account);

        emit EmergencyExit(lp, _account, eventId, ethProfit, ethLoss);
    }

    function liquidate(address lp, address _account, uint128 eventId, uint112 nonce) external override increaseNonceOnlyRelayer(lp, _account, nonce) returns (uint ethProfit, uint ethLoss) {
        convertState(lp, _account, State.Idle);

        _removeLiquidity(lp, _account, IStrategy(cpoolOf(lp)).balanceOf(_account));
        (ethProfit, ethLoss) = _handleProfitAndLoss(lp, _account);
        emit Liquidate(lp, _account, eventId, ethProfit, ethLoss);
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _updateLiquidity(address lp, address _account, uint128 leverage, uint collateral) private {
        uint targetDebtInBNB = _calculateTargetDebt(lp, collateral, leverage);
        uint currentDebtValue = bankBNB().accruedDebtValOf(lp, _account);

        if (currentDebtValue <= targetDebtInBNB) {
            uint borrowed = _borrow(lp, _account, targetDebtInBNB.sub(currentDebtValue));
            if (borrowed > 0) {
                _addLiquidity(lp, _account, borrowed);
            }
        } else {
            _removeLiquidity(lp, _account, _calculateFlipAmountWithBNB(flipOf(lp), currentDebtValue.sub(targetDebtInBNB)));
            _repay(lp, _account, address(this).balance);
        }
    }

    function _addLiquidity(address lp, address _account, uint value) private {
        address flip = flipOf(lp);
        _zap.zapIn{ value: value }(flip);
        ICPool(cpoolOf(lp)).deposit(_account, IBEP20(flip).balanceOf(address(this)));
    }

    function _removeLiquidity(address lp, address _account, uint amount) private {
        if (amount == 0) return;

        ICPool cpool = ICPool(cpoolOf(lp));
        cpool.withdraw(_account, amount);
        cpool.getReward(_account);

        _zapOut(flipOf(lp), amount);
        uint cakeBalance = IBEP20(CAKE).balanceOf(address(this));
        if (cakeBalance > 0) {
            _zapOut(CAKE, cakeBalance);
        }

        IPancakePair pair = IPancakePair(flipOf(lp));
        address token0 = pair.token0();
        address token1 = pair.token1();
        if (token0 != WBNB) {
            _zapOut(token0, IBEP20(token0).balanceOf(address(this)));
        }
        if (token1 != WBNB) {
            _zapOut(token1, IBEP20(token1).balanceOf(address(this)));
        }
    }

    function _handleProfitAndLoss(address lp, address _account) private returns(uint profit, uint loss) {
        profit = 0;
        loss = 0;

        uint balance = address(this).balance;
        uint debt = bankBNB().accruedDebtValOf(lp, _account);
        if (balance >= debt) {
            _repay(lp, _account, debt);
            if (balance > debt) {
                profit = bankETH().transferProfit{ value: balance - debt }();
            }
        } else {
            _repay(lp, _account, balance);
            loss = bankETH().repayOrHandOverDebt(lp, _account, debt - balance);
        }
    }

    function _calculateTargetDebt(address pool, uint collateral, uint128 leverage) private view returns(uint targetDebtInBNB) {
        uint value = relayer.valueOfAsset(pool, collateral);
        uint bnbPrice = relayer.priceOf(WBNB);
        targetDebtInBNB = value.mul(leverage).div(bnbPrice);
    }

    function _calculateFlipAmountWithBNB(address flip, uint bnbAmount) private view returns(uint) {
        return relayer.valueOfAsset(WBNB, bnbAmount).mul(1e18).div(relayer.priceOf(flip));
    }

    function _borrow(address poolAddress, address _account, uint amount) private returns (uint debt) {
        (uint liquidity, uint utilized) = getUtilizationInfo();
        amount = Math.min(amount, liquidity.sub(utilized));
        if (amount == 0) return 0;

        return bankBNB().borrow(poolAddress, _account, amount);
    }

    function _repay(address poolAddress, address _account, uint amount) private returns (uint debt) {
        return bankBNB().repay{ value: amount }(poolAddress, _account);
    }

    function _zapOut(address token, uint amount) private {
        if (IBEP20(token).allowance(address(this), address(_zap)) == 0) {
            IBEP20(token).safeApprove(address(_zap), uint(-1));
        }
        _zap.zapOut(token, amount);
    }

    /* ========== DASHBOARD VIEW FUNCTIONS ========== */

    function withdrawAmount(address lp, address account, uint ratio) public override view returns(uint lpBalance, uint cakeBalance) {
        IStrategy cpool = IStrategy(cpoolOf(lp));
        lpBalance = cpool.balanceOf(account).mul(ratio).div(1e18);
        cakeBalance = cpool.earned(account);    // reward: CAKE
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

import "./IBankBNB.sol";
import "./IBankETH.sol";


interface ICVaultBSCFlip {
    function getUtilizationInfo() external view returns(uint liquidity, uint utilized);
    function bankBNB() external view returns(IBankBNB);
    function bankETH() external view returns(IBankETH);
    function withdrawAmount(address lp, address account, uint ratio) external view returns(uint lpBalance, uint cakeBalance);

    function deposit(address lp, address account, uint128 eventId, uint112 nonce, uint128 leverage, uint collateral) external returns (uint bscBNBDebtShare, uint bscFlipBalance);
    function updateLeverage(address lp, address account, uint128 eventId, uint112 nonce, uint128 leverage, uint collateral) external returns (uint bscBNBDebtShare, uint bscFlipBalance);
    function withdrawAll(address lp, address account, uint128 eventId, uint112 nonce) external returns (uint ethProfit, uint ethLoss);
    function emergencyExit(address lp, address account, uint128 eventId, uint112 nonce) external returns (uint ethProfit, uint ethLoss);
    function liquidate(address lp, address account, uint128 eventId, uint112 nonce) external returns (uint ethProfit, uint ethLoss);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IBankETH {
    function transferProfit() external payable returns(uint ethAmount);
    function repayOrHandOverDebt(address lp, address account, uint debt) external returns(uint ethAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IZap {
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

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../../interfaces/IUniswapV2Pair.sol";
import "../interface/ICVaultETHLP.sol";
import "../interface/ICVaultRelayer.sol";
import "../../zap/IZap.sol";
import "../../library/Whitelist.sol";
import "./CVaultETHLPState.sol";
import "./CVaultETHLPStorage.sol";


contract CVaultETHLP is ICVaultETHLP, CVaultETHLPStorage, Whitelist {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    uint8 private constant SIG_DEPOSIT = 10;
    uint8 private constant SIG_LEVERAGE = 20;
    uint8 private constant SIG_WITHDRAW = 30;
    uint8 private constant SIG_LIQUIDATE = 40;
    uint8 private constant SIG_EMERGENCY = 50;
    uint8 private constant SIG_CLEAR = 63;          // only owner can execute if state is idle but the BSC position remains.

    /* ========== STATE VARIABLES ========== */

    IZap public zap;
    address public treasury;

    uint public relayerCost;
    uint public minimumDepositValue;
    uint public liquidationCollateralRatio;

    /* ========== EVENTS ========== */

    // Relay Request Events
    event DepositRequested(address indexed lp, address indexed account, uint indexed eventId, uint lpAmount, uint leverage);
    event UpdateLeverageRequested(address indexed lp, address indexed account, uint indexed eventId, uint leverage, uint collateral);
    event WithdrawRequested(address indexed lp, address indexed account, uint indexed eventId, uint lpAmount);
    event WithdrawAllRequested(address indexed lp, address indexed account, uint indexed eventId);
    event LiquidateRequested(address indexed lp, address indexed account, uint indexed eventId, uint lpAmount, address liquidator);
    event EmergencyExitRequested(address indexed lp, address indexed account, uint indexed eventId, uint lpAmount);

    // Impossible Situation: only owner can execute if state is idle but the BSC position remains.
    event ClearBSCState(address indexed lp, address indexed account, uint indexed eventId);

    // Relay Response Events
    event NotifyDeposited(address indexed lp, address indexed account, uint indexed eventId, uint bscBNBDebtShare, uint bscFlipBalance);
    event NotifyUpdatedLeverage(address indexed lp, address indexed account, uint indexed eventId, uint bscBNBDebtShare, uint bscFlipBalance);
    event NotifyWithdrawnAll(address indexed lp, address indexed account, uint indexed eventId, uint lpAmount, uint ethProfit, uint ethLoss);
    event NotifyLiquidated(address indexed lp, address indexed account, uint indexed eventId, uint ethProfit, uint ethLoss, uint penaltyLPAmount, address liquidator);
    event NotifyResolvedEmergency(address indexed lp, address indexed account, uint indexed eventId);

    // User Events
    event CollateralAdded(address indexed lp, address indexed account, uint lpAmount);
    event CollateralRemoved(address indexed lp, address indexed account, uint lpAmount);
    event UnpaidProfitClaimed(address indexed account, uint ethValue);
    event LossRealized(address indexed lp, address indexed account, uint indexed eventId, uint soldLPAmount, uint ethValue);

    /* ========== MODIFIERS ========== */

    modifier onlyCVaultRelayer() {
        require(address(relayer) != address(0) && msg.sender == address(relayer), "CVaultETHLP: caller is not the relayer");
        _;
    }

    modifier canRemoveCollateral(address lp, address _account, uint amount) {
        Account memory account = accountOf(lp, msg.sender);
        uint ratio = relayer.collateralRatioOnETH(lp, account.collateral.sub(amount), bscFlipOf(lp), account.bscFlipBalance, account.bscBNBDebt);
        require(ratio >= COLLATERAL_RATIO_MIN, "CVaultETHLP: can withdraw only up to 180% of the collateral ratio");
        _;
    }

    modifier hasEnoughBalance(uint value) {
        require(address(this).balance >= value, "CVaultETHLP: not enough balance, please try after UTC 00:00");
        _;
    }

    modifier costs {
        uint txFee = relayerCost;
        require(msg.value >= txFee, "CVaultETHLP: Not enough ether provided");
        _;
        if (msg.value > txFee) {
            msg.sender.transfer(msg.value.sub(txFee));
        }
    }

    /* ========== INITIALIZER ========== */

    function initialize() external initializer {
        __CVaultETHLPStorage_init();
        __Whitelist_init();

        relayerCost = 0.015 ether;
        minimumDepositValue = 100e18;
        liquidationCollateralRatio = 125e16;        // 125% == debt ratio 80%
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setZap(address newZap) external onlyOwner {
        zap = IZap(newZap);
    }

    function setPool(address lp, address bscFlip) external onlyOwner {
        _setPool(lp, bscFlip);
        IERC20(lp).safeApprove(address(zap), uint(- 1));
    }

    function recoverToken(address token, uint amount) external onlyOwner {
        require(bscFlipOf(token) == address(0), "CVaultETHLP: lp token can't be recovered");
        IERC20(token).safeTransfer(owner(), amount);
    }

    function setTreasury(address newTreasury) external onlyOwner {
        require(newTreasury != address(0), "CVaultETHLP: invalid treasury address");
        treasury = newTreasury;
    }

    function setRelayerCost(uint newValue) external onlyOwner {
        relayerCost = newValue;
    }

    function setMinimumDepositValue(uint newValue) external onlyOwner {
        require(newValue > 0, "CVaultETHLP: minimum deposit value is zero");
        minimumDepositValue = newValue;
    }

    function updateLiquidationCollateralRatio(uint newCollateralRatio) external onlyOwner {
        require(newCollateralRatio < COLLATERAL_RATIO_MIN, "CVaultETHLP: liquidation collateral ratio must be lower than COLLATERAL_RATIO_MIN");
        liquidationCollateralRatio = newCollateralRatio;
    }

    function clearBSCState(address lp, address _account) external onlyOwner {
        require(stateOf(lp, _account) == State.Idle, "CVaultETHLP: account should be idle state");

        uint eventId = relayer.requestRelayOnETH(lp, _account, SIG_CLEAR, 0, 0, 0);
        emit ClearBSCState(lp, _account, eventId);
    }

    /* ========== VIEW FUNCTIONS ========== */

    function validateRequest(uint8 signature, address _lp, address _account, uint128 _leverage, uint _collateral) external override view returns (uint8 validation, uint112 nonce) {
        Account memory account = accountOf(_lp, _account);
        bool isValid = false;
        if (signature == SIG_DEPOSIT) {
            isValid =
            account.state == State.Depositing
            && account.collateral > 0
            && account.collateral == _collateral
            && account.leverage == _leverage
            && account.updatedAt + EMERGENCY_EXIT_TIMELOCK - 10 minutes > block.timestamp;
        }
        else if (signature == SIG_LEVERAGE) {
            isValid =
            account.state == State.UpdatingLeverage
            && account.collateral > 0
            && account.collateral == _collateral
            && account.leverage == _leverage
            && account.updatedAt + EMERGENCY_EXIT_TIMELOCK - 10 minutes > block.timestamp;
        }
        else if (signature == SIG_WITHDRAW) {
            isValid =
            account.state == State.Withdrawing
            && account.collateral > 0
            && account.leverage == 0
            && account.updatedAt + EMERGENCY_EXIT_TIMELOCK - 10 minutes > block.timestamp;
        }
        else if (signature == SIG_EMERGENCY) {
            isValid =
            account.state == State.EmergencyExited
            && account.collateral == 0
            && account.leverage == 0;
        }
        else if (signature == SIG_LIQUIDATE) {
            isValid =
            account.state == State.Liquidating
            && account.liquidator != address(0);
        }
        else if (signature == SIG_CLEAR) {
            isValid = account.state == State.Idle && account.collateral == 0;
        }

        validation = isValid ? uint8(1) : uint8(0);
        nonce = account.nonce;
    }

    function canLiquidate(address lp, address _account) public override view returns (bool) {
        Account memory account = accountOf(lp, _account);
        return account.state == State.Farming && collateralRatioOf(lp, _account) < liquidationCollateralRatio;
    }

    function collateralRatioOf(address lp, address _account) public view returns (uint) {
        Account memory account = accountOf(lp, _account);
        return relayer.collateralRatioOnETH(lp, account.collateral, bscFlipOf(lp), account.bscFlipBalance, account.bscBNBDebt);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function deposit(address lp, uint amount, uint128 leverage) external notPaused notPausedPool(lp) validLeverage(leverage) onlyWhitelisted payable costs {
        require(relayer.isUtilizable(lp, amount, leverage), "CVaultETHLP: not enough balance to loan in the bank");
        require(relayer.valueOfAsset(lp, amount) >= minimumDepositValue, "CVaultETHLP: less than minimum deposit");

        convertState(lp, msg.sender, State.Depositing);

        uint collateral = _addCollateral(lp, msg.sender, amount);
        setLeverage(lp, msg.sender, leverage);

        uint eventId = relayer.requestRelayOnETH(lp, msg.sender, SIG_DEPOSIT, leverage, collateral, amount);
        emit DepositRequested(lp, msg.sender, eventId, amount, leverage);
    }

    function updateLeverage(address lp, uint128 leverage) external notPaused notPausedPool(lp) validLeverage(leverage) payable costs {
        convertState(lp, msg.sender, State.UpdatingLeverage);
        Account memory account = accountOf(lp, msg.sender);
        uint leverageDiff = Math.max(account.leverage, leverage).sub(Math.min(account.leverage, leverage));

        setLeverage(lp, msg.sender, leverage);

        uint eventId = relayer.requestRelayOnETH(lp, msg.sender, SIG_LEVERAGE, leverage, account.collateral, account.collateral.mul(leverageDiff).div(UNIT));
        emit UpdateLeverageRequested(lp, msg.sender, eventId, leverage, accountOf(lp, msg.sender).collateral);
    }

    function withdraw(address lp, uint amount) external payable costs {
        convertState(lp, msg.sender, State.UpdatingLeverage);

        Account memory account = accountOf(lp, msg.sender);
        uint targetCollateral = account.collateral.sub(amount);
        uint leverage = uint(account.leverage).mul(targetCollateral).div(account.collateral);
        require(LEVERAGE_MIN <= leverage && leverage <= LEVERAGE_MAX, "CVaultETHLP: leverage range should be [10%-150%]");

        setLeverage(lp, msg.sender, uint128(leverage));
        setWithdrawalRequestAmount(lp, msg.sender, amount);

        uint eventId = relayer.requestRelayOnETH(lp, msg.sender, SIG_LEVERAGE, uint128(leverage), account.collateral, amount);
        emit UpdateLeverageRequested(lp, msg.sender, eventId, leverage, accountOf(lp, msg.sender).collateral);
        emit WithdrawRequested(lp, msg.sender, eventId, amount);
    }

    function withdrawAll(address lp) external payable costs {
        convertState(lp, msg.sender, State.Withdrawing);
        setLeverage(lp, msg.sender, 0);

        Account memory account = accountOf(lp, msg.sender);
        uint eventId = relayer.requestRelayOnETH(lp, msg.sender, SIG_WITHDRAW, account.leverage, account.collateral, account.collateral);
        emit WithdrawAllRequested(lp, msg.sender, eventId);
    }

    function claimUnpaidETH(uint value) external hasEnoughBalance(value) {
        decreaseUnpaidETHValue(msg.sender, value);
        payable(msg.sender).transfer(value);
        emit UnpaidProfitClaimed(msg.sender, value);
    }

    function emergencyExit(address lp) external {
        convertState(lp, msg.sender, State.EmergencyExited);
        setLeverage(lp, msg.sender, 0);

        Account memory account = accountOf(lp, msg.sender);
        _removeCollateral(lp, msg.sender, account.collateral);

        uint eventId = relayer.requestRelayOnETH(lp, msg.sender, SIG_EMERGENCY, 0, account.collateral, account.collateral);
        emit EmergencyExitRequested(lp, msg.sender, eventId, account.collateral);
    }

    function addCollateral(address lp, uint amount) external onlyStateFarming(lp) {
        _addCollateral(lp, msg.sender, amount);
        emit CollateralAdded(lp, msg.sender, amount);
    }

    function removeCollateral(address lp, uint amount) external onlyStateFarming(lp) canRemoveCollateral(lp, msg.sender, amount) {
        _removeCollateral(lp, msg.sender, amount);
        emit CollateralRemoved(lp, msg.sender, amount);
    }

    function askLiquidation(address lp, address account) external payable costs {
        relayer.askLiquidationFromCVaultETH(lp, account, msg.sender);
    }

    function executeLiquidation(address lp, address _account, address _liquidator) external override onlyCVaultRelayer {
        if (!canLiquidate(lp, _account)) return;

        setLiquidator(lp, _account, _liquidator);
        convertState(lp, _account, State.Liquidating);

        Account memory account = accountOf(lp, _account);
        uint eventId = relayer.requestRelayOnETH(lp, _account, SIG_LIQUIDATE, account.leverage, account.collateral, account.collateral);
        emit LiquidateRequested(lp, _account, eventId, account.collateral, _liquidator);
    }

    /* ========== RELAYER FUNCTIONS ========== */

    function notifyDeposited(address lp, address _account, uint128 eventId, uint112 nonce, uint bscBNBDebt, uint bscFlipBalance) external override increaseNonceOnlyRelayers(lp, _account, nonce) {
        _notifyDeposited(lp, _account, bscBNBDebt, bscFlipBalance);
        emit NotifyDeposited(lp, _account, eventId, bscBNBDebt, bscFlipBalance);
    }

    function notifyUpdatedLeverage(address lp, address _account, uint128 eventId, uint112 nonce, uint bscBNBDebt, uint bscFlipBalance) external override increaseNonceOnlyRelayers(lp, _account, nonce) {
        _notifyDeposited(lp, _account, bscBNBDebt, bscFlipBalance);
        emit NotifyUpdatedLeverage(lp, _account, eventId, bscBNBDebt, bscFlipBalance);

        uint withdrawalRequestAmount = accountOf(lp, _account).withdrawalRequestAmount;
        if (withdrawalRequestAmount > 0) {
            setWithdrawalRequestAmount(lp, _account, 0);
            _removeCollateral(lp, _account, withdrawalRequestAmount);
            emit CollateralRemoved(lp, _account, withdrawalRequestAmount);
        }
    }

    function notifyWithdrawnAll(address lp, address _account, uint128 eventId, uint112 nonce, uint ethProfit, uint ethLoss) external override increaseNonceOnlyRelayers(lp, _account, nonce) {
        require(stateOf(lp, _account) == State.Withdrawing, "CVaultETHLP: state not Withdrawing");
        if (ethLoss > 0) {
            _repayLoss(lp, _account, eventId, ethLoss);
        }

        uint lpAmount = accountOf(lp, _account).collateral;
        _removeCollateral(lp, _account, lpAmount);

        if (ethProfit > 0) {
            _payProfit(_account, ethProfit);
        }

        convertState(lp, _account, State.Idle);
        emit NotifyWithdrawnAll(lp, _account, eventId, lpAmount, ethProfit, ethLoss);
    }

    function notifyLiquidated(address lp, address _account, uint128 eventId, uint112 nonce, uint ethProfit, uint ethLoss) external override increaseNonceOnlyRelayers(lp, _account, nonce) {
        require(stateOf(lp, _account) == State.Liquidating, "CVaultETHLP: state not Liquidating");
        if (ethLoss > 0) {
            _repayLoss(lp, _account, eventId, ethLoss);
        }

        Account memory account = accountOf(lp, _account);
        address liquidator = account.liquidator;

        uint penalty = account.collateral.mul(LIQUIDATION_PENALTY).div(UNIT);
        _payLiquidationPenalty(lp, _account, penalty, account.liquidator);
        _removeCollateral(lp, _account, account.collateral.sub(penalty));

        if (ethProfit > 0) {
            _payProfit(_account, ethProfit);
        }
        convertState(lp, _account, State.Idle);
        emit NotifyLiquidated(lp, _account, eventId, ethProfit, ethLoss, penalty, liquidator);
    }

    function notifyResolvedEmergency(address lp, address _account, uint128 eventId, uint112 nonce) external override increaseNonceOnlyRelayers(lp, _account, nonce) {
        require(stateOf(lp, _account) == State.EmergencyExited, "CVaultETHLP: state not EmergencyExited");
        convertState(lp, _account, State.Idle);

        emit NotifyResolvedEmergency(lp, _account, eventId);
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _addCollateral(address lp, address _account, uint amount) private returns (uint collateral) {
        IERC20(lp).transferFrom(_account, address(this), amount);
        collateral = increaseCollateral(lp, _account, amount);
    }

    function _removeCollateral(address lp, address _account, uint amount) private returns (uint collateral) {
        collateral = decreaseCollateral(lp, _account, amount);

        uint _fee = withdrawalFee(lp, _account, amount);
        if (_fee > 0) {
            _zapOutAll(lp, _fee);
        }
        IERC20(lp).safeTransfer(_account, amount.sub(_fee));
    }

    function _notifyDeposited(address lp, address _account, uint bscBNBDebt, uint bscFlipBalance) private {
        convertState(lp, _account, State.Farming);

        setBSCBNBDebt(lp, _account, bscBNBDebt);
        setBSCFlipBalance(lp, _account, bscFlipBalance);
    }

    function _payProfit(address _account, uint value) private {
        uint transfer;
        uint balance = address(this).balance;
        if (balance >= value) {
            transfer = value;
        } else {
            transfer = balance;
            increaseUnpaidETHValue(_account, value.sub(balance));
        }

        if (transfer > 0) {
            payable(_account).transfer(transfer);
        }
    }

    function _repayLoss(address lp, address _account, uint128 eventId, uint value) private {
        if (unpaidETH(_account) >= value) {
            decreaseUnpaidETHValue(_account, value);
            return;
        }

        Account memory account = accountOf(lp, _account);
        uint price = relayer.priceOf(lp);
        uint amount = Math.min(value.mul(1e18).div(price).mul(1000).div(997), account.collateral);
        uint before = address(this).balance;
        _zapOutAll(lp, amount);
        uint soldValue = address(this).balance.sub(before);
        decreaseCollateral(lp, _account, amount);

        emit LossRealized(lp, _account, eventId, amount, soldValue);
    }

    function _payLiquidationPenalty(address lp, address _account, uint penalty, address liquidator) private {
        require(liquidator != address(0), "CVaultETHLP: liquidator should not be zero");
        decreaseCollateral(lp, _account, penalty);

        uint fee = penalty.mul(LIQUIDATION_FEE).div(UNIT);
        IERC20(lp).safeTransfer(treasury, fee);
        IERC20(lp).safeTransfer(liquidator, penalty.sub(fee));
    }

    function _zapOutAll(address lp, uint amount) private {
        zap.zapOut(lp, amount);

        address token0 = IUniswapV2Pair(lp).token0();
        address token1 = IUniswapV2Pair(lp).token1();
        if (token0 != WETH) {
            _approveZap(token0);
            zap.zapOut(token0, IERC20(token0).balanceOf(address(this)));
        }
        if (token1 != WETH) {
            _approveZap(token1);
            zap.zapOut(token1, IERC20(token1).balanceOf(address(this)));
        }
    }

    function _approveZap(address token) private {
        if (IERC20(token).allowance(address(this), address(zap)) == 0) {
            IERC20(token).safeApprove(address(zap), uint(-1));
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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


interface ICVaultETHLP {
    function validateRequest(uint8 signature, address lp, address account, uint128 leverage, uint collateral) external view returns (uint8 validation, uint112 nonce);
    function canLiquidate(address lp, address account) external view returns (bool);
    function executeLiquidation(address lp, address _account, address _liquidator) external;

    function notifyDeposited(address lp, address account, uint128 eventId, uint112 nonce, uint bscBNBDebt, uint bscFlipBalance) external;
    function notifyUpdatedLeverage(address lp, address account, uint128 eventId, uint112 nonce, uint bscBNBDebt, uint bscFlipBalance) external;
    function notifyWithdrawnAll(address lp, address account, uint128 eventId, uint112 nonce, uint ethProfit, uint ethLoss) external;
    function notifyLiquidated(address lp, address account, uint128 eventId, uint112 nonce, uint ethProfit, uint ethLoss) external;
    function notifyResolvedEmergency(address lp, address account, uint128 eventId, uint112 nonce) external;
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

contract Whitelist is OwnableUpgradeable {
    mapping (address => bool) private _whitelist;
    bool private _disable;                      // default - false means whitelist feature is working on. if true no more use of whitelist

    event Whitelisted(address indexed _address, bool whitelist);
    event EnableWhitelist();
    event DisableWhitelist();

    modifier onlyWhitelisted {
        require(_disable || _whitelist[msg.sender], "Whitelist: caller is not on the whitelist");
        _;
    }

    function __Whitelist_init() internal initializer {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../interfaces/IUniswapV2Pair.sol";
import "../interfaces/IUniswapV2Factory.sol";
import "../interfaces/AggregatorV3Interface.sol";
import "../cvaults/eth/CVaultETHLP.sol";
import "../cvaults/CVaultRelayer.sol";
import {PoolConstant} from "../library/PoolConstant.sol";


contract DashboardETH is OwnableUpgradeable {
    using SafeMath for uint;

    IERC20 private constant WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IUniswapV2Factory private constant factory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    AggregatorV3Interface private constant ethPriceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

    /* ========== STATE VARIABLES ========== */

    address payable public cvaultAddress;
    mapping(address => address) private pairAddresses;

    /* ========== INITIALIZER ========== */

    function initialize() external initializer {
        __Ownable_init();
    }

    /* ========== Restricted Operation ========== */

    function setCVaultAddress(address payable _cvaultAddress) external onlyOwner {
        cvaultAddress = _cvaultAddress;
    }

    function setPairAddress(address asset, address pair) external onlyOwner {
        pairAddresses[asset] = pair;
    }

    /* ========== Value Calculation ========== */

    function priceOfETH() view public returns (uint) {
        (, int price, , ,) = ethPriceFeed.latestRoundData();
        return uint(price).mul(1e10);
    }

    function pricesInUSD(address[] memory assets) public view returns (uint[] memory) {
        uint[] memory prices = new uint[](assets.length);
        for (uint i = 0; i < assets.length; i++) {
            (, uint valueInUSD) = valueOfAsset(assets[i], 1e18);
            prices[i] = valueInUSD;
        }
        return prices;
    }

    function valueOfAsset(address asset, uint amount) public view returns (uint valueInETH, uint valueInUSD) {
        if (asset == address(0) || asset == address(WETH)) {
            valueInETH = amount;
            valueInUSD = amount.mul(priceOfETH()).div(1e18);
        } else if (keccak256(abi.encodePacked(IUniswapV2Pair(asset).symbol())) == keccak256("UNI-V2")) {
            if (IUniswapV2Pair(asset).token0() == address(WETH) || IUniswapV2Pair(asset).token1() == address(WETH)) {
                valueInETH = amount.mul(WETH.balanceOf(address(asset))).mul(2).div(IUniswapV2Pair(asset).totalSupply());
                valueInUSD = valueInETH.mul(priceOfETH()).div(1e18);
            } else {
                uint balanceToken0 = IERC20(IUniswapV2Pair(asset).token0()).balanceOf(asset);
                (uint token0PriceInETH,) = valueOfAsset(IUniswapV2Pair(asset).token0(), 1e18);

                valueInETH = amount.mul(balanceToken0).mul(2).mul(token0PriceInETH).div(1e18).div(IUniswapV2Pair(asset).totalSupply());
                valueInUSD = valueInETH.mul(priceOfETH()).div(1e18);
            }
        } else {
            address pairAddress = pairAddresses[asset];
            if (pairAddress == address(0)) {
                pairAddress = address(WETH);
            }

            uint decimalModifier = 0;
            uint decimals = uint(ERC20(asset).decimals());
            if (decimals < 18) {
                decimalModifier = 18 - decimals;
            }

            address pair = factory.getPair(asset, pairAddress);
            valueInETH = IERC20(pairAddress).balanceOf(pair).mul(amount).div(IERC20(asset).balanceOf(pair).mul(10 ** decimalModifier));
            if (pairAddress != address(WETH)) {
                (uint pairValueInETH,) = valueOfAsset(pairAddress, 1e18);
                valueInETH = valueInETH.mul(pairValueInETH).div(1e18);
            }
            valueInUSD = valueInETH.mul(priceOfETH()).div(1e18);
        }
    }

    /* ========== Collateral Calculation ========== */

    function collateralOfPool(address pool, address account) public view returns (uint collateralETH, uint collateralBSC, uint bnbDebt, uint leverage) {
        CVaultETHLPState.Account memory accountState = CVaultETHLP(cvaultAddress).accountOf(pool, account);
        collateralETH = accountState.collateral;
        collateralBSC = accountState.bscFlipBalance;
        bnbDebt = accountState.bscBNBDebt;
        leverage = accountState.leverage;
    }

    /* ========== TVL Calculation ========== */

    function tvlOfPool(address pool) public view returns (uint) {
        if (pool == address(0)) return 0;
        (, uint tvlInUSD) = valueOfAsset(pool, CVaultETHLP(cvaultAddress).totalCollateralOf(pool));
        return tvlInUSD;
    }

    /* ========== Pool Information ========== */

    function infoOfPool(address pool, address account) public view returns (PoolConstant.PoolInfoETH memory) {
        PoolConstant.PoolInfoETH memory poolInfo;
        if (pool == address(0)) {
            return poolInfo;
        }

        CVaultETHLP cvault = CVaultETHLP(cvaultAddress);
        CVaultETHLPState.Account memory accountState = cvault.accountOf(pool, account);

        (uint collateralETH, uint collateralBSC, uint bnbDebt, uint leverage) = collateralOfPool(pool, account);
        poolInfo.pool = pool;
        poolInfo.collateralETH = collateralETH;
        poolInfo.collateralBSC = collateralBSC;
        poolInfo.bnbDebt = bnbDebt;
        poolInfo.leverage = leverage;
        poolInfo.tvl = tvlOfPool(pool);
        poolInfo.updatedAt = accountState.updatedAt;
        poolInfo.depositedAt = accountState.depositedAt;
        poolInfo.feeDuration = cvault.WITHDRAWAL_FEE_PERIOD();
        poolInfo.feePercentage = cvault.WITHDRAWAL_FEE();
        return poolInfo;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

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
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
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
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

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
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
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

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./interface/ICVaultRelayer.sol";
import "./interface/ICVaultETHLP.sol";
import "./interface/ICVaultBSCFlip.sol";


contract CVaultRelayer is ICVaultRelayer, OwnableUpgradeable {
    using SafeMath for uint;

    uint8 public constant SIG_DEPOSIT = 10;
    uint8 public constant SIG_LEVERAGE = 20;
    uint8 public constant SIG_WITHDRAW = 30;
    uint8 public constant SIG_LIQUIDATE = 40;
    uint8 public constant SIG_EMERGENCY = 50;
    uint8 public constant SIG_CLEAR = 63;

    address public constant BNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    /* ========== STATE VARIABLES ========== */

    address public cvaultETH;
    address public cvaultBSC;

    uint public bankLiquidity;
    uint public bankUtilized;

    uint128 public pendingId;
    uint128 public completeId;
    uint128 public liqPendingId;
    uint128 public liqCompleteId;

    mapping(uint128 => RelayRequest) public requests;
    mapping(uint128 => RelayResponse) public responses;
    mapping(uint128 => RelayLiquidation) public liquidations;

    mapping(address => bool) private _relayHandlers;
    mapping(address => uint) private _tokenPrices;

    /* ========== EVENTS ========== */

    event RelayCompleted(uint128 indexed completeId, uint128 count);
    event RelayFailed(uint128 indexed requestId);

    /* ========== MODIFIERS ========== */

    modifier onlyCVaultETH() {
        require(cvaultETH != address(0) && msg.sender == cvaultETH, "CVaultRelayer: call is not the cvault eth");
        _;
    }

    modifier onlyRelayHandlers() {
        require(_relayHandlers[msg.sender], "CVaultRelayer: caller is not the relay handler");
        _;
    }

    /* ========== INITIALIZER ========== */

    function initialize() external initializer {
        __Ownable_init();
        require(owner() != address(0), "CVaultRelayer: owner must be set");
    }

    /* ========== RELAY VIEW FUNCTIONS ========== */

    function getPendingRequestsOnETH(uint128 limit) public view returns (RelayRequest[] memory) {
        if (pendingId < completeId) {
            return new RelayRequest[](0);
        }

        uint128 count = pendingId - completeId;
        count = count > limit ? limit : count;
        RelayRequest[] memory pendingRequests = new RelayRequest[](count);

        ICVaultETHLP cvaultETHLP = ICVaultETHLP(cvaultETH);
        for (uint128 index = 0; index < count; index++) {
            uint128 requestId = completeId + index + uint128(1);
            RelayRequest memory request = requests[requestId];

            (uint8 validation, uint112 nonce) = cvaultETHLP.validateRequest(request.signature, request.lp, request.account, request.leverage, request.collateral);
            request.validation = validation;
            request.nonce = nonce;

            pendingRequests[index] = request;
        }
        return pendingRequests;
    }

    function getPendingResponsesOnBSC(uint128 limit) public view returns (RelayResponse[] memory) {
        if (pendingId < completeId) {
            return new RelayResponse[](0);
        }

        uint128 count = pendingId - completeId;
        count = count > limit ? limit : count;
        RelayResponse[] memory pendingResponses = new RelayResponse[](count);

        uint128 returnCounter = count;
        for (uint128 requestId = pendingId; requestId > pendingId - count; requestId--) {
            returnCounter--;
            pendingResponses[returnCounter] = responses[requestId];
        }
        return pendingResponses;
    }

    function getPendingLiquidationCountOnETH() public view returns (uint) {
        if (liqPendingId < liqCompleteId) {
            return 0;
        }
        return liqPendingId - liqCompleteId;
    }

    function canAskLiquidation(address lp, address account) public view returns (bool) {
        if (liqPendingId < liqCompleteId) {
            return true;
        }

        uint128 count = liqPendingId - liqCompleteId;
        for (uint128 liqId = liqPendingId; liqId > liqPendingId - count; liqId--) {
            RelayLiquidation memory each = liquidations[liqId];
            if (each.lp == lp && each.account == account) {
                return false;
            }
        }
        return true;
    }

    function getHistoriesOf(uint128[] calldata selector) public view returns (RelayHistory[] memory) {
        RelayHistory[] memory histories = new RelayHistory[](selector.length);

        for (uint128 index = 0; index < selector.length; index++) {
            uint128 requestId = selector[index];
            histories[index] = RelayHistory({requestId : requestId, request : requests[requestId], response : responses[requestId]});
        }
        return histories;
    }

    /* ========== ORACLE VIEW FUNCTIONS ========== */

    function valueOfAsset(address token, uint amount) public override view returns (uint) {
        return priceOf(token).mul(amount).div(1e18);
    }

    function priceOf(address token) public override view returns (uint) {
        return _tokenPrices[token];
    }

    function collateralRatioOnETH(address lp, uint lpAmount, address flip, uint flipAmount, uint debt) external override view returns (uint) {
        uint lpValue = valueOfAsset(lp, lpAmount);
        uint flipValue = valueOfAsset(flip, flipAmount);
        uint debtValue = valueOfAsset(BNB, debt);

        if (debtValue == 0) {
            return uint(- 1);
        }
        return lpValue.add(flipValue).mul(1e18).div(debtValue);
    }

    function utilizationInfo() public override view returns (uint liquidity, uint utilized) {
        return (bankLiquidity, bankUtilized);
    }

    function utilizationInfoOnBSC() public view returns (uint liquidity, uint utilized) {
        return ICVaultBSCFlip(cvaultBSC).getUtilizationInfo();
    }

    function isUtilizable(address lp, uint amount, uint leverage) external override view returns (bool) {
        if (bankUtilized >= bankLiquidity) return false;

        uint availableBNBSupply = bankLiquidity.sub(bankUtilized);
        return valueOfAsset(BNB, availableBNBSupply) >= valueOfAsset(lp, amount).mul(leverage).div(1e18);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setCVaultETH(address _cvault) external onlyOwner {
        cvaultETH = _cvault;
    }

    function setCVaultBSC(address _cvault) external onlyOwner {
        cvaultBSC = _cvault;
    }

    function setRelayHandler(address newRelayHandler, bool permission) external onlyOwner {
        _relayHandlers[newRelayHandler] = permission;
    }

    /* ========== RELAY FUNCTIONS ========== */
    /*
    * tx 1.   CVaultETH           requestRelayOnETH          -> CVaultRelayer enqueues request
    * tx 2-1. CVaultRelayHandlers getPendingRequestsOnETH    -> CVaultRelayer returns pending request list
    * tx 2-2. CVaultRelayHandlers transferRelaysOnBSC        -> CVaultRelayer handles request list by signature and update response list
    * tx 3-1. CVaultRelayHandlers getPendingResponsesOnBSC   -> CVaultRelayer returns pending response list
    * tx 3-2. CVaultRelayHandlers completeRelaysOnETH        -> CVaultRelayer handles response list by signature and update completeId
    * tx 3-3. CVaultRelayHandlers syncCompletedRelaysOnBSC   -> CVaultRelayer synchronize completeId
    */

    function requestRelayOnETH(address lp, address account, uint8 signature, uint128 leverage, uint collateral, uint lpAmount) public override onlyCVaultETH returns (uint requestId) {
        pendingId++;
        RelayRequest memory request = RelayRequest({
        lp : lp, account : account, signature : signature, validation : uint8(0), nonce : uint112(0), requestId : pendingId,
        leverage : leverage, collateral : collateral, lpValue : valueOfAsset(lp, lpAmount)
        });
        requests[pendingId] = request;
        return pendingId;
    }

    function transferRelaysOnBSC(RelayRequest[] memory _requests) external onlyRelayHandlers {
        require(cvaultBSC != address(0), "CVaultRelayer: cvaultBSC must be set");

        ICVaultBSCFlip cvaultBSCFlip = ICVaultBSCFlip(cvaultBSC);
        for (uint index = 0; index < _requests.length; index++) {
            RelayRequest memory request = _requests[index];
            RelayResponse memory response = RelayResponse({
            lp : request.lp, account : request.account,
            signature : request.signature, validation : request.validation, nonce : request.nonce, requestId : request.requestId,
            bscBNBDebtShare : 0, bscFlipBalance : 0, ethProfit : 0, ethLoss : 0
            });

            if (request.validation != uint8(0)) {
                if (request.signature == SIG_DEPOSIT) {
                    (uint bscBNBDebtShare, uint bscFlipBalance) = cvaultBSCFlip.deposit(request.lp, request.account, request.requestId, request.nonce, request.leverage, request.collateral);
                    response.bscBNBDebtShare = bscBNBDebtShare;
                    response.bscFlipBalance = bscFlipBalance;
                }
                else if (request.signature == SIG_LEVERAGE) {
                    (uint bscBNBDebtShare, uint bscFlipBalance) = cvaultBSCFlip.updateLeverage(request.lp, request.account, request.requestId, request.nonce, request.leverage, request.collateral);
                    response.bscBNBDebtShare = bscBNBDebtShare;
                    response.bscFlipBalance = bscFlipBalance;
                }
                else if (request.signature == SIG_WITHDRAW) {
                    (uint ethProfit, uint ethLoss) = cvaultBSCFlip.withdrawAll(request.lp, request.account, request.requestId, request.nonce);
                    response.ethProfit = ethProfit;
                    response.ethLoss = ethLoss;
                }
                else if (request.signature == SIG_EMERGENCY) {
                    (uint ethProfit, uint ethLoss) = cvaultBSCFlip.emergencyExit(request.lp, request.account, request.requestId, request.nonce);
                    response.ethProfit = ethProfit;
                    response.ethLoss = ethLoss;
                }
                else if (request.signature == SIG_LIQUIDATE) {
                    (uint ethProfit, uint ethLoss) = cvaultBSCFlip.liquidate(request.lp, request.account, request.requestId, request.nonce);
                    response.ethProfit = ethProfit;
                    response.ethLoss = ethLoss;
                }
                else if (request.signature == SIG_CLEAR) {
                    (uint ethProfit, uint ethLoss) = cvaultBSCFlip.withdrawAll(request.lp, request.account, request.requestId, request.nonce);
                    response.ethProfit = ethProfit;
                    response.ethLoss = ethLoss;
                }
            }

            requests[request.requestId] = request;
            responses[response.requestId] = response;
            pendingId++;
        }

        (bankLiquidity, bankUtilized) = cvaultBSCFlip.getUtilizationInfo();
    }

    function completeRelaysOnETH(RelayResponse[] memory _responses, RelayUtilization memory utilization) external onlyRelayHandlers {
        bankLiquidity = utilization.liquidity;
        bankUtilized = utilization.utilized;

        for (uint index = 0; index < _responses.length; index++) {
            RelayResponse memory response = _responses[index];
            bool success;
            if (response.validation != uint8(0)) {
                if (response.signature == SIG_DEPOSIT) {
                    (success,) = cvaultETH.call(
                        abi.encodeWithSignature("notifyDeposited(address,address,uint128,uint112,uint256,uint256)",
                        response.lp, response.account, response.requestId, response.nonce, response.bscBNBDebtShare, response.bscFlipBalance)
                    );
                } else if (response.signature == SIG_LEVERAGE) {
                    (success,) = cvaultETH.call(
                        abi.encodeWithSignature("notifyUpdatedLeverage(address,address,uint128,uint112,uint256,uint256)",
                        response.lp, response.account, response.requestId, response.nonce, response.bscBNBDebtShare, response.bscFlipBalance)
                    );
                } else if (response.signature == SIG_WITHDRAW) {
                    (success,) = cvaultETH.call(
                        abi.encodeWithSignature("notifyWithdrawnAll(address,address,uint128,uint112,uint256,uint256)",
                        response.lp, response.account, response.requestId, response.nonce, response.ethProfit, response.ethLoss)
                    );
                } else if (response.signature == SIG_EMERGENCY) {
                    (success,) = cvaultETH.call(
                        abi.encodeWithSignature("notifyResolvedEmergency(address,address,uint128,uint112)",
                        response.lp, response.account, response.requestId, response.nonce)
                    );
                } else if (response.signature == SIG_LIQUIDATE) {
                    (success,) = cvaultETH.call(
                        abi.encodeWithSignature("notifyLiquidated(address,address,uint128,uint112,uint256,uint256)",
                        response.lp, response.account, response.requestId, response.nonce, response.ethProfit, response.ethLoss)
                    );
                } else if (response.signature == SIG_CLEAR) {
                    success = true;
                }

                if (!success) {
                    emit RelayFailed(response.requestId);
                }
            }

            responses[response.requestId] = response;
            completeId++;
        }
        emit RelayCompleted(completeId, uint128(_responses.length));
    }

    function syncCompletedRelaysOnBSC(uint128 _count) external onlyRelayHandlers {
        completeId = completeId + _count;
        emit RelayCompleted(completeId, _count);
    }

    function syncUtilization(RelayUtilization memory utilization) external onlyRelayHandlers {
        bankLiquidity = utilization.liquidity;
        bankUtilized = utilization.utilized;
    }

    /* ========== LIQUIDATION FUNCTIONS ========== */

    function askLiquidationFromHandler(RelayLiquidation[] memory asks) external override onlyRelayHandlers {
        for (uint index = 0; index < asks.length; index++) {
            RelayLiquidation memory each = asks[index];
            if (canAskLiquidation(each.lp, each.account)) {
                liqPendingId++;
                liquidations[liqPendingId] = each;
            }
        }
    }

    function askLiquidationFromCVaultETH(address lp, address account, address liquidator) public override onlyCVaultETH {
        if (canAskLiquidation(lp, account)) {
            liqPendingId++;
            RelayLiquidation memory liquidation = RelayLiquidation({lp : lp, account : account, liquidator : liquidator});
            liquidations[liqPendingId] = liquidation;
        }
    }

    function executeLiquidationOnETH() external override onlyRelayHandlers {
        require(liqPendingId > liqCompleteId, "CVaultRelayer: no pending liquidations");

        ICVaultETHLP cvaultETHLP = ICVaultETHLP(cvaultETH);
        for (uint128 index = 0; index < liqPendingId - liqCompleteId; index++) {
            RelayLiquidation memory each = liquidations[liqCompleteId + index + uint128(1)];
            cvaultETHLP.executeLiquidation(each.lp, each.account, each.liquidator);
            liqCompleteId++;
        }
    }

    /* ========== ORACLE FUNCTIONS ========== */

    function setOraclePairData(RelayOracleData[] calldata data) external onlyRelayHandlers {
        for (uint index = 0; index < data.length; index++) {
            RelayOracleData calldata each = data[index];
            _tokenPrices[each.token] = each.price;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/Math.sol";
import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import "../library/RewardsDistributionRecipientUpgradeable.sol";
import "../interfaces/IStrategy.sol";
import "../interfaces/IMasterChef.sol";
import "../interfaces/IBunnyMinter.sol";
import "../vaults/VaultController.sol";
import {PoolConstant} from "../library/PoolConstant.sol";


contract VaultFlipToCakeTester is VaultController, IStrategy, RewardsDistributionRecipientUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMath for uint;
    using SafeBEP20 for IBEP20;

    /* ========== CONSTANTS ============= */

    address private constant CAKE = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    IMasterChef private constant CAKE_MASTER_CHEF = IMasterChef(0x73feaa1eE314F8c655E354234017bE2193C9E24E);
    PoolConstant.PoolTypes public constant override poolType = PoolConstant.PoolTypes.FlipToCake;

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
    mapping (address => uint) private _depositedAt;

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

    function initialize(uint _pid) external initializer {
        (address _token,,,) = CAKE_MASTER_CHEF.poolInfo(_pid);
        __VaultController_init(IBEP20(_token));
        __RewardsDistributionRecipient_init();
        __ReentrancyGuard_init();

        _stakingToken.safeApprove(address(CAKE_MASTER_CHEF), uint(~0));

        pid = _pid;

        rewardsDuration = 24 hours;

        rewardsDistribution = msg.sender;
        setMinter(IBunnyMinter(0x0B4A714AAf59E46cb1900E3C031017Fd72667EfE));
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

    function priceShare() external view override returns(uint) {
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

    function _deposit(uint amount, address _to) private nonReentrant notPaused updateReward(_to) {
        require(amount > 0, "VaultFlipToCake: amount must be greater than zero");
        _totalSupply = _totalSupply.add(amount);
        _balances[_to] = _balances[_to].add(amount);
        _depositedAt[_to] = block.timestamp;
        _stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        CAKE_MASTER_CHEF.deposit(pid, amount);
        emit Deposited(_to, amount);

        _harvest();
    }

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
        CAKE_MASTER_CHEF.withdraw(pid, amount);
        uint withdrawalFee;
        if (canMint()) {
            uint depositTimestamp = _depositedAt[msg.sender];
            withdrawalFee = _minter.withdrawalFee(amount, depositTimestamp);
            if (withdrawalFee > 0) {
                uint performanceFee = withdrawalFee.div(100);
                _minter.mintFor(address(_stakingToken), withdrawalFee.sub(performanceFee), performanceFee, msg.sender, depositTimestamp);
                amount = amount.sub(withdrawalFee);
            }
        }

        _stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount, withdrawalFee);

        _harvest();
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
            _rewardsToken.withdraw(reward);
            uint cakeBalance = IBEP20(CAKE).balanceOf(address(this));
            uint performanceFee;

            if (canMint()) {
                performanceFee = _minter.performanceFee(cakeBalance);
                _minter.mintFor(CAKE, 0, performanceFee, msg.sender, _depositedAt[msg.sender]);
            }

            IBEP20(CAKE).safeTransfer(msg.sender, cakeBalance.sub(performanceFee));
            emit ProfitPaid(msg.sender, cakeBalance, performanceFee);
        }
    }

    function harvest() public override {
        CAKE_MASTER_CHEF.withdraw(pid, 0);
        _harvest();
    }

    function _harvest() private {
        uint cakeAmount = IBEP20(CAKE).balanceOf(address(this));
        uint _before = _rewardsToken.sharesOf(address(this));
        _rewardsToken.deposit(cakeAmount);
        uint amount = _rewardsToken.sharesOf(address(this)).sub(_before);
        if (amount > 0) {
            _notifyRewardAmount(amount);
            emit Harvested(amount);
        }
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setMinter(IBunnyMinter _minter) override public onlyOwner {
        VaultController.setMinter(_minter);
        if (address(_minter) != address(0)) {
            IBEP20(CAKE).safeApprove(address(_minter), 0);
            IBEP20(CAKE).safeApprove(address(_minter), uint(~0));
        }
    }

    function setRewardsToken(address newRewardsToken) public onlyOwner {
        require(address(_rewardsToken) == address(0), "VaultFlipToCake: rewards token already set");

        _rewardsToken = IStrategy(newRewardsToken);
        IBEP20(CAKE).safeApprove(newRewardsToken, 0);
        IBEP20(CAKE).safeApprove(newRewardsToken, uint(~0));
    }

    function notifyRewardAmount(uint reward) public override onlyRewardsDistribution {
        _notifyRewardAmount(reward);
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

    function setRewardsDuration(uint _rewardsDuration) external onlyOwner {
        require(periodFinish == 0 || block.timestamp > periodFinish, "VaultFlipToCake: reward duration can only be updated after the period ends");
        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    }

    /* ========== SALVAGE PURPOSE ONLY ========== */

    function recoverToken(address tokenAddress, uint tokenAmount) external override onlyOwner {
        require(tokenAddress != address(_stakingToken) && tokenAddress != _rewardsToken.stakingToken(), "VaultFlipToCake: cannot recover underlying token");
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
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/BEP20.sol";

import "../interfaces/IPancakeRouter02.sol";
import "../interfaces/IPancakePair.sol";
import "../interfaces/IStrategy.sol";
import "../interfaces/IMasterChef.sol";
import "../interfaces/IBunnyMinter.sol";
import "../interfaces/IBunnyChef.sol";
import "../library/PausableUpgradeable.sol";
import "../library/Whitelist.sol";


abstract contract VaultController is IVaultController, PausableUpgradeable, Whitelist {
    using SafeBEP20 for IBEP20;

    /* ========== CONSTANT VARIABLES ========== */
    BEP20 private constant BUNNY = BEP20(0xC9849E6fdB743d08fAeE3E34dd2D1bc69EA11a51);

    /* ========== STATE VARIABLES ========== */

    address public keeper;
    IBEP20 internal _stakingToken;
    IBunnyMinter internal _minter;
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
        __Whitelist_init();

        keeper = 0x793074D9799DC3c6039F8056F1Ba884a73462051;
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

    function setMinter(IBunnyMinter newMinter) virtual public onlyOwner {
        // can zero
        _minter = newMinter;
        if (address(newMinter) != address(0)) {
            require(address(newMinter) == BUNNY.getOwner(), 'VaultController: not bunny minter');
            _stakingToken.safeApprove(address(newMinter), 0);
            _stakingToken.safeApprove(address(newMinter), uint(~0));
        }
    }

    function setBunnyChef(IBunnyChef newBunnyChef) virtual public onlyOwner {
        _bunnyChef = newBunnyChef;
    }

    /* ========== SALVAGE PURPOSE ONLY ========== */

    function recoverToken(address _token, uint amount) virtual external onlyOwner {
        require(_token != address(_stakingToken), 'VaultController: cannot recover underlying token');
        IBEP20(_token).safeTransfer(owner(), amount);
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

import "../vaults/VaultController.sol";


contract VaultControllerTester is VaultController {
    function initialize(address _token) external initializer {
        __VaultController_init(IBEP20(_token));
        setMinter(IBunnyMinter(0x0B4A714AAf59E46cb1900E3C031017Fd72667EfE));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "../library/Whitelist.sol";

contract WhitelistTester is Whitelist {
    uint public count;
    function initialize() external initializer {
        __Whitelist_init();
    }

    function increase() external onlyWhitelisted {
        count++;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/math/Math.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol";

import "../../../interfaces/IPancakePair.sol";
import "../../../interfaces/IPancakeRouter02.sol";

import "../../../library/PausableUpgradeable.sol";
import "../../../library/Whitelist.sol";
import "../../interface/IBankBNB.sol";
import "../../interface/IBankETH.sol";


contract BankETH is IBankETH, PausableUpgradeable, Whitelist {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    uint private constant PERFORMANCE_FEE_MAX = 10000;

    address private constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address private constant ETH = 0x2170Ed0880ac9A755fd29B2688956BD959F933F8;
    IPancakeRouter02 private constant ROUTER = IPancakeRouter02(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F);

    /* ========== STATE VARIABLES ========== */

    uint public PERFORMANCE_FEE;
    uint private _treasuryFund;
    uint private _treasuryDebt;
    address public keeper;
    address public bankBNB;

    /* ========== MODIFIERS ========== */

    modifier onlyKeeper {
        require(msg.sender == keeper || msg.sender == owner(), "BankETH: not keeper");
        _;
    }

    /* ========== INITIALIZER ========== */

    receive() external payable {}

    function initialize() external initializer {
        __PausableUpgradeable_init();
        __Whitelist_init();

        PERFORMANCE_FEE = 1000;
        IBEP20(ETH).safeApprove(address(ROUTER), uint(-1));
    }

    /* ========== VIEW FUNCTIONS ========== */

    function balance() external view returns(uint) {
        return IBEP20(ETH).balanceOf(address(this));
    }

    function treasuryFund() external view returns(uint) {
        return _treasuryFund;
    }

    function treasuryDebt() external view returns(uint) {
        return _treasuryDebt;
    }

    /* ========== RESTRICTED FUNCTIONS - OWNER ========== */

    function setKeeper(address newKeeper) external onlyOwner {
        keeper = newKeeper;
    }

    function setPerformanceFee(uint newPerformanceFee) external onlyOwner {
        require(newPerformanceFee <= 5000, "BankETH: fee too much");
        PERFORMANCE_FEE = newPerformanceFee;
    }

    function recoverToken(address _token, uint amount) external onlyOwner {
        require(_token != ETH, 'BankETH: cannot recover eth token');
        if (_token == address(0)) {
            payable(owner()).transfer(amount);
        } else {
            IBEP20(_token).safeTransfer(owner(), amount);
        }
    }

    function setBankBNB(address newBankBNB) external onlyOwner {
        require(bankBNB == address(0), "BankETH: bankBNB is already set");
        bankBNB = newBankBNB;

        IBEP20(ETH).safeApprove(newBankBNB, uint(-1));
    }

    /* ========== RESTRICTED FUNCTIONS - KEEPER ========== */

    function repayTreasuryDebt() external onlyKeeper returns(uint ethAmount) {
        address[] memory path = new address[](2);
        path[0] = ETH;
        path[1] = WBNB;

        uint debt = IBankBNB(bankBNB).accruedDebtValOf(address(this), address(this));
        ethAmount = ROUTER.getAmountsIn(debt, path)[0];
        require(ethAmount <= IBEP20(ETH).balanceOf(address(this)), "BankETH: insufficient eth");

        if (_treasuryDebt >= ethAmount) {
            _treasuryFund = _treasuryFund.add(_treasuryDebt.sub(ethAmount));
            _treasuryDebt = 0;
            _repayTreasuryDebt(debt, ethAmount);
        } else if (_treasuryDebt.add(_treasuryFund) >= ethAmount) {
            _treasuryFund = _treasuryFund.sub(ethAmount.sub(_treasuryDebt));
            _treasuryDebt = 0;
            _repayTreasuryDebt(debt, ethAmount);
        } else {
            revert("BankETH: not enough eth balance");
        }
    }

    // panama bridge
    function transferTreasuryFund(address to, uint ethAmount) external onlyKeeper {
        IBEP20(ETH).safeTransfer(to, ethAmount);
    }

    /* ========== RESTRICTED FUNCTIONS - WHITELISTED ========== */

    function repayOrHandOverDebt(address lp, address account, uint debt) external override onlyWhitelisted returns(uint ethAmount)  {
        if (debt == 0) return 0;

        address[] memory path = new address[](2);
        path[0] = ETH;
        path[1] = WBNB;

        ethAmount = ROUTER.getAmountsIn(debt, path)[0];
        uint ethBalance = IBEP20(ETH).balanceOf(address(this));
        if (ethAmount <= ethBalance) {
            // repay
            uint[] memory amounts = ROUTER.swapTokensForExactETH(debt, ethAmount, path, address(this), block.timestamp);
            IBankBNB(bankBNB).repay{ value: amounts[1] }(lp, account);
        } else {
            if (ethBalance > 0) {
                uint[] memory amounts = ROUTER.swapExactTokensForETH(ethBalance, 0, path, address(this), block.timestamp);
                IBankBNB(bankBNB).repay{ value: amounts[1] }(lp, account);
            }

            _treasuryDebt = _treasuryDebt.add(ethAmount.sub(ethBalance));
            // insufficient ETH !!!!
            // handover BNB debt
            IBankBNB(bankBNB).handOverDebtToTreasury(lp, account);
        }
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function depositTreasuryFund(uint ethAmount) external {
        IBEP20(ETH).transferFrom(msg.sender, address(this), ethAmount);
        _treasuryFund = _treasuryFund.add(ethAmount);
    }

    function transferProfit() external override payable returns(uint ethAmount) {
        if (msg.value == 0) return 0;

        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = ETH;

        uint[] memory amounts = ROUTER.swapExactETHForTokens{ value : msg.value }(0, path, address(this), block.timestamp);
        uint fee = amounts[1].mul(PERFORMANCE_FEE).div(PERFORMANCE_FEE_MAX);

        _treasuryFund = _treasuryFund.add(fee);
        ethAmount = amounts[1].sub(fee);
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _repayTreasuryDebt(uint debt, uint maxETHAmount) private {
        address[] memory path = new address[](2);
        path[0] = ETH;
        path[1] = WBNB;

        uint[] memory amounts = ROUTER.swapTokensForExactETH(debt, maxETHAmount, path, address(this), block.timestamp);
        IBankBNB(bankBNB).repayTreasuryDebt{ value: amounts[1] }();
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

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../interfaces/IUniswapV2Pair.sol";
import "../interfaces/IUniswapV2Router02.sol";
import "./IWETH.sol";

contract ZapETH is OwnableUpgradeable {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    /* ========== CONSTANT VARIABLES ========== */

    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address private constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address private constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    IUniswapV2Router02 private constant ROUTER = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    /* ========== STATE VARIABLES ========== */

    mapping(address => bool) private notLP;
    mapping(address => address) private routePairAddresses;
    address[] public tokens;

    /* ========== INITIALIZER ========== */

    function initialize() external initializer {
        __Ownable_init();
        require(owner() != address(0), "ZapETH: owner must be set");

        setNotLP(WETH);
        setNotLP(USDT);
        setNotLP(USDC);
        setNotLP(DAI);
    }

    receive() external payable {}

    /* ========== View Functions ========== */

    function isLP(address _address) public view returns (bool) {
        return !notLP[_address];
    }

    function routePair(address _address) external view returns(address) {
        return routePairAddresses[_address];
    }

    /* ========== External Functions ========== */

    function zapInToken(address _from, uint amount, address _to) external {
        IERC20(_from).safeTransferFrom(msg.sender, address(this), amount);
        _approveTokenIfNeeded(_from);

        if (isLP(_to)) {
            IUniswapV2Pair pair = IUniswapV2Pair(_to);
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
                uint ethAmount = _swapTokenForETH(_from, amount, address(this));
                _swapETHToLP(_to, ethAmount, msg.sender);
            }
        } else {
            _swap(_from, amount, _to, msg.sender);
        }
    }

    function zapIn(address _to) external payable {
        _swapETHToLP(_to, msg.value, msg.sender);
    }

    function zapOut(address _from, uint amount) external {
        IERC20(_from).safeTransferFrom(msg.sender, address(this), amount);
        _approveTokenIfNeeded(_from);

        if (!isLP(_from)) {
            _swapTokenForETH(_from, amount, msg.sender);
        } else {
            IUniswapV2Pair pair = IUniswapV2Pair(_from);
            address token0 = pair.token0();
            address token1 = pair.token1();
            if (token0 == WETH || token1 == WETH) {
                ROUTER.removeLiquidityETH(token0 != WETH ? token0 : token1, amount, 0, 0, msg.sender, block.timestamp);
            } else {
                ROUTER.removeLiquidity(token0, token1, amount, 0, 0, msg.sender, block.timestamp);
            }
        }
    }

    /* ========== Private Functions ========== */

    function _approveTokenIfNeeded(address token) private {
        if (IERC20(token).allowance(address(this), address(ROUTER)) == 0) {
            IERC20(token).safeApprove(address(ROUTER), uint(~0));
        }
    }

    function _swapETHToLP(address lp, uint amount, address receiver) private {
        if (!isLP(lp)) {
            _swapETHForToken(lp, amount, receiver);
        } else {
            // lp
            IUniswapV2Pair pair = IUniswapV2Pair(lp);
            address token0 = pair.token0();
            address token1 = pair.token1();
            if (token0 == WETH || token1 == WETH) {
                address token = token0 == WETH ? token1 : token0;
                uint swapValue = amount.div(2);
                uint tokenAmount = _swapETHForToken(token, swapValue, address(this));

                _approveTokenIfNeeded(token);
                ROUTER.addLiquidityETH{value : amount.sub(swapValue)}(token, tokenAmount, 0, 0, receiver, block.timestamp);
            } else {
                uint swapValue = amount.div(2);
                uint token0Amount = _swapETHForToken(token0, swapValue, address(this));
                uint token1Amount = _swapETHForToken(token1, amount.sub(swapValue), address(this));

                _approveTokenIfNeeded(token0);
                _approveTokenIfNeeded(token1);
                ROUTER.addLiquidity(token0, token1, token0Amount, token1Amount, 0, 0, receiver, block.timestamp);
            }
        }
    }

    function _swapETHForToken(address token, uint value, address receiver) private returns (uint) {
        address[] memory path;

        if (routePairAddresses[token] != address(0)) {
            path = new address[](3);
            path[0] = WETH;
            path[1] = routePairAddresses[token];
            path[2] = token;
        } else {
            path = new address[](2);
            path[0] = WETH;
            path[1] = token;
        }

        uint[] memory amounts = ROUTER.swapExactETHForTokens{value : value}(0, path, receiver, block.timestamp);
        return amounts[amounts.length - 1];
    }

    function _swapTokenForETH(address token, uint amount, address receiver) private returns (uint) {
        address[] memory path;
        if (routePairAddresses[token] != address(0)) {
            path = new address[](3);
            path[0] = token;
            path[1] = routePairAddresses[token];
            path[2] = WETH;
        } else {
            path = new address[](2);
            path[0] = token;
            path[1] = WETH;
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
        if (intermediate != address(0) && (_from == WETH || _to == WETH)) {
            // [WETH, BUSD, VAI] or [VAI, BUSD, WETH]
            path = new address[](3);
            path[0] = _from;
            path[1] = intermediate;
            path[2] = _to;
        } else if (intermediate != address(0) && (_from == intermediate || _to == intermediate)) {
            // [VAI, BUSD] or [BUSD, VAI]
            path = new address[](2);
            path[0] = _from;
            path[1] = _to;
        } else if (intermediate != address(0) && routePairAddresses[_from] == routePairAddresses[_to]) {
            // [VAI, DAI] or [VAI, USDC]
            path = new address[](3);
            path[0] = _from;
            path[1] = intermediate;
            path[2] = _to;
        } else if (routePairAddresses[_from] != address(0) && routePairAddresses[_from] != address(0) && routePairAddresses[_from] != routePairAddresses[_to]) {
            // routePairAddresses[xToken] = xRoute
            // [VAI, BUSD, WETH, xRoute, xToken]
            path = new address[](5);
            path[0] = _from;
            path[1] = routePairAddresses[_from];
            path[2] = WETH;
            path[3] = routePairAddresses[_to];
            path[4] = _to;
        } else if (intermediate != address(0) && routePairAddresses[_from] != address(0)) {
            // [VAI, BUSD, WETH, BUNNY]
            path = new address[](4);
            path[0] = _from;
            path[1] = intermediate;
            path[2] = WETH;
            path[3] = _to;
        } else if (intermediate != address(0) && routePairAddresses[_to] != address(0)) {
            // [BUNNY, WETH, BUSD, VAI]
            path = new address[](4);
            path[0] = _from;
            path[1] = WETH;
            path[2] = intermediate;
            path[3] = _to;
        } else if (_from == WETH || _to == WETH) {
            // [WETH, BUNNY] or [BUNNY, WETH]
            path = new address[](2);
            path[0] = _from;
            path[1] = _to;
        } else {
            // [USDT, BUNNY] or [BUNNY, USDT]
            path = new address[](3);
            path[0] = _from;
            path[1] = WETH;
            path[2] = _to;
        }

        uint[] memory amounts = ROUTER.swapExactTokensForTokens(amount, 0, path, receiver, block.timestamp);
        return amounts[amounts.length - 1];
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setRoutePairAddress(address asset, address route) external onlyOwner {
        routePairAddresses[asset] = route;
    }

    function setNotLP(address token) public onlyOwner {
        bool needPush = notLP[token] == false;
        notLP[token] = true;
        if (needPush) {
            tokens.push(token);
        }
    }

    function removeToken(uint i) external onlyOwner {
        address token = tokens[i];
        notLP[token] = false;
        tokens[i] = tokens[tokens.length - 1];
        tokens.pop();
    }

    function sweep() external onlyOwner {
        for (uint i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            if (token == address(0)) continue;
            uint amount = IERC20(token).balanceOf(address(this));
            if (amount > 0) {
                if (token == WETH) {
                    IWETH(token).withdraw(amount);
                } else {
                    _swapTokenForETH(token, amount, owner());
                }
            }
        }

        uint balance = address(this).balance;
        if (balance > 0) {
            payable(owner()).transfer(balance);
        }
    }

    function withdraw(address token) external onlyOwner {
        if (token == address(0)) {
            payable(owner()).transfer(address(this).balance);
            return;
        }

        IERC20(token).transfer(owner(), IERC20(token).balanceOf(address(this)));
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

interface IWETH {
    function deposit() external;
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
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../../library/legacy/Pausable.sol";
import "../../../interfaces/IPancakeRouter02.sol";
import "./IVenusDistribution.sol";
import "./IVBNB.sol";

import "../../../library/SafeToken.sol";

contract StrategyVBNB is ReentrancyGuard, Pausable {
    using SafeToken for address;
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address private constant vBNB = 0xA07c5b74C9B40447a954e1466938b865b6BBea36;
    address private constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address private constant XVS = 0xcF6BB5389c92Bdda8a3747Ddb454cB7a64626C63;
    address private constant VENUS_UNITROLLER = 0xfD36E2c2a6789Db23113685031d7F16329158384;
    address private constant PANCAKESWAP_ROUTER = 0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F;

    address private constant KEEPER = 0x793074D9799DC3c6039F8056F1Ba884a73462051;

    address public bankBNB;
    uint256 public sharesTotal;

    /**
     * @dev Variables that can be changed to config profitability and risk:
     * {borrowRate}          - What % of our collateral do we borrow per leverage level.
     * {borrowDepth}         - How many levels of leverage do we take.
     * {BORROW_RATE_MAX}     - A limit on how much we can push borrow risk.
     * {BORROW_DEPTH_MAX}    - A limit on how many steps we can leverage.
     */
    uint256 public borrowRate;
    uint256 public borrowDepth;
    uint256 public constant BORROW_RATE_MAX = 595;
    uint256 public constant BORROW_RATE_MAX_HARD = 599;
    uint256 public constant BORROW_DEPTH_MAX = 6;

    uint256 public supplyBal; // Cached want supplied to venus
    uint256 public borrowBal; // Cached want borrowed from venus
    uint256 public supplyBalTargeted; // Cached targeted want supplied to venus to achieve desired leverage
    uint256 public supplyBalMin;

    modifier onlyBank {
        require(msg.sender == bankBNB, "StrategyVBNB: not bank");
        _;
    }

    modifier onlyKeeper {
        require(msg.sender == KEEPER || msg.sender == owner(), "StrategyVBNB: not keeper");
        _;
    }

    receive() payable external {}

    constructor(address _bankBNB) public {
        bankBNB = _bankBNB;

        IERC20(XVS).safeApprove(PANCAKESWAP_ROUTER, uint256(-1));

        address[] memory venusMarkets = new address[](1);
        venusMarkets[0] = vBNB;
        IVenusDistribution(VENUS_UNITROLLER).enterMarkets(venusMarkets);

        borrowRate = 585;
        borrowDepth = 3;
    }

    /* ========== VIEW FUNCTIONS ========== */

    function wantLockedTotal() public view returns (uint256) {
        return wantLockedInHere().add(supplyBal).sub(borrowBal);
    }

    function wantLockedInHere() public view returns (uint256) {
        return address(this).balance;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /// @dev Updates the risk profile and rebalances the vault funds accordingly.
    /// @param _borrowRate percent to borrow on each leverage level.
    /// @param _borrowDepth how many levels to leverage the funds.
    function rebalance(uint256 _borrowRate, uint256 _borrowDepth) external onlyOwner {
        require(_borrowRate <= BORROW_RATE_MAX, "!rate");
        require(_borrowDepth <= BORROW_DEPTH_MAX, "!depth");

        _deleverage(false, uint256(-1)); // deleverage all supplied want tokens
        borrowRate = _borrowRate;
        borrowDepth = _borrowDepth;
        _farm(true);
    }

    function harvest() external notPaused onlyKeeper {
        _harvest();
    }

    /**
     * @dev Pauses the strat.
     */
    function pause() external onlyOwner {
        paused = true;
        lastPauseTime = block.timestamp;

        IERC20(XVS).safeApprove(PANCAKESWAP_ROUTER, 0);
    }

    /**
     * @dev Unpauses the strat.
     */
    function unpause() external onlyOwner {
        paused = false;

        IERC20(XVS).safeApprove(PANCAKESWAP_ROUTER, uint256(-1));
    }

    function recoverToken(address _token, uint256 _amount, address _to) public onlyOwner {
        require(_token != XVS, "!safe");
        require(_token != vBNB, "!safe");

        IERC20(_token).safeTransfer(_to, _amount);
    }

    // ---------- VAULT FUNCTIONS ----------

    function deposit() public payable nonReentrant notPaused {
        _farm(true);
    }

    function withdraw(address account, uint256 _wantAmt) external onlyBank nonReentrant {
        uint256 wantBal = address(this).balance;
        if (wantBal < _wantAmt) {
            _deleverage(true, _wantAmt.sub(wantBal));
            wantBal = address(this).balance;
        }

        if (wantBal < _wantAmt) {
            _wantAmt = wantBal;
        }

        SafeToken.safeTransferETH(account, _wantAmt);

        if(address(this).balance > 1 szabo) {
            _farm(true);
        }
    }

    function migrate(address payable to) external onlyBank {
        _harvest();
        _deleverage(false, uint(-1));
        StrategyVBNB(to).deposit{ value: address(this).balance }();
    }

    // ---------- PUBLIC ----------
    /**
    * @dev Redeem to the desired leverage amount, then use it to repay borrow.
    * If already over leverage, redeem max amt redeemable, then use it to repay borrow.
    */
    function deleverageOnce() public {
        updateBalance(); // Updates borrowBal & supplyBal & supplyBalTargeted & supplyBalMin

        if (supplyBal <= supplyBalTargeted) {
            _removeSupply(supplyBal.sub(supplyBalMin));
        } else {
            _removeSupply(supplyBal.sub(supplyBalTargeted));
        }

        _repayBorrow(address(this).balance);

        updateBalance(); // Updates borrowBal & supplyBal & supplyBalTargeted & supplyBalMin
    }

    /**
     * @dev Redeem the max possible, use it to repay borrow
     */
    function deleverageUntilNotOverLevered() public {
        // updateBalance(); // To be more accurate, call updateBalance() first to cater for changes due to interest rates

        // If borrowRate slips below targeted borrowRate, withdraw the max amt first.
        // Further actual deleveraging will take place later on.
        // (This can happen in when net interest rate < 0, and supplied balance falls below targeted.)
        while (supplyBal > 0 && supplyBal <= supplyBalTargeted) {
            deleverageOnce();
        }
    }

    function farm(bool _withLev) public nonReentrant {
        _farm(_withLev);
    }

    /**
    * @dev Updates want locked in Venus after interest is accrued to this very block.
    * To be called before sensitive operations.
    */
    function updateBalance() public {
        supplyBal = IVBNB(vBNB).balanceOfUnderlying(address(this)); // a payable function because of accrueInterest()
        borrowBal = IVBNB(vBNB).borrowBalanceCurrent(address(this));
        supplyBalTargeted = borrowBal.mul(1000).div(borrowRate);
        supplyBalMin = borrowBal.mul(1000).div(BORROW_RATE_MAX_HARD);
    }

    // ---------- PRIVATE ----------
    function _farm(bool _withLev) private {
        uint balance = address(this).balance;
        if (balance > 1 szabo) {
            _leverage(address(this).balance, _withLev);
            updateBalance();
        }

        deleverageUntilNotOverLevered(); // It is possible to still be over-levered after depositing.
    }

    function _harvest() private {
        IVenusDistribution(VENUS_UNITROLLER).claimVenus(address(this));

        uint256 earnedAmt = IERC20(XVS).balanceOf(address(this));
        address[] memory path = new address[](2);
        path[0] = XVS;
        path[1] = WBNB;
        IPancakeRouter02(PANCAKESWAP_ROUTER).swapExactTokensForETH(
            earnedAmt,
            0,
            path,
            address(this),
            block.timestamp
        );

        _farm(false); // Supply wantToken without leverage, to cater for net -ve interest rates.
    }

    /**
     * @dev Repeatedly supplies and borrows bnb following the configured {borrowRate} and {borrowDepth}
     * into the vToken contract.
     */
    function _leverage(uint256 _amount, bool _withLev) private {
        if (_withLev) {
            for (uint256 i = 0; i < borrowDepth; i++) {
                _supply(_amount);
                _amount = _amount.mul(borrowRate).div(1000);
                _borrow(_amount);
            }
        }

        _supply(_amount); // Supply remaining want that was last borrowed.
    }

    /**
     * @dev Incrementally alternates between paying part of the debt and withdrawing part of the supplied
     * collateral. Continues to do this untill all want tokens is withdrawn. For partial deleveraging,
     * this continues until at least _minAmt of want tokens is reached.
     */

    function _deleverage(bool _delevPartial, uint256 _minAmt) private {
        updateBalance(); // Updates borrowBal & supplyBal & supplyBalTargeted & supplyBalMin

        deleverageUntilNotOverLevered();

        _removeSupply(supplyBal.sub(supplyBalMin));

        uint256 wantBal = wantLockedInHere();

        // Recursively repay borrowed + remove more from supplied
        while (wantBal < borrowBal) {
            // If only partially deleveraging, when sufficiently deleveraged, do not repay anymore
            if (_delevPartial && wantBal >= _minAmt) {
                return;
            }

            _repayBorrow(wantBal);

            updateBalance(); // Updates borrowBal & supplyBal & supplyBalTargeted & supplyBalMin

            _removeSupply(supplyBal.sub(supplyBalMin));

            wantBal = wantLockedInHere();
        }

        // If only partially deleveraging, when sufficiently deleveraged, do not repay
        if (_delevPartial && wantBal >= _minAmt) {
            return;
        }

        // Make a final repayment of borrowed
        _repayBorrow(borrowBal);

        // remove all supplied
        uint256 vTokenBal = IERC20(vBNB).balanceOf(address(this));
        IVBNB(vBNB).redeem(vTokenBal);
    }

    function _supply(uint256 _amount) private {
        IVBNB(vBNB).mint{ value: _amount }();
    }

    function _removeSupply(uint256 amount) private {
        IVBNB(vBNB).redeemUnderlying(amount);
    }

    function _borrow(uint256 _amount) private {
        IVBNB(vBNB).borrow(_amount);
    }

    function _repayBorrow(uint256 _amount) private {
        IVBNB(vBNB).repayBorrow{value: _amount}();
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

import "@pancakeswap/pancake-swap-lib/contracts/access/Ownable.sol";


abstract contract Pausable is Ownable {
    uint public lastPauseTime;
    bool public paused;

    event PauseChanged(bool isPaused);

    modifier notPaused {
        require(!paused, "This action cannot be performed while the contract is paused");
        _;
    }

    constructor() internal {
        require(owner() != address(0), "Owner must be set");
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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IVBNB {
    function mint() external payable;

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function borrow(uint256 borrowAmount) external returns (uint256);

    function repayBorrow() external payable;

    // function getAccountSnapshot(address account)
    //     external
    //     view
    //     returns (
    //         uint256,
    //         uint256,
    //         uint256,
    //         uint256
    //     );

    function balanceOfUnderlying(address owner) external returns (uint256);

    function borrowBalanceCurrent(address account) external returns (uint256);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol";

import "../../../library/bep20/BEP20Upgradeable.sol";
import "../../../library/SafeToken.sol";
import "../../../library/Whitelist.sol";
import "../../interface/IBankBNB.sol";
import "./config/BankConfig.sol";
import "../venus/IStrategyVBNB.sol";
import "../../../interfaces/IBunnyChef.sol";


contract BankBNB is IBankBNB, BEP20Upgradeable, ReentrancyGuardUpgradeable, Whitelist {
    using SafeToken for address;
    using SafeBEP20 for IBEP20;

    /* ========== STATE VARIABLES ========== */

    BankConfig public config;
    IBunnyChef public bunnyChef;

    uint public glbDebtShare;
    uint public glbDebtVal;
    uint public reservedBNB;
    uint public lastAccrueTime;

    address public bankETH;
    address public strategyVBNB;

    mapping(address => uint) private _principals;
    mapping(address => mapping(address => uint)) private _debtShares;

    /* ========== EVENTS ========== */

    event DebtShareAdded(address indexed pool, address indexed borrower, uint debtShare);
    event DebtShareRemoved(address indexed pool, address indexed borrower, uint debtShare);
    event DebtShareHandedOver(address indexed pool, address indexed borrower, address indexed handOverTo, uint debtShare);

    /* ========== MODIFIERS ========== */

    modifier accrue {
        IStrategyVBNB(strategyVBNB).updateBalance();
        if (now > lastAccrueTime) {
            uint interest = pendingInterest();
            glbDebtVal = glbDebtVal.add(interest);
            reservedBNB = reservedBNB.add(interest.mul(config.getReservePoolBps()).div(10000));
            lastAccrueTime = now;
        }
        _;
        IStrategyVBNB(strategyVBNB).updateBalance();
    }

    modifier onlyBankETH {
        require(msg.sender == bankETH, "BankBNB: caller is not the bankETH");
        _;
    }

    receive() payable external {}

    /* ========== INITIALIZER ========== */

    function initialize(string memory name, string memory symbol, uint8 decimals) external initializer {
        __BEP20__init(name, symbol, decimals);
        __ReentrancyGuard_init();
        __Whitelist_init();

        lastAccrueTime = block.timestamp;
    }

    /* ========== VIEW FUNCTIONS ========== */

    /// @dev Return the pending interest that will be accrued in the next call.
    function pendingInterest() public view returns (uint) {
        if (now > lastAccrueTime) {
            uint timePast = block.timestamp.sub(lastAccrueTime);
            uint ratePerSec = config.getInterestRate(glbDebtVal, totalLocked());
            return ratePerSec.mul(glbDebtVal).mul(timePast).div(1e18);
        } else {
            return 0;
        }
    }

    function priceInBNB() public view override returns (uint) {
        if (totalSupply() == 0) return 0;
        return totalLiquidity().mul(1e18).div(totalSupply());
    }

    /// @dev Return the total BNB entitled to the token holders. Be careful of unaccrued interests.
    function totalLiquidity() public view returns (uint) {
        return totalLocked().add(glbDebtVal).sub(reservedBNB);
    }

    function totalLocked() public view returns (uint) {
        return IStrategyVBNB(strategyVBNB).wantLockedTotal();
    }

    function debtValOf(address pool, address account) external view override returns (uint) {
        return debtShareToVal(debtShareOf(pool, account));
    }

    function debtValOfBankETH() external view returns (uint) {
        return debtShareToVal(debtShareOf(_unifiedDebtShareKey(), bankETH));
    }

    function debtShareOf(address pool, address account) public view override returns (uint) {
        return _debtShares[pool][account];
    }

    function principalOf(address account) public view returns (uint) {
        return _principals[account];
    }

    /// @dev Return the BNB debt value given the debt share. Be careful of unaccrued interests.
    /// @param debtShare The debt share to be converted.
    function debtShareToVal(uint debtShare) public view override returns (uint) {
        if (glbDebtShare == 0) return debtShare;
        // When there's no share, 1 share = 1 val.
        return debtShare.mul(glbDebtVal).div(glbDebtShare);
    }

    /// @dev Return the debt share for the given debt value. Be careful of unaccrued interests.
    /// @param debtVal The debt value to be converted.
    function debtValToShare(uint debtVal) public view override returns (uint) {
        if (glbDebtShare == 0) return debtVal;
        // When there's no share, 1 share = 1 val.
        return debtVal.mul(glbDebtShare).div(glbDebtVal);
    }

    function getUtilizationInfo() external view override returns (uint liquidity, uint utilized) {
        liquidity = totalLiquidity();
        utilized = glbDebtVal;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function deposit() external payable accrue nonReentrant {
        uint liquidity = totalLiquidity();
        uint share = liquidity == 0 ? msg.value : msg.value.mul(totalSupply()).div(liquidity);
        _principals[msg.sender] = _principals[msg.sender].add(msg.value);
        _mint(msg.sender, share);

        uint balance = address(this).balance;
        if (balance > 0) {
            IStrategyVBNB(strategyVBNB).deposit{value : balance}();
        }

        bunnyChef.notifyDeposited(msg.sender, share);
    }

    function withdraw(uint share) public accrue nonReentrant {
        if (totalSupply() == 0) return;

        uint bnbAvailable = totalLiquidity() - glbDebtVal;
        uint bnbAmount = share.mul(totalLiquidity()).div(totalSupply());
        require(bnbAvailable >= bnbAmount, "BankBNB: Not enough balance to withdraw");

        bunnyChef.notifyWithdrawn(msg.sender, share);

        _burn(msg.sender, share);
        _principals[msg.sender] = balanceOf(msg.sender).mul(totalLiquidity()).div(totalSupply());
        IStrategyVBNB(strategyVBNB).withdraw(msg.sender, bnbAmount);
    }

    function withdrawAll() external {
        uint share = balanceOf(msg.sender);
        if (share > 0) {
            withdraw(share);
        }
        getReward();
    }

    function getReward() public nonReentrant {
        bunnyChef.safeBunnyTransfer(msg.sender);
    }

    function accruedDebtValOf(address pool, address account) external override accrue returns (uint) {
        return debtShareToVal(debtShareOf(pool, account));
    }

    /* ========== RESTRICTED FUNCTIONS - CONFIGURATION ========== */

    function setBankETH(address newBankETH) external onlyOwner {
        require(newBankETH != address(0), "BankBNB: invalid bankBNB address");
        require(bankETH == address(0), "BankBNB: bankETH is already set");
        bankETH = newBankETH;
    }

    function setStrategyVBNB(address newStrategyVBNB) external onlyOwner {
        require(newStrategyVBNB != address(0), "BankBNB: invalid strategyVBNB address");
        if (strategyVBNB != address(0)) {
            IStrategyVBNB(strategyVBNB).migrate(payable(newStrategyVBNB));
        }
        strategyVBNB = newStrategyVBNB;
    }

    function updateConfig(address newConfig) external onlyOwner {
        require(newConfig != address(0), "BankBNB: invalid bankConfig address");
        config = BankConfig(newConfig);
    }

    function setBunnyChef(IBunnyChef _chef) public onlyOwner {
        require(address(bunnyChef) == address(0), "BankBNB: setBunnyChef only once");
        bunnyChef = IBunnyChef(_chef);
    }

    /* ========== RESTRICTED FUNCTIONS - WHITELISTED ========== */

    function borrow(address pool, address borrower, uint debtVal) external override accrue onlyWhitelisted returns (uint debtSharesOfBorrower) {
        debtVal = Math.min(debtVal, totalLocked());
        uint debtShare = debtValToShare(debtVal);

        _debtShares[pool][borrower] = _debtShares[pool][borrower].add(debtShare);
        glbDebtShare = glbDebtShare.add(debtShare);
        glbDebtVal = glbDebtVal.add(debtVal);
        emit DebtShareAdded(pool, borrower, debtShare);
        IStrategyVBNB(strategyVBNB).withdraw(msg.sender, debtVal);
        return debtVal;
    }

    function repay(address pool, address borrower) public payable override accrue onlyWhitelisted returns (uint debtSharesOfBorrower) {
        uint debtShare = Math.min(debtValToShare(msg.value), _debtShares[pool][borrower]);
        if (debtShare > 0) {
            uint debtVal = debtShareToVal(debtShare);
            _debtShares[pool][borrower] = _debtShares[pool][borrower].sub(debtShare);
            glbDebtShare = glbDebtShare.sub(debtShare);
            glbDebtVal = glbDebtVal.sub(debtVal);
            emit DebtShareRemoved(pool, borrower, debtShare);
        }

        uint balance = address(this).balance;
        if (balance > 0) {
            IStrategyVBNB(strategyVBNB).deposit{value : balance}();
        }

        return _debtShares[pool][borrower];
    }

    /* ========== RESTRICTED FUNCTIONS - BANKING ========== */

    function handOverDebtToTreasury(address pool, address borrower) external override accrue onlyBankETH returns (uint debtSharesOfBorrower) {
        uint debtShare = _debtShares[pool][borrower];
        _debtShares[pool][borrower] = 0;
        _debtShares[_unifiedDebtShareKey()][bankETH] = _debtShares[_unifiedDebtShareKey()][bankETH].add(debtShare);

        if (debtShare > 0) {
            emit DebtShareHandedOver(pool, borrower, msg.sender, debtShare);
        }
        return debtShare;
    }

    function repayTreasuryDebt() external payable override accrue onlyBankETH returns (uint debtSharesOfBorrower) {
        return repay(_unifiedDebtShareKey(), bankETH);
    }

    /* ========== RESTRICTED FUNCTIONS - OPERATION ========== */

    function withdrawReservedBNB(address to, uint value) external onlyOwner nonReentrant {
        require(reservedBNB >= value, "BankBNB: value must note exceed reservedBNB");
        reservedBNB = reservedBNB.sub(value);
        IStrategyVBNB(strategyVBNB).withdraw(to, value);
    }

    function distributeReservedBNBToHolders(uint value) external onlyOwner {
        require(reservedBNB >= value, "BankBNB: value must note exceed reservedBNB");
        reservedBNB = reservedBNB.sub(value);
    }

    function recoverToken(address token, address to, uint value) external onlyOwner {
        token.safeTransfer(to, value);
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _unifiedDebtShareKey() private view returns (address) {
        return address(this);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";

abstract contract BEP20Upgradeable is IBEP20, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    uint256[50] private __gap;

    constructor() public {
    }

    /**
     * @dev sets initials supply and the owner
     */
    function __BEP20__init(string memory name, string memory symbol, uint8 decimals) internal initializer {
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
pragma solidity ^0.6.12;

interface BankConfig {
    /// @dev Return the interest rate per second, using 1e18 as denom.
    function getInterestRate(uint256 debt, uint256 floating) external view returns (uint256);

    /// @dev Return the bps rate for reserve pool.
    function getReservePoolBps() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IStrategyVBNB {
    function supplyBal() external view returns (uint);
    function borrowBal() external view returns (uint);
    function wantLockedTotal() external view returns (uint);

    function harvest() external;
    function migrate(address payable to) external;
    function updateBalance() external;
    function deposit() external payable;
    function withdraw(address userAddress, uint256 wantAmt) external;
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
library SafeMathUpgradeable {
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
        return sub(a, b, "SafeMath: subtraction overflow");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
        return mod(a, b, "SafeMath: modulo by zero");
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@pancakeswap/pancake-swap-lib/contracts/access/Ownable.sol";
import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";
import "./BankConfig.sol";


interface InterestModel {
    /// @dev Return the interest rate per second, using 1e18 as denom.
    function getInterestRate(uint256 debt, uint256 floating) external view returns (uint256);
}

contract ConfigurableInterestBankConfig is BankConfig, Ownable {
    /// The portion of interests allocated to the reserve pool.
    uint256 public override getReservePoolBps;

    /// Interest rate model
    InterestModel public interestModel;

    constructor(uint256 _reservePoolBps, InterestModel _interestModel) public {
        setParams(_reservePoolBps, _interestModel);
    }

    /// @dev Set all the basic parameters. Must only be called by the owner.
    /// @param _reservePoolBps The new interests allocated to the reserve pool value.
    /// @param _interestModel The new interest rate model contract.
    function setParams(
        uint256 _reservePoolBps,
        InterestModel _interestModel
    ) public onlyOwner {
        getReservePoolBps = _reservePoolBps;
        interestModel = _interestModel;
    }

    /// @dev Return the interest rate per second, using 1e18 as denom.
    function getInterestRate(uint256 debt, uint256 floating) external view override returns (uint256) {
        return interestModel.getInterestRate(debt, floating);
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

import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol";
import "@pancakeswap/pancake-swap-lib/contracts/access/Ownable.sol";

import "../interfaces/IPancakePair.sol";
import "../interfaces/IPancakeRouter02.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract ZapBSC is OwnableUpgradeable {
    using SafeMath for uint;
    using SafeBEP20 for IBEP20;

    /* ========== CONSTANT VARIABLES ========== */

    address private constant CAKE = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    address private constant BUNNY = 0xC9849E6fdB743d08fAeE3E34dd2D1bc69EA11a51;
    address private constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address private constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address private constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    address private constant DAI = 0x1AF3F329e8BE154074D8769D1FFa4eE058B1DBc3;
    address private constant USDC = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;
    address private constant VAI = 0x4BD17003473389A42DAF6a0a729f6Fdb328BbBd7;
    address private constant BTCB = 0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c;
    address private constant ETH = 0x2170Ed0880ac9A755fd29B2688956BD959F933F8;

    IPancakeRouter02 private constant ROUTER = IPancakeRouter02(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F);

    /* ========== STATE VARIABLES ========== */

    mapping(address => bool) private notFlip;
    mapping(address => address) private routePairAddresses;
    address[] public tokens;

    /* ========== INITIALIZER ========== */

    function initialize() external initializer {
        __Ownable_init();
        require(owner() != address(0), "Zap: owner must be set");

        setNotFlip(CAKE);
        setNotFlip(BUNNY);
        setNotFlip(WBNB);
        setNotFlip(BUSD);
        setNotFlip(USDT);
        setNotFlip(DAI);
        setNotFlip(USDC);
        setNotFlip(VAI);
        setNotFlip(BTCB);
        setNotFlip(ETH);
    }

    receive() external payable {}


    /* ========== View Functions ========== */

    function isFlip(address _address) public view returns (bool) {
        return !notFlip[_address];
    }

    function routePair(address _address) external view returns(address) {
        return routePairAddresses[_address];
    }

    /* ========== External Functions ========== */

    function zapInToken(address _from, uint amount, address _to) external {
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
                uint bnbAmount = _swapTokenForBNB(_from, amount, address(this));
                _swapBNBToFlip(_to, bnbAmount, msg.sender);
            }
        } else {
            _swap(_from, amount, _to, msg.sender);
        }
    }

    function zapIn(address _to) external payable {
        _swapBNBToFlip(_to, msg.value, msg.sender);
    }

    function zapOut(address _from, uint amount) external {
        IBEP20(_from).safeTransferFrom(msg.sender, address(this), amount);
        _approveTokenIfNeeded(_from);

        if (!isFlip(_from)) {
            _swapTokenForBNB(_from, amount, msg.sender);
        } else {
            IPancakePair pair = IPancakePair(_from);
            address token0 = pair.token0();
            address token1 = pair.token1();
            if (token0 == WBNB || token1 == WBNB) {
                ROUTER.removeLiquidityETH(token0 != WBNB ? token0 : token1, amount, 0, 0, msg.sender, block.timestamp);
            } else {
                ROUTER.removeLiquidity(token0, token1, amount, 0, 0, msg.sender, block.timestamp);
            }
        }
    }

    /* ========== Private Functions ========== */

    function _approveTokenIfNeeded(address token) private {
        if (IBEP20(token).allowance(address(this), address(ROUTER)) == 0) {
            IBEP20(token).safeApprove(address(ROUTER), uint(~0));
        }
    }

    function _swapBNBToFlip(address flip, uint amount, address receiver) private {
        if (!isFlip(flip)) {
            _swapBNBForToken(flip, amount, receiver);
        } else {
            // flip
            IPancakePair pair = IPancakePair(flip);
            address token0 = pair.token0();
            address token1 = pair.token1();
            if (token0 == WBNB || token1 == WBNB) {
                address token = token0 == WBNB ? token1 : token0;
                uint swapValue = amount.div(2);
                uint tokenAmount = _swapBNBForToken(token, swapValue, address(this));

                _approveTokenIfNeeded(token);
                ROUTER.addLiquidityETH{value : amount.sub(swapValue)}(token, tokenAmount, 0, 0, receiver, block.timestamp);
            } else {
                uint swapValue = amount.div(2);
                uint token0Amount = _swapBNBForToken(token0, swapValue, address(this));
                uint token1Amount = _swapBNBForToken(token1, amount.sub(swapValue), address(this));

                _approveTokenIfNeeded(token0);
                _approveTokenIfNeeded(token1);
                ROUTER.addLiquidity(token0, token1, token0Amount, token1Amount, 0, 0, receiver, block.timestamp);
            }
        }
    }

    function _swapBNBForToken(address token, uint value, address receiver) private returns (uint) {
        address[] memory path;

        if (routePairAddresses[token] != address(0)) {
            path = new address[](3);
            path[0] = WBNB;
            path[1] = routePairAddresses[token];
            path[2] = token;
        } else {
            path = new address[](2);
            path[0] = WBNB;
            path[1] = token;
        }

        uint[] memory amounts = ROUTER.swapExactETHForTokens{value : value}(0, path, receiver, block.timestamp);
        return amounts[amounts.length - 1];
    }

    function _swapTokenForBNB(address token, uint amount, address receiver) private returns (uint) {
        address[] memory path;
        if (routePairAddresses[token] != address(0)) {
            path = new address[](3);
            path[0] = token;
            path[1] = routePairAddresses[token];
            path[2] = WBNB;
        } else {
            path = new address[](2);
            path[0] = token;
            path[1] = WBNB;
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
        if (intermediate != address(0) && (_from == WBNB || _to == WBNB)) {
            // [WBNB, BUSD, VAI] or [VAI, BUSD, WBNB]
            path = new address[](3);
            path[0] = _from;
            path[1] = intermediate;
            path[2] = _to;
        } else if (intermediate != address(0) && (_from == intermediate || _to == intermediate)) {
            // [VAI, BUSD] or [BUSD, VAI]
            path = new address[](2);
            path[0] = _from;
            path[1] = _to;
        } else if (intermediate != address(0) && routePairAddresses[_from] == routePairAddresses[_to]) {
            // [VAI, DAI] or [VAI, USDC]
            path = new address[](3);
            path[0] = _from;
            path[1] = intermediate;
            path[2] = _to;
        } else if (routePairAddresses[_from] != address(0) && routePairAddresses[_from] != address(0) && routePairAddresses[_from] != routePairAddresses[_to]) {
            // routePairAddresses[xToken] = xRoute
            // [VAI, BUSD, WBNB, xRoute, xToken]
            path = new address[](5);
            path[0] = _from;
            path[1] = routePairAddresses[_from];
            path[2] = WBNB;
            path[3] = routePairAddresses[_to];
            path[4] = _to;
        } else if (intermediate != address(0) && routePairAddresses[_from] != address(0)) {
            // [VAI, BUSD, WBNB, BUNNY]
            path = new address[](4);
            path[0] = _from;
            path[1] = intermediate;
            path[2] = WBNB;
            path[3] = _to;
        } else if (intermediate != address(0) && routePairAddresses[_to] != address(0)) {
            // [BUNNY, WBNB, BUSD, VAI]
            path = new address[](4);
            path[0] = _from;
            path[1] = WBNB;
            path[2] = intermediate;
            path[3] = _to;
        } else if (_from == WBNB || _to == WBNB) {
            // [WBNB, BUNNY] or [BUNNY, WBNB]
            path = new address[](2);
            path[0] = _from;
            path[1] = _to;
        } else {
            // [USDT, BUNNY] or [BUNNY, USDT]
            path = new address[](3);
            path[0] = _from;
            path[1] = WBNB;
            path[2] = _to;
        }

        uint[] memory amounts = ROUTER.swapExactTokensForTokens(amount, 0, path, receiver, block.timestamp);
        return amounts[amounts.length - 1];
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setRoutePairAddress(address asset, address route) external onlyOwner {
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
                _swapTokenForBNB(token, amount, owner());
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

import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol";

import "../../interfaces/IPancakeRouter02.sol";
import "../../interfaces/IPancakePair.sol";
import "../../interfaces/IPancakeFactory.sol";

abstract contract PancakeSwap {
    using SafeMath for uint;
    using SafeBEP20 for IBEP20;

    IPancakeRouter02 private constant ROUTER = IPancakeRouter02(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F);
    IPancakeFactory private constant factory = IPancakeFactory(0xBCfCcbde45cE874adCB698cC183deBcF17952812);

    address internal constant cake = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    address private constant _bunny = 0xC9849E6fdB743d08fAeE3E34dd2D1bc69EA11a51;
    address private constant _wbnb = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    function bunnyBNBFlipToken() internal view returns(address) {
        return factory.getPair(_bunny, _wbnb);
    }

    function tokenToBunnyBNB(address token, uint amount) internal returns(uint flipAmount) {
        if (token == cake) {
            flipAmount = _cakeToBunnyBNBFlip(amount);
        } else {
            // flip
            flipAmount = _flipToBunnyBNBFlip(token, amount);
        }
    }

    function _cakeToBunnyBNBFlip(uint amount) private returns(uint flipAmount) {
        swapToken(cake, amount.div(2), _bunny);
        swapToken(cake, amount.sub(amount.div(2)), _wbnb);

        flipAmount = generateFlipToken();
    }

    function _flipToBunnyBNBFlip(address token, uint amount) private returns(uint flipAmount) {
        IPancakePair pair = IPancakePair(token);
        address _token0 = pair.token0();
        address _token1 = pair.token1();
        IBEP20(token).safeApprove(address(ROUTER), 0);
        IBEP20(token).safeApprove(address(ROUTER), amount);
        ROUTER.removeLiquidity(_token0, _token1, amount, 0, 0, address(this), block.timestamp);
        if (_token0 == _wbnb) {
            swapToken(_token1, IBEP20(_token1).balanceOf(address(this)), _bunny);
            flipAmount = generateFlipToken();
        } else if (_token1 == _wbnb) {
            swapToken(_token0, IBEP20(_token0).balanceOf(address(this)), _bunny);
            flipAmount = generateFlipToken();
        } else {
            swapToken(_token0, IBEP20(_token0).balanceOf(address(this)), _bunny);
            swapToken(_token1, IBEP20(_token1).balanceOf(address(this)), _wbnb);
            flipAmount = generateFlipToken();
        }
    }

    function swapToken(address _from, uint _amount, address _to) private {
        if (_from == _to) return;

        address[] memory path;
        if (_from == _wbnb || _to == _wbnb) {
            path = new address[](2);
            path[0] = _from;
            path[1] = _to;
        } else {
            path = new address[](3);
            path[0] = _from;
            path[1] = _wbnb;
            path[2] = _to;
        }

        IBEP20(_from).safeApprove(address(ROUTER), 0);
        IBEP20(_from).safeApprove(address(ROUTER), _amount);
        ROUTER.swapExactTokensForTokens(_amount, 0, path, address(this), block.timestamp);
    }

    function generateFlipToken() private returns(uint liquidity) {
        uint amountADesired = IBEP20(_bunny).balanceOf(address(this));
        uint amountBDesired = IBEP20(_wbnb).balanceOf(address(this));

        IBEP20(_bunny).safeApprove(address(ROUTER), 0);
        IBEP20(_bunny).safeApprove(address(ROUTER), amountADesired);
        IBEP20(_wbnb).safeApprove(address(ROUTER), 0);
        IBEP20(_wbnb).safeApprove(address(ROUTER), amountBDesired);

        (,,liquidity) = ROUTER.addLiquidity(_bunny, _wbnb, amountADesired, amountBDesired, 0, 0, address(this), block.timestamp);

        // send dust
        IBEP20(_bunny).transfer(msg.sender, IBEP20(_bunny).balanceOf(address(this)));
        IBEP20(_wbnb).transfer(msg.sender, IBEP20(_wbnb).balanceOf(address(this)));
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

import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../interfaces/IPancakeRouter02.sol";
import "../interfaces/IPancakePair.sol";
import "../interfaces/IPancakeFactory.sol";

abstract contract PancakeSwapV2 is OwnableUpgradeable {
    using SafeMath for uint;
    using SafeBEP20 for IBEP20;

    IPancakeRouter02 private constant ROUTER = IPancakeRouter02(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F);
    IPancakeFactory private constant FACTORY = IPancakeFactory(0xBCfCcbde45cE874adCB698cC183deBcF17952812);

    address internal constant CAKE = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    address internal constant BUNNY = 0xC9849E6fdB743d08fAeE3E34dd2D1bc69EA11a51;
    address internal constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;

    function __PancakeSwapV2_init() internal initializer {
        __Ownable_init();
    }

    function tokenToBunnyBNB(address token, uint amount) internal returns(uint flipAmount) {
        if (token == CAKE) {
            flipAmount = _cakeToBunnyBNBFlip(amount);
        } else if (token == BUNNY) {
            // Burn BUNNY!!
            IBEP20(BUNNY).transfer(DEAD, amount);
            flipAmount = 0;
        } else {
            // flip
            flipAmount = _flipToBunnyBNBFlip(token, amount);
        }
    }

    function _cakeToBunnyBNBFlip(uint amount) private returns(uint flipAmount) {
        swapToken(CAKE, amount.div(2), BUNNY);
        swapToken(CAKE, amount.sub(amount.div(2)), WBNB);

        flipAmount = generateFlipToken();
    }

    function _flipToBunnyBNBFlip(address flip, uint amount) private returns(uint flipAmount) {
        IPancakePair pair = IPancakePair(flip);
        address _token0 = pair.token0();
        address _token1 = pair.token1();
        _approveTokenIfNeeded(flip);
        ROUTER.removeLiquidity(_token0, _token1, amount, 0, 0, address(this), block.timestamp);
        if (_token0 == WBNB) {
            swapToken(_token1, IBEP20(_token1).balanceOf(address(this)), BUNNY);
            flipAmount = generateFlipToken();
        } else if (_token1 == WBNB) {
            swapToken(_token0, IBEP20(_token0).balanceOf(address(this)), BUNNY);
            flipAmount = generateFlipToken();
        } else {
            swapToken(_token0, IBEP20(_token0).balanceOf(address(this)), BUNNY);
            swapToken(_token1, IBEP20(_token1).balanceOf(address(this)), WBNB);
            flipAmount = generateFlipToken();
        }
    }

    function swapToken(address _from, uint _amount, address _to) private {
        if (_from == _to) return;

        address[] memory path;
        if (_from == WBNB || _to == WBNB) {
            path = new address[](2);
            path[0] = _from;
            path[1] = _to;
        } else {
            path = new address[](3);
            path[0] = _from;
            path[1] = WBNB;
            path[2] = _to;
        }
        _approveTokenIfNeeded(_from);
        ROUTER.swapExactTokensForTokens(_amount, 0, path, address(this), block.timestamp);
    }

    function generateFlipToken() private returns(uint liquidity) {
        uint amountADesired = IBEP20(BUNNY).balanceOf(address(this));
        uint amountBDesired = IBEP20(WBNB).balanceOf(address(this));
        _approveTokenIfNeeded(BUNNY);
        _approveTokenIfNeeded(WBNB);

        (,,liquidity) = ROUTER.addLiquidity(BUNNY, WBNB, amountADesired, amountBDesired, 0, 0, address(this), block.timestamp);

        // send dust
        IBEP20(BUNNY).transfer(msg.sender, IBEP20(BUNNY).balanceOf(address(this)));
        IBEP20(WBNB).transfer(msg.sender, IBEP20(WBNB).balanceOf(address(this)));
    }

    function _approveTokenIfNeeded(address token) private {
        if (IBEP20(token).allowance(address(this), address(ROUTER)) == 0) {
            IBEP20(token).safeApprove(address(ROUTER), uint(-1));
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/Math.sol";
import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "../library/legacy/RewardsDistributionRecipient.sol";
import "../library/legacy/Pausable.sol";
import "../interfaces/legacy/IStrategyHelper.sol";
import "../interfaces/IMasterChef.sol";
import "../interfaces/legacy/ICakeVault.sol";
import "../interfaces/IBunnyMinter.sol";
import "../interfaces/legacy/IStrategyLegacy.sol";

contract CakeFlipVaultTester is IStrategyLegacy, RewardsDistributionRecipient, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    /* ========== STATE VARIABLES ========== */
    ICakeVault public rewardsToken;
    IBEP20 public stakingToken;
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public rewardsDuration = 24 hours;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    /* ========== CAKE     ============= */
    address private constant CAKE = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    IMasterChef private constant CAKE_MASTER_CHEF = IMasterChef(0x73feaa1eE314F8c655E354234017bE2193C9E24E);
    uint public poolId;
    address public keeper = 0x793074D9799DC3c6039F8056F1Ba884a73462051;
    mapping (address => uint) public depositedAt;

    /* ========== BUNNY HELPER / MINTER ========= */
    IStrategyHelper public helper = IStrategyHelper(0x154d803C328fFd70ef5df52cb027d82821520ECE);
    IBunnyMinter public minter;


    /* ========== CONSTRUCTOR ========== */

    constructor(uint _pid) public {
        (address _token,,,) = CAKE_MASTER_CHEF.poolInfo(_pid);
        stakingToken = IBEP20(_token);
        stakingToken.safeApprove(address(CAKE_MASTER_CHEF), uint(~0));
        poolId = _pid;

        rewardsDistribution = msg.sender;
        setMinter(IBunnyMinter(0x0B4A714AAf59E46cb1900E3C031017Fd72667EfE));
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

    function withdrawableBalanceOf(address account) override public view returns (uint) {
        return _balances[account];
    }

    // return cakeAmount, bunnyAmount, 0
    function profitOf(address account) override public view returns (uint _usd, uint _bunny, uint _bnb) {
        uint cakeVaultPrice = rewardsToken.priceShare();
        uint _earned = earned(account);
        uint amount = _earned.mul(cakeVaultPrice).div(1e18);

        if (address(minter) != address(0) && minter.isMinter(address(this))) {
            uint performanceFee = minter.performanceFee(amount);
            // cake amount
            _usd = amount.sub(performanceFee);

            uint bnbValue = helper.tvlInBNB(CAKE, performanceFee);
            // bunny amount
            _bunny = minter.amountBunnyToMint(bnbValue);
        } else {
            _usd = amount;
            _bunny = 0;
        }

        _bnb = 0;
    }

    function tvl() override public view returns (uint) {
        uint stakingTVL = helper.tvl(address(stakingToken), _totalSupply);

        uint price = rewardsToken.priceShare();
        uint earned = rewardsToken.balanceOf(address(this)).mul(price).div(1e18);
        uint rewardTVL = helper.tvl(CAKE, earned);

        return stakingTVL.add(rewardTVL);
    }

    function tvlStaking() external view returns (uint) {
        return helper.tvl(address(stakingToken), _totalSupply);
    }

    function tvlReward() external view returns (uint) {
        uint price = rewardsToken.priceShare();
        uint earned = rewardsToken.balanceOf(address(this)).mul(price).div(1e18);
        return helper.tvl(CAKE, earned);
    }

    function apy() override public view returns(uint _usd, uint _bunny, uint _bnb) {
        uint dailyAPY = helper.compoundingAPY(poolId, 365 days).div(365);

        uint cakeAPY = helper.compoundingAPY(0, 1 days);
        uint cakeDailyAPY = helper.compoundingAPY(0, 365 days).div(365);

        // let x = 0.5% (daily flip apr)
        // let y = 0.87% (daily cake apr)
        // sum of yield of the year = x*(1+y)^365 + x*(1+y)^364 + x*(1+y)^363 + ... + x
        // ref: https://en.wikipedia.org/wiki/Geometric_series
        // = x * (1-(1+y)^365) / (1-(1+y))
        // = x * ((1+y)^365 - 1) / (y)

        _usd = dailyAPY.mul(cakeAPY).div(cakeDailyAPY);
        _bunny = 0;
        _bnb = 0;
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
        depositedAt[_to] = block.timestamp;
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        CAKE_MASTER_CHEF.deposit(poolId, amount);
        emit Staked(_to, amount);

        _harvest();
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
        CAKE_MASTER_CHEF.withdraw(poolId, amount);

        if (address(minter) != address(0) && minter.isMinter(address(this))) {
            uint _depositedAt = depositedAt[msg.sender];
            uint withdrawalFee = minter.withdrawalFee(amount, _depositedAt);
            if (withdrawalFee > 0) {
                uint performanceFee = withdrawalFee.div(100);
                minter.mintFor(address(stakingToken), withdrawalFee.sub(performanceFee), performanceFee, msg.sender, _depositedAt);
                amount = amount.sub(withdrawalFee);
            }
        }

        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);

        _harvest();
    }

    function withdrawAll() override external {
        uint _withdraw = withdrawableBalanceOf(msg.sender);
        if (_withdraw > 0) {
            withdraw(_withdraw);
        }
        getReward();
    }

    function getReward() override public nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardsToken.withdraw(reward);
            uint cakeBalance = IBEP20(CAKE).balanceOf(address(this));

            if (address(minter) != address(0) && minter.isMinter(address(this))) {
                uint performanceFee = minter.performanceFee(cakeBalance);
                minter.mintFor(CAKE, 0, performanceFee, msg.sender, depositedAt[msg.sender]);
                cakeBalance = cakeBalance.sub(performanceFee);
            }

            IBEP20(CAKE).safeTransfer(msg.sender, cakeBalance);
            emit RewardPaid(msg.sender, cakeBalance);
        }
    }

    function harvest() override public {
        CAKE_MASTER_CHEF.withdraw(poolId, 0);
        _harvest();
    }

    function _harvest() private {
        uint cakeAmount = IBEP20(CAKE).balanceOf(address(this));
        uint _before = rewardsToken.sharesOf(address(this));
        rewardsToken.deposit(cakeAmount);
        uint amount = rewardsToken.sharesOf(address(this)).sub(_before);
        if (amount > 0) {
            _notifyRewardAmount(amount);
        }
    }

    function info(address account) override external view returns(UserInfo memory) {
        UserInfo memory userInfo;

        userInfo.balance = _balances[account];
        userInfo.principal = _balances[account];
        userInfo.available = withdrawableBalanceOf(account);

        Profit memory profit;
        (uint usd, uint bunny, uint bnb) = profitOf(account);
        profit.usd = usd;
        profit.bunny = bunny;
        profit.bnb = bnb;
        userInfo.profit = profit;

        userInfo.poolTVL = tvl();

        APY memory poolAPY;
        (usd, bunny, bnb) = apy();
        poolAPY.usd = usd;
        poolAPY.bunny = bunny;
        poolAPY.bnb = bnb;
        userInfo.poolAPY = poolAPY;

        return userInfo;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */
    function setKeeper(address _keeper) external {
        require(msg.sender == _keeper || msg.sender == owner(), 'auth');
        require(_keeper != address(0), 'zero address');
        keeper = _keeper;
    }

    function setMinter(IBunnyMinter _minter) public onlyOwner {
        // can zero
        minter = _minter;
        if (address(_minter) != address(0)) {
            IBEP20(CAKE).safeApprove(address(_minter), 0);
            IBEP20(CAKE).safeApprove(address(_minter), uint(~0));

            stakingToken.safeApprove(address(_minter), 0);
            stakingToken.safeApprove(address(_minter), uint(~0));
        }
    }

    function setRewardsToken_public(address _rewardsToken) public onlyOwner {
        require(address(rewardsToken) == address(0), "set rewards token already");

        rewardsToken = ICakeVault(_rewardsToken);

        IBEP20(CAKE).safeApprove(_rewardsToken, 0);
        IBEP20(CAKE).safeApprove(_rewardsToken, uint(~0));
    }

    function setHelper(IStrategyHelper _helper) external onlyOwner {
        require(address(_helper) != address(0), "zero address");
        helper = _helper;
    }

    function notifyRewardAmount(uint256 reward) override public onlyRewardsDistribution {
        _notifyRewardAmount(reward);
    }

    function _notifyRewardAmount(uint256 reward) private updateReward(address(0)) {
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
        uint _balance = rewardsToken.sharesOf(address(this));
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

import "@pancakeswap/pancake-swap-lib/contracts/access/Ownable.sol";

abstract contract RewardsDistributionRecipient is Ownable {
    address public rewardsDistribution;

    modifier onlyRewardsDistribution() {
        require(msg.sender == rewardsDistribution, "onlyRewardsDistribution");
        _;
    }

    function notifyRewardAmount(uint256 reward) virtual external;

    function setRewardsDistribution(address _rewardsDistribution) external onlyOwner {
        rewardsDistribution = _rewardsDistribution;
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

interface ICakeVault {
    function priceShare() external view returns(uint);
    function balanceOf(address account) external view returns(uint);
    function sharesOf(address account) external view returns(uint);
    function deposit(uint _amount) external;
    function withdraw(uint256 _amount) external;
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
    function withdrawableBalanceOf(address account) external view returns (uint);   // BUNNY STAKING POOL ONLY
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

    function info(address account) external view returns (UserInfo memory);
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
import "@pancakeswap/pancake-swap-lib/contracts/access/Ownable.sol";
import "../interfaces/legacy/IStrategyLegacy.sol";
import "../interfaces/IStrategy.sol";

contract MigratorV2 is Ownable {
    struct Status {
        address v1Address;
        address v2Address;

        IStrategyLegacy.UserInfo v1Info;    // v1 info

        bool needMigration; // true if v1's balance > 0 || wallets's balance > 0 || v2's balance > 0
        bool redeemed;      // true if (v1's balance == 0 && v1's profit == 0)
        bool approved;      // true if v2's allowance > 0
        bool deposited;     // true if v2's balance > 0
    }

    address[] private _vaults = [
    0x85537e99f5E535EdC72463e568CB3196130D1275, // CAKE
    0xed9BdC2E991fbEc75f0dD18b4110b8d49C79c5a9, // CAKE - BNB
    0x70368F425DCC37710a9982b4A4CE95fcBd009049, // BUSD - BNB
    0x655d5325C7510521c801E8F5ea074CDc1c9a3B71, // USDT - BNB
    0x8a5766863286789Ad185fd6505dA42a41137A044, // DAI - BNB
    0x828627292eD0A14C6b75Fa4ce9aa6fd859f20408, // USDC - BNB
    0x59E2a69c775991Ba1cb5540058428C28bE48da19, // USDT- BUSD
    0xeAbbadfF9857ef3200dE3518E1F964A9532cF9a5, // VAI - BUSD
    0xa3bFf2eFd9Bbeb098cc01A1285f7cA98227a52B1, // CakeMaximizer CAKE/BNB
    0x569b83F79Ab97757B6ab78ddBC40b1Eeb009d5AB, // CakeMaximizer BUSD/BNB
    0xDc6E9D719Be6Cc0EF4cD6484f7e215F904989bf8, // CakeMaximizer USDT/BNB
    0x916acb3e3b9f4B19FCfbFb327A64EA5e5FCbfbF0, // CakeMaximizer DAI/BNB
    0x62F2D4A792d13Da569Ec5fc0067dA71CaCB26609, // CakeMaximizer USDC/BNB
    0x3649b6d0Ab5727E0e02AC47AAfEC6b26e62fFa00, // CakeMaximizer USDT/BUSD
    0x23b68a3c008512a849981B6E69bBaC16048F3891 // CakeMaximizer VAI/BUSD
    ];

    address[] private _tokens = [
    0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82, // CAKE
    0xA527a61703D82139F8a06Bc30097cC9CAA2df5A6, // CAKE/BNB FLIP
    0x1B96B92314C44b159149f7E0303511fB2Fc4774f, // BUSD/BNB FLIP
    0x20bCC3b8a0091dDac2d0BC30F68E6CBb97de59Cd, // USDT/BNB FLIP
    0x56C77d59E82f33c712f919D09FcedDf49660a829, // DAI/BNB FLIP
    0x30479874f9320A62BcE3bc0e315C920E1D73E278, // USDC/BNB FLIP
    0xc15fa3E22c912A276550F3E5FE3b0Deb87B55aCd, // USDT/BUSD FLIP
    0xfF17ff314925Dff772b71AbdFF2782bC913B3575, // VAI/BUSD FLIP
    0xA527a61703D82139F8a06Bc30097cC9CAA2df5A6, // CakeMaximizer CAKE/BNB FLIP
    0x1B96B92314C44b159149f7E0303511fB2Fc4774f, // CakeMaximizer BUSD/BNB FLIP
    0x20bCC3b8a0091dDac2d0BC30F68E6CBb97de59Cd, // CakeMaximizer USDT/BNB FLIP
    0x56C77d59E82f33c712f919D09FcedDf49660a829, // CakeMaximizer DAI/BNB FLIP
    0x30479874f9320A62BcE3bc0e315C920E1D73E278, // CakeMaximizer USDC/BNB FLIP
    0xc15fa3E22c912A276550F3E5FE3b0Deb87B55aCd, // CakeMaximizer USDT/BUSD FLIP
    0xfF17ff314925Dff772b71AbdFF2782bC913B3575 // CakeMaximizer VAI/BUSD FLIP
    ];
    address[] private _v2 = [
    0xEDfcB78e73f7bA6aD2D829bf5D462a0924da28eD, // CAKE
    0x7eaaEaF2aB59C2c85a17BEB15B110F81b192e98a, // CAKE - BNB
    0x1b6e3d394f1D809769407DEA84711cF57e507B99, // BUSD - BNB
    0xC1aAE51746bEA1a1Ec6f17A4f75b422F8a656ee6, // USDT - BNB
    0x93546BA555557049D94E58497EA8eb057a3df939, // DAI - BNB
    0x1D5C982bb7233d2740161e7bEddCC14548C71186, // USDC - BNB
    0xC0314BbE19D4D5b048D3A3B974f0cA1B2cEE5eF3, // USDT- BUSD
    0xa59EFEf41040e258191a4096DC202583765a43E7, // VAI - BUSD
    0x3f139386406b0924eF115BAFF71D0d30CC090Bd5, // CakeMaximizer CAKE/BNB
    0x92a0f75a0f07C90a7EcB65eDD549Fa6a45a4975C, // CakeMaximizer BUSD/BNB
    0xE07BdaAc4573a00208D148bD5b3e5d2Ae4Ebd0Cc, // CakeMaximizer USDT/BNB
    0x5d1dcB4460799F5d5A40a1F4ecA558ADE1c56831, // CakeMaximizer DAI/BNB
    0x87DFCd4032760936606C7A0ADBC7acec1885293F, // CakeMaximizer USDC/BNB
    0x866FD0028eb7fc7eeD02deF330B05aB503e199d4, // CakeMaximizer USDT/BUSD
    0xa5B8cdd3787832AdEdFe5a04bF4A307051538FF2 // CakeMaximizer VAI/BUSD
    ];

    // dev only
//    function setV2Address(address _address) external onlyOwner {
//        _v2.push(_address);
//    }

    function statusOf(address user) external view returns (bool showMigrationPage, Status[] memory outputs) {
        Status[] memory results = new Status[](_vaults.length);

        for (uint i = 0; i < _vaults.length; i++) {
            IBEP20 token = IBEP20(_tokens[i]);
            IStrategyLegacy v1 = IStrategyLegacy(_vaults[i]);
            IStrategy v2 = IStrategy(_v2[i]);

            Status memory status;
            status.v1Address = _vaults[i];
            status.v2Address = _v2[i];
            status.v1Info = v1.info(user);

            status.needMigration = v1.balanceOf(user) > 0 || token.balanceOf(user) > 0 || v2.balanceOf(user) > 0;
            status.redeemed = v1.balanceOf(user) == 0;
            status.approved = token.allowance(user, address(v2)) > 0;
            status.deposited = v2.balanceOf(user) > 0;

            if (v1.balanceOf(user) > 0 && showMigrationPage == false) {
                showMigrationPage = true;
            }
            results[i] = status;
        }

        outputs = results;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/Math.sol";
import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import "../../../library/RewardsDistributionRecipientUpgradeable.sol";

import "../../../interfaces/IStrategy.sol";
import "../../../interfaces/IMasterChef.sol";
import "../../../interfaces/IBunnyMinter.sol";
import "../../interface/ICPool.sol";

import "../../../vaults/VaultController.sol";
import {PoolConstant} from "../../../library/PoolConstant.sol";


contract CPoolFlipToCake is ICPool, VaultController, IStrategy, RewardsDistributionRecipientUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMath for uint;
    using SafeBEP20 for IBEP20;

    /* ========== CONSTANTS ============= */

    address private constant CAKE = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    IMasterChef private constant CAKE_MASTER_CHEF = IMasterChef(0x73feaa1eE314F8c655E354234017bE2193C9E24E);
    PoolConstant.PoolTypes public constant override poolType = PoolConstant.PoolTypes.FlipToCake;

    /* ========== STATE VARIABLES ========== */

    IStrategy private _rewardsToken;

    uint public periodFinish;
    uint public rewardRate;
    uint public rewardsDuration;
    uint public lastUpdateTime;
    uint public rewardPerTokenStored;

    mapping(address => uint) public userRewardPerTokenPaid;
    mapping(address => uint) public override rewards;

    uint private _totalSupply;
    mapping(address => uint) private _balances;

    uint public override pid;
    mapping (address => uint) private _depositedAt;

    address public cvaultBSC;

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

    modifier onlyCVaultBSC {
        require(msg.sender == cvaultBSC, 'CPoolFlipToCake: caller is not the cvaultBSC');
        _;
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint reward);
    event RewardsDurationUpdated(uint newDuration);

    /* ========== INITIALIZER ========== */

    function initialize(uint _pid, address _cvaultBSC) external initializer {
        (address _token,,,) = CAKE_MASTER_CHEF.poolInfo(_pid);
        __VaultController_init(IBEP20(_token));
        __RewardsDistributionRecipient_init();
        __ReentrancyGuard_init();

        _stakingToken.safeApprove(address(CAKE_MASTER_CHEF), uint(~0));

        pid = _pid;

        rewardsDuration = 24 hours;
        rewardsDistribution = msg.sender;
        cvaultBSC = _cvaultBSC;
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

    function priceShare() external view override returns(uint) {
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

    function deposit(address to, uint amount) external override nonReentrant notPaused updateReward(to) onlyCVaultBSC {
        require(amount > 0, "CPoolFlipToCake: amount must be greater than zero");
        _totalSupply = _totalSupply.add(amount);
        _balances[to] = _balances[to].add(amount);
        _depositedAt[to] = block.timestamp;
        _stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        CAKE_MASTER_CHEF.deposit(pid, amount);
        emit Deposited(to, amount);

        _harvest();
    }

    function deposit(uint) public override {
        revert("N/A");
    }

    function depositAll() override external {
        revert("N/A");
    }

    function withdraw(uint) external override {
        revert("N/A");
    }

    function withdraw(address to, uint amount) public override nonReentrant updateReward(to) onlyCVaultBSC {
        require(amount > 0, "CPoolFlipToCake: amount must be greater than zero");
        _totalSupply = _totalSupply.sub(amount);
        _balances[to] = _balances[to].sub(amount);
        CAKE_MASTER_CHEF.withdraw(pid, amount);
        _stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(to, amount, 0);

        _harvest();
    }

    function withdrawAll() external override {
        revert("N/A");
    }

    function withdrawAll(address to) external override onlyCVaultBSC {
        uint _withdraw = withdrawableBalanceOf(to);
        if (_withdraw > 0) {
            withdraw(to, _withdraw);
        }
        getReward(to);
    }

    function getReward() external override {
        revert("N/A");
    }

    function getReward(address to) public override nonReentrant updateReward(to) onlyCVaultBSC {
        uint reward = rewards[to];
        if (reward > 0) {
            rewards[to] = 0;
            _rewardsToken.withdraw(reward);
            uint cakeBalance = IBEP20(CAKE).balanceOf(address(this));

            IBEP20(CAKE).safeTransfer(msg.sender, cakeBalance);
            emit ProfitPaid(to, cakeBalance, 0);
        }
    }

    function harvest() public override {
        CAKE_MASTER_CHEF.withdraw(pid, 0);
        _harvest();
    }

    function _harvest() private {
        uint cakeAmount = IBEP20(CAKE).balanceOf(address(this));
        uint _before = _rewardsToken.sharesOf(address(this));
        _rewardsToken.deposit(cakeAmount);
        uint amount = _rewardsToken.sharesOf(address(this)).sub(_before);
        if (amount > 0) {
            _notifyRewardAmount(amount);
            emit Harvested(amount);
        }
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setMinter(IBunnyMinter) override public onlyOwner {
        revert("N/A");
    }

    function setRewardsToken(address newRewardsToken) public onlyOwner {
        require(address(_rewardsToken) == address(0), "CPoolFlipToCake: rewards token already set");

        _rewardsToken = IStrategy(newRewardsToken);
        IBEP20(CAKE).safeApprove(newRewardsToken, 0);
        IBEP20(CAKE).safeApprove(newRewardsToken, uint(~0));
    }

    function notifyRewardAmount(uint reward) public override onlyRewardsDistribution {
        _notifyRewardAmount(reward);
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
        require(rewardRate <= _balance.div(rewardsDuration), "CPoolFlipToCake: reward rate must be in the right range");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardAdded(reward);
    }

    function setRewardsDuration(uint _rewardsDuration) external onlyOwner {
        require(periodFinish == 0 || block.timestamp > periodFinish, "CPoolFlipToCake: reward duration can only be updated after the period ends");
        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    }

    /* ========== SALVAGE PURPOSE ONLY ========== */

    function recoverToken(address tokenAddress, uint tokenAmount) external override onlyOwner {
        require(tokenAddress != address(_stakingToken) && tokenAddress != _rewardsToken.stakingToken(), "CPoolFlipToCake: cannot recover underlying token");
        IBEP20(tokenAddress).safeTransfer(owner(), tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/BEP20.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol";
import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";
import "@pancakeswap/pancake-swap-lib/contracts/access/Ownable.sol";
import "../../interfaces/IBunnyMinter.sol";
import "../../interfaces/legacy/IStakingRewards.sol";
import "./PancakeSwap.sol";
import "../../interfaces/legacy/IStrategyHelper.sol";

contract BunnyMinter is IBunnyMinter, Ownable, PancakeSwap {
    using SafeMath for uint;
    using SafeBEP20 for IBEP20;

    BEP20 private constant bunny = BEP20(0xC9849E6fdB743d08fAeE3E34dd2D1bc69EA11a51);
    address public constant dev = 0xe87f02606911223C2Cf200398FFAF353f60801F7;
    IBEP20 private constant WBNB = IBEP20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);

    uint public override WITHDRAWAL_FEE_FREE_PERIOD = 3 days;
    uint public override WITHDRAWAL_FEE = 50;
    uint public constant FEE_MAX = 10000;

    uint public PERFORMANCE_FEE = 3000; // 30%

    uint public override bunnyPerProfitBNB;
    uint public bunnyPerBunnyBNBFlip;

    address public constant bunnyPool = 0xCADc8CB26c8C7cB46500E61171b5F27e9bd7889D;
    IStrategyHelper public helper = IStrategyHelper(0xA84c09C1a2cF4918CaEf625682B429398b97A1a0);

    mapping (address => bool) private _minters;

    modifier onlyMinter {
        require(isMinter(msg.sender) == true, "not minter");
        _;
    }

    constructor() public {
        bunnyPerProfitBNB = 10e18;
        bunnyPerBunnyBNBFlip = 6e18;
        bunny.approve(bunnyPool, uint(~0));
    }

    function transferBunnyOwner(address _owner) external onlyOwner {
        Ownable(address(bunny)).transferOwnership(_owner);
    }

    function setWithdrawalFee(uint _fee) external onlyOwner {
        require(_fee < 500, "wrong fee");   // less 5%
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

    function setBunnyPerProfitBNB(uint _ratio) external onlyOwner {
        bunnyPerProfitBNB = _ratio;
    }

    function setBunnyPerBunnyBNBFlip(uint _bunnyPerBunnyBNBFlip) external onlyOwner {
        bunnyPerBunnyBNBFlip = _bunnyPerBunnyBNBFlip;
    }

    function setHelper(IStrategyHelper _helper) external onlyOwner {
        require(address(_helper) != address(0), "zero address");
        helper = _helper;
    }

    function isMinter(address account) override view public returns(bool) {
        if (bunny.getOwner() != address(this)) {
            return false;
        }

        if (block.timestamp < 1605585600) { // 12:00 SGT 17th November 2020
            return false;
        }
        return _minters[account];
    }

    function amountBunnyToMint(uint bnbProfit) override view public returns(uint) {
        return bnbProfit.mul(bunnyPerProfitBNB).div(1e18);
    }

    function amountBunnyToMintForBunnyBNB(uint amount, uint duration) override view public returns(uint) {
        return amount.mul(bunnyPerBunnyBNBFlip).mul(duration).div(365 days).div(1e18);
    }

    function withdrawalFee(uint amount, uint depositedAt) override view external returns(uint) {
        if (depositedAt.add(WITHDRAWAL_FEE_FREE_PERIOD) > block.timestamp) {
            return amount.mul(WITHDRAWAL_FEE).div(FEE_MAX);
        }
        return 0;
    }

    function performanceFee(uint profit) override view public returns(uint) {
        return profit.mul(PERFORMANCE_FEE).div(FEE_MAX);
    }

    function mintFor(address flip, uint _withdrawalFee, uint _performanceFee, address to, uint) override external onlyMinter {
        uint feeSum = _performanceFee.add(_withdrawalFee);
        IBEP20(flip).safeTransferFrom(msg.sender, address(this), feeSum);

        uint bunnyBNBAmount = tokenToBunnyBNB(flip, IBEP20(flip).balanceOf(address(this)));
        address flipToken = bunnyBNBFlipToken();
        IBEP20(flipToken).safeTransfer(bunnyPool, bunnyBNBAmount);
        IStakingRewards(bunnyPool).notifyRewardAmount(bunnyBNBAmount);

        uint contribution = helper.tvlInBNB(flipToken, bunnyBNBAmount).mul(_performanceFee).div(feeSum);
        uint mintBunny = amountBunnyToMint(contribution);
        mint(mintBunny, to);
    }

    function mintForBunnyBNB(uint amount, uint duration, address to) override external onlyMinter {
        uint mintBunny = amountBunnyToMintForBunnyBNB(amount, duration);
        if (mintBunny == 0) return;
        mint(mintBunny, to);
    }

    function mint(uint amount, address to) private {
        bunny.mint(amount);
        bunny.transfer(to, amount);

        uint bunnyForDev = amount.mul(15).div(100);
        bunny.mint(bunnyForDev);
        IStakingRewards(bunnyPool).stakeTo(bunnyForDev, dev);
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

import "../interfaces/IBunnyMinterV2.sol";
import "../interfaces/legacy/IStakingRewards.sol";
import "./PancakeSwapV2.sol";
import "../interfaces/legacy/IStrategyHelper.sol";

contract BunnyMinterV2 is IBunnyMinterV2, PancakeSwapV2 {
    using SafeMath for uint;
    using SafeBEP20 for IBEP20;

    /* ========== CONSTANTS ============= */

    BEP20 private constant BUNNY_TOKEN = BEP20(0xC9849E6fdB743d08fAeE3E34dd2D1bc69EA11a51);
    address public constant BUNNY_POOL = 0xCADc8CB26c8C7cB46500E61171b5F27e9bd7889D;
    address public constant DEPLOYER = 0xe87f02606911223C2Cf200398FFAF353f60801F7;
    address private constant BUNNY_BNB_FLIP = 0x7Bb89460599Dbf32ee3Aa50798BBcEae2A5F7f6a;
    address private constant TIMELOCK = 0x85c9162A51E03078bdCd08D4232Bab13ed414cC3;

    uint public constant FEE_MAX = 10000;

    /* ========== STATE VARIABLES ========== */

    address public bunnyChef;
    mapping (address => bool) private _minters;
    IStrategyHelper public helper;

    uint public PERFORMANCE_FEE;
    uint public override WITHDRAWAL_FEE_FREE_PERIOD;
    uint public override WITHDRAWAL_FEE;

    uint public override bunnyPerProfitBNB;
    uint public bunnyPerBunnyBNBFlip;   // will be deprecated

    /* ========== MODIFIERS ========== */

    modifier onlyMinter {
        require(isMinter(msg.sender) == true, "BunnyMinterV2: caller is not the minter");
        _;
    }

    modifier onlyBunnyChef {
        require(msg.sender == bunnyChef, "BunnyMinterV2: caller not the bunny chef");
        _;
    }

    /* ========== INITIALIZER ========== */

    function initialize() external initializer {
        __PancakeSwapV2_init();

        WITHDRAWAL_FEE_FREE_PERIOD = 3 days;
        WITHDRAWAL_FEE = 50;
        PERFORMANCE_FEE = 3000;

        bunnyPerProfitBNB = 5e18;
        bunnyPerBunnyBNBFlip = 6e18;

        helper = IStrategyHelper(0xA84c09C1a2cF4918CaEf625682B429398b97A1a0);
        BUNNY_TOKEN.approve(BUNNY_POOL, uint(-1));
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function transferBunnyOwner(address _owner) external onlyOwner {
        Ownable(address(BUNNY_TOKEN)).transferOwnership(_owner);
    }

    function setWithdrawalFee(uint _fee) external onlyOwner {
        require(_fee < 500, "wrong fee");   // less 5%
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

    function setBunnyPerProfitBNB(uint _ratio) external onlyOwner {
        bunnyPerProfitBNB = _ratio;
    }

    function setBunnyPerBunnyBNBFlip(uint _bunnyPerBunnyBNBFlip) external onlyOwner {
        bunnyPerBunnyBNBFlip = _bunnyPerBunnyBNBFlip;
    }

    function setHelper(IStrategyHelper _helper) external onlyOwner {
        require(address(_helper) != address(0), "BunnyMinterV2: helper can not be zero");
        helper = _helper;
    }

    function setBunnyChef(address _bunnyChef) external onlyOwner {
        require(bunnyChef == address(0), "BunnyMinterV2: setBunnyChef only once");
        bunnyChef = _bunnyChef;
    }

    /* ========== VIEWS ========== */

    function isMinter(address account) override public view returns(bool) {
        if (BUNNY_TOKEN.getOwner() != address(this)) {
            return false;
        }
        return _minters[account];
    }

    function amountBunnyToMint(uint bnbProfit) override public view returns(uint) {
        return bnbProfit.mul(bunnyPerProfitBNB).div(1e18);
    }

    function amountBunnyToMintForBunnyBNB(uint amount, uint duration) override public view returns(uint) {
        return amount.mul(bunnyPerBunnyBNBFlip).mul(duration).div(365 days).div(1e18);
    }

    function withdrawalFee(uint amount, uint depositedAt) override external view returns(uint) {
        if (depositedAt.add(WITHDRAWAL_FEE_FREE_PERIOD) > block.timestamp) {
            return amount.mul(WITHDRAWAL_FEE).div(FEE_MAX);
        }
        return 0;
    }

    function performanceFee(uint profit) override public view returns(uint) {
        return profit.mul(PERFORMANCE_FEE).div(FEE_MAX);
    }

    /* ========== V1 FUNCTIONS ========== */

    function mintFor(address flip, uint _withdrawalFee, uint _performanceFee, address to, uint) override external onlyMinter {
        uint feeSum = _performanceFee.add(_withdrawalFee);
        IBEP20(flip).safeTransferFrom(msg.sender, address(this), feeSum);

        uint bunnyBNBAmount = tokenToBunnyBNB(flip, IBEP20(flip).balanceOf(address(this)));
        if (bunnyBNBAmount == 0) return;

        IBEP20(BUNNY_BNB_FLIP).safeTransfer(BUNNY_POOL, bunnyBNBAmount);
        IStakingRewards(BUNNY_POOL).notifyRewardAmount(bunnyBNBAmount);

        uint contribution = helper.tvlInBNB(BUNNY_BNB_FLIP, bunnyBNBAmount).mul(_performanceFee).div(feeSum);
        uint mintBunny = amountBunnyToMint(contribution);
        if (mintBunny == 0) return;
        _mint(mintBunny, to);
    }

    // @dev will be deprecated
    function mintForBunnyBNB(uint amount, uint duration, address to) override external onlyMinter {
        uint mintBunny = amountBunnyToMintForBunnyBNB(amount, duration);
        if (mintBunny == 0) return;
        _mint(mintBunny, to);
    }

    /* ========== V2 FUNCTIONS ========== */

    function mint(uint amount) external override onlyBunnyChef {
        if (amount == 0) return;
        _mint(amount, address(this));
    }

    function safeBunnyTransfer(address _to, uint _amount) external override onlyBunnyChef {
        if (_amount == 0) return;

        uint256 bal = BUNNY_TOKEN.balanceOf(address(this));
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

    function _mint(uint amount, address to) private {
        BUNNY_TOKEN.mint(amount);
        if (to != address(this)) {
            BUNNY_TOKEN.transfer(to, amount);
        }

        uint bunnyForDev = amount.mul(15).div(100);
        BUNNY_TOKEN.mint(bunnyForDev);
        IStakingRewards(BUNNY_POOL).stakeTo(bunnyForDev, DEPLOYER);
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

import "@pancakeswap/pancake-swap-lib/contracts/access/Ownable.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract MigrationRewards is Ownable, ReentrancyGuard {
    using SafeBEP20 for IBEP20;

    struct Request {
        address account;
        uint rewards;
    }

    event MigrationRewardsPaid(address indexed account, uint amount);
    event EmergencyExit(address indexed token, uint amount);

    IBEP20 private constant BUNNY = IBEP20(0xC9849E6fdB743d08fAeE3E34dd2D1bc69EA11a51);
    mapping(address => uint) public rewards;

    function getReward() public nonReentrant {
        uint reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;

            BUNNY.safeTransfer(msg.sender, reward);
            emit MigrationRewardsPaid(msg.sender, reward);
        }
    }

    function updateRewards(Request[] memory requests) external onlyOwner {
        for (uint i = 0; i < requests.length; i++) {
            Request memory request = requests[i];
            rewards[request.account] = request.rewards;
        }
    }

    function emergencyExit(address token) external onlyOwner {
        IBEP20 asset = IBEP20(token);

        uint remain = asset.balanceOf(address(this));
        asset.safeTransfer(owner(), remain);
        emit EmergencyExit(token, remain);
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
        IBEP20(token).transfer(0xe87f02606911223C2Cf200398FFAF353f60801F7, IBEP20(token).balanceOf(address(this)));
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

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@pancakeswap/pancake-swap-lib/contracts/access/Ownable.sol";

import "../Timelock.sol";


interface IVault {
    function setMinter(address newMinter) external;
}

interface IBunnyPool {
    function setStakePermission(address _address, bool permission) external;
    function setRewardsDistribution(address _rewardsDistribution) external;
}

contract BunnyMinterMigrator is OwnableUpgradeable {
    address payable public constant TIMELOCK = 0x85c9162A51E03078bdCd08D4232Bab13ed414cC3;
    address private constant BUNNY_POOL = 0xCADc8CB26c8C7cB46500E61171b5F27e9bd7889D;
    address private constant MINTER_V1 = 0x0B4A714AAf59E46cb1900E3C031017Fd72667EfE;

    receive() external payable {}
    fallback() external payable {
        require(msg.sender == owner(), "not owner");

        address timelock = TIMELOCK;
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := call(gas(), timelock, callvalue(), ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }

    function initialize() external initializer {
        __Ownable_init();
    }

    function migrateMinterV2(address minterV2, uint eta) external onlyOwner {
        Timelock(TIMELOCK).executeTransaction(MINTER_V1, 0, "transferBunnyOwner(address)", abi.encode(minterV2), eta);

        // BUNNY/BNB + 15 farming pools
        address payable[16] memory pools = [
        0xc80eA568010Bca1Ad659d1937E17834972d66e0D,
        0xEDfcB78e73f7bA6aD2D829bf5D462a0924da28eD,
        0x7eaaEaF2aB59C2c85a17BEB15B110F81b192e98a,
        0x3f139386406b0924eF115BAFF71D0d30CC090Bd5,
        0x1b6e3d394f1D809769407DEA84711cF57e507B99,
        0x92a0f75a0f07C90a7EcB65eDD549Fa6a45a4975C,
        0xC1aAE51746bEA1a1Ec6f17A4f75b422F8a656ee6,
        0xE07BdaAc4573a00208D148bD5b3e5d2Ae4Ebd0Cc,
        0xa59EFEf41040e258191a4096DC202583765a43E7,
        0xa5B8cdd3787832AdEdFe5a04bF4A307051538FF2,
        0xC0314BbE19D4D5b048D3A3B974f0cA1B2cEE5eF3,
        0x866FD0028eb7fc7eeD02deF330B05aB503e199d4,
        0x0137d886e832842a3B11c568d5992Ae73f7A792e,
        0xCBd4472cbeB7229278F841b2a81F1c0DF1AD0058,
        0xE02BCFa3D0072AD2F52eD917a7b125e257c26032,
        0x41dF17D1De8D4E43d5493eb96e01100908FCcc4f
        ];

        for(uint i=0; i<pools.length; i++) {
            IVault(pools[i]).setMinter(minterV2);
            Ownable(pools[i]).transferOwnership(owner());
        }

        IBunnyPool(BUNNY_POOL).setRewardsDistribution(minterV2);
        IBunnyPool(BUNNY_POOL).setStakePermission(minterV2, true);
        Ownable(BUNNY_POOL).transferOwnership(owner());
        Ownable(minterV2).transferOwnership(TIMELOCK);

        Timelock(TIMELOCK).executeTransaction(TIMELOCK, 0, "setPendingAdmin(address)", abi.encode(owner()), eta);
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
pragma solidity 0.6.12;

import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";


contract TripleSlopeModel {
    using SafeMath for uint256;

    /// @dev Return the interest rate per second, using 1e18 as denom.
    function getInterestRate(uint256 debt, uint256 floating) external pure returns (uint256) {
        uint256 total = debt.add(floating);
        if (total == 0) return 0;

        uint256 utilization = debt.mul(10000).div(total);
        if (utilization < 5000) {
            // Less than 50% utilization - 10% APY
            return uint256(10e16) / 365 days;
        } else if (utilization < 9500) {
            // Between 50% and 95% - 10%-25% APY
            return (10e16 + utilization.sub(5000).mul(15e16).div(10000)) / 365 days;
        } else if (utilization < 10000) {
            // Between 95% and 100% - 25%-100% APY
            return (25e16 + utilization.sub(7500).mul(75e16).div(10000)) / 365 days;
        } else {
            // Not possible, but just in case - 100% APY
            return uint256(100e16) / 365 days;
        }
    }
}