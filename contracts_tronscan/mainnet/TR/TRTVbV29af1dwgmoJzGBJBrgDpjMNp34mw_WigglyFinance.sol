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
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals
    ) public {
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

//SourceUnit: WigglyFinance.sol

pragma solidity ^0.5.0;

import "./ERC20.sol";
import "./ERC20Detailed.sol";

contract WigglyFinance is ERC20, ERC20Detailed {

    struct Invester {
        uint256 _joined;
        uint256 _amount;
        uint256 _rewards;
        address _referrer;
    }
    
    uint256 private _minimum = 1000000; // minimum transaction fee = 1000000
    
    uint256 private _minutesElapse = 1051200; //60*24*365*2; // 2 Year.
    
    uint256 private _tokenRate = 6; // 1 wiggly for 6 tron.
    
    uint256 public initialsupply = 40000000; // Total Supply.
    
    uint256 private _initialwillbeSold = 4000000; // Total Sale Wiggly
    
    uint256 private _payofowner = 2000000;
    
    uint256 private _ticketprice = 10;
    
    uint256 private _totalLottaryReward = 20000; // Total Lottary Reward;
    
    uint256 private referralRate = 10; // 10% reference income.
    
    uint256 private resetMaxInvestmenttRate = 10; // burn 10% for reset max investment.
    
    uint256 private _fee = 2000000; // 2 TRX.
    
    uint8 private _decimal = 6;
    
    uint256 private _totalOnSale;
    
    uint256 public totalReward;
    
    uint256 public waitingTimer = 0; // Waiting Timer;
    
    address payable private _owner;
    
    address[] internal investmentholders;
    
    address[] internal referrerholders;
    
    mapping(address => Invester) private _investers;
    
    mapping(uint256 => address) public luckyInvesters;
    
    mapping(address => uint256) public referrer;
    
    mapping(address => uint256) private withdrawals;
    
    mapping(address => uint256) public maxinvestment;
    
    mapping(address => uint256) private tickets;
    
    mapping(address => uint256) private ticketnumbers;
    
    event CreateInvesment(address investor, uint256 amount);
    
    event Withdraw(address investor, uint256 amount);
    
    modifier onlyOwner {
      require(msg.sender == _owner, "ONLY THE CONTRACT OWNER CAN USE IT.");
      _;
    }
    
    modifier permission {
        require(waitingTimer != 0, "ICO IS NOT FINISHED YET");
        require(waitingTimer <= block.timestamp, "INVESTMENT HAS NOT STARTED YET");
      _;
    }
    
    /**
     * @dev See Withdraw
     * 
     * Shows the earnings of the investor.
     */
    
    function getWithdrawals(address _account) public view returns (uint256) {
        return withdrawals[_account];
    }
    
    /**
     * @dev See _totalOnSale
     * 
     * Displays the total number of Wiggly available for sale
     * 
     */
    
    function totalOnSale() public view returns (uint256) {
        return _totalOnSale;
    }
    
    /**
     * @dev See Owner
     * 
     * Shows the contract holder's address
     * 
     */
     
    function Owner() public view returns (address) {
        return _owner;
    }
    
    /**
     * @dev See Invester control.
     * 
     */
     
    function _isInvestmentholder(address _invester) public view returns(bool, uint256) {
        for (uint256 s = 0; s < investmentholders.length; s += 1){
            if (_invester == investmentholders[s]) return (true, s);
        }
        return (false, 0);
    }
    
    /**
     * @dev Reference control. 
     * 
     */
    
    function _isReferrerholder(address _referrer) public view returns(bool, uint256) {
        for (uint256 s = 0; s < referrerholders.length; s += 1){
            if (_referrer == referrerholders[s]) return (true, s);
        }
        return (false, 0);
    }
    
    /**
     * @dev Add invester to holder. 
     * 
     */
    
    function _addInvestmentholder(address _invester) private {
        (bool blnIsInvestmentholder, ) = _isInvestmentholder(_invester);
        if(!blnIsInvestmentholder) investmentholders.push(_invester);
    }
    
    /**
     * @dev Add Referrer to holder. 
     * 
     */
     
    function _addReferrerholder(address _referrer) private {
        (bool blnIsReferrerholder, ) = _isReferrerholder(_referrer);
        if(!blnIsReferrerholder) referrerholders.push(_referrer);
    }
    
    /**
     * @dev Get Investers investment amount. 
     * 
     */
     
    function getInvestment(address _invester) public view returns (uint256) {
        (bool blnIsInvestmentholder, ) = _isInvestmentholder(_invester);
        if(blnIsInvestmentholder) {
            return _investers[_invester]._amount;
        }
        return 0;
    }
    
    /**
     * @dev Total number of users the user refers.
     * 
     */
    
    function getReferralInvestors(address _account) public view returns(uint256){
        uint256 _referrals = 0;
        for (uint256 s = 0; s < investmentholders.length; s += 1){
            if(_investers[investmentholders[s]]._referrer == _account){
                _referrals = _referrals.add(1);
            }
        }
        return _referrals;
    }
    
    /**
     * @dev Total investment amount.
     * 
     */
    
    function totalInvestment() public view returns(uint256) {
        uint256 _totalInvestment = 0;
        for (uint256 s = 0; s < investmentholders.length; s += 1){
            _totalInvestment = _totalInvestment.add(_investers[investmentholders[s]]._amount);
            }
        return _totalInvestment;
    }
    
    function hasReference(address _invester) public view returns(bool) {
        if(_investers[_invester]._referrer != address(0x0)){
            return true;
        }
        return false;
    }
    
    function getTicket(address _account) public view returns(uint256){
        return tickets[_account].div(_ticketprice.mul(10 ** uint256(_decimal)));
    }
    
    function getReference(address _account) public view returns(address){
        return _investers[_account]._referrer;
    }
    
    function totalHolder() public view returns(uint256){
        return investmentholders.length;
    }
    
    function totalReferrer() public view returns(uint256){
        return referrerholders.length;
    }
    
    /**
     * name : Wiggly Finance
     * symbol : WGL
     * decimal : 6
     */
    
    /**
     * @dev Сonstructor Sets the original roles of the contract
     */
    
    constructor() public ERC20Detailed("Wiggly Finance", "WGL", _decimal){
        _owner = msg.sender;
        _totalOnSale = _totalOnSale.add(_initialwillbeSold * (10 ** uint256(_decimal)));
        totalReward = initialsupply.sub(_initialwillbeSold).sub(_payofowner).mul((10 ** uint256(_decimal)));
       _mint(msg.sender, (_payofowner * (10 ** uint256(_decimal))));
    }
    
    /**
     * @dev fallback function, redirect from wallet to deposit()
     */
     
    function () external payable {
        deposit(address(0x0));
    }
    
    /**
     * #dev Sends wiggly for tron
     */
     
    function deposit(address _referred) public payable {
    
        uint256 _sold;
        
        if(_totalOnSale >= (2000000 * (10 ** uint256(_decimal)))){
            _sold = msg.value.div(_tokenRate);
        }else if(_totalOnSale <= (1000000 * (10 ** uint256(_decimal)))){
            _sold = msg.value.div(_tokenRate + 2);
        }else{
            _sold = msg.value.div(_tokenRate + 1);
        }
        
        require(msg.value >= _minimum, 'VALUE CANNOT BE LESS THEN THE MINIMUM');
        require(address(this).balance >= msg.value, 'INSUFFICIENT BALANCE');
        require(_totalOnSale >= _sold, 'NOT ENOUGH TOKENS TO BE SOLD');

        if(_referred != address(0x0) && _referred != msg.sender && !hasReference(msg.sender)){
            
            uint256 _reward = _sold.mul(referralRate).div(100);
            _addReferrerholder(_referred);
            _investers[msg.sender]._referrer = _referred;
            referrer[_referred] = referrer[_referred].add(_reward);
            
        }
        
        _mint(msg.sender,_sold);
        _totalOnSale = _totalOnSale.sub(_sold);
        _owner.transfer(msg.value);
        
    }
    
    
    function resetMaxDeposit() public payable{
        
        require(maxinvestment[msg.sender] > 0, 'INVESTMENT MUST BE GREATER THAN ZERO');
        uint256 _burnFee = maxinvestment[msg.sender].mul(10).div(100); // %10 BURN
        require(balanceOf(msg.sender) >= _burnFee, "YOUR BALANCE IS INSUFFICIENT"); 
        require(msg.value == 5000000, 'VALUE MUST BE EQUAL TO MAX INFESTMENT FEE');
        require(address(this).balance >= 5000000, "YOUR BALANCE IS INSUFFICIENT");
        
        maxinvestment[msg.sender] = 0; // Reset Max Investment
        _burn(msg.sender,_burnFee);
        _owner.transfer(msg.value);
        
    }
    
    function createInvesment(uint256 _amount, address _referred) permission external{

        require(balanceOf(msg.sender) >= _amount, "YOUR BALANCE IS INSUFFICIENT");
        require(_amount >= _minimum, 'VALUE CANNOT BE LESS THEN THE MINIMUM');
        
        if(_referred != address(0x0) && _referred != msg.sender && !hasReference(msg.sender)){
            _addReferrerholder(_referred);
            _investers[msg.sender]._referrer = _referred;
        }
        
        if(_investers[msg.sender]._amount.add(_amount) > maxinvestment[msg.sender]){
            uint256 _difference = _investers[msg.sender]._amount.add(_amount).sub(maxinvestment[msg.sender]);
            maxinvestment[msg.sender] = maxinvestment[msg.sender].add(_difference);
            tickets[msg.sender] = tickets[msg.sender].add(_difference);
        }
        
        (bool blnIsInvestmentholder, ) = _isInvestmentholder(msg.sender);
        if(blnIsInvestmentholder){
            uint256 _balance = _calculateReward(msg.sender).add(_investers[msg.sender]._rewards);
            _investers[msg.sender]._rewards = _balance;
            if(hasReference(msg.sender)){
                referrer[_investers[msg.sender]._referrer] = referrer[_investers[msg.sender]._referrer].add(_balance.mul(referralRate).div(100)); 
            }
        }
        
        _investers[msg.sender]._amount = _investers[msg.sender]._amount.add(_amount);
        _investers[msg.sender]._joined = block.timestamp;
        _burn(msg.sender,_amount);
        _addInvestmentholder(msg.sender);
        
        emit CreateInvesment(msg.sender, _amount);
    }
    
    function removeInvestment(uint256 _amount) payable external {
        (bool blnIsInvestmentholder, ) = _isInvestmentholder(msg.sender);
        require(blnIsInvestmentholder, 'YOU DO NOT HAVE ANY INVESTMENT');
        require(_investers[msg.sender]._amount > _amount, 'YOUR INVESTMENT IS INSUFFICIENT, TRY `killInvestment()` FUNCTION');
        require(address(this).balance >= msg.value, 'INSUFFICIENT BALANCE');
        require(msg.value == _fee, 'DIFFERENT FROM THE SPECIFIED FEE');
        
        uint256 _balance = _calculateReward(msg.sender).add(_investers[msg.sender]._rewards);
        _investers[msg.sender]._rewards = _balance;
        if(hasReference(msg.sender)){
            referrer[_investers[msg.sender]._referrer] = referrer[_investers[msg.sender]._referrer].add(_balance.mul(referralRate).div(100)); 
        }
        
        _investers[msg.sender]._amount = _investers[msg.sender]._amount.sub(_amount);
        _investers[msg.sender]._joined = block.timestamp;
        _mint(msg.sender, _amount);
        _owner.transfer(msg.value);
        
    }
    

    function killInvestment() payable external{
        (bool _isInvestment, uint256 s) = _isInvestmentholder(msg.sender);

        require(_isInvestment, 'YOU DO NOT HAVE ANY INVESTMENT');
        require(address(this).balance >= msg.value, 'INSUFFICIENT BALANCE');
        require(msg.value == _fee, 'DIFFERENT FROM THE SPECIFIED FEE');
        
        uint256 _balance = _calculateReward(msg.sender).add(_investers[msg.sender]._rewards);
        
        if(_balance > 0){
            
            if(hasReference(msg.sender)){
                referrer[_investers[msg.sender]._referrer] = referrer[_investers[msg.sender]._referrer].add(_balance.mul(referralRate).div(100)); 
            }
            
            totalReward = totalReward.sub(_balance);
                
            withdrawals[msg.sender] = withdrawals[msg.sender].add(_balance);
            
            _investers[msg.sender]._rewards = 0;
            _investers[msg.sender]._joined = block.timestamp;
            
            emit Withdraw(msg.sender, _balance);
        }
        
        _mint(msg.sender,_investers[msg.sender]._amount.add(_balance));
        _owner.transfer(msg.value);
        _investers[msg.sender]._amount = 0;
        
        
        if(_isInvestment){
            investmentholders[s] = investmentholders[investmentholders.length - 1];
            investmentholders.pop();
        }
    }
    
    function getRate() public view returns (uint256){
        return totalReward.sub(unClaimedRewards()).div(totalInvestment().add(1000000000000).div(10000));
    }
    
    function getReward(address _account) public view returns(uint256){
        if(_investers[_account]._amount > 0){
            return _calculateReward(_account).add(_investers[_account]._rewards);
        }else{
            return 0;
        }
    }
    
    function refReward(address _account) public view returns(uint256){
        uint256 _totalRewards = 0;
        for (uint256 s = 0; s < investmentholders.length; s += 1){
            if(_investers[investmentholders[s]]._referrer == _account){
                _totalRewards = _totalRewards.add(_calculateReward(investmentholders[s]).mul(referralRate).div(100));
            }
        }
        return _totalRewards.add(referrer[_account]);
    }
    
    function _calculateReward(address _account) internal view returns(uint256){
        uint256 minutesCount = block.timestamp.sub(_investers[_account]._joined).div(1 minutes); // Time elapsed since the investment was made
        uint256 percent = _investers[_account]._amount.mul(getRate()).div(10000); // how much return
        return percent.mul(minutesCount).div(_minutesElapse); // minute jump, for example 1 day;
    }
    
    function distributeRewards() external onlyOwner returns(bool){

        for (uint256 s = 0; s < investmentholders.length; s += 1){
            uint256 _balance = _calculateReward(investmentholders[s]);
            _investers[investmentholders[s]]._rewards = _investers[investmentholders[s]]._rewards.add(_balance);
            if(hasReference(investmentholders[s])){
                referrer[_investers[investmentholders[s]]._referrer] = referrer[_investers[investmentholders[s]]._referrer].add(_balance.mul(referralRate).div(100));
            }
            _investers[investmentholders[s]]._joined = block.timestamp;
        }
        return true;
    }
    
    function unClaimedRewards() public view returns(uint256) {
        uint256 _totalRewards = 0;
        for (uint256 s = 0; s < investmentholders.length; s += 1){
            _totalRewards = _totalRewards.add(_investers[investmentholders[s]]._rewards);
        }
        return _totalRewards.add(unClaimedReferrerRewards());
    }
    
    function unClaimedReferrerRewards() public view returns(uint256) {
        uint256 _totalReward = 0;
        for (uint256 s = 0; s < referrerholders.length; s += 1){
            _totalReward = _totalReward.add(referrer[referrerholders[s]]);
            }
        return _totalReward;
    }
    
    function claimReward() public payable returns (bool){
        
        require(address(this).balance >= msg.value, 'INSUFFICIENT BALANCE');
        require(msg.value == _fee, 'DIFFERENT FROM THE SPECIFIED FEE');
        
        if(_investers[msg.sender]._amount > 0){
            uint256 _balance = _calculateReward(msg.sender).add(_investers[msg.sender]._rewards);
            if(_balance > 0){
                
                if(hasReference(msg.sender)){
                    referrer[_investers[msg.sender]._referrer] = referrer[_investers[msg.sender]._referrer].add(_balance.mul(referralRate).div(100)); 
                }
                
                totalReward = totalReward.sub(_balance.add(_balance));
                
                withdrawals[msg.sender] = withdrawals[msg.sender].add(_balance);
                _investers[msg.sender]._rewards = 0;
                _investers[msg.sender]._joined = block.timestamp;
                _mint(msg.sender, _balance);
                _owner.transfer(_fee);
                emit Withdraw(msg.sender, _balance);
            }
            return (true);
        }else{
            return (false);
        }
    }
    
    function claimRefererIncome() public payable returns(bool){

        require(address(this).balance >= msg.value, 'INSUFFICIENT BALANCE');
        require(msg.value == _fee, 'DIFFERENT FROM THE SPECIFIED FEE');
            
        (bool blnIsReferrerholder, ) = _isReferrerholder(msg.sender);
        
        if(blnIsReferrerholder){
            totalReward = totalReward.sub(referrer[msg.sender]);
            withdrawals[msg.sender] = withdrawals[msg.sender].add(referrer[msg.sender]);
            _mint(msg.sender,referrer[msg.sender]);
            _owner.transfer(_fee);
             emit Withdraw(msg.sender, referrer[msg.sender]);
            referrer[msg.sender] = 0;
            return true;
        }else{
            return false;
        }
    }
    
    function random(uint256 _num) internal view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp.add(_num), investmentholders)));
    }
    
    function checkTheLottery() public onlyOwner returns(bool){
        
        require(investmentholders.length > 0, 'THERE IS NOT ANY INVESTMENT');
        
        uint256 _luckyNumber;
        uint256 _numbers = 0;
        uint256 _lottaryReward = _totalLottaryReward * (10 ** uint256(_decimal));
        
        for (uint256 s = 0; s < investmentholders.length; s += 1){
            _numbers = _numbers.add(tickets[investmentholders[s]].div(_ticketprice.mul(10 ** uint256(_decimal)))); // calculate tickets
            ticketnumbers[investmentholders[s]] = _numbers; // set ticket numbers;
            tickets[investmentholders[s]] = _investers[investmentholders[s]]._amount; // reset tickets.
        }
        
        if(_numbers > 0){
            for (uint256 l = 0; l < 5; l += 1){
         
                _luckyNumber = random(l) % _numbers;
                
                // 20000 / 2 = 10000 First Prize
                // 10000 / 2 = 5000 Second Prize
                // 5000 / 2 = 2500 Third Prize
                // 2500 / 2 = 1250 fourth and fifth prize
            
                for (uint256 s = 0; s < investmentholders.length; s += 1){
                    if(_luckyNumber <= ticketnumbers[investmentholders[s]]){
                        if(l != 4) _lottaryReward = _lottaryReward.div(2);
                        luckyInvesters[l] = investmentholders[s];
                        _investers[investmentholders[s]]._rewards = _investers[investmentholders[s]]._rewards.add(_lottaryReward);
                        break;
                    }
                }
            }
        }
        
        totalReward = totalReward.sub(_lottaryReward);
        
        return true;
    }
    
    function buyTicket(uint256 _amount) external payable {
        require(balanceOf(msg.sender) >= _amount, "YOUR BALANCE IS INSUFFICIENT");
        require(_amount >= _minimum, 'VALUE CANNOT BE LESS THEN THE MINIMUM');
        require(_amount > _ticketprice.mul(10 ** uint256(_decimal)), 'VALUE CANNOT BE LESS THEN THE TICKET PRICE');
        require(msg.value == _fee, 'DIFFERENT FROM THE SPECIFIED FEE');
        
        tickets[msg.sender] = tickets[msg.sender].add(_amount);
        _burn(msg.sender,_amount);
        _owner.transfer(msg.value);
    }
    
    function doneico() external onlyOwner returns(uint256){

        if(_totalOnSale > 0){
            totalReward = totalReward.add(_totalOnSale);
            _totalOnSale = 0;
        }
        
        waitingTimer = block.timestamp.add(1296000); // 1296000 = 15 Day;
        
        return waitingTimer;
        
    }
    
    function withdrawRemainingReward() external onlyOwner{
        require(getRate() == 0, "RATE IS NOT ZERO");
        _mint(_owner,totalReward);
        totalReward = 0;
    }
    
    function withdrawOwner() external onlyOwner{
        if(address(this).balance >= 0)
        {
            _owner.transfer(address(this).balance);
        }
    }
}