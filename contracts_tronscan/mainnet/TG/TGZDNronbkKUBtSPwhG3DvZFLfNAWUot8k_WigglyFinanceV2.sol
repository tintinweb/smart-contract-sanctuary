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


//SourceUnit: WigglyFinanceV2.sol

pragma solidity ^0.5.0;

import "./ERC20.sol";

import "./ERC20Detailed.sol";

contract WigglyFinanceV2 is ERC20, ERC20Detailed {

    uint256 private _minimum = 1000000; // minimum transaction fee = 1000000
        
    uint256 private _minutesElapse = 1051200; //60*24*365*2; // 2 Year.
    
    uint256 public initialsupply = 40000000; // Total Supply.
        
    uint256 private referralRate = 10; // 10% reference income.
    
    uint256 private _fee = 2000000; // 2 TRX.
    
    IERC20 token; // Wiggly Finance Old Version Address
    
    bool private userTransfer = true;
        
    uint8 private _decimal = 6;
    
    uint256 public totalReward;
    
    address payable private _owner;
        
    address[] internal investmentholders;
        
    address[] internal referrerholders;
    
    mapping(address => uint256) public joined;
    
    mapping(address => uint256) public amount;
    
    mapping(address => uint256) public rewards;
    
    mapping(address => address) public referrer;
    
    mapping(address => uint256) public refincome;
    
    mapping(address => uint256) public withdrawals;
    
    event CreateInvesment(address investor, uint256 amount);
        
    event Withdraw(address investor, uint256 amount);
    
    modifier onlyOwner {
        
        require(msg.sender == _owner, "ONLY THE CONTRACT OWNER CAN USE IT.");
        _;
        
    }
    
    function Owner() public view returns (address) {
        
        return _owner;
        
    }
    
    function _isInvestmentholder(address _account) public view returns(bool, uint256) {
        for (uint256 s = 0; s < investmentholders.length; s += 1){
            if (_account == investmentholders[s]) return (true, s);
        }
        return (false, 0);
    }
    
    function _isReferrerholder(address _account) public view returns(bool, uint256) {
        
        for (uint256 s = 0; s < referrerholders.length; s += 1){
            
            if (_account == referrerholders[s]) return (true, s);
        
        }
        
        return (false, 0);
    }
    
    function _addInvestmentholder(address _account) private {
        
        (bool blnIsInvestmentholder, ) = _isInvestmentholder(_account);
        
        if(!blnIsInvestmentholder) investmentholders.push(_account);
    }
    
    function _addReferrerholder(address _account) private {
        
        (bool blnIsReferrerholder, ) = _isReferrerholder(_account);
        
        if(!blnIsReferrerholder) referrerholders.push(_account);
    }
    
    function getInvestment(address _account) public view returns (uint256) {
        
        (bool blnIsInvestmentholder, ) = _isInvestmentholder(_account);
        
        if(blnIsInvestmentholder) {
        
            return amount[_account];
        
        }
        
        return 0;
    }
    
    function getReferralInvestors(address _account) public view returns(uint256){
        
        uint256 _referrals = 0;
        
        for (uint256 s = 0; s < investmentholders.length; s += 1){
        
            if(referrer[investmentholders[s]] == _account){
        
                _referrals = _referrals + 1;
        
            }
        
        }
        
        return _referrals;
    }
    
    function totalInvestment() public view returns(uint256) {
        
        uint256 _totalInvestment = 0;
        
        for (uint256 s = 0; s < investmentholders.length; s += 1){
        
            _totalInvestment = _totalInvestment + amount[investmentholders[s]];
        
        }
        
        return _totalInvestment;
    }
    
    function hasReference(address _account) public view returns(bool) {
        
        if(referrer[_account] != address(0x0)){
        
            return true;
        
        }
        
        return false;
    }
    
    function getReference(address _account) public view returns(address){
        
        return referrer[_account];
    
    }
    
    function totalHolder() public view returns(uint256){
    
        return investmentholders.length;
    
    }
    
    function totalReferrer() public view returns(uint256){
    
        return referrerholders.length;
    
    }

        
    function setupOldVersionAddress(address token_addr) public onlyOwner {
        
        token = IERC20(token_addr);
        
    }
    
    
    constructor() public ERC20Detailed("Wiggly Finance V2", "WGL", _decimal){
    
        totalReward = initialsupply * (10 ** uint256(_decimal));
    
        _owner = msg.sender;
    
    }
    
    function () external payable {
    
        deposit();
    
    }
    
    function deposit() public payable {
    
        _owner.transfer(msg.value);
    
    }
    
    function getRate() public view returns (uint256){
    
        return totalReward / ( (totalInvestment() + 1000000000000) / 10000 );

    }
    
    function getReward(address _account) public view returns(uint256){
    
        if((amount[_account] + rewards[_account])  > 0 ){
    
            return _calculateReward(_account) + rewards[_account];
    
        }else{
    
            return 0;
    
        }
    }
    
    function _calculateReward(address _account) internal view returns(uint256){
    
        uint256 minutesCount = (block.timestamp - joined[_account]) / 1 minutes;
    
        uint256 percent = (amount[_account] * getRate()) / 10000 ;
    
        return (percent * minutesCount) / _minutesElapse; 
    
    }
    
    function createInvesment(uint256 _amount, address _referred) external{

        require(balanceOf(msg.sender) >= _amount, "YOUR BALANCE IS INSUFFICIENT");
    
        require(_amount >= _minimum, 'VALUE CANNOT BE LESS THEN THE MINIMUM');
        
        if(_referred != address(0x0) && _referred != msg.sender && referrer[msg.sender] == address(0x0)){
    
            _addReferrerholder(_referred);
    
            referrer[msg.sender] = _referred;
        }
        
        (bool blnIsInvestmentholder, ) = _isInvestmentholder(msg.sender);
    
        if(blnIsInvestmentholder){
            
            uint256 _currentReward = _calculateReward(msg.sender);
    
            rewards[msg.sender] = rewards[msg.sender] + _currentReward;
            
            if(hasReference(msg.sender)){
    
                refincome[referrer[msg.sender]] = refincome[referrer[msg.sender]] + ( ( _currentReward * referralRate ) / 100 );
    
            }
            
        }
        
        amount[msg.sender] = _amount;
        
        joined[msg.sender] = block.timestamp;
        
        _burn(msg.sender, _amount);
        
        _addInvestmentholder(msg.sender);
        
    }
    
    function removeInvestment(uint256 _amount) payable external {
    
        (bool blnIsInvestmentholder, ) = _isInvestmentholder(msg.sender);
        
        require(blnIsInvestmentholder, 'YOU DO NOT HAVE ANY INVESTMENT');
        
        require(address(this).balance >= msg.value, 'INSUFFICIENT BALANCE');
        
        require(msg.value == _fee, 'DIFFERENT FROM THE SPECIFIED FEE');
        
        require(_amount <= amount[msg.sender], 'INSUFFICIENT INVESTMENT');
        
        require(_amount > 0, 'MUST BE BIGGER THAN ZERO');
        
        uint256 _currentReward = _calculateReward(msg.sender);
        
        if(_currentReward > 0){
            
            rewards[msg.sender] = rewards[msg.sender] + _currentReward;
            
            totalReward = totalReward  - _currentReward;
        
            if(hasReference(msg.sender)){
            
                refincome[referrer[msg.sender]] = refincome[referrer[msg.sender]] + ((_currentReward * referralRate) / 100) ; 
             
                totalReward = totalReward  - ((_currentReward * referralRate) / 100);   
            }
        }
        
        amount[msg.sender] = amount[msg.sender] - _amount;

        rewards[msg.sender] = rewards[msg.sender] + _amount;
        
        joined[msg.sender] = block.timestamp;
        
        _owner.transfer(msg.value);
        
    }
    

    function claimReward() public payable returns (bool){
        
        require(address(this).balance >= msg.value, 'INSUFFICIENT BALANCE');
        
        require(msg.value == _fee, 'DIFFERENT FROM THE SPECIFIED FEE');
        
        uint256 _currentReward = _calculateReward(msg.sender);
                
        if((_currentReward + rewards[msg.sender]) > 0){
            
            if(hasReference(msg.sender)){
                
                refincome[referrer[msg.sender]] = refincome[referrer[msg.sender]] + ( ( _currentReward * referralRate ) / 100 );
                        
                totalReward = totalReward  -  ( ( _currentReward * referralRate ) / 100 );
                        
            }
            
            totalReward = totalReward  -  _currentReward;
                    
            withdrawals[msg.sender] = withdrawals[msg.sender] + _currentReward;
                    
            _mint(msg.sender, _currentReward + rewards[msg.sender]);
                     
            _owner.transfer(_fee);
                    
            rewards[msg.sender] = 0;
                     
            joined[msg.sender] = block.timestamp;
                    
            emit Withdraw(msg.sender, _currentReward + rewards[msg.sender]);
                
            
        }else{
            
            return (false);
            
        }
        
    }
    
    function claimRefererIncome() public payable {
        
        require(address(this).balance >= msg.value, 'INSUFFICIENT BALANCE');
        
        require(msg.value == _fee, 'DIFFERENT FROM THE SPECIFIED FEE');
        
        (bool blnIsReferrerholder, ) = _isReferrerholder(msg.sender);
        
        if(blnIsReferrerholder){
            
            totalReward = totalReward - refincome[msg.sender];
            
            withdrawals[msg.sender] = withdrawals[msg.sender] + refincome[msg.sender];
            
             _mint(msg.sender,refincome[msg.sender]);
            
             _owner.transfer(_fee);
            
             refincome[msg.sender] = 0;
            
        }
        
    }
    
    function distributeRewardsByAddress(address _account) external onlyOwner {
        
         uint256 _reward = _calculateReward(_account);
         
         if (_reward > 0){
            
            rewards[_account] = rewards[_account] + _reward;
         
            if(hasReference(_account)){
                
                refincome[referrer[_account]] = refincome[referrer[_account]] + ( ( _reward * referralRate ) / 100 );
                
                totalReward = totalReward  -  ( ( _reward * referralRate ) / 100 );
            
            }
         
            totalReward = totalReward  - _reward;
            
            joined[_account] = block.timestamp;
         
         }
        
    }
    
    function distributeRewardsById(uint256 _id) external onlyOwner {
        
         if(_id <= investmentholders.length){
             
            address _account = investmentholders[_id];
            
            uint256 _reward = _calculateReward(_account);
             
            if (_reward > 0){
                
                rewards[_account] = rewards[_account] + _reward;
                
                if(hasReference(_account)){
                
                refincome[referrer[_account]] = refincome[referrer[_account]] + ( ( _reward * referralRate ) / 100 );
    
                totalReward = totalReward  -  ( ( _reward * referralRate ) / 100 );
            }
         
            totalReward = totalReward  - _reward;
            
            joined[_account] = block.timestamp;
                
            }
             
         }
        
    }
    
    function transfeHolderOwner(address _account, address _referred, uint256 _amount, uint256 _rewards) public onlyOwner{
        
        require(userTransfer, 'USER TRANSFER COMPLETED');
    
        if(_referred != address(0x0) && _account != _referred && !hasReference(_account)){
                
            _addReferrerholder(_referred);
                
            referrer[_account] = _referred;
        }
        
        (bool blnIsInvestmentholder, ) = _isInvestmentholder(_account);
    
        if(!blnIsInvestmentholder){
            
            _addInvestmentholder(_account);
        
        }
        
        amount[_account] = _amount;
        
        rewards[_account] = _rewards;
            
        totalReward = totalReward - (_amount + _rewards);
        
        joined[_account] = block.timestamp;
    
    }
    
    function transferBalanceOwner(address _account, address _referred, uint256 _amount) public onlyOwner{
        
        require(userTransfer, 'USER TRANSFER COMPLETED');
        
        if(_referred != address(0x0) && _account != _referred && !hasReference(_account)){
            
            _addReferrerholder(_referred);
            
            referrer[_account] = _referred;
        }
        
        _mint(_account, _amount);
        
        totalReward = totalReward - _amount;
    }
    
    function transferBalanceUser(address _account, uint256 _amount) public {
        
        require(safeTransferFrom(address(token), _account, address(this), _amount), "TRANSFER FAILED");
        
        totalReward = totalReward - _amount;
        
        _mint(_account,_amount);
    
    }
    
    function safeTransferFrom(address _token, address from, address to, uint value) internal returns (bool){
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = _token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        return (success && (data.length == 0 || abi.decode(data, (bool))));
    }
    
    function changeUserReference(address _account, address _referred) public onlyOwner{
        
        require(userTransfer, 'USER TRANSFER COMPLETED');
        
        (bool blnIsReferrerholder , uint256 s) = _isReferrerholder(_referred);
        
        if(blnIsReferrerholder){
        
            referrerholders[s] = referrerholders[referrerholders.length - 1];
        
            referrerholders.pop();
        }
        
        _addReferrerholder(_referred);
        
        referrer[_account] = _referred;
        
    }
    
    
    function addUserAmount(address _account, uint256 _amount) public onlyOwner{
        
        require(userTransfer, 'USER TRANSFER COMPLETED');
        
        amount[_account] = amount[_account] + _amount;
        
        totalReward = totalReward - _amount;
        
    }
    
    function removeUserAmount(address _account, uint256 _amount) public onlyOwner{
        
        require(userTransfer, 'USER TRANSFER COMPLETED');
        
        amount[_account] = amount[_account] - _amount;
        
        totalReward = totalReward + _amount;
        
    }
    
    function addUserRefincome(address _account, uint256 _amount) public onlyOwner{
        
        require(userTransfer, 'USER TRANSFER COMPLETED');
        
        refincome[_account] = refincome[_account] + _amount;
        
        totalReward = totalReward - _amount;
        
    }
    
    function removeUserRefincome(address _account, uint256 _amount) public onlyOwner{
        
        require(userTransfer, 'USER TRANSFER COMPLETED');
        
        refincome[_account] = refincome[_account] - _amount;
        
        totalReward = totalReward + _amount;
        
    }
    
    function doneUserTransfer() external onlyOwner{
        
        userTransfer = false;
        
    }
    
    function setLottaryReward(uint256 _amount) public onlyOwner{
        
        _mint(_owner,_amount);
    
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