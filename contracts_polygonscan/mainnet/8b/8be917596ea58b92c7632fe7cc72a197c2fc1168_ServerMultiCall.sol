/**
 *Submitted for verification at polygonscan.com on 2021-09-11
*/

// File: @openzeppelin/contracts/utils/Context.sol



pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: polycrystal-on-chain-stats/contracts/Operators.sol



pragma solidity ^0.8.4;


contract Operators is Ownable {
    mapping(address => bool) public operators;

    event OperatorUpdated(address indexed operator, bool indexed status);

    modifier onlyOperator() {
        require(operators[msg.sender], "Operator: caller is not the operator");
        _;
    }

    // Update the status of the operator
    function updateOperator(address _operator, bool _status) external onlyOwner {
        operators[_operator] = _status;
        emit OperatorUpdated(_operator, _status);
    }
}
// File: polycrystal-on-chain-stats/contracts/ServerMultiCall.sol



pragma solidity ^0.8.0;


contract ServerMultiCall is Operators {
    
    struct FunctionCall {
        address operator;
        uint16 callID;
        uint16 demand; //must execute at least once every x seconds, 0 disables demand
        uint16 cooldown; //don't execute if done in the last x seconds, 0 disables the call
        uint48 lastExecuted; //timestamp of last execution
        
        address callAddr; //address to call
        uint96 gasLimit; //gas to send
        string signature; //such as "withdraw(uint256)"
        bytes data; //everything that follows, empty ("0x") if the function doesn't need any parameters
    }
    struct Config {
        address server;
        uint totalGasLimit; //maximum gas used by all calls
        uint operatorGasLimit; //maximum gas used by an operator
        uint operatorMaxCalls; //operator can't have more than this number of calls
        uint callMaxGasLimit; //the maximum gas allowed in one call
        uint minCooldown; //function calls can't be run more often than this
    }
    
    Config public config;
    FunctionCall[] public calls;
    
    function doCall(FunctionCall storage _call) internal returns (uint nextDemandTime) {
        uint _gas = gasleft();
        if (_gas > _call.gasLimit + 100000) {
            (bool success, bytes memory returnData) = _call.callAddr.call/*{value: 0, gas: _call.gasLimit}*/(abi.encodeWithSignature(_call.signature, _call.data));
            _call.lastExecuted = uint48(block.timestamp);
            
            uint gasUsed = _gas - gasleft();
            emit CallOutput(_call.callID, success, gasUsed, returnData);
        } else {
            emit AbortLowGas(_call.callID, _call.gasLimit, _gas);
        }
        return _call.lastExecuted + _call.demand;
    }
    
    
    function setConfig(Config calldata _config) external onlyOwner {
        config = _config;
        emit SetConfig(_config);
    }
    
    event OperatorUpdated(address indexed operator, bool indexed status, uint gasLimit);
    event ServerUpdated(address indexed _server);
    event CallOutput(uint indexed callID, bool indexed success, uint gasUsed, bytes returnData);
    event SetConfig(Config _config);
    event SetCall(FunctionCall _call);
    event AbortLowGas(uint16 indexed _callID, uint _gasLimit, uint _gasLeft);
    constructor() {
        operators[msg.sender] = true;
        config = Config({
            server: address(0),
            totalGasLimit: 18000000,
            operatorGasLimit: 5000000,
            operatorMaxCalls: 2,
            callMaxGasLimit: 5000000,
            minCooldown: 300
        });
    }
    

    modifier onlyServer() {
        require(msg.sender == config.server || operators[msg.sender], "Not assigned server account");
        _;
    }

    function addCall(uint16 demand, uint16 cooldown, address callAddr, uint96 gasLimit, string calldata signature, bytes calldata data) external onlyOperator {
        require(cooldown == 0 || demand >= cooldown, "demand time can't be shorter than cooldown");
        require(cooldown == 0 || cooldown > config.minCooldown, "invalid cooldown");
        require(isContract(callAddr), "target must be a contract");
        require(msg.sender == owner() || gasLimit < config.operatorGasLimit);
        require(msg.sender == owner() || numCallsOperator(msg.sender) < config.operatorMaxCalls, "too many calls for operator");
        FunctionCall memory newCall = FunctionCall({
            operator: msg.sender,
            callID: uint16(calls.length),
            demand: demand,
            cooldown: cooldown,
            lastExecuted: 0,
            callAddr: callAddr,
            gasLimit: gasLimit,
            signature: signature,
            data: data
        });
        calls.push() = newCall;
        emit SetCall(newCall);
        
        doCall(calls[calls.length - 1]);
    }
    function setCall(uint16 callID, uint16 demand, uint16 cooldown, address callAddr, uint96 gasLimit, string calldata signature, bytes calldata data) external onlyOperator {
        FunctionCall storage newCall = calls[callID];

        require(cooldown == 0 || cooldown >= config.minCooldown, "invalid cooldown");
        require(isContract(callAddr), "target must be a contract");
        
        if (msg.sender != owner()) {
            require(newCall.operator == msg.sender, "must be operator who created call, or owner");
            require(cooldown == 0 || demand >= cooldown, "demand time can't be shorter than cooldown");
            require(gasLimit < config.operatorGasLimit, "exceeds gas limit config");
            require(numCallsOperator(msg.sender) < config.operatorMaxCalls || cooldown == 0);
        }
        
        newCall.demand = demand;
        newCall.cooldown = cooldown;
        newCall.callAddr = callAddr;
        newCall.gasLimit = gasLimit;
        newCall.signature = signature;
        newCall.data = data;
        emit SetCall(newCall);
    }
    function numCallsOperator(address _op) internal view returns (uint count) {
        for (uint i; i < calls.length; i++) {
            if (calls[i].operator == _op && calls[i].cooldown > 0) count++;
        }
    }
    
    function performOperations() external payable onlyServer returns (uint callAgainAt) { //suggests to the server when it should call again; 0 means right away
        require (gasleft() >= 2000000, "not enough starting gas");
        require (msg.value == 0, "function should not actually receive ether");
        
        callAgainAt = type(uint).max;
        //execute demands    
        for (uint i; i < calls.length; i++) {
            if (gasleft() < 100000) return 0;
            if (calls[i].demand == 0 || calls[i].cooldown == 0) continue;
            if (calls[i].demand + calls[i].lastExecuted < block.timestamp) {
                uint _demand = doCall(calls[i]);
                if (_demand < callAgainAt) callAgainAt = _demand;
            }
        }
        //execute off-cooldown tasks   
        for (uint i; i < calls.length; i++) {
            if (gasleft() < 100000) return 0;
            if (calls[i].demand == 0 || calls[i].cooldown == 0) continue;
            if (calls[i].cooldown + calls[i].lastExecuted < block.timestamp) {
                uint _demand = doCall(calls[i]);
                if (_demand < callAgainAt) callAgainAt = _demand;
            }
        }
    }
    function isContract(address account) private view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }    
    
}