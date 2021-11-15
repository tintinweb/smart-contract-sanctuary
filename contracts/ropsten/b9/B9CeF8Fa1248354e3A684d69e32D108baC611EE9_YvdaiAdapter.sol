// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

import "./interfaces/external/yearn/IVault.sol";
import "./AdapterBase.sol";

// https://docs.yearn.finance/developers/yvaults-documentation/vault-interfaces#ivault
contract YvdaiAdapter is AdapterBase {
    address public governanceAccount;
    address public underlyingTokenAddress;
    address public programAddress;
    address public farmingPoolAccount;

    IVault private _yvdai;

    constructor(
        address underlyingTokenAddress_,
        address programAddress_,
        address farmingPoolAccount_
    ) {
        require(
            underlyingTokenAddress_ != address(0),
            "YvdaiAdapter: underlying token address is the zero address"
        );
        require(
            programAddress_ != address(0),
            "YvdaiAdapter: yvDai address is the zero address"
        );
        require(
            farmingPoolAccount_ != address(0),
            "YvdaiAdapter: farming pool account is the zero address"
        );

        governanceAccount = msg.sender;
        underlyingTokenAddress = underlyingTokenAddress_;
        programAddress = programAddress_;
        farmingPoolAccount = farmingPoolAccount_;

        _yvdai = IVault(programAddress);
    }

    modifier onlyBy(address account) {
        require(msg.sender == account, "YvdaiAdapter: sender not authorized");
        _;
    }

    function getTotalWrappedTokenAmountCore()
        internal
        view
        override
        returns (uint256)
    {
        return _yvdai.balanceOf(msg.sender);
    }

    function getWrappedTokenPriceInUnderlyingCore()
        internal
        view
        override
        returns (uint256)
    {
        return _yvdai.pricePerShare();
    }

    // https://github.com/crytic/slither/wiki/Detector-Documentation#reentrancy-vulnerabilities-3
    // The reentrancy check is in farming pool.
    function depositUnderlyingToken(uint256 amount)
        external
        override
        onlyBy(farmingPoolAccount)
        returns (uint256)
    {
        require(amount != 0, "YvdaiAdapter: can't add 0");

        uint256 receivedWrappedTokenQuantity =
            _yvdai.deposit(amount, address(this));

        // slither-disable-next-line reentrancy-events
        emit DepositUnderlyingToken(
            underlyingTokenAddress,
            programAddress,
            amount,
            receivedWrappedTokenQuantity,
            msg.sender,
            block.timestamp
        );

        return receivedWrappedTokenQuantity;
    }

    // https://github.com/crytic/slither/wiki/Detector-Documentation#reentrancy-vulnerabilities-3
    // The reentrancy check is in farming pool.
    function redeemWrappedToken(uint256 amount)
        external
        override
        onlyBy(farmingPoolAccount)
        returns (uint256)
    {
        require(amount != 0, "YvdaiAdapter: can't redeem 0");

        // The default maxLoss is 1: https://github.com/yearn/yearn-vaults/blob/v0.3.0/contracts/Vault.vy#L860
        uint256 receivedUnderlyingTokenQuantity =
            _yvdai.withdraw(amount, msg.sender, 1);

        // slither-disable-next-line reentrancy-events
        emit RedeemWrappedToken(
            underlyingTokenAddress,
            programAddress,
            amount,
            receivedUnderlyingTokenQuantity,
            msg.sender,
            block.timestamp
        );

        return receivedUnderlyingTokenQuantity;
    }

    function setGovernanceAccount(address newGovernanceAccount)
        external
        onlyBy(governanceAccount)
    {
        require(
            newGovernanceAccount != address(0),
            "YvdaiAdapter: new governance account is the zero address"
        );

        governanceAccount = newGovernanceAccount;
    }

    function setFarmingPoolAccount(address newFarmingPoolAccount)
        external
        onlyBy(governanceAccount)
    {
        require(
            newFarmingPoolAccount != address(0),
            "YvdaiAdapter: new farming pool account is the zero address"
        );

        farmingPoolAccount = newFarmingPoolAccount;
    }

    function sweep(address to) external override onlyBy(governanceAccount) {
        require(
            to != address(0),
            "YvdaiAdapter: the address to be swept is the zero address"
        );

        uint256 balance = _yvdai.balanceOf(address(this));
        emit Sweep(address(this), to, balance, msg.sender, block.timestamp);

        bool isTransferSuccessful = _yvdai.transfer(to, balance);
        require(isTransferSuccessful, "YvdaiAdapter: sweep failed");
    }
}

// SPDX-License-Identifier: MIT

// v1:
//  - https://docs.yearn.finance/developers/yvaults-documentation/vault-interfaces#ivault
//  - https://github.com/yearn/yearn-protocol/blob/develop/interfaces/yearn/IVault.sol
//
// Current:
//  - https://etherscan.io/address/0x19D3364A399d251E894aC732651be8B0E4e85001#code
//  - https://github.com/yearn/yearn-vaults/blob/v0.3.0/contracts/Vault.vy

pragma solidity ^0.7.6;

interface IVault {
    /**
     * @notice Gives the price for a single Vault share.
     * @dev See dev note on `withdraw`.
     * @return The value of a single share.
     */
    function pricePerShare() external view returns (uint256);

    function deposit() external returns (uint256);

    function deposit(uint256 _amount) external returns (uint256);

    function deposit(uint256 _amount, address recipient)
        external
        returns (uint256);

    /**
     * @notice
     *     Withdraws the calling account's tokens from this Vault, redeeming
     *     amount `_shares` for an appropriate amount of tokens.
     *     See note on `setWithdrawalQueue` for further details of withdrawal
     *     ordering and behavior.
     * @dev
     *     Measuring the value of shares is based on the total outstanding debt
     *     that this contract has ("expected value") instead of the total balance
     *     sheet it has ("estimated value") has important security considerations,
     *     and is done intentionally. If this value were measured against external
     *     systems, it could be purposely manipulated by an attacker to withdraw
     *     more assets than they otherwise should be able to claim by redeeming
     *     their shares.
     *     On withdrawal, this means that shares are redeemed against the total
     *     amount that the deposited capital had "realized" since the point it
     *     was deposited, up until the point it was withdrawn. If that number
     *     were to be higher than the "expected value" at some future point,
     *     withdrawing shares via this method could entitle the depositor to
     *     *more* than the expected value once the "realized value" is updated
     *     from further reports by the Strategies to the Vaults.
     *     Under exceptional scenarios, this could cause earlier withdrawals to
     *     earn "more" of the underlying assets than Users might otherwise be
     *     entitled to, if the Vault's estimated value were otherwise measured
     *     through external means, accounting for whatever exceptional scenarios
     *     exist for the Vault (that aren't covered by the Vault's own design.)
     * @param maxShares How many shares to try and redeem for tokens, defaults to
     *                  all.
     * @param recipient The address to issue the shares in this Vault to. Defaults
     *                  to the caller's address.
     * @param maxLoss   The maximum acceptable loss to sustain on withdrawal. Defaults
     *                  to 0%.
     * @return The quantity of tokens redeemed for `_shares`.
     */
    function withdraw(
        uint256 maxShares,
        address recipient,
        uint256 maxLoss
    ) external returns (uint256);

    function balanceOf(address) external view returns (uint256);

    /**
     * @notice
     *     Transfers shares from the caller's address to `receiver`. This function
     *     will always return true, unless the user is attempting to transfer
     *     shares to this contract's address, or to 0x0.
     * @param receiver  The address shares are being transferred to. Must not be
     *                   this contract's address, must not be 0x0.
     * @param amount    The quantity of shares to transfer.
     * @return
     *     True if transfer is sent to an address other than this contract's or
     *     0x0, otherwise the transaction will fail.
     */
    function transfer(address receiver, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/IAdapter.sol";

abstract contract AdapterBase is IAdapter {
    using SafeMath for uint256;

    function getTotalWrappedTokenAmountCore()
        internal
        view
        virtual
        returns (uint256);

    function getWrappedTokenPriceInUnderlyingCore()
        internal
        view
        virtual
        returns (uint256);

    function getWrappedTokenPriceInUnderlying()
        external
        view
        override
        returns (uint256)
    {
        return getWrappedTokenPriceInUnderlyingCore();
    }

    function getRedeemableUnderlyingTokensFor(uint256 amount)
        external
        view
        override
        returns (uint256)
    {
        uint256 price = getWrappedTokenPriceInUnderlyingCore();

        return amount.mul(price);
    }

    function getTotalRedeemableUnderlyingTokens()
        external
        view
        override
        returns (uint256)
    {
        uint256 totalWrappedTokenAmount = getTotalWrappedTokenAmountCore();
        uint256 price = getWrappedTokenPriceInUnderlyingCore();

        return totalWrappedTokenAmount.mul(price);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

interface IAdapter {
    function getWrappedTokenPriceInUnderlying() external view returns (uint256);

    function getTotalRedeemableUnderlyingTokens()
        external
        view
        returns (uint256);

    function getRedeemableUnderlyingTokensFor(uint256 amount)
        external
        view
        returns (uint256);

    function depositUnderlyingToken(uint256 amount) external returns (uint256);

    function redeemWrappedToken(uint256 amount) external returns (uint256);

    function sweep(address to) external;

    event DepositUnderlyingToken(
        address indexed underlyingAssetAddress,
        address indexed wrappedTokenAddress,
        uint256 underlyingAssetAmount,
        uint256 wrappedTokenQuantity,
        address operator,
        uint256 timestamp
    );

    event RedeemWrappedToken(
        address indexed underlyingAssetAddress,
        address indexed wrappedTokenAddress,
        uint256 wrappedTokenAmount,
        uint256 underlyingAssetQuantity,
        address operator,
        uint256 timestamp
    );

    event Sweep(
        address indexed from,
        address indexed to,
        uint256 amount,
        address operator,
        uint256 timestamp
    );
}

