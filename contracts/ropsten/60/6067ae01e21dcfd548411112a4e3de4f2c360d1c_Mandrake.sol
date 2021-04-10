/**
 *Submitted for verification at Etherscan.io on 2021-04-09
*/

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

// File: openzeppelin-solidity/contracts/utils/Address.sol


pragma solidity ^0.8.0;

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

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// File: openzeppelin-solidity/contracts/utils/Context.sol


pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: openzeppelin-solidity/contracts/access/Ownable.sol


pragma solidity ^0.8.0;

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
    constructor () {
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

// File: contracts/lib/SafeMath.sol

pragma solidity ^0.8.0;

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

// File: contracts/Mandrake.sol

/************************************
* Copyright © 2021 Mandrake COIN. ALL RIGHTS RESERVED.
***************************************/

pragma solidity ^0.8.0;





contract Mandrake is IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    // amount of owned tokens for users buyers of the token
    mapping (address => uint256) private _balances;
    // keeps track of amount authorized to to others users by an owner of the token
    mapping (address => mapping (address => uint256)) private _allowances;
    // token total is 1 trillion
    uint256 private constant tokenTotal = 1 * 10**12 * 10**18;
    // set base currently supply to the total supply
    uint256 private currentSupply = tokenTotal;
    
    // set in the constructor
    address private OWNER_ACCOUNT;
    // set this here to the wallet address for marketing tokens
    address private MARKETING_WALLET_ADDRESS;

    string private _name      = 'Mandrake';
    string private _symbol    = 'Mandrake';
    uint8  private _decimals  = 18;

    uint256 private percent90 = 1 * 10**12 * 10**18 *.9;
    uint256 private percent80 = 1 * 10**12 * 10**18 *.8;
    uint256 private percent70 = 1 * 10**12 * 10**18 *.7;
    uint256 private percent60 = 1 * 10**12 * 10**18 *.6;
    uint256 private percent50 = 1 * 10**12 * 10**18 *.5;
    uint256 private percent40 = 1 * 10**12 * 10**18 *.4;
    uint256 private percent30 = 1 * 10**12 * 10**18 *.3;
    uint256 private percent20 = 1 * 10**12 * 10**18 *.2;
    uint256 private percent10 = 1 * 10**12 * 10**18 *.1;

    constructor() {
        // set the owner of the account to the one whoe uploads the contract
        // this is the contract address and will not be able to be accessed by anyone
        OWNER_ACCOUNT = msg.sender;
        // set all supply of the token to the contract
        _balances[msg.sender] = currentSupply;
        // emit the event to transfer all suplly to the contract
        // this finishes setting up our contrat
        emit Transfer(address(0), msg.sender, tokenTotal);
    }

    /*****************************************************
    ******************************************************
    BASE FUNCTIONS
    Tested in '/test/Mandrake_base.test.js
    ******************************************************
    *****************************************************/

    // TEST FUNCTION #1 '/test/Mandrake_base.test.js
    // READ: return the name of the contract - Mandrake
    function name() public view returns (string memory) {
        return _name;
    }
    // TEST FUNCTION #2 '/test/Mandrake_base.test.js
    // READ: return the symbol of the contract - Mandrake
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    // TEST FUNCTION #3 '/test/Mandrake_base.test.js
    // READ: return the  decimals of the contract - 18
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    // TEST FUNCTION #4 '/test/Mandrake_base.test.js
    // READ: return the current supply in existence - starts with 1 trillionc
    function totalSupply() public view override returns (uint256) {
        return currentSupply;
    }

    // TEST FUNCTION #6 '/test/Mandrake_base.test.js
    // READ: return the balance of Mandrake that an address has
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /*****************************************************
    ******************************************************
    ALLOWANCES
    Tested in '/test/Mandrake_allowance.js
    ******************************************************
    *****************************************************/

    // TEST FUNCTION #1 '/test/Mandrake_allowance.test.js
    // READ: returns the amount authorized with the owner (@param 1) giving permison to the spender
    // (@param) 2 to take X coines (the return) from their account

    // In English, this function checks the amount that the first address has authorized the second
    // address to withraw from their wallet
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
    // TEST FUNCTION #2 '/test/Mandrake_allowance.test.js
    // WRITE: sets the amount (@param2)  the the taker (@param 1) can withdraw from the person who calls 
    // this function. 
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    // internal function, performs the approval of fund authorization 
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        require(balanceOf(owner) >= amount, "Insufficient Funds");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /*****************************************************
    ******************************************************
    TRANSFERS FUNCTIONS
    d in '/test/Mandrake_transfer.js
    ******************************************************
    *****************************************************/

    // this is not necesarily a buy function here

    // TEST FUNCTION #1 '/test/Mandrake_allowance.test.js
    // this is a buy of the token from the root contract
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(recipient != address(0), "Cannot Transfer To The Zero Address");
        require(amount > 0, "Transfer Amount Must Be Greater Than 0");
        require(_balances[msg.sender] >= amount, "Insufficient Funds");
        
        _transfer(msg.sender, recipient, amount);

        return true;
    }

    // sell / change hands
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {

        require(recipient != address(0), "Cannot Transfer To The Zero Address");
        require(sender != address(0), "Cannot Transfer From The Zero Address");
        require(amount > 0, "Transfer Amount Must Be Greater Than 0");
        require(_allowances[sender][recipient] >= amount, "Insufficient Funds For Transfer From");
        
        _approve(sender, recipient, _allowances[sender][recipient].sub(amount, "Insufficient Funds For Transfer From"));
        _transfer(sender, recipient, amount);

        return true;

    }

    function _transfer(address sender, address recipient, uint256 amount) private returns (bool) {
        
        // we are transfering back to the contact, burn some tokens
        if(recipient == OWNER_ACCOUNT) {
            
            uint256 amountToReturn = 0;
            uint256 amountToBurn   = 0;

            if(currentSupply >= percent50) {
    
                amountToBurn = amount;
    
            } else if(currentSupply >= percent30) {
    
                amountToBurn = amount.div(50);
                amountToReturn = amount.div(50);
    
            } else if(currentSupply >= percent10) {
    
                amountToBurn = amount.div(30);
                amountToReturn = amount.div(70);
    
            } else if(currentSupply >= percent10) {
    
                amountToBurn = amount.div(10);
                amountToReturn = amount.div(90);
    
            } else {

                amountToReturn = amount;
    
            }
    
            // reduce the full amount of the person who sold
            _balances[sender] = _balances[sender].sub(amount);
            // increates the contract supply by the amount to treturn to it
            _balances[recipient] = _balances[recipient].add(amountToReturn);
    
            // mirror the new supply by the amount to return to it 
            currentSupply = currentSupply.add(amountToReturn);
            
            emit Transfer(sender, recipient, amountToReturn);
            emit Transfer(sender, address(0), amountToBurn);

        } else {
            
            // burn 1 percent of token on any transactions not going back to the contract
            uint256 taxPercent = amount.div(100);
            uint256 amountAfterTax = amount.sub(taxPercent);
    
            // if we are under 10% supply apply no fees to buying the coin
            if(currentSupply < percent10) {
                amountAfterTax = amount;
                taxPercent = 0;
            }
    
            _balances[sender]       = _balances[sender].sub(amount);
            _balances[recipient]        = _balances[recipient].add(amountAfterTax);
    
            
            // mirror the new supply by the amount to return to it 
            currentSupply = currentSupply.sub(amount);
            
            // transfer to the designated account
            emit Transfer(sender, recipient, amountAfterTax);
            // burn 1% of the transaction if totaly supply is above 10%
            emit Transfer(sender, address(0), taxPercent);
            
        }

        return true;
    }


}