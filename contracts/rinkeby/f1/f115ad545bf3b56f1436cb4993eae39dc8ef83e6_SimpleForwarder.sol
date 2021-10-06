/**
 *Submitted for verification at Etherscan.io on 2021-10-06
*/

contract Enum {
    enum Operation {Call, DelegateCall}
}


contract SimpleForwarder {
    function execute(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 txGas
    ) internal returns (bool success) {
        if (operation == Enum.Operation.DelegateCall) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                success := delegatecall(txGas, to, add(data, 0x20), mload(data), 0, 0)
            }
        } else {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                success := call(txGas, to, value, add(data, 0x20), mload(data), 0, 0)
            }
        }
    }
    
    function delegateForward(address to, bytes memory data, uint256 txGas)
        external
        returns (bool success)
    {
        success = execute(to, 0, data, Enum.Operation.DelegateCall, txGas);
        require(success, string(abi.encode("delegate call failed")));
    }
    
    function forward(address to, bytes memory data, uint256 txGas) external returns (bool success) {
        success = execute(to, 0, data, Enum.Operation.Call, txGas);
        require(success, string(abi.encode("call failed")));
    }
}