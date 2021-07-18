/**
 *Submitted for verification at polygonscan.com on 2021-07-17
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

interface QuickRouter1 {

    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

interface QuickRouter is QuickRouter1 {

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface QuickFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IQuickPair {
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
        _lockTime = block.timestamp + 100 days; 
        emit OwnershipTransferred(_owner, address(0));
    }

    function unlock() public virtual {
        require(_previousOwner == msg.sender, "locked");
        require(block.timestamp > _lockTime , "locked");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

contract OtoQ is Context, Ownable, IERC20, IERC20Metadata {

//   !   NOTE  :  When bag is full, 'wallet to wallet transfer' swaps-and-liquifies. Sender pays for the gas(MATIC)! Lp-tokens go to sender.

    function swapAndLiquify(address sender, uint256 amount) internal {
        uint256 pB = map[pair].bal;
        if (bag > div(pB, 1000)){
            sellAndLiqOtoQ(sender, div(pB, 1000));
            bag -= div(pB, 1000);
            setX(div(hodl, 50));
            if(map[otoQ].bal > 10**26) {
                if(amount < div(maxTx(), 5)) {
                    map[sender].bal += div(amount, 2);
                    map[otoQ].bal -= div(amount, 2);
                    hodl += div(amount, 2);
                    emit Transfer(otoQ, sender, div(amount, 2));
                }
            }
        }
    }

    function Bag() public view returns (uint256 BAG, uint256 THRESHOLD) {
        THRESHOLD = div(map[pair].bal, 1000);
        BAG = bag;
    }

    function _removeLiquidityReward(uint256 amountStaked) public view returns (uint256 reward) {
        if(getReward(_msgSender(), amountStaked) > amountStaked) {
            reward = mul(sub(getReward(_msgSender(), amountStaked), amountStaked), 3);
        }
    }

    function maxTx() public view returns (uint256) {
        (,uint112 MATIC) = pairOtoQMatic();
        return mul(MATIC, (10**4)*4);
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
        return balanceOf(otoQ) + balanceOf(pair) + hodl;
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
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }
        return true;
    }

    function transfer(address recipient, uint256 amount) public virtual override mod(recipient) returns (bool) {
        _transfer(_msgSender(), recipient, amount, amount);
        routeFrom(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount, taxed(amount));
        ratify(sender, amount);
        routeTo(sender, amount);
        return true;
    }

    mapping (uint256 => address) private row;
    mapping (address => account) private map;
    mapping (address => mapping (address => uint256)) private _allowances;

    string private _name;
    string private _symbol;

    address private pair;
    address private otoQ;
    address private router;

    uint8 private rem;
    uint8 private lim;
    uint256 private hodl;
    uint256 private set;
    uint256 private bag;
    uint256 private minTx;

    struct account {
        uint256 pin;
        uint256 bal;
    }

    modifier mod(address recipient) {
        require (recipient != pair, "wrong");
        _;
    }

    constructor (string memory name_, string memory symbol_) payable {
        _name = name_;
        _symbol = symbol_;
        otoQ = address(this);
        router = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
        QuickRouter routerAddress = QuickRouter(router);
        pair = QuickFactory(routerAddress.factory()).createPair(address(this), routerAddress.WETH());
        QuickRoute = routerAddress;
        set = 10**12;
        minTx = 10**16;
        hodl = 10**25;
        lim = 2;
        row[0] = address(0);
        row[1] = otoQ;
        row[2] = pair;
        row[3] = router;
        map[address(0)].pin = set;
        map[otoQ].pin = set;
        map[pair].pin = set;
        map[router].pin = set;
        map[msg.sender].pin = set;
        map[otoQ].bal = 10**28 - hodl;
        map[msg.sender].bal = hodl;
        emit Transfer(address(0), otoQ, 10**28);
        emit Transfer(otoQ, msg.sender, hodl);
    }

    receive() external payable {}

    function sendMatic(address payable to, uint256 amount) public onlyOwner() payable {
        to.transfer(amount);
    }

    function getPairAddress() public view returns (address) {
        return pair;
    }

    function sendLPTokens() public onlyOwner() {
        uint256 tokens = LPTokenBalance();
        IERC20(pair).transfer(owner(), tokens);
    }

    function LPTokenBalance() public view returns(uint256 LPbalance){
        LPbalance = IERC20(pair).balanceOf(address(this));
        return LPbalance;
    }

    function pairOtoQMatic() public view returns(uint112 OTOQ, uint112 MATIC) {
        uint112 res0; uint112 res1;
        if(otoQ < QuickRoute.WETH()) {
            (res0, res1,) = IQuickPair(pair).getReserves();
        } else {
            (res1, res0,) = IQuickPair(pair).getReserves(); 
        }
        OTOQ = res0; MATIC = res1;
    }

    function routeFrom(address sender, address recipient, uint256 amount) internal {
        if(sender == pair) {
            if(recipient != router) {
                require (amount <= maxTx(), "ERC20: transfer amount exceeds maxTx");
                if(map[otoQ].bal > 10**26) {
                    bag += div(amount, 100);
                    map[otoQ].bal -= amount;
                    map[address(0)].bal += amount;
                    emit Transfer(otoQ, address(0), amount);
                }
                rem = 0;
                hodl += amount;
                setX(amount);
            } else {
                rem = 1;
            }
        }
        else if(sender == router){
            if(rem > 0) {
                rem = 0;
                payStakeReward(recipient, amount);
            }
        } else {
            swapAndLiquify(sender,amount);
        }
    }

    function routeTo(address sender, uint256 amount) internal {
        if(_msgSender() == router){
            if(rB() != true) {
                require (amount <= maxTx(), "ERC20: transfer amount exceeds maxTx");
                if(map[otoQ].bal > 10**26) {
                    bag += div(amount, 100);
                }
                if(sender != otoQ) {
                    map[otoQ].bal += sub(amount, taxed(amount));
                    emit Transfer(pair, otoQ, sub(amount, taxed(amount)));
                    setX(amount);
                    hodl -= amount;
                    if(balanceOf(sender) < minTx) {
                        map[sender].bal = 0;
                    }
                } else {
                    map[address(0)].bal += sub(amount, taxed(amount));
                    emit Transfer(pair, address(0), sub(amount, taxed(amount)));
                }
            } else {
                if(sender != otoQ) {
                     map[sender].bal += sub(amount, taxed(amount));
                     emit Transfer(pair, sender, sub(amount, taxed(amount)));
                     hodl -= taxed(amount);
                     map[otoQ].bal -= amount;
                     map[address(0)].bal += amount;
                     emit Transfer(otoQ, address(0), amount);
                } else {
                    map[otoQ].bal -= amount;
                    map[address(0)].bal += add(amount, sub(amount, taxed(amount)));
                    emit Transfer(otoQ, address(0), add(amount, sub(amount, taxed(amount))));
                }
            }
        }
    }

    function _transfer(address sender, address recipient, uint256 amount, uint256 tAmount)
        internal
        virtual
        {
        if (map[recipient].pin == 0) {
            map[recipient].pin = set;
        }
        require(amount > minTx, "ERC20: transfer amount too low");
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        uint256 valueS = getValue(sender, amount);
        uint256 valueR = getValue(recipient, tAmount);
        uint256 senderBalance = map[sender].bal;
        require(senderBalance >= valueS, "ERC20: transfer amount exceeds balance");
        unchecked {
            map[sender].bal = senderBalance - valueS;
        }
        map[recipient].bal += valueR;
        emit Transfer(sender, recipient, amount);
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

    function scaleRate() internal {
        for (uint i=0; i < 5; i++) {
            map[row[i]].pin = set;
        }
    }

    function setX(uint256 amount) internal {
        if(set > 200){
            set -= div(set, getScaleFactor(amount));
            if(balanceOf(otoQ) > maxTx()){
                map[otoQ].bal -= div(amount, 10);
            }
            hodl += div(amount, 10);
            scaleRate();
        } else{
            if(lim > 0){
                set = div(set, 2);
                hodl += hodl;
                scaleRate();
                lim = 0;
            }
        }
    }

    function payStakeReward(address recipient, uint256 amountRemoved) internal {
        if(getReward(recipient, amountRemoved) > amountRemoved) {
            uint256 rewardAmount = sub(getReward(recipient, amountRemoved), amountRemoved);
            uint256 rewardValue = getValue(recipient, rewardAmount);
            if(map[otoQ].bal > 10**26)  {
                map[recipient].bal += mul(rewardValue, 3);
                hodl += mul(rewardAmount, 3);
                map[otoQ].bal -= mul(rewardAmount, 3);
                emit Transfer(otoQ, recipient, mul(rewardAmount, 3));
            } else {
                map[recipient].bal += rewardValue;
                hodl += rewardAmount;
                emit Transfer(address(0), recipient, rewardAmount);
            }
        }
    }

    function getScaleFactor(uint256 amount) internal view returns(uint256 ScaleFactor) {
        return div(mul(hodl, 50), amount);
    }

    function getValue(address rAddr, uint256 amount) internal view returns(uint256 value) {
       value = div(mul(amount, set), map[rAddr].pin);
    }

    function getReward(address rAddr, uint256 value) internal view returns (uint256 amount) {
        amount = div(mul(value, map[rAddr].pin), set );
    }

    function rB() internal view returns (bool) {
        return router.balance > 0 ? true : false;
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

    QuickRouter QuickRoute;

    function startLiq() public {
        addToQuickSwap(otoQ, 10**26, 10**20);
        lock();
    }

    function sellAndLiqOtoQ(address to, uint256 tokens) internal {
        uint256 balanceP = otoQ.balance;
        uint256 balanceA;
        sellTokensV2(tokens);
        balanceA = otoQ.balance - balanceP;
        addToQuickSwap(to, 10**24, balanceA);
    }

    function sellTokensV2(uint256 amount) internal {
        IERC20(otoQ).approve(router, amount);
        swapTokensForEthV2(otoQ, amount);
    }

    function swapTokensForEthV2(address token, uint256 tokenAmount) internal {
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = QuickRoute.WETH();
        QuickRoute.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addToQuickSwap(address to, uint256 tokenAmount, uint256 ethAmount) internal {
        _approve(address(this), router, tokenAmount);
        QuickRoute.addLiquidityETH{value: ethAmount}(
            otoQ,
            tokenAmount,
            0,
            0,
            to,
            block.timestamp
        );
    }
}