// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {TokenInterface} from "./interfaces/IToken.sol";
import {AaveInterface} from "./interfaces/IAaveV2.sol";
import {AaveLendingPoolProviderInterface} from "./interfaces/IAaveV2.sol";
import {AaveDataProviderInterface} from "./interfaces/IAaveV2.sol";

import {Connector} from "./libraries/Connector.sol";

contract ConnectorAaveV2 is Connector {

    string public constant name = "ConnectorAaveV2";

    // Aave Referral Code
    uint16 internal constant referralCode = 3228;

    // Aave Lending Pool Provider
    AaveLendingPoolProviderInterface internal constant aaveProvider =
        AaveLendingPoolProviderInterface(
            0x88757f2f99175387aB4C6a4b3067c77A695b0349
        );
    // Aave Protocol Data Provider
    AaveDataProviderInterface internal constant aaveData =
        AaveDataProviderInterface(0x3c73A5E5785cAC854D468F727c606C07488a29D6);

    event AaveV2Deposit(
        address indexed token,
        uint256 tokenAmt,
        uint256 getId,
        uint256 setId
    );
    event AaveV2Withdraw(
        address indexed token,
        uint256 tokenAmt,
        uint256 getId,
        uint256 setId
    );
    event AaveV2Borrow(
        address indexed token,
        uint256 tokenAmt,
        uint256 indexed rateMode,
        uint256 getId,
        uint256 setId
    );
    event AaveV2Payback(
        address indexed token,
        uint256 tokenAmt,
        uint256 indexed rateMode,
        uint256 getId,
        uint256 setId
    );
    event AaveV2EnableCollateral(address[] tokens);
    event AaveV2SwapRateMode(address indexed token, uint256 rateMode);

    constructor (address _wethAddr, address _accountMemoryAddr) Connector(_wethAddr,_accountMemoryAddr) {
    }

    /**
     * @dev Deposit ETH/ERC20_Token.
     * @notice Deposit a token to Aave v2 for lending / collaterization.
     * @param token The address of the token to deposit.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amt The amount of the token to deposit. (For max: `uint256(-1)`)
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of tokens deposited.
     */
    function deposit(
        address token,
        uint256 amt,
        uint256 getId,
        uint256 setId
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        uint256 _amt = getUint(getId, amt);

        AaveInterface aave = AaveInterface(aaveProvider.getLendingPool());

        bool isEth = token == ethAddr;
        address _token = isEth ? wethAddr : token;

        TokenInterface tokenContract = TokenInterface(_token);

        if (isEth) {
            _amt = _amt == type(uint256).max ? address(this).balance : _amt;
            convertEthToWeth(isEth, tokenContract, _amt);
        } else {
            _amt = _amt == type(uint256).max
                ? tokenContract.balanceOf(address(this))
                : _amt;
        }

        approve(tokenContract, address(aave), _amt);

        aave.deposit(_token, _amt, address(this), referralCode);

        if (!getIsColl(_token)) {
            aave.setUserUseReserveAsCollateral(_token, true);
        }

        setUint(setId, _amt);

        _eventName = "LogDeposit(address,uint256,uint256,uint256)";
        _eventParam = abi.encode(token, _amt, getId, setId);
    }

    /**
     * @dev Withdraw ETH/ERC20_Token.
     * @notice Withdraw deposited token from Aave v2
     * @param token The address of the token to withdraw.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amt The amount of the token to withdraw. (For max: `uint256(-1)`)
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of tokens withdrawn.
     */
    function withdraw(
        address token,
        uint256 amt,
        uint256 getId,
        uint256 setId
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        uint256 _amt = getUint(getId, amt);

        AaveInterface aave = AaveInterface(aaveProvider.getLendingPool());
        bool isEth = token == ethAddr;
        address _token = isEth ? wethAddr : token;

        TokenInterface tokenContract = TokenInterface(_token);

        uint256 initialBal = tokenContract.balanceOf(address(this));
        aave.withdraw(_token, _amt, address(this));
        uint256 finalBal = tokenContract.balanceOf(address(this));

        _amt = sub(finalBal, initialBal);

        convertWethToEth(isEth, tokenContract, _amt);

        setUint(setId, _amt);

        _eventName = "LogWithdraw(address,uint256,uint256,uint256)";
        _eventParam = abi.encode(token, _amt, getId, setId);
    }

    /**
     * @dev Borrow ETH/ERC20_Token.
     * @notice Borrow a token using Aave v2
     * @param token The address of the token to borrow.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amt The amount of the token to borrow.
     * @param rateMode The type of borrow debt. (For Stable: 1, Variable: 2)
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of tokens borrowed.
     */
    function borrow(
        address token,
        uint256 amt,
        uint256 rateMode,
        uint256 getId,
        uint256 setId
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        uint256 _amt = getUint(getId, amt);

        AaveInterface aave = AaveInterface(aaveProvider.getLendingPool());

        bool isEth = token == ethAddr;
        address _token = isEth ? wethAddr : token;

        aave.borrow(_token, _amt, rateMode, referralCode, address(this));
        convertWethToEth(isEth, TokenInterface(_token), _amt);

        setUint(setId, _amt);

        _eventName = "LogBorrow(address,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(token, _amt, rateMode, getId, setId);
    }

    /**
     * @dev Payback borrowed ETH/ERC20_Token.
     * @notice Payback debt owed.
     * @param token The address of the token to payback.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amt The amount of the token to payback. (For max: `uint256(-1)`)
     * @param rateMode The type of debt paying back. (For Stable: 1, Variable: 2)
     * @param getId ID to retrieve amt.
     * @param setId ID stores the amount of tokens paid back.
     */
    function payback(
        address token,
        uint256 amt,
        uint256 rateMode,
        uint256 getId,
        uint256 setId
    )
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        uint256 _amt = getUint(getId, amt);

        AaveInterface aave = AaveInterface(aaveProvider.getLendingPool());

        bool isEth = token == ethAddr;
        address _token = isEth ? wethAddr : token;

        TokenInterface tokenContract = TokenInterface(_token);

        _amt = _amt == type(uint256).max
            ? getPaybackBalance(_token, rateMode)
            : _amt;

        if (isEth) convertEthToWeth(isEth, tokenContract, _amt);

        approve(tokenContract, address(aave), _amt);

        aave.repay(_token, _amt, rateMode, address(this));

        setUint(setId, _amt);

        _eventName = "LogPayback(address,uint256,uint256,uint256,uint256)";
        _eventParam = abi.encode(token, _amt, rateMode, getId, setId);
    }

    /**
     * @dev Enable collateral
     * @notice Enable an array of tokens as collateral
     * @param tokens Array of tokens to enable collateral
     */
    function enableCollateral(address[] calldata tokens)
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        uint256 _length = tokens.length;
        require(_length > 0, "0-tokens-not-allowed");

        AaveInterface aave = AaveInterface(aaveProvider.getLendingPool());

        for (uint256 i = 0; i < _length; i++) {
            address token = tokens[i];
            if (getCollateralBalance(token) > 0 && !getIsColl(token)) {
                aave.setUserUseReserveAsCollateral(token, true);
            }
        }

        _eventName = "LogEnableCollateral(address[])";
        _eventParam = abi.encode(tokens);
    }

    /**
     * @dev Swap borrow rate mode
     * @notice Swaps user borrow rate mode between variable and stable
     * @param token The address of the token to swap borrow rate.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param rateMode Desired borrow rate mode. (Stable = 1, Variable = 2)
     */
    function swapBorrowRateMode(address token, uint256 rateMode)
        external
        payable
        returns (string memory _eventName, bytes memory _eventParam)
    {
        AaveInterface aave = AaveInterface(aaveProvider.getLendingPool());

        uint256 currentRateMode = rateMode == 1 ? 2 : 1;

        if (getPaybackBalance(token, currentRateMode) > 0) {
            aave.swapBorrowRateMode(token, rateMode);
        }

        _eventName = "LogSwapRateMode(address,uint256)";
        _eventParam = abi.encode(token, rateMode);
    }



    /**
     * @dev Checks if collateral is enabled for an asset
     * @param token token address of the asset.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     */
    function getIsColl(address token) internal view returns (bool isCol) {
        (, , , , , , , , isCol) = aaveData.getUserReserveData(
            token,
            address(this)
        );
    }

    /**
     * @dev Get total debt balance & fee for an asset
     * @param token token address of the debt.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param rateMode Borrow rate mode (Stable = 1, Variable = 2)
     */
    function getPaybackBalance(address token, uint256 rateMode)
        internal
        view
        returns (uint256)
    {
        (, uint256 stableDebt, uint256 variableDebt, , , , , , ) = aaveData
            .getUserReserveData(token, address(this));
        return rateMode == 1 ? stableDebt : variableDebt;
    }

    /**
     * @dev Get total collateral balance for an asset
     * @param token token address of the collateral.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     */
    function getCollateralBalance(address token)
        internal
        view
        returns (uint256 bal)
    {
        (bal, , , , , , , , ) = aaveData.getUserReserveData(
            token,
            address(this)
        );
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface TokenInterface {
    function approve(address, uint256) external;
    function transfer(address, uint) external;
    function transferFrom(address, address, uint) external;
    function deposit() external payable;
    function withdraw(uint) external;
    function balanceOf(address) external view returns (uint);
    function decimals() external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AaveInterface {
    function deposit(address _asset, uint256 _amount, address _onBehalfOf, uint16 _referralCode) external;
    function withdraw(address _asset, uint256 _amount, address _to) external;
    function borrow(
        address _asset,
        uint256 _amount,
        uint256 _interestRateMode,
        uint16 _referralCode,
        address _onBehalfOf
    ) external;
    function repay(address _asset, uint256 _amount, uint256 _rateMode, address _onBehalfOf) external;
    function setUserUseReserveAsCollateral(address _asset, bool _useAsCollateral) external;
    function swapBorrowRateMode(address _asset, uint256 _rateMode) external;
}

interface AaveLendingPoolProviderInterface {
    function getLendingPool() external view returns (address);
}

interface AaveDataProviderInterface {
    function getReserveTokensAddresses(address _asset) external view returns (
        address aTokenAddress,
        address stableDebtTokenAddress,
        address variableDebtTokenAddress
    );
    function getUserReserveData(address _asset, address _user) external view returns (
        uint256 currentATokenBalance,
        uint256 currentStableDebt,
        uint256 currentVariableDebt,
        uint256 principalStableDebt,
        uint256 scaledVariableDebt,
        uint256 stableBorrowRate,
        uint256 liquidityRate,
        uint40 stableRateLastUpdated,
        bool usageAsCollateralEnabled
    );
}

interface AaveAddressProviderRegistryInterface {
    function getAddressesProvidersList() external view returns (address[] memory);
}

interface ATokenInterface {
    function balanceOf(address _user) external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { DSMath } from "./DSMath.sol";
import { TokenInterface } from "../interfaces/IToken.sol";

interface MemoryInterface {
    function getUint(uint256 id) external returns (uint256 num);
    function setUint(uint256 id, uint256 val) external;
}

abstract contract Connector is DSMath {

    address internal constant ethAddr =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    // address internal constant wethAddr =
    //     0xd0A1E359811322d97991E03f863a0C30C2cF029C;

    // MemoryInterface internal constant accountMemory =
    //     MemoryInterface(0xCe9E55D1e9B1d5FB8c5A97C041f1642351924153);

    address internal immutable wethAddr;
    address internal immutable accountMemoryAddr;

    constructor (address _wethAddr, address _accountMemoryAddr){
        wethAddr = _wethAddr;
        accountMemoryAddr = _accountMemoryAddr;
    }

    function getUint(uint256 getId, uint256 val)
        internal
        returns (uint256 returnVal)
    {
        returnVal = getId == 0 ? val : MemoryInterface(accountMemoryAddr).getUint(getId);
    }

    function setUint(uint256 setId, uint256 val) internal virtual {
        if (setId != 0)  MemoryInterface(accountMemoryAddr).setUint(setId, val);
    }

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
        view
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DSMath {
  uint constant WAD = 10 ** 18;
  uint constant RAY = 10 ** 27;

  function add(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(x, y);
  }

  function sub(uint x, uint y) internal virtual pure returns (uint z) {
    z = SafeMath.sub(x, y);
  }

  function mul(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.mul(x, y);
  }

  function div(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.div(x, y);
  }

  function wmul(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(SafeMath.mul(x, y), WAD / 2) / WAD;
  }

  function wdiv(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(SafeMath.mul(x, WAD), y / 2) / y;
  }

  function rdiv(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(SafeMath.mul(x, RAY), y / 2) / y;
  }

  function rmul(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(SafeMath.mul(x, y), RAY / 2) / RAY;
  }

  function toInt(uint x) internal pure returns (int y) {
    y = int(x);
    require(y >= 0, "int-overflow");
  }

  function toRad(uint wad) internal pure returns (uint rad) {
    rad = mul(wad, 10 ** 27);
  }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}