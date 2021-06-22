/**
 *Submitted for verification at Etherscan.io on 2021-06-22
*/

// SPDX-License-Identifier: MIT
// powered by Shah BHUDHAI

pragma solidity ^0.8.4;


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function softcapDeadline() external view returns (uint256);
    function softCapTokens() external view returns (uint256);
    function hardCapTokens() external view returns (uint256);
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}


contract ERC20 is Context, IERC20, IERC20Metadata {

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _deposits;

    address payable _owner;
    uint256 private _totalSupply;
    uint256 private _softCapTokens;
    uint256 private _hardCapTokens;
    uint256 private _totalSold;

    bool internal marketing = false;
    bool internal developers =false;
    bool internal seed_investors = false;
    bool internal wei_dai =false;
    bool internal founder = false;
    bool internal uniswapPool = false;
    bool internal Salefinished = false;

    string private _name;
    uint256 private _softcapDeadline;
    uint256 private _burningTime;
    string private _symbol;
    uint256 startOfSalesPeriod;

    constructor (address payable owner_) {
        _name = "B-MONEY";
        _symbol = "BMNY";
        _totalSupply = 80840e8;
        _softCapTokens = 11762e8;
        _hardCapTokens = 78415e8;
        _owner =  owner_;
        startOfSalesPeriod =1624309200;
        _softcapDeadline = startOfSalesPeriod + 7889229;
        _burningTime = startOfSalesPeriod+ 34186659;
    }


    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 8;
    }

    function softcapDeadline() public view virtual override returns (uint256) {
        return _softcapDeadline;
    }

    function softCapTokens() public view virtual override returns (uint256) {
        return _softCapTokens;
    }

    function hardCapTokens() public view virtual override returns (uint256) {
        return _hardCapTokens;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
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
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
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
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }
        return true;
    }

    receive() external payable {
        uint256 amount = msg.value*40/1e10;
        require(block.timestamp <= startOfSalesPeriod + 31556916 ,"sale finished ");
        require(block.timestamp >= startOfSalesPeriod,"sale period did not started");
        require (_totalSold <=78812e8, "sold out");
        require (_totalSold + amount <=78812e8, "not enough tokens left");
        require(_balances[msg.sender]+amount<=40e8, "you reached the personal cap");
        require(msg.value <= 1e18, "maximum buying is limited to 1 eth");
        _totalSold=_totalSold+amount;
        _mint(msg.sender,amount);
        _deposits[msg.sender] = _deposits[msg.sender] + msg.value;
    }

    //the contract is storing funds and gives refund option to the investor if soft cap not reached
	//for refunding, users must have tokens in their wallet which they bought
	//if user refunds, tokens will be burned and deducted from the total supply

    function refundNBurn (address payable recipient) external{
        require(msg.sender == recipient , "check the address");
        require((_totalSold < 11820e8) , "soft cap reached");
        require(block.timestamp > startOfSalesPeriod + 7889229 ,"time limit not reached wait until softcap deadline");
        require(_deposits[msg.sender]>0, "you do not have tokens to refund");
        require(_deposits[msg.sender]*40 ==_balances[msg.sender], "please check your token balance");
        recipient.transfer(_deposits[msg.sender]);
        _deposits[msg.sender]=0;
        _burn(msg.sender, _balances[msg.sender]);
        _balances[msg.sender]=0;
     }

    //there are two ways to create tokens, minting by using the buy function and claiming locked tokens.
	//the personal cap is 40 tokens. the token price is 0,025 ethers.
	//If total sold reaches hardcap, buy function will not mint tokens

     function buy()payable public returns(bool){
         uint256 amount = msg.value*40/1e10; 
         require(block.timestamp <= startOfSalesPeriod + 31556916 ,"sale finished "); 
         require(block.timestamp >= startOfSalesPeriod,"sale period did not started "); 
         require (_totalSold <=78812e8, "sold out"); 
         require (_totalSold + amount <=78812e8, "not enough token left"); 
         require(_balances[msg.sender]+amount<=40e8, "you reached the personal cap"); 
         require(msg.value <= 1e18, "maximum buying is limited to 1 eth"); 
         _totalSold=_totalSold+amount; 
         _mint(msg.sender,amount); 
         _deposits[msg.sender] = _deposits[msg.sender] + msg.value; 
         return (true);
    }

     function finalizeSale() public returns(bool){
         require(msg.sender == _owner , "NOT Accessable"); 
         uint256 amount = _hardCapTokens - _totalSold; 
         require (amount>0, "hardcap reached"); 
         require(block.timestamp > startOfSalesPeriod + 31556916 && Salefinished,"sale not finished "); 
         require (_totalSold <=78812e8, "sold out"); 
         _totalSold=_totalSold+amount; 
         _mint(0x3737373737373737373737373737373737373737,amount); 
         Salefinished=true; 
         return (true);
     }

    //burn function is especialy designed for the tokens of wei dai, if he did not claimed before lock time
	//his tokens are going to burned and deducted from total supply//
	//address 0x3737373737373737373737373737373737373737 will be used as a stove
	//if a user wants to burn tokens, they will send tokens to stove
	//ones a month, this function will called and burn tokens inside
    function stove() public virtual {
     require(block.timestamp > _burningTime ,"Burning time not reached, tokens are staying in the stove");
        if (_balances[0x7a2315E6894EC79329b18B61d708Eb13FD020EE4]>0) {
            _burn(0x7a2315E6894EC79329b18B61d708Eb13FD020EE4, _balances[0x7a2315E6894EC79329b18B61d708Eb13FD020EE4]);
            _burn(0x3737373737373737373737373737373737373737, _balances[0x3737373737373737373737373737373737373737]);
            _burningTime=_burningTime+2629743;
        } else {
            _burn(0x3737373737373737373737373737373737373737, _balances[0x3737373737373737373737373737373737373737]);
            _burningTime=_burningTime+2629743;
        }
    }

    function getPrice(uint256 TokenQuantity)public pure returns (uint256){
        uint256 price = 1e18/40;
        return TokenQuantity*price;
    }

    function totalSoldTokens()public view returns (uint256){
        return _totalSold;
    }

    function sale_finished()public view returns (bool){
        return Salefinished;
    }


    //there are five locks,
    //marketing tokens are locked until softcap reached 25%
	//devloper tokens are locked for 6 months
    //seed investors tokens are locked for 9 months
	//wei dai tokens are locked for 1 year
	//founder team tokens are locked for 2 years
    function claimLocked()public returns(bool success){
        require(msg.sender == 0xc17EcCeb85174A6A35774bECB547d93D388E450f || 
        msg.sender == 0x9A34767F3f742B20d354183689bB953A45Ac6ACE ||
        msg.sender == 0x440b87CCe2D1dd8DAcf31434bbbB85365e84B18B || 
        msg.sender == 0x114f8D89b4a5072C25FAd7E110AcB09827cEB5Eb || 
        msg.sender == 0x3515f46d4E06b7Dd7C22DDE1357CD1aee8E74Bc7,"Invalid User ");
        if(msg.sender == 0x9A34767F3f742B20d354183689bB953A45Ac6ACE ){
            require(_totalSold>=2955e8 && !marketing,"target limit not reached ");
            _mint(msg.sender,150e8);
            marketing = true;
            return(true);
        } else if(msg.sender == 0x3515f46d4E06b7Dd7C22DDE1357CD1aee8E74Bc7 ){
            require(block.timestamp >=startOfSalesPeriod + 15778458  && !developers,"time limit not reached ");
            _mint(msg.sender,359e8);
            developers = true;
            return(true);
        } else if(msg.sender == _owner ){
            require(!uniswapPool,"tokens already taken");
            _mint(msg.sender,100e8);
            uniswapPool = true;
            return(true);
        }else if(msg.sender == 0x114f8D89b4a5072C25FAd7E110AcB09827cEB5Eb ){
            require(block.timestamp >= startOfSalesPeriod + 23667687 && !seed_investors,"time limit not reached ");
            _mint(msg.sender,150e8);
            seed_investors = true;
            return(true);
        }
        else if(msg.sender == 0x440b87CCe2D1dd8DAcf31434bbbB85365e84B18B ){
            require(block.timestamp >= startOfSalesPeriod + 31556916 && !wei_dai,"time limit not reached ");
            _mint(msg.sender,920e8);
            wei_dai = true;
            return(true);
        }
        else if(msg.sender == _owner ){
            require(block.timestamp >= startOfSalesPeriod + 63113832 && !founder,"time limit not reached ");
            _mint(msg.sender,696e8);
            founder = true;
            return(true);
        }
    }

    function withdraw (uint256 amount) public returns(bool){
        require(msg.sender == _owner , "NOT Accessable");
        require((_totalSold >= 11820e8) , "soft cap not reached");
        if (amount >= address(this).balance) {
            _owner.transfer(address(this).balance);
        } else{
            _owner.transfer(amount);
        }
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(sender, recipient, amount);
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
    unchecked {
        _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }
    
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance"); 
    unchecked {
        _balances[account] = accountBalance - amount;
      }
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
      }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}