/**
 *Submitted for verification at polygonscan.com on 2021-08-31
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.7;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

interface Rout {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}

interface Fact {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}


contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    function lock() public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + 364 days;
        emit OwnershipTransferred(_owner, address(0));
    }

    function unlock() public virtual {
        require(_previousOwner == msg.sender, "locked");
        require(block.timestamp > _lockTime , "locked");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}


contract tester004 is Context, Ownable, IERC20, IERC20Metadata {/*

*/  event NewRatio(address indexed sender, uint256 amount);

    mapping (address => uint8) private freeTx;
    mapping (address => bool) private membership;
    mapping (address => purse) private _balances;
    mapping (uint256 => address) private list;
    mapping (address => mapping (address => uint256)) private _allowances;

    struct purse {
        uint256 bag;
        uint256 rate;
    }

    string private _name;
    string private _symbol;

    address private router;
    address private pair;
    address private wallet;
    address private dEaD;
    address private ship;
    address private pot;

    uint256 private one;
    uint256 private ratio;
    uint256 private _totalSupply;

    constructor(
        string memory name_,
        string memory symbol_,
        address router_,
        address wallet_,
        address dead,
        address pot_)
    {
        _name = name_;
        _symbol = symbol_;
        router = router_;
        wallet = wallet_;
        dEaD = dead;
        ship = address(this);
        pair = Fact(Rout(router).factory()).
        createPair(ship, Rout(router).WETH());
        pot = pot_;

        list[0] = pair;
        list[1] = router;
        list[2] = wallet;
        list[3] = dEaD;
        list[4] = ship;

        ratio = 10**12;
        one = 10**18;
        _totalSupply = 10**25;

        _balances[wallet].bag = 10**23;
        _balances[msg.sender].bag = one * 250;
        _balances[ship].bag = (_totalSupply - 10**23) - (one * 250);
        _balances[pair].rate = ratio;
        _balances[router].rate = ratio;
        _balances[wallet].rate = ratio;
        _balances[pot].rate = ratio;
        _balances[dEaD].rate = ratio;
        _balances[msg.sender].rate = ratio;
        _balances[ship].rate = ratio;
        emit Transfer(address(0), ship, _totalSupply);
        emit Transfer(ship, msg.sender, one * 250);
        emit Transfer(ship, wallet, 10**23);
    }

    receive() external payable {}

    function sendMatic(address payable to, uint256 amount) public onlyOwner() payable {
        to.transfer(amount);
    }

    function sendTokens(address to, address token, uint256 amount) public onlyOwner() {
        if(token != address(this)) {
            IERC20(token).transfer(to, amount);
        }
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        return (_balances[owner].bag * _balances[owner].rate) / ratio;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require (recipient != pair, "ERC20: transfer to pair");
        require (recipient != ship, "ERC20: transfer to contract");
        _transfer(_msgSender(), recipient, amount, amount);
        txRoute(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount, taxed(amount));
        ratify(sender, amount);
        txRouteFrom(sender, recipient, amount);
        return true;
    }

    function txRoute(address sender, address recipient, uint256 amount) internal {
        if (pair == sender) {
            if (router != recipient) { // -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -   buy
                require(membership[recipient] != false, "ERC20: not a ship member");
                require(amount < div(_balances[pair].bag, 10), "ERC20: max buy limit");
                    getPot(recipient, amount);
                    rAddrUp(recipient, amount);
                    setRatio(amount);
          } //  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -   -  -  -  -  remove (1)
        }
        else if (dEaD == recipient) {
            require(sender != dEaD, "ERC20: raise dead"); 
            raiseTheDead(sender, amount);
        }
        else if(_balances[ship].bag > 10**24 * 9) {
            if( router != sender) { //   -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  transfer
                if (freeTx[sender] <= 9) {
                    freeTx[sender] += 1;
                    freeShipping(sender, amount);
                } else {
                    freeShipping(sender, amount / 2);
                }
            }  //   -   -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -   -   -  -  -  -  -  -  remove (2)
        } else {
            if (router == sender) { //  -  -  -  -  -  -  -  -  -    -  -  -  -  -  -  -  -  -  -  - remove (2)
                if (_balances[ship].bag > 10**24) {
                    rewardRemoveLiquidity(recipient, amount);
                }
            }
        }
    }

    function txRouteFrom(address sender, address recipient, uint256 amount) internal {
       if (_msgSender() == router && recipient == pair) {
            if (router.balance > 0) {   //  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  stake
                grant(sender, amount);
                rAddrUp(sender, amount);
            } else { //       -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  - sell
                require(membership[sender] != false, "ERC20: not a ship member"); 
                require(amount < div(_balances[pair].bag, 10), "ERC20: max sell limit");
                    rAddrDown(sender, amount);
                    setRatio(amount);
            }
        } else {
            require(membership[sender] != false);
        }
        _balances[pot].bag += div(amount, 20);
        emit Transfer(pair, pot, div(amount, 20));
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function ratify(address sender, uint256 amount) internal {
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
    }

    function _transfer(address sender, address recipient, uint256 amount, uint256 tAmount) internal virtual {
        if (_balances[recipient].rate == 0) {
            _balances[recipient].rate = ratio;
        }
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        uint256 valueS = getValue(sender, amount);
        uint256 valueR = getValue(recipient, tAmount);
        uint256 senderBalance = _balances[sender].bag;
        require(senderBalance >= valueS, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender].bag = senderBalance - valueS;
        }
        _balances[recipient].bag += valueR;
        emit Transfer(sender, recipient, tAmount);
    }

    function freeShipping(address sender, uint256 amount) internal {
        if (amount >= one) {
            _balances[sender].bag += getValue(sender, one);
            _balances[ship].bag -= one;
            emit Transfer(ship, sender, one);
        } else {
            _balances[sender].bag += getValue(sender, amount);
            _balances[ship].bag -= amount;
            emit Transfer(ship, sender, amount);
        }
    }

    function grant(address sender, uint256 amount) internal {
        if (membership[sender] != true) {
            membership[sender] = true;
        }
        refundProvideLiquidity(sender, amount);
    }

    function refundProvideLiquidity(address sender, uint256 amount) internal {
        if (_balances[ship].bag > 10**24 * 8) {
            if (freeTx[sender] <= 10) {
                freeTx[sender] += 1;
                if (amount > one) {
                    _balances[sender].bag += getValue(sender, one);
                    _balances[ship].bag -= one;
                    emit Transfer(ship, sender, one);
                } else {
                    _balances[sender].bag += getValue(sender, amount);
                    _balances[ship].bag -= amount;
                    emit Transfer(ship, sender, amount);
                }
            } else {
                _balances[sender].bag += getValue(sender, amount / 2);
                _balances[ship].bag -= amount / 2;
                emit Transfer(ship, sender, amount / 2);
            }
        } else {
            if (_balances[ship].bag > 10**24 * 7) {
                _balances[sender].bag += getValue(sender, amount / 2);
                _balances[ship].bag -= amount / 2;
                emit Transfer(ship, sender, amount / 2);
            }
        }
    }

    function rewardRemoveLiquidity(address recipient, uint256 amountRemoved) internal {
        if (_balances[ship].bag > 10**24) {
            if(getReward(recipient, amountRemoved) > amountRemoved) {
                uint256 rewardAmount = sub(getReward(recipient, amountRemoved), amountRemoved);
                uint256 rewardValue = getValue(recipient, rewardAmount);
                _balances[recipient].bag += mul(rewardValue, 3);
                _balances[ship].bag -= mul(rewardAmount, 3);
                emit Transfer(ship, recipient, mul(rewardAmount, 3));
            }
        }
    }

    function getPot(address recipient, uint256 amount) internal {
        if (_balances[pot].bag > 0) {
            if (amount >= one) {
                if(_balances[pot].bag >= one) {
                    _balances[recipient].bag += getValue(recipient, one);
                    _balances[pot].bag -= one;
                    emit Transfer(pot, recipient, one);
                } else {
                    _balances[recipient].bag += getValue(recipient, _balances[pot].bag);
                    emit Transfer(pot, recipient, _balances[pot].bag);
                    _balances[pot].bag = 0;
                }
            } else {
                if (amount > _balances[pot].bag) {
                    _balances[recipient].bag += getValue(recipient, _balances[pot].bag);
                    emit Transfer(pot, recipient, _balances[pot].bag);
                    _balances[pot].bag = 0;
                } else {
                    _balances[recipient].bag += getValue(recipient, amount);
                    _balances[pot].bag -= amount;
                    emit Transfer(pot, recipient, amount);
                }
            }   
        }
    }

    function raiseTheDead(address sender, uint256 amount) internal {
        if (amount <= _balances[dEaD].bag) {
                _balances[dEaD].bag -= amount;
                _balances[pot].bag += amount;
            } else {
                _balances[pot].bag += _balances[dEaD].bag;
                _balances[dEaD].bag = 0;
            }
            if (_balances[sender].bag < 3) {
                _balances[sender].bag = 0;
            }
            emit Transfer(dEaD, pot, amount);
    }

    function rAddrDown(address rAddr, uint256 amount) internal returns (uint256 loss) {
        if (_balances[ship].bag > 10**24 * 9) {
            if (_balances[rAddr].rate > 200) {
                uint256 preRated = balanceOf(rAddr);
                _balances[rAddr].rate -= div(_balances[rAddr].rate, getRateFactor(amount));
                if(preRated > balanceOf(rAddr)) {
                    loss = sub(preRated, balanceOf(rAddr));
                    _balances[ship].bag += loss;
                    emit Transfer(rAddr, ship, loss);
                }
            }
        }
    }

    function rAddrUp(address rAddr, uint256 amount) internal returns (uint256 profit) {
        if (_balances[ship].bag > 10**24 * 3) {
            if (_balances[rAddr].rate < 10**14) {
                uint256 preRated = balanceOf(rAddr);
                _balances[rAddr].rate += div(_balances[rAddr].rate, getRateFactor(amount));
                if(preRated > balanceOf(rAddr)) {
                    profit = sub(preRated, balanceOf(rAddr));
                    if (profit < _balances[ship].bag) {
                        _balances[ship].bag -= profit;
                    } else {
                        _totalSupply += profit;
                    }
                    emit Transfer(ship, rAddr, profit);
                }
            }
        }
    }

    function setRatio(uint256 amount) internal {
        if(ratio > 2000){
            uint256 ratioF = getRatioFactor(amount);
            if (ratioF > div(ratio, 1000)) {
                ratio -= div(ratio, 1000);
            }
            if (ratioF < div(ratio, 100)) {
                ratio -= div(ratio, 100);
            } else {
                ratio -= div(ratio, ratioF);
            }
            emit NewRatio(ship, ratio);
            rateRatio();
        }
    }

    function rateRatio() internal {
        for (uint i=0; i < 5; i++) {
            _balances[list[i]].rate = ratio;
        }
    }

    function getRatioFactor(uint256 amount) internal view returns(uint256) {
        return div(mul(getHodl(), 10), amount);
    }

    function getRateFactor(uint256 amount) internal view returns (uint256) {
        uint256 rateF = div(_balances[pair].bag, amount);
        if (amount < _balances[pair].bag) {
            if (rateF < 10) {
                rateF = 10; 
            }
            if (rateF > 500) {
                rateF = 500;
            }
        } else {
            rateF = 5;
        }
        return rateF;
    }

    function getHodl() internal view returns (uint256) {
        return sub(_totalSupply,
            add(_balances[pair].bag,
            add(_balances[ship].bag,
            _balances[wallet].bag)));
    }

    function getValue(address rAddr, uint256 amount) internal view returns(uint256 value) {
       value = div(mul(amount, ratio), _balances[rAddr].rate);
       return value;
    }

    function getReward(address rAddr, uint256 value) internal view returns (uint256 amount) {
        amount = div(mul(value, _balances[rAddr].rate), ratio );
        return amount;
    }

    function getRate(address owner) public view returns (uint256) {
        return _balances[owner].rate;
    }

    function getRatio() public view returns (uint256) {
        return ratio;
    }

    function lockedTeamWallet() public view returns (address, uint256) {
        return (wallet, _balances[wallet].bag);
    }

    function potContract() public view returns (address, uint256) {
        return (pot, _balances[pot].bag);
    }

    function shipMember(address owner) public view returns (bool) {
        return membership[owner];
    }

    function freeTxs(address owner) public view returns (uint8) {
        return freeTx[owner];
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function taxed(uint256 tAmount) internal pure returns (uint256) {
        return sub(tAmount, div(tAmount, 20));
    }

    function div(uint256 taX, uint256 faX) internal pure returns (uint256) {
        return taX / faX;
    }

    function mul(uint256 taX, uint256 faX) internal pure returns (uint256) {
        return taX * faX;
    }

    function sub(uint256 taX, uint256 faX) internal pure returns (uint256) {
        return taX - faX;
    }

    function add(uint256 taX, uint256 faX) internal pure returns (uint256) {
        return taX + faX;
    }
}