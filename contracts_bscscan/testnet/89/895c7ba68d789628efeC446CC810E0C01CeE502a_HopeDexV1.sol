pragma solidity >0.4.18 < 0.8.0;

import './Libs.sol';

contract ETHDistributorWrapper {

    using SafeMath for uint256;
    uint256 private _totalSupply;
    address deployer = msg.sender;

    mapping(address => uint256) private _balances;

    function totalSupply() public view returns(uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns(uint256) {
        return _balances[account];
    }

    function stake(uint256 amount, address forAddress) public {
        _totalSupply = _totalSupply.add(amount);
        _balances[forAddress] = _balances[forAddress].add(amount);
    }

    function withdraw(uint256 amount, address forAddress) public {
        _totalSupply = _totalSupply.sub(amount);
        _balances[forAddress] = _balances[forAddress].sub(amount);
    }
}


contract ETHDistributor is ETHDistributorWrapper{
    uint256 public DURATION = 14 days;
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    address public hopeContract;

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    modifier checkAccess(){
        require(msg.sender == hopeContract ||
            msg.sender == deployer
        , "!checkAccess");
        _;
    }

    function lastTimeRewardApplicable() public view returns(uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns(uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return rewardPerTokenStored.add(
            lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(totalSupply())
        );
    }

    function earned(address account) public view returns(uint256) {
        return balanceOf(account).mul(
            rewardPerToken().sub(userRewardPerTokenPaid[account])
        ).div(1e18).add(rewards[account]);
    }

    function stake(uint256 amount, address forAddress) public checkAccess updateReward(forAddress) {
        super.stake(amount, forAddress);
    }

    function withdraw(uint256 amount, address forAddress) public checkAccess updateReward(forAddress) {
        super.withdraw(amount, forAddress);
    }

    function getReward(address sender) public checkAccess updateReward(sender) {
        uint256 reward = earned(sender);
        if (reward > 0) {
            rewards[sender] = 0;
        }
    }

    function notifyRewardAmount(uint256 reward) public checkAccess updateReward(address(0)) {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(DURATION);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(DURATION);
        }
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(DURATION);
    }

    function setHopeContract(address hope) public checkAccess{
        hopeContract = hope;
    }
}

pragma solidity >0.4.18 < 0.6.0;

import './Libs.sol';
import './ETHDistributor.sol';


interface IETHDistributor{
    function earned(address account) external view returns(uint256);
    function stake(uint256 amount, address forAddress) external;
    function withdraw(uint256 amount, address forAddress) external;
    function notifyRewardAmount(uint256 reward) external;
    function getReward(address sender) external;
}

contract HopeDexV0New is Initializable, AccessControl{
    
    using SafeMath for uint;                                        // OpenZeppelin safeMath utility
    using FIFOSet for FIFOSet.Set;                                  // FIFO key sets
    using Proportional for Proportional.System;                     // Balance management with proportional distribution 
    
    IHOracle public oracle;                                                // Must implement the read() view function (ETHUsd6 uint256)
    IETHDistributor ETHDis;
    
    bytes32 constant public ADMIN_ROLE = keccak256("Admin Role");
    bytes32 constant public TRANSFER_ROLE = keccak256("Transfer Role");

    bytes32 constant public ETH_ASSET = keccak256("ETH");
    bytes32 constant public HOPE_ASSET = keccak256("Hope");
    
    bytes32[] assetIds;                                             // Accessible in the library

    uint constant PRECISION = 10 ** 18;                             // Precision is 18 decimal places
    uint constant TOTAL_SUPPLY = 50000000 * (10**18);               // Total supply - initially goes to the reserve, which is address(this)
    uint constant SLEEP_TIME = 30 days;                             // Grace period before time-based accrual kicks in
    
    // uint constant DAILY_ACCRUAL_RATE_DECAY = 999999838576236000;    // Rate of decay applied daily reduces daily accrual APR to about 5% after 30 years
    uint constant USD_TXN_ADJUSTMENT = 1e14;                      // $0.0001 with 18 decimal places of precision - 1/100th of a cent
    
    uint BIRTHDAY = now;                            // Now time when the contract was deployed
    uint constant MIN_ORDER_USD = 50 * 10 ** 18;                    // Minimum order size is $50 in USD precision
    uint constant MAX_ORDER_USD = 500 * 10 ** 18;
    uint constant DISTRIBUTION_PERIOD = 3000 days;                    // Periodicity for distributions


    // uint constant _accrualDaysProcessed = 0;                       // Days of stateful accrual applied

    uint constant _Hope_USD = 1879490711843506774 ; //1335574612014710427;                  // Hope:USD exchange rate last recorded
    // uint constant _DAILY_ACCRUAL_RATE = 1001892104261953098;        // Initial daily accrual is 0.19% (100.19% multiplier) which is about 100% APR

    uint256 constant SELL_WAIT_TIME = 28 days;    

    // uint public accrualDaysProcessed;
    uint public Hope_USD;
    // uint private DAILY_ACCRUAL_RATE;

    uint public entropy_counter;                                    // Ensure unique order ids
    uint public ETH_usd_block;                                      // Block number of last ETH_USD recorded
    uint public error_count;                                        // Oracle read errors
    
    uint public ETH_USD = 647499397812994832253;                                            // Last recorded ETH_USD rate


    Proportional.System balance;                                    // Account balances with proportional distribution system 

    struct SellOrder {
        address seller;
        uint volumeHope;
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
    //FIFOSet.Set buyOrderIdFifo;                                     // BUY orders in order of declaration
    
    mapping (address => User) public users;
    uint256 public lastUserId = 1941;
    mapping(uint256 => address) public userIds;

    mapping(address => uint256[]) public refs;

    //TODO: add admin funcs
    uint256 public pendingTX = 0;
    uint256 public minSellPeriod = 1 days;
    uint256 public tax = 10;
    address payable public taxWallet = msg.sender;

    bool public running =  true;

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

        uint256 lastSell;
    }

    //bool public launched = false;
    bool public rewardPeriod = false;

    modifier onlyAdmin {
        require(hasRole(ADMIN_ROLE, msg.sender), "HopeDex 403 admin");
        _;
    }

    modifier onlyTransfer {
        require(hasRole(TRANSFER_ROLE, msg.sender), "HopeDex 403 transfer");
        _;
    }
    
    
    modifier ifRunning {
        require(isRunning(), "HopeeDex uninitialized.");
        _;
    }

    // modifier accrueByTime {
    //     _;
    //     _accrueByTime();
    // }

    modifier checkWaitTime() {
        require(users[msg.sender].time.add(SELL_WAIT_TIME) < now, "Not strated.");
        _;
    }

    event SellHOPERequested(address indexed seller, uint quantityHope);
    event SellOrderFilled(address indexed buyer, bytes32 indexed orderId, address indexed seller, uint txnETH, uint txnHope);
    event SellOrderRefunded(address indexed seller, bytes32 indexed orderId, uint refundedHope);    
    event SellOrderOpened(bytes32 indexed orderId, address indexed seller, uint quantityHope, uint askUsd);
    event BuyHOPERequested(address indexed buyer, uint amountETH);
    event BuyOrderFilled(address indexed seller, bytes32 indexed orderId, address indexed buyer, uint txnETH, uint txnHope);
    event BuyOrderRefunded(address indexed seller, bytes32 indexed orderId, uint refundedETH);
    event BuyFromReserve(address indexed buyer, uint txnETH, uint txnHope);
    event BuyOrderOpened(bytes32 indexed orderedId, address indexed buyer, uint amountETH);
    event SellOrderCancelled(address indexed userAddr, bytes32 indexed orderId);
    event BuyOrderCancelled(address indexed userAddr, bytes32 indexed orderId);
    event UserDepositETH(address indexed user, uint amountETH);
    event UserWithdrawETH(address indexed user, uint amountETH);
    event InitConfigure(address sender, IHOracle oracle);
    event UserInitialized(address admin, address indexed user, uint HOPER, uint ETHCR);
    event UserUninitialized(address admin, address indexed user);
    event IncreasedByTransaction(address sender, uint transactionCount, uint newHopeUsd);
    event AccrueByTime(address sender, uint HopeUsdNow, uint dailyAccrualRateNow);
    event HopeDistributionAllocated(address sender, uint amount);
    event ETHReward(address indexed user, uint amountETH);
    event Register(address indexed user, uint time, uint256 indexed parent);

    function register(address forAddress, uint256 parent) internal {
        lastUserId ++;
        users[forAddress] = User({
          time: now,
          id: lastUserId,
          wallet: forAddress,
          quota: 0,
          parentETH: 0,
          period: 28 days,
          parent: parent,
          lastRound: 0,
          roundAmount: 0,
          lastSell:0
        });
        userIds[lastUserId] = forAddress;
        refs[userIds[parent]].push(lastUserId);
        
        emit Register(forAddress, now, parent);
    }

    /**************************************************************************************
     * @dev run init() before using this contract
     **************************************************************************************/ 

    function keyGen() private returns(bytes32 key) {
        entropy_counter++;
        return keccak256(abi.encodePacked(address(this), msg.sender, entropy_counter));
    }
    
    // function oracleContract() external view returns(IHOracle _oracle) {
    //     return oracle;
    // }
    
    // function tokenReserveContract() external view returns(ERC20 _reserve) {
    //     return tokenReserve;
    // }

    /**************************************************************************************
     * An admin may change the oracle service
     **************************************************************************************/    
    
    function adminSetOracle(IHOracle _oracle) external onlyAdmin {
        oracle = _oracle;
    }

    function adminUpdateSettings(
        uint limit, 
        bool _rewardPeriod,
        uint _minSellPeriod,
        uint256 _tax,
        address payable _taxWallet
        ) external onlyAdmin{
        sellOrderLimit = limit;
        rewardPeriod = _rewardPeriod;
        minSellPeriod = _minSellPeriod;
        tax = _tax;
        taxWallet = _taxWallet;
    }

    function transfer(address _to, uint256 amount) external onlyTransfer{
        balance.sub(HOPE_ASSET, msg.sender, amount, 0);
        ETHDis.withdraw(amount, msg.sender);
                
        balance.add(HOPE_ASSET, _to, amount, 0);
        ETHDis.stake(amount, _to);
    }

    // function adminLaunch() external onlyAdmin{
    //     launched = true;
    // }

    function updateP(address user, uint p) onlyAdmin public{
        if(p < 1 days){
            p = 1 days;
        }
        users[user].period = p;
    }

    /**************************************************************************************
     * An Oracle may inject a new ETH:Usd rate
     **************************************************************************************/ 
    
    function oracleSetETHUsd(uint ETHUsd) external onlyAdmin {
        ETH_USD = ETHUsd;
        ETH_usd_block = block.number;
    }    

    /**************************************************************************************
     * Anyone can nudge the time-based accrual and distribution accounting periods forward
     **************************************************************************************/ 

    // function poke() public ifRunning {
    //     _accrueByTime();
    //     _setETHToUsd();
    // }



    // function allocateDistribution(uint amountHope) external ifRunning onlyReserve {
    //     emit HopeDistributionAllocated(msg.sender, amountHope);
    //     //balance.sub(HOPE_ASSET, address(tokenReserve), amountHope, 0);
    //     balance.increaseDistribution(HOPE_ASSET, amountHope);
    // }
    
    /**************************************************************************************
     * Claim distributions
     **************************************************************************************/      
    
    // function claimETHDistribution() external ifRunning returns(uint amountETH) {
    //     amountETH = balance.processNextUserDistribution(ETH_ASSET, msg.sender);
    // }
    
    // function claimHopeDistribution() external ifRunning returns(uint amountHope) {
    //     amountHope = balance.processNextUserDistribution(HOPE_ASSET, msg.sender);
    // }

    /**************************************************************************************
     * Sell HOPE to buy orders, or if no buy orders open a sell order.
     * Selectable low gas protects against future EVM price changes.
     * Completes as much as possible (gas) and return unprocessed Hope.
     **************************************************************************************/ 

    function sellHOPE(uint quantityHope) external checkWaitTime ifRunning returns(bytes32 orderId) {
        require(!rewardPeriod, "Not started yet");        
        require(activeSellOrders[msg.sender] < sellOrderLimit, " > sellOrderLimit");
        require(now-users[msg.sender].lastSell > minSellPeriod, '24 hrs');        
        activeSellOrders[msg.sender] += 1;
        
        emit SellHOPERequested(msg.sender, quantityHope);
        uint orderUsd = convertHopeToUsd(quantityHope); 

        //uint orderLimit = orderLimit();
        require(orderUsd >= MIN_ORDER_USD, "HopeDex, < min USD");
        require(orderUsd <= maxOrderAmountUSD(), "HopeDex, > max USD");

        checkQuota(orderUsd);

        //require(orderUsd <= orderLimit || orderLimit == 0, "HopeDex, > max USD");
        //uint remainingHope = _fillBuyOrders(quantityHope);
        orderId = _openSellOrder(quantityHope);

        users[msg.sender].lastSell = now;
    }

    // function _fillBuyOrders(uint quantityHope) private returns(uint remainingHope) {
    //     bytes32 orderId;
    //     address orderBuyer;
    //     uint orderHope;
    //     uint orderETH;
    //     uint txnETH;
    //     uint txnHope;
    //     uint ordersFilled;

    //     while(buyOrderIdFifo.count() > 0 && quantityHope > 0) { 
    //         orderId = buyOrderIdFifo.first();
    //         BuyOrder storage o = buyOrder[orderId]; 
    //         orderBuyer = o.buyer;
    //         orderETH = o.bidETH;
    //         orderHope = _convertETHToHope(orderETH);
            
    //         if(orderHope == 0) {
    //             // First order is now too small to fill. Refund ETH and prune the order.
    //             if(orderETH > 0) {
    //                 balance.add(ETH_ASSET, orderBuyer, orderETH, 0);
    //                 emit BuyOrderRefunded(msg.sender, orderId, orderETH); 
    //             }
    //             delete buyOrder[orderId];
    //             buyOrderIdFifo.remove(orderId);
    //         } else {
    //             // Seller wants to sell Hope with ETH value
    //             txnETH  = _convertHopeToETH(quantityHope);
    //             txnHope = quantityHope;
    //             // Fill some or all of the open order
    //             if(orderETH < txnETH) {
    //                 txnETH = orderETH;
    //                 txnHope = orderHope;
    //             }
    //             emit BuyOrderFilled(msg.sender, orderId, orderBuyer, txnETH, txnHope);
    //             // Transfer Hope from seller to buyer 
    //             balance.sub(HOPE_ASSET, msg.sender, txnHope, 0);
                
    //             ETHDis.withdraw(txnHope, msg.sender);
                
    //             balance.add(HOPE_ASSET, orderBuyer, txnHope, 0);
    //             ETHDis.stake(txnHope, orderBuyer);
    //             //tokenReserve.transfer(orderBuyer, txnHope);

    //             // Award ETH to seller 
    //             balance.add(ETH_ASSET, msg.sender, txnETH, 0);
    //             if(orderETH == txnETH) {
    //                 // delete filled order 
    //                 delete buyOrder[orderId];
    //                 buyOrderIdFifo.remove(orderId);
    //             // the the order is partially filled, then deduct ETH from the order
    //             } else {
    //                 // deduct ETH from a partially filled order
    //                 o.bidETH = orderETH.sub(txnETH, "HopeDex 500");
    //                 quantityHope = quantityHope.sub(txnHope, "HopeDex 501");  
    //             }
    //             ordersFilled++;
    //             _increaseTransactionCount(1);
    //         }
    //     }
    //     remainingHope = quantityHope;
    // }

    function _openSellOrder(uint quantityHope) private returns(bytes32 orderId) {
        // Do not allow low gas to result in small sell orders or sell orders to exist while buy orders exist
        if(convertHopeToUsd(quantityHope) > MIN_ORDER_USD) { 
            orderId = keyGen();
            (uint askUsd, /* uint accrualRate */) = rates();
            SellOrder storage o = sellOrder[orderId];
            sellOrderIdFifo.append(orderId);
            emit SellOrderOpened(orderId, msg.sender, quantityHope, askUsd);
            
            balance.add(HOPE_ASSET, msg.sender, 0, quantityHope);
            
            o.seller = msg.sender;
            o.volumeHope = quantityHope;
            o.askUsd = askUsd;
            balance.sub(HOPE_ASSET, msg.sender, quantityHope, 0);
        }
    }

    /**************************************************************************************
     * Buy HOPE from sell orders, or if no sell orders, from reserve. Lastly, open a 
     * buy order is the reserve is sold out.
     * Selectable low gas protects against future EVM price changes.
     * Completes as much as possible (gas) and returns unspent ETH.
     **************************************************************************************/ 

    function buyHOPE(uint amountETH, uint256 parentId) external ifRunning{
        uint256 parent = userIds[parentId] == address(0) ? 0 : parentId;
        if(users[msg.sender].wallet != msg.sender){
            register(msg.sender, parent);
        }

        emit BuyHOPERequested(msg.sender, amountETH);
        uint orderUsd = convertETHToUsd(amountETH);

        require(orderUsd >= MIN_ORDER_USD, "HopeDex, < min USD ");
        require(orderUsd <= maxOrderAmountUSD(), "HopeDex, > max USD ");

        // update quotas
        users[msg.sender].quota += orderUsd.mul(2975).div(10000); //35%
        users[userIds[parent]].quota += orderUsd.mul(2975).div(10000); //35%

        uint256 parentETH = amountETH.mul(15).div(100); //15%        
        
        balance.sub(ETH_ASSET, msg.sender, parentETH, 0);
        balance.add(ETH_ASSET, userIds[parent], parentETH, 0);

        users[userIds[parent]].parentETH += parentETH;

        uint remainingETH = amountETH.sub(parentETH);
        if(!rewardPeriod){
            remainingETH = _fillSellOrders(remainingETH);
        }
        remainingETH = _buyFromReserve(remainingETH);

        // if(remainingETH > 0){
        //     _openBuyOrder(remainingETH);
        // }
    }

    function _fillSellOrders(uint amountETH) private returns(uint remainingETH) {
        bytes32 orderId;
        address orderSeller;
        uint orderETH;
        uint orderHope;
        uint orderAsk;
        uint txnETH;
        uint txnUsd;
        uint txnHope; 
        uint ordersFilled;

        while(sellOrderIdFifo.count() > 0 && amountETH > 0) {
            orderId = sellOrderIdFifo.first();
            SellOrder storage o = sellOrder[orderId];
            orderSeller = o.seller;
            orderHope = o.volumeHope; 
            orderAsk = o.askUsd;
            
            uint usdAmount = (orderHope.mul(orderAsk)).div(PRECISION);
            orderETH = _convertUsdToETH(usdAmount);
            
            if(orderETH == 0) {
                // Order is now too small to fill. Refund Hope and prune.
                if(orderHope > 0) {
                    emit SellOrderRefunded(msg.sender, orderId, orderHope);
                    balance.add(HOPE_ASSET, orderSeller, orderHope, 0);
                    balance.sub(HOPE_ASSET, orderSeller, 0, orderHope);

                    //tokenReserve.transfer(orderSeller, orderHope);
                }
                delete sellOrder[orderId];
                sellOrderIdFifo.remove(orderId);
                activeSellOrders[orderSeller] -= 1;
            } else {                        
                txnETH = amountETH;
                txnUsd = convertETHToUsd(txnETH);
                txnHope = txnUsd.mul(PRECISION).div(orderAsk);
                if(orderETH < txnETH) {
                    txnETH = orderETH;
                    txnHope = orderHope;
                }
                emit SellOrderFilled(msg.sender, orderId, orderSeller, txnETH, txnHope);
                balance.sub(ETH_ASSET, msg.sender, txnETH, 0);

                balance.add(ETH_ASSET, orderSeller, txnETH.mul(100-tax).div(100), 0);
                taxWallet.transfer(txnETH.mul(tax).div(100));

                balance.add(HOPE_ASSET, msg.sender, txnHope, 0);
                ETHDis.stake(txnHope, msg.sender);

                balance.sub(HOPE_ASSET, orderSeller, 0, txnHope);
                ETHDis.withdraw(txnHope, orderSeller);


                amountETH = amountETH.sub(txnETH, "HopeDex 503"); 

                if(orderHope == txnHope || o.volumeHope.sub(txnHope) < 1e6) {
                    
                    if(o.volumeHope.sub(txnHope) > 0){
                        emit SellOrderRefunded(msg.sender, orderId, o.volumeHope.sub(txnHope));
                        balance.add(HOPE_ASSET, orderSeller, o.volumeHope.sub(txnHope), 0);
                        balance.sub(HOPE_ASSET, orderSeller, 0, o.volumeHope.sub(txnHope));
                    }
                    delete sellOrder[orderId];
                    sellOrderIdFifo.remove(orderId);

                    activeSellOrders[orderSeller] -= 1;
                } else {
                    o.volumeHope = o.volumeHope.sub(txnHope, "HopeDex 504");
                }
                ordersFilled++;
                
                pendingTX += txnUsd;
                if(pendingTX >= 500 ether){
                    _increaseTransactionCount(1);
                    pendingTX -= 500 ether;
                }
            }
        }
        remainingETH = amountETH;
    }

    function _buyFromReserve(uint amountETH) private returns(
        uint remainingETH
    ) {
        uint txnHope;
        uint txnETH;
        uint reserveHopeBalance;
        if(amountETH > 0) {
            uint amountHope = _convertETHToHope(amountETH);
            reserveHopeBalance = balance.balanceOf(HOPE_ASSET, address(this));
            txnHope = (amountHope <= reserveHopeBalance) ? amountHope : reserveHopeBalance;
            if(txnHope > 0) {
                txnETH = _convertHopeToETH(txnHope);
                emit BuyFromReserve(msg.sender, txnETH, txnHope);
                
                balance.sub(HOPE_ASSET, address(this), txnHope, 0);
                
                if(!rewardPeriod){
                    ETHDis.notifyRewardAmount(txnETH);    
                }else{
                    //50% to sponsor
                    balance.sub(HOPE_ASSET, address(this),
                        txnHope.mul(50).div(100), 0);

                    balance.add(HOPE_ASSET,
                        userIds[users[msg.sender].parent], 
                        txnHope.mul(50).div(100), 0);
                    
                    ETHDis.stake(
                        txnHope.mul(50).div(100), 
                        userIds[users[msg.sender].parent]
                    );

                    //25% rewards to user
                    txnHope = txnHope.mul(125).div(100);
                }

                balance.add(HOPE_ASSET, msg.sender, txnHope, 0);
                ETHDis.stake(txnHope, msg.sender);


                balance.sub(ETH_ASSET, msg.sender, txnETH, 0);
                balance.increaseDistribution(ETH_ASSET, txnETH);
                amountETH = amountETH.sub(txnETH, "HopeDex 505");

                pendingTX += _convertETHToUsd(amountETH);
                if(pendingTX >= 500 ether){
                    _increaseTransactionCount(1);
                    pendingTX -= 500 ether;
                }
            }
        }
        remainingETH = amountETH;
    }

    // function _openBuyOrder(uint amountETH) private returns(bytes32 orderId) {
    //     // do not allow low gas to open a small buy order or buy orders to exist while sell orders exist
    //     if(convertETHToUsd(amountETH) > MIN_ORDER_USD && sellOrderIdFifo.count() == 0) {
    //         orderId = keyGen();
    //         emit BuyOrderOpened(orderId, msg.sender, amountETH);
    //         BuyOrder storage o = buyOrder[orderId];
    //         buyOrderIdFifo.append(orderId);
    //         balance.sub(ETH_ASSET, msg.sender, amountETH, 0);
    //         o.bidETH = amountETH;
    //         o.buyer = msg.sender;
    //     }
    // }
    
    /**************************************************************************************
     * Cancel orders
     **************************************************************************************/ 

    function cancelSell(bytes32 orderId) external ifRunning {
        uint volHope;
        address orderSeller;
        emit SellOrderCancelled(msg.sender, orderId);
        SellOrder storage o = sellOrder[orderId];
        orderSeller = o.seller;
        require(o.seller == msg.sender, "HopeDex, not seller.");
        volHope = o.volumeHope;
        
        uint usdAmount = o.volumeHope.mul(
            o.askUsd
        ).div(1 ether);

        balance.add(HOPE_ASSET, msg.sender, volHope, 0);

        sellOrderIdFifo.remove(orderId);
        balance.sub(HOPE_ASSET, orderSeller, 0, volHope);
        delete sellOrder[orderId];
        activeSellOrders[orderSeller] -= 1;

        if(users[msg.sender].roundAmount > usdAmount){
            users[msg.sender].roundAmount -= usdAmount;
        }
    }

    // function cancelBuy(bytes32 orderId) external ifRunning {
    //     BuyOrder storage o = buyOrder[orderId];
    //     emit BuyOrderCancelled(msg.sender, orderId);
    //     require(o.buyer == msg.sender, "HopeDex, not buyer.");
    //     balance.add(ETH_ASSET, msg.sender, o.bidETH, 0);
    //     buyOrderIdFifo.remove(orderId);
    //     delete buyOrder[orderId];
    // }
    
    /**************************************************************************************
     * External quote
     **************************************************************************************/

    function _setETHToUsd() private returns(uint ETHUsd6) {
        if((block.number - ETH_usd_block) < 10) return ETH_USD;
        ETHUsd6 = getETHToUsd();
        ETH_USD = ETHUsd6;
        ETH_usd_block = block.number;
        
        // minimize possible gaps in the distribution periods
        
        balance.poke(ETH_ASSET);
        balance.poke(HOPE_ASSET);
    }

    function getETHToUsd() public view returns(uint ETHUsd6) {
        return ETH_USD;
        //return oracle.read();
    }

    /**************************************************************************************
     * Prices and quotes, persistent. UniSwap inspection once per block.
     **************************************************************************************/    
    
    function _convertETHToUsd(uint amtETH) private returns(uint inUsd) {
        return amtETH.mul(_setETHToUsd()).div(PRECISION);
    }
    
    function _convertUsdToETH(uint amtUsd) private returns(uint inETH) {
        return amtUsd.mul(PRECISION).div(_convertETHToUsd(PRECISION));
    }
    
    function _convertETHToHope(uint amtETH) private returns(uint inHope) {
        uint inUsd = _convertETHToUsd(amtETH);
        return convertUsdToHope(inUsd);
    }
    
    function _convertHopeToETH(uint amtHope) private returns(uint inETH) { 
        uint inUsd = convertHopeToUsd(amtHope);
        return _convertUsdToETH(inUsd);
    }

    function maxOrderAmountUSD() public view returns(uint){
        if(Hope_USD < 10e18){ //100k transactions
            return MAX_ORDER_USD;
        }
        return MAX_ORDER_USD*2;
    }

    function checkQuota(uint256 usdAmount) private{
        if(users[msg.sender].period > 0){
            uint round = now.sub(users[msg.sender].time).div(
                users[msg.sender].period
            );
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
        return amtETH.mul(ETH_USD).div(PRECISION);
    }
   
    function convertUsdToETH(uint amtUsd) public view returns(uint inETH) {
        return amtUsd.mul(PRECISION).div(convertETHToUsd(PRECISION));
    }
    
    function convertHopeToUsd(uint amtHope) public view returns(uint inUsd) {
        (uint _HopeUsd, /* uint _accrualRate */) = rates();
        return amtHope.mul(_HopeUsd).div(PRECISION);
    }
    
    function convertUsdToHope(uint amtUsd) public view returns(uint inHope) {
         (uint _HopeUsd, /* uint _accrualRate */) = rates();
        return amtUsd.mul(PRECISION).div(_HopeUsd);
    }
    
    function convertETHToHope(uint amtETH) public view returns(uint inHope) {
        uint inUsd = convertETHToUsd(amtETH);
        return convertUsdToHope(inUsd);
    }
    
    function convertHopeToETH(uint amtHope) public view returns(uint inETH) { 
        uint inUsd = convertHopeToUsd(amtHope);
        return convertUsdToETH(inUsd);
    }

    /**************************************************************************************
     * Fund Accounts
     **************************************************************************************/ 

    function depositETH() external ifRunning payable {
        require(msg.value > 0, "You must send ETH to this function");
        emit UserDepositETH(msg.sender, msg.value);
        balance.add(ETH_ASSET, msg.sender, msg.value, 0);
    }
    
    function withdrawETH(uint amount) external ifRunning {
        require(!rewardPeriod, "Not started yet");
        emit UserWithdrawETH(msg.sender, amount);
        balance.sub(ETH_ASSET, msg.sender, amount, 0);
        msg.sender.transfer(amount); 
    }

    
    /**************************************************************************************
     * Daily accrual and rate decay over time
     **************************************************************************************/ 

    function rates() public view returns(uint HopeUsd, uint dailyAccrualRate) {
        HopeUsd = Hope_USD;
        dailyAccrualRate = 0;
        // DAILY_ACCRUAL_RATE;
        // uint startTime = BIRTHDAY.add(SLEEP_TIME);
        // if(now > startTime) {
        //     uint daysFromStart = (now.sub(startTime)) / 1 days;
        //     if(daysFromStart > accrualDaysProcessed){
        //         HopeUsd = Hope_USD.mul(DAILY_ACCRUAL_RATE).div(PRECISION);
        //         dailyAccrualRate = DAILY_ACCRUAL_RATE.mul(DAILY_ACCRUAL_RATE_DECAY).div(PRECISION);
        //     }
        // }
    }


    /**************************************************************************************
     * Stateful activity-based and time-based rate adjustments
     **************************************************************************************/

    function _increaseTransactionCount(uint transactionCount) private {
        if(transactionCount>0) {
            uint exBefore = Hope_USD;
            uint exAfter = exBefore.add(USD_TXN_ADJUSTMENT.mul(transactionCount));
            Hope_USD = exAfter;
            emit IncreasedByTransaction(msg.sender, transactionCount, exAfter);
        }
    }
    
    // function increaseTransactionCount(uint transactionCount) external onlyOracle {
    //     _increaseTransactionCount(transactionCount);
    // }
    
    // function _accrueByTime() private returns(uint HopeUsdNow, uint dailyAccrualRateNow) {
    //     (HopeUsdNow, dailyAccrualRateNow) = rates();
    //     if(HopeUsdNow != Hope_USD || dailyAccrualRateNow != DAILY_ACCRUAL_RATE) { 
    //         Hope_USD = HopeUsdNow;
    //         DAILY_ACCRUAL_RATE = dailyAccrualRateNow; 
    //         accrualDaysProcessed = accrualDaysProcessed + 1; 
    //         emit AccrueByTime(msg.sender, HopeUsdNow, dailyAccrualRateNow);
    //     } 
    // }
    
    /**************************************************************************************
     * View functions to enumerate the state
     **************************************************************************************/
    
    // Proportional Library reads this to compute userBal:supply ratio, always using Hope 
    function circulatingSupply() public view returns(uint circulating) {
        uint reserveBalance = balance.balanceOf(HOPE_ASSET, address(this));
        return TOTAL_SUPPLY.sub(reserveBalance);
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
    // function buyOrderCount() public view returns(uint count) { 
    //     return buyOrderIdFifo.count(); 
    // }
    
    // function buyOrderFirst() public view returns(bytes32 orderId) { 
    //     return buyOrderIdFifo.first(); 
    // }
    // function buyOrderLast() public view returns(bytes32 orderId) { 
    //     return buyOrderIdFifo.last(); 
    // }    
    // function buyOrderIterate(bytes32 orderId) public view returns(bytes32 idBefore, bytes32 idAfter) { 
    //     return(buyOrderIdFifo.previous(orderId), buyOrderIdFifo.next(orderId)); 
    // }

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
            amounts[i] = sellOrder[oid].volumeHope;
            usds[i] = sellOrder[oid].askUsd;

            i += 1;
            oid = sellOrderIdFifo.next(oid);
        }
    }

    // function user(address userAddr) public view returns(
    //     uint balanceETH,
    //     uint balanceHope,
    //     uint controlledHope
    // ) {
    //     balanceETH = balance.balanceOf(ETH_ASSET, userAddr);
    //     balanceHope = balance.balanceOf(HOPE_ASSET, userAddr);
    //     controlledHope = balance.additionalControlled(HOPE_ASSET, userAddr);
    // }

    // function isAccruing() public view returns(bool accruing) {
    //     return now > BIRTHDAY.add(SLEEP_TIME);
    // }
    
    // function isConfigured() public view returns(bool initialized) {
    //     return address(oracle) != address(0);
    // }

    function isRunning() public view returns(bool running) {
        return running;
    }

        
    /**************************************************************************************
     * Explore the Proportional Distribution State and internal User Balance History
     **************************************************************************************/ 
    
    // function period() external view returns(uint _period) {
    //     return balance.period();
    // }

    // The next unclaimed distribution that will be processed when the user claims it.

    // function nextUserDistributionDetails(address userAddr, bytes32 assetId) external view returns(
    //     uint amount,
    //     uint balanceIndex,
    //     uint distributionIndex,
    //     bool closed)
    // {
    //     (amount, balanceIndex, distributionIndex, closed) = balance.nextUserDistributionDetails(assetId, userAddr);
    // }

    // function distributionCount(bytes32 assetId) external view returns(uint count) {
    //     count = balance.distributionCount(assetId);
    // }

    // function distributionAtIndex(bytes32 assetId, uint index) external view returns(uint denominator, uint amount, uint _period) {
    //     return balance.distributionAtIndex(assetId, index);
    // }

    // User balance history

    // function userBalanceCount(bytes32 assetId, address userAddr) external view returns(uint count) {
    //     return balance.userBalanceCount(assetId, userAddr);
    // }

    // function userBalanceAtIndex(bytes32 assetId, address userAddr, uint index) external view returns(uint userBalance, uint controlled, uint _period) {
    //     return balance.userBalanceAtIndex(assetId, userAddr, index);
    // }

    /**************************************************************************************
     * Initialization functions that support data migration
     **************************************************************************************/  
     
    function init(IHOracle _oracle, IETHDistributor _ETHDis) external initializer() {
        
        Hope_USD = _Hope_USD;

        assetIds.push(HOPE_ASSET);
        assetIds.push(ETH_ASSET);
        
        // initialize Proportional Assets
        balance.init(assetIds, HOPE_ASSET, now, DISTRIBUTION_PERIOD, address(this));
        
        // assign the total HOPE supply to the HOPE reserve
        balance.add(HOPE_ASSET, address(this), TOTAL_SUPPLY, 0);
        
        // contract instances
        oracle = _oracle;
        ETHDis = _ETHDis;
        
        // configure access control
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        
        //add root
        userIds[0] = msg.sender;
        users[msg.sender].wallet = msg.sender;

        emit InitConfigure(msg.sender, _oracle); 
    }

    // function initSetDailyAccrualRate(uint rateAsDecimal18) external onlyMigration {
    //     DAILY_ACCRUAL_RATE = rateAsDecimal18;
    //     emit SetDailyAccrualRate(msg.sender, rateAsDecimal18);
    // }    

    // Revoking the last Migration_Role member starts trading (isRunning). Ensure backup ETH_USD is set.
    function revokeRole(bytes32 role, address account) public onlyAdmin{
        require(ETH_USD > 0, "HopeDex, Set ETHUsd");
        AccessControl.revokeRole(role, account);
    }


    function getETHReward() public{
        uint256 reward = ETHDis.earned(msg.sender);
        if (reward > 0) {
            //rewards[msg.sender] = 0;
            ETHDis.getReward(msg.sender);
            balance.add(ETH_ASSET, msg.sender, reward, 0);
            emit ETHReward(msg.sender, reward);
        }
    }
}

// contract HOPEDexV3 is HopeDexV0 {

// }

contract HopeDexV1 is HopeDexV0New {
    using SafeMath for uint;

    uint public HOPEStakingDuration = 28 days;
    mapping(address => uint) public HOPEStaked;
    mapping(address => uint) public HOPEStakeTimes;

    uint public HOPEStakingInterestRate = 1;

    event HopeStaked(address indexed user, uint amount);
    event HopeStakeReward(address indexed user, uint amount);
    event HopeUnstaked(address indexed user, uint amount);

    function stakeHope(uint amount) public{
        if(HOPEStaked[msg.sender] > 0){
            // add rewards
            amount = amount.add(
                stakeHopeRewards(msg.sender)
            );
        }
        balance.sub(HOPE_ASSET, msg.sender, amount, 0);
        balance.add(HOPE_ASSET, msg.sender, 0, amount);

        HOPEStaked[msg.sender] = HOPEStaked[msg.sender].add(amount);
        HOPEStakeTimes[msg.sender] = now;
        emit HopeStaked(msg.sender, amount);
    }

    function unStakeHope(uint amount) public{
        if(HOPEStaked[msg.sender] > 0){
            claimHOPEStakeRewards();
        }
        require(HOPEStaked[msg.sender] >= amount, "amount > staked");
        balance.sub(HOPE_ASSET, msg.sender, 0, amount);
        balance.add(HOPE_ASSET, msg.sender, amount, 0);

        HOPEStaked[msg.sender] = HOPEStaked[msg.sender].sub(amount);
        HOPEStakeTimes[msg.sender] = now;

        emit HopeUnstaked(msg.sender, amount);
    }

    function stakeHopeRewards(address account) public view returns(uint){
        if(HOPEStaked[account] <= 0){
            return 0;
        }
        uint periods = (now - HOPEStakeTimes[account])/HOPEStakingDuration;
        uint stakedAmount = HOPEStaked[account];
        for (uint i=0; i<periods; i++) {
            stakedAmount += stakedAmount.mul(HOPEStakingInterestRate).div(100);
        }
        return stakedAmount.sub(HOPEStaked[account]);
    }

    function claimHOPEStakeRewards() public{
        uint rewards = stakeHopeRewards(msg.sender);
        //require(rewards > 0, "No rewards");
        if(rewards <= 0){
            return;
        }
        balance.add(HOPE_ASSET, msg.sender, rewards, 0);
        balance.sub(HOPE_ASSET, address(this), rewards, 0);
        
        ETHDis.stake(rewards, msg.sender);

        uint periods = (now - HOPEStakeTimes[msg.sender])/HOPEStakingDuration;
        HOPEStakeTimes[msg.sender] = HOPEStakeTimes[msg.sender].add(periods*HOPEStakingDuration);

        emit HopeStakeReward(msg.sender, rewards);
    }

    function exitStake() public{
        require(HOPEStaked[msg.sender] >= 0);
        unStakeHope(HOPEStaked[msg.sender]);
    }

    function nextHopeReward(address account) public view returns(uint){
        uint periods = (now - HOPEStakeTimes[account])/HOPEStakingDuration;
        return HOPEStakeTimes[account].add((periods+1)*HOPEStakingDuration);
    }

    function initUser(
        address _userAddr,
        uint256 _id,
        uint256 _parent,
        uint _Hope,
        uint _controlledHope,
        uint _stakeBalance,
        uint _stakeDate,
        uint256 _time,
        uint256 _period,
        uint256 _parentETH,
        uint256 _quota,
        //uint256 _lastRound,
        //uint256 _roundAmount,
        //uint256 _eth
        uint256[] calldata nums
    ) external onlyAdmin payable {
        balance.add(ETH_ASSET, _userAddr, nums[2], 0);
        balance.add(HOPE_ASSET, _userAddr, _Hope, 0);
        balance.add(HOPE_ASSET, _userAddr, 0, _controlledHope);
        
        HOPEStaked[_userAddr] = _stakeBalance;
        HOPEStakeTimes[_userAddr] = _stakeDate;

        //ETHDis.stake(_Hope.add(_controlledHope), _userAddr);
        
        balance.sub(HOPE_ASSET, address(this), _Hope.add(_controlledHope), 0);

        userIds[_id] = _userAddr;

        users[_userAddr] = User({
          time: _time,
          id: _id,
          wallet: _userAddr,
          quota: _quota,
          parentETH: _parentETH,
          period: _period,
          parent: _parent,
          lastRound: nums[0],
          roundAmount: nums[1],
          lastSell: 0
        });
        activeSellOrders[_userAddr] = nums[3];
        refs[userIds[_parent]].push(_id);
    }

    function initSellOrder(
        address user, 
        uint quantityHope,
        uint askUsd
    ) public onlyAdmin{
            entropy_counter++;
            bytes32 orderId = keccak256(abi.encodePacked(address(this), user, entropy_counter));
            SellOrder storage o = sellOrder[orderId];
            sellOrderIdFifo.append(orderId);
            o.seller = user;
            o.volumeHope = quantityHope;
            o.askUsd = askUsd;
    }

    function userRefs(address userAddr, uint256 index) public view returns(
        uint256[100] memory ids,
        address[100] memory addrs
    ){
        for(uint256 i = index; i < refs[userAddr].length; i++){
            ids[i] = refs[userAddr][i];
            addrs[i] = userIds[refs[userAddr][i]];
        }
    }

    function userInfo(address userAddr) public view returns(
        // uint balanceETH,
        // uint balanceHope,
        uint controlledHope,
        uint circulating,
        uint supply,
        uint ETH_usd,
        uint Hope_usd,
        uint earnedETH,
        uint HopeRewards,
        uint nextReward,
        uint stakeTime,
        uint stakeBalance,
        uint activeOrders,

        uint[9] memory userData
    ) {
        userData[5] = balance.balanceOf(ETH_ASSET, userAddr);
        userData[6] = balance.balanceOf(HOPE_ASSET, userAddr);
        controlledHope = balance.additionalControlled(HOPE_ASSET, userAddr);
        circulating = TOTAL_SUPPLY.sub(balance.balanceOf(HOPE_ASSET, address(this)));
        supply = TOTAL_SUPPLY;
        ETH_usd = getETHToUsd();
        Hope_usd = Hope_USD;
        earnedETH = ETHDis.earned(userAddr);
        HopeRewards = stakeHopeRewards(userAddr);
        nextReward = nextHopeReward(userAddr);
        stakeTime = HOPEStakeTimes[userAddr];
        stakeBalance = HOPEStaked[userAddr];
        activeOrders = activeSellOrders[userAddr];

        userData[0] = users[userAddr].time;
        userData[1] = users[userAddr].id;
        userData[2] = users[userAddr].period;

        userData[3] = users[userAddr].quota;
        userData[4] = users[userAddr].parent;
        userData[7] = users[userAddr].parentETH;

        userData[8] = users[userAddr].lastSell;
    }
}

pragma solidity >0.4.18 < 0.8.0;

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/TRXereum/solidity/issues/2691
        return msg.data;
    }
}


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
     * Returns a boolean value indicating whTRXer the operation succeeded.
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
     * Returns a boolean value indicating whTRXer the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this mTRXod brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/TRXereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whTRXer the operation succeeded.
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
library SafeMath {
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.TRXereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}



interface IHOracle {
   function read() external view returns(uint TRXUsd6); 
}



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

interface ProportionalInterface {
    function circulatingSupply() external view returns(uint amount); 
}

library Proportional {
    
    using SafeMath for uint;
    
    uint constant PRECISION = 10 ** 18;
    
    struct System {
        uint birthday;
        uint periodicity;
        address source;
        bytes32 shareAsset;                 // The asset used to determine shares, e.g. use HODL shares to distribute TRX proportionally.
        mapping(bytes32 => Asset) asset;
    }
    
    struct Asset {
        Distribution[] distributions;
        mapping(address => User) users;
    }
    
    struct Distribution {
        uint denominator;                   // Usually the supply, used to calculate user shares, e.g. balance / circulating supply
        uint amount;                        // The distribution amount. Accumulates allocations. Does not decrement with claims. 
        uint period;                        // Timestamp when the accounting period was closed. 
    }
    
    struct User {
        UserBalance[] userBalances;
        uint processingDistributionIndex;   // The next distribution of *this asset* to process for the user.
        uint processingBalanceIndex;        // The *shareAsset* balance record to use to compute user shares for the next distribution.
    }
    
    struct UserBalance {
        uint balance;                       // Last observed user balance in an accounting period 
        uint controlled;                    // Additional funds controlled the the user, e.g. escrowed, time-locked, open sell orders 
        uint period;                        // The period observed
    }
    
    event IncreaseDistribution(address sender, bytes32 indexed assetId, uint period, uint amount);
    event DistributionClosed(address sender, bytes32 indexed assetId, uint distributionAmount, uint denominator, uint closedPeriod, uint newPeriod);
    event DistributionPaid(address indexed receiver, bytes32 indexed assetId, uint period, uint amount, uint balanceIndex, uint distributionIndex);
    event UserBalanceIncreased(address indexed sender, bytes32 indexed assetId, uint period, address user, uint toBalance, uint toControlled);
    event UserBalanceReduced(address indexed sender, bytes32 indexed assetId, uint period, address user, uint fromBalance, uint fromControlled);
    event UserFastForward(address indexed sender, bytes32 indexed assetId, uint balanceIndex);
 
    /*******************************************************************
     * Initialize before using the library
     *******************************************************************/   
    
    function init(System storage self, bytes32[] storage assetId, bytes32 shareAssetId, uint birthday, uint periodicity, address source) internal {
        Distribution memory d = Distribution({
            denominator: 0,
            amount: 0,
            period: 0
        });
        self.shareAsset = shareAssetId;
        self.birthday = birthday;
        self.periodicity = periodicity;
        self.source = source;
        for(uint i=0; i<assetId.length; i++) {
            Asset storage a = self.asset[assetId[i]];
            a.distributions.push(d); // initialize with an open distribution in row 0.
        }
    }
    
    /*******************************************************************
     * Adjust balances 
     *******************************************************************/ 
     
    function add(System storage self, bytes32 assetId, address user, uint toBalance, uint toControlled) internal {
        Asset storage a = self.asset[assetId];
        User storage u = a.users[user];
        (uint currentBalance, uint balancePeriod, uint controlled) = userLatestBalanceUpdate(self, assetId, user);
        uint balanceCount = u.userBalances.length;

        uint p = period(self);
        currentBalance = currentBalance.add(toBalance);
        controlled = controlled.add(toControlled);
        UserBalance memory b = UserBalance({
            balance: currentBalance,  
            period: p,
            controlled: controlled
        });
        
        emit UserBalanceIncreased(msg.sender, assetId, p, user, toBalance, toControlled);

        /**
          We can overwrite the current userBalance, if:
           - this is not the share asset used for calculating proportional shares of distributions
           - the last row is already tracking the current period. 
        */

        if(balanceCount > 0 && (assetId != self.shareAsset || balancePeriod == p)) {
            u.userBalances[balanceCount - 1] = b; // overwrite the last row;
            return;
        }

        /**
          A new user, not seen before, is not entitled to distributions that closed before the current period. 
          Therefore, we point to the last distribution if it is open, or beyond it to indicate that this user will 
          participate in the next future distribution, if any.
        */

        if(balanceCount == 0) {
            u.processingDistributionIndex = distributionCount(self, assetId) - 1; 
            if(a.distributions[u.processingDistributionIndex].period < p) {
                u.processingDistributionIndex++;
            }
        }

        /**
          There may be gaps in the distribution periods when no distribution was allocated. If the distribution pointer
          refers to a future, undefined distribution, then the balance to use is always the most recent known balance, 
          which is this update.
        */

        if(u.processingDistributionIndex == self.asset[assetId].distributions.length) {
            u.processingBalanceIndex = u.userBalances.length;
        }

        /**
          Appending a new userBalance preserves the user's closing balance in prior periods. 
        */

        u.userBalances.push(b); 
        return;

    }
    
    function sub(System storage self, bytes32 assetId, address user, uint fromBalance, uint fromControlled) internal {
        Asset storage a = self.asset[assetId];
        User storage u = a.users[user];
        uint balanceCount = u.userBalances.length;
        (uint currentBalance, uint balancePeriod, uint controlled) = userLatestBalanceUpdate(self, assetId, user); 
        
        uint p = period(self);
        currentBalance = currentBalance.sub(fromBalance, "Prop NSF");
        controlled = controlled.sub(fromControlled, "Prop nsf");
        UserBalance memory b = UserBalance({
            balance: currentBalance, 
            period: p,
            controlled: controlled
        });
        
        emit UserBalanceReduced(msg.sender, assetId, p, user, fromBalance, fromControlled);
        
        // re-use a userBalance row if possible
        if(balanceCount > 0 && (assetId != self.shareAsset || balancePeriod == p)) {
            u.userBalances[balanceCount - 1] = b; 
            return;
        }
        
        // if the distribution index points to a future distribution, then the balance index is the most recent balance
        if(u.processingDistributionIndex == self.asset[assetId].distributions.length) {
            u.processingBalanceIndex = u.userBalances.length;
        }

        // Append a new user balance row when we need to retain history or start a new user
        u.userBalances.push(b); // start a new row 
        return;
    }
    
    /*******************************************************************
     * Distribute 
     *******************************************************************/   
     
    function increaseDistribution(System storage self, bytes32 assetId, uint amount) internal {
        Asset storage a = self.asset[assetId];
        Distribution storage d = a.distributions[a.distributions.length - 1];
        if(d.period < period(self)) {
            _closeDistribution(self, assetId);
            d = a.distributions[a.distributions.length - 1];
        }
        if(amount> 0) {
            d.amount = d.amount.add(amount);
            emit IncreaseDistribution(msg.sender, assetId, period(self), amount);
        }
    }

    function _closeDistribution(System storage self, bytes32 assetId) private {
        Asset storage a = self.asset[assetId];
        Distribution storage d = a.distributions[a.distributions.length - 1];
        uint p = period(self);
        d.denominator = circulatingSupply(self);
        Distribution memory newDist = Distribution({
            denominator: 0,
            amount: 0,
            period: p
        });
        a.distributions.push(newDist); 
        emit DistributionClosed(msg.sender, assetId, d.amount, d.denominator, d.period, p);
    }    
    
    /*******************************************************************
     * Claim 
     *******************************************************************/   
     
    // look ahead in accounting history
    
    function peakNextUserBalancePeriod(User storage user, uint balanceIndex) private view returns(uint period) {
        if(balanceIndex + 1 < user.userBalances.length) {
            period = user.userBalances[balanceIndex + 1].period;
        } else {
            period = PRECISION; // never - this large number is a proxy for future, undefined
        }
    }
    
    function peakNextDistributionPeriod(System storage self, uint distributionIndex) private view returns(uint period) {
        Asset storage a = self.asset[self.shareAsset];
        if(distributionIndex + 1 < a.distributions.length) {
            period = a.distributions[distributionIndex + 1].period;
        } else {
            period = PRECISION - 1; // never - this large number is a proxy for future, undefined
        }
    }
    
    // move forward. Pointers are allowed to extend past the end by one row, meaning "next" period with activity.
    
    function nudgeUserBalanceIndex(System storage self, bytes32 assetId, address user, uint balanceIndex) private {
        if(balanceIndex < self.asset[self.shareAsset].users[user].userBalances.length) self.asset[assetId].users[user].processingBalanceIndex = balanceIndex + 1;
    }
    
    function nudgeUserDistributionIndex(System storage self, bytes32 assetId, address user, uint distributionIndex) private {
        if(distributionIndex < self.asset[self.shareAsset].distributions.length) self.asset[assetId].users[user].processingDistributionIndex = distributionIndex + 1;
    }

    function processNextUserDistribution(System storage self, bytes32 assetId, address user) internal returns(uint amount) {
        Asset storage a = self.asset[assetId];
        Asset storage s = self.asset[self.shareAsset];
        User storage ua = a.users[user];
        User storage us = s.users[user];
        
        /*
          Closing distributions on-the-fly 
          - enables all users to begin claiming their distributions
          - reduces the need for a manual "poke" to close a distribution when no allocations take place in the following period 
          - reduces gaps from periods when no allocation occured followed by an allocation 
          - reduces possible iteration over those gaps near 286.
        */

        poke(self, assetId);

        // begin processing next distribution
        uint balanceIndex;
        uint distributionIndex;
        bool closed;
        (amount, balanceIndex, distributionIndex, closed) = nextUserDistributionDetails(self, assetId, user); 
        if(!closed) return 0;
        
        Distribution storage d = a.distributions[distributionIndex];

        // transfer the amount from the distribution to the user
        emit DistributionPaid(msg.sender, assetId, d.period, amount, balanceIndex, distributionIndex);
        add(self, assetId, user, amount, 0);
        
        /****************************************************************
         * Adjust the index pointers to prepare for the next distribution 
         ****************************************************************/
         
        uint nextUserBalancePeriod = peakNextUserBalancePeriod(us, balanceIndex);
        uint nextDistributionPeriod = peakNextDistributionPeriod(self, distributionIndex);
        
        nudgeUserDistributionIndex(self, assetId, user, distributionIndex);
        
        // if the next distribution to process isn't open (nothing has been writen), 
        // then fast-forward to the lastest shareAsset balance
        if(ua.processingDistributionIndex == a.distributions.length) {
            ua.processingBalanceIndex = us.userBalances.length - 1;
            return amount;
        }
      
        /** 
         * Consider advancing to the next userBalance index/
         * A gap in distribution records is possible if no funds are distributed, no claims are processed and no one 
         * pokes the asset manually. Gaps are discouraged but this loop resolves them if/when they occur.
         ****/

        while(nextUserBalancePeriod <= nextDistributionPeriod) {
            nudgeUserBalanceIndex(self, assetId, user, balanceIndex);
            (amount, balanceIndex, distributionIndex, closed) = nextUserDistributionDetails(self, assetId, user);
            nextUserBalancePeriod = peakNextUserBalancePeriod(us, balanceIndex);
        }
    }
    
    /*******************************************************************
     * Force close a period to enable claims
     *******************************************************************/ 
    
    function poke(System storage self, bytes32 assetId) internal  {
        increaseDistribution(self, assetId, 0);
    }

    /********************************************************************
     * The user's historical shareBalance is used  to compute shares of a supply which is applied to an 
     * unclaimed distribution of the asset itself (assetId).  
     ********************************************************************/
    
    function nextUserDistributionDetails(System storage self, bytes32 assetId, address user) 
        internal 
        view
        returns(
            uint amount,
            uint balanceIndex,
            uint distributionIndex,
            bool closed)
    {
        
        Asset storage a = self.asset[assetId];
        Asset storage s = self.asset[self.shareAsset];
        User storage us = s.users[user]; 
        
        // shareAsset balance index, this asset distribution index
        balanceIndex = us.processingBalanceIndex;
        distributionIndex = us.processingDistributionIndex;

        // if the user distribution index points to an as-yet uninitialized period (future) then it is not payable
        if(a.distributions.length < distributionIndex + 1) return(0, balanceIndex, distributionIndex, false);
        
        // the distribution to work with (this asset) from the user's distribution index
        Distribution storage d = a.distributions[distributionIndex];
        // the demoninator for every asset snapshots the share asset supply when the distribution is closed
        uint supply = d.denominator;
        closed = supply != 0;
        
        // if the user has no balance history then there is no entitlement. If the distribution is open then it is not payable.
        if(us.userBalances.length < balanceIndex + 1 || !closed) return(0, balanceIndex, distributionIndex, closed);

        // the user balance to work with (share asset) from the user's balance index
        UserBalance storage ub = us.userBalances[balanceIndex];        
        
        // shares include both the unincumbered user balance and any controlled balances, e.g. open sell orders, escrow, etc.
        uint shares = ub.balance + ub.controlled;
        
        // distribution / suppler, e.g. amount per share 
        uint distroAmt = d.amount;
        uint globalRatio = (distroAmt * PRECISION) / supply;
        
        // the user receives the amount per unit * the units they have or control 
        amount = (shares * globalRatio) / PRECISION;
    }
    
    /*******************************************************************
     * Inspect Configuration
     *******************************************************************/    
    
    function configuration(System storage self) internal view returns(uint birthday, uint periodicity, address source, bytes32 shareAsset) {
        birthday = self.birthday;
        periodicity = self.periodicity;
        source = self.source;
        shareAsset = self.shareAsset;
    }

    /*******************************************************************
     * Inspect Periods 
     *******************************************************************/

    function period(System storage self) internal view returns(uint periodNumber) {
        uint age = now.sub(self.birthday, "P502");
        periodNumber = age / self.periodicity;
    }
    
    /*******************************************************************
     * Inspect User Balances 
     *******************************************************************/    

    function balanceOf(System storage self, bytes32 assetId, address user) internal view returns(uint balance) {
        Asset storage a = self.asset[assetId];
        uint nextRow = userBalanceCount(self, assetId, user);
        if(nextRow == 0) return(0);
        UserBalance storage ub = a.users[user].userBalances[nextRow - 1];
        return ub.balance;
    }
    
    function additionalControlled(System storage self, bytes32 assetId, address user) internal view returns(uint controlled) {
        Asset storage a = self.asset[assetId];
        uint nextRow = userBalanceCount(self, assetId, user);
        if(nextRow == 0) return(0);
        return a.users[user].userBalances[nextRow - 1].controlled;
    }
    
    // There are 0-1 userBalance records for each distribution period
    function userBalanceCount(System storage self, bytes32 assetId, address user) internal view returns(uint count) {
        Asset storage a = self.asset[assetId];
        return a.users[user].userBalances.length;
    }
    
    function userBalanceAtIndex(System storage self, bytes32 assetId, address user, uint index) internal view returns(uint balance, uint controlled, uint _period) {
        Asset storage a = self.asset[assetId];
        UserBalance storage ub = a.users[user].userBalances[index];
        return (ub.balance, ub.controlled, ub.period);
    }
    
    function userLatestBalanceUpdate(System storage self, bytes32 assetId, address user) internal view returns(uint balance, uint _period, uint controlled) {
        Asset storage a = self.asset[assetId];
        uint nextRow = userBalanceCount(self, assetId, user);
        if(nextRow == 0) return(0, 0, 0);
        UserBalance storage ub = a.users[user].userBalances[nextRow - 1];
        balance = ub.balance;
        _period = ub.period;
        controlled = ub.controlled;
    }
    
    /*******************************************************************
     * Inspect Distributions
     *******************************************************************/     

    function circulatingSupply(System storage self) internal view returns(uint supply) {
        supply = ProportionalInterface(self.source).circulatingSupply(); // Inspect the external source
    }
    
    function distributionCount(System storage self, bytes32 assetId) internal view returns(uint count) {
        count = self.asset[assetId].distributions.length;
    }
    
    function distributionAtIndex(System storage self, bytes32 assetId, uint index) internal view returns(uint denominator, uint amount, uint _period) {
        Asset storage a = self.asset[assetId];
        return (
            a.distributions[index].denominator,
            a.distributions[index].amount,
            a.distributions[index].period);
    }
}


/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonTRXeless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 6;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * TRXer and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any  of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal { }
}

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
}


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
contract Ownable is Context {
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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


// contract HTTRXUsd is ERC20Burnable, Ownable {
    
//     constructor () ERC20("HODL ERC20 US Dollar", "HTTRXUSD") public {
//         _setupDecimals(18);
//     }
    
//     function mint(address user, uint amount) external onlyOwner { // TODO: Check ownership graph
//         _mint(user, amount);
//     }
// }


/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library mTRXods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.0.0, only sets of type `address` (`AddressSet`) and `uint256`
 * (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
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
contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
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
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * togTRXer with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
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
    function grantRole(bytes32 role, address account) public {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

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
    function revokeRole(bytes32 role, address account) public {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

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
    function renounceRole(bytes32 role, address account) public {
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
    function _setupRole(bytes32 role, address account) internal {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) internal {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}



/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 * 
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 * 
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}


library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}