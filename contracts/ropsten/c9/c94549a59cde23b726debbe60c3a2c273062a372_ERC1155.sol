pragma solidity 0.5.2;




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

/**
    @title ERC-1155 Multi Token Standard
    @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1155.md
    Note: The ERC-165 identifier for this interface is 0xd9b67a26.
 */
interface IERC1155 /* is ERC165 */ {
    /**
        @dev Either TransferSingle or TransferBatch MUST emit when tokens are transferred, including zero value transfers as well as minting or burning.
        Operator will always be msg.sender.
        Either event from address `0x0` signifies a minting operation.
        An event to address `0x0` signifies a burning or melting operation.
        The total value transferred from address 0x0 minus the total value transferred to 0x0 may be used by clients and exchanges to be added to the "circulating supply" for a given token ID.
        To define a token ID with no initial balance, the contract SHOULD emit the TransferSingle event from `0x0` to `0x0`, with the token creator as `_operator`.
    */
    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);

    /**
        @dev Either TransferSingle or TransferBatch MUST emit when tokens are transferred, including zero value transfers as well as minting or burning.
        Operator will always be msg.sender.
        Either event from address `0x0` signifies a minting operation.
        An event to address `0x0` signifies a burning or melting operation.
        The total value transferred from address 0x0 minus the total value transferred to 0x0 may be used by clients and exchanges to be added to the "circulating supply" for a given token ID.
        To define multiple token IDs with no initial balance, this SHOULD emit the TransferBatch event from `0x0` to `0x0`, with the token creator as `_operator`.
    */
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);

    /**
        @dev MUST emit when an approval is updated.
    */
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /**
        @dev MUST emit when the URI is updated for a token ID.
        URIs are defined in RFC 3986.
        The URI MUST point a JSON file that conforms to the "ERC-1155 Metadata JSON Schema".
    */
    event URI(string _value, uint256 indexed _id);

    /**
        @notice Transfers value amount of an _id from the _from address to the _to address specified.
        @dev MUST emit TransferSingle event on success.
        Caller must be approved to manage the _from account&#39;s tokens (see isApprovedForAll).
        MUST throw if `_to` is the zero address.
        MUST throw if balance of sender for token `_id` is lower than the `_value` sent.
        MUST throw on any other error.
        When transfer is complete, this function MUST check if `_to` is a smart contract (code size > 0). If so, it MUST call `onERC1155Received` on `_to` and revert if the return value is not `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`.
        @param _from    Source address
        @param _to      Target address
        @param _id      ID of the token type
        @param _value   Transfer amount
        @param _data    Additional data with no specified format, sent in call to `_to`
    */
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;

    /**
        @notice Send multiple types of Tokens from a 3rd party in one transfer (with safety call).
        @dev MUST emit TransferBatch event on success.
        Caller must be approved to manage the _from account&#39;s tokens (see isApprovedForAll).
        MUST throw if `_to` is the zero address.
        MUST throw if length of `_ids` is not the same as length of `_values`.
        MUST throw if any of the balance of sender for token `_ids` is lower than the respective `_values` sent.
        MUST throw on any other error.
        When transfer is complete, this function MUST check if `_to` is a smart contract (code size > 0). If so, it MUST call `onERC1155BatchReceived` on `_to` and revert if the return value is not `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`.
        @param _from    Source addresses
        @param _to      Target addresses
        @param _ids     IDs of each token type
        @param _values  Transfer amounts per token type
        @param _data    Additional data with no specified format, sent in call to `_to`
    */
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external;

    /**
        @notice Get the balance of an account&#39;s Tokens.
        @param _owner  The address of the token holder
        @param _id     ID of the Token
        @return        The _owner&#39;s balance of the Token type requested
     */
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);

    /**
        @notice Get the balance of multiple account/token pairs
        @param _owners The addresses of the token holders
        @param _ids    ID of the Tokens
        @return        The _owner&#39;s balance of the Token types requested
     */
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);

    /**
        @notice Enable or disable approval for a third party ("operator") to manage all of the caller&#39;s tokens.
        @dev MUST emit the ApprovalForAll event on success.
        @param _operator  Address to add to the set of authorized operators
        @param _approved  True if the operator is approved, false to revoke approval
    */
    function setApprovalForAll(address _operator, bool _approved) external;

    /**
        @notice Queries the approval status of an operator for a given owner.
        @param _owner     The owner of the Tokens
        @param _operator  Address of authorized operator
        @return           True if the operator is approved, false if not
    */
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

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
    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes calldata _data) external returns(bytes4);

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
    function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external returns(bytes4);
}



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

// A sample implementation of core ERC1155 function.
contract ERC1155 is IERC1155, ERC165
{
    using SafeMath for uint256;
    using Address for address;

    bytes4 constant public ERC1155_RECEIVED       = 0xf23a6e61;
    bytes4 constant public ERC1155_BATCH_RECEIVED = 0xbc197c81;

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
        bytes4(keccak256("balanceOfBatch(address[],uint256[])")) ^
        bytes4(keccak256("setApprovalForAll(address,bool)")) ^
        bytes4(keccak256("isApprovedForAll(address,address)"));
    */
    bytes4 constant private INTERFACE_SIGNATURE_ERC1155 = 0xd9b67a26;

    function supportsInterface(bytes4 _interfaceId)
    public
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
        @dev MUST emit TransferSingle event on success.
        Caller must be approved to manage the _from account&#39;s tokens (see isApprovedForAll).
        MUST Throw if `_to` is the zero address.
        MUST Throw if `_id` is not a valid token ID.
        MUST Throw on any other error.
        When transfer is complete, this function MUST check if `_to` is a smart contract (code size > 0). If so, it MUST call `onERC1155Received` on `_to` and revert if the return value is not `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`.
        @param _from    Source addresses
        @param _to      Target addresses
        @param _id      ID of the token type
        @param _value   Transfer amount
        @param _data    Additional data with no specified format, sent in call to `_to`
    */
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external {

        require(_to != address(0x0), "_to must be non-zero.");
        require(_from == msg.sender || operatorApproval[_from][msg.sender] == true, "Need operator approval for 3rd party transfers.");

        // SafeMath will throw with insuficient funds _from
        // or if _id is not valid (balance will be 0)
        balances[_id][_from] = balances[_id][_from].sub(_value);
        balances[_id][_to]   = _value.add(balances[_id][_to]);

        emit TransferSingle(msg.sender, _from, _to, _id, _value);

        if (_to.isContract()) {
            require(IERC1155TokenReceiver(_to).onERC1155Received(msg.sender, _from, _id, _value, _data) == ERC1155_RECEIVED, "Receiver contract did not accept the transfer.");
        }
    }

    /**
        @notice Send multiple types of Tokens from a 3rd party in one transfer (with safety call).
        @dev MUST emit TransferBatch event on success.
        Caller must be approved to manage the _from account&#39;s tokens (see isApprovedForAll).
        MUST Throw if `_to` is the zero address.
        MUST Throw if any of the `_ids` is not a valid token ID.
        MUST Throw on any other error.
        When transfer is complete, this function MUST check if `_to` is a smart contract (code size > 0). If so, it MUST call `onERC1155BatchReceived` on `_to` and revert if the return value is not `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`.
        @param _from    Source address
        @param _to      Target address
        @param _ids     IDs of each token type
        @param _values  Transfer amounts per token type
        @param _data    Additional data with no specified format, sent in call to `_to`
    */
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external {

        // MUST Throw on errors
        require(_to != address(0x0), "destination address must be non-zero.");
        require(_ids.length == _values.length, "_ids and _values array lenght must match.");
        require(_from == msg.sender || operatorApproval[_from][msg.sender] == true, "Need operator approval for 3rd party transfers.");

        for (uint256 i = 0; i < _ids.length; ++i) {
            uint256 id = _ids[i];
            uint256 value = _values[i];

            // SafeMath will throw with insuficient funds _from
            // or if _id is not valid (balance will be 0)
            balances[id][_from] = balances[id][_from].sub(value);
            balances[id][_to]   = value.add(balances[id][_to]);
        }

        // MUST emit event
        emit TransferBatch(msg.sender, _from, _to, _ids, _values);

        // Now that the balances are updated,
        // call onERC1155BatchReceived if the destination is a contract
        if (_to.isContract()) {
            require(IERC1155TokenReceiver(_to).onERC1155BatchReceived(msg.sender, _from, _ids, _values, _data) == ERC1155_BATCH_RECEIVED, "Receiver contract did not accept the transfer.");
        }
    }

    /**
        @notice Get the balance of an account&#39;s Tokens.
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
        @notice Get the balance of multiple account/token pairs
        @param _owners The addresses of the token holders
        @param _ids    ID of the Tokens
        @return        The _owner&#39;s balance of the Token types requested
     */
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory) {

        require(_owners.length == _ids.length);

        uint256[] memory balances_ = new uint256[](_owners.length);

        for (uint256 i = 0; i < _owners.length; ++i) {
            balances_[i] = balances[_ids[i]][_owners[i]];
        }

        return balances_;
    }

    /**
        @notice Enable or disable approval for a third party ("operator") to manage all of the caller&#39;s tokens.
        @dev MUST emit the ApprovalForAll event on success.
        @param _operator  Address to add to the set of authorized operators
        @param _approved  True if the operator is approved, false to revoke approval
    */
    function setApprovalForAll(address _operator, bool _approved) external {
        operatorApproval[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /**
        @notice Queries the approval status of an operator for a given owner.
        @param _owner     The owner of the Tokens
        @param _operator  Address of authorized operator
        @return           True if the operator is approved, false if not
    */
    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return operatorApproval[_owner][_operator];
    }
}