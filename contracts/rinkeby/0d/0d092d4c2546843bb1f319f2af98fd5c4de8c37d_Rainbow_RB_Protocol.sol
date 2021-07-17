pragma solidity 0.6.0;
import "./SafeMath.sol";
import "./RainbowMineInterface.sol";
import "./ERC20Interface.sol";
import "./OraclePriceFeedsInterface.sol";


contract Rainbow_RB_Protocol {
    
    using SafeMath for uint256;
    
    //User Structure
    struct User {
        address name;
        uint256 tokenID;
        //The number of insured assets
        uint256 tokenAmount;
        uint256 tokenPrice;
        uint256 userTotalAssets;

        uint256 startTime;
        uint256 timeType;
    }

    //Token pool Structure
    struct TokenPool {
        uint256 tokenID;
        uint256 tokenAmount;
        uint256 userAmount;
        uint256 tokenPoolAssets;
        uint256 compensateTokenTotal;
        mapping(address => User) users;
    }

    struct PlatformData {
        uint256 totalInsuranceCount;
        uint256 totalInsuranceCount_current;
        uint256 totalCompensation;
        uint256 totalAssets;
        uint256 tokenTotal;// Token total
        uint256 licenseFees;
    }

    struct PlatformFundManage {
        uint256 cost_1;//fees
        uint256 totalCost_1;
    }

    //TokenID protocol
    mapping(uint256 => address) public tokenIDProtocol;
    
    //TokenID protocol remove
    mapping(address => uint256) public tokenIDProtocol_remove;
    
    //Token Pool management
    mapping(uint256 => TokenPool) private tokenPools;

    //Platform for money
    PlatformFundManage private costManage;

    // Contract address
    address payable owner;

    //Usdt addres
    address public daiAddress;
     //rainbowRewardAddress
    address public rainbowRewardAddress;

    //Environmental statistics
    PlatformData private dataStatistics;

    address public mineManagerAddress;
    address public openOnlinePriceAddress;

    //Whether to limit the balance of insurance assets,default:0
    int256 public isBalanceLimit;
    
    uint256 constant public DAY = 24 * 60 * 60;

    event SetGuaranteeToken(uint256 tokenID,address tokenAddress);
    event SetUSAddress(address usAddr);
    event Deposit(uint256 tokenID,uint256 totalAssetsStart,uint256 price);
    event WithdrawAssets(uint256 tokenID,uint256 userAssetsStart,uint256 loseAssets,uint256 price);

    /*
     *@dev Init
     */
    constructor() public {
        costManage = PlatformFundManage({cost_1: 0,totalCost_1: 0});
        owner = msg.sender;
        dataStatistics = PlatformData({totalInsuranceCount: 0,totalAssets: 0,totalInsuranceCount_current: 0,totalCompensation: 0,tokenTotal: 0,licenseFees: 35});
        isBalanceLimit = 0;
    }
    
     modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /*
        time    ==      fees
    */
    function getTimeInfoWithTimeType(uint256 timeType) public view returns(uint256 timePeriod,uint256 timeFees){
        if(timeType == 1){
            timePeriod =  1 * DAY;
            timeFees = 35;
        }else if(timeType == 2){
            timePeriod = 3 * DAY;
            timeFees = 50;
        }else if(timeType == 3){
            timePeriod = 5 * DAY;
            timeFees = 70;
        }else if(timeType == 4){
            timePeriod = 7 * DAY;
            timeFees = 100;
        }else if(timeType == 5){
            timePeriod = 14 * DAY;
            timeFees = 150;
        }else if(timeType == 6){
            timePeriod = 28 * DAY;
            timeFees = 200;
        }else{
            timePeriod = 7 * DAY;
            timeFees = 100;
        }
    }

    /*
        state   ==  1   ==  TokenID error !
        state   ==  2   ==  No insurance assets
        state   ==  3   ==  Expired order
        state   ==  10  ==  Valid order
    */
    function orderVerification(uint256 _tokenType)public view returns(uint256 state,uint256 surplusTime){
        if(_tokenType >= dataStatistics.tokenTotal){
            return(1,0);
        }
        //Match Route
        TokenPool storage pool = matchRoute(_tokenType);
        //Out Token Pool
        User storage user = pool.users[msg.sender];
        if(user.tokenAmount == 0){
            return(2,0);
        }

        (,uint256 timePeriod) = getTimeInfoWithTimeType(user.timeType);
        if(now < (user.startTime + timePeriod)){
            return(10,user.startTime + timePeriod - now);
        }else{
            return(3,0);
        }
    }

    function removeInsurance(uint256 _tokenID,address _tokenAddress)public onlyOwner {
        require(_tokenAddress != address(0),"RemoveInsurance error .");
        require(_tokenID < dataStatistics.tokenTotal,"RemoveInsurance tokenID error .");
        require(tokenIDProtocol[_tokenID] == _tokenAddress,"RemoveInsurance no Match .");
        
        tokenIDProtocol_remove[_tokenAddress] = 10;
    }
    
    function reStartInsurance(address _tokenAddress)public onlyOwner {
        require(_tokenAddress != address(0),"RemoveInsurance error .");
        require(tokenIDProtocol_remove[_tokenAddress] == 10,"No Remove");
        tokenIDProtocol_remove[_tokenAddress] = 0;
    }

    function setBalanceLimit(int256 _balanceLimit) public onlyOwner {
        isBalanceLimit = _balanceLimit;
    }

    function setMineManager(address _addr)public onlyOwner {
        require(_addr != address(0),"Mine address error .");
        mineManagerAddress = _addr;
    }

    function setOnlinePricesPredictedMachine(address _addr)public onlyOwner {
        require(_addr != address(0),"OnlinePricesPredictedMachine address error .");
        openOnlinePriceAddress = _addr;
    }

    function setRainbowRewardAddress(address _addr)public onlyOwner {
        require(_addr != address(0),"rainbowRewardAddress error .");
        rainbowRewardAddress = _addr;
    }

    function transferOwnership(address payable newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

    //Set the agreement fee
    function setLicenseFeesValue(uint256 _fees) public onlyOwner{
        dataStatistics.licenseFees = _fees;
    }
    
    //Set guarantee token
    function addInsuranceToken(uint256 _tokenID,address _tokenAddress) public onlyOwner{
        require(tokenIDProtocol[_tokenID] == address(0),"Token is already supported.");
        require(_tokenAddress != address(0),"Invalid token address .");
        require(_tokenID == dataStatistics.tokenTotal,"TokenID error !");
        require(_tokenAddress != daiAddress,"tokenAddress error .");
        tokenIDProtocol[_tokenID] = _tokenAddress;
        dataStatistics.tokenTotal = dataStatistics.tokenTotal.add(1);
        distributionTokenPool(_tokenID);
    }

    //Get the token address corresponding to tokenID
    function getTokenAddressForTokenID(uint256 _tokenID) public view onlyOwner returns(address){
        return tokenIDProtocol[_tokenID];
    }

    //Set US dollar address  -》 usdt
    function setDaiAddress(address _daiAddr) public onlyOwner{
        require(_daiAddr != address(0),"Invalid token address .");
        daiAddress = _daiAddr;
        emit SetUSAddress(_daiAddr);
    }



    /*
       token supports the eth-token，usdt-token
    */
    function depositCalculation(
        uint256 _tokenType,
        uint256 _tokenAmount,
        uint256 _timeType
    )external view returns(uint256 payUsdts){
        if(tokenIDProtocol[_tokenType] == address(0)){
            //tokenID error .
            return 0;
        }
        if(openOnlinePriceAddress == address(0)){
            //openOnlinePriceAddress no init .
            return 1;
        }
        if(mineManagerAddress == address(0)){
            //MineManagerAddress no init .
            return 2;
        }
        if(tokenIDProtocol[_tokenType] == daiAddress){
            //token error .
            return 3;
        }
        if(_tokenAmount == 0){
            //token 0 .
            return 4;
        }
        OraclePriceFeeds onlinePriceManager = OraclePriceFeeds(openOnlinePriceAddress);
        (uint256 isValid,uint256 tokenToUsdtPrice) = onlinePriceManager.getPriceTokenToUsdt(tokenIDProtocol[_tokenType]);
        if(isValid != 10){
            //no support，tokenToUsdtPrice error .
            return 5;
        }
        if(tokenToUsdtPrice == 0){
            //tokenToUsdtPrice 0,abnormal.
            return 6;
        }

        //Open balance limit
        if(isBalanceLimit > 0){
            ERC20 insuranceToken = ERC20(tokenIDProtocol[_tokenType]);
            if(insuranceToken.balanceOf(msg.sender) < _tokenAmount){
                //Lack of balance .
                return 7;
            }
        }
        
        uint256 totalAssets = mulDiv(_tokenAmount,tokenToUsdtPrice,1e8);
        (,uint256 timeFees) = getTimeInfoWithTimeType(_timeType);
        payUsdts = mulDiv(totalAssets,timeFees,10000);
        return payUsdts;
    }


    //Insured assets
    function deposit(
        uint256 _tokenType,
        uint256 _tokenAmount,
        uint256 _payUsdts,
        uint256 _timeType
    )external payable {
        address tokenAddress = tokenIDProtocol[_tokenType];
        require(tokenAddress != address(0),"Unsupported tokens .");
        require(tokenIDProtocol_remove[tokenAddress] != 10,"Remove Token");
        require(openOnlinePriceAddress != address(0),"openOnlinePriceAddress no init .");
        require(mineManagerAddress != address(0),"MineManagerAddress no init .");
        require(tokenIDProtocol[_tokenType] != daiAddress,"token error .");
        require(rainbowRewardAddress != address(0),"rainbowRewardAddress no init .");
        require(_tokenAmount > 0,"token 0 .");
        require(_payUsdts > 0,"PayUsdts 0 .");
        require(_timeType >0 && _timeType < 7,"deposit: timeType error !");
        
        {
            (uint256 state,) = orderVerification(_tokenType);
            require(state != 10,"deposit: Order exists, error!");
        }
        
        ERC20 usdt = ERC20(daiAddress);
        ERC20 insuranceToken = ERC20(tokenIDProtocol[_tokenType]);
        uint256 tokenToUsdtPrice = 0;
        {
            if(isBalanceLimit > 0){
                require(insuranceToken.balanceOf(msg.sender) >= _tokenAmount,"Lack of balance .");
            }
            uint256 approveAmount = usdt.allowance(msg.sender,address(this));
            require(approveAmount >= _payUsdts,"PayUsdts approve error .");
            OraclePriceFeeds onlinePriceManager = OraclePriceFeeds(openOnlinePriceAddress);
            (uint256 isValid,uint256 _tokenToUsdtPrice) = onlinePriceManager.getPriceTokenToUsdt(tokenIDProtocol[_tokenType]);
            require(isValid == 10,"no support.");
            require(_tokenToUsdtPrice > 0,"TokenToUsdtPrice Abnormal.");
            tokenToUsdtPrice = _tokenToUsdtPrice;
        }
        
        uint256 totalAssets = mulDiv(_tokenAmount,tokenToUsdtPrice,1e8);
        (,uint256 timeFees) = getTimeInfoWithTimeType(_timeType);
        uint256 licenseFees = 0;
        {
            uint256 payUsdts = mulDiv(totalAssets,timeFees,10000);
            //Time deviation, resulting in value deviation, secondary verification
            uint256 maxDeviation = mulDiv(_payUsdts,5,100);
            require(payUsdts < _payUsdts.add(maxDeviation),"The price deviation is too big . UP");
            if(payUsdts > _payUsdts){
                require(usdt.transferFrom(msg.sender,rainbowRewardAddress,_payUsdts),"Deposit TransferFrom fails .");
                licenseFees = _payUsdts;
            }else{
                require(usdt.transferFrom(msg.sender,rainbowRewardAddress,payUsdts),"Deposit TransferFrom fails .");
                licenseFees = payUsdts;
            }
        }

        {
                TokenPool storage pool = matchRoute(_tokenType);
                User storage user = pool.users[msg.sender];
                
                costManage.cost_1 = costManage.cost_1.add(licenseFees);
                costManage.totalCost_1 = costManage.totalCost_1.add(licenseFees);
                
                pool.userAmount = pool.userAmount + 1;
                pool.tokenAmount = pool.tokenAmount + _tokenAmount;
                pool.tokenPoolAssets = pool.tokenPoolAssets + totalAssets;
                
                user.name = msg.sender;
                user.tokenID = _tokenType;
                user.tokenAmount = _tokenAmount;
                user.userTotalAssets = totalAssets;
                user.tokenPrice = tokenToUsdtPrice;
                user.startTime = now;
                user.timeType = _timeType;

                dataStatistics.totalAssets = dataStatistics.totalAssets.add(totalAssets);
                dataStatistics.totalInsuranceCount = dataStatistics.totalInsuranceCount.add(1);
                dataStatistics.totalInsuranceCount_current = dataStatistics.totalInsuranceCount_current.add(1);
        }
        emit Deposit(_tokenType,totalAssets,tokenToUsdtPrice);
    }
    

    //Distribute token pool
    function distributionTokenPool(uint256 _tokenID) private{
        tokenPools[_tokenID] = TokenPool({
            tokenID: _tokenID,
            tokenAmount: 0,
            userAmount: 0,
            tokenPoolAssets: 0,
            compensateTokenTotal: 0
        });
    }

    // Match Route
    function matchRoute(uint256 _tokenType)
        private
        view
        returns (TokenPool storage)
    {
        return tokenPools[_tokenType];
    }


    //Withdraw asset
    function withdrawAssets(uint256 _tokenType) external{
        require(_tokenType < dataStatistics.tokenTotal, "TokenID error !");

        (uint256 state,) = orderVerification(_tokenType);
        require(state == 10,"withdrawAssets:Invalid order, error !");

        //Match Route
        TokenPool storage pool = matchRoute(_tokenType);
        //Out Token Pool
        User storage user = pool.users[msg.sender];
        require(user.tokenAmount > 0,"No insurance assets");

        OraclePriceFeeds onlinePriceManager = OraclePriceFeeds(openOnlinePriceAddress);
        (uint256 isValid,uint256 tokenToUsdtPrice) = onlinePriceManager.getPriceTokenToUsdt(tokenIDProtocol[_tokenType]);
        require(isValid == 10,"no support.");
        require(tokenToUsdtPrice > 0,"TokenToUsdtPrice Abnormal.");

        ERC20 insuranceToken = ERC20(tokenIDProtocol[_tokenType]);
        uint256 tokenBalance = insuranceToken.balanceOf(msg.sender);
        uint256 settleAmount = 0;
        uint256 userAssertsStart = 0;
        if(isBalanceLimit > 0){
            if(user.tokenAmount > tokenBalance){
                settleAmount = tokenBalance;
                userAssertsStart = mulDiv(tokenBalance,user.tokenPrice,1e8);
            }else{
                settleAmount = user.tokenAmount;
                userAssertsStart = user.userTotalAssets;
            }
        }else{
            settleAmount = user.tokenAmount;
            userAssertsStart = user.userTotalAssets;
        }
        
        if(settleAmount == 0){
            pool.userAmount = pool.userAmount - 1;
            pool.tokenAmount = pool.tokenAmount - user.tokenAmount;
            pool.tokenPoolAssets = pool.tokenPoolAssets -user.userTotalAssets;
            user.tokenAmount = 0;
            user.userTotalAssets = 0;
            user.tokenPrice = 0;
            user.startTime = 0;
            user.timeType = 0;
            dataStatistics.totalInsuranceCount_current = dataStatistics.totalInsuranceCount_current.sub(1);
            emit WithdrawAssets(_tokenType,0,0,0);
        }else{
            require(userAssertsStart > 0,"userAssertsStart error .");
            uint256 userAssetsEnd = mulDiv(settleAmount,tokenToUsdtPrice,1e8);
            uint256 loseAssets = 0;
            uint256 compensateToken = 0;
            if(userAssetsEnd < userAssertsStart){
                //lose
                loseAssets = userAssertsStart - userAssetsEnd;
                compensateToken = RainbowMine(mineManagerAddress).startMine(userAssertsStart,loseAssets,msg.sender);
            }
            
            pool.userAmount = pool.userAmount.sub(1);
            pool.tokenAmount = pool.tokenAmount.sub(user.tokenAmount);
            pool.tokenPoolAssets = pool.tokenPoolAssets.sub(user.userTotalAssets);
            pool.compensateTokenTotal = pool.compensateTokenTotal.add(compensateToken);
            user.tokenAmount = 0;
            user.userTotalAssets = 0;
            user.tokenPrice = 0;
            user.timeType = 0;
            user.startTime = 0;
            dataStatistics.totalInsuranceCount_current = dataStatistics.totalInsuranceCount_current.sub(1);
            emit WithdrawAssets(_tokenType,userAssertsStart,loseAssets,tokenToUsdtPrice);
        }
    }

    function getUserClaimAmount(uint256 _tokenType)public view returns(uint256 _tokenAmount,uint256 _tokenStartPrice,uint256 _tokenEndPrice,uint256 _userTokens){
         //Match Route
        TokenPool storage pool = tokenPools[_tokenType];
        //Out Token Pool
        User storage user = pool.users[msg.sender];
        if(user.tokenAmount == 0){
            return(0,0,0,0);
        }
        OraclePriceFeeds onlinePriceManager = OraclePriceFeeds(openOnlinePriceAddress);
        (uint256 isValid,uint256 tokenToUsdtPrice) = onlinePriceManager.getPriceTokenToUsdt(tokenIDProtocol[_tokenType]);
        if(isValid != 10){
            //no support，tokenToUsdtPrice error .
            return (0,1,0,0);
        }
        if(tokenToUsdtPrice == 0){
            //tokenToUsdtPrice 0,abnormal.
            return (0,2,0,0);
        }
        ERC20 insuranceToken = ERC20(tokenIDProtocol[_tokenType]);
        uint256 tokenBalance = insuranceToken.balanceOf(msg.sender);
        uint256 settleAmount = 0;
        uint256 userAssertsStart = 0;
        if(isBalanceLimit > 0){
            if(user.tokenAmount > tokenBalance){
                settleAmount = tokenBalance;
                userAssertsStart = mulDiv(settleAmount,user.tokenPrice,1e8);
            }else{
                settleAmount = user.tokenAmount;
                userAssertsStart = user.userTotalAssets;
            }
        }else{
            settleAmount = user.tokenAmount;
            userAssertsStart = user.userTotalAssets;
        }
        
        _tokenAmount = settleAmount;
        _tokenStartPrice = user.tokenPrice;
        _tokenEndPrice = tokenToUsdtPrice;
        if(settleAmount == 0){
           return(0,3,0,0);
        }else{
            uint256 userAssetsEnd = mulDiv(settleAmount,tokenToUsdtPrice,1e8);
            if(userAssetsEnd < userAssertsStart){
                //lose
                uint256 loseAssets = userAssertsStart - userAssetsEnd;
                (,_userTokens) = (RainbowMine(mineManagerAddress).getUserClaimAmount(userAssertsStart,loseAssets,msg.sender));
            }else{
                _userTokens = 0;
            }
        }
    }

    function getUserInsuranceAmount(uint256 _tokenType)public view returns(uint256 _tokenAmount){
        TokenPool storage pool = tokenPools[_tokenType];
        User storage user = pool.users[msg.sender];
        _tokenAmount = user.tokenAmount;
    }

    // Get token pool Info
    function getTokenPoolInfo(uint256 _tokenType) public view returns (uint256,uint256,uint256,uint256)
    {
        TokenPool storage pool = tokenPools[_tokenType];
        return (pool.tokenAmount,pool.userAmount,pool.tokenPoolAssets,pool.compensateTokenTotal);
    }
    
    function getPlatformInfo_Current() public view returns (uint256,uint256,uint256){
        uint256 totalAssets = 0;//usdt
        for(uint i = 0;i<(dataStatistics.tokenTotal);i++){
            TokenPool storage pool = tokenPools[i];
            if(pool.tokenAmount >0){
                totalAssets = pool.tokenPoolAssets.add(totalAssets);
            }
        }
        return (costManage.cost_1,totalAssets,dataStatistics.totalInsuranceCount);
    }

    //Gets the total assets processed by the platform
    function getPlatformInfo_ever() public view returns (uint256,uint256,uint256){
        return (dataStatistics.totalAssets,dataStatistics.totalInsuranceCount,costManage.totalCost_1);
    }

    function getLicenseFees()public view returns(uint256){
        return dataStatistics.licenseFees;
    }

    // Receive ETH
    fallback() external payable {}
    receive() external payable {}

    function mulDiv (uint256 _x, uint256 _y, uint256 _z) public pure returns (uint256) {
        uint256 temp = _x.mul(_y);
        return temp.div(_z);
    }
}