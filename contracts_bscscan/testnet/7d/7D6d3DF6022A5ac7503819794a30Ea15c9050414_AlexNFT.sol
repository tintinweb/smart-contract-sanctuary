/**
 *Submitted for verification at BscScan.com on 2021-09-01
*/

/**
 *Submitted for verification at Etherscan.io on 2021-01-27
*/

pragma solidity ^0.5.0;


/**
 * @title ERC165
 * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
 */
interface IERC165 {
    /**
     * @notice Query if a contract implements an interface
     * @dev Interface identification is specified in ERC-165. This function
     * uses less than 30,000 gas
     * @param _interfaceId The interface identifier, as specified in ERC-165
     */
    function supportsInterface(bytes4 _interfaceId)
        external
        view
        returns (bool);
}

/**
 * @dev ERC-1155 interface for accepting safe transfers.
 */
interface IERC1155TokenReceiver {
    /**
     * @notice Handle the receipt of a single ERC1155 token type
     * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated
     * This function MAY throw to revert and reject the transfer
     * Return of other amount than the magic value MUST result in the transaction being reverted
     * Note: The token contract address is always the message sender
     * @param _operator  The address which called the `safeTransferFrom` function
     * @param _from      The address which previously owned the token
     * @param _id        The id of the token being transferred
     * @param _amount    The amount of tokens being transferred
     * @param _data      Additional data with no specified format
     * @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     */
    function onERC1155Received(
        address _operator,
        address _from,
        uint256 _id,
        uint256 _amount,
        bytes calldata _data
    ) external returns (bytes4);

    /**
     * @notice Handle the receipt of multiple ERC1155 token types
     * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeBatchTransferFrom` after the balances have been updated
     * This function MAY throw to revert and reject the transfer
     * Return of other amount than the magic value WILL result in the transaction being reverted
     * Note: The token contract address is always the message sender
     * @param _operator  The address which called the `safeBatchTransferFrom` function
     * @param _from      The address which previously owned the token
     * @param _ids       An array containing ids of each token being transferred
     * @param _amounts   An array containing amounts of each token being transferred
     * @param _data      Additional data with no specified format
     * @return           `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     */
    function onERC1155BatchReceived(
        address _operator,
        address _from,
        uint256[] calldata _ids,
        uint256[] calldata _amounts,
        bytes calldata _data
    ) external returns (bytes4);

    /**
     * @notice Indicates whether a contract implements the `ERC1155TokenReceiver` functions and so can accept ERC1155 token types.
     * @param  interfaceID The ERC-165 interface ID that is queried for support.s
     * @dev This function MUST return true if it implements the ERC1155TokenReceiver interface and ERC-165 interface.
     *      This function MUST NOT consume more than 5,000 gas.
     * @return Wheter ERC-165 or ERC1155TokenReceiver interfaces are supported.
     */
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath#mul: OVERFLOW");

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath#div: DIVISION_BY_ZERO");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath#sub: UNDERFLOW");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath#add: OVERFLOW");

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath#mod: DIVISION_BY_ZERO");
        return a % b;
    }
}

/**
 * Copyright 2018 ZeroEx Intl.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *   http://www.apache.org/licenses/LICENSE-2.0
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
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
        bytes32 codehash;


            bytes32 accountHash
         = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != 0x0 && codehash != accountHash);
    }
}

/**
 * @dev Implementation of Multi-Token Standard contract
 */
contract ERC1155 is IERC165 {
    using SafeMath for uint256;
    using Address for address;

    /***********************************|
  |        Variables and Events       |
  |__________________________________*/

    // onReceive function signatures
    bytes4 internal constant ERC1155_RECEIVED_VALUE = 0xf23a6e61;
    bytes4 internal constant ERC1155_BATCH_RECEIVED_VALUE = 0xbc197c81;

    // Objects balances
    mapping(address => mapping(uint256 => uint256)) internal balances;
    
    // Objects balances pending order
    mapping(address => mapping(uint256 => uint256)) internal balancesPending;
    
    // Order Creator
    mapping(address => mapping(uint256 => address)) internal orderCreator;
    
    // Objects price
    mapping(address => mapping(uint256 => uint256)) internal tokenPrice;
    
    // Objects is agent
    mapping(address => mapping(uint256 => bool)) internal isAgent;
   
    // Objects agent commission
    mapping(address => mapping(uint256 => uint256)) internal agentCommission;
    
    // Operator Functions
    mapping(address => mapping(address => bool)) internal operators;

    // Events
    event TransferSingle(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256 _id,
        uint256 _amount
    );
    event TransferBatch(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256[] _ids,
        uint256[] _amounts
    );
    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );
    event URI(string _uri, uint256 indexed _id);

    /***********************************|
  |     Public Transfer Functions     |
  |__________________________________*/

    /**
     * @notice Transfers amount amount of an _id from the _from address to the _to address specified
     * @param _from    Source address
     * @param _to      Target address
     * @param _id      ID of the token type
     * @param _amount  Transfered amount
     * @param _data    Additional data with no specified format, sent in call to `_to`
     */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data,
        bool _buyrequest
        // uint256 _tokenSupply
    ) internal {
        require(
            (msg.sender == _from) || isApprovedForAll(_from, msg.sender),
            "ERC1155#safeTransferFrom: INVALID_OPERATOR"
        );
        require(
            _to != address(0),
            "ERC1155#safeTransferFrom: INVALID_RECIPIENT"
        );
        // require(_amount >= balances[_from][_id]) is not necessary since checked with safemath operations

        _safeTransferFrom(_from, _to, _id, _amount, _buyrequest);
        _callonERC1155Received(_from, _to, _id, _amount, _data);
    }


    /***********************************|
  |    Internal Transfer Functions    |
  |__________________________________*/

    /**
     * @notice Transfers amount amount of an _id from the _from address to the _to address specified
     * @param _from    Source address
     * @param _to      Target address
     * @param _id      ID of the token type
     * @param _amount  Transfered amount
     */
    function _safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bool _buyrequest
    ) internal {
        if(_buyrequest){
            // Update balances
            balancesPending[_from][_id] = balancesPending[_from][_id].sub(_amount); // Subtract amount
            balances[_to][_id] = balances[_to][_id].add(_amount); // Add amount
        }
        else{
            // Update balances
            balances[_from][_id] = balances[_from][_id].sub(_amount); // Subtract amount
            balances[_to][_id] = balances[_to][_id].add(_amount); // Add amount
        }
        
        // Emit event
        emit TransferSingle(msg.sender, _from, _to, _id, _amount);
    }

    /**
     * @notice Verifies if receiver is contract and if so, calls (_to).onERC1155Received(...)
     */
    function _callonERC1155Received(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) internal {
        // Check if recipient is contract
        if (_to.isContract()) {
            bytes4 retval = IERC1155TokenReceiver(_to).onERC1155Received(
                msg.sender,
                _from,
                _id,
                _amount,
                _data
            );
            require(
                retval == ERC1155_RECEIVED_VALUE,
                "ERC1155#_callonERC1155Received: INVALID_ON_RECEIVE_MESSAGE"
            );
        }
    }


    /**
     * @notice Verifies if receiver is contract and if so, calls (_to).onERC1155BatchReceived(...)
     */
    function _callonERC1155BatchReceived(
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory _data
    ) internal {
        // Pass data if recipient is contract
        if (_to.isContract()) {
            bytes4 retval = IERC1155TokenReceiver(_to).onERC1155BatchReceived(
                msg.sender,
                _from,
                _ids,
                _amounts,
                _data
            );
            require(
                retval == ERC1155_BATCH_RECEIVED_VALUE,
                "ERC1155#_callonERC1155BatchReceived: INVALID_ON_RECEIVE_MESSAGE"
            );
        }
    }

    /***********************************|
  |         Operator Functions        |
  |__________________________________*/

    /**
     * @notice Enable or disable approval for a third party ("operator") to manage all of caller's tokens
     * @param _operator  Address to add to the set of authorized operators
     * @param _approved  True if the operator is approved, false to revoke approval
     */
    function setApprovalForAll(address _operator, bool _approved) external {
        // Update operator status
        operators[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /**
     * @notice Queries the approval status of an operator for a given owner
     * @param _owner     The owner of the Tokens
     * @param _operator  Address of authorized operator
     * @return True if the operator is approved, false if not
     */
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        returns (bool isOperator)
    {
        return operators[_owner][_operator];
    }

    /***********************************|
  |         Balance Functions         |
  |__________________________________*/

    /**
     * @notice Get the balance of an account's Tokens
     * @param _owner  The address of the token holder
     * @param _id     ID of the Token
     * @return The _owner's balance of the Token type requested
     */
    function balanceOf(address _owner, uint256 _id)
        public
        view
        returns (uint256)
    {
        return balances[_owner][_id];
    }
    
    function getTokenPrice(address _owner, uint256 _id)
        public
        view
        returns (uint256)
    {
        return tokenPrice[_owner][_id];
    }
    
    function getAgentFees(address _owner, uint256 _id)
        public
        view
        returns (uint256)
    {
        return agentCommission[_owner][_id];
    }
    
    function balanceOfOrder(address _owner, uint256 _id)
        public
        view
        returns (uint256)
    {
        return balancesPending[_owner][_id];
    }
    
    function ownerOfOrderCreator(address _owner, uint256 _id)
        public
        view
        returns (address)
    {
        return orderCreator[_owner][_id];
    }

    /***********************************|
  |          ERC165 Functions         |
  |__________________________________*/

    /**
     * INTERFACE_SIGNATURE_ERC165 = bytes4(keccak256("supportsInterface(bytes4)"));
     */
    bytes4 private constant INTERFACE_SIGNATURE_ERC165 = 0x01ffc9a7;

    /**
     * INTERFACE_SIGNATURE_ERC1155 =
     * bytes4(keccak256("safeTransferFrom(address,address,uint256,uint256,bytes)")) ^
     * bytes4(keccak256("safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)")) ^
     * bytes4(keccak256("balanceOf(address,uint256)")) ^
     * bytes4(keccak256("balanceOfBatch(address[],uint256[])")) ^
     * bytes4(keccak256("setApprovalForAll(address,bool)")) ^
     * bytes4(keccak256("isApprovedForAll(address,address)"));
     */
    bytes4 private constant INTERFACE_SIGNATURE_ERC1155 = 0xd9b67a26;

    /**
     * @notice Query if a contract implements an interface
     * @param _interfaceID  The interface identifier, as specified in ERC-165
     * @return `true` if the contract implements `_interfaceID` and
     */
    function supportsInterface(bytes4 _interfaceID)
        external
        view
        returns (bool)
    {
        if (
            _interfaceID == INTERFACE_SIGNATURE_ERC165 ||
            _interfaceID == INTERFACE_SIGNATURE_ERC1155
        ) {
            return true;
        }
        return false;
    }
}

/**
 * @dev Multi-Fungible Tokens with minting and burning methods. These methods assume
 *      a parent contract to be executed as they are `internal` functions
 */
contract ERC1155MintBurn is ERC1155 {
    /****************************************|
  |            Minting Functions           |
  |_______________________________________*/

    /**
     * @notice Mint _amount of tokens of a given id
     * @param _to      The address to mint tokens to
     * @param _id      Token id to mint
     * @param _amount  The amount to be minted
     * @param _data    Data to pass if receiver is contract
     */
    function _mint(
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) internal {
        // Add _amount
        balances[_to][_id] = balances[_to][_id].add(_amount);
        
        // Emit event
        emit TransferSingle(msg.sender, address(0x0), _to, _id, _amount);

        // Calling onReceive method if recipient is contract
        _callonERC1155Received(address(0x0), _to, _id, _amount, _data);
    }


    /****************************************|
  |            Burning Functions           |
  |_______________________________________*/

    /**
     * @notice Burn _amount of tokens of a given token id
     * @param _from    The address to burn tokens from
     * @param _id      Token id to burn
     * @param _amount  The amount to be burned
     */
    function _burn(
        address _from,
        uint256 _id,
        uint256 _amount
    ) internal {
        //Substract _amount
        balances[_from][_id] = balances[_from][_id].sub(_amount);

        // Emit event
        emit TransferSingle(msg.sender, _from, address(0x0), _id, _amount);
    }

}

/**
 * @notice Contract that handles metadata related methods.
 * @dev Methods assume a deterministic generation of URI based on token IDs.
 *      Methods also assume that URI uses hex representation of token IDs.
 */
contract ERC1155Metadata {
    // URI's default URI prefix
    string internal baseMetadataURI;
    event URI(string _uri, uint256 indexed _id);

    /***********************************|
  |     Metadata Public Function s    |
  |__________________________________*/

    /**
     * @notice A distinct Uniform Resource Identifier (URI) for a given token.
     * @dev URIs are defined in RFC 3986.
     *      URIs are assumed to be deterministically generated based on token ID
     *      Token IDs are assumed to be represented in their hex format in URIs
     * @return URI string
     */
    function uri(uint256 _id) public view returns (string memory) {
        return
            string(abi.encodePacked(baseMetadataURI, _uint2str(_id), ".json"));
    }

    /***********************************|
  |    Metadata Internal Functions    |
  |__________________________________*/

    /**
     * @notice Will emit default URI log event for corresponding token _id
     * @param _tokenIDs Array of IDs of tokens to log default URI
     */
    function _logURIs(uint256[] memory _tokenIDs) internal {
        string memory baseURL = baseMetadataURI;
        string memory tokenURI;

        for (uint256 i = 0; i < _tokenIDs.length; i++) {
            tokenURI = string(
                abi.encodePacked(baseURL, _uint2str(_tokenIDs[i]), ".json")
            );
            emit URI(tokenURI, _tokenIDs[i]);
        }
    }

    /**
     * @notice Will emit a specific URI log event for corresponding token
     * @param _tokenIDs IDs of the token corresponding to the _uris logged
     * @param _URIs    The URIs of the specified _tokenIDs
     */
    function _logURIs(uint256[] memory _tokenIDs, string[] memory _URIs)
        internal
    {
        require(
            _tokenIDs.length == _URIs.length,
            "ERC1155Metadata#_logURIs: INVALID_ARRAYS_LENGTH"
        );
        for (uint256 i = 0; i < _tokenIDs.length; i++) {
            emit URI(_URIs[i], _tokenIDs[i]);
        }
    }

    /**
     * @notice Will update the base URL of token's URI
     * @param _newBaseMetadataURI New base URL of token's URI
     */
    function _setBaseMetadataURI(string memory _newBaseMetadataURI) internal {
        baseMetadataURI = _newBaseMetadataURI;
    }

    /***********************************|
  |    Utility Internal Functions     |
  |__________________________________*/

    /**
     * @notice Convert uint256 to string
     * @param _i Unsigned integer to convert to string
     */
    function _uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }

        uint256 j = _i;
        uint256 ii = _i;
        uint256 len;

        // Get number of bytes
        while (j != 0) {
            len++;
            j /= 10;
        }

        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;

        // Get each individual ASCII
        while (ii != 0) {
            bstr[k--] = bytes1(uint8(48 + (ii % 10)));
            ii /= 10;
        }

        // Convert to string
        return string(bstr);
    }
}

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}

    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

library Strings {
    // via https://github.com/oraclize/ethereum-api/blob/master/oraclizeAPI_0.5.sol
    function strConcat(
        string memory _a,
        string memory _b,
        string memory _c,
        string memory _d,
        string memory _e
    ) internal pure returns (string memory) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(
            _ba.length + _bb.length + _bc.length + _bd.length + _be.length
        );
        bytes memory babcde = bytes(abcde);
        uint256 k = 0;
        for (uint256 i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
        for (uint256 i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
        for (uint256 i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
        for (uint256 i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
        for (uint256 i = 0; i < _be.length; i++) babcde[k++] = _be[i];
        return string(babcde);
    }

    function strConcat(
        string memory _a,
        string memory _b,
        string memory _c,
        string memory _d
    ) internal pure returns (string memory) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(
        string memory _a,
        string memory _b,
        string memory _c
    ) internal pure returns (string memory) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string memory _a, string memory _b)
        internal
        pure
        returns (string memory)
    {
        return strConcat(_a, _b, "", "", "");
    }

    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + (_i % 10)));
            _i /= 10;
        }
        return string(bstr);
    }
}

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping(address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account)
        internal
        view
        returns (bool)
    {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

contract MinterRole is Context {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor() internal {
        _addMinter(_msgSender());
    }

    modifier onlyMinter() {
        require(
            isMinter(_msgSender()),
            "MinterRole: caller does not have the Minter role"
        );
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(_msgSender());
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

/**
 * @title WhitelistAdminRole
 * @dev WhitelistAdmins are responsible for assigning and removing Whitelisted accounts.
 */
contract WhitelistAdminRole is Context {
    using Roles for Roles.Role;

    event WhitelistAdminAdded(address indexed account);
    event WhitelistAdminRemoved(address indexed account);

    Roles.Role private _whitelistAdmins;

    constructor() internal {
        _addWhitelistAdmin(_msgSender());
    }

    modifier onlyWhitelistAdmin() {
        require(
            isWhitelistAdmin(_msgSender()),
            "WhitelistAdminRole: caller does not have the WhitelistAdmin role"
        );
        _;
    }

    function isWhitelistAdmin(address account) public view returns (bool) {
        return _whitelistAdmins.has(account);
    }

    function addWhitelistAdmin(address account) public onlyWhitelistAdmin {
        _addWhitelistAdmin(account);
    }

    function renounceWhitelistAdmin() public {
        _removeWhitelistAdmin(_msgSender());
    }

    function _addWhitelistAdmin(address account) internal {
        _whitelistAdmins.add(account);
        emit WhitelistAdminAdded(account);
    }

    function _removeWhitelistAdmin(address account) internal {
        _whitelistAdmins.remove(account);
        emit WhitelistAdminRemoved(account);
    }
}

/**
 * @title ERC1155Tradable
 * ERC1155Tradable - ERC1155 contract that whitelists an operator address, 
 * has create and mint functionality, and supports useful standards from OpenZeppelin,
  like _exists(), name(), symbol(), and totalSupply()
 */
contract ERC1155Tradable is
    ERC1155,
    ERC1155MintBurn,
    ERC1155Metadata,
    Ownable
    // MinterRole,
    // WhitelistAdminRole
{
    event TransferSingle(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    
    using Strings for string;

    address proxyRegistryAddress;
    uint256 private _currentTokenID = 0;
    uint256 private _currentListID = 0;
    mapping(uint256 => address) public creators;
    mapping(string => uint256) public queryId;
    mapping(uint256 => uint256) public tokenSupply;
    mapping(uint256 => uint256) public tokenMaxSupply;
    
    // Contract name
    string public name;
    // Contract symbol
    string public symbol;

    constructor(
        string memory _name,
        string memory _symbol
    ) public {
        name = _name;
        symbol = _symbol;
    }

    function uri(uint256 _id) public view returns (string memory) {
        require(_exists(_id), "ERC721Tradable#uri: NONEXISTENT_TOKEN");
        return Strings.strConcat(baseMetadataURI, Strings.uint2str(_id));
    }

    /**
     * @dev Returns the total quantity for a token ID
     * @param _id uint256 ID of the token to query
     * @return amount of token in existence
     */
    function totalSupply(uint256 _id) public view returns (uint256) {
        return tokenSupply[_id];
    }

    /**
     * @dev Returns the max quantity for a token ID
     * @param _id uint256 ID of the token to query
     * @return amount of token in existence
     */
    function maxSupply(uint256 _id) public view returns (uint256) {
        return tokenMaxSupply[_id];
    }

    /**
     * @dev Will update the base URL of token's URI
     * @param _newBaseMetadataURI New base URL of token's URI
     */
    function setBaseMetadataURI(string memory _newBaseMetadataURI)
        public
        onlyOwner
    {
        _setBaseMetadataURI(_newBaseMetadataURI);
    }

    function MintToken(
        string calldata _queryId,
        uint256 _supply,
        bytes calldata _data
    ) external {
        require(_supply > 0, "Supply must be more than 0");
        

        //Check if item is not minted
        require(queryId[_queryId] == 0, "Query Id is not available");
        uint256 _id = _getNextTokenID();
        _incrementTokenTypeId();

        creators[_id] = msg.sender;
        queryId[_queryId] = _id;
        if (_supply != 0) _mint(msg.sender, _id, _supply, _data);
        tokenSupply[_id] = _supply;
        tokenMaxSupply[_id] = _supply;
    }
    
    function CreateOrder(
        string calldata _queryId,
        uint256 _tokenId,
        uint256 _amount, 
        uint256 _price,
        address _creatorAddress,
        bool _isagent, 
        uint256 _agentcommission, 
        uint256 _supply
    ) external {
        require(_supply > 0, "Supply must be more than 0");
        require(_price > 0, "Price must be more than 0");
        
        uint256 tokenId = 0;
        address creator = msg.sender;
        if(_isagent){
            creator = _creatorAddress;
        }
        
        //Check if item is not minted
        if(_tokenId == 0){
            require(queryId[_queryId] == 0, "Query Id is not available");
            uint256 _id = _getNextTokenID();
            _incrementTokenTypeId();
            
            

            creators[_id] = creator;
            queryId[_queryId] = _id;

            if (_supply != 0) _mint(creator, _id, _supply, "0x00");
            tokenSupply[_id] = _supply;
            tokenMaxSupply[_id] = _supply;
            tokenId = _id;
        }
        else{
            tokenId = _tokenId;
            require(_exists(tokenId) == true, "Token does not exist");
        }
        
        orderCreator[creator][tokenId] = msg.sender;
        
        //Check if order is curcurrently running
        if(balancesPending[creator][tokenId] > 0){
            CancelOrder(creator, tokenId);
        }
        
        //Check is item listed by owner
        require(balancesPending[creator][tokenId] == 0, "Item already listed by owner");
        require(balances[creator][tokenId] >= _amount, "Insufficient item balance.");
        
        //Set item listed quantity
        balances[creator][tokenId] = balances[creator][tokenId].sub(_amount);
        balancesPending[creator][tokenId] = balancesPending[creator][tokenId].add(_amount);
        
        //Set agentcommission
        isAgent[creator][tokenId] = _isagent;
        if(_isagent){
            agentCommission[creator][tokenId] = _agentcommission;
        }
        
        //Set item price
        tokenPrice[creator][tokenId] = _price;
    }
    
    function CancelOrder(address _ownerAddress ,uint256 _tokenId) public {
        
        //Check is item listed by owner
        require(orderCreator[msg.sender][_tokenId] == msg.sender, "Only order creator can remove order.");
        require(balancesPending[_ownerAddress][_tokenId] > 0, "No item to remove from order.");

        //Set owner delisted item
        uint256 _amount = balancesPending[msg.sender][_tokenId];
        balances[msg.sender][_tokenId] = balances[msg.sender][_tokenId].add(_amount);
        balancesPending[msg.sender][_tokenId] = balancesPending[msg.sender][_tokenId].sub(_amount);
        
        //Set item price
        tokenPrice[msg.sender][_tokenId] = 0;
    }
    
    /**
     * @dev calculates the next token ID based on value of _currentTokenID
     * @return uint256 for the next token ID
     */
    function _getNextListID() private view returns (uint256) {
        return _currentListID.add(1);
    }

    /**
     * @dev increments the value of _currentTokenID
     */
    function _incrementListId() private {
        _currentListID++;
    }
    
    function GetTokenId(string memory _queryId) view public returns (uint256) {
        return queryId[_queryId];
    }

    /**
     * @dev Burns some amount of tokens from an address
     * @param _from          Address of the future owner of the token
     * @param _id          Token ID to mint
     * @param _quantity    Amount of tokens to mint
     */
    function burn(
        address _from,
        uint256 _id,
        uint256 _quantity
    ) public {
        uint256 tokenId = _id;
        require(
            balances[_from][tokenId] >= _quantity,
            "Exceed the amount of balance"
        );
        _burn(_from, tokenId, _quantity);
        tokenMaxSupply[tokenId] = tokenMaxSupply[tokenId].sub(_quantity);
        tokenSupply[tokenId] = tokenSupply[tokenId].sub(_quantity);
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-free listings.
     */
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        returns (bool isOperator)
    {
        return ERC1155.isApprovedForAll(_owner, _operator);
    }

    /**
     * @dev Returns whether the specified token exists by checking to see if it has a creator
     * @param _id uint256 ID of the token to query the existence of
     * @return bool whether the token exists
     */
    function _exists(uint256 _id) internal view returns (bool) {
        return creators[_id] != address(0);
    }

    /**
     * @dev calculates the next token ID based on value of _currentTokenID
     * @return uint256 for the next token ID
     */
    function _getNextTokenID() private view returns (uint256) {
        return _currentTokenID.add(1);
    }

    /**
     * @dev increments the value of _currentTokenID
     */
    function _incrementTokenTypeId() private {
        _currentTokenID++;
    }
    
}

contract AlexNFT is ERC1155Tradable {
    
    event Purchase(address indexed previousOwner, address indexed newOwner, uint price, uint nftID, string uri);
    address payable _contractOwner;
    address payable _agentAccount;
    address payable _platformAcount;
    uint256 public _platformCommission;

     
    constructor(string memory _name, string memory _code)
        public
        ERC1155Tradable(_name, _code)
    {
        _setBaseMetadataURI("https://meta-sonce.rivex.finance/api/meta/");
        _contractOwner = msg.sender;
        _agentAccount = msg.sender;
        _platformAcount = msg.sender;
        _platformCommission = 2;
    }


    
    function contractURI() public view returns (string memory) {
        return baseMetadataURI;
    }
    
    function setContractURI(string memory _uri) public {
        _setBaseMetadataURI(_uri);
    }
    
    function buy(address _ownerAddress, uint256 _tokenId, uint _amount) external payable {
        
        uint256 quantity = balancesPending[_ownerAddress][_tokenId]; 
        uint256 price = tokenPrice[_ownerAddress][_tokenId]; 
        address payable owner = address(uint160(_ownerAddress));
        operators[owner][msg.sender] = true;
        
        require(balancesPending[_ownerAddress][_tokenId] > 0, "Item not listed currently");
        require(quantity >= _amount, "Error, the amount is more than the quantity available");
        require(msg.value >= price * _amount, "Error, the amount is lower");
        require(msg.sender != owner, "Can not buy what you own");
        
        address previousOwner = owner;
        address newOwner = msg.sender;

        bool isagent = isAgent[_ownerAddress][_tokenId];
        uint256 agentcommission = agentCommission[_ownerAddress][_tokenId];

        _trade(_tokenId, _amount, owner, price, isagent, agentcommission);

        emit Purchase(previousOwner, newOwner, price * _amount, _tokenId, contractURI());
    }
    
    function _trade(uint _tokenId, uint _amount, address payable _owner, uint256 _price, bool _isagent, uint256 agentcommission) internal {
        
        address payable _buyer = msg.sender;
        safeTransferFrom(_owner, _buyer, _tokenId, _amount, "", true);
        
        uint _sellerValue = 0;
        uint _clientValue = 0;
        uint _platformValue = (_price * _platformCommission / 100) * _amount;
        
        if(_isagent){
            _clientValue = (_price * agentcommission / 100) * _amount;
            _sellerValue = (_price * _amount) - (_clientValue + _platformValue);
        }
        else{
            _sellerValue = (_price * _amount) - _platformValue;
        }

        _owner.transfer(_sellerValue);
        if(_clientValue > 0){
            _agentAccount.transfer(_clientValue);
        }
        _platformAcount.transfer(_platformValue);
        
        if (msg.value > _price * _amount) {
            _buyer.transfer(msg.value - _price * _amount);
        }

    }
    
    function trasnferToken(uint256 _tokenId, uint256 _amount, address _to) public {
        require(balances[msg.sender][_tokenId] > _amount, "Amount is more than available balance");
        safeTransferFrom(msg.sender, _to, _tokenId, _amount, "", false);
    }
    
    function setAgent(address payable _agentaddress) public onlyOwner{
        _agentAccount = _agentaddress;
    }
    
    function setPlatformAccount(address payable _platformaccountaddress) public onlyOwner{
        _platformAcount = _platformaccountaddress;
    }
    
    function setPlatformCommission(uint platformCommission) public onlyOwner{
        _platformCommission = platformCommission;
    }
}