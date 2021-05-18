/**
 *Submitted for verification at Etherscan.io on 2021-05-18
*/

pragma solidity ^0.5.10;

//for administration management
contract Administration
{
    address private _admin;
    
    event AdminshipTransferred(address indexed currentAddress, address indexed newAdminAddress);
    
    constructor() internal
    {
        _admin = msg.sender;
        emit AdminshipTransferred(address(0),_admin);
    }
    
    function admin() public view returns (address)
    {
        return _admin;
    }
    
    //modified - function executed only if conditions in the modifier applied
    
    modifier onlyAdmin()
    {
        require(msg.sender == _admin,"Only admins can perform this action");
        //placeholder for the body.
        _;
    }
    
    // we used the onlyAdmin modifier as filter. only if the condition in the modifier is satisified, the function will be executed
    function transferAdminship(address  newAdminAddress) public onlyAdmin {
        emit AdminshipTransferred(_admin,newAdminAddress);
        _admin = newAdminAddress;
    }

}


contract MyToken {
    mapping (address => uint256) private _balances;
    
    //on behalf of. check the allowance given by the account
    mapping (address => mapping(address => uint256)) private _allowances;
    
    string private _name;
    string private _symbol;
    uint256 private _totalSupply;
    uint8 private _decimals;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approve(address indexed ownerAddress, address indexed spenderAddress, uint256 amount);
    
    constructor(uint256 initialSupply,string memory tokenName, string memory tokenSymbol,uint8  decimalPlaces) public {
        _balances[msg.sender] = initialSupply;
        _name = tokenName;
        _symbol = tokenSymbol;
        _totalSupply = initialSupply;
        _decimals = decimalPlaces;
    }

    //getter for private variables
    function name() public view returns (string memory){
        return _name;
    }
    
    function symbol() public view returns (string memory){
        return _symbol;
    }
    
    function decimals() public view returns (uint8){
        return _decimals;
    }
    
    function totalSupply() public view returns (uint256){
        return _totalSupply;
    }
    
    function setTotalSupply(uint256 totalAmount) internal{
        _totalSupply = totalAmount;
    }
    
    function allowance(address owner,address spender) public view returns (uint256)
    {
        return _allowances[owner][spender];
    }
    
    function setAllownace(address owner, address spender, uint256 amount) internal 
    {
        _allowances[owner][spender] = amount;
    }
    

    function balanceOf(address account) public view returns (uint256){
        return _balances[account];
    }
    
    function setBalance(address account, uint256 balance) internal
    {
        _balances[account] = balance;
    }
    
    function transfer(address beneficiary, uint256 amount) public returns(bool)
    {
        //for validation
        require(beneficiary != address(0) , "beneficiary address cannot be zero");
        require(_balances[msg.sender] >= amount, "Not enough balance");
        require(_balances[beneficiary] + amount > _balances[beneficiary],"Addition Overflow");
        
        _balances[msg.sender] -= amount;
        _balances[beneficiary] += amount;
        
        //an event for logging
        emit Transfer(msg.sender, beneficiary,amount);
        return true;
    }
    
    function approve(address spender, uint256 amount) public returns (bool success)
    {
        _allowances[msg.sender][spender] = amount;
        //to be complient with erc20Token
        emit Approve(msg.sender,spender,amount);
        return true;
    }
    
    
    function transferFrom(address spender, address beneficiary, uint256 amount) public returns (bool)
    {
        require(spender != address(0) , "beneficiary address cannot be zero");
        require(_balances[msg.sender] >= amount, "Not enough balance");
        require(_balances[beneficiary] + amount > _balances[beneficiary],"Addition Overflow");
        require(amount <= _allowances[spender][msg.sender],"Allowance is not enought");
        
        _balances[spender] -= amount;
        _allowances[spender][msg.sender] -= amount;
        _balances[beneficiary] +=amount;
        
        //for logging
        emit Transfer(spender,beneficiary,amount);
        
        return true;
    }
    
}


contract LBP is MyToken, Administration
{
    
    //creates a map of addresses and a bool against them
    mapping (address => bool) private _frozenAccounts;
    mapping (address => uint) private _pendingWithdrawels;
    
    event FrozenFund(address token, bool frozen);
    uint256 private _sellPrice = 1; //1 ether per token;
    uint256 private _buyPrice = 1;
    
    
       
    constructor(uint256 initialSupply,string memory tokenName, string memory tokenSymbol,uint8  decimalPlaces,address newAdmin) public
       
        //initial supply is zero because we have admin and the creator and the admin might differ
        MyToken(0,tokenName,tokenSymbol,decimalPlaces)
        {
            if(newAdmin != address(0) && newAdmin != msg.sender)
                transferAdminship(newAdmin);
            
            setBalance(admin(),initialSupply);
            setTotalSupply(initialSupply);
        }
        
        //target account inwhich the minted tokens will be transfered to
        function mintToken(address target, uint256 mintedAmount) public onlyAdmin
        {
            require(balanceOf(target) +mintedAmount> balanceOf(target),"Addition Overflow");
            require(totalSupply() + mintedAmount > totalSupply(),"Addition Overflow");
            
            setBalance(target,balanceOf(target) + mintedAmount);
            setTotalSupply(totalSupply()+ mintedAmount);
            
            emit Transfer(address(0),target,mintedAmount);
        } 
        
        function freezeAccount(address target, bool freeze) public onlyAdmin
        {
            _frozenAccounts[target] = freeze;
            emit FrozenFund(target,freeze);
        }
        
        function transfer(address beneficiary, uint256 amount) public returns(bool)
        {
            //for validation
            require(beneficiary != address(0) , "beneficiary address cannot be zero");
            require(balanceOf(msg.sender) >= amount, "Not enough balance");
            require(balanceOf(beneficiary) + amount > balanceOf(beneficiary),"Addition Overflow");
            require(!_frozenAccounts[msg.sender],"Account has been frozen");
            
            setBalance(msg.sender,balanceOf(msg.sender)-amount);
            setBalance(msg.sender,balanceOf(msg.sender)+amount);
            
            
            //an event for logging
            emit Transfer(msg.sender, beneficiary,amount);
            return true;
        }
        
        function transferFrom(address spender, address beneficiary, uint256 amount) public returns (bool)
        {
            require(spender != address(0) , "beneficiary address cannot be zero");
            require(balanceOf(msg.sender) >= amount, "Not enough balance");
            require(balanceOf(beneficiary) + amount > balanceOf(beneficiary),"Addition Overflow");
            require(amount <= allowance(spender,msg.sender),"Allowance is not enought");
            require(!_frozenAccounts[spender],"Account has been frozen");
            
            
            setBalance(spender,balanceOf(spender) - amount);
            setAllownace(spender,msg.sender,allowance(spender,msg.sender)-amount);
            setBalance(beneficiary,balanceOf(beneficiary)+amount);
            
            //for logging
            emit Transfer(spender,beneficiary,amount);
            
            return true;
        }
        
        
        function sellPrice() public view returns(uint256)
        {
            return _sellPrice;
        }
        
        function buyPrice() public view returns(uint256)
        {
            return _buyPrice;
        }
        
        function setPrices(uint256 newSellPrice, uint256 newBuyPrice) public onlyAdmin 
        {
            require(newSellPrice !=0,"Sell Price should be greater than 0");
            require(newBuyPrice !=0,"Buy Price should be greater than 0");
            
            _buyPrice = newBuyPrice;
            _sellPrice = newSellPrice;
        }
        
        
        //payable, because you are using ethers
        function buy() public payable
        {
            uint256 amount = (msg.value/(1 ether))/_buyPrice;
            address thisContractAddress  = address(this);
            
            require (balanceOf(thisContractAddress) >= amount, "Contract balance does not have enough value");
            require(balanceOf(msg.sender) + amount > balanceOf(msg.sender),"Addition Overflow");
            
            //decrease the amount of the buyer by the amount of tokens bought
            setBalance(thisContractAddress,balanceOf(thisContractAddress)-amount);
            setBalance(msg.sender,balanceOf(msg.sender)+amount);
            
            emit Transfer(thisContractAddress,msg.sender,amount);
            
        }
        
        function sell(uint256 amount) public payable
        {
            
            address thisContractAddress  = address(this);
            
            require (balanceOf(msg.sender) >= amount, "Your Balance does not have enough value");
            require(balanceOf(thisContractAddress) + amount > balanceOf(thisContractAddress),"Addition Overflow");
            
            //decrease the amount of the buyer by the amount of tokens bought
            setBalance(msg.sender,balanceOf(msg.sender)-amount);
            setBalance(thisContractAddress,balanceOf(thisContractAddress)+amount);
            
            //number of ethers seller should proceed
            uint256 saleProceed = amount * _sellPrice * (1 ether);
            //introduces pottentiol security risks
            //msg.sender.transfer
            //use widthraw pattern
            _pendingWithdrawels[msg.sender] += saleProceed; 
            emit Transfer(msg.sender,thisContractAddress,amount);
            
        }
        
        function widthraw() public
        {
            uint256 amount = _pendingWithdrawels[msg.sender];
            _pendingWithdrawels[msg.sender]=0;
            msg.sender.transfer(amount);
        }
        
}