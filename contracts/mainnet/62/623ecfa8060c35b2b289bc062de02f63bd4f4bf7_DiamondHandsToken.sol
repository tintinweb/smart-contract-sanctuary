/**
 *Submitted for verification at Etherscan.io on 2021-05-11
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;
// pragma experimental SMTChecker;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

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

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

contract DiamondHandsToken is ERC20("DiamondHands", unicode"💎🙌") {
    //// constants

    // balance has to be 100 tokens to become a diamond member who can:
    // - invite people and get bonus from their purchases
    // - buy extra tokens cheaper
    uint256 constant MINIMUM_DIAMOND_MEMBER_BALANCE = 100 * 1e18;
    // diamond members get 20% discount on purchases above 100 tokens
    uint256 constant DIAMOND_MEMBER_PURCHASE_PRICE_DISCOUNT_PER_THOUSAND = 200;
    // diamond members get 10% extra bonus tokens from people they invited, 
    // until those become diamond members themselves
    uint256 constant DIAMOND_MEMBER_INTRODUCER_BONUS_TOKENS_PER_THOUSAND = 100;
    // invited people get 10% discount on purchases,
    // until they become diamond members and get 20% diamond discount
    uint256 constant INVITED_PURCHASE_PRICE_DISCOUNT_PER_THOUSAND = 100;

    // Price growth
    // - the price grows 5% upon every iteration
    // - new iteration lasts 30-90 minutes and starts:
    //   * either after 100 tokens were bought in the current iteration (fast growth due to popularity),
    //   * or, if somebody buys or sells tokens after 90 minutes of no growth (slow growth)

    // initial token price is 0.001 ETH per token
    uint256 constant INITIAL_PRICE_ETH_WEI = 1e15;
    // for non-diamond and non-invited members the purchase price is sell price + 80%
    uint256 constant PURCHASE_PRICE_MILTIPLIER_PER_THOUSAND = 1800;
    // price grows 5% each iteration
    uint256 constant PRICE_GROWTH_MULTIPLIER_PER_THOUSAND = 1050;
    // maximum speed that the price can grow is once per 30 minutes
    uint256 constant MINIMUM_GROWTH_ITERATION_PERIOD = 30 minutes;
    // after 90 minutes of no growth (low activity), the price will still grow
    uint256 constant SLOW_GROWTH_ITERATION_PERIOD = 90 minutes;
    // at least 100 tokens have to be sold for fast growth
    uint256 constant FAST_GROWTH_THRESHOLD = 100 * 1e18;
    
    //// events
    event NewPrice(uint256 timestamp, uint256 newPrice);

    //// state
    mapping (address => address) private _introducers;
    uint256 private _sellPriceEthWei;
    uint256 private _lastPriceGrowthTimestamp;
    uint256 private _purchasedTokensForFastGrowthSoFar = 0;
    
    //// private
    constructor() payable {
        emit NewPrice(
            _lastPriceGrowthTimestamp = block.timestamp,
            _sellPriceEthWei = INITIAL_PRICE_ETH_WEI
            );
        // no pre-mine
    }

    function _isDiamondMember(address member) private view returns(bool) {
        return balanceOf(member) >= MINIMUM_DIAMOND_MEMBER_BALANCE;
    }
    function _registerUnderIntroducer(address introducer) private {
        require(msg.sender != introducer,
            "Members cannot introduce themselves");
        require(_introducers[msg.sender] == address(0) || _introducers[msg.sender] == introducer, 
            "Introducer cannot be changed later");
        require(_isDiamondMember(introducer), 
            "Provided introducer address is not a Diamond member at this moment");
        _introducers[msg.sender] = introducer;
    }
    function _growIfAccumulatedEnough(uint256 amountBought) private {
        // check if we should make the price grow
        uint256 accumulated = _purchasedTokensForFastGrowthSoFar + amountBought;
        uint256 lastPriceGrowthTimestamp = _lastPriceGrowthTimestamp;
        uint256 blockTimestamp = block.timestamp;
        if (
            // fast growth condition
            (accumulated > FAST_GROWTH_THRESHOLD
            && (lastPriceGrowthTimestamp + MINIMUM_GROWTH_ITERATION_PERIOD) <= blockTimestamp)
            ||
            // slow growth condition
            (lastPriceGrowthTimestamp + SLOW_GROWTH_ITERATION_PERIOD) <= blockTimestamp
            ) {
            // start new iteration with new price
            _purchasedTokensForFastGrowthSoFar = 0;
            emit NewPrice(
                _lastPriceGrowthTimestamp = blockTimestamp,
                _sellPriceEthWei = _sellPriceEthWei * PRICE_GROWTH_MULTIPLIER_PER_THOUSAND / 1000
                );
        }
        else {
            _purchasedTokensForFastGrowthSoFar = accumulated;
        }
    }
    function _sell(uint256 amount) private {
        uint256 sellPriceEthWei = _sellPriceEthWei;
        _growIfAccumulatedEnough(0);
        _burn(msg.sender, amount);
        payable(msg.sender).transfer(amount * sellPriceEthWei / 1e18);
    }
    function _buy(uint256 ethWeiAmount) private {
        uint256 sellPriceEthWei = _sellPriceEthWei;
        uint256 amountBought = 0;
        uint256 myBalance = balanceOf(msg.sender);
        address introducer = _introducers[msg.sender];

        // if not a diamond member yet, buy at non-diamond price
        if (myBalance < MINIMUM_DIAMOND_MEMBER_BALANCE) {
            uint256 nonDiamondBuyPriceInEthWei = 
                introducer != address(0) 
                    // if we have an introducer, get a discounted price
                    ? (sellPriceEthWei * PURCHASE_PRICE_MILTIPLIER_PER_THOUSAND * (1000 - INVITED_PURCHASE_PRICE_DISCOUNT_PER_THOUSAND) 
                        / (1000 * 1000))
                    // else get a normal price
                    : (sellPriceEthWei * PURCHASE_PRICE_MILTIPLIER_PER_THOUSAND / 1000);
            uint256 amountAtThisPrice = ethWeiAmount * 1e18 / nonDiamondBuyPriceInEthWei;

            // if didn't become a diamond member while buying
            if (myBalance + amountAtThisPrice <= MINIMUM_DIAMOND_MEMBER_BALANCE) {
                // buy the whole amount
                amountBought = amountAtThisPrice;
                ethWeiAmount = 0;
            }
            else {
                // buy just enough to become a diamond member, and buy the rest at diamond price
                amountBought = MINIMUM_DIAMOND_MEMBER_BALANCE - myBalance;
                ethWeiAmount -= amountBought * nonDiamondBuyPriceInEthWei / 1e18;
            }
        }

        // if still have money at this point, buy at diamond price
        if (ethWeiAmount > 0) {
            uint256 diamondBuyPriceInEthWei = 
                (sellPriceEthWei * PURCHASE_PRICE_MILTIPLIER_PER_THOUSAND * (1000 - DIAMOND_MEMBER_PURCHASE_PRICE_DISCOUNT_PER_THOUSAND) 
                        / (1000 * 1000));
            amountBought += ethWeiAmount * 1e18 / diamondBuyPriceInEthWei;
        }

        // grow the price
        _growIfAccumulatedEnough(amountBought);
        // mint the tokens
        _mint(msg.sender, amountBought);
        // mint tokens for the introducer
        if (introducer != address(0)) {
            _mint(introducer, amountBought * DIAMOND_MEMBER_INTRODUCER_BONUS_TOKENS_PER_THOUSAND / 1000);
        }
    }

    //// view
    function haveIntroducer() public view returns(bool) { return _introducers[msg.sender] != address(0); }
    function amDiamondMember() public view returns(bool) { return _isDiamondMember(msg.sender); }
    function getSellPrice() public view returns(uint256) { return _sellPriceEthWei; }
    function getBasicBuyPrice() public view returns(uint256) {
        return _sellPriceEthWei * PURCHASE_PRICE_MILTIPLIER_PER_THOUSAND / 1000;
    }
    function getBuyPriceWithMyDiscounts() public view returns(uint256) {
        if (_isDiamondMember(msg.sender)) {
            return 
                _sellPriceEthWei * PURCHASE_PRICE_MILTIPLIER_PER_THOUSAND * (1000 - DIAMOND_MEMBER_PURCHASE_PRICE_DISCOUNT_PER_THOUSAND) 
                / (1000 * 1000);
        }
        else if (_introducers[msg.sender] != address(0)) {
            return
                _sellPriceEthWei * PURCHASE_PRICE_MILTIPLIER_PER_THOUSAND * (1000 - INVITED_PURCHASE_PRICE_DISCOUNT_PER_THOUSAND) 
                / (1000 * 1000);
        }
        else {
            return _sellPriceEthWei * PURCHASE_PRICE_MILTIPLIER_PER_THOUSAND / 1000;
        }
    }
    function getTokensBoughtAfterLastGrowth() public view returns(uint256) { return _purchasedTokensForFastGrowthSoFar; }
    function getUiState() public view returns(
        uint256 secondsElapsed, 
        uint256 tokensSold, 
        uint256 sellPrice, 
        uint256 buyPriceBasic, 
        uint256 buyPricePersonal, 
        uint256 balance, 
        bool invited, 
        bool diamond) {
        return (
            block.timestamp - _lastPriceGrowthTimestamp,
            _purchasedTokensForFastGrowthSoFar,
            _sellPriceEthWei,
            getBasicBuyPrice(),
            getBuyPriceWithMyDiscounts(),
            balanceOf(msg.sender),
            haveIntroducer(),
            amDiamondMember()
            );
    }

    //// callable from outside
    function totalSupply() public view virtual override returns (uint256) {
        return address(this).balance * 1e18 / _sellPriceEthWei;
    }
    function buy() external payable {
        require(msg.value > 0,
            "Please send ETH to purchase tokens");
        _buy(msg.value);
    }
    function buyAndRegisterUnderIntroducer(address introducer) external payable {
        require(msg.value > 0,
            "Please send ETH to purchase tokens");
        require(introducer != address(0),
            "Please specify an introducer to register under");
        _registerUnderIntroducer(introducer);
        _buy(msg.value);
    }
    function sell(uint256 amount) external {
        require(amount > 0,
            "Please provide the amount of tokens to sell");
        _sell(amount);
    }
    function sellAll() external {
        uint256 balance = balanceOf(msg.sender);
        require(balance > 0,
            "You don't have any tokens to sell");
        _sell(balance);
    }
}