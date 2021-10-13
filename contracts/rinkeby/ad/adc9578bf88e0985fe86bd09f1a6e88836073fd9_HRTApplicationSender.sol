/**
 *Submitted for verification at Etherscan.io on 2021-10-13
*/

contract HRTApplication {
    event Application(bytes data, address sender, address origin);

    bytes public publicKey;

    constructor(bytes memory _publicKey) {
        publicKey = _publicKey;
    }

    function sendApplication(bytes calldata data) public {
        require(msg.sender != tx.origin, 'Must apply from a smart contract!');
        emit Application(data, msg.sender, tx.origin);
    }
}

contract HRTApplicationSender {
    function sendApplication(address to, bytes calldata data) public {
        HRTApplication(to).sendApplication(data);
    }
}