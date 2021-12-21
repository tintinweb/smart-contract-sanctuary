//SourceUnit: AbdoToken.sol

// 0.5.1-c8a2
// Enable optimization
pragma solidity ^0.5.0;

import "./ERC20.sol";
import "./ERC20Detailed.sol";

/**
 * @title SimpleToken
 * @dev Very simple ERC20 Token example, where all tokens are pre-assigned to the creator.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `ERC20` functions.
 */
contract AbdoToken is ERC20, ERC20Detailed {

    bool public buyDuringLaunchFlag = true; // intially it will be true

    // details about the token
    // uint256 public total_supply;
    // uint256 public currentSupply;
    // mapping(address => uint256) public balanceOf;

    address public owner;

    address[] investorCount;
    mapping(address => Investor) public investors;
    struct Investor 
    {
        address investorAddress;

        uint256 unlockDate4months;
        uint256 unlockDate8months;
        uint256 unlockDate12months;
    }

    address[] investor2Count;
    mapping(address => Investor2) public investors2;
    struct Investor2 
    {
        address investorAddress;
        uint256 unlockDate2months;
    }

    event TransferedFromCurrentSupply(uint from, address indexed to, uint256 value);

    event BoughtTokenDuringLaunch(address from, address to, uint amount);
    event BoughtToken(address from, address to, uint amount);
    event SoldToken(address from, address to, uint amount);



    modifier onlyOwner {
        require(msg.sender == owner, "You are not the owner of this smart contract");
        _;
    }

    constructor() public ERC20Detailed("AbdoToken", "ABT", 18) {
        // _mint(msg.sender, 20000000000 * (10 ** decimals()));
        _mint(msg.sender, 5);
        // investors[msg.sender] = Investor(msg.sender, 0, 0, 0);
        investors[msg.sender] = Investor(msg.sender, 0, 0, 0); //this is just for testing

        owner = msg.sender;
    }

    function checkCurrentSupply() view public onlyOwner returns(uint) 
    {
        return balanceOf(owner);
    }

    // to adjust the total amount supply, the operation is case sensitive (add, delete)
    function setTotalSupply(string memory operation, uint _amount) onlyOwner public returns(uint) 
    {

        if(keccak256(abi.encodePacked((operation))) == keccak256(abi.encodePacked(("add"))))
        {
            // uint newTotal = _amount * (10 ** decimals());
            // _mint(msg.sender, newTotal);

            // for testing
            uint newTotal = _amount;
            _mint(msg.sender, newTotal);
            
        }
        else if(keccak256(abi.encodePacked((operation))) == keccak256(abi.encodePacked(("delete"))))
        {
            // require(balanceOf(owner) >= _amount * (10 ** decimals()), "The amount is greater than the total supply"); // just for testing
            // uint newTotal = _amount * (10 ** decimals());
            // _burn(msg.sender, newTotal);

            // for testing
            require(balanceOf(owner) >= _amount, "The amount is greater than the total supply"); // just for testing
            uint newTotal = _amount;
            _burn(msg.sender, newTotal);

        }
        else
        {
            revert("This operation is not acceptable");
        }

        return totalSupply();
    }


     // transfer from the total supply to address. 
    function _transferFromContract(address _to, uint256 _value) internal {
        require(_to != address(0));

        transferFrom(owner, _to, _value);

        emit TransferedFromCurrentSupply(balanceOf(owner), _to, _value);
    }

    // check the investor from the list of investor that bought the token during the launch if the token
    function checkInvestor(address _address) public view returns(bool) 
    {
        bool res = false;

        if(investors[_address].investorAddress == _address)
        {
            res = true;
        }

        return res;
    }

    function checkInvestor2(address _address) public view returns(bool) 
    {
        bool res = false;

        if(investors2[_address].investorAddress == _address)
        {
            res = true;
        }

        return res;
    }

    // to buy the token from the token owner after the launch of the token
    function buyToken(uint _amount) external 
    {
        require(!buyDuringLaunchFlag, "This function is not available");

        // investors2[msg.sender] = Investor2(msg.sender, block.timestamp + 5256000);
        investors2[msg.sender] = Investor2(msg.sender, block.timestamp + 30); // for testing only 
        investor2Count.push(msg.sender);


        _transferFromContract(msg.sender, _amount);
        emit BoughtToken(owner, msg.sender, _amount);
    }

    // Special function to buy the token during the launch of the token.
    // The one who bought the token during the launch will be listed in the first list of investor. 
    // This function can be pause by the owner as after the launch its better to use the 
    function buyTokenDuringLaunch(uint _amount) external 
    {
        require(buyDuringLaunchFlag, "This function is not available");

        // investors[msg.sender] = Investor(msg.sender, block.timestamp + 10510000, block.timestamp + 21020000, block.timestamp + 31540000);
        investors[msg.sender] = Investor(msg.sender, block.timestamp + 30, block.timestamp + 60, block.timestamp + 120); //this is just for testing
        investorCount.push(msg.sender);

        _transferFromContract(msg.sender, _amount);
        emit BoughtTokenDuringLaunch(owner, msg.sender, _amount);
    }

    function sellToken(address _to, uint _amount) external 
    {
        bool check = checkInvestor(msg.sender);
        bool check2 = checkInvestor2(msg.sender);

        if(check && check2)
        {
            if(investors[msg.sender].unlockDate12months > investors2[msg.sender].unlockDate2months)
            {
                _sellTokenInvestors2(_to, _amount);
            }
            else
            {
                _sellTokenInvestors(_to, _amount);
            }
        }
        else if(check)
        {   
           _sellTokenInvestors(_to, _amount);
        }
        else if(check2)
        {
            _sellTokenInvestors2(_to, _amount);
        }
        else
        {
            revert("Address invalid!");
        }
    }

    // for the investor who buy the token before/during the launch
    function _sellTokenInvestors(address _to, uint _amount) internal 
    {
        if( block.timestamp >= investors[msg.sender].unlockDate4months && block.timestamp < investors[msg.sender].unlockDate8months) 
        {
            uint permissableAmount = balanceOf(msg.sender) * 10 / 100;
            if(_amount > permissableAmount)
            {
                revert("The amount you want to sell is higher than you're allowed");
            }

            transfer(_to, _amount);
            emit SoldToken(owner, msg.sender, _amount);
        }
        else if(block.timestamp >= investors[msg.sender].unlockDate8months && block.timestamp < investors[msg.sender].unlockDate12months)
        {
            uint permissableAmount = balanceOf(msg.sender) * 45 / 100;
            if(_amount > permissableAmount)
            {
                revert("The amount you want to sell is higher than you're allowed");
            }

            transfer(_to, _amount);
            emit SoldToken(owner, msg.sender, _amount);
        }
        else if(block.timestamp >= investors[msg.sender].unlockDate12months)
        {
            transfer(_to, _amount);
            emit SoldToken(owner, msg.sender, _amount);
        }
        else
        {
            revert("You did not pass your freeze period yet.");
        }
    }

    // for investor who buy the token after the launch
    function _sellTokenInvestors2(address _to, uint _amount) internal 
    {
        require(block.timestamp >= investors2[msg.sender].unlockDate2months, "You did not pass your freeze period yet.");
        transfer(_to, _amount);
        emit SoldToken(owner, msg.sender, _amount);
    }

}

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