// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

import "./Operators.sol";

contract ServerMultiCall is Operators {
    
    struct FunctionCall {
        address operator;
        uint16 callID;
        uint16 demand; //must execute at least once every x seconds, 0 disables the call
        uint16 cooldown; //don't execute if done in the last x seconds, 0 disables the call
        uint48 lastExecuted; //timestamp of last execution
        
        address callAddr; //address to call
        uint96 gasLimit; //gas to send
        string signature; //such as "withdraw(uint256)"
        bytes data; //everything that follows, empty if the function doesn't need any parameters
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
            (bool success, bytes memory returnData) = _call.callAddr.call{gas: _call.gasLimit}(abi.encodeWithSignature(_call.signature, _call.data));
            _call.lastExecuted = uint48(block.timestamp);
            
            uint gasUsed = _gas - gasleft();
            emit CallOutput(_call.callID, success, gasUsed, returnData);
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

    modifier onlyServer() {
        require(msg.sender == config.server || operators[msg.sender], "Not assigned server account");
        _;
    }

    function addCall(uint16 demand, uint16 cooldown, address callAddr, uint96 gasLimit, string calldata signature, bytes calldata data) external onlyOperator {
        require(demand >= cooldown, "demand time can't be shorter than cooldown");
        require(cooldown == 0 || cooldown < config.minCooldown, "invalid cooldown");
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
    }
    function setCall(uint16 callID, uint16 demand, uint16 cooldown, address callAddr, uint96 gasLimit, string calldata signature, bytes calldata data) external onlyOperator {
        FunctionCall storage newCall = calls[callID];
        require(newCall.operator == msg.sender || newCall.operator == owner());
        require(demand >= cooldown, "demand time can't be shorter than cooldown");
        require(cooldown == 0 || cooldown >= config.minCooldown, "invalid cooldown");
        require(isContract(callAddr), "target must be a contract");
        require(msg.sender == owner() || gasLimit < config.operatorGasLimit);
        require(msg.sender == owner() || numCallsOperator(msg.sender) < config.operatorMaxCalls, "too many calls for operator");
        
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
            if (calls[i].operator == _op) count++;
        }
    }
    
    function performOperations() external onlyServer returns (uint callAgainAt) { //suggests to the server when it should call again; 0 means right away
    
        //execute demands    
        for (uint i; i < calls.length; i++) {
            if (gasleft() < 100000) break;
            if (calls[i].demand == 0 || calls[i].cooldown == 0) continue;
            if (calls[i].demand + calls[i].lastExecuted < block.timestamp) {
                uint _demand = doCall(calls[i]);
                if (_demand < callAgainAt) callAgainAt = _demand;
            }
        }
        //execute off-cooldown tasks   
        for (uint i; i < calls.length; i++) {
            if (gasleft() < 100000) break;
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