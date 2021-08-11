//SourceUnit: YHL.sol

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
    
    

 
    mapping (address => uint256) public whiteList;

    mapping (address => mapping (address => uint256)) private _allowances;

     
    mapping (address => uint256) public _balanceOf;


   uint256 private _lastMintPowerTime;
   uint256 private _lastAllPowerTime;
   uint256 private _lastPromotionalTime;
   uint256 public _currentMint;
   uint256 private _mintTotal=1140000*10*8;
   uint256 private _totalSupply=1200000*10**8;
   string private _name ="YHL Token";
   string private _symbol="YHL";
   uint256 private _decimals = 8;
     
  address public ownerAddress;
    
  
  address public _burnPool = 0x000000000000000000000000000000000000dEaD;

  address public technologyAddress = address(0x41d79ca2f48c607fe4f62b19af5152a54e0e3a8abe);
  address public marketValueAddress=address(0x41331067be1ba7ee4ac3a70afa722eadd8dc1688ca);
  address public foundationAddress=address(0x4187365067bb5c9234eeb5eaf0bf281602dfc7fede);
  address public contractAddress=address(0x41031822facecf44f51214158ed80fe68255879391);
  address public rewardAddress=address(0x41b780aaf6b30287da57d34ffa268a50a4053dfdae);
  address public miningRevenueAddress=address(0x418fb810774c39cfe2d2bcbcb987a8bedfadb02091);
  address public promotionalAddress=address(0x412a51dc98e4c5eaf662b4a06a869a23b1c2565987);
 
    
    constructor ()public{
        _lastMintPowerTime=block.timestamp;
        _lastAllPowerTime=block.timestamp;
        _lastPromotionalTime=block.timestamp;
        ownerAddress=msg.sender;
        whiteList[msg.sender]=1;
        _balanceOf[ownerAddress] =30000*10**8; 
        _balanceOf[technologyAddress]=_totalSupply*1/100;
        _balanceOf[marketValueAddress]=_totalSupply*25/1000;
        _balanceOf[foundationAddress]=_totalSupply*15/1000;
        emit Transfer(address(0), ownerAddress,30000*10**8); 
    }
    
    function _transfer(address _from,address _to,uint256 _value) private{
        require(_from != address(0), "TRC20: transfer from the zero address");
        require(_to != address(0), "TRC20: transfer to the zero address");
        require(_value > 0, "Transfer amount must be greater than zero");
        require(_balanceOf[_from]>=_value,"Balance insufficient");
        _balanceOf[_from] -= _value;
        if(whiteList[_from]==1||whiteList[_to]==1){
            _balanceOf[_to] += _value;
        }else{
            uint256 burnAmount=_value*2/100;
            _balanceOf[_burnPool] += burnAmount;
            emit Transfer(_from,_burnPool,burnAmount);
            uint256 contractAmount=_value*2/100;
            _balanceOf[contractAddress] += contractAmount;
            emit Transfer(_from,contractAddress,contractAmount);
            uint256 rewardAmount=_value*1/100;
            _balanceOf[rewardAddress] += rewardAmount;
            emit Transfer(_from,rewardAddress,rewardAmount);
            _value=_value*95/100;
            _balanceOf[_to] += _value;
        }
        emit Transfer(_from,_to,_value);
     } 
     
     
     
     
    /**
     * Mobile mining power is called every 10 minutes
     **/
    function miningPower(uint256 mintAmount)public onlyOwner{
         require(_currentMint<_mintTotal,"Reach the maximum amount of mining");
         require(block.timestamp-_lastMintPowerTime > 36000, "It's not time yet");
         uint256 eachPart=_mintTotal/6/365/144;
         require(eachPart<=mintAmount, "Exceed the maximum mining amount");
         uint256 miningRevenueAmount=eachPart/2;
         uint256 promotionalAmount=eachPart/2;
         _currentMint+=mintAmount;
         _balanceOf[miningRevenueAddress] += miningRevenueAmount;
         _balanceOf[promotionalAddress] += promotionalAmount;
         _lastMintPowerTime=block.timestamp;
    }
    
    /**
     * Evenly distributed based on the computing power of the entire network every 10 minutes
     **/
    function allNetworkDstribution(address[]  memory accounts,uint256[]  memory amounts) public onlyOwner{
         require(block.timestamp-_lastAllPowerTime > 36000, "It's not time yet");
         for (uint i=0;i<accounts.length;i++){
             if(amounts[i]>_balanceOf[miningRevenueAddress]){
                 break;
             }
             if(accounts[i]==address(0)){
                 break;
             }
             _balanceOf[miningRevenueAddress] -= amounts[i];
             _balanceOf[accounts[i]] += amounts[i];
             emit Transfer(miningRevenueAddress,accounts[i],amounts[i]);
         }
         if(_balanceOf[miningRevenueAddress]>100000){
            _balanceOf[ownerAddress] +=_balanceOf[miningRevenueAddress]; 
            _balanceOf[miningRevenueAddress]=0;
            emit Transfer(miningRevenueAddress,ownerAddress,_balanceOf[miningRevenueAddress]);
         }
         _lastAllPowerTime=block.timestamp;
    }
    
     /**
     * Evenly distributed based on the computing power of the entire promotional every 10 minutes
     **/
    function promotionalDstribution(address[]  memory accounts,uint256[]  memory amounts) public onlyOwner{
         require(block.timestamp-_lastPromotionalTime > 36000, "It's not time yet");
         for (uint i=0;i<accounts.length;i++){
             if(amounts[i]>_balanceOf[promotionalAddress]){
                 break;
             }
             if(accounts[i]==address(0)){
                 break;
             }
             _balanceOf[promotionalAddress] -= amounts[i];
             _balanceOf[accounts[i]] += amounts[i];
             emit Transfer(promotionalAddress,accounts[i],amounts[i]);
         }
       
         _lastPromotionalTime=block.timestamp;
    }
    
  /**
   * updateLocalAddress
   **/
    function updateLocalAddress(address technology,address marketValue,address foundtion ,address contracts,
    address reward ,address miningRevenue,address promotional ) public onlyOwner {
        if(technology!=address(0))
        technologyAddress=technology;
        if(marketValue!=address(0))
        marketValueAddress=marketValue;
        if(foundtion!=address(0))
        foundationAddress=foundtion;
        if(contracts!=address(0))
        contractAddress=contracts;
        if(reward!=address(0))
        rewardAddress=reward;
        if(miningRevenue!=address(0))
        miningRevenueAddress=miningRevenue;
        if(promotional!=address(0))
        promotionalAddress=promotional;
        
    }
     
     
    function changeOwner(address account) public onlyOwner{
       _owner=account;
       ownerAddress=account;
    }
    
    function addWhite(address account) public onlyOwner returns(bool){
        whiteList[account]=1;
        return true;
    }
    
    function removeWhite(address account) public onlyOwner returns(bool){
        whiteList[account]=0;
        return true;
    }
    
      

    function _burn( uint256 amount)  public onlyOwner returns (bool) {
        require(_balanceOf[msg.sender]>=amount,"Balance insufficient");
        _balanceOf[msg.sender] -=  amount;
        _totalSupply -=  amount;
        return true;
    }

   function _mint(uint256 amount) internal {
        require(ownerAddress != address(0), "BEP20: mint to the zero address");
        _totalSupply += amount;
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