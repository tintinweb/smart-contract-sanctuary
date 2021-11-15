pragma solidity ^0.7.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



import "./CoinwindStrategy.sol";

contract BscCoinwindStrategy is CoinwindStrategy {

    constructor(uint16 _want, uint256 _pid) CoinwindStrategy(_want, _pid) {}

    /// @notice https://bscscan.com/token/0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c
    function weth() public override pure returns (address) {
        return address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    }

    /// @notice https://bscscan.com/address/0x52d22f040dee3027422e837312320b42e1fd737f
    function coinwind() public override pure returns (address) {
        return address(0x52d22F040dEE3027422e837312320b42e1fD737f);
    }

    /// @notice https://bscscan.com/token/0x422e3af98bc1de5a1838be31a56f75db4ad43730
    function cow() public override pure returns (address) {
        return address(0x422E3aF98bC1dE5a1838BE31A56f75DB4Ad43730);
    }

    /// @notice https://bscscan.com/token/0x9c65ab58d8d978db963e63f2bfb7121627e3a739
    function mdx() public override pure returns (address) {
        return address(0x9C65AB58d8d978DB963e63f2bfB7121627e3a739);
    }
}

pragma solidity ^0.7.0;
pragma abicoder v2;

// SPDX-License-Identifier: MIT OR Apache-2.0




import "./BaseStrategy.sol";
import "./ICoinwind.sol";

import "../SafeMath.sol";

/// @notice coinwind strategy
/// user deposited asset to coinwind will remain unchanged
/// user reward token is COW and MDX
abstract contract CoinwindStrategy is BaseStrategy {

    using SafeMath for uint256;

    event Withdraw(uint256 amountNeeded, uint256 depositedBeforeWithdraw, uint256 depositedAfterWithdraw, uint256 loss);

    uint256 public pid;

    constructor(uint16 _want, uint256 _pid) BaseStrategy(_want) {
        initCoinwind(_pid);
    }

    function initCoinwind(uint256 _pid) virtual internal {
        pid = _pid;
        (address token,,,,,,,,,,,) = ICoinwind(coinwind()).poolInfo(_pid);
        require(wantToken == token, 'CoinwindStrategy: want token not match');
    }

    /// @notice coinwind contract address
    function coinwind() public virtual view returns (address);

    /// @notice cow token address
    function cow() public virtual view returns (address);

    /// @notice mdx token address
    function mdx() public virtual view returns (address);

    /// @notice user deposited asset to coinwind will remain unchanged
    function wantNetValue() external override view returns (uint256) {
        uint256 deposited = ICoinwind(coinwind()).getDepositAsset(wantToken, address(this));
        uint256 balance = IERC20(wantToken).balanceOf(address(this));
        return balance.add(deposited);
    }

    function deposit() onlyVault external override {
        // coinwind only accept erc20 token, if want is platform token, we should first wrap it
        if (want == 0 && address(this).balance > 0) {
            IWETH(wantToken).deposit{value: address(this).balance}();
        }
        uint256 balance = IERC20(wantToken).balanceOf(address(this));
        require(balance > 0, 'CoinwindStrategy: deposit nothing');

        deposit(balance);
    }

    /// @notice coinwind withdraw will harvest before repay token
    function withdraw(uint256 amountNeeded) onlyVault external override returns (uint256) {
        require(amountNeeded > 0, 'CoinwindStrategy: withdraw nothing');

        // make sure deposited token is enough to withdraw
        uint256 depositedBeforeWithdraw = ICoinwind(coinwind()).getDepositAsset(wantToken, address(this));
        require(depositedBeforeWithdraw >= amountNeeded, 'CoinwindStrategy: deposited asset not enough');

        // withdraw want token from coinwind, we must check withdraw loss though coinwind says there is no loss when withdraw
        // according to it's document https://docs.coinwind.com/guide/singlefarms
        uint256 balanceBeforeWithdraw = IERC20(wantToken).balanceOf(address(this));
        ICoinwind(coinwind()).withdraw(wantToken, amountNeeded);
        uint256 balanceAfterWithdraw = IERC20(wantToken).balanceOf(address(this));
        uint256 depositedAfterWithdraw = ICoinwind(coinwind()).getDepositAsset(wantToken, address(this));

        // cal loss and transfer all token of strategy to vault
        uint256 depositedDiff = depositedBeforeWithdraw.sub(depositedAfterWithdraw);
        require(depositedDiff >= amountNeeded, 'CoinwindStrategy: withdraw goal not completed');
        uint256 withdrawn = balanceAfterWithdraw.sub(balanceBeforeWithdraw);
        uint256 loss;
        if (depositedDiff > withdrawn) {
            loss = depositedDiff - withdrawn;
        }
        safeTransferWantTokenToVault(balanceAfterWithdraw);

        emit Withdraw(amountNeeded, depositedBeforeWithdraw, depositedAfterWithdraw, loss);

        return loss;
    }

    /// @notice harvest all pending rewards at once
    function harvest() onlyVault external override {
        // set withdraw amount to zero
        ICoinwind(coinwind()).withdraw(wantToken, 0);

        // transfer reward tokens to vault
        harvestAllRewardTokenToVault();
    }

    function migrate(address _newStrategy) onlyVault external override {
        // withdraw all token with harvest
        ICoinwind(coinwind()).withdrawAll(wantToken);

        // transfer want token to new strategy
        uint256 balance = IERC20(wantToken).balanceOf(address(this));
        if (balance > 0) {
            require(Utils.sendERC20(IERC20(wantToken), _newStrategy, balance), 'CoinwindStrategy: want token transfer failed');
        }

        // transfer reward tokens to vault
        harvestAllRewardTokenToVault();
    }

    /// @notice deposit want token to coinwind if there are any
    function onMigrate() onlyVault external override {
        uint256 balance = IERC20(wantToken).balanceOf(address(this));
        if (balance > 0) {
            deposit(balance);
        }
    }

    /// @notice emergency withdraw from coinwind without harvest
    function emergencyExit() onlyVault external override {
        ICoinwind(coinwind()).emergencyWithdraw(pid);
        uint256 balance = IERC20(wantToken).balanceOf(address(this));
        if (balance > 0) {
            safeTransferWantTokenToVault(balance);
        }
        // we still try send reward token to vault though emergency withdraw of coinwind has no reward
        harvestAllRewardTokenToVault();
    }

    /// @notice deposit amount of token to coinwind
    function deposit(uint256 amount) internal {
        // only approve limited amount of token to coinwind
        IERC20(wantToken).approve(coinwind(), amount);
        ICoinwind(coinwind()).deposit(wantToken, amount);
    }

    /// @notice harvest cow and mdx to vault
    function harvestAllRewardTokenToVault() internal {
        harvestRewardTokenToVault(cow());
        harvestRewardTokenToVault(mdx());
    }

    /// @notice harvest reward token to vault
    function harvestRewardTokenToVault(address rewardToken) internal {
        uint256 balance = IERC20(rewardToken).balanceOf(address(this));
        if (balance > 0) {
            require(Utils.sendERC20(IERC20(rewardToken), vault(), balance), 'CoinwindStrategy: reward token transfer failed');
            emit Harvest(want, rewardToken, balance);
        }
    }
}

pragma solidity ^0.7.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



import "../IStrategy.sol";
import "../IVault.sol";
import "../Utils.sol";
import "../IERC20.sol";

import "./IWETH.sol";

abstract contract BaseStrategy is IStrategy {

    event Harvest(uint256 want, address rewardToken, uint256 amount);

    /// @notice Vault is a proxy address and will be not changed after upgrade
    address public constant VAULT_ADDRESS = 0xd810D67E0bdbC823f8EF7F04FEF0299508C28404;

    /// @notice want token id
    uint16 public override want;
    /// @notice want token address, if want == 0 then wantToken is wrapped platform token or erc20 token managed by Governance contract
    address public wantToken;

    modifier onlyVault {
        require(msg.sender == vault(), 'BaseStrategy: require Vault');
        _;
    }

    constructor(uint16 _want) {
        initWant(_want);
    }

    function initWant(uint16 _want) virtual internal {
        want = _want;
        if (want == 0) {
            wantToken = weth();
        } else {
            wantToken = IVault(vault()).wantToken(_want);
        }
    }

    /// @notice receive platform token
    receive() external payable {}

    function vault() public virtual override view returns (address) {
        return VAULT_ADDRESS;
    }

    /// @notice Return wrapped platform token address:WETH, WBNB, WHT
    function weth() public virtual view returns (address);

    /// @notice transfer want token to vault
    function safeTransferWantTokenToVault(uint256 amount) internal {
        // do not use wantToken == weth() condition, we must use want token id to determine what asset vault really need
        // if ETH and WETH both in vault, ETH token id = 0, WETH token id = 1
        // the two asset have different want token id in strategy but have the same wantToken(WETH)
        if (want == 0) {
            IWETH(wantToken).withdraw(amount);
            (bool success, ) = vault().call{value: amount}("");
            require(success, "BaseStrategy: eth transfer failed");
        } else {
            require(Utils.sendERC20(IERC20(wantToken), vault(), amount), 'BaseStrategy: erc20 transfer failed');
        }
    }
}

pragma solidity ^0.7.0;
pragma abicoder v2;

// SPDX-License-Identifier: MIT




/// @notice interface come from https://bscscan.com/bytecode-decompiler?a=0x52d22f040dee3027422e837312320b42e1fd737f
/// HECO contract address: 0x22F560e032b256e8C7Cb50253591B0850162cb74
/// BSC contract address: 0x52d22f040dee3027422e837312320b42e1fd737f
/// Amount deposited to coinwind will not increase or decrease and farm reward token is COW and MDX
interface ICoinwind {

    struct PoolCowInfo {
        uint256 accCowPerShare;
        uint256 accCowShare;
        uint256 blockCowReward;
        uint256 blockMdxReward;
    }

    /// @notice return pool length
    function poolLength() external view returns (uint256);

    /// @notice return pool info
    function poolInfo(uint256 pid) external view returns (
        address token,
        uint256 lastRewardBlock,
        uint256 accMdxPerShare,
        uint256 govAccMdxPerShare,
        uint256 accMdxShare,
        uint256 totalAmount,
        uint256 totalAmountLimit,
        uint256 profit,
        uint256 earnLowerlimit,
        uint256 min,
        uint256 lastRewardBlockProfit,
        PoolCowInfo memory cowInfo);

    /// @notice deposit amount of token to coinwind
    function deposit(address token, uint256 amount) external;

    /// @notice deposit all amount of token to coinwind
    function depositAll(address token) external;

    /// @notice return the token amount user deposited
    function getDepositAsset(address token, address userAddress) external view returns (uint256);

    /// @notice withdraw amount token from coinwind and harvest all pending reward
    function withdraw(address token, uint256 amount) external;

    /// @notice withdraw all token from coinwind and harvest all pending reward
    function withdrawAll(address token) external;

    /// @notice withdraw all token from coinwind without harvest
    function emergencyWithdraw(uint256 pid) external;
}

pragma solidity ^0.7.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



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
        require(c >= a, "14");

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
        return sub(a, b, "v");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
        require(c / a == b, "15");

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
        return div(a, b, "x");
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "y");
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.7.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



/// @title Interface of the strategy contract
/// @author ZkLink Labs
/// @notice IStrategy implement must has default receive function
interface IStrategy {

    /**
     * @notice Returns the net value of want token in strategy
     * There are three kinds of strategy:
     * 1. want and reward token are the same, net value grows with time, no harvest
     * 2. want and reward token are different, want net value keep constant and reward token are transferred to vault after harvest
     * 3. want and reward token are different, want net value grows with time and reward token are transferred to vault after harvest
     */
    function wantNetValue() external view returns (uint256);

    /**
     * @notice Returns vault contract address.
     */
    function vault() external view returns (address);

    /**
     * @notice Returns token id strategy want to invest.
     */
    function want() external view returns (uint16);

    /**
    * @notice Response on vault deposit token to strategy
    */
    function deposit() external;

    /**
     * @notice Withdraw `amountNeeded` token to vault(may produce some loss). Token amount return back from strategy may be a little more than
     * amountNeeded. amountNeeded <= amountActuallyTransferredToVault + loss
     * @param amountNeeded amount need to withdraw from strategy
     * @return loss that happened in withdraw
     */
    function withdraw(uint256 amountNeeded) external returns (uint256);

    /**
     * @notice Harvest reward tokens to vault.
     */
    function harvest() external;

    /**
     * @notice Migrate all assets to `_newStrategy`.
     */
    function migrate(address _newStrategy) external;

    /**
     * @notice Response after old strategy migrate all assets to this new strategy
     */
    function onMigrate() external;

    /**
     * @notice Emergency exit from strategy, all assets will return back to vault regardless of loss
     */
    function emergencyExit() external;
}

pragma solidity ^0.7.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



/// @title Interface of the vault contract
/// @author ZkLink Labs
interface IVault {

    /// @notice return want token by id
    /// @param wantId must be erc20 token id
    function wantToken(uint16 wantId) external view returns (address);

    /// @notice Record user deposit(can only be call by zkSync), after deposit debt of vault will increase
    /// @param tokenId Token id
    /// @param amount Token amount
    function recordDeposit(uint16 tokenId, uint256 amount) external;

    /// @notice Withdraw token from vault to satisfy user withdraw request(can only be call by zkSync)
    /// @notice Withdraw may produce loss, after withdraw debt of vault will decrease
    /// @dev More details see test/vault_withdraw_test.js
    /// @param tokenId Token id
    /// @param to Token receive address
    /// @param amount Amount of tokens to transfer
    /// @param maxAmount Maximum possible amount of tokens to transfer
    /// @param lossBip Loss bip which user can accept, 100 means 1% loss
    /// @return uint256 Amount debt of vault decreased
    function withdraw(uint16 tokenId, address to, uint256 amount, uint256 maxAmount, uint256 lossBip) external returns (uint256);
}

pragma solidity ^0.7.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



import "./IERC20.sol";
import "./Bytes.sol";

library Utils {
    /// @notice Returns lesser of two values
    function minU32(uint32 a, uint32 b) internal pure returns (uint32) {
        return a < b ? a : b;
    }

    /// @notice Returns lesser of two values
    function minU64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    /// @notice Sends tokens
    /// @dev NOTE: this function handles tokens that have transfer function not strictly compatible with ERC20 standard
    /// @dev NOTE: call `transfer` to this token may return (bool) or nothing
    /// @param _token Token address
    /// @param _to Address of recipient
    /// @param _amount Amount of tokens to transfer
    /// @return bool flag indicating that transfer is successful
    function sendERC20(
        IERC20 _token,
        address _to,
        uint256 _amount
    ) internal returns (bool) {
        (bool callSuccess, bytes memory callReturnValueEncoded) =
            address(_token).call(abi.encodeWithSignature("transfer(address,uint256)", _to, _amount));
        // `transfer` method may return (bool) or nothing.
        bool returnedSuccess = callReturnValueEncoded.length == 0 || abi.decode(callReturnValueEncoded, (bool));
        return callSuccess && returnedSuccess;
    }

    /// @notice Transfers token from one address to another
    /// @dev NOTE: this function handles tokens that have transfer function not strictly compatible with ERC20 standard
    /// @dev NOTE: call `transferFrom` to this token may return (bool) or nothing
    /// @param _token Token address
    /// @param _from Address of sender
    /// @param _to Address of recipient
    /// @param _amount Amount of tokens to transfer
    /// @return bool flag indicating that transfer is successful
    function transferFromERC20(
        IERC20 _token,
        address _from,
        address _to,
        uint256 _amount
    ) internal returns (bool) {
        (bool callSuccess, bytes memory callReturnValueEncoded) =
            address(_token).call(abi.encodeWithSignature("transferFrom(address,address,uint256)", _from, _to, _amount));
        // `transferFrom` method may return (bool) or nothing.
        bool returnedSuccess = callReturnValueEncoded.length == 0 || abi.decode(callReturnValueEncoded, (bool));
        return callSuccess && returnedSuccess;
    }

    /// @notice Recovers signer's address from ethereum signature for given message
    /// @param _signature 65 bytes concatenated. R (32) + S (32) + V (1)
    /// @param _messageHash signed message hash.
    /// @return address of the signer
    function recoverAddressFromEthSignature(bytes memory _signature, bytes32 _messageHash)
        internal
        pure
        returns (address)
    {
        require(_signature.length == 65, "P"); // incorrect signature length

        bytes32 signR;
        bytes32 signS;
        uint8 signV;
        assembly {
            signR := mload(add(_signature, 32))
            signS := mload(add(_signature, 64))
            signV := byte(0, mload(add(_signature, 96)))
        }

        return ecrecover(_messageHash, signV, signR, signS);
    }

    /// @notice Returns new_hash = hash(old_hash + bytes)
    function concatHash(bytes32 _hash, bytes memory _bytes) internal pure returns (bytes32) {
        bytes32 result;
        assembly {
            let bytesLen := add(mload(_bytes), 32)
            mstore(_bytes, _hash)
            result := keccak256(_bytes, bytesLen)
        }
        return result;
    }

    function hashBytesToBytes20(bytes memory _bytes) internal pure returns (bytes20) {
        return bytes20(uint160(uint256(keccak256(_bytes))));
    }
}

pragma solidity ^0.7.0;

// SPDX-License-Identifier: UNLICENSED


/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

pragma solidity ^0.7.0;

// SPDX-License-Identifier: MIT



/// @notice interface come from contract address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2) in eth main net
/// bsc WBNB contract address: 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c
/// heco WHT contract address: 0x5545153ccfca01fbd7dd11c0b23ba694d9509a6f
/// WETH, WBNB and WHT has the same interface
interface IWETH {

    function deposit() external payable;

    function withdraw(uint256) external;
}

pragma solidity ^0.7.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



// Functions named bytesToX, except bytesToBytes20, where X is some type of size N < 32 (size of one word)
// implements the following algorithm:
// f(bytes memory input, uint offset) -> X out
// where byte representation of out is N bytes from input at the given offset
// 1) We compute memory location of the word W such that last N bytes of W is input[offset..offset+N]
// W_address = input + 32 (skip stored length of bytes) + offset - (32 - N) == input + offset + N
// 2) We load W from memory into out, last N bytes of W are placed into out

library Bytes {
    function toBytesFromUInt16(uint16 self) internal pure returns (bytes memory _bts) {
        return toBytesFromUIntTruncated(uint256(self), 2);
    }

    function toBytesFromUInt24(uint24 self) internal pure returns (bytes memory _bts) {
        return toBytesFromUIntTruncated(uint256(self), 3);
    }

    function toBytesFromUInt32(uint32 self) internal pure returns (bytes memory _bts) {
        return toBytesFromUIntTruncated(uint256(self), 4);
    }

    function toBytesFromUInt128(uint128 self) internal pure returns (bytes memory _bts) {
        return toBytesFromUIntTruncated(uint256(self), 16);
    }

    // Copies 'len' lower bytes from 'self' into a new 'bytes memory'.
    // Returns the newly created 'bytes memory'. The returned bytes will be of length 'len'.
    function toBytesFromUIntTruncated(uint256 self, uint8 byteLength) private pure returns (bytes memory bts) {
        require(byteLength <= 32, "Q");
        bts = new bytes(byteLength);
        // Even though the bytes will allocate a full word, we don't want
        // any potential garbage bytes in there.
        uint256 data = self << ((32 - byteLength) * 8);
        assembly {
            mstore(
                add(bts, 32), // BYTES_HEADER_SIZE
                data
            )
        }
    }

    // Copies 'self' into a new 'bytes memory'.
    // Returns the newly created 'bytes memory'. The returned bytes will be of length '20'.
    function toBytesFromAddress(address self) internal pure returns (bytes memory bts) {
        bts = toBytesFromUIntTruncated(uint256(self), 20);
    }

    // See comment at the top of this file for explanation of how this function works.
    // NOTE: theoretically possible overflow of (_start + 20)
    function bytesToAddress(bytes memory self, uint256 _start) internal pure returns (address addr) {
        uint256 offset = _start + 20;
        require(self.length >= offset, "R");
        assembly {
            addr := mload(add(self, offset))
        }
    }

    // Reasoning about why this function works is similar to that of other similar functions, except NOTE below.
    // NOTE: that bytes1..32 is stored in the beginning of the word unlike other primitive types
    // NOTE: theoretically possible overflow of (_start + 20)
    function bytesToBytes20(bytes memory self, uint256 _start) internal pure returns (bytes20 r) {
        require(self.length >= (_start + 20), "S");
        assembly {
            r := mload(add(add(self, 0x20), _start))
        }
    }

    // See comment at the top of this file for explanation of how this function works.
    // NOTE: theoretically possible overflow of (_start + 0x2)
    function bytesToUInt16(bytes memory _bytes, uint256 _start) internal pure returns (uint16 r) {
        uint256 offset = _start + 0x2;
        require(_bytes.length >= offset, "T");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // See comment at the top of this file for explanation of how this function works.
    // NOTE: theoretically possible overflow of (_start + 0x3)
    function bytesToUInt24(bytes memory _bytes, uint256 _start) internal pure returns (uint24 r) {
        uint256 offset = _start + 0x3;
        require(_bytes.length >= offset, "U");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // NOTE: theoretically possible overflow of (_start + 0x4)
    function bytesToUInt32(bytes memory _bytes, uint256 _start) internal pure returns (uint32 r) {
        uint256 offset = _start + 0x4;
        require(_bytes.length >= offset, "V");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // NOTE: theoretically possible overflow of (_start + 0x10)
    function bytesToUInt128(bytes memory _bytes, uint256 _start) internal pure returns (uint128 r) {
        uint256 offset = _start + 0x10;
        require(_bytes.length >= offset, "W");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // See comment at the top of this file for explanation of how this function works.
    // NOTE: theoretically possible overflow of (_start + 0x14)
    function bytesToUInt160(bytes memory _bytes, uint256 _start) internal pure returns (uint160 r) {
        uint256 offset = _start + 0x14;
        require(_bytes.length >= offset, "X");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // NOTE: theoretically possible overflow of (_start + 0x20)
    function bytesToBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32 r) {
        uint256 offset = _start + 0x20;
        require(_bytes.length >= offset, "Y");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // Original source code: https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol#L228
    // Get slice from bytes arrays
    // Returns the newly created 'bytes memory'
    // NOTE: theoretically possible overflow of (_start + _length)
    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_bytes.length >= (_start + _length), "Z"); // bytes length is less then start byte + length bytes

        bytes memory tempBytes = new bytes(_length);

        if (_length != 0) {
            assembly {
                let slice_curr := add(tempBytes, 0x20)
                let slice_end := add(slice_curr, _length)

                for {
                    let array_current := add(_bytes, add(_start, 0x20))
                } lt(slice_curr, slice_end) {
                    slice_curr := add(slice_curr, 0x20)
                    array_current := add(array_current, 0x20)
                } {
                    mstore(slice_curr, mload(array_current))
                }
            }
        }

        return tempBytes;
    }

    /// Reads byte stream
    /// @return new_offset - offset + amount of bytes read
    /// @return data - actually read data
    // NOTE: theoretically possible overflow of (_offset + _length)
    function read(
        bytes memory _data,
        uint256 _offset,
        uint256 _length
    ) internal pure returns (uint256 new_offset, bytes memory data) {
        data = slice(_data, _offset, _length);
        new_offset = _offset + _length;
    }

    // NOTE: theoretically possible overflow of (_offset + 1)
    function readBool(bytes memory _data, uint256 _offset) internal pure returns (uint256 new_offset, bool r) {
        new_offset = _offset + 1;
        r = uint8(_data[_offset]) != 0;
    }

    // NOTE: theoretically possible overflow of (_offset + 1)
    function readUint8(bytes memory _data, uint256 _offset) internal pure returns (uint256 new_offset, uint8 r) {
        new_offset = _offset + 1;
        r = uint8(_data[_offset]);
    }

    // NOTE: theoretically possible overflow of (_offset + 2)
    function readUInt16(bytes memory _data, uint256 _offset) internal pure returns (uint256 new_offset, uint16 r) {
        new_offset = _offset + 2;
        r = bytesToUInt16(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 3)
    function readUInt24(bytes memory _data, uint256 _offset) internal pure returns (uint256 new_offset, uint24 r) {
        new_offset = _offset + 3;
        r = bytesToUInt24(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 4)
    function readUInt32(bytes memory _data, uint256 _offset) internal pure returns (uint256 new_offset, uint32 r) {
        new_offset = _offset + 4;
        r = bytesToUInt32(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 16)
    function readUInt128(bytes memory _data, uint256 _offset) internal pure returns (uint256 new_offset, uint128 r) {
        new_offset = _offset + 16;
        r = bytesToUInt128(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 20)
    function readUInt160(bytes memory _data, uint256 _offset) internal pure returns (uint256 new_offset, uint160 r) {
        new_offset = _offset + 20;
        r = bytesToUInt160(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 20)
    function readAddress(bytes memory _data, uint256 _offset) internal pure returns (uint256 new_offset, address r) {
        new_offset = _offset + 20;
        r = bytesToAddress(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 20)
    function readBytes20(bytes memory _data, uint256 _offset) internal pure returns (uint256 new_offset, bytes20 r) {
        new_offset = _offset + 20;
        r = bytesToBytes20(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 32)
    function readBytes32(bytes memory _data, uint256 _offset) internal pure returns (uint256 new_offset, bytes32 r) {
        new_offset = _offset + 32;
        r = bytesToBytes32(_data, _offset);
    }

    /// Trim bytes into single word
    function trim(bytes memory _data, uint256 _new_length) internal pure returns (uint256 r) {
        require(_new_length <= 0x20, "10"); // new_length is longer than word
        require(_data.length >= _new_length, "11"); // data is to short

        uint256 a;
        assembly {
            a := mload(add(_data, 0x20)) // load bytes into uint256
        }

        return a >> ((0x20 - _new_length) * 8);
    }

    // Helper function for hex conversion.
    function halfByteToHex(bytes1 _byte) internal pure returns (bytes1 _hexByte) {
        require(uint8(_byte) < 0x10, "hbh11"); // half byte's value is out of 0..15 range.

        // "FEDCBA9876543210" ASCII-encoded, shifted and automatically truncated.
        return bytes1(uint8(0x66656463626139383736353433323130 >> (uint8(_byte) * 8)));
    }

    // Convert bytes to ASCII hex representation
    function bytesToHexASCIIBytes(bytes memory _input) internal pure returns (bytes memory _output) {
        bytes memory outStringBytes = new bytes(_input.length * 2);

        // code in `assembly` construction is equivalent of the next code:
        // for (uint i = 0; i < _input.length; ++i) {
        //     outStringBytes[i*2] = halfByteToHex(_input[i] >> 4);
        //     outStringBytes[i*2+1] = halfByteToHex(_input[i] & 0x0f);
        // }
        assembly {
            let input_curr := add(_input, 0x20)
            let input_end := add(input_curr, mload(_input))

            for {
                let out_curr := add(outStringBytes, 0x20)
            } lt(input_curr, input_end) {
                input_curr := add(input_curr, 0x01)
                out_curr := add(out_curr, 0x02)
            } {
                let curr_input_byte := shr(0xf8, mload(input_curr))
                // here outStringByte from each half of input byte calculates by the next:
                //
                // "FEDCBA9876543210" ASCII-encoded, shifted and automatically truncated.
                // outStringByte = byte (uint8 (0x66656463626139383736353433323130 >> (uint8 (_byteHalf) * 8)))
                mstore(
                    out_curr,
                    shl(0xf8, shr(mul(shr(0x04, curr_input_byte), 0x08), 0x66656463626139383736353433323130))
                )
                mstore(
                    add(out_curr, 0x01),
                    shl(0xf8, shr(mul(and(0x0f, curr_input_byte), 0x08), 0x66656463626139383736353433323130))
                )
            }
        }
        return outStringBytes;
    }
}

