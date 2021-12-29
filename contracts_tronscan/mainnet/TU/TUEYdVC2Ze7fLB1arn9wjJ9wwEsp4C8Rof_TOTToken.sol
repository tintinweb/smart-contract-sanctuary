//SourceUnit: ERC20.sol

pragma solidity ^0.5.0;

import "./IERC20.sol";
import "./SafeMath.sol";

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
contract ERC20 is IERC20 {
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
        _transfer(msg.sender, recipient, amount);
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
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
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
     * - `sender` must have a balance of at least `value`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
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
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
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
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
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

        _balances[sender] = _balances[sender].sub(amount);
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
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
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
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Destoys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
}

//SourceUnit: ERC20Detailed.sol

pragma solidity ^0.5.0;

import "./IERC20.sol";

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



//SourceUnit: IERC20.sol

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


//SourceUnit: SafeMath.sol

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
        require(b <= a, "SafeMath: subtraction overflow");
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
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
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}


//SourceUnit: TOTToken.sol


// These tokens are tied to the Futira Coin as per www.futiracoin.com. 
// The 6 billion tokens here have 6 billion Futira Coins in a special wallet. 
// When the Futira Coin is listed on any exchange, the token can be exchanged for a coin. Futira reserves the right to burn the tokens in its wallet at any time.

pragma solidity ^0.5.0;

import "./ERC20.sol";
import "./ERC20Detailed.sol";


contract TOTToken is ERC20, ERC20Detailed {

    mapping(address => bool) freezeAccount;
    mapping(address => bool) public signers;
    mapping(address => bool) private vote;
    uint private totalTrueVotes = 0;
    bool public result = false;
    uint pendingTransactionID = 1;
    
    uint[] public pendingTransactionList;
    
    uint public currentTotalSupply;
    uint public deployDate;
    uint public launchDate;
    
    uint public unlockDate2months;
    uint public unlockDate4months;
    uint public unlockDate8months;
    uint public unlockDate12months;
    uint public unlockDate35days;
    uint public unlockDate56days;
    
    uint public firstType;
    uint public secondType;
    uint public thirdType;
    
    address public owner;
    
    address[] buyerCount;
    mapping(address => Buyer) public buyers;
    struct Buyer 
    {
        address buyerAddress;
        uint amount1;
        uint amount2;
        uint amount3;
        uint amount4;
    
        uint totalAmount;
        uint totalAmount1;
    }
    
    mapping(uint => OwnerTransaction) public ownerTransactions;
    struct OwnerTransaction 
    {
        address to;
        uint amount;
        string status;
        uint allowedTime;
    }
    
    event TransferedFromCurrentSupply(uint from, address indexed to, uint256 value);
    
    event BoughtTokenDuringLaunch(address from, address to, uint256 amount);
    event BoughtToken(address from, address to, uint256 amount);
    event SoldToken(address from, address to, uint256 amount);
    
    
    modifier onlyOwner {
        require(msg.sender == owner, "You are not the owner of this smart contract. Contact info@futiracoin.com for help.");
        _;
    }
    
    modifier onlySigner {
        require(signers[msg.sender] == true, "You are not the signer of this smart contract. Contact info@futiracoin.com for help.");
        _;
    }
    
    constructor(address _signer1, address _signer2) public ERC20Detailed("TOTToken", "TOT", 6) {
        _mint(msg.sender, 1000 * (10 ** 6));
        currentTotalSupply += 1000 * (10 ** 6);
        
        
    	launchDate = deployDate + 900;
        unlockDate35days = deployDate + 1000;
        unlockDate56days = deployDate + 1100;
        unlockDate2months = launchDate + 900;
        unlockDate4months = launchDate + 1000;
        unlockDate8months = launchDate + 1200;
        unlockDate12months = launchDate + 1400;
    
        firstType = deployDate + 300; 
        secondType = deployDate + 500;
        thirdType = deployDate + 800; 
    
        pendingTransactionList.push(0);
    
        owner = msg.sender;
    
        // the signer will forever be the same
        // change this into the signer address
        signers[_signer1] = true;
        signers[_signer2] = true;
    }
    
    // For signers to cast their vote
    function signersApproval(bool _signersVote) onlySigner public{
    
        if (_signersVote == true)
        {
             if(totalTrueVotes < 2)
            {
                totalTrueVotes += 1;
            }
        }
        else {
            if(totalTrueVotes > 0)
            {
                totalTrueVotes -= 1;
            }
        }
    
        if (totalTrueVotes >= 1){
            result = true;
        }
        else if (totalTrueVotes == 0) {
            result = false;
        }
    }
    
    // To get a detail about a pending transaction
    function getPendingTransaction(uint _id) public view returns(address, uint, string memory, uint) 
    {
        if(msg.sender != owner && signers[msg.sender] != true)
        {
            revert("You are not the owner or signer of this smart contract. Contact info@futiracoin.com for help.");
        }
        return (ownerTransactions[_id].to, ownerTransactions[_id].amount, ownerTransactions[_id].status, ownerTransactions[_id].allowedTime);
    }
    
    // To get a list of pending transaction 
    function getAllPendingTransaction() public view returns(uint[] memory) 
    {
        if(msg.sender != owner && signers[msg.sender] != true)
        {
            revert("You are not the owner or signer of this smart contract. Contact info@futiracoin.com for help.");
        }
        return pendingTransactionList;
    }
    
    // For admin to freeze any account
    function freezeAnAccount(address _address) onlyOwner public
    {
        freezeAccount[_address] = true;
    }
    
    // For admin to unfreeze any account
    function unfreezeAnAccount(address _address) onlyOwner public
    {
        freezeAccount[_address] = false;
    }
    
    function setTotalSupply(string memory operation, uint _amount) onlyOwner public returns(uint) 
    {
        if(keccak256(abi.encodePacked((operation))) == keccak256(abi.encodePacked(("add"))))
        {
            _mint(msg.sender, _amount);
            currentTotalSupply += _amount;
        }
        else if(keccak256(abi.encodePacked((operation))) == keccak256(abi.encodePacked(("delete"))))
        {
            require(currentTotalSupply >= _amount, "The amount is greater than the total supply. Contact info@futiracoin.com for help.");
            _burn(msg.sender, _amount);
            currentTotalSupply -= _amount;
        }
        else
        {
            revert("This operation is not acceptable. Contact info@futiracoin.com for help.");
        }
    
        return totalSupply();
    }
    
    // To transfer the token from the owner to the _to address
    function _transferFromContract(address _to, uint256 _value) internal {
        require(_to != address(0), "Error with the buyer address. Contact info@futiracoin.com for help.");
    
        _transfer(owner, _to, _value);
        currentTotalSupply -= _value;
    
        emit TransferedFromCurrentSupply(balanceOf(owner), _to, _value);
    }
    
    // To get the buyer details on token they have on each type
    function getBuyer(address _address) public view returns(address, uint, uint, uint, uint, uint, uint)
    {
        if(buyers[_address].buyerAddress == _address)
        {
            return (buyers[_address].buyerAddress, buyers[_address].amount1, buyers[_address].amount2, buyers[_address].amount3, buyers[_address].amount4, buyers[_address].totalAmount, buyers[_address].totalAmount1);
        }
        else
        {
            revert("Cannot find this address. Contact info@futiracoin.com for help.");
        }
    }
    
    function transfer(address _to, uint256 _amount) public returns(bool)
    {
        require(!freezeAccount[msg.sender], "Your address has been hold from transfering the token. Contact info@futiracoin.com for help.");
    
        if(msg.sender == owner)
        {
           deleteExceededTimePendingTransaction();
           createPendingTransaction(_to, _amount);
        }
        else
        {
    
            if(block.timestamp > unlockDate12months)
            {
                uint permissableAmount = buyers[msg.sender].amount1 + buyers[msg.sender].amount2 + buyers[msg.sender].amount3 + buyers[msg.sender].amount4 ;
                if(_amount > permissableAmount)
                {
                    revert("The amount you want to transfer is higher than you're allowed. Contact info@futiracoin.com for help.");
                }
    
                uint totalAmount = buyers[_to].amount4 + _amount;
                uint totalAmount2 = buyers[_to].totalAmount + _amount;
                buyers[msg.sender].totalAmount -= _amount;              
                buyers[_to].buyerAddress = _to;
                buyers[_to].amount4 = totalAmount;
                buyers[_to].totalAmount = totalAmount2;
                uint balance;
                balance = updateAmount(msg.sender, _amount,100);
                if(balance != 0) {balance = updateAmount(msg.sender, balance, 2);}
                if(balance != 0) {balance = updateAmount(msg.sender, balance, 3);}
                if(balance != 0) {balance = updateAmount(msg.sender, balance, 4);}
                _transfer(msg.sender, _to, _amount);             
    
            }
            else if (block.timestamp > unlockDate8months)
            {
    
                uint soldOutPercent = ((buyers[msg.sender].totalAmount1 - buyers[msg.sender].amount1) / 100) * buyers[msg.sender].totalAmount1;
                uint percentFinal = 55 - soldOutPercent;
                uint permissableAmount = (buyers[msg.sender].amount1 * percentFinal / 100) + buyers[msg.sender].amount2 + buyers[msg.sender].amount3 + buyers[msg.sender].amount4 ;
                if(_amount > permissableAmount)
                {
                    revert("The amount you want to sell is higher than you're allowed. Contact info@futiracoin.com for help.");
                }
    
                buyers[msg.sender].totalAmount -= _amount;
                buyers[_to].buyerAddress = _to;
                buyers[_to].amount4 = buyers[_to].amount4 + _amount;
                buyers[_to].totalAmount += _amount;
    
                uint balance;
                balance = updateAmount(msg.sender, _amount, 55);
                if(balance != 0) {balance = updateAmount(msg.sender, balance, 2);}
                if(balance != 0) {balance = updateAmount(msg.sender, balance, 3);}
                if(balance != 0) {balance = updateAmount(msg.sender, balance, 4);}
                 _transfer(msg.sender, _to, _amount);             
            }
            else if (block.timestamp > unlockDate4months)
            {
                uint permissableAmount = buyers[msg.sender].totalAmount1 * 10/100 + buyers[msg.sender].amount2 + buyers[msg.sender].amount3 + buyers[msg.sender].amount4 ;
                if(_amount > permissableAmount)
                {
                    revert("The amount you want to sell is higher than you're allowed. Contact info@futiracoin.com for help.");
                }
    
                buyers[msg.sender].totalAmount -= _amount;
                buyers[_to].buyerAddress = _to;
                buyers[_to].amount4 = buyers[_to].amount4 + _amount;
                buyers[_to].totalAmount += _amount;
    
                uint balance;
                balance = updateAmount(msg.sender, _amount, 10);
                if(balance != 0) {balance = updateAmount(msg.sender, balance, 2);}
                if(balance != 0) {balance = updateAmount(msg.sender, balance, 3);}
                if(balance != 0) {balance = updateAmount(msg.sender, balance, 4);}
                 _transfer(msg.sender, _to, _amount);          
            }
            else if (block.timestamp > unlockDate2months)
            {
                uint permissableAmount = buyers[msg.sender].amount2 + buyers[msg.sender].amount3 + buyers[msg.sender].amount4 ;
                if(_amount > permissableAmount)
                {
                    revert("The amount you want to sell is higher than you're allowed. Contact info@futiracoin.com for help.");
                }
    
                buyers[msg.sender].totalAmount -= _amount;
                buyers[_to].buyerAddress = _to;
                buyers[_to].amount4 = buyers[_to].amount4 + _amount;
                buyers[_to].totalAmount += _amount;            
                uint balance;
                balance = updateAmount(msg.sender, _amount, 2);
                if(balance != 0) {balance = updateAmount(msg.sender, balance, 3);}
                if(balance != 0) {balance = updateAmount(msg.sender, balance, 4);}
                 _transfer(msg.sender, _to, _amount);           
            }              
            else
            {
                revert("You can't transfer these tokens. Contact info@futiracoin.com for help.");
            }
    
            if (_to == owner )
            {
                buyers[_to].totalAmount =balanceOf(_to) ;    
            }
        }
        return true;
    }
    
    // to transfer from an address to another address and store in amount4
    function transferFrom(address sender, address _to, uint256 _amount) onlyOwner public returns(bool)
    {
        if(_to == owner)
        {
            _transfer(sender, _to, _amount);
            currentTotalSupply += _amount;
    
            buyers[sender].totalAmount -= _amount;
    
            uint balance;
            balance = updateAmount(sender, _amount, 100);
            if(balance != 0) {balance = updateAmount(sender, balance, 2);}
            if(balance != 0) {balance = updateAmount(sender, balance, 3);}
            if(balance != 0) {balance = updateAmount(sender, balance, 4);}
    
        }
        else if (sender == owner)
        {
            deleteExceededTimePendingTransaction();
            createPendingTransaction(_to, _amount);
        }
        else
        {
            _transfer(sender, _to, _amount);
            buyers[sender].totalAmount -= _amount;
    
            buyers[_to].buyerAddress = _to;
            buyers[_to].amount4 = buyers[_to].amount4 + _amount;
            buyers[_to].totalAmount += _amount;
    
            uint balance;
            balance = updateAmount(sender, _amount, 100);
            if(balance != 0) {balance = updateAmount(sender, balance, 2);}
            if(balance != 0) {balance = updateAmount(sender, balance, 3);}
            if(balance != 0) {balance = updateAmount(sender, balance, 4);}
        }
    
        return true;
    }
    
    // To update the buyer amount of token in their respective type
    function updateAmount(address _buyer, uint256 _amount, uint buyerType) internal returns(uint)
    {
        if(buyerType == 100)
        {
            if(buyers[_buyer].amount1 >= _amount)
            {
                buyers[_buyer].amount1 = buyers[_buyer].amount1 - _amount;
                return 0;
            }
            else
            {
                buyers[_buyer].amount1 = 0 ;
                return _amount - buyers[_buyer].amount1;
            }
        }
        else if(buyerType == 55)
        {
            uint soldOutPercent = ((buyers[msg.sender].totalAmount1 - buyers[msg.sender].amount1) / 100) * buyers[msg.sender].totalAmount1;
            uint percentFinal = 55 - soldOutPercent;
    
            if(buyers[_buyer].amount1 * percentFinal / 100 >= _amount)
            {
                buyers[_buyer].amount1 = buyers[_buyer].amount1 - _amount;
                return 0;
            }
            else
            {
                uint balance = _amount - buyers[_buyer].amount1 * percentFinal / 100;
                buyers[_buyer].amount1 = buyers[_buyer].amount1 -  buyers[_buyer].totalAmount1 * percentFinal / 100;
                return balance;
            }
        }
        else if(buyerType == 10)
        {
            if(buyers[_buyer].totalAmount1 * 10/100 >= _amount)
            {
                buyers[_buyer].amount1 = buyers[_buyer].amount1 - _amount;
                return 0;
            }
            else
            {
                uint balance = _amount - buyers[_buyer].totalAmount1 * 10/100;
                buyers[_buyer].amount1 = buyers[_buyer].amount1 -  buyers[_buyer].totalAmount1 * 10/100;
                return balance;
            }
        }
        else if(buyerType == 2)
        {
            if(buyers[_buyer].amount2 >= _amount)
            {
                buyers[_buyer].amount2 = buyers[_buyer].amount2 - _amount;
                return 0;
            }
            else
            {
                uint balance = _amount - buyers[_buyer].amount2;
                buyers[_buyer].amount2 = 0 ;
                return balance;
            }
        }
        else if(buyerType == 3)
        {
            if(buyers[_buyer].amount3 >= _amount)
            {
                buyers[_buyer].amount3 = buyers[_buyer].amount3 - _amount;
                return 0;
            }
            else
            {
                uint balance = _amount - buyers[_buyer].amount3;
                buyers[_buyer].amount3 = 0 ;
                return balance;
            }
        }
        else if(buyerType == 4)
        {
            if(buyers[_buyer].amount4 >= _amount)
            {
                buyers[_buyer].amount4 = buyers[_buyer].amount4 - _amount;
                return 0;
            }
            else
            {
                uint balance = _amount - buyers[_buyer].amount4;
                buyers[_buyer].amount4 = 0 ;
                return balance;
            }
        }
    
        return 0;
    }
    
    // To check whether an ID is in the pendingTransactionList
    function checkPendingTransactionList(uint _id) internal view returns(bool)
    {
        for(uint i = 0; i < pendingTransactionList.length; i++)
        {
            if(pendingTransactionList[i] == _id)
            {
                return true;
            }
        }
    
        return false;
    }
    
    // To change the status into failed and delete all the pending transaction that has exceed the time allowed
    function deleteExceededTimePendingTransaction() internal
    {
        for(uint i = 0; i < pendingTransactionList.length; i++)
        {
            bool check = checkPendingTransactionList(i);
            if(check && block.timestamp > ownerTransactions[i].allowedTime)
            {
                ownerTransactions[i].status = "failed";
                delete pendingTransactionList[i];
            }
        }
    }
    
    // This function will create a pending transaction for signer to sign
    function createPendingTransaction(address _to, uint _amount) internal returns(uint)
    {
        uint id =  pendingTransactionID;
        ownerTransactions[id] = OwnerTransaction(_to, _amount, "pending", block.timestamp + 300);
        pendingTransactionList.push(id);
    
        pendingTransactionID = pendingTransactionID + 1;
    
        return id;
    }
    
    // for signer to approve all the transaction in the pendingTransactionList
    function approveAllPendingTransaction() onlySigner public
    {
        for(uint i = 0; i < pendingTransactionList.length; i++)
        {
            uint id =  pendingTransactionList[i];
            bool check = checkPendingTransactionList(id);
            if(check)
            {
                if(ownerTransactions[id].allowedTime > block.timestamp && keccak256(abi.encodePacked((ownerTransactions[id].status))) == keccak256(abi.encodePacked(("pending"))))
                {
                    approvePendingTransaction(id);
                }
            }
        }
    }
    
    // for signer to approve a transaction in the pendingTransactionList
    function approvePendingTransaction(uint _id) onlySigner public
    {
        uint id = _id;
        bool check = checkPendingTransactionList(id);
        require(check, "This ID is not in the transaction pending list. Contact info@futiracoin.com for help.");
        require(result, "Did not have permission from signer. Contact info@futiracoin.com for help.");
    
        if(ownerTransactions[id].allowedTime > block.timestamp && keccak256(abi.encodePacked((ownerTransactions[id].status))) == keccak256(abi.encodePacked(("pending"))))
        {
            address _to = ownerTransactions[id].to;
            uint _amount = ownerTransactions[id].amount;
    
            if(block.timestamp <= firstType)
            {
                uint totalAmount = buyers[_to].amount1 + _amount;
                uint totalAmount2 = buyers[_to].totalAmount + _amount;
                buyers[_to].buyerAddress = _to;
                buyers[_to].amount1 = totalAmount;
                buyers[_to].totalAmount1 = totalAmount;
                buyers[_to].totalAmount = totalAmount2;
                _transferFromContract(_to, _amount);
            }
            else if(block.timestamp < secondType && block.timestamp > firstType)
            {
                uint totalAmount = buyers[_to].amount2 + _amount;
                uint totalAmount2 = buyers[_to].totalAmount + _amount;
                buyers[_to].buyerAddress = _to;
                buyers[_to].amount2 = totalAmount;
                buyers[_to].totalAmount = totalAmount2;
                _transferFromContract(_to, _amount);
            }
            else if(block.timestamp < thirdType && block.timestamp > secondType)
            {
                uint totalAmount = buyers[_to].amount3 + _amount;
                uint totalAmount2 = buyers[_to].totalAmount + _amount;
                buyers[_to].buyerAddress = _to;
                buyers[_to].amount3 = totalAmount;
                buyers[_to].totalAmount = totalAmount2;
                _transferFromContract(_to, _amount);
            }
            else
            {
                uint totalAmount = buyers[_to].amount4 + _amount;
                uint totalAmount2 = buyers[_to].totalAmount + _amount;
                buyers[_to].buyerAddress = _to;
                buyers[_to].amount4 = totalAmount;
                buyers[_to].totalAmount = totalAmount2;
                _transferFromContract(_to, _amount);
            }
    
            ownerTransactions[id].status = "successful";
            delete pendingTransactionList[id];
            emit SoldToken(msg.sender, ownerTransactions[id].to, ownerTransactions[id].amount);
        }
        else if(block.timestamp > ownerTransactions[id].allowedTime)
        {
            ownerTransactions[id].status = "failed";
            delete pendingTransactionList[id];
        }
        else if(keccak256(abi.encodePacked((ownerTransactions[id].status))) == keccak256(abi.encodePacked(("successful"))))
        {
            revert("This transaction is already already successful . Contact info@futiracoin.com for help.");
        }
        else
        {
            revert("This transaction failed. Contact info@futiracoin.com for help.");
        }
    
    }
    
    function increaseAllowance(address _to, uint _amount) onlyOwner public returns(bool){}
    function decreaseAllowance(address _to, uint _amount) onlyOwner public returns(bool){}
    function approve(address _to, uint _amount) onlyOwner public returns(bool){}
    function allowance(address _owner, address _spender) onlyOwner public view returns (uint256) {}
    
}