/**
 *Submitted for verification at polygonscan.com on 2021-09-13
*/

pragma solidity 0.7.3;

// IFxMessageProcessor represents interface to process message
interface IFxMessageProcessor {
    function processMessageFromRoot(uint256 stateId, address rootMessageSender, bytes calldata data) external;
}

contract ChildUser is IFxMessageProcessor {
    event MessageProcessed(uint256 stateId, address rootMessageSender, bytes data);
    
    address public constant FX_CHILD = address(0x8397259c983751DAf40400790063935a11afa28a);
    address public constant MASTER = address(0x84E94F8032b3F9fEc34EE05F192Ad57003337988);
    
    bytes public latestResult;
    
    mapping (uint256 => uint256) public proposedValues;
    mapping (uint256 => bool) public isProposed;
    
    function processMessageFromRoot(uint256 stateId, address rootMessageSender, bytes calldata data) external override {
        emit MessageProcessed(stateId, rootMessageSender, data);
        
        // Check FxChild is a local sender
        // require(msg.sender == address(FX_CHILD), "Not FxChild");
        // Check Master is a remote sender
        // require(rootMessageSender == address(MASTER), "Not Master");
        
        latestResult = data;
    }
    
    function proposeLatestResult() external {
        (bytes memory latestResultParsed) = abi.decode(latestResult, (bytes));
        (uint256 timestamp, uint256 price) = abi.decode(latestResultParsed, (uint256, uint256));
        proposedValues[timestamp] = price;
        isProposed[timestamp] = true;
    }
    
    function decodeResult(bytes calldata data) external view returns (uint256 timestamp, uint256 price) {
        (bytes memory res) = abi.decode(data, (bytes));
        (timestamp, price) = abi.decode(res, (uint256, uint256));
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
    
    function encodeBytes(uint256 timestamp, uint256 price) pure external returns (bytes memory) {
        return abi.encode(timestamp, price);
    }
}