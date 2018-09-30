pragma solidity ^0.4.23;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

library Dictionary {
    uint constant private NULL = 0;

    struct Node {
        uint prev;
        uint next;
        uint data;
        bool initialized;
    }

    struct Data {
        mapping(uint => Node) list;
        uint firstNodeId;
        uint lastNodeId;
        uint len;
    }

    function insertAfter(Data storage self, uint afterId, uint id, uint data) internal {
        if (self.list[id].initialized) {
            self.list[id].data = data;
            return;
        }
        self.list[id].prev = afterId;
        if (self.list[afterId].next == NULL) {
            self.list[id].next =  NULL;
            self.lastNodeId = id;
        } else {
            self.list[id].next = self.list[afterId].next;
            self.list[self.list[afterId].next].prev = id;
        }
        self.list[id].data = data;
        self.list[id].initialized = true;
        self.list[afterId].next = id;
        self.len++;
    }

    function insertBefore(Data storage self, uint beforeId, uint id, uint data) internal {
        if (self.list[id].initialized) {
            self.list[id].data = data;
            return;
        }
        self.list[id].next = beforeId;
        if (self.list[beforeId].prev == NULL) {
            self.list[id].prev = NULL;
            self.firstNodeId = id;
        } else {
            self.list[id].prev = self.list[beforeId].prev;
            self.list[self.list[beforeId].prev].next = id;
        }
        self.list[id].data = data;
        self.list[id].initialized = true;
        self.list[beforeId].prev = id;
        self.len++;
    }

    function insertBeginning(Data storage self, uint id, uint data) internal {
        if (self.list[id].initialized) {
            self.list[id].data = data;
            return;
        }
        if (self.firstNodeId == NULL) {
            self.firstNodeId = id;
            self.lastNodeId = id;
            self.list[id] = Node({ prev: 0, next: 0, data: data, initialized: true });
            self.len++;
        } else
            insertBefore(self, self.firstNodeId, id, data);
    }

    function insertEnd(Data storage self, uint id, uint data) internal {
        if (self.lastNodeId == NULL) insertBeginning(self, id, data);
        else
            insertAfter(self, self.lastNodeId, id, data);
    }

    function set(Data storage self, uint id, uint data) internal {
        insertEnd(self, id, data);
    }

    function get(Data storage self, uint id) internal view returns (uint) {
        return self.list[id].data;
    }

    function remove(Data storage self, uint id) internal returns (bool) {
        uint nextId = self.list[id].next;
        uint prevId = self.list[id].prev;

        if (prevId == NULL) self.firstNodeId = nextId; //first node
        else self.list[prevId].next = nextId;

        if (nextId == NULL) self.lastNodeId = prevId; //last node
        else self.list[nextId].prev = prevId;

        delete self.list[id];
        self.len--;

        return true;
    }

    function getSize(Data storage self) internal view returns (uint) {
        return self.len;
    }

    function next(Data storage self, uint id) internal view returns (uint) {
        return self.list[id].next;
    }

    function prev(Data storage self, uint id) internal view returns (uint) {
        return self.list[id].prev;
    }

    function keys(Data storage self) internal constant returns (uint[]) {
        uint[] memory arr = new uint[](self.len);
        uint node = self.firstNodeId;
        for (uint i=0; i < self.len; i++) {
            arr[i] = node;
            node = next(self, node);
        }
        return arr;
    }
}

interface Provider {
    function isBrickOwner(uint _brickId, address _address) external view returns (bool success);
    function addBrick(uint _brickId, string _title, string _url, uint32 _expired, string _description, bytes32[] _tags, uint _value)
        external returns (bool success);
    function changeBrick(
        uint _brickId,
        string _title,
        string _url,
        string _description,
        bytes32[] _tags,
        uint _value) external returns (bool success);
    function accept(uint _brickId, address[] _builderAddresses, uint[] percentages, uint _additionalValue) external returns (uint total);
    function cancel(uint _brickId) external returns (uint value);
    function startWork(uint _brickId, bytes32 _builderId, bytes32 _nickName, address _builderAddress) external returns(bool success);
    function getBrickIds() external view returns(uint[]);
    function getBrickSize() external view returns(uint);
    function getBrick(uint _brickId) external view returns(
        string title,
        string url, 
        address owner,
        uint value,
        uint32 dateCreated,
        uint32 dateCompleted, 
        uint32 expired,
        uint status
    );

    function getBrickDetail(uint _brickId) external view returns(
        bytes32[] tags, 
        string description, 
        uint32 builders, 
        address[] winners
    );

    function getBrickBuilders(uint _brickId) external view returns (
        address[] addresses,
        uint[] dates,
        bytes32[] keys,
        bytes32[] names
    );

    function filterBrick(
        uint _brickId, 
        bytes32[] _tags, 
        uint _status, 
        uint _started,
        uint _expired
        ) external view returns (
      bool
    );


    function participated( 
        uint _brickId,
        address _builder
        ) external view returns (
        bool
    ); 
}

// solhint-disable-next-line compiler-fixed, compiler-gt-0_4








contract WeBuildWorldImplementation is Ownable, Provider {
    using SafeMath for uint256;	
    using Dictionary for Dictionary.Data;

    enum BrickStatus { Inactive, Active, Completed, Cancelled }

    struct Builder {
        address addr;
        uint dateAdded;
        bytes32 key;
        bytes32 nickName;
    }
    
    struct Brick {
        string title;
        string url;
        string description;
        bytes32[] tags;
        address owner;
        uint value;
        uint32 dateCreated;
        uint32 dateCompleted;
        uint32 expired;
        uint32 numBuilders;
        BrickStatus status;
        address[] winners;
        mapping (uint => Builder) builders;
    }

    address public main = 0x0;
    mapping (uint => Brick) public bricks;

    string public constant VERSION = "0.1";
    Dictionary.Data public brickIds;
    uint public constant DENOMINATOR = 10000;

    modifier onlyMain() {
        require(msg.sender == main);
        _;
    }

    function () public payable {
        revert();
    }    

    function isBrickOwner(uint _brickId, address _address) external view returns (bool success) {
        return bricks[_brickId].owner == _address;
    }    

    function addBrick(uint _brickId, string _title, string _url, uint32 _expired, string _description, bytes32[] _tags, uint _value) 
        external onlyMain
        returns (bool success)
    {
        // greater than 0.01 eth
        require(_value >= 10 ** 16);
        // solhint-disable-next-line
        require(bricks[_brickId].owner == 0x0 || bricks[_brickId].owner == tx.origin);

        Brick memory brick = Brick({
            title: _title,
            url: _url,
            description: _description,   
            tags: _tags,
            // solhint-disable-next-line
            owner: tx.origin,
            status: BrickStatus.Active,
            value: _value,
            // solhint-disable-next-line 
            dateCreated: uint32(now),
            dateCompleted: 0,
            expired: _expired,
            numBuilders: 0,
            winners: new address[](0)
        });

        // only add when it&#39;s new
        if (bricks[_brickId].owner == 0x0) {
            brickIds.insertBeginning(_brickId, 0);
        }
        bricks[_brickId] = brick;

        return true;
    }

    function changeBrick(uint _brickId, string _title, string _url, string _description, bytes32[] _tags, uint _value) 
        external onlyMain
        returns (bool success) 
    {
        require(bricks[_brickId].status == BrickStatus.Active);

        bricks[_brickId].title = _title;
        bricks[_brickId].url = _url;
        bricks[_brickId].description = _description;
        bricks[_brickId].tags = _tags;

        // Add to the fund.
        if (_value > 0) {
            bricks[_brickId].value = bricks[_brickId].value.add(_value);
        }

        return true;
    }

    // msg.value is tip.
    function accept(uint _brickId, address[] _winners, uint[] _weights, uint _value) 
        external onlyMain
        returns (uint) 
    {
        require(bricks[_brickId].status == BrickStatus.Active);
        require(_winners.length == _weights.length);
        // disallow to take to your own.

        uint total = 0;
        bool included = false;
        for (uint i = 0; i < _winners.length; i++) {
            // solhint-disable-next-line
            require(_winners[i] != tx.origin, "Owner should not win this himself");
            for (uint j =0; j < bricks[_brickId].numBuilders; j++) {
                if (bricks[_brickId].builders[j].addr == _winners[i]) {
                    included = true;
                    break;
                }
            }
            total = total.add(_weights[i]);
        }

        require(included, "Winner doesn&#39;t participant");
        require(total == DENOMINATOR, "total should be in total equals to denominator");

        bricks[_brickId].status = BrickStatus.Completed;
        bricks[_brickId].winners = _winners;
        // solhint-disable-next-line
        bricks[_brickId].dateCompleted = uint32(now);

        if (_value > 0) {
            bricks[_brickId].value = bricks[_brickId].value.add(_value);
        }

        return bricks[_brickId].value;
    }

    function cancel(uint _brickId) 
        external onlyMain
        returns (uint value) 
    {
        require(bricks[_brickId].status != BrickStatus.Completed);
        require(bricks[_brickId].status != BrickStatus.Cancelled);

        bricks[_brickId].status = BrickStatus.Cancelled;

        return bricks[_brickId].value;
    }

    function startWork(uint _brickId, bytes32 _builderId, bytes32 _nickName, address _builderAddress) 
        external onlyMain returns(bool success)
    {
        require(_builderAddress != 0x0);
        require(bricks[_brickId].status == BrickStatus.Active);
        require(_brickId >= 0);
        require(bricks[_brickId].expired >= now);

        bool included = false;

        for (uint i = 0; i < bricks[_brickId].numBuilders; i++) {
            if (bricks[_brickId].builders[i].addr == _builderAddress) {
                included = true;
                break;
            }
        }
        require(!included);

        // bricks[_brickId]
        Builder memory builder = Builder({
            addr: _builderAddress,
            key: _builderId,
            nickName: _nickName,
            // solhint-disable-next-line
            dateAdded: now
        });
        bricks[_brickId].builders[bricks[_brickId].numBuilders++] = builder;

        return true;
    }

    function getBrickIds() external view returns(uint[]) {
        return brickIds.keys();
    }    

    function getBrickSize() external view returns(uint) {
        return brickIds.getSize();
    }

    function _matchedTags(bytes32[] _tags, bytes32[] _stack) private pure returns (bool){
        if(_tags.length > 0){
            for (uint i = 0; i < _tags.length; i++) {
                for(uint j = 0; j < _stack.length; j++){
                    if(_tags[i] == _stack[j]){
                        return true;
                    }
                }
            }
            return false;
        }else{
            return true;
        } 
    }

    function participated(
        uint _brickId,   
        address _builder
        )
        external view returns (bool) {
 
        for (uint j = 0; j < bricks[_brickId].numBuilders; j++) {
            if (bricks[_brickId].builders[j].addr == _builder) {
                return true;
            }
        } 

        return false;
    }

    
    function filterBrick(
        uint _brickId, 
        bytes32[] _tags, 
        uint _status, 
        uint _started,
        uint _expired
        )
        external view returns (bool) {  
        Brick memory brick = bricks[_brickId];  

        bool satisfy = _matchedTags(_tags, brick.tags);  

        if(_started > 0){
            satisfy = brick.dateCreated >= _started;
        }
        
        if(_expired > 0){
            satisfy = brick.expired >= _expired;
        }
 
        return satisfy && (uint(brick.status) == _status
            || uint(BrickStatus.Cancelled) < _status 
            || uint(BrickStatus.Inactive) > _status);
    }

    function getBrick(uint _brickId) external view returns (
        string title,
        string url,
        address owner,
        uint value,
        uint32 dateCreated,
        uint32 dateCompleted,
        uint32 expired,
        uint status
    ) {
        Brick memory brick = bricks[_brickId];
        return (
            brick.title,
            brick.url,
            brick.owner,
            brick.value,
            brick.dateCreated,
            brick.dateCompleted,
            brick.expired,
            uint(brick.status)
        );
    }
    
    function getBrickDetail(uint _brickId) external view returns (
        bytes32[] tags,
        string description, 
        uint32 builders,
        address[] winners
    ) {
        Brick memory brick = bricks[_brickId];
        return ( 
            brick.tags, 
            brick.description, 
            brick.numBuilders,
            brick.winners
        );
    }

    function getBrickBuilders(uint _brickId) external view returns (
        address[] addresses,
        uint[] dates,
        bytes32[] keys,
        bytes32[] names
    )
    {
        // Brick memory brick = bricks[_brickId];
        addresses = new address[](bricks[_brickId].numBuilders);
        dates = new uint[](bricks[_brickId].numBuilders);
        keys = new bytes32[](bricks[_brickId].numBuilders);
        names = new bytes32[](bricks[_brickId].numBuilders);

        for (uint i = 0; i < bricks[_brickId].numBuilders; i++) {
            addresses[i] = bricks[_brickId].builders[i].addr;
            dates[i] = bricks[_brickId].builders[i].dateAdded;
            keys[i] = bricks[_brickId].builders[i].key;
            names[i] = bricks[_brickId].builders[i].nickName;
        }
    }    

    function setMain(address _address) public onlyOwner returns(bool) {
        main = _address;
        return true;
    }     
}