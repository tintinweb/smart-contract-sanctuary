pragma solidity 0.4.20;

contract IAugur {
    function createChildUniverse(bytes32 _parentPayoutDistributionHash, uint256[] _parentPayoutNumerators, bool _parentInvalid) public returns (IUniverse);
    function isKnownUniverse(IUniverse _universe) public view returns (bool);
    function trustedTransfer(ERC20 _token, address _from, address _to, uint256 _amount) public returns (bool);
    function logMarketCreated(bytes32 _topic, string _description, string _extraInfo, IUniverse _universe, address _market, address _marketCreator, bytes32[] _outcomes, int256 _minPrice, int256 _maxPrice, IMarket.MarketType _marketType) public returns (bool);
    function logMarketCreated(bytes32 _topic, string _description, string _extraInfo, IUniverse _universe, address _market, address _marketCreator, int256 _minPrice, int256 _maxPrice, IMarket.MarketType _marketType) public returns (bool);
    function logInitialReportSubmitted(IUniverse _universe, address _reporter, address _market, uint256 _amountStaked, bool _isDesignatedReporter, uint256[] _payoutNumerators, bool _invalid) public returns (bool);
    function disputeCrowdsourcerCreated(IUniverse _universe, address _market, address _disputeCrowdsourcer, uint256[] _payoutNumerators, uint256 _size, bool _invalid) public returns (bool);
    function logDisputeCrowdsourcerContribution(IUniverse _universe, address _reporter, address _market, address _disputeCrowdsourcer, uint256 _amountStaked) public returns (bool);
    function logDisputeCrowdsourcerCompleted(IUniverse _universe, address _market, address _disputeCrowdsourcer) public returns (bool);
    function logInitialReporterRedeemed(IUniverse _universe, address _reporter, address _market, uint256 _amountRedeemed, uint256 _repReceived, uint256 _reportingFeesReceived, uint256[] _payoutNumerators) public returns (bool);
    function logDisputeCrowdsourcerRedeemed(IUniverse _universe, address _reporter, address _market, uint256 _amountRedeemed, uint256 _repReceived, uint256 _reportingFeesReceived, uint256[] _payoutNumerators) public returns (bool);
    function logFeeWindowRedeemed(IUniverse _universe, address _reporter, uint256 _amountRedeemed, uint256 _reportingFeesReceived) public returns (bool);
    function logMarketFinalized(IUniverse _universe) public returns (bool);
    function logMarketMigrated(IMarket _market, IUniverse _originalUniverse) public returns (bool);
    function logReportingParticipantDisavowed(IUniverse _universe, IMarket _market) public returns (bool);
    function logMarketParticipantsDisavowed(IUniverse _universe) public returns (bool);
    function logOrderCanceled(IUniverse _universe, address _shareToken, address _sender, bytes32 _orderId, Order.Types _orderType, uint256 _tokenRefund, uint256 _sharesRefund) public returns (bool);
    function logOrderCreated(Order.Types _orderType, uint256 _amount, uint256 _price, address _creator, uint256 _moneyEscrowed, uint256 _sharesEscrowed, bytes32 _tradeGroupId, bytes32 _orderId, IUniverse _universe, address _shareToken) public returns (bool);
    function logOrderFilled(IUniverse _universe, address _shareToken, address _filler, bytes32 _orderId, uint256 _numCreatorShares, uint256 _numCreatorTokens, uint256 _numFillerShares, uint256 _numFillerTokens, uint256 _marketCreatorFees, uint256 _reporterFees, uint256 _amountFilled, bytes32 _tradeGroupId) public returns (bool);
    function logCompleteSetsPurchased(IUniverse _universe, IMarket _market, address _account, uint256 _numCompleteSets) public returns (bool);
    function logCompleteSetsSold(IUniverse _universe, IMarket _market, address _account, uint256 _numCompleteSets) public returns (bool);
    function logTradingProceedsClaimed(IUniverse _universe, address _shareToken, address _sender, address _market, uint256 _numShares, uint256 _numPayoutTokens, uint256 _finalTokenBalance) public returns (bool);
    function logUniverseForked() public returns (bool);
    function logFeeWindowTransferred(IUniverse _universe, address _from, address _to, uint256 _value) public returns (bool);
    function logReputationTokensTransferred(IUniverse _universe, address _from, address _to, uint256 _value) public returns (bool);
    function logDisputeCrowdsourcerTokensTransferred(IUniverse _universe, address _from, address _to, uint256 _value) public returns (bool);
    function logShareTokensTransferred(IUniverse _universe, address _from, address _to, uint256 _value) public returns (bool);
    function logReputationTokenBurned(IUniverse _universe, address _target, uint256 _amount) public returns (bool);
    function logReputationTokenMinted(IUniverse _universe, address _target, uint256 _amount) public returns (bool);
    function logShareTokenBurned(IUniverse _universe, address _target, uint256 _amount) public returns (bool);
    function logShareTokenMinted(IUniverse _universe, address _target, uint256 _amount) public returns (bool);
    function logFeeWindowBurned(IUniverse _universe, address _target, uint256 _amount) public returns (bool);
    function logFeeWindowMinted(IUniverse _universe, address _target, uint256 _amount) public returns (bool);
    function logDisputeCrowdsourcerTokensBurned(IUniverse _universe, address _target, uint256 _amount) public returns (bool);
    function logDisputeCrowdsourcerTokensMinted(IUniverse _universe, address _target, uint256 _amount) public returns (bool);
    function logFeeWindowCreated(IFeeWindow _feeWindow, uint256 _id) public returns (bool);
    function logFeeTokenTransferred(IUniverse _universe, address _from, address _to, uint256 _value) public returns (bool);
    function logFeeTokenBurned(IUniverse _universe, address _target, uint256 _amount) public returns (bool);
    function logFeeTokenMinted(IUniverse _universe, address _target, uint256 _amount) public returns (bool);
    function logTimestampSet(uint256 _newTimestamp) public returns (bool);
    function logInitialReporterTransferred(IUniverse _universe, IMarket _market, address _from, address _to) public returns (bool);
    function logMarketTransferred(IUniverse _universe, address _from, address _to) public returns (bool);
    function logMarketMailboxTransferred(IUniverse _universe, IMarket _market, address _from, address _to) public returns (bool);
    function logEscapeHatchChanged(bool _isOn) public returns (bool);
}

contract IControlled {
    function getController() public view returns (IController);
    function setController(IController _controller) public returns(bool);
}

contract Controlled is IControlled {
    IController internal controller;

    modifier onlyWhitelistedCallers {
        require(controller.assertIsWhitelisted(msg.sender));
        _;
    }

    modifier onlyCaller(bytes32 _key) {
        require(msg.sender == controller.lookup(_key));
        _;
    }

    modifier onlyControllerCaller {
        require(IController(msg.sender) == controller);
        _;
    }

    modifier onlyInGoodTimes {
        require(controller.stopInEmergency());
        _;
    }

    modifier onlyInBadTimes {
        require(controller.onlyInEmergency());
        _;
    }

    function Controlled() public {
        controller = IController(msg.sender);
    }

    function getController() public view returns(IController) {
        return controller;
    }

    function setController(IController _controller) public onlyControllerCaller returns(bool) {
        controller = _controller;
        return true;
    }
}

contract Augur is Controlled, IAugur {

    enum TokenType{
        ReputationToken,
        ShareToken,
        DisputeCrowdsourcer,
        FeeWindow,
        FeeToken
    }

    event MarketCreated(bytes32 indexed topic, string description, string extraInfo, address indexed universe, address market, address indexed marketCreator, bytes32[] outcomes, uint256 marketCreationFee, int256 minPrice, int256 maxPrice, IMarket.MarketType marketType);
    event InitialReportSubmitted(address indexed universe, address indexed reporter, address indexed market, uint256 amountStaked, bool isDesignatedReporter, uint256[] payoutNumerators, bool invalid);
    event DisputeCrowdsourcerCreated(address indexed universe, address indexed market, address disputeCrowdsourcer, uint256[] payoutNumerators, uint256 size, bool invalid);
    event DisputeCrowdsourcerContribution(address indexed universe, address indexed reporter, address indexed market, address disputeCrowdsourcer, uint256 amountStaked);
    event DisputeCrowdsourcerCompleted(address indexed universe, address indexed market, address disputeCrowdsourcer);
    event InitialReporterRedeemed(address indexed universe, address indexed reporter, address indexed market, uint256 amountRedeemed, uint256 repReceived, uint256 reportingFeesReceived, uint256[] payoutNumerators);
    event DisputeCrowdsourcerRedeemed(address indexed universe, address indexed reporter, address indexed market, address disputeCrowdsourcer, uint256 amountRedeemed, uint256 repReceived, uint256 reportingFeesReceived, uint256[] payoutNumerators);
    event ReportingParticipantDisavowed(address indexed universe, address indexed market, address reportingParticipant);
    event MarketParticipantsDisavowed(address indexed universe, address indexed market);
    event FeeWindowRedeemed(address indexed universe, address indexed reporter, address indexed feeWindow, uint256 amountRedeemed, uint256 reportingFeesReceived);
    event MarketFinalized(address indexed universe, address indexed market);
    event MarketMigrated(address indexed market, address indexed originalUniverse, address indexed newUniverse);
    event UniverseForked(address indexed universe);
    event UniverseCreated(address indexed parentUniverse, address indexed childUniverse, uint256[] payoutNumerators, bool invalid);
    event OrderCanceled(address indexed universe, address indexed shareToken, address indexed sender, bytes32 orderId, Order.Types orderType, uint256 tokenRefund, uint256 sharesRefund);
    // The ordering here is to match functions higher in the call chain to avoid stack depth issues
    event OrderCreated(Order.Types orderType, uint256 amount, uint256 price, address indexed creator, uint256 moneyEscrowed, uint256 sharesEscrowed, bytes32 tradeGroupId, bytes32 orderId, address indexed universe, address indexed shareToken);
    event OrderFilled(address indexed universe, address indexed shareToken, address filler, bytes32 orderId, uint256 numCreatorShares, uint256 numCreatorTokens, uint256 numFillerShares, uint256 numFillerTokens, uint256 marketCreatorFees, uint256 reporterFees, uint256 amountFilled, bytes32 tradeGroupId);
    event CompleteSetsPurchased(address indexed universe, address indexed market, address indexed account, uint256 numCompleteSets);
    event CompleteSetsSold(address indexed universe, address indexed market, address indexed account, uint256 numCompleteSets);
    event TradingProceedsClaimed(address indexed universe, address indexed shareToken, address indexed sender, address market, uint256 numShares, uint256 numPayoutTokens, uint256 finalTokenBalance);
    event TokensTransferred(address indexed universe, address indexed token, address indexed from, address to, uint256 value, TokenType tokenType, address market);
    event TokensMinted(address indexed universe, address indexed token, address indexed target, uint256 amount, TokenType tokenType, address market);
    event TokensBurned(address indexed universe, address indexed token, address indexed target, uint256 amount, TokenType tokenType, address market);
    event FeeWindowCreated(address indexed universe, address feeWindow, uint256 startTime, uint256 endTime, uint256 id);
    event InitialReporterTransferred(address indexed universe, address indexed market, address from, address to);
    event MarketTransferred(address indexed universe, address indexed market, address from, address to);
    event MarketMailboxTransferred(address indexed universe, address indexed market, address indexed mailbox, address from, address to);
    event EscapeHatchChanged(bool isOn);
    event TimestampSet(uint256 newTimestamp);

    mapping(address => bool) private universes;
    mapping(address => bool) private crowdsourcers;

    //
    // Universe
    //

    function createGenesisUniverse() public returns (IUniverse) {
        return createUniverse(IUniverse(0), bytes32(0), new uint256[](0), false);
    }

    function createChildUniverse(bytes32 _parentPayoutDistributionHash, uint256[] _parentPayoutNumerators, bool _parentInvalid) public returns (IUniverse) {
        IUniverse _parentUniverse = IUniverse(msg.sender);
        require(isKnownUniverse(_parentUniverse));
        return createUniverse(_parentUniverse, _parentPayoutDistributionHash, _parentPayoutNumerators, _parentInvalid);
    }

    function createUniverse(IUniverse _parentUniverse, bytes32 _parentPayoutDistributionHash, uint256[] _parentPayoutNumerators, bool _parentInvalid) private returns (IUniverse) {
        UniverseFactory _universeFactory = UniverseFactory(controller.lookup("UniverseFactory"));
        IUniverse _newUniverse = _universeFactory.createUniverse(controller, _parentUniverse, _parentPayoutDistributionHash);
        universes[_newUniverse] = true;
        UniverseCreated(_parentUniverse, _newUniverse, _parentPayoutNumerators, _parentInvalid);
        return _newUniverse;
    }

    function isKnownUniverse(IUniverse _universe) public view returns (bool) {
        return universes[_universe];
    }

    //
    // Crowdsourcers
    //

    function isKnownCrowdsourcer(IDisputeCrowdsourcer _crowdsourcer) public view returns (bool) {
        return crowdsourcers[_crowdsourcer];
    }

    function disputeCrowdsourcerCreated(IUniverse _universe, address _market, address _disputeCrowdsourcer, uint256[] _payoutNumerators, uint256 _size, bool _invalid) public returns (bool) {
        require(isKnownUniverse(_universe));
        require(_universe.isContainerForMarket(IMarket(msg.sender)));
        crowdsourcers[_disputeCrowdsourcer] = true;
        DisputeCrowdsourcerCreated(_universe, _market, _disputeCrowdsourcer, _payoutNumerators, _size, _invalid);
        return true;
    }

    //
    // Transfer
    //

    function trustedTransfer(ERC20 _token, address _from, address _to, uint256 _amount) public onlyWhitelistedCallers returns (bool) {
        require(_amount > 0);
        require(_token.transferFrom(_from, _to, _amount));
        return true;
    }

    //
    // Logging
    //

    // This signature is intended for the categorical market creation. We use two signatures for the same event because of stack depth issues which can be circumvented by maintaining order of paramaters
    function logMarketCreated(bytes32 _topic, string _description, string _extraInfo, IUniverse _universe, address _market, address _marketCreator, bytes32[] _outcomes, int256 _minPrice, int256 _maxPrice, IMarket.MarketType _marketType) public returns (bool) {
        require(isKnownUniverse(_universe));
        require(_universe == IUniverse(msg.sender));
        MarketCreated(_topic, _description, _extraInfo, _universe, _market, _marketCreator, _outcomes, _universe.getOrCacheMarketCreationCost(), _minPrice, _maxPrice, _marketType);
        return true;
    }

    // This signature is intended for yesNo and scalar market creation. See function comment above for explanation.
    function logMarketCreated(bytes32 _topic, string _description, string _extraInfo, IUniverse _universe, address _market, address _marketCreator, int256 _minPrice, int256 _maxPrice, IMarket.MarketType _marketType) public returns (bool) {
        require(isKnownUniverse(_universe));
        require(_universe == IUniverse(msg.sender));
        MarketCreated(_topic, _description, _extraInfo, _universe, _market, _marketCreator, new bytes32[](0), _universe.getOrCacheMarketCreationCost(), _minPrice, _maxPrice, _marketType);
        return true;
    }

    function logInitialReportSubmitted(IUniverse _universe, address _reporter, address _market, uint256 _amountStaked, bool _isDesignatedReporter, uint256[] _payoutNumerators, bool _invalid) public returns (bool) {
        require(isKnownUniverse(_universe));
        require(_universe.isContainerForMarket(IMarket(msg.sender)));
        InitialReportSubmitted(_universe, _reporter, _market, _amountStaked, _isDesignatedReporter, _payoutNumerators, _invalid);
        return true;
    }

    function logDisputeCrowdsourcerContribution(IUniverse _universe, address _reporter, address _market, address _disputeCrowdsourcer, uint256 _amountStaked) public returns (bool) {
        require(isKnownUniverse(_universe));
        require(_universe.isContainerForMarket(IMarket(msg.sender)));
        DisputeCrowdsourcerContribution(_universe, _reporter, _market, _disputeCrowdsourcer, _amountStaked);
        return true;
    }

    function logDisputeCrowdsourcerCompleted(IUniverse _universe, address _market, address _disputeCrowdsourcer) public returns (bool) {
        require(isKnownUniverse(_universe));
        require(_universe.isContainerForMarket(IMarket(msg.sender)));
        DisputeCrowdsourcerCompleted(_universe, _market, _disputeCrowdsourcer);
        return true;
    }

    function logInitialReporterRedeemed(IUniverse _universe, address _reporter, address _market, uint256 _amountRedeemed, uint256 _repReceived, uint256 _reportingFeesReceived, uint256[] _payoutNumerators) public returns (bool) {
        require(isKnownUniverse(_universe));
        require(_universe.isContainerForReportingParticipant(IReportingParticipant(msg.sender)));
        InitialReporterRedeemed(_universe, _reporter, _market, _amountRedeemed, _repReceived, _reportingFeesReceived, _payoutNumerators);
        return true;
    }

    function logDisputeCrowdsourcerRedeemed(IUniverse _universe, address _reporter, address _market, uint256 _amountRedeemed, uint256 _repReceived, uint256 _reportingFeesReceived, uint256[] _payoutNumerators) public returns (bool) {
        IDisputeCrowdsourcer _disputeCrowdsourcer = IDisputeCrowdsourcer(msg.sender);
        require(isKnownCrowdsourcer(_disputeCrowdsourcer));
        DisputeCrowdsourcerRedeemed(_universe, _reporter, _market, _disputeCrowdsourcer, _amountRedeemed, _repReceived, _reportingFeesReceived, _payoutNumerators);
        return true;
    }

    function logReportingParticipantDisavowed(IUniverse _universe, IMarket _market) public returns (bool) {
        require(isKnownUniverse(_universe));
        require(_universe.isContainerForReportingParticipant(IReportingParticipant(msg.sender)));
        ReportingParticipantDisavowed(_universe, _market, msg.sender);
        return true;
    }

    function logMarketParticipantsDisavowed(IUniverse _universe) public returns (bool) {
        require(isKnownUniverse(_universe));
        IMarket _market = IMarket(msg.sender);
        require(_universe.isContainerForMarket(_market));
        MarketParticipantsDisavowed(_universe, _market);
        return true;
    }

    function logFeeWindowRedeemed(IUniverse _universe, address _reporter, uint256 _amountRedeemed, uint256 _reportingFeesReceived) public returns (bool) {
        require(isKnownUniverse(_universe));
        require(_universe.isContainerForFeeWindow(IFeeWindow(msg.sender)));
        FeeWindowRedeemed(_universe, _reporter, msg.sender, _amountRedeemed, _reportingFeesReceived);
        return true;
    }

    function logMarketFinalized(IUniverse _universe) public returns (bool) {
        require(isKnownUniverse(_universe));
        IMarket _market = IMarket(msg.sender);
        require(_universe.isContainerForMarket(_market));
        MarketFinalized(_universe, _market);
        return true;
    }

    function logMarketMigrated(IMarket _market, IUniverse _originalUniverse) public returns (bool) {
        IUniverse _newUniverse = IUniverse(msg.sender);
        require(isKnownUniverse(_newUniverse));
        MarketMigrated(_market, _originalUniverse, _newUniverse);
        return true;
    }

    function logOrderCanceled(IUniverse _universe, address _shareToken, address _sender, bytes32 _orderId, Order.Types _orderType, uint256 _tokenRefund, uint256 _sharesRefund) public onlyWhitelistedCallers returns (bool) {
        OrderCanceled(_universe, _shareToken, _sender, _orderId, _orderType, _tokenRefund, _sharesRefund);
        return true;
    }

    function logOrderCreated(Order.Types _orderType, uint256 _amount, uint256 _price, address _creator, uint256 _moneyEscrowed, uint256 _sharesEscrowed, bytes32 _tradeGroupId, bytes32 _orderId, IUniverse _universe, address _shareToken) public onlyWhitelistedCallers returns (bool) {
        OrderCreated(_orderType, _amount, _price, _creator, _moneyEscrowed, _sharesEscrowed, _tradeGroupId, _orderId, _universe, _shareToken);
        return true;
    }

    function logOrderFilled(IUniverse _universe, address _shareToken, address _filler, bytes32 _orderId, uint256 _numCreatorShares, uint256 _numCreatorTokens, uint256 _numFillerShares, uint256 _numFillerTokens, uint256 _marketCreatorFees, uint256 _reporterFees, uint256 _amountFilled, bytes32 _tradeGroupId) public onlyWhitelistedCallers returns (bool) {
        OrderFilled(_universe, _shareToken, _filler, _orderId, _numCreatorShares, _numCreatorTokens, _numFillerShares, _numFillerTokens, _marketCreatorFees, _reporterFees, _amountFilled, _tradeGroupId);
        return true;
    }

    function logCompleteSetsPurchased(IUniverse _universe, IMarket _market, address _account, uint256 _numCompleteSets) public onlyWhitelistedCallers returns (bool) {
        CompleteSetsPurchased(_universe, _market, _account, _numCompleteSets);
        return true;
    }

    function logCompleteSetsSold(IUniverse _universe, IMarket _market, address _account, uint256 _numCompleteSets) public onlyWhitelistedCallers returns (bool) {
        CompleteSetsSold(_universe, _market, _account, _numCompleteSets);
        return true;
    }

    function logTradingProceedsClaimed(IUniverse _universe, address _shareToken, address _sender, address _market, uint256 _numShares, uint256 _numPayoutTokens, uint256 _finalTokenBalance) public onlyWhitelistedCallers returns (bool) {
        TradingProceedsClaimed(_universe, _shareToken, _sender, _market, _numShares, _numPayoutTokens, _finalTokenBalance);
        return true;
    }

    function logUniverseForked() public returns (bool) {
        require(universes[msg.sender]);
        UniverseForked(msg.sender);
        return true;
    }

    function logFeeWindowTransferred(IUniverse _universe, address _from, address _to, uint256 _value) public returns (bool) {
        require(isKnownUniverse(_universe));
        require(_universe.isContainerForFeeWindow(IFeeWindow(msg.sender)));
        TokensTransferred(_universe, msg.sender, _from, _to, _value, TokenType.FeeWindow, 0);
        return true;
    }

    function logReputationTokensTransferred(IUniverse _universe, address _from, address _to, uint256 _value) public returns (bool) {
        require(isKnownUniverse(_universe));
        require(_universe.getReputationToken() == IReputationToken(msg.sender));
        TokensTransferred(_universe, msg.sender, _from, _to, _value, TokenType.ReputationToken, 0);
        return true;
    }

    function logDisputeCrowdsourcerTokensTransferred(IUniverse _universe, address _from, address _to, uint256 _value) public returns (bool) {
        IDisputeCrowdsourcer _disputeCrowdsourcer = IDisputeCrowdsourcer(msg.sender);
        require(isKnownCrowdsourcer(_disputeCrowdsourcer));
        TokensTransferred(_universe, msg.sender, _from, _to, _value, TokenType.DisputeCrowdsourcer, _disputeCrowdsourcer.getMarket());
        return true;
    }

    function logShareTokensTransferred(IUniverse _universe, address _from, address _to, uint256 _value) public returns (bool) {
        require(isKnownUniverse(_universe));
        IShareToken _shareToken = IShareToken(msg.sender);
        require(_universe.isContainerForShareToken(_shareToken));
        TokensTransferred(_universe, msg.sender, _from, _to, _value, TokenType.ShareToken, _shareToken.getMarket());
        return true;
    }

    function logReputationTokenBurned(IUniverse _universe, address _target, uint256 _amount) public returns (bool) {
        require(isKnownUniverse(_universe));
        require(_universe.getReputationToken() == IReputationToken(msg.sender));
        TokensBurned(_universe, msg.sender, _target, _amount, TokenType.ReputationToken, 0);
        return true;
    }

    function logReputationTokenMinted(IUniverse _universe, address _target, uint256 _amount) public returns (bool) {
        require(isKnownUniverse(_universe));
        require(_universe.getReputationToken() == IReputationToken(msg.sender));
        TokensMinted(_universe, msg.sender, _target, _amount, TokenType.ReputationToken, 0);
        return true;
    }

    function logShareTokenBurned(IUniverse _universe, address _target, uint256 _amount) public returns (bool) {
        require(isKnownUniverse(_universe));
        IShareToken _shareToken = IShareToken(msg.sender);
        require(_universe.isContainerForShareToken(_shareToken));
        TokensBurned(_universe, msg.sender, _target, _amount, TokenType.ShareToken, _shareToken.getMarket());
        return true;
    }

    function logShareTokenMinted(IUniverse _universe, address _target, uint256 _amount) public returns (bool) {
        require(isKnownUniverse(_universe));
        IShareToken _shareToken = IShareToken(msg.sender);
        require(_universe.isContainerForShareToken(_shareToken));
        TokensMinted(_universe, msg.sender, _target, _amount, TokenType.ShareToken, _shareToken.getMarket());
        return true;
    }

    function logFeeWindowBurned(IUniverse _universe, address _target, uint256 _amount) public returns (bool) {
        require(isKnownUniverse(_universe));
        require(_universe.isContainerForFeeWindow(IFeeWindow(msg.sender)));
        TokensBurned(_universe, msg.sender, _target, _amount, TokenType.FeeWindow, 0);
        return true;
    }

    function logFeeWindowMinted(IUniverse _universe, address _target, uint256 _amount) public returns (bool) {
        require(isKnownUniverse(_universe));
        require(_universe.isContainerForFeeWindow(IFeeWindow(msg.sender)));
        TokensMinted(_universe, msg.sender, _target, _amount, TokenType.FeeWindow, 0);
        return true;
    }

    function logDisputeCrowdsourcerTokensBurned(IUniverse _universe, address _target, uint256 _amount) public returns (bool) {
        IDisputeCrowdsourcer _disputeCrowdsourcer = IDisputeCrowdsourcer(msg.sender);
        require(isKnownCrowdsourcer(_disputeCrowdsourcer));
        TokensBurned(_universe, msg.sender, _target, _amount, TokenType.DisputeCrowdsourcer, _disputeCrowdsourcer.getMarket());
        return true;
    }

    function logDisputeCrowdsourcerTokensMinted(IUniverse _universe, address _target, uint256 _amount) public returns (bool) {
        IDisputeCrowdsourcer _disputeCrowdsourcer = IDisputeCrowdsourcer(msg.sender);
        require(isKnownCrowdsourcer(_disputeCrowdsourcer));
        TokensMinted(_universe, msg.sender, _target, _amount, TokenType.DisputeCrowdsourcer, _disputeCrowdsourcer.getMarket());
        return true;
    }

    function logFeeWindowCreated(IFeeWindow _feeWindow, uint256 _id) public returns (bool) {
        require(universes[msg.sender]);
        FeeWindowCreated(msg.sender, _feeWindow, _feeWindow.getStartTime(), _feeWindow.getEndTime(), _id);
        return true;
    }

    function logFeeTokenTransferred(IUniverse _universe, address _from, address _to, uint256 _value) public returns (bool) {
        require(isKnownUniverse(_universe));
        require(_universe.isContainerForFeeToken(IFeeToken(msg.sender)));
        TokensTransferred(_universe, msg.sender, _from, _to, _value, TokenType.FeeToken, 0);
        return true;
    }

    function logFeeTokenBurned(IUniverse _universe, address _target, uint256 _amount) public returns (bool) {
        require(isKnownUniverse(_universe));
        require(_universe.isContainerForFeeToken(IFeeToken(msg.sender)));
        TokensBurned(_universe, msg.sender, _target, _amount, TokenType.FeeToken, 0);
        return true;
    }

    function logFeeTokenMinted(IUniverse _universe, address _target, uint256 _amount) public returns (bool) {
        require(isKnownUniverse(_universe));
        require(_universe.isContainerForFeeToken(IFeeToken(msg.sender)));
        TokensMinted(_universe, msg.sender, _target, _amount, TokenType.FeeToken, 0);
        return true;
    }

    function logTimestampSet(uint256 _newTimestamp) public returns (bool) {
        require(msg.sender == controller.lookup("Time"));
        TimestampSet(_newTimestamp);
        return true;
    }

    function logInitialReporterTransferred(IUniverse _universe, IMarket _market, address _from, address _to) public returns (bool) {
        require(isKnownUniverse(_universe));
        require(_universe.isContainerForMarket(_market));
        require(msg.sender == _market.getInitialReporterAddress());
        InitialReporterTransferred(_universe, _market, _from, _to);
        return true;
    }

    function logMarketTransferred(IUniverse _universe, address _from, address _to) public returns (bool) {
        require(isKnownUniverse(_universe));
        IMarket _market = IMarket(msg.sender);
        require(_universe.isContainerForMarket(_market));
        MarketTransferred(_universe, _market, _from, _to);
        return true;
    }

    function logMarketMailboxTransferred(IUniverse _universe, IMarket _market, address _from, address _to) public returns (bool) {
        require(isKnownUniverse(_universe));
        require(_universe.isContainerForMarket(_market));
        require(IMailbox(msg.sender) == _market.getMarketCreatorMailbox());
        MarketMailboxTransferred(_universe, _market, msg.sender, _from, _to);
        return true;
    }

    function logEscapeHatchChanged(bool _isOn) public returns (bool) {
        require(msg.sender == address(controller));
        EscapeHatchChanged(_isOn);
        return true;
    }
}

contract IController {
    function assertIsWhitelisted(address _target) public view returns(bool);
    function lookup(bytes32 _key) public view returns(address);
    function stopInEmergency() public view returns(bool);
    function onlyInEmergency() public view returns(bool);
    function getAugur() public view returns (IAugur);
    function getTimestamp() public view returns (uint256);
}

contract UniverseFactory {
    function createUniverse(IController _controller, IUniverse _parentUniverse, bytes32 _parentPayoutDistributionHash) public returns (IUniverse) {
        Delegator _delegator = new Delegator(_controller, "Universe");
        IUniverse _universe = IUniverse(_delegator);
        _universe.initialize(_parentUniverse, _parentPayoutDistributionHash);
        return _universe;
    }
}

contract DelegationTarget is Controlled {
    bytes32 public controllerLookupName;
}

contract Delegator is DelegationTarget {
    function Delegator(IController _controller, bytes32 _controllerLookupName) public {
        controller = _controller;
        controllerLookupName = _controllerLookupName;
    }

    function() external payable {
        // Do nothing if we haven&#39;t properly set up the delegator to delegate calls
        if (controllerLookupName == 0) {
            return;
        }

        // Get the delegation target contract
        address _target = controller.lookup(controllerLookupName);

        assembly {
            //0x40 is the address where the next free memory slot is stored in Solidity
            let _calldataMemoryOffset := mload(0x40)
            // new "memory end" including padding. The bitwise operations here ensure we get rounded up to the nearest 32 byte boundary
            let _size := and(add(calldatasize, 0x1f), not(0x1f))
            // Update the pointer at 0x40 to point at new free memory location so any theoretical allocation doesn&#39;t stomp our memory in this call
            mstore(0x40, add(_calldataMemoryOffset, _size))
            // Copy method signature and parameters of this call into memory
            calldatacopy(_calldataMemoryOffset, 0x0, calldatasize)
            // Call the actual method via delegation
            let _retval := delegatecall(gas, _target, _calldataMemoryOffset, calldatasize, 0, 0)
            switch _retval
            case 0 {
                // 0 == it threw, so we revert
                revert(0,0)
            } default {
                // If the call succeeded return the return data from the delegate call
                let _returndataMemoryOffset := mload(0x40)
                // Update the pointer at 0x40 again to point at new free memory location so any theoretical allocation doesn&#39;t stomp our memory in this call
                mstore(0x40, add(_returndataMemoryOffset, returndatasize))
                returndatacopy(_returndataMemoryOffset, 0x0, returndatasize)
                return(_returndataMemoryOffset, returndatasize)
            }
        }
    }
}

contract IOwnable {
    function getOwner() public view returns (address);
    function transferOwnership(address newOwner) public returns (bool);
}

contract ITyped {
    function getTypeName() public view returns (bytes32);
}

contract Initializable {
    bool private initialized = false;

    modifier afterInitialized {
        require(initialized);
        _;
    }

    modifier beforeInitialized {
        require(!initialized);
        _;
    }

    function endInitialization() internal beforeInitialized returns (bool) {
        initialized = true;
        return true;
    }

    function getInitialized() public view returns (bool) {
        return initialized;
    }
}

library SafeMathUint256 {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a <= b) {
            return a;
        } else {
            return b;
        }
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a >= b) {
            return a;
        } else {
            return b;
        }
    }

    function getUint256Min() internal pure returns (uint256) {
        return 0;
    }

    function getUint256Max() internal pure returns (uint256) {
        return 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    }

    function isMultipleOf(uint256 a, uint256 b) internal pure returns (bool) {
        return a % b == 0;
    }

    // Float [fixed point] Operations
    function fxpMul(uint256 a, uint256 b, uint256 base) internal pure returns (uint256) {
        return div(mul(a, b), base);
    }

    function fxpDiv(uint256 a, uint256 b, uint256 base) internal pure returns (uint256) {
        return div(mul(a, base), b);
    }
}

contract ERC20Basic {
    event Transfer(address indexed from, address indexed to, uint256 value);

    function balanceOf(address _who) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    function totalSupply() public view returns (uint256);
}

contract ERC20 is ERC20Basic {
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function allowance(address _owner, address _spender) public view returns (uint256);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
    function approve(address _spender, uint256 _value) public returns (bool);
}

contract IFeeToken is ERC20, Initializable {
    function initialize(IFeeWindow _feeWindow) public returns (bool);
    function getFeeWindow() public view returns (IFeeWindow);
    function feeWindowBurn(address _target, uint256 _amount) public returns (bool);
    function mintForReportingParticipant(address _target, uint256 _amount) public returns (bool);
}

contract IFeeWindow is ITyped, ERC20 {
    function initialize(IUniverse _universe, uint256 _feeWindowId) public returns (bool);
    function getUniverse() public view returns (IUniverse);
    function getReputationToken() public view returns (IReputationToken);
    function getStartTime() public view returns (uint256);
    function getEndTime() public view returns (uint256);
    function getNumMarkets() public view returns (uint256);
    function getNumInvalidMarkets() public view returns (uint256);
    function getNumIncorrectDesignatedReportMarkets() public view returns (uint256);
    function getNumDesignatedReportNoShows() public view returns (uint256);
    function getFeeToken() public view returns (IFeeToken);
    function isActive() public view returns (bool);
    function isOver() public view returns (bool);
    function onMarketFinalized() public returns (bool);
    function buy(uint256 _attotokens) public returns (bool);
    function redeem(address _sender) public returns (bool);
    function redeemForReportingParticipant() public returns (bool);
    function mintFeeTokens(uint256 _amount) public returns (bool);
    function trustedUniverseBuy(address _buyer, uint256 _attotokens) public returns (bool);
}

contract IMailbox {
    function initialize(address _owner, IMarket _market) public returns (bool);
    function depositEther() public payable returns (bool);
}

contract IMarket is ITyped, IOwnable {
    enum MarketType {
        YES_NO,
        CATEGORICAL,
        SCALAR
    }

    function initialize(IUniverse _universe, uint256 _endTime, uint256 _feePerEthInAttoeth, ICash _cash, address _designatedReporterAddress, address _creator, uint256 _numOutcomes, uint256 _numTicks) public payable returns (bool _success);
    function derivePayoutDistributionHash(uint256[] _payoutNumerators, bool _invalid) public view returns (bytes32);
    function getUniverse() public view returns (IUniverse);
    function getFeeWindow() public view returns (IFeeWindow);
    function getNumberOfOutcomes() public view returns (uint256);
    function getNumTicks() public view returns (uint256);
    function getDenominationToken() public view returns (ICash);
    function getShareToken(uint256 _outcome)  public view returns (IShareToken);
    function getMarketCreatorSettlementFeeDivisor() public view returns (uint256);
    function getForkingMarket() public view returns (IMarket _market);
    function getEndTime() public view returns (uint256);
    function getMarketCreatorMailbox() public view returns (IMailbox);
    function getWinningPayoutDistributionHash() public view returns (bytes32);
    function getWinningPayoutNumerator(uint256 _outcome) public view returns (uint256);
    function getReputationToken() public view returns (IReputationToken);
    function getFinalizationTime() public view returns (uint256);
    function getInitialReporterAddress() public view returns (address);
    function deriveMarketCreatorFeeAmount(uint256 _amount) public view returns (uint256);
    function isContainerForShareToken(IShareToken _shadyTarget) public view returns (bool);
    function isContainerForReportingParticipant(IReportingParticipant _reportingParticipant) public view returns (bool);
    function isInvalid() public view returns (bool);
    function finalize() public returns (bool);
    function designatedReporterWasCorrect() public view returns (bool);
    function designatedReporterShowed() public view returns (bool);
    function isFinalized() public view returns (bool);
    function finalizeFork() public returns (bool);
    function assertBalances() public view returns (bool);
}

contract IReportingParticipant {
    function getStake() public view returns (uint256);
    function getPayoutDistributionHash() public view returns (bytes32);
    function liquidateLosing() public returns (bool);
    function redeem(address _redeemer) public returns (bool);
    function isInvalid() public view returns (bool);
    function isDisavowed() public view returns (bool);
    function migrate() public returns (bool);
    function getPayoutNumerator(uint256 _outcome) public view returns (uint256);
    function getMarket() public view returns (IMarket);
    function getSize() public view returns (uint256);
}

contract IDisputeCrowdsourcer is IReportingParticipant, ERC20 {
    function initialize(IMarket market, uint256 _size, bytes32 _payoutDistributionHash, uint256[] _payoutNumerators, bool _invalid) public returns (bool);
    function contribute(address _participant, uint256 _amount) public returns (uint256);
}

contract IInitialReporter is IReportingParticipant {
    function initialize(IMarket _market, address _designatedReporter) public returns (bool);
    function report(address _reporter, bytes32 _payoutDistributionHash, uint256[] _payoutNumerators, bool _invalid) public returns (bool);
    function resetReportTimestamp() public returns (bool);
    function designatedReporterShowed() public view returns (bool);
    function designatedReporterWasCorrect() public view returns (bool);
    function getDesignatedReporter() public view returns (address);
    function getReportTimestamp() public view returns (uint256);
    function migrateREP() public returns (bool);
}

contract IReputationToken is ITyped, ERC20 {
    function initialize(IUniverse _universe) public returns (bool);
    function migrateOut(IReputationToken _destination, uint256 _attotokens) public returns (bool);
    function migrateIn(address _reporter, uint256 _attotokens) public returns (bool);
    function trustedReportingParticipantTransfer(address _source, address _destination, uint256 _attotokens) public returns (bool);
    function trustedMarketTransfer(address _source, address _destination, uint256 _attotokens) public returns (bool);
    function trustedFeeWindowTransfer(address _source, address _destination, uint256 _attotokens) public returns (bool);
    function trustedUniverseTransfer(address _source, address _destination, uint256 _attotokens) public returns (bool);
    function getUniverse() public view returns (IUniverse);
    function getTotalMigrated() public view returns (uint256);
    function getTotalTheoreticalSupply() public view returns (uint256);
    function mintForReportingParticipant(uint256 _amountMigrated) public returns (bool);
}

contract IUniverse is ITyped {
    function initialize(IUniverse _parentUniverse, bytes32 _parentPayoutDistributionHash) external returns (bool);
    function fork() public returns (bool);
    function getParentUniverse() public view returns (IUniverse);
    function createChildUniverse(uint256[] _parentPayoutNumerators, bool _invalid) public returns (IUniverse);
    function getChildUniverse(bytes32 _parentPayoutDistributionHash) public view returns (IUniverse);
    function getReputationToken() public view returns (IReputationToken);
    function getForkingMarket() public view returns (IMarket);
    function getForkEndTime() public view returns (uint256);
    function getForkReputationGoal() public view returns (uint256);
    function getParentPayoutDistributionHash() public view returns (bytes32);
    function getDisputeRoundDurationInSeconds() public view returns (uint256);
    function getOrCreateFeeWindowByTimestamp(uint256 _timestamp) public returns (IFeeWindow);
    function getOrCreateCurrentFeeWindow() public returns (IFeeWindow);
    function getOrCreateNextFeeWindow() public returns (IFeeWindow);
    function getOpenInterestInAttoEth() public view returns (uint256);
    function getRepMarketCapInAttoeth() public view returns (uint256);
    function getTargetRepMarketCapInAttoeth() public view returns (uint256);
    function getOrCacheValidityBond() public returns (uint256);
    function getOrCacheDesignatedReportStake() public returns (uint256);
    function getOrCacheDesignatedReportNoShowBond() public returns (uint256);
    function getOrCacheReportingFeeDivisor() public returns (uint256);
    function getDisputeThresholdForFork() public view returns (uint256);
    function getInitialReportMinValue() public view returns (uint256);
    function calculateFloatingValue(uint256 _badMarkets, uint256 _totalMarkets, uint256 _targetDivisor, uint256 _previousValue, uint256 _defaultValue, uint256 _floor) public pure returns (uint256 _newValue);
    function getOrCacheMarketCreationCost() public returns (uint256);
    function getCurrentFeeWindow() public view returns (IFeeWindow);
    function getOrCreateFeeWindowBefore(IFeeWindow _feeWindow) public returns (IFeeWindow);
    function isParentOf(IUniverse _shadyChild) public view returns (bool);
    function updateTentativeWinningChildUniverse(bytes32 _parentPayoutDistributionHash) public returns (bool);
    function isContainerForFeeWindow(IFeeWindow _shadyTarget) public view returns (bool);
    function isContainerForMarket(IMarket _shadyTarget) public view returns (bool);
    function isContainerForReportingParticipant(IReportingParticipant _reportingParticipant) public view returns (bool);
    function isContainerForShareToken(IShareToken _shadyTarget) public view returns (bool);
    function isContainerForFeeToken(IFeeToken _shadyTarget) public view returns (bool);
    function addMarketTo() public returns (bool);
    function removeMarketFrom() public returns (bool);
    function decrementOpenInterest(uint256 _amount) public returns (bool);
    function decrementOpenInterestFromMarket(uint256 _amount) public returns (bool);
    function incrementOpenInterest(uint256 _amount) public returns (bool);
    function incrementOpenInterestFromMarket(uint256 _amount) public returns (bool);
    function getWinningChildUniverse() public view returns (IUniverse);
    function isForking() public view returns (bool);
}

contract ICash is ERC20 {
    function depositEther() external payable returns(bool);
    function depositEtherFor(address _to) external payable returns(bool);
    function withdrawEther(uint256 _amount) external returns(bool);
    function withdrawEtherTo(address _to, uint256 _amount) external returns(bool);
    function withdrawEtherToIfPossible(address _to, uint256 _amount) external returns (bool);
}

contract IOrders {
    function saveOrder(Order.Types _type, IMarket _market, uint256 _fxpAmount, uint256 _price, address _sender, uint256 _outcome, uint256 _moneyEscrowed, uint256 _sharesEscrowed, bytes32 _betterOrderId, bytes32 _worseOrderId, bytes32 _tradeGroupId) public returns (bytes32 _orderId);
    function removeOrder(bytes32 _orderId) public returns (bool);
    function getMarket(bytes32 _orderId) public view returns (IMarket);
    function getOrderType(bytes32 _orderId) public view returns (Order.Types);
    function getOutcome(bytes32 _orderId) public view returns (uint256);
    function getAmount(bytes32 _orderId) public view returns (uint256);
    function getPrice(bytes32 _orderId) public view returns (uint256);
    function getOrderCreator(bytes32 _orderId) public view returns (address);
    function getOrderSharesEscrowed(bytes32 _orderId) public view returns (uint256);
    function getOrderMoneyEscrowed(bytes32 _orderId) public view returns (uint256);
    function getBetterOrderId(bytes32 _orderId) public view returns (bytes32);
    function getWorseOrderId(bytes32 _orderId) public view returns (bytes32);
    function getBestOrderId(Order.Types _type, IMarket _market, uint256 _outcome) public view returns (bytes32);
    function getWorstOrderId(Order.Types _type, IMarket _market, uint256 _outcome) public view returns (bytes32);
    function getLastOutcomePrice(IMarket _market, uint256 _outcome) public view returns (uint256);
    function getOrderId(Order.Types _type, IMarket _market, uint256 _fxpAmount, uint256 _price, address _sender, uint256 _blockNumber, uint256 _outcome, uint256 _moneyEscrowed, uint256 _sharesEscrowed) public pure returns (bytes32);
    function getTotalEscrowed(IMarket _market) public view returns (uint256);
    function isBetterPrice(Order.Types _type, uint256 _price, bytes32 _orderId) public view returns (bool);
    function isWorsePrice(Order.Types _type, uint256 _price, bytes32 _orderId) public view returns (bool);
    function assertIsNotBetterPrice(Order.Types _type, uint256 _price, bytes32 _betterOrderId) public view returns (bool);
    function assertIsNotWorsePrice(Order.Types _type, uint256 _price, bytes32 _worseOrderId) public returns (bool);
    function recordFillOrder(bytes32 _orderId, uint256 _sharesFilled, uint256 _tokensFilled) public returns (bool);
    function setPrice(IMarket _market, uint256 _outcome, uint256 _price) external returns (bool);
    function incrementTotalEscrowed(IMarket _market, uint256 _amount) external returns (bool);
    function decrementTotalEscrowed(IMarket _market, uint256 _amount) external returns (bool);
}

contract IShareToken is ITyped, ERC20 {
    function initialize(IMarket _market, uint256 _outcome) external returns (bool);
    function createShares(address _owner, uint256 _amount) external returns (bool);
    function destroyShares(address, uint256 balance) external returns (bool);
    function getMarket() external view returns (IMarket);
    function getOutcome() external view returns (uint256);
    function trustedOrderTransfer(address _source, address _destination, uint256 _attotokens) public returns (bool);
    function trustedFillOrderTransfer(address _source, address _destination, uint256 _attotokens) public returns (bool);
    function trustedCancelOrderTransfer(address _source, address _destination, uint256 _attotokens) public returns (bool);
}

library Order {
    using SafeMathUint256 for uint256;

    enum Types {
        Bid, Ask
    }

    enum TradeDirections {
        Long, Short
    }

    struct Data {
        // Contracts
        IOrders orders;
        IMarket market;
        IAugur augur;

        // Order
        bytes32 id;
        address creator;
        uint256 outcome;
        Order.Types orderType;
        uint256 amount;
        uint256 price;
        uint256 sharesEscrowed;
        uint256 moneyEscrowed;
        bytes32 betterOrderId;
        bytes32 worseOrderId;
    }

    //
    // Constructor
    //

    // No validation is needed here as it is simply a librarty function for organizing data
    function create(IController _controller, address _creator, uint256 _outcome, Order.Types _type, uint256 _attoshares, uint256 _price, IMarket _market, bytes32 _betterOrderId, bytes32 _worseOrderId) internal view returns (Data) {
        require(_outcome < _market.getNumberOfOutcomes());
        require(_price < _market.getNumTicks());

        IOrders _orders = IOrders(_controller.lookup("Orders"));
        IAugur _augur = _controller.getAugur();

        return Data({
            orders: _orders,
            market: _market,
            augur: _augur,
            id: 0,
            creator: _creator,
            outcome: _outcome,
            orderType: _type,
            amount: _attoshares,
            price: _price,
            sharesEscrowed: 0,
            moneyEscrowed: 0,
            betterOrderId: _betterOrderId,
            worseOrderId: _worseOrderId
        });
    }

    //
    // "public" functions
    //

    function getOrderId(Order.Data _orderData) internal view returns (bytes32) {
        if (_orderData.id == bytes32(0)) {
            bytes32 _orderId = _orderData.orders.getOrderId(_orderData.orderType, _orderData.market, _orderData.amount, _orderData.price, _orderData.creator, block.number, _orderData.outcome, _orderData.moneyEscrowed, _orderData.sharesEscrowed);
            require(_orderData.orders.getAmount(_orderId) == 0);
            _orderData.id = _orderId;
        }
        return _orderData.id;
    }

    function getOrderTradingTypeFromMakerDirection(Order.TradeDirections _creatorDirection) internal pure returns (Order.Types) {
        return (_creatorDirection == Order.TradeDirections.Long) ? Order.Types.Bid : Order.Types.Ask;
    }

    function getOrderTradingTypeFromFillerDirection(Order.TradeDirections _fillerDirection) internal pure returns (Order.Types) {
        return (_fillerDirection == Order.TradeDirections.Long) ? Order.Types.Ask : Order.Types.Bid;
    }

    function escrowFunds(Order.Data _orderData) internal returns (bool) {
        if (_orderData.orderType == Order.Types.Ask) {
            return escrowFundsForAsk(_orderData);
        } else if (_orderData.orderType == Order.Types.Bid) {
            return escrowFundsForBid(_orderData);
        }
    }

    function saveOrder(Order.Data _orderData, bytes32 _tradeGroupId) internal returns (bytes32) {
        return _orderData.orders.saveOrder(_orderData.orderType, _orderData.market, _orderData.amount, _orderData.price, _orderData.creator, _orderData.outcome, _orderData.moneyEscrowed, _orderData.sharesEscrowed, _orderData.betterOrderId, _orderData.worseOrderId, _tradeGroupId);
    }

    //
    // Private functions
    //

    function escrowFundsForBid(Order.Data _orderData) private returns (bool) {
        require(_orderData.moneyEscrowed == 0);
        require(_orderData.sharesEscrowed == 0);
        uint256 _attosharesToCover = _orderData.amount;
        uint256 _numberOfOutcomes = _orderData.market.getNumberOfOutcomes();

        // Figure out how many almost-complete-sets (just missing `outcome` share) the creator has
        uint256 _attosharesHeld = 2**254;
        for (uint256 _i = 0; _i < _numberOfOutcomes; _i++) {
            if (_i != _orderData.outcome) {
                uint256 _creatorShareTokenBalance = _orderData.market.getShareToken(_i).balanceOf(_orderData.creator);
                _attosharesHeld = SafeMathUint256.min(_creatorShareTokenBalance, _attosharesHeld);
            }
        }

        // Take shares into escrow if they have any almost-complete-sets
        if (_attosharesHeld > 0) {
            _orderData.sharesEscrowed = SafeMathUint256.min(_attosharesHeld, _attosharesToCover);
            _attosharesToCover -= _orderData.sharesEscrowed;
            for (_i = 0; _i < _numberOfOutcomes; _i++) {
                if (_i != _orderData.outcome) {
                    _orderData.market.getShareToken(_i).trustedOrderTransfer(_orderData.creator, _orderData.market, _orderData.sharesEscrowed);
                }
            }
        }
        // If not able to cover entire order with shares alone, then cover remaining with tokens
        if (_attosharesToCover > 0) {
            _orderData.moneyEscrowed = _attosharesToCover.mul(_orderData.price);
            require(_orderData.augur.trustedTransfer(_orderData.market.getDenominationToken(), _orderData.creator, _orderData.market, _orderData.moneyEscrowed));
        }

        return true;
    }

    function escrowFundsForAsk(Order.Data _orderData) private returns (bool) {
        require(_orderData.moneyEscrowed == 0);
        require(_orderData.sharesEscrowed == 0);
        IShareToken _shareToken = _orderData.market.getShareToken(_orderData.outcome);
        uint256 _attosharesToCover = _orderData.amount;

        // Figure out how many shares of the outcome the creator has
        uint256 _attosharesHeld = _shareToken.balanceOf(_orderData.creator);

        // Take shares in escrow if user has shares
        if (_attosharesHeld > 0) {
            _orderData.sharesEscrowed = SafeMathUint256.min(_attosharesHeld, _attosharesToCover);
            _attosharesToCover -= _orderData.sharesEscrowed;
            _shareToken.trustedOrderTransfer(_orderData.creator, _orderData.market, _orderData.sharesEscrowed);
        }

        // If not able to cover entire order with shares alone, then cover remaining with tokens
        if (_attosharesToCover > 0) {
            _orderData.moneyEscrowed = _orderData.market.getNumTicks().sub(_orderData.price).mul(_attosharesToCover);
            require(_orderData.augur.trustedTransfer(_orderData.market.getDenominationToken(), _orderData.creator, _orderData.market, _orderData.moneyEscrowed));
        }

        return true;
    }
}