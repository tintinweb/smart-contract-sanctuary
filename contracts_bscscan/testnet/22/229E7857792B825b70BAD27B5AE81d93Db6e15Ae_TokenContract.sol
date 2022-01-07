pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier:MIT

interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IdexFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IdexPair {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}

interface IdexRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract Ownable is Context {
    address payable private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = payable(_msgSender());
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = payable(address(0));
    }

    function transferOwnership(address payable newOwner)
        public
        virtual
        onlyOwner
    {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// Protocol by team BloctechSolutions.com

contract TokenContract is Context, IBEP20, Ownable {
    string private _name = "New Token"; // token name
    string private _symbol = "NT"; // token symbol
    uint8 private _decimals = 9; // token decimal
    uint256 private _totalSupply = 1 * 1e11 * 1e9; // token supply

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _whiteList;
    mapping(address => bool) private _blackList;
    mapping(address => bool) private _greyList;

    IdexRouter public dexRouter;
    address public dexPair;
    address public address1;
    address public address2 = address1;
    address public address3 = address1;

    bool public swapAndLiquifyStatus; // should be true to turn on to liquidate the pool
    bool public feeStatus = true; // should be true to turn on tax fee
    bool public sellLimitValid = true; // should be true to turn on sell count validation
    bool public priceLimitValid = true; // should be true to turn on price drop validation
    bool public tradingOpen; //once switched on, can never be switched off.
    bool public contractStatus; //to pause contract

    uint256 public lpFee = 40; // 4% will be added to the liquidity pool
    uint256 public fee1 = 20; // 2% will go to the lottery pool
    uint256 public fee2 = 20; // 2% will go to the market address
    uint256 public fee3 = 20; // 2% will go to the Dead address to deflate NT

    uint256 public launchTime; // can be set only once
    uint256 public lastSellTime; // set after every 24 hours
    uint256 public sellCoolDownDuration = 24 hours; // selling will be reset after this time
    uint256 public sellCount; // count the number of sell tx per day
    uint256 public maxSellCount = 20; // max sell tx 20 per day
    uint256 public declinedPricePercent = 200; // stop selling if price declined more then 20%
    uint256 public lastClosingPrice; // last day closing price of token
    uint256 public additionalFee = 200; // 20% additional fee for the grey list user
    uint256 public minTokenNumberToSell = _totalSupply / (100000); // 0.001% max tx amount will trigger swap and add liquidity
    uint256 public maxBuyAmount = _totalSupply / (100); // should be 1% percent per transaction
    uint256 public maxSellAmount = _totalSupply * (5) / (1000); // should be 0.5% percent per transaction
    uint256 public maxHoldAmount = _totalSupply / (100); // should be 1% percent per transaction
    uint256 public divider = 1000;

    event SwapAndLiquifyStatusUpdated(bool enabled);
    event contractStatusUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    constructor(address payable _address1) {
        _balances[owner()] = _totalSupply;
        address1 = _address1;

        IdexRouter _dexRouter = IdexRouter(
            0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
        );
        // Create a dex pair for this new token
        dexPair = IdexFactory(_dexRouter.factory()).createPair(
            address(this),
            _dexRouter.WETH()
        );

        // set the rest of the contract variables
        dexRouter = _dexRouter;

        //exclude owner and this contract from fee
        _whiteList[owner()] = true;
        _whiteList[address(this)] = true;

        emit Transfer(address(0), owner(), _totalSupply);
    }

    //to receive BNB from dexRouter when swapping
    receive() external payable {}

    function name() public view returns (string memory) {
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

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()] - (amount)
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + (addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] - (subtractedValue)
        );
        return true;
    }

    function isUserWhiteListed(address account) public view returns (bool) {
        return _whiteList[account];
    }

    function isUserBlackListed(address account) public view returns (bool) {
        return _blackList[account];
    }

    function isUserGreyListed(address account) public view returns (bool) {
        return _greyList[account];
    }

    // admin setter functions

    function setMaxBuyAmount(uint256 _amount) public onlyOwner {
        maxBuyAmount = _amount;
    }
    function setMaxSellAmount(uint256 _amount) public onlyOwner {
        maxSellAmount = _amount;
    }
    function setMaxHoldAmount(uint256 _amount) public onlyOwner {
        maxHoldAmount = _amount;
    }

    function setMinTokenNumberToSell(uint256 _amount) public onlyOwner {
        minTokenNumberToSell = _amount;
    }

    function includeOrExcludeFromWhiteList(address account, bool _state)
        public
        onlyOwner
    {
        _whiteList[account] = _state;
    }

    function includeOrExcludeFromGreyList(address account, bool _state)
        public
        onlyOwner
    {
        _greyList[account] = _state;
    }

    function includeOrExcludeFromBlackList(address account, bool _state)
        public
        onlyOwner
    {
        _blackList[account] = _state;
    }
    function enableOrDisableFees(bool _state) external onlyOwner {
        feeStatus = _state;
    }
    
    function enableOrDisableSellLimit(bool _state) external onlyOwner {
        sellLimitValid = _state;
    }
     function enableOrDisablePriceLimit(bool _state) external onlyOwner {
        priceLimitValid = _state;
    }
    function setTaxFeePercent(
        uint256 _lpFee,
        uint256 _fee1,
        uint256 _fee2,
        uint256 _fee3
    ) external onlyOwner {
        lpFee = _lpFee;
        fee1 = _fee1;
        fee2 = _fee2;
        fee3 = _fee3;
    }

    function setSellCoolDownDuration(bool _state, uint256 _duration, uint256 _count) external onlyOwner {
        sellLimitValid = _state;
        sellCoolDownDuration = _duration;
        maxSellCount = _count;
    }

    function setPriceLimit(uint256 _maxBuyAmount) external onlyOwner {
        maxBuyAmount = _maxBuyAmount;
    }

    function startTrading() external onlyOwner {
        tradingOpen = true;
        launchTime = block.timestamp;
        lastSellTime = block.timestamp;
        swapAndLiquifyStatus = true;
        emit SwapAndLiquifyStatusUpdated(true);
    }

    function setSwapAndLiquifyStatus(bool _state) public onlyOwner {
        swapAndLiquifyStatus = _state;
        emit SwapAndLiquifyStatusUpdated(_state);
    }

    function ContractStatus(bool _status)public onlyOwner{
        contractStatus = _status;
        emit contractStatusUpdated(_status);
    }

    function setAddress1(address _address)
        external
        onlyOwner
    {
        address1 = _address;
    }

    function setAddress2(address _address)
        external
        onlyOwner
    {
        address2 = _address;
    } 

    function setAddress3(address _address)
        external
        onlyOwner
    {
        address3 = _address;
    } 
    function setdexRouter(IdexRouter _dexRouter, address _dexPair)
        external
        onlyOwner
    {
        dexRouter = _dexRouter;
        dexPair = _dexPair;
    }

    // Internal functions for contract use

    function totalFeePerTx(uint256 tAmount) internal view returns (uint256) {
        uint256 percentage = (tAmount *
            (lpFee + (fee1) + (fee2) + (fee3))) / (divider);
        return percentage;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "NT: approve from the zero address");
        require(spender != address(0), "NT: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function getCurrentPrice() public view returns (uint256) {
        (uint256 token, uint256 Wbnb, ) = IdexPair(dexPair).getReserves();
        uint256 currentRate = Wbnb / (token / (10**_decimals));
        return currentRate;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "NT: transfer from the zero address");
        require(to != address(0), "NT: transfer to the zero address");
        require(amount > 0, "NT: amount must be greater than zero");
        require(contractStatus == true,"contract is pauseed");
        if (from != owner() && to != owner()) {
            if (!tradingOpen) {
                require(
                    from != dexPair && to != dexPair,
                    "Trading is not enabled"
                );
            }
        }

        // swap and liquify
        swapAndLiquify(from, to);

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to _whiteList account then remove the fee
        if (_whiteList[from] || _whiteList[to] || !feeStatus) {
            takeFee = false;
        }

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from, to, amount, takeFee);
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        require(!_blackList[sender] && !_blackList[recipient],"NT : user prohibited");
        if (!takeFee) {
            _basicTransfer(sender, recipient, amount);
        } else if (sender == dexPair) {
            require(
                amount <= maxBuyAmount,
                "NT: can not buy more then max limit"
            );
            _transferWithFee(sender, recipient, amount);
        } else if (recipient == dexPair) {
            require(
                amount <= maxSellAmount,
                "NT: can not sell more then max limit"
            );
            if(block.timestamp < lastSellTime + (sellCoolDownDuration)){
                if(sellLimitValid){require(sellCount <= maxSellCount,"NT: wait for selling cool down");
                sellCount++;}
                if(priceLimitValid){uint256 minPriceLimit = lastClosingPrice - (lastClosingPrice * declinedPricePercent / divider);
                require(getCurrentPrice() < minPriceLimit,"NT: token price droped more than limit");}
            } else {
                sellCount = 0;
                lastSellTime = block.timestamp;
                lastClosingPrice  = getCurrentPrice();
            }

            _transferWithFee(sender, recipient, amount);
        } else {
            _transferWithFee(sender, recipient, amount);
        }
    }

    function _transferWithFee(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        uint256 transferAmount;
        transferAmount = tAmount - (totalFeePerTx(tAmount));
        if(_greyList[sender]){
            transferAmount -=  tAmount * (additionalFee) / divider;
            _takeAdditionalFee(sender, tAmount);
        } else if(balanceOf(sender) > maxHoldAmount && sender != dexPair ) {

             transferAmount -=  tAmount * (additionalFee) / divider;
            _takeAdditionalFee(sender, tAmount);
        }
        _balances[sender] = _balances[sender] - (tAmount);
        _balances[recipient] = _balances[recipient] + (transferAmount);
        if(lpFee > 0) _takeLPFee(sender, tAmount);
        if(fee1 > 0) _takefee1(sender, tAmount);
        if(fee2 > 0) _takefee2(sender, tAmount);
        if(fee3 > 0) _takefee3(sender, tAmount);
        emit Transfer(sender, recipient, transferAmount);
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        _balances[sender] = _balances[sender] - (tAmount);
        _balances[recipient] = _balances[recipient] + (tAmount);
        emit Transfer(sender, recipient, tAmount);
    }

    function _takeLPFee(address sender, uint256 tAmount) internal {
        uint256 tPoolFee = (tAmount * (lpFee)) / (divider);
        _balances[address(this)] = _balances[address(this)] + (tPoolFee);
        emit Transfer(sender, address(this), tPoolFee);
    }

    function _takefee1(address sender, uint256 tAmount) internal {
        uint256 t_fee2 = (tAmount * (fee1)) / (divider);
        _balances[address1] = _balances[address1] + (t_fee2);
        emit Transfer(sender, address1, t_fee2);
    }

    function _takefee2(address sender, uint256 tAmount) internal {
        uint256 tfee2 = (tAmount * (fee2)) / (divider);
        _balances[address2] = _balances[address2] + (tfee2);
        emit Transfer(sender, address2, tfee2);
    }

    function _takefee3(address sender, uint256 tAmount) internal {
        uint256 tfee3 = (tAmount * (fee3)) / (divider);
        _balances[address3] = _balances[address3] + (tfee3);
        emit Transfer(sender, address3, tfee3);
    }

    function _takeAdditionalFee(address sender, uint256 tAmount) internal {
        uint256 tFee = (tAmount * (additionalFee)) / (divider);
        _balances[address(this)] = _balances[address(this)] + (tFee);
        emit Transfer(sender, address(this), tFee);
    }

    function swapAndLiquify(address from, address to) private {
        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is dex pair.
        uint256 contractTokenBalance = balanceOf(address(this));
        bool shouldSell = contractTokenBalance >= minTokenNumberToSell;

        if (
            shouldSell &&
            from != dexPair &&
            swapAndLiquifyStatus &&
            !(from == address(this) && to == address(dexPair)) // swap 1 time
        ) {
            contractTokenBalance = minTokenNumberToSell;
            // approve contract
            _approve(address(this), address(dexRouter), contractTokenBalance);

            uint256 halfLiquidity = contractTokenBalance / (2);
            uint256 otherHalfLiquidity = contractTokenBalance - (halfLiquidity);

            uint256 initialBalance = address(this).balance;
            // now is to lock into liquidty pool
            Utils.swapTokensForEth(address(dexRouter), halfLiquidity);

            uint256 bnbToBeAddedToLiquidity = address(this).balance -
                initialBalance;

            // add liquidity to Dex
            if (bnbToBeAddedToLiquidity > 0) {
                Utils.addLiquidity(
                    address(dexRouter),
                    owner(),
                    otherHalfLiquidity,
                    bnbToBeAddedToLiquidity
                );

                emit SwapAndLiquify(
                    halfLiquidity,
                    bnbToBeAddedToLiquidity,
                    otherHalfLiquidity
                );
            }
        }
    }
}

library Utils {
    function swapTokensForEth(address routerAddress, uint256 tokenAmount)
        internal
    {
        IdexRouter dexRouter = IdexRouter(routerAddress);

        // generate the dex pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        // make the swap
        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BNB
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(
        address routerAddress,
        address owner,
        uint256 tokenAmount,
        uint256 ethAmount
    ) internal {
        IdexRouter dexRouter = IdexRouter(routerAddress);

        // add the liquidity
        dexRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner,
            block.timestamp + 360
        );
    }
}