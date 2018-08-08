pragma solidity ^0.4.18;

// @author - <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="f6809f80939d9c9f9481b6919b979f9ad895999b">[email&#160;protected]</a>
// Website: http://CryptoStockMarket.co
// Only CEO can change CEO and CFO address

contract CompanyAccessControl {
    
    address public ceoAddress;
    address public cfoAddress;

    bool public paused = false;

    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }

    modifier onlyCLevel() {
        require(
            msg.sender == ceoAddress ||
            msg.sender == cfoAddress
        );
        _;
    }

    function setCEO(address _newCEO) 
    onlyCEO 
    external {
        require(_newCEO != address(0));
        ceoAddress = _newCEO;
    }

    function setCFO(address _newCFO) 
    onlyCEO 
    external {
        require(_newCFO != address(0));
        cfoAddress = _newCFO;
    }

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused {
        require(paused);
        _;
    }

    function pause() 
    onlyCLevel
    external 
    whenNotPaused {
        paused = true;
    }

    function unpause() 
    onlyCLevel 
    whenPaused 
    external {
        paused = false;
    }
}

// Keeps a mapping of onwerAddress to the number of shares owned
contract BookKeeping {
    
    struct ShareHolders {
        mapping(address => uint) ownerAddressToShares;
        uint numberOfShareHolders;
    }
    
    // _amount should be greator than 0
    function _sharesBought(ShareHolders storage _shareHolders, address _owner, uint _amount) 
    internal {
        // If user didn&#39;t have shares earlier, he is now a share holder!
        if (_shareHolders.ownerAddressToShares[_owner] == 0) {
            _shareHolders.numberOfShareHolders += 1;
        }
        _shareHolders.ownerAddressToShares[_owner] += _amount;
        
    }

    // _amount should be greator or equal to what user already have, otherwise will result in underflow
    function _sharesSold(ShareHolders storage _shareHolders, address _owner, uint _amount) 
    internal {
        _shareHolders.ownerAddressToShares[_owner] -= _amount;
        
        // if user sold all his tokens, then there is one less share holder
        if (_shareHolders.ownerAddressToShares[_owner] == 0) {
            _shareHolders.numberOfShareHolders -= 1;
        }
    }
}


contract CompanyConstants {
    // Days after which trading volume competiton result will be annouced
    uint constant TRADING_COMPETITION_PERIOD = 5 days;
    
    // Max Percentage of shares that can be released per cycle
    uint constant MAX_PERCENTAGE_SHARE_RELEASE = 5;
    
    uint constant MAX_CLAIM_SHARES_PERCENTAGE = 5;
    
    // Release cycle! Every company needs to wait for "at least" 10 days
    // before releasing next set of shares!
    uint constant MIN_COOLDOWN_TIME = 10; // in days
    uint constant MAX_COOLDOWN_TIME = 255;
    
    // A company can start with min 100 tokens or max 10K tokens
    // and min(10%, 500) new tokens will be released every x days where
    // x >= 10;
    uint constant INIT_MAX_SHARES_IN_CIRCULATION = 10000;
    uint constant INIT_MIN_SHARES_IN_CIRCULATION = 100;
    uint constant MAX_SHARES_RELEASE_IN_ONE_CYCLE = 500;
    
    // Company will take a cut of 10% from the share sales!
    uint constant SALES_CUT = 10;
    
    // Company will take a cut of 2% when an order is claimed.
    uint constant ORDER_CUT = 2;
    
    // Type of orders
    enum OrderType {Buy, Sell}
    
    // A new company is listed!
    event Listed(uint companyId, string companyName, uint sharesInCirculation, uint pricePerShare,
    uint percentageSharesToRelease, uint nextSharesReleaseTime, address owner);
    
    // Tokens are claimed!
    event Claimed(uint companyId, uint numberOfShares, address owner);
    
    // Tokens are transfered
    event Transfer(uint companyId, address from, address to, uint numberOfShares);
    
    // There is a new CEO of the company
    event CEOChanged(uint companyId, address previousCEO, address newCEO);
    
    // Shares are relased for the company
    event SharesReleased(uint companyId, address ceo, uint numberOfShares, uint nextSharesReleaseTime);
    
    // A new order is placed
    event OrderPlaced(uint companyId, uint orderIndex, uint amount, uint pricePerShare, OrderType orderType, address owner);
    
    // An order is claimed!
    event OrderFilled(uint companyId, uint orderIndex, uint amount, address buyer);
    
    // A placed order is cancelled!
    event OrderCancelled(uint companyId, uint orderIndex);
    
    event TradingWinnerAnnounced(uint companyId, address winner, uint sharesAwarded);
}

contract CompanyBase is BookKeeping, CompanyConstants {

    struct Company {
        // Company names are stored as hashes to save gas cost during execution
        bytes32 companyNameHash;

        // Percentage of shares to release
        // will be less than maxPercentageSharesRelease
        uint32 percentageSharesToRelease;

        // The time of the release cycle in days. If it is set to 10
        // then it means shares can only be released every 10 days 
        // Min values is 10
        uint32 coolDownTime;
        
        // Total number of shares that are in circulation right now!
        uint32 sharesInCirculation; 

        // Total number of shares that are still with the company and can be claimed by paying the price
        uint32 unclaimedShares; 
        
        // Address of the person who owns more tha 50% shares of the company.
        address ceoOfCompany; 

        // Address of person who registered this company and will receive money from the share sales.
        address ownedBy; 
        
        // The exact time in future before which shares can&#39;t be released!
        // if shares are just released then nextSharesReleaseTime will be (now + coolDownTime);
        uint nextSharesReleaseTime; 

        // Price of one share as set by the company
        uint pricePerShare; 

        // Share holders of the company
        ShareHolders shareHolders;
    }

    Company[] companies;
    
    function getCompanyDetails(uint _companyId) 
    view
    external 
    returns (
        bytes32 companyNameHash,
        uint percentageSharesToRelease,
        uint coolDownTime,
        uint nextSharesReleaseTime,
        uint sharesInCirculation,
        uint unclaimedShares,
        uint pricePerShare,
        uint sharesRequiredToBeCEO,
        address ceoOfCompany,     
        address owner,
        uint numberOfShareHolders) {

        Company storage company = companies[_companyId];

        companyNameHash = company.companyNameHash;
        percentageSharesToRelease = company.percentageSharesToRelease;
        coolDownTime = company.coolDownTime;
        nextSharesReleaseTime = company.nextSharesReleaseTime;
        sharesInCirculation = company.sharesInCirculation;
        unclaimedShares = company.unclaimedShares;
        pricePerShare = company.pricePerShare; 
        sharesRequiredToBeCEO = (sharesInCirculation/2) + 1;
        ceoOfCompany = company.ceoOfCompany;
        owner = company.ownedBy;
        numberOfShareHolders = company.shareHolders.numberOfShareHolders;
    }

    function getNumberOfShareHolders(uint _companyId) 
    view
    external
    returns (uint) {
        return companies[_companyId].shareHolders.numberOfShareHolders;
    }

    function getNumberOfSharesForAddress(uint _companyId, address _user) 
    view
    external 
    returns(uint) {
        return companies[_companyId].shareHolders.ownerAddressToShares[_user];
    }
    
    function getTotalNumberOfRegisteredCompanies()
    view
    external
    returns (uint) {
        return companies.length;
    }
}

contract TradingVolume is CompanyConstants {
    
    struct Traders {
        uint relaseTime;
        address winningTrader;
        mapping (address => uint) sharesTraded;
    }
    
    mapping (uint => Traders) companyIdToTraders;
    
    // unique _companyId
    function _addNewCompanyTraders(uint _companyId) 
    internal {
        Traders memory traders = Traders({
            winningTrader : 0x0,
            relaseTime : now + TRADING_COMPETITION_PERIOD 
        });
        
        companyIdToTraders[_companyId] = traders;
    }
    
    // _from!=_to , _amount > 0
    function _updateTradingVolume(Traders storage _traders, address _from, address _to, uint _amount) 
    internal {
        _traders.sharesTraded[_from] += _amount;
        _traders.sharesTraded[_to] += _amount;
        
        if (_traders.sharesTraded[_from] > _traders.sharesTraded[_traders.winningTrader]) {
            _traders.winningTrader = _from;
        } 
        
        if (_traders.sharesTraded[_to] > _traders.sharesTraded[_traders.winningTrader]) {
            _traders.winningTrader = _to;
        } 
    }
    
    // Get reference of winningTrader before clearing
    function _clearWinner(Traders storage _traders) 
    internal {
        delete _traders.sharesTraded[_traders.winningTrader];
        delete _traders.winningTrader;
        _traders.relaseTime = now + TRADING_COMPETITION_PERIOD;
    }
}

contract ApprovalContract is CompanyAccessControl {
    // Approver who are approved to launch a company a particular name
    // the bytes32 hash is the hash of the company name!
    mapping(bytes32 => address) public approvedToLaunch;
    
    // Make sure that we don&#39;t add two companies with same name
    mapping(bytes32 => bool) public registredCompanyNames;
    
    // Approve addresses to launch a company with the given name
    // Only ceo or cfo can approve a company;
    // the owner who launched the company would receive 90% from the sales of
    // shares and 10% will be kept by the contract!
    function addApprover(address _owner, string _companyName) 
    onlyCLevel
    whenNotPaused
    external {
        approvedToLaunch[keccak256(_companyName)] = _owner;
    }
}

contract CompanyMain is CompanyBase, ApprovalContract, TradingVolume {
    uint public withdrawableBalance;
    
    // The cut contract takes from the share sales of an approved company.
    // price is in wei
    function _computeSalesCut(uint _price) 
    pure
    internal 
    returns (uint) {
        return (_price * SALES_CUT)/100;
    }
    
    // Whenever there is transfer of tokens from _from to _to, CEO of company might get changed!
    function _updateCEOIfRequired(Company storage _company, uint _companyId, address _to) 
    internal {
        uint sharesRequiredToBecomeCEO = (_company.sharesInCirculation/2 ) + 1;
        address currentCEO = _company.ceoOfCompany;
        
        if (_company.shareHolders.ownerAddressToShares[currentCEO] >= sharesRequiredToBecomeCEO) {
            return;
        } 
        
        if (_to != address(this) && _company.shareHolders.ownerAddressToShares[_to] >= sharesRequiredToBecomeCEO) {
            _company.ceoOfCompany = _to;
            emit CEOChanged(_companyId, currentCEO, _to);
            return;
        }
        
        if (currentCEO == 0x0) {
            return;
        }
        _company.ceoOfCompany = 0x0;
        emit CEOChanged(_companyId, currentCEO, 0x0);
    }
    

    /// Transfer tokens from _from to _to and verify if CEO of company has changed!
    // _from should have enough tokens before calling this functions!
    // _numberOfTokens should be greator than 0
    function _transfer(uint _companyId, address _from, address _to, uint _numberOfTokens) 
    internal {
        Company storage company = companies[_companyId];
        
        _sharesSold(company.shareHolders, _from, _numberOfTokens);
        _sharesBought(company.shareHolders, _to, _numberOfTokens);

        _updateCEOIfRequired(company, _companyId, _to);
        
        emit Transfer(_companyId, _from, _to, _numberOfTokens);
    }
    
    function transferPromotionalShares(uint _companyId, address _to, uint _amount)
    onlyCLevel
    whenNotPaused
    external
    {
        Company storage company = companies[_companyId];
        // implies a promotional company
        require(company.pricePerShare == 0);
        require(companies[_companyId].shareHolders.ownerAddressToShares[msg.sender] >= _amount);
        _transfer(_companyId, msg.sender, _to, _amount);
    }
    
    function addPromotionalCompany(string _companyName, uint _precentageSharesToRelease, uint _coolDownTime, uint _sharesInCirculation)
    onlyCLevel
    whenNotPaused 
    external
    {
        bytes32 companyNameHash = keccak256(_companyName);
        
        // There shouldn&#39;t be a company that is already registered with same name!
        require(registredCompanyNames[companyNameHash] == false);
        
        // Max 10% shares can be released in one release cycle, to control liquidation
        // and uncontrolled issuing of new tokens. Furthermore the max shares that can
        // be released in one cycle can only be upto 500.
        require(_precentageSharesToRelease <= MAX_PERCENTAGE_SHARE_RELEASE);
        
        // The min release cycle should be at least 10 days
        require(_coolDownTime >= MIN_COOLDOWN_TIME && _coolDownTime <= MAX_COOLDOWN_TIME);

        uint _companyId = companies.length;
        uint _nextSharesReleaseTime = now + _coolDownTime * 1 days;
        
        Company memory company = Company({
            companyNameHash: companyNameHash,
            
            percentageSharesToRelease : uint32(_precentageSharesToRelease),
            coolDownTime : uint32(_coolDownTime),
            
            sharesInCirculation : uint32(_sharesInCirculation),
            nextSharesReleaseTime : _nextSharesReleaseTime,
            unclaimedShares : 0,
            
            pricePerShare : 0,
            
            ceoOfCompany : 0x0,
            ownedBy : msg.sender,
            shareHolders : ShareHolders({numberOfShareHolders : 0})
            });

        companies.push(company);
        _addNewCompanyTraders(_companyId);
        // Register company name
        registredCompanyNames[companyNameHash] = true;
        _sharesBought(companies[_companyId].shareHolders, msg.sender, _sharesInCirculation);
        emit Listed(_companyId, _companyName, _sharesInCirculation, 0, _precentageSharesToRelease, _nextSharesReleaseTime, msg.sender);
    }

    // Add a new company with the given name  
    function addNewCompany(string _companyName, uint _precentageSharesToRelease, uint _coolDownTime, uint _sharesInCirculation, uint _pricePerShare) 
    external 
    whenNotPaused 
    {
        bytes32 companyNameHash = keccak256(_companyName);
        
        // There shouldn&#39;t be a company that is already registered with same name!
        require(registredCompanyNames[companyNameHash] == false);
        
        // Owner have the permissions to launch the company
        require(approvedToLaunch[companyNameHash] == msg.sender);
        
        // Max 10% shares can be released in one release cycle, to control liquidation
        // and uncontrolled issuing of new tokens. Furthermore the max shares that can
        // be released in one cycle can only be upto 500.
        require(_precentageSharesToRelease <= MAX_PERCENTAGE_SHARE_RELEASE);
        
        // The min release cycle should be at least 10 days
        require(_coolDownTime >= MIN_COOLDOWN_TIME && _coolDownTime <= MAX_COOLDOWN_TIME);
        
        require(_sharesInCirculation >= INIT_MIN_SHARES_IN_CIRCULATION &&
        _sharesInCirculation <= INIT_MAX_SHARES_IN_CIRCULATION);

        uint _companyId = companies.length;
        uint _nextSharesReleaseTime = now + _coolDownTime * 1 days;

        Company memory company = Company({
            companyNameHash: companyNameHash,
            
            percentageSharesToRelease : uint32(_precentageSharesToRelease),
            nextSharesReleaseTime : _nextSharesReleaseTime,
            coolDownTime : uint32(_coolDownTime),
            
            sharesInCirculation : uint32(_sharesInCirculation),
            unclaimedShares : uint32(_sharesInCirculation),
            
            pricePerShare : _pricePerShare,
            
            ceoOfCompany : 0x0,
            ownedBy : msg.sender,
            shareHolders : ShareHolders({numberOfShareHolders : 0})
            });

        companies.push(company);
        _addNewCompanyTraders(_companyId);
        // Register company name
        registredCompanyNames[companyNameHash] = true;
        emit Listed(_companyId, _companyName, _sharesInCirculation, _pricePerShare, _precentageSharesToRelease, _nextSharesReleaseTime, msg.sender);
    }
    
    // People can claim shares from the company! 
    // The share price is fixed. However, once bought the users can place buy/sell
    // orders of any amount!
    function claimShares(uint _companyId, uint _numberOfShares) 
    whenNotPaused
    external 
    payable {
        Company storage company = companies[_companyId];
        
        require (_numberOfShares > 0 &&
            _numberOfShares <= (company.sharesInCirculation * MAX_CLAIM_SHARES_PERCENTAGE)/100);

        require(company.unclaimedShares >= _numberOfShares);
        
        uint totalPrice = company.pricePerShare * _numberOfShares;
        require(msg.value >= totalPrice);

        company.unclaimedShares -= uint32(_numberOfShares);

        _sharesBought(company.shareHolders, msg.sender, _numberOfShares);
        _updateCEOIfRequired(company, _companyId, msg.sender);

        if (totalPrice > 0) {
            uint salesCut = _computeSalesCut(totalPrice);
            withdrawableBalance += salesCut;
            uint sellerProceeds = totalPrice - salesCut;

            company.ownedBy.transfer(sellerProceeds);
        } 

        emit Claimed(_companyId, _numberOfShares, msg.sender);
    }
    
    // Company&#39;s next shares can be released only by the CEO of the company! 
    // So there should exist a CEO first
    function releaseNextShares(uint _companyId) 
    external 
    whenNotPaused {

        Company storage company = companies[_companyId];
        
        require(company.ceoOfCompany == msg.sender);
        
        // If there are unclaimedShares with the company, then new shares can&#39;t be relased!
        require(company.unclaimedShares == 0 );
        
        require(now >= company.nextSharesReleaseTime);

        company.nextSharesReleaseTime = now + company.coolDownTime * 1 days;
        
        // In worst case, we will be relasing max 500 tokens every 10 days! 
        // If we will start with max(10K) tokens, then on average we will be adding
        // 18000 tokens every year! In 100 years, it will be 1.8 millions. Multiplying it
        // by 10 makes it 18 millions. There is no way we can overflow the multiplication here!
        uint sharesToRelease = (company.sharesInCirculation * company.percentageSharesToRelease)/100;
        
        // Max 500 tokens can be relased
        if (sharesToRelease > MAX_SHARES_RELEASE_IN_ONE_CYCLE) {
            sharesToRelease = MAX_SHARES_RELEASE_IN_ONE_CYCLE;
        }
        
        if (sharesToRelease > 0) {
            company.sharesInCirculation += uint32(sharesToRelease);
            _sharesBought(company.shareHolders, company.ceoOfCompany, sharesToRelease);
            emit SharesReleased(_companyId, company.ceoOfCompany, sharesToRelease, company.nextSharesReleaseTime);
        }
    }
    
    function _updateTradingVolume(uint _companyId, address _from, address _to, uint _amount) 
    internal {
        Traders storage traders = companyIdToTraders[_companyId];
        _updateTradingVolume(traders, _from, _to, _amount);
        
        if (now < traders.relaseTime) {
            return;
        }
        
        Company storage company = companies[_companyId];
        uint _newShares = company.sharesInCirculation/100;
        if (_newShares > MAX_SHARES_RELEASE_IN_ONE_CYCLE) {
            _newShares = 100;
        }
        company.sharesInCirculation += uint32(_newShares);
         _sharesBought(company.shareHolders, traders.winningTrader, _newShares);
        _updateCEOIfRequired(company, _companyId, traders.winningTrader);
        emit TradingWinnerAnnounced(_companyId, traders.winningTrader, _newShares);
        _clearWinner(traders);
    }
}

contract MarketBase is CompanyMain {
    
    function MarketBase() public {
        ceoAddress = msg.sender;
        cfoAddress = msg.sender;
    }
    
    struct Order {
        // Owner who placed the order
        address owner;
                
        // Total number of tokens in order
        uint32 amount;
        
        // Amount of tokens that are already bought/sold by other people
        uint32 amountFilled;
        
        // Type of the order
        OrderType orderType;
        
        // Price of one share
        uint pricePerShare;
    }
    
    // A mapping of companyId to orders
    mapping (uint => Order[]) companyIdToOrders;
    
    // _amount > 0
    function _createOrder(uint _companyId, uint _amount, uint _pricePerShare, OrderType _orderType) 
    internal {
        Order memory order = Order({
            owner : msg.sender,
            pricePerShare : _pricePerShare,
            amount : uint32(_amount),
            amountFilled : 0,
            orderType : _orderType
        });
        
        uint index = companyIdToOrders[_companyId].push(order) - 1;
        emit OrderPlaced(_companyId, index, order.amount, order.pricePerShare, order.orderType, msg.sender);
    }
    
    // Place a sell request if seller have enough tokens!
    function placeSellRequest(uint _companyId, uint _amount, uint _pricePerShare) 
    whenNotPaused
    external {
        require (_amount > 0);
        require (_pricePerShare > 0);

        // Seller should have enough tokens to place a sell order!
        _verifyOwnershipOfTokens(_companyId, msg.sender, _amount);

        _transfer(_companyId, msg.sender, this, _amount);
        _createOrder(_companyId, _amount, _pricePerShare, OrderType.Sell);
    }
    
    // Place a request to buy shares of a particular company!
    function placeBuyRequest(uint _companyId, uint _amount, uint _pricePerShare) 
    external 
    payable 
    whenNotPaused {
        require(_amount > 0);
        require(_pricePerShare > 0);
        require(_amount == uint(uint32(_amount)));
        
        // Should have enough eth!
        require(msg.value >= _amount * _pricePerShare);

        _createOrder(_companyId, _amount, _pricePerShare, OrderType.Buy);
    }
    
    // Cancel a placed order!
    function cancelRequest(uint _companyId, uint _orderIndex) 
    external {        
        Order storage order = companyIdToOrders[_companyId][_orderIndex];
        
        require(order.owner == msg.sender);
        
        uint sharesRemaining = _getRemainingSharesInOrder(order);
        
        require(sharesRemaining > 0);

        order.amountFilled += uint32(sharesRemaining);
        
        if (order.orderType == OrderType.Buy) {

             // If its a buy order, transfer the ether back to owner;
            uint price = _getTotalPrice(order, sharesRemaining);
            
            // Sends money back to owner!
            msg.sender.transfer(price);
        } else {
            
            // Send the tokens back to the owner
            _transfer(_companyId, this, msg.sender, sharesRemaining);
        }

        emit OrderCancelled(_companyId, _orderIndex);
    }
    
    // Fill the sell order!
    function fillSellOrder(uint _companyId, uint _orderIndex, uint _amount) 
    whenNotPaused
    external 
    payable {
        require(_amount > 0);
        
        Order storage order = companyIdToOrders[_companyId][_orderIndex];
        require(order.orderType == OrderType.Sell);
        
        require(msg.sender != order.owner);
       
        _verifyRemainingSharesInOrder(order, _amount);

        uint price = _getTotalPrice(order, _amount);
        require(msg.value >= price);

        order.amountFilled += uint32(_amount);
        
        // transfer tokens to the buyer
        _transfer(_companyId, this, msg.sender, _amount);
        
        // send money to seller after taking a small share
        _transferOrderMoney(price, order.owner);  
        
        _updateTradingVolume(_companyId, msg.sender, order.owner, _amount);
        
        emit OrderFilled(_companyId, _orderIndex, _amount, msg.sender);
    }
    
    // Fill the sell order!
    function fillSellOrderPartially(uint _companyId, uint _orderIndex, uint _maxAmount) 
    whenNotPaused
    external 
    payable {
        require(_maxAmount > 0);
        
        Order storage order = companyIdToOrders[_companyId][_orderIndex];
        require(order.orderType == OrderType.Sell);
        
        require(msg.sender != order.owner);
       
        uint buyableShares = _getRemainingSharesInOrder(order);
        require(buyableShares > 0);
        
        if (buyableShares > _maxAmount) {
            buyableShares = _maxAmount;
        }

        uint price = _getTotalPrice(order, buyableShares);
        require(msg.value >= price);

        order.amountFilled += uint32(buyableShares);
        
        // transfer tokens to the buyer
        _transfer(_companyId, this, msg.sender, buyableShares);
        
        // send money to seller after taking a small share
        _transferOrderMoney(price, order.owner); 
        
        _updateTradingVolume(_companyId, msg.sender, order.owner, buyableShares);
        
        uint buyerProceeds = msg.value - price;
        msg.sender.transfer(buyerProceeds);
        
        emit OrderFilled(_companyId, _orderIndex, buyableShares, msg.sender);
    }

    // Fill the buy order!
    function fillBuyOrder(uint _companyId, uint _orderIndex, uint _amount) 
    whenNotPaused
    external {
        require(_amount > 0);
        
        Order storage order = companyIdToOrders[_companyId][_orderIndex];
        require(order.orderType == OrderType.Buy);
        
        require(msg.sender != order.owner);
        
        // There should exist enought shares to fulfill the request!
        _verifyRemainingSharesInOrder(order, _amount);
        
        // The seller have enought tokens to fulfill the request!
        _verifyOwnershipOfTokens(_companyId, msg.sender, _amount);
        
        order.amountFilled += uint32(_amount);
        
        // transfer the tokens from the seller to the buyer!
        _transfer(_companyId, msg.sender, order.owner, _amount);
        
        uint price = _getTotalPrice(order, _amount);
        
        // transfer the money from this contract to the seller
        _transferOrderMoney(price , msg.sender);
        
        _updateTradingVolume(_companyId, msg.sender, order.owner, _amount);

        emit OrderFilled(_companyId, _orderIndex, _amount, msg.sender);
    }
    
    // Fill buy order partially if possible!
    function fillBuyOrderPartially(uint _companyId, uint _orderIndex, uint _maxAmount) 
    whenNotPaused
    external {
        require(_maxAmount > 0);
        
        Order storage order = companyIdToOrders[_companyId][_orderIndex];
        require(order.orderType == OrderType.Buy);
        
        require(msg.sender != order.owner);
        
        // There should exist enought shares to fulfill the request!
        uint buyableShares = _getRemainingSharesInOrder(order);
        require(buyableShares > 0);
        
        if ( buyableShares > _maxAmount) {
            buyableShares = _maxAmount;
        }
        
        // The seller have enought tokens to fulfill the request!
        _verifyOwnershipOfTokens(_companyId, msg.sender, buyableShares);
        
        order.amountFilled += uint32(buyableShares);
        
        // transfer the tokens from the seller to the buyer!
        _transfer(_companyId, msg.sender, order.owner, buyableShares);
        
        uint price = _getTotalPrice(order, buyableShares);
        
        // transfer the money from this contract to the seller
        _transferOrderMoney(price , msg.sender);
        
        _updateTradingVolume(_companyId, msg.sender, order.owner, buyableShares);

        emit OrderFilled(_companyId, _orderIndex, buyableShares, msg.sender);
    }

    // transfer money to the owner!
    function _transferOrderMoney(uint _price, address _owner) 
    internal {
        uint priceCut = (_price * ORDER_CUT)/100;
        _owner.transfer(_price - priceCut);
        withdrawableBalance += priceCut;
    }

    // Returns the price for _amount tokens for the given order
    // _amount > 0
    // order should be verified
    function _getTotalPrice(Order storage _order, uint _amount) 
    view
    internal 
    returns (uint) {
        return _amount * _order.pricePerShare;
    }
    
    // Gets the number of remaining shares that can be bought or sold under this order
    function _getRemainingSharesInOrder(Order storage _order) 
    view
    internal 
    returns (uint) {
        return _order.amount - _order.amountFilled;
    }

    // Verifies if the order have _amount shares to buy/sell
    // _amount > 0
    function _verifyRemainingSharesInOrder(Order storage _order, uint _amount) 
    view
    internal {
        require(_getRemainingSharesInOrder(_order) >= _amount);
    }

    // Checks if the owner have at least &#39;_amount&#39; shares of the company
    // _amount > 0
    function _verifyOwnershipOfTokens(uint _companyId, address _owner, uint _amount) 
    view
    internal {
        require(companies[_companyId].shareHolders.ownerAddressToShares[_owner] >= _amount);
    }
    
    // Returns the length of array! All orders might not be active
    function getNumberOfOrders(uint _companyId) 
    view
    external 
    returns (uint numberOfOrders) {
        numberOfOrders = companyIdToOrders[_companyId].length;
    }

    function getOrderDetails(uint _comanyId, uint _orderIndex) 
    view
    external 
    returns (address _owner,
        uint _pricePerShare,
        uint _amount,
        uint _amountFilled,
        OrderType _orderType) {
            Order storage order =  companyIdToOrders[_comanyId][_orderIndex];
            
            _owner = order.owner;
            _pricePerShare = order.pricePerShare;
            _amount = order.amount;
            _amountFilled = order.amountFilled;
            _orderType = order.orderType;
    }
    
    function withdrawBalance(address _address) 
    onlyCLevel
    external {
        require(_address != 0x0);
        uint balance = withdrawableBalance;
        withdrawableBalance = 0;
        _address.transfer(balance);
    }
    
    // Only when the contract is paused and there is a subtle bug!
    function kill(address _address) 
    onlyCLevel
    whenPaused
    external {
        require(_address != 0x0);
        selfdestruct(_address);
    }
}