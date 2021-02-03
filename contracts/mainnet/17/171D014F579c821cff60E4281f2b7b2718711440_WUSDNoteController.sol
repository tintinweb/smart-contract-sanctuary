/**
 *Submitted for verification at Etherscan.io on 2021-02-03
*/

// File: contracts\WUSD\util\ERC1155Receiver.sol

// SPDX-License-Identifier: MIT

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

// File: contracts\WUSD\util\IERC1155.sol

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

// File: contracts\WUSD\util\IERC20.sol

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

// File: contracts\WUSD\util\IEthItemInteroperableInterface.sol

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

// File: contracts\WUSD\util\IEthItem.sol

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

// File: contracts\WUSD\util\INativeV1.sol

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

// File: contracts\WUSD\IWUSDNoteController.sol

//SPDX_License_Identifier: MIT

pragma solidity ^0.7.6;


interface IWUSDNoteController {

    function wusdCollection() external view returns(address);
    function wusdObjectId() external view returns(uint256);
    function wusdNoteObjectId() external view returns(uint256);
    function multiplier() external view returns(uint256);

    function info() external view returns(address, uint256, uint256, uint256);

    function init(address _wusdCollection, uint256 _wusdObjectId, uint256 _wusdNoteObjectId, uint256 _multiplier) external;
}

// File: contracts\WUSD\WUSDNoteController.sol

//SPDX_License_Identifier: MIT

pragma solidity ^0.7.6;




contract WUSDNoteController is IWUSDNoteController, ERC1155Receiver {

    address public override wusdCollection;
    uint256 public override wusdObjectId;
    uint256 public override wusdNoteObjectId;
    uint256 public override multiplier;

    function init(address _wusdCollection, uint256 _wusdObjectId, uint256 _wusdNoteObjectId, uint256 _multiplier) public override {
        require(wusdCollection == address(0), "Already init");
        wusdCollection = _wusdCollection;
        wusdObjectId = _wusdObjectId;
        wusdNoteObjectId = _wusdNoteObjectId;
        multiplier = _multiplier;
    }

    function info() public override view returns(address, uint256, uint256, uint256) {
        return (wusdCollection, wusdObjectId, wusdNoteObjectId, multiplier);
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
            require(msg.sender == wusdCollection, "Only WUSD collection allowed here");
            uint256[] memory usdIds = new uint256[](ids.length);
            uint256[] memory usdValues = new uint256[](ids.length);
            for(uint256 i = 0; i < ids.length; i++) {
                require(ids[i] == wusdNoteObjectId, "Only WUSD Note allowed here");
                usdIds[i] = wusdObjectId;
                usdValues[i] = values[i] * multiplier;
            }
            INativeV1 collection = INativeV1(wusdCollection);
            collection.burnBatch(ids, values);
            collection.safeBatchTransferFrom(address(this), from, usdIds, usdValues, data);
            return this.onERC1155BatchReceived.selector;
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
            require(msg.sender == wusdCollection, "Only WUSD collection allowed here");
            require(id == wusdNoteObjectId, "Only WUSD Note allowed here");
            INativeV1 collection = INativeV1(wusdCollection);
            collection.burn(id, value);
            collection.safeTransferFrom(address(this), from, wusdObjectId, value * multiplier, data);
            return this.onERC1155Received.selector;
    }
}