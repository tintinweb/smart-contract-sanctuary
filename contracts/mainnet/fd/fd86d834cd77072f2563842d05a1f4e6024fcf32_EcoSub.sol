// SPDX-License-Identifier: MIT
/*SPDX-License-Identifier: MIT


███████╗░█████╗░░█████╗░░█████╗░███████╗██╗░░░░░██╗██╗░░░██╗███╗░░░███╗
██╔════╝██╔══██╗██╔══██╗██╔══██╗██╔════╝██║░░░░░██║██║░░░██║████╗░████║
█████╗░░██║░░╚═╝██║░░██║██║░░╚═╝█████╗░░██║░░░░░██║██║░░░██║██╔████╔██║
██╔══╝░░██║░░██╗██║░░██║██║░░██╗██╔══╝░░██║░░░░░██║██║░░░██║██║╚██╔╝██║
███████╗╚█████╔╝╚█████╔╝╚█████╔╝███████╗███████╗██║╚██████╔╝██║░╚═╝░██║
╚══════╝░╚════╝░░╚════╝░░╚════╝░╚══════╝╚══════╝╚═╝░╚═════╝░╚═╝░░░░░╚═╝

Brought to you by Kryptual Team */
pragma solidity ^0.6.0;
import "./EcoSub2.sol";


contract EcoceliumSub is Initializable { 

    IAbacusOracle abacus;
    EcoceliumTokenManager ETM;
    EcoceliumSub1 ES1;
    enum Status {OPEN,CLOSED}
    /*============Mappings=============
    ----------------------------------*/
    mapping (address => User) public users;
    uint [] public orderIds;
    mapping (string => uint) public YieldForTokens;
    mapping (uint64 => Order) public Orders;
    mapping (string => uint ) public borrowCollection;
    
    /*=========Structs================
    --------------------------------*/    
    
    struct Order{
        address creator;
        address [] borrowers;
        uint time;
        uint expiryDate;
        uint duration;
        uint amount;
        uint amountLeft;
        uint yield;
        uint earnings;
        mapping (address => BorrowatOrder) borrows;
        string token;
        Status status;
    }
    
    struct BorrowatOrder{
        uint64 orderId;
        uint amount;
        uint duration;
        uint dated;
        uint duesPaid;
    }
    
    struct freeStorage{
        uint amount;
        uint time;
        string wtoken;
        uint usdvalue;
    }
    
    struct User{
        uint ecoWithdrawls;
        uint totalDeposit;
        uint totalBorrowed;
        freeStorage [] myDeposits;
        freeStorage [] myBorrows;
        mapping(string => uint) deposits;
        mapping(string => uint) borrows;
        uint64 [] borrowedOrders;
        uint64 [] createdOrders;
        mapping(string => uint) tokenYield;
    }
    
    function initializeAddress(address ETMaddress,address AbacusAddress, address ES1address) external {
            ETM = EcoceliumTokenManager(ETMaddress);
            abacus = IAbacusOracle(AbacusAddress); 
            ES1 = EcoceliumSub1(ES1address);
    }


    /*============Main Functions===============
    ---------------------------------*/
   
    function zeroDepositorPush(address userAddress, string memory _tokenSymbol, uint _amount) external {
        if(ES1.friendlyaddress(msg.sender)){
            uint tokenUsdValue = _amount*fetchTokenPrice(_tokenSymbol)/(10**8);
            users[userAddress].totalDeposit += tokenUsdValue;
            freeStorage memory newDeposit = freeStorage({     amount: _amount,
                                                        time: now,
                                                        wtoken: _tokenSymbol,
                                                        usdvalue: tokenUsdValue   });
            users[userAddress].myDeposits.push(newDeposit);
            users[userAddress].deposits[_tokenSymbol] += _amount;
        }
    }
    
    /*function getUsersOrders(address userAddress) public view returns(uint64 [] memory){
        return users[userAddress].createdOrders;
    }*/
    
    function getUserDepositsbyToken(address userAddress, string memory wtoken) public view returns(uint) {
        return users[userAddress].deposits[wtoken];
    }
    
    function getbuyPower(address userAddress) public view returns (uint){
        uint buyPower;
        if(!ES1.isRegistrar(userAddress)) {
            if(ES1.isUserLocked(userAddress)) { return 0; }
            buyPower += users[userAddress].totalDeposit - ((users[userAddress].totalDeposit*ES1.CDSpercent())/100);
            buyPower -= users[userAddress].totalBorrowed;
        } else {    buyPower = (10**20);        }
        return buyPower;
    }

    function createOrder(address userAddress,string memory _tokenSymbol ,uint _amount,uint _duration,uint _yield,address _contractAddress) external{
        //_order(userAddress,_tokenSymbol,_amount,_duration,_yield,_contractAddress);
        if(ES1.friendlyaddress(msg.sender)){
        wERC20 token = wERC20(ETM.getwTokenAddress(_tokenSymbol));
        // uint amount = _amount*(10**uint(token.decimals()));
        require(token.availableAmount(userAddress)>= (_amount*(10**uint(token.decimals()))),"insufficient balance");
        (uint64 _orderId,uint newAmount,uint fee) = _ordersub(_amount*(10**uint(token.decimals())),userAddress,_duration,_tokenSymbol);
        address [] memory _borrowers;
        Orders[_orderId] = Order({       
                                            creator : userAddress,
                                            borrowers : _borrowers,
                                            time : now,
                                            duration : _duration,
                                            amount : newAmount,
                                            amountLeft : newAmount,    
                                            token : _tokenSymbol,
                                            yield : _yield,
                                            earnings : 0,
                                            status : Status.OPEN,
                                            expiryDate : now + _duration*(30 days)
        });
        token.burnFrom(userAddress,fee);
        token.lock(userAddress,newAmount);
        ES1.setOwnerFeeVault(_tokenSymbol, fee);
        orderIds.push(_orderId);
        users[userAddress].totalDeposit += _amount*fetchTokenPrice(_tokenSymbol)/(10**8);
        users[userAddress].createdOrders.push(_orderId);
        scheduleExpiry(_orderId, _contractAddress);
        ES1.emitOrderCreated(userAddress,_duration,_yield,newAmount,_tokenSymbol); 
        }
    }

    function _ordersub(uint amount,address userAddress,uint _duration,string memory _tokenSymbol) internal view returns (uint64, uint, uint){
        uint newAmount = amount - (amount*ES1.tradeFee())/100;
        uint fee = (amount*ES1.tradeFee())/100;
        uint64 _orderId = uint64(uint(keccak256(abi.encodePacked(userAddress,_tokenSymbol,_duration,now))));
        return (_orderId,newAmount,fee);
    }
    
    /*function getTokenByOrderID(uint64 _orderId) public view returns (uint, string memory) {
        return (Orders[_orderId].earnings,Orders[_orderId].token);
    }*/
    
    function borrow(uint64 _orderId,uint _amount,uint _duration,address msgSender,address _contractAddress) external {
        if((ES1.friendlyaddress(msg.sender)) && Orders[_orderId].creator != address(0)) {
            if((Orders[_orderId].expiryDate -  now > _duration*(30 days) && _duration>0 && _duration%1 == 0 && Orders[_orderId].status == Status.OPEN)){
                uint usdValue = _amount*fetchTokenPrice(Orders[_orderId].token)/(10**8);
                if((getbuyPower(msgSender) >= usdValue && Orders[_orderId].amountLeft >= _amount)){
                    wERC20 token = wERC20(ETM.getwTokenAddress(Orders[_orderId].token));
                    uint amount = _amount*(10**uint(token.decimals()));
                    token.release(Orders[_orderId].creator,amount);
                    token.burnFrom(Orders[_orderId].creator,amount);
                    token.mint(msgSender,_amount);
                    Orders[_orderId].amountLeft -=  _amount;
                    users[msgSender].borrowedOrders.push(_orderId);
                    users[msgSender].totalBorrowed += usdValue;
                    Orders[_orderId].borrowers.push(msgSender);
                    Orders[_orderId].borrows[msgSender] =  BorrowatOrder({
                                                                orderId : _orderId,
                                                                amount : _amount,
                                                                duration : _duration,
                                                                dated : now,
                                                                duesPaid : 0
                                                            }); 
                    scheduleCheck(_orderId,msgSender,1,_contractAddress);
                    if(Orders[_orderId].amountLeft == 0){
                        Orders[_orderId].status = Status.CLOSED;    }       
                    ES1.emitBorrowed(_orderId,msgSender,_amount,_duration);
                }
            }
        }
    }
    
    function payDue(uint64 _orderId,uint _duration,address msgSender) public{
        if((ES1.friendlyaddress(msg.sender) && (Orders[_orderId].borrows[msgSender].duesPaid <= Orders[_orderId].borrows[msgSender].duration ))){
        wERC20 ecoToken = wERC20(ETM.getwTokenAddress(ES1.WRAP_ECO_SYMBOL()));
        uint due = orderMonthlyDue(_orderId,msgSender,_duration)*(10**uint(ecoToken.decimals()));
        uint fee = (due*ES1.rewardFee())/100;
        ecoToken.burnFrom(msgSender,due);
        ES1.setOwnerFeeVault(ES1.WRAP_ECO_SYMBOL(), fee);
        ecoToken.mint(Orders[_orderId].creator,due-fee);
        users[Orders[_orderId].creator].tokenYield[Orders[_orderId].token] += due - fee;
        Orders[_orderId].borrows[msgSender].duesPaid += 1;
        Orders[_orderId].earnings += due - fee;
        YieldForTokens[Orders[_orderId].token] += due;
        if(Orders[_orderId].borrows[msgSender].duesPaid == Orders[_orderId].borrows[msgSender].duration) {
            ES1.setUserLocked(msgSender,false);
        }
        ES1.emitDuePaid(_orderId,msgSender,orderMonthlyDue(_orderId,msgSender,_duration));
        }
    }
    
    function orderExpired(uint64 _orderId) external {
        if(ES1.friendlyaddress(msg.sender) && (Orders[_orderId].expiryDate <= now)){
            wERC20(ETM.getwTokenAddress(Orders[_orderId].token)).release(Orders[_orderId].creator,Orders[_orderId].amountLeft);
            users[Orders[_orderId].creator].totalDeposit -= Orders[_orderId].amount*fetchTokenPrice(Orders[_orderId].token)/(10**8);
            Orders[_orderId].status = Status.CLOSED;
        }
    }    

    function scheduleExpiry(uint64 _orderId,address _contractAddress) internal{
        uint time = Orders[_orderId].expiryDate - Orders[_orderId].time;
        bytes memory data = abi.encodeWithSelector(bytes4(keccak256('orderExpired(uint256)')),_orderId);
        uint callCost = 300000*1e9 + abacus.callFee();
        abacus.scheduleFunc{value:callCost}(_contractAddress, time ,data , abacus.callFee() ,300000 , 1e9 );
    }    
    
    function scheduleCheck(uint _orderId,address borrower,uint month,address _contractAddress) internal{
        bytes memory data = abi.encodeWithSelector(bytes4(keccak256('dueCheck(uint256,address,uint256)')),_orderId,borrower,month, _contractAddress);
        uint callCost = 300000*1e9 + abacus.callFee();
        abacus.scheduleFunc{value:callCost}(_contractAddress, 30 days ,data , abacus.callFee() ,300000 , 1e9 );
    } 
    
    function cancelOrder(uint64 _orderId) external{
        if(ES1.friendlyaddress(msg.sender) && Orders[_orderId].amount == Orders[_orderId].amountLeft){
            wERC20(ETM.getwTokenAddress(Orders[_orderId].token)).release(Orders[_orderId].creator,Orders[_orderId].amountLeft);
            Orders[_orderId].status = Status.CLOSED;
        }
    }
    
    function dueCheck(uint64 _orderId,address borrower,uint month, address _contractAddress) public {
        if(ES1.friendlyaddress(msg.sender) && (now >= Orders[_orderId].time * Orders[_orderId].borrows[borrower].duesPaid + 30 days)){
            if(Orders[_orderId].borrows[borrower].duesPaid < month && !ES1.isRegistrar(borrower) && !ES1.isUserLocked(borrower)){
                wERC20 ecoToken = wERC20(ETM.getwTokenAddress(ES1.WRAP_ECO_SYMBOL()));
                uint due = orderMonthlyDue(_orderId,borrower,1)*(10**uint(ecoToken.decimals()));
                uint fee = (due*ES1.rewardFee())/100;
                ES1.setUserLocked(borrower, true);
                ecoToken.mint(Orders[_orderId].creator,due-fee);
                ES1.setOwnerFeeVault(Orders[_orderId].token, fee);
                ecoToken.mint(Orders[_orderId].creator,due-fee);
                users[Orders[_orderId].creator].tokenYield[Orders[_orderId].token] += due - fee;
                Orders[_orderId].earnings += due -fee;    
                YieldForTokens[Orders[_orderId].token] += due;
                ES1.emitDuePaid(_orderId,borrower,orderMonthlyDue(_orderId,borrower,1));
            }
            if(Orders[_orderId].borrows[borrower].duesPaid != Orders[_orderId].borrows[borrower].duration){
                scheduleCheck(_orderId,borrower,1,_contractAddress);
            }
        }
    }
    
    function orderMonthlyDue(uint64 _orderId, address _borrower,uint _duration) public view returns(uint){
        if (Orders[_orderId].creator != address(0)) {
            (uint ecoPrice,uint tokenPrice ) = (fetchTokenPrice(ES1.WRAP_ECO_SYMBOL()), fetchTokenPrice(Orders[_orderId].token));
            uint principle = (Orders[_orderId].borrows[_borrower].amount*_duration)/Orders[_orderId].borrows[_borrower].duration;
            uint tokendue = principle +  (principle*Orders[_orderId].yield*_duration)/(100*Orders[_orderId].borrows[_borrower].duration);
            return (tokendue*tokenPrice)/ecoPrice;
        }
    }
    
    function borrowZero(uint _amount, string memory token, address userAddress, address _contractAddress) public {
        uint usdValue = _amount*fetchTokenPrice(token)/(10**8);
        require(getbuyPower(userAddress) >= usdValue,"power insufficient"); 
        require(!ES1.isUserLocked(userAddress) && ES1.friendlyaddress(msg.sender), "UserLocked Pay Dues");
        //users[userAddress].buyingPower -= usdValue;
        users[userAddress].borrows[token] += _amount;
        freeStorage memory newBorrow = freeStorage({  amount: _amount,
                                                    time: now,
                                                    wtoken: token,
                                                    usdvalue: usdValue   });
        users[userAddress].myBorrows.push(newBorrow);
        uint amount = _amount*(10**uint(wERC20(ETM.getwTokenAddress(token)).decimals()));
        wERC20(ETM.getwTokenAddress(token)).mint(userAddress,amount);
        if(!ES1.isRegistrar(userAddress)){
            scheduleCheck(0,userAddress,1,_contractAddress);
        }
    }
    
    function zeroDepositorPop(address userAddress, string memory _tokenSymbol, uint _amount) public {
        require(ES1.friendlyaddress(msg.sender),"Not Friendly Address");
        if(users[userAddress].deposits[_tokenSymbol]>0) {
            uint tokenUsdValue = _amount*fetchTokenPrice(_tokenSymbol)/(10**8);
            users[userAddress].deposits[_tokenSymbol] -= _amount;
            users[userAddress].totalDeposit -= tokenUsdValue;
            uint amountLeft= _amount;
            uint counter = users[userAddress].myDeposits.length;
            for( uint i= counter-1; amountLeft >0 ; i--){
                if (users[userAddress].myDeposits[i].amount < amountLeft){   
                    amountLeft -= users[userAddress].myDeposits[i].amount;
                    issueReward(userAddress, _tokenSymbol, users[userAddress].myDeposits[i].time, users[userAddress].myDeposits[i].amount*fetchTokenPrice(_tokenSymbol)/(10**8));
                    users[userAddress].myDeposits.pop(); 
                } else {
                    users[userAddress].myDeposits[i].amount -= amountLeft;
                    issueReward(userAddress, _tokenSymbol, users[userAddress].myDeposits[i].time, amountLeft*fetchTokenPrice(_tokenSymbol)/(10**8));
                    amountLeft = 0;
                }
            }    
        }
    }
    
    function zeroBorrowPop(address userAddress, string memory _tokenSymbol, uint _amount) public returns (uint) {
        require(ES1.friendlyaddress(msg.sender),"Not Friendly Address");
        if(users[userAddress].borrows[_tokenSymbol]>0) {
            uint tokenUsdValue = _amount*fetchTokenPrice(_tokenSymbol)/(10**8);
            users[userAddress].borrows[_tokenSymbol] -= _amount;
            users[userAddress].totalBorrowed -= tokenUsdValue;
            uint amountLeft= _amount;
            uint dues;
            uint counter = users[userAddress].myBorrows.length;
            for( uint i= counter-1; amountLeft >0 ; i--){
                if (users[userAddress].myBorrows[i].amount < amountLeft){
                    uint a = users[userAddress].myBorrows[i].amount;
                    amountLeft -= a;
                    dues+= calculateECOEarning(a*fetchTokenPrice(_tokenSymbol)/(10**8), _tokenSymbol, users[userAddress].myBorrows[i].time);
                    users[userAddress].myBorrows.pop(); 
                } else {
                    users[userAddress].myDeposits[i].amount -= amountLeft;
                    dues += calculateECOEarning(amountLeft*fetchTokenPrice(_tokenSymbol)/(10**8), _tokenSymbol, users[userAddress].myBorrows[i].time);
                    amountLeft = 0;
                }
            } 
            ES1.setOwnerFeeVault(_tokenSymbol, (dues*ES1.rewardFee()/100));
            return (dues*(ES1.rewardFee()+100)/100);
        }
    }
    
    function issueReward(address userAddress, string memory _tokenSymbol, uint time, uint tokenUsdValue) internal {
        wERC20 ecoToken = wERC20(ETM.getwTokenAddress(ES1.WRAP_ECO_SYMBOL()));
        uint reward = calculateECOEarning(tokenUsdValue, _tokenSymbol, time);
        ecoToken.mint(userAddress, reward);
    }
    
    function calculateECOEarning(uint usdvalue, string memory _tokenSymbol, uint time) private view returns (uint){
        uint _amount = usdvalue*fetchTokenPrice(ES1.WRAP_ECO_SYMBOL());
        uint reward = (_amount * ES1.slabRateDeposit(_tokenSymbol) * (time - now))/3155695200; //decimal from Abacus is setoff by decimal from Eco
        return reward;
    }
    
    function getECOEarnings(address userAddress) public view returns (uint){
        uint ecobalance;
        for(uint i=1; i<users[userAddress].myDeposits.length && i<users[userAddress].myBorrows.length; i++) {
            ecobalance += calculateECOEarning(users[userAddress].myDeposits[i].usdvalue, users[userAddress].myDeposits[i].wtoken, users[userAddress].myDeposits[i].time);
            ecobalance -= calculateECOEarning(users[userAddress].myBorrows[i].usdvalue, users[userAddress].myBorrows[i].wtoken, users[userAddress].myBorrows[i].time);
        }
        return ecobalance - users[userAddress].ecoWithdrawls;
    }
    
    function redeemEcoEarning(address userAddress, uint amount) external {
        require(ES1.friendlyaddress(msg.sender),"Not Friendly Address");
        users[userAddress].ecoWithdrawls += amount;
    }
    
     /*==============Helpers============
    ---------------------------------*/    
 
 
    function getOrderIds() public view returns(uint [] memory){
        return orderIds;
    }
    
    /*function getUserBorrowedOrders(address userAddress) public view returns(uint64 [] memory borrowedOrders){
        return users[userAddress].borrowedOrders;
    }*/
    
    function fetchTokenPrice(string memory _tokenSymbol) public view returns(uint64){ //Put any Token Wrapped or Direct
            return abacus.getJobResponse(ETM.getFetchId(_tokenSymbol))[0];
    }
    
}
