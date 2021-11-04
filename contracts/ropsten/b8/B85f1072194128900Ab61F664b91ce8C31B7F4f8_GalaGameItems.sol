import "./SafeMath.sol";
import "./Address.sol";
import "./Common.sol";
import "./IERC1155TokenReceiver.sol";
import "./IERC1155.sol";

pragma solidity ^0.5.0;


contract GalaGameItems is IERC1155, ERC165, CommonConstants {
    using SafeMath for uint256;
    using Address for address;

    uint256 constant TYPE_MASK = uint256(uint128(~0)) << 128;
    uint256 constant NF_INDEX_MASK = uint128(~0);
    uint256 constant TYPE_NF_BIT = 1 << 255;
    uint256 nonce;

    string public client;

    address public owner;

    mapping(uint256 => mapping(address => uint256)) internal balances; // id => (owner => balance)
    mapping(address => mapping(address => bool)) internal operatorApproval; // owner => (operator => approved)
    mapping(uint256 => address) nfOwners;
    mapping(uint256 => bool) public nfExists;
    mapping(uint256 => uint256) public tokenSupply;
    mapping(address => bool) internal creators;

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 indexed _id,
        uint256 _oldValue,
        uint256 _value
    );

    event TransferSingle(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256 _id,
        uint256 _value
    );
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event URI(string _value, uint256 indexed _id);
    event Client(string _clientName);
    event TransferBatch(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256[] _ids,
        uint256[] _values
    );

    event Creator(address _creator, bool _authorized);

    constructor(string memory _client) public {
      require(bytes(_client).length > 0);
      owner = msg.sender;
      creators[msg.sender] = true;
      client = _client;
      emit Client(_client);
    }

    modifier creatorOnly() {
        require(creators[msg.sender], "Creator permission required");
        _;
    }

    modifier ownerOnly() {
        require(msg.sender == owner);
        _;
    }

    function create(string calldata _uri, bool _isNF) external creatorOnly returns (uint256 _type) {
        _type = (++nonce << 128);

        if (_isNF){
          _type = _type | TYPE_NF_BIT;
          nfExists[_type] = true;
        } 

        emit TransferSingle(msg.sender, address(0x0), address(0x0), _type, 0);

        if (bytes(_uri).length > 0) emit URI(_uri, _type);
        return _type;
    }

    function mintNonFungible(
        uint256[] calldata _ids,
        address[] calldata _to,
        bytes calldata _data
    ) external creatorOnly {
      require(_ids.length == _to.length, "IDs and recipients must be of same length");
        for (uint256 i = 0; i < _to.length; ++i) {
            uint256 tokenType = getNonFungibleBaseType(_ids[i]);
            require(nfExists[tokenType], "NF token must exist");
            require(isNonFungible(tokenType), "TokenType not non-fungible");
            require(_to[i] != address(0x0), "Cannot mint to zero address");
            require(nfOwners[_ids[i]] == address(0x0), "Token already owned");
            address distributeTo = _to[i];
            nfOwners[_ids[i]] = distributeTo;
            tokenSupply[tokenType] = tokenSupply[tokenType].add(1);
            balances[tokenType][distributeTo] = balances[tokenType][distributeTo].add(1);

            emit TransferSingle(msg.sender, address(0x0), distributeTo, _ids[i], 1);

            if (distributeTo.isContract()) {
                _doSafeTransferAcceptanceCheck(msg.sender, msg.sender, distributeTo, _ids[i], 1, _data);
            }
        }
    }

    function mintFungible(
        uint256 _id,
        address[] calldata _to,
        uint256[] calldata _quantities,
        bytes calldata _data
    ) external creatorOnly {
        require(isFungible(_id), "ID must be a non-fungible ID");
        require(_to.length == _quantities.length);
        for (uint256 i = 0; i < _to.length; ++i) {
            require(_to[i] != address(0x0));
            balances[_id][_to[i]] = _quantities[i].add(balances[_id][_to[i]]);
            tokenSupply[_id] = tokenSupply[_id].add(_quantities[i]);

            emit TransferSingle(msg.sender, address(0x0), _to[i], _id, _quantities[i]);

            if (_to[i].isContract()) {
                _doSafeTransferAcceptanceCheck(
                    msg.sender,
                    msg.sender,
                    _to[i],
                    _id,
                    _quantities[i],
                    _data
                );
            }
        }
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external {
        require(_to != address(0x0), "cannot send to zero address");
        require(
            _from == msg.sender || operatorApproval[_from][msg.sender] == true,
            "Need operator approval for 3rd party transfers"
        );

        if (isNonFungible(_id)) {
            require(nfOwners[_id] == _from);
            require(_value > 0);
            nfOwners[_id] = _to;
            // You could keep balance of NF type in base type id like so:
            uint256 baseType = getNonFungibleBaseType(_id);
            balances[baseType][_from] = balances[baseType][_from].sub(_value);
            balances[baseType][_to] = balances[baseType][_to].add(_value);
        } else {
            balances[_id][_from] = balances[_id][_from].sub(_value);
            balances[_id][_to] = balances[_id][_to].add(_value);
        }

        emit TransferSingle(msg.sender, _from, _to, _id, _value);

        if (_to.isContract()) {
            _doSafeTransferAcceptanceCheck(msg.sender, _from, _to, _id, _value, _data);
        }
    }

    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external {
        require(_to != address(0x0), "Cannot send to zero address");
        require(_ids.length == _values.length, "Array length must match");
        require(
            _from == msg.sender || operatorApproval[_from][msg.sender] == true,
            "Need operator approval for 3rd party transfers"
        );

        for (uint256 i = 0; i < _ids.length; ++i) {
            if (isNonFungible(_ids[i])) {
                require(nfOwners[_ids[i]] == _from);
                require(_values[i] > 0);
                nfOwners[_ids[i]] = _to;
                balances[getNonFungibleBaseType(_ids[i])][_from] = balances[getNonFungibleBaseType(
                    _ids[i]
                )][_from]
                    .sub(_values[i]);
                balances[getNonFungibleBaseType(_ids[i])][_to] = balances[getNonFungibleBaseType(
                    _ids[i]
                )][_to]
                    .add(_values[i]);
            } else {
                balances[_ids[i]][_from] = balances[_ids[i]][_from].sub(_values[i]);
                balances[_ids[i]][_to] = _values[i].add(balances[_ids[i]][_to]);
            }
        }

        emit TransferBatch(msg.sender, _from, _to, _ids, _values);

        if (_to.isContract()) {
            _doSafeBatchTransferAcceptanceCheck(msg.sender, _from, _to, _ids, _values, _data);
        }
    }

    function balanceOf(address _owner, uint256 _id) external view returns (uint256) {
        if (isNonFungibleItem(_id)) return nfOwners[_id] == _owner ? 1 : 0;
        return balances[_id][_owner];
    }

    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids)
        external
        view
        returns (uint256[] memory)
    {
        require(_owners.length == _ids.length);
        uint256[] memory balances_ = new uint256[](_owners.length);
        for (uint256 i = 0; i < _owners.length; ++i) {
            uint256 id = _ids[i];
            if (isNonFungibleItem(id)) {
                balances_[i] = nfOwners[id] == _owners[i] ? 1 : 0;
            } else {
                balances_[i] = balances[id][_owners[i]];
            }
        }

        return balances_;
    }

    function setApprovalForAll(address _operator, bool _approved) external {
        operatorApproval[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return operatorApproval[_owner][_operator];
    }

    function isNonFungible(uint256 _id) public pure returns (bool) {
        return _id & TYPE_NF_BIT == TYPE_NF_BIT;
    }

    function isFungible(uint256 _id) public pure returns (bool) {
        return _id & TYPE_NF_BIT == 0;
    }

    function getNonFungibleIndex(uint256 _id) public pure returns (uint256) {
        return _id & NF_INDEX_MASK;
    }

    function getNonFungibleBaseType(uint256 _id) public pure returns (uint256) {
        return _id & TYPE_MASK;
    }

    function isNonFungibleBaseType(uint256 _id) public pure returns (bool) {
        // A base type has the NF bit but does not have an index.
        return (_id & TYPE_NF_BIT == TYPE_NF_BIT) && (_id & NF_INDEX_MASK == 0);
    }

    function isNonFungibleItem(uint256 _id) public pure returns (bool) {
        // A base type has the NF bit but does has an index.
        return (_id & TYPE_NF_BIT == TYPE_NF_BIT) && (_id & NF_INDEX_MASK != 0);
    }

    function ownerOf(uint256 _id) public view returns (address) {
        return nfOwners[_id];
    }

    /////////////////////////////////////////// ERC165 //////////////////////////////////////////////

    bytes4 private constant INTERFACE_SIGNATURE_ERC165 = 0x01ffc9a7;
    bytes4 private constant INTERFACE_SIGNATURE_ERC1155 = 0xd9b67a26;

    function supportsInterface(bytes4 _interfaceId) public view returns (bool) {
        if (
            _interfaceId == INTERFACE_SIGNATURE_ERC165 ||
            _interfaceId == INTERFACE_SIGNATURE_ERC1155
        ) {
            return true;
        }

        return false;
    }

    /////////////////////////////////////////// Internal //////////////////////////////////////////////

    function _doSafeTransferAcceptanceCheck(
        address _operator,
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes memory _data
    ) internal {
        require(
            ERC1155TokenReceiver(_to).onERC1155Received(_operator, _from, _id, _value, _data) ==
                ERC1155_ACCEPTED,
            "contract returned an unknown value from onERC1155Received"
        );
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address _operator,
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _values,
        bytes memory _data
    ) internal {
        require(
            ERC1155TokenReceiver(_to).onERC1155BatchReceived(
                _operator,
                _from,
                _ids,
                _values,
                _data
            ) == ERC1155_BATCH_ACCEPTED,
            "contract returned an unknown value from onERC1155BatchReceived"
        );
    }

    /////////////////////////////////////////// ERC1155 //////////////////////////////////////////////

    function batchAuthorizeCreators(address[] calldata _addresses) external ownerOnly {
        for (uint256 i = 0; i < _addresses.length; ++i) {
            emit Creator(_addresses[i], true);
            creators[_addresses[i]] = true;
        }
    }

    function batchDeauthorizeCreators(address[] calldata _addresses) external ownerOnly {
        for (uint256 i = 0; i < _addresses.length; ++i) {
            delete creators[_addresses[i]];
            emit Creator(_addresses[i], false);
        }
    }

    function burn(
        address _from,
        uint256[] calldata _ids,
        uint256[] calldata _values
    ) external {
        require(
            _from == msg.sender || operatorApproval[_from][msg.sender] == true,
            "Need operator approval for 3rd party burn"
        );
        require(_ids.length > 0 && _ids.length == _values.length);
        for (uint256 i = 0; i < _ids.length; i++) {
            if (isFungible(_ids[i])) {
                require(balances[_ids[i]][_from] >= _values[i]);
                balances[_ids[i]][_from] = balances[_ids[i]][_from].sub(_values[i]);
                tokenSupply[_ids[i]] = tokenSupply[_ids[i]].sub(_values[i]);
            } else {
                require(isNonFungible(_ids[i]));
                require(_values[i] == 1);
                uint256 baseType = getNonFungibleBaseType(_ids[i]);
                balances[baseType][_from] = balances[baseType][_from].sub(1);
                tokenSupply[baseType] = tokenSupply[baseType].sub(_values[i]);
                delete nfOwners[_ids[i]];
            }
            emit TransferSingle(msg.sender, _from, address(0x0), _ids[i], _values[i]);
        }
    }

    function setNewUri(string calldata _uri, uint256 _id) external creatorOnly {
        require(bytes(_uri).length > 0);
        emit URI(_uri, _id);
    }

    function updateClientName(string calldata _newClientName) external ownerOnly {
        require(bytes(_newClientName).length > 0);
        client = _newClientName;
        emit Client(_newClientName);
    }
}

pragma solidity ^0.5.0;


library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
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

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

pragma solidity ^0.5.0;


library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}

pragma solidity ^0.5.0;


contract CommonConstants {
    bytes4 internal constant ERC1155_ACCEPTED = 0xf23a6e61;
    bytes4 internal constant ERC1155_BATCH_ACCEPTED = 0xbc197c81;
}

pragma solidity ^0.5.0;


interface ERC1155TokenReceiver {
    function onERC1155Received(
        address _operator,
        address _from,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external returns (bytes4);

    function onERC1155BatchReceived(
        address _operator,
        address _from,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external returns (bytes4);
}

pragma solidity ^0.5.0;

import "./ERC165.sol";


/* is ERC165 */
interface IERC1155 {
    event TransferSingle(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256 _id,
        uint256 _value
    );
    event TransferBatch(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256[] _ids,
        uint256[] _values
    );
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event URI(string _value, uint256 indexed _id);

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external;

    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external;

    function balanceOf(address _owner, uint256 _id) external view returns (uint256);

    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids)
        external
        view
        returns (uint256[] memory);

    function setApprovalForAll(address _operator, bool _approved) external;

    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

pragma solidity ^0.5.0;


interface ERC165 {
    function supportsInterface(bytes4 _interfaceId) external view returns (bool);
}