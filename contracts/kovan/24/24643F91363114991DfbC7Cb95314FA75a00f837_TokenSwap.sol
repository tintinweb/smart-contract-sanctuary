pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

//todos
//function to issue out LP token based on the provider's pool ownership 

contract TokenSwap {

	using SafeMath for uint256;

	string public name = "TokenSwap DEX";
	uint256 public dexLiquidity;
	address deployer;
 
	IERC20 token;
	IERC20 token2; 
	IERC20 lptoken;

	string[] public pairs;
	mapping (address => uint256) public liquidity;
	mapping (address => mapping (string => uint256)) public totalLiquidity;
	mapping (address => mapping (string => mapping (string => uint256))) public poolLiquidity;
	mapping (address => mapping (string => uint256)) public lptokenOwned;
	mapping (string => uint256) public pool; //ETH-DApp: "500"
	mapping (string => mapping (string => uint256)) public poolPair; //original liquidity regardless of trade - affected by new liquidity provided
	mapping (string => mapping (string => uint256)) public newPoolPair; //current post trade liquidity affected by trades

	event LiquidityProvided(address provider, string pair1, uint256 pair1Amount, string pair2, uint256 pair2Amount);
	event Traded(address trader, string pool, uint256 inputAmount, string inputToken, uint256 outputAmount, string outputToken);

	constructor(address _tokenAddress, address _lptokenAddress, address _token2Address) {
		token = IERC20(_tokenAddress);
		lptoken = IERC20(_lptokenAddress);
		token2 = IERC20(_token2Address);
		deployer = msg.sender;
	}

	function returnPairs() public view returns(string[] memory) {
		return pairs;
	}

	function issueLPToken(address _provider, uint256 _lptAmount, string memory _pairName) public {
		lptokenOwned[_provider][_pairName] = _lptAmount;
	}

	function initEthPair(uint256 _tokenAmount, string memory _pairName, string memory _pair1, string memory _pair2) public payable {
		require(_tokenAmount > 0);
		if (keccak256(abi.encodePacked(_pair2)) == keccak256(abi.encodePacked('DApp'))) {
			token.transferFrom(msg.sender, address(this), _tokenAmount);
		} else {
			token2.transferFrom(msg.sender, address(this), _tokenAmount);
		}
		liquidity[msg.sender] += _tokenAmount + msg.value;
		dexLiquidity += _tokenAmount + msg.value;
		pool[_pairName] += _tokenAmount + msg.value;
		totalLiquidity[msg.sender][_pairName] += _tokenAmount + msg.value;
		poolLiquidity[msg.sender][_pairName][_pair1] += msg.value;
		poolLiquidity[msg.sender][_pairName][_pair2] += _tokenAmount;
		poolPair[_pairName][_pair1] += msg.value;
		poolPair[_pairName][_pair2] += _tokenAmount;
		pairs.push(_pairName);
		emit LiquidityProvided(msg.sender, _pair1, msg.value, _pair2, _tokenAmount);
	}

	function addEthPair(uint256 _tokenAmount, string memory _pairName, string memory _pair1, string memory _pair2) public payable {
		require(_tokenAmount > 0);
		if (keccak256(abi.encodePacked(_pair2)) == keccak256(abi.encodePacked('DApp'))) {
			token.transferFrom(msg.sender, address(this), _tokenAmount);
		} else {
			token2.transferFrom(msg.sender, address(this), _tokenAmount);
		}
		liquidity[msg.sender] += _tokenAmount + msg.value;
		dexLiquidity += _tokenAmount + msg.value;
		pool[_pairName] += _tokenAmount + msg.value;
		totalLiquidity[msg.sender][_pairName] += _tokenAmount + msg.value;
		poolLiquidity[msg.sender][_pairName][_pair1] += msg.value;
		poolLiquidity[msg.sender][_pairName][_pair2] += _tokenAmount;
		poolPair[_pairName][_pair1] += msg.value;
		poolPair[_pairName][_pair2] += _tokenAmount;
		emit LiquidityProvided(msg.sender, _pair1, msg.value, _pair2, _tokenAmount);
	}

	function initTokenPair(uint256 _token1Amount, uint256 _token2Amount, string memory _pairName, string memory _pair1, string memory _pair2) public {
		require(_token1Amount > 0 && _token2Amount > 0);
		token.transferFrom(msg.sender, address(this), _token1Amount);
		token2.transferFrom(msg.sender, address(this), _token2Amount);
		liquidity[msg.sender] += _token1Amount + _token2Amount;
		dexLiquidity += _token1Amount + _token2Amount;
		pool[_pairName] += _token1Amount + _token2Amount;
		totalLiquidity[msg.sender][_pairName] += _token1Amount + _token2Amount;
		poolLiquidity[msg.sender][_pairName][_pair1] += _token1Amount;
		poolLiquidity[msg.sender][_pairName][_pair2] += _token2Amount;
		poolPair[_pairName][_pair1] += _token1Amount;
		poolPair[_pairName][_pair2] += _token2Amount;
		pairs.push(_pairName);
		emit LiquidityProvided(msg.sender, _pair1, _token1Amount, _pair2, _token2Amount);
	}

	function addTokenPair(uint256 _token1Amount, uint256 _token2Amount, string memory _pairName, string memory _pair1, string memory _pair2) public {
		require(_token1Amount > 0 && _token2Amount > 0);
		token.transferFrom(msg.sender, address(this), _token1Amount);
		token2.transferFrom(msg.sender, address(this), _token2Amount);
		liquidity[msg.sender] += _token1Amount + _token2Amount;
		dexLiquidity += _token1Amount + _token2Amount;
		pool[_pairName] += _token1Amount + _token2Amount;
		totalLiquidity[msg.sender][_pairName] += _token1Amount + _token2Amount;
		poolLiquidity[msg.sender][_pairName][_pair1] += _token1Amount;
		poolLiquidity[msg.sender][_pairName][_pair2] += _token2Amount;
		poolPair[_pairName][_pair1] += _token1Amount;
		poolPair[_pairName][_pair2] += _token2Amount;
		emit LiquidityProvided(msg.sender, _pair1, _token1Amount, _pair2, _token2Amount);
	}

	function tradeEthforToken(string memory _pairName, string memory _pair1, string memory _pair2) public payable {
		require(pool[_pairName] > 0, "No liquidity exists in this pool");
		uint256 pair1Balance; 
		uint256 pair2Balance;
		if (newPoolPair[_pairName][_pair1] == 0 && newPoolPair[_pairName][_pair2] == 0) {
			pair1Balance = poolPair[_pairName][_pair1];
			pair2Balance = poolPair[_pairName][_pair2];
		} else {
			pair1Balance = newPoolPair[_pairName][_pair1];
			pair2Balance = newPoolPair[_pairName][_pair2];
		}
		uint256 inputAmount = msg.value;
		require(pair1Balance > msg.value && pair2Balance > 0);
		uint256 poolConstant = pair1Balance * pair2Balance;
		uint256 inputAmountWithFee = inputAmount.mul(997);
		uint256 postTradePair2Balance = poolConstant.mul(1000) / (inputAmountWithFee.add(pair1Balance.mul(1000)));
		uint256 tokenTradeValue = pair2Balance.sub(postTradePair2Balance);
		require(pair2Balance > tokenTradeValue);
		if (keccak256(abi.encodePacked(_pair2)) == keccak256(abi.encodePacked('DApp'))) {
			token.transfer(msg.sender, tokenTradeValue);
		} else {
			token2.transfer(msg.sender, tokenTradeValue);
		}
		newPoolPair[_pairName][_pair1] = pair1Balance.add(inputAmount);
		newPoolPair[_pairName][_pair2] = pair2Balance.sub(tokenTradeValue);
		uint256 poolBal = pool[_pairName];
		poolBal = poolBal.add(inputAmount).sub(tokenTradeValue);
		pool[_pairName] = poolBal;
		dexLiquidity = dexLiquidity.add(inputAmount).sub(tokenTradeValue);
		emit Traded(msg.sender, _pairName, inputAmount, _pair1, tokenTradeValue, _pair2);
	}

	function tradeTokenforEth(uint256 _tokenAmount, string memory _pairName, string memory _pair1, string memory _pair2) public {
		require(pool[_pairName] > 0, "No liquidity exists in this pool");
		uint256 pair1Balance;
		uint256 pair2Balance;
		if (newPoolPair[_pairName][_pair1] == 0 && newPoolPair[_pairName][_pair2] == 0) {
			pair1Balance = poolPair[_pairName][_pair1];
			pair2Balance = poolPair[_pairName][_pair2];
		} else {
			pair1Balance = newPoolPair[_pairName][_pair1];
			pair2Balance = newPoolPair[_pairName][_pair2];
		}
		uint256 inputAmount = _tokenAmount;
		require(pair1Balance > 0 && pair2Balance > inputAmount);
		uint256 poolConstant = pair1Balance * pair2Balance;
		uint256 postTradePair1Balance = poolConstant.mul(1000) / (pair2Balance.mul(1000).add(inputAmount.mul(997)));
		uint256 etherTradeValue = pair1Balance.sub(postTradePair1Balance);
		require(pair1Balance > etherTradeValue);
		address payable trader = payable(msg.sender);
		if (keccak256(abi.encodePacked(_pair2)) == keccak256(abi.encodePacked('DApp'))) {
			token.transferFrom(msg.sender, address(this), inputAmount);
		} else {
			token2.transferFrom(msg.sender, address(this), inputAmount);
		}
		trader.transfer(etherTradeValue);
		newPoolPair[_pairName][_pair1] = pair1Balance.sub(etherTradeValue);
		newPoolPair[_pairName][_pair2] = pair2Balance.add(inputAmount);
		uint256 poolBal = pool[_pairName];
		poolBal = poolBal.add(inputAmount).sub(etherTradeValue);
		pool[_pairName] = poolBal;
		dexLiquidity = dexLiquidity.add(inputAmount).sub(etherTradeValue);
		emit Traded(msg.sender, _pairName, inputAmount, _pair2, etherTradeValue, _pair1);
	}

	function tradeTokenforToken(uint256 _tokenAmount, string memory _tradeToken, string memory _pairName, string memory _pair1, string memory _pair2) public {
		require(pool[_pairName] > 0, "No liquidity exists in this pool");
		uint256 pair1Balance;
		uint256 pair2Balance;
		if (newPoolPair[_pairName][_pair1] == 0 && newPoolPair[_pairName][_pair2] == 0) {
			pair1Balance = poolPair[_pairName][_pair1];
			pair2Balance = poolPair[_pairName][_pair2];
		} else {
			pair1Balance = newPoolPair[_pairName][_pair1];
			pair2Balance = newPoolPair[_pairName][_pair2];
		}
		uint256 inputAmount = _tokenAmount;
		uint256 tokenTradeValue;
		require(pair1Balance > 0 && pair2Balance > 0);
		uint256 poolConstant = pair1Balance * pair2Balance;
		if (keccak256(abi.encodePacked(_tradeToken)) == keccak256(abi.encodePacked(_pair1))) {
			uint256 postTradePairBalance = poolConstant.mul(1000) / (pair1Balance.mul(1000).add(inputAmount.mul(997)));
			tokenTradeValue = pair2Balance.sub(postTradePairBalance);
			require(pair2Balance > tokenTradeValue);
			token.transferFrom(msg.sender, address(this), inputAmount);//assumed that pair1 is token
			token2.transfer(msg.sender, tokenTradeValue);
			newPoolPair[_pairName][_pair1] = pair1Balance.add(inputAmount);
			newPoolPair[_pairName][_pair2] = pair2Balance.sub(tokenTradeValue);
		} else {
			uint256 postTradePairBalance = poolConstant.mul(1000) / (pair2Balance.mul(1000).add(inputAmount.mul(997)));
			tokenTradeValue = pair1Balance.sub(postTradePairBalance);
			require(pair1Balance > tokenTradeValue);
			token2.transferFrom(msg.sender, address(this), inputAmount);//assumed that pair2 is token2
			token.transfer(msg.sender, tokenTradeValue);
			newPoolPair[_pairName][_pair1] = pair1Balance.sub(tokenTradeValue);
			newPoolPair[_pairName][_pair2] = pair2Balance.add(inputAmount);
		}
		uint256 poolBal = pool[_pairName];
		poolBal = poolBal.add(inputAmount).sub(tokenTradeValue);
		pool[_pairName] = poolBal;
		dexLiquidity = dexLiquidity.add(inputAmount).sub(tokenTradeValue);
		emit Traded(msg.sender, _pairName, inputAmount, _tradeToken, tokenTradeValue, _pair2);
	}

	function withdraw(string memory _pairName, string memory _pair1, uint256 _pair1Amount, uint256 _pair2Amount, string memory _pair2, uint256 check1, uint256 check2) public {
		require(totalLiquidity[msg.sender][_pairName] > 0, "Can't withdraw from this pool");
		uint256 poolHold1 = poolLiquidity[msg.sender][_pairName][_pair1];//100ETH
		uint256 poolHold2 = poolLiquidity[msg.sender][_pairName][_pair2];//1000 DAPP
		uint256 poolLiquid1 = poolPair[_pairName][_pair1]; //150 ETH old
		uint256 poolLiquid2 = poolPair[_pairName][_pair2];//1500 DAPP
		uint256 tradeLiquid1 = newPoolPair[_pairName][_pair1];
		uint256 tradeLiquid2 = newPoolPair[_pairName][_pair2];
		require((check1 > _pair1Amount) && (check2 > _pair2Amount), "Can't take more than ownership portion");
		if (keccak256(abi.encodePacked(_pair1)) == keccak256(abi.encodePacked('ETH'))) {
			address payable trader = payable(msg.sender);
			trader.transfer(_pair1Amount);
			token.transfer(msg.sender, _pair2Amount);
		} else {
			token.transfer(msg.sender, _pair1Amount);
			token2.transfer(msg.sender, _pair2Amount);
		}
		poolLiquidity[msg.sender][_pairName][_pair1] = poolHold1.sub(_pair1Amount);
		poolLiquidity[msg.sender][_pairName][_pair2] = poolHold2.sub(_pair2Amount);
		poolPair[_pairName][_pair1] = poolLiquid1.sub(_pair1Amount);
		poolPair[_pairName][_pair2] = poolLiquid2.sub(_pair2Amount);
		newPoolPair[_pairName][_pair1] = tradeLiquid1.sub(_pair1Amount);
		newPoolPair[_pairName][_pair2] = tradeLiquid2.sub(_pair2Amount);
		uint256 totalWithdraw = _pair1Amount.add(_pair2Amount);
		pool[_pairName] -= totalWithdraw;
		dexLiquidity = dexLiquidity.sub(totalWithdraw);
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "berlin",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}