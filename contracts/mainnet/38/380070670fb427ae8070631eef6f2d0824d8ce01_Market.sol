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

contract IController {
    function assertIsWhitelisted(address _target) public view returns(bool);
    function lookup(bytes32 _key) public view returns(address);
    function stopInEmergency() public view returns(bool);
    function onlyInEmergency() public view returns(bool);
    function getAugur() public view returns (IAugur);
    function getTimestamp() public view returns (uint256);
}

contract DisputeCrowdsourcerFactory {
    function createDisputeCrowdsourcer(IController _controller, IMarket _market, uint256 _size, bytes32 _payoutDistributionHash, uint256[] _payoutNumerators, bool _invalid) public returns (IDisputeCrowdsourcer) {
        Delegator _delegator = new Delegator(_controller, "DisputeCrowdsourcer");
        IDisputeCrowdsourcer _disputeCrowdsourcer = IDisputeCrowdsourcer(_delegator);
        _disputeCrowdsourcer.initialize(_market, _size, _payoutDistributionHash, _payoutNumerators, _invalid);
        return _disputeCrowdsourcer;
    }
}

contract InitialReporterFactory {
    function createInitialReporter(IController _controller, IMarket _market, address _designatedReporter) public returns (IInitialReporter) {
        Delegator _delegator = new Delegator(_controller, "InitialReporter");
        IInitialReporter _initialReporter = IInitialReporter(_delegator);
        _initialReporter.initialize(_market, _designatedReporter);
        return _initialReporter;
    }
}

contract MailboxFactory {
    function createMailbox(IController _controller, address _owner, IMarket _market) public returns (IMailbox) {
        Delegator _delegator = new Delegator(_controller, "Mailbox");
        IMailbox _mailbox = IMailbox(_delegator);
        _mailbox.initialize(_owner, _market);
        return _mailbox;
    }
}

contract MapFactory {
    function createMap(IController _controller, address _owner) public returns (Map) {
        Delegator _delegator = new Delegator(_controller, "Map");
        Map _map = Map(_delegator);
        _map.initialize(_owner);
        return _map;
    }
}

contract ShareTokenFactory {
    function createShareToken(IController _controller, IMarket _market, uint256 _outcome) public returns (IShareToken) {
        Delegator _delegator = new Delegator(_controller, "ShareToken");
        IShareToken _shareToken = IShareToken(_delegator);
        _shareToken.initialize(_market, _outcome);
        return _shareToken;
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

contract Ownable is IOwnable {
    address internal owner;

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function Ownable() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner returns (bool) {
        if (_newOwner != address(0)) {
            onTransferOwnership(owner, _newOwner);
            owner = _newOwner;
        }
        return true;
    }

    // Subclasses of this token may want to send additional logs through the centralized Augur log emitter contract
    function onTransferOwnership(address, address) internal returns (bool);
}

contract Map is DelegationTarget, Ownable, Initializable {
    mapping(bytes32 => bytes32) private items;
    uint256 private count;

    function initialize(address _owner) public beforeInitialized returns (bool) {
        endInitialization();
        owner = _owner;
        return true;
    }

    function add(bytes32 _key, bytes32 _value) public onlyOwner returns (bool) {
        if (contains(_key)) {
            return false;
        }
        items[_key] = _value;
        count += 1;
        return true;
    }

    function add(bytes32 _key, address _value) public onlyOwner returns (bool) {
        return add(_key, bytes32(_value));
    }

    function remove(bytes32 _key) public onlyOwner returns (bool) {
        if (!contains(_key)) {
            return false;
        }
        delete items[_key];
        count -= 1;
        return true;
    }

    function getValueOrZero(bytes32 _key) public view returns (bytes32) {
        return items[_key];
    }

    function get(bytes32 _key) public view returns (bytes32) {
        bytes32 _value = items[_key];
        require(_value != bytes32(0));
        return _value;
    }

    function getAsAddressOrZero(bytes32 _key) public view returns (address) {
        return address(getValueOrZero(_key));
    }

    function getAsAddress(bytes32 _key) public view returns (address) {
        return address(get(_key));
    }

    function contains(bytes32 _key) public view returns (bool) {
        return items[_key] != bytes32(0);
    }

    function getCount() public view returns (uint256) {
        return count;
    }

    function onTransferOwnership(address, address) internal returns (bool) {
        return true;
    }
}

library SafeMathInt256 {
    // Signed ints with n bits can range from -2**(n-1) to (2**(n-1) - 1)
    int256 private constant INT256_MIN = -2**(255);
    int256 private constant INT256_MAX = (2**(255) - 1);

    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function div(int256 a, int256 b) internal pure returns (int256) {
        // No need to check for dividing by 0 -- Solidity automatically throws on division by 0
        int256 c = a / b;
        return c;
    }

    function sub(int256 a, int256 b) internal pure returns (int256) {
        require(((a >= 0) && (b >= a - INT256_MAX)) || ((a < 0) && (b <= a - INT256_MIN)));
        return a - b;
    }

    function add(int256 a, int256 b) internal pure returns (int256) {
        require(((a >= 0) && (b <= INT256_MAX - a)) || ((a < 0) && (b >= INT256_MIN - a)));
        return a + b;
    }

    function min(int256 a, int256 b) internal pure returns (int256) {
        if (a <= b) {
            return a;
        } else {
            return b;
        }
    }

    function max(int256 a, int256 b) internal pure returns (int256) {
        if (a >= b) {
            return a;
        } else {
            return b;
        }
    }

    function getInt256Min() internal pure returns (int256) {
        return INT256_MIN;
    }

    function getInt256Max() internal pure returns (int256) {
        return INT256_MAX;
    }

    // Float [fixed point] Operations
    function fxpMul(int256 a, int256 b, int256 base) internal pure returns (int256) {
        return div(mul(a, b), base);
    }

    function fxpDiv(int256 a, int256 b, int256 base) internal pure returns (int256) {
        return div(mul(a, base), b);
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

contract Market is DelegationTarget, ITyped, Initializable, Ownable, IMarket {
    using SafeMathUint256 for uint256;
    using SafeMathInt256 for int256;

    // Constants
    uint256 private constant MAX_FEE_PER_ETH_IN_ATTOETH = 1 ether / 2;
    uint256 private constant APPROVAL_AMOUNT = 2 ** 256 - 1;
    address private constant NULL_ADDRESS = address(0);
    uint256 private constant MIN_OUTCOMES = 2;
    uint256 private constant MAX_OUTCOMES = 8;

    // Contract Refs
    IUniverse private universe;
    IFeeWindow private feeWindow;
    ICash private cash;

    // Attributes
    uint256 private numTicks;
    uint256 private feeDivisor;
    uint256 private endTime;
    uint256 private numOutcomes;
    bytes32 private winningPayoutDistributionHash;
    uint256 private validityBondAttoeth;
    IMailbox private marketCreatorMailbox;
    uint256 private finalizationTime;

    // Collections
    IReportingParticipant[] public participants;
    Map public crowdsourcers;
    IShareToken[] private shareTokens;

    function initialize(IUniverse _universe, uint256 _endTime, uint256 _feePerEthInAttoeth, ICash _cash, address _designatedReporterAddress, address _creator, uint256 _numOutcomes, uint256 _numTicks) public onlyInGoodTimes payable beforeInitialized returns (bool _success) {
        endInitialization();
        require(MIN_OUTCOMES <= _numOutcomes && _numOutcomes <= MAX_OUTCOMES);
        require(_numTicks > 0);
        require(_designatedReporterAddress != NULL_ADDRESS);
        require((_numTicks >= _numOutcomes));
        require(_feePerEthInAttoeth <= MAX_FEE_PER_ETH_IN_ATTOETH);
        require(_creator != NULL_ADDRESS);
        require(controller.getTimestamp() < _endTime);
        require(address(_cash) == controller.lookup("Cash"));
        universe = _universe;
        require(!universe.isForking());
        owner = _creator;
        assessFees();
        endTime = _endTime;
        numOutcomes = _numOutcomes;
        numTicks = _numTicks;
        feeDivisor = _feePerEthInAttoeth == 0 ? 0 : 1 ether / _feePerEthInAttoeth;
        cash = _cash;
        InitialReporterFactory _initialReporterFactory = InitialReporterFactory(controller.lookup("InitialReporterFactory"));
        participants.push(_initialReporterFactory.createInitialReporter(controller, this, _designatedReporterAddress));
        marketCreatorMailbox = MailboxFactory(controller.lookup("MailboxFactory")).createMailbox(controller, owner, this);
        crowdsourcers = MapFactory(controller.lookup("MapFactory")).createMap(controller, this);
        for (uint256 _outcome = 0; _outcome < numOutcomes; _outcome++) {
            shareTokens.push(createShareToken(_outcome));
        }
        approveSpenders();
        // If the value was not at least equal to this fee this will throw. The addition here cannot overflow as these fees are capped
        uint256 _refund = msg.value.sub(validityBondAttoeth);
        if (_refund > 0) {
            owner.transfer(_refund);
        }
        return true;
    }

    function assessFees() private onlyInGoodTimes returns (bool) {
        require(getReputationToken().balanceOf(this) >= universe.getOrCacheDesignatedReportNoShowBond());
        validityBondAttoeth = universe.getOrCacheValidityBond();
        return true;
    }

    function createShareToken(uint256 _outcome) private onlyInGoodTimes returns (IShareToken) {
        return ShareTokenFactory(controller.lookup("ShareTokenFactory")).createShareToken(controller, this, _outcome);
    }

    // This will need to be called manually for each open market if a spender contract is updated
    function approveSpenders() public onlyInGoodTimes returns (bool) {
        bytes32[5] memory _names = [bytes32("CancelOrder"), bytes32("CompleteSets"), bytes32("FillOrder"), bytes32("TradingEscapeHatch"), bytes32("ClaimTradingProceeds")];
        for (uint256 i = 0; i < _names.length; i++) {
            require(cash.approve(controller.lookup(_names[i]), APPROVAL_AMOUNT));
        }
        for (uint256 j = 0; j < numOutcomes; j++) {
            require(shareTokens[j].approve(controller.lookup("FillOrder"), APPROVAL_AMOUNT));
        }
        return true;
    }

    function doInitialReport(uint256[] _payoutNumerators, bool _invalid) public onlyInGoodTimes returns (bool) {
        IInitialReporter _initialReporter = getInitialReporter();
        uint256 _timestamp = controller.getTimestamp();
        require(_initialReporter.getReportTimestamp() == 0);
        require(_timestamp > endTime);
        bool _isDesignatedReporter = msg.sender == _initialReporter.getDesignatedReporter();
        bool _designatedReportingExpired = _timestamp > getDesignatedReportingEndTime();
        require(_designatedReportingExpired || _isDesignatedReporter);
        distributeNoShowBond(_initialReporter, msg.sender);
        // The designated reporter must actually pay the required REP stake to report
        if (msg.sender == _initialReporter.getDesignatedReporter()) {
            IReputationToken _reputationToken = getReputationToken();
            _reputationToken.trustedMarketTransfer(msg.sender, _initialReporter, universe.getOrCacheDesignatedReportStake());
        }
        bytes32 _payoutDistributionHash = derivePayoutDistributionHash(_payoutNumerators, _invalid);
        feeWindow = universe.getOrCreateNextFeeWindow();
        _initialReporter.report(msg.sender, _payoutDistributionHash, _payoutNumerators, _invalid);
        controller.getAugur().logInitialReportSubmitted(universe, msg.sender, this, _initialReporter.getStake(), _isDesignatedReporter, _payoutNumerators, _invalid);
        return true;
    }

    function contribute(uint256[] _payoutNumerators, bool _invalid, uint256 _amount) public onlyInGoodTimes returns (bool) {
        require(feeWindow.isActive());
        require(!universe.isForking());
        bytes32 _payoutDistributionHash = derivePayoutDistributionHash(_payoutNumerators, _invalid);
        require(_payoutDistributionHash != getWinningReportingParticipant().getPayoutDistributionHash());
        IDisputeCrowdsourcer _crowdsourcer = getOrCreateDisputeCrowdsourcer(_payoutDistributionHash, _payoutNumerators, _invalid);
        uint256 _actualAmount = _crowdsourcer.contribute(msg.sender, _amount);
        controller.getAugur().logDisputeCrowdsourcerContribution(universe, msg.sender, this, _crowdsourcer, _actualAmount);
        if (_crowdsourcer.totalSupply() == _crowdsourcer.getSize()) {
            finishedCrowdsourcingDisputeBond(_crowdsourcer);
        }
        return true;
    }

    function finishedCrowdsourcingDisputeBond(IReportingParticipant _reportingParticipant) private returns (bool) {
        participants.push(_reportingParticipant);
        crowdsourcers = MapFactory(controller.lookup("MapFactory")).createMap(controller, this); // disavow other crowdsourcers
        if (IDisputeCrowdsourcer(_reportingParticipant).getSize() >= universe.getDisputeThresholdForFork()) {
            universe.fork();
        } else {
            feeWindow = universe.getOrCreateNextFeeWindow();
            // Participants is implicitly bounded by the floor of the initial report REP cost to be no more than 21
            for (uint256 i = 0; i < participants.length; i++) {
                participants[i].migrate();
            }
        }
        controller.getAugur().logDisputeCrowdsourcerCompleted(universe, this, _reportingParticipant);
        return true;
    }

    function finalize() public onlyInGoodTimes returns (bool) {
        if (universe.getForkingMarket() == this) {
            return finalizeFork();
        }

        require(winningPayoutDistributionHash == bytes32(0));

        require(getInitialReporter().getReportTimestamp() != 0);
        require(feeWindow.isOver());
        require(!universe.isForking());
        winningPayoutDistributionHash = participants[participants.length-1].getPayoutDistributionHash();
        feeWindow.onMarketFinalized();
        universe.decrementOpenInterestFromMarket(shareTokens[0].totalSupply().mul(numTicks));
        redistributeLosingReputation();
        distributeValidityBond();
        finalizationTime = controller.getTimestamp();
        controller.getAugur().logMarketFinalized(universe);
        return true;
    }

    function finalizeFork() public onlyInGoodTimes returns (bool) {
        require(universe.getForkingMarket() == this);
        require(winningPayoutDistributionHash == bytes32(0));
        IUniverse _winningUniverse = universe.getWinningChildUniverse();
        winningPayoutDistributionHash = _winningUniverse.getParentPayoutDistributionHash();
        finalizationTime = controller.getTimestamp();
        controller.getAugur().logMarketFinalized(universe);
        return true;
    }

    function redistributeLosingReputation() private returns (bool) {
        // If no disputes occured early exit
        if (participants.length == 1) {
            return true;
        }

        IReportingParticipant _reportingParticipant;

        // Initial pass is to liquidate losers so we have sufficient REP to pay the winners. Participants is implicitly bounded by the floor of the initial report REP cost to be no more than 21
        for (uint256 i = 0; i < participants.length; i++) {
            _reportingParticipant = participants[i];
            if (_reportingParticipant.getPayoutDistributionHash() != winningPayoutDistributionHash) {
                _reportingParticipant.liquidateLosing();
            }
        }

        IReputationToken _reputationToken = getReputationToken();

        // Now redistribute REP. Participants is implicitly bounded by the floor of the initial report REP cost to be no more than 21
        for (uint256 j = 0; j < participants.length; j++) {
            _reportingParticipant = participants[j];
            if (_reportingParticipant.getPayoutDistributionHash() == winningPayoutDistributionHash) {
                require(_reputationToken.transfer(_reportingParticipant, _reportingParticipant.getSize().div(2)));
            }
        }
        return true;
    }

    function distributeNoShowBond(IInitialReporter _initialReporter, address _reporter) private returns (bool) {
        IReputationToken _reputationToken = getReputationToken();
        uint256 _repBalance = _reputationToken.balanceOf(this);
        // If the designated reporter showed up return the no show bond to the market creator. Otherwise it will be used as stake in the first report.
        if (_reporter == _initialReporter.getDesignatedReporter()) {
            require(_reputationToken.transfer(owner, _repBalance));
        } else {
            require(_reputationToken.transfer(_initialReporter, _repBalance));
        }
        return true;
    }

    function getMarketCreatorSettlementFeeDivisor() public view returns (uint256) {
        return feeDivisor;
    }

    function deriveMarketCreatorFeeAmount(uint256 _amount) public view returns (uint256) {
        if (feeDivisor == 0) {
            return 0;
        }
        return _amount / feeDivisor;
    }

    function distributeValidityBond() private returns (bool) {
        // If the market resolved to invalid the bond gets sent to the fee window. Otherwise it gets returned to the market creator mailbox.
        if (!isInvalid()) {
            marketCreatorMailbox.depositEther.value(validityBondAttoeth)();
        } else {
            cash.depositEtherFor.value(validityBondAttoeth)(universe.getCurrentFeeWindow());
        }
        return true;
    }

    function getOrCreateDisputeCrowdsourcer(bytes32 _payoutDistributionHash, uint256[] _payoutNumerators, bool _invalid) private returns (IDisputeCrowdsourcer) {
        IDisputeCrowdsourcer _crowdsourcer = IDisputeCrowdsourcer(crowdsourcers.getAsAddressOrZero(_payoutDistributionHash));
        if (_crowdsourcer == IDisputeCrowdsourcer(0)) {
            uint256 _size = getParticipantStake().mul(2).sub(getStakeInOutcome(_payoutDistributionHash).mul(3));
            DisputeCrowdsourcerFactory _disputeCrowdsourcerFactory = DisputeCrowdsourcerFactory(controller.lookup("DisputeCrowdsourcerFactory"));
            _crowdsourcer = _disputeCrowdsourcerFactory.createDisputeCrowdsourcer(controller, this, _size, _payoutDistributionHash, _payoutNumerators, _invalid);
            crowdsourcers.add(_payoutDistributionHash, address(_crowdsourcer));
            controller.getAugur().disputeCrowdsourcerCreated(universe, this, _crowdsourcer, _payoutNumerators, _size, _invalid);
        }
        return _crowdsourcer;
    }

    function migrateThroughOneFork() public onlyInGoodTimes returns (bool) {
        // only proceed if the forking market is finalized
        IMarket _forkingMarket = universe.getForkingMarket();
        require(_forkingMarket.isFinalized());
        require(!isFinalized());

        IUniverse _currentUniverse = universe;
        bytes32 _winningForkPayoutDistributionHash = _forkingMarket.getWinningPayoutDistributionHash();
        IUniverse _destinationUniverse = _currentUniverse.getChildUniverse(_winningForkPayoutDistributionHash);

        uint256 _marketOI = shareTokens[0].totalSupply().mul(numTicks);

        universe.decrementOpenInterestFromMarket(_marketOI);

        // follow the forking market to its universe
        if (feeWindow != IFeeWindow(0)) {
            feeWindow = _destinationUniverse.getOrCreateNextFeeWindow();
        }
        _destinationUniverse.addMarketTo();
        _currentUniverse.removeMarketFrom();
        IReputationToken _oldReputationToken = getReputationToken();
        universe = _destinationUniverse;

        universe.incrementOpenInterestFromMarket(_marketOI);

        // reset state back to Initial Reporter
        IInitialReporter _initialParticipant = getInitialReporter();

        delete participants;
        participants.push(_initialParticipant);
        _initialParticipant.resetReportTimestamp();

        // Migrate REP
        _initialParticipant.migrateREP();
        IReputationToken _newReputationToken = getReputationToken();
        uint256 _balance = _oldReputationToken.balanceOf(this);
        if (_balance > 0) {
            _oldReputationToken.migrateOut(_newReputationToken, _balance);
        }

        // Disavow crowdsourcers
        crowdsourcers = MapFactory(controller.lookup("MapFactory")).createMap(controller, this);
        return true;
    }

    function disavowCrowdsourcers() public onlyInGoodTimes returns (bool) {
        require(universe.isForking());
        IMarket _forkingMarket = getForkingMarket();
        require(_forkingMarket != this);
        require(!isFinalized());
        IInitialReporter _initialParticipant = getInitialReporter();
        delete participants;
        participants.push(_initialParticipant);
        crowdsourcers = MapFactory(controller.lookup("MapFactory")).createMap(controller, this);
        controller.getAugur().logMarketParticipantsDisavowed(universe);
        return true;
    }

    function withdrawInEmergency() public onlyInBadTimes onlyOwner returns (bool) {
        IReputationToken _reputationToken = getReputationToken();
        uint256 _repBalance = _reputationToken.balanceOf(this);
        require(_reputationToken.transfer(msg.sender, _repBalance));
        if (this.balance > 0) {
            msg.sender.transfer(this.balance);
        }
        return true;
    }

    function getParticipantStake() public view returns (uint256) {
        uint256 _sum;
        // Participants is implicitly bounded by the floor of the initial report REP cost to be no more than 21
        for (uint256 i = 0; i < participants.length; ++i) {
            _sum += participants[i].getStake();
        }
        return _sum;
    }

    function getStakeInOutcome(bytes32 _payoutDistributionHash) public view returns (uint256) {
        uint256 _sum;
        // Participants is implicitly bounded by the floor of the initial report REP cost to be no more than 21
        for (uint256 i = 0; i < participants.length; ++i) {
            if (participants[i].getPayoutDistributionHash() != _payoutDistributionHash) {
                continue;
            }
            _sum += participants[i].getStake();
        }
        return _sum;
    }

    function getTypeName() public view returns (bytes32) {
        return "Market";
    }

    function getForkingMarket() public view returns (IMarket) {
        return universe.getForkingMarket();
    }

    function getWinningPayoutDistributionHash() public view returns (bytes32) {
        return winningPayoutDistributionHash;
    }

    function isFinalized() public view returns (bool) {
        return winningPayoutDistributionHash != bytes32(0);
    }

    function getDesignatedReporter() public view returns (address) {
        return getInitialReporter().getDesignatedReporter();
    }

    function designatedReporterShowed() public view returns (bool) {
        return getInitialReporter().designatedReporterShowed();
    }

    function designatedReporterWasCorrect() public view returns (bool) {
        return getInitialReporter().designatedReporterWasCorrect();
    }

    function getEndTime() public view returns (uint256) {
        return endTime;
    }

    function getMarketCreatorMailbox() public view returns (IMailbox) {
        return marketCreatorMailbox;
    }

    function isInvalid() public view returns (bool) {
        require(isFinalized());
        return getWinningReportingParticipant().isInvalid();
    }

    function getInitialReporter() public view returns (IInitialReporter) {
        return IInitialReporter(participants[0]);
    }

    function getInitialReporterAddress() public view returns (address) {
        return address(participants[0]);
    }

    function getReportingParticipant(uint256 _index) public view returns (IReportingParticipant) {
        return participants[_index];
    }

    function getCrowdsourcer(bytes32 _payoutDistributionHash) public view returns (IDisputeCrowdsourcer) {
        return  IDisputeCrowdsourcer(crowdsourcers.getAsAddressOrZero(_payoutDistributionHash));
    }

    function getWinningReportingParticipant() public view returns (IReportingParticipant) {
        return participants[participants.length-1];
    }

    function getWinningPayoutNumerator(uint256 _outcome) public view returns (uint256) {
        require(isFinalized());
        return getWinningReportingParticipant().getPayoutNumerator(_outcome);
    }

    function getUniverse() public view returns (IUniverse) {
        return universe;
    }

    function getFeeWindow() public view returns (IFeeWindow) {
        return feeWindow;
    }

    function getFinalizationTime() public view returns (uint256) {
        return finalizationTime;
    }

    function getReputationToken() public view returns (IReputationToken) {
        return universe.getReputationToken();
    }

    function getNumberOfOutcomes() public view returns (uint256) {
        return numOutcomes;
    }

    function getNumTicks() public view returns (uint256) {
        return numTicks;
    }

    function getDenominationToken() public view returns (ICash) {
        return cash;
    }

    function getShareToken(uint256 _outcome) public view returns (IShareToken) {
        return shareTokens[_outcome];
    }

    function getDesignatedReportingEndTime() public view returns (uint256) {
        return endTime.add(Reporting.getDesignatedReportingDurationSeconds());
    }

    function getNumParticipants() public view returns (uint256) {
        return participants.length;
    }

    function getValidityBondAttoeth() public view returns (uint256) {
        return validityBondAttoeth;
    }

    function derivePayoutDistributionHash(uint256[] _payoutNumerators, bool _invalid) public view returns (bytes32) {
        uint256 _sum = 0;
        uint256 _previousValue = _payoutNumerators[0];
        require(_payoutNumerators.length == numOutcomes);
        for (uint256 i = 0; i < _payoutNumerators.length; i++) {
            uint256 _value = _payoutNumerators[i];
            _sum = _sum.add(_value);
            require(!_invalid || _value == _previousValue);
            _previousValue = _value;
        }
        if (_invalid) {
            require(_previousValue == numTicks / numOutcomes);
        } else {
            require(_sum == numTicks);
        }
        return keccak256(_payoutNumerators, _invalid);
    }

    function isContainerForShareToken(IShareToken _shadyShareToken) public view returns (bool) {
        return getShareToken(_shadyShareToken.getOutcome()) == _shadyShareToken;
    }

    function isContainerForReportingParticipant(IReportingParticipant _shadyReportingParticipant) public view returns (bool) {
        if (crowdsourcers.getAsAddressOrZero(_shadyReportingParticipant.getPayoutDistributionHash()) == address(_shadyReportingParticipant)) {
            return true;
        }
        // Participants is implicitly bounded by the floor of the initial report REP cost to be no more than 21
        for (uint256 i = 0; i < participants.length; i++) {
            if (_shadyReportingParticipant == participants[i]) {
                return true;
            }
        }
        return false;
    }

    function onTransferOwnership(address _owner, address _newOwner) internal returns (bool) {
        controller.getAugur().logMarketTransferred(getUniverse(), _owner, _newOwner);
        return true;
    }

    function assertBalances() public view returns (bool) {
        // Escrowed funds for open orders
        uint256 _expectedBalance = IOrders(controller.lookup("Orders")).getTotalEscrowed(this);
        // Market Open Interest. If we&#39;re finalized we need actually calculate the value
        if (isFinalized()) {
            IReportingParticipant _winningReportingPartcipant = getWinningReportingParticipant();
            for (uint256 i = 0; i < numOutcomes; i++) {
                _expectedBalance = _expectedBalance.add(shareTokens[i].totalSupply().mul(_winningReportingPartcipant.getPayoutNumerator(i)));
            }
        } else {
            _expectedBalance = _expectedBalance.add(shareTokens[0].totalSupply().mul(numTicks));
        }

        assert(cash.balanceOf(this) >= _expectedBalance);
        return true;
    }
}

library Reporting {
    uint256 private constant DESIGNATED_REPORTING_DURATION_SECONDS = 3 days;
    uint256 private constant DISPUTE_ROUND_DURATION_SECONDS = 7 days;
    uint256 private constant CLAIM_PROCEEDS_WAIT_TIME = 3 days;
    uint256 private constant FORK_DURATION_SECONDS = 60 days;

    uint256 private constant INITIAL_REP_SUPPLY = 11 * 10 ** 6 * 10 ** 18; // 11 Million REP

    uint256 private constant DEFAULT_VALIDITY_BOND = 1 ether / 100;
    uint256 private constant VALIDITY_BOND_FLOOR = 1 ether / 100;
    uint256 private constant DEFAULT_REPORTING_FEE_DIVISOR = 100; // 1% fees
    uint256 private constant MAXIMUM_REPORTING_FEE_DIVISOR = 10000; // Minimum .01% fees
    uint256 private constant MINIMUM_REPORTING_FEE_DIVISOR = 3; // Maximum 33.3~% fees. Note than anything less than a value of 2 here will likely result in bugs such as divide by 0 cases.

    uint256 private constant TARGET_INVALID_MARKETS_DIVISOR = 100; // 1% of markets are expected to be invalid
    uint256 private constant TARGET_INCORRECT_DESIGNATED_REPORT_MARKETS_DIVISOR = 100; // 1% of markets are expected to have an incorrect designate report
    uint256 private constant TARGET_DESIGNATED_REPORT_NO_SHOWS_DIVISOR = 100; // 1% of markets are expected to have an incorrect designate report
    uint256 private constant TARGET_REP_MARKET_CAP_MULTIPLIER = 15; // We multiply and divide by constants since we want to multiply by a fractional amount (7.5)
    uint256 private constant TARGET_REP_MARKET_CAP_DIVISOR = 2;

    uint256 private constant FORK_MIGRATION_PERCENTAGE_BONUS_DIVISOR = 20; // 5% bonus to any REP migrated during a fork

    function getDesignatedReportingDurationSeconds() internal pure returns (uint256) { return DESIGNATED_REPORTING_DURATION_SECONDS; }
    function getDisputeRoundDurationSeconds() internal pure returns (uint256) { return DISPUTE_ROUND_DURATION_SECONDS; }
    function getClaimTradingProceedsWaitTime() internal pure returns (uint256) { return CLAIM_PROCEEDS_WAIT_TIME; }
    function getForkDurationSeconds() internal pure returns (uint256) { return FORK_DURATION_SECONDS; }
    function getDefaultValidityBond() internal pure returns (uint256) { return DEFAULT_VALIDITY_BOND; }
    function getValidityBondFloor() internal pure returns (uint256) { return VALIDITY_BOND_FLOOR; }
    function getTargetInvalidMarketsDivisor() internal pure returns (uint256) { return TARGET_INVALID_MARKETS_DIVISOR; }
    function getTargetIncorrectDesignatedReportMarketsDivisor() internal pure returns (uint256) { return TARGET_INCORRECT_DESIGNATED_REPORT_MARKETS_DIVISOR; }
    function getTargetDesignatedReportNoShowsDivisor() internal pure returns (uint256) { return TARGET_DESIGNATED_REPORT_NO_SHOWS_DIVISOR; }
    function getTargetRepMarketCapMultiplier() internal pure returns (uint256) { return TARGET_REP_MARKET_CAP_MULTIPLIER; }
    function getTargetRepMarketCapDivisor() internal pure returns (uint256) { return TARGET_REP_MARKET_CAP_DIVISOR; }
    function getForkMigrationPercentageBonusDivisor() internal pure returns (uint256) { return FORK_MIGRATION_PERCENTAGE_BONUS_DIVISOR; }
    function getMaximumReportingFeeDivisor() internal pure returns (uint256) { return MAXIMUM_REPORTING_FEE_DIVISOR; }
    function getMinimumReportingFeeDivisor() internal pure returns (uint256) { return MINIMUM_REPORTING_FEE_DIVISOR; }
    function getDefaultReportingFeeDivisor() internal pure returns (uint256) { return DEFAULT_REPORTING_FEE_DIVISOR; }
    function getInitialREPSupply() internal pure returns (uint256) { return INITIAL_REP_SUPPLY; }
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