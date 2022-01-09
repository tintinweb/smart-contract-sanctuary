pragma solidity ^0.8.0;

contract Messaging {
    uint256 public threadCount = 1;

    // TODO - Usage Global metrics to get total number of messages,threads stored
    // uint256 public messagesCount;
    

    mapping(address => uint256[]) private threadIds;
    mapping(uint256 => Thread) private threads;
    mapping(address => string) private pubEncKeys; // mapping of address to public encryption key https://docs.metamask.io/guide/rpc-api.html#eth-getencryptionpublickey

    mapping(uint256 => Message[]) public messages;
    uint256 public messagesIndex = 0;

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
        address sender,
        string uri,
        uint256 timestamp
    );

    function getPubEncKeys(address receiver) public view returns(string memory sender_key, string memory receiver_key) {

        require(bytes(pubEncKeys[msg.sender]).length != 0, "Sender must be registered to use service");

        if (bytes(pubEncKeys[msg.sender]).length != 0) {
            sender_key = pubEncKeys[msg.sender];
        }
        if (bytes(pubEncKeys[receiver]).length != 0) {
            receiver_key = pubEncKeys[receiver];
        }
        return (sender_key, receiver_key);
    }

    function setPubEncKey(string memory encKey) public {
        pubEncKeys[msg.sender] = encKey;
    }

    function newThread(
        address _receiver,
        string memory _sender_key,
        string memory _receiver_key
    ) internal returns (uint256) {
       

        threads[threadCount] = Thread(
            threadCount,
            _receiver,
            _receiver_key,
            msg.sender,
            _sender_key
        );

        threadIds[msg.sender].push(threadCount);
        threadIds[_receiver].push(threadCount);

        threadCount++;

        return threadCount-1;
    }

    function getAllThreads() public view returns(uint256[] memory) {
        if(threadIds[msg.sender].length != 0 ) {
            require(threads[threadIds[msg.sender][0]].sender == msg.sender || threads[threadIds[msg.sender][0]].receiver == msg.sender );
            return threadIds[msg.sender];
        }
    }

    function getThread(uint thread_id) public view returns(Thread memory) {
        if(threadIds[msg.sender].length != 0 ) {
            require(threads[thread_id].sender == msg.sender || threads[thread_id].receiver == msg.sender );
            return threads[thread_id];
        }
    }

    function getMessages(uint thread_id) public view returns(Message[] memory) {
        if(threadIds[msg.sender].length != 0 ) {
            require(threads[thread_id].sender == msg.sender || threads[thread_id].receiver == msg.sender );
            return messages[thread_id];
        }
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

            emit MessageSent(_receiver, msg.sender, _uri, block.timestamp);
        } else {
            Thread storage thread = threads[_thread_id];

            require(
                msg.sender == thread.receiver || msg.sender == thread.sender,
                "Only the receiver & sender can reply to the messages."
            );

            messages[_thread_id].push(
                Message(_receiver, _uri, block.timestamp)
            );

            emit MessageSent(_receiver, msg.sender, _uri, block.timestamp);
        }
    }
}