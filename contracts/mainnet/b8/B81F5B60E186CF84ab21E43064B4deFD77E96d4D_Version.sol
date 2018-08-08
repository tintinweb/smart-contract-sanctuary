pragma solidity ^0.4.13;

contract DSAuthority {
    function canCall(
        address src, address dst, bytes4 sig
    ) public view returns (bool);
}

contract DSAuthEvents {
    event LogSetAuthority (address indexed authority);
    event LogSetOwner     (address indexed owner);
}

contract DSAuth is DSAuthEvents {
    DSAuthority  public  authority;
    address      public  owner;

    function DSAuth() public {
        owner = msg.sender;
        LogSetOwner(msg.sender);
    }

    function setOwner(address owner_)
        public
        auth
    {
        owner = owner_;
        LogSetOwner(owner);
    }

    function setAuthority(DSAuthority authority_)
        public
        auth
    {
        authority = authority_;
        LogSetAuthority(authority);
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig));
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (authority == DSAuthority(0)) {
            return false;
        } else {
            return authority.canCall(src, this, sig);
        }
    }
}

contract DSExec {
    function tryExec( address target, bytes calldata, uint value)
             internal
             returns (bool call_ret)
    {
        return target.call.value(value)(calldata);
    }
    function exec( address target, bytes calldata, uint value)
             internal
    {
        if(!tryExec(target, calldata, value)) {
            revert();
        }
    }

    // Convenience aliases
    function exec( address t, bytes c )
        internal
    {
        exec(t, c, 0);
    }
    function exec( address t, uint256 v )
        internal
    {
        bytes memory c; exec(t, c, v);
    }
    function tryExec( address t, bytes c )
        internal
        returns (bool)
    {
        return tryExec(t, c, 0);
    }
    function tryExec( address t, uint256 v )
        internal
        returns (bool)
    {
        bytes memory c; return tryExec(t, c, v);
    }
}

contract DSNote {
    event LogNote(
        bytes4   indexed  sig,
        address  indexed  guy,
        bytes32  indexed  foo,
        bytes32  indexed  bar,
        uint              wad,
        bytes             fax
    ) anonymous;

    modifier note {
        bytes32 foo;
        bytes32 bar;

        assembly {
            foo := calldataload(4)
            bar := calldataload(36)
        }

        LogNote(msg.sig, msg.sender, foo, bar, msg.value, msg.data);

        _;
    }
}

contract DSGroup is DSExec, DSNote {
    address[]  public  members;
    uint       public  quorum;
    uint       public  window;
    uint       public  actionCount;

    mapping (uint => Action)                     public  actions;
    mapping (uint => mapping (address => bool))  public  confirmedBy;
    mapping (address => bool)                    public  isMember;

    // Legacy events
    event Proposed   (uint id, bytes calldata);
    event Confirmed  (uint id, address member);
    event Triggered  (uint id);

    struct Action {
        address  target;
        bytes    calldata;
        uint     value;

        uint     confirmations;
        uint     deadline;
        bool     triggered;
    }

    function DSGroup(
        address[]  members_,
        uint       quorum_,
        uint       window_
    ) {
        members  = members_;
        quorum   = quorum_;
        window   = window_;

        for (uint i = 0; i < members.length; i++) {
            isMember[members[i]] = true;
        }
    }

    function memberCount() constant returns (uint) {
        return members.length;
    }

    function target(uint id) constant returns (address) {
        return actions[id].target;
    }
    function calldata(uint id) constant returns (bytes) {
        return actions[id].calldata;
    }
    function value(uint id) constant returns (uint) {
        return actions[id].value;
    }

    function confirmations(uint id) constant returns (uint) {
        return actions[id].confirmations;
    }
    function deadline(uint id) constant returns (uint) {
        return actions[id].deadline;
    }
    function triggered(uint id) constant returns (bool) {
        return actions[id].triggered;
    }

    function confirmed(uint id) constant returns (bool) {
        return confirmations(id) >= quorum;
    }
    function expired(uint id) constant returns (bool) {
        return now > deadline(id);
    }

    function deposit() note payable {
    }

    function propose(
        address  target,
        bytes    calldata,
        uint     value
    ) onlyMembers note returns (uint id) {
        id = ++actionCount;

        actions[id].target    = target;
        actions[id].calldata  = calldata;
        actions[id].value     = value;
        actions[id].deadline  = now + window;

        Proposed(id, calldata);
    }

    function confirm(uint id) onlyMembers onlyActive(id) note {
        assert(!confirmedBy[id][msg.sender]);

        confirmedBy[id][msg.sender] = true;
        actions[id].confirmations++;

        Confirmed(id, msg.sender);
    }

    function trigger(uint id) onlyMembers onlyActive(id) note {
        assert(confirmed(id));

        actions[id].triggered = true;
        exec(actions[id].target, actions[id].calldata, actions[id].value);

        Triggered(id);
    }

    modifier onlyMembers {
        assert(isMember[msg.sender]);
        _;
    }

    modifier onlyActive(uint id) {
        assert(!expired(id));
        assert(!triggered(id));
        _;
    }

    //------------------------------------------------------------------
    // Legacy functions
    //------------------------------------------------------------------

    function getInfo() constant returns (
        uint  quorum_,
        uint  memberCount,
        uint  window_,
        uint  actionCount_
    ) {
        return (quorum, members.length, window, actionCount);
    }

    function getActionStatus(uint id) constant returns (
        uint     confirmations,
        uint     deadline,
        bool     triggered,
        address  target,
        uint     value
    ) {
        return (
            actions[id].confirmations,
            actions[id].deadline,
            actions[id].triggered,
            actions[id].target,
            actions[id].value
        );
    }
}

contract DSGroupFactory is DSNote {
    mapping (address => bool)  public  isGroup;

    function newGroup(
        address[]  members,
        uint       quorum,
        uint       window
    ) note returns (DSGroup group) {
        group = new DSGroup(members, quorum, window);
        isGroup[group] = true;
    }
}

contract DSMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }
    function imin(int x, int y) internal pure returns (int z) {
        return x <= y ? x : y;
    }
    function imax(int x, int y) internal pure returns (int z) {
        return x >= y ? x : y;
    }

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It&#39;s O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    function rpow(uint x, uint n) internal pure returns (uint z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}

contract DSThing is DSAuth, DSNote, DSMath {

    function S(string s) internal pure returns (bytes4) {
        return bytes4(keccak256(s));
    }

}

contract WETH9_ {
    string public name     = "Wrapped Ether";
    string public symbol   = "WETH";
    uint8  public decimals = 18;

    event  Approval(address indexed src, address indexed guy, uint wad);
    event  Transfer(address indexed src, address indexed dst, uint wad);
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);

    mapping (address => uint)                       public  balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;

    function() public payable {
        deposit();
    }
    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        Deposit(msg.sender, msg.value);
    }
    function withdraw(uint wad) public {
        require(balanceOf[msg.sender] >= wad);
        balanceOf[msg.sender] -= wad;
        msg.sender.transfer(wad);
        Withdrawal(msg.sender, wad);
    }

    function totalSupply() public view returns (uint) {
        return this.balance;
    }

    function approve(address guy, uint wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad)
        public
        returns (bool)
    {
        require(balanceOf[src] >= wad);

        if (src != msg.sender && allowance[src][msg.sender] != uint(-1)) {
            require(allowance[src][msg.sender] >= wad);
            allowance[src][msg.sender] -= wad;
        }

        balanceOf[src] -= wad;
        balanceOf[dst] += wad;

        Transfer(src, dst, wad);

        return true;
    }
}

interface FundInterface {

    // EVENTS

    event PortfolioContent(address[] assets, uint[] holdings, uint[] prices);
    event RequestUpdated(uint id);
    event Redeemed(address indexed ofParticipant, uint atTimestamp, uint shareQuantity);
    event FeesConverted(uint atTimestamp, uint shareQuantityConverted, uint unclaimed);
    event CalculationUpdate(uint atTimestamp, uint managementFee, uint performanceFee, uint nav, uint sharePrice, uint totalSupply);
    event ErrorMessage(string errorMessage);

    // EXTERNAL METHODS
    // Compliance by Investor
    function requestInvestment(uint giveQuantity, uint shareQuantity, address investmentAsset) external;
    function executeRequest(uint requestId) external;
    function cancelRequest(uint requestId) external;
    function redeemAllOwnedAssets(uint shareQuantity) external returns (bool);
    // Administration by Manager
    function enableInvestment(address[] ofAssets) external;
    function disableInvestment(address[] ofAssets) external;
    function shutDown() external;

    // PUBLIC METHODS
    function emergencyRedeem(uint shareQuantity, address[] requestedAssets) public returns (bool success);
    function calcSharePriceAndAllocateFees() public returns (uint);


    // PUBLIC VIEW METHODS
    // Get general information
    function getModules() view returns (address, address, address);
    function getLastRequestId() view returns (uint);
    function getManager() view returns (address);

    // Get accounting information
    function performCalculations() view returns (uint, uint, uint, uint, uint, uint, uint);
    function calcSharePrice() view returns (uint);
}

interface AssetInterface {
    /*
     * Implements ERC 20 standard.
     * https://github.com/ethereum/EIPs/blob/f90864a3d2b2b45c4decf95efd26b3f0c276051a/EIPS/eip-20-token-standard.md
     * https://github.com/ethereum/EIPs/issues/20
     *
     *  Added support for the ERC 223 "tokenFallback" method in a "transfer" function with a payload.
     *  https://github.com/ethereum/EIPs/issues/223
     */

    // Events
    event Approval(address indexed _owner, address indexed _spender, uint _value);

    // There is no ERC223 compatible Transfer event, with `_data` included.

    //ERC 223
    // PUBLIC METHODS
    function transfer(address _to, uint _value, bytes _data) public returns (bool success);

    // ERC 20
    // PUBLIC METHODS
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);
    function approve(address _spender, uint _value) public returns (bool success);
    // PUBLIC VIEW METHODS
    function balanceOf(address _owner) view public returns (uint balance);
    function allowance(address _owner, address _spender) public view returns (uint remaining);
}

contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Asset is DSMath, ERC20Interface {

    // DATA STRUCTURES

    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;
    uint public _totalSupply;

    // PUBLIC METHODS

    /**
     * @notice Send `_value` tokens to `_to` from `msg.sender`
     * @dev Transfers sender&#39;s tokens to a given address
     * @dev Similar to transfer(address, uint, bytes), but without _data parameter
     * @param _to Address of token receiver
     * @param _value Number of tokens to transfer
     * @return Returns success of function call
     */
    function transfer(address _to, uint _value)
        public
        returns (bool success)
    {
        require(balances[msg.sender] >= _value); // sanity checks
        require(balances[_to] + _value >= balances[_to]);

        balances[msg.sender] = sub(balances[msg.sender], _value);
        balances[_to] = add(balances[_to], _value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    /// @notice Transfer `_value` tokens from `_from` to `_to` if `msg.sender` is allowed.
    /// @notice Restriction: An account can only use this function to send to itself
    /// @dev Allows for an approved third party to transfer tokens from one
    /// address to another. Returns success.
    /// @param _from Address from where tokens are withdrawn.
    /// @param _to Address to where tokens are sent.
    /// @param _value Number of tokens to transfer.
    /// @return Returns success of function call.
    function transferFrom(address _from, address _to, uint _value)
        public
        returns (bool)
    {
        require(_from != address(0));
        require(_to != address(0));
        require(_to != address(this));
        require(balances[_from] >= _value);
        require(allowed[_from][msg.sender] >= _value);
        require(balances[_to] + _value >= balances[_to]);
        // require(_to == msg.sender); // can only use transferFrom to send to self

        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);
        return true;
    }

    /// @notice Allows `_spender` to transfer `_value` tokens from `msg.sender` to any address.
    /// @dev Sets approved amount of tokens for spender. Returns success.
    /// @param _spender Address of allowed account.
    /// @param _value Number of approved tokens.
    /// @return Returns success of function call.
    function approve(address _spender, uint _value) public returns (bool) {
        require(_spender != address(0));

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    // PUBLIC VIEW METHODS

    /// @dev Returns number of allowed tokens that a spender can transfer on
    /// behalf of a token owner.
    /// @param _owner Address of token owner.
    /// @param _spender Address of token spender.
    /// @return Returns remaining allowance for spender.
    function allowance(address _owner, address _spender)
        constant
        public
        returns (uint)
    {
        return allowed[_owner][_spender];
    }

    /// @dev Returns number of tokens owned by the given address.
    /// @param _owner Address of token owner.
    /// @return Returns balance of owner.
    function balanceOf(address _owner) constant public returns (uint) {
        return balances[_owner];
    }

    function totalSupply() view public returns (uint) {
        return _totalSupply;
    }
}

interface SharesInterface {

    event Created(address indexed ofParticipant, uint atTimestamp, uint shareQuantity);
    event Annihilated(address indexed ofParticipant, uint atTimestamp, uint shareQuantity);

    // VIEW METHODS

    function getName() view returns (bytes32);
    function getSymbol() view returns (bytes8);
    function getDecimals() view returns (uint);
    function getCreationTime() view returns (uint);
    function toSmallestShareUnit(uint quantity) view returns (uint);
    function toWholeShareUnit(uint quantity) view returns (uint);

}

contract Shares is SharesInterface, Asset {

    // FIELDS

    // Constructor fields
    bytes32 public name;
    bytes8 public symbol;
    uint public decimal;
    uint public creationTime;

    // METHODS

    // CONSTRUCTOR

    /// @param _name Name these shares
    /// @param _symbol Symbol of shares
    /// @param _decimal Amount of decimals sharePrice is denominated in, defined to be equal as deciamls in REFERENCE_ASSET contract
    /// @param _creationTime Timestamp of share creation
    function Shares(bytes32 _name, bytes8 _symbol, uint _decimal, uint _creationTime) {
        name = _name;
        symbol = _symbol;
        decimal = _decimal;
        creationTime = _creationTime;
    }

    // PUBLIC METHODS

    /**
     * @notice Send `_value` tokens to `_to` from `msg.sender`
     * @dev Transfers sender&#39;s tokens to a given address
     * @dev Similar to transfer(address, uint, bytes), but without _data parameter
     * @param _to Address of token receiver
     * @param _value Number of tokens to transfer
     * @return Returns success of function call
     */
    function transfer(address _to, uint _value)
        public
        returns (bool success)
    {
        require(balances[msg.sender] >= _value); // sanity checks
        require(balances[_to] + _value >= balances[_to]);

        balances[msg.sender] = sub(balances[msg.sender], _value);
        balances[_to] = add(balances[_to], _value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    // PUBLIC VIEW METHODS

    function getName() view returns (bytes32) { return name; }
    function getSymbol() view returns (bytes8) { return symbol; }
    function getDecimals() view returns (uint) { return decimal; }
    function getCreationTime() view returns (uint) { return creationTime; }
    function toSmallestShareUnit(uint quantity) view returns (uint) { return mul(quantity, 10 ** getDecimals()); }
    function toWholeShareUnit(uint quantity) view returns (uint) { return quantity / (10 ** getDecimals()); }

    // INTERNAL METHODS

    /// @param recipient Address the new shares should be sent to
    /// @param shareQuantity Number of shares to be created
    function createShares(address recipient, uint shareQuantity) internal {
        _totalSupply = add(_totalSupply, shareQuantity);
        balances[recipient] = add(balances[recipient], shareQuantity);
        emit Created(msg.sender, now, shareQuantity);
        emit Transfer(address(0), recipient, shareQuantity);
    }

    /// @param recipient Address the new shares should be taken from when destroyed
    /// @param shareQuantity Number of shares to be annihilated
    function annihilateShares(address recipient, uint shareQuantity) internal {
        _totalSupply = sub(_totalSupply, shareQuantity);
        balances[recipient] = sub(balances[recipient], shareQuantity);
        emit Annihilated(msg.sender, now, shareQuantity);
        emit Transfer(recipient, address(0), shareQuantity);
    }
}

interface CompetitionInterface {

    // EVENTS

    event Register(uint withId, address fund, address manager);
    event ClaimReward(address registrant, address fund, uint shares);

    // PRE, POST, INVARIANT CONDITIONS

    function termsAndConditionsAreSigned(address byManager, uint8 v, bytes32 r, bytes32 s) view returns (bool);
    function isWhitelisted(address x) view returns (bool);
    function isCompetitionActive() view returns (bool);

    // CONSTANT METHODS

    function getMelonAsset() view returns (address);
    function getRegistrantId(address x) view returns (uint);
    function getRegistrantFund(address x) view returns (address);
    function getCompetitionStatusOfRegistrants() view returns (address[], address[], bool[]);
    function getTimeTillEnd() view returns (uint);
    function getEtherValue(uint amount) view returns (uint);
    function calculatePayout(uint payin) view returns (uint);

    // PUBLIC METHODS

    function registerForCompetition(address fund, uint8 v, bytes32 r, bytes32 s) payable;
    function batchAddToWhitelist(uint maxBuyinQuantity, address[] whitelistants);
    function withdrawMln(address to, uint amount);
    function claimReward();

}

interface ComplianceInterface {

    // PUBLIC VIEW METHODS

    /// @notice Checks whether investment is permitted for a participant
    /// @param ofParticipant Address requesting to invest in a Melon fund
    /// @param giveQuantity Quantity of Melon token times 10 ** 18 offered to receive shareQuantity
    /// @param shareQuantity Quantity of shares times 10 ** 18 requested to be received
    /// @return Whether identity is eligible to invest in a Melon fund.
    function isInvestmentPermitted(
        address ofParticipant,
        uint256 giveQuantity,
        uint256 shareQuantity
    ) view returns (bool);

    /// @notice Checks whether redemption is permitted for a participant
    /// @param ofParticipant Address requesting to redeem from a Melon fund
    /// @param shareQuantity Quantity of shares times 10 ** 18 offered to redeem
    /// @param receiveQuantity Quantity of Melon token times 10 ** 18 requested to receive for shareQuantity
    /// @return Whether identity is eligible to redeem from a Melon fund.
    function isRedemptionPermitted(
        address ofParticipant,
        uint256 shareQuantity,
        uint256 receiveQuantity
    ) view returns (bool);
}

contract DBC {

    // MODIFIERS

    modifier pre_cond(bool condition) {
        require(condition);
        _;
    }

    modifier post_cond(bool condition) {
        _;
        assert(condition);
    }

    modifier invariant(bool condition) {
        require(condition);
        _;
        assert(condition);
    }
}

contract Owned is DBC {

    // FIELDS

    address public owner;

    // NON-CONSTANT METHODS

    function Owned() { owner = msg.sender; }

    function changeOwner(address ofNewOwner) pre_cond(isOwner()) { owner = ofNewOwner; }

    // PRE, POST, INVARIANT CONDITIONS

    function isOwner() internal returns (bool) { return msg.sender == owner; }

}

contract Fund is DSMath, DBC, Owned, Shares, FundInterface {

    event OrderUpdated(address exchange, bytes32 orderId, UpdateType updateType);

    // TYPES

    struct Modules { // Describes all modular parts, standardised through an interface
        CanonicalPriceFeed pricefeed; // Provides all external data
        ComplianceInterface compliance; // Boolean functions regarding invest/redeem
        RiskMgmtInterface riskmgmt; // Boolean functions regarding make/take orders
    }

    struct Calculations { // List of internal calculations
        uint gav; // Gross asset value
        uint managementFee; // Time based fee
        uint performanceFee; // Performance based fee measured against QUOTE_ASSET
        uint unclaimedFees; // Fees not yet allocated to the fund manager
        uint nav; // Net asset value
        uint highWaterMark; // A record of best all-time fund performance
        uint totalSupply; // Total supply of shares
        uint timestamp; // Time when calculations are performed in seconds
    }

    enum UpdateType { make, take, cancel }
    enum RequestStatus { active, cancelled, executed }
    struct Request { // Describes and logs whenever asset enter and leave fund due to Participants
        address participant; // Participant in Melon fund requesting investment or redemption
        RequestStatus status; // Enum: active, cancelled, executed; Status of request
        address requestAsset; // Address of the asset being requested
        uint shareQuantity; // Quantity of Melon fund shares
        uint giveQuantity; // Quantity in Melon asset to give to Melon fund to receive shareQuantity
        uint receiveQuantity; // Quantity in Melon asset to receive from Melon fund for given shareQuantity
        uint timestamp;     // Time of request creation in seconds
        uint atUpdateId;    // Pricefeed updateId when this request was created
    }

    struct Exchange {
        address exchange;
        address exchangeAdapter;
        bool takesCustody;  // exchange takes custody before making order
    }

    struct OpenMakeOrder {
        uint id; // Order Id from exchange
        uint expiresAt; // Timestamp when the order expires
    }

    struct Order { // Describes an order event (make or take order)
        address exchangeAddress; // address of the exchange this order is on
        bytes32 orderId; // Id as returned from exchange
        UpdateType updateType; // Enum: make, take (cancel should be ignored)
        address makerAsset; // Order maker&#39;s asset
        address takerAsset; // Order taker&#39;s asset
        uint makerQuantity; // Quantity of makerAsset to be traded
        uint takerQuantity; // Quantity of takerAsset to be traded
        uint timestamp; // Time of order creation in seconds
        uint fillTakerQuantity; // Quantity of takerAsset to be filled
    }

    // FIELDS

    // Constant fields
    uint public constant MAX_FUND_ASSETS = 20; // Max ownable assets by the fund supported by gas limits
    uint public constant ORDER_EXPIRATION_TIME = 86400; // Make order expiration time (1 day)
    // Constructor fields
    uint public MANAGEMENT_FEE_RATE; // Fee rate in QUOTE_ASSET per managed seconds in WAD
    uint public PERFORMANCE_FEE_RATE; // Fee rate in QUOTE_ASSET per delta improvement in WAD
    address public VERSION; // Address of Version contract
    Asset public QUOTE_ASSET; // QUOTE asset as ERC20 contract
    // Methods fields
    Modules public modules; // Struct which holds all the initialised module instances
    Exchange[] public exchanges; // Array containing exchanges this fund supports
    Calculations public atLastUnclaimedFeeAllocation; // Calculation results at last allocateUnclaimedFees() call
    Order[] public orders;  // append-only list of makes/takes from this fund
    mapping (address => mapping(address => OpenMakeOrder)) public exchangesToOpenMakeOrders; // exchangeIndex to: asset to open make orders
    bool public isShutDown; // Security feature, if yes than investing, managing, allocateUnclaimedFees gets blocked
    Request[] public requests; // All the requests this fund received from participants
    mapping (address => bool) public isInvestAllowed; // If false, fund rejects investments from the key asset
    address[] public ownedAssets; // List of all assets owned by the fund or for which the fund has open make orders
    mapping (address => bool) public isInAssetList; // Mapping from asset to whether the asset exists in ownedAssets
    mapping (address => bool) public isInOpenMakeOrder; // Mapping from asset to whether the asset is in a open make order as buy asset

    // METHODS

    // CONSTRUCTOR

    /// @dev Should only be called via Version.setupFund(..)
    /// @param withName human-readable descriptive name (not necessarily unique)
    /// @param ofQuoteAsset Asset against which mgmt and performance fee is measured against and which can be used to invest using this single asset
    /// @param ofManagementFee A time based fee expressed, given in a number which is divided by 1 WAD
    /// @param ofPerformanceFee A time performance based fee, performance relative to ofQuoteAsset, given in a number which is divided by 1 WAD
    /// @param ofCompliance Address of compliance module
    /// @param ofRiskMgmt Address of risk management module
    /// @param ofPriceFeed Address of price feed module
    /// @param ofExchanges Addresses of exchange on which this fund can trade
    /// @param ofDefaultAssets Addresses of assets to enable invest for (quote asset is already enabled)
    /// @return Deployed Fund with manager set as ofManager
    function Fund(
        address ofManager,
        bytes32 withName,
        address ofQuoteAsset,
        uint ofManagementFee,
        uint ofPerformanceFee,
        address ofCompliance,
        address ofRiskMgmt,
        address ofPriceFeed,
        address[] ofExchanges,
        address[] ofDefaultAssets
    )
        Shares(withName, "MLNF", 18, now)
    {
        require(ofManagementFee < 10 ** 18); // Require management fee to be less than 100 percent
        require(ofPerformanceFee < 10 ** 18); // Require performance fee to be less than 100 percent
        isInvestAllowed[ofQuoteAsset] = true;
        owner = ofManager;
        MANAGEMENT_FEE_RATE = ofManagementFee; // 1 percent is expressed as 0.01 * 10 ** 18
        PERFORMANCE_FEE_RATE = ofPerformanceFee; // 1 percent is expressed as 0.01 * 10 ** 18
        VERSION = msg.sender;
        modules.compliance = ComplianceInterface(ofCompliance);
        modules.riskmgmt = RiskMgmtInterface(ofRiskMgmt);
        modules.pricefeed = CanonicalPriceFeed(ofPriceFeed);
        // Bridged to Melon exchange interface by exchangeAdapter library
        for (uint i = 0; i < ofExchanges.length; ++i) {
            require(modules.pricefeed.exchangeIsRegistered(ofExchanges[i]));
            var (ofExchangeAdapter, takesCustody, ) = modules.pricefeed.getExchangeInformation(ofExchanges[i]);
            exchanges.push(Exchange({
                exchange: ofExchanges[i],
                exchangeAdapter: ofExchangeAdapter,
                takesCustody: takesCustody
            }));
        }
        QUOTE_ASSET = Asset(ofQuoteAsset);
        // Quote Asset always in owned assets list
        ownedAssets.push(ofQuoteAsset);
        isInAssetList[ofQuoteAsset] = true;
        require(address(QUOTE_ASSET) == modules.pricefeed.getQuoteAsset()); // Sanity check
        for (uint j = 0; j < ofDefaultAssets.length; j++) {
            require(modules.pricefeed.assetIsRegistered(ofDefaultAssets[j]));
            isInvestAllowed[ofDefaultAssets[j]] = true;
        }
        atLastUnclaimedFeeAllocation = Calculations({
            gav: 0,
            managementFee: 0,
            performanceFee: 0,
            unclaimedFees: 0,
            nav: 0,
            highWaterMark: 10 ** getDecimals(),
            totalSupply: _totalSupply,
            timestamp: now
        });
    }

    // EXTERNAL METHODS

    // EXTERNAL : ADMINISTRATION

    /// @notice Enable investment in specified assets
    /// @param ofAssets Array of assets to enable investment in
    function enableInvestment(address[] ofAssets)
        external
        pre_cond(isOwner())
    {
        for (uint i = 0; i < ofAssets.length; ++i) {
            require(modules.pricefeed.assetIsRegistered(ofAssets[i]));
            isInvestAllowed[ofAssets[i]] = true;
        }
    }

    /// @notice Disable investment in specified assets
    /// @param ofAssets Array of assets to disable investment in
    function disableInvestment(address[] ofAssets)
        external
        pre_cond(isOwner())
    {
        for (uint i = 0; i < ofAssets.length; ++i) {
            isInvestAllowed[ofAssets[i]] = false;
        }
    }

    function shutDown() external pre_cond(msg.sender == VERSION) { isShutDown = true; }

    // EXTERNAL : PARTICIPATION

    /// @notice Give melon tokens to receive shares of this fund
    /// @dev Recommended to give some leeway in prices to account for possibly slightly changing prices
    /// @param giveQuantity Quantity of Melon token times 10 ** 18 offered to receive shareQuantity
    /// @param shareQuantity Quantity of shares times 10 ** 18 requested to be received
    /// @param investmentAsset Address of asset to invest in
    function requestInvestment(
        uint giveQuantity,
        uint shareQuantity,
        address investmentAsset
    )
        external
        pre_cond(!isShutDown)
        pre_cond(isInvestAllowed[investmentAsset]) // investment using investmentAsset has not been deactivated by the Manager
        pre_cond(modules.compliance.isInvestmentPermitted(msg.sender, giveQuantity, shareQuantity))    // Compliance Module: Investment permitted
    {
        requests.push(Request({
            participant: msg.sender,
            status: RequestStatus.active,
            requestAsset: investmentAsset,
            shareQuantity: shareQuantity,
            giveQuantity: giveQuantity,
            receiveQuantity: shareQuantity,
            timestamp: now,
            atUpdateId: modules.pricefeed.getLastUpdateId()
        }));

        emit RequestUpdated(getLastRequestId());
    }

    /// @notice Executes active investment and redemption requests, in a way that minimises information advantages of investor
    /// @dev Distributes melon and shares according to the request
    /// @param id Index of request to be executed
    /// @dev Active investment or redemption request executed
    function executeRequest(uint id)
        external
        pre_cond(!isShutDown)
        pre_cond(requests[id].status == RequestStatus.active)
        pre_cond(
            _totalSupply == 0 ||
            (
                now >= add(requests[id].timestamp, modules.pricefeed.getInterval()) &&
                modules.pricefeed.getLastUpdateId() >= add(requests[id].atUpdateId, 2)
            )
        )   // PriceFeed Module: Wait at least one interval time and two updates before continuing (unless it is the first investment)

    {
        Request request = requests[id];
        var (isRecent, , ) =
            modules.pricefeed.getPriceInfo(address(request.requestAsset));
        require(isRecent);

        // sharePrice quoted in QUOTE_ASSET and multiplied by 10 ** fundDecimals
        uint costQuantity = toWholeShareUnit(mul(request.shareQuantity, calcSharePriceAndAllocateFees())); // By definition quoteDecimals == fundDecimals
        if (request.requestAsset != address(QUOTE_ASSET)) {
            var (isPriceRecent, invertedRequestAssetPrice, requestAssetDecimal) = modules.pricefeed.getInvertedPriceInfo(request.requestAsset);
            if (!isPriceRecent) {
                revert();
            }
            costQuantity = mul(costQuantity, invertedRequestAssetPrice) / 10 ** requestAssetDecimal;
        }

        if (
            isInvestAllowed[request.requestAsset] &&
            costQuantity <= request.giveQuantity
        ) {
            request.status = RequestStatus.executed;
            require(AssetInterface(request.requestAsset).transferFrom(request.participant, address(this), costQuantity)); // Allocate Value
            createShares(request.participant, request.shareQuantity); // Accounting
            if (!isInAssetList[request.requestAsset]) {
                ownedAssets.push(request.requestAsset);
                isInAssetList[request.requestAsset] = true;
            }
        } else {
            revert(); // Invalid Request or invalid giveQuantity / receiveQuantity
        }
    }

    /// @notice Cancels active investment and redemption requests
    /// @param id Index of request to be executed
    function cancelRequest(uint id)
        external
        pre_cond(requests[id].status == RequestStatus.active) // Request is active
        pre_cond(requests[id].participant == msg.sender || isShutDown) // Either request creator or fund is shut down
    {
        requests[id].status = RequestStatus.cancelled;
    }

    /// @notice Redeems by allocating an ownership percentage of each asset to the participant
    /// @dev Independent of running price feed!
    /// @param shareQuantity Number of shares owned by the participant, which the participant would like to redeem for individual assets
    /// @return Whether all assets sent to shareholder or not
    function redeemAllOwnedAssets(uint shareQuantity)
        external
        returns (bool success)
    {
        return emergencyRedeem(shareQuantity, ownedAssets);
    }

    // EXTERNAL : MANAGING

    /// @notice Universal method for calling exchange functions through adapters
    /// @notice See adapter contracts for parameters needed for each exchange
    /// @param exchangeIndex Index of the exchange in the "exchanges" array
    /// @param method Signature of the adapter method to call (as per ABI spec)
    /// @param orderAddresses [0] Order maker
    /// @param orderAddresses [1] Order taker
    /// @param orderAddresses [2] Order maker asset
    /// @param orderAddresses [3] Order taker asset
    /// @param orderAddresses [4] Fee recipient
    /// @param orderValues [0] Maker token quantity
    /// @param orderValues [1] Taker token quantity
    /// @param orderValues [2] Maker fee
    /// @param orderValues [3] Taker fee
    /// @param orderValues [4] Timestamp (seconds)
    /// @param orderValues [5] Salt/nonce
    /// @param orderValues [6] Fill amount: amount of taker token to be traded
    /// @param orderValues [7] Dexy signature mode
    /// @param identifier Order identifier
    /// @param v ECDSA recovery id
    /// @param r ECDSA signature output r
    /// @param s ECDSA signature output s
    function callOnExchange(
        uint exchangeIndex,
        bytes4 method,
        address[5] orderAddresses,
        uint[8] orderValues,
        bytes32 identifier,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
    {
        require(modules.pricefeed.exchangeMethodIsAllowed(
            exchanges[exchangeIndex].exchange, method
        ));
        require((exchanges[exchangeIndex].exchangeAdapter).delegatecall(
            method, exchanges[exchangeIndex].exchange,
            orderAddresses, orderValues, identifier, v, r, s
        ));
    }

    function addOpenMakeOrder(
        address ofExchange,
        address ofSellAsset,
        uint orderId
    )
        pre_cond(msg.sender == address(this))
    {
        isInOpenMakeOrder[ofSellAsset] = true;
        exchangesToOpenMakeOrders[ofExchange][ofSellAsset].id = orderId;
        exchangesToOpenMakeOrders[ofExchange][ofSellAsset].expiresAt = add(now, ORDER_EXPIRATION_TIME);
    }

    function removeOpenMakeOrder(
        address ofExchange,
        address ofSellAsset
    )
        pre_cond(msg.sender == address(this))
    {
        delete exchangesToOpenMakeOrders[ofExchange][ofSellAsset];
    }

    function orderUpdateHook(
        address ofExchange,
        bytes32 orderId,
        UpdateType updateType,
        address[2] orderAddresses, // makerAsset, takerAsset
        uint[3] orderValues        // makerQuantity, takerQuantity, fillTakerQuantity (take only)
    )
        pre_cond(msg.sender == address(this))
    {
        // only save make/take
        if (updateType == UpdateType.make || updateType == UpdateType.take) {
            orders.push(Order({
                exchangeAddress: ofExchange,
                orderId: orderId,
                updateType: updateType,
                makerAsset: orderAddresses[0],
                takerAsset: orderAddresses[1],
                makerQuantity: orderValues[0],
                takerQuantity: orderValues[1],
                timestamp: block.timestamp,
                fillTakerQuantity: orderValues[2]
            }));
        }
        emit OrderUpdated(ofExchange, orderId, updateType);
    }

    // PUBLIC METHODS

    // PUBLIC METHODS : ACCOUNTING

    /// @notice Calculates gross asset value of the fund
    /// @dev Decimals in assets must be equal to decimals in PriceFeed for all entries in AssetRegistrar
    /// @dev Assumes that module.pricefeed.getPriceInfo(..) returns recent prices
    /// @return gav Gross asset value quoted in QUOTE_ASSET and multiplied by 10 ** shareDecimals
    function calcGav() returns (uint gav) {
        // prices quoted in QUOTE_ASSET and multiplied by 10 ** assetDecimal
        uint[] memory allAssetHoldings = new uint[](ownedAssets.length);
        uint[] memory allAssetPrices = new uint[](ownedAssets.length);
        address[] memory tempOwnedAssets;
        tempOwnedAssets = ownedAssets;
        delete ownedAssets;
        for (uint i = 0; i < tempOwnedAssets.length; ++i) {
            address ofAsset = tempOwnedAssets[i];
            // assetHoldings formatting: mul(exchangeHoldings, 10 ** assetDecimal)
            uint assetHoldings = add(
                uint(AssetInterface(ofAsset).balanceOf(address(this))), // asset base units held by fund
                quantityHeldInCustodyOfExchange(ofAsset)
            );
            // assetPrice formatting: mul(exchangePrice, 10 ** assetDecimal)
            var (isRecent, assetPrice, assetDecimals) = modules.pricefeed.getPriceInfo(ofAsset);
            if (!isRecent) {
                revert();
            }
            allAssetHoldings[i] = assetHoldings;
            allAssetPrices[i] = assetPrice;
            // gav as sum of mul(assetHoldings, assetPrice) with formatting: mul(mul(exchangeHoldings, exchangePrice), 10 ** shareDecimals)
            gav = add(gav, mul(assetHoldings, assetPrice) / (10 ** uint256(assetDecimals)));   // Sum up product of asset holdings of this vault and asset prices
            if (assetHoldings != 0 || ofAsset == address(QUOTE_ASSET) || isInOpenMakeOrder[ofAsset]) { // Check if asset holdings is not zero or is address(QUOTE_ASSET) or in open make order
                ownedAssets.push(ofAsset);
            } else {
                isInAssetList[ofAsset] = false; // Remove from ownedAssets if asset holdings are zero
            }
        }
        emit PortfolioContent(tempOwnedAssets, allAssetHoldings, allAssetPrices);
    }

    /// @notice Add an asset to the list that this fund owns
    function addAssetToOwnedAssets (address ofAsset)
        public
        pre_cond(isOwner() || msg.sender == address(this))
    {
        isInOpenMakeOrder[ofAsset] = true;
        if (!isInAssetList[ofAsset]) {
            ownedAssets.push(ofAsset);
            isInAssetList[ofAsset] = true;
        }
    }

    /**
    @notice Calculates unclaimed fees of the fund manager
    @param gav Gross asset value in QUOTE_ASSET and multiplied by 10 ** shareDecimals
    @return {
      "managementFees": "A time (seconds) based fee in QUOTE_ASSET and multiplied by 10 ** shareDecimals",
      "performanceFees": "A performance (rise of sharePrice measured in QUOTE_ASSET) based fee in QUOTE_ASSET and multiplied by 10 ** shareDecimals",
      "unclaimedfees": "The sum of both managementfee and performancefee in QUOTE_ASSET and multiplied by 10 ** shareDecimals"
    }
    */
    function calcUnclaimedFees(uint gav)
        view
        returns (
            uint managementFee,
            uint performanceFee,
            uint unclaimedFees)
    {
        // Management fee calculation
        uint timePassed = sub(now, atLastUnclaimedFeeAllocation.timestamp);
        uint gavPercentage = mul(timePassed, gav) / (1 years);
        managementFee = wmul(gavPercentage, MANAGEMENT_FEE_RATE);

        // Performance fee calculation
        // Handle potential division through zero by defining a default value
        uint valuePerShareExclMgmtFees = _totalSupply > 0 ? calcValuePerShare(sub(gav, managementFee), _totalSupply) : toSmallestShareUnit(1);
        if (valuePerShareExclMgmtFees > atLastUnclaimedFeeAllocation.highWaterMark) {
            uint gainInSharePrice = sub(valuePerShareExclMgmtFees, atLastUnclaimedFeeAllocation.highWaterMark);
            uint investmentProfits = wmul(gainInSharePrice, _totalSupply);
            performanceFee = wmul(investmentProfits, PERFORMANCE_FEE_RATE);
        }

        // Sum of all FEES
        unclaimedFees = add(managementFee, performanceFee);
    }

    /// @notice Calculates the Net asset value of this fund
    /// @param gav Gross asset value of this fund in QUOTE_ASSET and multiplied by 10 ** shareDecimals
    /// @param unclaimedFees The sum of both managementFee and performanceFee in QUOTE_ASSET and multiplied by 10 ** shareDecimals
    /// @return nav Net asset value in QUOTE_ASSET and multiplied by 10 ** shareDecimals
    function calcNav(uint gav, uint unclaimedFees)
        view
        returns (uint nav)
    {
        nav = sub(gav, unclaimedFees);
    }

    /// @notice Calculates the share price of the fund
    /// @dev Convention for valuePerShare (== sharePrice) formatting: mul(totalValue / numShares, 10 ** decimal), to avoid floating numbers
    /// @dev Non-zero share supply; value denominated in [base unit of melonAsset]
    /// @param totalValue the total value in QUOTE_ASSET and multiplied by 10 ** shareDecimals
    /// @param numShares the number of shares multiplied by 10 ** shareDecimals
    /// @return valuePerShare Share price denominated in QUOTE_ASSET and multiplied by 10 ** shareDecimals
    function calcValuePerShare(uint totalValue, uint numShares)
        view
        pre_cond(numShares > 0)
        returns (uint valuePerShare)
    {
        valuePerShare = toSmallestShareUnit(totalValue) / numShares;
    }

    /**
    @notice Calculates essential fund metrics
    @return {
      "gav": "Gross asset value of this fund denominated in [base unit of melonAsset]",
      "managementFee": "A time (seconds) based fee",
      "performanceFee": "A performance (rise of sharePrice measured in QUOTE_ASSET) based fee",
      "unclaimedFees": "The sum of both managementFee and performanceFee denominated in [base unit of melonAsset]",
      "feesShareQuantity": "The number of shares to be given as fees to the manager",
      "nav": "Net asset value denominated in [base unit of melonAsset]",
      "sharePrice": "Share price denominated in [base unit of melonAsset]"
    }
    */
    function performCalculations()
        view
        returns (
            uint gav,
            uint managementFee,
            uint performanceFee,
            uint unclaimedFees,
            uint feesShareQuantity,
            uint nav,
            uint sharePrice
        )
    {
        gav = calcGav(); // Reflects value independent of fees
        (managementFee, performanceFee, unclaimedFees) = calcUnclaimedFees(gav);
        nav = calcNav(gav, unclaimedFees);

        // The value of unclaimedFees measured in shares of this fund at current value
        feesShareQuantity = (gav == 0) ? 0 : mul(_totalSupply, unclaimedFees) / gav;
        // The total share supply including the value of unclaimedFees, measured in shares of this fund
        uint totalSupplyAccountingForFees = add(_totalSupply, feesShareQuantity);
        sharePrice = _totalSupply > 0 ? calcValuePerShare(gav, totalSupplyAccountingForFees) : toSmallestShareUnit(1); // Handle potential division through zero by defining a default value
    }

    /// @notice Converts unclaimed fees of the manager into fund shares
    /// @return sharePrice Share price denominated in [base unit of melonAsset]
    function calcSharePriceAndAllocateFees() public returns (uint)
    {
        var (
            gav,
            managementFee,
            performanceFee,
            unclaimedFees,
            feesShareQuantity,
            nav,
            sharePrice
        ) = performCalculations();

        createShares(owner, feesShareQuantity); // Updates _totalSupply by creating shares allocated to manager

        // Update Calculations
        uint highWaterMark = atLastUnclaimedFeeAllocation.highWaterMark >= sharePrice ? atLastUnclaimedFeeAllocation.highWaterMark : sharePrice;
        atLastUnclaimedFeeAllocation = Calculations({
            gav: gav,
            managementFee: managementFee,
            performanceFee: performanceFee,
            unclaimedFees: unclaimedFees,
            nav: nav,
            highWaterMark: highWaterMark,
            totalSupply: _totalSupply,
            timestamp: now
        });

        emit FeesConverted(now, feesShareQuantity, unclaimedFees);
        emit CalculationUpdate(now, managementFee, performanceFee, nav, sharePrice, _totalSupply);

        return sharePrice;
    }

    // PUBLIC : REDEEMING

    /// @notice Redeems by allocating an ownership percentage only of requestedAssets to the participant
    /// @dev This works, but with loops, so only up to a certain number of assets (right now the max is 4)
    /// @dev Independent of running price feed! Note: if requestedAssets != ownedAssets then participant misses out on some owned value
    /// @param shareQuantity Number of shares owned by the participant, which the participant would like to redeem for a slice of assets
    /// @param requestedAssets List of addresses that consitute a subset of ownedAssets.
    /// @return Whether all assets sent to shareholder or not
    function emergencyRedeem(uint shareQuantity, address[] requestedAssets)
        public
        pre_cond(balances[msg.sender] >= shareQuantity)  // sender owns enough shares
        returns (bool)
    {
        address ofAsset;
        uint[] memory ownershipQuantities = new uint[](requestedAssets.length);
        address[] memory redeemedAssets = new address[](requestedAssets.length);

        // Check whether enough assets held by fund
        for (uint i = 0; i < requestedAssets.length; ++i) {
            ofAsset = requestedAssets[i];
            require(isInAssetList[ofAsset]);
            for (uint j = 0; j < redeemedAssets.length; j++) {
                if (ofAsset == redeemedAssets[j]) {
                    revert();
                }
            }
            redeemedAssets[i] = ofAsset;
            uint assetHoldings = add(
                uint(AssetInterface(ofAsset).balanceOf(address(this))),
                quantityHeldInCustodyOfExchange(ofAsset)
            );

            if (assetHoldings == 0) continue;

            // participant&#39;s ownership percentage of asset holdings
            ownershipQuantities[i] = mul(assetHoldings, shareQuantity) / _totalSupply;

            // CRITICAL ERR: Not enough fund asset balance for owed ownershipQuantitiy, eg in case of unreturned asset quantity at address(exchanges[i].exchange) address
            if (uint(AssetInterface(ofAsset).balanceOf(address(this))) < ownershipQuantities[i]) {
                isShutDown = true;
                emit ErrorMessage("CRITICAL ERR: Not enough assetHoldings for owed ownershipQuantitiy");
                return false;
            }
        }

        // Annihilate shares before external calls to prevent reentrancy
        annihilateShares(msg.sender, shareQuantity);

        // Transfer ownershipQuantity of Assets
        for (uint k = 0; k < requestedAssets.length; ++k) {
            // Failed to send owed ownershipQuantity from fund to participant
            ofAsset = requestedAssets[k];
            if (ownershipQuantities[k] == 0) {
                continue;
            } else if (!AssetInterface(ofAsset).transfer(msg.sender, ownershipQuantities[k])) {
                revert();
            }
        }
        emit Redeemed(msg.sender, now, shareQuantity);
        return true;
    }

    // PUBLIC : FEES

    /// @dev Quantity of asset held in exchange according to associated order id
    /// @param ofAsset Address of asset
    /// @return Quantity of input asset held in exchange
    function quantityHeldInCustodyOfExchange(address ofAsset) returns (uint) {
        uint totalSellQuantity;     // quantity in custody across exchanges
        uint totalSellQuantityInApprove; // quantity of asset in approve (allowance) but not custody of exchange
        for (uint i; i < exchanges.length; i++) {
            if (exchangesToOpenMakeOrders[exchanges[i].exchange][ofAsset].id == 0) {
                continue;
            }
            var (sellAsset, , sellQuantity, ) = GenericExchangeInterface(exchanges[i].exchangeAdapter).getOrder(exchanges[i].exchange, exchangesToOpenMakeOrders[exchanges[i].exchange][ofAsset].id);
            if (sellQuantity == 0) {    // remove id if remaining sell quantity zero (closed)
                delete exchangesToOpenMakeOrders[exchanges[i].exchange][ofAsset];
            }
            totalSellQuantity = add(totalSellQuantity, sellQuantity);
            if (!exchanges[i].takesCustody) {
                totalSellQuantityInApprove += sellQuantity;
            }
        }
        if (totalSellQuantity == 0) {
            isInOpenMakeOrder[sellAsset] = false;
        }
        return sub(totalSellQuantity, totalSellQuantityInApprove); // Since quantity in approve is not actually in custody
    }

    // PUBLIC VIEW METHODS

    /// @notice Calculates sharePrice denominated in [base unit of melonAsset]
    /// @return sharePrice Share price denominated in [base unit of melonAsset]
    function calcSharePrice() view returns (uint sharePrice) {
        (, , , , , sharePrice) = performCalculations();
        return sharePrice;
    }

    function getModules() view returns (address, address, address) {
        return (
            address(modules.pricefeed),
            address(modules.compliance),
            address(modules.riskmgmt)
        );
    }

    function getLastRequestId() view returns (uint) { return requests.length - 1; }
    function getLastOrderIndex() view returns (uint) { return orders.length - 1; }
    function getManager() view returns (address) { return owner; }
    function getOwnedAssetsLength() view returns (uint) { return ownedAssets.length; }
    function getExchangeInfo() view returns (address[], address[], bool[]) {
        address[] memory ofExchanges = new address[](exchanges.length);
        address[] memory ofAdapters = new address[](exchanges.length);
        bool[] memory takesCustody = new bool[](exchanges.length);
        for (uint i = 0; i < exchanges.length; i++) {
            ofExchanges[i] = exchanges[i].exchange;
            ofAdapters[i] = exchanges[i].exchangeAdapter;
            takesCustody[i] = exchanges[i].takesCustody;
        }
        return (ofExchanges, ofAdapters, takesCustody);
    }
    function orderExpired(address ofExchange, address ofAsset) view returns (bool) {
        uint expiryTime = exchangesToOpenMakeOrders[ofExchange][ofAsset].expiresAt;
        require(expiryTime > 0);
        return block.timestamp >= expiryTime;
    }
    function getOpenOrderInfo(address ofExchange, address ofAsset) view returns (uint, uint) {
        OpenMakeOrder order = exchangesToOpenMakeOrders[ofExchange][ofAsset];
        return (order.id, order.expiresAt);
    }
}

contract CompetitionCompliance is ComplianceInterface, DBC, Owned {

    address public competitionAddress;

    // CONSTRUCTOR

    /// @dev Constructor
    /// @param ofCompetition Address of the competition contract
    function CompetitionCompliance(address ofCompetition) public {
        competitionAddress = ofCompetition;
    }

    // PUBLIC VIEW METHODS

    /// @notice Checks whether investment is permitted for a participant
    /// @param ofParticipant Address requesting to invest in a Melon fund
    /// @param giveQuantity Quantity of Melon token times 10 ** 18 offered to receive shareQuantity
    /// @param shareQuantity Quantity of shares times 10 ** 18 requested to be received
    /// @return Whether identity is eligible to invest in a Melon fund.
    function isInvestmentPermitted(
        address ofParticipant,
        uint256 giveQuantity,
        uint256 shareQuantity
    )
        view
        returns (bool)
    {
        return competitionAddress == ofParticipant;
    }

    /// @notice Checks whether redemption is permitted for a participant
    /// @param ofParticipant Address requesting to redeem from a Melon fund
    /// @param shareQuantity Quantity of shares times 10 ** 18 offered to redeem
    /// @param receiveQuantity Quantity of Melon token times 10 ** 18 requested to receive for shareQuantity
    /// @return isEligible Whether identity is eligible to redeem from a Melon fund.
    function isRedemptionPermitted(
        address ofParticipant,
        uint256 shareQuantity,
        uint256 receiveQuantity
    )
        view
        returns (bool)
    {
        return competitionAddress == ofParticipant;
    }

    /// @notice Checks whether an address is whitelisted in the competition contract and competition is active
    /// @param x Address
    /// @return Whether the address is whitelisted
    function isCompetitionAllowed(
        address x
    )
        view
        returns (bool)
    {
        return CompetitionInterface(competitionAddress).isWhitelisted(x) && CompetitionInterface(competitionAddress).isCompetitionActive();
    }


    // PUBLIC METHODS

    /// @notice Changes the competition address
    /// @param ofCompetition Address of the competition contract
    function changeCompetitionAddress(
        address ofCompetition
    )
        pre_cond(isOwner())
    {
        competitionAddress = ofCompetition;
    }

}

interface GenericExchangeInterface {

    // EVENTS

    event OrderUpdated(uint id);

    // METHODS
    // EXTERNAL METHODS

    function makeOrder(
        address onExchange,
        address sellAsset,
        address buyAsset,
        uint sellQuantity,
        uint buyQuantity
    ) external returns (uint);
    function takeOrder(address onExchange, uint id, uint quantity) external returns (bool);
    function cancelOrder(address onExchange, uint id) external returns (bool);


    // PUBLIC METHODS
    // PUBLIC VIEW METHODS

    function isApproveOnly() view returns (bool);
    function getLastOrderId(address onExchange) view returns (uint);
    function isActive(address onExchange, uint id) view returns (bool);
    function getOwner(address onExchange, uint id) view returns (address);
    function getOrder(address onExchange, uint id) view returns (address, address, uint, uint);
    function getTimestamp(address onExchange, uint id) view returns (uint);

}

contract CanonicalRegistrar is DSThing, DBC {

    // TYPES

    struct Asset {
        bool exists; // True if asset is registered here
        bytes32 name; // Human-readable name of the Asset as in ERC223 token standard
        bytes8 symbol; // Human-readable symbol of the Asset as in ERC223 token standard
        uint decimals; // Decimal, order of magnitude of precision, of the Asset as in ERC223 token standard
        string url; // URL for additional information of Asset
        string ipfsHash; // Same as url but for ipfs
        address breakIn; // Break in contract on destination chain
        address breakOut; // Break out contract on this chain; A way to leave
        uint[] standards; // compliance with standards like ERC20, ERC223, ERC777, etc. (the uint is the standard number)
        bytes4[] functionSignatures; // Whitelisted function signatures that can be called using `useExternalFunction` in Fund contract. Note: Adhere to a naming convention for `Fund<->Asset` as much as possible. I.e. name same concepts with the same functionSignature.
        uint price; // Price of asset quoted against `QUOTE_ASSET` * 10 ** decimals
        uint timestamp; // Timestamp of last price update of this asset
    }

    struct Exchange {
        bool exists;
        address adapter; // adapter contract for this exchange
        // One-time note: takesCustody is inverse case of isApproveOnly
        bool takesCustody; // True in case of exchange implementation which requires  are approved when an order is made instead of transfer
        bytes4[] functionSignatures; // Whitelisted function signatures that can be called using `useExternalFunction` in Fund contract. Note: Adhere to a naming convention for `Fund<->ExchangeAdapter` as much as possible. I.e. name same concepts with the same functionSignature.
    }
    // TODO: populate each field here
    // TODO: add whitelistFunction function

    // FIELDS

    // Methods fields
    mapping (address => Asset) public assetInformation;
    address[] public registeredAssets;

    mapping (address => Exchange) public exchangeInformation;
    address[] public registeredExchanges;

    // METHODS

    // PUBLIC METHODS

    /// @notice Registers an Asset information entry
    /// @dev Pre: Only registrar owner should be able to register
    /// @dev Post: Address ofAsset is registered
    /// @param ofAsset Address of asset to be registered
    /// @param inputName Human-readable name of the Asset as in ERC223 token standard
    /// @param inputSymbol Human-readable symbol of the Asset as in ERC223 token standard
    /// @param inputDecimals Human-readable symbol of the Asset as in ERC223 token standard
    /// @param inputUrl Url for extended information of the asset
    /// @param inputIpfsHash Same as url but for ipfs
    /// @param breakInBreakOut Address of break in and break out contracts on destination chain
    /// @param inputStandards Integers of EIP standards this asset adheres to
    /// @param inputFunctionSignatures Function signatures for whitelisted asset functions
    function registerAsset(
        address ofAsset,
        bytes32 inputName,
        bytes8 inputSymbol,
        uint inputDecimals,
        string inputUrl,
        string inputIpfsHash,
        address[2] breakInBreakOut,
        uint[] inputStandards,
        bytes4[] inputFunctionSignatures
    )
        auth
        pre_cond(!assetInformation[ofAsset].exists)
    {
        assetInformation[ofAsset].exists = true;
        registeredAssets.push(ofAsset);
        updateAsset(
            ofAsset,
            inputName,
            inputSymbol,
            inputDecimals,
            inputUrl,
            inputIpfsHash,
            breakInBreakOut,
            inputStandards,
            inputFunctionSignatures
        );
        assert(assetInformation[ofAsset].exists);
    }

    /// @notice Register an exchange information entry
    /// @dev Pre: Only registrar owner should be able to register
    /// @dev Post: Address ofExchange is registered
    /// @param ofExchange Address of the exchange
    /// @param ofExchangeAdapter Address of exchange adapter for this exchange
    /// @param inputTakesCustody Whether this exchange takes custody of tokens before trading
    /// @param inputFunctionSignatures Function signatures for whitelisted exchange functions
    function registerExchange(
        address ofExchange,
        address ofExchangeAdapter,
        bool inputTakesCustody,
        bytes4[] inputFunctionSignatures
    )
        auth
        pre_cond(!exchangeInformation[ofExchange].exists)
    {
        exchangeInformation[ofExchange].exists = true;
        registeredExchanges.push(ofExchange);
        updateExchange(
            ofExchange,
            ofExchangeAdapter,
            inputTakesCustody,
            inputFunctionSignatures
        );
        assert(exchangeInformation[ofExchange].exists);
    }

    /// @notice Updates description information of a registered Asset
    /// @dev Pre: Owner can change an existing entry
    /// @dev Post: Changed Name, Symbol, URL and/or IPFSHash
    /// @param ofAsset Address of the asset to be updated
    /// @param inputName Human-readable name of the Asset as in ERC223 token standard
    /// @param inputSymbol Human-readable symbol of the Asset as in ERC223 token standard
    /// @param inputUrl Url for extended information of the asset
    /// @param inputIpfsHash Same as url but for ipfs
    function updateAsset(
        address ofAsset,
        bytes32 inputName,
        bytes8 inputSymbol,
        uint inputDecimals,
        string inputUrl,
        string inputIpfsHash,
        address[2] ofBreakInBreakOut,
        uint[] inputStandards,
        bytes4[] inputFunctionSignatures
    )
        auth
        pre_cond(assetInformation[ofAsset].exists)
    {
        Asset asset = assetInformation[ofAsset];
        asset.name = inputName;
        asset.symbol = inputSymbol;
        asset.decimals = inputDecimals;
        asset.url = inputUrl;
        asset.ipfsHash = inputIpfsHash;
        asset.breakIn = ofBreakInBreakOut[0];
        asset.breakOut = ofBreakInBreakOut[1];
        asset.standards = inputStandards;
        asset.functionSignatures = inputFunctionSignatures;
    }

    function updateExchange(
        address ofExchange,
        address ofExchangeAdapter,
        bool inputTakesCustody,
        bytes4[] inputFunctionSignatures
    )
        auth
        pre_cond(exchangeInformation[ofExchange].exists)
    {
        Exchange exchange = exchangeInformation[ofExchange];
        exchange.adapter = ofExchangeAdapter;
        exchange.takesCustody = inputTakesCustody;
        exchange.functionSignatures = inputFunctionSignatures;
    }

    // TODO: check max size of array before remaking this becomes untenable
    /// @notice Deletes an existing entry
    /// @dev Owner can delete an existing entry
    /// @param ofAsset address for which specific information is requested
    function removeAsset(
        address ofAsset,
        uint assetIndex
    )
        auth
        pre_cond(assetInformation[ofAsset].exists)
    {
        require(registeredAssets[assetIndex] == ofAsset);
        delete assetInformation[ofAsset]; // Sets exists boolean to false
        delete registeredAssets[assetIndex];
        for (uint i = assetIndex; i < registeredAssets.length-1; i++) {
            registeredAssets[i] = registeredAssets[i+1];
        }
        registeredAssets.length--;
        assert(!assetInformation[ofAsset].exists);
    }

    /// @notice Deletes an existing entry
    /// @dev Owner can delete an existing entry
    /// @param ofExchange address for which specific information is requested
    /// @param exchangeIndex index of the exchange in array
    function removeExchange(
        address ofExchange,
        uint exchangeIndex
    )
        auth
        pre_cond(exchangeInformation[ofExchange].exists)
    {
        require(registeredExchanges[exchangeIndex] == ofExchange);
        delete exchangeInformation[ofExchange];
        delete registeredExchanges[exchangeIndex];
        for (uint i = exchangeIndex; i < registeredExchanges.length-1; i++) {
            registeredExchanges[i] = registeredExchanges[i+1];
        }
        registeredExchanges.length--;
        assert(!exchangeInformation[ofExchange].exists);
    }

    // PUBLIC VIEW METHODS

    // get asset specific information
    function getName(address ofAsset) view returns (bytes32) { return assetInformation[ofAsset].name; }
    function getSymbol(address ofAsset) view returns (bytes8) { return assetInformation[ofAsset].symbol; }
    function getDecimals(address ofAsset) view returns (uint) { return assetInformation[ofAsset].decimals; }
    function assetIsRegistered(address ofAsset) view returns (bool) { return assetInformation[ofAsset].exists; }
    function getRegisteredAssets() view returns (address[]) { return registeredAssets; }
    function assetMethodIsAllowed(
        address ofAsset, bytes4 querySignature
    )
        returns (bool)
    {
        bytes4[] memory signatures = assetInformation[ofAsset].functionSignatures;
        for (uint i = 0; i < signatures.length; i++) {
            if (signatures[i] == querySignature) {
                return true;
            }
        }
        return false;
    }

    // get exchange-specific information
    function exchangeIsRegistered(address ofExchange) view returns (bool) { return exchangeInformation[ofExchange].exists; }
    function getRegisteredExchanges() view returns (address[]) { return registeredExchanges; }
    function getExchangeInformation(address ofExchange)
        view
        returns (address, bool)
    {
        Exchange exchange = exchangeInformation[ofExchange];
        return (
            exchange.adapter,
            exchange.takesCustody
        );
    }
    function getExchangeFunctionSignatures(address ofExchange)
        view
        returns (bytes4[])
    {
        return exchangeInformation[ofExchange].functionSignatures;
    }
    function exchangeMethodIsAllowed(
        address ofExchange, bytes4 querySignature
    )
        returns (bool)
    {
        bytes4[] memory signatures = exchangeInformation[ofExchange].functionSignatures;
        for (uint i = 0; i < signatures.length; i++) {
            if (signatures[i] == querySignature) {
                return true;
            }
        }
        return false;
    }
}

interface SimplePriceFeedInterface {

    // EVENTS

    event PriceUpdated(bytes32 hash);

    // PUBLIC METHODS

    function update(address[] ofAssets, uint[] newPrices) external;

    // PUBLIC VIEW METHODS

    // Get price feed operation specific information
    function getQuoteAsset() view returns (address);
    function getLastUpdateId() view returns (uint);
    // Get asset specific information as updated in price feed
    function getPrice(address ofAsset) view returns (uint price, uint timestamp);
    function getPrices(address[] ofAssets) view returns (uint[] prices, uint[] timestamps);
}

contract SimplePriceFeed is SimplePriceFeedInterface, DSThing, DBC {

    // TYPES
    struct Data {
        uint price;
        uint timestamp;
    }

    // FIELDS
    mapping(address => Data) public assetsToPrices;

    // Constructor fields
    address public QUOTE_ASSET; // Asset of a portfolio against which all other assets are priced

    // Contract-level variables
    uint public updateId;        // Update counter for this pricefeed; used as a check during investment
    CanonicalRegistrar public registrar;
    CanonicalPriceFeed public superFeed;

    // METHODS

    // CONSTRUCTOR

    /// @param ofQuoteAsset Address of quote asset
    /// @param ofRegistrar Address of canonical registrar
    /// @param ofSuperFeed Address of superfeed
    function SimplePriceFeed(
        address ofRegistrar,
        address ofQuoteAsset,
        address ofSuperFeed
    ) {
        registrar = CanonicalRegistrar(ofRegistrar);
        QUOTE_ASSET = ofQuoteAsset;
        superFeed = CanonicalPriceFeed(ofSuperFeed);
    }

    // EXTERNAL METHODS

    /// @dev Only Owner; Same sized input arrays
    /// @dev Updates price of asset relative to QUOTE_ASSET
    /** Ex:
     *  Let QUOTE_ASSET == MLN (base units), let asset == EUR-T,
     *  let Value of 1 EUR-T := 1 EUR == 0.080456789 MLN, hence price 0.080456789 MLN / EUR-T
     *  and let EUR-T decimals == 8.
     *  Input would be: information[EUR-T].price = 8045678 [MLN/ (EUR-T * 10**8)]
     */
    /// @param ofAssets list of asset addresses
    /// @param newPrices list of prices for each of the assets
    function update(address[] ofAssets, uint[] newPrices)
        external
        auth
    {
        _updatePrices(ofAssets, newPrices);
    }

    // PUBLIC VIEW METHODS

    // Get pricefeed specific information
    function getQuoteAsset() view returns (address) { return QUOTE_ASSET; }
    function getLastUpdateId() view returns (uint) { return updateId; }

    /**
    @notice Gets price of an asset multiplied by ten to the power of assetDecimals
    @dev Asset has been registered
    @param ofAsset Asset for which price should be returned
    @return {
      "price": "Price formatting: mul(exchangePrice, 10 ** decimal), to avoid floating numbers",
      "timestamp": "When the asset&#39;s price was updated"
    }
    */
    function getPrice(address ofAsset)
        view
        returns (uint price, uint timestamp)
    {
        Data data = assetsToPrices[ofAsset];
        return (data.price, data.timestamp);
    }

    /**
    @notice Price of a registered asset in format (bool areRecent, uint[] prices, uint[] decimals)
    @dev Convention for price formatting: mul(price, 10 ** decimal), to avoid floating numbers
    @param ofAssets Assets for which prices should be returned
    @return {
        "prices":       "Array of prices",
        "timestamps":   "Array of timestamps",
    }
    */
    function getPrices(address[] ofAssets)
        view
        returns (uint[], uint[])
    {
        uint[] memory prices = new uint[](ofAssets.length);
        uint[] memory timestamps = new uint[](ofAssets.length);
        for (uint i; i < ofAssets.length; i++) {
            var (price, timestamp) = getPrice(ofAssets[i]);
            prices[i] = price;
            timestamps[i] = timestamp;
        }
        return (prices, timestamps);
    }

    // INTERNAL METHODS

    /// @dev Internal so that feeds inheriting this one are not obligated to have an exposed update(...) method, but can still perform updates
    function _updatePrices(address[] ofAssets, uint[] newPrices)
        internal
        pre_cond(ofAssets.length == newPrices.length)
    {
        updateId++;
        for (uint i = 0; i < ofAssets.length; ++i) {
            require(registrar.assetIsRegistered(ofAssets[i]));
            require(assetsToPrices[ofAssets[i]].timestamp != now); // prevent two updates in one block
            assetsToPrices[ofAssets[i]].timestamp = now;
            assetsToPrices[ofAssets[i]].price = newPrices[i];
        }
        emit PriceUpdated(keccak256(ofAssets, newPrices));
    }
}

contract StakingPriceFeed is SimplePriceFeed {

    OperatorStaking public stakingContract;
    AssetInterface public stakingToken;

    // CONSTRUCTOR

    /// @param ofQuoteAsset Address of quote asset
    /// @param ofRegistrar Address of canonical registrar
    /// @param ofSuperFeed Address of superfeed
    function StakingPriceFeed(
        address ofRegistrar,
        address ofQuoteAsset,
        address ofSuperFeed
    )
        SimplePriceFeed(ofRegistrar, ofQuoteAsset, ofSuperFeed)
    {
        stakingContract = OperatorStaking(ofSuperFeed); // canonical feed *is* staking contract
        stakingToken = AssetInterface(stakingContract.stakingToken());
    }

    // EXTERNAL METHODS

    /// @param amount Number of tokens to stake for this feed
    /// @param data Data may be needed for some future applications (can be empty for now)
    function depositStake(uint amount, bytes data)
        external
        auth
    {
        require(stakingToken.transferFrom(msg.sender, address(this), amount));
        require(stakingToken.approve(stakingContract, amount));
        stakingContract.stake(amount, data);
    }

    /// @param amount Number of tokens to unstake for this feed
    /// @param data Data may be needed for some future applications (can be empty for now)
    function unstake(uint amount, bytes data) {
        stakingContract.unstake(amount, data);
    }

    function withdrawStake()
        external
        auth
    {
        uint amountToWithdraw = stakingContract.stakeToWithdraw(address(this));
        stakingContract.withdrawStake();
        require(stakingToken.transfer(msg.sender, amountToWithdraw));
    }
}

interface RiskMgmtInterface {

    // METHODS
    // PUBLIC VIEW METHODS

    /// @notice Checks if the makeOrder price is reasonable and not manipulative
    /// @param orderPrice Price of Order
    /// @param referencePrice Reference price obtained through PriceFeed contract
    /// @param sellAsset Asset (as registered in Asset registrar) to be sold
    /// @param buyAsset Asset (as registered in Asset registrar) to be bought
    /// @param sellQuantity Quantity of sellAsset to be sold
    /// @param buyQuantity Quantity of buyAsset to be bought
    /// @return If makeOrder is permitted
    function isMakePermitted(
        uint orderPrice,
        uint referencePrice,
        address sellAsset,
        address buyAsset,
        uint sellQuantity,
        uint buyQuantity
    ) view returns (bool);

    /// @notice Checks if the takeOrder price is reasonable and not manipulative
    /// @param orderPrice Price of Order
    /// @param referencePrice Reference price obtained through PriceFeed contract
    /// @param sellAsset Asset (as registered in Asset registrar) to be sold
    /// @param buyAsset Asset (as registered in Asset registrar) to be bought
    /// @param sellQuantity Quantity of sellAsset to be sold
    /// @param buyQuantity Quantity of buyAsset to be bought
    /// @return If takeOrder is permitted
    function isTakePermitted(
        uint orderPrice,
        uint referencePrice,
        address sellAsset,
        address buyAsset,
        uint sellQuantity,
        uint buyQuantity
    ) view returns (bool);
}

contract OperatorStaking is DBC {

    // EVENTS

    event Staked(address indexed user, uint256 amount, uint256 total, bytes data);
    event Unstaked(address indexed user, uint256 amount, uint256 total, bytes data);
    event StakeBurned(address indexed user, uint256 amount, bytes data);

    // TYPES

    struct StakeData {
        uint amount;
        address staker;
    }

    // Circular linked list
    struct Node {
        StakeData data;
        uint prev;
        uint next;
    }

    // FIELDS

    // INTERNAL FIELDS
    Node[] internal stakeNodes; // Sorted circular linked list nodes containing stake data (Built on top https://programtheblockchain.com/posts/2018/03/30/storage-patterns-doubly-linked-list/)

    // PUBLIC FIELDS
    uint public minimumStake;
    uint public numOperators;
    uint public withdrawalDelay;
    mapping (address => bool) public isRanked;
    mapping (address => uint) public latestUnstakeTime;
    mapping (address => uint) public stakeToWithdraw;
    mapping (address => uint) public stakedAmounts;
    uint public numStakers; // Current number of stakers (Needed because of array holes)
    AssetInterface public stakingToken;

    // TODO: consider renaming "operator" depending on how this is implemented
    //  (i.e. is pricefeed staking itself?)
    function OperatorStaking(
        AssetInterface _stakingToken,
        uint _minimumStake,
        uint _numOperators,
        uint _withdrawalDelay
    )
        public
    {
        require(address(_stakingToken) != address(0));
        stakingToken = _stakingToken;
        minimumStake = _minimumStake;
        numOperators = _numOperators;
        withdrawalDelay = _withdrawalDelay;
        StakeData memory temp = StakeData({ amount: 0, staker: address(0) });
        stakeNodes.push(Node(temp, 0, 0));
    }

    // METHODS : STAKING

    function stake(
        uint amount,
        bytes data
    )
        public
        pre_cond(amount >= minimumStake)
    {
        uint tailNodeId = stakeNodes[0].prev;
        stakedAmounts[msg.sender] += amount;
        updateStakerRanking(msg.sender);
        require(stakingToken.transferFrom(msg.sender, address(this), amount));
    }

    function unstake(
        uint amount,
        bytes data
    )
        public
    {
        uint preStake = stakedAmounts[msg.sender];
        uint postStake = preStake - amount;
        require(postStake >= minimumStake || postStake == 0);
        require(stakedAmounts[msg.sender] >= amount);
        latestUnstakeTime[msg.sender] = block.timestamp;
        stakedAmounts[msg.sender] -= amount;
        stakeToWithdraw[msg.sender] += amount;
        updateStakerRanking(msg.sender);
        emit Unstaked(msg.sender, amount, stakedAmounts[msg.sender], data);
    }

    function withdrawStake()
        public
        pre_cond(stakeToWithdraw[msg.sender] > 0)
        pre_cond(block.timestamp >= latestUnstakeTime[msg.sender] + withdrawalDelay)
    {
        uint amount = stakeToWithdraw[msg.sender];
        stakeToWithdraw[msg.sender] = 0;
        require(stakingToken.transfer(msg.sender, amount));
    }

    // VIEW FUNCTIONS

    function isValidNode(uint id) view returns (bool) {
        // 0 is a sentinel and therefore invalid.
        // A valid node is the head or has a previous node.
        return id != 0 && (id == stakeNodes[0].next || stakeNodes[id].prev != 0);
    }

    function searchNode(address staker) view returns (uint) {
        uint current = stakeNodes[0].next;
        while (isValidNode(current)) {
            if (staker == stakeNodes[current].data.staker) {
                return current;
            }
            current = stakeNodes[current].next;
        }
        return 0;
    }

    function isOperator(address user) view returns (bool) {
        address[] memory operators = getOperators();
        for (uint i; i < operators.length; i++) {
            if (operators[i] == user) {
                return true;
            }
        }
        return false;
    }

    function getOperators()
        view
        returns (address[])
    {
        uint arrLength = (numOperators > numStakers) ?
            numStakers :
            numOperators;
        address[] memory operators = new address[](arrLength);
        uint current = stakeNodes[0].next;
        for (uint i; i < arrLength; i++) {
            operators[i] = stakeNodes[current].data.staker;
            current = stakeNodes[current].next;
        }
        return operators;
    }

    function getStakersAndAmounts()
        view
        returns (address[], uint[])
    {
        address[] memory stakers = new address[](numStakers);
        uint[] memory amounts = new uint[](numStakers);
        uint current = stakeNodes[0].next;
        for (uint i; i < numStakers; i++) {
            stakers[i] = stakeNodes[current].data.staker;
            amounts[i] = stakeNodes[current].data.amount;
            current = stakeNodes[current].next;
        }
        return (stakers, amounts);
    }

    function totalStakedFor(address user)
        view
        returns (uint)
    {
        return stakedAmounts[user];
    }

    // INTERNAL METHODS

    // DOUBLY-LINKED LIST

    function insertNodeSorted(uint amount, address staker) internal returns (uint) {
        uint current = stakeNodes[0].next;
        if (current == 0) return insertNodeAfter(0, amount, staker);
        while (isValidNode(current)) {
            if (amount > stakeNodes[current].data.amount) {
                break;
            }
            current = stakeNodes[current].next;
        }
        return insertNodeBefore(current, amount, staker);
    }

    function insertNodeAfter(uint id, uint amount, address staker) internal returns (uint newID) {

        // 0 is allowed here to insert at the beginning.
        require(id == 0 || isValidNode(id));

        Node storage node = stakeNodes[id];

        stakeNodes.push(Node({
            data: StakeData(amount, staker),
            prev: id,
            next: node.next
        }));

        newID = stakeNodes.length - 1;

        stakeNodes[node.next].prev = newID;
        node.next = newID;
        numStakers++;
    }

    function insertNodeBefore(uint id, uint amount, address staker) internal returns (uint) {
        return insertNodeAfter(stakeNodes[id].prev, amount, staker);
    }

    function removeNode(uint id) internal {
        require(isValidNode(id));

        Node storage node = stakeNodes[id];

        stakeNodes[node.next].prev = node.prev;
        stakeNodes[node.prev].next = node.next;

        delete stakeNodes[id];
        numStakers--;
    }

    // UPDATING OPERATORS

    function updateStakerRanking(address _staker) internal {
        uint newStakedAmount = stakedAmounts[_staker];
        if (newStakedAmount == 0) {
            isRanked[_staker] = false;
            removeStakerFromArray(_staker);
        } else if (isRanked[_staker]) {
            removeStakerFromArray(_staker);
            insertNodeSorted(newStakedAmount, _staker);
        } else {
            isRanked[_staker] = true;
            insertNodeSorted(newStakedAmount, _staker);
        }
    }

    function removeStakerFromArray(address _staker) internal {
        uint id = searchNode(_staker);
        require(id > 0);
        removeNode(id);
    }

}

contract CanonicalPriceFeed is OperatorStaking, SimplePriceFeed, CanonicalRegistrar {

    // EVENTS
    event SetupPriceFeed(address ofPriceFeed);

    struct HistoricalPrices {
        address[] assets;
        uint[] prices;
        uint timestamp;
    }

    // FIELDS
    bool public updatesAreAllowed = true;
    uint public minimumPriceCount = 1;
    uint public VALIDITY;
    uint public INTERVAL;
    mapping (address => bool) public isStakingFeed; // If the Staking Feed has been created through this contract
    HistoricalPrices[] public priceHistory;

    // METHODS

    // CONSTRUCTOR

    /// @dev Define and register a quote asset against which all prices are measured/based against
    /// @param ofStakingAsset Address of staking asset (may or may not be quoteAsset)
    /// @param ofQuoteAsset Address of quote asset
    /// @param quoteAssetName Name of quote asset
    /// @param quoteAssetSymbol Symbol for quote asset
    /// @param quoteAssetDecimals Decimal places for quote asset
    /// @param quoteAssetUrl URL related to quote asset
    /// @param quoteAssetIpfsHash IPFS hash associated with quote asset
    /// @param quoteAssetBreakInBreakOut Break-in/break-out for quote asset on destination chain
    /// @param quoteAssetStandards EIP standards quote asset adheres to
    /// @param quoteAssetFunctionSignatures Whitelisted functions of quote asset contract
    // /// @param interval Number of seconds between pricefeed updates (this interval is not enforced on-chain, but should be followed by the datafeed maintainer)
    // /// @param validity Number of seconds that datafeed update information is valid for
    /// @param ofGovernance Address of contract governing the Canonical PriceFeed
    function CanonicalPriceFeed(
        address ofStakingAsset,
        address ofQuoteAsset, // Inital entry in asset registrar contract is Melon (QUOTE_ASSET)
        bytes32 quoteAssetName,
        bytes8 quoteAssetSymbol,
        uint quoteAssetDecimals,
        string quoteAssetUrl,
        string quoteAssetIpfsHash,
        address[2] quoteAssetBreakInBreakOut,
        uint[] quoteAssetStandards,
        bytes4[] quoteAssetFunctionSignatures,
        uint[2] updateInfo, // interval, validity
        uint[3] stakingInfo, // minStake, numOperators, unstakeDelay
        address ofGovernance
    )
        OperatorStaking(
            AssetInterface(ofStakingAsset), stakingInfo[0], stakingInfo[1], stakingInfo[2]
        )
        SimplePriceFeed(address(this), ofQuoteAsset, address(0))
    {
        registerAsset(
            ofQuoteAsset,
            quoteAssetName,
            quoteAssetSymbol,
            quoteAssetDecimals,
            quoteAssetUrl,
            quoteAssetIpfsHash,
            quoteAssetBreakInBreakOut,
            quoteAssetStandards,
            quoteAssetFunctionSignatures
        );
        INTERVAL = updateInfo[0];
        VALIDITY = updateInfo[1];
        setOwner(ofGovernance);
    }

    // EXTERNAL METHODS

    /// @notice Create a new StakingPriceFeed
    function setupStakingPriceFeed() external {
        address ofStakingPriceFeed = new StakingPriceFeed(
            address(this),
            stakingToken,
            address(this)
        );
        isStakingFeed[ofStakingPriceFeed] = true;
        StakingPriceFeed(ofStakingPriceFeed).setOwner(msg.sender);
        emit SetupPriceFeed(ofStakingPriceFeed);
    }

    /// @dev override inherited update function to prevent manual update from authority
    function update() external { revert(); }

    /// @dev Burn state for a pricefeed operator
    /// @param user Address of pricefeed operator to burn the stake from
    function burnStake(address user)
        external
        auth
    {
        uint totalToBurn = add(stakedAmounts[user], stakeToWithdraw[user]);
        stakedAmounts[user] = 0;
        stakeToWithdraw[user] = 0;
        updateStakerRanking(user);
        emit StakeBurned(user, totalToBurn, "");
    }

    // PUBLIC METHODS

    // STAKING

    function stake(
        uint amount,
        bytes data
    )
        public
        pre_cond(isStakingFeed[msg.sender])
    {
        OperatorStaking.stake(amount, data);
    }

    // function stakeFor(
    //     address user,
    //     uint amount,
    //     bytes data
    // )
    //     public
    //     pre_cond(isStakingFeed[user])
    // {

    //     OperatorStaking.stakeFor(user, amount, data);
    // }

    // AGGREGATION

    /// @dev Only Owner; Same sized input arrays
    /// @dev Updates price of asset relative to QUOTE_ASSET
    /** Ex:
     *  Let QUOTE_ASSET == MLN (base units), let asset == EUR-T,
     *  let Value of 1 EUR-T := 1 EUR == 0.080456789 MLN, hence price 0.080456789 MLN / EUR-T
     *  and let EUR-T decimals == 8.
     *  Input would be: information[EUR-T].price = 8045678 [MLN/ (EUR-T * 10**8)]
     */
    /// @param ofAssets list of asset addresses
    function collectAndUpdate(address[] ofAssets)
        public
        auth
        pre_cond(updatesAreAllowed)
    {
        uint[] memory newPrices = pricesToCommit(ofAssets);
        priceHistory.push(
            HistoricalPrices({assets: ofAssets, prices: newPrices, timestamp: block.timestamp})
        );
        _updatePrices(ofAssets, newPrices);
    }

    function pricesToCommit(address[] ofAssets)
        view
        returns (uint[])
    {
        address[] memory operators = getOperators();
        uint[] memory newPrices = new uint[](ofAssets.length);
        for (uint i = 0; i < ofAssets.length; i++) {
            uint[] memory assetPrices = new uint[](operators.length);
            for (uint j = 0; j < operators.length; j++) {
                SimplePriceFeed feed = SimplePriceFeed(operators[j]);
                var (price, timestamp) = feed.assetsToPrices(ofAssets[i]);
                if (now > add(timestamp, VALIDITY)) {
                    continue; // leaves a zero in the array (dealt with later)
                }
                assetPrices[j] = price;
            }
            newPrices[i] = medianize(assetPrices);
        }
        return newPrices;
    }

    /// @dev from MakerDao medianizer contract
    function medianize(uint[] unsorted)
        view
        returns (uint)
    {
        uint numValidEntries;
        for (uint i = 0; i < unsorted.length; i++) {
            if (unsorted[i] != 0) {
                numValidEntries++;
            }
        }
        if (numValidEntries < minimumPriceCount) {
            revert();
        }
        uint counter;
        uint[] memory out = new uint[](numValidEntries);
        for (uint j = 0; j < unsorted.length; j++) {
            uint item = unsorted[j];
            if (item != 0) {    // skip zero (invalid) entries
                if (counter == 0 || item >= out[counter - 1]) {
                    out[counter] = item;  // item is larger than last in array (we are home)
                } else {
                    uint k = 0;
                    while (item >= out[k]) {
                        k++;  // get to where element belongs (between smaller and larger items)
                    }
                    for (uint l = counter; l > k; l--) {
                        out[l] = out[l - 1];    // bump larger elements rightward to leave slot
                    }
                    out[k] = item;
                }
                counter++;
            }
        }

        uint value;
        if (counter % 2 == 0) {
            uint value1 = uint(out[(counter / 2) - 1]);
            uint value2 = uint(out[(counter / 2)]);
            value = add(value1, value2) / 2;
        } else {
            value = out[(counter - 1) / 2];
        }
        return value;
    }

    function setMinimumPriceCount(uint newCount) auth { minimumPriceCount = newCount; }
    function enableUpdates() auth { updatesAreAllowed = true; }
    function disableUpdates() auth { updatesAreAllowed = false; }

    // PUBLIC VIEW METHODS

    // FEED INFORMATION

    function getQuoteAsset() view returns (address) { return QUOTE_ASSET; }
    function getInterval() view returns (uint) { return INTERVAL; }
    function getValidity() view returns (uint) { return VALIDITY; }
    function getLastUpdateId() view returns (uint) { return updateId; }

    // PRICES

    /// @notice Whether price of asset has been updated less than VALIDITY seconds ago
    /// @param ofAsset Asset in registrar
    /// @return isRecent Price information ofAsset is recent
    function hasRecentPrice(address ofAsset)
        view
        pre_cond(assetIsRegistered(ofAsset))
        returns (bool isRecent)
    {
        var ( , timestamp) = getPrice(ofAsset);
        return (sub(now, timestamp) <= VALIDITY);
    }

    /// @notice Whether prices of assets have been updated less than VALIDITY seconds ago
    /// @param ofAssets All assets in registrar
    /// @return isRecent Price information ofAssets array is recent
    function hasRecentPrices(address[] ofAssets)
        view
        returns (bool areRecent)
    {
        for (uint i; i < ofAssets.length; i++) {
            if (!hasRecentPrice(ofAssets[i])) {
                return false;
            }
        }
        return true;
    }

    function getPriceInfo(address ofAsset)
        view
        returns (bool isRecent, uint price, uint assetDecimals)
    {
        isRecent = hasRecentPrice(ofAsset);
        (price, ) = getPrice(ofAsset);
        assetDecimals = getDecimals(ofAsset);
    }

    /**
    @notice Gets inverted price of an asset
    @dev Asset has been initialised and its price is non-zero
    @dev Existing price ofAssets quoted in QUOTE_ASSET (convention)
    @param ofAsset Asset for which inverted price should be return
    @return {
        "isRecent": "Whether the price is fresh, given VALIDITY interval",
        "invertedPrice": "Price based (instead of quoted) against QUOTE_ASSET",
        "assetDecimals": "Decimal places for this asset"
    }
    */
    function getInvertedPriceInfo(address ofAsset)
        view
        returns (bool isRecent, uint invertedPrice, uint assetDecimals)
    {
        uint inputPrice;
        // inputPrice quoted in QUOTE_ASSET and multiplied by 10 ** assetDecimal
        (isRecent, inputPrice, assetDecimals) = getPriceInfo(ofAsset);

        // outputPrice based in QUOTE_ASSET and multiplied by 10 ** quoteDecimal
        uint quoteDecimals = getDecimals(QUOTE_ASSET);

        return (
            isRecent,
            mul(10 ** uint(quoteDecimals), 10 ** uint(assetDecimals)) / inputPrice,
            quoteDecimals   // TODO: check on this; shouldn&#39;t it be assetDecimals?
        );
    }

    /**
    @notice Gets reference price of an asset pair
    @dev One of the address is equal to quote asset
    @dev either ofBase == QUOTE_ASSET or ofQuote == QUOTE_ASSET
    @param ofBase Address of base asset
    @param ofQuote Address of quote asset
    @return {
        "isRecent": "Whether the price is fresh, given VALIDITY interval",
        "referencePrice": "Reference price",
        "decimal": "Decimal places for this asset"
    }
    */
    function getReferencePriceInfo(address ofBase, address ofQuote)
        view
        returns (bool isRecent, uint referencePrice, uint decimal)
    {
        if (getQuoteAsset() == ofQuote) {
            (isRecent, referencePrice, decimal) = getPriceInfo(ofBase);
        } else if (getQuoteAsset() == ofBase) {
            (isRecent, referencePrice, decimal) = getInvertedPriceInfo(ofQuote);
        } else {
            revert(); // no suitable reference price available
        }
    }

    /// @notice Gets price of Order
    /// @param sellAsset Address of the asset to be sold
    /// @param buyAsset Address of the asset to be bought
    /// @param sellQuantity Quantity in base units being sold of sellAsset
    /// @param buyQuantity Quantity in base units being bought of buyAsset
    /// @return orderPrice Price as determined by an order
    function getOrderPriceInfo(
        address sellAsset,
        address buyAsset,
        uint sellQuantity,
        uint buyQuantity
    )
        view
        returns (uint orderPrice)
    {
        return mul(buyQuantity, 10 ** uint(getDecimals(sellAsset))) / sellQuantity;
    }

    /// @notice Checks whether data exists for a given asset pair
    /// @dev Prices are only upated against QUOTE_ASSET
    /// @param sellAsset Asset for which check to be done if data exists
    /// @param buyAsset Asset for which check to be done if data exists
    /// @return Whether assets exist for given asset pair
    function existsPriceOnAssetPair(address sellAsset, address buyAsset)
        view
        returns (bool isExistent)
    {
        return
            hasRecentPrice(sellAsset) && // Is tradable asset (TODO cleaner) and datafeed delivering data
            hasRecentPrice(buyAsset) && // Is tradable asset (TODO cleaner) and datafeed delivering data
            (buyAsset == QUOTE_ASSET || sellAsset == QUOTE_ASSET) && // One asset must be QUOTE_ASSET
            (buyAsset != QUOTE_ASSET || sellAsset != QUOTE_ASSET); // Pair must consists of diffrent assets
    }

    /// @return Sparse array of addresses of owned pricefeeds
    function getPriceFeedsByOwner(address _owner)
        view
        returns(address[])
    {
        address[] memory ofPriceFeeds = new address[](numStakers);
        if (numStakers == 0) return ofPriceFeeds;
        uint current = stakeNodes[0].next;
        for (uint i; i < numStakers; i++) {
            StakingPriceFeed stakingFeed = StakingPriceFeed(stakeNodes[current].data.staker);
            if (stakingFeed.owner() == _owner) {
                ofPriceFeeds[i] = address(stakingFeed);
            }
            current = stakeNodes[current].next;
        }
        return ofPriceFeeds;
    }

    function getHistoryLength() returns (uint) { return priceHistory.length; }

    function getHistoryAt(uint id) returns (address[], uint[], uint) {
        address[] memory assets = priceHistory[id].assets;
        uint[] memory prices = priceHistory[id].prices;
        uint timestamp = priceHistory[id].timestamp;
        return (assets, prices, timestamp);
    }
}

interface VersionInterface {

    // EVENTS

    event FundUpdated(uint id);

    // PUBLIC METHODS

    function shutDown() external;

    function setupFund(
        bytes32 ofFundName,
        address ofQuoteAsset,
        uint ofManagementFee,
        uint ofPerformanceFee,
        address ofCompliance,
        address ofRiskMgmt,
        address[] ofExchanges,
        address[] ofDefaultAssets,
        uint8 v,
        bytes32 r,
        bytes32 s
    );
    function shutDownFund(address ofFund);

    // PUBLIC VIEW METHODS

    function getNativeAsset() view returns (address);
    function getFundById(uint withId) view returns (address);
    function getLastFundId() view returns (uint);
    function getFundByManager(address ofManager) view returns (address);
    function termsAndConditionsAreSigned(uint8 v, bytes32 r, bytes32 s) view returns (bool signed);

}

contract Version is DBC, Owned, VersionInterface {
    // FIELDS

    bytes32 public constant TERMS_AND_CONDITIONS = 0xAA9C907B0D6B4890E7225C09CBC16A01CB97288840201AA7CDCB27F4ED7BF159; // Hashed terms and conditions as displayed on IPFS, decoded from base 58

    // Constructor fields
    string public VERSION_NUMBER; // SemVer of Melon protocol version
    address public MELON_ASSET; // Address of Melon asset contract
    address public NATIVE_ASSET; // Address of Fixed quote asset
    address public GOVERNANCE; // Address of Melon protocol governance contract
    address public CANONICAL_PRICEFEED; // Address of the canonical pricefeed

    // Methods fields
    bool public isShutDown; // Governance feature, if yes than setupFund gets blocked and shutDownFund gets opened
    address public COMPLIANCE; // restrict to Competition compliance module for this version
    address[] public listOfFunds; // A complete list of fund addresses created using this version
    mapping (address => address) public managerToFunds; // Links manager address to fund address created using this version

    // EVENTS

    event FundUpdated(address ofFund);

    // METHODS

    // CONSTRUCTOR

    /// @param versionNumber SemVer of Melon protocol version
    /// @param ofGovernance Address of Melon governance contract
    /// @param ofMelonAsset Address of Melon asset contract
    function Version(
        string versionNumber,
        address ofGovernance,
        address ofMelonAsset,
        address ofNativeAsset,
        address ofCanonicalPriceFeed,
        address ofCompetitionCompliance
    ) {
        VERSION_NUMBER = versionNumber;
        GOVERNANCE = ofGovernance;
        MELON_ASSET = ofMelonAsset;
        NATIVE_ASSET = ofNativeAsset;
        CANONICAL_PRICEFEED = ofCanonicalPriceFeed;
        COMPLIANCE = ofCompetitionCompliance;
    }

    // EXTERNAL METHODS

    function shutDown() external pre_cond(msg.sender == GOVERNANCE) { isShutDown = true; }

    // PUBLIC METHODS

    /// @param ofFundName human-readable descriptive name (not necessarily unique)
    /// @param ofQuoteAsset Asset against which performance fee is measured against
    /// @param ofManagementFee A time based fee, given in a number which is divided by 10 ** 15
    /// @param ofPerformanceFee A time performance based fee, performance relative to ofQuoteAsset, given in a number which is divided by 10 ** 15
    /// @param ofCompliance Address of participation module
    /// @param ofRiskMgmt Address of risk management module
    /// @param ofExchanges Addresses of exchange on which this fund can trade
    /// @param ofDefaultAssets Enable invest/redeem with these assets (quote asset already enabled)
    /// @param v ellipitc curve parameter v
    /// @param r ellipitc curve parameter r
    /// @param s ellipitc curve parameter s
    function setupFund(
        bytes32 ofFundName,
        address ofQuoteAsset,
        uint ofManagementFee,
        uint ofPerformanceFee,
        address ofCompliance,
        address ofRiskMgmt,
        address[] ofExchanges,
        address[] ofDefaultAssets,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) {
        require(!isShutDown);
        require(termsAndConditionsAreSigned(v, r, s));
        require(CompetitionCompliance(COMPLIANCE).isCompetitionAllowed(msg.sender));
        require(managerToFunds[msg.sender] == address(0)); // Add limitation for simpler migration process of shutting down and setting up fund
        address[] memory melonAsDefaultAsset = new address[](1);
        melonAsDefaultAsset[0] = MELON_ASSET; // Melon asset should be in default assets
        address ofFund = new Fund(
            msg.sender,
            ofFundName,
            NATIVE_ASSET,
            0,
            0,
            COMPLIANCE,
            ofRiskMgmt,
            CANONICAL_PRICEFEED,
            ofExchanges,
            melonAsDefaultAsset
        );
        listOfFunds.push(ofFund);
        managerToFunds[msg.sender] = ofFund;
        emit FundUpdated(ofFund);
    }

    /// @dev Dereference Fund and shut it down
    /// @param ofFund Address of the fund to be shut down
    function shutDownFund(address ofFund)
        pre_cond(isShutDown || managerToFunds[msg.sender] == ofFund)
    {
        Fund fund = Fund(ofFund);
        delete managerToFunds[msg.sender];
        fund.shutDown();
        emit FundUpdated(ofFund);
    }

    // PUBLIC VIEW METHODS

    /// @dev Proof that terms and conditions have been read and understood
    /// @param v ellipitc curve parameter v
    /// @param r ellipitc curve parameter r
    /// @param s ellipitc curve parameter s
    /// @return signed Whether or not terms and conditions have been read and understood
    function termsAndConditionsAreSigned(uint8 v, bytes32 r, bytes32 s) view returns (bool signed) {
        return ecrecover(
            // Parity does prepend \x19Ethereum Signed Message:\n{len(message)} before signing.
            //  Signature order has also been changed in 1.6.7 and upcoming 1.7.x,
            //  it will return rsv (same as geth; where v is [27, 28]).
            // Note that if you are using ecrecover, v will be either "00" or "01".
            //  As a result, in order to use this value, you will have to parse it to an
            //  integer and then add 27. This will result in either a 27 or a 28.
            //  https://github.com/ethereum/wiki/wiki/JavaScript-API#web3ethsign
            keccak256("\x19Ethereum Signed Message:\n32", TERMS_AND_CONDITIONS),
            v,
            r,
            s
        ) == msg.sender; // Has sender signed TERMS_AND_CONDITIONS
    }

    function getNativeAsset() view returns (address) { return NATIVE_ASSET; }
    function getFundById(uint withId) view returns (address) { return listOfFunds[withId]; }
    function getLastFundId() view returns (uint) { return listOfFunds.length - 1; }
    function getFundByManager(address ofManager) view returns (address) { return managerToFunds[ofManager]; }
}