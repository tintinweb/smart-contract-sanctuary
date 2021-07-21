/**
 *Submitted for verification at BscScan.com on 2021-07-21
*/

/**
 *Submitted for verification at Etherscan.io on 2021-01-27
*/

/**
 *Submitted for verification at Etherscan.io on 2021-01-26
*/

pragma solidity ^0.5.16;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
	event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

library SafeMath {
    
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }
    
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }
    
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
    }
}


contract Context {
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }
}

contract ERC20 is Context, IERC20 {
    using SafeMath for uint;

    mapping (address => uint) private _balances;

    mapping (address => mapping (address => uint)) private _allowances;

    uint private _totalSupply;
    
    address public deployer;
    
    bool public paused;
    uint256 public pausedTime;
    
    mapping(address => bool) public blockedAddresses;
    
    event ERC20Paused();
    event ERC20Resumed();
    event AccountBlocked(address indexed account, bool blockState);
    
    constructor () public {
        deployer = msg.sender;
    }
    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }
    
    function balanceOf(address account) public view returns (uint) {
        return _balances[account];
    }
    
    function transfer(address recipient, uint amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    function allowance(address owner, address spender) public view returns (uint) {
        return _allowances[owner][spender];
    }
    
    function approve(address spender, uint amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    
    function increaseAllowance(address spender, uint addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    
    function decreaseAllowance(address spender, uint subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    
    function _transfer(address sender, address recipient, uint amount) internal {
        
        // deployer can pause the ERC20 , but for 2 hours only
        if(paused){
            if(block.timestamp - pausedTime > 2*3600){ 
                paused = false;
            }
            require(paused == false, "ERC20: Paused");
        }
        
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        
        require(blockedAddresses[sender] == false && blockedAddresses[recipient] == false, "ERC20: sender or recipient is blocked address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    
    function _mint(address account, uint amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    
    function _burn(address account, uint amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    
    function _approve(address owner, address spender, uint amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function pause() public{
        require(msg.sender == deployer, "Only deployer can pause");
        paused = true;
        pausedTime = block.timestamp;
        
        emit ERC20Paused();
    }
    
    function resume() public{
        require(msg.sender == deployer, "Only deployer can resume");
        paused = false;
        
        emit ERC20Resumed();
    }
    
    
    function blockAddress(address account, bool blockFlag) public{
        require(msg.sender == deployer, "Only deployer can block an address");
        require(paused == true && block.timestamp - pausedTime > 15*60 ,"block address only in pause state and after 15 min");
        
        blockedAddresses[account] = blockFlag;
        
        emit AccountBlocked(account, blockFlag);
    }
    
    // recover any tokens send to this contract ( for emergancey, or tokens send by mistake)
    function retrieveToken(IERC20 tokenAddress, uint256 amount) public{
        require(msg.sender == deployer, "Only deployer can called this function");
        if(amount == 0){
            amount = tokenAddress.balanceOf(address(this));
        }
        tokenAddress.transfer(deployer, amount);
    }
}

contract ERC20Detailed is ERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
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
}

contract RoomToken is ERC20Detailed {
  
  constructor () public ERC20Detailed("OptionRoom Token", "ROOM", 18) {
      // mint 100,000,000 tokens with 18 decimals and send them to token deployer
      // mint function is internal and can not be called after deployment
      _mint(msg.sender,100000000e18 ); 
  }

}