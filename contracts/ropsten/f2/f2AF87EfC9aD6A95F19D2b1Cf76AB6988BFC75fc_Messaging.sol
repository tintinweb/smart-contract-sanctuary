pragma solidity ^0.8.0;

contract Messaging {
    uint256 public threadCount = 1;
    mapping(uint256 => Thread) public threads;
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
        } else {
            Thread storage thread = threads[_thread_id];

            require(
                msg.sender == thread.receiver || msg.sender == thread.sender,
                "Only the receiver & sender can reply to the messages."
            );

            messages[thread.thread_id].push(
                Message(_receiver, _uri, block.timestamp)
            );
        }
    }
}