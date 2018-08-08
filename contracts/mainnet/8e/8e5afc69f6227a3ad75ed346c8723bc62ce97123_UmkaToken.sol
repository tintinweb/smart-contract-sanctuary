pragma solidity ^0.4.23;

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract ERC20 {
    function totalSupply() external constant returns (uint256 _totalSupply);
    function balanceOf(address _owner) external constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _old, uint256 _new) external returns (bool success);
    function allowance(address _owner, address _spender) external constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    constructor () internal {
    }
}

library RingList {

    address constant NULL = 0x0;
    address constant HEAD = 0x0;
    bool constant PREV = false;
    bool constant NEXT = true;

    struct LinkedList{
        mapping (address => mapping (bool => address)) list;
    }

    /// @dev returns true if the list exists
    /// @param self stored linked list from contract
    function listExists(LinkedList storage self)
    internal
    view returns (bool)
    {
        // if the head nodes previous or next pointers both point to itself, then there are no items in the list
        if (self.list[HEAD][PREV] != HEAD || self.list[HEAD][NEXT] != HEAD) {
            return true;
        } else {
            return false;
        }
    }

    /// @dev returns true if the node exists
    /// @param self stored linked list from contract
    /// @param _node a node to search for
    function nodeExists(LinkedList storage self, address _node)
    internal
    view returns (bool)
    {
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

    /// @dev Returns the number of elements in the list
    /// @param self stored linked list from contract
    function sizeOf(LinkedList storage self) internal view returns (uint256 numElements) {
        bool exists;
        address i;
        (exists,i) = getAdjacent(self, HEAD, NEXT);
        while (i != HEAD) {
            (exists,i) = getAdjacent(self, i, NEXT);
            numElements++;
        }
        return;
    }

    /// @dev Returns the links of a node as a tuple
    /// @param self stored linked list from contract
    /// @param _node id of the node to get
    function getNode(LinkedList storage self, address _node)
    internal view returns (bool, address, address)
    {
        if (!nodeExists(self,_node)) {
            return (false,0x0,0x0);
        } else {
            return (true,self.list[_node][PREV], self.list[_node][NEXT]);
        }
    }

    /// @dev Returns the link of a node `_node` in direction `_direction`.
    /// @param self stored linked list from contract
    /// @param _node id of the node to step from
    /// @param _direction direction to step in
    function getAdjacent(LinkedList storage self, address _node, bool _direction)
    internal view returns (bool, address)
    {
        if (!nodeExists(self,_node)) {
            return (false,0x0);
        } else {
            return (true,self.list[_node][_direction]);
        }
    }

    /// @dev Can be used before `insert` to build an ordered list
    /// @param self stored linked list from contract
    /// @param _node an existing node to search from, e.g. HEAD.
    /// @param _value value to seek
    /// @param _direction direction to seek in
    //  @return next first node beyond &#39;_node&#39; in direction `_direction`
    function getSortedSpot(LinkedList storage self, address _node, address _value, bool _direction)
    internal view returns (address)
    {
        if (sizeOf(self) == 0) { return 0x0; }
        require((_node == 0x0) || nodeExists(self,_node));
        bool exists;
        address next;
        (exists,next) = getAdjacent(self, _node, _direction);
        while  ((next != 0x0) && (_value != next) && ((_value < next) != _direction)) next = self.list[next][_direction];
        return next;
    }

    /// @dev Creates a bidirectional link between two nodes on direction `_direction`
    /// @param self stored linked list from contract
    /// @param _node first node for linking
    /// @param _link  node to link to in the _direction
    function createLink(LinkedList storage self, address _node, address _link, bool _direction) internal  {
        self.list[_link][!_direction] = _node;
        self.list[_node][_direction] = _link;
    }

    /// @dev Insert node `_new` beside existing node `_node` in direction `_direction`.
    /// @param self stored linked list from contract
    /// @param _node existing node
    /// @param _new  new node to insert
    /// @param _direction direction to insert node in
    function insert(LinkedList storage self, address _node, address _new, bool _direction) internal returns (bool) {
        if(!nodeExists(self,_new) && nodeExists(self,_node)) {
            address c = self.list[_node][_direction];
            createLink(self, _node, _new, _direction);
            createLink(self, _new, c, _direction);
            return true;
        } else {
            return false;
        }
    }

    /// @dev removes an entry from the linked list
    /// @param self stored linked list from contract
    /// @param _node node to remove from the list
    function remove(LinkedList storage self, address _node) internal returns (address) {
        if ((_node == NULL) || (!nodeExists(self,_node))) { return 0x0; }
        createLink(self, self.list[_node][PREV], self.list[_node][NEXT], NEXT);
        delete self.list[_node][PREV];
        delete self.list[_node][NEXT];
        return _node;
    }

    /// @dev pushes an enrty to the head of the linked list
    /// @param self stored linked list from contract
    /// @param _node new entry to push to the head
    /// @param _direction push to the head (NEXT) or tail (PREV)
    function push(LinkedList storage self, address _node, bool _direction) internal  {
        insert(self, HEAD, _node, _direction);
    }

    /// @dev pops the first entry from the linked list
    /// @param self stored linked list from contract
    /// @param _direction pop from the head (NEXT) or the tail (PREV)
    function pop(LinkedList storage self, bool _direction) internal returns (address) {
        bool exists;
        address adj;

        (exists,adj) = getAdjacent(self, HEAD, _direction);

        return remove(self, adj);
    }
}

contract UmkaToken is ERC20 {
    using SafeMath for uint256;
    using RingList for RingList.LinkedList;

    address public owner;

    bool    public              paused         = false;
    bool    public              contractEnable = true;

    uint256 private             summarySupply;

    string  public              name = "";
    string  public              symbol = "";
    uint8   public              decimals = 0;

    mapping(address => uint256)                      private   accounts;
    mapping(address => string)                       private   umkaAddresses;
    mapping(address => mapping (address => uint256)) private   allowed;
    mapping(address => uint8)                        private   group;
    mapping(bytes32 => uint256)                      private   distribution;

    RingList.LinkedList                              private   holders;

    struct groupPolicy {
        uint8 _default;
        uint8 _backend;
        uint8 _admin;
        uint8 _migration;
        uint8 _subowner;
        uint8 _owner;
    }

    groupPolicy public currentState = groupPolicy(0, 3, 4, 9, 2, 9);

    event EvGroupChanged(address _address, uint8 _oldgroup, uint8 _newgroup);
    event EvMigration(address _address, uint256 _balance, uint256 _secret);
    event Pause();
    event Unpause();

    constructor (string _name, string _symbol, uint8 _decimals, uint256 _startTokens) public {
        owner = msg.sender;

        group[owner] = currentState._owner;

        accounts[msg.sender]  = _startTokens;

        holders.push(msg.sender, true);
        summarySupply    = _startTokens;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        emit Transfer(address(0x0), msg.sender, _startTokens);
    }

    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }

    modifier minGroup(int _require) {
        require(group[msg.sender] >= _require);
        _;
    }

    modifier onlyGroup(int _require) {
        require(group[msg.sender] == _require);
        _;
    }

    modifier whenNotPaused() {
        require(!paused || group[msg.sender] >= currentState._backend);
        _;
    }

    modifier whenPaused() {
        require(paused);
        _;
    }

    function servicePause() minGroup(currentState._admin) whenNotPaused public {
        paused = true;
        emit Pause();
    }

    function serviceUnpause() minGroup(currentState._admin) whenPaused public {
        paused = false;
        emit Unpause();
    }

    function serviceGroupChange(address _address, uint8 _group) minGroup(currentState._admin) external returns(uint8) {
        require(_address != address(0));

        uint8 old = group[_address];
        if(old <= currentState._admin) {
            group[_address] = _group;
            emit EvGroupChanged(_address, old, _group);
        }
        return group[_address];
    }

    function serviceTransferOwnership(address newOwner) minGroup(currentState._owner) external {
        require(newOwner != address(0));

        group[newOwner] = currentState._subowner;
        group[msg.sender] = currentState._subowner;
        emit EvGroupChanged(newOwner, currentState._owner, currentState._subowner);
    }

    function serviceClaimOwnership() onlyGroup(currentState._subowner) external {
        address temp = owner;
        uint256 value = accounts[owner];

        accounts[owner] = accounts[owner].sub(value);
        holders.remove(owner);
        accounts[msg.sender] = accounts[msg.sender].add(value);
        holders.push(msg.sender, true);

        owner = msg.sender;

        delete group[temp];
        group[msg.sender] = currentState._owner;

        emit EvGroupChanged(msg.sender, currentState._subowner, currentState._owner);
        emit Transfer(temp, owner, value);
    }

    function serviceIncreaseBalance(address _who, uint256 _value) minGroup(currentState._admin) external returns(bool) {
        require(_who != address(0));
        require(_value > 0);

        accounts[_who] = accounts[_who].add(_value);
        summarySupply = summarySupply.add(_value);
        holders.push(_who, true);
        emit Transfer(address(0), _who, _value);
        return true;
    }

    function serviceDecreaseBalance(address _who, uint256 _value) minGroup(currentState._admin) external returns(bool) {
        require(_who != address(0));
        require(_value > 0);
        require(accounts[_who] >= _value);

        accounts[_who] = accounts[_who].sub(_value);
        summarySupply = summarySupply.sub(_value);
        if(accounts[_who] == 0){
            holders.remove(_who);
        }
        emit Transfer(_who, address(0), _value);
        return true;
    }

    function serviceRedirect(address _from, address _to, uint256 _value) minGroup(currentState._admin) external returns(bool){
        require(_from != address(0));
        require(_to != address(0));
        require(_value > 0);
        require(accounts[_from] >= _value);
        require(_from != _to);

        accounts[_from] = accounts[_from].sub(_value);
        if(accounts[_from] == 0){
            holders.remove(_from);
        }
        accounts[_to] = accounts[_to].add(_value);
        holders.push(_to, true);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function serviceTokensBurn(address _address) external minGroup(currentState._admin) returns(uint256 balance) {
        require(_address != address(0));
        require(accounts[_address] > 0);

        uint256 sum = accounts[_address];
        accounts[_address] = 0;
        summarySupply = summarySupply.sub(sum);
        holders.remove(_address);
        emit Transfer(_address, address(0), sum);
        return accounts[_address];
    }

    function serviceTrasferToDist(bytes32 _to, uint256 _value) external minGroup(currentState._admin) {
        require(_value > 0);
        require(accounts[owner] >= _value);

        distribution[_to] = distribution[_to].add(_value);
        accounts[owner] = accounts[owner].sub(_value);
        emit Transfer(owner, address(0), _value);
    }

    function serviceTrasferFromDist(bytes32 _from, address _to, uint256 _value) external minGroup(currentState._backend) {
        require(_to != address(0));
        require(_value > 0);
        require(distribution[_from] >= _value);

        accounts[_to] = accounts[_to].add(_value);
        holders.push(_to, true);
        distribution[_from] = distribution[_from].sub(_value);
        emit Transfer(address(0), _to, _value);
    }

    function getGroup(address _check) external constant returns(uint8 _group) {
        return group[_check];
    }

    function getBalanceOfDist(bytes32 _of) external constant returns(uint256){
        return distribution[_of];
    }

    function getHoldersLength() external constant returns(uint256){
        return holders.sizeOf();
    }

    function getHolderLink(address _holder) external constant returns(bool, address, address){
        return holders.getNode(_holder);
    }

    function getUmkaAddress(address _who) external constant returns(string umkaAddress){
        return umkaAddresses[_who];
    }

    function setUmkaAddress(string _umka) minGroup(currentState._default) whenNotPaused external{
        umkaAddresses[msg.sender] = _umka;
    }

    function transfer(address _to, uint256 _value) onlyPayloadSize(64) minGroup(currentState._default) whenNotPaused external returns (bool success) {
        require(_to != address(0));
        require (accounts[msg.sender] >= _value);

        accounts[msg.sender] = accounts[msg.sender].sub(_value);
        if(accounts[msg.sender] == 0){
            holders.remove(msg.sender);
        }
        accounts[_to] = accounts[_to].add(_value);
        holders.push(_to, true);
        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(64) minGroup(currentState._default) whenNotPaused external returns (bool success) {
        require(_to != address(0));
        require(_from != address(0));
        require(_value <= accounts[_from]);
        require(_value <= allowed[_from][msg.sender]);

        accounts[_from] = accounts[_from].sub(_value);
        if(accounts[_from] == 0){
            holders.remove(_from);
        }
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        accounts[_to] = accounts[_to].add(_value);
        holders.push(_to, true);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _old, uint256 _new) onlyPayloadSize(64) minGroup(currentState._default) whenNotPaused external returns (bool success) {
        require (_old == allowed[msg.sender][_spender]);
        require(_spender != address(0));

        allowed[msg.sender][_spender] = _new;
        emit Approval(msg.sender, _spender, _new);
        return true;
    }

    function allowance(address _owner, address _spender) external constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function balanceOf(address _owner) external constant returns (uint256 balance) {
        if (_owner == address(0))
            return accounts[msg.sender];
        return accounts[_owner];
    }

    function totalSupply() external constant returns (uint256 _totalSupply) {
        _totalSupply = summarySupply;
    }

    function destroy() minGroup(currentState._owner) external {
        selfdestruct(msg.sender);
    }

    function settingsSwitchState() external minGroup(currentState._owner) returns (bool state) {

        if(contractEnable) {
            currentState._default = 9;
            currentState._migration = 0;
            contractEnable = false;
        } else {
            currentState._default = 0;
            currentState._migration = 9;
            contractEnable = true;
        }

        return contractEnable;
    }

    function userMigration(uint256 _secrect) external minGroup(currentState._migration) returns (bool successful) {
        uint256 balance = accounts[msg.sender];

        require (balance > 0);

        accounts[msg.sender] = accounts[msg.sender].sub(balance);
        holders.remove(msg.sender);
        accounts[owner] = accounts[owner].add(balance);
        holders.push(owner, true);
        emit EvMigration(msg.sender, balance, _secrect);
        emit Transfer(msg.sender, owner, balance);
        return true;
    }
}