/**
 *Submitted for verification at hecoinfo.com on 2022-05-31
*/

/**
 *Submitted for verification at hecoinfo.com on 2022-04-29
*/

/**
 *Submitted for verification at hecoinfo.com on 2021-09-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "e001");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "e002");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "e003");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "e004");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "e005");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "e006");
        uint256 c = a / b;
        return c;
    }
}

contract Cake is Ownable {
    using SafeMath for uint256;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool)  public MinerList;
    mapping(address=>bool) public takeNoFeeList;
    uint256 public maxSupply;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 public burnFee = 1;
    uint256 public lpFee = 2;
    address public lpAddress;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor (string memory name, string memory symbol, uint256 _preSupply, uint256 _maxSupply) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
        _totalSupply = _preSupply.mul(1e18);
        maxSupply = _maxSupply.mul(1e18);
        _balances[_msgSender()] = _totalSupply;
        takeNoFeeList[msg.sender] = true;
        takeNoFeeList[address(1)] = true;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }
    
    function setLpAddress(address _lpAddress) external onlyOwner {
        lpAddress = _lpAddress;
    }
    
    function setTakeNoFeeList(address[] memory _addressList,bool _status) external  onlyOwner {
     for (uint256 i=0;i<_addressList.length;i++) {
         takeNoFeeList[_addressList[i]] = _status;
     }   
    }
    
    function setFee(uint256 _burnFee,uint256 _lpFee) external onlyOwner {
        burnFee = _burnFee;
        lpFee = _lpFee;
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

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "e007");
        require(recipient != address(0), "e008");
        _beforeTokenTransfer(sender, recipient, amount);
        _balances[sender] = _balances[sender].sub(amount);
        
        if (takeNoFeeList[sender] || takeNoFeeList[recipient]) {
            _balances[recipient] = _balances[recipient].add(amount);
            emit Transfer(sender, recipient, amount);
        } else {
            uint256 burnAmount = amount.mul(burnFee).div(100);
            uint256 lpAmount = amount.mul(lpFee).div(100);
            uint256 transferAmount = amount.sub(burnAmount).sub(lpAmount);
            _balances[lpAddress] = _balances[lpAddress].add(lpAmount);
            _balances[address(1)] = _balances[address(1)].add(burnAmount);
            _balances[recipient] = _balances[recipient].add(transferAmount);
            emit Transfer(sender, lpAddress, lpAmount);
            emit Transfer(sender, address(1), burnAmount);
            emit Transfer(sender, recipient, transferAmount);
        }

    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "e009");
        require(spender != address(0), "e010");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), 'BEP20: mint to the zero address');
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    function addMiner(address _adddress) public onlyOwner {
        MinerList[_adddress] = true;
    }

    function removeMiner(address _adddress) public onlyOwner {
        MinerList[_adddress] = false;
    }

    function mint(address _to, uint256 _amount) public returns (bool) {
        require(MinerList[msg.sender], "only miner!");
        require(_totalSupply.add(_amount) <= maxSupply);
        _mint(_to, _amount);
    }
}