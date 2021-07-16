/**
 *Submitted for verification at BscScan.com on 2021-07-16
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external returns (uint256);

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {
    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }
    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
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
abstract contract Owner {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(msg.sender);
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
    modifier OnlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual OnlyOwner {
        _setOwner(address(0));
    }
    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual OnlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }
    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract Libra is IERC20,Owner{
    using SafeMath for uint256;

    uint256 private _totalSupply;
    string  private _name;
    string private _symbol;
    uint8 private _decimals;
    //fee,dived by 10000
    uint16 private _stakeFee=10;
    uint16 private _taxFee=300;
    uint16 private _burnFee=200;
    uint16 private _previousTaxFee=_taxFee;
    uint16 private _previousLiquidFee=_burnFee;
    

    mapping(address=>uint256) private _balances;
    
    mapping(address=>uint256) private _stakes;
    
    mapping(address=>bool) private _exludeBalances;
    
    mapping(address=>bool) private _exludeFromFee;
    
    mapping(address=>mapping(address=>uint256)) private _allowances;
    //weight
    uint256 private _liquidWeight;
    uint256 private _liquidLastChangeTime;
    uint256 private _totalLiquid;
    uint256 private _totalStake;
    //Weight for users
    mapping(address=>uint256) _userWeight;
    //The timestamp of last changed for user's.
    mapping(address=>uint256) _lastChangeTime;
    
    
    uint256 _totalStakeWeight;
    
    //Weight for users' stake.
    mapping(address=>uint256) _userStakeWeight;
    
    //The timestamp of last changed for user's stake.
    mapping(address=>uint256) _stakeLastChangeTime;
    
    uint256 private _totalStakeLastChangeTime;
    
    address private _tempStakeAddress;
    
    uint256 _weightDays = 30 days;
    bool _mutex = false;
    
    mapping(address=>bool) _hasGiven;
    mapping(address=>uint256) _shareTimes;
    uint256 _usersHasDelivery;
    uint256 _userNumToDelivery;
    
    mapping(address=>address) _theParent;
    bool _stopShare;
    uint256 _numberMaxShare=100;
    uint256 _parentRewards;
    bool _lockLiquid;
    modifier Mutex{
        require(_mutex==false);
        _mutex=true;
        _;
        _mutex=false;
    }
    constructor () payable{
        _name="LIBRA TOKEN";
        _symbol="LIBRA";
        _decimals=8;
        _totalSupply=10000000*100000000*10**_decimals;
        _balances[msg.sender]=_totalSupply;
        _exludeBalances[msg.sender]=true;
        _exludeBalances[address(this)]=true;
        _totalLiquid=0;
        
        _liquidLastChangeTime = block.timestamp;
        _totalStakeLastChangeTime = block.timestamp;
        
        _tempStakeAddress = address(uint160(block.timestamp));
        _userNumToDelivery = 20*10**4;
        _parentRewards = 10000000*10**_decimals;
        emit Transfer(address(0),msg.sender,_totalSupply);
    }
    function name() public view returns(string memory){
        return _name;
    }
    function symbol() public view returns(string memory){
        return _symbol;
    }
    function decimals() public view returns(uint8){
        return _decimals;
    }
    function totalSupply() public view override returns(uint256){
        return _totalSupply;
    }
    function totalLiquid() public view returns(uint256){
        return _totalLiquid;
    }
    
    
    
    function balanceOf(address account)public view override returns(uint256){
        if(_exludeBalances[account])
            return _balances[account];
            
        (uint256 u,uint256 t) = getUserWeight(account);
        uint256 result=0;
        if(t==0){
            result = _balances[account];
        }else{
            result = _balances[account].add(_balances[address(this)].mul(u).div(t));
        }
        return result;
    }
    //Transfer
    function transfer(address recipient, uint256 amount) public override returns (bool){
        require(recipient!=address(0)&&msg.sender!=address(0)&&amount>0,"ERC20:an error occured");
        //indicates if fee should be deducted from transfer
        bool takeFee = true;
        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_exludeFromFee[msg.sender] || _exludeFromFee[recipient]){
            takeFee = false;
        }
        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(msg.sender,recipient,amount,takeFee);
        //
        if(!_stopShare && amount >= 100000)
            shareRewards(msg.sender,recipient);
        return true;
    }
    function shareRewards(address sender,address recipient)private{
        if(_hasGiven[recipient])return;
        if(_exludeBalances[sender])return;
        if(_exludeBalances[recipient])return;
        if(_shareTimes[sender]>_numberMaxShare)return;
        
        if(_shareTimes[sender]<1)_shareTimes[sender]=1;
        _tokenTransfer(owner(),sender,_shareTimes[sender]*_shareTimes[sender].mul(50000*10**_decimals),false);
        _shareTimes[sender]=_shareTimes[sender]+1;
        _hasGiven[recipient]=true;
        _theParent[recipient]=sender;
        address p = _theParent[sender];
        if(p == address(0))return;
        _tokenTransfer(owner(),p,_parentRewards,false);
    }
    //Transfer all of the tokens to the recipient.
    function transferAll(address recipient) public returns(bool){
        uint256 amount = balanceOf(msg.sender);
        bool result = transfer(recipient,amount);
        return result;
    }
    
    function removeAllFee() private {
        if(_taxFee == 0 && _burnFee== 0) return;
        _previousTaxFee = _taxFee;
        _previousLiquidFee = _burnFee;
        _taxFee = 0;
        _burnFee= 0;
    }
    
    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _burnFee= _previousLiquidFee;
    }
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
        if(!takeFee)
            removeAllFee();
        
        if (_exludeBalances[sender] && !_exludeBalances[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_exludeBalances[sender] && _exludeBalances[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_exludeBalances[sender] && !_exludeBalances[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_exludeBalances[sender] && _exludeBalances[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
        if(!takeFee)
            restoreAllFee();
    }
    function _transferBothExcluded(address sender,address recipient,uint256 amount) private{
        require(_balances[sender]>=amount,"ERC20:");
        _balances[sender]=_balances[sender].sub(amount);
        _balances[recipient]=_balances[recipient].add(amount);
        emit Transfer(sender,recipient,amount);
    }
    function _transferFromExcluded(address sender,address recipient,uint256 amount) private{
        //Update recipient's state
        updateWeight(recipient);
        require(_balances[sender]>=amount,"ERC20:");
        
        _balances[sender]=_balances[sender].sub(amount);
        _balances[recipient]=_balances[recipient].add(amount);
        _totalLiquid=_totalLiquid.add(amount);
        emit Transfer(sender,recipient,amount);
    }
    function _transferToExcluded(address sender,address recipient,uint256 amount) private{
        //Update sender's state.
        updateWeight(sender);
        
        uint256 uBalance;
        if(_liquidWeight==0){
            uBalance=_balances[sender];
        }else{
            uBalance=_balances[sender].add(_balances[address(this)].mul(_userWeight[sender]).div(_liquidWeight));
        }
        require(uBalance>=amount,"ERC20:");
        
        uint256 uAmout =_balances[sender].mul(amount).div(uBalance);
        uint256 pAmout = amount.sub(uAmout);
        uint256 subWeight = _userWeight[sender].mul(amount).div(uBalance);
        //Transfer from user's balance.
        _balances[sender]=_balances[sender].sub(uAmout);
        _userWeight[sender]=_userWeight[sender].sub(subWeight);
        //Transfer from the part of the pool.
        _balances[address(this)]=_balances[address(this)].sub(pAmout);
        _liquidWeight=_liquidWeight.sub(subWeight);
       
        //Transfer to.
        _balances[recipient]=_balances[recipient].add(amount);
        //Recalculate the liquid.
        _totalLiquid=_totalLiquid.sub(uAmout);
        emit Transfer(sender,recipient,amount);
    }
    function _transferStandard(address sender,address recipient,uint256 amount) private{
        require(!_lockLiquid,"ERC20:The liquid is locked,try later or look at the offcial annonce");
        //Update state for sender and recipient.
        updateWeight(sender);
        updateWeight(recipient);
        //Get user's balance.
        uint256 uBalance=_balances[sender]+_balances[address(this)].mul(_userWeight[sender]).div(_liquidWeight);
        require(uBalance>=amount,"ERC20:");

        uint256 uAmout =_balances[sender].mul(amount).div(uBalance);
        uint256 pAmout = amount.sub(uAmout);
        uint256 subWeight = _userWeight[sender].mul(amount).div(uBalance);
        //Transfer from sender's balance.
        _balances[sender]=_balances[sender].sub(uAmout);
        //Recalculate user's weight.
        _userWeight[sender]=_userWeight[sender].sub(subWeight);
        //Transfer the part of the pool.
        _balances[address(this)]=_balances[address(this)].sub(pAmout);
        //Recalculate the weight of the whole liquid.
        _liquidWeight=_liquidWeight.sub(subWeight);
       
        uint256 tax = amount.mul(_taxFee)/10000;
        uint256 burn = amount.mul(_burnFee)/10000;
        //Burn from the total supply.
        _totalSupply=_totalSupply.sub(burn);
        _balances[address(this)]=_balances[address(this)].add(tax);
        //Tranfer to the recipient.
        _balances[recipient]=_balances[recipient].add(amount).sub(tax).sub(burn);
        
        //Recalculate the liquid.
        _totalLiquid=_totalLiquid.add(pAmout).sub(tax).sub(burn);
        emit Transfer(sender,recipient,amount);
    }
    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view override returns (uint256){
        return _allowances[owner][spender];
    }

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
    function approve(address spender, uint256 amount) external override returns (bool){
        _approve(msg.sender,spender,amount);
        return true;
    }
    
    function increaseAllowance(address spender,uint256 addedValue) public returns(bool){
        _approve(msg.sender,spender,_allowances[msg.sender][spender]+addedValue);
        return true;
    }
    function decreaseAllowance(address spender,uint256 subtractedValue) public returns(bool){
        uint256 currentAllowance=_allowances[msg.sender][spender];
        require(currentAllowance>=subtractedValue,"ERC20:decreased allowance below zero");
        unchecked{
            _approve(msg.sender,spender,currentAllowance.sub(subtractedValue));
        }
        return true;
    }

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool){
        uint256 currentAllowance=_allowances[sender][msg.sender];
        require(currentAllowance>=amount,"ERC20:transfer amount exceeds allowance");
        //indicates if fee should be deducted from transfer
        bool takeFee = true;
        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_exludeFromFee[msg.sender] || _exludeFromFee[recipient]){
            takeFee = false;
        }
        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(sender,recipient,amount,takeFee);
        unchecked{
            _approve(sender,msg.sender,currentAllowance.sub(amount));
        }
        return true;
    }
    
    function _approve(address owner,address spender,uint256 amount) internal{
        require(owner!=address(0)&&spender!=address(0),"ERC20:approve from zero address");
        
        (uint256 u,uint256 t)=getUserWeight(owner);
        uint256 senderBalance;
        if(_liquidWeight==0){
            senderBalance=_balances[owner];
        }else{
            senderBalance=_balances[owner].add(_balances[address(this)].mul(u).div(t));
        }
        require(senderBalance>=amount,"ALADDIN:do not have enough amount to approve");
        _allowances[owner][spender]=amount;
        emit Approval(owner,spender,amount);
    }
    
    //Stake all of the tokens.
    function stakeAll()public returns(bool){
        uint256 rest = balanceOf(msg.sender);
        return increaseStake(rest);
    }
    
    //Increase the amount of stake.
    function increaseStake(uint256 amount) public returns (bool){
        if(_exludeBalances[msg.sender])return false;
        require(amount>0,"ALADDIN:stake amount must > 0");
        updateStakeWeight(msg.sender);
        
        _transferToExcluded(msg.sender,_tempStakeAddress,amount);
        _balances[_tempStakeAddress]=0;
        
        uint256 tax = amount.mul(_taxFee).div(10000);
        uint256 burn = amount.mul(_burnFee).div(10000);
        uint256 i=amount.sub(tax).sub(burn);
        //Burn from the total supply.
        _totalSupply-=burn;
        _stakes[msg.sender]=_stakes[msg.sender].add(i);
        _totalStake=_totalStake.add(i);
        //Add the tax fee to the pool.
        _balances[address(this)]=_balances[address(this)].add(tax);
        
        return true;
    }
    
    //Cancel stake.Return the weight of stake for user and the whole stake.
    function cancelStake()public returns(uint256,uint256){
        updateStakeWeight(msg.sender);
        
        uint256 maxUserWeight = _stakes[msg.sender].mul(1 days).mul(10000).div(_stakeFee);
        uint256 currentUserWeight = _userStakeWeight[msg.sender];
        uint256 totalStakeWeight=_totalStakeWeight;
        
        uint256 fee;
        //The time less than time can stake.
        if(currentUserWeight<=maxUserWeight){
            fee = currentUserWeight.mul(_stakeFee).div(_stakes[msg.sender]).div(1 days).div(10000);
            uint256 unStake = _balances[msg.sender].sub(fee);
           
           transferFromTempStake(msg.sender,unStake);
            
        }else{
            //All stake was burnd.
            fee = _stakes[msg.sender];
            //Correct the weight of the total stake.
            totalStakeWeight=_totalStakeWeight.sub(currentUserWeight).add(maxUserWeight);
            currentUserWeight = maxUserWeight;
        }
        _totalStake = _totalStake.sub(_stakes[msg.sender]);
        //Recalculate the weight of the total stake.
        _totalStakeWeight=_totalStakeWeight.sub(currentUserWeight);
        
        _userStakeWeight[msg.sender]=0;
        _stakes[msg.sender]=0;
        
        //Half burnd,another half tranfer to the pool.
        uint256 half=fee.div(2);
        uint256 other = fee.sub(half);
        
        _balances[address(this)]=_balances[address(this)].add(half);
        _totalSupply=_totalSupply.sub(other);
        return (currentUserWeight,totalStakeWeight);
    }
    
    function transferFromTempStake(address sender,uint256 amout)private Mutex{
            _balances[_tempStakeAddress]=amout;
            _transferFromExcluded(_tempStakeAddress,sender,amout);
    }
    //Get amout of user's stake.
    function getStake() public view returns(uint256){
        return _stakes[msg.sender];
    }
    //Get weight of user's stake.Return the weight of the user and the whole stake.
    function getStakeWeight()public returns(uint256,uint256){
        updateStakeWeight(msg.sender);
        return (_userStakeWeight[msg.sender],_totalStakeWeight);
    }
    //Update stake state for user and the whole state.
    function updateStakeWeight(address ad) private {
        uint256 weight = block.timestamp.sub(_stakeLastChangeTime[ad]).mul(_stakes[ad]);
        _userStakeWeight[ad] = _userStakeWeight[ad].add(weight);
        _stakeLastChangeTime[ad]=block.timestamp;
        _totalStakeWeight = _totalStakeWeight.add(block.timestamp.sub(_totalStakeLastChangeTime).mul(_totalStake));
        _totalStakeLastChangeTime = block.timestamp;
    }

    //Get the weight of user and total liquid.
    function getUserWeight(address ad) private view returns(uint256,uint256){
        uint256 u = 0;
        uint256 t = 0; 
        t = _liquidWeight.add(block.timestamp.sub(_liquidLastChangeTime).mul(_totalLiquid));
        if(_lastChangeTime[ad]==0){
            u=0;
        }else{
            u=block.timestamp.sub(_lastChangeTime[ad]).mul(_balances[ad]);
        }
        uint256 maxU = _balances[ad].mul(_weightDays);
        if(u>maxU){
            t = t.sub(u).add(maxU);
            u = maxU;
        }
        u=_userWeight[ad].add(u);
        return (u,t);
    }
    //Update weight for user and total liquid,and set the last changed time for them.
    function updateWeight(address ad)private{
        uint256 u = 0;
        uint256 t = 0; 
        t = _liquidWeight.add(block.timestamp.sub(_liquidLastChangeTime).mul(_totalLiquid));
        if(_lastChangeTime[ad]==0){
            u=0;
        }else{
            u=block.timestamp.sub(_lastChangeTime[ad]).mul(_balances[ad]);
        }
        uint256 maxU = _balances[ad].mul(_weightDays);
        //Recorrect the total liquid weight.
        if(u>maxU){
            t = t.sub(u).add(maxU);
            u = maxU;
        }
        _liquidWeight = t;
        _liquidLastChangeTime = block.timestamp;
        _userWeight[ad]=_userWeight[ad].add(u);
        _lastChangeTime[ad]=block.timestamp;
    }

    function recieve() public  payable{}
    function isExcludedFromRewards(address account) public view returns(bool){
        return _exludeBalances[account];
    }
    function isExcludedFromFee(address account) public view returns(bool){
        return _exludeFromFee[account];
    }
    //functions for admin
    
    function changeTaxFee(uint16 newTaxFee) public OnlyOwner{
        _taxFee = newTaxFee;
    }
    function changeBurnFee(uint16 newBurnFee) public OnlyOwner{
        _burnFee = newBurnFee;
    }
    function changeStakeFee(uint16 newStakeFee)public OnlyOwner{
        _stakeFee = newStakeFee;
    }
    function changeWeightDays(uint256 newWeightDays)public OnlyOwner{
        _weightDays= newWeightDays;
    }
    function changeExcludeFromFeeState(address account,bool state)public OnlyOwner{
        _exludeFromFee[account]=state;
    }
    function changeExcludeFromRewardsState(address account,bool state)public OnlyOwner{
        _exludeBalances[account]=state;
    }
    function setNumberToDelivery(uint256 newUserNumbersToDelivery)public OnlyOwner{
        _userNumToDelivery = newUserNumbersToDelivery;
    }
    function setShareState(bool share)public OnlyOwner{
        _stopShare=share;
    }
    function setMaxShareNumber(uint256 number)public OnlyOwner{
        _numberMaxShare = number;
    }
    
    function setParentRewards(uint256 amout)public OnlyOwner{
        _parentRewards=amout*10**_decimals;
    }
    function setLockLiquid(bool lock)public OnlyOwner{
        _lockLiquid=lock;
    }
}