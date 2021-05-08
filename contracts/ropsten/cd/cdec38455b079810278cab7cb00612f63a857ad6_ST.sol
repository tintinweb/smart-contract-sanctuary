/**
 *Submitted for verification at Etherscan.io on 2021-05-08
*/

// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^0.5.0;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

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

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol

pragma solidity ^0.5.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
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
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}

// File: @openzeppelin/contracts/token/ERC20/ERC20Detailed.sol

pragma solidity ^0.5.0;


/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

// File: @openzeppelin/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/oraclizeAPI_0.5.sol

/*
ORACLIZE_API
Copyright (c) 2015-2016 Oraclize SRL
Copyright (c) 2016 Oraclize LTD
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

pragma solidity >= 0.5.0 < 0.6.0; 

library usingOraclize {
    function safeParseInt(string memory _a, uint _b) internal pure returns (uint _parsedInt) {
        bytes memory bresult = bytes(_a);
        uint mint = 0;
        bool decimals = false;
        for (uint i = 0; i < bresult.length; i++) {
            if ((uint(uint8(bresult[i])) >= 48) && (uint(uint8(bresult[i])) <= 57)) {
                if (decimals) {
                   if (_b == 0) break;
                    else _b--;
                }
                mint *= 10;
                mint += uint(uint8(bresult[i])) - 48;
            } else if (uint(uint8(bresult[i])) == 46) {
                require(!decimals, 'More than one decimal encountered in string!');
                decimals = true;
            } else {
                revert("Non-numeral character encountered in string!");
            }
        }
        if (_b > 0) {
            mint *= 10 ** _b;
        }
        return mint;
    }
}

// File: contracts/Oracle.sol

pragma solidity ^0.5.0;
//File containing the Source code for mock Oracle providing ETH/GBP value on Ethereum Blockchain.



contract Oracle is Ownable{
    uint public ETHGBP;
    uint public updated;
    uint[3] private pendingUpdates;
    address private Server2Owner;
    address private Server3Owner;
    bool private updating;
    
    event PriceUpdate(uint _time, uint _value);
    
    constructor(address _owner2, address _owner3) public{
        pendingUpdates = [0,0,0];
        Server2Owner = _owner2;
        Server3Owner = _owner3;
        updating = false;
    }
    
    
    modifier onlyServer(address server){
            require(msg.sender == server);
            _;
        }
    
    function insertion(uint[3] memory data) internal pure returns(uint[3] memory){
        uint length = 3;
        for (uint i = 1; i < length; i++) {
            uint key = data[i];
            uint j = i - 1;
            while ((int(j) >= 0) && (data[j] > key)) {
                data[j + 1] = data[j];
                j--;
            }
            data[j + 1] = key;
        }
        return data;
    }
    
    function updatePriceServer1(string memory _value) public onlyOwner returns(bool) {
        addToPending(0, usingOraclize.safeParseInt(_value,18));
        return true;
    }
    function updatePriceServer2(string memory _value) public onlyServer(Server2Owner) returns(bool) {
        addToPending(1,usingOraclize.safeParseInt(_value,18));
        return true;
    }
    function updatePriceServer3(string memory _value) public onlyServer(Server3Owner) returns(bool) {
        addToPending(2, usingOraclize.safeParseInt(_value,18));
        return true;
    }
    
    function addToPending(uint8  _id, uint  _value) internal {
        pendingUpdates[_id] = _value;
        
        if (updating != true && pendingUpdates[0] != 0 && pendingUpdates[1]!= 0 && pendingUpdates[2]!=0){
            updating = true;
            uint[3] memory sorted = insertion(pendingUpdates);
            ETHGBP = sorted[1];
            updated = now;
            pendingUpdates = [0,0,0];
            updating = false;
            emit PriceUpdate(updated, ETHGBP);
        }
        }
    }

// File: contracts/BT.sol

pragma solidity ^0.5.0;


//Allows token to be owned by another address.


contract BT is ERC20, ERC20Detailed, Ownable{
    
    constructor() public ERC20Detailed("BackingToken", "BT", 18){}
    
    function mint(address _to, uint _quantity) public onlyOwner returns(bool success){
        _mint(_to, _quantity);
        return true;
    }
    
    function burn(address _from, uint _quantity) public onlyOwner returns(bool success){
        _burn(_from, _quantity);
        return true;
    }
    
}

// File: contracts/ST.sol

/*
Implements ERC20 Token, ST, which is pegged to the value of £1 using Ether as collateral.
*/
pragma solidity ^0.5.0;
//OpenZeppelin imports which implement the ERC-20 Interface.


//SafeMath library which prevents overflow when carrying out arithmetic.

//Local file import of contracts: Mock Oracle (Oracle) and Backing Token (BT).



contract ST is ERC20, ERC20Detailed{
    using SafeMath for uint;
    Oracle private oracle; //The oracle which provides pricing data.

    BT public bt; //Instance of BT Contract responsible for ERC-20 compliant backing token, owned by this contract.
    uint constant private WAD = 10 ** 18; //10^18, used in pricing arithmetic.
    uint public vault; //Stores the ammount of collateral held by the contract... used instead of this(address).balance because the vault value needs to be used in calculations without inclusion of payments included with deposit calls.
    uint private constant minCollatRatio = 12 * (10**17); //120% Minimum collateral percentage
    uint private constant mintFee = 2*(10**15); //0.2% base Minting fee
    uint private constant burnFee = 5*(10**15); //0.5% base Burning fee
    uint private constant floorPriceBT = 5 * (10**17); //Absolute minimum unit price for BT token: 0.50 GBP.
        
    constructor(address _oracle) public ERC20Detailed("StableToken", "ST", 18) {
    oracle = Oracle(_oracle); //Update the oracle and load into interface.
    bt = BT(new BT()); //Deploy a new BT contract.
    }
    //Core functions for enacting the stabilisation mechanisms:
    
    /**
    * @notice  Handles Ether deposits into the contract, mint ST tokens to the tune of the GBP equivalent of value minus fees.
    * @param _to The address to receive newly minted ST tokens.
    * @return Whether the minting was successful or not
    */
    function mint(address _to) public payable returns(bool success){
        require(bt.totalSupply() != 0, 'Requires deposit into BT tokens to initiate system.');
        uint feeMultiplier = collateralRatio() < minCollatRatio ? 3 : 1;
        uint transactionValue = calcMinusFees(ETH_TO_GBP(msg.value), mintFee.mul(feeMultiplier));
        _mint(_to, transactionValue);
        vault += msg.value;
        return true;
    }
    /**
    * @notice Redeems `_value` quantity of ST tokens for the equivalent GBP value in ETH minus fees.
    * @param _value The number of ST tokens which are to be redeemed
    * @return Whether the burning was successful or not
    */
    function burn(uint _value) public returns(bool success){
        uint feeMultiplier = collateralRatio() < minCollatRatio ? 1 : 3;
        uint burnValue = calcMinusFees(GBP_TO_ETH(_value), burnFee*feeMultiplier);
        require(vaultValue() >= burnValue, 'Not enough collateral to cover burn');
        require(adjustedCollateralRatioBurn(_value)>=WAD, 'Minimum collateral ratio of 100% violated.' );
        _burn(msg.sender, _value);
        msg.sender.transfer(burnValue);
        vault -= burnValue;
        return true;
    }
    /**
    * @notice Accepts Ether payment and mints BT tokens based on the current unit price of BT.
    * @param _to The address to receive newly minted BT tokens.
    * @return Whether the deposit was successful or not
    */
    function deposit(address _to) public payable returns(bool success){
        uint transactionValue = ETH_TO_BT(msg.value);
        bt.mint(_to, transactionValue);
        vault += msg.value;
        return true;
    }
    /**
    * @notice Redeem `_bt` BT tokens for the equivalent £ value in ETH.
    * @param _bt The number of BT tokens to be redeemed and subsequently burned.
    * @return Whether the deposit was successful or not
    */
    function withdraw(uint _bt) public returns(bool success){
        uint withdrawEth = BT_TO_ETH(_bt);
        require(buffer() > 0, 'No Collateral to cover withdrawal');
        require(adjustedCollateralRatioWithdraw(ETH_TO_GBP(withdrawEth)) > minCollatRatio || totalSupply() == 0, 'Minimum collateral ratio of 120% violated');
        bt.burn(msg.sender, _bt);
        msg.sender.transfer(withdrawEth);
        vault -= withdrawEth;
        return true;
    }
    
    /**
    * @notice Exchange `_st` ST tokens for the equivalent value in BT tokens. Applies fees when collateral ratio is above 120% 
    * @param _st The number of ST tokens to be exchanged.
    * @return Whether the deposit was successful or not
    */
    function exchange(uint _st) public returns (bool success){
        _burn(msg.sender,_st); //Burn the ST tokens
        uint btValue = (_st.mul(WAD)).div(unitPriceBT());
        uint afterFees = collateralRatio() < minCollatRatio ? btValue : calcMinusFees(btValue, burnFee);
        bt.mint(msg.sender, afterFees);
        return true;
    }
    //Helper functions:
    
    /**
    * @notice calculates the GBP value of the ETH being stored int he vault according to current market price.
    * @return Current £ value of the vault. (How much collateral is being held).
    */
    function vaultValue() public view returns(uint value){
        return (vault.mul(oracle.ETHGBP())).div(WAD);
    }
    
    /**
    * @notice Calculates the GBP value of the buffer.
    * @return The current buffer value.
    */
    function buffer() public view returns(int bufferValue){
        return int(vaultValue()) - int(totalSupply());
    }
    /**
    * @notice Calculates the current collateral ratio (vaultVaule / ST total supply)
    * @return The current collateral ratio.
    */
    function collateralRatio() public view returns(uint ratio){
        if(vaultValue() == 0 || totalSupply() == 0) {
            return WAD;
        }else{
        return (vaultValue().mul(WAD)).div(totalSupply());
        }
    }
    /**
    * @notice Calculates the collateral ratio that would be produced as a result of burning `_burning` ST tokens
    * @param _burning The number of ST tokens being burnt
    * @return The future collateral ratio acheived as a result of burning the ST tokens.
    */
    function adjustedCollateralRatioBurn(uint _burning) internal view returns(uint ratio){
        if(vaultValue() == 0 || vaultValue() == _burning || totalSupply() == 0 || totalSupply() == _burning){
            return WAD;
        }else{
            return((vaultValue().sub(_burning)).mul(WAD)).div(totalSupply().sub(_burning));
        }
    }
    
    /**
    * @notice Calculates the collateral ratio that would be produced as a result of withdrawing `_withdrawingValue` worth of BT tokens
    * @param _withdrawingValue The GBP value of BT tokens being withdrawn
    * @return The future collateral ratio acheived as a result of withdrawing this value of BT tokens.
    */
    function adjustedCollateralRatioWithdraw(uint _withdrawingValue) internal view returns(uint ratio){
        if(vaultValue() == 0 || vaultValue() == _withdrawingValue || totalSupply() == 0 ){
            return minCollatRatio;
        }else{
            return((vaultValue().sub(_withdrawingValue)).mul(WAD)).div(totalSupply());
        }
    }
    /**
    * @notice Returns the `_value` minus the `_feePercentage`. Used to apply fees to operations.
    * @param _value The number that is going to have a percentage of fees subtracted from it.
    * @param _feePercentage The percentage of fees that are to be charged on the operation
    * @return The ammount of tokens to mint, taking into consideration the fees.
    */
    function calcMinusFees(uint _value, uint _feePercentage) internal pure returns(uint _lessFees){
        uint multiplier = WAD - _feePercentage;
        uint value = (multiplier.mul(_value)).div(WAD);
        return value;
    }
    /**
    * @notice Calculates the GBP value of an Ethereum transaction of value `_eth`.. used to mint the correct number of ST.
    * @param _eth The ammount of ETH being converted to ST value.
    * @return The number of ST tokens to mint based on an ETH transactions value.
    */
    function ETH_TO_GBP(uint _eth) private  view returns (uint _GBP){
        return (oracle.ETHGBP().mul(_eth)).div(WAD);
    }
    /**
    * @notice calculates the ETH value of `_gbp` GBP worth of ST tokens.
    * @param _gbp The ammount of ST tokens being converted to ETH value.
    * @return The ETH value of `_gbp` ST Tokens.
    */
    function GBP_TO_ETH(uint _gbp) private view returns (uint _ETH){
        return (_gbp.mul(WAD)).div(oracle.ETHGBP());
    }
    /**
    * @notice calculates the ETH value of `_bt` number of BT tokens.
    * @param _bt The ammount of BT being converted to ETH value.
    * @return The ETH value of `_bt` BT Tokens.
    */
    function BT_TO_ETH(uint _bt) private view returns(uint _ETH){
        uint gbpValue = (_bt.mul(unitPriceBT())).div(WAD);
        return GBP_TO_ETH(gbpValue);
    }
    /**
    * @notice Calculates the  quantity of BT tokens `_eth` amount of ETH is worth. Used to mint the correct number of BT.
    * @param _eth The ammount of ETH being converted to BT value.
    * @return The number of BT tokens to mint based on an ETH transactions value.
    */
    function ETH_TO_BT(uint _eth) private view returns(uint _BT){
        uint gbpValue = ETH_TO_GBP(_eth);
        return (gbpValue.mul(WAD)).div(unitPriceBT());
    }
    /**
    * @notice calculates the GBP unit price of a single BT token.
    * @return The current GBP value of 1 BT token.
    */
    function unitPriceBT() public view returns(uint price){
        if(bt.totalSupply() == 0 || buffer() ==0 ){
            return WAD;
        } else if(buffer() > 0){
            return (uint(buffer()).mul(WAD)).div(bt.totalSupply());
        } else {
            //Buffer must be negative if execution ends up here....
            return collateralRatio() > floorPriceBT ? collateralRatio() : floorPriceBT;
        }
    }
}