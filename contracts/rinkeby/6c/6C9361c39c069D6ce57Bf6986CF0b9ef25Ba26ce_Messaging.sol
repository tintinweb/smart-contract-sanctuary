pragma solidity ^0.8.0;

contract Messaging {
    uint256 public threadCount = 1;

    mapping(uint256 => Thread) public threads;
    mapping(uint256 => Message[]) public messages;
    uint256 public messagesIndex = 0;
    mapping(address => string) private pubEncKeys; // mapping of address to public encryption key https://docs.metamask.io/guide/rpc-api.html#eth-getencryptionpublickey


    struct Thread {
        uint256 thread_id;
        address receiver;
        string receiver_key;
        address sender;
        string sender_key;
    }

    struct Message {
        address receiver;
        string uri;
        uint256 timestamp;
    }

    event MessageSent (
        address receiver,
        string uri,
        uint256 timestamp
    );

    function getPubEncKeys(address receiver) public view returns(string memory sender_key, string memory receiver_key) {

        require(msg.sender == receiver, "0");
        require(bytes(pubEncKeys[msg.sender]).length != 0, "-1");
        require(bytes(pubEncKeys[receiver]).length != 0, "-2");

        if (bytes(pubEncKeys[msg.sender]).length != 0) {
            sender_key = pubEncKeys[msg.sender];
        }
        if (bytes(pubEncKeys[receiver]).length != 0) {
            receiver_key = pubEncKeys[receiver];
        }
        return (sender_key, receiver_key);
    }

    function checkUserRegistration() public view returns(bool) {
        return bytes(pubEncKeys[msg.sender]).length != 0;
    }

    function setPubEncKey(string memory encKey) public {
        pubEncKeys[msg.sender] = encKey;
    }

    function newThread(
        address _receiver,
        string memory _sender_key,
        string memory _receiver_key
    ) internal returns (uint256) {
        threadCount++;

        threads[threadCount] = Thread(
            threadCount,
            _receiver,
            _receiver_key,
            msg.sender,
            _sender_key
        );

        return threadCount;
    }

    function sendMessage(
        uint256 _thread_id,
        string memory _uri,
        address _receiver,
        string memory _sender_key,
        string memory _receiver_key
    ) public {
        if (_thread_id == 0) {
            uint256 new_thread_id = newThread(
                _receiver,
                _sender_key,
                _receiver_key
            );

            messages[new_thread_id].push(
                Message(_receiver, _uri, block.timestamp)
            );

            emit MessageSent(_receiver, _uri, block.timestamp);
        } else {
            Thread storage thread = threads[_thread_id];

            require(
                msg.sender == thread.receiver || msg.sender == thread.sender,
                "Only the receiver & sender can reply to the messages."
            );

            messages[thread.thread_id].push(
                Message(_receiver, _uri, block.timestamp)
            );

            emit MessageSent(_receiver, _uri, block.timestamp);
        }
    }
}