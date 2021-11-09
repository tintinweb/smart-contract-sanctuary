/**
 *Submitted for verification at Etherscan.io on 2021-11-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20{
    function totalSupply() external view returns(uint);
    function balanceOf(address account) external view returns(uint);
    
    function transfer(address recipient, uint amount) external returns(bool);
    function transferFrom(address sender, address recipient, uint amount) external returns(bool);
    
    function approve(address spender, uint amount) external returns(bool);
    function allowance(address owner, address spender) external view returns(uint);
    
    event Transfer (address indexed from, address indexed to, uint value);
    event Approval (address indexed owner, address indexed spender, uint value);
}




contract Ownable{
    
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(msg.sender);
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    
       function owner() public view virtual returns (address) {
        return _owner;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}







contract ERC20 is IERC20, Ownable{
    
    mapping (address => uint) private _balances;
    mapping (address => mapping(address => uint )) private _allowances;
   
    uint internal _totalSupply;
    string internal _name;
    string internal _symbol;
    uint internal decimals;
    uint internal lockTime;
    event _Balances(uint);
    
    constructor() {
        _name = "ARY Token";
        _symbol = "ARY";
        decimals = 18;
        lockTime = 1 + block.timestamp; //2629743 = one month ----- for practice purpose 2 minutes are keeping lockTime
        
        _totalSupply = 1000 * 10**decimals;
        _balances[owner()] = _totalSupply;
    }
    
    modifier isTimeLock(){
        require(block.timestamp > lockTime,"ERC20: Wait for the vesting time");
        require(block.timestamp < (lockTime + 2700000), "ERC20: Sales Ended");
        _;
    } 
    
    function name()public view returns(string memory){
        return _name;
    }
    
    function symbol()public view returns(string memory){
        return _symbol;
    }
    
    function totalSupply()public view virtual override returns(uint){
        return _totalSupply;
    }
    
    function balanceOf(address account) public view virtual override returns(uint){
        return _balances[account];
    }
    
    function currentSupply() public view returns(uint){
        return (_totalSupply - _balances[owner()]);
        
    }
    
    function salesStartTime()public view returns(uint){
        return lockTime;
    }
    
    function salesEndTime()public view returns(uint){
        return (lockTime + 2700000);
    }
    
    function transfer(address recipient, uint amount)public virtual override returns(bool){
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    
      function _transfer(address sender, address recipient, uint amount)internal virtual isTimeLock returns(bool){
        require(sender != address(0), "sender is not valid address");
        require(recipient != address(0), "recipient is not valid address");
        require(_balances[sender] >= amount,"insufficient balance");
        
      _balances[sender] -= amount; 
      _balances[recipient] += amount;
      
        emit Transfer(sender, recipient, amount);
        return true;
    }
    
    function buyTokens(address recipient, uint amount)internal virtual isTimeLock returns(bool){
        require(msg.sender != address(0), "sender is not valid address");
        require(recipient != address(0), "recipient is not valid address");
        
       _balances[owner()] -= amount; 
       _balances[recipient] += amount;
      
        emit Transfer(owner(), recipient, amount);
        return true;
    }  
    
    function mint(address account, uint _mint)internal virtual isTimeLock returns(bool){
        require(account != address(0) && _mint > 0,"unauthorized call");
        _totalSupply += _mint*10**decimals;
        _balances[account] += _mint*10**decimals;
        return true;
    }

    function approve(address spender, uint amount)public virtual override returns(bool){
        address tokenOwner = msg.sender;
        
        require(msg.sender == tokenOwner,"Caller is not tokenOwner");
        require(_balances[tokenOwner] > amount,"Insufficient funds in tokenOwner account");
        require(tokenOwner != address(0), "tokenOwner is not valid address");
        require(spender != address(0), "spender is not valid address");
        
        _allowances[tokenOwner][spender] = amount;
        emit Approval(tokenOwner,spender,amount);
        return true;
    }
    
    function allowance(address tokenOwner, address spender)public virtual override view returns(uint){
        return _allowances[tokenOwner][spender];
    }
    
    function transferFrom(address tokenOwner, address recipient, uint amount)public virtual override isTimeLock returns(bool){
        address spender = msg.sender;
        uint value = _allowances[tokenOwner][spender];
        require(value > amount,"Authorizer limit is not enough /or/ insufficient funds");
        require(recipient != address(0), "Recipient is not valid address");
        
        _allowances[tokenOwner][spender] -= amount;
        _transfer(tokenOwner,recipient,amount);
        
        emit Transfer(tokenOwner, recipient, amount);
        return true;
    }
    
    function killingContract()external payable onlyOwner() returns(uint){
        address contractAddress = address(this);
        uint remainingToken = _balances[contractAddress];
        if (remainingToken > 0){
            _transfer(contractAddress,owner(),remainingToken);
            emit _Balances (_balances[owner()]);
        }

        selfdestruct(payable(owner()));
        emit Transfer(contractAddress,owner(),remainingToken);
        return _balances[owner()];
    }
    
}







contract TokenSale is ERC20{
    
    uint internal rateBuy;           // rate of token = Ether
    uint public fundRais;       //sum of ethers collecting during token sale
    uint internal maxSupply;
    mapping (address => bool) internal priceSetter;
    
    
    constructor(){
        maxSupply = 5000 *10**decimals;
        rateBuy = 1;                     // 1 ether = 100 ARY
    }
    
    modifier isAuthorizer () {
       require(msg.sender == owner() || priceSetter[msg.sender],"caller is not authorizer"); 
        _;
    }
    
    fallback()external payable{   }
    
    receive() external payable{   }
    
    function maxSupplyCap()public view returns(uint){
        return maxSupply;
    }
    
    function minting(address account, uint _mint)public  returns(bool){
        require(account != address(0),"account should not be zeor address");
        require(totalSupply() + (_mint*10**decimals) <= maxSupplyCap(),"TokenCaped: Cap exceeded");
        mint(account,_mint);
        return true;
    }
    
    
    function setRateSetter(address _priceSetter)public onlyOwner(){
        priceSetter[_priceSetter] = true;
    }
    
    function delRateSetter(address _priceSetter)public onlyOwner(){
        priceSetter[_priceSetter] = false;
    }
    
    
    function setRate(uint _newRate) public isAuthorizer returns(uint newRate){
        require(_newRate > 0,"Rate must not be Zero");
        rateBuy = _newRate;
        return rateBuy;
    }
    
    function getBuyRate() public view returns(uint){
        return rateBuy;
    }
    
    
    function buyToken(address account) public payable returns(uint FundsRais){
        uint tokensAllocation = msg.value * rateBuy;
        fundRais = fundRais + msg.value;
        
        require(account != address(0), "address must not be Zero");
        require(msg.value > 0,"minimum purchase must not be Zero ether");
        
        buyTokens(account,tokensAllocation);
        return fundRais;
    }
    
    function tokenBuyBack(address _seller, uint _tokenReturn, uint _rateSale)public payable returns(bool){
        address seller = _seller;
        uint etherReturn = (_tokenReturn / _rateSale)/(1**decimals);
        
        require (msg.sender == seller && seller !=address(0),"Seller must be valid account holder");
        require (_tokenReturn <= balanceOf(seller),"Seller token balance is not sufficient");
        require (etherReturn <= fundRais,"No liquidity for this token");

        _transfer(seller,owner(),_tokenReturn);
        fundRais = fundRais - etherReturn;
        payable(seller).transfer(etherReturn);
        
        emit Transfer(seller, owner(),_tokenReturn);
        return true;
    }
    
    function withdrawFunds()public payable onlyOwner() returns(uint FundRais){
        payable(msg.sender).transfer(address(this).balance);
        return fundRais;
    }
    
    
    
}