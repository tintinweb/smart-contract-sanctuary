/**
 *Submitted for verification at Etherscan.io on 2022-01-06
*/

contract MyContract {
    string public message = "Buy $ASH";
    address public owner = msg.sender;

    modifier ownerOnly() {
        require(msg.sender == owner, "Function restricted to owner");
        _;
    }

    function setMessage(string memory _newMessage) public ownerOnly returns(string memory) {
        message = _newMessage;
        return message;
    }

}