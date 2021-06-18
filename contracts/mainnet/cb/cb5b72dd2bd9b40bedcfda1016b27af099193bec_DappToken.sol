/**
 *Submitted for verification at Etherscan.io on 2021-06-18
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

library SafeMath {
  
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);

        return c;
    }
 
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction underflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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

    function mul(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
   
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, errorMessage);

        return c;
    }
  
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
    
        return c;
    }
  
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
 
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function mint(address, uint256) external;
    function burn(uint256) external;
    function transfer(address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract DappToken is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private allowances;

    uint256 public totalSupply;

    string public name;
    string public symbol;
    uint8 public decimals;
    
    address public ownerAddress;
    address public bridgeContractAddress;

    modifier onlyBridge {
        require(msg.sender == bridgeContractAddress, "Can be called only by bridge Contract");   
        _;
    }

    modifier onlyOwner {
        require(msg.sender == ownerAddress, "Can be called only by owner");   
        _;
    }

    constructor(string memory _name, string memory _symbol, address _bridgeContractAddress, address _owner) {
        name = _name;
        symbol = _symbol;
        decimals = 4;
        ownerAddress = _owner;
        bridgeContractAddress = _bridgeContractAddress;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return allowances[owner][spender];
    }
   
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        balances[sender] = balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        balances[recipient] = balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function mint(address account, uint256 amount) public override onlyBridge() {
        require(account != address(0), "ERC20: mint to the zero address");

        totalSupply = totalSupply.add(amount);
        balances[account] = balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function burn(uint256 amount) public override {
        balances[msg.sender] = balances[msg.sender].sub(amount, "ERC20: burn amount exceeds balance");
        totalSupply = totalSupply.sub(amount);
        emit Transfer(msg.sender, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function updateBridgeContractAddress(address _bridgeContractAddress) public onlyOwner() {
        require(_bridgeContractAddress != address(0), "Bridge address is zero address");
        bridgeContractAddress = _bridgeContractAddress;
    }
    function transferOwnership(address _newOwner) public onlyOwner() {
        require(_newOwner != address(0), "Owner address is zero address");
        ownerAddress = _newOwner;
    }

}