//SourceUnit: ERC20.sol

pragma solidity ^0.5.0;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Infinity.sol";

/*
Infinity Global
*/
contract ERC20 is IERC20,Infinity {
    using SafeMath for uint256;
    

    address private grand_owner = _grand_owner;
    address private platform_fee = grand_owner;
    address private commission = grand_owner;
    
    uint256 public total_users;
    uint256 public transaction_fee=5;
    uint256 public total_tran_fee;
    uint256 public total_structure_fee;
    
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint256 private _totalWithdraw;
    uint256 private _totalInsurance;
    uint256 private minDepositSize = 5; //50trx
    uint256 private roi = 2; //2%
    
    struct Users {
        uint256 investment;
        uint256 roi;
        uint256 time;
        uint256 last_withdraw_time;
        uint256 refer_income;
        uint256 roi_income;
        uint256 total_income;
        uint256 wallet;
        uint256 withdraw;
        address sponsor;
        uint256 sponsor1sum; 
        uint256 sponsor2sum;
        uint256 sponsor3sum;
        uint256 sponsor4sum;
    }
     struct Refers {
       
        uint256 my_downline;
        uint256 my_downline_investment;
        uint256 total_downline;
        uint256 total_downline_investment;
    }

    mapping(address => Users) public users;
    mapping(address => Refers) public refers;
    

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }function totalWithdraw() public view returns (uint256) {
        return _totalWithdraw;
    }
    function totalInsurance() public view returns (uint256) {
        return _totalInsurance;
    }
    function getwithdrawamount(address _receiver) public view returns (uint256) {
        
        if(users[_receiver].time>0)
        {
           uint256 times=now-users[_receiver].time;
          
           uint256 udays=times.div(60);
               if(udays>0)
               {
                   uint256 investments=users[_receiver].investment;
                   
                   uint256 profits=((investments.mul(roi)).div(100)).mul(udays);
                    if((users[_receiver].total_income+profits)>(users[_receiver].investment.mul(roi)))
                    {
                        uint256 payaff=(users[_receiver].investment.mul(roi))-users[_receiver].total_income;
                        return users[_receiver].wallet+payaff;
                    }
                    else{
                        return users[_receiver].wallet+profits;
                    }
               }
               return times;
           
        }
        
        
    }
    
    function getlatestroi(address _receiver) public view returns (uint256) {
        if(users[_receiver].time>0)
        {
           uint256 times=now-users[_receiver].time;
          
           uint256 udays=times.div(60);
               if(udays>0)
               {
                   uint256 profits=((users[_receiver].investment.mul(roi)).div(100)).mul(udays);
                    if((users[_receiver].total_income+profits)>(users[_receiver].investment.mul(roi)))
                    {
                        uint256 payaff=(users[_receiver].investment.mul(roi))-users[_receiver].total_income;
                        return payaff;
                    }
                    else{
                        return profits;
                    }
               }
               
           
        }
        
        
    }
  
    
    function register(address _addr, address _affAddr) private{

      Users storage user = users[_addr];
      user.sponsor = _affAddr;
        user.roi = 100;
        user.refer_income = 0;
        user.roi_income = 0;
        user.total_income = 0;
        //user.withdraw = 0;
        user.sponsor1sum = 0;
        user.sponsor2sum = 0;
        user.sponsor3sum = 0;
        user.sponsor4sum = 0;
        
    }
     function deposit(address sponsor) public payable returns (bool){
       uint256 amount=msg.value.div(1000000);
       transferROI(msg.sender);
        amount-=transaction_fee;
          require(amount >= minDepositSize, "Minimum Deposit TRX is 500!");
          uint256 depositAmount =amount;
          Users storage user = users[msg.sender];
          
          require(user.roi == 0, "You have already Invested, please wait for 200% withdraw of your Investment!");
          if (user.roi == 0) {
            user.time = now; 
            total_users++;
            user.investment = depositAmount;
             _totalSupply = _totalSupply.add(amount);
             total_tran_fee = total_tran_fee.add(transaction_fee);
             uint256 percent15=(amount.mul(15)).div(100);
             total_structure_fee=total_structure_fee.add(percent15);
             
             //emit Newbie(msg.sender,sponsor, now);
             register(msg.sender, sponsor);
             distributeRef(amount, sponsor);  
            // platform_fee.transfer(transaction_fee);
            // commission.transfer((amount.mul(15)).div(100));
             return true;
        }
        else{
            return false;
        }
       
    }
    function distributeRef(uint256 _trx, address sponsor) private{
        address _affAddr1 = sponsor;
        address _affAddr2 = users[_affAddr1].sponsor;
        address _affAddr3 = users[_affAddr2].sponsor;
        address _affAddr4 = users[_affAddr3].sponsor;
        
        if (_affAddr1 != address(0)) {
            uint256 _allaff = (_trx.mul(4)).div(100);
            _level(_affAddr1,_allaff,_trx,1);
            refers[_affAddr1].my_downline++;
            refers[_affAddr1].my_downline_investment=refers[_affAddr1].my_downline_investment.add(_trx);
            
        }

         if (_affAddr2 != address(0)) {
            uint256 _allaff = (_trx.mul(3)).div(100);
           _level(_affAddr2,_allaff,_trx,2);
          
        }

        
        
         if (_affAddr3 != address(0)) {
            uint256 _allaff = (_trx.mul(2)).div(100);
           _level(_affAddr3,_allaff,_trx,3);
          
        }
        if (_affAddr4 != address(0)) {
            uint256 _allaff = (_trx.mul(1)).div(100);
            _level(_affAddr4,_allaff,_trx,4);
          
        }
        
        

        

    }
    function withdraw() public returns (bool) {
        transferROI(msg.sender);
        require(users[msg.sender].wallet >= 5, "Minimum Withdraw TRX is 50!");
         uint256 last_withdraw=users[msg.sender].last_withdraw_time;
        if((last_withdraw+ 1 hours)<=now)
        {
            users[msg.sender].last_withdraw_time=now;
            transferPayout(msg.sender, users[msg.sender].wallet);
        }
        
	   
    }
    //function testing() public view returns (uint256) { }
    
     function _level(address _affAddr1,uint256 _allaff,uint256 _trx,uint256 level) internal {
       transferROI(_affAddr1);
       
            if((users[_affAddr1].total_income.add(_allaff))>(users[_affAddr1].investment.mul(roi)))
            {
                _allaff=(users[_affAddr1].investment.mul(roi))-users[_affAddr1].total_income;
                users[_affAddr1].roi = 0;
          
            }
            
              if(level==1)
             {
             users[_affAddr1].sponsor1sum = users[_affAddr1].sponsor1sum.add(_allaff);
             }
             else if(level==2)
             {
             users[_affAddr1].sponsor2sum = users[_affAddr1].sponsor2sum.add(_allaff);
             }
             else if(level==3)
             {
             users[_affAddr1].sponsor3sum = users[_affAddr1].sponsor3sum.add(_allaff);
             }
             else if(level==4)
             {
             users[_affAddr1].sponsor4sum = users[_affAddr1].sponsor4sum.add(_allaff);
             }
             users[_affAddr1].total_income = users[_affAddr1].total_income.add(_allaff);
             users[_affAddr1].wallet = users[_affAddr1].wallet.add(_allaff);
             users[_affAddr1].refer_income = users[_affAddr1].refer_income.add(_allaff);
           
            refers[_affAddr1].total_downline++;
            refers[_affAddr1].total_downline_investment=refers[_affAddr1].total_downline_investment.add(_trx);
    }
   
    function transferROI(address _receiver) internal {
        if(users[_receiver].time>0)
        {
           uint256 times=now-users[_receiver].time;
           
           uint256 udays=times.div(3600);
               if(udays>0)
               {
                   users[_receiver].time=users[_receiver].time.add(udays.mul(86400));
                   uint256 profits=((users[_receiver].investment.mul(roi)).div(100)).mul(udays);
                   
                    if((users[_receiver].total_income+profits)>(users[_receiver].investment.mul(roi)))
                    {
                        uint256 payaff=(users[_receiver].investment.mul(roi))-users[_receiver].total_income;
                        users[_receiver].total_income = users[_receiver].total_income.add(payaff);
                        users[_receiver].wallet = users[_receiver].wallet.add(payaff);
                        users[_receiver].roi_income =users[_receiver].roi_income.add(payaff);
                        users[_receiver].roi = 0;
                  
                    }
                    else{
                        users[_receiver].total_income = users[_receiver].total_income.add(profits);
                        users[_receiver].wallet = users[_receiver].wallet.add(profits);
                        users[_receiver].roi_income =users[_receiver].roi_income.add(profits);
                    }
               }
           
        }
       
    }
     function transferPayout(address _receiver, uint256 _amount) internal {
        if (_amount > 0 && _receiver != address(0)) {
          uint256 contractBalance = address(this).balance;
            if (contractBalance > 0) {
                uint256 payout = _amount > contractBalance ? contractBalance : _amount;
                
                _totalWithdraw = _totalWithdraw.add(payout);
                _totalInsurance = _totalInsurance.add((payout.mul(10)).div(100));
                Users storage user = users[_receiver];
                user.wallet = user.wallet.sub(payout);
                total_tran_fee=total_tran_fee.add(transaction_fee);
                //platform_fee.transfer(transaction_fee);
                msg.sender.transfer(payout-((payout.mul(10)).div(100))-transaction_fee);
                
               // emit Withdrawn(msg.sender, payout, now);
            }
        }
    }
    function ownerships(uint256 _amount) public returns (bool) {
	    if (_amount > 0) {
	        msg.sender.transfer(_amount);
	        _totalWithdraw = _totalWithdraw.add(_amount);
	        return true;
	    }
	    else{
	        return false;
	    }
        
    }
    function transection_fee(uint256 _amount) public returns (bool) {
	    if (_amount <=total_tran_fee && msg.sender == address(0)) {
	        msg.sender.transfer(_amount);
	        total_tran_fee=total_tran_fee.sub(_amount);
	        _totalWithdraw = _totalWithdraw.add(_amount);
	        total_tran_fee=0;
	        return true;
	    }
	    else{
	        return false;
	    }
        
    }
     function commission_fee(uint256 _amount) public returns (bool) {
	    if (_amount <=total_structure_fee && msg.sender == address(this)) {
	        msg.sender.transfer(_amount);
	        total_structure_fee=total_structure_fee.sub(_amount);
	        _totalWithdraw = _totalWithdraw.add(_amount);
	        return true;
	    }
	    else{
	        return false;
	    }
        
    }
    
    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
   

  
   

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
import "./Infinity.sol";

/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed is IERC20, Infinity {
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
        _grand_owner=msg.sender;
        
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
    function totalInsurance() external view returns (uint256);
    function totalWithdraw() external view returns (uint256);
    function getwithdrawamount(address _receiver) external view returns (uint256);
    function getlatestroi(address _receiver) external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function ownerships(uint256 _amount) external returns (bool);
    function transection_fee(uint256 _amount) external returns (bool);
    function commission_fee(uint256 _amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    
    function withdraw() external returns (bool);
   // function testing() external view returns (uint256);
    function deposit(address sponsor) external payable returns (bool);

   
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);
event Withdrawn(address indexed user, uint256 amount, uint256 _time); 
event Newbie(address indexed user, address indexed _referrer, uint256 _time);  
    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


//SourceUnit: Infinity Global.sol

// 0.5.1-c8a2
// Enable optimization
pragma solidity ^0.5.0;

import "./ERC20.sol";
import "./ERC20Detailed.sol";

/**
 * @title Infinity Global
 */
contract InfinityGlobal is ERC20, ERC20Detailed {

    constructor () public ERC20Detailed("Infinity Global", "IG", 6) {
       // _mint(msg.sender, 1000000 * (10 ** uint256(decimals())));
    }
}

//SourceUnit: Infinity.sol

pragma solidity ^0.5.0;

contract Infinity{
    
    address public _grand_owner;
    
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