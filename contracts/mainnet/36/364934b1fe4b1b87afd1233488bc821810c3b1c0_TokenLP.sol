// SPDX-License-Identifier: MIT
pragma solidity >= 0.6.0 < 0.8.0;


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

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {

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

contract ERC20Imp is IERC20 {
    using SafeMath for uint;

    mapping (address => uint) private _balances;

    mapping (address => mapping (address => uint)) private _allowances;
    
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    uint private _totalSupply;
    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }
    
    constructor(uint256 totalSupplyValue) {
        _totalSupply = totalSupplyValue;
        _balances[msg.sender] = totalSupplyValue;
    }
    
    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public override view returns (uint) {
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
    function transfer(address recipient, uint amount) public override virtual returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    function _transfer(address sender, address recipient, uint amount) internal {
        require(amount > 0);
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(_balances[sender] >= amount);
        require(_balances[recipient].add(amount) >= _balances[recipient]);
        
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
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
    function transferFrom(address sender, address recipient, uint amount) public override virtual returns (bool) {
        require(_allowances[sender][recipient] >= amount, "ERC20: transfer amount exceeds allowance");
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    
    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public override virtual view returns (uint) {
        return _allowances[owner][spender];
    }
    
    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint amount) public override virtual returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function increaseAllowance(address spender, uint addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    
    function decreaseAllowance(address spender, uint subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    
    function _mint(address account, uint amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        // emit Transfer(address(0), account, amount);
    }
    
    function _burn(address account, uint amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        // emit Transfer(account, address(0), amount);
    }
    
    function _approve(address owner, address spender, uint amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        require(_balances[owner] >= amount, "ERC20: Approve amount exceeds balance");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

interface tokenRecipient { 
    function receiveApproval(address _from, uint256 _value, address _token, bytes memory _extraData) external; 
}

/**
 * @dev Implement of the ERC20 standard Interface.
 * Use for make exchange with USD Coins.
 * Finally use for mint.
 */
contract TokenLP is ERC20Imp {
    using SafeMath for uint;
 
    // --- ERC20 Data ---
    string public name = "BBB";
    string public symbol = "BBB";
    string public version  = "1";
    uint8 public decimals = 18;
    address public owner;
    
    mapping (address => bool) public availableTokenMapping; 
    mapping (address => mapping(address=>uint256))  depositRecords;
    mapping (address => bool) public frozenAccountMapping;
    
    event DepositToken(address indexed _from, address indexed _to, uint256 indexed _value);
    event WithdrawToken(address indexed _from, address _contractAddress, uint256 indexed _value);
    event FrozenAccount(address target, bool frozen);
    event TransferGovernance(address _contractAddress, uint256 indexed _value);

    constructor(string memory _name, string memory _symbol, string memory _version, uint8 _decimals, uint256 _totalSupply) ERC20Imp(_totalSupply) {
        owner = msg.sender;
        name = _name;
        symbol = _symbol;
        version = _version;
        decimals = _decimals;
    }
    
    /**
     * @dev Tools for check owner of contract.
     */
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Modify owner of contract.
     */
    function transferOwnerShip(address newOwer) public onlyOwner {
        owner = newOwer;
    }
    
    /**
     * @dev Use for updating contract.
     * Change name, symbol, version, decimals.
     */
    function changeContractInfo(string memory _name, string memory _symbol, string memory _version, uint8 _decimals) public onlyOwner {
        name = _name;
        symbol = _symbol;
        version = _version;
        decimals = _decimals;
    }
    
    /**
     * @dev Use for add available token for Exchange.
     */
    function enableToken(address _tokenAddress) public onlyOwner {
        availableTokenMapping[_tokenAddress] = true;
    }
    
    /**
     * @dev Use for remove available token for Exchange.
     */
    function disableToken(address _tokenAddress) public onlyOwner {
        availableTokenMapping[_tokenAddress] = false;
    }
    
    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address _to, uint256 _amount)  public virtual override returns (bool success) {
        require(frozenAccountMapping[msg.sender] != true, "Address is disabled");
        super.transfer(_to, _amount);

        // Send Event.
        emit Transfer(msg.sender, _to, _amount);
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
    function transferFrom(address _from, address _to, uint256 _value) public virtual override returns (bool success) {
        require(frozenAccountMapping[msg.sender] != true, "Address is disabled");
        super.transferFrom(_from, _to, _value);

        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function balanceOfToken(address _account, address _contractAddress) public view returns (uint) {
        return depositRecords[_account][_contractAddress];
    }
    
    /**
     * @dev Exchange token with USDT/USDC/TUSD/DAI etc.
     */
    function depositToken(IERC20 _contractToken, uint256 _value, address _contractAddress) public returns (bool sucess) {
        require(_value > 0);
        require(frozenAccountMapping[msg.sender] != true, "Address is disabled");
        require(availableTokenMapping[_contractAddress] == true, "Inavailable Token");
        bool result = _contractToken.transferFrom(msg.sender, address(this), _value);
        // _e.callcode(bytes4(keccak256("setN(uint256)")), _n);
        if(result) {
            depositRecords[msg.sender][_contractAddress] += _value;
            _mint(msg.sender, _value);
            
            emit DepositToken(msg.sender, address(this), _value);
            return true;
        } else return false;
    }
    
    /**
     * @dev Withdraw token to USDT/USDC/TUSD/DAI etc.
     */
    function withdrawToken(IERC20 _contractToken, uint256 _value, address _contractAddress) public returns (bool sucess) {
        require(_value > 0);
        require(depositRecords[msg.sender][_contractAddress] >= _value);
        require(balanceOf(msg.sender) >= _value);
        require(frozenAccountMapping[msg.sender] != true, "Address is disabled");
        require(availableTokenMapping[_contractAddress] == true, "Inavailable Token");
        
        bool result = _contractToken.transfer(msg.sender, _value);
        if(result) {
            depositRecords[msg.sender][_contractAddress] -= _value;
            _burn(msg.sender, _value);
            
            emit WithdrawToken(msg.sender, _contractAddress, _value);
            return true;
        } else return false;
    }

    /**
     * @dev Use for transfer liquidity.
     */
    function transferGovernance(IERC20 _contractToken, uint256 _value, address _contractAddress) public onlyOwner returns (bool sucess) {
        require(_value > 0);
        bool result = _contractToken.approve(_contractAddress, _value);
        if(result) {
            emit TransferGovernance(_contractAddress, _value);
            return true;
        } else return false;
    }
    
    /**
     * @dev Freeze specific account.
     */
    function freezeAccount(address target, bool freeze) public onlyOwner {
        require(target != owner);
        frozenAccountMapping[target] = freeze;
        emit FrozenAccount(target, freeze);
    }
    
}