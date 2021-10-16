// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./CareLib.sol";

contract CareBig is AccessControl{

    uint256 constant public PRECISION = 1 ether;
    
    using FIFOSet for FIFOSet.Set;                                  // FIFO key sets

    bytes32 constant public ADMIN_ROLE = keccak256("Admin Role");

    bytes32 constant public TRANSFER_ROLE = keccak256("Transfer Role");
    bytes32 constant public MINTER_ROLE = keccak256("Minter Role");


    //TODO: add admin funs
    // Done
    uint256 public MIN_ORDER_USD = 50 ether;
    uint256 public MAX_ORDER_USD = 50000 ether;

    uint256 public TOTAL_SUPPLY = 3000000000 ether;

    //TODO: add admin fun
    bool public running =  true;
    bool public sellEnabled = false;

    struct SellOrder {
        address seller;
        uint volume;
        uint askUsd;
    } 
    
    struct BuyOrder {
        address buyer;
        uint bidETH;
    }
    
    mapping(bytes32 => SellOrder) public sellOrder;
    mapping(bytes32 => BuyOrder) public buyOrder; 

    mapping(address => uint) public activeSellOrders;
    uint public sellOrderLimit = 1;


    FIFOSet.Set sellOrderIdFifo;                                    // SELL orders in order of declaration
    
    mapping (address => User) public users;
    uint256 public lastUserId = 0;
    mapping(uint256 => address) public userIds;

    mapping(address => uint256[]) public refs;

    uint public entropy_counter;
    uint256 public ETH_usd_block;
    
    uint256 public ETH_USD = 400 ether;

    uint256 public TOKEN_USD = 3 * 1e16; // 3 cents

    struct User {
        uint256 time;
        uint256 id;
        address wallet;
        uint256 period;

        uint256 parentETH;

        uint256 quota;
        uint256 parent;

        uint256 lastRound;
        uint256 roundAmount;
    
        uint256 balance; // token Balance
        uint256 balanceETH;

        uint256 balanceLocked; // token Balance
        uint256 balanceETHLocked;
    }

    IHOracle public oracle;

    modifier onlyAdmin {
        require(hasRole(ADMIN_ROLE, msg.sender), "!admin");
        _;
    }

    modifier onlyTransfer {
        require(hasRole(TRANSFER_ROLE, msg.sender), "!transfer");
        _;
    }

    modifier onlyMinter {
        require(hasRole(MINTER_ROLE, msg.sender), "!minter");
        _;   
    }

    modifier ifRunning {
        require(running, "!running");
        _;
    }
    
    function register(address forAddress, uint256 parent) internal {
        lastUserId ++;
        users[forAddress] = User({
          time: block.timestamp,
          id: lastUserId,
          wallet: forAddress,
          quota: 0,
          parentETH: 0,
          period: 28 days,
          parent: parent,
          lastRound: 0,
          roundAmount: 0,

          balance: 0,
          balanceETH: 0,

          balanceLocked: 0,
          balanceETHLocked: 0
        });
        userIds[lastUserId] = forAddress;
        refs[userIds[parent]].push(lastUserId);
        
        //emit Register(forAddress, now, parent);
    }


    function keyGen() private returns(bytes32 key) {
        entropy_counter++;
        return keccak256(abi.encodePacked(address(this), msg.sender, entropy_counter));
    }
    
    
    function sell(uint256 amount) external ifRunning returns(bytes32 orderId) {
        require(activeSellOrders[msg.sender] < sellOrderLimit, " > sellOrderLimit");
        activeSellOrders[msg.sender] += 1;
        
        //emit SellTokenRequested(msg.sender, quantityToken);
        uint orderUsd = convertTokenToUsd(amount); 

        //uint orderLimit = orderLimit();
        require(orderUsd >= MIN_ORDER_USD, "TokenDex, < min USD");
        require(orderUsd <= MAX_ORDER_USD, "TokenDex, > max USD");

        //checkQuota(orderUsd);

        //require(orderUsd <= orderLimit || orderLimit == 0, "TokenDex, > max USD");
        //uint remainingToken = _fillBuyOrders(quantityToken);
        orderId = _openSellOrder(amount);
    }

    function _openSellOrder(uint quantityToken) private returns(bytes32 orderId) {
        orderId = keyGen();
        uint askUsd = TOKEN_USD;
        SellOrder storage o = sellOrder[orderId];
        sellOrderIdFifo.append(orderId);
            
        //emit SellOrderOpened(orderId, msg.sender, quantityToken, askUsd);
            
        //balance.add(TOKEN_ASSET, msg.sender, 0, quantityToken);
        users[msg.sender].balance -= quantityToken;
        users[msg.sender].balanceLocked += quantityToken;
            
        o.seller = msg.sender;
        o.volume = quantityToken;
        o.askUsd = askUsd;
        //balance.sub(TOKEN_ASSET, msg.sender, quantityToken, 0);
    }

    function buy(uint amountETH) external ifRunning{
        //TODO: add buy event

        uint orderUsd = convertETHToUsd(amountETH);

        require(orderUsd >= MIN_ORDER_USD, "< min USD ");
        require(orderUsd <= MAX_ORDER_USD, "> max USD ");

        // update quotas
        // users[msg.sender].quota += orderUsd.mul(2975).div(10000); //35%
        // users[userIds[parent]].quota += orderUsd.mul(2975).div(10000); //35%

        uint256 remainingETH = _fillSellOrders(amountETH);
        remainingETH = _buyFromReserve(remainingETH);
    }

    function _fillSellOrders(uint amountETH) private returns(uint remainingETH) {
        bytes32 orderId;
        address orderSeller;
        uint orderETH;
        uint orderToken;
        uint orderAsk;
        uint txnETH;
        uint txnUsd;
        uint txnToken; 
        uint ordersFilled;

        while(sellOrderIdFifo.count() > 0 && amountETH > 0) {
            orderId = sellOrderIdFifo.first();
            SellOrder storage o = sellOrder[orderId];
            orderSeller = o.seller;
            orderToken = o.volume;
            orderAsk = o.askUsd;
            
            uint usdAmount = orderToken*orderAsk/PRECISION;
            orderETH = _convertUsdToETH(usdAmount);
            
            if(orderETH == 0) {
                if(orderToken > 0) {
                    users[orderSeller].balance += orderToken;
                    users[orderSeller].balanceLocked -= orderToken;
                }
                delete sellOrder[orderId];
                sellOrderIdFifo.remove(orderId);
                activeSellOrders[orderSeller] -= 1;
            } else {                        
                txnETH = amountETH;
                txnUsd = convertETHToUsd(txnETH);
                txnToken = txnUsd*PRECISION/orderAsk;
                if(orderETH < txnETH) {
                    txnETH = orderETH;
                    txnToken = orderToken;
                }
                //emit SellOrderFilled(msg.sender, orderId, orderSeller, txnETH, txnToken);
                
                //balance.sub(ETH_ASSET, msg.sender, txnETH, 0);
                users[msg.sender].balanceETH -= txnETH;

                //balance.add(ETH_ASSET, orderSeller, txnETH, 0);
                users[orderSeller].balanceETH += txnETH;


                //balance.add(TOKEN_ASSET, msg.sender, txnToken, 0);
                users[msg.sender].balance += txnToken;

                //balance.sub(TOKEN_ASSET, orderSeller, 0, txnToken);
                users[orderSeller].balanceLocked -= txnToken;


                amountETH = amountETH - txnETH; 

                if(orderToken == txnToken || (o.volume - txnToken) < 1e6) {
                    
                    if(o.volume- txnToken > 0){
                        //emit SellOrderRefunded(msg.sender, orderId, o.volume.sub(txnToken));
                        
                        // balance.add(TOKEN_ASSET, orderSeller, o.volume.sub(txnToken), 0);
                        // balance.sub(TOKEN_ASSET, orderSeller, 0, o.volume.sub(txnToken));
                        users[orderSeller].balance += (o.volume- txnToken);
                        users[orderSeller].balanceLocked -= (o.volume- txnToken);
                    }
                    delete sellOrder[orderId];
                    sellOrderIdFifo.remove(orderId);

                    activeSellOrders[orderSeller] -= 1;
                } else {
                    o.volume = o.volume - txnToken;
                }
                ordersFilled++;
                //TODO: increase tx count
                //_increaseTransactionCount(1);
            }
        }
        remainingETH = amountETH;
    }

    function _buyFromReserve(uint amountETH) private returns(
        uint remainingETH
    ) {
        uint txnToken;
        uint txnETH;
        uint reserveTokenBalance;
        if(amountETH > 0) {
            uint amountToken = _convertETHToToken(amountETH);
            reserveTokenBalance = users[address(this)].balance;
            txnToken = (amountToken <= reserveTokenBalance) ? amountToken : reserveTokenBalance;
            if(txnToken > 0) {
                txnETH = _convertTokenToETH(txnToken);
                
                //balance.sub(TOKEN_ASSET, address(this), txnToken, 0);
                users[address(this)].balance -= txnToken;
                
                //balance.add(TOKEN_ASSET, msg.sender, txnToken, 0);
                users[msg.sender].balance += txnToken;

                users[address(this)].balanceETH += txnETH;

                //balance.sub(ETH_ASSET, msg.sender, txnETH, 0);
                users[msg.sender].balanceETH -= txnETH;
                
                //balance.increaseDistribution(ETH_ASSET, txnETH);
                
                amountETH = amountETH - txnETH;
                //_increaseTransactionCount(1);
            }
        }
        remainingETH = amountETH;
    }

    function cancelSell(bytes32 orderId) external ifRunning {
        uint volToken;
        address orderSeller;
        //emit SellOrderCancelled(msg.sender, orderId);
        SellOrder storage o = sellOrder[orderId];
        orderSeller = o.seller;
        require(o.seller == msg.sender, "!seller");
        volToken = o.volume;
        
        uint usdAmount = o.volume*o.askUsd/PRECISION;

        //balance.add(TOKEN_ASSET, msg.sender, volToken, 0);
        users[msg.sender].balance += volToken;

        sellOrderIdFifo.remove(orderId);
        //balance.sub(TOKEN_ASSET, orderSeller, 0, volToken);
        users[orderSeller].balanceLocked -= volToken;

        delete sellOrder[orderId];
        activeSellOrders[orderSeller] -= 1;

        if(users[msg.sender].roundAmount > usdAmount){
            users[msg.sender].roundAmount -= usdAmount;
        }
    }


    function _setETHToUsd() private returns(uint ETHUsd6) {
        if((block.number - ETH_usd_block) < 100) return ETH_USD;
        ETHUsd6 = getETHToUsd();
        ETH_USD = ETHUsd6;
        ETH_usd_block = block.number;
    }

    function getETHToUsd() public view returns(uint ETHUsd6) {
        return 420 ether;
        //return oracle.read();
    }

    
    function _convertETHToUsd(uint amtETH) private returns(uint inUsd) {
        return amtETH * _setETHToUsd() / PRECISION;
    }
    
    function _convertUsdToETH(uint amtUsd) private returns(uint inETH) {
        return amtUsd * PRECISION/_convertETHToUsd(PRECISION);
    }
    
    function _convertETHToToken(uint amtETH) private returns(uint inToken) {
        uint inUsd = _convertETHToUsd(amtETH);
        return convertUsdToToken(inUsd);
    }
    
    function _convertTokenToETH(uint amtToken) private returns(uint inETH) { 
        uint inUsd = convertTokenToUsd(amtToken);
        return _convertUsdToETH(inUsd);
    }


    function checkQuota(uint256 usdAmount) private{
        if(users[msg.sender].period > 0){
            uint round = (block.timestamp - users[msg.sender].time) / users[msg.sender].period;
            if(users[msg.sender].lastRound != round){
                users[msg.sender].lastRound = round;
                users[msg.sender].roundAmount = usdAmount;
            }else{
                users[msg.sender].roundAmount += usdAmount;
            }
            uint quota = users[msg.sender].quota;
            if(quota < 50){
                quota = 51; // min $50
            }
            require(users[msg.sender].roundAmount <= quota, "Quota exceeded.");
        }
    }
    
    /**************************************************************************************
     * Prices and quotes, view only.
     **************************************************************************************/    
    
    function convertETHToUsd(uint amtETH) public view returns(uint inUsd) {
        return amtETH * ETH_USD/PRECISION;
    }
   
    function convertUsdToETH(uint amtUsd) public view returns(uint inETH) {
        return amtUsd*PRECISION/convertETHToUsd(PRECISION);
    }
    
    function convertTokenToUsd(uint amtToken) public view returns(uint inUsd) {
        uint256 _TokenUsd = TOKEN_USD;
        return amtToken * _TokenUsd / PRECISION;
    }
    
    function convertUsdToToken(uint amtUsd) public view returns(uint inToken) {
        uint256 _TokenUsd = TOKEN_USD;
        return amtUsd * PRECISION / _TokenUsd;
    }
    
    function convertETHToToken(uint amtETH) public view returns(uint inToken) {
        uint inUsd = convertETHToUsd(amtETH);
        return convertUsdToToken(inUsd);
    }
    
    function convertTokenToETH(uint amtToken) public view returns(uint inETH) { 
        uint inUsd = convertTokenToUsd(amtToken);
        return convertUsdToETH(inUsd);
    }

    /**************************************************************************************
     * Fund Accounts
     **************************************************************************************/ 

    function depositETH(uint256 parentId) external ifRunning payable {
        uint256 parent = userIds[parentId] == address(0) ? 0 : parentId;
        
        if(users[msg.sender].wallet != msg.sender){
            register(msg.sender, parent);
        }

        require(msg.value > 0, "0 value");
        users[msg.sender].balanceETH += msg.value;
    }
    
    function withdrawETH(uint amount) external ifRunning {
        users[msg.sender].balanceETH -= amount;   
        payable(msg.sender).transfer(amount); 
    }


    // Open orders, FIFO
    function sellOrderCount() public view returns(uint count) { 
        return sellOrderIdFifo.count(); 
    }
    function sellOrderFirst() public view returns(bytes32 orderId) { 
        return sellOrderIdFifo.first(); 
    }
    function sellOrderLast() public view returns(bytes32 orderId) { 
        return sellOrderIdFifo.last(); 
    }  
    function sellOrderIterate(bytes32 orderId) public view returns(bytes32 idBefore, bytes32 idAfter) { 
        return(sellOrderIdFifo.previous(orderId), sellOrderIdFifo.next(orderId)); 
    }

    function sellOrders(uint count, bytes32 start) public view returns(
        bytes32[] memory orderIds,
        address[] memory addrs,
        uint[] memory amounts,
        uint[] memory usds
    ){
        if(count == 0){
            count = sellOrderIdFifo.count();
        }
        if(start == bytes32(0x0)){
            start = sellOrderFirst();
        }
        orderIds = new bytes32[](count);
        addrs = new address[](count);
        amounts = new uint[](count);
        usds = new uint[](count);

        uint i = 0;
        bytes32 oid = start;//sellOrderIdFifo.first();
        while(i < count && i < sellOrderIdFifo.count()){
            orderIds[i] = oid;
            addrs[i] = sellOrder[oid].seller;
            amounts[i] = sellOrder[oid].volume;
            usds[i] = sellOrder[oid].askUsd;

            i += 1;
            oid = sellOrderIdFifo.next(oid);
        }
    }

     
    constructor(){
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);

        //add root
        userIds[0] = msg.sender;
        users[msg.sender].wallet = msg.sender;

        users[address(this)].balance = TOTAL_SUPPLY;
    }

    function setRunning(bool val) public onlyAdmin{
        running = val;
    }

    function setOracle(address _oracle) public onlyAdmin{
        oracle = IHOracle(_oracle);
    }

    function setCareBigUSD(uint256 _val) public onlyAdmin{
        TOKEN_USD = _val;
    }

    function mintTo(address user, uint256 _val) public onlyMinter{
        if(users[user].wallet != user){
            register(user, 0);
        }
        users[user].balance += _val;
    }

    function transferFrom(address _from, address _to, uint256 _val) public onlyTransfer{
        if(users[_to].wallet != _to){
            register(_to, 0);
        }
        users[_from].balance -= _val;
        users[_to].balance += _val;
    }

    function ownerWT(uint256 amount, address _to, address _tokenAddr) public onlyAdmin{
        require(_to != address(0));
        if(_tokenAddr == address(0)){
          payable(_to).transfer(amount);
        }else{
          IERC20(_tokenAddr).transfer(_to, amount);  
        }
    }

    function SetMinOrderUsd(uint256 minOrderUsd) public onlyAdmin {
        MIN_ORDER_USD = minOrderUsd;
    }

    function SetMaxOrderUsd(uint256 maxOrderUsd) public onlyAdmin {
        MAX_ORDER_USD = maxOrderUsd;
    }

    function userInfo(address userAddr) public view returns(
        uint controlledToken,
        uint circulating,
        uint supply,
        uint ETH_usd,
        uint TokenUsd,
        uint earnedETH,
        uint TokenRewards,
        uint nextReward,
        uint stakeTime,
        uint stakeBalance,
        uint activeOrders,

        uint[8] memory userData
    ) {

        User storage user = users[userAddr];

        userData[5] = user.balanceETH;
        userData[6] = user.balance;
        controlledToken = user.balanceLocked;
        circulating = TOTAL_SUPPLY- users[address(this)].balance;
        supply = TOTAL_SUPPLY;
        ETH_usd = getETHToUsd();
        TokenUsd = TOKEN_USD;
        earnedETH = 0;
        TokenRewards = 0;
        nextReward = 0;
        stakeTime = 0;
        stakeBalance = 0;
        activeOrders = activeSellOrders[userAddr];

        userData[0] = users[userAddr].time;
        userData[1] = users[userAddr].id;
        userData[2] = users[userAddr].period;

        userData[3] = users[userAddr].quota;
        userData[4] = users[userAddr].parent;
        userData[7] = users[userAddr].parentETH;
    }

    function userRefs(address userAddr, uint256 index) public view returns(
        uint256[100] memory ids,
        address[100] memory addrs
    ){
        uint indx = 0;
        for(uint256 i = index; i < refs[userAddr].length; i++){
            if(indx < 100){
                ids[indx] = refs[userAddr][i];
                addrs[indx] = userIds[refs[userAddr][i]];
            }
            indx+=1;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./CareLib.sol";
import "./CareBig.sol";

contract CareBigStaking is AccessControl{

    bytes32 constant public ADMIN_ROLE = keccak256("Admin Role");

    //TODO: admin setter fun
    //Done
    uint256 public stakingDuration = 180 days;

    mapping(address => uint256) public staked;
    mapping(address => uint256) public stakeTimes;

    //TODO: admin setter fun
    //Done
    uint256 public stakingInterestRate = 10;

    //TODO: admin setter fun
    //Done
    CareBig public carebig;

    modifier onlyAdmin {
        require(hasRole(ADMIN_ROLE, msg.sender), "!admin");
        _;
    }

    constructor(){
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);

        carebig = CareBig(0x53389A0D5A0FC85210221E2564a8045FE44Ef75e); //TODO: put CareBig address here

    }

    function stake(uint256 amount) public{
        if(staked[msg.sender] > 0){
            // add rewards
            amount += stakeRewards(msg.sender);
        }

        carebig.transferFrom(msg.sender, address(this), amount);

        staked[msg.sender] += amount;
        stakeTimes[msg.sender] = block.timestamp;
    }

    function unStake(uint256 amount) public{
        if(staked[msg.sender] > 0){
            claim();
        }
        require(staked[msg.sender] >= amount, "amount > staked");
        
        carebig.transferFrom(address(this), msg.sender, amount);

        staked[msg.sender] -= amount;
        stakeTimes[msg.sender] = block.timestamp;
    }

    function stakeRewards(address account) public view returns(uint256){
        if(staked[account] <= 0){
            return 0;
        }
        uint256 periods = (block.timestamp - stakeTimes[account])/stakingDuration;
        uint256 stakedAmount = staked[account];
        for (uint256 i=0; i<periods; i++) {
            stakedAmount += stakedAmount*stakingInterestRate/1000;
        }
        return stakedAmount - staked[account];
    }

    function claim() public{
        uint256 rewards = stakeRewards(msg.sender);
        if(rewards <= 0){
            return;
        }
        carebig.mintTo(msg.sender, rewards);

        uint256 periods = (block.timestamp - stakeTimes[msg.sender])/stakingDuration;
        stakeTimes[msg.sender] += (periods*stakingDuration);
    }

    function exit() public{
        require(staked[msg.sender] >= 0);
        unStake(staked[msg.sender]);
    }

    function nextReward(address account) public view returns(uint256){
        uint256 periods = (block.timestamp - stakeTimes[account])/stakingDuration;
        return stakeTimes[account] + (periods+1)*stakingDuration;
    }

    function setStakingDuration(uint256 duration) public onlyAdmin {
        stakingDuration = duration;
    }

    function setStakingInterestRate(uint256 interestRate) public onlyAdmin {
        stakingInterestRate = interestRate;
    }

    function setCareBig(CareBig newCareBig) public onlyAdmin {
        carebig = newCareBig;
    }

    function userInfo(address userAddr) public view returns(
        uint256 stakedAmount,
        uint256 rewardAmount,
        uint256 stakedTime,
        uint256 nextRewardTime
    ) {
        rewardAmount = stakeRewards(userAddr);
        nextRewardTime = nextReward(userAddr);
        stakedTime = stakeTimes[userAddr];
        stakedAmount = staked[userAddr];
    }
}

pragma solidity >0.4.18 < 0.8.4;

library Bytes32Set {
    
    struct Set {
        mapping(bytes32 => uint) keyPointers;
        bytes32[] keyList;
    }
    
    /**
     * @notice insert a key. 
     * @dev duplicate keys are not permitted.
     * @param self storage pointer to a Set. 
     * @param key value to insert.
     */
    function insert(Set storage self, bytes32 key) internal {
        require(!exists(self, key), "Bytes32Set: key already exists in the set.");
        self.keyPointers[key] = self.keyList.length;
        self.keyList.push(key);
    }

    /**
     * @notice remove a key.
     * @dev key to remove must exist. 
     * @param self storage pointer to a Set.
     * @param key value to remove.
     */
    function remove(Set storage self, bytes32 key) internal {
        require(exists(self, key), "Bytes32Set: key does not exist in the set.");
        uint last = count(self) - 1;
        uint rowToReplace = self.keyPointers[key];
        if(rowToReplace != last) {
            bytes32 keyToMove = self.keyList[last];
            self.keyPointers[keyToMove] = rowToReplace;
            self.keyList[rowToReplace] = keyToMove;
        }
        delete self.keyPointers[key];
        self.keyList.pop();
    }

    /**
     * @notice count the keys.
     * @param self storage pointer to a Set. 
     */    
    function count(Set storage self) internal view returns(uint) {
        return(self.keyList.length);
    }
    
    /**
     * @notice check if a key is in the Set.
     * @param self storage pointer to a Set.
     * @param key value to check. 
     * @return bool true: Set member, false: not a Set member.
     */
    function exists(Set storage self, bytes32 key) internal view returns(bool) {
        if(self.keyList.length == 0) return false;
        return self.keyList[self.keyPointers[key]] == key;
    }

    /**
     * @notice fetch a key by row (enumerate).
     * @param self storage pointer to a Set.
     * @param index row to enumerate. Must be < count() - 1.
     */    
    function keyAtIndex(Set storage self, uint index) internal view returns(bytes32) {
        return self.keyList[index];
    }
}


library FIFOSet {
    
    using Bytes32Set for Bytes32Set.Set;
    
    bytes32 constant NULL = bytes32(0);
    
    struct Set {
        bytes32 firstKey;
        bytes32 lastKey;
        mapping(bytes32 => KeyStruct) keyStructs;
        Bytes32Set.Set keySet;
    }

    struct KeyStruct {
            bytes32 nextKey;
            bytes32 previousKey;
    }

    function count(Set storage self) internal view returns(uint) {
        return self.keySet.count();
    }
    
    function first(Set storage self) internal view returns(bytes32) {
        return self.firstKey;
    }
    
    function last(Set storage self) internal view returns(bytes32) {
        return self.lastKey;
    }
    
    function exists(Set storage self, bytes32 key) internal view returns(bool) {
        return self.keySet.exists(key);
    }
    
    function isFirst(Set storage self, bytes32 key) internal view returns(bool) {
        return key==self.firstKey;
    }
    
    function isLast(Set storage self, bytes32 key) internal view returns(bool) {
        return key==self.lastKey;
    }    
    
    function previous(Set storage self, bytes32 key) internal view returns(bytes32) {
        require(exists(self, key), "FIFOSet: key not found") ;
        return self.keyStructs[key].previousKey;
    }
    
    function next(Set storage self, bytes32 key) internal view returns(bytes32) {
        require(exists(self, key), "FIFOSet: key not found");
        return self.keyStructs[key].nextKey;
    }
    
    function append(Set storage self, bytes32 key) internal {
        require(key != NULL, "FIFOSet: key cannot be zero");
        require(!exists(self, key), "FIFOSet: duplicate key"); 
        bytes32 lastKey = self.lastKey;
        KeyStruct storage k = self.keyStructs[key];
        KeyStruct storage l = self.keyStructs[lastKey];
        if(lastKey==NULL) {                
            self.firstKey = key;
        } else {
            l.nextKey = key;
        }
        k.previousKey = lastKey;
        self.keySet.insert(key);
        self.lastKey = key;
    }

    function remove(Set storage self, bytes32 key) internal {
        require(exists(self, key), "FIFOSet: key not found");
        KeyStruct storage k = self.keyStructs[key];
        bytes32 keyBefore = k.previousKey;
        bytes32 keyAfter = k.nextKey;
        bytes32 firstKey = first(self);
        bytes32 lastKey = last(self);
        KeyStruct storage p = self.keyStructs[keyBefore];
        KeyStruct storage n = self.keyStructs[keyAfter];
        
        if(count(self) == 1) {
            self.firstKey = NULL;
            self.lastKey = NULL;
        } else {
            if(key == firstKey) {
                n.previousKey = NULL;
                self.firstKey = keyAfter;  
            } else 
            if(key == lastKey) {
                p.nextKey = NULL;
                self.lastKey = keyBefore;
            } else {
                p.nextKey = keyAfter;
                n.previousKey = keyBefore;
            }
        }
        self.keySet.remove(key);
        delete self.keyStructs[key];
    }
}

interface IHOracle {
   function read() external view returns(uint TRXUsd6); 
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping (address => bool) members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if(!hasRole(role, account)) {
            revert(string(abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(uint160(account), 20),
                " is missing role ",
                Strings.toHexString(uint256(role), 32)
            )));
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}