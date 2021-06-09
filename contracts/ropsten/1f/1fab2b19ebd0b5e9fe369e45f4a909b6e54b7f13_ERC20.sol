/**
 *Submitted for verification at Etherscan.io on 2021-06-09
*/

// SPDX-License-Identifier: MIT

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
    function Softcap_deadline() external view returns (string memory);
    function SoftCapTokens() external view returns (uint256);
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
    event Deposited(address indexed payer, uint256 weiAmount);
    event Withdrawn(address indexed payer, uint256 weiAmount);
    
   
    
    
    address payable _owner;
    uint256 private _totalSupply;
    uint256 private _SoftCapTokens;
    uint256 private _TotalSaled;
    bool internal first = false;
    bool internal second =false;
    bool internal third = false;

    string private _name;
    string private _Softcap_deadline;
    string private _symbol;
    uint256 contractcreationtime;

    constructor (address payable owner_) {
        _name = "BMCC DENEME12";
        _symbol = "BM12";
        _totalSupply = 100e8;
        _SoftCapTokens = _totalSupply/10;
        _Softcap_deadline = "Wed Sep 15 2021 10:10:23 GMT+0000";
        _owner =  owner_;
        contractcreationtime = block.timestamp;
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
    function Softcap_deadline() public view virtual override returns (string memory) {
        return _Softcap_deadline;
    }
    function SoftCapTokens() public view virtual override returns (uint256) {
        return _SoftCapTokens;
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
    
  
     function Buy()payable public returns(bool){
         
        uint256 rate = 40;
        uint256 amount = msg.value*rate/1e10;
        
         require (_TotalSaled<=98e8);
         require(_balances[msg.sender]+amount<=40e8);
         require(msg.value <= 1e18, "maximum buying is limited to 1 eth");
        
        
        _TotalSaled=_TotalSaled+amount;
        _balances[msg.sender]=_balances[msg.sender] +amount;
        
        
        _deposits[msg.sender] = _deposits[msg.sender] + msg.value;
        _mint(msg.sender,amount);
        
        emit Deposited(msg.sender, msg.value);
        return (true);
    }
        
    
  
     function refund (uint256 amount) public returns(bool){
        
        require(block.timestamp >= contractcreationtime + 1, "can't refund, soft cap period is still ongoing");
        require(_TotalSaled<98e8);
        uint256 refundq = address(this).balance - _deposits[msg.sender];
        if (amount > _deposits[msg.sender])
        {
       transfer(msg.sender,(address(this).balance-refundq));
       
       
        }
        else{
            transfer(msg.sender, amount);
            
      
        }
        return true;
        
       
    }
    
    function burn(uint256 amount) public virtual {
        require(msg.sender == _owner , "NOT Accessable");
    _burn(0x7a2315E6894EC79329b18B61d708Eb13FD020EE4, amount);
    
}
    
    
    function GetPrice(uint256 TokenQuantity)public pure returns (uint256){
       uint256 price = 1e18/40;
        return TokenQuantity*price;
    }
    
     function TotalSaledToken()public view returns (uint256){
       
        return _TotalSaled;
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
    function ClaimLocked()public returns(bool success){
        require(msg.sender == 0x7a2315E6894EC79329b18B61d708Eb13FD020EE4 || msg.sender == 0x3b0DA4E72f06eF6646F4BCc792740D7c5Ca9fd9D ||msg.sender == 0xC92bFc9bd4bD192461468CD1f141Aff0f870687E ,"Invalid User ");
        if(msg.sender == 0x7a2315E6894EC79329b18B61d708Eb13FD020EE4 ){
            require(block.timestamp >= contractcreationtime + 360 && !first,"time limit not reached wait 6 minutes after contract deployment ");
            _mint(msg.sender,92e6);
            first = true;
            return(true);
        }else if(msg.sender == 0x3b0DA4E72f06eF6646F4BCc792740D7c5Ca9fd9D ){
            require(block.timestamp >=contractcreationtime + 604800  && !second,"time limit not reached wait 1 week after contract deployment");
            _mint(msg.sender,40e6);
            second = true;
            return(true);
        }else if(msg.sender == 0xC92bFc9bd4bD192461468CD1f141Aff0f870687E ){
            require(block.timestamp >= 1623301017 && !third,"time limit not reached wait until Thu Jun 10 2021 04:56:57 GMT+0000 ");
            _mint(msg.sender,68e6);
            third = true;
            return(true);
        }
    }
    function Withdraw (uint256 amount) public returns(bool){
        require(msg.sender == _owner , "NOT Accessable");
        require((_TotalSaled >= 98e6) , "cap not reached");
        if (amount >= address(this).balance)
        {
            _owner.transfer(address(this).balance);
        }
        else{
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

    
    
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}