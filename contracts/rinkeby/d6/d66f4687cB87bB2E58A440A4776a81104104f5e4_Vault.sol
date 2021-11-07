// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../lib/ERC1155/ERC1155.sol";

contract Vault is ERC1155 {
    //  ᶘಠಿᴥಠᶅ constructor
    constructor()
        ERC1155(
            "Vault",
            "ITEM",
            "ipfs://",
            "QmWxQbiwdQ5ztV4epii5fNA2BMEKvwQeNkbn4hYnQwT7VP"
        )
    {
        mint(
            msg.sender,
            1_000_000,
            "QmSHSo5zKYa3tKzx64P9py94NaTpThuh13Kszyo2LUmKbT"
        );
    }

    //  ᶘಠಿᴥಠᶅ minting
    function mint(
        address _receiver,
        uint256 _amount,
        string memory _uri
    ) public onlyOwner {
        _mint(_receiver, _amount, _uri);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../ERC165/ERC165.sol";
import "./IERC1155.sol";
import "../Address.sol";
import "./IERC1155Receiver.sol";
import "../AccessControl.sol";

contract ERC1155 is ERC165, IERC1155, AccessControl {
    // ʕಠಿᴥಠʔ libraries
    using Address for address;

    // ʕಠಿᴥಠʔ structs
    struct Account {
        mapping(uint256 => uint256) balances;
        mapping(address => bool) operators;
    }

    struct Token {
        string uri;
        uint256 totalSupply;
    }

    // ʕಠಿᴥಠʔ variables
    string public name;
    string public symbol;
    string public baseUri;
    string internal _contractUri;
    uint256 public tokenCount;
    mapping(address => Account) internal _accounts;
    mapping(uint256 => Token) internal _tokens;

    // ʕಠಿᴥಠʔ constructor
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseUri,
        string memory __contractUri
    ) {
        name = _name;
        symbol = _symbol;
        baseUri = _baseUri;
        _contractUri = __contractUri;
    }

    // ʕಠಿᴥಠʔ total supply
    function totalSupply(uint256 _id) public view returns (uint256) {
        return _tokens[_id].totalSupply;
    }

    // ʕಠಿᴥಠʔ information
    function setName(string memory _name) public onlyOwner {
        name = _name;
    }

    function setSymbol(string memory _symbol) public onlyOwner {
        symbol = _symbol;
    }

    // ʕಠಿᴥಠʔ uri
    function setBaseUri(string memory _baseUri) public onlyOwner {
        baseUri = _baseUri;
    }

    function setContractURI(string memory __contractUri) public onlyOwner {
        _contractUri = __contractUri;
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(baseUri, _contractUri));
    }

    function uri(uint256 _id) public view returns (string memory) {
        return string(abi.encodePacked(baseUri, _tokens[_id].uri));
    }

    // ʕಠಿᴥಠʔ transfer
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes calldata _data
    ) public virtual override {
        require(_to != address(0), "ERC1155: TRANSFER__toZERO_ADDRESS");

        require(
            _from == msg.sender || isApprovedForAll(_from, msg.sender),
            "ERC1155: MISSING_TOKEN_ACCESS"
        );

        _accounts[_from].balances[_id] -= _amount;
        _accounts[_to].balances[_id] += _amount;

        emit TransferSingle(msg.sender, _from, _to, _id, _amount);

        _checkSafeTransfer(msg.sender, _from, _to, _id, _amount, 30_000, _data);
    }

    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _amounts,
        bytes calldata _data
    ) public virtual override {
        require(_to != address(0), "ERC1155: TRANSFER__toZERO_ADDRESS");

        require(
            _from == msg.sender || isApprovedForAll(_from, msg.sender),
            "ERC1155: MISSING_TOKEN_ACCESS"
        );

        for (uint256 i = 0; i < _ids.length; ++i) {
            uint256 id = _ids[i];
            uint256 amount = _amounts[i];

            _accounts[_from].balances[id] -= amount;
            _accounts[_to].balances[id] += amount;
        }

        emit TransferBatch(msg.sender, _from, _to, _ids, _amounts);

        _checkBatchSafeTransfer(
            msg.sender,
            _from,
            _to,
            _ids,
            _amounts,
            30_000,
            _data
        );
    }

    // ʕಠಿᴥಠʔ balance
    function balanceOf(address _owner, uint256 _id)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _accounts[_owner].balances[_id];
    }

    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        uint256[] memory balances = new uint256[](_owners.length);
        for (uint256 i = 0; i <= _owners.length; i++) {
            balances[i] = _accounts[_owners[i]].balances[_ids[i]];
        }
        return balances;
    }

    // ʕಠಿᴥಠʔ approval
    function setApprovalForAll(address _operator, bool _approved)
        public
        virtual
        override
    {
        _accounts[msg.sender].operators[_operator] = _approved;
    }

    function isApprovedForAll(address _owner, address _operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _accounts[_owner].operators[_operator];
    }

    // ʕಠಿᴥಠʔ internal
    function _mint(
        address _receiver,
        uint256 _amount,
        string memory _uri
    ) internal {
        _accounts[_receiver].balances[tokenCount] += _amount;
        Token storage token = _tokens[tokenCount];
        token.totalSupply += _amount;
        if (
            keccak256(abi.encodePacked(token.uri)) !=
            keccak256(abi.encodePacked(_uri))
        ) token.uri = _uri;

        emit TransferSingle(
            msg.sender,
            address(0),
            _receiver,
            tokenCount,
            _amount
        );

        tokenCount++;
    }

    function _exists(uint256 _id) internal view returns (bool) {
        return _tokens[_id].totalSupply > 0;
    }

    function _checkSafeTransfer(
        address _operator,
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        uint256 _gasLimit,
        bytes calldata _data
    ) internal {
        if (_to.isContract()) {
            try
                IERC1155Receiver(_to).onERC1155Received{gas: _gasLimit}(
                    _operator,
                    _from,
                    _id,
                    _amount,
                    _data
                )
            returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155RECEIVER_REJECTED_TOKENS");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: NON_ERC1155RECEIVER_IMPLEMENTER");
            }
        }
    }

    function _checkBatchSafeTransfer(
        address _operator,
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _amounts,
        uint256 _gasLimit,
        bytes calldata _data
    ) internal {
        if (_to.isContract()) {
            try
                IERC1155Receiver(_to).onERC1155BatchReceived{gas: _gasLimit}(
                    _operator,
                    _from,
                    _ids,
                    _amounts,
                    _data
                )
            returns (bytes4 response) {
                if (
                    response != IERC1155Receiver.onERC1155BatchReceived.selector
                ) {
                    revert("ERC1155: ERC1155RECEIVER_REJECTED_BATCH_TOKENS");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: NON_ERC1155RECEIVER_IMPLEMENTER");
            }
        }
    }

    // ʕಠಿᴥಠʔ ERC165
    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(IERC165, ERC165)
        returns (bool)
    {
        return
            _interfaceId == type(IERC1155).interfaceId ||
            super.supportsInterface(_interfaceId);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC165.sol";

contract ERC165 is IERC165 {
    // ʕಠಿᴥಠʔ supportsInterface
    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _interfaceId == type(IERC165).interfaceId;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../ERC165/IERC165.sol";

interface IERC1155 is IERC165 {
    // ʕಠಿᴥಠʔ events
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

    // ʕಠಿᴥಠʔ transfer
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes calldata _data
    ) external;

    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _amounts,
        bytes calldata _data
    ) external;

    // ʕಠಿᴥಠʔ balance
    function balanceOf(address _owner, uint256 _id)
        external
        view
        returns (uint256);

    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids)
        external
        view
        returns (uint256[] memory);

    // ʕಠಿᴥಠʔ approval
    function setApprovalForAll(address _operator, bool _approved) external;

    function isApprovedForAll(address _owner, address _operator)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

library Address {
    // ʕಠಿᴥಠʔ isContract
    function isContract(address _account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_account)
        }
        return size > 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../ERC165/IERC165.sol";

interface IERC1155Receiver is IERC165 {
    // ʕಠಿᴥಠʔ received
    function onERC1155Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        uint256 _amount,
        bytes calldata _data
    ) external returns (bytes4);

    function onERC1155BatchReceived(
        address _operator,
        address _from,
        uint256[] calldata _tokenIds,
        uint256[] calldata _amounts,
        bytes calldata _data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract AccessControl {
    // ʕಠಿᴥಠʔ variables
    address internal _owner;
    mapping(address => bool) internal _operators;

    // ʕಠಿᴥಠʔ constructor
    constructor() {
        _owner = msg.sender;
    }

    // ʕಠಿᴥಠʔ owner
    function isOwner(address _account) public view returns (bool) {
        return _account == _owner;
    }

    function getOwner() public view returns (address) {
        return _owner;
    }

    function setOwner(address _newOwner) public onlyOwner {
        _owner = _newOwner;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "AccessControl: ONLY_OWNER");
        _;
    }

    // ʕಠಿᴥಠʔ operators
    function isOperator(address _account) public view returns (bool) {
        return _operators[_account];
    }

    function setOperator(address _account, bool _approved) public onlyOwner {
        _operators[_account] = _approved;
    }

    modifier onlyOperator() {
        require(isOperator(msg.sender), "AccessControl: ONLY_OPERATOR");
        _;
    }

    // ʕಠಿᴥಠʔ both
    modifier onlyOwnerOrOperator() {
        require(
            isOperator(msg.sender) || isOwner(msg.sender),
            "AccessControl: ONLY_OWNER_OR_OPERATOR"
        );
        _;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC165 {
    // ʕಠಿᴥಠʔ supportsInterface
    function supportsInterface(bytes4 _interfaceId)
        external
        view
        returns (bool);
}