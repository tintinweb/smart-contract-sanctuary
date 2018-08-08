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