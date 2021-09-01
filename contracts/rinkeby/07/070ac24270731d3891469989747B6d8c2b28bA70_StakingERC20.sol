// SPDX-License-Identifier: NONE
pragma solidity ^0.7.0;

import '@balancer-labs/balancer-core-v2/contracts/lib/openzeppelin/SafeERC20.sol';
import "./Distribute.sol";
import "./interfaces/IERC900.sol";

/**
 * An IERC900 staking contract
 */
contract StakingERC20 is IERC900  {
    using SafeERC20 for IERC20;

    /// @dev handle to access ERC20 token token contract to make transfers
    IERC20 private _token;
    Distribute public staking_contract_eth;
    Distribute public staking_contract_token;

    event ProfitToken(uint256 amount);
    event ProfitEth(uint256 amount);
    event StakeChanged(uint256 total, uint256 timestamp);

    constructor(IERC20 stake_token, IERC20 reward_token, uint256 decimals) {
        _token = stake_token;
        staking_contract_eth = new Distribute(decimals, IERC20(address(0)));
        staking_contract_token = new Distribute(decimals, reward_token);
    }

    function distribute_eth() payable external {
        staking_contract_eth.distribute{value : msg.value}(0, msg.sender);
        emit ProfitEth(msg.value);
    }

    function distribute(uint256 amount) external {
        staking_contract_token.distribute(amount, msg.sender);
        emit ProfitToken(amount);
    }
    
    /**
        @dev Stakes a certain amount of tokens, this MUST transfer the given amount from the account
        @param amount Amount of ERC20 token to stake
        @param data Additional data as per the EIP900
    */
    function stake(uint256 amount, bytes calldata data) external override {
        stakeFor(msg.sender, amount, data);
    }

    /**
        @dev Stakes a certain amount of tokens, this MUST transfer the given amount from the caller
        @param account Address who will own the stake afterwards
        @param amount Amount of ERC20 token to stake
        @param data Additional data as per the EIP900
    */
    function stakeFor(address account, uint256 amount, bytes calldata data) public override {
        //transfer the ERC20 token from the account, he must have set an allowance of {amount} tokens
        _token.safeTransferFrom(msg.sender, address(this), amount);
        staking_contract_eth.stakeFor(account, amount);
        staking_contract_token.stakeFor(account, amount);
        emit Staked(account, amount, totalStakedFor(account), data);
        emit StakeChanged(staking_contract_eth.totalStaked(), block.timestamp);
    }

    /**
        @dev Unstakes a certain amount of tokens, this SHOULD return the given amount of tokens to the account, if unstaking is currently not possible the function MUST revert
        @param amount Amount of ERC20 token to remove from the stake
        @param data Additional data as per the EIP900
    */
    function unstake(uint256 amount, bytes calldata data) external override {
        staking_contract_eth.unstakeFrom(msg.sender, amount);
        staking_contract_token.unstakeFrom(msg.sender, amount);
        _token.safeTransfer(msg.sender, amount);
        emit Unstaked(msg.sender, amount, totalStakedFor(msg.sender), data);
        emit StakeChanged(staking_contract_eth.totalStaked(), block.timestamp);
    }

     /**
        @dev Withdraws rewards (basically unstake then restake)
        @param amount Amount of ERC20 token to remove from the stake
    */
    function withdraw(uint256 amount) external {
        staking_contract_eth.withdrawFrom(msg.sender, amount);
        staking_contract_token.withdrawFrom(msg.sender,amount);
    }

    /**
        @dev Returns the current total of tokens staked for an address
        @param account address owning the stake
        @return the total of staked tokens of this address
    */
    function totalStakedFor(address account) public view override returns (uint256) {
        return staking_contract_eth.totalStakedFor(account);
    }
    
    /**
        @dev Returns the current total of tokens staked
        @return the total of staked tokens
    */
    function totalStaked() external view override returns (uint256) {
        return staking_contract_eth.totalStaked();
    }

    /**
        @dev returns the total rewards stored for token and eth
    */
    function totalReward() external view returns (uint256 token, uint256 eth) {
        token = staking_contract_token.getTotalReward();
        eth = staking_contract_eth.getTotalReward();
    }

    /**
        @dev Address of the token being used by the staking interface
        @return ERC20 token token address
    */
    function token() external view override returns (address) {
        return address(_token);
    }

    /**
        @dev MUST return true if the optional history functions are implemented, otherwise false
        We dont want this
    */
    function supportsHistory() external pure override returns (bool) {
        return false;
    }

    /**
        @dev Returns how much ETH the user can withdraw currently
        @param account Address of the user to check reward for
        @return _eth the amount of ETH the account will perceive if he unstakes now
        @return __token the amount of tokens the account will perceive if he unstakes now
    */
    function getReward(address account) public view returns (uint256 _eth, uint256 __token) {
        _eth = staking_contract_eth.getReward(account);
        __token = staking_contract_token.getReward(account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../helpers/BalancerErrors.sol";

import "./IERC20.sol";

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
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(address(token), abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(address(token), abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     *
     * WARNING: `token` is assumed to be a contract: calls to EOAs will *not* revert.
     */
    function _callOptionalReturn(address token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.
        (bool success, bytes memory returndata) = token.call(data);

        // If the low-level call didn't succeed we return whatever was returned from it.
        assembly {
            if eq(success, 0) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        // Finally we check the returndata size is either zero or true - note that this check will always pass for EOAs
        _require(returndata.length == 0 || abi.decode(returndata, (bool)), Errors.SAFE_ERC20_CALL_FAILED);
    }
}

// SPDX-License-Identifier: NONE
pragma solidity ^0.7.0;

import "@balancer-labs/balancer-core-v2/contracts/lib/math/Math.sol";
import "@balancer-labs/balancer-core-v2/contracts/lib/openzeppelin/IERC20.sol";
import '@balancer-labs/balancer-core-v2/contracts/lib/openzeppelin/SafeERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

/**
 * staking contract for ERC20 tokens or ETH
 */
contract Distribute is Ownable {
    using Math for uint256;
    using SafeERC20 for IERC20;

    /**
     @dev This value is very important because if the number of bonds is too great
     compared to the distributed value, then the bond increase will be zero
     therefore this value depends on the number of decimals
     of the distributed token and I suggest it to be the same
     For example if the token has 18 decimals, then the precision should also have 18 decimals

    */
    uint256 public PRECISION;

    uint256 constant INITIAL_BOND_VALUE = 1000000;

    uint256 public bond_value = INITIAL_BOND_VALUE;
    //just for info
    uint256 public investor_count;

    uint256 private _total_staked;
    uint256 private _temp_pool;
    // the amount of dust left to distribute after the bond value has been updated
    uint256 public to_distribute;
    mapping(address => uint256) private _bond_value_addr;
    mapping(address => uint256) private _stakes;

    /// @dev token to distribute
    IERC20 public reward_token;

    /**
        @dev Initialize the contract
        @param decimals Number of decimals of the reward token
        @param _reward_token The token used for rewards. Set to 0 for ETH
    */
    constructor(uint256 decimals, IERC20 _reward_token) Ownable() {
        reward_token = _reward_token;
        PRECISION = 10**decimals;
    }

    /**
        @dev Stakes a certain amount, this MUST transfer the given amount from the caller
        @param account Address who will own the stake afterwards
        @param amount Amount to stake
    */
    function stakeFor(address account, uint256 amount) public onlyOwner {
        require(account != address(0), "Distribute: Invalid account");
        require(amount > 0, "Distribute: Amount must be greater than zero");
        _total_staked = _total_staked.add(amount);
        if(_stakes[account] == 0) {
            investor_count++;
        }

        uint256 accumulated_reward = getReward(account);
        _stakes[account] = _stakes[account].add(amount);

        uint256 new_bond_value = accumulated_reward * PRECISION / _stakes[account];
        _bond_value_addr[account] = bond_value.sub(new_bond_value);
    }

    /**
        @dev unstakes a certain amounts, if unstaking is currently not possible the function MUST revert
        @param account From whom
        @param amount Amount to remove from the stake
    */
    function unstakeFrom(address payable account, uint256 amount) public onlyOwner {
        require(account != address(0), "Distribute: Invalid account");
        require(amount > 0, "Distribute: Amount must be greater than zero");
        require(amount <= _stakes[account], "Distribute: Dont have enough staked");
        uint256 to_reward = _getReward(account, amount);
        _total_staked = _total_staked.sub(amount);
        _stakes[account] = _stakes[account].sub(amount);
        if(_stakes[account] == 0) {
            investor_count--;
        }

        if(to_reward == 0) return;
        //take into account dust error during payment too
        if(address(reward_token) != address(0)) {
            reward_token.safeTransfer(account, to_reward);
        }
        else {
            account.transfer(to_reward);
        }
    }

     /**
        @dev Withdraws rewards (basically unstake then restake)
        @param account From whom
        @param amount Amount to remove from the stake
    */
    function withdrawFrom(address payable account, uint256 amount) external onlyOwner {
        unstakeFrom(account, amount);
        stakeFor(account, amount);
    }

    /**
        @dev Called contracts to distribute dividends
        Updates the bond value
        @param amount Amount of token to distribute
        @param from Address from which to take the token
    */
    function distribute(uint256 amount, address from) external payable onlyOwner {
        if(address(reward_token) != address(0)) {
            if(amount == 0) return;
            reward_token.safeTransferFrom(from, address(this), amount);
        } else {
            amount = msg.value;
        }

        if(_total_staked == 0) {
            // no stakes yet, put into temp pool
            _temp_pool = _temp_pool.add(amount);
            return;
        }

        // if a temp pool existed, add it to the current distribution
        if(_temp_pool > 0) {
            amount = amount.add(_temp_pool);
            _temp_pool = 0;
        }
        
        uint256 temp_to_distribute = to_distribute.add(amount);
        uint256 total_bonds = _total_staked / PRECISION;
        uint256 bond_increase = temp_to_distribute / total_bonds;
        uint256 distributed_total = total_bonds.mul(bond_increase);
        bond_value = bond_value.add(bond_increase);
        //collect the dust because of the PRECISION used for bonds
        //it will be reinjected into the next distribution
        to_distribute = temp_to_distribute.sub(distributed_total);
    }

    /**
        @dev Returns the current total staked for an address
        @param account address owning the stake
        @return the total staked for this account
    */
    function totalStakedFor(address account) external view returns (uint256) {
        return _stakes[account];
    }
    
    /**
        @return current staked token
    */
    function totalStaked() external view returns (uint256) {
        return _total_staked;
    }

    /**
        @dev Returns how much the user can withdraw currently
        @param account Address of the user to check reward for
        @return the amount account will perceive if he unstakes now
    */
    function getReward(address account) public view returns (uint256) {
        return _getReward(account,_stakes[account]);
    }

    /**
        @dev returns the total amount of stored rewards
    */
    function getTotalReward() external view returns (uint256) {
        if(address(reward_token) != address(0)) {
            return reward_token.balanceOf(address(this));
        } else {
            return address(this).balance;
        }
    }

    /**
        @dev Returns how much the user can withdraw currently
        @param account Address of the user to check reward for
        @param amount Number of stakes
        @return the amount account will perceive if he unstakes now
    */
    function _getReward(address account, uint256 amount) internal view returns (uint256) {
        return amount.mul(bond_value.sub(_bond_value_addr[account])) / PRECISION;
    }
}

// SPDX-License-Identifier: NONE
pragma solidity ^0.7.0;

//https://github.com/ethereum/EIPs/blob/master/EIPS/eip-900.md
interface IERC900 {
    event Staked(address indexed addr, uint256 amount, uint256 total, bytes data);
    event Unstaked(address indexed addr, uint256 amount, uint256 total, bytes data);

    function stake(uint256 amount, bytes calldata data) external;
    function stakeFor(address addr, uint256 amount, bytes calldata data) external;
    function unstake(uint256 amount, bytes calldata data) external;
    function totalStakedFor(address addr) external view returns (uint256);
    function totalStaked() external view returns (uint256);
    function token() external view returns (address);
    function supportsHistory() external pure returns (bool);

    // optional
    //function lastStakedFor(address addr) public view returns (uint256);
    //function totalStakedForAt(address addr, uint256 blockNumber) public view returns (uint256);
    //function totalStakedAt(uint256 blockNumber) public view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;

// solhint-disable

/**
 * @dev Reverts if `condition` is false, with a revert reason containing `errorCode`. Only codes up to 999 are
 * supported.
 */
function _require(bool condition, uint256 errorCode) pure {
    if (!condition) _revert(errorCode);
}

/**
 * @dev Reverts with a revert reason containing `errorCode`. Only codes up to 999 are supported.
 */
function _revert(uint256 errorCode) pure {
    // We're going to dynamically create a revert string based on the error code, with the following format:
    // 'BAL#{errorCode}'
    // where the code is left-padded with zeroes to three digits (so they range from 000 to 999).
    //
    // We don't have revert strings embedded in the contract to save bytecode size: it takes much less space to store a
    // number (8 to 16 bits) than the individual string characters.
    //
    // The dynamic string creation algorithm that follows could be implemented in Solidity, but assembly allows for a
    // much denser implementation, again saving bytecode size. Given this function unconditionally reverts, this is a
    // safe place to rely on it without worrying about how its usage might affect e.g. memory contents.
    assembly {
        // First, we need to compute the ASCII representation of the error code. We assume that it is in the 0-999
        // range, so we only need to convert three digits. To convert the digits to ASCII, we add 0x30, the value for
        // the '0' character.

        let units := add(mod(errorCode, 10), 0x30)

        errorCode := div(errorCode, 10)
        let tenths := add(mod(errorCode, 10), 0x30)

        errorCode := div(errorCode, 10)
        let hundreds := add(mod(errorCode, 10), 0x30)

        // With the individual characters, we can now construct the full string. The "BAL#" part is a known constant
        // (0x42414c23): we simply shift this by 24 (to provide space for the 3 bytes of the error code), and add the
        // characters to it, each shifted by a multiple of 8.
        // The revert reason is then shifted left by 200 bits (256 minus the length of the string, 7 characters * 8 bits
        // per character = 56) to locate it in the most significant part of the 256 slot (the beginning of a byte
        // array).

        let revertReason := shl(200, add(0x42414c23000000, add(add(units, shl(8, tenths)), shl(16, hundreds))))

        // We can now encode the reason in memory, which can be safely overwritten as we're about to revert. The encoded
        // message will have the following layout:
        // [ revert reason identifier ] [ string location offset ] [ string length ] [ string contents ]

        // The Solidity revert reason identifier is 0x08c739a0, the function selector of the Error(string) function. We
        // also write zeroes to the next 28 bytes of memory, but those are about to be overwritten.
        mstore(0x0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
        // Next is the offset to the location of the string, which will be placed immediately after (20 bytes away).
        mstore(0x04, 0x0000000000000000000000000000000000000000000000000000000000000020)
        // The string length is fixed: 7 characters.
        mstore(0x24, 7)
        // Finally, the string itself is stored.
        mstore(0x44, revertReason)

        // Even if the string is only 7 bytes long, we need to return a full 32 byte slot containing it. The length of
        // the encoded message is therefore 4 + 32 + 32 + 32 = 100.
        revert(0, 100)
    }
}

library Errors {
    // Math
    uint256 internal constant ADD_OVERFLOW = 0;
    uint256 internal constant SUB_OVERFLOW = 1;
    uint256 internal constant SUB_UNDERFLOW = 2;
    uint256 internal constant MUL_OVERFLOW = 3;
    uint256 internal constant ZERO_DIVISION = 4;
    uint256 internal constant DIV_INTERNAL = 5;
    uint256 internal constant X_OUT_OF_BOUNDS = 6;
    uint256 internal constant Y_OUT_OF_BOUNDS = 7;
    uint256 internal constant PRODUCT_OUT_OF_BOUNDS = 8;
    uint256 internal constant INVALID_EXPONENT = 9;

    // Input
    uint256 internal constant OUT_OF_BOUNDS = 100;
    uint256 internal constant UNSORTED_ARRAY = 101;
    uint256 internal constant UNSORTED_TOKENS = 102;
    uint256 internal constant INPUT_LENGTH_MISMATCH = 103;
    uint256 internal constant ZERO_TOKEN = 104;

    // Shared pools
    uint256 internal constant MIN_TOKENS = 200;
    uint256 internal constant MAX_TOKENS = 201;
    uint256 internal constant MAX_SWAP_FEE_PERCENTAGE = 202;
    uint256 internal constant MIN_SWAP_FEE_PERCENTAGE = 203;
    uint256 internal constant MINIMUM_BPT = 204;
    uint256 internal constant CALLER_NOT_VAULT = 205;
    uint256 internal constant UNINITIALIZED = 206;
    uint256 internal constant BPT_IN_MAX_AMOUNT = 207;
    uint256 internal constant BPT_OUT_MIN_AMOUNT = 208;
    uint256 internal constant EXPIRED_PERMIT = 209;

    // Pools
    uint256 internal constant MIN_AMP = 300;
    uint256 internal constant MAX_AMP = 301;
    uint256 internal constant MIN_WEIGHT = 302;
    uint256 internal constant MAX_STABLE_TOKENS = 303;
    uint256 internal constant MAX_IN_RATIO = 304;
    uint256 internal constant MAX_OUT_RATIO = 305;
    uint256 internal constant MIN_BPT_IN_FOR_TOKEN_OUT = 306;
    uint256 internal constant MAX_OUT_BPT_FOR_TOKEN_IN = 307;
    uint256 internal constant NORMALIZED_WEIGHT_INVARIANT = 308;
    uint256 internal constant INVALID_TOKEN = 309;
    uint256 internal constant UNHANDLED_JOIN_KIND = 310;
    uint256 internal constant ZERO_INVARIANT = 311;

    // Lib
    uint256 internal constant REENTRANCY = 400;
    uint256 internal constant SENDER_NOT_ALLOWED = 401;
    uint256 internal constant PAUSED = 402;
    uint256 internal constant PAUSE_WINDOW_EXPIRED = 403;
    uint256 internal constant MAX_PAUSE_WINDOW_DURATION = 404;
    uint256 internal constant MAX_BUFFER_PERIOD_DURATION = 405;
    uint256 internal constant INSUFFICIENT_BALANCE = 406;
    uint256 internal constant INSUFFICIENT_ALLOWANCE = 407;
    uint256 internal constant ERC20_TRANSFER_FROM_ZERO_ADDRESS = 408;
    uint256 internal constant ERC20_TRANSFER_TO_ZERO_ADDRESS = 409;
    uint256 internal constant ERC20_MINT_TO_ZERO_ADDRESS = 410;
    uint256 internal constant ERC20_BURN_FROM_ZERO_ADDRESS = 411;
    uint256 internal constant ERC20_APPROVE_FROM_ZERO_ADDRESS = 412;
    uint256 internal constant ERC20_APPROVE_TO_ZERO_ADDRESS = 413;
    uint256 internal constant ERC20_TRANSFER_EXCEEDS_ALLOWANCE = 414;
    uint256 internal constant ERC20_DECREASED_ALLOWANCE_BELOW_ZERO = 415;
    uint256 internal constant ERC20_TRANSFER_EXCEEDS_BALANCE = 416;
    uint256 internal constant ERC20_BURN_EXCEEDS_ALLOWANCE = 417;
    uint256 internal constant SAFE_ERC20_CALL_FAILED = 418;
    uint256 internal constant ADDRESS_INSUFFICIENT_BALANCE = 419;
    uint256 internal constant ADDRESS_CANNOT_SEND_VALUE = 420;
    uint256 internal constant SAFE_CAST_VALUE_CANT_FIT_INT256 = 421;
    uint256 internal constant GRANT_SENDER_NOT_ADMIN = 422;
    uint256 internal constant REVOKE_SENDER_NOT_ADMIN = 423;
    uint256 internal constant RENOUNCE_SENDER_NOT_ALLOWED = 424;
    uint256 internal constant BUFFER_PERIOD_EXPIRED = 425;

    // Vault
    uint256 internal constant INVALID_POOL_ID = 500;
    uint256 internal constant CALLER_NOT_POOL = 501;
    uint256 internal constant SENDER_NOT_ASSET_MANAGER = 502;
    uint256 internal constant USER_DOESNT_ALLOW_RELAYER = 503;
    uint256 internal constant INVALID_SIGNATURE = 504;
    uint256 internal constant EXIT_BELOW_MIN = 505;
    uint256 internal constant JOIN_ABOVE_MAX = 506;
    uint256 internal constant SWAP_LIMIT = 507;
    uint256 internal constant SWAP_DEADLINE = 508;
    uint256 internal constant CANNOT_SWAP_SAME_TOKEN = 509;
    uint256 internal constant UNKNOWN_AMOUNT_IN_FIRST_SWAP = 510;
    uint256 internal constant MALCONSTRUCTED_MULTIHOP_SWAP = 511;
    uint256 internal constant INTERNAL_BALANCE_OVERFLOW = 512;
    uint256 internal constant INSUFFICIENT_INTERNAL_BALANCE = 513;
    uint256 internal constant INVALID_ETH_INTERNAL_BALANCE = 514;
    uint256 internal constant INVALID_POST_LOAN_BALANCE = 515;
    uint256 internal constant INSUFFICIENT_ETH = 516;
    uint256 internal constant UNALLOCATED_ETH = 517;
    uint256 internal constant ETH_TRANSFER = 518;
    uint256 internal constant CANNOT_USE_ETH_SENTINEL = 519;
    uint256 internal constant TOKENS_MISMATCH = 520;
    uint256 internal constant TOKEN_NOT_REGISTERED = 521;
    uint256 internal constant TOKEN_ALREADY_REGISTERED = 522;
    uint256 internal constant TOKENS_ALREADY_SET = 523;
    uint256 internal constant TOKENS_LENGTH_MUST_BE_2 = 524;
    uint256 internal constant NONZERO_TOKEN_BALANCE = 525;
    uint256 internal constant BALANCE_TOTAL_OVERFLOW = 526;
    uint256 internal constant POOL_NO_TOKENS = 527;
    uint256 internal constant INSUFFICIENT_FLASH_LOAN_BALANCE = 528;

    // Fees
    uint256 internal constant SWAP_FEE_PERCENTAGE_TOO_HIGH = 600;
    uint256 internal constant FLASH_LOAN_FEE_PERCENTAGE_TOO_HIGH = 601;
    uint256 internal constant INSUFFICIENT_FLASH_LOAN_FEE_AMOUNT = 602;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

import "../helpers/BalancerErrors.sol";

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow checks.
 * Adapted from OpenZeppelin's SafeMath library
 */
library Math {
    /**
     * @dev Returns the addition of two unsigned integers of 256 bits, reverting on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        _require(c >= a, Errors.ADD_OVERFLOW);
        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        _require((b >= 0 && c >= a) || (b < 0 && c < a), Errors.ADD_OVERFLOW);
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers of 256 bits, reverting on overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        _require(b <= a, Errors.SUB_OVERFLOW);
        uint256 c = a - b;
        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        _require((b >= 0 && c <= a) || (b < 0 && c > a), Errors.SUB_OVERFLOW);
        return c;
    }

    /**
     * @dev Returns the largest of two numbers of 256 bits.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers of 256 bits.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        _require(a == 0 || c / a == b, Errors.MUL_OVERFLOW);
        return c;
    }

    function divDown(uint256 a, uint256 b) internal pure returns (uint256) {
        _require(b != 0, Errors.ZERO_DIVISION);
        return a / b;
    }

    function divUp(uint256 a, uint256 b) internal pure returns (uint256) {
        _require(b != 0, Errors.ZERO_DIVISION);

        if (a == 0) {
            return 0;
        } else {
            return 1 + (a - 1) / b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}