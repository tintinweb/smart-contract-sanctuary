// SPDX-License-Identifier: BitYield
pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;

import './lib/AddressArrayUtils.sol';

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';

import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';

contract IndexC1 is Ownable {
  using AddressArrayUtils for address[];
  using SafeMath for uint;
  using SafeMath for uint256;
  
  /* ============ State Variables ============ */
  
  // assetAddresses; this is an array of the tokens that will be held in this fund 
  // A valid Uniswap pair must be present on the execution network to provide a swap
  address[] internal assetAddresses;
  
  // assetLimits; this maps the asset(a token's address) => to it's funding allocation maximum
  // example: {0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984 => 100000000000000000}
  mapping (address => uint256) internal assetLimits;
  
  // balances; one level deeper to hold the balance of a specific token per an address
  // example: {0xInvestorAddress: {0xTokenAddress => (uint256 balance)}
  mapping (address => mapping (address => balance)) internal balances;
  
  // balance; used to hold a more efficient set of balances per investor address
  // and token address
  struct balance {
    uint ethAmount;
    uint tokAmount;
  }

  // name; is the name of the IndexFund
  string public name;

  uint256 internal constant ETHER_BASE = 1000000000000000000;
  address internal constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  address internal constant UNISWAP_FACTORY_ADDRESS = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
  
  IUniswapV2Router02 private uniswapRouter;
  IUniswapV2Factory  private uniswapFactory;
  
  /* ============ Events ================= */
  event EnterMarket(
    address indexed from_, 
    uint amountDeposited_,
    uint currentBlock_
  );
  
  event ExitMarket(
    address indexed from_, 
    uint amountWithdrawn_,
    uint currentBlock_
  );
  
  event SwapInit(
    address indexed token_,
    uint amountIn_,
    uint[] amounts_
  );
  
  event SwapSuccess(
    address indexed token_, 
    uint etherAmount_, 
    uint[] amounts_
  );
  
  event SwapFailureString(
    address indexed token_, 
    string err_
  );
  
  event SwapFailureBytes(
    address indexed token_, 
    bytes err_
  );

  /* ============ Constructor ============ */
  constructor(
    string memory _name,
    address[] memory _assets, 
    uint256[] memory _limits
  ) public {
    Ownable(msg.sender);
    
    require(_assets.length == _limits.length, "asset arrays must be equal");
    require(_assets.length != 0, "asset array must not be empty");
    
    // Setting the assets and their limits here
    for (uint i = 0; i < _assets.length; i++) {
      address asset = _assets[i];
      require(assetLimits[asset] == 0, "asset already added");
      assetLimits[asset] = _limits[i];
    }

    name = _name;
    assetAddresses = _assets;

    uniswapRouter  = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);
    uniswapFactory = IUniswapV2Factory(UNISWAP_FACTORY_ADDRESS);
  }
  
  // enterMarket; is the main entry point to this contract. It takes msg.value and splits
  // to the allocation ceilings in wei. Any funds not used are returned to the sender
  function enterMarket() public payable {    
    uint256 totalEther = 0;

    for (uint i = 0; i < assetAddresses.length; i++) {
      address tokenAddress = assetAddresses[i];

      uint256 tokenEtherBase = msg.value.mul(assetLimits[tokenAddress]);
      uint256 tokenEtherAmount = tokenEtherBase.div(ETHER_BASE);
    
      // LIVE -----------------------------------------------------------------------
      try uniswapRouter.swapExactETHForTokens{ 
        value: tokenEtherAmount 
      }(
        0, 
        getPathForETHtoTOKEN(tokenAddress), 
        address(this), 
        block.timestamp.add(120)
      ) returns (uint[] memory tokenAmounts) {
          balances[msg.sender][tokenAddress] = balance(
            tokenAmounts[0], 
            tokenAmounts[1]
          );
            
          emit SwapSuccess(tokenAddress, tokenEtherAmount, tokenAmounts);
      } catch Error(string memory _err) {
          emit SwapFailureString(tokenAddress, _err);
          continue;
      } catch (bytes memory _err) {
          emit SwapFailureBytes(tokenAddress, _err);
          continue;
      }
      
      // TEST -----------------------------------------------------------------------
      // balances[msg.sender][tokenAddress] = balance(
      //   tokenEtherAmount, 
      //   12434562745188401
      // );
  
      // Increment the totalEther deposited
      totalEther = totalEther.add(tokenEtherAmount);
    }
  
    // Refund any unused Ether
    // This needs to only refund the Ether difference from msg.value, not the address
    // ******************************************************************************
    (bool success,) = msg.sender.call{ value: msg.value.sub(totalEther) }("");
    require(success, "enterMarket; refund failed");
    
    // Emit the EnterMarket event
    emit EnterMarket(
      msg.sender,
      totalEther,
      block.number
    );
  }
  
  function exitMarket() public {
    // Keep track of the ether accounted for so if failure, the refunded amount is proper
    uint256 totalEther = 0;
    
    for (uint i = 0; i < assetAddresses.length; i++) {
      address tokenAddress = assetAddresses[i];

      // The original token amount, not ether
      uint amountIn = balances[msg.sender][tokenAddress].tokAmount;
      
      address[] memory path = getPathForTOKENtoETH(tokenAddress);
      uint[] memory returnedAmounts = uniswapRouter.getAmountsOut(amountIn, path);
      
      IERC20 token = IERC20(tokenAddress);
      require(token.approve(UNISWAP_ROUTER_ADDRESS, amountIn),
        "must approve the token out"
      );

      emit SwapInit(tokenAddress, amountIn, returnedAmounts);

      try uniswapRouter.swapExactTokensForETH( 
        returnedAmounts[0],
        returnedAmounts[1],
        path, 
        msg.sender, 
        block.timestamp.add(100)
      ) returns (uint[] memory tokenAmounts) {
        totalEther = totalEther.add(tokenAmounts[1]);
        
        // Remove the record entry for this balance, very important
        delete balances[msg.sender][tokenAddress];
        
        emit SwapSuccess(tokenAddress, amountIn, tokenAmounts);
      } catch Error(string memory _err) {
        emit SwapFailureString(tokenAddress, _err);
        continue;
      } catch (bytes memory _err) {
        emit SwapFailureBytes(tokenAddress, _err);
        continue;
      }
    }
    
    // Emit the ExitMarket event
    emit ExitMarket(
      msg.sender,
      totalEther,
      block.number
    );
  }
  
  function custodialWithdraw(address recipient) public {
    require(owner() == msg.sender,
      "owner must be msg.sender"
    );
    
    // we will need to implement a controller multi approval here, not just the owner
    // sender can initiate this method.
    
    // Reduce the token balances
    for (uint i = 0; i < assetAddresses.length; i++) {
      IERC20 t = IERC20(assetAddresses[i]);
      uint256 balanceOfToken = t.balanceOf(address(this));      
      t.transfer(recipient, balanceOfToken);
    }
    
    // Reduce the ether balance
    (bool success,) = msg.sender.call{ value: address(this).balance }("");
    require(success, "custodialWithdraw; withdraw failed");
  }

  // getPathForETHtoTOKEN; given a token's address, return a path from the WETH UniswapRouter
  function getPathForETHtoTOKEN(address token) private view returns (address[] memory) {
    address[] memory path = new address[](2);
    path[0] = uniswapRouter.WETH();
    path[1] = token;
  
    return path;
  }
  
  // getPathForTOKENtoETH; given a token's address, return a path to the WETH UniswapRouter
  function getPathForTOKENtoETH(address token) private view returns (address[] memory) {
    address[] memory path = new address[](2);
    path[0] = token;
    path[1] = uniswapRouter.WETH();
    
    return path;
  }

  /* ============ Getters ============ */
  
  // getInvestorBalanceByToken; returns the investors token balance
  function getInvestorBalanceByToken(address investor, address token) 
    public view returns(balance memory) 
  { 
    return balances[investor][token]; 
  }
  
  // getAssets; returns an array of all the Fund's investable assets only
  function getAssets() 
    public view returns(address[] memory) 
  { 
    return assetAddresses; 
  }
  
  // getAssetLimit; for a given asset, returns it's allocation ceiling
  function getAssetLimit(address token) 
    public view returns(uint256) 
  { 
    return assetLimits[token]; 
  }
  
  // receive; required to accept ether
  receive() 
    external payable 
  {}
}

pragma solidity ^0.6.8;

/**
* @title AddressArrayUtils
* @author BitYield
*
* Utility functions to handle Address Arrays
*/
library AddressArrayUtils {
	
	/**
	 * Finds the index of the first occurrence of the given element.
	 * @param A The input array to search
	 * @param a The value to find
	 * @return Returns (index and isIn) for the first occurrence starting from index 0
	 */
	function indexOf(address[] memory A, address a) internal pure returns (uint256, bool) {
		uint256 length = A.length;
		for (uint256 i = 0; i < length; i++) {
			if (A[i] == a) {
				return (i, true);
			}
		}
		return (uint256(-1), false);
	}
	
	/**
	* Returns true if the value is present in the list. Uses indexOf internally.
	* @param A The input array to search
	* @param a The value to find
	* @return Returns isIn for the first occurrence starting from index 0
	*/
	function contains(address[] memory A, address a) internal pure returns (bool) {
		(, bool isIn) = indexOf(A, a);
		return isIn;
	}
	
	/**
	* Returns true if there are 2 elements that are the same in an array
	* @param A The input array to search
	* @return Returns boolean for the first occurrence of a duplicate
	*/
	function hasDuplicate(address[] memory A) internal pure returns(bool) {
		require(A.length > 0, "A is empty");
	
		for (uint256 i = 0; i < A.length - 1; i++) {
			address current = A[i];
			for (uint256 j = i + 1; j < A.length; j++) {
				if (current == A[j]) {
					return true;
				}
			}
		}
		return false;
	}
	
	/**
	 * @param A The input array to search
	 * @param a The address to remove     
	 * @return Returns the array with the object removed.
	 */
	function remove(address[] memory A, address a)
		internal
		pure
		returns (address[] memory)
	{
		(uint256 index, bool isIn) = indexOf(A, a);
		if (!isIn) {
			revert("Address not in array.");
		} else {
			(address[] memory _A,) = pop(A, index);
			return _A;
		}
	}
	
	/**
	* Removes specified index from array
	* @param A The input array to search
	* @param index The index to remove
	* @return Returns the new array and the removed entry
	*/
	function pop(address[] memory A, uint256 index)
		internal
		pure
		returns (address[] memory, address)
	{
		uint256 length = A.length;
		require(index < A.length, "Index must be < A length");
		address[] memory newAddresses = new address[](length - 1);
		for (uint256 i = 0; i < index; i++) {
			newAddresses[i] = A[i];
		}
		for (uint256 j = index + 1; j < length; j++) {
			newAddresses[j - 1] = A[j];
		}
		return (newAddresses, A[index]);
	}
	
	/**
	 * Returns the combination of the two arrays
	 * @param A The first array
	 * @param B The second array
	 * @return Returns A extended by B
	 */
	function extend(address[] memory A, address[] memory B) internal pure returns (address[] memory) {
		uint256 aLength = A.length;
		uint256 bLength = B.length;
		address[] memory newAddresses = new address[](aLength + bLength);
		for (uint256 i = 0; i < aLength; i++) {
			newAddresses[i] = A[i];
		}
		for (uint256 j = 0; j < bLength; j++) {
			newAddresses[aLength + j] = B[j];
		}
		return newAddresses;
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

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
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