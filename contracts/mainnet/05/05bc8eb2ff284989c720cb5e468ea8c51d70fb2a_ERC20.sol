// SPDX-License-Identifier: Unlicense

pragma solidity ^0.6.0;

import "IERC20.sol";
import "IERC20Metadata.sol";
import "Context.sol";


contract ERC20 is Context, IERC20, IERC20Metadata {
    // Instance of Token
    IERC20 token;
    
    //  MAPPINGS
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
	mapping (address => uint256) public lockTokens;
    // VARAIBLES
    uint256 private _totalSupply;
    uint256 public tokenPrice;
    uint256 public remainingTokens;
    string private _name;
    string private _symbol;
    address payable ownerAccount;
    uint256 releaseTime;
    uint256 public cap;
    uint256 lockedAmount;
    uint256 releaseTimeOwner;
	uint256 public mintCapAnnual;
	uint256 public mintAvailableDate;
	uint256 private _mini;
    
    
    //  MODIFIERS
    modifier onlyOwner(){
        require(msg.sender == ownerAccount, "You are not an Owner.");
        _;
    }
    
    
    constructor () public {
        _name = "Ice Cube";
        _symbol = "iCube";
        _totalSupply = 1050000000000 * (10**18);
        _balances[_msgSender()] = _totalSupply;
        ownerAccount = msg.sender;
        tokenPrice = 800000000;
        token = IERC20(address(this));
        cap = 2100000000000 * (10**18);
		mintCapAnnual = cap/50;
        releaseTime = 0;  
        lockedAmount = 0;
        releaseTimeOwner = 0;
		mintAvailableDate = 1655683200;
    }   
	
    
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }


    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }


    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        if(address(this) == msg.sender){
            _transfer(_msgSender(), recipient, amount);
        }
        else{																			
            uint256 checkBalance = (_balances[_msgSender()] - lockTokens[_msgSender()]);
            require(now >= releaseTime || checkBalance >= amount,"Token is Paused");
            require(amount <= cap,"Cap amount exceeded...");
            if(ownerAccount == _msgSender()){
                if(releaseTimeOwner != 0){
                     require((_balances[ownerAccount] - amount) >= lockedAmount,"Passed wrong value");
                     require( now >= releaseTimeOwner,"Owner can not transfer this time");    
                    _transfer(_msgSender(), recipient, amount);
                    
                }else{
                    _transfer(_msgSender(), recipient, amount);
                }
            }else{
                _transfer(_msgSender(), recipient, amount);
            }
        }
        return true;
    }
    
    function noPausedtransfer(address recipient, uint256 amount) internal returns (bool) {
        require(amount <= cap,"Cap amount exceeded...");
        
        if(ownerAccount == _msgSender()){
            if(releaseTimeOwner != 0){
                 require((_balances[ownerAccount] - amount) >= lockedAmount,"Passed wrong value");
                 require( now >= releaseTimeOwner,"Owner can not transfer this time");    
                _transfer(_msgSender(), recipient, amount);
                
            }else{
                _transfer(_msgSender(), recipient, amount);
            }
        }else{
            _transfer(_msgSender(), recipient, amount);
        }
    }
    
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }


    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        require(now >= releaseTime || lockTokens[_msgSender()] <= 0,"Token is Paused");
        require(amount <= cap,"Cap amount exceeded...");
        if(ownerAccount == _msgSender()){
            if(releaseTimeOwner != 0){
                 require((_balances[ownerAccount] - amount) >= lockedAmount,"Passed wrong value");
                 require( now >= releaseTimeOwner,"Owner can not transfer this time");    
                 uint256 currentAllowance = _allowances[sender][_msgSender()];
                 require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
                _approve(sender, _msgSender(), currentAllowance - amount);

            }else{
                uint256 currentAllowance = _allowances[sender][_msgSender()];
                require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
                _approve(sender, _msgSender(), currentAllowance - amount);
            }
        }else{
            uint256 currentAllowance = _allowances[sender][_msgSender()];
            require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
        return true;
    }
    
    


    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    // THIS FUNCTION WILL CALL ONLY OWNER FOR MINTING THE TOKENS 
    // IF TOTAL SUPPLY ACHIEVED THE CAPPED VALUE THEN NO MINTING WILL ALLOWED
    // THEN OWNER NEED TO INCREASE THE CAP VALUE BY USING 'setCapAmount' FUNCTION
    function mint(address account, uint256 amount) public onlyOwner{
        require(account != address(0), "ERC20: mint to the zero address");
        require(_totalSupply + amount<= cap,"Amount Exceeded Market Cap");
		require(amount<= mintCapAnnual,"Amount Exceeded Mint Cap");
		require(mintAvailableDate<= now,"Coin Not Ready for Mint");
		mintAvailableDate += 31536000;
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    // THIS FUNCTION WILL CALL ONLY FOR OWNER FOR BURNING THE TOKENS
    function burn(address account, uint256 amount) public onlyOwner{
        require(account != address(0), "ERC20: burn from the zero address");
        if(ownerAccount == msg.sender){
            if(releaseTimeOwner != 0){
                require((_balances[ownerAccount] - amount) >= lockedAmount,"Passed wrong value");
                require( now >= releaseTimeOwner,"Owner can not transfer this time");
                uint256 accountBalance = _balances[account];
                require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
                _balances[account] = accountBalance - amount;
                _totalSupply -= amount;
                emit Transfer(account, address(0), amount);   
            }else{
                uint256 accountBalance = _balances[account];
                require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
                _balances[account] = accountBalance - amount;
                _totalSupply -= amount;
                emit Transfer(account, address(0), amount);
            }
        }else{
            uint256 accountBalance = _balances[account];
            require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
            _balances[account] = accountBalance - amount;
            _totalSupply -= amount;
            emit Transfer(account, address(0), amount);
        }
    }

    // THIS WILL PAUSE THE TOKEN
    function pauseToken(uint256 timestamp) public onlyOwner{
        releaseTime = timestamp;
    }
    
    // THIS WILL SET THE PRICE OF TOKEN
    function setPrice(uint256 _price) public onlyOwner{
        tokenPrice = _price;
    }
    
    
    // OWNER NEED TO CALL THIS FUNCTION BEFORE START ICO
    // OWNER ALSO NEED TO SET A GOAL OF TOKEN AMOUNT FOR FUND RAISING
    // THIS FUNCTION WILL TRANSFER THE TOKENS FROM OWNER TO CONTRACT
    function startBuying(uint256 tokenAmount, uint256 time) public onlyOwner{
        releaseTime = time;
        remainingTokens = tokenAmount;
        noPausedtransfer(address(this),tokenAmount);
    }
    
   
    
  
    //  THIS FUMCTION WILL BE USED BY INVESTOR FOR BUYING TOKENS
    //  IF THE OWNER WILL END ICO THEN NO ONE CAN INVEST ANYMORE 
    function buyToken() public payable{
        require(msg.value > 0,"You are passing wrong value");
		require(msg.value <= 10**19,"Maximum order size is 10 ETH");
        require(msg.sender != address(0),"Invalid Address of Buyer");
        require(now <= releaseTime, "TokenSale is ended.");
        address sender = msg.sender; 
        uint256 quantity = (msg.value / tokenPrice) * 10**18;
		lockTokens[sender] += quantity;								 
        ownerAccount.transfer(msg.value);
        token.transfer(sender,quantity);
        remainingTokens -= quantity; 
    }
    
	//  OWNER CAN LOCK THEIR TOKENS	
    function lockOwnerTokens(uint256 amount, uint256 _time) public onlyOwner {
        lockedAmount = amount;
        releaseTimeOwner = _time;
    }
    
	// WITHDRAW
    function withdraw() public onlyOwner{
        require(remainingTokens > 0,"All tokens are Sold.");
        token.transfer(ownerAccount,remainingTokens);
    }
      
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    
}