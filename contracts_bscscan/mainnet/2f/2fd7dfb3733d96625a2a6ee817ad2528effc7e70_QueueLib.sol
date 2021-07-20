/**
 *Submitted for verification at BscScan.com on 2021-07-20
*/

pragma solidity <=0.7.0;

library QueueLib {
    struct Queue {
        bytes32 first;
        bytes32 last;
        mapping(bytes32 => bytes32) nextElement;
        mapping(bytes32 => bytes32) prevElement;
    }

    function drop(Queue storage queue, bytes32 rqHash) public {
        bytes32 prevElement = queue.prevElement[rqHash];
        bytes32 nextElement = queue.nextElement[rqHash];

        if (prevElement != bytes32(0)) {
            queue.nextElement[prevElement] = nextElement;
        } else {
            queue.first = nextElement;
        }

        if (nextElement != bytes32(0)) {
            queue.prevElement[nextElement] = prevElement;
        } else {
            queue.last = prevElement;
        }
    }

    // function next(Queue storage queue, bytes32 startRqHash) public view returns(bytes32) {
    //     if (startRqHash == 0x000)
    //         return queue.first;
    //     else {
    //         return queue.nextElement[startRqHash];
    //     }
    // }

    function push(Queue storage queue, bytes32 elementHash) public {
        if (queue.first == 0x000) {
            queue.first = elementHash;
            queue.last = elementHash;
        } else {
            queue.nextElement[queue.last] = elementHash;
            queue.prevElement[elementHash] = queue.last;
            queue.nextElement[elementHash] = bytes32(0);
            queue.last = elementHash;
        }
    }
}