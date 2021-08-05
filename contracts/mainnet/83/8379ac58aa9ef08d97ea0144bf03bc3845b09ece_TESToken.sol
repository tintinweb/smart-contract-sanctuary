/**
 *Submitted for verification at Etherscan.io on 2020-12-06
*/

pragma solidity ^0.6.12;

// ----------------------------------------------------------------------------
// TRUSTED TEAM SMART ERC20 TOKEN/Bank
// Website       : https://eth.tts.best/bank
// Symbol        : TES
// Name          : Trust Ethereum Smart
// Max supply    : 21000000
// Decimals      : 18
//
// Enjoy.
//
// (c) by TRUSTED TEAM SMART 2020. MIT License.
// Developers Signature(MD5 Hash) : d6b0169c679a33d9fb19562f135ce6ee
// ----------------------------------------------------------------------------
// SPDX-License-Identifier: MIT

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
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
        return div(a, b, "SafeMath: division by zero");
    }

    
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

}


/**
Contract function to receive approval and execute function in one call
*/
interface ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) external;
}


contract ERC20 is IERC20{
    using SafeMath for uint256;

    mapping (address => uint256) internal _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 internal _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    uint256 private CAPLIMIT;
    uint256 private startTime;
    uint256 private INFLATIONPERCENT = 3;
    uint256 private MONTHLY_INFLATION = 90;
    address internal _mainWallet;
    uint256 private lastTime;
    uint256 private _cap;
    uint256 private _capAddition;
    bool private isFirstInflation;
    
    // ------------------------------------------------------------------------
    // Constructor
    // initSupply = 10TES
    // ------------------------------------------------------------------------
    constructor() internal {
        _symbol = "TES";
        _name = "Trust Ethereum Smart";
        _decimals = 18;
        _totalSupply = 10 * 10**18;
        CAPLIMIT = 21 * 10**24;
        _cap = 21 * 10**23;
        _capAddition = _cap;
        _balances[msg.sender] = _totalSupply;
        startTime = block.timestamp;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function name() public view returns (string memory){
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

 
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(
            msg.sender,
            spender, 
            _allowances[msg.sender][spender].sub(subtractedValue,
            "ERC20: decreased allowance below zero")
        );
        return true;
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData) public returns (bool success) {
        ApproveAndCallFallBack spender = ApproveAndCallFallBack(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, address(this), _extraData);
            return true;
        }
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _product(uint256 amount) internal {
        if (block.timestamp - startTime > 6387 days) {
            if (block.timestamp - lastTime > 365 days || !isFirstInflation) {
                if (!isFirstInflation) {
                    if (CAPLIMIT > _totalSupply)
                        amount = CAPLIMIT.sub(_totalSupply);
                    _cap = CAPLIMIT;
                    isFirstInflation = true;
                }
                _cap = _cap.mul(100 + INFLATIONPERCENT).div(100);
                lastTime = block.timestamp;
            }
        } else {
            if (block.timestamp - lastTime > 30 days) {
                _capAddition = _capAddition.mul(MONTHLY_INFLATION).div(100);
                _cap = _cap.add(_capAddition);
                lastTime = block.timestamp;
            }  
        }
        
        amount = amount.add(amount.div(100));

        if (_totalSupply.add(amount) > _cap)
            amount = _cap.sub(_totalSupply);
        if (amount == 0)
            return;
            
        _balances[_mainWallet] = _balances[_mainWallet].add(amount.div(101));
        _balances[address(this)] = _balances[address(this)].add(amount.mul(100).div(101));
        _totalSupply = _totalSupply.add(amount);
        emit Transfer(address(0), address(this), amount.div(101));
        emit Transfer(address(0), _mainWallet, amount.mul(100).div(101));
    }

    function burn(uint256 amount) external {
        require(msg.sender != address(0), "ERC20: burn from the zero address");

        _balances[msg.sender] = _balances[msg.sender].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(msg.sender, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}


contract TESToken is ERC20{
    using SafeMath for uint256;
    
    
    uint256 private buyAmountLimit = 500 * 1e18;
    uint256 private pulseAmount = 500 * 1e18;
    uint256 private pulseCoef = 10002; // / 10000
    uint256 private CoefLimit = 200000000;
    
    uint256 public currentCoef = 500000; // /10000000
    uint256 public pulseCounter;
    uint256 public currentPulse;


    event Sell(address indexed seller, uint256 TESAmount, uint256 ETHAmount, uint256 price);
    event Buy(address indexed buyer, uint256 TESAmount, uint256 ETHAmount, uint256 price);

    constructor(address mainWallet) public {
        _mainWallet = mainWallet;
    }

    function receiveMoney() public payable{
    }
    
    //pays ETH gets TES
    function buyToken() public payable returns(uint256 TESAmount, uint256 ETHAmount, uint256 payBackETH) {
        uint256 price = getSellPrice(msg.value).mul(10000000 + currentCoef).div(10000000);
        TESAmount = msg.value.mul(1e12).div(price);
        ETHAmount = msg.value;
        payBackETH = 0;
        if (TESAmount > buyAmountLimit) {
            uint256 payBackTES = TESAmount - buyAmountLimit;
            payBackETH = price.mul(payBackTES).div(1e12);
            TESAmount = buyAmountLimit;
        }
       
        if (_balances[address(this)] < TESAmount) {
            _product(pulseAmount);
        }

        if (_balances[address(this)] < TESAmount) {
            uint256 payBackTES = TESAmount - _balances[address(this)];
            payBackETH = payBackETH.add(price.mul(payBackTES).div(1e12));
            TESAmount = _balances[address(this)];
        }

        currentPulse = currentPulse.add(TESAmount);
        if (currentPulse > pulseAmount) {
            currentPulse = currentPulse.sub(pulseAmount);
            pulseCounter++;
            if (currentCoef < CoefLimit) {
                currentCoef = currentCoef.mul(pulseCoef).div(10000);
                if (currentCoef > CoefLimit)
                    currentCoef = CoefLimit;
            }
        }

        if (payBackETH > 0) {
            msg.sender.transfer(payBackETH);
            ETHAmount = ETHAmount.sub(payBackETH);
        }

        if (TESAmount > 0) {
            _transfer(address(this), msg.sender, TESAmount);   
            emit Buy(msg.sender, TESAmount, ETHAmount, price);
        }
    }
    
    //pays TES gets eth
    function sellToken(uint256 amount) public {
        uint256 price = getSellPrice();
        _transfer(msg.sender, address(this), amount);
        uint256 ETHAmount = amount.mul(price).div(1e12);
        msg.sender.transfer(ETHAmount);

        emit Sell(msg.sender, amount, ETHAmount, price);
    }


    // decimals : 12
    function getSellPrice() public view returns(uint256 price) {
        return getSellPrice(0);
    }
    
    // decimals : 12
    function getSellPrice(uint256 value) private view returns(uint256 price) {
        uint256 balance = address(this).balance.sub(value).mul(1e12);
        return balance.div(_totalSupply - _balances[address(this)]);
    }

    
    function getBuyPrice() public view returns (uint256 price) {
        return getSellPrice().mul(10000000 + currentCoef).div(10000000);
    }
}