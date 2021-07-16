//SourceUnit: exchange.sol

pragma solidity 0.5.14;

contract ITRC20 {
  function transfer(address to, uint256 value) public returns (bool success);
  function transferFrom(address from, address to, uint256 value) public returns (bool success);
  function balanceOf(address account) external view returns(uint256);
  function allowance(address _owner, address _spender)external view returns(uint256);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

contract PlanetOneDEX {
    using SafeMath for uint;
    
    event DepositandWithdraw(address from,address tokenAddress,uint256 amount,uint256 type_); //Type = 0-deposit 1- withdraw , Token address = address(0) - eth , address - token address;
    event tradeEvent(uint _makerOrderID, uint _takerOrderID, uint _price, uint _makerTradeAmount, uint _takerTradeAmount, uint _timeStamp);
    event stakerFeeTransfer( address _staker, uint _amount);
    event referrerFeeTransfer( address _referrer, uint _amount);
    event referredBy( address _user, address _referrer);
    
    address payable public admin;
    address public tradeAddress;
    address public feeTokenAddress;
    address public POI;
    
    address[] stakerWallets;
    
    uint POIValue;
    
    bool public dexStatus;
    bool public feeTokenStatus;
    
    struct user{
        address ref;
        uint totalTrade;
        mapping(address => uint) _balance;
    }
      
    struct orders{
        address userAddress;
        address tokenAddress;
        uint8 status;
        uint128 type_;
        uint128 price;
        uint128 quantity;
        uint128 tradeQuantity;
    }
    
    struct tokens{
        address tokenAddress;
        string tokenSymbol;
        uint128 decimals;
        uint120 withdrawFee;
        uint8 status;
    }
    
    constructor(address payable _admin, address tradeAddress_, address _poi, address _stakerWallets1, address _stakerWallets2, address _stakerWallets3, address _stakerWallets4, address _stakerWallets5, address _stakerWallets6) public{ 
        admin = _admin;
        tradeAddress = tradeAddress_;
        POI = _poi;
        
        tokendetails[POI] = tokens(POI,"POI",1e18,0,1);
        
        feeTokenAddress = address(0);
        feeTokenStatus = true;
        
        tokendetails[address(0)] = tokens(address(0),"Trx",1e6,0,1);
        
        user_status[admin] = true;
        
        stakerWallets.push(_stakerWallets1);
        stakerWallets.push(_stakerWallets2);
        stakerWallets.push(_stakerWallets3);
        stakerWallets.push(_stakerWallets4);
        stakerWallets.push(_stakerWallets5);
        stakerWallets.push(_stakerWallets6);
        
        dexStatus = true;
    }

    mapping(uint256=>orders) public Order;
    
    mapping(address => user) public userDetails;
    
    mapping(address=>uint256) public withdrawfee;
     
    mapping(address=>tokens) public tokendetails;
     
    mapping(address=>bool) public user_status;
     
    mapping(uint256=>bool)public tradeOrders;
     
    mapping(address=>mapping(address=>uint256)) public adminProfit;
     
    mapping(bytes32 => bool) public signature;
    
    modifier dexstatuscheck(){
       require(dexStatus == true);
       _;
    }
    
    modifier onlyTradeAddress(){
        require(msg.sender == tradeAddress, "Only trader address");
       _;
    }
    
    modifier onlyOwner(){
    require(msg.sender == admin, "only owner");
      _;
    }
    
    modifier notOwner(){
    require(msg.sender != admin, "not owner");
      _;
    }
    
    function updatePOIValue( uint _valueTRX) public onlyOwner returns (bool) {
        require(_valueTRX > 0, "_valueTRX must be greater than zero");
        POIValue = _valueTRX;
        return true;
    }
    
    function setDexStatus(bool status_) onlyOwner public { dexStatus = status_; }   
    
    function changeTradeAddress(address changeTradeaddress) onlyOwner public { tradeAddress = changeTradeaddress; }
    
    function changeAdmin(address payable changeAdminaddress) onlyOwner public { admin = changeAdminaddress; }
 
    function setFeeToken(address feeTokenaddress, bool _status) onlyOwner public returns(bool){
        feeTokenAddress = feeTokenaddress;
        feeTokenStatus = _status;
        return true;
    }

    function addToken(address tokenAddress_,string memory tokenSymbol,uint128 decimal_,uint120 withdrawFee_) onlyTradeAddress public returns(bool){
        require(tokendetails[tokenAddress_].status == 0, "Token already added");
        tokendetails[tokenAddress_] = tokens(tokenAddress_,tokenSymbol,decimal_,withdrawFee_,1);
        return true;
    }
    
    function updateToken(address tokenAddress_,string memory tokenSymbol,uint128 decimal_,uint120 withdrawFee_) onlyTradeAddress public returns(bool){
        require(tokendetails[tokenAddress_].status == 1, "Token is not added");
        tokendetails[tokenAddress_] = tokens(tokenAddress_,tokenSymbol,decimal_,withdrawFee_,1);
        return true;
    }
    
    function addReferral( address _referral) public notOwner returns (bool) {
        require(_referral != address(0), "must not be a zero address");
        require(_referral != msg.sender,"referral and user must not be a same address");
        require(user_status[_referral] == true,"_referral is not registerred.");
        require(userDetails[msg.sender].ref == address(0),"already referred by a user.");
        
        userDetails[msg.sender].ref = _referral;
        user_status[msg.sender] = true; 
        emit referredBy( msg.sender, _referral);
        return true;
    }
    
    function deposit() dexstatuscheck notOwner public payable returns(bool) { 
        require(msg.value > 0, "value must be greater than zero");
        
        if(userDetails[msg.sender].ref == address(0)) { userDetails[msg.sender].ref = admin; emit referredBy( msg.sender, admin); }
        
        userDetails[msg.sender]._balance[address(0)] = userDetails[msg.sender]._balance[address(0)].add(msg.value.mul(1e18).div(tokendetails[address(0)].decimals));
        
        if(!user_status[msg.sender]) user_status[msg.sender] = true; 
        
        emit DepositandWithdraw( msg.sender, address(0),msg.value,0);
        return true;
    }
    
    function tokenDeposit(address tokenaddr,uint256 tokenAmount) dexstatuscheck notOwner public returns(bool)
    {
        require((tokenAmount > 0) && (tokendetails[tokenaddr].status == 1),"token amount is zero or token is not activated"); 
        require(ITRC20(tokenaddr).balanceOf(msg.sender) >= tokenAmount, "insufficient balance"); 
        require(ITRC20(tokenaddr).allowance(msg.sender,address(this)) >= tokenAmount,"insufficient allowance"); 
        
        if(userDetails[msg.sender].ref == address(0)) { userDetails[msg.sender].ref = admin; emit referredBy( msg.sender, admin);}
        
        userDetails[msg.sender]._balance[tokenaddr] = userDetails[msg.sender]._balance[tokenaddr].add(tokenAmount.mul(1e18).div(tokendetails[tokenaddr].decimals));
        ITRC20(tokenaddr).transferFrom(msg.sender,address(this), tokenAmount);
        
        if(!user_status[msg.sender]) user_status[msg.sender] = true; 
        
        emit DepositandWithdraw( msg.sender,tokenaddr,tokenAmount,0);
        return true;
    }
  
    function withdraw(uint8 type_,address tokenaddr,uint256 amount) dexstatuscheck notOwner public returns(bool) {
        require(type_ ==0 || type_ == 1); // type : 0- ether withdraw 1- token withdraw;
        
        if(type_==0){
            require(tokenaddr == address(0)); 
            require((amount>0) && (amount <= (userDetails[msg.sender]._balance[address(0)].mul(tokendetails[address(0)].decimals).mul(1e18)).div(1e18).div(1e18)) && (withdrawfee[address(0)] < amount));
            require(amount<=address(this).balance);
            
            tokenaddr = address(0);
            msg.sender.transfer(amount.sub(withdrawfee[tokenaddr])); 
        }
        else{
            require(tokenaddr != address(0) && tokendetails[tokenaddr].status==1); 
            require(amount>0 && amount <= ((userDetails[msg.sender]._balance[tokenaddr].mul(tokendetails[tokenaddr].decimals).mul(1e18)).div(1e18).div(1e18)) && withdrawfee[tokenaddr]<amount);
            ITRC20(tokenaddr).transfer(msg.sender, (amount.sub(withdrawfee[tokenaddr])));  
        }
        
        userDetails[msg.sender]._balance[tokenaddr] = userDetails[msg.sender]._balance[tokenaddr].sub(amount.mul(1e18).div(tokendetails[tokenaddr].decimals));  
        adminProfit[admin][tokenaddr] = adminProfit[admin][tokenaddr].add(withdrawfee[tokenaddr].mul(1e18).div(tokendetails[tokenaddr].decimals)); 
        
        emit DepositandWithdraw( msg.sender,tokenaddr,amount,1);
        return true;
    }
    
    function adminProfitWithdraw(uint8 type_,address tokenAddr,uint256 amount)public onlyOwner returns(bool){ 
       require(type_ ==0 || type_ == 1);
         if(type_==0){
            require((amount>0) && (amount <= (adminProfit[admin][address(0)].mul(tokendetails[address(0)].decimals).mul(1e18)).div(1e18).div(1e18))); 
            adminProfit[admin][address(0)] = adminProfit[admin][address(0)].sub(amount.mul(1e18).div(tokendetails[address(0)].decimals)); 
            admin.transfer(amount); 
        }
        else{
            require(tokenAddr != address(0)) ;
            require(amount>0 && amount <= ((adminProfit[admin][tokenAddr].mul(tokendetails[tokenAddr].decimals).mul(1e18)).div(1e18).div(1e18))); 
            adminProfit[admin][tokenAddr] = adminProfit[admin][tokenAddr].sub(amount.mul(1e18).div(tokendetails[tokenAddr].decimals));
            ITRC20(tokenAddr).transfer(admin, amount);
        }
        return true;
    }
        
        
    function setwithdrawfee(address[] memory addr,uint120[] memory feeamount)public onlyOwner returns(bool)  // admin can set withdraw fee for token and ether
    {
      require(addr.length <10 && feeamount.length < 10 && addr.length == feeamount.length);
      
      for(uint8 i=0;i<addr.length;i++){
        withdrawfee[addr[i]]=feeamount[i];   
        tokendetails[addr[i]].withdrawFee = feeamount[i];   
      }
       return true;
    }
    
    function verifyMessage(bytes32 msgHash, uint8 v, bytes32 r, bytes32 s) public pure returns (address){
     return ecrecover(msgHash, v, r, s);
    }
    
    // makerOrder
    // 0- orderid
    // 1- quantity
    // 2- price
    // 3 - type  1- buy 2- sell
    // 4-  expiryTime
    // 5 - trade amount
    // 6 - trade fee
    // 7 - buyer dex token status
  
    // takerOrder
    // 0- orderid
    // 1- quantity
    // 2- price
    // 3- type  1- buy 2- sell
    // 4- expiryTime
    // 5- trade amount
    // 6- trade fee
    // 7- buyer dex token status
  
    // tradeAddress
    // 0- makertokenAddress
    // 1- makeruserAddress
    // 2 - takertokenaddress
    // 3 - takeruseraddress
    
    function makeOrder(uint128[8] memory makerOrder, uint128[8] memory takerOrder,address[] memory traderAddress, bytes32[2] memory msgHash,uint8[2] memory  v,bytes32[4] memory rs) onlyTradeAddress public returns(bool){
        require(tradeOrders[makerOrder[0]]!=true && tradeOrders[takerOrder[0]] !=true,"order exist");
        require(makerOrder[4]>=block.timestamp && takerOrder[4]>=block.timestamp, "invalid expiry time");
        
        uint256 amount__m;
        uint256 amount__t;
        
        makerOrder[7]=0;
        takerOrder[7]=0;
        
        if(Order[makerOrder[0]].status ==0){ // if maker order is new;  && tradeAddress[0]!=feeTokenAddress
            // if maker buy or sell but receiving amt is fee token 
            if(traderAddress[2]==feeTokenAddress){
                (feeTokenStatus) ? makerOrder[7]=1 : makerOrder[7]=0;
            }
            else{
                require(userDetails[traderAddress[1]]._balance[feeTokenAddress]>=makerOrder[6],"maker insufficient fee amount");   // trade will happen event if fee amount is unset
                makerOrder[7]=1;
                
                if(traderAddress[0] == feeTokenAddress )
                  amount__m =amount__m.add(makerOrder[6]);
            }
            // vrs verification  for maker  when order is new;
            require(verifyMessage(msgHash[0],v[0],rs[0],rs[1])==tradeAddress,"maker signature failed");
            require((signature[msgHash[0]] != true), "maker signature exist");
            
            signature[msgHash[0]] = true;
            makerOrder[5] = makerOrder[1];
        }
        else{
            require(Order[makerOrder[0]].tradeQuantity > 0,"maker insufficient trade amount");
           
            makerOrder[2] = Order[makerOrder[0]].price;
            makerOrder[3] = Order[makerOrder[0]].type_;
            makerOrder[5] = Order[makerOrder[0]].tradeQuantity;
            traderAddress[0] = Order[makerOrder[0]].tokenAddress;
            traderAddress[1] = Order[makerOrder[0]].userAddress;
        }

        if(Order[takerOrder[0]].status ==0){  // if taker order is new;
            // if taker buy or sell but receiving amt is fee token 
            if(traderAddress[0]==feeTokenAddress){
                (feeTokenStatus) ? takerOrder[7]=1 : takerOrder[7]=0;
            }
            else{
                // trade will happen even if fee amount is unset
                require(userDetails[traderAddress[3]]._balance[feeTokenAddress]>=takerOrder[6],"taker insufficient fee amount");      
                takerOrder[7]=1;
                
                if(traderAddress[2] == feeTokenAddress)
                    amount__t = amount__t.add(takerOrder[6]);
            }
            
            // vrs verification  for taker  when order is new;
            require(verifyMessage(msgHash[1],v[1],rs[2],rs[3]) == tradeAddress,"taker signature failed");
            require((signature[msgHash[1]] != true), "taker signature exist");
            
            signature[msgHash[1]] = true;
            takerOrder[5] = takerOrder[1];
        }
        else{
            require(Order[takerOrder[0]].tradeQuantity > 0,"taker insufficient trade amount");
            takerOrder[2] = Order[takerOrder[0]].price;
            takerOrder[3] = Order[takerOrder[0]].type_;
            takerOrder[5] = Order[takerOrder[0]].tradeQuantity;
            traderAddress[2] = Order[takerOrder[0]].tokenAddress;
            traderAddress[3] = Order[takerOrder[0]].userAddress;
        }

        uint128 tradeAmount;

        if(takerOrder[5] > makerOrder[5])
            tradeAmount = makerOrder[5];
        else
            tradeAmount = takerOrder[5];
            
        //if maker order is buy 
        if(makerOrder[3] == 1){ 
            amount__m =amount__m.add(div128(mul128(tradeAmount,makerOrder[2]),1e18)) ; // maker buy trade amount
            amount__t =amount__t.add(tradeAmount);  // taker sell trade amount;
        }
        else{    //else maker order is sell 
            amount__m = amount__m.add(tradeAmount); // maker sell trade amount
            amount__t = amount__t.add(div128(mul128(tradeAmount,makerOrder[2]), 1e18)); // taker sell trade amount
        }
        
        require((userDetails[traderAddress[1]]._balance[traderAddress[0]] >= amount__m) && (amount__m > 0), "insufficient maker balance to trade");
        require((userDetails[traderAddress[3]]._balance[traderAddress[2]] >= amount__t) && (amount__t > 0), "insufficient taker balance to trade");
        
        if(takerOrder[5] > makerOrder[5]){
            if(Order[takerOrder[0]].status!=1)
                Order[takerOrder[0]] = orders(traderAddress[3],traderAddress[2],1,takerOrder[3],takerOrder[2],takerOrder[1],takerOrder[5]);
            
            Order[takerOrder[0]].tradeQuantity -=tradeAmount; 
            Order[makerOrder[0]].tradeQuantity=0;
            tradeOrders[makerOrder[0]] = true;
        }
        else if(takerOrder[5] < makerOrder[5]){
            if(Order[makerOrder[0]].status!=1  ){
                Order[makerOrder[0]] = orders(traderAddress[1],traderAddress[0],1,makerOrder[3],makerOrder[2],makerOrder[1],makerOrder[5]);     
            }
            
            Order[makerOrder[0]].tradeQuantity -=tradeAmount;
            Order[takerOrder[0]].tradeQuantity=0;
            tradeOrders[takerOrder[0]] = true;
        }
        else{
            Order[makerOrder[0]].tradeQuantity=0;
            Order[takerOrder[0]].tradeQuantity=0;
            tradeOrders[makerOrder[0]] = true;
            tradeOrders[takerOrder[0]] = true;
        }
        // maker receive amount
        makerOrder[5] = uint128(amount__t); 
        // taker receive amount
        takerOrder[5] = uint128(amount__m);
                    
        if(makerOrder[7]==1 ){
            // If maker is seller and token sold is feetoken
            // fee is deducted from the user(maker) and admin balance(feetoken) is updated
            if(traderAddress[0] == feeTokenAddress){
                amount__m = amount__m.sub(makerOrder[6]);
                takerOrder[5]=sub128(takerOrder[5],uint128(makerOrder[6]));
                // reduce user balance
                userDetails[traderAddress[1]]._balance[feeTokenAddress] =userDetails[traderAddress[1]]._balance[feeTokenAddress].sub(makerOrder[6]);
                // update admin balance
                feeDistribution( traderAddress[1], makerOrder[6]);
            }
            // If maker is buyer and token buy is fee token or maker is seller and receiving token is fee token.
            else if(traderAddress[2] == feeTokenAddress){
                // trade amount >= feeAmount
                if(makerOrder[5]>=makerOrder[6]){
                    makerOrder[5] = sub128(makerOrder[5],uint128(makerOrder[6]));
                    feeDistribution( traderAddress[1], makerOrder[6]);    
                }
                // trade amount < feeAmount
                else{
                    feeDistribution( traderAddress[1], makerOrder[5]);
                    makerOrder[5] = 0;
                }
            }
            else{
                userDetails[traderAddress[1]]._balance[feeTokenAddress] = userDetails[traderAddress[1]]._balance[feeTokenAddress].sub(makerOrder[6]);
                feeDistribution( traderAddress[1], makerOrder[6]);
            }
        }
            
        if(takerOrder[7]==1){
            // If taker is seller and token sold is feetoken
            // fee is deducted from the user(taker) and admin balance(feetoken) is updated
            if(traderAddress[2] == feeTokenAddress){
                amount__t = amount__t.sub(takerOrder[6]);
                makerOrder[5] =sub128(makerOrder[5],uint128(takerOrder[6]));
                userDetails[traderAddress[3]]._balance[feeTokenAddress] = userDetails[traderAddress[3]]._balance[feeTokenAddress].sub(takerOrder[6]);
                feeDistribution( traderAddress[3], takerOrder[6]); 
            }
            // If taker is buyer and token buy is fee token or taker is seller and receiving token is fee token.
            else if(traderAddress[0] == feeTokenAddress){
                if(takerOrder[5]>=takerOrder[6]){
                    takerOrder[5] = sub128(takerOrder[5],uint128(takerOrder[6]));
                    feeDistribution( traderAddress[3], takerOrder[6]);    
                }
                else{
                    feeDistribution( traderAddress[3], takerOrder[5]);
                    takerOrder[5]=0;
                }
            }
            else{
                userDetails[traderAddress[3]]._balance[feeTokenAddress] = userDetails[traderAddress[3]]._balance[feeTokenAddress].sub(takerOrder[6]);
                feeDistribution( traderAddress[3],takerOrder[6]);
            }
        }

        userDetails[traderAddress[1]]._balance[traderAddress[0]] = userDetails[traderAddress[1]]._balance[traderAddress[0]].sub(amount__m);   // freeze buyer amount   
        userDetails[traderAddress[3]]._balance[traderAddress[2]] = userDetails[traderAddress[3]]._balance[traderAddress[2]].sub(amount__t);   // freeze buyer amount 
        
        userDetails[traderAddress[1]]._balance[traderAddress[2]] = userDetails[traderAddress[1]]._balance[traderAddress[2]].add(makerOrder[5]); //marker order
        userDetails[traderAddress[3]]._balance[traderAddress[0]] = userDetails[traderAddress[3]]._balance[traderAddress[0]].add(takerOrder[5]); //take order
        
        emit tradeEvent(makerOrder[0], takerOrder[0], makerOrder[2], makerOrder[5], takerOrder[5], block.timestamp);
        
        return true;
    }
    
    function failsafe( address token, address _to, uint amount) public onlyOwner returns (bool) {
        address _contractAdd = address(this);
        if(token == address(0)){
            require(_contractAdd.balance >= amount,"insufficient TRX");
            address(uint160(_to)).transfer(amount);
        }
        else{
            require( ITRC20(token).balanceOf(_contractAdd) >= amount,"insufficient Token balance");
            ITRC20(token).transfer(_to, amount);
        }
    }
    
    function feeDistribution( address trader, uint amount) internal returns (bool) {
        userDetails[trader].totalTrade++;
        
        uint fivePercent = amount.mul(5).div(100);
        uint seventyPercent = amount.mul(70).div(100);
        
        for(uint i=0;i<6;i++){
            if(i ==0) {
                address(uint160(stakerWallets[i])).transfer(seventyPercent.mul(tokendetails[feeTokenAddress].decimals).div(1e18));
                emit stakerFeeTransfer( stakerWallets[i], seventyPercent.mul(tokendetails[feeTokenAddress].decimals).div(1e18));
            }
            else{
                address(uint160(stakerWallets[i])).transfer(fivePercent.mul(tokendetails[feeTokenAddress].decimals).div(1e18));
                emit stakerFeeTransfer( stakerWallets[i], fivePercent.mul(tokendetails[feeTokenAddress].decimals).div(1e18));
            }
        }
        
        if(userDetails[trader].totalTrade < 5){ distributeRefFee(trader, userDetails[trader].ref, amount); }
        
        return true;
    }
    
    function distributeRefFee( address _trader, address _referrer, uint _amount) internal {
        uint _fee;
        
        if(userDetails[_trader].totalTrade == 1){ _fee = computeFee( _amount, 4); }
        else if(userDetails[_trader].totalTrade == 2){ _fee = computeFee( _amount, 3); }
        else if(userDetails[_trader].totalTrade == 3){ _fee = computeFee( _amount, 2); }
        else if(userDetails[_trader].totalTrade == 4){ _fee = computeFee( _amount, 1); }
        
        if(_referrer != admin)
            userDetails[_referrer]._balance[POI] = userDetails[_referrer]._balance[POI].add(_fee);
        else
            adminProfit[admin][POI] = adminProfit[admin][POI].add(_fee); 
            
        emit referrerFeeTransfer( _referrer, _fee);
    }
    
    function getTokenBalance( address _user, address _token) public view returns (uint) {
        return userDetails[_user]._balance[_token];
    }
    
    function computeFee( uint amount, uint distribution) public view returns (uint) {
        uint _fee = amount.mul(distribution).div(100);
        return  _fee.mul(1e18).div(POIValue);
    }
    
    function sub128(uint128 a, uint128 b) internal pure  returns (uint128) {
        assert(b <= a);
        return a - b;
    }
    
    function mul128(uint128 a, uint128 b) internal pure returns (uint128) {
        if (a == 0) {
            return 0;
        }
        uint128 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    
    function div128(uint128 a, uint128 b) internal pure returns (uint128) {
        require(b > 0, "SafeMath: division by zero");
        uint128 c = a / b;
        return c;
    }
    
}