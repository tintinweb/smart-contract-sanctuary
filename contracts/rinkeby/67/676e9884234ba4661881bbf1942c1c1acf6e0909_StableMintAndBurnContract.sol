/**
 *Submitted for verification at Etherscan.io on 2021-09-06
*/

// SPDX-License-Identifier: UNLICENCED

pragma solidity <0.8.6;

abstract contract OwnerContract{
    address internal owner;
    
    address WBTCAddress = 0x577D296678535e4903D59A4C929B718e1D575e0A;
    address USDTAddress = 0xD9BA894E0097f8cC2BBc9D24D308b98e36dc6D02;
    address USDCAddress = 0x4DBCdF9B62e891a7cec5A2568C3F4FAF9E8Abe2b;
    address WETHAddress = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
    address LINKAddress = 0x01BE23585060835E02B77ef475b0Cc51aA1e0709;
    address UNISWAP_R_V2 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address WBTCOracleAddress = 0xECe365B379E1dD183B20fc5f022230C044d51404;
    address WETHOracleAddress = 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e;
    address LINKOracleAddress = 0xd8bD0a1cB028a31AA859A21A3758685a95dE4623;
    address StabletokenAddress = 0xcaBD65e3b9b6996A03C0447a8A67FE3AB2acFf34;
    address profitContractAddress = 0xa198DeF6C7dBD4B80f22b3C8c6edbA41E0EE9ECf;
    
    event ownershipTransfered(address from, address to);
    
    constructor() {
        owner = msg.sender;
    }
    
    modifier isOwner(){
        require(msg.sender==owner, "Access denied!");
        _;
    }
    
    function transferOwnership(address _to) public isOwner{
        owner = _to;
        emit ownershipTransfered(msg.sender, owner);
    }

    
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function deposit() external payable;
    function withdraw(uint wad) external;
    function burn(address _receiver, uint256 _amont) external;
    function mint(address _receiver, uint256 _amont) external;
}

interface AggregatorV3Interface {
  function latestRoundData() external view returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

interface IUniswapV2Router02 {
    
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

abstract contract ColletoralsContract is OwnerContract{
    
    AggregatorV3Interface WBTCAggregator = AggregatorV3Interface(WBTCOracleAddress);
    AggregatorV3Interface WETHAggregator = AggregatorV3Interface(WETHOracleAddress);
    AggregatorV3Interface LINKAggregator = AggregatorV3Interface(LINKOracleAddress);
    /*
    AggregatorV3Interface UNIAggregator = AggregatorV3Interface();
    AggregatorV3Interface MATICAggregator = AggregatorV3Interface();
    AggregatorV3Interface QUICKAggregator = AggregatorV3Interface();
    AggregatorV3Interface SOLAggregator = AggregatorV3Interface();
    AggregatorV3Interface PBNBAggregator = AggregatorV3Interface();
    */
    
    function getWBTCPrice() public view returns (uint){
        (, int256 answer,,,) = WBTCAggregator.latestRoundData();
        answer = answer - (answer % 1);
        return uint(answer/10**8);
    }
    
    function getWETHPrice() public view returns (uint){
        (, int256 answer,,,) = WETHAggregator.latestRoundData();
        answer = answer - (answer % 1);
        return uint(answer/10**8);
    }
    
    function getLINKPrice() public view returns (uint){
        (, int256 answer,,,) = LINKAggregator.latestRoundData();
        answer = answer - (answer % 1);
        return uint(answer/10**6);
    }
    /*
    function getUNIPrice() public view returns (uint){
        (, int256 answer,,,) = UNIAggregator.latestRoundData();
        answer = answer - (answer % 1);
        return uint(answer/10**8);
    }
    
    function getMATICPrice() public view returns (int){
        (, int256 answer,,,) = MATICAggregator.latestRoundData();
        answer = answer - (answer % 1);
        return answer/10**8;
    }
    
    function getQUICKPrice() public view returns (int){
        (, int256 answer,,,) = QUICKAggregator.latestRoundData();
        answer = answer - (answer % 1);
        return answer/10**8;
    }
    
    function getSOLPrice() public view returns (int){
        (, int256 answer,,,) = SOLAggregator.latestRoundData();
        answer = answer - (answer % 1);
        return answer/10**8;
    }
    
    function getPBNBPrice() public view returns (int){
        (, int256 answer,,,) = PBNBAggregator.latestRoundData();
        answer = answer - (answer % 1);
        return answer/10**8;
    }
    */
    
}

interface ShareProfitInterface{
    function depositUSDTProfit(uint256 _amount) external;
    function depositUSDCProfit(uint256 _amount) external;
}

abstract contract profitContract is OwnerContract{
    
    event profitContractAddressChanged(address _by, address _to);
    
    ShareProfitInterface ProfitSpread = ShareProfitInterface(profitContractAddress);
    
    function changeProfitReceiver(address _to) public isOwner{
        profitContractAddress = payable(_to);
        ProfitSpread = ShareProfitInterface(profitContractAddress);
        emit profitContractAddressChanged(msg.sender, _to);
    }
    
    IERC20 Stabletoken = IERC20(StabletokenAddress);
}

abstract contract liquidityAddContract is OwnerContract, ColletoralsContract, profitContract{
    uint internal WETHAmount;
    uint internal WBTCAmount;
    uint internal LINKAmount;
    uint internal USDTAmount;
    uint internal USDCAmount;
    uint public result2;
    uint[] public result3;
    
    IUniswapV2Router02 Uniswap = IUniswapV2Router02 (UNISWAP_R_V2);
    
    function swapWETH() public returns (uint[] memory){
        uint _amount = WETHAmount * 7 / 10;
        require(_amount > 0, "Not enough amount of tokens");
        uint timeNow = block.timestamp;
        address[] memory swapPath = new address[](2);
        swapPath[0] = WETHAddress;
        swapPath[1] = USDTAddress;
        uint price = getWETHPrice();
        uint[] memory result = Uniswap.swapExactTokensForTokens(_amount, (_amount * price * 90 / 100), swapPath, address(this), timeNow + 120);
        WETHAmount -= result[0];
        USDTAmount += result[1];
        return result;
    }
    
    function swapWBTC() public returns(uint[] memory){
        uint _amount = WBTCAmount * 7 / 10;
        require(_amount > 0, "Not enough amount of tokens");
        uint timeNow = block.timestamp;
        address[] memory swapPath = new address[](2);
        swapPath[0] = WBTCAddress;
        swapPath[1] = USDCAddress;
        uint price = (9882);
        uint[] memory result = Uniswap.swapExactTokensForTokens(_amount, (_amount * price * 90 / 100), swapPath, address(this), timeNow + 120);
        WBTCAmount -= result[0];
        USDCAmount += result[1];
        return result;
    }
    
    function swapLINK() public returns(uint[] memory){
        uint _amount = LINKAmount * 7 / 10;
        require(_amount > 0, "Not enough amount of tokens");
        uint timeNow = block.timestamp;
        address[] memory swapPath = new address[](2);
        swapPath[0] = LINKAddress;
        swapPath[1] = USDTAddress;
        uint price = getLINKPrice();
        uint[] memory result = Uniswap.swapExactTokensForTokens(_amount, (_amount * (price / 100) * 90 / 100), swapPath, address(this), timeNow + 120);
        LINKAmount -= result[0];
        USDTAmount += result[1];
        return result;
    }
    
    function addLiquidityStable() public{
        if (USDCAmount > USDTAmount && USDCAmount > 0){
            uint _amount = USDCAmount * 7 / 10;
            uint timeNow = block.timestamp;
            Stabletoken.mint(address(this), _amount);
            (uint minted,,) = Uniswap.addLiquidity(StabletokenAddress, USDCAddress, _amount, _amount*(10**10), _amount, _amount*(10**10), address(this), timeNow + 120);
            Stabletoken.burn(address(this), (_amount - minted));
            USDCAmount -= (_amount - minted);
        }
        if(USDTAmount > USDCAmount && USDTAmount > 0){
            uint _amount = USDTAmount * 7 / 10;
            uint timeNow = block.timestamp;
            Stabletoken.mint(address(this), _amount);
            (uint minted,,) = Uniswap.addLiquidity(StabletokenAddress, USDTAddress, _amount, _amount, _amount, _amount, address(this), timeNow + 120);
            Stabletoken.burn(address(this), (_amount - minted));
            USDTAmount -= (_amount - minted);
        }
    }
    
    function swapWBTCandProfit(uint256 _amount) public{
        require(_amount > 0, "Not enough amount of tokens");
        uint timeNow = block.timestamp;
        address[] memory swapPath = new address[](2);
        swapPath[0] = WBTCAddress;
        swapPath[1] = USDCAddress;
        uint price = (9882);
        uint[] memory result = Uniswap.swapExactTokensForTokens(_amount, (_amount * price * 90 / 100), swapPath, address(this), timeNow + 120);
        ProfitSpread.depositUSDCProfit(result[1]);
    }
    
    function swapLINKandProfit(uint256 _amount) public{
        require(_amount > 0, "Not enough amount of tokens");
        uint timeNow = block.timestamp;
        address[] memory swapPath = new address[](2);
        swapPath[0] = LINKAddress;
        swapPath[1] = USDTAddress;
        uint price = getLINKPrice();
        uint[] memory result = Uniswap.swapExactTokensForTokens(_amount, (_amount * (price / 100) * 90 / 100), swapPath, address(this), timeNow + 120);
        ProfitSpread.depositUSDTProfit(result[1]);
    }
    
    function swapWETHandProfit(uint256 _amount) public{
        require(_amount > 0, "Not enough amount of tokens");
        uint timeNow = block.timestamp;
        address[] memory swapPath = new address[](2);
        swapPath[0] = WETHAddress;
        swapPath[1] = USDTAddress;
        uint price = getWETHPrice();
        uint[] memory result = Uniswap.swapExactTokensForTokens(_amount, (_amount * price * 90 / 100), swapPath, address(this), timeNow + 120);
        ProfitSpread.depositUSDTProfit(result[1]);
    }
}

contract StableMintAndBurnContract is profitContract, liquidityAddContract{
    
    uint public profitReceiverPercentage;
    uint public redeemTax;
    uint public referralPercentage;
    
    IERC20 WBTC = IERC20(WBTCAddress);
    IERC20 USDT = IERC20(USDTAddress);
    IERC20 LINK = IERC20(LINKAddress);
    IERC20 WETH = IERC20(WETHAddress);
    IERC20 USDC = IERC20(USDCAddress);
    
    /*
    WETHERC20 UNI = WETHERC20(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    WETHERC20 MATIC = WETHERC20(0x1343A33d5510e95B87166433BCDDd5DbEe8B4D8A);
    */
    
    constructor(){
        redeemTax = 50;
        referralPercentage = 20;
        profitReceiverPercentage = 15;
        WBTC.approve(UNISWAP_R_V2, 9999999**11);
        WETH.approve(UNISWAP_R_V2, 9999999**11);
        USDT.approve(UNISWAP_R_V2, 9999999**11);
        USDC.approve(UNISWAP_R_V2, 9999999**11);
        Stabletoken.approve(UNISWAP_R_V2, 9999999**11);
        USDT.approve(profitContractAddress, 9999999**11);
        USDC.approve(profitContractAddress, 9999999**11);
    }
    
    function approveThem() public {
        WBTC.approve(UNISWAP_R_V2, 9999999**11);
        WETH.approve(UNISWAP_R_V2, 9999999**11);
        USDT.approve(UNISWAP_R_V2, 9999999**11);
        USDC.approve(UNISWAP_R_V2, 9999999**11);
        Stabletoken.approve(UNISWAP_R_V2, 9999999**11);
        USDT.approve(profitContractAddress, 9999999**11);
        USDC.approve(profitContractAddress, 9999999**11);
    }
     
    function mintNewStableWithWETH(uint _amount, address _referral) public {
        require(_amount > 0, "You need to sell at least some tokens");
        uint256 allowance = WETH.allowance(msg.sender, address(this));
        require(allowance >= _amount, "Check the token allowance");
        uint256 price = getWETHPrice();
        WETH.transferFrom(msg.sender, address(this), (_amount*(10000 - referralPercentage)/10000));
        WETH.transferFrom(msg.sender, _referral, _amount*(referralPercentage)/10000);
        Stabletoken.mint(msg.sender, price*_amount);
        WETHAmount += _amount * (redeemTax - profitReceiverPercentage - referralPercentage)/10000;
    }
    
    function mintNewStableWithWBTC(uint _amount, address _referral) public {
        require(_amount > 0, "You need to sell at least some tokens");
        uint256 allowance = WBTC.allowance(msg.sender, address(this));
        require(allowance >= _amount, "Check the token allowance");
        uint256 price = getWBTCPrice() * 10**10;
        WBTC.transferFrom(msg.sender, address(this), (_amount*(10000 - referralPercentage)/10000));
        WBTC.transferFrom(msg.sender, _referral, _amount*(referralPercentage)/10000);
        Stabletoken.mint(msg.sender, price*_amount);
        WBTCAmount += _amount * (redeemTax - profitReceiverPercentage - referralPercentage)/10000;
    }
    
    function mintNewStableWithUSDT(uint _amount, address _referral) public {
        require(_amount > 0, "You need to sell at least some tokens");
        USDT.transferFrom(msg.sender, address(this), (_amount*(10000 - referralPercentage)/10000));
        USDT.transferFrom(msg.sender, _referral, _amount*(referralPercentage)/10000);
        Stabletoken.mint(msg.sender, _amount);
        USDTAmount += _amount * (redeemTax - profitReceiverPercentage - referralPercentage)/10000;
    }
    
    function mintNewStableWithUSDC(uint _amount, address _referral) public {
        require(_amount > 0, "You need to sell at least some tokens");
        uint256 allowance = USDC.allowance(msg.sender, address(this));
        require(allowance >= _amount, "Check the token allowance");
        USDC.transferFrom(msg.sender, address(this), (_amount*(10000 - referralPercentage)/10000));
        USDC.transferFrom(msg.sender, _referral, _amount*(referralPercentage)/10000);
        Stabletoken.mint(msg.sender,  _amount);
        USDCAmount += _amount * (redeemTax - profitReceiverPercentage - referralPercentage)/10000;
    }
    
    function mintNewStableWithLINK(uint _amount, address _referral) public {
        require(_amount > 0, "You need to sell at least some tokens");
        uint256 allowance = LINK.allowance(msg.sender, address(this));
        require(allowance >= _amount, "Check the token allowance");
        uint256 price = getLINKPrice();
        LINK.transferFrom(msg.sender, address(this), (_amount*(10000 - referralPercentage)/10000));
        LINK.transferFrom(msg.sender, _referral, _amount*(referralPercentage)/10000);
        Stabletoken.mint(msg.sender, price * _amount / 100);
        LINKAmount += _amount * (redeemTax - profitReceiverPercentage - referralPercentage)/10000;
    }
    
    function redeemCollateralWETH(uint _amount) public {
        require(_amount > 0, "You need to sell at least some tokens");
        uint256 price = getWETHPrice();
        Stabletoken.burn(msg.sender, _amount);
        WETH.transfer(msg.sender, (_amount / price * (10000 - redeemTax)/10000));
        swapWETHandProfit(_amount / price * (profitReceiverPercentage)/10000);
        swapWETH();
    }
    
    function redeemCollateralWBTC(uint _amount) public {
        require(_amount > 0, "You need to sell at least some tokens");
        uint256 price = getWBTCPrice();
        Stabletoken.burn(msg.sender, _amount);
        WBTC.transfer(msg.sender, (_amount / price * (10000 - redeemTax)/10000 / (10**10)));
        swapWBTCandProfit(_amount / price * (profitReceiverPercentage)/10000 / (10**10));
        swapWBTC();
    }
    
    function redeemCollateralUSDT(uint _amount) public {
        require(_amount > 0, "You need to sell at least some tokens");
        Stabletoken.burn(msg.sender, _amount);
        USDT.transfer(msg.sender, (_amount * (10000 - redeemTax)/10000));
        ProfitSpread.depositUSDTProfit((_amount * (profitReceiverPercentage)/10000));
        addLiquidityStable();
    }
    
    function redeemCollateralUSDC(uint _amount) public {
        require(_amount > 0, "You need to sell at least some tokens");
        Stabletoken.burn(msg.sender, _amount);
        USDC.transfer(msg.sender, (_amount * (10000 - redeemTax)/10000));
        ProfitSpread.depositUSDCProfit((_amount * (profitReceiverPercentage)/10000));
        addLiquidityStable();
    }
    
    function redeemCollateralLINK(uint _amount) public {
        require(_amount > 0, "You need to sell at least some tokens");
        uint256 price = getLINKPrice();
        Stabletoken.burn(msg.sender, _amount);
        LINK.transfer(msg.sender, (_amount / price * ((10000 - redeemTax)/10000) / 100));
        swapLINKandProfit((_amount / price * (profitReceiverPercentage)/10000));
        swapLINK();
    }
    
    function changePercentage(uint _choice ,uint _percentage) public isOwner{
        if (_choice == 0){
            referralPercentage = _percentage;
        }else if(_choice == 1){
            profitReceiverPercentage = _percentage;
        }else if (_choice == 2){
            redeemTax = _percentage;
        }
    }
    
    function changeAddress(uint _choice, address _address) public isOwner{
        if (_choice == 0){WBTCAddress = _address;WBTC = IERC20(WBTCAddress);}
        else if(_choice == 1){USDTAddress = _address;IERC20(USDTAddress);}
        else if(_choice == 2){USDCAddress = _address;IERC20(USDCAddress);}
        else if(_choice == 3){WETHAddress = _address;IERC20(WETHAddress);}
        else if(_choice == 4){LINKAddress = _address;IERC20(LINKAddress);}
        else if(_choice == 5){UNISWAP_R_V2 = _address;Uniswap = IUniswapV2Router02 (UNISWAP_R_V2);}
        else if(_choice == 6){WBTCOracleAddress = _address; WBTCAggregator = AggregatorV3Interface(WBTCOracleAddress);}
        else if(_choice == 7){WETHOracleAddress = _address;WETHAggregator = AggregatorV3Interface(WETHOracleAddress);}
        else if(_choice == 8){LINKOracleAddress = _address;LINKAggregator = AggregatorV3Interface(LINKOracleAddress);}
        else if(_choice == 9){StabletokenAddress = _address;Stabletoken = IERC20(StabletokenAddress);}
    }
    
}