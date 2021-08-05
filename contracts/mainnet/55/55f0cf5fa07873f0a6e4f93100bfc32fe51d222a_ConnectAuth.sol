/**
 *Submitted for verification at Etherscan.io on 2020-04-27
*/

pragma solidity ^0.6.0;

/**
 * @title ConnectAuth.
 * @dev Connector For Adding Authorities.
 */

interface AccountInterface {
    function enable(address) external;
    function disable(address) external;
}

interface EventInterface {
    function emitEvent(uint _connectorType, uint _connectorID, bytes32 _eventCode, bytes calldata _eventData) external;
}


contract Basics {

    /**
     * @dev Return InstaEvent Address.
     */
    function getEventAddr() public pure returns (address) {
        return 0x2af7ea6Cb911035f3eb1ED895Cb6692C39ecbA97;
    }

     /**
     * @dev Connector ID and Type.
     */
    function connectorID() public pure returns(uint _type, uint _id) {
        (_type, _id) = (1, 10);
    }

}


contract Auth is Basics {

    event LogAddAuth(address indexed _msgSender, address indexed _authority);
    event LogRemoveAuth(address indexed _msgSender, address indexed _authority);

    /**
     * @dev Add New authority
     * @param authority authority Address.
     */
    function add(address authority) public payable {
        AccountInterface(address(this)).enable(authority);

        emit LogAddAuth(msg.sender, authority);

        bytes32 _eventCode = keccak256("LogAddAuth(address,address)");
        bytes memory _eventParam = abi.encode(msg.sender, authority);
        (uint _type, uint _id) = connectorID();
        EventInterface(getEventAddr()).emitEvent(_type, _id, _eventCode, _eventParam);
    }

    /**
     * @dev Remove authority
     * @param authority authority Address.
     */
    function remove(address authority) public payable {
        AccountInterface(address(this)).disable(authority);

        emit LogRemoveAuth(msg.sender, authority);

        bytes32 _eventCode = keccak256("LogRemoveAuth(address,address)");
        bytes memory _eventParam = abi.encode(msg.sender, authority);
        (uint _type, uint _id) = connectorID();
        EventInterface(getEventAddr()).emitEvent(_type, _id, _eventCode, _eventParam);
    }

}


contract ConnectAuth is Auth {
    string public constant name = "Auth-v1";
}