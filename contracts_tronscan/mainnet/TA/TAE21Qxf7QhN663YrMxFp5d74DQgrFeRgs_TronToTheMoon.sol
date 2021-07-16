//SourceUnit: ITRC20.sol

pragma solidity 0.5.4;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface ITRC20 {
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

pragma solidity 0.5.4;
library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
     
    function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
        uint256 c = add(a,m);
        uint256 d = sub(c,1);
        return mul(div(d,m),m);
    }
    
}

//SourceUnit: TRC20.sol

pragma solidity 0.5.4;

import "./ITRC20.sol";
import "./SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to_mint be added in a derived contract using {_mint}.
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
contract TRC20 is ITRC20 {
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

//SourceUnit: TRC20Detailed.sol

pragma solidity 0.5.4;

import "./ITRC20.sol";

/**
 * @dev Optional functions from the ERC20 standard.
 */
contract TRC20Detailed is ITRC20 {
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



//SourceUnit: token.sol

// 0.5.1-c8a2
// Enable optimization
pragma solidity 0.5.4;

import "./TRC20.sol";
import "./TRC20Detailed.sol";
contract Token is TRC20, TRC20Detailed {

    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    constructor () public TRC20Detailed("Tron To The Moon", "TTTM",6) {
        _mint(msg.sender,(10000000 * (10 ** 6)));
    }
}

//SourceUnit: tronToTheMoon.sol

pragma solidity 0.5.4;
import "./token.sol";
//=====Contract to find division for more accuracy=====//
//========================================================//
contract Divide {

  function percent(uint numerator, uint denominator, uint precision) internal 

  pure returns(uint quotient) {

         // caution, check safe-to-multiply here
        uint _numerator  = numerator * 10 ** (precision+1);
        // with rounding of last digit
        uint _quotient =  ((_numerator / denominator) + 5) / 10;
        return ( _quotient);
  }

}
//=====Contract to find percentages for more accuracy=====//
//========================================================//
contract Percentage is Divide{

    uint256 public baseValue = 100;

    function onePercent(uint256 _value) internal view returns (uint256)  {
        uint256 roundValue = SafeMath.ceil(_value, baseValue);
        uint256 Percent = SafeMath.div(SafeMath.mul(roundValue, baseValue), 10000);
        return  Percent;
    }
}
contract Owned is Percentage{
    modifier onlyOwner() {
        require(msg.sender==owner,"you are not a owner");
        _;
    }
    
    address payable public owner;
    function changeOwner(address payable _newOwner) public onlyOwner {
        require(_newOwner!=address(0));
        owner = _newOwner;
    }
    
}
//=====Main Contract of Tron To The Moon  =====//
//========================================================//
contract TronToTheMoon is Token,Owned{
     constructor()public{
     startTime=now;
     owner=msg.sender;
     addTokenHolder(owner);
    }
    /**
    * @notice A method to check if an address is a stakeholder.
    * @param _address The address to verify.
    * @return bool, uint256 Whether the address is a stakeholder,
    * and if so its position in the tokenHolders array.
    */
   function isTokenHolder(address _address)
       public
       view
       returns(bool, uint256)
   {
       for (uint256 s = 0; s < tokenHolders.length; s += 1){
           if (_address == tokenHolders[s]) return (true, s);
       }
       return (false, 0);
   }

   /**
    * @notice A method to add a stakeholder.
    * @param _stakeholder The stakeholder to add.
    */
   function addTokenHolder(address _stakeholder)
       public
   {
       (bool _isStakeholder, ) = isTokenHolder(_stakeholder);
       if(!_isStakeholder) tokenHolders.push(_stakeholder);
   }

   /**
    * @notice A method to remove a stakeholder.
    * @param _stakeholder The stakeholder to remove.
    */
   function removeTokenHolder(address _stakeholder)
       public
   {
       (bool _isStakeholder, uint256 s) = isTokenHolder(_stakeholder);
       if(_isStakeholder){
           tokenHolders[s] = tokenHolders[tokenHolders.length - 1];
           tokenHolders.pop();
       }
   }
    using SafeMath for uint256;
    struct Users{
        uint256 stakeHolderBonus;
        uint256 refferalBonus;
        uint256 totalWithdrawn;
        uint256 totlarefferalEarned;
        uint256 totalDividendEarned;
        uint256 totalTRXDeposited;
        address upline;
    }
    mapping(address=>Users)public users;
    uint256 public startTime;
    address[] public tokenHolders;
    uint256 public totalTokenMinted=10000000000000;
    uint256 public totalTokenSold;
    using SafeMath for uint256;
    uint256 initialPrice=20000;
    
    event Buy(string nature,address indexed _buyer,uint256 _tokens,uint256 _amounts);
    event Sell(string nature,address indexed _seller,uint256 _tokens,uint256 _amounts);
    event Withdraw(string nature,address indexed _drawer,uint256 _amountWithDrawn);
    
    function buyPriceCalculation() internal view returns(uint){
        require(startTime != 0,"contract isn't deployed yet!");
        uint256 increment= ((now - startTime)/(1 days))*10;
        return increment;
    }
    function TTTMtoTrx()public view returns(uint256){
       if(circulatingSupply()==0){
         return 0;   
        }
        else{
        return SafeMath.div(sellPriceCalculation(),10e6);  
        }  
    }
    function TrxToTTTM()public view returns(uint256){
        return buyPriceCalculation()+initialPrice;
    }
    function buyPrice(uint256 _trxvalue)public view returns(uint256){
       _trxvalue=SafeMath.sub(_trxvalue,onePercent(_trxvalue)*10);
       uint256 price= (buyPriceCalculation()+initialPrice);
       return (_trxvalue/price).mul(1000000);
    }
    function setReferral(address payable _upline,address _add)internal{
        
        require(_upline==owner||0!=balanceOf(_upline) && _upline!=address(0),"Upline doesn't exist!");
        users[_add].upline=_upline;
    }
    function totalTokenBalance()internal view returns(uint256){
        uint256 i;
        uint256 totalbalance;
        for(i=0;i<tokenHolders.length;i++){
           totalbalance+=balanceOf(tokenHolders[i]);
        }
        return totalbalance;
    }
    function tokenHoldeBonus(uint256 _totalBonus,address _tokenHolder)internal view returns(uint256){
        uint256 bonus=percent(balanceOf(_tokenHolder),totalTokenBalance(),8);
        uint256 singleTotalBonus=onePercent(_totalBonus);
        uint256 bonusOfuser=SafeMath.div(SafeMath.mul(bonus,singleTotalBonus),10**6);
        return bonusOfuser;
    }
     //==================Buy token function==========//
   //========================================================//
    function buyToken(uint256 _trxvalue,address payable _refferedBy)public payable returns(bool){
     uint256 i;
     require(msg.value==_trxvalue,"Invalid price");
     require(buyPrice(_trxvalue)>0,"Invalid amount of token selected");
     setReferral(_refferedBy,msg.sender);
      users[_refferedBy].refferalBonus+=SafeMath.mul(onePercent(_trxvalue),2);
      users[_refferedBy].totlarefferalEarned+=SafeMath.mul(onePercent(_trxvalue),2);
      uint256 TotalstakeholderBonus=SafeMath.mul(onePercent(_trxvalue),8);
        for(i=0;i<tokenHolders.length;i++){
            users[tokenHolders[i]].stakeHolderBonus+=tokenHoldeBonus(TotalstakeholderBonus,tokenHolders[i]);
            users[tokenHolders[i]].totalDividendEarned+=tokenHoldeBonus(TotalstakeholderBonus,tokenHolders[i]);
            
        }
    _mint(msg.sender,buyPrice(_trxvalue)); 
     totalTokenMinted+=buyPrice(_trxvalue);
     users[msg.sender].totalTRXDeposited+=_trxvalue;
     addTokenHolder(msg.sender);
     
     emit Buy("Buy",msg.sender,buyPrice(_trxvalue),_trxvalue);
     return true;
    }
    //==================Market price check==========//
   //========================================================//
    function marketCap()public view returns(uint256){
        uint256 i;
        uint256 totalRewards;
        for(i=0;i<tokenHolders.length;i++){
        totalRewards+=SafeMath.add(users[tokenHolders[i]].refferalBonus,users[tokenHolders[i]].stakeHolderBonus);
        }
        return SafeMath.sub(address(this).balance,totalRewards);
    }
    function circulatingSupply()public view returns(uint256){
        return SafeMath.sub(totalTokenMinted-10000000000000,totalTokenSold);
    }
    //==================Sell Price check function==========//
   //========================================================//
      function sellPrice(uint256 _numberOfTokens)public view returns(uint256){
        if(circulatingSupply()==0){
         return 0;   
        }
        else{
        uint256 totalPercent=SafeMath.mul(onePercent(_numberOfTokens),10);
        uint256 totalTokens=SafeMath.sub(_numberOfTokens,totalPercent);
        uint256 price=SafeMath.mul(totalTokens,sellPriceCalculation());
        return SafeMath.div(price,10e12);  
        }
    }
    function totalSellPrice(uint256 _numberOfTokens)internal view returns(uint256){
        if(circulatingSupply()==0){
         return 0;   
        }
        else{
        uint256 price=SafeMath.mul(_numberOfTokens,sellPriceCalculation());
        return SafeMath.div(price,10e12);  
        }
    }
    function sellPriceCalculation()internal view returns(uint256){
        require(circulatingSupply()>0,"No token bought yet");
        uint256 marketCapValue=SafeMath.mul(marketCap(),10e12);
        uint256 price= SafeMath.div(marketCapValue,circulatingSupply());
        return price;
    }
    //=====================Sell Function====================//
   //========================================================//
    function sellToken(uint256 _numberOfTokens)public returns(bool){
        uint256 i;
        require(balanceOf(msg.sender)>=_numberOfTokens,"you dont have enough tokens!");
        uint256 actualValue=sellPrice(_numberOfTokens);
        uint256 price=totalSellPrice(_numberOfTokens);
      users[users[msg.sender].upline].refferalBonus+=SafeMath.mul(onePercent(price),2);
      users[users[msg.sender].upline].totlarefferalEarned+=SafeMath.mul(onePercent(price),2);
      uint256 TotalstakeholderBonus=SafeMath.mul(onePercent(price),8);
        for(i=0;i<tokenHolders.length;i++){
            users[tokenHolders[i]].stakeHolderBonus+=tokenHoldeBonus(TotalstakeholderBonus,tokenHolders[i]);
            users[tokenHolders[i]].totalDividendEarned+=tokenHoldeBonus(TotalstakeholderBonus,tokenHolders[i]);
        }
        _burn(msg.sender,_numberOfTokens);
        msg.sender.transfer(actualValue);
        users[msg.sender].totalWithdrawn+=actualValue;
        totalTokenSold+=_numberOfTokens;
        if(balanceOf(msg.sender)==0){
         removeTokenHolder(msg.sender);
        }
        emit Sell("Sell",msg.sender,_numberOfTokens,actualValue);
        return true;
    }
    //=====Withdraw reward function=====//
   //========================================================//
    function withDraw()public returns(bool){
        require(users[msg.sender].refferalBonus>0||users[msg.sender].stakeHolderBonus>0,"You have no reward");
        uint256 totalRewards=users[msg.sender].refferalBonus.add(users[msg.sender].stakeHolderBonus);
        msg.sender.transfer(totalRewards);
        users[msg.sender].refferalBonus=0;
        users[msg.sender].stakeHolderBonus=0;
        users[msg.sender].totalWithdrawn+=totalRewards;
        emit Withdraw("Withdraw",msg.sender,totalRewards);
        return true;
    }
}