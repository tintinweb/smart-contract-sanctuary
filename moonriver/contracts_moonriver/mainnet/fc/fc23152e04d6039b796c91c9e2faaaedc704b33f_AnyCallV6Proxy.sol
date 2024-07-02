/**
 *Submitted for verification at moonriver.moonscan.io on 2022-05-30
*/

/**
 *Submitted for verification at polygonscan.com on 2022-05-12
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

/// IApp interface of the application
interface IApp {
    /// (required) call on the destination chain to exec the interaction
    function anyExecute(bytes calldata _data) external returns (bool success, bytes memory result);

    /// (optional,advised) call back on the originating chain if the cross chain interaction fails
    function anyFallback(address _to, bytes calldata _data) external;
}

/// anycall executor is the delegator to execute contract calling (like a sandbox)
contract AnyCallExecutor {
    struct Context {
        address from;
        uint256 fromChainID;
        uint256 nonce;
    }

    Context public context;
    address public creator;

    constructor() {
        creator = msg.sender;
    }

    function execute(
        address _to,
        bytes calldata _data,
        address _from,
        uint256 _fromChainID,
        uint256 _nonce
    ) external returns (bool success, bytes memory result) {
        if (msg.sender != creator) {
            return (false, "AnyCallExecutor: caller is not the creator");
        }
        context = Context({from: _from, fromChainID: _fromChainID, nonce: _nonce});
        (success, result) = IApp(_to).anyExecute(_data);
        context = Context({from: address(0), fromChainID: 0, nonce: 0});
    }
}

/// anycall proxy is a universal protocal to complete cross-chain interaction.
/// 1. the client call `anyCall` on the originating chain
///         to submit a request for a cross chain interaction
/// 2. the mpc network verify the request and call `anyExec` on the destination chain
///         to execute a cross chain interaction
/// 3. if step 2 failed and step 1 has set non-zero fallback,
///         then call `anyFallback` on the originating chain
contract AnyCallV6Proxy {
    // Packed fee information (only 1 storage slot)
    struct FeeData {
        uint128 accruedFees;
        uint128 premium;
    }

    // App config
    struct AppConfig {
        address app; // the application contract address
        address appAdmin; // account who admin the application's config
        uint256 appFlags; // flags of the application
    }

    // Src fee is (baseFees + msg.data.length*feesPerByte)
    struct SrcFeeConfig {
        uint256 baseFees;
        uint256 feesPerByte;
    }

    // Exec record
    struct ExecRecord {
        address to;
        bytes data;
    }

    // Context of the request on originating chain
    struct RequestContext {
        bytes32 txhash;
        address from;
        uint256 fromChainID;
        uint256 nonce;
        uint256 flags;
    }

    // anycall version
    string constant ANYCALL_VERSION = "v6.0";

    // Flags constant
    uint256 public constant FLAG_MERGE_CONFIG_FLAGS = 0x1;
    uint256 public constant FLAG_PAY_FEE_ON_SRC = 0x1 << 1;

    // App Modes constant
    uint256 public constant APPMODE_USE_CUSTOM_SRC_FEES = 0x1;

    // Modes constant
    uint256 public constant PERMISSIONLESS_MODE = 0x1;
    uint256 public constant FREE_MODE = 0x1 << 1;

    // Extra cost of execution (SSTOREs.SLOADs,ADDs,etc..)
    // TODO: analysis to verify the correct overhead gas usage
    uint256 constant EXECUTION_OVERHEAD = 100000;

    // key is app address
    mapping(address => string) public appIdentifier;

    // key is appID, a unique identifier for each project
    mapping(string => AppConfig) public appConfig;
    mapping(string => mapping(address => bool)) public appExecWhitelist;
    mapping(string => address[]) public appHistoryWhitelist;
    mapping(string => bool) public appBlacklist;
    mapping(uint256 => SrcFeeConfig) public srcDefaultFees; // key is chainID
    mapping(string => mapping(uint256 => SrcFeeConfig)) public srcCustomFees;
    mapping(string => uint256) public appDefaultModes;
    mapping(string => mapping(uint256 => uint256)) public appCustomModes;

    mapping(address => bool) public isAdmin;
    address[] public admins;

    address public mpc;
    address public pendingMPC;

    uint256 public mode;
    bool public paused;

    uint256 public minReserveBudget;
    mapping(address => uint256) public executionBudget;
    FeeData private _feeData;

    // applications should give permission to this executor
    AnyCallExecutor public executor;

    mapping(bytes32 => ExecRecord) public retryExecRecords;

    mapping(bytes32 => bool) public execCompleted;
    uint256 nonce;

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1);
        unlocked = 0;
        _;
        unlocked = 1;
    }

    event LogAnyCall(
        address indexed from,
        address indexed to,
        bytes data,
        address _fallback,
        uint256 indexed toChainID,
        uint256 flags,
        string appID,
        uint256 nonce
    );

    event LogAnyExec(
        bytes32 indexed txhash,
        address indexed from,
        address indexed to,
        uint256 fromChainID,
        uint256 nonce,
        bool success,
        bytes result
    );

    event Deposit(address indexed account, uint256 amount);
    event Withdraw(address indexed account, uint256 amount);
    event SetBlacklist(string appID, bool flag);
    event SetWhitelist(string appID, address indexed whitelist, bool flag);
    event UpdatePremium(uint256 oldPremium, uint256 newPremium);
    event AddAdmin(address admin);
    event RemoveAdmin(address admin);
    event ChangeMPC(address indexed oldMPC, address indexed newMPC, uint256 timestamp);
    event ApplyMPC(address indexed oldMPC, address indexed newMPC, uint256 timestamp);
    event SetAppConfig(string appID, address indexed app, address indexed appAdmin, uint256 appFlags);
    event UpgradeApp(string appID, address indexed oldApp, address indexed newApp);
    event StoreRetryExecRecord(bytes32 indexed txhash, address indexed from, address indexed to, uint256 fromChainID, uint256 nonce, bytes data);
    event DoneRetryExecRecord(bytes32 indexed txhash, address indexed from, uint256 fromChainID, uint256 nonce);

    constructor(
        address _admin,
        address _mpc,
        uint128 _premium,
        uint256 _mode
    ) {
        require(_mpc != address(0), "zero mpc address");
        if (_admin != address(0)) {
            isAdmin[_admin] = true;
            admins.push(_admin);
        }
        if (_mpc != _admin) {
            isAdmin[_mpc] = true;
            admins.push(_mpc);
        }

        mpc = _mpc;
        _feeData.premium = _premium;
        mode = _mode;

        executor = new AnyCallExecutor();

        emit ApplyMPC(address(0), _mpc, block.timestamp);
        emit UpdatePremium(0, _premium);
    }

    /// @dev Access control function
    modifier onlyMPC() {
        require(msg.sender == mpc, "only MPC");
        _;
    }

    /// @dev Access control function
    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "only admin");
        _;
    }

    /// @dev pausable control function
    modifier whenNotPaused() {
        require(!paused, "paused");
        _;
    }

    /// @dev Charge an account for execution costs on this chain
    /// @param _from The account to charge for execution costs
    modifier charge(address _from, uint256 _flags) {
        uint256 gasUsed;

        // Prepare charge fee on the destination chain
        if (!_isSet(mode, FREE_MODE)) {
            if (!_isSet(_flags, FLAG_PAY_FEE_ON_SRC)) {
                require(executionBudget[_from] >= minReserveBudget, "less than min budget");
                gasUsed = gasleft() + EXECUTION_OVERHEAD;
            }
        }

        _;

        // Charge fee on the dest chain
        if (gasUsed > 0) {
            uint256 totalCost = (gasUsed - gasleft()) * (tx.gasprice + _feeData.premium);
            uint256 budget = executionBudget[_from];
            require(budget > totalCost, "no enough budget");
            executionBudget[_from] = budget - totalCost;
            _feeData.accruedFees += uint128(totalCost);
        }
    }

    /// @dev set paused flag to pause/unpause functions
    function setPaused(bool _paused) external onlyAdmin {
        paused = _paused;
    }

    function _paySrcFees(uint256 fees) internal {
        require(msg.value >= fees, "no enough src fee");
        if (fees > 0) { // pay fees
            (bool success,) = mpc.call{value: fees}("");
            require(success);
        }
        if (msg.value > fees) { // return remaining amount
            (bool success,) = msg.sender.call{value: msg.value - fees}("");
            require(success);
        }
    }

    /**
        @notice Submit a request for a cross chain interaction
        @param _to The target to interact with on `_toChainID`
        @param _data The calldata supplied for the interaction with `_to`
        @param _fallback The address to call back on the originating chain
            if the cross chain interaction fails
            for security reason, it must be zero or `msg.sender` address
        @param _toChainID The target chain id to interact with
        @param _flags The flags of app on the originating chain
    */
    function anyCall(
        address _to,
        bytes calldata _data,
        address _fallback,
        uint256 _toChainID,
        uint256 _flags
    ) external lock payable whenNotPaused {
        require(_fallback == address(0) || _fallback == msg.sender, "wrong fallback");
        string memory _appID = appIdentifier[msg.sender];

        require(!appBlacklist[_appID], "blacklist");

        bool _permissionlessMode = _isSet(mode, PERMISSIONLESS_MODE);
        if (!_permissionlessMode) {
            require(appExecWhitelist[_appID][msg.sender], "no permission");
        }

        if (!_isSet(mode, FREE_MODE)) {
            AppConfig storage config = appConfig[_appID];
            require(
                (_permissionlessMode && config.app == address(0)) ||
                msg.sender == config.app,
                "app not exist"
            );

            if (_isSet(_flags, FLAG_MERGE_CONFIG_FLAGS) && config.app == msg.sender) {
                _flags |= config.appFlags;
            }

            if (_isSet(_flags, FLAG_PAY_FEE_ON_SRC)) {
                uint256 fees = _calcSrcFees(_appID, _toChainID, _data.length);
                _paySrcFees(fees);
            } else if (msg.value > 0) {
                _paySrcFees(0);
            }
        }

        nonce++;
        emit LogAnyCall(msg.sender, _to, _data, _fallback, _toChainID, _flags, _appID, nonce);
    }

    /**
        @notice Execute a cross chain interaction
        @dev Only callable by the MPC
        @param _to The cross chain interaction target
        @param _data The calldata supplied for interacting with target
        @param _fallback The address to call on originating chain if the interaction fails
        @param _appID The app identifier to check whitelist
        @param _ctx The context of the request on originating chain
    */
    function anyExec(
        address _to,
        bytes memory _data,
        address _fallback,
        string memory _appID,
        RequestContext memory _ctx
    ) external lock whenNotPaused charge(_ctx.from, _ctx.flags) onlyMPC {
        address _from = _ctx.from;

        require(_fallback == address(0) || _fallback == _from, "wrong fallback");

        require(!appBlacklist[_appID], "blacklist");

        if (!_isSet(mode, PERMISSIONLESS_MODE)) {
            require(appExecWhitelist[_appID][_to], "no permission");
        }

        bytes32 uniqID = calcUniqID(_ctx.txhash, _from, _ctx.fromChainID, _ctx.nonce);
        require(!execCompleted[uniqID], "exec completed");

        bool success;
        {
            bytes memory result;
            try executor.execute(_to, _data, _from, _ctx.fromChainID, _ctx.nonce) returns (bool succ, bytes memory res) {
                (success, result) = (succ, res);
            } catch Error(string memory reason) {
                result = bytes(reason);
            } catch (bytes memory reason) {
                result = reason;
            }
            emit LogAnyExec(_ctx.txhash, _from, _to, _ctx.fromChainID, _ctx.nonce, success, result);
        }

        if (success) {
            execCompleted[uniqID] = true;
        } else if (_fallback == address(0)) {
            retryExecRecords[uniqID] = ExecRecord(_to, _data);
            emit StoreRetryExecRecord(_ctx.txhash, _from, _to, _ctx.fromChainID, _ctx.nonce, _data);
        } else {
            // Call the fallback on the originating chain with the call information (to, data)
            nonce++;
            emit LogAnyCall(
                _from,
                _fallback,
                abi.encodeWithSelector(IApp.anyFallback.selector, _to, _data),
                address(0),
                _ctx.fromChainID,
                0, // pay fee on dest chain
                _appID,
                nonce);
        }
    }

    function _isSet(uint256 _value, uint256 _testBits) internal pure returns (bool) {
        return (_value & _testBits) == _testBits;
    }

    // @notice Calc unique ID
    function calcUniqID(bytes32 _txhash, address _from, uint256 _fromChainID, uint256 _nonce) public pure returns (bytes32) {
        return keccak256(abi.encode(_txhash, _from, _fromChainID, _nonce));
    }

    /// @notice Retry stored exec record
    function retryExec(bytes32 _txhash, address _from, uint256 _fromChainID, uint256 _nonce) external {
        bytes32 uniqID = calcUniqID(_txhash, _from, _fromChainID, _nonce);
        require(!execCompleted[uniqID], "exec completed");

        ExecRecord storage record = retryExecRecords[uniqID];
        require(record.to != address(0), "no retry record");

        address _to = record.to;
        bytes memory _data = record.data;

        // Clear record
        record.to = address(0);
        record.data = "";

        (bool success,) = executor.execute(_to, _data, _from, _fromChainID, _nonce);
        require(success);

        execCompleted[uniqID] = true;
        emit DoneRetryExecRecord(_txhash, _from, _fromChainID, _nonce);
    }

    /// @notice Deposit native currency crediting `_account` for execution costs on this chain
    /// @param _account The account to deposit and credit for
    function deposit(address _account) external payable {
        executionBudget[_account] += msg.value;
        emit Deposit(_account, msg.value);
    }

    /// @notice Withdraw a previous deposit from your account
    /// @param _amount The amount to withdraw from your account
    function withdraw(uint256 _amount) external {
        executionBudget[msg.sender] -= _amount;
        emit Withdraw(msg.sender, _amount);
        (bool success,) = msg.sender.call{value: _amount}("");
        require(success);
    }

    /// @notice Withdraw all accrued execution fees
    /// @dev The MPC is credited in the native currency
    function withdrawAccruedFees() external {
        uint256 fees = _feeData.accruedFees;
        _feeData.accruedFees = 0;
        (bool success,) = mpc.call{value: fees}("");
        require(success);
    }

    /// @notice Set app blacklist
    function setBlacklist(string calldata _appID, bool _flag) external onlyAdmin {
        appBlacklist[_appID] = _flag;
        emit SetBlacklist(_appID, _flag);
    }

    /// @notice Set app blacklist in batch
    function setBlacklists(string[] calldata _appIDs, bool _flag) external onlyAdmin {
        for (uint256 i = 0; i < _appIDs.length; i++) {
            this.setBlacklist(_appIDs[i], _flag);
        }
    }

    /// @notice Set the premimum for cross chain executions
    /// @param _premium The premium per gas
    function setPremium(uint128 _premium) external onlyAdmin {
        emit UpdatePremium(_feeData.premium, _premium);
        _feeData.premium = _premium;
    }

    /// @notice Set minimum exection budget for cross chain executions
    /// @param _minBudget The minimum exection budget
    function setMinReserveBudget(uint128 _minBudget) external onlyAdmin {
        minReserveBudget = _minBudget;
    }

    /// @notice Set mode
    function setMode(uint256 _mode) external onlyAdmin {
        mode = _mode;
    }

    /// @notice Change mpc
    function changeMPC(address _mpc) external onlyMPC {
        pendingMPC = _mpc;
        emit ChangeMPC(mpc, _mpc, block.timestamp);
    }

    /// @notice Apply mpc
    function applyMPC() external {
        require(msg.sender == pendingMPC);
        emit ApplyMPC(mpc, pendingMPC, block.timestamp);
        mpc = pendingMPC;
        pendingMPC = address(0);
    }

    /// @notice Get the total accrued fees in native currency
    /// @dev Fees increase when executing cross chain requests
    function accruedFees() external view returns(uint128) {
        return _feeData.accruedFees;
    }

    /// @notice Get the gas premium cost
    /// @dev This is similar to priority fee in eip-1559, except instead of going
    ///     to the miner it is given to the MPC executing cross chain requests
    function premium() external view returns(uint128) {
        return _feeData.premium;
    }

    /// @notice Add admin
    function addAdmin(address _admin) external onlyMPC {
        require(!isAdmin[_admin]);
        isAdmin[_admin] = true;
        admins.push(_admin);
        emit AddAdmin(_admin);
    }

    /// @notice Remove admin
    function removeAdmin(address _admin) external onlyMPC {
        require(isAdmin[_admin]);
        isAdmin[_admin] = false;
        uint256 length = admins.length;
        for (uint256 i = 0; i < length - 1; i++) {
            if (admins[i] == _admin) {
                admins[i] = admins[length - 1];
                break;
            }
        }
        admins.pop();
        emit RemoveAdmin(_admin);
    }

    /// @notice Get all admins
    function getAllAdmins() external view returns (address[] memory) {
        return admins;
    }

    /// @notice Init app config
    function initAppConfig(
        string calldata _appID,
        address _app,
        address _admin,
        uint256 _flags,
        address[] calldata _whitelist
    ) external onlyAdmin {
        require(bytes(_appID).length > 0, "empty appID");
        require(_app != address(0), "zero app address");

        AppConfig storage config = appConfig[_appID];
        require(config.app == address(0), "app exist");

        appIdentifier[_app] = _appID;

        config.app = _app;
        config.appAdmin = _admin;
        config.appFlags = _flags;

        address[] memory whitelist = new address[](1+_whitelist.length);
        whitelist[0] = _app;
        for (uint256 i = 0; i < _whitelist.length; i++) {
            whitelist[i+1] = _whitelist[i];
        }
        _setAppWhitelist(_appID, whitelist, true);

        emit SetAppConfig(_appID, _app, _admin, _flags);
    }

    /// @notice Update app config
    /// can be operated only by mpc or app admin
    /// the config.app will always keep unchanged here
    function updateAppConfig(
        address _app,
        address _admin,
        uint256 _flags,
        address[] calldata _whitelist
    ) external {
        string memory _appID = appIdentifier[_app];
        AppConfig storage config = appConfig[_appID];

        require(config.app == _app && _app != address(0), "app not exist");
        require(msg.sender == mpc || msg.sender == config.appAdmin, "forbid");

        if (_admin != address(0)) {
            config.appAdmin = _admin;
        }
        config.appFlags = _flags;
        if (_whitelist.length > 0) {
            _setAppWhitelist(_appID, _whitelist, true);
        }

        emit SetAppConfig(_appID, _app, _admin, _flags);
    }

    /// @notice Upgrade app
    /// can be operated only by mpc or app admin
    /// change config.app to a new address
    /// require the `_newApp` is not inited
    function upgradeApp(address _oldApp, address _newApp) external {
        string memory _appID = appIdentifier[_oldApp];
        AppConfig storage config = appConfig[_appID];

        require(config.app == _oldApp && _oldApp != address(0), "app not exist");
        require(msg.sender == mpc || msg.sender == config.appAdmin, "forbid");
        require(bytes(appIdentifier[_newApp]).length == 0, "new app is inited");

        config.app = _newApp;

        emit UpgradeApp(_appID, _oldApp, _newApp);
    }

    /// @notice Add whitelist
    function addWhitelist(address _app, address[] memory _whitelist) external {
        string memory _appID = appIdentifier[_app];
        AppConfig storage config = appConfig[_appID];

        require(config.app == _app && _app != address(0), "app not exist");
        require(msg.sender == mpc || msg.sender == config.appAdmin, "forbid");

        _setAppWhitelist(_appID, _whitelist, true);
    }

    /// @notice Remove whitelist
    function removeWhitelist(address _app, address[] memory _whitelist) external {
        string memory _appID = appIdentifier[_app];
        AppConfig storage config = appConfig[_appID];

        require(config.app == _app && _app != address(0), "app not exist");
        require(msg.sender == mpc || msg.sender == config.appAdmin, "forbid");

        _setAppWhitelist(_appID, _whitelist, false);
    }

    function _setAppWhitelist(string memory _appID, address[] memory _whitelist, bool _flag) internal {
        mapping(address => bool) storage whitelist = appExecWhitelist[_appID];
        address[] storage historyWhitelist = appHistoryWhitelist[_appID];
        address addr;
        for (uint256 i = 0; i < _whitelist.length; i++) {
            addr = _whitelist[i];
            if (whitelist[addr] == _flag) {
                continue;
            }
            if (_flag) {
                historyWhitelist.push(addr);
            }
            whitelist[addr] = _flag;
            emit SetWhitelist(_appID, addr, _flag);
        }
    }

    /// @notice Get history whitelist length
    function getHistoryWhitelistLength(string memory _appID) external view returns (uint256) {
        return appHistoryWhitelist[_appID].length;
    }

    /// @notice Get all history whitelist
    function getAllHistoryWhitelist(string memory _appID) external view returns (address[] memory) {
        return appHistoryWhitelist[_appID];
    }

    /// @notice Tidy history whitelist to be same with actual whitelist
    function tidyHistoryWhitelist(string memory _appID) external {
        mapping(address => bool) storage actualWhitelist = appExecWhitelist[_appID];
        address[] storage historyWhitelist = appHistoryWhitelist[_appID];
        uint256 histLength = historyWhitelist.length;
        uint256 popIndex = histLength;
        address addr;
        for (uint256 i = 0; i < popIndex; ) {
            addr = historyWhitelist[i];
            if (actualWhitelist[addr]) {
                i++;
            } else {
                popIndex--;
                historyWhitelist[i] = historyWhitelist[popIndex];
            }
        }
        for (uint256 i = popIndex; i < histLength; i++) {
            historyWhitelist.pop();
        }
    }

    /// @notice Set default src fees
    function setDefaultSrcFees(
        uint256[] calldata _toChainIDs,
        uint256[] calldata _baseFees,
        uint256[] calldata _feesPerByte
    ) external onlyAdmin {
        uint256 length = _toChainIDs.length;
        require(length == _baseFees.length && length == _feesPerByte.length);

        for (uint256 i = 0; i < length; i++) {
            srcDefaultFees[_toChainIDs[i]] = SrcFeeConfig(_baseFees[i], _feesPerByte[i]);
        }
    }

    /// @notice Set custom src fees
    function setCustomSrcFees(
        address _app,
        uint256[] calldata _toChainIDs,
        uint256[] calldata _baseFees,
        uint256[] calldata _feesPerByte
    ) external onlyAdmin {
        string memory _appID = appIdentifier[_app];
        AppConfig storage config = appConfig[_appID];

        require(config.app == _app && _app != address(0), "app not exist");
        require(_isSet(config.appFlags, FLAG_PAY_FEE_ON_SRC), "flag not set");

        uint256 length = _toChainIDs.length;
        require(length == _baseFees.length && length == _feesPerByte.length);

        mapping(uint256 => SrcFeeConfig) storage _srcFees = srcCustomFees[_appID];
        for (uint256 i = 0; i < length; i++) {
            _srcFees[_toChainIDs[i]] = SrcFeeConfig(_baseFees[i], _feesPerByte[i]);
        }
    }

    /// @notice Set app modes
    function setAppModes(
        address _app,
        uint256 _appDefaultMode,
        uint256[] calldata _toChainIDs,
        uint256[] calldata _appCustomModes
    ) external onlyAdmin {
        string memory _appID = appIdentifier[_app];
        AppConfig storage config = appConfig[_appID];
        require(config.app == _app && _app != address(0), "app not exist");

        uint256 length = _toChainIDs.length;
        require(length == _appCustomModes.length);

        appDefaultModes[_appID] = _appDefaultMode;

        for (uint256 i = 0; i < length; i++) {
            appCustomModes[_appID][_toChainIDs[i]] = _appCustomModes[i];
        }
    }

    /// @notice Calc fees
    function calcSrcFees(
        address _app,
        uint256 _toChainID,
        uint256 _dataLength
    ) external view returns (uint256) {
        string memory _appID = appIdentifier[_app];
        return _calcSrcFees(_appID, _toChainID, _dataLength);
    }

    /// @notice Calc fees
    function calcSrcFees(
        string calldata _appID,
        uint256 _toChainID,
        uint256 _dataLength
    ) external view returns (uint256) {
        return _calcSrcFees(_appID, _toChainID, _dataLength);
    }

    /// @notice Is use custom src fees
    function isUseCustomSrcFees(string memory _appID, uint256 _toChainID) public view returns (bool) {
        uint256 _appMode = appCustomModes[_appID][_toChainID];
        if (_isSet(_appMode, APPMODE_USE_CUSTOM_SRC_FEES)) {
            return true;
        }
        _appMode = appDefaultModes[_appID];
        return _isSet(_appMode, APPMODE_USE_CUSTOM_SRC_FEES);
    }

    function _calcSrcFees(
        string memory _appID,
        uint256 _toChainID,
        uint256 _dataLength
    ) internal view returns (uint256) {
        SrcFeeConfig memory customFees = srcCustomFees[_appID][_toChainID];
        uint256 customBaseFees = customFees.baseFees;
        uint256 customFeesPerBytes = customFees.feesPerByte;

        if (isUseCustomSrcFees(_appID, _toChainID)) {
            return customBaseFees + _dataLength * customFeesPerBytes;
        }

        SrcFeeConfig memory defaultFees = srcDefaultFees[_toChainID];
        uint256 defaultBaseFees = defaultFees.baseFees;
        uint256 defaultFeesPerBytes = defaultFees.feesPerByte;

        uint256 baseFees = (customBaseFees > defaultBaseFees) ? customBaseFees : defaultBaseFees;
        uint256 feesPerByte = (customFeesPerBytes > defaultFeesPerBytes) ? customFeesPerBytes : defaultFeesPerBytes;

        return baseFees + _dataLength * feesPerByte;
    }
}