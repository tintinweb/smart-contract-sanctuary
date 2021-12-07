//SourceUnit: FHT.sol

pragma solidity ^0.5.8;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

contract Context {
    
    constructor () internal { }

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  
    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

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

contract FHT is IERC20, Ownable {
    using SafeMath for uint256;
    
    string private _name;
    
    string private _symbol;
    
    uint8 private _decimals;
    
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;
    
    uint8 private burnProp;
    
    bool private flag;
    
    mapping(address => bool) private whiteList;

    uint256 private divPool;

    address private dev;
    
  
    constructor() public {
        _symbol = "FHT";
        _name = "FHT";
        _decimals = 18;
        _totalSupply = 6000000*1e18;
        _balances[msg.sender] = _totalSupply;
        flag = true;
        emit Transfer(address(0), msg.sender, _totalSupply);
        whiteList[msg.sender] = true;
        burnProp = 6;
        divPool = 0;
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

    function transfer(address recipient, uint256 amount) public returns (bool) {
        if(flag){
            _burnTransfer(msg.sender, recipient, amount);
        }else{
            _transfer(msg.sender, recipient, amount);
        }
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        if(flag){
            _burnTransfer(sender, recipient, amount);
        }else{
            _transfer(sender, recipient, amount);
        }
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }
    
    function _burnTransfer(address _from, address _to, uint256 _value) internal returns (uint256){
        require(_from != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");
        
        uint256 burnAmount;
        uint256 disAmount;
        uint256 divAmount;
        if (whiteList[_from] || whiteList[_to]) {
            burnAmount = 0;
            disAmount = 0;
            divAmount = 0;
        } else {
            uint8 disProp = burnProp - 2;
            uint8 divProp = 2;
            burnAmount = _value.mul(burnProp).div(100);
            disAmount = _value.mul(disProp).div(100);
            divAmount = _value.mul(divProp).div(100);
            _totalSupply = _totalSupply.sub(disAmount);
        }
        
        _balances[_from] = _balances[_from].sub(_value);
        uint256 realValue = _value.sub(burnAmount);
        _balances[_to] = _balances[_to].add(realValue);
        _balances[dev] = _balances[dev].add(divAmount);
        divPool = divPool.add(divAmount);
        if(_totalSupply <= 660000*1e18){
            flag = false;
        }
        emit Transfer(_from, _to, _value);
        return _value;
    }
    
    function setWhiteList(address _addr,uint8 _type) public onlyOwner {
        if(_type == 1){
            require(!whiteList[_addr], "Candidate must not be whitelisted.");
            whiteList[_addr] = true;
        }else{
            require(whiteList[_addr], "Candidate must not be whitelisted.");
            whiteList[_addr] = false;
        }
    }
    
     function getWhiteList(address _addr) public view onlyOwner returns(bool) {
        return whiteList[_addr];
    }
    
    function setBurnProp(uint8 _prop) public onlyOwner {
       burnProp = _prop; 
    }
    
    function getBurnProp() public view onlyOwner returns(uint8) {
        return burnProp;
    }

    function setDev(address _addr) public onlyOwner {
       dev = _addr; 
    }

    function setDivPool(uint256 _val) public onlyOwner {
       divPool = _val; 
    }

    function getDivPool() public view returns(uint256) {
        return divPool;
    }

}