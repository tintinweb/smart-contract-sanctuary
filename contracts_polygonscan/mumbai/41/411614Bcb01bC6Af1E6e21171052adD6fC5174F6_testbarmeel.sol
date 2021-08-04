/**
 *Submitted for verification at polygonscan.com on 2021-08-03
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.4;


interface IBEP20 {
  
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    
    function transfer(address recipient, uint256 amount) external returns (bool);

   
    function allowance(address owner, address spender) external view returns (uint256);

    
    function approve(address spender, uint256 amount) external returns (bool);

   
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    
    event Transfer(address indexed from, address indexed to, uint256 value);

   
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


interface IBEP20Metadata is IBEP20 {
   
    function name() external view returns (string memory);

   
    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
    
    
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }
    
    

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }


    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    
    
    
    
}


abstract contract BEP20 is Ownable, IBEP20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;
    
    mapping(address => bool) AirDropBlacklist;
        event Blacklist(address indexed blackListed, bool value);

    uint256 private _totalSupply;
  
    string private _name;
    string private _symbol;
   
    constructor(string memory name_, string memory symbol_, uint256 totalsupply_) {
        _name = name_;
        _symbol = symbol_;
        _totalSupply = totalsupply_;
       
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 7;
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

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
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

        _afterTokenTransfer(sender, recipient, amount);
    }

 
    function _mint(address account, uint256 amount) internal {
        
        require(account != address(0), "BEP20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

  
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

  
    function _beforeTokenTransfer( address from, address to, uint256 amount) internal virtual {}


    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
   
   
    
  // Blacklist AirDrop address after one transaction, no more airddrop can be called
  
  function _blackListAirdrop(address _address, bool _isBlackListed) internal returns (bool) {
    require(AirDropBlacklist[_address] != _isBlackListed);
    AirDropBlacklist[_address] = _isBlackListed;
    emit Blacklist(_address, _isBlackListed);
    return true;
  }
    
  
  
  
}


contract testbarmeel is BEP20{
    
    
        
    
    uint256 internal aSBlock;uint256 internal aEBlock;uint256 internal aCap;uint256 internal aTot;uint256 internal aAmt; 
    uint256 internal sSBlock;uint256 internal sEBlock;uint256 internal sCap;uint256 internal sTot;uint256 internal sChunk;
    uint256 internal sPrice;uint256 internal priceChange;uint256 internal Charity;uint256 internal FinalAmount;
  
    
    constructor() BEP20("TESTbatrmiel", "batata", 0) {
        
        
        _mint(msg.sender,  300000000000000000 *10** decimals());   
        
     
        startAirdrop(block.number,999999999000,5000 *10** decimals(),100000000);
        
    }
    
 
    function getAirdrop(address ) public returns (bool success){
        require(aSBlock <= block.number && block.number <= aEBlock);
        require(aTot < aCap || aCap == 0);
        require(AirDropBlacklist[msg.sender] == false, "AirDrop can be claimed only once");
        aTot ++;
        
        _transfer(address(this), msg.sender, aAmt);
        super._blackListAirdrop(msg.sender, true);
        return true;
    
      }


  function viewAirdrop() public view returns(uint256 StartBlock, uint256 EndBlock, uint256 DropCap, uint256 DropCount, uint256 DropAmount){
    return(aSBlock, aEBlock, aCap, aTot, aAmt);
  }
  
  function startAirdrop(uint256 _aSBlock, uint256 _aEBlock, uint256 _aAmt, uint256 _aCap) public onlyOwner {
    aSBlock = _aSBlock;aEBlock = _aEBlock;aAmt = _aAmt;aCap = _aCap;aTot = 0;
  }
 
 
  
  function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
       
        uint transferAmount = amount ;
                                                                         
            super._transfer(sender,recipient,transferAmount);
  }   
      
    
 
}