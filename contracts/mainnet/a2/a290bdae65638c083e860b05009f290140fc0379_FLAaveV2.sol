/**
 *Submitted for verification at Etherscan.io on 2021-04-09
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.7.6;  
pragma experimental ABIEncoderV2;


abstract contract IDFSRegistry {
 
    function getAddr(bytes32 _id) public view virtual returns (address);

    function addNewContract(
        bytes32 _id,
        address _contractAddr,
        uint256 _waitPeriod
    ) public virtual;

    function startContractChange(bytes32 _id, address _newContractAddr) public virtual;

    function approveContractChange(bytes32 _id) public virtual;

    function cancelContractChange(bytes32 _id) public virtual;

    function changeWaitPeriod(bytes32 _id, uint256 _newWaitPeriod) public virtual;
}    



interface IERC20 {
    function totalSupply() external view returns (uint256 supply);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transfer(address _to, uint256 _value) external returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function approve(address _spender, uint256 _value) external returns (bool success);

    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    function decimals() external view returns (uint256 digits);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}    



library Address {
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
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
}    



library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}    







library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /// @dev Edited so it always first approves 0 and then the value, because of non standard tokens
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
        );
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}    



/// @title A stateful contract that holds and can change owner/admin
contract AdminVault {
    address public owner;
    address public admin;

    constructor() {
        owner = msg.sender;
        admin = 0x25eFA336886C74eA8E282ac466BdCd0199f85BB9;
    }

    /// @notice Admin is able to change owner
    /// @param _owner Address of new owner
    function changeOwner(address _owner) public {
        require(admin == msg.sender, "msg.sender not admin");
        owner = _owner;
    }

    /// @notice Admin is able to set new admin
    /// @param _admin Address of multisig that becomes new admin
    function changeAdmin(address _admin) public {
        require(admin == msg.sender, "msg.sender not admin");
        admin = _admin;
    }

}    








/// @title AdminAuth Handles owner/admin privileges over smart contracts
contract AdminAuth {
    using SafeERC20 for IERC20;

    AdminVault public constant adminVault = AdminVault(0xCCf3d848e08b94478Ed8f46fFead3008faF581fD);

    modifier onlyOwner() {
        require(adminVault.owner() == msg.sender, "msg.sender not owner");
        _;
    }

    modifier onlyAdmin() {
        require(adminVault.admin() == msg.sender, "msg.sender not admin");
        _;
    }

    /// @notice withdraw stuck funds
    function withdrawStuckFunds(address _token, address _receiver, uint256 _amount) public onlyOwner {
        if (_token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            payable(_receiver).transfer(_amount);
        } else {
            IERC20(_token).safeTransfer(_receiver, _amount);
        }
    }

    /// @notice Destroy the contract
    function kill() public onlyAdmin {
        selfdestruct(payable(msg.sender));
    }
}    



contract DefisaverLogger {
    event LogEvent(
        address indexed contractAddress,
        address indexed caller,
        string indexed logName,
        bytes data
    );

    // solhint-disable-next-line func-name-mixedcase
    function Log(
        address _contract,
        address _caller,
        string memory _logName,
        bytes memory _data
    ) public {
        emit LogEvent(_contract, _caller, _logName, _data);
    }
}    






/// @title Stores all the important DFS addresses and can be changed (timelock)
contract DFSRegistry is AdminAuth {
    DefisaverLogger public constant logger = DefisaverLogger(
        0x5c55B921f590a89C1Ebe84dF170E655a82b62126
    );

    string public constant ERR_ENTRY_ALREADY_EXISTS = "Entry id already exists";
    string public constant ERR_ENTRY_NON_EXISTENT = "Entry id doesn't exists";
    string public constant ERR_ENTRY_NOT_IN_CHANGE = "Entry not in change process";
    string public constant ERR_WAIT_PERIOD_SHORTER = "New wait period must be bigger";
    string public constant ERR_CHANGE_NOT_READY = "Change not ready yet";
    string public constant ERR_EMPTY_PREV_ADDR = "Previous addr is 0";
    string public constant ERR_ALREADY_IN_CONTRACT_CHANGE = "Already in contract change";
    string public constant ERR_ALREADY_IN_WAIT_PERIOD_CHANGE = "Already in wait period change";

    struct Entry {
        address contractAddr;
        uint256 waitPeriod;
        uint256 changeStartTime;
        bool inContractChange;
        bool inWaitPeriodChange;
        bool exists;
    }

    mapping(bytes32 => Entry) public entries;
    mapping(bytes32 => address) public previousAddresses;

    mapping(bytes32 => address) public pendingAddresses;
    mapping(bytes32 => uint256) public pendingWaitTimes;

    /// @notice Given an contract id returns the registered address
    /// @dev Id is keccak256 of the contract name
    /// @param _id Id of contract
    function getAddr(bytes32 _id) public view returns (address) {
        return entries[_id].contractAddr;
    }

    /// @notice Helper function to easily query if id is registered
    /// @param _id Id of contract
    function isRegistered(bytes32 _id) public view returns (bool) {
        return entries[_id].exists;
    }

    /////////////////////////// OWNER ONLY FUNCTIONS ///////////////////////////

    /// @notice Adds a new contract to the registry
    /// @param _id Id of contract
    /// @param _contractAddr Address of the contract
    /// @param _waitPeriod Amount of time to wait before a contract address can be changed
    function addNewContract(
        bytes32 _id,
        address _contractAddr,
        uint256 _waitPeriod
    ) public onlyOwner {
        require(!entries[_id].exists, ERR_ENTRY_ALREADY_EXISTS);

        entries[_id] = Entry({
            contractAddr: _contractAddr,
            waitPeriod: _waitPeriod,
            changeStartTime: 0,
            inContractChange: false,
            inWaitPeriodChange: false,
            exists: true
        });

        // Remember tha address so we can revert back to old addr if needed
        previousAddresses[_id] = _contractAddr;

        logger.Log(
            address(this),
            msg.sender,
            "AddNewContract",
            abi.encode(_id, _contractAddr, _waitPeriod)
        );
    }

    /// @notice Reverts to the previous address immediately
    /// @dev In case the new version has a fault, a quick way to fallback to the old contract
    /// @param _id Id of contract
    function revertToPreviousAddress(bytes32 _id) public onlyOwner {
        require(entries[_id].exists, ERR_ENTRY_NON_EXISTENT);
        require(previousAddresses[_id] != address(0), ERR_EMPTY_PREV_ADDR);

        address currentAddr = entries[_id].contractAddr;
        entries[_id].contractAddr = previousAddresses[_id];

        logger.Log(
            address(this),
            msg.sender,
            "RevertToPreviousAddress",
            abi.encode(_id, currentAddr, previousAddresses[_id])
        );
    }

    /// @notice Starts an address change for an existing entry
    /// @dev Can override a change that is currently in progress
    /// @param _id Id of contract
    /// @param _newContractAddr Address of the new contract
    function startContractChange(bytes32 _id, address _newContractAddr) public onlyOwner {
        require(entries[_id].exists, ERR_ENTRY_NON_EXISTENT);
        require(!entries[_id].inWaitPeriodChange, ERR_ALREADY_IN_WAIT_PERIOD_CHANGE);

        entries[_id].changeStartTime = block.timestamp; // solhint-disable-line
        entries[_id].inContractChange = true;

        pendingAddresses[_id] = _newContractAddr;

        logger.Log(
            address(this),
            msg.sender,
            "StartContractChange",
            abi.encode(_id, entries[_id].contractAddr, _newContractAddr)
        );
    }

    /// @notice Changes new contract address, correct time must have passed
    /// @param _id Id of contract
    function approveContractChange(bytes32 _id) public onlyOwner {
        require(entries[_id].exists, ERR_ENTRY_NON_EXISTENT);
        require(entries[_id].inContractChange, ERR_ENTRY_NOT_IN_CHANGE);
        require(
            block.timestamp >= (entries[_id].changeStartTime + entries[_id].waitPeriod), // solhint-disable-line
            ERR_CHANGE_NOT_READY
        );

        address oldContractAddr = entries[_id].contractAddr;
        entries[_id].contractAddr = pendingAddresses[_id];
        entries[_id].inContractChange = false;
        entries[_id].changeStartTime = 0;

        pendingAddresses[_id] = address(0);
        previousAddresses[_id] = oldContractAddr;

        logger.Log(
            address(this),
            msg.sender,
            "ApproveContractChange",
            abi.encode(_id, oldContractAddr, entries[_id].contractAddr)
        );
    }

    /// @notice Cancel pending change
    /// @param _id Id of contract
    function cancelContractChange(bytes32 _id) public onlyOwner {
        require(entries[_id].exists, ERR_ENTRY_NON_EXISTENT);
        require(entries[_id].inContractChange, ERR_ENTRY_NOT_IN_CHANGE);

        address oldContractAddr = pendingAddresses[_id];

        pendingAddresses[_id] = address(0);
        entries[_id].inContractChange = false;
        entries[_id].changeStartTime = 0;

        logger.Log(
            address(this),
            msg.sender,
            "CancelContractChange",
            abi.encode(_id, oldContractAddr, entries[_id].contractAddr)
        );
    }

    /// @notice Starts the change for waitPeriod
    /// @param _id Id of contract
    /// @param _newWaitPeriod New wait time
    function startWaitPeriodChange(bytes32 _id, uint256 _newWaitPeriod) public onlyOwner {
        require(entries[_id].exists, ERR_ENTRY_NON_EXISTENT);
        require(!entries[_id].inContractChange, ERR_ALREADY_IN_CONTRACT_CHANGE);

        pendingWaitTimes[_id] = _newWaitPeriod;

        entries[_id].changeStartTime = block.timestamp; // solhint-disable-line
        entries[_id].inWaitPeriodChange = true;

        logger.Log(
            address(this),
            msg.sender,
            "StartWaitPeriodChange",
            abi.encode(_id, _newWaitPeriod)
        );
    }

    /// @notice Changes new wait period, correct time must have passed
    /// @param _id Id of contract
    function approveWaitPeriodChange(bytes32 _id) public onlyOwner {
        require(entries[_id].exists, ERR_ENTRY_NON_EXISTENT);
        require(entries[_id].inWaitPeriodChange, ERR_ENTRY_NOT_IN_CHANGE);
        require(
            block.timestamp >= (entries[_id].changeStartTime + entries[_id].waitPeriod), // solhint-disable-line
            ERR_CHANGE_NOT_READY
        );

        uint256 oldWaitTime = entries[_id].waitPeriod;
        entries[_id].waitPeriod = pendingWaitTimes[_id];
        
        entries[_id].inWaitPeriodChange = false;
        entries[_id].changeStartTime = 0;

        pendingWaitTimes[_id] = 0;

        logger.Log(
            address(this),
            msg.sender,
            "ApproveWaitPeriodChange",
            abi.encode(_id, oldWaitTime, entries[_id].waitPeriod)
        );
    }

    /// @notice Cancel wait period change
    /// @param _id Id of contract
    function cancelWaitPeriodChange(bytes32 _id) public onlyOwner {
        require(entries[_id].exists, ERR_ENTRY_NON_EXISTENT);
        require(entries[_id].inWaitPeriodChange, ERR_ENTRY_NOT_IN_CHANGE);

        uint256 oldWaitPeriod = pendingWaitTimes[_id];

        pendingWaitTimes[_id] = 0;
        entries[_id].inWaitPeriodChange = false;
        entries[_id].changeStartTime = 0;

        logger.Log(
            address(this),
            msg.sender,
            "CancelWaitPeriodChange",
            abi.encode(_id, oldWaitPeriod, entries[_id].waitPeriod)
        );
    }
}    







/// @title Implements Action interface and common helpers for passing inputs
abstract contract ActionBase is AdminAuth {
    address public constant REGISTRY_ADDR = 0xD6049E1F5F3EfF1F921f5532aF1A1632bA23929C;
    DFSRegistry public constant registry = DFSRegistry(REGISTRY_ADDR);

    DefisaverLogger public constant logger = DefisaverLogger(
        0x5c55B921f590a89C1Ebe84dF170E655a82b62126
    );

    string public constant ERR_SUB_INDEX_VALUE = "Wrong sub index value";
    string public constant ERR_RETURN_INDEX_VALUE = "Wrong return index value";

    /// @dev Subscription params index range [128, 255]
    uint8 public constant SUB_MIN_INDEX_VALUE = 128;
    uint8 public constant SUB_MAX_INDEX_VALUE = 255;

    /// @dev Return params index range [1, 127]
    uint8 public constant RETURN_MIN_INDEX_VALUE = 1;
    uint8 public constant RETURN_MAX_INDEX_VALUE = 127;

    /// @dev If the input value should not be replaced
    uint8 public constant NO_PARAM_MAPPING = 0;

    /// @dev We need to parse Flash loan actions in a different way
    enum ActionType { FL_ACTION, STANDARD_ACTION, CUSTOM_ACTION }

    /// @notice Parses inputs and runs the implemented action through a proxy
    /// @dev Is called by the TaskExecutor chaining actions together
    /// @param _callData Array of input values each value encoded as bytes
    /// @param _subData Array of subscribed vales, replaces input values if specified
    /// @param _paramMapping Array that specifies how return and subscribed values are mapped in input
    /// @param _returnValues Returns values from actions before, which can be injected in inputs
    /// @return Returns a bytes32 value through DSProxy, each actions implements what that value is
    function executeAction(
        bytes[] memory _callData,
        bytes[] memory _subData,
        uint8[] memory _paramMapping,
        bytes32[] memory _returnValues
    ) public payable virtual returns (bytes32);

    /// @notice Parses inputs and runs the single implemented action through a proxy
    /// @dev Used to save gas when executing a single action directly
    function executeActionDirect(bytes[] memory _callData) public virtual payable;

    /// @notice Returns the type of action we are implementing
    function actionType() public pure virtual returns (uint8);


    //////////////////////////// HELPER METHODS ////////////////////////////

    /// @notice Given an uint256 input, injects return/sub values if specified
    /// @param _param The original input value
    /// @param _mapType Indicated the type of the input in paramMapping
    /// @param _subData Array of subscription data we can replace the input value with
    /// @param _returnValues Array of subscription data we can replace the input value with
    function _parseParamUint(
        uint _param,
        uint8 _mapType,
        bytes[] memory _subData,
        bytes32[] memory _returnValues
    ) internal pure returns (uint) {
        if (isReplaceable(_mapType)) {
            if (isReturnInjection(_mapType)) {
                _param = uint(_returnValues[getReturnIndex(_mapType)]);
            } else {
                _param = abi.decode(_subData[getSubIndex(_mapType)], (uint));
            }
        }

        return _param;
    }


    /// @notice Given an addr input, injects return/sub values if specified
    /// @param _param The original input value
    /// @param _mapType Indicated the type of the input in paramMapping
    /// @param _subData Array of subscription data we can replace the input value with
    /// @param _returnValues Array of subscription data we can replace the input value with
    function _parseParamAddr(
        address _param,
        uint8 _mapType,
        bytes[] memory _subData,
        bytes32[] memory _returnValues
    ) internal pure returns (address) {
        if (isReplaceable(_mapType)) {
            if (isReturnInjection(_mapType)) {
                _param = address(bytes20((_returnValues[getReturnIndex(_mapType)])));
            } else {
                _param = abi.decode(_subData[getSubIndex(_mapType)], (address));
            }
        }

        return _param;
    }

    /// @notice Given an bytes32 input, injects return/sub values if specified
    /// @param _param The original input value
    /// @param _mapType Indicated the type of the input in paramMapping
    /// @param _subData Array of subscription data we can replace the input value with
    /// @param _returnValues Array of subscription data we can replace the input value with
    function _parseParamABytes32(
        bytes32 _param,
        uint8 _mapType,
        bytes[] memory _subData,
        bytes32[] memory _returnValues
    ) internal pure returns (bytes32) {
        if (isReplaceable(_mapType)) {
            if (isReturnInjection(_mapType)) {
                _param = (_returnValues[getReturnIndex(_mapType)]);
            } else {
                _param = abi.decode(_subData[getSubIndex(_mapType)], (bytes32));
            }
        }

        return _param;
    }

    /// @notice Checks if the paramMapping value indicated that we need to inject values
    /// @param _type Indicated the type of the input
    function isReplaceable(uint8 _type) internal pure returns (bool) {
        return _type != NO_PARAM_MAPPING;
    }

    /// @notice Checks if the paramMapping value is in the return value range
    /// @param _type Indicated the type of the input
    function isReturnInjection(uint8 _type) internal pure returns (bool) {
        return (_type >= RETURN_MIN_INDEX_VALUE) && (_type <= RETURN_MAX_INDEX_VALUE);
    }

    /// @notice Transforms the paramMapping value to the index in return array value
    /// @param _type Indicated the type of the input
    function getReturnIndex(uint8 _type) internal pure returns (uint8) {
        require(isReturnInjection(_type), ERR_SUB_INDEX_VALUE);

        return (_type - RETURN_MIN_INDEX_VALUE);
    }

    /// @notice Transforms the paramMapping value to the index in sub array value
    /// @param _type Indicated the type of the input
    function getSubIndex(uint8 _type) internal pure returns (uint8) {
        require(_type >= SUB_MIN_INDEX_VALUE, ERR_RETURN_INDEX_VALUE);

        return (_type - SUB_MIN_INDEX_VALUE);
    }
}    



abstract contract IDSProxy {
    // function execute(bytes memory _code, bytes memory _data)
    //     public
    //     payable
    //     virtual
    //     returns (address, bytes32);

    function execute(address _target, bytes memory _data) public payable virtual returns (bytes32);

    function setCache(address _cacheAddr) public payable virtual returns (bool);

    function owner() public view virtual returns (address);
}    


  

/// @title Struct data in a separate contract so it can be used in multiple places
contract StrategyData {
    struct Template {
        string name;
        bytes32[] triggerIds;
        bytes32[] actionIds;
        uint8[][] paramMapping;
    }

    struct Task {
        string name;
        bytes[][] callData;
        bytes[][] subData;
        bytes32[] actionIds;
        uint8[][] paramMapping;
    }

    struct Strategy {
        uint templateId;
        address proxy;
        bytes[][] subData;
        bytes[][] triggerData;
        bool active;

        uint posInUserArr;
    }
}    


  






/// @title Storage of strategies and templates
contract Subscriptions is StrategyData, AdminAuth {
    DefisaverLogger public constant logger = DefisaverLogger(0x5c55B921f590a89C1Ebe84dF170E655a82b62126);

    string public constant ERR_EMPTY_STRATEGY = "Strategy does not exist";
    string public constant ERR_SENDER_NOT_OWNER = "Sender is not strategy owner";
    string public constant ERR_USER_POS_EMPTY = "No user positions";

    /// @dev The order of strategies might change as they are deleted
    Strategy[] public strategies;

    /// @dev Templates are fixed and are non removable
    Template[] public templates;

    /// @dev Keeps track of all the users strategies (their indexes in the array)
    mapping (address => uint[]) public usersPos;

    /// @dev Increments on state change, used for easier off chain tracking of changes
    uint public updateCounter;

    /// @notice Creates a new strategy with an existing template
    /// @param _templateId Id of the template used for strategy
    /// @param _active If the strategy is turned on at the start
    /// @param _subData Subscription data for actions
    /// @param _triggerData Subscription data for triggers
    function createStrategy(
        uint _templateId,
        bool _active,
        bytes[][] memory _subData,
        bytes[][] memory _triggerData
    ) public returns (uint) {
        strategies.push(
            Strategy({
                templateId: _templateId,
                proxy: msg.sender,
                active: _active,
                subData: _subData,
                triggerData: _triggerData,
                posInUserArr: (usersPos[msg.sender].length - 1)
            })
        );

        usersPos[msg.sender].push(strategies.length - 1);

        updateCounter++;

        logger.Log(address(this), msg.sender, "CreateStrategy", abi.encode(strategies.length - 1));

        return strategies.length - 1;
    }

    /// @notice Creates a new template to use in strategies
    /// @dev Templates once created can't be changed
    /// @param _name Name of template, used mainly for logging
    /// @param _triggerIds Array of trigger ids which translate to trigger addresses
    /// @param _actionIds Array of actions ids which translate to action addresses
    /// @param _paramMapping Array that holds metadata of how inputs are mapped to sub/return data
    function createTemplate(
        string memory _name,
        bytes32[] memory _triggerIds,
        bytes32[] memory _actionIds,
        uint8[][] memory _paramMapping
    ) public returns (uint) {
        
        templates.push(
            Template({
                name: _name,
                triggerIds: _triggerIds,
                actionIds: _actionIds,
                paramMapping: _paramMapping
            })
        );

        updateCounter++;

        logger.Log(address(this), msg.sender, "CreateTemplate", abi.encode(templates.length - 1));

        return templates.length - 1;
    }

    /// @notice Updates the users strategy
    /// @dev Only callable by proxy who created the strategy
    /// @param _strategyId Id of the strategy to update
    /// @param _templateId Id of the template used for strategy
    /// @param _active If the strategy is turned on at the start
    /// @param _subData Subscription data for actions
    /// @param _triggerData Subscription data for triggers
    function updateStrategy(
        uint _strategyId,
        uint _templateId,
        bool _active,
        bytes[][] memory _subData,
        bytes[][] memory _triggerData
    ) public {
        Strategy storage s = strategies[_strategyId];

        require(s.proxy != address(0), ERR_EMPTY_STRATEGY);
        require(msg.sender == s.proxy, ERR_SENDER_NOT_OWNER);

        s.templateId = _templateId;
        s.active = _active;
        s.subData = _subData;
        s.triggerData = _triggerData;

        updateCounter++;

        logger.Log(address(this), msg.sender, "UpdateStrategy", abi.encode(_strategyId));
    }

    /// @notice Unsubscribe an existing strategy
    /// @dev Only callable by proxy who created the strategy
    /// @param _subId Subscription id
    function removeStrategy(uint256 _subId) public {
        Strategy memory s = strategies[_subId];
        require(s.proxy != address(0), ERR_EMPTY_STRATEGY);
        require(msg.sender == s.proxy, ERR_SENDER_NOT_OWNER);

        uint lastSub = strategies.length - 1;

        _removeUserPos(msg.sender, s.posInUserArr);

        strategies[_subId] = strategies[lastSub]; // last strategy put in place of the deleted one
        strategies.pop(); // delete last strategy, because it moved

        logger.Log(address(this), msg.sender, "Unsubscribe", abi.encode(_subId));
    }

    function _removeUserPos(address _user, uint _index) internal {
        require(usersPos[_user].length > 0, ERR_USER_POS_EMPTY);
        uint lastPos = usersPos[_user].length - 1;

        usersPos[_user][_index] = usersPos[_user][lastPos];
        usersPos[_user].pop();
    }

    ///////////////////// VIEW ONLY FUNCTIONS ////////////////////////////

    function getTemplateFromStrategy(uint _strategyId) public view returns (Template memory) {
        uint templateId = strategies[_strategyId].templateId;
        return templates[templateId];
    }

    function getStrategy(uint _strategyId) public view returns (Strategy memory) {
        return strategies[_strategyId];
    }

    function getTemplate(uint _templateId) public view returns (Template memory) {
        return templates[_templateId];
    }

    function getStrategyCount() public view returns (uint256) {
        return strategies.length;
    }

    function getTemplateCount() public view returns (uint256) {
        return templates.length;
    }

    function getStrategies() public view returns (Strategy[] memory) {
        return strategies;
    }

    function getTemplates() public view returns (Template[] memory) {
        return templates;
    }

    function userHasStrategies(address _user) public view returns (bool) {
        return usersPos[_user].length > 0;
    }

    function getUserStrategies(address _user) public view returns (Strategy[] memory) {
        Strategy[] memory userStrategies = new Strategy[](usersPos[_user].length);
        
        for (uint i = 0; i < usersPos[_user].length; ++i) {
            userStrategies[i] = strategies[usersPos[_user][i]];
        }

        return userStrategies;
    }

    function getPaginatedStrategies(uint _page, uint _perPage) public view returns (Strategy[] memory) {
        Strategy[] memory strategiesPerPage = new Strategy[](_perPage);

        uint start = _page * _perPage;
        uint end = start + _perPage;

        end = (end > strategiesPerPage.length) ? strategiesPerPage.length : end;

        uint count = 0;
        for (uint i = start; i < end; i++) {
            strategiesPerPage[count] = strategies[i];
            count++;
        }

        return strategiesPerPage;
    }

    function getPaginatedTemplates(uint _page, uint _perPage) public view returns (Template[] memory) {
        Template[] memory templatesPerPage = new Template[](_perPage);

        uint start = _page * _perPage;
        uint end = start + _perPage;

        end = (end > templatesPerPage.length) ? templatesPerPage.length : end;

        uint count = 0;
        for (uint i = start; i < end; i++) {
            templatesPerPage[count] = templates[i];
            count++;
        }

        return templatesPerPage;
    }
}    



contract DSMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "");
    }

    function div(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x / y;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x <= y ? x : y;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x >= y ? x : y;
    }

    function imin(int256 x, int256 y) internal pure returns (int256 z) {
        return x <= y ? x : y;
    }

    function imax(int256 x, int256 y) internal pure returns (int256 z) {
        return x >= y ? x : y;
    }

    uint256 constant WAD = 10**18;
    uint256 constant RAY = 10**27;

    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }

    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
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
    function rpow(uint256 x, uint256 n) internal pure returns (uint256 z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}    


  

abstract contract IFLParamGetter {
    function getFlashLoanParams(bytes memory _data)
        public
        view
        virtual
        returns (
            address[] memory tokens,
            uint256[] memory amount,
            uint256[] memory modes
        );
}    



abstract contract ILendingPool {
    function flashLoan(
        address payable _receiver,
        address _reserve,
        uint256 _amount,
        bytes calldata _params
    ) external virtual;

    function deposit(
        address _reserve,
        uint256 _amount,
        uint16 _referralCode
    ) external payable virtual;

    function setUserUseReserveAsCollateral(address _reserve, bool _useAsCollateral)
        external
        virtual;

    function borrow(
        address _reserve,
        uint256 _amount,
        uint256 _interestRateMode,
        uint16 _referralCode
    ) external virtual;

    function repay(
        address _reserve,
        uint256 _amount,
        address payable _onBehalfOf
    ) external payable virtual;

    function swapBorrowRateMode(address _reserve) external virtual;

    function getReserves() external view virtual returns (address[] memory);

    /// @param _reserve underlying token address
    function getReserveData(address _reserve)
        external
        view
        virtual
        returns (
            uint256 totalLiquidity, // reserve total liquidity
            uint256 availableLiquidity, // reserve available liquidity for borrowing
            uint256 totalBorrowsStable, // total amount of outstanding borrows at Stable rate
            uint256 totalBorrowsVariable, // total amount of outstanding borrows at Variable rate
            uint256 liquidityRate, // current deposit APY of the reserve for depositors, in Ray units.
            uint256 variableBorrowRate, // current variable rate APY of the reserve pool, in Ray units.
            uint256 stableBorrowRate, // current stable rate APY of the reserve pool, in Ray units.
            uint256 averageStableBorrowRate, // current average stable borrow rate
            uint256 utilizationRate, // expressed as total borrows/total liquidity.
            uint256 liquidityIndex, // cumulative liquidity index
            uint256 variableBorrowIndex, // cumulative variable borrow index
            address aTokenAddress, // aTokens contract address for the specific _reserve
            uint40 lastUpdateTimestamp // timestamp of the last update of reserve data
        );

    /// @param _user users address
    function getUserAccountData(address _user)
        external
        view
        virtual
        returns (
            uint256 totalLiquidityETH, // user aggregated deposits across all the reserves. In Wei
            uint256 totalCollateralETH, // user aggregated collateral across all the reserves. In Wei
            uint256 totalBorrowsETH, // user aggregated outstanding borrows across all the reserves. In Wei
            uint256 totalFeesETH, // user aggregated current outstanding fees in ETH. In Wei
            uint256 availableBorrowsETH, // user available amount to borrow in ETH
            uint256 currentLiquidationThreshold, // user current average liquidation threshold across all the collaterals deposited
            uint256 ltv, // user average Loan-to-Value between all the collaterals
            uint256 healthFactor // user current Health Factor
        );

    /// @param _reserve underlying token address
    /// @param _user users address
    function getUserReserveData(address _reserve, address _user)
        external
        view
        virtual
        returns (
            uint256 currentATokenBalance, // user current reserve aToken balance
            uint256 currentBorrowBalance, // user current reserve outstanding borrow balance
            uint256 principalBorrowBalance, // user balance of borrowed asset
            uint256 borrowRateMode, // user borrow rate mode either Stable or Variable
            uint256 borrowRate, // user current borrow rate APY
            uint256 liquidityRate, // user current earn rate on _reserve
            uint256 originationFee, // user outstanding loan origination fee
            uint256 variableBorrowIndex, // user variable cumulative index
            uint256 lastUpdateTimestamp, // Timestamp of the last data update
            bool usageAsCollateralEnabled // Whether the user's current reserve is enabled as a collateral
        );

    function getReserveConfigurationData(address _reserve)
        external
        view
        virtual
        returns (
            uint256 ltv,
            uint256 liquidationThreshold,
            uint256 liquidationBonus,
            address rateStrategyAddress,
            bool usageAsCollateralEnabled,
            bool borrowingEnabled,
            bool stableBorrowRateEnabled,
            bool isActive
        );

    // ------------------ LendingPoolCoreData ------------------------
    function getReserveATokenAddress(address _reserve) public view virtual returns (address);

    function getReserveConfiguration(address _reserve)
        external
        view
        virtual
        returns (
            uint256,
            uint256,
            uint256,
            bool
        );

    function getUserUnderlyingAssetBalance(address _reserve, address _user)
        public
        view
        virtual
        returns (uint256);

    function getReserveCurrentLiquidityRate(address _reserve) public view virtual returns (uint256);

    function getReserveCurrentVariableBorrowRate(address _reserve)
        public
        view
        virtual
        returns (uint256);

    function getReserveTotalLiquidity(address _reserve) public view virtual returns (uint256);

    function getReserveAvailableLiquidity(address _reserve) public view virtual returns (uint256);

    function getReserveTotalBorrowsVariable(address _reserve) public view virtual returns (uint256);

    // ---------------- LendingPoolDataProvider ---------------------
    function calculateUserGlobalData(address _user)
        public
        view
        virtual
        returns (
            uint256 totalLiquidityBalanceETH,
            uint256 totalCollateralBalanceETH,
            uint256 totalBorrowBalanceETH,
            uint256 totalFeesETH,
            uint256 currentLtv,
            uint256 currentLiquidationThreshold,
            uint256 healthFactor,
            bool healthFactorBelowThreshold
        );
}

  

/**
 * @title LendingPoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Aave Governance
 * @author Aave
 **/
interface ILendingPoolAddressesProviderV2 {
  event LendingPoolUpdated(address indexed newAddress);
  event ConfigurationAdminUpdated(address indexed newAddress);
  event EmergencyAdminUpdated(address indexed newAddress);
  event LendingPoolConfiguratorUpdated(address indexed newAddress);
  event LendingPoolCollateralManagerUpdated(address indexed newAddress);
  event PriceOracleUpdated(address indexed newAddress);
  event LendingRateOracleUpdated(address indexed newAddress);
  event ProxyCreated(bytes32 id, address indexed newAddress);
  event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);

  function setAddress(bytes32 id, address newAddress) external;

  function setAddressAsProxy(bytes32 id, address impl) external;

  function getAddress(bytes32 id) external view returns (address);

  function getLendingPool() external view returns (address);

  function setLendingPoolImpl(address pool) external;

  function getLendingPoolConfigurator() external view returns (address);

  function setLendingPoolConfiguratorImpl(address configurator) external;

  function getLendingPoolCollateralManager() external view returns (address);

  function setLendingPoolCollateralManager(address manager) external;

  function getPoolAdmin() external view returns (address);

  function setPoolAdmin(address admin) external;

  function getEmergencyAdmin() external view returns (address);

  function setEmergencyAdmin(address admin) external;

  function getPriceOracle() external view returns (address);

  function setPriceOracle(address priceOracle) external;

  function getLendingRateOracle() external view returns (address);

  function setLendingRateOracle(address lendingRateOracle) external;
} 

  



library DataTypes {
  // refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
  struct ReserveData {
    //stores the reserve configuration
    ReserveConfigurationMap configuration;
    //the liquidity index. Expressed in ray
    uint128 liquidityIndex;
    //variable borrow index. Expressed in ray
    uint128 variableBorrowIndex;
    //the current supply rate. Expressed in ray
    uint128 currentLiquidityRate;
    //the current variable borrow rate. Expressed in ray
    uint128 currentVariableBorrowRate;
    //the current stable borrow rate. Expressed in ray
    uint128 currentStableBorrowRate;
    uint40 lastUpdateTimestamp;
    //tokens addresses
    address aTokenAddress;
    address stableDebtTokenAddress;
    address variableDebtTokenAddress;
    //address of the interest rate strategy
    address interestRateStrategyAddress;
    //the id of the reserve. Represents the position in the list of the active reserves
    uint8 id;
  }

  struct ReserveConfigurationMap {
    //bit 0-15: LTV
    //bit 16-31: Liq. threshold
    //bit 32-47: Liq. bonus
    //bit 48-55: Decimals
    //bit 56: Reserve is active
    //bit 57: reserve is frozen
    //bit 58: borrowing is enabled
    //bit 59: stable rate borrowing enabled
    //bit 60-63: reserved
    //bit 64-79: reserve factor
    uint256 data;
  }

  struct UserConfigurationMap {
    uint256 data;
  }

  enum InterestRateMode {NONE, STABLE, VARIABLE}
}

interface ILendingPoolV2 {
  /**
   * @dev Emitted on deposit()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address initiating the deposit
   * @param onBehalfOf The beneficiary of the deposit, receiving the aTokens
   * @param amount The amount deposited
   * @param referral The referral code used
   **/
  event Deposit(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint16 indexed referral
  );

  /**
   * @dev Emitted on withdraw()
   * @param reserve The address of the underlyng asset being withdrawn
   * @param user The address initiating the withdrawal, owner of aTokens
   * @param to Address that will receive the underlying
   * @param amount The amount to be withdrawn
   **/
  event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);

  /**
   * @dev Emitted on borrow() and flashLoan() when debt needs to be opened
   * @param reserve The address of the underlying asset being borrowed
   * @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
   * initiator of the transaction on flashLoan()
   * @param onBehalfOf The address that will be getting the debt
   * @param amount The amount borrowed out
   * @param borrowRateMode The rate mode: 1 for Stable, 2 for Variable
   * @param borrowRate The numeric rate at which the user has borrowed
   * @param referral The referral code used
   **/
  event Borrow(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint256 borrowRateMode,
    uint256 borrowRate,
    uint16 indexed referral
  );

  /**
   * @dev Emitted on repay()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The beneficiary of the repayment, getting his debt reduced
   * @param repayer The address of the user initiating the repay(), providing the funds
   * @param amount The amount repaid
   **/
  event Repay(
    address indexed reserve,
    address indexed user,
    address indexed repayer,
    uint256 amount
  );

  /**
   * @dev Emitted on swapBorrowRateMode()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user swapping his rate mode
   * @param rateMode The rate mode that the user wants to swap to
   **/
  event Swap(address indexed reserve, address indexed user, uint256 rateMode);

  /**
   * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   **/
  event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   **/
  event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on rebalanceStableBorrowRate()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user for which the rebalance has been executed
   **/
  event RebalanceStableBorrowRate(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on flashLoan()
   * @param target The address of the flash loan receiver contract
   * @param initiator The address initiating the flash loan
   * @param asset The address of the asset being flash borrowed
   * @param amount The amount flash borrowed
   * @param premium The fee flash borrowed
   * @param referralCode The referral code used
   **/
  event FlashLoan(
    address indexed target,
    address indexed initiator,
    address indexed asset,
    uint256 amount,
    uint256 premium,
    uint16 referralCode
  );

  /**
   * @dev Emitted when the pause is triggered.
   */
  event Paused();

  /**
   * @dev Emitted when the pause is lifted.
   */
  event Unpaused();

  /**
   * @dev Emitted when a borrower is liquidated. This event is emitted by the LendingPool via
   * LendingPoolCollateral manager using a DELEGATECALL
   * This allows to have the events in the generated ABI for LendingPool.
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param liquidatedCollateralAmount The amount of collateral received by the liiquidator
   * @param liquidator The address of the liquidator
   * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   **/
  event LiquidationCall(
    address indexed collateralAsset,
    address indexed debtAsset,
    address indexed user,
    uint256 debtToCover,
    uint256 liquidatedCollateralAmount,
    address liquidator,
    bool receiveAToken
  );

  /**
   * @dev Emitted when the state of a reserve is updated. NOTE: This event is actually declared
   * in the ReserveLogic library and emitted in the updateInterestRates() function. Since the function is internal,
   * the event will actually be fired by the LendingPool contract. The event is therefore replicated here so it
   * gets added to the LendingPool ABI
   * @param reserve The address of the underlying asset of the reserve
   * @param liquidityRate The new liquidity rate
   * @param stableBorrowRate The new stable borrow rate
   * @param variableBorrowRate The new variable borrow rate
   * @param liquidityIndex The new liquidity index
   * @param variableBorrowIndex The new variable borrow index
   **/
  event ReserveDataUpdated(
    address indexed reserve,
    uint256 liquidityRate,
    uint256 stableBorrowRate,
    uint256 variableBorrowRate,
    uint256 liquidityIndex,
    uint256 variableBorrowIndex
  );

  /**
   * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
   * @param asset The address of the underlying asset to deposit
   * @param amount The amount to be deposited
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  /**
   * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
   * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
   * @param asset The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
   * @param to Address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   **/
  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external;

  /**
   * @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
   * already deposited enough collateral, or he was given enough allowance by a credit delegator on the
   * corresponding debt token (StableDebtToken or VariableDebtToken)
   * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
   *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
   * @param asset The address of the underlying asset to borrow
   * @param amount The amount to be borrowed
   * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   * @param onBehalfOf Address of the user who will receive the debt. Should be the address of the borrower itself
   * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
   * if he has been given credit delegation allowance
   **/
  function borrow(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    uint16 referralCode,
    address onBehalfOf
  ) external;

  /**
   * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
   * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
   * @param asset The address of the borrowed underlying asset previously borrowed
   * @param amount The amount to repay
   * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
   * @param rateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
   * user calling the function if he wants to reduce/remove his own debt, or the address of any other
   * other borrower whose debt should be removed
   **/
  function repay(
    address asset,
    uint256 amount,
    uint256 rateMode,
    address onBehalfOf
  ) external;

  /**
   * @dev Allows a borrower to swap his debt between stable and variable mode, or viceversa
   * @param asset The address of the underlying asset borrowed
   * @param rateMode The rate mode that the user wants to swap to
   **/
  function swapBorrowRateMode(address asset, uint256 rateMode) external;

  /**
   * @dev Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
   * - Users can be rebalanced if the following conditions are satisfied:
   *     1. Usage ratio is above 95%
   *     2. the current deposit APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too much has been
   *        borrowed at a stable rate and depositors are not earning enough
   * @param asset The address of the underlying asset borrowed
   * @param user The address of the user to be rebalanced
   **/
  function rebalanceStableBorrowRate(address asset, address user) external;

  /**
   * @dev Allows depositors to enable/disable a specific deposited asset as collateral
   * @param asset The address of the underlying asset deposited
   * @param useAsCollateral `true` if the user wants to use the deposit as collateral, `false` otherwise
   **/
  function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;

  /**
   * @dev Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
   * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
   *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   **/
  function liquidationCall(
    address collateralAsset,
    address debtAsset,
    address user,
    uint256 debtToCover,
    bool receiveAToken
  ) external;

  /**
   * @dev Allows smartcontracts to access the liquidity of the pool within one transaction,
   * as long as the amount taken plus a fee is returned.
   * IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept into consideration.
   * For further details please visit https://developers.aave.com
   * @param receiverAddress The address of the contract receiving the funds, implementing the IFlashLoanReceiver interface
   * @param assets The addresses of the assets being flash-borrowed
   * @param amounts The amounts amounts being flash-borrowed
   * @param modes Types of the debt to open if the flash loan is not returned:
   *   0 -> Don't open any debt, just revert if funds can't be transferred from the receiver
   *   1 -> Open debt at stable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
   *   2 -> Open debt at variable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
   * @param onBehalfOf The address  that will receive the debt in the case of using on `modes` 1 or 2
   * @param params Variadic packed params to pass to the receiver as extra information
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function flashLoan(
    address receiverAddress,
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata modes,
    address onBehalfOf,
    bytes calldata params,
    uint16 referralCode
  ) external;

  /**
   * @dev Returns the user account data across all the reserves
   * @param user The address of the user
   * @return totalCollateralETH the total collateral in ETH of the user
   * @return totalDebtETH the total debt in ETH of the user
   * @return availableBorrowsETH the borrowing power left of the user
   * @return currentLiquidationThreshold the liquidation threshold of the user
   * @return ltv the loan to value of the user
   * @return healthFactor the current health factor of the user
   **/
  function getUserAccountData(address user)
    external
    view
    returns (
      uint256 totalCollateralETH,
      uint256 totalDebtETH,
      uint256 availableBorrowsETH,
      uint256 currentLiquidationThreshold,
      uint256 ltv,
      uint256 healthFactor
    );

  function initReserve(
    address reserve,
    address aTokenAddress,
    address stableDebtAddress,
    address variableDebtAddress,
    address interestRateStrategyAddress
  ) external;

  function setReserveInterestRateStrategyAddress(address reserve, address rateStrategyAddress)
    external;

  function setConfiguration(address reserve, uint256 configuration) external;

  /**
   * @dev Returns the configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The configuration of the reserve
   **/
  function getConfiguration(address asset) external view returns (DataTypes.ReserveConfigurationMap memory);

  /**
   * @dev Returns the configuration of the user across all the reserves
   * @param user The user address
   * @return The configuration of the user
   **/
  function getUserConfiguration(address user) external view returns (DataTypes.UserConfigurationMap memory);

  /**
   * @dev Returns the normalized income normalized income of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve's normalized income
   */
  function getReserveNormalizedIncome(address asset) external view returns (uint256);

  /**
   * @dev Returns the normalized variable debt per unit of asset
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve normalized variable debt
   */
  function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);

  /**
   * @dev Returns the state and configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The state of the reserve
   **/
  function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);

  function finalizeTransfer(
    address asset,
    address from,
    address to,
    uint256 amount,
    uint256 balanceFromAfter,
    uint256 balanceToBefore
  ) external;

  function getReservesList() external view returns (address[] memory);

  function getAddressesProvider() external view returns (ILendingPoolAddressesProviderV2);

  function setPause(bool val) external;

  function paused() external view returns (bool);
}    





abstract contract IWETH {
    function allowance(address, address) public virtual returns (uint256);

    function balanceOf(address) public virtual returns (uint256);

    function approve(address, uint256) public virtual;

    function transfer(address, uint256) public virtual returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) public virtual returns (bool);

    function deposit() public payable virtual;

    function withdraw(uint256) public virtual;
}    






library TokenUtils {
    using SafeERC20 for IERC20;

    address public constant WETH_ADDR = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant ETH_ADDR = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function approveToken(
        address _tokenAddr,
        address _to,
        uint256 _amount
    ) internal {
        if (_tokenAddr == ETH_ADDR) return;

        if (IERC20(_tokenAddr).allowance(address(this), _to) < _amount) {
            IERC20(_tokenAddr).safeApprove(_to, _amount);
        }
    }

    function pullTokensIfNeeded(
        address _token,
        address _from,
        uint256 _amount
    ) internal returns (uint256) {
        // handle max uint amount
        if (_amount == type(uint256).max) {
            uint256 userAllowance = IERC20(_token).allowance(_from, address(this));
            uint256 balance = getBalance(_token, _from);

            // pull max allowance amount if balance is bigger than allowance
            _amount = (balance > userAllowance) ? userAllowance : balance;
        }

        if (_from != address(0) && _from != address(this) && _token != ETH_ADDR && _amount != 0) {
            IERC20(_token).safeTransferFrom(_from, address(this), _amount);
        }

        return _amount;
    }

    function withdrawTokens(
        address _token,
        address _to,
        uint256 _amount
    ) internal returns (uint256) {
        if (_amount == type(uint256).max) {
            _amount = getBalance(_token, address(this));
        }

        if (_to != address(0) && _to != address(this) && _amount != 0) {
            if (_token != ETH_ADDR) {
                IERC20(_token).safeTransfer(_to, _amount);
            } else {
                payable(_to).transfer(_amount);
            }
        }

        return _amount;
    }

    function depositWeth(uint256 _amount) internal {
        IWETH(WETH_ADDR).deposit{value: _amount}();
    }

    function withdrawWeth(uint256 _amount) internal {
        IWETH(WETH_ADDR).withdraw(_amount);
    }

    function getBalance(address _tokenAddr, address _acc) internal view returns (uint256) {
        if (_tokenAddr == ETH_ADDR) {
            return _acc.balance;
        } else {
            return IERC20(_tokenAddr).balanceOf(_acc);
        }
    }

    function getTokenDecimals(address _token) internal view returns (uint256) {
        if (_token == ETH_ADDR) return 18;

        return IERC20(_token).decimals();
    }
}    



/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}    


  












/// @title Action that gets and receives a FL from Aave V2
contract FLAaveV2 is ActionBase, StrategyData, DSMath, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using TokenUtils for address;

    string constant ERR_ONLY_AAVE_CALLER = "Caller not aave pool";
    string constant ERR_SAME_CALLER = "FL taker must be this contract";

    address
        public constant AAVE_LENDING_POOL = 0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9;

    ILendingPoolAddressesProviderV2
        public constant addressesProvider = ILendingPoolAddressesProviderV2(
        0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5
    );

    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint16 public constant AAVE_REFERRAL_CODE = 64;

    /// @dev Function sig of TaskExecutor._executeActionsFromFL()
    bytes4 public constant CALLBACK_SELECTOR = 0xd6741b9e;

    bytes32 constant TASK_EXECUTOR_ID = keccak256("TaskExecutor");

    struct FLAaveV2Data {
        address[] tokens;
        uint256[] amounts;
        uint256[] modes;
        address onBehalfOf;
        address flParamGetterAddr;
        bytes flParamGetterData;
    }

    /// @inheritdoc ActionBase
    function executeAction(
        bytes[] memory _callData,
        bytes[] memory,
        uint8[] memory,
        bytes32[] memory
    ) public override payable returns (bytes32) {
        FLAaveV2Data memory flData = parseInputs(_callData);

        // if we want to get on chain info about FL params
        if (flData.flParamGetterAddr != address(0)) {
            (flData.tokens, flData.amounts, flData.modes) =
                IFLParamGetter(flData.flParamGetterAddr).getFlashLoanParams(flData.flParamGetterData);
        }

        bytes memory taskData = _callData[_callData.length - 1];
        uint flAmount = _flAaveV2(flData, taskData);

        return bytes32(flAmount);
    }

    // solhint-disable-next-line no-empty-blocks
    function executeActionDirect(bytes[] memory _callData) public override payable {}

    /// @inheritdoc ActionBase
    function actionType() public override pure returns (uint8) {
        return uint8(ActionType.FL_ACTION);
    }

    //////////////////////////// ACTION LOGIC ////////////////////////////

    /// @notice Gets a Fl from AaveV2 and returns back the execution to the action address
    /// @param _flData All the amounts/tokens and related aave fl data
    /// @param _params Rest of the data we have in the task
    function _flAaveV2(FLAaveV2Data memory _flData, bytes memory _params) internal returns (uint) {

        ILendingPoolV2(AAVE_LENDING_POOL).flashLoan(
            address(this),
            _flData.tokens,
            _flData.amounts,
            _flData.modes,
            _flData.onBehalfOf,
            _params,
            AAVE_REFERRAL_CODE
        );

        logger.Log(
            address(this),
            msg.sender,
            "FLAaveV2",
            abi.encode(_flData.tokens, _flData.amounts, _flData.modes, _flData.onBehalfOf)
        );

        return _flData.amounts[0];
    }

    /// @notice Aave callback function that formats and calls back TaskExecutor
    function executeOperation(
        address[] memory _assets,
        uint256[] memory _amounts,
        uint256[] memory _fees,
        address _initiator,
        bytes memory _params
    ) public nonReentrant returns (bool) {
        require(msg.sender == AAVE_LENDING_POOL, ERR_ONLY_AAVE_CALLER);
        require(_initiator == address(this), ERR_SAME_CALLER);

        (Task memory currTask, address proxy) = abi.decode(_params, (Task, address));

        // Send FL amounts to user proxy
        for (uint256 i = 0; i < _assets.length; ++i) {
            _assets[i].withdrawTokens(proxy, _amounts[i]);
        }

        address payable taskExecutor = payable(registry.getAddr(TASK_EXECUTOR_ID));

        // call Action execution
        IDSProxy(proxy).execute{value: address(this).balance}(
            taskExecutor,
            abi.encodeWithSelector(CALLBACK_SELECTOR, currTask, bytes32(add(_amounts[0],_fees[0])))
        );

        // return FL
        for (uint256 i = 0; i < _assets.length; i++) {
            _assets[i].approveToken(address(AAVE_LENDING_POOL), add(_amounts[i],_fees[i]));
        }

        return true;
    }

    function parseInputs(bytes[] memory _callData)
        public
        pure
        returns (FLAaveV2Data memory flData)
    {
        flData.amounts = abi.decode(_callData[0], (uint256[]));
        flData.tokens = abi.decode(_callData[1], (address[]));
        flData.modes = abi.decode(_callData[2], (uint256[]));
        flData.onBehalfOf = abi.decode(_callData[3], (address));
        flData.flParamGetterAddr = abi.decode(_callData[4], (address));
        flData.flParamGetterData = abi.decode(_callData[5], (bytes));
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}
}