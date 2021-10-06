/**
 *Submitted for verification at BscScan.com on 2021-10-05
*/

// SPDX-License-Identifier: MIT
// powered by Shah BHUDHAI

pragma solidity ^0.8.4;


interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


interface IBEP20Metadata is IBEP20 {
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


contract BMONEY is Context, IBEP20, IBEP20Metadata {

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
    bool internal DexPool = false;
    bool internal Salefinished = false;

    string private _name;
    uint256 private _softcapDeadline;
    uint256 private _burningTime;
    string private _symbol;
    uint256 startOfSalesPeriod;

    constructor (address payable owner_) {
        _name = "nanic";
        _symbol = "nani4";
        _totalSupply = 100e8;
        _softCapTokens = 118220e8;
        _hardCapTokens = 788190e8;
        _owner =  owner_;
        startOfSalesPeriod =1624863600;
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
        require(currentAllowance >= amount, "BEP20: transfer amount exceeds allowance");
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
        require(currentAllowance >= subtractedValue, "BEP20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }
        return true;
    }

    receive() external payable {
        uint256 amount = msg.value*50/1e10;
        require(block.timestamp <= startOfSalesPeriod + 31556926 ,"Sale finished ");
        require(block.timestamp >= startOfSalesPeriod,"Sale period did not started");
        require(_totalSold <=788190e8, "Sold out");
        require(_totalSold + amount <=788190e8, "Not enough tokens left");
        require(_balances[msg.sender]+amount<=500e8, "You reached the personal cap");
        require(msg.value <= 10e18, "Maximum buying is limited to 10 bnb");
        _totalSold=_totalSold+amount;
        _mint(msg.sender,amount);
        _deposits[msg.sender] = _deposits[msg.sender] + msg.value;
        _balances[msg.sender] = _balances[msg.sender] + amount;
    }

    //The contract stores funds and gives refund option to the investor if soft cap not reached
	//For refund, users must have tokens in their wallet which they bought
	//If user refunds, tokens will be burned and deducted from the total supply

    function refundNBurn (address payable recipient) external{
        require(msg.sender == recipient , "Check the address");
        require((_totalSold < 118220e8) , "Soft cap reached");
        require(block.timestamp > startOfSalesPeriod + 7889229 ,"Time limit not reached. Wait until soft cap deadline");
        require(_deposits[msg.sender]>0, "You do not have tokens to refund");
        
        recipient.transfer(_deposits[msg.sender]);
        _deposits[msg.sender]=0;
        _burn(msg.sender, _balances[msg.sender]);
        _balances[msg.sender]=0;
     }

    //There are theree ways to create tokens; minting by using the buy function, 
	//sending direct bnb to the contract and claiming locked tokens.
	//The personal cap is 500 tokens. The token price for the ICO period is 0,02 bnb.
	//If total sold reaches hard cap, buy function will not mint tokens

     function buy()payable public returns(bool){
         uint256 amount = msg.value*50/1e10; 
         require(block.timestamp <= startOfSalesPeriod + 31556926 ,"Sale finished "); 
         require(block.timestamp >= startOfSalesPeriod,"Sale period did not started ");
         require(_totalSold <=788190e8, "Sold out"); 
         require(_totalSold + amount <=788190e8, "Not enough token left"); 
         require(_balances[msg.sender]+amount<=500e8, "You reached the personal cap"); 
         require(msg.value <= 10e18, "Maximum buying is limited to 10 bnb"); 
         _totalSold=_totalSold+amount; 
         _mint(msg.sender,amount); 
         _deposits[msg.sender] = _deposits[msg.sender] + msg.value; 
          _balances[msg.sender] = _balances[msg.sender] + amount;
         return (true);
    
    }

     function finalizeSale() public returns(bool){
         require(msg.sender == _owner , "NOT Accessable"); 
         uint256 amount = _hardCapTokens - _totalSold; 
         require(amount>0, "Hardcap reached"); 
         require(block.timestamp > startOfSalesPeriod + 31556926 && Salefinished,"Sale not finished "); 
         require (_totalSold <=788190e8, "Sold out"); 
         _totalSold=_totalSold+amount; 
         _mint(0x3737373737373737373737373737373737373737,amount); 
         Salefinished=true; 
         return (true);
     }

    //Burn function is especially designed for the tokens of Wei DAI, if he did not claimed before lock time + 1 months
	//his tokens are going to be burned and deducted from total supply.
	//Address 0x3737373737373737373737373737373737373737 will be used as a stove
	//If a user wants to burn tokens, they will send tokens to stove
	//Once a month, this function will be called and burn tokens inside.
    function stove() public virtual {
     require(block.timestamp > _burningTime ,"Burning time not reached, tokens are staying in the stove");
        if (_balances[0x440b87CCe2D1dd8DAcf31434bbbB85365e84B18B]>0) {
            _burn(0x440b87CCe2D1dd8DAcf31434bbbB85365e84B18B, _balances[0x440b87CCe2D1dd8DAcf31434bbbB85365e84B18B]);
            _burn(0x3737373737373737373737373737373737373737, _balances[0x3737373737373737373737373737373737373737]);
            _burningTime=_burningTime+2629743;
        } else {
            _burn(0x3737373737373737373737373737373737373737, _balances[0x3737373737373737373737373737373737373737]);
            _burningTime=_burningTime+2629743;
        }
    }

    function getPrice(uint256 TokenQuantity)public pure returns (uint256){
        uint256 price = 1e18/50;
        return TokenQuantity*price;
    }

    function totalSoldTokens()public view returns (uint256){
        return _totalSold;
    }

    function sale_finished()public view returns (bool){
        return Salefinished;
    }


    //There are six locks,
	//Dex Pool tokens will be available after contract deployment. 
	//That tokens will be used for creating pool on dexes.
    //Marketing tokens are locked until softcap reached 25%.
	//Developer tokens are locked for 6 months.
    //Seed investors tokens are locked for 9 months.
	//Wei DAI tokens are locked for 1 year.
	//Founder team tokens are locked for 2 years
    function claimLocked()public returns(bool success){
        require(msg.sender == _owner || 
        msg.sender == 0x9A34767F3f742B20d354183689bB953A45Ac6ACE ||
        msg.sender == 0x7203FAC48E911B397cc8bb29E55f4C1c06a57Fe8 ||
        msg.sender == 0x440b87CCe2D1dd8DAcf31434bbbB85365e84B18B || 
        msg.sender == 0x114f8D89b4a5072C25FAd7E110AcB09827cEB5Eb || 
        msg.sender == 0x3515f46d4E06b7Dd7C22DDE1357CD1aee8E74Bc7,"Invalid User ");
        if(msg.sender == 0x9A34767F3f742B20d354183689bB953A45Ac6ACE ){
            require(_totalSold>=29705e8 && !marketing,"Target limit is not reached or tokens are already taken");
            _mint(msg.sender,1500e8);
            marketing = true;
            return(true);
        } else if(msg.sender == 0x3515f46d4E06b7Dd7C22DDE1357CD1aee8E74Bc7 ){
            require(block.timestamp >=startOfSalesPeriod + 15778458  && !developers,"Time limit is not reached or tokens are already taken");
            _mint(msg.sender,2730e8);
            developers = true;
            return(true);
        } else if(msg.sender == 0x7203FAC48E911B397cc8bb29E55f4C1c06a57Fe8 ){
            require(!DexPool,"Tokens are already taken");
            _mint(msg.sender,500e8);
            DexPool = true;
            return(true);
        }else if(msg.sender == 0x114f8D89b4a5072C25FAd7E110AcB09827cEB5Eb ){
            require(block.timestamp >= startOfSalesPeriod + 23667687 && !seed_investors,"Time limit is not reached or tokens are already taken");
            _mint(msg.sender,1000e8);
            seed_investors = true;
            return(true);
        }
        else if(msg.sender == 0x440b87CCe2D1dd8DAcf31434bbbB85365e84B18B ){
            require(block.timestamp >= startOfSalesPeriod + 31556926 && !wei_dai,"Time limit is not reached or tokens are already taken");
            _mint(msg.sender,9200e8);
            wei_dai = true;
            return(true);
        }
        else if(msg.sender == _owner ){
            require(block.timestamp >= startOfSalesPeriod + 63113832 && !founder,"Time limit is not reached or tokens are already taken");
            _mint(msg.sender,5280e8);
            founder = true;
            return(true);
        }
    }

    function withdraw (uint256 amount) public returns(bool){
        require(msg.sender == _owner , "NOT Accessable");
        require((_totalSold >= 118220e8) , "Soft cap did not reached");
        if (amount >= address(this).balance) {
            _owner.transfer(address(this).balance);
        } else{
            _owner.transfer(amount);
        }
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");
        _beforeTokenTransfer(sender, recipient, amount);
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "BEP20: transfer amount exceeds balance");
    unchecked {
        _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "BEP20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }
    
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "BEP20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "BEP20: burn amount exceeds balance"); 
    unchecked {
        _balances[account] = accountBalance - amount;
      }
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
      }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}