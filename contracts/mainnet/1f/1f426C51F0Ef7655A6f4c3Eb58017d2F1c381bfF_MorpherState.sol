pragma solidity 0.5.16;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IMorpherToken.sol";

// ----------------------------------------------------------------------------------
// Data and token balance storage of the Morpher platform
// Writing access is only granted to platform contracts. The contract can be paused
// by an elected platform administrator (see MorpherGovernance) to perform protocol updates.
// ----------------------------------------------------------------------------------

contract MorpherState is Ownable {
    using SafeMath for uint256;

    bool public mainChain;
    uint256 public totalSupply;
    uint256 public totalToken;
    uint256 public totalInPositions;
    uint256 public totalOnOtherChain;
    uint256 public maximumLeverage = 10**9; // Leverage precision is 1e8, maximum leverage set to 10 initially
    uint256 constant PRECISION = 10**8;
    uint256 constant DECIMALS = 18;
    uint256 constant REWARDPERIOD = 1 days;
    bool public paused = false;

    address public morpherGovernance;
    address public morpherRewards;
    address public administrator;
    address public oracleContract;
    address public sideChainOperator;
    address public morpherBridge;
    address public morpherToken;

    uint256 public rewardBasisPoints;
    uint256 public lastRewardTime;

    bytes32 public sideChainMerkleRoot;
    uint256 public sideChainMerkleRootWrittenAtTime;

    // Set initial withdraw limit from sidechain to 20m token or 2% of initial supply
    uint256 public mainChainWithdrawLimit24 = 2 * 10**25;

    mapping(address => bool) private stateAccess;
    mapping(address => bool) private transferAllowed;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowed;

    mapping(bytes32 => bool) private marketActive;

    // ----------------------------------------------------------------------------
    // Position struct records virtual futures
    // ----------------------------------------------------------------------------
    struct position {
        uint256 lastUpdated;
        uint256 longShares;
        uint256 shortShares;
        uint256 meanEntryPrice;
        uint256 meanEntrySpread;
        uint256 meanEntryLeverage;
        uint256 liquidationPrice;
        bytes32 positionHash;
    }

    // ----------------------------------------------------------------------------
    // A portfolio is an address specific collection of postions
    // ----------------------------------------------------------------------------
    mapping(address => mapping(bytes32 => position)) private portfolio;

    // ----------------------------------------------------------------------------
    // Record all addresses that hold a position of a market, needed for clean stock splits
    // ----------------------------------------------------------------------------
    struct hasExposure {
        uint256 maxMappingIndex;
        mapping(address => uint256) index;
        mapping(uint256 => address) addy;
    }

    mapping(bytes32 => hasExposure) private exposureByMarket;

    // ----------------------------------------------------------------------------
    // Bridge Variables
    // ----------------------------------------------------------------------------
    mapping (address => uint256) private tokenClaimedOnThisChain;
    mapping (address => uint256) private tokenSentToLinkedChain;
    mapping (address => uint256) private tokenSentToLinkedChainTime;
    mapping (bytes32 => bool) private positionClaimedOnMainChain;

    uint256 public lastWithdrawLimitReductionTime;
    uint256 public last24HoursAmountWithdrawn;
    uint256 public withdrawLimit24Hours;
    uint256 public inactivityPeriod = 3 days;
    uint256 public transferNonce;
    bool public fastTransfersEnabled;

    // ----------------------------------------------------------------------------
    // Sidechain spam protection
    // ----------------------------------------------------------------------------

    mapping(address => uint256) private lastRequestBlock;
    mapping(address => uint256) private numberOfRequests;
    uint256 public numberOfRequestsLimit;

    // ----------------------------------------------------------------------------
    // Events
    // ----------------------------------------------------------------------------
    event StateAccessGranted(address indexed whiteList, uint256 indexed blockNumber);
    event StateAccessDenied(address indexed blackList, uint256 indexed blockNumber);

    event TransfersEnabled(address indexed whiteList);
    event TransfersDisabled(address indexed blackList);

    event Transfer(address indexed sender, address indexed recipient, uint256 amount);
    event Mint(address indexed recipient, uint256 amount, uint256 totalToken);
    event Burn(address indexed recipient, uint256 amount, uint256 totalToken);
    event NewTotalSupply(uint256 newTotalSupply);
    event NewTotalOnOtherChain(uint256 newTotalOnOtherChain);
    event NewTotalInPositions(uint256 newTotalOnOtherChain);
    event OperatingRewardMinted(address indexed recipient, uint256 amount);

    event RewardsChange(address indexed rewardsAddress, uint256 indexed rewardsBasisPoints);
    event LastRewardTime(uint256 indexed rewardsTime);
    event GovernanceChange(address indexed governanceAddress);
    event TokenChange(address indexed tokenAddress);
    event AdministratorChange(address indexed administratorAddress);
    event OracleChange(address indexed oracleContract);
    event MaximumLeverageChange(uint256 maxLeverage);
    event MarketActivated(bytes32 indexed activateMarket);
    event MarketDeActivated(bytes32 indexed deActivateMarket);
    event BridgeChange(address _bridgeAddress);
    event SideChainMerkleRootUpdate(bytes32 indexed sideChainMerkleRoot);
    event NewSideChainOperator(address indexed sideChainOperator);
    event NumberOfRequestsLimitUpdate(uint256 _numberOfRequests);

    event MainChainWithdrawLimitUpdate(uint256 indexed mainChainWithdrawLimit24);
    event TokenSentToLinkedChain(address _address, uint256 _token, uint256 _totalTokenSent, bytes32 indexed _tokenSentToLinkedChainHash);
    event TransferredTokenClaimed(address _address, uint256 _token);
    event LastWithdrawAt();
    event RollingWithdrawnAmountUpdated(uint256 _last24HoursAmountWithdrawn, uint256 _lastWithdrawLimitReductionTime);
    event WithdrawLimitUpdated(uint256 _amount);
    event InactivityPeriodUpdated(uint256 _periodLength);
    event FastWithdrawsDisabled();
    event NewBridgeNonce(uint256 _transferNonce);
    event Last24HoursAmountWithdrawnReset();

    event StatePaused(address administrator, bool _paused);

    event SetAllowance(address indexed sender, address indexed spender, uint256 tokens);
    event SetPosition(bytes32 indexed positionHash,
        address indexed sender,
        bytes32 indexed marketId,
        uint256 timeStamp,
        uint256 longShares,
        uint256 shortShares,
        uint256 meanEntryPrice,
        uint256 meanEntrySpread,
        uint256 meanEntryLeverage,
        uint256 liquidationPrice
    );
    event SetBalance(address indexed account, uint256 balance, bytes32 indexed balanceHash);
    event TokenTransferredToOtherChain(address indexed account, uint256 tokenTransferredToOtherChain, bytes32 indexed transferHash);

    modifier notPaused {
        require(paused == false, "MorpherState: Contract paused, aborting");
        _;
    }

    modifier onlyPlatform {
        require(stateAccess[msg.sender] == true, "MorpherState: Only Platform is allowed to execute operation.");
        _;
    }

    modifier onlyGovernance {
        require(msg.sender == getGovernance(), "MorpherState: Calling contract not the Governance Contract. Aborting.");
        _;
    }

    modifier onlyAdministrator {
        require(msg.sender == getAdministrator(), "MorpherState: Caller is not the Administrator. Aborting.");
        _;
    }

    modifier onlySideChainOperator {
        require(msg.sender == sideChainOperator, "MorpherState: Caller is not the Sidechain Operator. Aborting.");
        _;
    }

    modifier canTransfer {
        require(getCanTransfer(msg.sender), "MorpherState: Caller may not transfer token. Aborting.");
        _;
    }

    modifier onlyBridge {
        require(msg.sender == getMorpherBridge(), "MorpherState: Caller is not the Bridge. Aborting.");
        _;
    }

    modifier onlyMainChain {
        require(mainChain == true, "MorpherState: Can only be called on mainchain.");
        _;
    }

    modifier onlySideChain {
        require(mainChain == false, "MorpherState: Can only be called on mainchain.");
        _;
    }

    constructor(bool _mainChain, address _sideChainOperator, address _morpherTreasury) public {
        // @Deployer: Transfer State Ownership to cold storage address after deploying protocol
        mainChain = _mainChain; // true for Ethereum, false for Morpher PoA sidechain
        setLastRewardTime(now);
        uint256 _sideChainMint = 575000000 * 10**(DECIMALS);
        uint256 _mainChainMint = 425000000 * 10**(DECIMALS);
        grantAccess(owner());
        setSideChainOperator(owner());
        if (mainChain == false) { // Create token only on sidechain
            balances[owner()] = _sideChainMint; // Create airdrop and team token on sidechain
            totalToken = _sideChainMint;
            emit Mint(owner(), balanceOf(owner()), _sideChainMint);
            setRewardBasisPoints(0); // Reward is minted on mainchain
            setRewardAddress(address(0));
            setTotalOnOtherChain(_mainChainMint);
        } else {
            balances[owner()] = _mainChainMint; // Create treasury and investor token on mainchain
            totalToken = _mainChainMint;
            emit Mint(owner(), balanceOf(owner()), _mainChainMint);
            setRewardBasisPoints(15000); // 15000 / PRECISION = 0.00015
            setRewardAddress(_morpherTreasury);
            setTotalOnOtherChain(_sideChainMint);
        }
        fastTransfersEnabled = true;
        setNumberOfRequestsLimit(3);
        setMainChainWithdrawLimit(totalSupply / 50);
        setSideChainOperator(_sideChainOperator);
        denyAccess(owner());
    }

    // ----------------------------------------------------------------------------
    // Setter/Getter functions for market wise exposure
    // ----------------------------------------------------------------------------

    function getMaxMappingIndex(bytes32 _marketId) public view returns(uint256 _maxMappingIndex) {
        return exposureByMarket[_marketId].maxMappingIndex;
    }

    function getExposureMappingIndex(bytes32 _marketId, address _address) public view returns(uint256 _mappingIndex) {
        return exposureByMarket[_marketId].index[_address];
    }

    function getExposureMappingAddress(bytes32 _marketId, uint256 _mappingIndex) public view returns(address _address) {
        return exposureByMarket[_marketId].addy[_mappingIndex];
    }

    function setMaxMappingIndex(bytes32 _marketId, uint256 _maxMappingIndex) public onlyPlatform {
        exposureByMarket[_marketId].maxMappingIndex = _maxMappingIndex;
    }

    function setExposureMapping(bytes32 _marketId, address _address, uint256 _index) public onlyPlatform  {
        setExposureMappingIndex(_marketId, _address, _index);
        setExposureMappingAddress(_marketId, _address, _index);
    }

    function setExposureMappingIndex(bytes32 _marketId, address _address, uint256 _index) public onlyPlatform {
        exposureByMarket[_marketId].index[_address] = _index;
    }

    function setExposureMappingAddress(bytes32 _marketId, address _address, uint256 _index) public onlyPlatform {
        exposureByMarket[_marketId].addy[_index] = _address;
    }

    // ----------------------------------------------------------------------------
    // Setter/Getter functions for bridge variables
    // ----------------------------------------------------------------------------
    function setTokenClaimedOnThisChain(address _address, uint256 _token) public onlyBridge {
        tokenClaimedOnThisChain[_address] = _token;
        emit TransferredTokenClaimed(_address, _token);
    }

    function getTokenClaimedOnThisChain(address _address) public view returns (uint256 _token) {
        return tokenClaimedOnThisChain[_address];
    }

    function setTokenSentToLinkedChain(address _address, uint256 _token) public onlyBridge {
        tokenSentToLinkedChain[_address] = _token;
        tokenSentToLinkedChainTime[_address] = now;
        emit TokenSentToLinkedChain(_address, _token, tokenSentToLinkedChain[_address], getBalanceHash(_address, tokenSentToLinkedChain[_address]));
    }

    function getTokenSentToLinkedChain(address _address) public view returns (uint256 _token) {
        return tokenSentToLinkedChain[_address];
    }

    function getTokenSentToLinkedChainTime(address _address) public view returns (uint256 _timeStamp) {
        return tokenSentToLinkedChainTime[_address];
    }

    function add24HoursWithdrawn(uint256 _amount) public onlyBridge {
        last24HoursAmountWithdrawn = last24HoursAmountWithdrawn.add(_amount);
        emit RollingWithdrawnAmountUpdated(last24HoursAmountWithdrawn, lastWithdrawLimitReductionTime);
    }

    function update24HoursWithdrawLimit(uint256 _amount) public onlyBridge {
        if (last24HoursAmountWithdrawn > _amount) {
            last24HoursAmountWithdrawn = last24HoursAmountWithdrawn.sub(_amount);
        } else {
            last24HoursAmountWithdrawn = 0;
        }
        lastWithdrawLimitReductionTime = now;
        emit RollingWithdrawnAmountUpdated(last24HoursAmountWithdrawn, lastWithdrawLimitReductionTime);
    }

    function set24HourWithdrawLimit(uint256 _limit) public onlyBridge {
        withdrawLimit24Hours = _limit;
        emit WithdrawLimitUpdated(_limit);
    }

    function resetLast24HoursAmountWithdrawn() public onlyBridge {
        last24HoursAmountWithdrawn = 0;
        emit Last24HoursAmountWithdrawnReset();
    }

    function setInactivityPeriod(uint256 _periodLength) public onlyBridge {
        inactivityPeriod = _periodLength;
        emit InactivityPeriodUpdated(_periodLength);
    }

    function getBridgeNonce() public onlyBridge returns (uint256 _nonce) {
        transferNonce++;
        emit NewBridgeNonce(transferNonce);
        return transferNonce;
    }

    function disableFastWithdraws() public onlyBridge {
        fastTransfersEnabled = false;
        emit FastWithdrawsDisabled();
    }

    function setPositionClaimedOnMainChain(bytes32 _positionHash) public onlyBridge {
        positionClaimedOnMainChain[_positionHash] = true;
    }

    function getPositionClaimedOnMainChain(bytes32 _positionHash) public view returns (bool _alreadyClaimed) {
        return positionClaimedOnMainChain[_positionHash];
    }

    // ----------------------------------------------------------------------------
    // Setter/Getter functions for spam protection
    // ----------------------------------------------------------------------------

    function setLastRequestBlock(address _address) public onlyPlatform {
        lastRequestBlock[_address] = block.number;
    }

    function getLastRequestBlock(address _address) public view returns(uint256 _lastRequestBlock) {
        return lastRequestBlock[_address];
    }

    function setNumberOfRequests(address _address, uint256 _numberOfRequests) public onlyPlatform {
        numberOfRequests[_address] = _numberOfRequests;
    }

    function increaseNumberOfRequests(address _address) public onlyPlatform{
        numberOfRequests[_address]++;
    }

    function getNumberOfRequests(address _address) public view returns(uint256 _numberOfRequests) {
        return numberOfRequests[_address];
    }

    function setNumberOfRequestsLimit(uint256 _numberOfRequestsLimit) public onlyPlatform {
        numberOfRequestsLimit = _numberOfRequestsLimit;
        emit NumberOfRequestsLimitUpdate(_numberOfRequestsLimit);
    }

    function getNumberOfRequestsLimit() public view returns (uint256 _numberOfRequestsLimit) {
        return numberOfRequestsLimit;
    }

    function setMainChainWithdrawLimit(uint256 _mainChainWithdrawLimit24) public onlyOwner {
        mainChainWithdrawLimit24 = _mainChainWithdrawLimit24;
        emit MainChainWithdrawLimitUpdate(_mainChainWithdrawLimit24);
    }

    function getMainChainWithdrawLimit() public view returns (uint256 _mainChainWithdrawLimit24) {
        return mainChainWithdrawLimit24;
    }

    // ----------------------------------------------------------------------------
    // Setter/Getter functions for state access
    // ----------------------------------------------------------------------------

    function grantAccess(address _address) public onlyOwner {
        stateAccess[_address] = true;
        emit StateAccessGranted(_address, block.number);
    }

    function denyAccess(address _address) public onlyOwner {
        stateAccess[_address] = false;
        emit StateAccessDenied(_address, block.number);
    }

    function getStateAccess(address _address) public view returns(bool _hasAccess) {
        return stateAccess[_address];
    }

    // ----------------------------------------------------------------------------
    // Setter/Getter functions for addresses that can transfer tokens (sidechain only)
    // ----------------------------------------------------------------------------

    function enableTransfers(address _address) public onlyOwner {
        transferAllowed[_address] = true;
        emit TransfersEnabled(_address);
    }

    function disableTransfers(address _address) public onlyOwner {
        transferAllowed[_address] = false;
        emit TransfersDisabled(_address);
    }

    function getCanTransfer(address _address) public view returns(bool _hasAccess) {
        return transferAllowed[_address];
    }

    // ----------------------------------------------------------------------------
    // Minting/burning/transfer of token
    // ----------------------------------------------------------------------------

    function transfer(address _from, address _to, uint256 _token) public onlyPlatform notPaused {
        require(balances[_from] >= _token, "MorpherState: Not enough token.");
        balances[_from] = balances[_from].sub(_token);
        balances[_to] = balances[_to].add(_token);
        IMorpherToken(morpherToken).emitTransfer(_from, _to, _token);
        emit Transfer(_from, _to, _token);
        emit SetBalance(_from, balances[_from], getBalanceHash(_from, balances[_from]));
        emit SetBalance(_to, balances[_to], getBalanceHash(_to, balances[_to]));
    }

    function mint(address _address, uint256 _token) public onlyPlatform notPaused {
        balances[_address] = balances[_address].add(_token);
        totalToken = totalToken.add(_token);
        updateTotalSupply();
        IMorpherToken(morpherToken).emitTransfer(address(0), _address, _token);
        emit Mint(_address, _token, totalToken);
        emit SetBalance(_address, balances[_address], getBalanceHash(_address, balances[_address]));
    }

    function burn(address _address, uint256 _token) public onlyPlatform notPaused {
        require(balances[_address] >= _token, "MorpherState: Not enough token.");
        balances[_address] = balances[_address].sub(_token);
        totalToken = totalToken.sub(_token);
        updateTotalSupply();
        IMorpherToken(morpherToken).emitTransfer(_address, address(0), _token);
        emit Burn(_address, _token, totalToken);
        emit SetBalance(_address, balances[_address], getBalanceHash(_address, balances[_address]));
    }

    // ----------------------------------------------------------------------------
    // Setter/Getter functions for balance and token functions (ERC20)
    // ----------------------------------------------------------------------------
    function updateTotalSupply() private {
        totalSupply = totalToken.add(totalInPositions).add(totalOnOtherChain);
        emit NewTotalSupply(totalSupply);
    }

    function setTotalInPositions(uint256 _totalInPositions) public onlyAdministrator {
        totalInPositions = _totalInPositions;
        updateTotalSupply();
        emit NewTotalInPositions(_totalInPositions);
    }

    function setTotalOnOtherChain(uint256 _newTotalOnOtherChain) public onlySideChainOperator {
        totalOnOtherChain = _newTotalOnOtherChain;
        updateTotalSupply();
        emit NewTotalOnOtherChain(_newTotalOnOtherChain);
    }

    function balanceOf(address _tokenOwner) public view returns (uint256 balance) {
        return balances[_tokenOwner];
    }

    function setAllowance(address _from, address _spender, uint256 _tokens) public onlyPlatform {
        allowed[_from][_spender] = _tokens;
        emit SetAllowance(_from, _spender, _tokens);
    }

    function getAllowance(address _tokenOwner, address spender) public view returns (uint256 remaining) {
        return allowed[_tokenOwner][spender];
    }

    // ----------------------------------------------------------------------------
    // Setter/Getter functions for platform roles
    // ----------------------------------------------------------------------------

    function setGovernanceContract(address _newGovernanceContractAddress) public onlyOwner {
        morpherGovernance = _newGovernanceContractAddress;
        emit GovernanceChange(_newGovernanceContractAddress);
    }

    function getGovernance() public view returns (address _governanceContract) {
        return morpherGovernance;
    }

    function setMorpherBridge(address _newBridge) public onlyOwner {
        morpherBridge = _newBridge;
        emit BridgeChange(_newBridge);
    }

    function getMorpherBridge() public view returns (address _currentBridge) {
        return morpherBridge;
    }

    function setOracleContract(address _newOracleContract) public onlyGovernance {
        oracleContract = _newOracleContract;
        emit OracleChange(_newOracleContract);
    }

    function getOracleContract() public view returns(address) {
        return oracleContract;
    }

    function setTokenContract(address _newTokenContract) public onlyOwner {
        morpherToken = _newTokenContract;
        emit TokenChange(_newTokenContract);
    }

    function getTokenContract() public view returns(address) {
        return morpherToken;
    }

    function setAdministrator(address _newAdministrator) public onlyGovernance {
        administrator = _newAdministrator;
        emit AdministratorChange(_newAdministrator);
    }

    function getAdministrator() public view returns(address) {
        return administrator;
    }

    // ----------------------------------------------------------------------------
    // Setter/Getter functions for platform operating rewards
    // ----------------------------------------------------------------------------

    function setRewardAddress(address _newRewardsAddress) public onlyOwner {
        morpherRewards = _newRewardsAddress;
        emit RewardsChange(_newRewardsAddress, rewardBasisPoints);
    }

    function setRewardBasisPoints(uint256 _newRewardBasisPoints) public onlyOwner {
        if (mainChain == true) {
            require(_newRewardBasisPoints <= 15000, "MorpherState: Reward basis points need to be less or equal to 15000.");
        } else {
            require(_newRewardBasisPoints == 0, "MorpherState: Reward basis points can only be set on Ethereum.");
        }
        rewardBasisPoints = _newRewardBasisPoints;
        emit RewardsChange(morpherRewards, _newRewardBasisPoints);
    }

    function setLastRewardTime(uint256 _lastRewardTime) private {
        lastRewardTime = _lastRewardTime;
        emit LastRewardTime(_lastRewardTime);
    }

    // ----------------------------------------------------------------------------
    // Setter/Getter functions for platform administration
    // ----------------------------------------------------------------------------

    function activateMarket(bytes32 _activateMarket) public onlyAdministrator {
        marketActive[_activateMarket] = true;
        emit MarketActivated(_activateMarket);
    }

    function deActivateMarket(bytes32 _deActivateMarket) public onlyAdministrator {
        marketActive[_deActivateMarket] = false;
        emit MarketDeActivated(_deActivateMarket);
    }

    function getMarketActive(bytes32 _marketId) public view returns(bool _active) {
        return marketActive[_marketId];
    }

    function setMaximumLeverage(uint256 _newMaximumLeverage) public onlyAdministrator {
        require(_newMaximumLeverage > PRECISION, "MorpherState: Leverage precision is 1e8");
        maximumLeverage = _newMaximumLeverage;
        emit MaximumLeverageChange(_newMaximumLeverage);
    }

    function getMaximumLeverage() public view returns(uint256 _maxLeverage) {
        return maximumLeverage;
    }

    function pauseState() public onlyAdministrator {
        paused = true;
        emit StatePaused(msg.sender, true);
    }

    function unPauseState() public onlyAdministrator {
        paused = false;
        emit StatePaused(msg.sender, false);
    }

    // ----------------------------------------------------------------------------
    // Setter/Getter for side chain state
    // ----------------------------------------------------------------------------

    function setSideChainMerkleRoot(bytes32 _sideChainMerkleRoot) public onlyBridge {
        sideChainMerkleRoot = _sideChainMerkleRoot;
        sideChainMerkleRootWrittenAtTime = now;
        payOperatingReward;
        emit SideChainMerkleRootUpdate(_sideChainMerkleRoot);
    }

    function getSideChainMerkleRoot() public view returns(bytes32 _sideChainMerkleRoot) {
        return sideChainMerkleRoot;
    }

    function setSideChainOperator(address _address) public onlyOwner {
        sideChainOperator = _address;
        emit NewSideChainOperator(_address);
    }

    function getSideChainOperator() public view returns (address _address) {
        return sideChainOperator;
    }

    function getSideChainMerkleRootWrittenAtTime() public view returns(uint256 _sideChainMerkleRoot) {
        return sideChainMerkleRootWrittenAtTime;
    }

    // ----------------------------------------------------------------------------
    // Setter/Getter functions for portfolio
    // ----------------------------------------------------------------------------

    function setPosition(
        address _address,
        bytes32 _marketId,
        uint256 _timeStamp,
        uint256 _longShares,
        uint256 _shortShares,
        uint256 _meanEntryPrice,
        uint256 _meanEntrySpread,
        uint256 _meanEntryLeverage,
        uint256 _liquidationPrice
    ) public onlyPlatform {
        portfolio[_address][_marketId].lastUpdated = _timeStamp;
        portfolio[_address][_marketId].longShares = _longShares;
        portfolio[_address][_marketId].shortShares = _shortShares;
        portfolio[_address][_marketId].meanEntryPrice = _meanEntryPrice;
        portfolio[_address][_marketId].meanEntrySpread = _meanEntrySpread;
        portfolio[_address][_marketId].meanEntryLeverage = _meanEntryLeverage;
        portfolio[_address][_marketId].liquidationPrice = _liquidationPrice;
        portfolio[_address][_marketId].positionHash = getPositionHash(
            _address,
            _marketId,
            _timeStamp,
            _longShares,
            _shortShares,
            _meanEntryPrice,
            _meanEntrySpread,
            _meanEntryLeverage,
            _liquidationPrice
        );
        if (_longShares > 0 || _shortShares > 0) {
            addExposureByMarket(_marketId, _address);
        } else {
            deleteExposureByMarket(_marketId, _address);
        }
        emit SetPosition(
            portfolio[_address][_marketId].positionHash,
            _address,
            _marketId,
            _timeStamp,
            _longShares,
            _shortShares,
            _meanEntryPrice,
            _meanEntrySpread,
            _meanEntryLeverage,
            _liquidationPrice
        );
    }

    function getPosition(
        address _address,
        bytes32 _marketId
    ) public view returns (
        uint256 _longShares,
        uint256 _shortShares,
        uint256 _meanEntryPrice,
        uint256 _meanEntrySpread,
        uint256 _meanEntryLeverage,
        uint256 _liquidationPrice
    ) {
        return(
        portfolio[_address][_marketId].longShares,
        portfolio[_address][_marketId].shortShares,
        portfolio[_address][_marketId].meanEntryPrice,
        portfolio[_address][_marketId].meanEntrySpread,
        portfolio[_address][_marketId].meanEntryLeverage,
        portfolio[_address][_marketId].liquidationPrice
        );
    }

    function getPositionHash(
        address _address,
        bytes32 _marketId,
        uint256 _timeStamp,
        uint256 _longShares,
        uint256 _shortShares,
        uint256 _meanEntryPrice,
        uint256 _meanEntrySpread,
        uint256 _meanEntryLeverage,
        uint256 _liquidationPrice
    ) public pure returns (bytes32 _hash) {
        return keccak256(
            abi.encodePacked(
                _address,
                _marketId,
                _timeStamp,
                _longShares,
                _shortShares,
                _meanEntryPrice,
                _meanEntrySpread,
                _meanEntryLeverage,
                _liquidationPrice
            )
        );
    }

    function getBalanceHash(address _address, uint256 _balance) public pure returns (bytes32 _hash) {
        return keccak256(abi.encodePacked(_address, _balance));
    }

    function getLastUpdated(address _address, bytes32 _marketId) public view returns (uint256 _lastUpdated) {
        return(portfolio[_address][_marketId].lastUpdated);
    }

    function getLongShares(address _address, bytes32 _marketId) public view returns (uint256 _longShares) {
        return(portfolio[_address][_marketId].longShares);
    }

    function getShortShares(address _address, bytes32 _marketId) public view returns (uint256 _shortShares) {
        return(portfolio[_address][_marketId].shortShares);
    }

    function getMeanEntryPrice(address _address, bytes32 _marketId) public view returns (uint256 _meanEntryPrice) {
        return(portfolio[_address][_marketId].meanEntryPrice);
    }

    function getMeanEntrySpread(address _address, bytes32 _marketId) public view returns (uint256 _meanEntrySpread) {
        return(portfolio[_address][_marketId].meanEntrySpread);
    }

    function getMeanEntryLeverage(address _address, bytes32 _marketId) public view returns (uint256 _meanEntryLeverage) {
        return(portfolio[_address][_marketId].meanEntryLeverage);
    }

    function getLiquidationPrice(address _address, bytes32 _marketId) public view returns (uint256 _liquidationPrice) {
        return(portfolio[_address][_marketId].liquidationPrice);
    }

    // ----------------------------------------------------------------------------
    // Record positions by market by address. Needed for exposure aggregations
    // and spits and dividends.
    // ----------------------------------------------------------------------------
    function addExposureByMarket(bytes32 _symbol, address _address) private {
        // Address must not be already recored
        uint256 _myExposureIndex = getExposureMappingIndex(_symbol, _address);
        if (_myExposureIndex == 0) {
            uint256 _maxMappingIndex = getMaxMappingIndex(_symbol).add(1);
            setMaxMappingIndex(_symbol, _maxMappingIndex);
            setExposureMapping(_symbol, _address, _maxMappingIndex);
        }
    }

    function deleteExposureByMarket(bytes32 _symbol, address _address) private {
        // Get my index in mapping
        uint256 _myExposureIndex = getExposureMappingIndex(_symbol, _address);
        // Get last element of mapping
        uint256 _lastIndex = getMaxMappingIndex(_symbol);
        address _lastAddress = getExposureMappingAddress(_symbol, _lastIndex);
        // If _myExposureIndex is greater than 0 (i.e. there is an exposure of that address on that market) delete it
        if (_myExposureIndex > 0) {
            // If _myExposureIndex is less than _lastIndex overwrite element at _myExposureIndex with element at _lastIndex in
            // deleted elements position.
            if (_myExposureIndex < _lastIndex) {
                setExposureMappingAddress(_symbol, _lastAddress, _myExposureIndex);
                setExposureMappingIndex(_symbol, _lastAddress, _myExposureIndex);
            }
            // Delete _lastIndex and _lastAddress element and reduce maxExposureIndex
            setExposureMappingAddress(_symbol, address(0), _lastIndex);
            setExposureMappingIndex(_symbol, _address, 0);
            // Shouldn't happen, but check that not empty
            if (_lastIndex > 0) {
                setMaxMappingIndex(_symbol, _lastIndex.sub(1));
            }
        }
    }

    // ----------------------------------------------------------------------------
    // Calculate and send operating reward
    // Every 24 hours the protocol mints rewardBasisPoints/(PRECISION) percent of the total
    // supply as reward for the protocol operator. The amount can not exceed 0.015% per
    // day.
    // ----------------------------------------------------------------------------

    function payOperatingReward() public onlyMainChain {
        if (now > lastRewardTime.add(REWARDPERIOD)) {
            uint256 _reward = totalSupply.mul(rewardBasisPoints).div(PRECISION);
            setLastRewardTime(lastRewardTime.add(REWARDPERIOD));
            mint(morpherRewards, _reward);
            emit OperatingRewardMinted(morpherRewards, _reward);
        }
    }
}