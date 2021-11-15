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
   
    uint public _totalsupply;
    string public name;
    string public symbol;
    uint public decimals;
    uint internal lockTime;
    address internal contractAddress;
    event _Balances(uint);
    
    constructor() {
        name = "AR Token";
        symbol = "ART";
        decimals = 3;
        contractAddress = address(this);
        lockTime = 120 + block.timestamp; //2629743 = one month ----- for practice purpose 2 minutes are keeping lockTime
        
        _totalsupply = 10000 * 10**decimals;
        _balances[owner()] = _totalsupply;
    }
    
    modifier isTimeLock(){
        require(block.timestamp > lockTime,"Wait for the vesting time");
        _;
    } 
    
    function totalSupply()public view virtual override returns(uint){
        return _totalsupply;
    }
    
    function getTokenDetails()public view returns(
        string memory Name, 
        string memory Symbol, 
        uint Decimals, 
        address Owner,
        address ContractAddress)
    {
        return (name, symbol, decimals, owner(), contractAddress);
    }
    
    function balanceOf(address account) public view virtual override returns(uint){
        return _balances[account];
    }
    
    function contractBalance() public view returns(uint){
        return contractAddress.balance;
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
    
    function buyTokens(address recipient, uint amount)internal virtual returns(bool){
        require(msg.sender != address(0), "sender is not valid address");
        require(recipient != address(0), "recipient is not valid address");
        
       _balances[owner()] -= amount; 
       _balances[recipient] += amount;
      
        emit Transfer(owner(), recipient, amount);
        return true;
    }  
    
    function mint(address account, uint _mint)internal virtual isTimeLock returns(bool){
        require(account != address(0) && _mint > 0,"unauthorized call");
        _totalsupply += _mint*10**decimals;
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







contract TheToken is ERC20{
    
    uint public rateBuy;           // rate of token = Ether
    uint public fundRais;       //sum of ethers collecting during token sale
    uint private maxSupply;
    mapping (address => bool) internal priceSetter;
    
    
    constructor(){
        maxSupply = 500000 *10**decimals;
        rateBuy = 1000;                     // 1 ether = 100 MBDE
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
        require(totalSupply() + (_mint*10**18) <= maxSupplyCap(),"TokenCaped: Cap exceeded");
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
    
    // function isContract(address _addr) private view returns (bool is_contract) {
    //     uint length;
    //         assembly {
    //             // retrieve the size of the code on target address; this needs assembly
    //                 length := extcodesize(_addr)
    //             }
    //         return (length>0);
    // }
    
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
}

