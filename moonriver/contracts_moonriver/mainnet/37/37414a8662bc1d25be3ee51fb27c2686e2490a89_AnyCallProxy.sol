/**
 *Submitted for verification at moonriver.moonscan.io on 2022-04-11
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

contract AnyCallProxy {
    // Context information for destination chain targets
    struct Context {
        address sender;
        uint256 fromChainID;
    }

    // Packed fee information (only 1 storage slot)
    struct FeeData {
        uint128 accruedFees;
        uint128 premium;
    }

    // Packed MPC transfer info (only 1 storage slot)
    struct TransferData {
        uint96 effectiveTime;
        address pendingMPC;
    }

    // Extra cost of execution (SSTOREs.SLOADs,ADDs,etc..)
    // TODO: analysis to verify the correct overhead gas usage
    uint256 constant EXECUTION_OVERHEAD = 100000;

    address public mpc;

    mapping(address => bool) public blacklist;
    mapping(address => mapping(address => mapping(uint256 => bool))) public whitelist;

    Context public context;

    uint256 public minReserveBudget;
    mapping(address => uint256) public executionBudget;
    FeeData private _feeData;

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
        uint256 indexed toChainID
    );

    event LogAnyExec(
        address indexed from,
        address indexed to,
        bytes data,
        bool success,
        bytes result,
        address _fallback,
        uint256 indexed fromChainID
    );

    event Deposit(address indexed account, uint256 amount);
    event Withdrawl(address indexed account, uint256 amount);
    event SetBlacklist(address indexed account, bool flag);
    event SetWhitelist(
        address indexed from,
        address indexed to,
        uint256 indexed toChainID,
        bool flag
    );
    event TransferMPC(address oldMPC, address newMPC, uint256 effectiveTime);
    event UpdatePremium(uint256 oldPremium, uint256 newPremium);

    constructor(address _mpc, uint128 _premium) {
        mpc = _mpc;
        _feeData.premium = _premium;

        emit TransferMPC(address(0), _mpc, block.timestamp);
        emit UpdatePremium(0, _premium);
    }

    /// @dev Access control function
    modifier onlyMPC() {
        require(msg.sender == mpc); // dev: only MPC
        _;
    }

    /// @dev Charge an account for execution costs on this chain
    /// @param _from The account to charge for execution costs
    modifier charge(address _from) {
        require(executionBudget[_from] >= minReserveBudget);
        uint256 gasUsed = gasleft() + EXECUTION_OVERHEAD;
        _;
        uint256 totalCost = (gasUsed - gasleft()) * (tx.gasprice + _feeData.premium);

        executionBudget[_from] -= totalCost;
        _feeData.accruedFees += uint128(totalCost);
    }

    /**
        @notice Submit a request for a cross chain interaction
        @param _to The target to interact with on `_toChainID`
        @param _data The calldata supplied for the interaction with `_to`
        @param _fallback The address to call back on the originating chain
            if the cross chain interaction fails
        @param _toChainID The target chain id to interact with
    */
    function anyCall(
        address _to,
        bytes calldata _data,
        address _fallback,
        uint256 _toChainID
    ) external {
        require(!blacklist[msg.sender]); // dev: caller is blacklisted
        require(whitelist[msg.sender][_to][_toChainID]); // dev: request denied

        emit LogAnyCall(msg.sender, _to, _data, _fallback, _toChainID);
    }

    /**
        @notice Execute a cross chain interaction
        @dev Only callable by the MPC
        @param _from The request originator
        @param _to The cross chain interaction target
        @param _data The calldata supplied for interacting with target
        @param _fallback The address to call on `_fromChainID` if the interaction fails
        @param _fromChainID The originating chain id
    */
    function anyExec(
        address _from,
        address _to,
        bytes calldata _data,
        address _fallback,
        uint256 _fromChainID
    ) external lock charge(_from) onlyMPC {
        context = Context({sender: _from, fromChainID: _fromChainID});
        (bool success, bytes memory result) = _to.call(_data);
        context = Context({sender: address(0), fromChainID: 0});

        emit LogAnyExec(_from, _to, _data, success, result, _fallback, _fromChainID);

        // Call the fallback on the originating chain with the call information (to, data)
        // _from, _fromChainID, _toChainID can all be identified via contextual info
        if (!success && _fallback != address(0)) {
            emit LogAnyCall(
                _from,
                _fallback,
                abi.encodeWithSignature("anyFallback(address,bytes)", _to, _data),
                address(0),
                _fromChainID
            );
        }
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
        emit Withdrawl(msg.sender, _amount);
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

    /// @notice Set the whitelist premitting an account to issue a cross chain request
    /// @param _from The account which will submit cross chain interaction requests
    /// @param _to The target of the cross chain interaction
    /// @param _toChainID The target chain id
    function setWhitelist(
        address _from,
        address _to,
        uint256 _toChainID,
        bool _flag
    ) external onlyMPC {
        whitelist[_from][_to][_toChainID] = _flag;
        emit SetWhitelist(_from, _to, _toChainID, _flag);
    }

    /// @notice Set the whitelist premitting an account to issue a cross chain request
    /// @param _from The account which will submit cross chain interaction requests
    /// @param _tos The targets of the cross chain interaction
    /// @param _toChainIDs The target chain ids
    function setWhitelists(
        address _from,
        address[] calldata _tos,
        uint256[] calldata _toChainIDs,
        bool _flag
    ) external onlyMPC {
        require(_tos.length == _toChainIDs.length);
        for (uint256 i = 0; i < _tos.length; i++) {
            whitelist[_from][_tos[i]][_toChainIDs[i]] = _flag;
            emit SetWhitelist(_from, _tos[i], _toChainIDs[i], _flag);
        }
    }

    /// @notice Set an account's blacklist status
    /// @dev A simpler way to deactive an account's permission to issue
    ///     cross chain requests without updating the whitelist
    /// @param _account The account to update blacklist status of
    /// @param _flag The blacklist state to put `_account` in
    function setBlacklist(address _account, bool _flag) external onlyMPC {
        blacklist[_account] = _flag;
        emit SetBlacklist(_account, _flag);
    }

    /// @notice Set an accounts' blacklist status
    /// @dev A simpler way to deactive an account's permission to issue
    ///     cross chain requests without updating the whitelist
    /// @param _accounts The accounts to update blacklist status of
    /// @param _flag The blacklist state to put `_account` in
    function setBlacklists(address[] calldata _accounts, bool _flag) external onlyMPC {
        for (uint256 i = 0; i < _accounts.length; i++) {
            blacklist[_accounts[i]] = _flag;
            emit SetBlacklist(_accounts[i], _flag);
        }
    }

    /// @notice Set the premimum for cross chain executions
    /// @param _premium The premium per gas
    function setPremium(uint128 _premium) external onlyMPC {
        emit UpdatePremium(_feeData.premium, _premium);
        _feeData.premium = _premium;
    }

    /// @notice Set minimum exection budget for cross chain executions
    /// @param _minBudget The minimum exection budget
    function setMinReserveBudget(uint128 _minBudget) external onlyMPC {
        minReserveBudget = _minBudget;
    }

    /// @notice Initiate a transfer of MPC status
    /// @param _newMPC The address of the new MPC
    function changeMPC(address _newMPC) external onlyMPC {
        emit TransferMPC(mpc, _newMPC, block.timestamp);
        mpc = _newMPC;
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
}