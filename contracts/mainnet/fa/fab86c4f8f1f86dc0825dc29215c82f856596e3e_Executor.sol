pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;




abstract contract TriggerInterface {
    function isTriggered(bytes memory, bytes memory) virtual public returns (bool);
} abstract contract DSProxyInterface {

    /// Truffle wont compile if this isn't commented
    // function execute(bytes memory _code, bytes memory _data)
    //     public virtual
    //     payable
    //     returns (address, bytes32);

    function execute(address _target, bytes memory _data) public virtual payable returns (bytes32);

    function setCache(address _cacheAddr) public virtual payable returns (bool);

    function owner() public virtual returns (address);
}

/// @title Struct Data in a separate contract soit can be used in multiple places
contract StrategyData {

    struct Trigger {
        bytes32 id;
        bytes data;
    }

    struct Action {
        bytes32 id;
        bytes data;
    }

    struct Strategy {
        address user;
        address proxy;
        bool active;
        uint[] triggerIds;
        uint[] actionIds;
    }
} contract DefisaverLogger {
    event LogEvent(
        address indexed contractAddress,
        address indexed caller,
        string indexed logName,
        bytes data
    );

    // solhint-disable-next-line func-name-mixedcase
    function Log(address _contract, address _caller, string memory _logName, bytes memory _data)
        public
    {
        emit LogEvent(_contract, _caller, _logName, _data);
    }
}





/// @title Storage of actions and triggers which can be added/removed and modified
contract Subscriptions is StrategyData {

    DefisaverLogger public constant logger = DefisaverLogger(0x5c55B921f590a89C1Ebe84dF170E655a82b62126);

    Strategy[] internal strategies;
    Action[] internal actions;
    Trigger[] internal triggers;

    /// @notice Subscribes a new strategy for a user
    /// @param _triggers Array of trigger data
    /// @param _actions Array of action data
    function subscribe(Trigger[] memory _triggers, Action[] memory _actions) public {
        uint[] memory triggerIds = new uint[](_triggers.length);
        uint[] memory actionsIds = new uint[](_actions.length);

        // Populate triggers
        for (uint i = 0; i < _triggers.length; ++i) {
            triggers.push(Trigger({
                id: _triggers[i].id,
                data: _triggers[i].data
            }));

            triggerIds[i] = triggers.length - 1;
        }

        // Populate actions
        for (uint i = 0; i < _actions.length; ++i) {
            actions.push(Action({
                id: _actions[i].id,
                data: _actions[i].data
            }));

            actionsIds[i] = actions.length - 1;
        }

        strategies.push(Strategy({
            user: getProxyOwner(msg.sender),
            proxy: msg.sender,
            active: true,
            triggerIds: triggerIds,
            actionIds: actionsIds
        }));

        logger.Log(address(this), msg.sender, "Subscribe", abi.encode(strategies.length - 1));
    }

    // TODO: what if we have more/less actions then in the original strategy?

    /// @notice Update an existing strategy
    /// @param _subId Subscription id
    /// @param _triggers Array of trigger data
    /// @param _actions Array of action data
    function update(uint _subId, Trigger[] memory _triggers, Action[] memory _actions) public {
        Strategy memory s = strategies[_subId];
        require(s.user != address(0), "Strategy does not exist");
        require(msg.sender == s.proxy, "Proxy not strategy owner");

        // update triggers
        for (uint i = 0; i < _triggers.length; ++i) {
            triggers[s.triggerIds[i]] = Trigger({
                id: _triggers[i].id,
                data: _triggers[i].data
            });
        }

        // update actions
        for (uint i = 0; i < _actions.length; ++i) {
            actions[s.actionIds[i]] = Action({
                id: _actions[i].id,
                data: _actions[i].data
            });
        }

        logger.Log(address(this), msg.sender, "Update", abi.encode(_subId));
    }

    /// @notice Unsubscribe an existing strategy
    /// @param _subId Subscription id
    function unsubscribe(uint _subId) public {
        Strategy memory s = strategies[_subId];
        require(s.user != address(0), "Strategy does not exist");
        require(msg.sender == s.proxy, "Proxy not strategy owner");

        strategies[_subId].active = false;

        logger.Log(address(this), msg.sender, "Unsubscribe", abi.encode(_subId));
    }


    function getProxyOwner(address _proxy) internal returns (address proxyOwner) {
        proxyOwner = DSProxyInterface(_proxy).owner();
        require(proxyOwner != address(0), "No proxy");
    }

    ///////////////////// VIEW ONLY FUNCTIONS ////////////////////////////

    function getTrigger(uint _triggerId) public view returns (Trigger memory) {
        return triggers[_triggerId];
    }

    function getAction(uint _actionId) public view returns (Action memory) {
        return actions[_actionId];
    }

    function getStreategyCount() public view returns (uint) {
        return strategies.length;
    }

    function getStrategy(uint _subId) public view returns (Strategy memory) {
        return strategies[_subId];
    }

} interface ERC20 {
    function totalSupply() external view returns (uint256 supply);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transfer(address _to, uint256 _value) external returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value)
        external
        returns (bool success);

    function approve(address _spender, uint256 _value) external returns (bool success);

    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    function decimals() external view returns (uint256 digits);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
} library Address {
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

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
} library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

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

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
} library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(ERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     */
    function safeApprove(ERC20 token, address spender, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(ERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(ERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(ERC20 token, bytes memory data) private {

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
} contract AdminAuth {

    using SafeERC20 for ERC20;

    address public owner;
    address public admin;

    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    /// @notice Admin is set by owner first time, after that admin is super role and has permission to change owner
    /// @param _admin Address of multisig that becomes admin
    function setAdminByOwner(address _admin) public {
        require(msg.sender == owner);
        require(admin == address(0));

        admin = _admin;
    }

    /// @notice Admin is able to set new admin
    /// @param _admin Address of multisig that becomes new admin
    function setAdminByAdmin(address _admin) public {
        require(msg.sender == admin);

        admin = _admin;
    }

    /// @notice Admin is able to change owner
    /// @param _owner Address of new owner
    function setOwnerByAdmin(address _owner) public {
        require(msg.sender == admin);

        owner = _owner;
    }

    /// @notice Destroy the contract
    function kill() public onlyOwner {
        selfdestruct(payable(owner));
    }

    /// @notice  withdraw stuck funds
    function withdrawStuckFunds(address _token, uint _amount) public onlyOwner {
        if (_token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            payable(owner).transfer(_amount);
        } else {
            ERC20(_token).safeTransfer(owner, _amount);
        }
    }
} /// @title Handles authorization of who can call the execution of strategies
contract BotAuth is AdminAuth {

    mapping (address => bool) public approvedCallers;

    /// @notice Checks if the caller is approved for the specific strategy
    /// @dev Currently auth callers are approved for all strategies
    /// @param _strategyId Id of strategy not used for this version
    /// @param _caller Address of the caller
    function isApproved(uint _strategyId, address _caller) public view returns (bool) {
        return approvedCallers[_caller];
    }

    /// @notice Adds a new bot address which will be able to call repay/boost
    /// @param _caller Bot address
    function addCaller(address _caller) public onlyOwner {
        approvedCallers[_caller] = true;
    }

    /// @notice Removes a bot address so it can't call repay/boost
    /// @param _caller Bot address
    function removeCaller(address _caller) public onlyOwner {
        approvedCallers[_caller] = false;
    }

} /// @title Stores all the important DFS addresses and can be changed (timelock)
contract Registry is AdminAuth {

    DefisaverLogger public constant logger = DefisaverLogger(0x5c55B921f590a89C1Ebe84dF170E655a82b62126);

    struct Entry {
        address contractAddr;
        uint waitPeriod;
        uint changeStartTime;
        bool inChange;
        bool exists;
    }

    mapping (bytes32 => Entry) public entries;
    mapping (bytes32 => address) public pendingAddresses;

    /// @notice Given an contract id returns the registred address
    /// @dev Id is kecceak256 of the contract name
    /// @param _id Id of contract
    function getAddr(bytes32 _id) public view returns (address) {
        return entries[_id].contractAddr;
    }

    /////////////////////////// ADMIN ONLY FUNCTIONS ///////////////////////////

    // TODO: REMOVE ONLY FOR TESTING
    function changeInsant(bytes32 _id, address _contractAddr) public onlyOwner {
        entries[_id].contractAddr = _contractAddr;
    }

    /// @notice Adds a new contract to the registry
    /// @param _id Id of contract
    /// @param _contractAddr Address of the contract
    /// @param _waitPeriod Amount of time to wait before a contract address can be changed
    function addNewContract(bytes32 _id, address _contractAddr, uint _waitPeriod) public onlyOwner {
        require(!entries[_id].exists, "Entry id already exists");

        entries[_id] = Entry({
            contractAddr: _contractAddr,
            waitPeriod: _waitPeriod,
            changeStartTime: 0,
            inChange: false,
            exists: true
        });

        logger.Log(address(this), msg.sender, "AddNewContract", abi.encode(_id, _contractAddr, _waitPeriod));
    }

    /// @notice Starts an address change for an existing entry
    /// @dev Can override a change that is currently in progress
    /// @param _id Id of contract
    /// @param _newContractAddr Address of the new contract
    function startContractChange(bytes32 _id, address _newContractAddr) public onlyOwner {
        require(entries[_id].exists, "Entry id doesn't exists");

        entries[_id].changeStartTime = now;
        entries[_id].inChange = true;

        pendingAddresses[_id] = _newContractAddr;

        logger.Log(address(this), msg.sender, "StartChange", abi.encode(_id, entries[_id].contractAddr, _newContractAddr));
    }

    /// @notice Changes new contract address, correct time must have passed
    /// @dev Can override a change that is currently in progress
    /// @param _id Id of contract
    function approveContractChange(bytes32 _id) public onlyOwner {
        require(entries[_id].exists, "Entry id doesn't exists");
        require(entries[_id].inChange, "Entry not in change process");
        require((entries[_id].changeStartTime + entries[_id].waitPeriod) > now, "Change not ready yet");

        address oldContractAddr = entries[_id].contractAddr;
        entries[_id].contractAddr = pendingAddresses[_id];
        entries[_id].inChange = false;
        entries[_id].changeStartTime = 0;

        pendingAddresses[_id] = address(0);

        logger.Log(address(this), msg.sender, "ApproveChange", abi.encode(_id, oldContractAddr, entries[_id].contractAddr));
    }

    /// @notice Cancel pending change
    /// @param _id Id of contract
    function cancelContractChange(bytes32 _id) public onlyOwner {
        require(entries[_id].exists, "Entry id doesn't exists");
        require(entries[_id].inChange, "Entry is not change process");

        address oldContractAddr = pendingAddresses[_id];

        pendingAddresses[_id] = address(0);
        entries[_id].inChange = false;
        entries[_id].changeStartTime = 0;

        logger.Log(address(this), msg.sender, "CancelChange", abi.encode(_id, oldContractAddr, entries[_id].contractAddr));
    }

    /// @notice Changes wait period for an entry
    /// @param _id Id of contract
    /// @param _newWaitPeriod New wait time, must be bigger than before
    function changeWaitPeriod(bytes32 _id, uint _newWaitPeriod) public onlyOwner {
        require(entries[_id].exists, "Entry id doesn't exists");
        require(_newWaitPeriod > entries[_id].waitPeriod, "New wait period must be bigger");

        entries[_id].waitPeriod = _newWaitPeriod;

        logger.Log(address(this), msg.sender, "ChangeWaitPeriod", abi.encode(_id, _newWaitPeriod));
    }

}








/// @title Main entry point for executing automated strategies
contract Executor is StrategyData {

    Registry public constant registry = Registry(0xD1E8EA7709e85b22B846fb6EB5a411a348279A8a);
    // Subscriptions public constant subscriptions = Subscriptions(0x76a185a4f66C0d09eBfbD916e0AD0f1CDF6B911b);

    /// @notice Checks all the triggers and executes actions
    /// @dev Only auhtorized callers can execute it
    /// @param _strategyId Id of the strategy
    /// @param _triggerCallData All input data needed to execute triggers
    /// @param _actionsCallData All input data needed to execute actions
    function executeStrategy(
        uint _strategyId,
        bytes[] memory _triggerCallData,
        bytes[] memory _actionsCallData
    ) public {
        address subscriptionsAddr = registry.getAddr(keccak256("Subscriptions"));

        Strategy memory strategy = Subscriptions(subscriptionsAddr).getStrategy(_strategyId);
        require(strategy.active, "Strategy is not active");

        // check bot auth
        checkCallerAuth(_strategyId);

        // check if all the triggers are true
        checkTriggers(strategy, _triggerCallData, subscriptionsAddr);

        // execute actions
        callActions(strategy, _actionsCallData);
    }

    /// @notice Checks if msg.sender has auth, reverts if not
    /// @param _strategyId Id of the strategy
    function checkCallerAuth(uint _strategyId) public view {
        address botAuthAddr = registry.getAddr(keccak256("BotAuth"));
        require(BotAuth(botAuthAddr).isApproved(_strategyId, msg.sender), "msg.sender is not approved caller");
    }

    /// @notice Checks if all the triggers are true, reverts if not
    /// @param _strategy Strategy data we have in storage
    /// @param _triggerCallData All input data needed to execute triggers
    function checkTriggers(Strategy memory _strategy, bytes[] memory _triggerCallData, address _subscriptionsAddr) public {
        for (uint i = 0; i < _strategy.triggerIds.length; ++i) {
            Trigger memory trigger = Subscriptions(_subscriptionsAddr).getTrigger(_strategy.triggerIds[i]);
            address triggerAddr = registry.getAddr(trigger.id);

            bool isTriggered = TriggerInterface(triggerAddr).isTriggered(_triggerCallData[i], trigger.data);
            require(isTriggered, "Trigger not activated");
        }
    }

    /// @notice Execute all the actions in order
    /// @param _strategy Strategy data we have in storage
    /// @param _actionsCallData All input data needed to execute actions
    function callActions(Strategy memory _strategy, bytes[] memory _actionsCallData) internal {
        address actionManagerProxyAddr = registry.getAddr(keccak256("ActionManagerProxy"));

        DSProxyInterface(_strategy.proxy).execute{value: msg.value}(
            actionManagerProxyAddr,
            abi.encodeWithSignature(
                "manageActions(uint[],bytes[])",
                _strategy.actionIds,
                _actionsCallData
        ));
    }
}