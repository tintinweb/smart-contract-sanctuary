// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract IPhoenix {
	function getTotalLevels(address _user) external view returns(uint256){}
}
/**
 ______     __         ______     ______     ______    
/\  == \   /\ \       /\  __ \   /\___  \   /\  ___\   
\ \  __<   \ \ \____  \ \  __ \  \/_/  /__  \ \  __\   
 \ \_____\  \ \_____\  \ \_\ \_\   /\_____\  \ \_____\ 
  \/_____/   \/_____/   \/_/\/_/   \/_____/   \/_____/ 

*/


contract Blaze is ERC20, Ownable {

	using SafeMath for uint256;
	
	mapping(address => uint) lastUpdate;

	mapping(address => bool) burnAddresses;

	mapping(address => uint) tokensOwed;

	IPhoenix[] public phoenixContracts;

	uint[] ratePerLevel;

	constructor() ERC20("Blaze", "BLAZE") {

	}

	/**
	 __     __   __     ______   ______     ______     ______     ______     ______   __     ______     __   __    
	/\ \   /\ "-.\ \   /\__  _\ /\  ___\   /\  == \   /\  __ \   /\  ___\   /\__  _\ /\ \   /\  __ \   /\ "-.\ \   
	\ \ \  \ \ \-.  \  \/_/\ \/ \ \  __\   \ \  __<   \ \  __ \  \ \ \____  \/_/\ \/ \ \ \  \ \ \/\ \  \ \ \-.  \  
	 \ \_\  \ \_\\"\_\    \ \_\  \ \_____\  \ \_\ \_\  \ \_\ \_\  \ \_____\    \ \_\  \ \_\  \ \_____\  \ \_\\"\_\ 
	  \/_/   \/_/ \/_/     \/_/   \/_____/   \/_/ /_/   \/_/\/_/   \/_____/     \/_/   \/_/   \/_____/   \/_/ \/_/ 

	*/
	                                                                                                               
	/*
	* @dev updates the tokens owed and the last time the user updated, called when leveling up a phoenix or minting
	* @dev _userAddress is the address of the user to update
	*/
	function updateTokens(address _userAddress) external {

		if (_userAddress != address(0)) {

			uint lastTime = lastUpdate[_userAddress];
			
			uint currentTime = block.timestamp;

			lastUpdate[_userAddress] = currentTime;
 
			IPhoenix[] memory phoenix_contracts = phoenixContracts;

			uint[] memory ratePerLev = ratePerLevel; 

			if(lastTime > 0) {

				uint claimable;

				for(uint i = 0; i < phoenix_contracts.length; i++) {

					claimable += phoenix_contracts[i].getTotalLevels(_userAddress).mul(ratePerLev[i]);

				}
 
				tokensOwed[_userAddress] += claimable.mul(currentTime - lastTime).div(86400);
			}
			
		}

	}

	/**
	* @dev called on token transfer, and updates the tokens owed and last update for each user involved in the transaction
	* @param _fromAddress is the address the token is being sent from
	* @param _toAddress is the address the token is being sent to
	*/
	function updateTransfer(address _fromAddress, address _toAddress) external {

		uint currentTime = block.timestamp;

		uint claimable;

		uint timeDifference;

		uint lastTime;

		IPhoenix[] memory phoenix_contracts = phoenixContracts;

		uint[] memory ratePerLev = ratePerLevel;

		if(_fromAddress != address(0)) {

			lastTime = lastUpdate[_fromAddress];
			lastUpdate[_fromAddress] = currentTime;

			if(lastTime > 0) {

				claimable = 0;

				timeDifference = currentTime - lastTime;

				for(uint i = 0; i < phoenix_contracts.length; i++) {

					claimable += phoenix_contracts[i].getTotalLevels(_fromAddress).mul(ratePerLev[i]);

				}
 
				tokensOwed[_fromAddress] += claimable.mul(timeDifference).div(86400);
			}

		}

		if(_toAddress != address(0)) {

			lastTime = lastUpdate[_toAddress];
			lastUpdate[_toAddress] = currentTime;

			if(lastTime > 0) {

				claimable = 0;

				timeDifference = currentTime - lastTime;

				for(uint i = 0; i < phoenix_contracts.length; i++) {

					claimable += phoenix_contracts[i].getTotalLevels(_toAddress).mul(ratePerLev[i]);

				}
 
				tokensOwed[_toAddress] += claimable.mul(timeDifference).div(86400);
			}

		}

	}

	/**
	* @dev claims tokens generated and mints into the senders wallet
	*/
	function claim() external {

    	address sender = _msgSender();

    	uint lastUpdated = lastUpdate[sender];
    	uint time = block.timestamp;

    	require(lastUpdated > 0, "No tokens to claim");

    	lastUpdate[sender] = time;

    	uint unclaimed = getPendingTokens(sender, time - lastUpdated);

    	if(tokensOwed[sender] > 0) {

    		unclaimed += tokensOwed[sender];
    		tokensOwed[sender] = 0;

    	}

    	require(unclaimed > 0, "No tokens to claim");

    	_mint(sender, unclaimed);

    }

    /**
    * @dev burns the desired amount of tokens from the wallet, this can only be called by accepted addresses, prefers burning owed tokens over minted
    * @param _from is the address to burn the tokens from
    * @param _amount is the number of tokens attempting to be burned
    */
	function burn(address _from, uint256 _amount) external {

		require(burnAddresses[_msgSender()] == true, "Don't have permission to call this function");

		uint owed = tokensOwed[_from];	

		if(owed >= _amount) {
			tokensOwed[_from] -= _amount;
			return;
		}

		uint balance = balanceOf(_from);

		if(balance >= _amount) {
			_burn(_from, _amount);
			return;

		}

		if(balance + owed >= _amount) {

			tokensOwed[_from] = 0;

			_burn(_from, _amount - owed);

			return;

		}

		uint lastUpdated = lastUpdate[_from];

		require(lastUpdated > 0, "User doesn't have enough blaze to complete this action");

		uint time = block.timestamp;

		uint claimable = getPendingTokens(_from,  time - lastUpdated);

		lastUpdate[_from] = time;

		if(claimable >= _amount) {

			tokensOwed[_from] += claimable - _amount;
			return;

		} 

		if(claimable + owed >= _amount) {

			tokensOwed[_from] -= _amount - claimable;
			return;

		}

		if(balance + owed + claimable >= _amount) {

			tokensOwed[_from] = 0;

			_burn(_from, _amount - (owed + claimable));

			return;

		}

		revert("User doesn't have enough blaze available to complete this action");

			
	}


	/**
	 ______     ______     ______     _____    
	/\  == \   /\  ___\   /\  __ \   /\  __-.  
	\ \  __<   \ \  __\   \ \  __ \  \ \ \/\ \ 
	 \ \_\ \_\  \ \_____\  \ \_\ \_\  \ \____- 
	  \/_/ /_/   \/_____/   \/_/\/_/   \/____/ 
                                          
    */

    /**
    * @dev returns the last time an address has updated with the contract
    * @param _userAddress is the user address that wants the know the time
    */
	function lastUpdateTime(address _userAddress) public view returns(uint) {
		return lastUpdate[_userAddress];
	}

	/**
	* @dev Gets the total tokens that are available to be claimed and minted for a given address
	* @param _userAddress is the address that the claimable tokens are calculated for
	*/
	function getClaimableTokens(address _userAddress) public view returns(uint) {
		return tokensOwed[_userAddress] + getPendingTokens(_userAddress);
	}

	/**
	* @dev returns the tokens accounted for but not minted for a given address
	* @param _userAddress is the address that wants to know whats owed
	*/
	function getTokensOwed(address _userAddress) public view returns(uint) {
		return tokensOwed[_userAddress];
	}

	
	/**
	* @dev recieves the pending tokens yet to be accounted for
	* @param _userAddress is the address which the pending tokens are being calculated for
	* @param _timeDifference is the current time minus the last time the _userAddress was updated
	*/
	function getPendingTokens(address _userAddress, uint _timeDifference) public view returns(uint) {

		uint claimable;

		for(uint i = 0; i < phoenixContracts.length; i++) {

			claimable += phoenixContracts[i].getTotalLevels(_userAddress).mul(ratePerLevel[i]);

		}

		//multiply by the time in seconds, then divide by the number seconds in the day;
		return claimable.mul(_timeDifference).div(86400);
	}


	/**
	* @dev recieves the pending tokens yet to be accounted for, this function is called if the time difference since last update is unknown for the address
	* @param _userAddress is the address which the pending tokens are being calculated for
	*/
	function getPendingTokens(address _userAddress) public view returns(uint) {
		
		uint lastUpdated = lastUpdate[_userAddress];

		if(lastUpdated == 0) {
			return 0;
		}

		return getPendingTokens(_userAddress, block.timestamp - lastUpdated);

	}

   
   /**
     ______     __     __     __   __     ______     ______    
	/\  __ \   /\ \  _ \ \   /\ "-.\ \   /\  ___\   /\  == \   
	\ \ \/\ \  \ \ \/ ".\ \  \ \ \-.  \  \ \  __\   \ \  __<   
	 \ \_____\  \ \__/".~\_\  \ \_\\"\_\  \ \_____\  \ \_\ \_\ 
	  \/_____/   \/_/   \/_/   \/_/ \/_/   \/_____/   \/_/ /_/ 

	*/
        
    /**
    * @dev Sets a phoenix contract where the phoenixs are capable of burning and generating tokens
    * @param _phoenixAddress is the address of the phoenix contract
    * @param _index is the index of where to set this information, either to add a new collection, or update an existing one
    * @param _ratePerLevel is the rate of token generation per phoenix level for this contract
    */                                                   
    function setPhoenixContract(address _phoenixAddress, uint _index, uint _ratePerLevel) external onlyOwner {
		require(_index <= phoenixContracts.length, "index outside range");

		if(phoenixContracts.length == _index) {
			phoenixContracts.push(IPhoenix(_phoenixAddress));
			ratePerLevel.push(_ratePerLevel);
		} 
		else {

			if(burnAddresses[address(phoenixContracts[_index])] == true) {
				burnAddresses[address(phoenixContracts[_index])] = false;
			}

			phoenixContracts[_index] = IPhoenix(_phoenixAddress);
			ratePerLevel[_index] = _ratePerLevel;


		}

		burnAddresses[_phoenixAddress] = true;
	}

	/**
	* @dev sets the addresss that are allowed to call the burn function
	* @param _burnAddress is the address being set
	* @param _value is to allow or remove burning permission
	*/
	function setBurnAddress(address _burnAddress, bool _value) external onlyOwner {
		burnAddresses[_burnAddress] = _value;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}