/**
 *Submitted for verification at BscScan.com on 2021-08-13
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IPair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function token0() external view returns (address);

    function token1() external view returns (address);
}

interface IRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function createPair(address tokenA, address tokenB) external returns (address pair);
}
pragma solidity ^0.8.0;

abstract contract Common {
    address public ZERO = 0x0000000000000000000000000000000000000000;
    address public ONE = 0x0000000000000000000000000000000000000001;
    address public DEAD = 0x000000000000000000000000000000000000dEaD;

    function toWei(uint256 amount) public pure returns (uint256) {
        return amount * 1E18;
    }
}
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}
pragma solidity ^0.8.0;

abstract contract Access is Context {
    mapping(address => bool) accessor;
    address accessorAdmin;
    modifier accessed() {
        require(isAccessable(_msgSender()), "access valid");
        _;
    }
    constructor() {accessorAdmin = _msgSender();}
    function grantAccess(address addr) public accessed {if (!isAccessable(addr)) accessor[addr] = true;}

    function revokeAccess(address addr) public accessed {if (isAccessable(addr)) accessor[addr] = false;}

    function isAccessable(address addr) internal view returns (bool) {return accessor[addr] || _msgSender() == accessorAdmin;}

    function isAccessable() internal view returns (bool) {return isAccessable(_msgSender());}
}
pragma solidity ^0.8.0;

abstract contract DynamicRate is Common, Access {
    struct DynamicRateBox {
        uint256 rate;
        uint256 lowest;
        uint256 highest;
    }

    mapping(uint256 => DynamicRateBox) public DynamicBuyRateConfig;
    mapping(uint256 => DynamicRateBox) public DynamicSellRateConfig;
    uint256 maxBuyLevel;
    uint256 maxSellLevel;
    IPair private pair;
    IRouter private router;

    function updateIPair2(IPair pair_) public accessed {pair = pair_;}

    function updateIRouter2(IRouter router_) public accessed {router = router_;}

    function updateDynamicBuyRateConfig(uint256 level, uint256 rate, uint256 lowest, uint256 highest) public accessed {
        DynamicBuyRateConfig[level] = DynamicRateBox(rate, lowest, highest);
        if (maxBuyLevel < level) maxBuyLevel = level;
    }

    function updateDynamicSellRateConfig(uint256 level, uint256 rate, uint256 lowest, uint256 highest) public accessed {
        DynamicSellRateConfig[level] = DynamicRateBox(rate, lowest, highest);
        if (maxSellLevel < level) maxSellLevel = level;
    }

    function getDynamicBuyRate() public view returns (uint256) {return getDynamicRate(true);}

    function getDynamicSellRate() public view returns (uint256) {return getDynamicRate(false);}

    function getDynamicRate(bool isBuy) private view returns (uint256) {
        (uint112 _reserve0, uint112 _reserve1,) = pair.getReserves();
        uint112 WDynamicRealtimeAmountInPool = _reserve1;
        if (pair.token0() == router.WETH()) {WDynamicRealtimeAmountInPool = _reserve0;}
        uint level = maxSellLevel;
        if (isBuy) level = maxBuyLevel;
        for (uint8 i = 0; i <= level; i++) {
            if (isBuy) {
                if (DynamicBuyRateConfig[i].lowest <= WDynamicRealtimeAmountInPool && WDynamicRealtimeAmountInPool < DynamicBuyRateConfig[i].highest) {
                    return DynamicBuyRateConfig[i].rate;
                }
            } else {
                if (DynamicSellRateConfig[i].lowest <= WDynamicRealtimeAmountInPool && WDynamicRealtimeAmountInPool < DynamicSellRateConfig[i].highest) {
                    return DynamicSellRateConfig[i].rate;
                }
            }
        }
        return 10000;
    }
}
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
pragma solidity ^0.8.0;



interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}
pragma solidity ^0.8.0;

contract ERC20 is Context, IERC20, IERC20Metadata, Access {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
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

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(sender, recipient, amount);
        _move(sender, recipient, amount);
        _afterTokenTransfer(sender, recipient, amount);
    }

    function _move(address sender, address recipient, uint256 amount) internal virtual {
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    function rescueLossToken(IERC20 token_, address _recipient) public accessed {token_.transfer(_recipient, token_.balanceOf(address(this)));}

    function rescueLossChain(address payable _recipient) public accessed {_recipient.transfer(address(this).balance);}
}
pragma solidity ^0.8.0;

contract FeeHandler is Common, Access, ERC20 {
    struct Fee {
        bool exists;
        uint256 feeName;
        uint256 percent;
        address feeTo;
        uint256 remainMinTotalSupply;
    }

    mapping(uint256 => Fee) public feeConfig;
    uint256[] public feeNames;
    mapping(address => bool) _noFee;
    constructor(
        string memory name_,
        string memory symbol_
    ) ERC20(name_, symbol_) {}
    function noFee(address addr, bool noFee_) public accessed {
        _noFee[addr] = noFee_;
    }

    function ifNoFee(address addr) public view returns (bool) {
        return _noFee[addr];
    }

    function updateFeeConfig(uint256 feeName, uint256 percent, address feeTo, uint256 remainMinTotalSupply) public accessed {
        if (!feeConfig[feeName].exists) {
            feeNames.push(feeName);
        }
        feeConfig[feeName] = Fee(true, feeName, percent, feeTo, remainMinTotalSupply);
    }

    function _processAllFees(address from, uint256 amount) internal virtual {
        if (!ifNoFee(from)) {
            _handAllFees(from, amount);
        }
    }

    function _handAllFees(address from, uint256 amount) private {
        uint256 amountLeft = amount;
        for (uint8 i = 0; i < feeNames.length; i++) {
            if (amountLeft == 0) break;
            uint256 fee = amount * feeConfig[feeNames[i]].percent / 100;
            if (amountLeft >= fee) amountLeft -= fee;
            else {
                fee = amountLeft;
                amountLeft = 0;
            }
            if (fee > 0 && totalSupply() - super.balanceOf(DEAD) > feeConfig[feeNames[i]].remainMinTotalSupply) {
                super._move(from, feeConfig[feeNames[i]].feeTo, fee);
            }
        }
    }
}
pragma solidity ^0.8.0;

abstract contract FeeETH is Access {
    uint256 internal swapETHTokenThreshold = 1E6 * 1E18;
    IRouter private router;

    function updateIRouter3(IRouter router_) public accessed {
        router = router_;
    }

    function updateSwapETHTokenThreshold(uint256 swapETHTokenThreshold_) public accessed {
        swapETHTokenThreshold = swapETHTokenThreshold_;
    }

    function _processETHFee(uint256 tokenAmount) internal view returns (bool) {
        return tokenAmount >= swapETHTokenThreshold;
    }

    function swapTokensForEth(IERC20 token, uint256 tokenAmount) internal {

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        token.approve(address(router), tokenAmount);

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
}
pragma solidity ^0.8.0;

abstract contract FeeFOMO is Access {
    struct FOMOR {
        address user;
        uint256 amount;
        uint256 time;
    }

    FOMOR public lastBuyer;
    FOMOR public currentBuyer;
    uint256 internal fomoDuration = 4 hours;

    function updateFomoDuration(uint256 fomoDuration_) public accessed {
        fomoDuration = fomoDuration_;
    }

    function _recordBuyerForFOMO(address addr, uint256 amount) internal {
        lastBuyer = currentBuyer;
        currentBuyer = FOMOR(addr, amount, block.timestamp);
    }

    function _processFOMO() internal view returns (bool) {
        return currentBuyer.time - lastBuyer.time > fomoDuration;
    }
}
pragma solidity ^0.8.0;

abstract contract FeePrize is Access {
    struct Prize {
        address user;
        uint256 amount;
    }

    mapping(uint256 => Prize) internal lastUsersForRewardPrize;
    uint256 internal lastUsersAmountForRewardThePrize;
    uint256 public tickerForRewardPrize;
    uint256 private rewardTimeDurationBase;
    uint256 internal nextRewardTime;
    constructor() {
        updateLastUsersAmountForRewardThePrize(6);
        _updateRewardTimeDurationBase(30 minutes);
    }

    function updateRewardTimeDurationBase(uint256 second) public accessed {
        _updateRewardTimeDurationBase(second);
    }

    function updateLastUsersAmountForRewardThePrize(uint256 lastUsersAmountForRewardThePrize_) public accessed {
        lastUsersAmountForRewardThePrize = lastUsersAmountForRewardThePrize_;
    }

    function _updateRewardTimeDurationBase(uint256 second) internal {
        rewardTimeDurationBase = second;
        _updateNextRewardTime();
    }

    function _updateNextRewardTime() internal {
        nextRewardTime = block.timestamp + rewardTimeDurationBase + (block.timestamp % 1 hours);

        for (uint256 i = 0; i < lastUsersAmountForRewardThePrize; i++) {
            delete lastUsersForRewardPrize[i];
        }
    }

    function _recordBuyerForRewardPrize(address addr, uint256 amount) internal {
        lastUsersForRewardPrize[tickerForRewardPrize % lastUsersAmountForRewardThePrize] = Prize(addr, amount);
        tickerForRewardPrize++;
    }

    function _calcCurrentUsersAmount() internal view returns (uint256) {
        uint256 amount;
        for (uint8 i = 0; i < lastUsersAmountForRewardThePrize; i++) {
            amount += lastUsersForRewardPrize[i].amount;
        }
        return amount;
    }
}
pragma solidity ^0.8.0;

contract SpecialFee is FeeHandler, FeeETH, FeeFOMO, FeePrize {
    enum SF {rate4ClaimETH, rate4FOMO, rate4Prize}
    mapping(SF => uint256) public specialFeePool;

    event RewardedPrize(address user, uint256 amount);
    event RewardedFOMO(address user, uint256 amount);
    constructor(
        string memory name_,
        string memory symbol_
    ) FeeHandler(name_, symbol_) {}

    function _recordSpecialFee(uint256 amount) internal {
        uint256 feeETH = amount * feeConfig[uint256(SF.rate4ClaimETH)].percent / 100;
        if (feeETH > 0) specialFeePool[SF.rate4ClaimETH] += feeETH;
        uint256 feeFOMO = amount * feeConfig[uint256(SF.rate4FOMO)].percent / 100;
        if (feeFOMO > 0) specialFeePool[SF.rate4FOMO] += feeFOMO;
        uint256 feePrize = amount * feeConfig[uint256(SF.rate4Prize)].percent / 100;
        if (feePrize > 0) specialFeePool[SF.rate4Prize] += feePrize;
    }

    function _processAllFees(address from, uint256 amount) internal virtual override {
        if (!ifNoFee(from)) {
            _recordSpecialFee(amount);
            super._processAllFees(from, amount);
        }
    }

    function _beforeProcessSpecialFee(address addr, uint256 amount) internal {

        super._recordBuyerForFOMO(addr, amount);
        super._recordBuyerForRewardPrize(addr, amount);
    }

    function _processSpecialFee() internal {

        _handETH();

        _handPrize();

        _handFOMO();
    }

    function _handETH() internal {
        if (super._processETHFee(specialFeePool[SF.rate4ClaimETH])) {
            super.swapTokensForEth(IERC20(address(this)), specialFeePool[SF.rate4ClaimETH]);
            specialFeePool[SF.rate4ClaimETH] = 0;
        }
    }

    function _handPrize() internal {
        if (block.timestamp > nextRewardTime) {
            uint256 prizePool = specialFeePool[SF.rate4Prize];
            if (prizePool > 0) {
                uint256 userTotalAmount = super._calcCurrentUsersAmount();
                for (uint8 i = 0; i < lastUsersAmountForRewardThePrize; i++) {
                    address user = lastUsersForRewardPrize[i].user;
                    uint256 amount = lastUsersForRewardPrize[i].amount;
                    uint256 prizeAmount = prizePool * amount / userTotalAmount;
                    super._move(address(this), user, prizeAmount);
                    emit RewardedPrize(user, prizeAmount);
                }
                super._updateNextRewardTime();
            }
        }
        specialFeePool[SF.rate4Prize] = 0;
    }

    function _handFOMO() internal {
        if (super._processFOMO()) {
            uint256 prizePool = specialFeePool[SF.rate4FOMO];
            if (prizePool > 0) {
                uint256 thisBalance = super.balanceOf(address(this)) - specialFeePool[SF.rate4FOMO] - specialFeePool[SF.rate4FOMO];

                if (prizePool > thisBalance) prizePool = thisBalance;
                super._move(address(this), lastBuyer.user, prizePool);
                specialFeePool[SF.rate4FOMO] = 0;
                emit RewardedFOMO(lastBuyer.user, prizePool);
            }
        }
    }
}
pragma solidity ^0.8.0;

contract ClaimETH is SpecialFee {
    event ClaimedETH(address benifeciary, uint256 bnbAmount);

    struct Schedule {
        uint256 startTime;
        uint256 nextTime;
        uint256 lowestAmount;
    }

    uint256 claimETHDuration = 3 days;
    uint256 startTime;
    mapping(address => Schedule) claimETHSchedule;
    constructor(
        string memory name_,
        string memory symbol_
    ) SpecialFee(name_, symbol_) {
        startTime = block.timestamp + claimETHDuration;
    }
    function updateClaimETHDuration(uint256 duration) public accessed {
        claimETHDuration = duration;
    }

    function _updateClaimETHSchedule(address addr) internal {
        claimETHSchedule[addr].startTime = block.timestamp;
        claimETHSchedule[addr].nextTime = block.timestamp + claimETHDuration;
        _updateClaimableAmount(addr);
    }

    function _updateClaimableAmount(address addr) internal {
        if (claimETHSchedule[addr].startTime == 0) _updateClaimETHSchedule(addr);
        if (claimETHSchedule[addr].lowestAmount > super.balanceOf(addr)) claimETHSchedule[addr].lowestAmount = super.balanceOf(addr);
    }

    function claimETH() external {
        if (block.timestamp > startTime && block.timestamp > claimETHSchedule[_msgSender()].nextTime) {
            uint256 earnETH = getClaimableETH(_msgSender());
            if (earnETH > 0) {
                payable(_msgSender()).transfer(earnETH);
                _updateClaimETHSchedule(_msgSender());
                emit ClaimedETH(_msgSender(), earnETH);
            }
        }
    }

    function getClaimableETH(address addr) public view returns (uint256) {
        uint256 totalETH = address(this).balance;
        uint256 rate = claimETHSchedule[addr].lowestAmount * 1E18 / super.totalSupply();
        return totalETH * rate / 1E18;
    }

    function getClaimableDuration(address addr) public view returns (uint256) {
        if (claimETHSchedule[addr].nextTime == 0) return 0;
        else if (claimETHSchedule[addr].nextTime <= block.timestamp) return 0;
        else return claimETHSchedule[addr].nextTime - block.timestamp;
    }
}
pragma solidity ^0.8.0;

contract BotKiller is Access {
    mapping(address => bool) botList;
    uint256 private duration;

    function markBot(address addr, bool b) public accessed {botList[addr] = b;}

    function isBot(address addr) internal view returns (bool) {return botList[addr];}
}
pragma solidity ^0.8.0;

contract Token is Common, DynamicRate, ClaimETH, BotKiller {
    uint256 _totalSupply = 1E34;
    address public pair;
    address fund;
    IRouter router;
    bool isStartSwap;
    constructor() ClaimETH("GhostFeg", "GOF") {
        initIRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);

        super.noFee(address(this), true);
        super.noFee(_msgSender(), true);
        super.noFee(DEAD, true);
        super.noFee(ZERO, true);
        super.noFee(ONE, true);

        super.updateDynamicSellRateConfig(0, 40, 0, toWei(300));
        super.updateDynamicSellRateConfig(1, 30, toWei(300), toWei(600));
        super.updateDynamicSellRateConfig(2, 20, toWei(600), toWei(1200));
        super.updateDynamicSellRateConfig(3, 10, toWei(1200), toWei(2400));
        super.updateDynamicSellRateConfig(4, 5, toWei(2400), ~uint256(0));
        super.updateDynamicBuyRateConfig(0, 5, 0, toWei(300));
        super.updateDynamicBuyRateConfig(1, 10, toWei(300), toWei(600));
        super.updateDynamicBuyRateConfig(2, 20, toWei(600), toWei(1200));
        super.updateDynamicBuyRateConfig(3, 30, toWei(1200), toWei(2400));
        super.updateDynamicBuyRateConfig(4, 40, toWei(2400), ~uint256(0));

        super.updateFeeConfig(0, 20, address(this), 0);
        super.updateFeeConfig(1, 20, address(this), 0);
        super.updateFeeConfig(2, 40, address(this), 0);
        super.updateFeeConfig(11, 10, DEAD, 1E27);
        super.updateFeeConfig(12, 10, fund, 0);
        super._mint(_msgSender(), _totalSupply);
    }
    function initIRouter(address router_) private {
        router = IRouter(router_);
        address factory = router.factory();
        pair = IFactory(factory).createPair(address(this), router.WETH());
        super.updateIPair2(IPair(pair));
        super.updateIRouter2(router);
        super.updateIRouter3(router);
        super.noFee(pair, true);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        if (!isStartSwap) require(pair != from && pair != to, "swap not start");
        require(!super.isBot(from) && !super.isBot(to), "forbid");
        super._beforeTokenTransfer(from, to, amount);
    }

    function startSwap() external accessed {
        isStartSwap = true;
    }

    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        if (amount > 0) {
            if (!super.ifNoFee(from)) {
                uint256 fees = amount * super.getDynamicSellRate() / 100;
                super._processAllFees(from, fees);
            }
            if (!super.ifNoFee(to)) {
                uint256 fees = amount * super.getDynamicBuyRate() / 100;
                super._processAllFees(to, fees);
            }
            if (pair == from) {
                super._beforeProcessSpecialFee(to, amount);
            }
            super._processSpecialFee();
        }

        super._updateClaimableAmount(from);
        super._updateClaimableAmount(to);
        super._afterTokenTransfer(from, to, amount);
    }
}