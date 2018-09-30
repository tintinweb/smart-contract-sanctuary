pragma solidity ^0.4.25;

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

library Address {

    /**
     * Returns whether the target address is a contract
     * @dev This function will return false if invoked during the constructor of a contract,
     * as the code is not actually created until after the constructor finishes.
     * @param account address of the account to check
     * @return whether the target address is a contract
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solium-disable-next-line security/no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

}

interface IERC1155TokenReceiver {
    /// @notice Handle the receipt of an ERC1155 type
    /// @dev The smart contract calls this function on the recipient
    ///  after a `safeTransfer`. This function MAY throw to revert and reject the
    ///  transfer. Return of other than the magic value MUST result in the
    ///  transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _operator The address which called `safeTransferFrom` function
    /// @param _from The address which previously owned the token
    /// @param _id The identifier of the item being transferred
    /// @param _value The amount of the item being transferred
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
    ///  unless throwing
    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes _data) external returns(bytes4);
}

interface IERC1155 {
    event Approval(address indexed _owner, address indexed _spender, uint256 indexed _id, uint256 _oldValue, uint256 _value);
    event Transfer(address _spender, address indexed _from, address indexed _to, uint256 indexed _id, uint256 _value);

    function transferFrom(address _from, address _to, uint256 _id, uint256 _value) external;
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes _data) external;
    function approve(address _spender, uint256 _id, uint256 _currentValue, uint256 _value) external;
    function balanceOf(uint256 _id, address _owner) external view returns (uint256);
    function allowance(uint256 _id, address _owner, address _spender) external view returns (uint256);
}

interface IERC1155Extended {
    function transfer(address _to, uint256 _id, uint256 _value) external;
    function safeTransfer(address _to, uint256 _id, uint256 _value, bytes _data) external;
}

interface IERC1155BatchTransfer {
    function batchTransferFrom(address _from, address _to, uint256[] _ids, uint256[] _values) external;
    function safeBatchTransferFrom(address _from, address _to, uint256[] _ids, uint256[] _values, bytes _data) external;
    function batchApprove(address _spender, uint256[] _ids,  uint256[] _currentValues, uint256[] _values) external;
}

interface IERC1155BatchTransferExtended {
    function batchTransfer(address _to, uint256[] _ids, uint256[] _values) external;
    function safeBatchTransfer(address _to, uint256[] _ids, uint256[] _values, bytes _data) external;
}

interface IERC1155Operators {
    event OperatorApproval(address indexed _owner, address indexed _operator, uint256 indexed _id, bool _approved);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    function setApproval(address _operator, uint256[] _ids, bool _approved) external;
    function isApproved(address _owner, address _operator, uint256 _id)  external view returns (bool);
    function setApprovalForAll(address _operator, bool _approved) external;
    function isApprovedForAll(address _owner, address _operator) external view returns (bool isOperator);
}

interface IERC1155Views {
    function totalSupply(uint256 _id) external view returns (uint256);
    function name(uint256 _id) external view returns (string);
    function symbol(uint256 _id) external view returns (string);
    function decimals(uint256 _id) external view returns (uint8);
    function uri(uint256 _id) external view returns (string);
}

contract ERC1155 is IERC1155, IERC1155Extended, IERC1155BatchTransfer, IERC1155BatchTransferExtended {
    using SafeMath for uint256;
    using Address for address;

    // Variables
    struct PropertyAddress {
        string street_address;
        string country_region;
        string city;
        string post_code;
    }

    struct PropertyLayout {
        string room_type;
        string smoking_policy;
        string bed_policy;
    }

    struct PropertyFacilities {
        bool internet;
        bool parking;
        string staff_speaking_language; // Turn to array later
    }

    struct PropertyContact {
        string contact_name;
        string phone_number;
        string alternative_number;
    }

    struct Property {
        PropertyAddress property_address;
        PropertyLayout layout;
        PropertyFacilities facility;
        PropertyContact property_contact;
    }

    struct Items {
        address owner;
        string name; // Room name
        uint256 totalSupply;
        uint256 price; // Price of Room
        
        Property detail;

        mapping (address => uint256) balances;
    }
    mapping (uint256 => uint8) public decimals;
    mapping (uint256 => string) public symbols;
    mapping (uint256 => mapping(address => mapping(address => uint256))) public allowances;
    mapping (uint256 => Items) public items;

    bytes4 constant private ERC1155_RECEIVED = 0xf23a6e61;

/////////////////////////////////////////// IERC1155 //////////////////////////////////////////////

    // Events
    event Approval(address indexed _owner, address indexed _spender, uint256 indexed _id, uint256 _oldValue, uint256 _value);
    event Transfer(address _spender, address indexed _from, address indexed _to, uint256 indexed _id, uint256 _value);

    function transferFrom(address _from, address _to, uint256 _id, uint256 _value) external {
        if(_from != msg.sender) {
            //require(allowances[_id][_from][msg.sender] >= _value);
            allowances[_id][_from][msg.sender] = allowances[_id][_from][msg.sender].sub(_value);
        }

        items[_id].balances[_from] = items[_id].balances[_from].sub(_value);
        items[_id].balances[_to] = _value.add(items[_id].balances[_to]);

        emit Transfer(msg.sender, _from, _to, _id, _value);
    }

    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes _data) external {
        this.transferFrom(_from, _to, _id, _value);

        // solium-disable-next-line arg-overflow
        require(_checkAndCallSafeTransfer(_from, _to, _id, _value, _data));
    }

    function approve(address _spender, uint256 _id, uint256 _currentValue, uint256 _value) external {
        // if the allowance isn&#39;t 0, it can only be updated to 0 to prevent an allowance change immediately after withdrawal
        require(_value == 0 || allowances[_id][msg.sender][_spender] == _currentValue);
        allowances[_id][msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _id, _currentValue, _value);
    }

    function balanceOf(uint256 _id, address _owner) external view returns (uint256) {
        return items[_id].balances[_owner];
    }

    function allowance(uint256 _id, address _owner, address _spender) external view returns (uint256) {
        return allowances[_id][_owner][_spender];
    }

/////////////////////////////////////// IERC1155Extended //////////////////////////////////////////

    function transfer(address _to, uint256 _id, uint256 _value) external {
        // Not needed. SafeMath will do the same check on .sub(_value)
        //require(_value <= items[_id].balances[msg.sender]);
        items[_id].balances[msg.sender] = items[_id].balances[msg.sender].sub(_value);
        items[_id].balances[_to] = _value.add(items[_id].balances[_to]);
        emit Transfer(msg.sender, msg.sender, _to, _id, _value);
    }

    function safeTransfer(address _to, uint256 _id, uint256 _value, bytes _data) external {
        this.transfer(_to, _id, _value);

        // solium-disable-next-line arg-overflow
        require(_checkAndCallSafeTransfer(msg.sender, _to, _id, _value, _data));
    }

//////////////////////////////////// IERC1155BatchTransfer ////////////////////////////////////////

    function batchTransferFrom(address _from, address _to, uint256[] _ids, uint256[] _values) external {
        uint256 _id;
        uint256 _value;

        if(_from == msg.sender) {
            for (uint256 i = 0; i < _ids.length; ++i) {
                _id = _ids[i];
                _value = _values[i];

                items[_id].balances[_from] = items[_id].balances[_from].sub(_value);
                items[_id].balances[_to] = _value.add(items[_id].balances[_to]);

                emit Transfer(msg.sender, _from, _to, _id, _value);
            }
        }
        else {
            for (i = 0; i < _ids.length; ++i) {
                _id = _ids[i];
                _value = _values[i];

                allowances[_id][_from][msg.sender] = allowances[_id][_from][msg.sender].sub(_value);

                items[_id].balances[_from] = items[_id].balances[_from].sub(_value);
                items[_id].balances[_to] = _value.add(items[_id].balances[_to]);

                emit Transfer(msg.sender, _from, _to, _id, _value);
            }
        }
    }

    function safeBatchTransferFrom(address _from, address _to, uint256[] _ids, uint256[] _values, bytes _data) external {
        this.batchTransferFrom(_from, _to, _ids, _values);

        for (uint256 i = 0; i < _ids.length; ++i) {
            // solium-disable-next-line arg-overflow
            require(_checkAndCallSafeTransfer(_from, _to, _ids[i], _values[i], _data));
        }
    }

    function batchApprove(address _spender, uint256[] _ids,  uint256[] _currentValues, uint256[] _values) external {
        uint256 _id;
        uint256 _value;

        for (uint256 i = 0; i < _ids.length; ++i) {
            _id = _ids[i];
            _value = _values[i];

            require(_value == 0 || allowances[_id][msg.sender][_spender] == _currentValues[i]);
            allowances[_id][msg.sender][_spender] = _value;
            emit Approval(msg.sender, _spender, _id, _currentValues[i], _value);
        }
    }

//////////////////////////////// IERC1155BatchTransferExtended ////////////////////////////////////

    function batchTransfer(address _to, uint256[] _ids, uint256[] _values) external {
        uint256 _id;
        uint256 _value;

        for (uint256 i = 0; i < _ids.length; ++i) {
            _id = _ids[i];
            _value = _values[i];

            items[_id].balances[msg.sender] = items[_id].balances[msg.sender].sub(_value);
            items[_id].balances[_to] = _value.add(items[_id].balances[_to]);

            emit Transfer(msg.sender, msg.sender, _to, _id, _value);
        }
    }

    function safeBatchTransfer(address _to, uint256[] _ids, uint256[] _values, bytes _data) external {
        this.batchTransfer(_to, _ids, _values);

        for (uint256 i = 0; i < _ids.length; ++i) {
            // solium-disable-next-line arg-overflow
            require(_checkAndCallSafeTransfer(msg.sender, _to, _ids[i], _values[i], _data));
        }
    }

//////////////////////////////// IERC1155BatchTransferExtended ////////////////////////////////////

    // Optional meta data view Functions
    // consider multi-lingual support for name?
    function name(uint256 _id) external view returns (string) {
        return items[_id].name;
    }

    function symbol(uint256 _id) external view returns (string) {
        return symbols[_id];
    }

    function decimals(uint256 _id) external view returns (uint8) {
        return decimals[_id];
    }

    function totalSupply(uint256 _id) external view returns (uint256) {
        return items[_id].totalSupply;
    }


////////////////////////////////////////// OPTIONALS //////////////////////////////////////////////


    function multicastTransfer(address[] _to, uint256[] _ids, uint256[] _values) external {
        for (uint256 i = 0; i < _to.length; ++i) {
            uint256 _id = _ids[i];
            uint256 _value = _values[i];
            address _dst = _to[i];

            items[_id].balances[msg.sender] = items[_id].balances[msg.sender].sub(_value);
            items[_id].balances[_dst] = _value.add(items[_id].balances[_dst]);

            emit Transfer(msg.sender, msg.sender, _dst, _id, _value);
        }
    }

    function safeMulticastTransfer(address[] _to, uint256[] _ids, uint256[] _values, bytes _data) external {
        this.multicastTransfer(_to, _ids, _values);

        for (uint256 i = 0; i < _ids.length; ++i) {
            // solium-disable-next-line arg-overflow
            require(_checkAndCallSafeTransfer(msg.sender, _to[i], _ids[i], _values[i], _data));
        }
    }

////////////////////////////////////////// INTERNAL //////////////////////////////////////////////

    function _checkAndCallSafeTransfer(
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes _data
    )
    internal
    returns (bool)
    {
        if (!_to.isContract()) {
            return true;
        }
        bytes4 retval = IERC1155TokenReceiver(_to).onERC1155Received(
            msg.sender, _from, _id, _value, _data);
        return (retval == ERC1155_RECEIVED);
    }
}

contract owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}

/**
    @dev Mintable form of ERC1155
    Shows how easy it is to mint new items
*/
contract HotelItem is owned,ERC1155 {
    mapping (uint256 => address) public minters;
    uint256 public nonce;
    
    constructor() public {
           
    }

    function mint(string _name, uint256 _totalSupply, uint256 _price, uint8 _decimals, string _symbol)
    external onlyOwner returns(uint256 _id) {
        _id = ++nonce;

        items[_id].owner = msg.sender;
        items[_id].name = _name;
        items[_id].totalSupply = _totalSupply;


        // +---------------------+
        // | Property Variables  |
        // +---------------------+
        items[_id].price = _price;
        // +-------------------------+
        // | End Property Variables  |
        // +-------------------------+

        decimals[_id] = _decimals;
        symbols[_id] = _symbol;

        // Grant the items to the minter
        items[_id].balances[msg.sender] = _totalSupply;
    }

    // Set Property Address
    function set_property_address(uint256 _id, string _street_address, string _country_region, string _city, string _post_code)
    external onlyOwner returns(uint256) {

        // +---------------------+
        // | Property Variables  |
        // +---------------------+
        // Property Address
        items[_id].detail.property_address.street_address = _street_address;
        items[_id].detail.property_address.country_region = _country_region;
        items[_id].detail.property_address.country_region = _city;
        items[_id].detail.property_address.post_code = _post_code;

        // +-------------------------+
        // | End Property Variables  |
        // +-------------------------+
    }

    // Set Property Layout
    function set_property_layout(uint256 _id, string _room_type, string _smoking_policy, string _bed_policy) external onlyOwner returns(uint256) {
        // +---------------------+
        // | Property Variables  |
        // +---------------------+
        // Property Layout
        items[_id].detail.layout.room_type = _room_type;
        items[_id].detail.layout.smoking_policy = _smoking_policy;
        items[_id].detail.layout.bed_policy = _bed_policy;
        // +-------------------------+
        // | End Property Variables  |
        // +-------------------------+

        // Grant the items to the minter
    }

    // Set Property Facilities
    function set_property_facility(uint256 _id, bool _internet, bool _parking, string _staff_speaking_language) external onlyOwner returns(uint256) {
        // +---------------------+
        // | Property Variables  |
        // +---------------------+
       // Property Facilities
        items[_id].detail.facility.internet = _internet;
        items[_id].detail.facility.parking = _parking;
        items[_id].detail.facility.staff_speaking_language = _staff_speaking_language;
        // +-------------------------+
        // | End Property Variables  |
        // +-------------------------+

        // Grant the items to the minter
    }

    // Set Property Contact
    function set_property_contact(uint256 _id, string _contact_name, string _phone_number, string _alternative_number) external onlyOwner returns(uint256) {
        // +---------------------+
        // | Property Variables  |
        // +---------------------+
        // Property Contact
        items[_id].detail.property_contact.contact_name = _contact_name;
        items[_id].detail.property_contact.phone_number = _phone_number;
        items[_id].detail.property_contact.alternative_number = _alternative_number;
        // +-------------------------+
        // | End Property Variables  |
        // +-------------------------+

        // Grant the items to the minter
    }
}