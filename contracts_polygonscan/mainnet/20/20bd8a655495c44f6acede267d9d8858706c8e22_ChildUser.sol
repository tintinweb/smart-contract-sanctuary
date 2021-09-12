/**
 *Submitted for verification at polygonscan.com on 2021-09-12
*/

pragma solidity 0.7.3;

// IFxMessageProcessor represents interface to process message
interface IFxMessageProcessor {
    function processMessageFromRoot(uint256 stateId, address rootMessageSender, bytes calldata data) external;
}

contract ChildUser is IFxMessageProcessor {
    address public constant FX_CHILD = address(0x8397259c983751DAf40400790063935a11afa28a);

    address public constant MASTER = address(0x84E94F8032b3F9fEc34EE05F192Ad57003337988);
    
    uint256 public result;
    
    bytes public log1;
    bytes public log2;
    
    function processMessageFromRoot(uint256 stateId, address rootMessageSender, bytes calldata data) external override {
        // Check FxChild is a local sender
        // require(msg.sender == address(FX_CHILD), "Not FxChild");
        // Check Master is a remote sender
        // require(rootMessageSender == address(MASTER), "Not Master");
        log1 = data;
        
        (bytes memory bytesRes) = abi.decode(data, (bytes));
        log2 = bytesRes;
        
        // require(bytesRes.length >= 32, "data too short");
        // uint256 res;
        // assembly {
        //     res := mload(add(bytesRes, add(0x20, 0)))
        // }
        
        // result = res;
        
        // stateId;
    }
    
    function decodeBytes(bytes calldata data) pure external returns (bytes memory) {
        (bytes memory res) = abi.decode(data, (bytes));
        return res;
        
    }
    
    function decodeUint256(bytes calldata data) pure external returns (uint256) {
        (bytes memory bytesRes) = abi.decode(data, (bytes));
        require(bytesRes.length >= 32, "data too short");
        uint256 res;
        assembly {
            res := mload(add(bytesRes, add(0x20, 0)))
        }
        
        return res;
        
    }
}