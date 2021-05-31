/**
 *Submitted for verification at Etherscan.io on 2021-05-31
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    
    function totalSupply() external view returns (uint256);
    function balanceOf(address tokenOwner) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address tokenOwner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

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
        if (a == 0) return 0;

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

contract Ownable {
    
    address private owner = msg.sender;
    
    function getOwner() public view returns (address) {
        return owner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "ERC20: permission denied");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner returns (bool) {
        owner = newOwner;
        return true;
    }
    
}

contract Feeable is Ownable {
    
    bool public feeOn = true;
    address public feeTo = msg.sender;
    uint256 public feePoint = 6;
    uint256 public feeRatio = 1000;

    function setFeeTo(address _feeTo) public onlyOwner returns (address) {
        feeTo = _feeTo;
        return feeTo;
    }
    
    function setFeeOn(bool _feeOn) public onlyOwner returns (bool) {
        feeOn = _feeOn;
        return feeOn;
    }
    
    function setFeePoint(uint256 _feePoint) public onlyOwner returns (uint256) {
        feePoint = _feePoint;
        return feePoint;
    }
    
    function setFeeRatio(uint256 _feeRatio) public onlyOwner returns (uint256) {
        feeRatio = _feeRatio;
        return feePoint;
    }
    
}

contract OxCoinToken is IERC20, Feeable {
    
    using SafeMath for uint256;
    
    string public name = "OxCoin Token";
    string public symbol = "OXC";
    uint256 public decimals = 8;
    uint256 private _totalSupply = 10 ** 10 * (10 ** 8);
    
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowed;
    
    constructor() {
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function mint(address tokenOwner, uint256 amount) public onlyOwner returns (uint256) {
        _totalSupply = _totalSupply.add(amount);
        balances[tokenOwner] = balances[tokenOwner].add(amount);
        emit Transfer(address(0), tokenOwner, amount);
        return balances[tokenOwner];
    }

    function burn(address tokenOwner, uint256 amount) public returns (uint256) {
        require(msg.sender == getOwner() || msg.sender == tokenOwner, "ERC20: permission denied");
        _totalSupply = _totalSupply.sub(amount);
        balances[tokenOwner] = balances[tokenOwner].sub(amount);
        emit Transfer(tokenOwner, address(0), amount);
        return balances[tokenOwner];
    }
    
    function airDrop(address[] memory recipients, uint256[] memory amount) public {
        require(recipients.length > 0 && amount.length > 0, "ERC20: The airdrop need required an available address and amount");
        require(amount.length >= recipients.length, "ERC20: The amount length of the airdrop array cannot be less than the address length");
        
        uint256 totalAmount = 0;
        for(uint256 n = 0; n < amount.length; n++) {
            totalAmount = totalAmount.add(amount[n]);
        }
        
        require(balances[msg.sender] >= totalAmount, "ERC20: airdrops transfer sender amount exceeds balance");
        for (uint256 i = 0; i < recipients.length; i++) {
            _transfer(msg.sender, recipients[i], amount[i]);
        }
    }
    
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return balances[tokenOwner];    
    }
    
    function allowance(address tokenOwner, address spender) public override view returns (uint) {
        return allowed[tokenOwner][spender];
    }
    
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, allowed[sender][msg.sender].sub(amount));
        return true;
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(balances[sender] >= amount, "ERC20: transfer sender amount exceeds balance");
        
        uint256 fee = 0;
        if (feeOn) {
            fee = amount.mul(feePoint).div(feeRatio);
            if (fee == 0) fee = 1; //Minimum amount 0.00000001 OXC
            balances[feeTo] = balances[feeTo].add(fee);
        }
        
        balances[sender] = balances[sender].sub(amount);
        balances[recipient] = balances[recipient].add(amount.sub(fee));
        
        emit Transfer(sender, recipient, amount);
    }
    
    function _approve(address tokenOwner, address spender, uint256 amount) internal {
        allowed[tokenOwner][spender] = amount;
    }
    
}