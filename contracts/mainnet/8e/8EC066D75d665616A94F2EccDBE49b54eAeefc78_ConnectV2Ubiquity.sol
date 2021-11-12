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

pragma solidity ^0.7.0;

import { TokenInterface } from "./interfaces.sol";
import { Stores } from "./stores.sol";
import { DSMath } from "./math.sol";

abstract contract Basic is DSMath, Stores {

    function convert18ToDec(uint _dec, uint256 _amt) internal pure returns (uint256 amt) {
        amt = (_amt / 10 ** (18 - _dec));
    }

    function convertTo18(uint _dec, uint256 _amt) internal pure returns (uint256 amt) {
        amt = mul(_amt, 10 ** (18 - _dec));
    }

    function getTokenBal(TokenInterface token) internal view returns(uint _amt) {
        _amt = address(token) == ethAddr ? address(this).balance : token.balanceOf(address(this));
    }

    function getTokensDec(TokenInterface buyAddr, TokenInterface sellAddr) internal view returns(uint buyDec, uint sellDec) {
        buyDec = address(buyAddr) == ethAddr ?  18 : buyAddr.decimals();
        sellDec = address(sellAddr) == ethAddr ?  18 : sellAddr.decimals();
    }

    function encodeEvent(string memory eventName, bytes memory eventParam) internal pure returns (bytes memory) {
        return abi.encode(eventName, eventParam);
    }

    function approve(TokenInterface token, address spender, uint256 amount) internal {
        try token.approve(spender, amount) {

        } catch {
            token.approve(spender, 0);
            token.approve(spender, amount);
        }
    }

    function changeEthAddress(address buy, address sell) internal pure returns(TokenInterface _buy, TokenInterface _sell){
        _buy = buy == ethAddr ? TokenInterface(wethAddr) : TokenInterface(buy);
        _sell = sell == ethAddr ? TokenInterface(wethAddr) : TokenInterface(sell);
    }

    function convertEthToWeth(bool isEth, TokenInterface token, uint amount) internal {
        if(isEth) token.deposit{value: amount}();
    }

    function convertWethToEth(bool isEth, TokenInterface token, uint amount) internal {
       if(isEth) {
            approve(token, address(token), amount);
            token.withdraw(amount);
        }
    }
}

pragma solidity ^0.7.0;

interface TokenInterface {
    function approve(address, uint256) external;
    function transfer(address, uint) external;
    function transferFrom(address, address, uint) external;
    function deposit() external payable;
    function withdraw(uint) external;
    function balanceOf(address) external view returns (uint);
    function decimals() external view returns (uint);
}

interface MemoryInterface {
    function getUint(uint id) external returns (uint num);
    function setUint(uint id, uint val) external;
}

interface InstaMapping {
    function cTokenMapping(address) external view returns (address);
    function gemJoinMapping(bytes32) external view returns (address);
}

interface AccountInterface {
    function enable(address) external;
    function disable(address) external;
    function isAuth(address) external view returns (bool);
}

pragma solidity ^0.7.0;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

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

pragma solidity ^0.7.0;

import { MemoryInterface, InstaMapping } from "./interfaces.sol";


abstract contract Stores {

  /**
   * @dev Return ethereum address
   */
  address constant internal ethAddr = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  /**
   * @dev Return Wrapped ETH address
   */
  address constant internal wethAddr = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

  /**
   * @dev Return memory variable address
   */
  MemoryInterface constant internal instaMemory = MemoryInterface(0x8a5419CfC711B2343c17a6ABf4B2bAFaBb06957F);

  /**
   * @dev Return InstaDApp Mapping Addresses
   */
  InstaMapping constant internal instaMapping = InstaMapping(0xe81F70Cc7C0D46e12d70efc60607F16bbD617E88);

  /**
   * @dev Get Uint value from InstaMemory Contract.
   */
  function getUint(uint getId, uint val) internal returns (uint returnVal) {
    returnVal = getId == 0 ? val : instaMemory.getUint(getId);
  }

  /**
  * @dev Set Uint value in InstaMemory Contract.
  */
  function setUint(uint setId, uint val) virtual internal {
    if (setId != 0) instaMemory.setUint(setId, val);
  }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

contract Events {
	event LogDeposit(
		address indexed userAddress,
		address indexed token,
		uint256 amount,
		uint256 indexed bondingShareId,
		uint256 lpAmount,
		uint256 durationWeeks,
		uint256 getId,
		uint256 setId
	);
	event LogWithdraw(
		address indexed userAddress,
		uint256 indexed bondingShareId,
		uint256 lpAmount,
		uint256 endBlock,
		address indexed token,
		uint256 amount,
		uint256 getId,
		uint256 setId
	);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import { Basic } from "../../common/basic.sol";
import { IUbiquityAlgorithmicDollarManager } from "./interfaces.sol";

abstract contract Helpers is Basic {
	/**
	 * @dev Ubiquity Algorithmic Dollar Manager
	 */
	IUbiquityAlgorithmicDollarManager internal constant ubiquityManager =
		IUbiquityAlgorithmicDollarManager(
			0x4DA97a8b831C345dBe6d16FF7432DF2b7b776d98
		);

	/**
	 * @dev DAI Address
	 */
	address internal constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

	/**
	 * @dev USDC Address
	 */
	address internal constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

	/**
	 * @dev USDT Address
	 */
	address internal constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

	/**
	 * @dev Curve 3CRV Token Address
	 */
	address internal constant CRV3 = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;

	/**
	 * @dev Curve 3Pool Address
	 */
	address internal constant Pool3 =
		0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;

	/**
	 * @dev Ubiquity Algorithmic Dollar Address
	 */
	function getUAD() internal returns (address) {
		return ubiquityManager.dollarTokenAddress();
	}

	/**
	 * @dev Ubiquity Metapool uAD / 3CRV Address
	 */
	function getUADCRV3() internal returns (address) {
		return ubiquityManager.stableSwapMetaPoolAddress();
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

interface IUbiquityBondingV2 {
	struct Bond {
		address minter;
		uint256 lpFirstDeposited;
		uint256 creationBlock;
		uint256 lpRewardDebt;
		uint256 endBlock;
		uint256 lpAmount;
	}

	function deposit(uint256 lpAmount, uint256 durationWeeks)
		external
		returns (uint256 bondingShareId);

	function removeLiquidity(uint256 lpAmount, uint256 bondId) external;

	function holderTokens(address) external view returns (uint256[] memory);

	function totalLP() external view returns (uint256);

	function totalSupply() external view returns (uint256);

	function getBond(uint256 bondId) external returns (Bond memory bond);
}

interface IUbiquityMetaPool {
	function add_liquidity(uint256[2] memory _amounts, uint256 _min_mint_amount)
		external
		returns (uint256);

	function remove_liquidity_one_coin(
		uint256 lpAmount,
		int128 i,
		uint256 min_amount
	) external returns (uint256);
}

interface I3Pool {
	function add_liquidity(
		uint256[3] calldata _amounts,
		uint256 _min_mint_amount
	) external;

	function remove_liquidity_one_coin(
		uint256 lpAmount,
		int128 i,
		uint256 min_amount
	) external;
}

interface IUbiquityAlgorithmicDollarManager {
	function dollarTokenAddress() external returns (address);

	function stableSwapMetaPoolAddress() external returns (address);

	function bondingContractAddress() external returns (address);

	function bondingShareAddress() external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

/**
 * @title Ubiquity.
 * @dev Ubiquity Dollar (uAD).
 */

import { TokenInterface } from "../../common/interfaces.sol";
import { IUbiquityBondingV2, IUbiquityMetaPool, I3Pool } from "./interfaces.sol";
import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";

abstract contract UbiquityResolver is Helpers, Events {
	/**
	 * @dev Deposit into Ubiquity protocol
	 * @notice 3POOL (DAI / USDC / USDT) => METAPOOL (3CRV / uAD) => uAD3CRV-f => Ubiquity BondingShare
	 * @notice STEP 1 : 3POOL (DAI / USDC / USDT) => 3CRV
	 * @notice STEP 2 : METAPOOL(3CRV / UAD) => uAD3CRV-f
	 * @notice STEP 3 : uAD3CRV-f => Ubiquity BondingShare
	 * @param token Token deposited : DAI, USDC, USDT, 3CRV, uAD or uAD3CRV-f
	 * @param amount Amount of tokens to deposit (For max: `uint256(-1)`)
	 * @param durationWeeks Duration in weeks tokens will be locked (4-208)
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the bonding share id of tokens deposited.
	 */
	function deposit(
		address token,
		uint256 amount,
		uint256 durationWeeks,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		address UAD3CRVf = getUADCRV3();
		bool[6] memory tok = [
			token == DAI, // 0
			token == USDC, // 1
			token == USDT, // 2
			token == CRV3, // 3
			token == getUAD(), // 4
			token == UAD3CRVf // 5
		];

		require(
			// DAI / USDC / USDT / CRV3 / UAD / UAD3CRVF
			tok[0] || tok[1] || tok[2] || tok[3] || tok[4] || tok[5],
			"Invalid token: must be DAI, USDC, USDT, 3CRV, uAD or uAD3CRV-f"
		);

		uint256 _amount = getUint(getId, amount);
		uint256 lpAmount;

		// Full balance if amount = -1
		if (_amount == uint256(-1)) {
			_amount = getTokenBal(TokenInterface(token));
		}

		// STEP 1 : SwapTo3CRV : Deposit DAI, USDC or USDT into 3Pool to get 3Crv LPs
		// DAI / USDC / USDT
		if (tok[0] || tok[1] || tok[2]) {
			uint256[3] memory amounts1;

			if (tok[0]) amounts1[0] = _amount;
			else if (tok[1]) amounts1[1] = _amount;
			else if (tok[2]) amounts1[2] = _amount;

			approve(TokenInterface(token), Pool3, _amount);
			I3Pool(Pool3).add_liquidity(amounts1, 0);
		}

		// STEP 2 : ProvideLiquidityToMetapool : Deposit in uAD3CRV pool to get uAD3CRV-f LPs
		// DAI / USDC / USDT / CRV3 / UAD
		if (tok[0] || tok[1] || tok[2] || tok[3] || tok[4]) {
			uint256[2] memory amounts2;
			address token2 = token;
			uint256 _amount2;

			if (tok[4]) {
				_amount2 = _amount;
				amounts2[0] = _amount2;
			} else {
				if (tok[3]) {
					_amount2 = _amount;
				} else {
					token2 = CRV3;
					_amount2 = getTokenBal(TokenInterface(token2));
				}
				amounts2[1] = _amount2;
			}

			approve(TokenInterface(token2), UAD3CRVf, _amount2);
			lpAmount = IUbiquityMetaPool(UAD3CRVf).add_liquidity(amounts2, 0);
		}

		// STEP 3 : Farm/ApeIn : Deposit uAD3CRV-f LPs into UbiquityBondingV2 and get Ubiquity Bonding Shares
		// UAD3CRVF
		if (tok[5]) {
			lpAmount = _amount;
		}

		address bonding = ubiquityManager.bondingContractAddress();
		approve(TokenInterface(UAD3CRVf), bonding, lpAmount);
		uint256 bondingShareId = IUbiquityBondingV2(bonding).deposit(
			lpAmount,
			durationWeeks
		);

		setUint(setId, bondingShareId);

		_eventName = "LogDeposit(address,address,uint256,uint256,uint256,uint256,uint256,uint256)";
		_eventParam = abi.encode(
			address(this),
			token,
			amount,
			bondingShareId,
			lpAmount,
			durationWeeks,
			getId,
			setId
		);
	}

	/**
	 * @dev Withdraw from Ubiquity protocol
	 * @notice Ubiquity BondingShare => uAD3CRV-f => METAPOOL (3CRV / uAD) => 3POOL (DAI / USDC / USDT)
	 * @notice STEP 1 : Ubiquity BondingShare  => uAD3CRV-f
	 * @notice STEP 2 : uAD3CRV-f => METAPOOL(3CRV / UAD)
	 * @notice STEP 3 : 3CRV => 3POOL (DAI / USDC / USDT)
	 * @param bondingShareId Bonding Share Id to withdraw
	 * @param token Token to withdraw to : DAI, USDC, USDT, 3CRV, uAD or uAD3CRV-f
	 * @param getId ID
	 * @param setId ID
	 */
	function withdraw(
		uint256 bondingShareId,
		address token,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		address UAD3CRVf = getUADCRV3();
		bool[6] memory tok = [
			token == DAI, // 0
			token == USDC, // 1
			token == USDT, // 2
			token == CRV3, // 3
			token == getUAD(), // 4
			token == UAD3CRVf // 5
		];

		require(
			// DAI / USDC / USDT / CRV3 / UAD / UAD3CRVF
			tok[0] || tok[1] || tok[2] || tok[3] || tok[4] || tok[5],
			"Invalid token: must be DAI, USDC, USDT, 3CRV, uAD or uAD3CRV-f"
		);

		uint256 _bondingShareId = getUint(getId, bondingShareId);

		// Get Bond
		IUbiquityBondingV2.Bond memory bond = IUbiquityBondingV2(
			ubiquityManager.bondingShareAddress()
		).getBond(_bondingShareId);

		require(address(this) == bond.minter, "Not bond owner");

		// STEP 1 : Withdraw Ubiquity Bonding Shares to get back uAD3CRV-f LPs
		address bonding = ubiquityManager.bondingContractAddress();
		IUbiquityBondingV2(bonding).removeLiquidity(
			bond.lpAmount,
			_bondingShareId
		);

		// STEP 2 : Withdraw uAD3CRV-f LPs to get back uAD or 3Crv
		// DAI / USDC / USDT / CRV3 / UAD
		if (tok[0] || tok[1] || tok[2] || tok[3] || tok[4]) {
			uint256 amount2 = getTokenBal(TokenInterface(UAD3CRVf));
			IUbiquityMetaPool(UAD3CRVf).remove_liquidity_one_coin(
				amount2,
				tok[4] ? 0 : 1,
				0
			);
		}

		// STEP 3 : Withdraw  3Crv LPs from 3Pool to get back DAI, USDC or USDT
		// DAI / USDC / USDT
		if (tok[0] || tok[1] || tok[2]) {
			uint256 amount1 = getTokenBal(TokenInterface(CRV3));
			I3Pool(Pool3).remove_liquidity_one_coin(
				amount1,
				tok[0] ? 0 : (tok[1] ? 1 : 2),
				0
			);
		}

		uint256 amount = getTokenBal(TokenInterface(token));

		setUint(setId, amount);
		_eventName = "LogWithdraw(address,uint256,uint256,uint256,address,uint256,uint256,uint256)";
		_eventParam = abi.encode(
			address(this),
			_bondingShareId,
			bond.lpAmount,
			bond.endBlock,
			token,
			amount,
			getId,
			setId
		);
	}
}

contract ConnectV2Ubiquity is UbiquityResolver {
	string public constant name = "Ubiquity-v1";
}