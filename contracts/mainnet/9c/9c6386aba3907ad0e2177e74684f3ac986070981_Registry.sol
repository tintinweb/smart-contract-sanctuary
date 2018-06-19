pragma solidity ^0.4.23;

/*****************************************************
************* PENNYETHER REGISTRY ********************
******************************************************

Registry allows a permanent owner to map names to addresses.
Anyone can find a mapped address by calling .addressOf(),
which throws if the name is not registered to an address.

Registry uses a doubly linked list to maintain an iterable
list of name => address mappings. When a name is mapped to
the address 0, it is removed from the list.

Methods:
    - [onlyOwner] register(name, address)
    - [onlyOnwer] unregiser(name)
Public Views:
    - size()
    - addressOf(name)
    - nameOf(address)
    - mappings()

*/
contract Registry {
    // Doubly Linked List of NameEntries
    struct Entry {
        address addr;
        bytes32 next;
        bytes32 prev;
    }
    mapping (bytes32 => Entry) public entries;

    // Used to determine if an entry is empty or not.
    address constant NO_ADDRESS = address(0);

    address public owner;
    modifier fromOwner() { require(msg.sender==owner); _; }

    event Created(uint time);
    event Registered(uint time, bytes32 name, address addr);
    event Unregistered(uint time, bytes32 name);

    // Constructor sets the owner
    constructor(address _owner)
        public
    {
        owner = _owner;
        emit Created(now);
    }


    /******************************************************/
    /*************** OWNER METHODS ************************/
    /******************************************************/

    function register(bytes32 _name, address _addr)
        fromOwner
        public
    {
        require(_name != 0 && _addr != 0);
        Entry storage entry = entries[_name];

        // If new entry, replace first one with this one.
        if (entry.addr == NO_ADDRESS) {
            entry.next = entries[0x0].next;
            entries[entries[0x0].next].prev = _name;
            entries[0x0].next = _name;
        }
        // Update the address
        entry.addr = _addr;
        emit Registered(now, _name, _addr);
    }

    function unregister(bytes32 _name)
        fromOwner
        public
    {
        require(_name != 0);
        Entry storage entry = entries[_name];
        if (entry.addr == NO_ADDRESS) return;

        // Remove entry by stitching together prev and next
        entries[entry.prev].next = entry.next;
        entries[entry.next].prev = entry.prev;
        delete entries[_name];
        emit Unregistered(now, _name);
    }


    /******************************************************/
    /*************** PUBLIC VIEWS *************************/
    /******************************************************/

    function size()
        public
        view
        returns (uint _size)
    {
        Entry memory _curEntry = entries[0x0];
        while (_curEntry.next > 0) {
            _curEntry = entries[_curEntry.next];
            _size++;
        }
        return _size;
    }

    // Retrieves the address for the name of _name.
    function addressOf(bytes32 _name)
        public
        view
        returns (address _addr)
    {
        _addr = entries[_name].addr;
        require(_addr != address(0));
        return _addr;
    }

    // Retrieves a associated with an _address.
    function nameOf(address _address)
        public
        view
        returns (bytes32 _name)
    {
        Entry memory _curEntry = entries[0x0];
        Entry memory _nextEntry;
        while (_curEntry.next > 0) {
            _nextEntry = entries[_curEntry.next];
            if (_nextEntry.addr == _address){
                return _curEntry.next;
            }
            _curEntry = _nextEntry;
        }
    }

    // Retrieves the name of _addr, if any
    function mappings()
        public
        view
        returns (bytes32[] _names, address[] _addresses)
    {
        uint _size = size();

        // Populate names and addresses
        _names = new bytes32[](_size);
        _addresses = new address[](_size);
        uint _i = 0;
        Entry memory _curEntry = entries[0x0];
        Entry memory _nextEntry;
        while (_curEntry.next > 0) {
            _nextEntry = entries[_curEntry.next];
            _names[_i] = _curEntry.next;
            _addresses[_i] = _nextEntry.addr;
            _curEntry = _nextEntry;
            _i++;
        }
        return (_names, _addresses);
    }
}