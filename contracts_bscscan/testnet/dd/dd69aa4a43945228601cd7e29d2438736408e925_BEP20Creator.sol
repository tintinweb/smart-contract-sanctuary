/**
 *Submitted for verification at BscScan.com on 2022-01-07
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-11
*/

pragma solidity ^0.8.7;

/*
 * Welcome to BEP20 Token Generator! Please check our website.
 * Website: https://bep20.site
 */
 
interface IERC20 {
    function transfer(address _to, uint256 _amount) external returns (bool);
}

contract BEP20Creator {
    string public constant _name = "bep20.site";
    string public constant _symbol = "bep20.site";
    uint8 public constant _decimals = 18;
    uint256 public constant _totalSupply = 1000000000 * 10**_decimals;
    
    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private allowances;
    address public _owner = address(0);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor () {
       emit OwnershipTransferred(_owner, msg.sender);
       _owner = msg.sender;
       balances[_owner] = _totalSupply;
    }
    
    receive () external payable {
    }
    
    modifier onlyOwner() {
        require(_owner == msg.sender, "Error: caller is not the owner");
        _;
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
    
    function getOwner() public view returns (address) {
        return _owner;
    }
    
    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "Error: transfer from the zero address");
        require(recipient != address(0), "Error: transfer to the zero address");

        uint256 senderBalance = balances[sender];
        require(senderBalance >= amount, "Error: transfer amount exceeds balance");
        balances[sender] = senderBalance - amount;
        balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }
    
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "Error: approve from the zero address");
        require(spender != address(0), "Error: approve to the zero address");

        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function transfer(address recipient, uint256 amount) public virtual returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public virtual returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = allowances[sender][msg.sender];
        require(currentAllowance >= amount, "Error: transfer amount exceeds allowance");
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
        require(currentAllowance >= subtractedValue, "Error: decreased allowance below zero");
        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }
    
    function withdraw(uint256 amount) public payable onlyOwner returns (bool) {
        require(amount <= address(this).balance, "Error: withdrawal amount exceeds balance");
        payable(msg.sender).transfer(amount);
        return true;
    }
    
    function withdrawToken(address tokenContract, uint256 amount) public virtual onlyOwner {
        IERC20 _tokenContract = IERC20(tokenContract);
        _tokenContract.transfer(msg.sender, amount);
    }
    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Error: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}