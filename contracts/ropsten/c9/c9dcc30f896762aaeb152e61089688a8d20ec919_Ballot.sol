pragma solidity ^0.4.24;

/**
 * This utility library was forked from https://github.com/o0ragman0o/LibCLL
 */
library LinkedListLib {

    uint256 constant NULL = 0;
    uint256 constant HEAD = 0;
    bool constant PREV = false;
    bool constant NEXT = true;

    struct LinkedList {
        mapping (uint256 => mapping (bool => uint256)) list;
        uint256 length;
        uint256 index;
    }

    /**
     * @dev returns true if the list exists
     * @param self stored linked list from contract
     */
    function listExists(LinkedList storage self)
        internal
        view returns (bool) {
        return self.length > 0;
    }

    /**
     * @dev returns true if the node exists
     * @param self stored linked list from contract
     * @param _node a node to search for
     */
    function nodeExists(LinkedList storage self, uint256 _node)
        internal
        view returns (bool) {
        if (self.list[_node][PREV] == HEAD && self.list[_node][NEXT] == HEAD) {
            if (self.list[HEAD][NEXT] == _node) {
                return true;
            } else {
                return false;
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Returns the number of elements in the list
     * @param self stored linked list from contract
     */ 
    function sizeOf(LinkedList storage self) 
        internal 
        view 
        returns (uint256 numElements) {
        return self.length;
    }

    /**
     * @dev Returns the links of a node as a tuple
     * @param self stored linked list from contract
     * @param _node id of the node to get
     */
    function getNode(LinkedList storage self, uint256 _node)
        public 
        view 
        returns (bool, uint256, uint256) {
        if (!nodeExists(self,_node)) {
            return (false, 0, 0);
        } else {
            return (true, self.list[_node][PREV], self.list[_node][NEXT]);
        }
    }

    /**
     * @dev Returns the link of a node `_node` in direction `_direction`.
     * @param self stored linked list from contract
     * @param _node id of the node to step from
     * @param _direction direction to step in
     */
    function getAdjacent(LinkedList storage self, uint256 _node, bool _direction)
        public 
        view 
        returns (bool, uint256) {
        if (!nodeExists(self,_node)) {
            return (false,0);
        } else {
            return (true,self.list[_node][_direction]);
        }
    }

    /**
     * @dev Can be used before `insert` to build an ordered list
     * @param self stored linked list from contract
     * @param _node an existing node to search from, e.g. HEAD.
     * @param _value value to seek
     * @param _direction direction to seek in
     * @return next first node beyond &#39;_node&#39; in direction `_direction`
     */
    function getSortedSpot(LinkedList storage self, uint256 _node, uint256 _value, bool _direction)
        public 
        view 
        returns (uint256) {
        if (sizeOf(self) == 0) { 
            return 0; 
        }
        require((_node == 0) || nodeExists(self,_node));
        bool exists;
        uint256 next;
        (exists,next) = getAdjacent(self, _node, _direction);
        while  ((next != 0) && (_value != next) && ((_value < next) != _direction)) next = self.list[next][_direction];
        return next;
    }

    /**
     * @dev Creates a bidirectional link between two nodes on direction `_direction`
     * @param self stored linked list from contract
     * @param _node first node for linking
     * @param _link  node to link to in the _direction
     */
    function createLink(LinkedList storage self, uint256 _node, uint256 _link, bool _direction) 
        private {
        self.list[_link][!_direction] = _node;
        self.list[_node][_direction] = _link;
    }

    /**
     * @dev Insert node `_new` beside existing node `_node` in direction `_direction`.
     * @param self stored linked list from contract
     * @param _node existing node
     * @param _new  new node to insert
     * @param _direction direction to insert node in
     */
    function insert(LinkedList storage self, uint256 _node, uint256 _new, bool _direction) 
        internal 
        returns (bool) {
        if(!nodeExists(self,_new) && nodeExists(self,_node)) {
            uint256 c = self.list[_node][_direction];
            createLink(self, _node, _new, _direction);
            createLink(self, _new, c, _direction);
            self.length++;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev removes an entry from the linked list
     * @param self stored linked list from contract
     * @param _node node to remove from the list
     */
    function remove(LinkedList storage self, uint256 _node) 
        internal 
        returns (uint256) {
        if ((_node == NULL) || (!nodeExists(self,_node))) { 
            return 0; 
        }
        createLink(self, self.list[_node][PREV], self.list[_node][NEXT], NEXT);
        delete self.list[_node][PREV];
        delete self.list[_node][NEXT];
        self.length--;
        return _node;
    }

    /**
     * @dev pushes an enrty to the head of the linked list
     * @param self stored linked list from contract
     * @param _index The node Id
     * @param _direction push to the head (NEXT) or tail (PREV)
     */
    function add(LinkedList storage self, uint256 _index, bool _direction) 
        internal 
        returns (uint256) {
        insert(self, HEAD, _index, _direction);
        return self.index;
    }

    /**
     * @dev pushes an enrty to the head of the linked list
     * @param self stored linked list from contract
     * @param _direction push to the head (NEXT) or tail (PREV)
     */
    function push(LinkedList storage self, bool _direction) 
        internal 
        returns (uint256) {
        self.index++;
        insert(self, HEAD, self.index, _direction);
        return self.index;
    }

    /**
     * @dev pops the first entry from the linked list
     * @param self stored linked list from contract
     * @param _direction pop from the head (NEXT) or the tail (PREV)
     */
    function pop(LinkedList storage self, bool _direction) 
        internal 
        returns (uint256) {
        bool exists;
        uint256 adj;
        (exists,adj) = getAdjacent(self, HEAD, _direction);
        return remove(self, adj);
    }

    /**
     * @dev Returns the node list and next node as a tuple
     * @param self stored linked list from contract
     * @param _node the begin id of the node to get
     * @param _limit the total nodes of one page
     * @param _direction direction to step in
     */
    function getNodes(LinkedListLib.LinkedList storage self, uint256 _node, uint256 _limit, bool _direction) 
        internal 
        view 
        returns (uint256[], uint256) {
        bool exists;
        uint256 i;
        uint256 index = 0;
        uint256 count = _limit;
        if(count > self.length) {
            count = self.length;
        }
        uint256[] memory result;
        (exists, i) = getAdjacent(self, _node, _direction);
        if(!exists) {
            result = new uint256[](0);
            return (new uint256[](0), 0);
        }else {
            result = new uint256[](count);
            while (i != 0 && index < count) {
                result[index] = i;
                (exists,i) = getAdjacent(self, i, _direction);
                index++;
            }
            return (result, i);
        }
    }
}
/**
Owned contract
 */
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed from, address indexed to);

    constructor() public {
        owner = msg.sender;
    }

    /**
     * Only the owner of contract
     */ 
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    /**
     * transfer the ownership to other
     * - Only the owner can operate
     */ 
    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    /** 
     * Accept the ownership from last owner
     */ 
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}
/**
Safe maths
 */
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        // b >= 0
        require(c >= a); 
    }

    function sub(uint a, uint b) internal pure returns (uint c) {
        // c >= 0
        require(b <= a);
        c = a - b;
    }

    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        // Avoid overflow 
        require(a == 0 || c / a == b);
    }

    function div(uint a, uint b) internal pure returns (uint c) {
        // Avoid zero denominator
        require(b > 0);     
        c = a / b;  
    }
}
contract Ballot is Owned {
    using LinkedListLib for LinkedListLib.LinkedList;
    using SafeMath for uint256;
    
    constructor () public {
        
    }
    
    uint256 public totalSupply;
    string public name = &quot;Ecotech Ballot Token&quot;;
    string public symbol = &quot;STAR&quot;;
    uint8 public decimals = 0;

    // 候选人
    struct Voter {
        uint256 vote;
        uint256 balance;
        address ads;
        bytes32 name;
    }

    mapping (uint256 => Voter) voters;
    mapping (address => uint256) voterIds;
    LinkedListLib.LinkedList voterList = LinkedListLib.LinkedList(0, 0);

    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev 添加投票人
     * @param _voterIds 投票人地址
     * @param _voterNames 投票人姓名(转为bytes32)
     */
    function addVoters(address[] _voterIds, bytes32[] _voterNames) external onlyOwner {
        uint256 id = 0;
        require(_voterIds.length == _voterNames.length && _voterNames.length > 0);
        for (uint256 i = 0;i < _voterIds.length; i++) {
            id = voterList.push(false);
            voters[id] = Voter(0, 0, _voterIds[i], _voterNames[i]);
            voterIds[_voterIds[i]] = id;
        }
    }

    /**
     * @dev 删除投票人
     * @param _voterIds 投票人IDs
     */
    function removeVoters(uint256[] _voterIds) external onlyOwner {
        require(_voterIds.length > 0);
        uint256 vid = 0;
        for (uint256 i = 0;i < _voterIds.length; i++) {
            vid = _voterIds[i];
            require(voterList.nodeExists(vid));
            delete voterIds[voters[vid].ads];
            delete voters[vid];
            voterList.remove(vid);
        }
    }

    /**
     * @dev 清空所有人手里的票
     */
    function burnVotes() external onlyOwner {
        uint256[] memory _vids;
        uint256 _next;
        (_vids, _next) = voterList.getNodes(0, voterList.sizeOf(), true);
        for (uint256 i = 0;i < _vids.length; i++) {
            voters[_vids[i]].vote = 0;
        }
    }

    /**
     * @dev 清空投票结果
     */
    function burnBalances() external onlyOwner {
        uint256[] memory _vids;
        uint256 _next;
        (_vids, _next) = voterList.getNodes(0, voterList.sizeOf(), true);
        for (uint256 i = 0;i < _vids.length; i++) {
            voters[_vids[i]].balance = 0;
        }
        totalSupply = 0;
    }

    /**
     * @dev 给所有人发放相同的票数
     * @param _vote 票数
     */
    function addVotes(uint256 _vote) external onlyOwner {
        uint256[] memory _vids;
        uint256 _next;
        (_vids, _next) = voterList.getNodes(0, voterList.sizeOf(), true);
        for (uint256 i = 0;i < _vids.length; i++) {
            voters[_vids[i]].vote = voters[_vids[i]].vote.add(_vote);
        }
    }

    /**
     * @dev 给某人发放票数
     * @param _vote 票数
     * @param _to 目标人地址
     */
    function addVote(uint256 _vote, address _to) external onlyOwner{
        uint256 vid = voterIds[_to];
        require(voterList.nodeExists(vid));
        voters[vid].vote = voters[vid].vote.add(_vote);
    }

    /**
     * @dev 查询所有的候选人IDs
     * @param _from 开始ID，如果从头开始_from=0
     * @param _limit 每页显示数量
     * @return 返回所有的IDs和下一个ID，如果下一个ID=0说明已经没有下一页
     */
    function getVoters(uint256 _from, uint256 _limit) external view returns(uint256[], uint256) {
        return voterList.getNodes(_from, _limit, true);
    }

    /**
     * @dev 获取候选人详情
     * @param _vid 候选人ID
     * @return 返回持有票数、被投票数、地址、姓名
     */
    function getVoter(uint256 _vid) external view returns(uint256,uint256, address, bytes32) {
        return (voters[_vid].vote,voters[_vid].balance, voters[_vid].ads, voters[_vid].name);
    }

    /**
     * @dev 查询自己的信息
     * @return 返回持有票数、被投票数、地址、姓名
     */
    function getOneself() external view returns(uint256,uint256, address, bytes32) {
        uint256 vid = voterIds[msg.sender];
        return (voters[vid].vote,voters[vid].balance, voters[vid].ads, voters[vid].name);
    }
    
    /**
     * @dev 查询某人的被投票情况
     * @param _tokenOwner 地址
     * @return 返回被查询者的被投票情况
     */
    function balanceOf(address _tokenOwner) public view returns (uint balance) {
        uint256 vid = voterIds[_tokenOwner];
        return voters[vid].balance;
    }
    
    /**
     * @dev 投票，不能投给自己；投票人和候选人都要在列表中
     * @param _to 被选人
     * @param _tokens 票数
     */
    function transfer(address _to, uint _tokens) public returns (bool success) {
        // 不能投给自己
        require(_to != msg.sender);
        
        // 投票人在候选人列表
        uint256 vid = voterIds[msg.sender];
        require(voterList.nodeExists(vid));
        voters[vid].vote = voters[vid].vote.sub(_tokens);

        // 被投票人也在候选人列表
        uint256 toVid = voterIds[_to];
        require(voterList.nodeExists(toVid));
        voters[toVid].balance = voters[toVid].balance.add(_tokens);
        
        // 记录所有投出的票数
        totalSupply = totalSupply.add(_tokens);
        emit Transfer(msg.sender, _to, _tokens);
        return true;
    }
}