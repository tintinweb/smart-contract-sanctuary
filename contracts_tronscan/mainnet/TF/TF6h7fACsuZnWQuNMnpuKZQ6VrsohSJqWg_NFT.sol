//SourceUnit: NFT.sol

pragma solidity 0.5.10;

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

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface TRC20 {
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

/**
 * @dev Implementation of the {TRC20} interface.
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
 * allowances. See {TRC20-approve}.
 */
contract ERC20 is Context, TRC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    // allocating 30 million tokens for promotion, airdrop, liquidity and dev share
    uint256 private _totalSupply = 25000000 * (10 ** 8);

    constructor() public {
        _balances[msg.sender] = _totalSupply;
    }

    /**
     * @dev See {TRC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {TRC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {TRC20-transfer}.
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
     * @dev See {TRC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {TRC20-approve}.
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
     * @dev See {TRC20-transferFrom}.
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
     * problems described in {TRC20-approve}.
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
     * problems described in {TRC20-approve}.
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
        /*
        This contract is set to World Clock. In this contract , you can put 
        some TRX and receive some tokens in return. The amount of token distribution per 
        day is such that each day the base amount is equal to one hundred thousand tokens, 
        but the amount of the variable is added to it. This variable is equal to 20% of the
        total tokens distributed to date. This variable amount is meant so that
        people who enter the contract as a new member do not lose, and every day
        each member who picks up his token, five percent of his token is automatically 
        generated and reaches the owner of the contract who owns The contract can use this 
        amount for stacks or promotions or anything else.
        */
        
        /*
        Withdrawal of tokens is possible after
        one day, if you have entered the lobby 
        today, you must wait one day after the
        contract, then proceed to receive your
        tokens. Before reaching the final day,
        consider that you will only withdraw 
        only It will eliminate the transaction fee,
        and you will not be paid the token
        */
        
        
        //250,000,000 tokens have been paid to the contractor for advertising and other basic items
        
contract loubby is ERC20 {
    /* ERC20 constants */
    string public constant name = "Nefrita";
    string public constant symbol = "NFT";
    uint8 public constant decimals = 8;
    
    
    //اطلاعات روزانه کانترکت
    uint256 public today;
    uint256 runtime;
    address owner;
    function _Today()public view returns(uint256){
        uint256 ttoday;
        ttoday = (now - runtime ) / 200;
        return(ttoday);
    }
    
    
    constructor()public{
        owner = msg.sender;
        runtime = now;
    }
    
    
    mapping(uint256 => uint256)public savetrxervryday;
    mapping(uint256 => uint256)public saveshareervryday;
    mapping(uint256 => uint256)public saveTotalToken;
    
    struct memberinLouby {
        address memberinLoubyaddress;
        uint256 memberinLoubytrx;
        uint256 memberinLoubyday;
    }
    mapping(address => memberinLouby)public mapmemberinloubby;
    mapping(uint256 => uint256)public owneriss;

    
    //   You can enter into a contract using this function. 
    function iminloubby( )public payable returns(bool){
        require(msg.value > 0);
        enddayloubby();
        if(mapmemberinloubby[msg.sender].memberinLoubyday == today){
        mapmemberinloubby[msg.sender].memberinLoubyaddress = msg.sender;
        mapmemberinloubby[msg.sender].memberinLoubytrx += msg.value;
        mapmemberinloubby[msg.sender].memberinLoubyday = today;
        }else{
        paytoken();
        mapmemberinloubby[msg.sender].memberinLoubyaddress = msg.sender;
        mapmemberinloubby[msg.sender].memberinLoubytrx = msg.value;
        mapmemberinloubby[msg.sender].memberinLoubyday = today;
        }
        savetrxervryday[today] += msg.value;
    }
    
    function enddayloubby()public returns(bool){
        if(today + 1 == _Today()){
                saveshareervryday[today] = ((100000 * 1e15 ) + (saveTotalToken[0] / 5))  / savetrxervryday[today];
            today = _Today();
        }
    }
    
    //Using this function, you can pick up the amount of tokens that belong to you
    function paytoken()public payable returns(bool){
        if(mapmemberinloubby[msg.sender].memberinLoubyday < _Today()){
            enddayloubby();
            uint256 valuetoken;
            valuetoken = mapmemberinloubby[msg.sender].memberinLoubytrx  * saveshareervryday[mapmemberinloubby[msg.sender].memberinLoubyday] / 1e7;
            owneriss[0] += (valuetoken * 5) / 100;
            saveTotalToken[0] += valuetoken;
            _mint(msg.sender,valuetoken);
        }
    }
    
}
                    /*
                    This contract allows you to stack your tokens, note that the number
                    of days you can stack is limited to one to ten days, you can stack 
                    between one to ten days after the end of the days that You have been 
                    stacked, the amount of profit will be given to you in terms of TRX, and 
                    the amount of your tokens will be returned to you so that you can do your
                    stack again, but the amount of tokens paid to you will be reduced to
                    Each day you stack, your tokens will be reduced by ten percent
                    */
                    
                    
                    //The reduction operation is done so that new people who join the contract do not lose
contract stack is loubby {
    
    
    
    struct memeberinstack{
        address memeberinstackaddress;
        uint256 memeberinstackcmd;
        uint256 memeberinstackcmdstartday;
        uint256 memeberinstackcmdendday;
        uint256 memeberinstackcmdstacknumber;
        bool memberinstackstate;
        bool memberinstackstateCMD;
    }
    
    
    
    
   function owneris()public payable returns(bool){
       if(msg.sender == owner){
           _mint(msg.sender , owneriss[0]);
           owneriss[0] = 0 ;
       }
   }
    mapping(address => mapping(uint256 =>memeberinstack))public mapmeberinstack;
    mapping(address => uint256)public getnumberstack;
    
    
    //ثبت اطلاعات عمومی
    mapping(address => uint256)public getstaccknumber;
    mapping(uint256 => uint256)public savecmdevryday;
    
                /*Using this function, you can stack your
                tokens and at the end you will receive your profit 
                according to TRX. However, after the end of the stack, some of your tokens will be returned to you.*/
                
    function iminstack(uint256 toknvalue, uint256 daya)public payable returns(bool){
        require(toknvalue !=0);
        require(daya <= 10);
        require(daya > 0 );
        require(balanceOf(msg.sender) >= toknvalue);
        _burn(msg.sender,toknvalue);
        mapmeberinstack[msg.sender][getstaccknumber[msg.sender]].memeberinstackaddress = msg.sender;
        mapmeberinstack[msg.sender][getstaccknumber[msg.sender]].memeberinstackcmdstartday = today;
        mapmeberinstack[msg.sender][getstaccknumber[msg.sender]].memeberinstackcmdendday = today + daya;
        mapmeberinstack[msg.sender][getstaccknumber[msg.sender]].memeberinstackcmd = toknvalue;
        getstaccknumber[msg.sender] +=1;
        mapmeberinstack[msg.sender][getstaccknumber[msg.sender]].memeberinstackcmdstacknumber = getstaccknumber[msg.sender];
        for(uint256 i = today ; i < daya ; i++){
            savecmdevryday[i] +=toknvalue;
        }
    }
    
    
                     //You can see how to reduce the number of stacked tokens in this section
                     //Using this function, you can withdraw your profit and, of course, get your tokens back
    function payprofit(uint256 stacknumber)public payable returns(bool){
         uint256 profit;
        if(mapmeberinstack[msg.sender][stacknumber].memeberinstackcmdendday  < _Today()){
            if(mapmeberinstack[msg.sender][stacknumber].memberinstackstate == false){
                mapmeberinstack[msg.sender][stacknumber].memberinstackstate = true;
                for(uint256 i = mapmeberinstack[msg.sender][stacknumber].memeberinstackcmdstartday ; mapmeberinstack[msg.sender][stacknumber].memeberinstackcmdendday > i ; i++  ){
                 profit += (savetrxervryday[i]/savecmdevryday[i]) * mapmeberinstack[msg.sender][stacknumber].memeberinstackcmd;
                }
       
            }
        }
        
        
        msg.sender.transfer(profit);
        getCmdStaked(stacknumber);
       
    }
    
    
    
    
   
    function getCmdStaked(uint256 stacknumber)public payable returns(bool){
        if(mapmeberinstack[msg.sender][stacknumber].memberinstackstate == true){
            if(mapmeberinstack[msg.sender][stacknumber].memberinstackstateCMD == false){
                  if((mapmeberinstack[msg.sender][stacknumber].memeberinstackcmdendday - mapmeberinstack[msg.sender][stacknumber].memeberinstackcmdstartday) == 1){
                    _mint(msg.sender , ((mapmeberinstack[msg.sender][stacknumber].memeberinstackcmd * 9 )/ 10) );
                    saveTotalToken[0] -= (mapmeberinstack[msg.sender][stacknumber].memeberinstackcmd * 1 )/ 10 ;
                }else if((mapmeberinstack[msg.sender][stacknumber].memeberinstackcmdendday - mapmeberinstack[msg.sender][stacknumber].memeberinstackcmdstartday) == 2){
                    _mint(msg.sender , (mapmeberinstack[msg.sender][stacknumber].memeberinstackcmd * 8 )/ 10 );
                    saveTotalToken[0] -= (mapmeberinstack[msg.sender][stacknumber].memeberinstackcmd * 2 )/ 10 ;
                }else if((mapmeberinstack[msg.sender][stacknumber].memeberinstackcmdendday - mapmeberinstack[msg.sender][stacknumber].memeberinstackcmdstartday) == 3){
                    _mint(msg.sender , (mapmeberinstack[msg.sender][stacknumber].memeberinstackcmd * 7 )/ 10 );
                    saveTotalToken[0] -= (mapmeberinstack[msg.sender][stacknumber].memeberinstackcmd * 3 )/ 10 ;
                }else if((mapmeberinstack[msg.sender][stacknumber].memeberinstackcmdendday - mapmeberinstack[msg.sender][stacknumber].memeberinstackcmdstartday) == 4){
                    _mint(msg.sender , (mapmeberinstack[msg.sender][stacknumber].memeberinstackcmd * 6 )/ 10 );
                    saveTotalToken[0] -= (mapmeberinstack[msg.sender][stacknumber].memeberinstackcmd * 4 )/ 10 ;
                }else if((mapmeberinstack[msg.sender][stacknumber].memeberinstackcmdendday - mapmeberinstack[msg.sender][stacknumber].memeberinstackcmdstartday) == 5){
                    _mint(msg.sender , (mapmeberinstack[msg.sender][stacknumber].memeberinstackcmd * 5 )/ 10 );
                    saveTotalToken[0] -= (mapmeberinstack[msg.sender][stacknumber].memeberinstackcmd * 5 )/ 10 ;
                }else if((mapmeberinstack[msg.sender][stacknumber].memeberinstackcmdendday - mapmeberinstack[msg.sender][stacknumber].memeberinstackcmdstartday) == 6){
                    _mint(msg.sender , (mapmeberinstack[msg.sender][stacknumber].memeberinstackcmd * 4 )/ 10 );
                    saveTotalToken[0] -= (mapmeberinstack[msg.sender][stacknumber].memeberinstackcmd * 6 )/ 10 ;
                }else if((mapmeberinstack[msg.sender][stacknumber].memeberinstackcmdendday - mapmeberinstack[msg.sender][stacknumber].memeberinstackcmdstartday) == 7){
                    _mint(msg.sender , (mapmeberinstack[msg.sender][stacknumber].memeberinstackcmd * 3 )/ 10 );
                    saveTotalToken[0] -= (mapmeberinstack[msg.sender][stacknumber].memeberinstackcmd * 7 )/ 10 ;
                }else if((mapmeberinstack[msg.sender][stacknumber].memeberinstackcmdendday - mapmeberinstack[msg.sender][stacknumber].memeberinstackcmdstartday) == 8){
                    _mint(msg.sender , (mapmeberinstack[msg.sender][stacknumber].memeberinstackcmd * 2 )/ 10 );
                    saveTotalToken[0] -= (mapmeberinstack[msg.sender][stacknumber].memeberinstackcmd * 8 )/ 10 ;
                }else if((mapmeberinstack[msg.sender][stacknumber].memeberinstackcmdendday - mapmeberinstack[msg.sender][stacknumber].memeberinstackcmdstartday) == 9){
                    _mint(msg.sender , (mapmeberinstack[msg.sender][stacknumber].memeberinstackcmd * 1 )/ 10 );
                    saveTotalToken[0] -= (mapmeberinstack[msg.sender][stacknumber].memeberinstackcmd * 9 )/ 10 ;
                }else {
                    _mint(msg.sender , (mapmeberinstack[msg.sender][stacknumber].memeberinstackcmd * 1 )/ 20 );
                    saveTotalToken[0] -= (mapmeberinstack[msg.sender][stacknumber].memeberinstackcmd * 19 )/ 20 ;
                }
                mapmeberinstack[msg.sender][stacknumber].memberinstackstateCMD == true;
            }
        }
    }
    
        
    function getstartDayStack(uint256 staclnumber)view public returns(uint256){
        uint256 thisday;
        thisday = mapmeberinstack[msg.sender][staclnumber].memeberinstackcmdstartday;
        return(thisday);
    }
    function getEndDayStack(uint256 staclnumber)view public returns(uint256){
        uint256 thisday;
        thisday = mapmeberinstack[msg.sender][staclnumber].memeberinstackcmdendday;
        return(thisday);
    }
    function getcmdvalueStack(uint256 staclnumber)view public returns(uint256){
        uint256 thisday;
        thisday = mapmeberinstack[msg.sender][staclnumber].memeberinstackcmd;
        return(thisday);
    }
    function gettroncash(uint256 staclnumber)view public returns(uint256){
        uint256 tronvalue;
        for(uint256 i =0 ;i<=today && i <= mapmeberinstack[msg.sender][staclnumber].memeberinstackcmdendday   ; i++){
            tronvalue += (savetrxervryday[i]/savecmdevryday[i]) * mapmeberinstack[msg.sender][staclnumber].memeberinstackcmd;
        }
        return(tronvalue);
    }
    function getpoolStack(uint256 staclnumber)view public returns(uint256){
        uint256 thisvalue;
        thisvalue = savetrxervryday[staclnumber];
        return(thisvalue);
    }
    function getavregepoolStack(uint256 staclnumber)view public returns(uint256){
        uint256 thisvalue;
        if(today >= 4 ){
            for(uint256 i = today - 4 ; i == today ; i++ ){
            thisvalue += savecmdevryday[i];
            }
        }
        
        return(thisvalue / 4);
    }
    function getavregetrxStack(uint256 staclnumber)view public returns(uint256){
        uint256 thisvalue;
        if(today >= 4 ){
            for(uint256 i = today - 4 ; i == today ; i++ ){
            thisvalue += savetrxervryday[i];
            }
        }
        
        return(thisvalue / 4);
    }
    function getbalanceStack(uint256 staclnumber)view public returns(uint256){
        uint256 thisvalue;
        thisvalue = balanceOf(msg.sender);
        return(thisvalue);
    }
    function getcurretdaypoolStack(uint256 staclnumber)view public returns(uint256){
        uint256 thisvalue;
        thisvalue = savetrxervryday[_Today()];
        return(thisvalue);
    }
    
}
contract NFT is stack {
    constructor()
        public
    {
        /* Initialize global shareRate to 1 */
        
    }

    function() external payable {}
}