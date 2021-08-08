/**
 *Submitted for verification at polygonscan.com on 2021-08-07
*/

/*
    Each address has its own variable 'maximum-sell-limit' that increases with the buy-amount.
    Maximum 'insta-refund' for providing liquidity is 1 SPEM.
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;


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

interface QRout {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}

interface QFact{
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IQPair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
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


contract Spem is Context, Ownable, IERC20, IERC20Metadata {


    event Set(address indexed Contract, uint256 AmountSet);

    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (uint256 => address) private row;
    mapping (address => Account) private map;

     struct Account {
        uint256 pin;
        uint256 bal;
        uint256 spemmed;
        uint256 maxF;
        bool rewarded;
    }

    string private _name;
    string private _symbol;

    address private router;
    address private pair;
    address private spem;
    address public wallet;

    uint8 private rem;
    uint8 private lim;

    uint256 private sum;
    uint256 private set;
    uint256 private minTx;
    uint256 private oneSpem;
    uint256 private _totalSupply;

    constructor (string memory name_, string memory symbol_, address router_, address spemwallet_) {
        router = router_;
        spem = address(this);
        wallet = spemwallet_;
        pair = QFact(QRout(router).factory()).createPair(address(this), QRout(router).WETH());

        _name = name_;
        _symbol = symbol_;

        row[0] = pair;
        row[1] = spem;
        row[2] = router;
        row[3] = wallet;

        lim = 2;
        sum = 20;
        set = 10**12;
        minTx = 10**15;
        oneSpem = 10**18;
        _totalSupply = 10**22 * 5;

        map[pair].pin = set;
        map[spem].pin = set;
        map[router].pin = set;
        map[msg.sender].pin = set;
        map[wallet].pin = set;

        map[spem].bal = sub(_totalSupply, add(oneSpem, 10**20 * 25));
        map[wallet].bal = 10**20 * 25;
        map[msg.sender].bal = oneSpem;

        emit Transfer(address(0), spem, _totalSupply);
        emit Transfer(spem, wallet, add(oneSpem, 10**20 * 25));
        emit Transfer(wallet, msg.sender, oneSpem);
    }

    receive() external payable {}

    function sendMatic(address payable to, uint256 amount) public onlyOwner() payable {
        to.transfer(amount);
    }

    function sendTokens(address to, address token, uint256 amount) public onlyOwner() {
        if(token != spem) {
            IERC20(token).transfer(to, amount);
        }
    }

    function spamSPEM(address[] calldata recipients) public onlyOwner() {
        require(map[spem].bal > 10**22 * 4);
        for (uint256 i = 0; i < recipients.length; i++) {
            if(map[recipients[i]].pin == 0) {
                spam(recipients[i]);
            }
        }
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

    modifier mod(address recipient) {
        require (recipient != pair, "ERC20: transfer to pair");
        _;
    }

    function transfer(address recipient, uint256 amount) public virtual override mod(recipient) returns (bool) {
        _transfer(_msgSender(), recipient, amount, sent(_msgSender(), recipient, amount));
        routeFrom(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount, tax(amount));
        ratify(sender, amount);
        routeTo(sender, recipient, amount);
        return true;
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

    function balanceOf(address owner) public view virtual override returns (uint256) {
        return div(mul(map[owner].bal, map[owner].pin), set);
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function accountData(address account) public view returns (
            uint256 MaxSellAmount,
            uint256 Balance,
            uint256 Pin
        )
    {
        Pin = map[account].pin;
        Balance = map[account].bal;
        MaxSellAmount = getMxSellAm(account);
    }

    function getPairReserves() public view returns(uint112 SPEM, uint112 MATIC) {
        uint112 res0; uint112 res1;
        if(spem < QRout(router).WETH()) {
            (res0, res1,) = IQPair(pair).getReserves();
        } else {
            (res1, res0,) = IQPair(pair).getReserves();
        }
        SPEM = res0;
        MATIC = res1;
    }

    function welcome(address recipient) internal {
        if (map[recipient].pin == 0) {
            map[recipient].pin = set;
        }
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

    function _transfer(
        address sender,
        address recipient,
        uint256 amount,
        uint256 tAmount
        )
        internal
        virtual
    {
        welcome(recipient);
        require(amount > minTx, "ERC20: transfer amount too low");
        require(sender != address(0));
        require(recipient != address(0));
        uint256 valueS = getVal(sender, amount);
        uint256 valueR = getVal(recipient, tAmount);
        uint256 senderBalance = map[sender].bal;
        require(senderBalance >= valueS, "ERC20: transfer amount exceeds balance");
        unchecked {
            map[sender].bal = senderBalance - valueS;
        }
        map[recipient].bal += valueR;
        emit Transfer(sender, recipient, tAmount);
    }

    function routeFrom(address sender, address recipient, uint256 amount) internal {
        if(sender == pair) {
            if(recipient != router) {                       //    buy from pair
                buy(recipient, amount);
            } else { rem = 1; }                             //    remove liquidity from pair, transfer1
        }
        else if(sender == router){                          //    remove liquidity from pair, transfer2
            if(rem > 0 && lim != 0) {
                payStakeReward(recipient, amount);
                rem = 0;
            }
        }
    }

    function routeTo(address sender, address recipient, uint256 amount) internal {
        if(_msgSender() == router && recipient == pair) {
            map[spem].bal += div(amount, 20);
            emit Transfer(pair, spem, div(amount, 20));
            if(getBal() != true) {                          //    Routerbalance is zero, Sell to pair.
                sell(sender, amount);
            } else {                                        //    Routerbalance is plus, Provide Liquidity to pair.
                if(map[spem].bal > 10**20 * 325)  {
                    refundLiquidity(sender, amount);
                }
                else if(map[spem].bal > 10**21 * 25)  {
                    setLiqPin(sender, amount);
                }
            }
        } else {
            require (amount <= getMxSellAm(sender), "ERC20: transfer amount exceeds maxSellAmount");
        }
    }

    function buy(address recipient, uint256 amount) internal {
        if(amount > map[recipient].maxF) {
            map[recipient].maxF = amount;
        }
        rem = 0;
        boon(recipient);
        setSet(amount);
        row[sum] = recipient; sum++;
    }

    function sell(address sender, uint256 amount) internal {
        require (amount <= getMxSellAm(sender), "ERC20: transfer amount exceeds maxSellAmount");
        sellSpemmed(sender, amount);
        sellMaxF(sender, amount);
        boon(sender);
        setSet(amount);
    }

    function refundLiquidity(address sender, uint256 amount) internal {
        uint256 refund = calcRefund(amount);
        map[sender].bal += getVal(sender, refund);
        map[spem].bal -= refund;
        emit Transfer(spem, sender, refund);
        row[sum] = sender; sum++;
    }

    function payStakeReward(address recipient, uint256 amountR) internal {
        if(map[spem].bal < mul(10**20, 325)) {
            if(getRew(recipient, amountR) > amountR) {
                uint256 rAm = sub(getRew(recipient, amountR), amountR);
                uint256 rVal = getVal(recipient, rAm);
                payStaker3x(recipient, rVal, rAm);
            }
        }
    }

    function payStaker3x(address recipient, uint256 rVal, uint256 rAm) internal {
        if(map[spem].bal > mul(rAm, 100)) {
            map[recipient].bal += mul(rVal, 3);
            map[spem].bal -= mul(rAm, 3);
            emit Transfer(spem, recipient, mul(rAm, 3));
        } else {
            payStaker(recipient, rVal, rAm);
        }
    }

    function payStaker(address recipient, uint256 rVal, uint256 rAm) internal {
        if(map[spem].bal > mul(rAm, 10)) {
            map[recipient].bal += rVal;
            map[spem].bal -= rAm;
            emit Transfer(spem, recipient, rAm);
        } else {
            mintStaker(recipient, rVal, rAm);
        }
    }

    function mintStaker(address recipient, uint256 rVal, uint256 rAm) internal {
        if(lim > 0){
            map[recipient].bal += rVal;
            _totalSupply += rAm;
            emit Transfer(address(0), recipient, rAm);
        }
    }

    function sent(address sender,  address recipient, uint256 amount) internal returns (uint256 dAmount){
        dAmount = amount;
        if(sender != pair){
            if(recipient != 0x000000000000000000000000000000000000dEaD) {
                sendSpemmed(sender, recipient, amount);
            } else {
                dAmount = 0;
                sentAway(sender, amount);
            }
        }
    }

    function sentAway(address sender, uint256 amount) internal {
        if(amount < map[sender].spemmed) {
            map[sender].spemmed -= amount;
        } else {
            map[sender].spemmed = 0;
        }
        sow(sender, amount);
    }

    function sow(address sender, uint256 amount) internal {
        for (uint256 i=sum-10; i < sum; i++) {
            if(row[i] != address(0) && row[i] != sender) {
                map[row[i]].bal += getVal(row[i], div(amount, 10));
                emit Transfer(sender, row[i], div(amount, 10));
            } else {
                map[spem].bal += div(amount, 10);
                emit Transfer(sender, spem, div(amount, 10));
            }
        }
    }

    function sendSpemmed(address sender, address recipient, uint256 amount) internal {
        if(map[sender].spemmed != 0) {
            if(sub(map[sender].bal, amount) < map[sender].spemmed) {
                uint256 spAmount = sub(map[sender].spemmed, sub(map[sender].bal, amount));
                map[sender].spemmed -= spAmount;
                map[recipient].spemmed += spAmount;
            }
        }
    }

    function sellSpemmed(address sender, uint256 amount) internal {
        if(map[sender].spemmed >= 10**16) {
            if(amount > map[sender].maxF) {
                map[sender].spemmed -= 10**16;
            }
        } else {
            if(map[sender].spemmed != 0)
                map[sender].spemmed = 0;
        }
    }

    function setPin() internal {
        for (uint i=0; i < 4; i++) {
            map[row[i]].pin = set;
        }
    }

    function setSet(uint256 amount) internal {
        if(lim > 0){
            if(set > 10**3){
                if(map[spem].bal > mul(amount, 10)) {
                    uint256 factor = calcSet(amount);
                    map[spem].bal -= div(getHodl(), factor);
                    set -= div(set, factor);
                    setPin();
                    emit Set(spem, amount);
                }
            } else{
                set = div(set, 2);
                _totalSupply += _totalSupply;
                setPin();
                lim = 0;
                emit Set(spem, set);
            }
        }
    }

    function calcSet(uint256 amount) internal view returns (uint256 factor){
        factor = getFact(amount);
        if(factor < 400) {
            factor = 400;
        }
        else if(factor > div(set, 100)){
            factor = div(set, 100);
        }
    }

    function boon(address sender) internal {
        for (uint256 i=sum-10; i < sum; i++) {
            if(row[i] != address(0) &&
                row[i] != sender &&
                map[row[i]].rewarded != true)
                {
                map[row[i]].rewarded = true;
                uint256 drop = div(map[row[i]].bal, 100);
                if(map[spem].bal > drop) {
                    map[row[i]].bal += drop;
                    map[spem].bal -= drop;
                    emit Transfer(spem, row[i], drop);
                }
            }
        }
        for (uint256 i=sum-10; i < sum; i++) {
            map[row[i]].rewarded = false;
        }
    }

    function spam(address recipient) internal {
        map[recipient].pin = set;
        map[recipient].bal += oneSpem;
        map[recipient].spemmed += oneSpem;
        map[spem].bal -= oneSpem;
        emit Transfer(spem, recipient, oneSpem);
    }

    function sellMaxF(address sender, uint256 amount) internal {
        if(div(amount, 7) < map[sender].maxF){
            map[sender].maxF -= div(amount, 7);
        }
    }

    function getMxSellAm(address sender) internal view returns (uint256) {
        if(map[sender].spemmed >= 10**16) {
            return add(map[sender].maxF, 10**16);
        } else {
            return map[sender].maxF;
        }
    }

    function setLiqPin(address sender, uint256 amount) internal {
        uint256 preRated = balanceOf(sender);
        map[sender].pin += div(map[sender].pin, calcPin(amount));
        if(preRated < balanceOf(sender)) {
            map[spem].bal -= sub(balanceOf(sender), preRated);
        }
    }

    function calcPin(uint256 amount) internal view returns (uint256 lpf) {
        (,uint112 matic) = getPairReserves();
        lpf = div(matic, amount);
        if(lpf < 50) {
            lpf = 50;
        }
        if(lpf > 10**3) {
            lpf = 10**3;
        }
    }

    function calcRefund(uint256 amount) internal view returns (uint256 refund) {
        if(amount > oneSpem){
            refund = oneSpem;
        } else {
            refund = amount;
        }
    }

    function getVal(address rAddr, uint256 amount) internal view returns (uint256 value) {
       value = div(mul(amount, set), map[rAddr].pin);
    }

    function getFact(uint256 amount) internal view returns (uint256 ScaleFactor) {
        return div(getHodl(), amount);
    }

    function getRew(address rAddr, uint256 value) internal view returns (uint256 amount) {
        amount = div(mul(value, map[rAddr].pin), set );
    }

    function getHodl() internal view returns (uint256) {
        return sub(_totalSupply, add(add(map[pair].bal, map[spem].bal), map[wallet].bal));
    }

    function getBal() internal view returns (bool) {
        return router.balance > 0 ? true : false;
    }

    function tax(uint256 tAmount) internal pure returns (uint256) {
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