// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

pragma experimental ABIEncoderV2;

import {Helpers} from "./helpers.sol";
import "./interface.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * Matic protocol staking connectors provide function to delegate, undelegate, restake and withdraw functions for matic tokens.  
 */
contract MaticProtocolStaking is Helpers {
    string public constant name = "MaticProtocol-v1";

    using SafeMath for uint256;

    /**
     *  @notice Delegate matic token to single validator by validator Id.
     *  
     *  @param validatorId Id of validator to whom matic tokens will be delegated.
     *  @param amount Total amount of matic to be delegated.
     *  @param minShare minimum share of validator pool should be recieved after delegation.
     *  @param getId If non zero than it will override amount and read it from memory contract.
     */
    function delegate(
        uint256 validatorId,
        uint256 amount,
        uint256 minShare,
        uint256 getId
    ) external payable {
        uint256 delegationAmount = getUint(getId, amount);
        IValidatorShareProxy validatorContractAddress = IValidatorShareProxy(
            stakeManagerProxy.getValidatorContract(validatorId)
        );
        require(address(validatorContractAddress) != address(0), "!Validator");
        validatorContractAddress.buyVoucher(delegationAmount, minShare);
    }

    /**
     * @notice Delegate matic token to multiple validators in one go. 
     * 
     * @param validatorIds List of validator Ids to whom delegation will be done.
     * @param amount Total amount of matic tokens to be delegated.
     * @param portions List of percentage from `amount` to delegate to each validator.
     * @param minShares List of minshares recieved for each validators. 
     * @param getId If non zero than it will override amount and read it from memory contract.
     */
    function delegateMultiple(
        uint256[] memory validatorIds,
        uint256 amount,
        uint256[] memory portions,
        uint256[] memory minShares,
        uint256 getId
    ) external payable {
        require(
            portions.length == validatorIds.length,
            "Validator and Portion length doesnt match"
        );
        uint256 delegationAmount = getUint(getId, amount);
        uint256 totalPortions = 0;

        uint256[] memory validatorAmount = new uint256[](validatorIds.length);

        for (uint256 position = 0; position < portions.length; position++) {
            validatorAmount[position] = portions[position]
                .mul(delegationAmount)
                .div(PORTIONS_SUM);
            totalPortions = totalPortions + portions[position];
        }

        require(totalPortions == PORTIONS_SUM, "Portion Mismatch");

        maticToken.approve(address(stakeManagerProxy), delegationAmount);

        for (uint256 i = 0; i < validatorIds.length; i++) {
            IValidatorShareProxy validatorContractAddress = IValidatorShareProxy(
                    stakeManagerProxy.getValidatorContract(validatorIds[i])
                );
            require(
                address(validatorContractAddress) != address(0),
                "!Validator"
            );
            validatorContractAddress.buyVoucher(
                validatorAmount[i],
                minShares[i]
            );
        }
    }
    /**
     * @notice Withdraw matic token rewards generated after delegation.
     * 
     * @param validatorId Id of Validator.
     * @param setId If set to non zero it will set reward amount to memory contract to be used by subsequent connectors. 
     */
    function withdrawRewards(uint256 validatorId, uint256 setId)
        external
        payable
    {
        IValidatorShareProxy validatorContractAddress = IValidatorShareProxy(
            stakeManagerProxy.getValidatorContract(validatorId)
        );
        require(address(validatorContractAddress) != address(0), "!Validator");
        uint256 initialBal = getTokenBal(maticToken);
        validatorContractAddress.withdrawRewards();
        uint256 finalBal = getTokenBal(maticToken);
        uint256 rewards = sub(finalBal, initialBal);
        setUint(setId, rewards);
    }

    /**
     * @notice Withdraw matic token rewards generated after delegationc from multiple validators.
     * 
     * @param validatorIds List of validators Ids.
     * @param setId If set to non zero it will set reward amount to memory contract to be used by subsequent connectors. 
     */
    function withdrawRewardsMultiple(
        uint256[] memory validatorIds,
        uint256 setId
    ) external payable {
        require(validatorIds.length > 0, "! validators Ids length");

        uint256 initialBal = getTokenBal(maticToken);
        for (uint256 i = 0; i < validatorIds.length; i++) {
            IValidatorShareProxy validatorContractAddress = IValidatorShareProxy(
                    stakeManagerProxy.getValidatorContract(validatorIds[i])
                );
            require(
                address(validatorContractAddress) != address(0),
                "!Validator"
            );
            validatorContractAddress.withdrawRewards();
        }
        uint256 finalBal = getTokenBal(maticToken);
        uint256 rewards = sub(finalBal, initialBal);
        setUint(setId, rewards);
    }

    /** 
     * @notice Trigger undelegation process from a single validator.
     * 
     * @param validatorId Id of validator.
     * @param claimAmount Total amount to be undelegated. 
     / @param maximumSharesToBurn Maximum shares to be burned.
     */
    function sellVoucher(
        uint256 validatorId,
        uint256 claimAmount,
        uint256 maximumSharesToBurn
    ) external payable {
        IValidatorShareProxy validatorContractAddress = IValidatorShareProxy(
            stakeManagerProxy.getValidatorContract(validatorId)
        );
        require(address(validatorContractAddress) != address(0), "!Validator");
        validatorContractAddress.sellVoucher_new(
            claimAmount,
            maximumSharesToBurn
        );
    }
    /** 
     * @notice Trigger undelegation process from multiple validators.
     * 
     * @param validatorIds List of Ids of validator.
     * @param claimAmounts List of claim amounts. 
     / @param maximumSharesToBurns List of maximum shares to burn for each validators. 
     */
    function sellVoucherMultiple(
        uint256[] memory validatorIds,
        uint256[] memory claimAmounts,
        uint256[] memory maximumSharesToBurns
    ) external payable {
        require(validatorIds.length > 0, "! validators Ids length");
        require((validatorIds.length == claimAmounts.length), "!claimAmount ");
        require(
            (validatorIds.length == maximumSharesToBurns.length),
            "!maximumSharesToBurns "
        );

        for (uint256 i = 0; i < validatorIds.length; i++) {
            IValidatorShareProxy validatorContractAddress = IValidatorShareProxy(
                    stakeManagerProxy.getValidatorContract(validatorIds[i])
                );
            require(
                address(validatorContractAddress) != address(0),
                "!Validator"
            );
            validatorContractAddress.sellVoucher_new(
                claimAmounts[i],
                maximumSharesToBurns[i]
            );
        }
    }

    /** 
     * @notice Restake rewards generated by delegation to a validator. 
     * 
     * @param validatorId Id of validator.
     */
    function restake(uint256 validatorId) external payable {
        IValidatorShareProxy validatorContractAddress = IValidatorShareProxy(
            stakeManagerProxy.getValidatorContract(validatorId)
        );
        require(address(validatorContractAddress) != address(0), "!Validator");
        validatorContractAddress.restake();
    }
    /** 
     * @notice Restake rewards generated by delegation to a multiple validators. 
     * 
     * @param validatorIds List of validator ids.
     */
    function restakeMultiple(uint256[] memory validatorIds) external payable {
        require(validatorIds.length > 0, "! validators Ids length");

        for (uint256 i = 0; i < validatorIds.length; i++) {
            IValidatorShareProxy validatorContractAddress = IValidatorShareProxy(
                    stakeManagerProxy.getValidatorContract(validatorIds[i])
                );
            require(
                address(validatorContractAddress) != address(0),
                "!Validator"
            );
            validatorContractAddress.restake();
        }
    }
    /** 
     * @notice Withdraw undelegated token after unbonding period is passed. 
     * 
     * @param validatorId Id of validator.
     * @param unbondNonce Nonce of unbond request. 
     */
    function unstakeClaimedTokens(uint256 validatorId, uint256 unbondNonce)
        external
        payable
    {
        IValidatorShareProxy validatorContractAddress = IValidatorShareProxy(
            stakeManagerProxy.getValidatorContract(validatorId)
        );
        require(address(validatorContractAddress) != address(0), "!Validator");
        validatorContractAddress.unstakeClaimTokens_new(unbondNonce);
    }

    /** 
     * @notice Multiple Withdraw undelegated tokens after unbonding period is passed. 
     * 
     * @param validatorIds List of validator Ids.
     * @param unbondNonces List of unbond nonces. 
     */
    function unstakeClaimedTokensMultiple(
        uint256[] memory validatorIds,
        uint256[] memory unbondNonces
    ) external payable {
        require(validatorIds.length > 0, "! validators Ids length");

        for (uint256 i = 0; i < validatorIds.length; i++) {
            IValidatorShareProxy validatorContractAddress = IValidatorShareProxy(
                    stakeManagerProxy.getValidatorContract(validatorIds[i])
                );
            require(
                address(validatorContractAddress) != address(0),
                "!Validator"
            );
            validatorContractAddress.unstakeClaimTokens_new(unbondNonces[i]);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

import {TokenInterface} from "../../common/interfaces.sol";
import {DSMath} from "../../common/math.sol";
import {Basic} from "../../common/basic.sol";
import "./interface.sol";

abstract contract Helpers is DSMath, Basic {
    IStakeManagerProxy public constant stakeManagerProxy =
        IStakeManagerProxy(0x00200eA4Ee292E253E6Ca07dBA5EdC07c8Aa37A3);

    TokenInterface public constant maticToken =
        TokenInterface(0x499d11E0b6eAC7c0593d8Fb292DCBbF815Fb29Ae);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

interface IStakeManagerProxy {
    function getValidatorContract(uint256 validatorId)
        external
        view
        returns (address);
}

interface IValidatorShareProxy {
    function buyVoucher(uint256 _amount, uint256 _minSharesToMint) external;

    function restake() external;

    function withdrawRewards() external;

    function sellVoucher_new(uint256 _claimAmount, uint256 _maximumSharesToBurn)
        external;

    function unstakeClaimTokens_new(uint256 unbondNonce) external;
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

interface TokenInterface {
    function approve(address, uint256) external;

    function transfer(address, uint256) external;

    function transferFrom(
        address,
        address,
        uint256
    ) external;

    function deposit() external payable;

    function withdraw(uint256) external;

    function balanceOf(address) external view returns (uint256);

    function decimals() external view returns (uint256);
}

interface MemoryInterface {
    function getUint(uint256 id) external returns (uint256 num);

    function setUint(uint256 id, uint256 val) external;
}

interface AccountInterface {
    function enable(address) external;

    function disable(address) external;

    function isAuth(address) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

contract DSMath {
    uint256 constant WAD = 10**18;
    uint256 constant RAY = 10**27;

    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = SafeMath.add(x, y);
    }

    function sub(uint256 x, uint256 y)
        internal
        pure
        virtual
        returns (uint256 z)
    {
        z = SafeMath.sub(x, y);
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = SafeMath.mul(x, y);
    }

    function div(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = SafeMath.div(x, y);
    }

    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = SafeMath.add(SafeMath.mul(x, y), WAD / 2) / WAD;
    }

    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = SafeMath.add(SafeMath.mul(x, WAD), y / 2) / y;
    }

    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = SafeMath.add(SafeMath.mul(x, RAY), y / 2) / y;
    }

    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = SafeMath.add(SafeMath.mul(x, y), RAY / 2) / RAY;
    }

    function toInt(uint256 x) internal pure returns (int256 y) {
        y = int256(x);
        require(y >= 0, "int-overflow");
    }

    function toRad(uint256 wad) internal pure returns (uint256 rad) {
        rad = mul(wad, 10**27);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

import {TokenInterface} from "./interfaces.sol";
import {Stores} from "./stores.sol";
import {DSMath} from "./math.sol";

abstract contract Basic is DSMath, Stores {
    function convert18ToDec(uint256 _dec, uint256 _amt)
        internal
        pure
        returns (uint256 amt)
    {
        amt = (_amt / 10**(18 - _dec));
    }

    function convertTo18(uint256 _dec, uint256 _amt)
        internal
        pure
        returns (uint256 amt)
    {
        amt = mul(_amt, 10**(18 - _dec));
    }

    function getTokenBal(TokenInterface token)
        internal
        view
        returns (uint256 _amt)
    {
        _amt = address(token) == ethAddr
            ? address(this).balance
            : token.balanceOf(address(this));
    }

    function getTokensDec(TokenInterface buyAddr, TokenInterface sellAddr)
        internal
        view
        returns (uint256 buyDec, uint256 sellDec)
    {
        buyDec = address(buyAddr) == ethAddr ? 18 : buyAddr.decimals();
        sellDec = address(sellAddr) == ethAddr ? 18 : sellAddr.decimals();
    }

    function encodeEvent(string memory eventName, bytes memory eventParam)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encode(eventName, eventParam);
    }

    function approve(
        TokenInterface token,
        address spender,
        uint256 amount
    ) internal {
        try token.approve(spender, amount) {} catch {
            token.approve(spender, 0);
            token.approve(spender, amount);
        }
    }

    function changeEthAddress(address buy, address sell)
        internal
        pure
        returns (TokenInterface _buy, TokenInterface _sell)
    {
        _buy = buy == ethAddr ? TokenInterface(wethAddr) : TokenInterface(buy);
        _sell = sell == ethAddr
            ? TokenInterface(wethAddr)
            : TokenInterface(sell);
    }

    function convertEthToWeth(
        bool isEth,
        TokenInterface token,
        uint256 amount
    ) internal {
        if (isEth) token.deposit{value: amount}();
    }

    function convertWethToEth(
        bool isEth,
        TokenInterface token,
        uint256 amount
    ) internal {
        if (isEth) {
            approve(token, address(token), amount);
            token.withdraw(amount);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

import {MemoryInterface} from "./interfaces.sol";

abstract contract Stores {
    /**
     * @dev Return ethereum address
     */
    address internal constant ethAddr =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /**
     * @dev Return Wrapped ETH address
     */
    address internal constant wethAddr =
        0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;

    /**
     * @dev Return memory variable address
     */
    MemoryInterface internal constant stakeAllMemory =
        MemoryInterface(0xCE6d5fdBB0F90c896E18F315f7248507725CAd1a);

    uint256 public constant PORTIONS_SUM = 1000000;

    /**
     * @dev Get Uint value from StakeAllMemory Contract.
     */
    function getUint(uint256 getId, uint256 val)
        internal
        returns (uint256 returnVal)
    {
        returnVal = getId == 0 ? val : stakeAllMemory.getUint(getId);
    }

    /**
     * @dev Set Uint value in StakeAllMemory Contract.
     */
    function setUint(uint256 setId, uint256 val) internal virtual {
        if (setId != 0) stakeAllMemory.setUint(setId, val);
    }
}