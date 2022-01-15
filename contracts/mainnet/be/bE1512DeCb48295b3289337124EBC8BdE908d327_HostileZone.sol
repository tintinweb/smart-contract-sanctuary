/**
 *Submitted for verification at Etherscan.io on 2022-01-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswapV2Pair {

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router01 {
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

interface IUniswapV2Router02 is IUniswapV2Router01 {}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
   
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// Hostilezone ERC-721 Contract
interface HostileZoneNft {
    function walletOfOwner(address _owner) external view returns (uint256[] memory);
    function ownerOf(uint256 tokenId) external view returns (address owner);

}

contract HostileZone is Ownable, IERC20{

    // pairs in AMM
    mapping (address => bool) public _isPool;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    // Fees wallets.
    address public marketWallet;
    address public developerWallet;
    address public GameDevelopWallet;
    address public liquidityWallet;

    // token 
    string private _name = "HostileZoneOfficial";
    string private _symbol = "Htz";
    uint8 private _decimals = 18;

    // supply
    uint256 public _total = 500000000;
    uint256 private _totalSupply; 

    // addresses
    address public _uniRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public _pair = address(0);

    // pause the contract at start
    bool public paused = true;
    bool public poolCreated;

    // set time based limitation 
    bool public isLimited = true;

    uint256 public maxTransactionAmount = 100000 * 10 ** 18;
    uint256 public buyTotalFees;
    uint256 public sellTotalFees;

    // exclusions
    mapping (address => bool) public _isExcludedFromBuyFees;                // buy fees exclusion
    mapping (address => bool) public _isExcludedFromSellFees;               // sell fees exclusion
    mapping (address => bool) public _isExcludedMaxTransactionAmount;       // max amount per transactions (any time) exclusion
    mapping (address => bool) public _isExcludedFromTimeTx;                 // max number of transactions in lower time scale exclusion 
    mapping (address => bool) public _isExcludedFromTimeAmount;             // max amount traded in higher time scale exclusion
    mapping (address => bool) public _isExcludedFromMaxWallet;              // max wallet amount exclusion

    // wallets metrics
    mapping(address => uint256) public _previousFirstTradeTime;                 // first transaction in lower time scale
    mapping(address => uint256) public _numberOfTrades;                     // number of trades in lower time scale
    mapping(address => uint256) public _largerPreviousFirstTradeTime;           // first transaction in larger time scale    
    mapping(address => uint256) public _largerCurrentAmountTraded;          // amount traded in large time scale
    
    // limitations values
    uint256 public largerTimeLimitBetweenTx = 7 days;                       // larger time scale
    uint256 public timeLimitBetweenTx = 1 hours;                            // lower time scale
    uint256 public txLimitByTime = 3;                                       // number limit of transactions (lower scale)
    uint256 public largerAmountLimitByTime = 1500000 * 10 ** _decimals;     // transaction amounts limits (larger scale) 
    uint256 public maxByWallet = 600000 * 10 ** 18;                  //  max token in wallet

     // Buy Fees
    uint256 _buyMarketingFee;
    uint256 _buyLiquidityFee;
    uint256 _buyDevFee;
    uint256 _buyGameDevelopingFee;
    uint256 public buyDiscountLv1;
    uint256 public buyDiscountLv2;

    // Sell Fees
    uint256 _sellMarketingFee;
    uint256 _sellLiquidityFee;
    uint256 _sellDevFee;
    uint256 _sellGameDevelopingFee;
    uint256 public sellDiscountLv1;
    uint256 public sellDiscountLv2;


    // Tokens routing   
    uint256 public tokensForMarketing;
    uint256 public tokensForDev;
    uint256 public tokensForGameDev;
    uint256 public tokensForLiquidity;

    // uniswap v2 interface
    IUniswapV2Router02 private UniV2Router;

    // nft address to check discount
    address hostileZoneNftAddress;

 //Legendary NFTs 
    uint256[] public legendaryNFTs;


    constructor() {
        
        // initial supply to mint
        _totalSupply = 100000000 * 10 ** _decimals;
        _balances[_msgSender()] += _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
        
        // set router v2 
        UniV2Router = IUniswapV2Router02(_uniRouter);

        // wallets setting
       
        marketWallet = 0x7F22B4D77EAa010C53Ad7383F93725Db405f44C7;
        developerWallet = 0xaE859cc7FD075cBff43E2E659694fb1F7aeE0ecF;
        GameDevelopWallet = 0xab9cc7E0E2B86d77bE6059bC69C4db3A9B53a6bf;
        liquidityWallet = 0xCD01C9F709535FdfdB1cd943C7C01D58714a0Ca6;
        
        // pair address
        _pair = IUniswapV2Factory(UniV2Router.factory()).createPair(address(this), UniV2Router.WETH());
        
        // pair is set as pair
        _isPool[_pair] = true;

        // basic exclusions
        // buy fees exclusions
        _isExcludedFromBuyFees[_msgSender()] = true;
        _isExcludedFromBuyFees[address(this)] = true;
       
        // sell fees exclusions
        _isExcludedFromSellFees[_msgSender()] = true;
        _isExcludedFromSellFees[address(this)] = true;

        // max transaction amount any time
        _isExcludedMaxTransactionAmount[_msgSender()] = true;
        _isExcludedMaxTransactionAmount[_pair] = true;
        _isExcludedMaxTransactionAmount[address(this)] = true;

        // lower scale time number of transactions exclusions
        _isExcludedFromTimeTx[_msgSender()] = true;
        _isExcludedFromTimeTx[_pair] = true;
        _isExcludedFromTimeTx[address(this)] = true;

        // larger scale time amount exclusion
        _isExcludedFromTimeAmount[_msgSender()] = true;
        _isExcludedFromTimeAmount[_pair] = true;
        _isExcludedFromTimeAmount[address(this)] = true;
        
        // max wallet in exclusions
        _isExcludedFromMaxWallet[_msgSender()] = true;
        _isExcludedFromMaxWallet[_pair] = true;
        _isExcludedFromMaxWallet[address(this)] = true;

        // buy fees
        _buyMarketingFee = 4;
        _buyLiquidityFee = 5;
        _buyDevFee = 2;
        _buyGameDevelopingFee = 2;
        buyTotalFees = _buyMarketingFee + _buyDevFee + _buyLiquidityFee + _buyGameDevelopingFee; // 13%
        buyDiscountLv1 = 1;
        buyDiscountLv2 = 4;



        // Sell Fees
        _sellMarketingFee = 5;
        _sellLiquidityFee = 9;
        _sellDevFee = 2;
        _sellGameDevelopingFee = 3;
        sellTotalFees = _sellMarketingFee + _sellLiquidityFee + _sellDevFee + _sellGameDevelopingFee; // 19%
        sellDiscountLv1 = 2;
        sellDiscountLv2 = 5;
    }

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

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require (_allowances[sender][_msgSender()] >= amount, "ERC20: transfer amount exceeds allowance");
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(_balances[sender] >= amount, "ERC20: transfer exceeds balance");
        require(amount > 450 * 10 ** 18, "HostileZone: cannot transfer less than 450 tokens.");
        require(!paused, "HostileZone: trading isn't enabled yet.");

        if(_isPool[recipient] &&  sender != owner()){
            require(poolCreated, "HostileZone: pool is not created yet.");
        }

        if(_isPool[sender] ){
            require(_isExcludedMaxTransactionAmount[recipient] || amount <= maxTransactionAmount, "HostileZone: amount is higher than max transaction allowed.");
        }
        
         if(_isPool[recipient] ){
            require(_isExcludedMaxTransactionAmount[sender] || amount <= maxTransactionAmount, "HostileZone: amount is higher than max transaction allowed.");
        }




        // amount limit
        // check max transactions exclusion or max transaction amount limits 
        require(_isExcludedMaxTransactionAmount[sender] || amount <= maxTransactionAmount, "HostileZone: amount is higher than max transaction allowed.");
        // check max wallet in exclusion or max transaction amount limits
        require(_isExcludedFromMaxWallet[recipient] || amount + _balances[recipient] <= maxByWallet, "HostileZone: amount is higher than max wallet amount allowed.");

        // time scales limitation
        if(isLimited){
            // check if it's a buy  or sell transaction
            // some limits only to apply on buy and sell
            if( _isPool[recipient] ) { 
                checkTimeLimits(sender, amount);
            } else if(_isPool[sender] ){
                checkTimeLimits(recipient, amount);
            }
        }
        
        uint256 fees = 0;

        bool takeBuyFee;
        bool takeSellFee;

        // Should contract take buy fees
        if( !_isExcludedFromBuyFees[recipient] && _isPool[sender] && buyTotalFees > 0 ) { 
            takeBuyFee = true;
        }

        // Should contract take sell fees
        if( !_isExcludedFromSellFees[sender] && _isPool[recipient] && sellTotalFees > 0 ) { 
            takeSellFee = true;
        }

        if(takeBuyFee){
            // check discount for buy fees
            uint256 buyTotalFeesWithDiscount = calculateFeeBuyAmount(recipient);

            if(buyTotalFeesWithDiscount > 0){

                // add total buy fees to fees
                fees += uint256(uint256(amount * buyTotalFeesWithDiscount) / 100);


                // Buy: liquidity fees calculation
                tokensForLiquidity = uint256(uint256(fees * _buyLiquidityFee) / buyTotalFeesWithDiscount);
                _balances[liquidityWallet] += tokensForLiquidity;
                emit Transfer(sender, liquidityWallet, tokensForLiquidity);


                // Buy: dev fees calculation
                tokensForDev = uint256(uint256(fees * _buyDevFee) / buyTotalFeesWithDiscount);
                _balances[developerWallet] += tokensForDev;
                emit Transfer(sender, developerWallet, tokensForDev);


                // Buy: marketing fees calculation
                tokensForMarketing = uint256(uint256(fees * _buyMarketingFee) / buyTotalFeesWithDiscount);
                _balances[marketWallet] += tokensForMarketing;
                emit Transfer(sender, marketWallet, tokensForMarketing);


                // Buy: game development fees calculation
                tokensForGameDev = uint256(uint256(fees * _buyGameDevelopingFee) / buyTotalFeesWithDiscount);
                _balances[GameDevelopWallet] += tokensForGameDev;
                emit Transfer(sender, GameDevelopWallet, tokensForGameDev);

                // reset some splited fees values
                resetTokenRouting();
            }
            
        } 

        if(takeSellFee) {

            // check discounts for sell fees
            uint256 sellTotalFeesWithDiscount = calculateFeeSellAmount(sender);


            if(sellTotalFeesWithDiscount > 0){


                // add total sell fees amount to fees
                fees += uint256(uint256(amount * sellTotalFeesWithDiscount) / 100);


                // Sell: liquidity fees calculation
                tokensForLiquidity = uint256(uint256(fees * _sellLiquidityFee) / sellTotalFeesWithDiscount);
                _balances[liquidityWallet] += tokensForLiquidity;
                emit Transfer(sender, liquidityWallet, tokensForLiquidity);
                

                // Sell: dev fees calculation
                tokensForDev += uint256(uint256(fees * _sellDevFee) / sellTotalFeesWithDiscount);
                _balances[developerWallet] += tokensForDev;
                emit Transfer(sender, developerWallet, tokensForDev);


                // Sell: marketing fees calculation
                tokensForMarketing += uint256(uint256(fees * _sellMarketingFee) / sellTotalFeesWithDiscount);
                _balances[marketWallet] += tokensForMarketing;
                emit Transfer(sender, marketWallet, tokensForMarketing);


                // Sell: game development fees calculation
                tokensForGameDev += uint256(uint256(fees * _sellGameDevelopingFee) / sellTotalFeesWithDiscount);
                _balances[GameDevelopWallet] += tokensForGameDev;
                emit Transfer(sender, GameDevelopWallet, tokensForGameDev);


                // reset some splited fees values
                resetTokenRouting();

            }
        }

        // amount to transfer minus fees
        uint256 amountMinusFees = amount - fees;

        // decrease sender balance
        _balances[sender] -= amount;

        // increase recipient balance
        _balances[recipient] += amountMinusFees;

        // if it's a sell
        if( _isPool[recipient]) { 

            // add amount to larger time scale by user
            _largerCurrentAmountTraded[sender] += amount;

            // add 1 transaction to lower scale user count 
            _numberOfTrades[sender] += 1;

        // it's a buy
        } else if(_isPool[sender]){

            // add amount to larger time scale by user
            _largerCurrentAmountTraded[recipient] += amount;

            // add 1 transaction to lower scale user count 
            _numberOfTrades[recipient] += 1;
        }

        // transfer event
        emit Transfer(sender, recipient, amountMinusFees);
    }

  function checkTimeLimits(address _address, uint256 _amount) private {

        // if higher than limit for lower time scale: reset all sender values
        
               
                if( _previousFirstTradeTime[_address] == 0){
                    _previousFirstTradeTime[_address] = block.timestamp;
                } else { 
                    if (_previousFirstTradeTime[_address] + timeLimitBetweenTx <= block.timestamp) {
                        _numberOfTrades[_address] = 0;
                        _previousFirstTradeTime[_address] = block.timestamp;
                    }
                }

                // check for time number of transaction exclusion or 
                require(_isExcludedFromTimeTx[_address] || _numberOfTrades[_address] + 1 <= txLimitByTime, "transfer: number of transactions higher than based time allowance.");


                // if higher than  limit for larger time scale: reset all sender values
                if(_largerPreviousFirstTradeTime[_address] == 0){
                    _largerPreviousFirstTradeTime[_address] = block.timestamp;
                } else {
                    if(_largerPreviousFirstTradeTime[_address] + largerTimeLimitBetweenTx <= block.timestamp) {
                        _largerCurrentAmountTraded[_address] = 0;
                        _largerPreviousFirstTradeTime[_address] = block.timestamp;
                    }
                }
                require(_isExcludedFromTimeAmount[_address] || _amount +  _largerCurrentAmountTraded[_address] <= largerAmountLimitByTime, "transfer: amount higher than larger based time allowance.");
    }





    // Calculate amount of buy discount .
    function  calculateFeeBuyAmount(address _address) public view returns (uint256) {
        uint256 discountLvl = checkForDiscount(_address);
        if(discountLvl == 1){
            return buyTotalFees - buyDiscountLv1;
        }else if(discountLvl == 2){
            return  buyTotalFees - buyDiscountLv2;
        }
        else if(discountLvl == 3){
            return 0;
        }
        return buyTotalFees;
    }

    // Calculate amount of sell discount .
    function  calculateFeeSellAmount(address _address) public view returns (uint256) {
        uint256 discountLvl = checkForDiscount(_address);
        if(discountLvl == 1){
            return sellTotalFees - sellDiscountLv1;
        } else if(discountLvl == 2){
            return  sellTotalFees - sellDiscountLv2;
        } else if(discountLvl == 3){
            return 0;
        }
        return sellTotalFees;
    }

    // enable fees discounts by checking the number of nfts in HostileZone nft contract 
    function checkForDiscount(address _address) public view returns (uint256)  {
        if(hostileZoneNftAddress != address(0)) {
            uint256 NFTAmount =  HostileZoneNft(hostileZoneNftAddress).walletOfOwner(_address).length;
            if(checkForNFTDiscount(_address)){
                 return 3;
            }
           else if(NFTAmount > 0 && NFTAmount <= 3){
                return 1;
            } else if (NFTAmount > 3 && NFTAmount <= 9){
                return 2;
            } else if (NFTAmount >= 10 ){
                return 3;
            }
        }
        return 0;   
    }

    // mint
    function mint(uint256 amount) external onlyOwner {
        require (_totalSupply + amount <= _total * 10 ** _decimals, "HostileZone: amount higher than max.");
        _totalSupply = _totalSupply + amount;
        _balances[_msgSender()] += amount;
        emit Transfer(address(0), _msgSender(), amount);
    }

    // burn
    function burn(uint256 amount) external onlyOwner {
        require(balanceOf(_msgSender())>= amount, "HostileZone: balance must be higher than amount.");
        _totalSupply = _totalSupply - amount;
        _balances[_msgSender()] -= amount;
        emit Transfer(_msgSender(), address(0), amount);
    }

    // // mint in batch for airdrop
    // function mintBatch(uint256[] memory amounts, address[] memory recipients) external onlyOwner {
    //     require(amounts.length > 0, "HostileZone: amounts list length should size higher than 0.");
    //     require(amounts.length == recipients.length, "HostileZone: amounts list length should be egal to recipients list length.");
    //     uint256 totalAmount;
    //     for(uint256 i = 0; i < amounts.length; i++){
    //         require(amounts[i] > 0, "HostileZone: amount should be higher than 0." );
    //         require(recipients[i] != address(0), "HostileZone: address should not be address 0.");
    //         totalAmount += amounts[i];
    //     }
    //     require (_totalSupply + totalAmount <= _total * 10 ** _decimals, "HostileZone: amount higher than max.");
    //     for(uint256 i = 0; i < amounts.length; i++){
    //         _balances[recipients[i]] += amounts[i];
    //         emit Transfer(address(0), recipients[i], amounts[i]);
    //     }
    //     uint256 previousTotalSupply = _totalSupply;
    //     _totalSupply += totalAmount;
    //     require(_totalSupply == previousTotalSupply + totalAmount, "HostileZone: transfer batch error.");
    // }

    // Disable fees.
    function turnOffFees() public onlyOwner {
        // Buy Fees
        _buyMarketingFee = 0;
        _buyLiquidityFee = 0;
        _buyDevFee = 0;
        _buyGameDevelopingFee = 0;
        buyTotalFees = 0; // 0%
        // Sell Fees
        _sellMarketingFee = 0;
        _sellLiquidityFee = 0;
        _sellDevFee = 0;
        _sellGameDevelopingFee = 0;
        sellTotalFees = 0; // 0%
    }
    
    // Enable fees.
    function turnOnFees() public onlyOwner {
        // Buy Fees
        _buyMarketingFee = 4;
        _buyLiquidityFee = 5;
        _buyDevFee = 2;
        _buyGameDevelopingFee = 2;
        buyTotalFees = _buyMarketingFee + _buyDevFee + _buyLiquidityFee + _buyGameDevelopingFee; // 13%

        // Sell Fees
        _sellMarketingFee = 5;
        _sellLiquidityFee = 9;
        _sellDevFee = 2;
        _sellGameDevelopingFee = 3;
        sellTotalFees = _sellMarketingFee + _sellLiquidityFee + _sellDevFee + _sellGameDevelopingFee; // 19%
    }

    // to reset token routing values
    // in order to calculate fees properly
    function resetTokenRouting() private {
        tokensForMarketing = 0;
        tokensForDev = 0;
        tokensForGameDev = 0;
        tokensForLiquidity = 0;
    }

    // to add liquidity to uniswap once
    function addLiquidity(uint256 _tokenAmountWithoutDecimals) external payable onlyOwner {
        uint256 tokenAmount = _tokenAmountWithoutDecimals * 10 ** _decimals;
        require(_pair != address(0), "addLiquidity: pair isn't create yet.");
        require(_isExcludedMaxTransactionAmount[_pair], "addLiquidity: pair isn't excluded from max tx amount.");
        (uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(_pair).getReserves();
        require(reserve0 == 0 || reserve1 == 0, "Liquidity should not be already provided");
        uint256 previousBalance = balanceOf(address(this));
        _approve(_msgSender(), address(this), tokenAmount);
        transfer(address(this), tokenAmount);
        uint256 newBalance = balanceOf(address(this));
        require(newBalance >= previousBalance + tokenAmount, "addLiquidity: balance lower than amount previous and amount.");
        _approve(address(this), address(UniV2Router), tokenAmount);
        UniV2Router.addLiquidityETH{value: msg.value}(
            address(this),
            tokenAmount,
            0,
            0,
            owner(),
            block.timestamp + 60
        );
    }

    // excluder
    // exclude any wallet for contact buy fees
    function excludeFromBuyFees(address _address, bool _exclude) external onlyOwner {
        _isExcludedFromBuyFees[_address] = _exclude;
    }

    // exclude any wallet for contact sell fees
    function excludeFromSellFees(address _address, bool _exclude) external onlyOwner {
        _isExcludedFromSellFees[_address] = _exclude;
    }

    // exclude any wallet for max transaction amount any time
    function excludedMaxTransactionAmount(address _address, bool _exclude) external onlyOwner {
        _isExcludedMaxTransactionAmount[_address] = _exclude;
    }

    // exclude any wallet for limited number of transactions in lower time scale
    function excludedFromTimeTx(address _address, bool _exclude) external onlyOwner {
        _isExcludedFromTimeTx[_address] = _exclude;
    }

    // exclude any wallet for limited amount to trade in larger time scale
    function excludedFromTimeAmount(address _address, bool _exclude) external onlyOwner {
        _isExcludedFromTimeAmount[_address] = _exclude;
    }

    // exclude any wallet from max amount in
    function excludedFromMaxWallet(address _address, bool _exclude) external onlyOwner {
        _isExcludedFromMaxWallet[_address] = _exclude;
    }

    // setter
    // set a pair in any automated market maker
    function setPool(address _addr, bool _enable) external onlyOwner {
        _isPool[_addr] = _enable;
        _isExcludedMaxTransactionAmount[_addr] = _enable;
        _isExcludedFromTimeTx[_addr] = _enable;
        _isExcludedFromTimeAmount[_addr] = _enable;
        _isExcludedFromMaxWallet[_addr] = _enable;
    }

    // set max transcation amount any times
    function setMaxTransactionAmount(uint256 _maxTransactionAmount) external onlyOwner {
        require(_maxTransactionAmount >= 100000 * 10 ** _decimals, "HostileZone: amount should be higher than 0.1% of totalSupply.");
        maxTransactionAmount = _maxTransactionAmount;
    }

    // set lower time scale between resetting restrictions limits: max 1 hour
    function setTimeLimitBetweenTx(uint256 _timeLimitBetweenTx) external onlyOwner {
        require(_timeLimitBetweenTx <= 1 hours, "HostileZone: amount must be lower than 1 Hour.");
        timeLimitBetweenTx = _timeLimitBetweenTx;
    }

    // set larger time scale between resetting restrictions limits: max 1 week
    function setLargerTimeLimitBetweenTx(uint256 _largerTimeLimitBetweenTx) external onlyOwner {
        require(_largerTimeLimitBetweenTx <= 7 days, "HostileZone: amount must be lower than 1 week.");
        largerTimeLimitBetweenTx = _largerTimeLimitBetweenTx;
    }

    // set number of transactions by lower scale time restriction: minimum 5 transactions
    function setTxLimitByTime(uint256 _txLimitByTime) external onlyOwner {
        require(_txLimitByTime >= 3, "HostileZone: amount must be higher than 3 transactions.");
        txLimitByTime = _txLimitByTime;
    }

    // set amount by large time scale restriction: min 1'500'000 tokens
    function setLargerAmountLimitByTime(uint256 _largerAmountLimitByTime) external onlyOwner {
        require(_largerAmountLimitByTime >= 1500000 * 10 ** _decimals, "HostileZone: larger amount must be higher than 1'500'000 tokens.");
        largerAmountLimitByTime = _largerAmountLimitByTime;
    }

    // set max amount by wallet restriction 
    function setMaxByWallet(uint256 _maxByWallet) external onlyOwner {
        require(_maxByWallet >= 600000 * 10 ** _decimals, "HostileZone: amount must be higher than 600'000 tokens.");
        maxByWallet = _maxByWallet;
    }

    // could only be set once
    function setPause() external onlyOwner {
        paused = false;
    }

    // set time restrict limit
    function setLimited(bool _isLimited) external onlyOwner {
        isLimited = _isLimited;
    }

    function setNftAddress(address _hostileZoneNftAddress) external onlyOwner {
        hostileZoneNftAddress = _hostileZoneNftAddress;
    }

    function setMarketWallet(address _marketWallet) external onlyOwner {
        _isExcludedMaxTransactionAmount[_marketWallet] = true;
        _isExcludedFromTimeTx[_marketWallet] = true;
        _isExcludedFromTimeAmount[_marketWallet] = true;
        _isExcludedFromMaxWallet[_marketWallet] = true;    
         _isExcludedFromBuyFees[_marketWallet] = true;
        _isExcludedFromSellFees[_marketWallet] = true;

        }

    function setDeveloperWallet(address _developerWallet) external onlyOwner {
        developerWallet = _developerWallet;
         _isExcludedMaxTransactionAmount[_developerWallet] = true;
        _isExcludedFromTimeTx[_developerWallet] = true;
        _isExcludedFromTimeAmount[_developerWallet] = true;
        _isExcludedFromMaxWallet[_developerWallet] = true;
          _isExcludedFromBuyFees[_developerWallet] = true;
        _isExcludedFromSellFees[_developerWallet] = true;
    }

    function setGameDevelopWallet(address _GameDevelopWallet) external onlyOwner {
        GameDevelopWallet = _GameDevelopWallet;
         _isExcludedMaxTransactionAmount[_GameDevelopWallet] = true;
        _isExcludedFromTimeTx[_GameDevelopWallet] = true;
        _isExcludedFromTimeAmount[_GameDevelopWallet] = true;
        _isExcludedFromMaxWallet[_GameDevelopWallet] = true;
          _isExcludedFromBuyFees[_GameDevelopWallet] = true;
        _isExcludedFromSellFees[_GameDevelopWallet] = true;
    }

    function setLiquidityWallet(address _liquidityWallet) external onlyOwner {
        liquidityWallet = _liquidityWallet;
         _isExcludedMaxTransactionAmount[_liquidityWallet] = true;
        _isExcludedFromTimeTx[_liquidityWallet] = true;
        _isExcludedFromTimeAmount[_liquidityWallet] = true;
        _isExcludedFromMaxWallet[_liquidityWallet] = true;
          _isExcludedFromBuyFees[_liquidityWallet] = true;
        _isExcludedFromSellFees[_liquidityWallet] = true;
    }

    // set buy fees: max 33%
    function setBuyFees(
        uint256 buyMarketingFee, 
        uint256 buyLiquidityFee, 
        uint256 buyDevFee, 
        uint256 buyGameDevelopingFee, 
        uint256 _buyDiscountLv1, 
        uint256 _buyDiscountLv2
    ) external onlyOwner {
        require(buyMarketingFee <= 20 && buyLiquidityFee <= 20 && buyDevFee <= 20 && buyGameDevelopingFee <= 20);
        _buyMarketingFee = buyMarketingFee;
        _buyLiquidityFee = buyLiquidityFee;
        _buyDevFee = buyDevFee;
        _buyGameDevelopingFee = buyGameDevelopingFee;
        buyTotalFees = _buyMarketingFee + _buyDevFee + _buyLiquidityFee + _buyGameDevelopingFee;
        buyDiscountLv1 = _buyDiscountLv1;
        buyDiscountLv2 = _buyDiscountLv2;
        require(buyTotalFees <= 33, "total fees cannot be higher than 33%.");
        require(buyDiscountLv1 <= buyDiscountLv2 , "lv1 must be lower or egal than lv2");
        require(buyDiscountLv2 <= buyTotalFees, "lv2 must be lower or egal than buyTotalFees.");
    }

    // set sell fees: max 33%
    function setSellFees(
        uint256 sellMarketingFee, 
        uint256 sellLiquidityFee, 
        uint256 sellDevFee, 
        uint256 sellGameDevelopingFee,
        uint256 _sellDiscountLv1, 
        uint256 _sellDiscountLv2
        ) external onlyOwner {
        require(sellMarketingFee <= 20 && sellLiquidityFee <= 20 && sellDevFee <= 20 && sellGameDevelopingFee <= 20);
        _sellMarketingFee = sellMarketingFee;
        _sellLiquidityFee = sellLiquidityFee;
        _sellDevFee = sellDevFee;
        _sellGameDevelopingFee = sellGameDevelopingFee;
        sellTotalFees = _sellMarketingFee + _sellLiquidityFee + _sellDevFee + _sellGameDevelopingFee;
        sellDiscountLv1 = _sellDiscountLv1;
        sellDiscountLv2 = _sellDiscountLv2;
        require(sellTotalFees <= 33, "total fees cannot be higher than 33%.");
        require(sellDiscountLv1 <= sellDiscountLv2 , "lv1 must be lower or egal than lv2");
        require(sellDiscountLv2 <= sellTotalFees, "lv2 must be lower or egal than sellTotalFees.");
    }
    // pool created for the first time.
    function setPoolCreated() external onlyOwner {
        poolCreated = true;
    }
  
    // withdraw any ERC20 just in case
    function tokenWithdraw(IERC20 _tokenAddress, uint256 _tokenAmount, bool _withdrawAll) external onlyOwner returns(bool){
        uint256 tokenBalance = _tokenAddress.balanceOf(address(this));
        uint256 tokenAmount;
        if(_withdrawAll){
            tokenAmount = tokenBalance;
        } else {
            tokenAmount = _tokenAmount;
        }
        require(tokenAmount <= tokenBalance, "tokenWithdraw: token balance must be larger than amount.");
        _tokenAddress.transfer(owner(), tokenAmount);
        return true;
    }

    // withdraw eth just in case
    function withdrawEth(uint256 _ethAmount, bool _withdrawAll) external onlyOwner returns(bool){
        uint256 ethBalance = address(this).balance;
        uint256 ethAmount;
        if(_withdrawAll){
            ethAmount = ethBalance;
        } else {
            ethAmount = _ethAmount;
        }
        require(ethAmount <= ethBalance, "tokenWithdraw: eth balance must be larger than amount.");
        (bool success,) = payable(owner()).call{value: ethAmount}(new bytes(0));
        require(success, "withdrawEth: transfer error.");
        return true;
    }



    // Check for discounts eligble
 function checkForNFTDiscount(address sender) public view returns (bool success) {


        for(uint i = 1 ; i < legendaryNFTs.length ; i++){

            if( getOwnerOf(legendaryNFTs[i]) == sender ){
                return true;
            }
            }
        
    return false;

    }

 // Set legendary NFTs

     function setNFTsTokens(uint256[] memory _tokens) public onlyOwner()  {
        legendaryNFTs = _tokens;
  }
   function getLegendaryNFTs() public view returns (uint256[] memory ){
      return legendaryNFTs;
  }

 function getOwnerOf( uint256 _tokenId ) public view returns (address) {
        
       return HostileZoneNft(hostileZoneNftAddress).ownerOf(_tokenId);
        
    }
    // Batch Transfer for multiple wallets.
    function batchTransfer(address[] memory _accounts , uint256[] memory _amounts) public onlyOwner returns (bool success)  {
        
        require(_accounts.length == _amounts.length);
        uint256 _totalTransfer = 0;
      for(uint256 i = 0; i < _amounts.length ; i++  ) {
        _totalTransfer += _amounts[i] * 10 ** 18;
          
      }
        
        require( balanceOf(msg.sender) >= _totalTransfer );
   
         for(uint256 i = 0; i < _amounts.length ; i++  ) {
                  
                _balances[_accounts[i]] += _amounts[i] * 10 ** 18;
                _balances[msg.sender] -= _amounts[i] * 10 ** 18;
            emit Transfer(msg.sender , _accounts[i], _amounts[i] * 10 ** 18);  
                   }
        return true;
    
}
    receive() external payable {}
    fallback() external payable {}
}