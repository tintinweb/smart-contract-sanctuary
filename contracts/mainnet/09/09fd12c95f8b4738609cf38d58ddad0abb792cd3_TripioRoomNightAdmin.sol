pragma solidity ^0.4.24;

/**
 * Owned contract
 */
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed from, address indexed to);

    /**
     * Constructor
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Only the owner of contract
     */ 
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    /**
     * @dev transfer the ownership to other
     *      - Only the owner can operate
     */ 
    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    /** 
     * @dev Accept the ownership from last owner
     */ 
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}
contract TRNData is Owned {
    TripioRoomNightData dataSource;
    /**
     * Only the valid vendor and the vendor is valid
     */ 
    modifier onlyVendor {
        uint256 vendorId = dataSource.vendorIds(msg.sender);
        require(vendorId > 0);
        (,,,bool valid) = dataSource.getVendor(vendorId);
        require(valid);
        _;
    }

    /**
     * The vendor is valid
     */
    modifier vendorValid(address _vendor) {
        uint256 vendorId = dataSource.vendorIds(_vendor);
        require(vendorId > 0);
        (,,,bool valid) = dataSource.getVendor(vendorId);
        require(valid);
        _;
    }

    /**
     * The vendorId is valid
     */
    modifier vendorIdValid(uint256 _vendorId) {
        (,,,bool valid) = dataSource.getVendor(_vendorId);
        require(valid);
        _;
    }

    /**
     * Rate plan exist.
     */
    modifier ratePlanExist(uint256 _vendorId, uint256 _rpid) {
        (,,,bool valid) = dataSource.getVendor(_vendorId);
        require(valid);
        require(dataSource.ratePlanIsExist(_vendorId, _rpid));
        _;
    }
    
    /**
     * Token is valid
     */
    modifier validToken(uint256 _tokenId) {
        require(_tokenId > 0);
        require(dataSource.roomNightIndexToOwner(_tokenId) != address(0));
        _;
    }

    /**
     * Tokens are valid
     */
    modifier validTokenInBatch(uint256[] _tokenIds) {
        for(uint256 i = 0; i < _tokenIds.length; i++) {
            require(_tokenIds[i] > 0);
            require(dataSource.roomNightIndexToOwner(_tokenIds[i]) != address(0));
        }
        _;
    }

    /**
     * Whether the `_tokenId` can be transfered
     */
    modifier canTransfer(uint256 _tokenId) {
        address owner = dataSource.roomNightIndexToOwner(_tokenId);
        bool isOwner = (msg.sender == owner);
        bool isApproval = (msg.sender == dataSource.roomNightApprovals(_tokenId));
        bool isOperator = (dataSource.operatorApprovals(owner, msg.sender));
        require(isOwner || isApproval || isOperator);
        _;
    }

    /**
     * Whether the `_tokenIds` can be transfered
     */
    modifier canTransferInBatch(uint256[] _tokenIds) {
        for(uint256 i = 0; i < _tokenIds.length; i++) {
            address owner = dataSource.roomNightIndexToOwner(_tokenIds[i]);
            bool isOwner = (msg.sender == owner);
            bool isApproval = (msg.sender == dataSource.roomNightApprovals(_tokenIds[i]));
            bool isOperator = (dataSource.operatorApprovals(owner, msg.sender));
            require(isOwner || isApproval || isOperator);
        }
        _;
    }


    /**
     * Whether the `_tokenId` can be operated by `msg.sender`
     */
    modifier canOperate(uint256 _tokenId) {
        address owner = dataSource.roomNightIndexToOwner(_tokenId);
        bool isOwner = (msg.sender == owner);
        bool isOperator = (dataSource.operatorApprovals(owner, msg.sender));
        require(isOwner || isOperator);
        _;
    }

    /**
     * Whether the `_date` is valid(no hours, no seconds)
     */
    modifier validDate(uint256 _date) {
        require(_date > 0);
        require(dateIsLegal(_date));
        _;
    }

    /**
     * Whether the `_dates` are valid(no hours, no seconds)
     */
    modifier validDates(uint256[] _dates) {
        for(uint256 i = 0;i < _dates.length; i++) {
            require(_dates[i] > 0);
            require(dateIsLegal(_dates[i]));
        }
        _;
    }

    function dateIsLegal(uint256 _date) pure private returns(bool) {
        uint256 year = _date / 10000;
        uint256 mon = _date / 100 - year * 100;
        uint256 day = _date - mon * 100 - year * 10000;
        
        if(year < 1970 || mon <= 0 || mon > 12 || day <= 0 || day > 31)
            return false;

        if(4 == mon || 6 == mon || 9 == mon || 11 == mon){
            if (day == 31) {
                return false;
            }
        }
        if(((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0)) {
            if(2 == mon && day > 29) {
                return false;
            }
        }else {
            if(2 == mon && day > 28){
                return false;
            }
        }
        return true;
    }
    /**
     * Constructor
     */
    constructor() public {

    }
}
contract TRNVendors is TRNData {
    
    /**
     * Constructor
     */
    constructor() public {

    }

    /**
     * This emits when vendor is added
     */
    event VendorAdded(address indexed _vendor, string _name);

    /**
     * This emits when vendor is removed
     */
    event VendorRemoved(address indexed _vendor);

    /**
     * This emits when vendor&#39;s validation is changed
     */
    event VendorValid(address indexed _vendor, bool _valid);

    /**
     * This emits when vendor&#39;s name is updated
     */
    event VendorUpdated(address indexed _vendor, string _name);

    /**
     * @dev Add vendor to the system.
     *      Only owner can operate
     *      Throw when `_vendor` is equal to `address(0)`
     *      Throw unless `_vendor` not exist.
     *      Throw when `_name`&#39;s length lte 0 or mte 100.
     * @param _vendor The address of vendor
     * @param _name The name of vendor
     * @return Success
     */
    function addVendor(address _vendor, string _name) 
        external 
        onlyOwner 
        returns(bool) {
        // _vendor is valid address
        require(_vendor != address(0));
        // _vendor not exists
        require(dataSource.vendorIds(_vendor) == 0);
        // The length of _name between 0 and 1000
        bytes memory nameBytes = bytes(_name);
        require(nameBytes.length > 0 && nameBytes.length < 200);

        dataSource.pushVendor(_name, _vendor, false);
    
        // Event
        emit VendorAdded(_vendor, _name);
        return true;
    }

    /**
     * @dev Remove vendor from the system by address.
     *      Only owner can operate
     * @param _vendor The address of vendor
     * @return Success
     */
    function removeVendorByAddress(address _vendor) 
        public 
        onlyOwner 
        returns(bool) {
        // _vendor exists
        uint256 id = dataSource.vendorIds(_vendor);
        require(id > 0);
        
        dataSource.removeVendor(id);
        // Event
        emit VendorRemoved(_vendor);
        return true;
    }

    /**
     * @dev Remove vendor from the system by Id
     *      Only owner can operate
     * @param _vendorId The id of vendor
     */
    function removeVendorById(uint256 _vendorId) 
        external 
        onlyOwner 
        returns(bool) {
        (,address vendor,,) = dataSource.getVendor(_vendorId);
        return removeVendorByAddress(vendor);
    }

    /**
     * @dev Change the `_vendorId`&#39;s validation
     *      Only owner can operate
     * @param _vendorId The id of vendor
     * @param _valid The validation of vendor
     * @return Success
     */
    function makeVendorValid(uint256 _vendorId, bool _valid) 
        external 
        onlyOwner 
        returns(bool) {
        (,address vendor,,) = dataSource.getVendor(_vendorId);
        require(dataSource.vendorIds(vendor) > 0);
        dataSource.updateVendorValid(_vendorId, _valid);
        
        // Event
        emit VendorValid(vendor, _valid);
        return true;
    }

    /**
     * @dev Update the `_vendorId`&#39;s name
     *      Only owner can operate
     * @param _vendorId Then id of vendor
     * @param _name The name of vendor
     * @return Success
     */
    function updateVendorName(uint256 _vendorId, string _name) 
        external
        onlyOwner
        returns(bool) {
        (,address vendor,,) = dataSource.getVendor(_vendorId);
        require(dataSource.vendorIds(vendor) > 0);
        // The length of _name between 0 and 1000
        bytes memory nameBytes = bytes(_name);
        require(nameBytes.length > 0 && nameBytes.length < 200);
        dataSource.updateVendorName(_vendorId, _name);

        // Event
        emit VendorUpdated(vendor, _name);
        return true;
    }

    /**
     * @dev Get Vendor ids by page
     * @param _from The begin vendorId
     * @param _limit How many vendorIds one page
     * @return The vendorIds and the next vendorId as tuple, the next page not exists when next eq 0
     */
    function getVendorIds(uint256 _from, uint256 _limit) 
        external 
        view 
        returns(uint256[], uint256){
        return dataSource.getVendors(_from, _limit, true);
    }

    /**
     * @dev Get Vendor by id
     * @param _vendorId Then vendor id
     * @return The vendor info(_name, _vendor, _timestamp, _valid)
     */
    function getVendor(uint256 _vendorId) 
        external 
        view 
        returns(string _name, address _vendor, uint256 _timestamp, bool _valid) {
        (_name, _vendor, _timestamp, _valid) = dataSource.getVendor(_vendorId);
    }

    /**
     * @dev Get Vendor by address\
     * @param _vendor Then vendor address
     * @return Then vendor info(_vendorId, _name, _timestamp, _valid)
     */
    function getVendorByAddress(address _vendor) 
        external 
        view
        returns(uint256 _vendorId, string _name, uint256 _timestamp, bool _valid) {
        _vendorId = dataSource.vendorIds(_vendor);
        (_name,, _timestamp, _valid) = dataSource.getVendor(_vendorId);
    }
}

contract TRNTokens is TRNData {
    /**
     * Constructor
     */
    constructor() public {

    }
    /**
     * This emits when token contract is added
     */
    event TokenAdded(address indexed _token);

    /**
     * This emits when token contract is removed
     */
    event TokenRemoved(uint256 _index);

    /**
     * @dev Add supported digital currency token
     *      Only owner can operate
     * @param _contract The address of digital currency contract
     */
    function addToken(address _contract) 
        external 
        onlyOwner 
        returns(uint256) {
        require(_contract != address(0));
        uint256 id = dataSource.pushToken(_contract, false);
        // Event 
        emit TokenAdded(_contract);
        return id;
    }

    /**
     * @dev Remove digital currency token
     *      Only owner can operate
     * @param _tokenId The index of digital currency contract
     */
    function removeToken(uint256 _tokenId) 
        external 
        onlyOwner 
        returns(bool){
        require(dataSource.tokenIndexToAddress(_tokenId) != address(0));
        dataSource.removeToken(_tokenId);
        // Event
        emit TokenRemoved(_tokenId);
        return true;
    }

    /**
     * @dev Returns all the supported digital currency tokens
     * @param _from The begin tokenId
     * @param _limit How many tokenIds one page 
     * @return All the supported digital currency tokens
     */

    function supportedTokens(uint256 _from, uint256 _limit) 
        external 
        view 
        returns(uint256[], uint256) {
        return dataSource.getTokens(_from, _limit, true);
    }

    /**
     * @dev Return the token info
     * @param _tokenId The token Id
     * @return The token info(symbol, name, decimals)
     */
    function getToken(uint256 _tokenId) 
        external
        view 
        returns(string _symbol, string _name, uint8 _decimals, address _token) {
        return dataSource.getToken(_tokenId);
    }
}


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
}

contract TripioToken {
    string public name;
    string public symbol;
    uint8 public decimals;
    function transfer(address _to, uint256 _value) public returns (bool);
    function balanceOf(address who) public view returns (uint256);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
}
contract TripioRoomNightData is Owned {
    using LinkedListLib for LinkedListLib.LinkedList;
    // Interface signature of erc165.
    // bytes4(keccak256("supportsInterface(bytes4)"))
    bytes4 constant public interfaceSignature_ERC165 = 0x01ffc9a7;

    // Interface signature of erc721 metadata.
    // bytes4(keccak256("name()")) ^ bytes4(keccak256("symbol()")) ^ bytes4(keccak256("tokenURI(uint256)"));
    bytes4 constant public interfaceSignature_ERC721Metadata = 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd;
        
    // Interface signature of erc721.
    // bytes4(keccak256("balanceOf(address)")) ^
    // bytes4(keccak256("ownerOf(uint256)")) ^
    // bytes4(keccak256("safeTransferFrom(address,address,uint256,bytes)")) ^
    // bytes4(keccak256("safeTransferFrom(address,address,uint256)")) ^
    // bytes4(keccak256("transferFrom(address,address,uint256)")) ^
    // bytes4(keccak256("approve(address,uint256)")) ^
    // bytes4(keccak256("setApprovalForAll(address,bool)")) ^
    // bytes4(keccak256("getApproved(uint256)")) ^
    // bytes4(keccak256("isApprovedForAll(address,address)"));
    bytes4 constant public interfaceSignature_ERC721 = 0x70a08231 ^ 0x6352211e ^ 0xb88d4fde ^ 0x42842e0e ^ 0x23b872dd ^ 0x095ea7b3 ^ 0xa22cb465 ^ 0x081812fc ^ 0xe985e9c5;

    // Base URI of token asset
    string public tokenBaseURI;

    // Authorized contracts
    struct AuthorizedContract {
        string name;
        address acontract;
    }
    mapping (address=>uint256) public authorizedContractIds;
    mapping (uint256 => AuthorizedContract) public authorizedContracts;
    LinkedListLib.LinkedList public authorizedContractList = LinkedListLib.LinkedList(0, 0);

    // Rate plan prices
    struct Price {
        uint16 inventory;       // Rate plan inventory
        bool init;              // Whether the price is initied
        mapping (uint256 => uint256) tokens;
    }

    // Vendor hotel RPs
    struct RatePlan {
        string name;            // Name of rate plan.
        uint256 timestamp;      // Create timestamp.
        bytes32 ipfs;           // The address of rate plan detail on IPFS.
        Price basePrice;        // The base price of rate plan
        mapping (uint256 => Price) prices;   // date -> Price
    }

    // Vendors
    struct Vendor {
        string name;            // Name of vendor.
        address vendor;         // Address of vendor.
        uint256 timestamp;      // Create timestamp.
        bool valid;             // Whether the vendor is valid(default is true)
        LinkedListLib.LinkedList ratePlanList;
        mapping (uint256=>RatePlan) ratePlans;
    }
    mapping (address => uint256) public vendorIds;
    mapping (uint256 => Vendor) vendors;
    LinkedListLib.LinkedList public vendorList = LinkedListLib.LinkedList(0, 0);

    // Supported digital currencies
    mapping (uint256 => address) public tokenIndexToAddress;
    LinkedListLib.LinkedList public tokenList = LinkedListLib.LinkedList(0, 0);

    // RoomNight tokens
    struct RoomNight {
        uint256 vendorId;
        uint256 rpid;
        uint256 token;          // The digital currency token 
        uint256 price;          // The digital currency price
        uint256 timestamp;      // Create timestamp.
        uint256 date;           // The checkin date
        bytes32 ipfs;           // The address of rate plan detail on IPFS.
    }
    RoomNight[] public roomnights;
    // rnid -> owner
    mapping (uint256 => address) public roomNightIndexToOwner;

    // Owner Account
    mapping (address => LinkedListLib.LinkedList) public roomNightOwners;

    // Vendor Account
    mapping (address => LinkedListLib.LinkedList) public roomNightVendors;

    // The authorized address for each TRN
    mapping (uint256 => address) public roomNightApprovals;

    // The authorized operators for each address
    mapping (address => mapping (address => bool)) public operatorApprovals;

    // The applications of room night redund
    mapping (address => mapping (uint256 => bool)) public refundApplications;

    // The signature of `onERC721Received(address,uint256,bytes)`
    // bytes4(keccak256("onERC721Received(address,uint256,bytes)"));
    bytes4 constant public ERC721_RECEIVED = 0xf0b9e5ba;

    /**
     * This emits when contract authorized
     */
    event ContractAuthorized(address _contract);

    /**
     * This emits when contract deauthorized
     */
    event ContractDeauthorized(address _contract);

    /**
     * The contract is valid
     */
    modifier authorizedContractValid(address _contract) {
        require(authorizedContractIds[_contract] > 0);
        _;
    }

    /**
     * The contract is valid
     */
    modifier authorizedContractIdValid(uint256 _cid) {
        require(authorizedContractList.nodeExists(_cid));
        _;
    }

    /**
     * Only the owner or authorized contract is valid
     */
    modifier onlyOwnerOrAuthorizedContract {
        require(msg.sender == owner || authorizedContractIds[msg.sender] > 0);
        _;
    }

    /**
     * Constructor
     */
    constructor() public {
        // Add one invalid RoomNight, avoid subscript 0
        roomnights.push(RoomNight(0, 0, 0, 0, 0, 0, 0));
    }

    /**
     * @dev Returns the node list and next node as a tuple
     * @param self stored linked list from contract
     * @param _node the begin id of the node to get
     * @param _limit the total nodes of one page
     * @param _direction direction to step in
     */
    function getNodes(LinkedListLib.LinkedList storage self, uint256 _node, uint256 _limit, bool _direction) 
        private
        view 
        returns (uint256[], uint256) {
        bool exists;
        uint256 i = 0;
        uint256 ei = 0;
        uint256 index = 0;
        uint256 count = _limit;
        if(count > self.length) {
            count = self.length;
        }
        (exists, i) = self.getAdjacent(_node, _direction);
        if(!exists || count == 0) {
            return (new uint256[](0), 0);
        }else {
            uint256[] memory temp = new uint256[](count);
            if(_node != 0) {
                index++;
                temp[0] = _node;
            }
            while (i != 0 && index < count) {
                temp[index] = i;
                (exists,i) = self.getAdjacent(i, _direction);
                index++;
            }
            ei = i;
            if(index < count) {
                uint256[] memory result = new uint256[](index);
                for(i = 0; i < index; i++) {
                    result[i] = temp[i];
                }
                return (result, ei);
            }else {
                return (temp, ei);
            }
        }
    }

    /**
     * @dev Authorize `_contract` to execute this contract&#39;s funs
     * @param _contract The contract address
     * @param _name The contract name
     */
    function authorizeContract(address _contract, string _name) 
        public 
        onlyOwner 
        returns(bool) {
        uint256 codeSize;
        assembly { codeSize := extcodesize(_contract) }
        require(codeSize != 0);
        // Not exists
        require(authorizedContractIds[_contract] == 0);

        // Add
        uint256 id = authorizedContractList.push(false);
        authorizedContractIds[_contract] = id;
        authorizedContracts[id] = AuthorizedContract(_name, _contract);

        // Event
        emit ContractAuthorized(_contract);
        return true;
    }

    /**
     * @dev Deauthorized `_contract` by address
     * @param _contract The contract address
     */
    function deauthorizeContract(address _contract) 
        public 
        onlyOwner
        authorizedContractValid(_contract)
        returns(bool) {
        uint256 id = authorizedContractIds[_contract];
        authorizedContractList.remove(id);
        authorizedContractIds[_contract] = 0;
        delete authorizedContracts[id];
        
        // Event 
        emit ContractDeauthorized(_contract);
        return true;
    }

    /**
     * @dev Deauthorized `_contract` by contract id
     * @param _cid The contract id
     */
    function deauthorizeContractById(uint256 _cid) 
        public
        onlyOwner
        authorizedContractIdValid(_cid)
        returns(bool) {
        address acontract = authorizedContracts[_cid].acontract;
        authorizedContractList.remove(_cid);
        authorizedContractIds[acontract] = 0;
        delete authorizedContracts[_cid];

        // Event 
        emit ContractDeauthorized(acontract);
        return true;
    }

    /**
     * @dev Get authorize contract ids by page
     * @param _from The begin authorize contract id
     * @param _limit How many authorize contract ids one page
     * @return The authorize contract ids and the next authorize contract id as tuple, the next page not exists when next eq 0
     */
    function getAuthorizeContractIds(uint256 _from, uint256 _limit) 
        external 
        view 
        returns(uint256[], uint256){
        return getNodes(authorizedContractList, _from, _limit, true);
    }

    /**
     * @dev Get authorize contract by id
     * @param _cid Then authorize contract id
     * @return The authorize contract info(_name, _acontract)
     */
    function getAuthorizeContract(uint256 _cid) 
        external 
        view 
        returns(string _name, address _acontract) {
        AuthorizedContract memory acontract = authorizedContracts[_cid]; 
        _name = acontract.name;
        _acontract = acontract.acontract;
    }

    /*************************************** GET ***************************************/

    /**
     * @dev Get the rate plan by `_vendorId` and `_rpid`
     * @param _vendorId The vendor id
     * @param _rpid The rate plan id
     */
    function getRatePlan(uint256 _vendorId, uint256 _rpid) 
        public 
        view 
        returns (string _name, uint256 _timestamp, bytes32 _ipfs) {
        _name = vendors[_vendorId].ratePlans[_rpid].name;
        _timestamp = vendors[_vendorId].ratePlans[_rpid].timestamp;
        _ipfs = vendors[_vendorId].ratePlans[_rpid].ipfs;
    }

    /**
     * @dev Get the rate plan price by `_vendorId`, `_rpid`, `_date` and `_tokenId`
     * @param _vendorId The vendor id
     * @param _rpid The rate plan id
     * @param _date The date desc (20180723)
     * @param _tokenId The digital token id
     * @return The price info(inventory, init, price)
     */
    function getPrice(uint256 _vendorId, uint256 _rpid, uint256 _date, uint256 _tokenId) 
        public
        view 
        returns(uint16 _inventory, bool _init, uint256 _price) {
        _inventory = vendors[_vendorId].ratePlans[_rpid].prices[_date].inventory;
        _init = vendors[_vendorId].ratePlans[_rpid].prices[_date].init;
        _price = vendors[_vendorId].ratePlans[_rpid].prices[_date].tokens[_tokenId];
        if(!_init) {
            // Get the base price
            _inventory = vendors[_vendorId].ratePlans[_rpid].basePrice.inventory;
            _price = vendors[_vendorId].ratePlans[_rpid].basePrice.tokens[_tokenId];
            _init = vendors[_vendorId].ratePlans[_rpid].basePrice.init;
        }
    }

    /**
     * @dev Get the rate plan prices by `_vendorId`, `_rpid`, `_dates` and `_tokenId`
     * @param _vendorId The vendor id
     * @param _rpid The rate plan id
     * @param _dates The dates desc ([20180723,20180724,20180725])
     * @param _tokenId The digital token id
     * @return The price info(inventory, init, price)
     */
    function getPrices(uint256 _vendorId, uint256 _rpid, uint256[] _dates, uint256 _tokenId) 
        public
        view 
        returns(uint16[] _inventories, uint256[] _prices) {
        uint16[] memory inventories = new uint16[](_dates.length);
        uint256[] memory prices = new uint256[](_dates.length);
        uint256 date;
        for(uint256 i = 0; i < _dates.length; i++) {
            date = _dates[i];
            uint16 inventory = vendors[_vendorId].ratePlans[_rpid].prices[date].inventory;
            bool init = vendors[_vendorId].ratePlans[_rpid].prices[date].init;
            uint256 price = vendors[_vendorId].ratePlans[_rpid].prices[date].tokens[_tokenId];
            if(!init) {
                // Get the base price
                inventory = vendors[_vendorId].ratePlans[_rpid].basePrice.inventory;
                price = vendors[_vendorId].ratePlans[_rpid].basePrice.tokens[_tokenId];
                init = vendors[_vendorId].ratePlans[_rpid].basePrice.init;
            }
            inventories[i] = inventory;
            prices[i] = price;
        }
        return (inventories, prices);
    }

    /**
     * @dev Get the inventory by  by `_vendorId`, `_rpid` and `_date`
     * @param _vendorId The vendor id
     * @param _rpid The rate plan id
     * @param _date The date desc (20180723)
     * @return The inventory info(inventory, init)
     */
    function getInventory(uint256 _vendorId, uint256 _rpid, uint256 _date) 
        public
        view 
        returns(uint16 _inventory, bool _init) {
        _inventory = vendors[_vendorId].ratePlans[_rpid].prices[_date].inventory;
        _init = vendors[_vendorId].ratePlans[_rpid].prices[_date].init;
        if(!_init) {
            // Get the base price
            _inventory = vendors[_vendorId].ratePlans[_rpid].basePrice.inventory;
        }
    }

    /**
     * @dev Whether the rate plan is exist
     * @param _vendorId The vendor id
     * @param _rpid The rate plan id
     * @return If the rate plan of the vendor is exist returns true otherwise return false
     */
    function ratePlanIsExist(uint256 _vendorId, uint256 _rpid) 
        public 
        view 
        returns (bool) {
        return vendors[_vendorId].ratePlanList.nodeExists(_rpid);
    }

    /**
     * @dev Get orders of owner by page
     * @param _owner The owner address
     * @param _from The begin id of the node to get
     * @param _limit The total nodes of one page
     * @param _direction Direction to step in
     * @return The order ids and the next id
     */
    function getOrdersOfOwner(address _owner, uint256 _from, uint256 _limit, bool _direction) 
        public 
        view 
        returns (uint256[], uint256) {
        return getNodes(roomNightOwners[_owner], _from, _limit, _direction);
    }

    /**
     * @dev Get orders of vendor by page
     * @param _owner The vendor address
     * @param _from The begin id of the node to get
     * @param _limit The total nodes of on page
     * @param _direction Direction to step in 
     * @return The order ids and the next id
     */
    function getOrdersOfVendor(address _owner, uint256 _from, uint256 _limit, bool _direction) 
        public 
        view 
        returns (uint256[], uint256) {
        return getNodes(roomNightVendors[_owner], _from, _limit, _direction);
    }

    /**
     * @dev Get the token count of somebody 
     * @param _owner The owner of token
     * @return The token count of `_owner`
     */
    function balanceOf(address _owner) 
        public 
        view 
        returns(uint256) {
        return roomNightOwners[_owner].length;
    }

    /**
     * @dev Get rate plan ids of `_vendorId`
     * @param _from The begin id of the node to get
     * @param _limit The total nodes of on page
     * @param _direction Direction to step in 
     * @return The rate plan ids and the next id
     */
    function getRatePlansOfVendor(uint256 _vendorId, uint256 _from, uint256 _limit, bool _direction) 
        public 
        view 
        returns(uint256[], uint256) {
        return getNodes(vendors[_vendorId].ratePlanList, _from, _limit, _direction);
    }

    /**
     * @dev Get token ids
     * @param _from The begin id of the node to get
     * @param _limit The total nodes of on page
     * @param _direction Direction to step in 
     * @return The token ids and the next id
     */
    function getTokens(uint256 _from, uint256 _limit, bool _direction) 
        public 
        view 
        returns(uint256[], uint256) {
        return getNodes(tokenList, _from, _limit, _direction);
    }

    /**
     * @dev Get token Info
     * @param _tokenId The token id
     * @return The token info(symbol, name, decimals)
     */
    function getToken(uint256 _tokenId)
        public 
        view 
        returns(string _symbol, string _name, uint8 _decimals, address _token) {
        _token = tokenIndexToAddress[_tokenId];
        TripioToken tripio = TripioToken(_token);
        _symbol = tripio.symbol();
        _name = tripio.name();
        _decimals = tripio.decimals();
    }

    /**
     * @dev Get vendor ids
     * @param _from The begin id of the node to get
     * @param _limit The total nodes of on page
     * @param _direction Direction to step in 
     * @return The vendor ids and the next id
     */
    function getVendors(uint256 _from, uint256 _limit, bool _direction) 
        public 
        view 
        returns(uint256[], uint256) {
        return getNodes(vendorList, _from, _limit, _direction);
    }

    /**
     * @dev Get the vendor infomation by vendorId
     * @param _vendorId The vendor id
     * @return The vendor infomation(name, vendor, timestamp, valid)
     */
    function getVendor(uint256 _vendorId) 
        public 
        view 
        returns(string _name, address _vendor,uint256 _timestamp, bool _valid) {
        _name = vendors[_vendorId].name;
        _vendor = vendors[_vendorId].vendor;
        _timestamp = vendors[_vendorId].timestamp;
        _valid = vendors[_vendorId].valid;
    }

    /*************************************** SET ***************************************/
    /**
     * @dev Update base uri of token metadata
     * @param _tokenBaseURI The base uri
     */
    function updateTokenBaseURI(string _tokenBaseURI) 
        public 
        onlyOwnerOrAuthorizedContract {
        tokenBaseURI = _tokenBaseURI;
    }

    /**
     * @dev Push order to user&#39;s order list
     * @param _owner The buyer address
     * @param _rnid The room night order id
     * @param _direction direction to step in
     */
    function pushOrderOfOwner(address _owner, uint256 _rnid, bool _direction) 
        public 
        onlyOwnerOrAuthorizedContract {
        if(!roomNightOwners[_owner].listExists()) {
            roomNightOwners[_owner] = LinkedListLib.LinkedList(0, 0);
        }
        roomNightOwners[_owner].add(_rnid, _direction);
    }

    /**
     * @dev Remove order from owner&#39;s order list
     * @param _owner The owner address
     * @param _rnid The room night order id
     */
    function removeOrderOfOwner(address _owner, uint _rnid) 
        public 
        onlyOwnerOrAuthorizedContract {
        require(roomNightOwners[_owner].nodeExists(_rnid));
        roomNightOwners[_owner].remove(_rnid);
    }

    /**
     * @dev Push order to the vendor&#39;s order list
     * @param _vendor The vendor address
     * @param _rnid The room night order id
     * @param _direction direction to step in
     */
    function pushOrderOfVendor(address _vendor, uint256 _rnid, bool _direction) 
        public 
        onlyOwnerOrAuthorizedContract {
        if(!roomNightVendors[_vendor].listExists()) {
            roomNightVendors[_vendor] = LinkedListLib.LinkedList(0, 0);
        }
        roomNightVendors[_vendor].add(_rnid, _direction);
    }

    /**
     * @dev Remove order from vendor&#39;s order list
     * @param _vendor The vendor address
     * @param _rnid The room night order id
     */
    function removeOrderOfVendor(address _vendor, uint256 _rnid) 
        public 
        onlyOwnerOrAuthorizedContract {
        require(roomNightVendors[_vendor].nodeExists(_rnid));
        roomNightVendors[_vendor].remove(_rnid);
    }

    /**
     * @dev Transfer token to somebody
     * @param _tokenId The token id 
     * @param _to The target owner of the token
     */
    function transferTokenTo(uint256 _tokenId, address _to) 
        public 
        onlyOwnerOrAuthorizedContract {
        roomNightIndexToOwner[_tokenId] = _to;
        roomNightApprovals[_tokenId] = address(0);
    }

    /**
     * @dev Approve `_to` to operate the `_tokenId`
     * @param _tokenId The token id
     * @param _to Somebody to be approved
     */
    function approveTokenTo(uint256 _tokenId, address _to) 
        public 
        onlyOwnerOrAuthorizedContract {
        roomNightApprovals[_tokenId] = _to;
    }

    /**
     * @dev Approve `_operator` to operate all the Token of `_to`
     * @param _operator The operator to be approved
     * @param _to The owner of tokens to be operate
     * @param _approved Approved or not
     */
    function approveOperatorTo(address _operator, address _to, bool _approved) 
        public 
        onlyOwnerOrAuthorizedContract {
        operatorApprovals[_to][_operator] = _approved;
    } 

    /**
     * @dev Update base price of rate plan
     * @param _vendorId The vendor id
     * @param _rpid The rate plan id
     * @param _tokenId The digital token id
     * @param _price The price to be updated
     */
    function updateBasePrice(uint256 _vendorId, uint256 _rpid, uint256 _tokenId, uint256 _price)
        public 
        onlyOwnerOrAuthorizedContract {
        vendors[_vendorId].ratePlans[_rpid].basePrice.init = true;
        vendors[_vendorId].ratePlans[_rpid].basePrice.tokens[_tokenId] = _price;
    }

    /**
     * @dev Update base inventory of rate plan 
     * @param _vendorId The vendor id
     * @param _rpid The rate plan id
     * @param _inventory The inventory to be updated
     */
    function updateBaseInventory(uint256 _vendorId, uint256 _rpid, uint16 _inventory)
        public 
        onlyOwnerOrAuthorizedContract {
        vendors[_vendorId].ratePlans[_rpid].basePrice.inventory = _inventory;
    }

    /**
     * @dev Update price by `_vendorId`, `_rpid`, `_date`, `_tokenId` and `_price`
     * @param _vendorId The vendor id
     * @param _rpid The rate plan id
     * @param _date The date desc (20180723)
     * @param _tokenId The digital token id
     * @param _price The price to be updated
     */
    function updatePrice(uint256 _vendorId, uint256 _rpid, uint256 _date, uint256 _tokenId, uint256 _price)
        public
        onlyOwnerOrAuthorizedContract {
        if (vendors[_vendorId].ratePlans[_rpid].prices[_date].init) {
            vendors[_vendorId].ratePlans[_rpid].prices[_date].tokens[_tokenId] = _price;
        } else {
            vendors[_vendorId].ratePlans[_rpid].prices[_date] = Price(0, true);
            vendors[_vendorId].ratePlans[_rpid].prices[_date].tokens[_tokenId] = _price;
        }
    }

    /**
     * @dev Update inventory by `_vendorId`, `_rpid`, `_date`, `_inventory`
     * @param _vendorId The vendor id
     * @param _rpid The rate plan id
     * @param _date The date desc (20180723)
     * @param _inventory The inventory to be updated
     */
    function updateInventories(uint256 _vendorId, uint256 _rpid, uint256 _date, uint16 _inventory)
        public 
        onlyOwnerOrAuthorizedContract {
        if (vendors[_vendorId].ratePlans[_rpid].prices[_date].init) {
            vendors[_vendorId].ratePlans[_rpid].prices[_date].inventory = _inventory;
        } else {
            vendors[_vendorId].ratePlans[_rpid].prices[_date] = Price(_inventory, true);
        }
    }

    /**
     * @dev Reduce inventories
     * @param _vendorId The vendor id
     * @param _rpid The rate plan id
     * @param _date The date desc (20180723)
     * @param _inventory The amount to be reduced
     */
    function reduceInventories(uint256 _vendorId, uint256 _rpid, uint256 _date, uint16 _inventory) 
        public  
        onlyOwnerOrAuthorizedContract {
        uint16 a = 0;
        if(vendors[_vendorId].ratePlans[_rpid].prices[_date].init) {
            a = vendors[_vendorId].ratePlans[_rpid].prices[_date].inventory;
            require(_inventory <= a);
            vendors[_vendorId].ratePlans[_rpid].prices[_date].inventory = a - _inventory;
        }else if(vendors[_vendorId].ratePlans[_rpid].basePrice.init){
            a = vendors[_vendorId].ratePlans[_rpid].basePrice.inventory;
            require(_inventory <= a);
            vendors[_vendorId].ratePlans[_rpid].basePrice.inventory = a - _inventory;
        }
    }

    /**
     * @dev Add inventories
     * @param _vendorId The vendor id
     * @param _rpid The rate plan id
     * @param _date The date desc (20180723)
     * @param _inventory The amount to be add
     */
    function addInventories(uint256 _vendorId, uint256 _rpid, uint256 _date, uint16 _inventory) 
        public  
        onlyOwnerOrAuthorizedContract {
        uint16 c = 0;
        if(vendors[_vendorId].ratePlans[_rpid].prices[_date].init) {
            c = _inventory + vendors[_vendorId].ratePlans[_rpid].prices[_date].inventory;
            require(c >= _inventory);
            vendors[_vendorId].ratePlans[_rpid].prices[_date].inventory = c;
        }else if(vendors[_vendorId].ratePlans[_rpid].basePrice.init) {
            c = _inventory + vendors[_vendorId].ratePlans[_rpid].basePrice.inventory;
            require(c >= _inventory);
            vendors[_vendorId].ratePlans[_rpid].basePrice.inventory = c;
        }
    }

    /**
     * @dev Update inventory and price by `_vendorId`, `_rpid`, `_date`, `_tokenId`, `_price` and `_inventory`
     * @param _vendorId The vendor id
     * @param _rpid The rate plan id
     * @param _date The date desc (20180723)
     * @param _tokenId The digital token id
     * @param _price The price to be updated
     * @param _inventory The inventory to be updated
     */
    function updatePriceAndInventories(uint256 _vendorId, uint256 _rpid, uint256 _date, uint256 _tokenId, uint256 _price, uint16 _inventory)
        public 
        onlyOwnerOrAuthorizedContract {
        if (vendors[_vendorId].ratePlans[_rpid].prices[_date].init) {
            vendors[_vendorId].ratePlans[_rpid].prices[_date].inventory = _inventory;
            vendors[_vendorId].ratePlans[_rpid].prices[_date].tokens[_tokenId] = _price;
        } else {
            vendors[_vendorId].ratePlans[_rpid].prices[_date] = Price(_inventory, true);
            vendors[_vendorId].ratePlans[_rpid].prices[_date].tokens[_tokenId] = _price;
        }
    }

    /**
     * @dev Push rate plan to `_vendorId`&#39;s rate plan list
     * @param _vendorId The vendor id
     * @param _name The name of rate plan
     * @param _ipfs The rate plan IPFS address
     * @param _direction direction to step in
     */
    function pushRatePlan(uint256 _vendorId, string _name, bytes32 _ipfs, bool _direction) 
        public 
        onlyOwnerOrAuthorizedContract
        returns(uint256) {
        RatePlan memory rp = RatePlan(_name, uint256(now), _ipfs, Price(0, false));
        
        uint256 id = vendors[_vendorId].ratePlanList.push(_direction);
        vendors[_vendorId].ratePlans[id] = rp;
        return id;
    }

    /**
     * @dev Remove rate plan of `_vendorId` by `_rpid`
     * @param _vendorId The vendor id
     * @param _rpid The rate plan id
     */
    function removeRatePlan(uint256 _vendorId, uint256 _rpid) 
        public 
        onlyOwnerOrAuthorizedContract {
        delete vendors[_vendorId].ratePlans[_rpid];
        vendors[_vendorId].ratePlanList.remove(_rpid);
    }

    /**
     * @dev Update `_rpid` of `_vendorId` by `_name` and `_ipfs`
     * @param _vendorId The vendor id
     * @param _rpid The rate plan id
     * @param _name The rate plan name
     * @param _ipfs The rate plan IPFS address
     */
    function updateRatePlan(uint256 _vendorId, uint256 _rpid, string _name, bytes32 _ipfs)
        public 
        onlyOwnerOrAuthorizedContract {
        vendors[_vendorId].ratePlans[_rpid].ipfs = _ipfs;
        vendors[_vendorId].ratePlans[_rpid].name = _name;
    }
    
    /**
     * @dev Push token contract to the token list
     * @param _direction direction to step in
     */
    function pushToken(address _contract, bool _direction)
        public 
        onlyOwnerOrAuthorizedContract 
        returns(uint256) {
        uint256 id = tokenList.push(_direction);
        tokenIndexToAddress[id] = _contract;
        return id;
    }

    /**
     * @dev Remove token by `_tokenId`
     * @param _tokenId The digital token id
     */
    function removeToken(uint256 _tokenId) 
        public 
        onlyOwnerOrAuthorizedContract {
        delete tokenIndexToAddress[_tokenId];
        tokenList.remove(_tokenId);
    }

    /**
     * @dev Generate room night token
     * @param _vendorId The vendor id
     * @param _rpid The rate plan id
     * @param _date The date desc (20180723)
     * @param _token The token id
     * @param _price The token price
     * @param _ipfs The rate plan IPFS address
     */
    function generateRoomNightToken(uint256 _vendorId, uint256 _rpid, uint256 _date, uint256 _token, uint256 _price, bytes32 _ipfs)
        public 
        onlyOwnerOrAuthorizedContract 
        returns(uint256) {
        roomnights.push(RoomNight(_vendorId, _rpid, _token, _price, now, _date, _ipfs));

        // Give the token to `_customer`
        uint256 rnid = uint256(roomnights.length - 1);
        return rnid;
    }

    /**
     * @dev Update refund applications
     * @param _buyer The room night token holder
     * @param _rnid The room night token id
     * @param _isRefund Is redund or not
     */
    function updateRefundApplications(address _buyer, uint256 _rnid, bool _isRefund) 
        public 
        onlyOwnerOrAuthorizedContract {
        refundApplications[_buyer][_rnid] = _isRefund;
    }

    /**
     * @dev Push vendor info to the vendor list
     * @param _name The name of vendor
     * @param _vendor The vendor address
     * @param _direction direction to step in
     */
    function pushVendor(string _name, address _vendor, bool _direction)
        public 
        onlyOwnerOrAuthorizedContract 
        returns(uint256) {
        uint256 id = vendorList.push(_direction);
        vendorIds[_vendor] = id;
        vendors[id] = Vendor(_name, _vendor, uint256(now), true, LinkedListLib.LinkedList(0, 0));
        return id;
    }

    /**
     * @dev Remove vendor from vendor list
     * @param _vendorId The vendor id
     */
    function removeVendor(uint256 _vendorId) 
        public 
        onlyOwnerOrAuthorizedContract {
        vendorList.remove(_vendorId);
        address vendor = vendors[_vendorId].vendor;
        vendorIds[vendor] = 0;
        delete vendors[_vendorId];
    }

    /**
     * @dev Make vendor valid or invalid
     * @param _vendorId The vendor id
     * @param _valid The vendor is valid or not
     */
    function updateVendorValid(uint256 _vendorId, bool _valid)
        public 
        onlyOwnerOrAuthorizedContract {
        vendors[_vendorId].valid = _valid;
    }

    /**
     * @dev Modify vendor&#39;s name
     * @param _vendorId The vendor id
     * @param _name Then vendor name
     */
    function updateVendorName(uint256 _vendorId, string _name)
        public 
        onlyOwnerOrAuthorizedContract {
        vendors[_vendorId].name = _name;
    }
}


contract TripioRoomNightAdmin is TRNVendors, TRNTokens {
    /**
     * This emits when token base uri changed
     */
    event TokenBaseURIChanged(string _uri);

    /**
     * Constructor
     */
    constructor(address _dataSource) public {
        // Init the data source
        dataSource = TripioRoomNightData(_dataSource);
    }

     /**
     * @dev Update the base URI of token asset
     * @param _uri The base uri of token asset
     */
    function updateBaseTokenURI(string _uri) 
        external 
        onlyOwner {
        dataSource.updateTokenBaseURI(_uri);
        emit TokenBaseURIChanged(_uri);
    }

    /**
     * @dev Destory the contract
     */
    function destroy() external onlyOwner {
        selfdestruct(owner);
    }
}