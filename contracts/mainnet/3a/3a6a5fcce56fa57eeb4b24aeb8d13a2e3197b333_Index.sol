/**
 *Submitted for verification at Etherscan.io on 2021-02-02
*/

// File: contracts\index\util\IEthItemOrchestrator.sol

//SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface IEthItemOrchestrator {
    function createNative(bytes calldata modelInitPayload, string calldata ens)
        external
        returns (address newNativeAddress, bytes memory modelInitCallResponse);
}

// File: contracts\index\util\IERC1155.sol

// SPDX_License_Identifier: MIT

pragma solidity ^0.7.6;

interface IERC1155 {

    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address account, address operator) external view returns (bool);

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// File: contracts\index\util\IERC20.sol

// SPDX_License_Identifier: MIT

pragma solidity ^0.7.6;

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function decimals() external view returns (uint8);
}

// File: contracts\index\util\IEthItemInteroperableInterface.sol

// SPDX_License_Identifier: MIT

pragma solidity ^0.7.6;


interface IEthItemInteroperableInterface is IERC20 {

    function mainInterface() external view returns (address);

    function objectId() external view returns (uint256);

    function mint(address owner, uint256 amount) external;

    function burn(address owner, uint256 amount) external;

    function permitNonce(address sender) external view returns(uint256);

    function permit(address owner, address spender, uint value, uint8 v, bytes32 r, bytes32 s) external;

    function interoperableInterfaceVersion() external pure returns(uint256 ethItemInteroperableInterfaceVersion);
}

// File: contracts\index\util\IEthItem.sol

// SPDX_License_Identifier: MIT

pragma solidity ^0.7.6;



interface IEthItem is IERC1155 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function totalSupply(uint256 objectId) external view returns (uint256);

    function name(uint256 objectId) external view returns (string memory);

    function symbol(uint256 objectId) external view returns (string memory);

    function decimals(uint256 objectId) external view returns (uint256);

    function uri(uint256 objectId) external view returns (string memory);

    function mainInterfaceVersion() external pure returns(uint256 ethItemInteroperableVersion);

    function toInteroperableInterfaceAmount(uint256 objectId, uint256 ethItemAmount) external view returns (uint256 interoperableInterfaceAmount);

    function toMainInterfaceAmount(uint256 objectId, uint256 erc20WrapperAmount) external view returns (uint256 mainInterfaceAmount);

    function interoperableInterfaceModel() external view returns (address, uint256);

    function asInteroperable(uint256 objectId) external view returns (IEthItemInteroperableInterface);

    function emitTransferSingleEvent(address sender, address from, address to, uint256 objectId, uint256 amount) external;

    function mint(uint256 amount, string calldata partialUri)
        external
        returns (uint256, address);

    function burn(
        uint256 objectId,
        uint256 amount
    ) external;

    function burnBatch(
        uint256[] calldata objectIds,
        uint256[] calldata amounts
    ) external;
}

// File: contracts\index\util\INativeV1.sol

//SPDX_License_Identifier: MIT

pragma solidity ^0.7.6;


interface INativeV1 is IEthItem {

    function init(string calldata name, string calldata symbol, bool hasDecimals, string calldata collectionUri, address extensionAddress, bytes calldata extensionInitPayload) external returns(bytes memory extensionInitCallResponse);

    function extension() external view returns (address extensionAddress);

    function canMint(address operator) external view returns (bool result);

    function isEditable(uint256 objectId) external view returns (bool result);

    function releaseExtension() external;

    function uri() external view returns (string memory);

    function decimals() external view returns (uint256);

    function mint(uint256 amount, string calldata tokenName, string calldata tokenSymbol, string calldata objectUri, bool editable) external returns (uint256 objectId, address tokenAddress);

    function mint(uint256 amount, string calldata tokenName, string calldata tokenSymbol, string calldata objectUri) external returns (uint256 objectId, address tokenAddress);

    function mint(uint256 objectId, uint256 amount) external;

    function makeReadOnly(uint256 objectId) external;

    function setUri(string calldata newUri) external;

    function setUri(uint256 objectId, string calldata newUri) external;
}

// File: contracts\index\util\ERC1155Receiver.sol

// SPDX_License_Identifier: MIT

pragma solidity ^0.7.6;

abstract contract ERC1155Receiver {
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor() {
        _registerInterface(_INTERFACE_ID_ERC165);
        _registerInterface(
            ERC1155Receiver(0).onERC1155Received.selector ^
            ERC1155Receiver(0).onERC1155BatchReceived.selector
        );
    }

    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        virtual
        returns(bytes4);

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        virtual
        returns(bytes4);
}

// File: contracts\index\util\DFOHub.sol

// SPDX_License_Identifier: MIT

pragma solidity ^0.7.6;

interface IDoubleProxy {
    function proxy() external view returns (address);
}

interface IMVDProxy {
    function getMVDFunctionalitiesManagerAddress() external view returns(address);
    function getMVDWalletAddress() external view returns (address);
    function getStateHolderAddress() external view returns(address);
    function submit(string calldata codeName, bytes calldata data) external payable returns(bytes memory returnData);
}

interface IMVDFunctionalitiesManager {
    function getFunctionalityData(string calldata codeName) external view returns(address, uint256, string memory, address, uint256);
    function isAuthorizedFunctionality(address functionality) external view returns(bool);
}

interface IStateHolder {
    function getUint256(string calldata name) external view returns(uint256);
    function getAddress(string calldata name) external view returns(address);
    function clear(string calldata varName) external returns(string memory oldDataType, bytes memory oldVal);
}

// File: contracts\index\Index.sol

//SPDX_License_Identifier: MIT

pragma solidity ^0.7.6;
pragma abicoder v2;





contract Index is ERC1155Receiver {

    address public _doubleProxy;

    mapping(address => bool) _temporaryIndex;

    event NewIndex(uint256 indexed id, address indexed interoperableInterfaceAddress, address indexed token, uint256 amount);

    address public collection;

    mapping(uint256 => address[]) public tokens;
    mapping(uint256 => uint256[]) public amounts;

    constructor(address doubleProxy, address ethItemOrchestrator, string memory name, string memory symbol, string memory uri) {
        _doubleProxy = doubleProxy;
        (collection,) = IEthItemOrchestrator(ethItemOrchestrator).createNative(abi.encodeWithSignature("init(string,string,bool,string,address,bytes)", name, symbol, true, uri, address(this), ""), "");
    }

    modifier onlyDFO() {
        require(IMVDFunctionalitiesManager(IMVDProxy(IDoubleProxy(_doubleProxy).proxy()).getMVDFunctionalitiesManagerAddress()).isAuthorizedFunctionality(msg.sender), "Unauthorized");
        _;
    }

    function setDoubleProxy(address newDoubleProxy) public onlyDFO {
        _doubleProxy = newDoubleProxy;
    }

    function setCollectionUri(string memory uri) public onlyDFO {
        INativeV1(collection).setUri(uri);
    }

    function info(uint256 objectId, uint256 value) public view returns(address[] memory _tokens, uint256[] memory _amounts) {
        uint256 amount = value == 0 ? 1e18 : value;
        _tokens = tokens[objectId];
        _amounts = new uint256[](_tokens.length);
        for(uint256 i = 0; i < _amounts.length; i++) {
            _amounts[i] = (amounts[objectId][i] * amount) / 1e18;
        }
    }

    function mint(string memory name, string memory symbol, string memory uri, address[] memory _tokens, uint256[] memory _amounts, uint256 value, address receiver) public payable returns(uint256 objectId, address interoperableInterfaceAddress) {
        require(_tokens.length > 0 && _tokens.length == _amounts.length, "invalid length");
        for(uint256 i = 0; i < _tokens.length; i++) {
            require(!_temporaryIndex[_tokens[i]], "already done");
            require(_amounts[i] > 0, "amount");
            _temporaryIndex[_tokens[i]] = true;
            if(value > 0) {
                uint256 tokenValue = (_amounts[i] * value) / 1e18;
                require(tokenValue > 0, "Insufficient balance");
                if(_tokens[i] == address(0)) {
                    require(msg.value == tokenValue, "insufficient eth");
                } else {
                    _safeTransferFrom(_tokens[i], msg.sender, address(this), tokenValue);
                }
            }
        }
        require(_temporaryIndex[address(0)] || msg.value == 0, "eth not involved");
        INativeV1 theCollection = INativeV1(collection);
        (objectId, interoperableInterfaceAddress) = theCollection.mint(value == 0 ? 1e18 : value, name, symbol, uri, true);
        tokens[objectId] = _tokens;
        amounts[objectId] = _amounts;
        if(value == 0) {
            theCollection.burn(objectId, theCollection.balanceOf(address(this), objectId));
        } else {
            _safeTransfer(interoperableInterfaceAddress, receiver == address(0) ? msg.sender : receiver, theCollection.toInteroperableInterfaceAmount(objectId, theCollection.balanceOf(address(this), objectId)));
        }
        for(uint256 i = 0; i < _tokens.length; i++) {
            delete _temporaryIndex[_tokens[i]];
            emit NewIndex(objectId, interoperableInterfaceAddress, _tokens[i], _amounts[i]);
        }
    }

    function mint(uint256 objectId, uint256 value, address receiver) public payable {
        require(value > 0, "value");
        bool ethInvolved = false;
        for(uint256 i = 0; i < tokens[objectId].length; i++) {
            uint256 tokenValue = (amounts[objectId][i] * value) / 1e18;
            require(tokenValue > 0, "Insufficient balance");
            if(tokens[objectId][i] == address(0)) {
                ethInvolved = true;
                 require(msg.value == tokenValue, "insufficient eth");
            } else {
                _safeTransferFrom(tokens[objectId][i], msg.sender, address(this), tokenValue);
            }
        }
        require(ethInvolved || msg.value == 0, "eth not involved");
        INativeV1 theCollection = INativeV1(collection);
        theCollection.mint(objectId, value);
        _safeTransfer(address(theCollection.asInteroperable(objectId)), receiver == address(0) ? msg.sender : receiver, theCollection.toInteroperableInterfaceAmount(objectId, theCollection.balanceOf(address(this), objectId)));
    }

    function onERC1155Received(
        address,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        public
        override
        returns(bytes4) {
            require(msg.sender == collection, "Only Index collection allowed here");
            _onSingleReceived(from, id, value, data);
            return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address from,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    )
        public
        override
        returns(bytes4) {

        require(msg.sender == collection, "Only Index collection allowed here");
        bytes[] memory payloads = abi.decode(data, (bytes[]));
        require(payloads.length == ids.length, "Wrong payloads length");
        for(uint256 i = 0; i < ids.length; i++) {
            _onSingleReceived(from, ids[i], values[i], payloads[i]);
        }
        return this.onERC1155BatchReceived.selector;
    }

    function _onSingleReceived(
        address from,
        uint256 objectId,
        uint256 value,
        bytes memory data) private {
            address receiver = data.length == 0 ? from : abi.decode(data, (address));
            receiver = receiver == address(0) ? from : receiver;
            INativeV1 theCollection = INativeV1(collection);
            theCollection.burn(objectId, value);
            for(uint256 i = 0; i < tokens[objectId].length; i++) {
                uint256 tokenValue = (amounts[objectId][i] * value) / 1e18;
                if(tokens[objectId][i] == address(0)) {
                    payable(receiver).transfer(tokenValue);
                } else {
                    _safeTransfer(tokens[objectId][i], receiver, tokenValue);
                }
            }
    }

    function _safeApprove(address erc20TokenAddress, address to, uint256 value) internal {
        bytes memory returnData = _call(erc20TokenAddress, abi.encodeWithSelector(IERC20(erc20TokenAddress).approve.selector, to, value));
        require(returnData.length == 0 || abi.decode(returnData, (bool)), 'APPROVE_FAILED');
    }

    function _safeTransfer(address erc20TokenAddress, address to, uint256 value) internal {
        bytes memory returnData = _call(erc20TokenAddress, abi.encodeWithSelector(IERC20(erc20TokenAddress).transfer.selector, to, value));
        require(returnData.length == 0 || abi.decode(returnData, (bool)), 'TRANSFER_FAILED');
    }

    function _safeTransferFrom(address erc20TokenAddress, address from, address to, uint256 value) private {
        bytes memory returnData = _call(erc20TokenAddress, abi.encodeWithSelector(IERC20(erc20TokenAddress).transferFrom.selector, from, to, value));
        require(returnData.length == 0 || abi.decode(returnData, (bool)), 'TRANSFERFROM_FAILED');
    }

    function _call(address location, bytes memory payload) private returns(bytes memory returnData) {
        assembly {
            let result := call(gas(), location, 0, add(payload, 0x20), mload(payload), 0, 0)
            let size := returndatasize()
            returnData := mload(0x40)
            mstore(returnData, size)
            let returnDataPayloadStart := add(returnData, 0x20)
            returndatacopy(returnDataPayloadStart, 0, size)
            mstore(0x40, add(returnDataPayloadStart, size))
            switch result case 0 {revert(returnDataPayloadStart, size)}
        }
    }
}