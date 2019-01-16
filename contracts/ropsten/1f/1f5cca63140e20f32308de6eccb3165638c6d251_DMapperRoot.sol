pragma solidity ^0.4.0;

contract DMapperRoot {
    using SafeMath for uint256;

    /*
        EVENTS
    */

    event BlockSubmitted(
        uint256 blockNumber
    );

    /*
        STORAGE
    */
    uint256 public constant CHILD_BLOCK_INTERVAL = 1;

    address public operator;

    uint256 public currentMapBlock;

    mapping(uint256 => MapBlock) public mapBlocks;

    struct MapBlock {
        bytes32 root;
        uint256 timestamp;
    }


    /*
        MODIFIER
    */
    modifier onlyOperator() {
        require(msg.sender == operator);
        _;
    }


    /*
        CONSTRUCTOR
    */
    constructor()
    public
    {
        operator = msg.sender;
        currentMapBlock = 0;
    }

    /*
        PUBLIC FUNCTIONS
    */

    function submitBlock(bytes32 _root)
    public
    onlyOperator //Proof of Authority
    {
        uint256 submittedBlockNumber = currentMapBlock;
        mapBlocks[currentMapBlock] = MapBlock({
            root : _root,
            timestamp : block.timestamp
            });

        // Update block numbers.
        currentMapBlock = currentMapBlock.add(CHILD_BLOCK_INTERVAL);

        emit BlockSubmitted(submittedBlockNumber);
    }

    /*
        PUBLIC VIEW FUNCTIONS
    */
    function getMapBlock(uint256 _blockNumber)
    public
    view
    returns (bytes32, uint256)
    {
        return (mapBlocks[_blockNumber].root, mapBlocks[_blockNumber].timestamp);
    }
}

library SafeMath {
    function mul(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256) 
    {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b)
        internal
        pure
        returns (uint256) 
    {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

library Math {

    function max(uint256 a, uint256 b)
        internal
        pure
        returns (uint256) 
    {
        return a >= b ? a : b;
    }
}