pragma solidity ^0.4.24;

// File: contracts/SafeMath.sol

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

// File: contracts/Address.sol

/**
 * Utility library of inline functions on addresses
 */
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

// File: contracts/IERC1155TokenReceiver.sol

interface IERC1155TokenReceiver {
    /**
        @notice Handle the receipt of a single ERC1155 token type
        @dev The smart contract calls this function on the recipient
        after a `safeTransferFrom`. This function MAY throw to revert and reject the
        transfer. Return of other than the magic value MUST result in the
        transaction being reverted
        Note: the contract address is always the message sender
        @param _operator  The address which called `safeTransferFrom` function
        @param _from      The address which previously owned the token
        @param _id        An array containing the ids of the token being transferred
        @param _value     An array containing the amount of tokens being transferred
        @param _data      Additional data with no specified format
        @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
    */
    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes _data) external returns(bytes4);

    /**
        @notice Handle the receipt of multiple ERC1155 token types
        @dev The smart contract calls this function on the recipient
        after a `safeTransferFrom`. This function MAY throw to revert and reject the
        transfer. Return of other than the magic value MUST result in the
        transaction being reverted
        Note: the contract address is always the message sender
        @param _operator  The address which called `safeTransferFrom` function
        @param _from      The address which previously owned the token
        @param _ids       An array containing ids of each token being transferred
        @param _values    An array containing amounts of each token being transferred
        @param _data      Additional data with no specified format
        @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
    */
    function onERC1155BatchReceived(address _operator, address _from, uint256[] _ids, uint256[] _values, bytes _data) external returns(bytes4);
}

// File: contracts/ERC165.sol

/**
 * @title ERC165
 * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
 */
interface ERC165 {

    /**
     * @notice Query if a contract implements an interface
     * @param _interfaceId The interface identifier, as specified in ERC-165
     * @dev Interface identification is specified in ERC-165. This function
     * uses less than 30,000 gas.
     */
    function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
}

// File: contracts/IERC1155.sol

/**
    @title ERC-1155 Multi Token Standard
    @dev Note: the ERC-165 identifier for this interface is 0x97a409d2.
 */
interface IERC1155 /*is ERC165*/ {
    /**
        @dev Either TransferSingle or TransferBatch MUST emit when tokens are transferred, including zero value transfers as well as minting or burning. This event supports single tokens.
        A `TransferSingle` event from address `0x0` signifies a minting operation. The total value transferred from address 0x0 minus the total value transferred to 0x0 may be used by clients and exchanges to be added to the "circulating supply" for a given token ID
        A `TransferSingle` event to address `0x0` signifies a burning or melting operation.
        This MUST emit a 0 value, from `0x0` to `0x0` with `_operator` assuming the role of the token creator. This can be used to define a token ID with no initial balance at the time of creation.
    */
    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);

    /**
        @dev Either TransferSingle or TransferBatch MUST emit when tokens are transferred, including zero value transfers as well as minting or burning. This event supports multiple _ids and _values.
        A `TransferBatch` event from address `0x0` signifies a minting operation. The total value transferred from address 0x0 minus the total value transferred to 0x0 may be used by clients and exchanges to be added to the "circulating supply" for a given token ID
        A `TransferBatch` event to address `0x0` signifies a burning or melting operation.
        This MUST emit a 0 value, from `0x0` to `0x0` with `_operator` assuming the role of the token creator. This can be used to define a token ID with no initial balance at the time of creation.
    */
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);

    /**
        @dev MUST emit when an approval is updated
    */
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /**
        @dev Emits when the URI is updated for a token ID.
        The URI may point to a JSON file that conforms to the "ERC-1155 Metadata JSON Schema".
    */
    event URI(string _value, uint256 indexed _id);

    /**
        @dev Emits when the Name is updated for a token ID
    */
    event Name(string _value, uint256 indexed _id);

    /**
        @notice Transfers value amount of an _id from the _from address to the _to addresses specified. Each parameter array should be the same length, with each index correlating.
        @dev MUST emit Transfer event on success.
        Caller must have sufficient allowance by _from for the _id/_value pair, or isApprovedForAll must be true.
        Throws if `_to` is the zero address.
        Throws if `_id` is not a valid token ID.
        When transfer is complete, this function checks if `_to` is a smart contract (code size > 0). If so, it calls `onERC1155Received` on `_to` and throws if the return value is not `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`.
        @param _from    source addresses
        @param _to      target addresses
        @param _id      ID of the Token
        @param _value   transfer amounts
        @param _data    Additional data with no specified format, sent in call to `_to`
    */
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes _data) external;

    /**
        @notice Send multiple types of Tokens from a 3rd party in one transfer (with safety call)
        @dev MUST emit Transfer event per id on success.
        Caller must have a sufficient allowance by _from for each of the id/value pairs.
        Throws on any error rather than return a false flag to minimize user errors.
        @param _from    Source address
        @param _to      Target address
        @param _ids     Types of Tokens
        @param _values  Transfer amounts per token type
        @param _data    Additional data with no specified format, sent in call to `_to`
    */
    function safeBatchTransferFrom(address _from, address _to, uint256[] _ids, uint256[] _values, bytes _data) external;

    /**
        @notice Get the balance of an account&#39;s Tokens
        @param _owner  The address of the token holder
        @param _id     ID of the Token
        @return        The _owner&#39;s balance of the Token type requested
     */
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);

    /**
        @notice Enable or disable approval for a third party ("operator") to manage all of `msg.sender`&#39;s tokens.
        @dev MUST emit the ApprovalForAll event on success.
        @param _operator  Address to add to the set of authorized operators
        @param _approved  True if the operator is approved, false to revoke approval
    */
    function setApprovalForAll(address _operator, bool _approved) external;

    /**
        @notice Queries the approval status of an operator for a given Token and owner
        @param _owner     The owner of the Tokens
        @param _operator  Address of authorized operator
        @return           True if the operator is approved, false if not
    */
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

// File: contracts/ERC1155.sol

// A basic implementation of ERC1155.
// Supports core 1155
contract ERC1155 is IERC1155, ERC165
{
    using SafeMath for uint256;
    using Address for address;

    bytes4 constant public ERC1155_RECEIVED = 0xf23a6e61;

    // id => (owner => balance)
    mapping (uint256 => mapping(address => uint256)) internal balances;

    // owner => (operator => approved)
    mapping (address => mapping(address => bool)) internal operatorApproval;

/////////////////////////////////////////// ERC165 //////////////////////////////////////////////

    /*
        bytes4(keccak256(&#39;supportsInterface(bytes4)&#39;));
    */
    bytes4 constant private INTERFACE_SIGNATURE_ERC165 = 0x01ffc9a7;

    /*
        bytes4(keccak256("safeTransferFrom(address,address,uint256,uint256,bytes)")) ^
        bytes4(keccak256("safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)")) ^
        bytes4(keccak256("balanceOf(address,uint256)")) ^
        bytes4(keccak256("setApprovalForAll(address,bool)")) ^
        bytes4(keccak256("isApprovedForAll(address,address)"));
    */
    bytes4 constant private INTERFACE_SIGNATURE_ERC1155 = 0x97a409d2;

    function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool) {
         if (_interfaceId == INTERFACE_SIGNATURE_ERC165 ||
             _interfaceId == INTERFACE_SIGNATURE_ERC1155) {
            return true;
         }

         return false;
    }

/////////////////////////////////////////// ERC1155 //////////////////////////////////////////////

    /**
        @notice Transfers value amount of an _id from the _from address to the _to addresses specified. Each parameter array should be the same length, with each index correlating.
        @dev MUST emit Transfer event on success.
        Caller must have sufficient allowance by _from for the _id/_value pair, or isApprovedForAll must be true.
        Throws if `_to` is the zero address.
        Throws if `_id` is not a valid token ID.
        When transfer is complete, this function checks if `_to` is a smart contract (code size > 0). If so, it calls `onERC1155Received` on `_to` and throws if the return value is not `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`.
        @param _from    source addresses
        @param _to      target addresses
        @param _id      ID of the Token
        @param _value   transfer amounts
        @param _data    Additional data with no specified format, sent in call to `_to`
    */

    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes _data) external {

        require(_to != 0);
        require(_from == msg.sender || operatorApproval[_from][msg.sender] == true, "Need operator approval for 3rd party transfers.");

        // Note: SafeMath will deal with insuficient funds _from
        balances[_id][_from] = balances[_id][_from].sub(_value);
        balances[_id][_to]   = _value.add(balances[_id][_to]);

        emit TransferSingle(msg.sender, _from, _to, _id, _value);

        if (_to.isContract()) {
            require(IERC1155TokenReceiver(_to).onERC1155Received(msg.sender, _from, _id, _value, _data) == ERC1155_RECEIVED);
        }
    }

    /**
        @notice Send multiple types of Tokens from a 3rd party in one transfer (with safety call)
        @dev MUST emit Transfer event per id on success.
        Caller must have a sufficient allowance by _from for each of the id/value pairs.
        Throws on any error rather than return a false flag to minimize user errors.
        @param _from    Source address
        @param _to      Target address
        @param _ids     Types of Tokens
        @param _values  Transfer amounts per token type
        @param _data    Additional data with no specified format, sent in call to `_to`
    */
    function safeBatchTransferFrom(address _from, address _to, uint256[] _ids, uint256[] _values, bytes _data) external {

        require(_to != 0);
        require(_ids.length == _values.length);

        // Solidity does not scope variables, so declare them here.
        uint256 id;
        uint256 value;
        uint256 i;

        // Only supporting a global operator approval allows us to do only 1 check and not to touch storage to handle allowances.
        require(_from == msg.sender || operatorApproval[_from][msg.sender] == true, "Need operator approval for 3rd party transfers.");

        // We assume _ids.length == _values.length
        // we don&#39;t check since out of bound access will throw.
        for (i = 0; i < _ids.length; ++i) {
            id = _ids[i];
            value = _values[i];

            balances[id][_from] = balances[id][_from].sub(value);
            balances[id][_to] = value.add(balances[id][_to]);
        }

        emit TransferBatch(msg.sender, _from, _to, _ids, _values);

        if (_to.isContract()) {
            require(IERC1155TokenReceiver(_to).onERC1155BatchReceived(msg.sender, _from, _ids, _values, _data) == ERC1155_RECEIVED);
        }
    }

    /**
        @notice Get the balance of an account&#39;s Tokens
        @param _owner  The address of the token holder
        @param _id     ID of the Token
        @return        The _owner&#39;s balance of the Token type requested
     */
    function balanceOf(address _owner, uint256 _id) external view returns (uint256) {
        // The balance of any account can be calculated from the Transfer events history.
        // However, since we need to keep the balances to validate transfer request,
        // there is no extra cost to also privide a querry function.
        return balances[_id][_owner];
    }

    /**
        @notice Enable or disable approval for a third party ("operator") to manage all of `msg.sender`&#39;s tokens.
        @dev MUST emit the ApprovalForAll event on success.
        @param _operator  Address to add to the set of authorized operators
        @param _approved  True if the operator is approved, false to revoke approval
    */
    function setApprovalForAll(address _operator, bool _approved) external {
        operatorApproval[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /**
        @notice Queries the approval status of an operator for a given Token and owner
        @param _owner     The owner of the Tokens
        @param _operator  Address of authorized operator
        @return           True if the operator is approved, false if not
    */
    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return operatorApproval[_owner][_operator];
    }
}

// File: contracts/ERC1155MixedFungible.sol

/**
    @dev Extension to ERC1155 for Mixed Fungible and Non-Fungible Items support
    The main benefit is sharing of common type information, just like you do when
    creating a fungible id.
*/
contract ERC1155MixedFungible is ERC1155 {

    // Use a split bit implementation.
    // Store the type in the upper 128 bits..
    uint256 constant TYPE_MASK = uint256(uint128(~0)) << 128;

    // ..and the non-fungible index in the lower 128
    uint256 constant NF_INDEX_MASK = uint128(~0);

    // The top bit is a flag to tell if this is a NFI.
    uint256 constant TYPE_NF_BIT = 1 << 255;

    mapping (uint256 => address) nfOwners;

    // Only to make code clearer. Should not be functions
    function isNonFungible(uint256 _id) public pure returns(bool) {
        return _id & TYPE_NF_BIT == TYPE_NF_BIT;
    }
    function isFungible(uint256 _id) public pure returns(bool) {
        return _id & TYPE_NF_BIT == 0;
    }
    function getNonFungibleIndex(uint256 _id) public pure returns(uint256) {
        return _id & NF_INDEX_MASK;
    }
    function getNonFungibleBaseType(uint256 _id) public pure returns(uint256) {
        return _id & TYPE_MASK;
    }
    function isNonFungibleBaseType(uint256 _id) public pure returns(bool) {
        // A base type has the NF bit but does not have an index.
        return (_id & TYPE_NF_BIT == TYPE_NF_BIT) && (_id & NF_INDEX_MASK == 0);
    }
    function isNonFungibleItem(uint256 _id) public pure returns(bool) {
        // A base type has the NF bit but does has an index.
        return (_id & TYPE_NF_BIT == TYPE_NF_BIT) && (_id & NF_INDEX_MASK != 0);
    }
    function ownerOf(uint256 _id) public view returns (address) {
        return nfOwners[_id];
    }

    // overide
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes _data) external {

        require(_to != 0);
        require(_from == msg.sender || operatorApproval[_from][msg.sender] == true, "Need operator approval for 3rd party transfers.");

        if (isNonFungible(_id)) {
            require(nfOwners[_id] == _from);
            nfOwners[_id] = _to;
            // You could keep balance of NF type in base type id like so:
            // uint256 baseType = getNonFungibleBaseType(_id);
            // balances[baseType][_from] = balances[baseType][_from].sub(_value);
            // balances[baseType][_to]   = balances[baseType][_to].add(_value);
        } else {
            balances[_id][_from] = balances[_id][_from].sub(_value);
            balances[_id][_to]   = balances[_id][_to].add(_value);
        }

        emit TransferSingle(msg.sender, _from, _to, _id, _value);

        if (_to.isContract()) {
            require(IERC1155TokenReceiver(_to).onERC1155Received(msg.sender, _from, _id, _value, _data) == ERC1155_RECEIVED);
        }
    }

    // overide
    function safeBatchTransferFrom(address _from, address _to, uint256[] _ids, uint256[] _values, bytes _data) external {

        require(_to != 0, "cannot send to zero address");
        require(_ids.length == _values.length, "Array length must match");

        // Only supporting a global operator approval allows us to do only 1 check and not to touch storage to handle allowances.
        require(_from == msg.sender || operatorApproval[_from][msg.sender] == true, "Need operator approval for 3rd party transfers.");

        for (uint256 i = 0; i < _ids.length; ++i) {
            // Cache value to local variable to reduce read costs.
            uint256 id = _ids[i];
            uint256 value = _values[i];

            if (isNonFungible(id)) {
                require(nfOwners[id] == _from);
                nfOwners[id] = _to;
            } else {
                balances[id][_from] = balances[id][_from].sub(value);
                balances[id][_to]   = value.add(balances[id][_to]);
            }
        }

        emit TransferBatch(msg.sender, _from, _to, _ids, _values);

        if (_to.isContract()) {
            require(IERC1155TokenReceiver(_to).onERC1155BatchReceived(msg.sender, _from, _ids, _values, _data) == ERC1155_RECEIVED);
        }
    }

    function balanceOf(address _owner, uint256 _id) external view returns (uint256) {
        if (isNonFungibleItem(_id))
            return nfOwners[_id] == _owner ? 1 : 0;
        return balances[_id][_owner];
    }
}

// File: contracts/ERC1155MixedFungibleMintable.sol

/**
    @dev Mintable form of ERC1155
    Shows how easy it is to mint new items
*/
contract ERC1155MixedFungibleMintable is ERC1155MixedFungible {

    uint256 nonce;
    mapping (uint256 => address) public creators;
    mapping (uint256 => uint256) public maxIndex;

    modifier creatorOnly(uint256 _id) {
        require(creators[_id] == msg.sender);
        _;
    }

    // This function only creates the type.
    function create(
        string _name,
        string _uri,
        bool   _isNF)
    external returns(uint256 _type) {

        // Store the type in the upper 128 bits
        _type = (++nonce << 128);

        // Set a flag if this is an NFI.
        if (_isNF)
          _type = _type | TYPE_NF_BIT;

        // This will allow restricted access to creators.
        creators[_type] = msg.sender;

        // emit a Transfer event with Create semantic to help with discovery.
        emit TransferSingle(msg.sender, 0x0, 0x0, _type, 0);

        if (bytes(_name).length > 0)
            emit Name(_name, _type);

        if (bytes(_uri).length > 0)
            emit URI(_uri, _type);
    }

    function mintNonFungible(uint256 _type, address[] _to) external creatorOnly(_type) {

        // No need to check this is a nf type rather than an id since
        // creatorOnly() will only let a type pass through.
        require(isNonFungible(_type));

        // Index are 1-based.
        uint256 index = maxIndex[_type] + 1;

        for (uint256 i = 0; i < _to.length; ++i) {
            address dst = _to[i];
            uint256 id  = _type | index + i;

            nfOwners[id] = dst;

            // You could use base-type id to store NF type balances if you wish.
            // balances[_type][dst] = quantity.add(balances[_type][dst]);

            emit TransferSingle(msg.sender, 0x0, dst, id, 1);

            if (dst.isContract()) {
                require(IERC1155TokenReceiver(dst).onERC1155Received(msg.sender, msg.sender, id, 1, &#39;&#39;) == ERC1155_RECEIVED);
            }
        }

        maxIndex[_type] = _to.length.add(maxIndex[_type]);
    }

    function mintFungible(uint256 _id, address[] _to, uint256[] _quantities)  external creatorOnly(_id) {

        require(isFungible(_id));

        for (uint256 i = 0; i < _to.length; ++i) {

            address to = _to[i];
            uint256 quantity = _quantities[i];

            // Grant the items to the caller
            balances[_id][to] = quantity.add(balances[_id][to]);

            // Emit the Transfer/Mint event.
            // the 0x0 source address implies a mint
            // It will also provide the circulating supply info.
            emit TransferSingle(msg.sender, 0x0, to, _id, quantity);

            if (to.isContract()) {
                require(IERC1155TokenReceiver(to).onERC1155Received(msg.sender, msg.sender, _id, quantity, &#39;&#39;) == ERC1155_RECEIVED);
            }
        }
    }
}