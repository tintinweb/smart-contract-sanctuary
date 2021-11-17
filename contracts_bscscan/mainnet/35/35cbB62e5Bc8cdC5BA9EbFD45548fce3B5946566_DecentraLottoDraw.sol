pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: Unlicensed

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";



//DecentraLotto Interface
interface IDecentraLotto {
  function CHARITY_WALLET (  ) external view returns ( address );
  function _burnFee (  ) external view returns ( uint256 );
  function _charityFee (  ) external view returns ( uint256 );
  function _liquidityFee (  ) external view returns ( uint256 );
  function _maxTxAmount (  ) external view returns ( uint256 );
  function _previousCharityFee (  ) external view returns ( uint256 );
  function _tBurnTotal (  ) external view returns ( uint256 );
  function _taxFee (  ) external view returns ( uint256 );
  function allowance ( address owner, address spender ) external view returns ( uint256 );
  function approve ( address spender, uint256 amount ) external returns ( bool );
  function balanceOf ( address account ) external view returns ( uint256 );
  function buybackBurn ( uint256 amount ) external;
  function decimals (  ) external pure returns ( uint8 );
  function decreaseAllowance ( address spender, uint256 subtractedValue ) external returns ( bool );
  function excludeFromFee ( address account ) external;
  function excludeFromReward ( address account ) external;
  function geUnlockTime (  ) external view returns ( uint256 );
  function includeInFee ( address account ) external;
  function includeInReward ( address account ) external;
  function increaseAllowance ( address spender, uint256 addedValue ) external returns ( bool );
  function isExcludedFromFee ( address account ) external view returns ( bool );
  function isExcludedFromReward ( address account ) external view returns ( bool );
  function lock ( uint256 time ) external;
  function name (  ) external pure returns ( string memory );
  function owner (  ) external view returns ( address );
  function reflectionFromToken ( uint256 tAmount, bool deductTransferFee ) external view returns ( uint256 );
  function renounceOwnership (  ) external;
  function setCharityFeePercent ( uint256 charityFee ) external;
  function setCharityWallet ( address _charityWallet ) external;
  function setLiquidityFeePercent ( uint256 liquidityFee ) external;
  function setMaxTxPercent ( uint256 maxTxPercent ) external;
  function setRouterAddress ( address newRouter ) external;
  function setSwapAndLiquifyEnabled ( bool _enabled ) external;
  function setTaxFeePercent ( uint256 taxFee ) external;
  function swapAndLiquifyEnabled (  ) external view returns ( bool );
  function symbol (  ) external pure returns ( string memory );
  function tokenFromReflection ( uint256 rAmount ) external view returns ( uint256 );
  function totalDonated (  ) external view returns ( uint256 );
  function totalFees (  ) external view returns ( uint256 );
  function totalSupply (  ) external view returns ( uint256 );
  function transfer ( address recipient, uint256 amount ) external returns ( bool );
  function transferFrom ( address sender, address recipient, uint256 amount ) external returns ( bool );
  function transferOwnership ( address newOwner ) external;
  function uniswapV2Pair (  ) external view returns ( address );
  function uniswapV2Router (  ) external view returns ( address );
  function unlock (  ) external;
  function withdrawEth ( uint256 amount ) external;
}

interface IDELOStaking {
    function ADDFUNDS(uint256 tokens) external;
}

abstract contract RandomNumberConsumer is VRFConsumerBase {
    
    bytes32 internal keyHash;
    uint256 internal fee;
    
    uint256 public randomResult;
    
    //contracts: https://docs.chain.link/docs/vrf-contracts/
    //faucets: https://docs.chain.link/docs/link-token-contracts/
    constructor(address _vrfCoordinator, address _link, bytes32 _keyHash, uint256 _fee) 
        VRFConsumerBase(
            _vrfCoordinator, // VRF Coordinator
            _link  // LINK Token
        ) public
    {
        keyHash = _keyHash;
        fee = _fee; // 0.1 LINK for testnet, 0.2 LINK for Live (Varies by network)
    }
    
    /** 
     * Requests randomness 
     */
    function getRandomNumber() internal returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        return requestRandomness(keyHash, fee);
    }
}

contract DrawInterface {
    struct NewDraw {
        uint256 id;
        uint32 numParticipants;
        uint32 numTickets;
        address[] winners;
        mapping (uint256 => address) tickets;
        mapping (address => uint256) walletSpendBNB;
        mapping (address => uint16) walletNumTickets;
        mapping (address => uint256) walletWinAmount;
        // A unix timestamp, denoting the created datetime of this draw
        uint256 createdOn;
        // A unix timestamp, denoting the end of the draw
        uint256 drawDeadline;
        uint256 totalPot;
        LotteryState state;
    }  
    
    enum LotteryState{
        Open,
        Closed,
        Ready,
        Finished
    }
}

contract DecentraLottoDraw is Context, Ownable, RandomNumberConsumer, DrawInterface {
    using Address for address;
    
    IERC20 weth;
    IDecentraLotto delo;
    IDELOStaking deloStaking;
    
    address public deloAddress = 0xC91B4AA7e5C247CB506e112E7FEDF6af7077b90A;
    address public deloStakingAddress = 0xd06e418850Cc6a29a9e8a99ddb8304730367b55D;
    address public peg = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56; // busd
    address public wethAddress = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; //wbnb
    address public megadrawWallet = 0x1e714e7DAAb6886920726059960b4A8f68F319e8;
    
    mapping (address => bool) public stablesAccepted;
    
    uint256 public drawLength;
    mapping (uint16 => NewDraw) public draws;
    uint16 public currentDraw = 0;

    mapping (address => uint16) private walletTotalTicketsPurchased;
    
    mapping (address => uint16) private walletTotalWins;
    mapping (address => uint256) private walletTotalWinValueDelo;
    
    mapping (address => uint16) private walletTotalCharityTickets;
    mapping (address => uint256) private totalAirdropsReceived;
    
    mapping (address => bool) public charityRecipients;

    uint256 public priceOneTicket = 10 *10**18;
    uint8 public maxTicketsPerTxn = 60;
    uint8 public discountFiveTickets = 5;
    uint8 public discountTenTickets = 10;
    uint8 public discountTwentyTickets = 20;
    
    uint8 public liquidityDivisor = 20; //5%
    uint8 public marketingDivisor = 10; //10%
    uint8 public hedgeDivisor = 10; //10%
    uint8 public stakingDivisor = 5; //20%
    uint8 public megadrawDivisor = 20; //5%
    bool public takeLiquidity = true;
    bool public takeMarketing = false;
    bool public takeHedge = true;
    bool public takeStaking = true;
    bool public takeMegadraw = true;
    
    bool public stopNextDraw = false;
    uint public maxWinners = 40;
    bytes32 private requestId;
    
    IUniswapV2Router02 public uniswapV2Router;
    bool private inSwapAndLiquify;

    constructor () 
        RandomNumberConsumer(
            0x747973a5A2a4Ae1D3a8fDF5479f1514F65Db9C31, //vrfCoordinator
            0x404460C6A5EdE2D891e8297795264fDe62ADBB75, //link address
            0xc251acd21ec4fb7f31bb8868288bfdbaeb4fbfec2df3735ddbd4f7dc8d60103c, //key hash
            0.2 * 10 ** 18 //fee
        ) public {
        uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        delo = IDecentraLotto(deloAddress);
        deloStaking = IDELOStaking(deloStakingAddress);
        weth = IERC20(wethAddress);
        drawLength = 1 * 1 weeks;
        stablesAccepted[0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56] = true; //busd
        stablesAccepted[0x1AF3F329e8BE154074D8769D1FFa4eE058B1DBc3] = true; //dai
        stablesAccepted[0x55d398326f99059fF775485246999027B3197955] = true; //usdt
        stablesAccepted[0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d] = true; //usdc
        
        //change state to finished
        _changeState(LotteryState.Finished);
    }
    
    event LotteryStateChanged(LotteryState newState);
    
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );
    
    event TicketsBought(address indexed user, uint256 amount);
    event GetRandom(bytes32 requestId);
    event GotRandom(uint256 randomNumber);
    event WinnerPaid(address indexed user, uint256 amount);
    event DrawCreated(uint256 id);
    
    modifier isState(LotteryState _state){
        NewDraw storage draw = draws[currentDraw];
        require(draw.state == _state, "Wrong state for this action");
        _;
    }
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    //@dev - a failsafe just in case the state is stuck somewhere and we need to re-trigger the drawWinners()
    function changeStateEmergency(LotteryState _newState) external onlyOwner {
        NewDraw storage draw = draws[currentDraw];
        draw.state = _newState;
        emit LotteryStateChanged(draw.state);
    }
    
    function _changeState(LotteryState _newState) private {
        NewDraw storage draw = draws[currentDraw];
        draw.state = _newState;
        emit LotteryStateChanged(draw.state);
    }
    
    function setStopNextDraw(bool _stopNextDraw) external onlyOwner{
        stopNextDraw = _stopNextDraw;
    }
    
    function setMaxTicketsPerTxn(uint8 _maxTicketsPerTxn) external onlyOwner{
        maxTicketsPerTxn = _maxTicketsPerTxn;
    }
    
    function setMaxWinners(uint amt) external onlyOwner{
        maxWinners = amt;
    }
    
    function setMegadrawWallet(address _address) external onlyOwner{
        megadrawWallet = _address;
    }
    
    function setDeloStakingAddress(address _address) external onlyOwner{
        deloStakingAddress = _address;
        deloStaking = IDELOStaking(deloStakingAddress);
    }
    
    function setPegAddress(address _address) external onlyOwner{
        peg = _address;
    }
    
    function setWETHAddress(address _address) external onlyOwner{
        wethAddress = _address;
    }
    
    function setRouterAddress(address newRouter) external onlyOwner() {
        IUniswapV2Router02 _newPancakeRouter = IUniswapV2Router02(newRouter);
        uniswapV2Router = _newPancakeRouter;
    }
    
    function setTicketPrice(uint256 _priceOneTicket) external onlyOwner{
        priceOneTicket = _priceOneTicket;
    }
    
    function setDiscounts(uint8 _discountFiveTickets, uint8 _discountTenTickets, uint8 _discountTwentyTickets) external onlyOwner{
        discountFiveTickets = _discountFiveTickets;
        discountTenTickets = _discountTenTickets;
        discountTwentyTickets = _discountTwentyTickets;
    }
    
    function addCharityRecipient(address _charity) external onlyOwner{
        charityRecipients[_charity] = true;
    }
    
    function removeCharityRecipient(address _charity) external onlyOwner{
        charityRecipients[_charity] = false;
    }
    
    function setLiquidityDivisor(uint8 _liqdiv) external onlyOwner{
        liquidityDivisor = _liqdiv;
    }
    
    function setMarketingDivisor(uint8 _markdiv) external onlyOwner{
        require(_markdiv >= 5, "Cannot set over 20% marketing allocation");
        marketingDivisor = _markdiv;
    }
    
    function setHedgeDivisor(uint8 _hedgediv) external onlyOwner{
        hedgeDivisor = _hedgediv;
    }
    
    function setStakingDivisor(uint8 _stakingdiv) external onlyOwner{
        stakingDivisor = _stakingdiv;
    }
    
    function setMegadrawDivisor(uint8 _megadrawDivisor) external onlyOwner{
        megadrawDivisor = _megadrawDivisor;
    }
    
    function toggleTakeLiquidity(bool _liq) external onlyOwner{
        takeLiquidity = _liq;
    }
    
    function toggleTakeMarketing(bool _mark) external onlyOwner{
        takeMarketing = _mark;
    }
    
    function toggleTakeHedge(bool _hedge) external onlyOwner{
        takeHedge = _hedge;
    }
    
    function toggleTakeStaking(bool _takeStaking) external onlyOwner{
        takeStaking = _takeStaking;
    }
    
    function toggleTakeMegadraw(bool _takeMegadraw) external onlyOwner{
        takeMegadraw = _takeMegadraw;
    }
    
    function removeStablePayment(address _stable) external onlyOwner{
        stablesAccepted[_stable] = false;
    }
    
    //withdraw dust
    function withdrawBNB(uint256 amount) external onlyOwner {
        msg.sender.transfer(amount);
    }
    
    //withdraw token link or trapped tokens
    function withdrawToken(address _address, uint256 amount) external onlyOwner {
        // Ensure requested tokens isn't DELO (cannot withdraw the pot)
        require(_address != deloAddress, "Cannot withdraw Lottery pot");
        IERC20 token = IERC20(_address);
        token.transfer(msg.sender, amount);
    }
    
    function setDrawLength(uint multiplier, uint unit) external onlyOwner returns(bool){
        if (unit == 1){
            drawLength = multiplier * 1 seconds;
        }else if (unit == 2){
            drawLength = multiplier * 1 minutes;
        }else if (unit == 3){
            drawLength = multiplier * 1 hours;
        }else if (unit == 4){
            drawLength = multiplier * 1 days;
        }else if (unit == 5){
            drawLength = multiplier * 1 weeks;
        }
        
        return true;
    }
    
    function updateLengthOfCurrentDraw(uint multiplier, uint unit) external onlyOwner returns(bool){
        NewDraw storage draw = draws[currentDraw];
        uint dlen;
        if (unit == 1){
            dlen = multiplier * 1 seconds;
        }else if (unit == 2){
            dlen = multiplier * 1 minutes;
        }else if (unit == 3){
            dlen = multiplier * 1 hours;
        }else if (unit == 4){
            dlen = multiplier * 1 days;
        }else if (unit == 5){
            dlen = multiplier * 1 weeks;
        }
        draw.drawDeadline = draw.createdOn + dlen;
        return true;
    }
    
    function getWalletWinAmountForDraw(uint16 _id, address winner) external view returns(uint){
        NewDraw storage draw = draws[_id];
        return draw.walletWinAmount[winner];
    }
    
    function getDrawStats(uint16 _id) external view returns(uint, uint, address[] memory, uint256, uint256, uint256, uint256, LotteryState, uint){
        NewDraw storage draw = draws[_id];
        return (
            draw.id, 
            draw.numParticipants, 
            draw.winners,
            draw.numTickets, 
            draw.createdOn, 
            draw.drawDeadline,
            draw.totalPot,
            draw.state,
            getNumberWinners()
        );
    }
    
    function getDrawStats() external view returns(uint, uint, address[] memory, uint256, uint256, uint256, uint256, LotteryState, uint){
        NewDraw storage draw = draws[currentDraw];
        return (
            draw.id, 
            draw.numParticipants, 
            draw.winners,
            draw.numTickets, 
            draw.createdOn, 
            draw.drawDeadline, 
            draw.totalPot,
            draw.state,
            getNumberWinners()
        );
    }
    
    function getDrawWalletStats(uint16 _id) external view returns (uint, uint, uint256, uint256, uint256, uint256, uint256){
        NewDraw storage draw = draws[_id];
        return (
            draw.walletSpendBNB[msg.sender], 
            draw.walletNumTickets[msg.sender],
            walletTotalTicketsPurchased[msg.sender],
            walletTotalWins[msg.sender],
            walletTotalWinValueDelo[msg.sender],
            walletTotalCharityTickets[msg.sender],
            totalAirdropsReceived[msg.sender]
        );
    }
    
    function getDrawWalletStats() external view returns (uint, uint, uint256, uint256, uint256, uint256, uint256){
        NewDraw storage draw = draws[currentDraw];
        return (
            draw.walletSpendBNB[msg.sender], 
            draw.walletNumTickets[msg.sender],
            walletTotalTicketsPurchased[msg.sender],
            walletTotalWins[msg.sender],
            walletTotalWinValueDelo[msg.sender],
            walletTotalCharityTickets[msg.sender],
            totalAirdropsReceived[msg.sender]
        );
    }
    
    function getCurrentPot() public view returns(uint256){
        uint256 deloBal = delo.balanceOf(address(this));
        return deloBal - deloBal.div(liquidityDivisor) - deloBal.div(megadrawDivisor);
    }
    
    // to be able to manually trigger the next draw if the previous one was stopped
    function createNextDrawManual() external onlyOwner returns(bool){
        NewDraw storage draw = draws[currentDraw];
        require(draw.state == LotteryState.Finished, 'Cannot create new draw until winners drawn from previous.');
        return createNextDraw();
    }
    
    function createNextDraw() private returns(bool){
        currentDraw = currentDraw + 1;
        NewDraw storage draw = draws[currentDraw];
        draw.id = currentDraw;
        draw.numTickets = 0;
        draw.createdOn = now;
        draw.drawDeadline = draw.createdOn + drawLength;
        draw.numParticipants = 0;
        _changeState(LotteryState.Open);
        emit DrawCreated(draw.id);
    }
    
    function getNumberWinners() public view returns(uint){
        uint numWinners = 0;
        uint256 deloCost = getTicketCostInDelo();
        uint256 bal = delo.balanceOf(address(this)).div(2);
        while (bal >= deloCost && numWinners <= maxWinners){
            bal = bal.sub(bal.div(2));
            numWinners++;
        }
        return numWinners;
    }
    
    function drawWinners() public isState(LotteryState.Ready) returns(bool){
        NewDraw storage draw = draws[currentDraw];
        
        _changeState(LotteryState.Finished);

        //seed for abi encoding random number
        uint seed = 1;
        
        //only execute while the winning amount * 2 is more than the balance
        uint256 deloCost = getTicketCostInDelo();
        
        draw.totalPot = delo.balanceOf(address(this));
        
        while (delo.balanceOf(address(this)).div(2) >= deloCost && seed <= maxWinners){
            //pick a random winner
            address winner = draw.tickets[(uint256(keccak256(abi.encode(randomResult, seed))).mod(draw.numTickets))];
            //add them to the winners array
            draw.winners.push(winner);
            //increment their wins
            walletTotalWins[winner]++;
            //add their win value
            uint256 amt = delo.balanceOf(address(this)).div(2);
            walletTotalWinValueDelo[winner] += amt;
            draw.walletWinAmount[winner] += amt;
            //transfer their winnings
            delo.transfer(winner, amt);
            //increment the seed
            seed = seed + 1;
            emit WinnerPaid(winner, amt);
        }
        
        randomResult = 0;

        if (stopNextDraw == false){
            createNextDraw();
        }
    }
    
    /**
        * Callback function used by VRF Coordinator
    */
    function fulfillRandomness(bytes32 _requestId, uint256 randomness) internal override {
        require (requestId == _requestId, "requestId doesn't match");
        
        randomResult = randomness;
        
        _changeState(LotteryState.Ready);
        
        emit GotRandom(randomResult);
    }
    
    function endDrawAndGetRandom() external isState(LotteryState.Open) returns(bool){
        NewDraw storage draw = draws[currentDraw];
        require (now > draw.drawDeadline, 'Draw deadline not yet reached');
        
        _changeState(LotteryState.Closed);
        
        //take liquidityDivisor of the total jackpot and add it to liquidity of the DELO token
        uint256 jackpotTotal = delo.balanceOf(address(this));
        if (takeLiquidity == true && inSwapAndLiquify == false){
            //% to liquidity
            swapAndLiquify(jackpotTotal.div(liquidityDivisor));
        }
        
        //take themegadraw allotment
        if (takeMegadraw == true){
            //take megadraw % to be accumulated for megadraws
            delo.transfer(megadrawWallet, jackpotTotal.div(megadrawDivisor));
        }
        
        //get random number
        requestId = getRandomNumber();
        
        GetRandom(requestId);
        
        return true;
    }
    
    function getPriceForTickets(address tokenAddress, uint numTickets) public view returns(uint256){
        uint256 cost = 0;
        uint256 price;
        if (numTickets >= 20){
            price = priceOneTicket - priceOneTicket.mul(discountTwentyTickets).div(100);
        }else if(numTickets >= 10){
            price = priceOneTicket - priceOneTicket.mul(discountTenTickets).div(100);
        }else if(numTickets >= 5){
            price = priceOneTicket - priceOneTicket.mul(discountFiveTickets).div(100);
        }else{
            price = priceOneTicket;
        }
        
        //returns the amount of bnb needed
        if (tokenAddress == uniswapV2Router.WETH()){
            address[] memory path = new address[](2);
            path[0] = uniswapV2Router.WETH();
            path[1] = peg;
            uint256[] memory amountIn = uniswapV2Router.getAmountsIn(price, path);
            cost = amountIn[0] * numTickets;
        }else{
            if (stablesAccepted[tokenAddress] == true){
                cost = price * numTickets;
            }else{
                revert('Stable not accepted as payment');
            }
        }
        return cost;
    }
    
    function getDELOValueInPeg(uint256 amt) external view returns(uint256[] memory){
        address[] memory path = new address[](3);
        path[0] = deloAddress;
        path[1] = uniswapV2Router.WETH();
        path[2] = peg;
        uint256[] memory amountOut = uniswapV2Router.getAmountsOut(amt, path);
        return amountOut;
    }
    
    function getDELOValueInBNB(uint256 amt) external view returns(uint256[] memory){
        address[] memory path = new address[](2);
        path[0] = deloAddress;
        path[1] = uniswapV2Router.WETH();
        uint256[] memory amountOut = uniswapV2Router.getAmountsOut(amt, path);
        return amountOut;
    }
    
    function getBNBValueInDelo(uint256 amt) external view returns(uint256[] memory){
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = deloAddress;
        uint256[] memory amountOut = uniswapV2Router.getAmountsOut(amt, path);
        return amountOut;
    }
    
    function getPEGValueInDelo(uint256 amt) external view returns(uint256[] memory){
        address[] memory path = new address[](3);
        path[0] = peg;
        path[1] = uniswapV2Router.WETH();
        path[2] = deloAddress;
        uint256[] memory amountOut = uniswapV2Router.getAmountsOut(amt, path);
        return amountOut;
    }
    
    function getTicketCostInDelo() public view returns(uint256){
        address[] memory path = new address[](3);
        path[0] = deloAddress;
        path[1] = uniswapV2Router.WETH();
        path[2] = peg;
        uint256[] memory amountIn = uniswapV2Router.getAmountsIn(priceOneTicket, path);
        return amountIn[0];
    }
    
    function buyTicketsBNB(uint16 numTickets, address recipient, address airDropRecipient) payable external isState(LotteryState.Open) returns(bool){
        NewDraw storage draw = draws[currentDraw];
        require (now < draw.drawDeadline, 'Ticket purchases have ended for this draw');
        require (recipient != address(0), 'Cannot buy a ticket for null address');
        require (numTickets <= maxTicketsPerTxn, 'You are trying to buy too many tickets in this TXN');
        
        uint256 cost = getPriceForTickets(wethAddress, numTickets);
        require (msg.value >= cost, 'Insufficient amount. More BNB required for purchase.');
        
        processTransaction(cost, numTickets, recipient, airDropRecipient);
        
        //refund any excess
        msg.sender.transfer(msg.value - cost);
        
        return true;
    }
    
    //approve must first be called by msg.sender
    function buyTicketsStable(address tokenAddress, uint16 numTickets, address recipient, address airdropRecipient) isState(LotteryState.Open) external returns(bool){
        NewDraw storage draw = draws[currentDraw];
        require (now < draw.drawDeadline, 'Ticket purchases have ended for this draw');
        require (recipient != address(0), 'Cannot buy a ticket for null address');
        require (numTickets <= maxTicketsPerTxn, 'You are trying to buy too many tickets in this TXN');
        
        uint256 price = getPriceForTickets(tokenAddress, numTickets);
        
        require (price > 0, 'Unsupported token provided as payment');
            
        IERC20 token = IERC20(tokenAddress);
        
        require(token.allowance(msg.sender, address(this)) >= price, "Check the token allowance");
        require(token.balanceOf(msg.sender) >= price, "Insufficient balance");
        
        uint256 initialTokenBal = token.balanceOf(address(this));
        token.transferFrom(msg.sender, address(this), price);
        uint256 tokenAmount = token.balanceOf(address(this)).sub(initialTokenBal);
            
        uint bnbValue = 0;
        
        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;
        
        swapTokensForEth(tokenAddress, tokenAmount);
        
        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);
        
        bnbValue = newBalance;
        
        return processTransaction(bnbValue, numTickets, recipient, airdropRecipient);
    }
    
    function assignTickets(uint256 bnbValue, uint16 numTickets, address receiver) isState(LotteryState.Open) private returns(bool){
        NewDraw storage draw = draws[currentDraw];
        //only add a new participant if the wallet has not purchased a ticket already
        if (draw.walletNumTickets[receiver] <= 0){
            draw.numParticipants++;
        }
        
        //add the wallet for each ticket they purchased
        uint32 num = draw.numTickets;
        for (uint i=0; i < numTickets; i++){
            draw.tickets[num] = receiver;
            num += 1;
        }
        draw.numTickets = num;
        draw.walletNumTickets[receiver] += numTickets;
        walletTotalTicketsPurchased[receiver] += numTickets;
        
        draw.walletSpendBNB[receiver] += bnbValue;
        draw.totalPot = getCurrentPot();
        
        emit TicketsBought(receiver, numTickets);
        
        return true;
    }
    
    function processTransaction(uint256 bnbValue, uint16 numTickets, address recipient, address airdropRecipient) isState(LotteryState.Open) private returns(bool){
        uint256 initialTokenBal = delo.balanceOf(address(this));
        
        //take the marketing amount in bnb
        if (takeMarketing == true){
            bnbValue = bnbValue.sub(bnbValue.div(marketingDivisor));
        }
        
        //swap the bnb from the ticket sale for DELO
        swapEthForDelo(bnbValue);
        uint256 tokenAmount = delo.balanceOf(address(this)).sub(initialTokenBal);
        
        if (takeHedge == true){
            //give % of purchase back to purchaser, or to ticket recipient, or to charity recipient (if that address is authorised)
            if (airdropRecipient == msg.sender || airdropRecipient == recipient || charityRecipients[airdropRecipient] == true){
                totalAirdropsReceived[airdropRecipient] += tokenAmount.div(hedgeDivisor);
                delo.transfer(airdropRecipient, tokenAmount.div(hedgeDivisor));
            }
            //record the amount of ticket airdrops the purchaser donated to charity
            if (charityRecipients[airdropRecipient] == true){
                walletTotalCharityTickets[msg.sender] += numTickets;
            }
        }
        
        if (takeStaking == true){
            //call the ADDFUNDS method of staking contract to reward stakers
            uint256 amt = tokenAmount.div(stakingDivisor);
            delo.approve(deloStakingAddress, amt);
            deloStaking.ADDFUNDS(amt);
        }
        
        return assignTickets(bnbValue, numTickets, recipient);
    }
    
    //to receive ETH from uniswapV2Router when swapping
    receive() external payable {}
    
    function swapTokensForEth(address _token, uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = _token;
        path[1] = uniswapV2Router.WETH();

        IERC20 token = IERC20(_token);
        token.approve(address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETH(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }
    
    function swapTokensWithFeeForEth(address _token, uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = _token;
        path[1] = uniswapV2Router.WETH();

        IERC20 token = IERC20(_token);
        token.approve(address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }
    
    function swapEthForDelo(uint256 ethAmount) private {
        // generate the uniswap pair path of weth -> token
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = deloAddress;

        // make the swap
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmount}(
            0, // accept any amount of token
            path,
            address(this),
            block.timestamp
        );
    }
    
    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // split the contract balance into halves
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensWithFeeForEth(deloAddress, half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);
        
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }
    
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        delo.approve(address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            deloAddress,
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this), // add liquidity to the contract
            block.timestamp
        );
    }
    
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

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
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./vendor/SafeMathChainlink.sol";

import "./interfaces/LinkTokenInterface.sol";

import "./VRFRequestIDBase.sol";

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {

  using SafeMathChainlink for uint256;

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(bytes32 requestId, uint256 randomness)
    internal virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 constant private USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(bytes32 _keyHash, uint256 _fee)
    internal returns (bytes32 requestId)
  {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed  = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash].add(1);
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface immutable internal LINK;
  address immutable private vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 /* keyHash */ => uint256 /* nonce */) private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(address _vrfCoordinator, address _link) public {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathChainlink {
  /**
    * @dev Returns the addition of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `+` operator.
    *
    * Requirements:
    * - Addition cannot overflow.
    */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  /**
    * @dev Returns the subtraction of two unsigned integers, reverting on
    * overflow (when the result is negative).
    *
    * Counterpart to Solidity's `-` operator.
    *
    * Requirements:
    * - Subtraction cannot overflow.
    */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath: subtraction overflow");
    uint256 c = a - b;

    return c;
  }

  /**
    * @dev Returns the multiplication of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `*` operator.
    *
    * Requirements:
    * - Multiplication cannot overflow.
    */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  /**
    * @dev Returns the integer division of two unsigned integers. Reverts on
    * division by zero. The result is rounded towards zero.
    *
    * Counterpart to Solidity's `/` operator. Note: this function uses a
    * `revert` opcode (which leaves remaining gas untouched) while Solidity
    * uses an invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    * - The divisor cannot be zero.
    */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath: division by zero");
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
    * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
    * Reverts when dividing by zero.
    *
    * Counterpart to Solidity's `%` operator. This function uses a `revert`
    * opcode (which leaves remaining gas untouched) while Solidity uses an
    * invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    * - The divisor cannot be zero.
    */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);
  function approve(address spender, uint256 value) external returns (bool success);
  function balanceOf(address owner) external view returns (uint256 balance);
  function decimals() external view returns (uint8 decimalPlaces);
  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);
  function increaseApproval(address spender, uint256 subtractedValue) external;
  function name() external view returns (string memory tokenName);
  function symbol() external view returns (string memory tokenSymbol);
  function totalSupply() external view returns (uint256 totalTokensIssued);
  function transfer(address to, uint256 value) external returns (bool success);
  function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract VRFRequestIDBase {

  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(bytes32 _keyHash, uint256 _userSeed,
    address _requester, uint256 _nonce)
    internal pure returns (uint256)
  {
    return  uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(
    bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}