//SourceUnit: YHL0827.sol

pragma solidity ^0.6.12;
// SPDX-License-Identifier: Unlicensed
pragma experimental ABIEncoderV2;

interface ITRC20 {

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
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Owend {
    address public _owner;

    constructor () internal {
        _owner = msg.sender;
    }
   
    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _owner = newOwner;
    }
}


contract YHL is ITRC20, Owend{
  using SafeMath for uint256;
  mapping (address => uint256) public whiteList;
  mapping (address => uint256) public unilateralList;
  
  mapping (address => mapping (address => uint256)) private _allowances;
  mapping (address => uint256) private _balanceOf;
  mapping(address => address) private referrals;
  address[] private referralsKey;
  uint256 public _lastMintPowerTime;

  uint256 public _currentMint;
  uint256 public eachPart;
  uint256 private _mintTotal=1140000*10**8;
  uint256 private _totalSupply=1200000*10**8;
  string private _name ="YHL Token";
  string private _symbol="YHL";
  uint256 private _decimals = 8;
  uint256 private profitFee=5;
  uint256 private burnScale=1;
  uint256 private luidityScale=1;
  uint256 private rewardScale=3;
  address public ownerAddress;
  address public _burnPool = 0x000000000000000000000000000000000000dEaD;
 
  address public luidityAddress=address(0x4188e7d1df0359cbcf41ef933a0aeda5404afa3136);
  address public rewardAddress=address(0x41cf31b4a02ddac9782a803d2d63411a0350f711c1);
  address public miningRevenueAddress=address(0x417d6609fde20e736c471b721320f098010cd1838b);
  address public promotionalAddress=address(0x4121581801632e2a98f5077f8a23f2f163f7b8e9d0);
 
    
    constructor ()public{
        _lastMintPowerTime=block.timestamp;
        ownerAddress=msg.sender;
        whiteList[msg.sender]=1;
        eachPart=_mintTotal.div(6).div(365).div(144);
        _balanceOf[ownerAddress] =60000*10**8; 
        emit Transfer(address(0), ownerAddress,60000*10**8); 
    }
    
    function _transfer(address _from,address _to,uint256 _value) private{
        require(_from != address(0), "TRC20: transfer from the zero address");
        require(_to != address(0), "TRC20: transfer to the zero address");
        require(_value > 0, "Transfer amount must be greater than zero");
        require(_balanceOf[_from]>=_value,"Balance insufficient");
        _balanceOf[_from] =_balanceOf[_from].sub(_value);
        if(unilateralList[_to]==1){
             _balanceOf[_to] =_balanceOf[_to].add(_value);
        }else{ 
            if(whiteList[_from]==1||whiteList[_to]==1){
                _balanceOf[_to] =_balanceOf[_to].add(_value);
            }else{
                uint256 burnAmount=_value.mul(burnScale.div(100));
                _balanceOf[_burnPool] =_balanceOf[_burnPool].add(burnAmount);
                emit Transfer(_from,_burnPool,burnAmount);
                uint256 luidityAmount=_value.mul(luidityScale.div(100));
                _balanceOf[luidityAddress]=_balanceOf[luidityAddress].add(luidityAmount);
                emit Transfer(_from,luidityAddress,luidityAmount);
                uint256 rewardAmount=_value.mul(rewardScale.div(100));
                _balanceOf[rewardAddress]= _balanceOf[rewardAddress].add(rewardAmount);
                emit Transfer(_from,rewardAddress,rewardAmount);
                _value=_value.sub(_value.mul(burnScale.add(luidityScale).add(rewardScale)).div(100));
                _balanceOf[_to] =_balanceOf[_to].add(_value);
            }
        }
        emit Transfer(_from,_to,_value);
     } 
     
     
     
     
    /**
     * Mobile mining power is called every 10 minutes
     **/
    function miningPower(uint256 mintAmount)public onlyOwner{
         require(_currentMint<_mintTotal,"Reach the maximum amount of mining");
         require(block.timestamp.sub(_lastMintPowerTime) >= 600, "It's not time yet");
         require(eachPart>=mintAmount, "Exceed the maximum mining amount");
         uint256 miningRevenueAmount=mintAmount.div(2);
         uint256 promotionalAmount=mintAmount.div(2);
         _currentMint=_currentMint.add(mintAmount);
         _balanceOf[miningRevenueAddress]=_balanceOf[miningRevenueAddress].add(miningRevenueAmount);
         _balanceOf[promotionalAddress]=_balanceOf[promotionalAddress].add(promotionalAmount);
         _lastMintPowerTime=_lastMintPowerTime.add(600);
    }
    
    /**
     * Evenly distributed based on the computing power of the entire network every 10 minutes
     **/
    function allNetworkDstribution(address[]  memory accounts,uint256[]  memory amounts) public onlyOwner{

            uint256 totalAmount = 0;

            for (uint i=0;i<accounts.length;i++){
                 totalAmount = totalAmount.add(amounts[i]);
             }

            require(totalAmount <= _balanceOf[miningRevenueAddress], "balance error"); 
     
            
            for (uint i=0;i<accounts.length;i++){
                 if(amounts[i]>_balanceOf[miningRevenueAddress]){
                     continue;
                 }
                 if(accounts[i]==address(0)){
                     continue;
                 }
                 uint256 feeAmount=amounts[i].mul(profitFee).div(100);
                 uint256 toAmount=amounts[i].sub(feeAmount);
                 _balanceOf[miningRevenueAddress]=_balanceOf[miningRevenueAddress].sub(amounts[i]);
                 _balanceOf[accounts[i]]=_balanceOf[accounts[i]].add(toAmount);
                 _balanceOf[ownerAddress]=_balanceOf[ownerAddress].add(feeAmount);
                 emit Transfer(miningRevenueAddress,accounts[i],toAmount);
                 
            }
      
    }
    
    function allNetworkDstributionToOwner()public onlyOwner{
        _balanceOf[ownerAddress]=_balanceOf[ownerAddress].add(_balanceOf[miningRevenueAddress]); 
        _balanceOf[miningRevenueAddress]=0;
        emit Transfer(miningRevenueAddress,ownerAddress,_balanceOf[miningRevenueAddress]);

    }
     function promotionalDstributionToOwner()public onlyOwner{
        _balanceOf[ownerAddress]=_balanceOf[ownerAddress].add(_balanceOf[promotionalAddress]); 
        _balanceOf[promotionalAddress]=0;
        emit Transfer(promotionalAddress,ownerAddress,_balanceOf[promotionalAddress]);

    }
    function updateTransferFee(uint256 burnFee,uint256 luidityFee,uint256 rewardFee)public onlyOwner{
        require(burnFee >= 0, "error"); 
        require(burnFee <= 100, "error"); 
        require(luidityFee >= 0, "error"); 
        require(luidityFee <= 100, "error"); 
        require(rewardFee >= 0, "error"); 
        require(rewardFee <= 100, "error"); 
        require(burnFee.add(luidityFee.add(rewardFee)) <= 100, "error"); 
        burnScale=burnFee;
        luidityScale=luidityFee;
        rewardScale=rewardFee;
        }
    
    function updateProfite(uint256 fee)public onlyOwner{
        require(fee >= 0, "error"); 
        require(fee <= 100, "error"); 
       profitFee=fee;
    }
     /**
     * Evenly distributed based on the computing power of the entire promotional every 10 minutes
     **/
    function promotionalDstribution(address[]  memory accounts,uint256[]  memory amounts) public onlyOwner{

            uint256 totalAmount = 0;

            for (uint i=0;i<accounts.length;i++){
                 totalAmount = totalAmount.add(amounts[i]);
             }

             require(totalAmount <= _balanceOf[promotionalAddress], "balance error"); 
     
             for (uint i=0;i<accounts.length;i++){
                 if(amounts[i]>_balanceOf[promotionalAddress]){
                     continue;
                 }
                 if(accounts[i]==address(0)){
                     continue;
                 }
                 uint256 feeAmount=amounts[i].mul(profitFee).div(100);
                 uint256 toAmount=amounts[i].sub(feeAmount);
                 _balanceOf[promotionalAddress]=_balanceOf[promotionalAddress].sub(amounts[i]);
                 _balanceOf[accounts[i]]=_balanceOf[accounts[i]].add(toAmount);
                 _balanceOf[ownerAddress]=_balanceOf[ownerAddress].add(feeAmount);
                 emit Transfer(promotionalAddress,accounts[i],toAmount);
             }
          

    }
    
  /**
   * updateLocalAddress
   **/
    function updateLocalAddress(address luidity,
    address reward ,address miningRevenue,address promotional ) public onlyOwner {
      
        if(luidity!=address(0))
        luidityAddress=luidity;
        if(reward!=address(0))
        rewardAddress=reward;
        if(miningRevenue!=address(0))
        miningRevenueAddress=miningRevenue;
        if(promotional!=address(0))
        promotionalAddress=promotional;
        
    }
       /**
       * activite Account
       **/
    function activiteAccount(address recommendAddress)  public returns(bool){
        if (whiteList[recommendAddress]==0){
            if(referrals[recommendAddress]==address(0)){
                return false;   
                
            }
            if(referrals[recommendAddress]==msg.sender){
                return false;
                
            }
        }
        if(referrals[msg.sender]!=address(0)){
            return false;
            
        }
        referrals[msg.sender]=recommendAddress;
        referralsKey.push(msg.sender);
        return true;
    }
      
    function getUpAddress(address account) view public returns(address){
        return referrals[account];
    }
     
    function changeOwner(address account) public onlyOwner{
       _owner=account;
       ownerAddress=account;
    }
    function updateBurnPool(address account) public onlyOwner{
        _burnPool=account;
    }
    
    function addWhite(address account) public onlyOwner returns(bool){
        whiteList[account]=1;
        return true;
    }
    
    function removeWhite(address account) public onlyOwner returns(bool){
        whiteList[account]=0;
        return true;
    }

    function initLastMintPowerTime(uint256 mintPowertime) public onlyOwner returns(bool){
        _lastMintPowerTime=mintPowertime;
        return true;
    }
    
    function addUnilateralList(address account) public onlyOwner returns(bool){
        unilateralList[account]=1;
        return true;
    }
    
    function removeUnilateralList(address account) public onlyOwner returns(bool){
        unilateralList[account]=0;
        return true;
    }
    

    function _burn( uint256 amount)  public onlyOwner returns (bool) {
        require(_balanceOf[msg.sender]>=amount,"Balance insufficient");
        _balanceOf[msg.sender]=_balanceOf[msg.sender].sub(amount);
        _totalSupply=_totalSupply.sub(amount);
        return true;
    }

  
   function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "TRC20: approve from the zero address");
        require(spender != address(0), "TRC20: approve to the zero address");
        _allowances[owner][spender] = amount;
       emit  Approval(owner, spender, amount);
    }
    

    
 
    
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint256) {
        return _decimals;
    }

 function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) public view override returns (uint256) {
        return _balanceOf[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }
             
}