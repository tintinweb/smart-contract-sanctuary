/**
 *Submitted for verification at polygonscan.com on 2021-09-02
*/

pragma solidity 0.7.3;

// IFxMessageProcessor represents interface to process message
interface IFxMessageProcessor {
    function processMessageFromRoot(uint256 stateId, address rootMessageSender, bytes calldata data) external;
}

contract ChildUser is IFxMessageProcessor {
    address public constant FX_CHILD = address(0x8397259c983751DAf40400790063935a11afa28a);

    address public constant MASTER = address(0x84E94F8032b3F9fEc34EE05F192Ad57003337988);
    
    bytes public result;
    
    function processMessageFromRoot(uint256 stateId, address rootMessageSender, bytes calldata data) external override {
        // Check FxChild is a local sender
        require(msg.sender == address(FX_CHILD), "Not FxChild");
        // Check Master is a remote sender
        require(rootMessageSender == address(MASTER), "Not Master");
        
        result = data;
        
        stateId;
    }
}