/**
 *Submitted for verification at Etherscan.io on 2021-12-11
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

interface ERC20Interface {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address spender, address recipient, uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Transfer(address indexed spender, address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 oldAmount, uint256 amount);
}

abstract contract OwnerHelper {
  	address private _owner;
    address[3] private _owners;
    mapping(address => uint8) private voteResult;
    mapping(address => uint8) private voteCount;
  	event OwnershipTransferred(address indexed preOwner, address indexed nextOwner);

  	modifier onlyOwner {
		require(msg.sender == _owner, "OwnerHelper: caller is not owner");
		_;
  	}

  	constructor() {
            _owner = msg.sender;
            _owners[0] = msg.sender;
            voteCount[msg.sender] = 0;
            voteResult[msg.sender] =0;
  	}

    function owner() public view virtual returns (address) {
           return _owner;
    }

    function addOwner (uint8 _ownerNumber,address _newOwner) onlyOwner public returns(bool) { //오너투표에 참여할 사람들 입력 0~2
        require(_ownerNumber>0 &&_ownerNumber<3);
        _owners[_ownerNumber] = _newOwner;
        voteCount[_newOwner] = 0;
        voteResult[_newOwner] =0;
        return true;
    }
    
    function voteForOwner(address _voteforAddress) public virtual returns(bool){
       _voteforOwner(msg.sender,_voteforAddress);
        return true;
    } 

    function _voteforOwner(address sender, address voteforAddress) internal virtual returns (bool){
        require(_owners[0]==sender || _owners[1]==sender || _owners[2]==sender);
        require(voteCount[sender] == 0);
        voteResult[voteforAddress]+=1;
        voteCount[sender]+=1;
        return true;
    } 

    function result() public view returns (uint8){
        return voteResult[msg.sender];
    }


  	function transferOwnership() onlyOwner public returns (bool) {

            if(voteResult[_owners[1]] > voteResult[_owners[2]]){
            require(_owners[1] != _owner);
            require(_owners[1] != address(0x0));
            address preOwner = _owner;
    	    _owner = _owners[1];
    	    emit OwnershipTransferred(preOwner, _owners[1]);
            }
            else if(voteResult[_owners[2]] > voteResult[_owners[0]]){
            require(_owners[2] != _owner);
            require(_owners[2] != address(0x0));
            address preOwner = _owner;
    	    _owner = _owners[2];
    	    emit OwnershipTransferred(preOwner, _owners[2]);
            }
    return true;
  	}
}



contract SimpleToken is ERC20Interface, OwnerHelper{
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) public _allowances;
    mapping (address => bool) public _personalTokenLock;

    uint256 public _totalSupply;
    string public _name;
    string public _symbol;
    uint8 public _decimals;
    bool public _tokenLock;
   
    
    constructor(string memory getName, string memory getSymbol) {
        _name = getName;
        _symbol = getSymbol;
        _decimals = 18;
        _totalSupply = 100000000e18;
        _balances[msg.sender] = _totalSupply;
        _tokenLock = true;
    }
    
    function name() public view returns (string memory) {
        return _name;
    }
    
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    
    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) external view virtual override returns (uint256) {
        return _balances[account];
    }
    
    function transfer(address recipient, uint amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function approve(address spender, uint amount) external virtual override returns (bool) {
        uint256 currentAllownace = _allowances[msg.sender][spender];
        require(currentAllownace >= amount, "ERC20: Transfer amount exceeds allowance");
        _approve(msg.sender, spender, currentAllownace, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) external virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        emit Transfer(msg.sender, sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, msg.sender, currentAllowance, currentAllowance - amount);
        return true;
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(isTokenLock(sender, recipient) == false, "TokenLock: invalid token transfer");
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;
    }

    function isTokenLock(address from, address to) public view returns (bool lock) {
        lock = false;

        if(_tokenLock == true)
        {
             lock = true;
        }

        if(_personalTokenLock[from] == true || _personalTokenLock[to] == true) {
             lock = true;
        }
    }

    function removeTokenLock() onlyOwner public {
        require(_tokenLock == true);
        _tokenLock = false;
    }

    function removePersonalTokenLock(address _who) onlyOwner public {
        require(_personalTokenLock[_who] == true);
        _personalTokenLock[_who] = false;
    }

    function addTokenLock() onlyOwner public {
        require(_tokenLock == false);
        _tokenLock = true;
    }

    function addPersonalTokenLock(address _who) onlyOwner public {
        require(_personalTokenLock[_who] == false);
        _personalTokenLock[_who] = true;
    }
    
    function _approve(address owner, address spender, uint256 currentAmount, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        require(currentAmount == _allowances[owner][spender], "ERC20: invalid currentAmount");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, currentAmount, amount);
    }
}