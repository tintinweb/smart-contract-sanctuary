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

contract EcoceliumDataManager is Initializable {
    
    IAbacusOracle abacus;
    EcoMoneyManager EMM;
    EcoceliumInit Init;
    enum Status {OPENCREATOR, OPENBORROW, MATCHED, CLOSED} 

    /*============Mappings=============
    ----------------------------------*/
    mapping (string => uint64[]) public orderpool;  //is an always sorted array based on Yield Rate of Pending Orders for all currencies
    mapping (string => uint) public poolindex;  //Index of First Investor Bid for all currencies
    
    mapping (address => User) public users;
    //mapping (address => address) public sponsorAddress; //FOR TREASURY PLAN
    mapping (uint64 => Status) public orderStatus;
    mapping (uint64 => matchedOrder) public matchOrderMap;
    mapping (uint64 => Order) public openOrderMap;
    
    /*=========Structs and Initializer================
    --------------------------------*/    
    
    struct freeStorage{     //USER DEPOSIT / BORROW STRUCTURE
        uint amount;
        uint time;
        string wtoken;
        uint usdvalue;
    }
    
    struct matchedOrder{            //RUNNING OR MATCHED ORDERS IN THIS FORM
        address supplier;
        address borrower;
        uint time;
        uint expiryDate;
        uint duration;
        uint amount;
        uint usdvalue;
        uint yield;
        string wtoken;
        uint duesPaid;
    }

    struct Order{       // PENDING ORDERS IN THIS FORMAT
        address creator;
        uint duration;
        uint amount;
        uint yield;
        string wtoken;
    }    
    
    struct User{
        uint totalDeposit;  //USD VALUE OF TOTAL DEPOSIT AT DEPOSIT TIME
        uint totalBorrowed; //USD VALUE OF TOTAL DEPOSIT AT BORROW TIME
        freeStorage [] myDeposits; //DEPOSIT DATA
        freeStorage [] myBorrows; //BORROW DATA
        mapping(string => uint) deposits; //CURRENCY-WISE TOTAL DEPOSIT COUNT FULL VALUE 
        mapping(string => uint) borrows; //CURRENCY-WISE TOTAL BORROW COUNT FULL VALUE
        uint64 [] borrowedOrders; //BORROWED ORDER - ORDER ID
        uint64 [] createdOrders; //CREATED ORDER - ORDER ID
        uint64 [] myOrders; //MATCHED ORDR - ORDER ID
    }
    
    function initializeAddress(address payable EMMaddress,address AbacusAddress, address payable Initaddress) external initializer{
            EMM = EcoMoneyManager(EMMaddress);
            abacus = IAbacusOracle(AbacusAddress); 
            Init = EcoceliumInit(Initaddress);
    }

    /*============Main Functions===============
    Key Notes - 
    1) Always call main functions of Data Manager with Wrapped Token
    2) _status signifies (status == Status.OPENCREATOR) operation - Returns True for Deposit Functions and False for Borrow Function
    3) require(Init.friendlyaddress(msg.sender) ,"Not Friendly Address"); - This is mentioned in the EcoceliumInit Contract
    4) FreePusher/Popper are for Liquidity Pools and push/pop order and matchOrder is the Order Matching Engine
    5) Fetch Token Price Returns Values in 10**8
    6) Amounts are with setting off Token Decimals
    ---------------------------------*/
    
    function freePusher(address userAddress, string memory token, uint _amount, bool _status) external {  //_status signifies (status == Status.OPENCREATOR) operation
        require(Init.friendlyaddress(msg.sender) ,"Not Friendly Address");
        uint _usdValue = USDValue(_amount, token);
        freeStorage memory newStorage = freeStorage({  amount: _amount,
                                                    time: now,
                                                    wtoken: token,
                                                    usdvalue: _usdValue   });
        if(_status){
            users[userAddress].myDeposits.push(newStorage);
            users[userAddress].totalDeposit += _usdValue;
            users[userAddress].deposits[token] += _amount;
        }   else {
            users[userAddress].myBorrows.push(newStorage);
            users[userAddress].totalBorrowed += _usdValue;
            users[userAddress].borrows[token] += _amount;
        }
    }
    
    function freePopper(address userAddress, string memory _tokenSymbol, uint _amount, bool _status) public returns (uint dues) {
        require(Init.friendlyaddress(msg.sender),"Not Friendly Address");
        if(_status) { 
            require(users[userAddress].deposits[_tokenSymbol]>_amount, "Insufficient Deposits");
            users[userAddress].deposits[_tokenSymbol] -= _amount;
            users[userAddress].totalDeposit -= USDValue(_amount, _tokenSymbol); 
        } else {
            require(users[userAddress].borrows[_tokenSymbol]>_amount,"Insufficient Borrowings");
            users[userAddress].borrows[_tokenSymbol] -= _amount;
            users[userAddress].totalBorrowed -= USDValue(_amount, _tokenSymbol);
        }
        uint amountLeft= _amount;
        freeStorage [] storage mystorage = _status ?  users[userAddress].myDeposits : users[userAddress].myBorrows;
        for( uint i= mystorage.length-1; amountLeft >0 ; i--){
            if(keccak256(abi.encodePacked(mystorage[i].wtoken)) != keccak256(abi.encodePacked(_tokenSymbol))) { continue; }
            if (mystorage[i].amount <= amountLeft){
                amountLeft -= mystorage[i].amount;
                dues+= calculateECOEarning(USDValue(mystorage[i].amount,_tokenSymbol), _tokenSymbol, mystorage[i].time);
                mystorage.pop(); 
            } else {
                mystorage[i].amount -= amountLeft;
                dues += calculateECOEarning(USDValue(amountLeft,_tokenSymbol), _tokenSymbol, mystorage[i].time);
                amountLeft = 0;
            }
        } 
        _status ? users[userAddress].myDeposits = mystorage :   users[userAddress].myBorrows = mystorage;
        Init.setOwnerFeeVault(_tokenSymbol, (dues*Init.rewardFee()/100));
    }
    
    function pushOrder(address userAddress,string memory _tokenSymbol ,uint _amount,uint _duration, uint _yield, bool _status) internal returns (uint){
        (uint64 _orderId,uint newAmount,uint fee) = _ordersub(_amount,userAddress,_duration,_tokenSymbol);
        openOrderMap[_orderId] = Order({       
                                            creator : userAddress,
                                            duration : _duration,
                                            amount : newAmount,
                                            yield : _yield,
                                            wtoken : _tokenSymbol
                                 });
        if(_status) {
            orderStatus[_orderId] = Status.OPENCREATOR;
            users[userAddress].createdOrders.push(_orderId);
        } else  {
            orderStatus[_orderId] = Status.OPENBORROW;
            users[userAddress].borrowedOrders.push(_orderId);  }
        poolSorter(_orderId, _tokenSymbol, true);
        return fee;
    }
    
    function poolSorter(uint64 _orderId, string memory _tokenSymbol, bool _status) internal {        //Status here signifies Insertion if True, and Deletion if false
        uint64 [] memory temp;
        bool task;
        poolindex[_tokenSymbol]=0;
        for((uint i, uint j)=(0,0);i<orderpool[_tokenSymbol].length;(i++,j++)) {
            temp[j]=orderpool[_tokenSymbol][i];
            if(!task && _status && openOrderMap[temp[j]].yield > openOrderMap[_orderId].yield) {    //Insertion Case
                    temp[j]=_orderId; temp[++j]=orderpool[_tokenSymbol][i]; task = true;
            }else if(!task && !_status && _orderId == temp[j]){     //Deletion Case
                temp[j]=orderpool[_tokenSymbol][++i]; task = true;
            }
            if(orderStatus[orderpool[_tokenSymbol][i-1]]==Status.OPENBORROW && orderStatus[orderpool[_tokenSymbol][i]]==Status.OPENCREATOR) {       //Assigns updatePoolIndex
                poolindex[_tokenSymbol] = i;
                break;
            }
        }
        orderpool[_tokenSymbol] = temp;
    }
    
    function matchOrder(address userAddress, string memory _tokenSymbol ,uint _amount,uint _duration,uint _yield, uint64 _orderId, bool _status) internal    {
        matchOrderMap[_orderId] = matchedOrder({       
                                            supplier : (orderStatus[_orderId] == Status.OPENBORROW) ? userAddress : openOrderMap[_orderId].creator,
                                            borrower : (orderStatus[_orderId] == Status.OPENCREATOR) ? userAddress : openOrderMap[_orderId].creator,
                                            time    : now,
                                            expiryDate : now + _duration*(30 days),
                                            duration : _duration,
                                            amount : _amount,
                                            usdvalue : USDValue(_amount,_tokenSymbol),
                                            yield : _yield,
                                            wtoken : _tokenSymbol,
                                            duesPaid : 0
                                            });
        _status ? delete users[openOrderMap[_orderId].creator].borrowedOrders[_orderId] : delete users[userAddress].createdOrders[_orderId];
        delete openOrderMap[_orderId];
        orderStatus[_orderId]=Status.MATCHED;
        users[matchOrderMap[_orderId].supplier].myOrders.push(_orderId);
        users[matchOrderMap[_orderId].borrower].myOrders.push(_orderId);
        scheduleExpiry(_orderId);
        scheduleCheck(_orderId,matchOrderMap[_orderId].borrower,1);
        EMM.mintWrappedToken(matchOrderMap[_orderId].borrower, _amount, _tokenSymbol);
        Init.emitOrderCreated(userAddress,_duration,_yield,_amount,_tokenSymbol); 
    }
    
    function newOrder(address userAddress,string memory _tokenSymbol ,uint _amount,uint _duration, uint _yield, bool _status) external {
        require(Init.friendlyaddress(msg.sender),"Not Friendly Address");
        uint amountLeft= _amount;
        uint index;
        if(_status){
           index = poolindex[_tokenSymbol]-1;
           users[userAddress].deposits[_tokenSymbol] +=_amount;
           users[userAddress].totalDeposit += USDValue(_amount, _tokenSymbol);
        }   else {
           index = poolindex[_tokenSymbol];
            users[userAddress].borrows[_tokenSymbol] +=_amount;
           users[userAddress].totalBorrowed += USDValue(_amount, _tokenSymbol);
        }
        while(amountLeft>0){
            if(poolindex[_tokenSymbol] == 0) { pushOrder(userAddress, _tokenSymbol, _amount, _duration, _yield, _status);  break; }
            Order memory iOrder = openOrderMap[orderpool[_tokenSymbol][index]];
            if((_status && _yield>iOrder.yield) || (!_status && _yield<iOrder.yield) || (_status)?(orderStatus[orderpool[_tokenSymbol][index]] == Status.OPENCREATOR):(orderStatus[orderpool[_tokenSymbol][index]] == Status.OPENBORROW)){
                pushOrder(userAddress, _tokenSymbol, _amount, _duration, _yield, _status);
                break;
            } else   {
                uint tduration = _duration > iOrder.duration ? iOrder.duration : _duration;
                uint tyield = _yield > iOrder.yield ? iOrder.yield : _yield;
                uint64 tID = orderpool[_tokenSymbol][index];
                if(iOrder.amount>=amountLeft) { 
                    if(iOrder.amount != amountLeft) {
                        pushOrder(iOrder.creator, _tokenSymbol, iOrder.amount-amountLeft, iOrder.duration, iOrder.yield, !_status);     }
                    matchOrder(userAddress, _tokenSymbol, amountLeft, tduration, tyield, tID, _status);
                    amountLeft=0;
                } else {
                    pushOrder(userAddress, _tokenSymbol, amountLeft- iOrder.amount, _duration, _yield, _status);
                    matchOrder(userAddress, _tokenSymbol, amountLeft, tduration, tyield, tID , _status);
                    amountLeft -= openOrderMap[orderpool[_tokenSymbol][index]].amount;    }
            }
        }
    }
    
    function orderExpired  (uint64 _orderId) external {
        require(Init.friendlyaddress(msg.sender),"Not Friendly Address");
        require (matchOrderMap[_orderId].expiryDate <= now);
        EMM.releaseWrappedToken(matchOrderMap[_orderId].supplier,matchOrderMap[_orderId].amount, matchOrderMap[_orderId].wtoken);    
        users[matchOrderMap[_orderId].supplier].totalDeposit -= matchOrderMap[_orderId].usdvalue;
        users[matchOrderMap[_orderId].borrower].totalBorrowed -= matchOrderMap[_orderId].usdvalue;
        orderStatus[_orderId] = Status.CLOSED;
        delete matchOrderMap[_orderId];
        delete users[matchOrderMap[_orderId].supplier].myOrders[_orderId];
        delete users[matchOrderMap[_orderId].borrower].myOrders[_orderId];
        //Init.OrderExpired(_orderId,msgSender,orderMonthlyDue(_orderId,msgSender,_duration));
    } 

    function payDue(uint64 _orderId,uint _duration,address msgSender) external returns (uint due){
        due = orderMonthlyDue(_orderId,_duration);
        uint fee = (due*Init.rewardFee())/100;
        EMM.burnECOFrom(msgSender,due+fee);
        Init.setOwnerFeeVault(Init.WRAP_ECO_SYMBOL(), fee);
        matchOrderMap[_orderId].duesPaid += 1;
        matchOrderMap[_orderId].duesPaid >= matchOrderMap[_orderId].duration  ? Init.setUserLocked(msgSender,false) :  Init.setUserLocked(msgSender,true);
        Init.emitDuePaid(_orderId,msgSender,orderMonthlyDue(_orderId,_duration));
    }

    function dueCheck(uint64 _orderId,address borrower,uint month) external returns(uint) {
        require (Init.friendlyaddress(msg.sender) && now >= matchOrderMap[_orderId].time + matchOrderMap[_orderId].duesPaid * 30 days);
        if(matchOrderMap[_orderId].duesPaid < month && !Init.isRegistrar(borrower) && !Init.isUserLocked(borrower)){
            uint due = orderMonthlyDue(_orderId,1);
            matchOrderMap[_orderId].duesPaid >= matchOrderMap[_orderId].duration  ? Init.setUserLocked(borrower,false) :  Init.setUserLocked(borrower,true);
            EMM.mintECO(matchOrderMap[_orderId].supplier,due*(100-Init.rewardFee())/100);
            Init.emitDuePaid(_orderId,borrower,orderMonthlyDue(_orderId,1));
        }
        if(matchOrderMap[_orderId].duesPaid >= matchOrderMap[_orderId].duration){
            scheduleCheck(_orderId,borrower,1);
        }
    }

    function scheduleExpiry(uint64 _orderId) internal{
        uint time = matchOrderMap[_orderId].expiryDate - matchOrderMap[_orderId].time;
        bytes memory data = abi.encodeWithSelector(bytes4(keccak256('orderExpired(uint256)')),_orderId);
        uint callCost = 300000*1e9 + abacus.callFee();
        abacus.scheduleFunc{value:callCost}(address(this), time ,data , abacus.callFee() ,300000 , 1e9 );
    }    
    
    function scheduleCheck(uint _orderId,address borrower,uint month) internal{
        bytes memory data = abi.encodeWithSelector(bytes4(keccak256('dueCheck(uint256,address,uint256)')),_orderId,borrower,month);
        uint callCost = 300000*1e9 + abacus.callFee();
        abacus.scheduleFunc{value:callCost}(address(this), 30 days ,data , abacus.callFee() ,300000 , 1e9 );
    } 
    
    function cancelOrder(uint64 _orderId) external{
        require(Init.friendlyaddress(msg.sender));
        if(orderStatus[_orderId]==Status.OPENCREATOR) {
            EMM.releaseWrappedToken(openOrderMap[_orderId].creator,openOrderMap[_orderId].amount, openOrderMap[_orderId].wtoken);
            delete users[openOrderMap[_orderId].creator].borrowedOrders[_orderId];  
        }   else {
            delete users[openOrderMap[_orderId].creator].createdOrders[_orderId];   
        }
        poolSorter(_orderId, openOrderMap[_orderId].wtoken,false);
        delete openOrderMap[_orderId];
        orderStatus[_orderId] = Status.CLOSED;
    }
    
     /*==============Helpers============
    ---------------------------------*/   
    
    function USDValue(uint amount, string memory _token) public view returns (uint usdvalue) {
        usdvalue = amount*fetchTokenPrice(_token)/(10**8)/wERC20(EMM.getwTokenAddress(_token)).decimals();
    }
    
    function orderMonthlyDue(uint64 _orderId, uint _duration) public view returns(uint due){
        orderStatus[_orderId] == Status.MATCHED ?  due = USDValue (matchOrderMap[_orderId].amount, matchOrderMap[_orderId].wtoken) * matchOrderMap[_orderId].yield * _duration*30 days*fetchTokenPrice(Init.WRAP_ECO_SYMBOL())/ 3155695200/(10**8) : due = 0;
    }
    
    function fetchTokenPrice(string memory _tokenSymbol) public view returns(uint64){ //Put any Token Wrapped or Direct
            return abacus.getJobResponse(EMM.getFetchId(_tokenSymbol))[0];
    }
    
    /*function issueReward(address userAddress, string memory _tokenSymbol, uint time, uint tokenUsdValue) internal {
        uint reward = calculateECOEarning(tokenUsdValue, _tokenSymbol, time);
        EMM.mintECO(userAddress, reward);
    }*/
    
    function calculateECOEarning(uint usdvalue, string memory _tokenSymbol, uint time) private view returns (uint){
        uint _amount = usdvalue*fetchTokenPrice(Init.WRAP_ECO_SYMBOL())/(10**8);
        uint reward = (_amount * Init.slabRateDeposit(_tokenSymbol) * (now - time))/3155695200; //decimal from Abacus is setoff by decimal from Eco
        return reward;
    }
    
    function getECOEarnings(address userAddress) public view returns (uint){
        uint ecobalance;
        for(uint i=0; i<users[userAddress].myDeposits.length || i<users[userAddress].myBorrows.length; i++) {
            ecobalance += calculateECOEarning(users[userAddress].myDeposits[i].usdvalue, users[userAddress].myDeposits[i].wtoken, users[userAddress].myDeposits[i].time);
            ecobalance -= calculateECOEarning(users[userAddress].myBorrows[i].usdvalue, users[userAddress].myBorrows[i].wtoken, users[userAddress].myBorrows[i].time);
        }
        return ecobalance - EMM.ecoWithdrawls(userAddress);
    }
    
    function _ordersub(uint amount,address userAddress,uint _duration,string memory _tokenSymbol) internal view returns (uint64, uint, uint){
        uint newAmount = amount - (amount*Init.tradeFee())/100;
        uint fee = (amount*Init.tradeFee())/100;
        uint64 _orderId = uint64(uint(keccak256(abi.encodePacked(userAddress,_tokenSymbol,_duration,now))));
        return (_orderId,newAmount,fee);
    }
    
    function getUserDepositsbyToken(address userAddress, string memory wtoken) public view returns(uint) {
        return users[userAddress].deposits[wtoken];
    }
    
    function getUserBorrowedOrderbyToken(address userAddress, string memory wtoken) public view returns(uint) {
        return users[userAddress].borrows[wtoken];
    }
    
    function getUserBorrowedOrder(address userAddress) public view returns (uint64 [] memory) {
        return users[userAddress].borrowedOrders;
    }
    
    function getUserDepositOrder(address userAddress) public view returns (uint64 [] memory) {
        return users[userAddress].createdOrders;
    }
    
    function getUserMatchOrder(address userAddress) public view returns (uint64 [] memory) {
        return users[userAddress].myOrders;
    }
    
    function getbuyPower(address userAddress) public view returns (uint){
        if(!Init.isRegistrar(userAddress)) { return (10**30);   }
        if(Init.isUserLocked(userAddress)) { return 0; }
        uint buyPower;
        buyPower += users[userAddress].totalDeposit - ((users[userAddress].totalDeposit*Init.CDSpercent())/100);
        buyPower -= users[userAddress].totalBorrowed;
        return buyPower;
    }
    
    function getOrderIds(string memory wtoken) public view returns (uint64 [] memory orderIds) {
        return orderpool[wtoken];
    }
}

contract Ecocelium is Initializable{

    address public owner;
    address payable EMMAddress;
    IAbacusOracle abacus;
    EcoMoneyManager EMM;
    EcoceliumDataManager EDM;
    EcoceliumInit Init;
    
    function initialize(address _owner,address payable EMMaddress,address payable AbacusAddress,address EDMaddress, address payable Initaddress)public payable initializer {
        owner = _owner;
        EMM = EcoMoneyManager(EMMaddress);
        EMMAddress = EMMaddress;
        abacus = IAbacusOracle(AbacusAddress);//0x323f81D9F57d2c3d5555b14d90651aCDc03F9d52
        EDM = EcoceliumDataManager(EDMaddress);
        Init = EcoceliumInit(Initaddress);
    }
    
    function changeOwner(address _owner) public{
        require(msg.sender==owner);
        owner = _owner;
    }
    
    function updateContracts() public{
        require(msg.sender==owner);
        EMM = EcoMoneyManager(Init.MONEYMANAGER());
        abacus = IAbacusOracle(Init.ABACUS());
        EDM = EcoceliumDataManager(Init.DATAMANAGER());
    }
    
     /*===========Main functions============
    -------------------------------------*/   

    function Deposit(string memory rtoken, uint _amount) external payable {
        address _msgSender = msg.sender;
        string memory wtoken = EMM.getWrapped(rtoken);
        _deposit(rtoken, _amount, _msgSender, wtoken);
        EDM.freePusher(_msgSender, wtoken, _amount, true);
        EMM.mintWrappedToken(_msgSender, _amount, wtoken);
        EMM.lockWrappedToken(_msgSender, _amount,wtoken);
    }
    
    function _deposit(string memory rtoken,uint _amount, address msgSender, string memory wtoken) internal {
        require(EMM.getwTokenAddress(wtoken) != address(0),"not supported");
        if(keccak256(abi.encodePacked(rtoken)) == keccak256(abi.encodePacked(Init.ETH_SYMBOL()))) { 
            require(msg.value >= _amount);
            EMM.DepositManager{value:msg.value}(rtoken, _amount, msgSender);
        }else {
        EMM.DepositManager(rtoken, _amount, msgSender); }
        Init.emitSwap(msgSender,rtoken,wtoken,_amount);
    }
    
    function depositAndOrder(address userAddress,string memory rtoken ,uint _amount,uint _duration,uint _yield) external payable {
        require(msg.sender == userAddress);
        _deposit(rtoken, _amount, userAddress, EMM.getWrapped(rtoken));
        EDM.newOrder(userAddress, EMM.getWrapped(rtoken), _amount, _duration, _yield, true);
    }
    
    function createOrder(address userAddress,string memory _tokenSymbol ,uint _amount,uint _duration,uint _yield) external payable {
        require(msg.sender == userAddress);
        string memory wtoken = EMM.getWrapped(_tokenSymbol);
        require(EDM.getUserDepositsbyToken(userAddress, wtoken) >= _amount, "Insufficient Balance"); 
        uint ecoEarnings = EDM.freePopper(userAddress, wtoken , _amount, true);
        EMM.mintECO(userAddress,ecoEarnings);
        EDM.newOrder(userAddress, wtoken, _amount, _duration, _yield, true); 
    }
    
    function getAggEcoBalance(address userAddress) public view returns(uint) {
        return wERC20(EMM.getwTokenAddress(Init.WRAP_ECO_SYMBOL())).balanceOf(userAddress) + EDM.getECOEarnings(userAddress);
    }
    
    function borrowOrder(address userAddress, string memory rtoken, uint amount, uint duration, uint yield) public {//Rewrite this part
        require(isWithdrawEligible(userAddress, rtoken, amount));
        EDM.newOrder(msg.sender,rtoken, amount,duration,yield,false);
    }
    
    function payDueOrder(uint64 _orderId,uint _duration) external {
        EDM.payDue(_orderId,_duration,msg.sender);
    }
    
    function clearBorrow(string memory rtoken, uint _amount) external payable{
        address msgSender = msg.sender;
        string memory wtoken = EMM.getWrapped(rtoken);
        uint dues = EDM.freePopper(msgSender, wtoken, _amount, false);
        if(keccak256(abi.encodePacked(rtoken)) == keccak256(abi.encodePacked(Init.ETH_SYMBOL()))) { 
            require(msg.value == _amount);
            EMM.DepositManager{value:_amount}(rtoken, _amount, msgSender);
        }else {
        EMM.DepositManager(rtoken, dues, msgSender);    }
    }
    
    function Borrow(address payable userAddress, uint _amount, string memory _tokenSymbol) public {
        require(userAddress == msg.sender);
        require(isWithdrawEligible(userAddress, _tokenSymbol, _amount));
        EDM.freePusher(msg.sender, EMM.getWrapped(_tokenSymbol), _amount,false);
        EMM.WithdrawManager(_tokenSymbol, _amount, userAddress);
    }
    
    function SwapWrapToWrap(string memory token1,string memory token2, uint token1amount)  external returns(uint) {
        address msgSender = msg.sender;
        (uint token1price,uint token2price) = (fetchTokenPrice(token1),fetchTokenPrice(token2));
        uint token2amount = EDM.USDValue(token1amount,token1)*(100-Init.swapFee())*(10**uint(wERC20(EMM.getwTokenAddress(token2)).decimals()))*(10**8)/token2price/100;
        EMM.w2wswap(msgSender, token1, token1amount, token2amount, token2);
        EDM.freePopper(msgSender,token1,token1amount,true);
        Init.setOwnerFeeVault(token1, token1price*Init.swapFee()/100);
        EDM.freePusher(msgSender, token2,token2amount,true);
        Init.emitSwap(msgSender,token1,token2,token2amount);
        return token2amount;
    }
    
    function cancelOrder(uint64 _orderId) public{
        (address creator,,,,) = EDM.openOrderMap(_orderId);
        require(msg.sender==creator);
        EDM.cancelOrder(_orderId);
    }
    
    receive() external payable {  }

    /*==============Helpers============
    ---------------------------------*/    
    
    function orderMonthlyDue(uint64 _orderId,uint _duration) public view returns(uint){
        return EDM.orderMonthlyDue(_orderId,_duration);
    }
    
    function updateFees(uint _swapFee,uint _tradeFee,uint _rewardFee) public{
        require(msg.sender == owner);
        Init.updateFees(_swapFee,_tradeFee,_rewardFee);
    }
    
    function getOrderIds(string memory wtoken) public view returns(uint64 [] memory){
        return EDM.getOrderIds(wtoken);
    }
    
    function fetchTokenPrice(string memory _tokenSymbol) public view returns(uint64){
        return EDM.fetchTokenPrice(_tokenSymbol);
    }
    
    function Withdraw(string memory to, uint _amount) external payable{
        address payable msgSender = msg.sender;
        string memory from = EMM.getWrapped(to);
        require(EMM.getwTokenAddress(from) != address(0),"not supported");
        require(!Init.isUserLocked(msgSender), "Your Address is Locked Pay Dues");
        require(isWithdrawEligible(msgSender, to, _amount) , "Not Eligible for Withdraw");
        wERC20 wToken = wERC20(EMM.getwTokenAddress(to));
        uint amountLeft;
        uint availableBalance = wToken.balanceOf(msgSender) - EDM.getUserDepositsbyToken(msgSender, from) - EDM.getUserBorrowedOrderbyToken(msgSender, from);
        if(keccak256(abi.encodePacked(to)) == keccak256(abi.encodePacked(Init.ECO()))) {
            require( wToken.balanceOf(msgSender) + EDM.getECOEarnings(msgSender) >= _amount,"Insufficient Balance");
            if(availableBalance >= _amount) {
                EMM.WithdrawManager(to,_amount, msgSender);
            } else {
                if(wToken.balanceOf(msgSender) >=_amount)   { 
                _withdraw(msgSender, from, _amount, to);        }  else {
                amountLeft =  _amount - wToken.balanceOf(msgSender);
                _withdraw(msgSender, from, wToken.balanceOf(msgSender), to);
                EMM.redeemEcoEarning(msgSender,amountLeft); }
            }
        }
        else  {  require(wToken.balanceOf(msgSender)>=_amount,"Insufficient balance");
                _withdraw(msgSender, from, wToken.balanceOf(msgSender), to);
        }
        Init.emitSwap(msgSender,from,to,_amount);
    }
    
    function _withdraw(address payable msgSender, string memory from, uint amount, string memory to) internal {
        EMM.releaseWrappedToken(msgSender,amount, from);
        EMM.burnWrappedFrom(msgSender, amount, from);
        Init.setOwnerFeeVault(to,(amount*Init.swapFee())/100);
        EDM.freePopper(msgSender,from,amount, true);
        uint newAmount = amount - (amount*Init.swapFee())/100;
        EMM.WithdrawManager(to,newAmount, msgSender);
    }
    
    function isWithdrawEligible(address userAddress, string memory to, uint amount) internal view returns (bool Eligible){
        return (EDM.getbuyPower(userAddress)*(Init.CDSpercent())/100) > (amount*fetchTokenPrice(to)/(10**8));
    }    
}

    