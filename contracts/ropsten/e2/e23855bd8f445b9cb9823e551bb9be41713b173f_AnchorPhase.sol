/**
 *Submitted for verification at Etherscan.io on 2019-07-08
*/

pragma solidity 0.5.10;
pragma experimental ABIEncoderV2;


/**
 * @title LinkedList
 *
 * This library allows to store and use linked list.
 *
 * The List structure stores the first and the last item and a mapping of nodes.
 * Each element in a Node structure contains a reference to the next and previous element.
 */

library LinkedList {
    struct List {
        // nodes
        uint64 first;
        uint64 last;
        mapping (uint64 => Node) nodes;
    }

    struct Node {
        // links
        uint64 prev;
        uint64 next;
    }

    function linkFirst(List storage list, uint64 _id) internal {
        linkInside(list, _id, 0, list.first);
    }

    function linkLast(List storage list, uint64 _id) internal {
        linkInside(list, _id, list.last, 0);
    }

    function linkBefore(List storage list, uint64 _id, uint64 _target) internal {
        linkInside(list, _id, list.nodes[_target].prev, _target);
    }

    function linkInside(List storage list, uint64 _id, uint64 _prev, uint64 _next) internal {
        Node storage prev = list.nodes[_prev];
        Node storage next = list.nodes[_next];

        // Sanity checks.
        assert(list.nodes[_id].prev == 0);
        assert(list.nodes[_id].next == 0);
        assert(
            (prev.next == _next && next.prev == _prev) ||
            (_prev == 0 && _next == list.first) ||
            (_prev == list.last && _next == 0)
        );

        list.nodes[_id] = Node({prev: _prev, next: _next});

        if (_prev == 0) {
            list.first = _id;
        } else {
            prev.next = _id;
        }
        if (_next == 0) {
            list.last = _id;
        } else {
            next.prev = _id;
        }
    }

    function unlink(List storage list, uint64 _index) internal {
        Node storage node = list.nodes[_index];
        uint64 prev = node.prev;
        uint64 next = node.next;

        // Sanity checks.
        assert(
            prev != 0 ||
            next != 0 ||
            _index == list.first ||
            _index == list.last
        );

        if (prev == 0) {
            list.first = next;
        } else {
            list.nodes[prev].next = next;
            node.prev = 0;
        }

        if (next == 0) {
            list.last = prev;
        } else {
            list.nodes[next].prev = prev;
            node.next = 0;
        }

        delete list.nodes[_index];
    }

    function setHead(List storage list, uint64 _targetId) internal {
        uint64 current = list.first;
        while (current != _targetId) {
            uint64 temp = current;
            current = list.nodes[current].next;

            delete list.nodes[temp];
        }

        if (_targetId == 0) {
            list.first = 0;
            list.last = 0;
            return;
        }

        list.nodes[_targetId].prev = 0;
        list.first = _targetId;
    }

    function getNext(List storage list, uint64 _nodeId) public view returns(uint64) {
        return list.nodes[_nodeId].next;
    }

    function getPrev(List storage list, uint64 _nodeId) public view returns(uint64) {
        return list.nodes[_nodeId].prev;
    }
}


interface ERC20Interface {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed from, address indexed spender, uint256 value);

    function totalSupply() external view returns(uint256 supply);
    function balanceOf(address _owner) external view returns(uint256 balance);
    //solhint-disable-next-line no-simple-event-func-name
    function transfer(address _to, uint256 _value) external returns(bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns(bool success);
    function approve(address _spender, uint256 _value) external returns(bool success);
    function allowance(address _owner, address _spender) external view returns(uint256 remaining);

    function symbol() external view returns(string memory);
    function decimals() external view returns(uint8);
    function name() external view returns(string memory);
}

interface EToken2Interface {
    function reissueAsset(bytes32 _symbol, uint _value) external returns(bool);
    function revokeAsset(bytes32 _symbol, uint _value) external returns(bool);
}

interface AssetProxyInterface {
    function etoken2Symbol() external view returns(bytes32);
    function etoken2() external view returns(EToken2Interface);
}

interface AnchorPhaseInterface {
    function anct() external view returns(ERC20Interface);
    function doct() external view returns(ERC20Interface);
    function ANCT() external view returns(bytes32);
    function DOCT() external view returns(bytes32);
    function eToken2() external view returns(EToken2Interface);
}

contract AnchorManagerInterface {
    function executeContraction(uint _doctValue) external;
    function executeExpansion(uint _anctValue) external;
    function execute(address _to, bytes calldata _data) external;
}


contract AnchorPhase is AnchorPhaseInterface {
    event ContractionPhaseResponse(
        uint64 responseId,
        uint responseValue,
        address responder,
        uint reward);
    event ContractionPhaseEnded();
    event CPQCleared();
    event ExpansionPhaseException(uint64 responseId);
    event ExpansionPhaseReward(uint64 responseId, uint reward, address responder);
    event ExpansionPhaseEnded();
    event AirdropPreinited(uint airdropPreinitBlock);
    event AirdropStarted(bytes32 airdropSeed);
    event AirdropEnded();

    ERC20Interface public anct;
    ERC20Interface public doct;

    bytes32 public ANCT;
    bytes32 public DOCT;
    EToken2Interface public eToken2;

    using LinkedList for LinkedList.List;
    // Contraction Phase Queue
    LinkedList.List cpq;

    uint public constant HUNDRED_PERCENT = 10000;

    struct Response {
        address responder;
        uint time;
        uint reward;
    }

    mapping(uint64 => Response) public responses;
    uint64 public responseId = 1;
    uint64 public phaseFirstResponseId = 1;
    uint public minimumResponseValue = 1000 * (10 ** 8);

    uint public airdropPreinitBlock;
    bool public airdropStarted;

    constructor(ERC20Interface _anct, ERC20Interface _doct) public {
        anct = _anct;
        doct = _doct;
        eToken2 = AssetProxyInterface(address(_anct)).etoken2();
        ANCT = AssetProxyInterface(address(_anct)).etoken2Symbol();
        DOCT = AssetProxyInterface(address(_doct)).etoken2Symbol();
    }

    function respond(uint _value) public {
        require(_value >= minimumResponseValue, &#39;Response value is less than mininmum&#39;);
        uint balance = doct.balanceOf(address(this));
        require(balance > 0, &#39;Contraction Phase did not start&#39;);
        uint responseValue = _min(_value, balance);
        uint rewardMultiplier = responseSequenceMultiplier(responseId - phaseFirstResponseId);
        uint reward = responseValue * rewardMultiplier / HUNDRED_PERCENT;
        require(anct.transferFrom(msg.sender, address(this), responseValue), &#39;ANCT transfer failed&#39;);
        require(doct.transfer(msg.sender, reward), &#39;DOCT transfer failed&#39;);
        responses[responseId] = Response(msg.sender, block.timestamp, reward);
        emit ContractionPhaseResponse(responseId, responseValue, msg.sender, reward);
        cpq.linkLast(responseId++);
        bool isEndOfPhase = balance == reward;
        if (isEndOfPhase) {
            phaseFirstResponseId = responseId;
            emit ContractionPhaseEnded();
        }
        require(eToken2.revokeAsset(ANCT, responseValue), &#39;ANCT burn failed&#39;);
    }

    function expand() public {
        uint startingBalance = anct.balanceOf(address(this));
        require(startingBalance > 0, &#39;Expansion Phase did not start&#39;);
        uint balance = startingBalance;
        uint64 nextResponseId = cpq.first;
        require(nextResponseId > 0, &#39;CPQ is empty, proceed to airdrop&#39;);
        while(true) {
            Response memory response = responses[nextResponseId];
            uint reward = _min(response.reward, balance);
            // If responder burned, or otherwise moved, some of his DOCT.
            if (doct.balanceOf(response.responder) < reward) {
                emit ExpansionPhaseException(nextResponseId);
                delete responses[nextResponseId];
                nextResponseId = cpq.getNext(nextResponseId);
                continue;
            }
            require(doct.transferFrom(response.responder, address(this), reward), &#39;DOCT transfer failed&#39;);
            require(anct.transfer(response.responder, reward), &#39;ANCT transfer failed&#39;);
            balance = balance - reward;
            emit ExpansionPhaseReward(nextResponseId, reward, response.responder);
            if (reward == response.reward) {
                delete responses[nextResponseId];
                nextResponseId = cpq.getNext(nextResponseId);
            } else {
                responses[nextResponseId].reward = response.reward - reward;
            }
            if (nextResponseId == 0) {
                emit CPQCleared();
                break;
            }
            if (balance == 0) {
                break;
            }
            if (gasleft() <= 1000000) {
                break;
            }
        }
        cpq.setHead(nextResponseId);
        if (balance == 0) {
            emit ExpansionPhaseEnded();
        }
        require(eToken2.revokeAsset(DOCT, startingBalance - balance), &#39;DOCT burn failed&#39;);
    }

    function responseSequenceMultiplier(uint _seqNumber) pure public returns(uint) {
        if (_seqNumber >= 5) {
            return HUNDRED_PERCENT;
        } else if (_seqNumber == 4) {
            return 10100;
        } else if (_seqNumber == 3) {
            return 10200;
        } else if (_seqNumber == 2) {
            return 10500;
        } else if (_seqNumber == 1) {
            return 10800;
        }
        return 11000;
    }

    function preinitAirdrop() public {
        require(airdropStarted == false, &#39;Airdrop already started&#39;);
        require(airdropPreinitBlock == 0, &#39;Airdrop already started&#39;);
        require(anct.balanceOf(address(this)) > 0, &#39;Nothing to airdrop&#39;);
        require(cpq.first == 0, &#39;CPQ is not empty, proceed to expand&#39;);
        airdropPreinitBlock = block.number;
        emit AirdropPreinited(block.number);
    }

    function initAirdrop() public {
        require(airdropStarted == false, &#39;Airdrop already started&#39;);
        uint targetBlockNumber = airdropPreinitBlock + 12;
        uint blocksSincePreinit = block.number - airdropPreinitBlock;
        require(blocksSincePreinit >= 12, &#39;12 blocks did not pass&#39;);
        if (blocksSincePreinit - 12 < 256) {
            airdropPreinitBlock = block.number;
            emit AirdropPreinited(block.number);
            return;
        }
        airdropPreinitBlock = 0;
        airdropStarted = true;
        emit AirdropStarted(blockhash(targetBlockNumber));
    }

    function airdrop(address[] memory _receivers, uint[] memory _values) public {
        require(airdropStarted, &#39;Airdrop is not started&#39;);
        require(_receivers.length == _values.length, &#39;Lists length differs&#39;);
        for (uint i = 0; i < _receivers.length; i++) {
            require(anct.transfer(_receivers[i], _values[i]), &#39;ANCT transfer failed&#39;);
        }
        if (anct.balanceOf(address(this)) > 0) {
            return;
        }
        airdropStarted = false;
        emit AirdropEnded();
    }

    function getCPQ() public view returns(Response[] memory) {
        uint size = 0;
        uint64 nextResponseId = cpq.first;
        while (nextResponseId > 0) {
            size++;
            nextResponseId = cpq.getNext(nextResponseId);
        }
        Response[] memory result = new Response[](size);
        nextResponseId = cpq.first;
        for (uint i = 0; i < size; i++) {
            result[i] = responses[nextResponseId];
            nextResponseId = cpq.getNext(nextResponseId);
        }
        return result;
    }

    function _min(uint _a, uint _b) pure internal returns(uint) {
        return _a < _b ? _a : _b;
    }
}