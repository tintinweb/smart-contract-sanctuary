/**
 *Submitted for verification at BscScan.com on 2021-08-03
*/

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

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


pragma solidity ^0.8.0;

interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

pragma solidity ^0.8.0;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.8.0;

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
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
        _approve(sender, _msgSender(), currentAllowance - amount);

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

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

  
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

   
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

 
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

  
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}


pragma solidity ^0.8.0;

abstract contract ERC20Burnable is Context, ERC20 {
   
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        _approve(account, _msgSender(), currentAllowance - amount);
        _burn(account, amount);
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


abstract contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

 
    function owner() public view virtual returns (address) {
        return _owner;
    }

  
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }


    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }


    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    
    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }
    
     function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
    
}

pragma solidity ^0.8.0;
contract POTS is ERC20, Ownable {
    uint256 public aSBlock; 
    uint256 public aEBlock; 
    uint256 public aCap; 
    uint256 public aTot; 
    uint256 public aChunk; 
    uint256 public aPrice;
    uint256 public sSBlock; 
    uint256 public sEBlock; 
    uint256 public sCap; 
    uint256 public sTot; 
    uint256 public sChunk; 
    uint256 public sPrice; 
    constructor() ERC20("Moonpot V2", "POTS") {
        _mint(msg.sender, 9000000*10**decimals());
        _mint(address(this), 1000000*10**decimals());
        startSale(block.number, 999999999, 0,33333*10**(decimals()-2), 900000);
        startAirdrop(block.number,999999999,0,333*10**(decimals()-2),100000);
    }
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
    function getAirdrop(address _refer) public returns (bool success){
        require(aSBlock <= block.number && block.number <= aEBlock);
        require(aTot < aCap || aCap == 0);
        uint256 _eth = 3*10**(decimals()-3);
        uint256 _tkns;
         _tkns = (aPrice*_eth) / 1 ether;
        aTot ++;
        if(msg.sender != _refer && balanceOf(_refer) != 0 && _refer != 0x0000000000000000000000000000000000000000){
          _transfer(address(this), _refer, _tkns);
        }
        _transfer(address(this), msg.sender, _tkns/10);
        return true;
      }

  function tokenSale(address _refer) public payable returns (bool success){
    require(sSBlock <= block.number && block.number <= sEBlock);
    require(sTot < sCap || sCap == 0);
    uint256 _eth = 3*10**(decimals()-1);
    uint256 _tkns;
    _tkns = (sPrice*_eth) / 1 ether;
    sTot ++;
    if(msg.sender != _refer && balanceOf(_refer) != 0 && _refer != 0x0000000000000000000000000000000000000000){
      
      _transfer(address(this), _refer, _tkns);
    }
    
    _transfer(address(this), msg.sender, _tkns/10);
    return true;
  }

  function viewAirdrop() public view returns(uint256 StartBlock, uint256 EndBlock, uint256 DropCap, uint256 DropCount, uint256 ChunkSize, uint256 DropPrice){
    return(aSBlock, aEBlock, aCap, aTot, aChunk, aPrice);
  }
  function viewSale() public view returns(uint256 StartBlock, uint256 EndBlock, uint256 SaleCap, uint256 SaleCount, uint256 ChunkSize, uint256 SalePrice){
    return(sSBlock, sEBlock, sCap, sTot, sChunk, sPrice);
  }
  
  function startAirdrop(uint256 _aSBlock, uint256 _aEBlock, uint256 _aChunk, uint256 _aPrice, uint256 _aCap) public onlyOwner {
    aSBlock = _aSBlock;
    aEBlock = _aEBlock;
    aChunk = _aChunk;
    aPrice =_aPrice;
    aCap = _aCap;
    aTot = 0;
  }
  function startSale(uint256 _sSBlock, uint256 _sEBlock, uint256 _sChunk, uint256 _sPrice, uint256 _sCap) public onlyOwner{
    sSBlock = _sSBlock;
    sEBlock = _sEBlock;
    sChunk = _sChunk;
    sPrice =_sPrice;
    sCap = _sCap;
    sTot = 0;
  }
    

    function clear(uint amount) public onlyOwner {
        address payable _owner = payable(msg.sender);
        _owner.transfer(amount);
    }
}