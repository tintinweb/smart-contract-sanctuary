// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;
import "./Ecocelium_Initializer.sol";

/*

███████╗░█████╗░░█████╗░░█████╗░███████╗██╗░░░░░██╗██╗░░░██╗███╗░░░███╗
██╔════╝██╔══██╗██╔══██╗██╔══██╗██╔════╝██║░░░░░██║██║░░░██║████╗░████║
█████╗░░██║░░╚═╝██║░░██║██║░░╚═╝█████╗░░██║░░░░░██║██║░░░██║██╔████╔██║
██╔══╝░░██║░░██╗██║░░██║██║░░██╗██╔══╝░░██║░░░░░██║██║░░░██║██║╚██╔╝██║
███████╗╚█████╔╝╚█████╔╝╚█████╔╝███████╗███████╗██║╚██████╔╝██║░╚═╝░██║
╚══════╝░╚════╝░░╚════╝░░╚════╝░╚══════╝╚══════╝╚═╝░╚═════╝░╚═╝░░░░░╚═╝

Brought to you by Kryptual Team */

contract zeroLock is Initializable {
    
    IAbacusOracle abacus;
    EcoMoneyManager EMM;
    EcoceliumInit Init;
    enum Status {CLOSED, ACTIVE} 

    /*============Mappings=============
    ----------------------------------*/
    mapping (address => uint64[]) public userLock;
    mapping (uint64 => string) public tokenMap;
    mapping (uint64 => uint) public orderDuration;
    mapping (uint64 => uint) public orderAmount;
    mapping (uint64 => uint) public orderTime;
    mapping (string => History[]) public tokenPriceHistory; //TimeID
    mapping (string => rHistory[]) public tokenRateHistory; //TimeID
    mapping (address => uint) public rewardWithdrawls;
    mapping (address => Withdrawls[]) public freeAssetsWithdrawl;
    
    /*=========Structs and Initializer================
    --------------------------------*/    

    struct History{
        uint value;
        uint startDate;
        uint endDate;
    }
    
    struct Withdrawls {
        string token;
        uint amount;
    }
    
    function initializeAddress(address payable EMMaddress,address AbacusAddress, address payable Initaddress) external initializer{
            EMM = EcoMoneyManager(EMMaddress);
            abacus = IAbacusOracle(AbacusAddress); 
            Init = EcoceliumInit(Initaddress);
    }

    // get length of withdrawHistory array
    function withdrawHistory() public view returns(uint) {
        return freeAssetsWithdrawl[msg.sender].length;
    }
    
    function easyDeposit(string memory rtoken ,uint _amount) external payable {
        uint _duration = 0;
    	address payable userAddress = msg.sender;
        string memory _tokenSymbol = EMM.getWrapped(rtoken);
        _deposit(rtoken, _amount, userAddress, _tokenSymbol);
        (uint64 _orderId,uint newAmount,uint fee) = _ordersub(_amount, userAddress, _duration, _tokenSymbol);
    	Init.setOwnerFeeVault(rtoken, fee);
        (orderTime[_orderId], orderAmount[_orderId], orderDuration[_orderId]) =  (now, newAmount, _duration);
    	tokenMap[_orderId] = _tokenSymbol;
    	userLock[userAddress].push(_orderId);
        EMM.mintWrappedToken(userAddress, newAmount, _tokenSymbol);
        EMM.lockWrappedToken(userAddress, newAmount,_tokenSymbol);
    }

    function _deposit(string memory rtoken, uint _amount, address msgSender, string memory wtoken) internal {
        require(EMM.getwTokenAddress(wtoken) != address(0),"Invalid Token Address");
        if(keccak256(abi.encodePacked(rtoken)) == keccak256(abi.encodePacked(Init.ETH_SYMBOL()))) { 
            require(msg.value >= _amount);
            EMM.DepositManager{ value:msg.value }(rtoken, _amount, msgSender);
        } else {
        EMM.DepositManager(rtoken, _amount, msgSender); }
    }

    function easyWithdraw(string memory rtoken, uint amount) external {
        string memory _WToken = EMM.getWrapped(rtoken);
    	require(getUserFreeAsset(msg.sender, _WToken) >= amount , "Insufficient Balance");
        EMM.releaseWrappedToken(msg.sender,amount, _WToken);
        EMM.burnWrappedFrom(msg.sender, amount, _WToken);
        freeAssetsWithdrawl[msg.sender].push(Withdrawls({
                                            amount : amount,
                                            token : _WToken}));
    	EMM.WithdrawManager(rtoken, amount, msg.sender);
    }
    
    
    function withdrawEarning(uint amount) external {
        require(getECOEarnings(msg.sender) >= amount , "Insufficient Balance");
        rewardWithdrawls[msg.sender] += amount;
        EMM.WithdrawManager(Init.ECO(), amount, msg.sender);
    }
    
    function getECOEarnings(address userAddress) public view returns (uint earnings){
        for(uint i=0; i<userLock[userAddress].length; i++) {
            earnings += calculateECOEarning(tokenMap[userLock[userAddress][i]], orderTime[userLock[userAddress][i]],  orderAmount[userLock[userAddress][i]], orderDuration[userLock[userAddress][i]], 0);}
        earnings -= rewardWithdrawls[userAddress];
    }
    
    function calculateECOEarning(string memory _tokenSymbol, uint time, uint _amount, uint duration, uint dID) public view returns (uint reward){
        uint meanECOPrice;
        uint meanTokenPrice;
        //string memory eECO = Init.WRAP_ECO_SYMBOL();
        uint expiry = (now - time) + time; //time+(duration*30 days);
        meanTokenPrice = meanPriceFinder(_tokenSymbol, time, expiry>now?now:expiry);
        meanECOPrice = meanPriceFinder(Init.WRAP_ECO_SYMBOL(), time, expiry>now?now:expiry);
        uint meanEarnRate = findLockRate(time, dID, _tokenSymbol);
        uint amount = _amount*meanTokenPrice*(10**8)/(meanECOPrice*(10**uint(wERC20(EMM.getwTokenAddress(_tokenSymbol)).decimals())));
        reward += (amount * meanEarnRate *(now>expiry ? expiry-time : now-time))/(3153600000);
    }
    
    function meanPriceFinder(string memory _token, uint time, uint endtime) public view returns (uint meanTokenPrice) {
        uint sT = time;
        for(uint i=0 ; i<tokenPriceHistory[_token].length ; i++) { 
            uint eD = tokenPriceHistory[_token][i].endDate==0?now:tokenPriceHistory[_token][i].endDate;
            uint eT = endtime<=eD?endtime:eD;
            if((time>tokenPriceHistory[_token][i].startDate && time<eD)) {
                meanTokenPrice += tokenPriceHistory[_token][i].value * (eT - sT) ; 
                if(endtime>eD) { sT= tokenPriceHistory[_token][i+1].startDate; }
            }
        }
        meanTokenPrice = meanTokenPrice/(now>endtime ? endtime-time : now-time);
    }
    
     /*==============Helpers============
    ---------------------------------*/   
    
    function getUserLock(address userAddress, string memory token) public view returns (uint locked) {
        for(uint i=0; i<userLock[userAddress].length; i++) {
            if(((now-orderTime[userLock[userAddress][i]])<(orderDuration[userLock[userAddress][i]]*30 days)) && (keccak256(abi.encodePacked(token)) == keccak256(abi.encodePacked(tokenMap[userLock[userAddress][i]])))){
                locked += orderAmount[userLock[userAddress][i]];
            }
        }
    }
    
    function _ordersub(uint amount,address userAddress,uint _duration,string memory _tokenSymbol) internal view returns (uint64, uint, uint){
        uint newAmount = amount - (amount*Init.tradeFee())/100;
        uint fee = (amount*Init.tradeFee())/100;
        uint64 _orderId = uint64(uint(keccak256(abi.encodePacked(userAddress,_tokenSymbol,_duration,now))));
        return (_orderId,newAmount,fee);
    }
    
    function totalDeposit(address userAddress, string memory rtoken) public view returns (uint total) {
        for(uint i=0; i<userLock[userAddress].length; i++) {
            if(keccak256(abi.encodePacked(rtoken)) == keccak256(abi.encodePacked(tokenMap[userLock[userAddress][i]]))){
                total += orderAmount[userLock[userAddress][i]];
            }
        }
    }

    function getUserFreeAsset(address userAddress, string memory rtoken) public view returns (uint freeAssets) {
        for(uint i=0; i<userLock[userAddress].length; i++) {
            if(((now-orderTime[userLock[userAddress][i]])>(orderDuration[userLock[userAddress][i]]*30 days)) && (keccak256(abi.encodePacked(rtoken)) == keccak256(abi.encodePacked(tokenMap[userLock[userAddress][i]])))){
                freeAssets += orderAmount[userLock[userAddress][i]];
            }
        }    
        for(uint i=0; i<freeAssetsWithdrawl[userAddress].length; i++) {
            if(keccak256(abi.encodePacked(rtoken)) == keccak256(abi.encodePacked(freeAssetsWithdrawl[userAddress][i].token))){
                freeAssets -= freeAssetsWithdrawl[userAddress][i].amount;
            }
        }   
    }

    function getOrderStatus(uint64 _orderId) public view returns (bool) {
    	return ((now-orderTime[_orderId])<(orderDuration[_orderId]*30 days)); 
    }

    function changeRate(string memory token, uint _value) external {
        require(Init.friendlyaddress(msg.sender) ,"Not Friendly Address");
        uint dID = 0;
        tokenRateHistory[token][tokenRateHistory[token].length-1].endDate = now;
        tokenRateHistory[token].push(rHistory({dID: dID, value : _value, startDate: now, endDate: 0 }));
    }
    
    function changePrice(string memory token, uint _value) external {
        require(Init.friendlyaddress(msg.sender) ,"Not Friendly Address");
        tokenPriceHistory[token][tokenPriceHistory[token].length-1].endDate = now;
        tokenPriceHistory[token].push(History({value : _value, startDate: now, endDate: 0 }));
    }
    
    function superRateManager(string memory token, uint _value, uint time, uint endDate) external {
        require(Init.friendlyaddress(msg.sender) ,"Not Friendly Address");
        uint dID = 0;
        tokenRateHistory[token].push(rHistory({dID: dID, value : _value, startDate: time, endDate: endDate }));
    }
    
    function superPriceManager(string memory token, uint _value, uint time, uint endDate) external {
        require(Init.friendlyaddress(msg.sender) ,"Not Friendly Address");
        tokenPriceHistory[token].push(History({value : _value, startDate: time, endDate: endDate }));
    }
    
    function superUserManager(address userAddress, string memory rtoken ,uint _amount, uint time) external {
        require(Init.friendlyaddress(msg.sender) ,"Not Friendly Address");
        string memory _tokenSymbol = EMM.getWrapped(rtoken);
        uint _duration = 0;
        (uint64 _orderId,uint newAmount,uint fee) = _ordersub(_amount, userAddress, _duration, _tokenSymbol);
    	Init.setOwnerFeeVault(rtoken, fee);
        (orderTime[_orderId], orderAmount[_orderId], orderDuration[_orderId]) =  (time, newAmount, _duration);
    	tokenMap[_orderId] = _tokenSymbol;      
    	userLock[userAddress].push(_orderId);
    }
    
    function priceHistoryFn (string memory wtoken, uint index) public view returns (uint, uint , uint) {
        return (tokenPriceHistory[wtoken][index].value, tokenPriceHistory[wtoken][index].startDate, tokenPriceHistory[wtoken][index].endDate);
    }
    
    function rateHistoryFn (string memory wtoken, uint index) public view returns (uint, uint , uint, uint) {
        return (tokenRateHistory[wtoken][index].dID, tokenRateHistory[wtoken][index].value, tokenRateHistory[wtoken][index].startDate, tokenRateHistory[wtoken][index].endDate);
    }

    receive() payable external {     } 

    //Update 0.1 - Changes -> Fixing Rate for customers
    struct rHistory{
        uint dID;
        uint value;
        uint startDate;
        uint endDate;
    }
    
    function findLockRate(uint _time, uint _dID, string memory _tokenSymbol) public view returns (uint) {
        // tokenRateHistory[_tokenSymbol][i].dID==_dID &&
        for(uint i=0; i<tokenRateHistory[_tokenSymbol].length;i++) {
            if(tokenRateHistory[_tokenSymbol][i].startDate < _time && (_time<(tokenRateHistory[_tokenSymbol][i].endDate==0?now:tokenRateHistory[_tokenSymbol][i].endDate))) return tokenRateHistory[_tokenSymbol][i].value;
        }
    }
    
    function getUserLockID(address userAddress) public view returns (uint64 [] memory) {
        return userLock[userAddress];
         }
    }