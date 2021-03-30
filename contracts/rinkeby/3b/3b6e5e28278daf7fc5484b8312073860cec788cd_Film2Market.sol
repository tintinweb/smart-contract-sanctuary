pragma solidity >=0.6.0;

import './F2M-Libraries.sol';

contract Film2Market {

    IUniswapV2Router02 public router;
    IERC20 public USDERC20;
    IERC20 public CBKERC20;
    OracleF2M public oracle;
    IUniswapV2Pair public pair;
    
    address payable public admin;
    address private liquidityManager;
    address private USD;
    address private CBK;
    
    uint public deadline;
    uint public minReserves;
    uint public liquiPercent;
    uint public buyPercent;
    uint public slippage;
    uint public maxSlippage;
    
    mapping(address => bool) public isWhitelist;
    mapping(address => uint) public redeemed;
    mapping(address => uint) public price;
    mapping(address => uint) public bought;
    mapping(address => bool) public hasRedeemed;
    mapping(address => bool) public openToCommunity;
    mapping(address => uint) public communityPrice;
    mapping(address => bool) public offerEndedWithoutSuccess;
    mapping(address => mapping (address => uint)) public deposited;


    event Bought(address client, uint amount);
    event UserWhitelisted(address client, uint amount);
    event Redeemed(address client, uint amount);
    event NewTokenOpened(address token, uint price);
    event OfferEndedWithoutSuccess(address token, uint balance, uint price);
    event DepositClaimed(address user, address token, uint amount);
    event CommunityRedeemed(address user, uint amount);
    

    constructor (address _router, address _USD, address _CBK, address _pair) public {
        router = IUniswapV2Router02(_router);
        pair = IUniswapV2Pair(_pair);
        admin = payable(msg.sender);
        liquidityManager = msg.sender;
        USD = _USD;
        CBK = _CBK;
        USDERC20 = IERC20(_USD);
        CBKERC20 = IERC20(_CBK);
        deadline = 1640995199;
        slippage = 30;
        maxSlippage = 500;
        liquiPercent = 900;
        buyPercent = 100;
    }
    
    //This modifier requires a user to be the admin to interact with some functions.
    modifier onlyOwner() {
        require(msg.sender == admin, "Only the owner is allowed to access this function.");
        _;
    }
    
    //This modifier requires a user to be whitelisted to interact with some functions. Only the admin can whitelist users.
    modifier whitelist() {
        require(isWhitelist[msg.sender] == true, "Only whitelisted addresses are allowed to access this function.");
        _;
    }
    
    //Admin can whitelist users to interact with this smartcontract, Only whitelisted users will be able to buy() and redeem() CBK tokens from F2M.
    function whitelistUser(address user, uint amount) onlyOwner public {
        isWhitelist[user] = true;
        price[user] = amount;
        emit UserWhitelisted(user, amount);
    }

    //Admin can add a new token open for community voting/pooling
    function openToken(address _token, uint _price) onlyOwner public {
        openToCommunity[_token] = true;
        communityPrice[_token] = _price;
        offerEndedWithoutSuccess[_token] = false;
        emit NewTokenOpened(_token, _price);
    }
    
    //Admin can set the minimun USD reserves required in Uniswap's pair to change buy() functionality from "adding liquidity and buying" to "buying".
    function setMinReserves(uint newMin) onlyOwner public {
        minReserves = newMin;
    }
    
    //Admin can transfer control of this smartcontract to a different address.
    function changeAdmin(address payable newAdmin) onlyOwner public {
        admin = newAdmin;
    }
    
    //Admin can transfer destination of the LP tokens to a different admin address.
    function changeLiquidityManager(address _newManager) onlyOwner public {
        liquidityManager = _newManager;
    }
    
    //Admin can set uniswap's deadline.
    function newDeadline(uint _newDeadline) onlyOwner public {
        deadline = _newDeadline;
    }

    //Admin can set the oracle address.
    function newOracle(address _Oracle) onlyOwner public {
        oracle = OracleF2M(_Oracle);
    }

    //Admin can set default slippage and maxSlippage values.
    //Set in ‰ (_slippage = 10 = 1%).
    function presetSlippage(uint _newSlippage, uint _maxSlippage) onlyOwner public {
        slippage = _newSlippage;
        maxSlippage = _maxSlippage;
    }
    
    //Admin can set the percentages that are added to liquidity and bought from uniswap in the buy() function.
    //Set in ‰ (10 = 1%)
    function setPercentages(uint _toLiquidity, uint _toBuy) onlyOwner public {
        require(_toLiquidity <= 1000);
        require(_toBuy <= 1000);
        liquiPercent = _toLiquidity;
        buyPercent = _toBuy;
    }
    
    //Admin can approve the router 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D to spend CBK and USD. Needed to interact with Uniswap.
    function approveUNI() onlyOwner public {
        uint amnt = 1000000000 ether;
        CBKERC20.approve(address(router), amnt);
        USDERC20.approve(address(router), amnt);
    }
    
     //Admin can end the redeemCommunity of a token. If it that has not fulfilled the price, it allow users to claim back deposited tokens.
    function endOffer(address token) onlyOwner public {
        offerEndedWithoutSuccess[token] = true;
        emit OfferEndedWithoutSuccess(token, IERC20(token).balanceOf(address(this)), communityPrice[token]);
    }
    
    //This function reads current Uniswap's reserves.
    function reserves() public view returns (uint, uint) {
        (uint a, uint b, ) = pair.getReserves();
        return(a, b);
    }
    
    //This function is a protection against frontrunning attempts by bots, if currentPrice differs more than safePrice + or - slippage it will fail.
    function noFrontRun(uint usdAmount, uint cbkAmount, uint _slippage) internal view returns(bool){
        uint oraclePrice = oracle.consult(CBK, cbkAmount);
        uint safeMin = (oraclePrice*1000)/(1000+_slippage);
        uint safeMax = (oraclePrice*1000)/(1000-_slippage);
        bool isValid;
        if (usdAmount <= safeMax && usdAmount >= safeMin) {
            isValid = true;
        }
        return (isValid);
    }

    //This function allows whitelisted users to buy CBK tokens with a preset slippage, to use a custom slippage % use buyWithSlippage(). 
    function buyDefault(uint amountCBK) whitelist public {
        buy(amountCBK, slippage, deadline);
    }

    //This function allows whitelisted users to buy CBK tokens with a custom slippage which is set in ‰ (_slippage = 10 = 1%).
    //If Uniswap's USD reserves are lower than minReserves, the smartcontract will first add liquidity and buy after,
    //according to the percentage set in liquiPercent
    //If Uniswap's USD reserves are higher than minReserves, the smartcontract will buy the USD percentage set in buyPercent.
    //This function was designed to provide liquidity to CBK while optimizing the producer's revenue.
    function buy(uint amountCBK, uint _slippage, uint _deadline) whitelist public {
        require(bought[msg.sender] + amountCBK <= price[msg.sender], "Amount exceeds allowance");
        require(amountCBK <= CBKERC20.balanceOf(address(this)));
        require(_slippage <= maxSlippage);
        (uint a, uint b) = reserves();
        uint amountUSD = router.quote(amountCBK, b, a);
        require(noFrontRun(amountUSD, amountCBK, _slippage) == true, "Oracle: Price is out of range");
        require(USDERC20.transferFrom(msg.sender, address(this), amountUSD));
        address[] memory path = new address[](2);
        path[0] = address(USD);
        path[1] = address(CBK);
        if(a < minReserves) {
            uint toBuy = addUni(amountUSD, a, b, _deadline);
            buyUni(toBuy, 0, path, _deadline);
        } else if(a >= minReserves) {
            buyUni(amountUSD*buyPercent/1000, 0, path, _deadline);
            USDERC20.transfer(admin, USDERC20.balanceOf(address(this)));
        }
        bought[msg.sender] += amountCBK;
        CBKERC20.transfer(msg.sender, amountCBK);
        emit Bought(msg.sender, amountCBK);
    }
    
    //This internal function adds liquidity to Uniswap's pair.
    function addUni(uint amountA, uint reservesA, uint reservesB, uint _deadline) internal returns(uint){
        uint toLiquidity = amountA*liquiPercent/1000;
        uint amountB = router.quote(toLiquidity, reservesA, reservesB);
        router.addLiquidity(USD, CBK, toLiquidity, amountB, toLiquidity, amountB, liquidityManager, _deadline);
        return(amountA-toLiquidity);
    }
    
    //This internal function buys CBK from Uniswap.
    function buyUni(uint amountIn, uint amountOutMin, address[] memory path, uint _deadline) internal {
        router.swapExactTokensForTokens(amountIn, amountOutMin, path, address(this), _deadline);
    }
    
    
    //Admin can withdraw any ERC20 token held in this smartcontract.
    function adminWithdraw(address token) onlyOwner public {
        IERC20(token).transfer(admin, IERC20(token).balanceOf(address(this)));
    }
    
    //Admin can withdraw ETH held in this smartcontract.
    function adminWithdrawETH() onlyOwner public {
        payable(msg.sender).transfer(address(this).balance);
    }
    
    //This function allows whitelisted users to redeem CBK tokens in order to pay for Product Placement.
    //Each user must negotiate privately with the producer before being able to purchase marketing activities related with the documentary.
    function redeem(uint amount) whitelist public {
        require(hasRedeemed[msg.sender] = false);
        uint burnAmount = amount/20;
        CBKERC20.burn(burnAmount);
        require(CBKERC20.transferFrom(msg.sender, liquidityManager, amount - burnAmount));
        redeemed[msg.sender] += amount;
        if(redeemed[msg.sender] >= price[msg.sender]) {
            hasRedeemed[msg.sender] = true;
            emit Redeemed(msg.sender, redeemed[msg.sender]);
        }
    }

    //The community can deposit tokens of projects that have an open offer.
    //If the soft-cap is not reached, users can claim back their tokens after the admin has ended the offer without succes.
    function redeemCommunity(address token, uint amount) public {
        require(openToCommunity[token] == true);
        require(IERC20(token).transferFrom(msg.sender, address(this), amount));
        deposited[token][msg.sender] += amount;
        uint tokenBalance = IERC20(token).balanceOf(address(this));
        if(tokenBalance >= communityPrice[token]) {
            openToCommunity[token] = false;
            emit CommunityRedeemed(token, tokenBalance);
        } 
    }

    //The owner can convert an arbitrary amount of third-party tokens to CBK in Uniswap
    function pushToUni(uint amount, uint amountOutMin, address[] memory path, uint _deadline) onlyOwner public {
        buyUni(amount, amountOutMin, path, _deadline);
    }

}