/**
 *Submitted for verification at Etherscan.io on 2021-02-13
*/

// SPDX-License-Identifier: NONE

pragma solidity ^0.6.12;

library SafeMathInt {
  function mul(int256 a, int256 b) internal pure returns (int256) {
    // Prevent overflow when multiplying INT256_MIN with -1
    // https://github.com/RequestNetwork/requestNetwork/issues/43
    require(!(a == - 2**255 && b == -1) && !(b == - 2**255 && a == -1));

    int256 c = a * b;
    require((b == 0) || (c / b == a));
    return c;
  }

  function div(int256 a, int256 b) internal pure returns (int256) {
    // Prevent overflow when dividing INT256_MIN by -1
    // https://github.com/RequestNetwork/requestNetwork/issues/43
    require(!(a == - 2**255 && b == -1) && (b > 0));

    return a / b;
  }

  function sub(int256 a, int256 b) internal pure returns (int256) {
    require((b >= 0 && a - b <= a) || (b < 0 && a - b > a));

    return a - b;
  }

  function add(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a + b;
    require((b >= 0 && c >= a) || (b < 0 && c < a));
    return c;
  }

  function toUint256Safe(int256 a) internal pure returns (uint256) {
    require(a >= 0);
    return uint256(a);
  }
  
  function toInt256Safe(uint256 a) internal pure returns (int256) {
    int256 b = int256(a);
    require(b >= 0);
    return b;
  }
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

contract Sector {
    
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using SafeMathInt for uint256;
    
    uint256 constant internal magnitude = 2**128; // For calculating precise amount for small ether dividend
    uint256 internal DividendPerShare; // Amount of dividend ether per share. Calculated according to decimals
    mapping(address => int256) internal DividendCorrections; // To correct dividend while transferring
    mapping(address => uint256) internal withdrawnDividends; // Keeps track of total withdrawn dividends
    uint256 public activeTokens = 0;
    
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint256 private _decimals;
    address public owner;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed user, address indexed spender, uint256 value);
    
    event DividendsDistributed(address indexed from, uint256 weiAmount);
    event DividendWithdrawn(address indexed to, uint256 weiAmount);
    event TokensSentToSale(uint amount,address receiver);
  
    constructor () public {
        _name = "SECTOR";
        _symbol = "SEC";
        _decimals = 18;
        owner = msg.sender;
        _mint(msg.sender,100*10**_decimals);
    }
    
    receive() external payable {
        distributeDividends();
    }
    
// Function to send tokens to ICO/sale
    function sendTokensToSale(uint256 amount, address receiver) external {
        require(msg.sender == owner,"Only owner can send token for sale");
        require(balanceOf(owner) >= amount,"Insufficient balance to send");
        _balances[msg.sender] = _balances[msg.sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[receiver] = _balances[receiver].add(amount);
        activeTokens += amount;
        emit TokensSentToSale(amount,receiver);
        
    }
    
// Function to distribute dividends to token holders    
    function distributeDividends() public payable {
        if (msg.value > 0) {
            DividendPerShare = DividendPerShare.add((msg.value).mul(magnitude) / activeTokens);
            emit DividendsDistributed(msg.sender, msg.value);
        }
    }
    
// Function to withdraw available dividends    
    function withdrawDividends() public {
        require(msg.sender != owner,"Owner cannot claim dividends!");
        uint256 _withdrawableDividend = withdrawableDividendOf(msg.sender);
        if (_withdrawableDividend > 0) {
            withdrawnDividends[msg.sender] = withdrawnDividends[msg.sender].add(_withdrawableDividend);
            emit DividendWithdrawn(msg.sender, _withdrawableDividend);
            (msg.sender).transfer(_withdrawableDividend);
        }
    }
    
//----------- VIEWS ----------//    
    
// Available amount of dividend to withdraw    
    function withdrawableDividendOf(address user) public view returns(uint256) {
        return accumulativeDividendOf(user).sub(withdrawnDividends[user]);
    }
    
// Amount of dividend an account earned in total    
    function accumulativeDividendOf(address user) public view returns(uint256) {
        return DividendPerShare.mul(balanceOf(user)).toInt256Safe().add(DividendCorrections[user]).toUint256Safe() / magnitude;
    }

// Total withdrawn amount of dividend of an account    
    function withdrawnDividendOf(address user) public view returns(uint256) {
        return withdrawnDividends[user];
    }
    
//--------- TOKEN FUNCTIONS --------------//

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint256) {
        return _decimals;
    }

    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address user, address spender) public view returns (uint256) {
        return _allowances[user][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(sender != owner,"Use sendTokensToSale function");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        
        // Error correction while transferring token
        int256 Correction = DividendPerShare.mul(amount).toInt256Safe();
        DividendCorrections[sender] = DividendCorrections[sender].add(Correction);
        DividendCorrections[recipient] = DividendCorrections[recipient].sub(Correction);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }


    function _approve(address user, address spender, uint256 amount) internal {
        require(user != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[user][spender] = amount;
        emit Approval(user, spender, amount);
    }

}