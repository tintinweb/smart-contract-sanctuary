/**
 *Submitted for verification at Etherscan.io on 2021-02-03
*/

// File: contracts\WUSD\util\IEthItemOrchestrator.sol

//SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface IEthItemOrchestrator {
    function createNative(bytes calldata modelInitPayload, string calldata ens)
        external
        returns (address newNativeAddress, bytes memory modelInitCallResponse);
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

// File: contracts\amm-aggregator\common\AMMData.sol

//SPDX_License_Identifier: MIT
pragma solidity ^0.7.6;

struct LiquidityPoolData {
    address liquidityPoolAddress;
    uint256 amount;
    address tokenAddress;
    bool amountIsLiquidityPool;
    bool involvingETH;
    address receiver;
}

struct SwapData {
    bool enterInETH;
    bool exitInETH;
    address[] liquidityPoolAddresses;
    address[] path;
    address inputToken;
    uint256 amount;
    address receiver;
}

// File: contracts\amm-aggregator\common\IAMM.sol

//SPDX_License_Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;


interface IAMM {

    event NewLiquidityPoolAddress(address indexed);

    function info() external view returns(string memory name, uint256 version);

    function data() external view returns(address ethereumAddress, uint256 maxTokensPerLiquidityPool, bool hasUniqueLiquidityPools);

    function balanceOf(address liquidityPoolAddress, address owner) external view returns(uint256, uint256[] memory, address[] memory);

    function byLiquidityPool(address liquidityPoolAddress) external view returns(uint256, uint256[] memory, address[] memory);

    function byTokens(address[] calldata liquidityPoolTokens) external view returns(uint256, uint256[] memory, address, address[] memory);

    function byPercentage(address liquidityPoolAddress, uint256 numerator, uint256 denominator) external view returns (uint256, uint256[] memory, address[] memory);

    function byLiquidityPoolAmount(address liquidityPoolAddress, uint256 liquidityPoolAmount) external view returns(uint256[] memory, address[] memory);

    function byTokenAmount(address liquidityPoolAddress, address tokenAddress, uint256 tokenAmount) external view returns(uint256, uint256[] memory, address[] memory);

    function createLiquidityPoolAndAddLiquidity(address[] calldata tokenAddresses, uint256[] calldata amounts, bool involvingETH, address receiver) external payable returns(uint256, uint256[] memory, address, address[] memory);

    function addLiquidity(LiquidityPoolData calldata data) external payable returns(uint256, uint256[] memory, address[] memory);
    function addLiquidityBatch(LiquidityPoolData[] calldata data) external payable returns(uint256[] memory, uint256[][] memory, address[][] memory);

    function removeLiquidity(LiquidityPoolData calldata data) external returns(uint256, uint256[] memory, address[] memory);
    function removeLiquidityBatch(LiquidityPoolData[] calldata data) external returns(uint256[] memory, uint256[][] memory, address[][] memory);

    function getSwapOutput(address tokenAddress, uint256 tokenAmount, address[] calldata, address[] calldata path) view external returns(uint256[] memory);

    function swapLiquidity(SwapData calldata data) external payable returns(uint256);
    function swapLiquidityBatch(SwapData[] calldata data) external payable returns(uint256[] memory);
}

// File: contracts\WUSD\AllowedAMM.sol

//SPDX_License_Identifier: MIT

pragma solidity ^0.7.6;

struct AllowedAMM {
    address ammAddress;
    address[] liquidityPools;
}

// File: contracts\WUSD\WUSDExtension.sol

//SPDX_License_Identifier: MIT

pragma solidity ^0.7.6;
//pragma abicoder v2;






contract WUSDExtension {

    uint256 private constant DECIMALS = 18;

    address private _controller;

    address private _collection;

    uint256 private _mainItemObjectId;
    address private _mainItemInteroperableAddress;

    constructor(address orchestrator, string memory name, string memory symbol, string memory collectionUri, string memory mainItemName, string memory mainItemSymbol, string memory mainItemUri) {
        _controller = msg.sender;
        (_collection,) = IEthItemOrchestrator(orchestrator).createNative(abi.encodeWithSignature("init(string,string,bool,string,address,bytes)", name, symbol, true, collectionUri, address(this), ""), "");
        (_mainItemObjectId, _mainItemInteroperableAddress) = _mintEmpty(mainItemName, mainItemSymbol, mainItemUri, true);
    }

    function collection() public view returns (address) {
        return _collection;
    }

    function data() public view returns (address, uint256, address) {
        return (_collection, _mainItemObjectId, _mainItemInteroperableAddress);
    }

    function controller() public view returns (address) {
        return _controller;
    }

    modifier controllerOnly() {
        require(msg.sender == _controller, "Unauthorized action");
        _;
    }

    function mintEmpty(string memory tokenName, string memory tokenSymbol, string memory objectUri, bool editable) public controllerOnly returns(uint256 objectId, address interoperableInterfaceAddress) {
        return _mintEmpty(tokenName, tokenSymbol, objectUri, editable);
    }

    function _mintEmpty(string memory tokenName, string memory tokenSymbol, string memory objectUri, bool editable) private returns(uint256 objectId, address interoperableInterfaceAddress) {
        INativeV1 theCollection = INativeV1(_collection);
        (objectId, interoperableInterfaceAddress) = theCollection.mint(10**18, tokenName, tokenSymbol, objectUri, editable);
        theCollection.burn(objectId, theCollection.balanceOf(address(this), objectId));
    }

    function setCollectionUri(string memory uri) public controllerOnly {
        INativeV1(_collection).setUri(uri);
    }

    function setItemUri(uint256 existingObjectId, string memory uri) public controllerOnly {
        INativeV1(_collection).setUri(existingObjectId, uri);
    }

    function makeReadOnly(uint256 objectId) public controllerOnly {
        INativeV1(_collection).makeReadOnly(objectId);
    }

    function mintFor(address ammPlugin, address liquidityPoolAddress, uint256 liquidityPoolAmount, address receiver) public controllerOnly {
        _safeTransferFrom(liquidityPoolAddress, msg.sender, address(this), liquidityPoolAmount);
        _mint(_mainItemObjectId, _normalizeAndSumAmounts(ammPlugin, liquidityPoolAddress, liquidityPoolAmount), receiver);
    }

    function mintForRebalanceByCredit(AllowedAMM[] memory amms) public controllerOnly returns(uint256 credit) {
        uint256 totalSupply = INativeV1(_collection).totalSupply(_mainItemObjectId);
        for(uint256 i = 0; i < amms.length; i++) {
            for(uint256 j = 0; j < amms[i].liquidityPools.length; j++) {
                credit += _normalizeAndSumAmounts(amms[i].ammAddress, amms[i].liquidityPools[j], IERC20(amms[i].liquidityPools[j]).balanceOf(address(this)));
            }
        }
        require(credit > totalSupply, "No credit");
        _mint(_mainItemObjectId, credit = (credit - totalSupply), msg.sender);
    }

    function burnFor(uint256 objectId, uint256 value, address receiver) public controllerOnly {
        _safeTransferFrom(_mainItemInteroperableAddress, msg.sender, address(this), INativeV1(_collection).toInteroperableInterfaceAmount(_mainItemObjectId, value));
        INativeV1(_collection).burn(_mainItemObjectId, value);
        _mint(objectId, value, receiver);
    }

    function _mint(uint256 objectId, uint256 amount, address receiver) private {
        INativeV1(_collection).mint(objectId, amount);
        INativeV1(_collection).safeTransferFrom(address(this), receiver, objectId, INativeV1(_collection).balanceOf(address(this), objectId), "");
    }

    function burnFor(address from, uint256 value, address ammPlugin, address liquidityPoolAddress, uint256 liquidityPoolAmount, address liquidityPoolReceiver) public controllerOnly {
        _safeTransferFrom(_mainItemInteroperableAddress, msg.sender, address(this), INativeV1(_collection).toInteroperableInterfaceAmount(_mainItemObjectId, value));
        uint256 toBurn = _normalizeAndSumAmounts(ammPlugin, liquidityPoolAddress, liquidityPoolAmount);
        require(value >= toBurn, "Insufficient Amount");
        if(value > toBurn) {
            INativeV1(_collection).safeTransferFrom(address(this), from, _mainItemObjectId, value - toBurn, "");
        }
        INativeV1(_collection).burn(_mainItemObjectId, toBurn);
        _safeTransfer(liquidityPoolAddress, liquidityPoolReceiver, liquidityPoolAmount);
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

    function _normalizeAndSumAmounts(address ammPlugin, address liquidityPoolAddress, uint256 liquidityPoolAmount)
        private
        view
        returns(uint256 amount) {
            IERC20 liquidityPool = IERC20(liquidityPoolAddress);
            (uint256[] memory amounts, address[] memory tokens) = IAMM(ammPlugin).byLiquidityPoolAmount(address(liquidityPool), liquidityPoolAmount);
            for(uint256 i = 0; i < amounts.length; i++) {
                amount += _normalizeTokenAmountToDefaultDecimals(tokens[i], amounts[i]);
            }
    }

    function _normalizeTokenAmountToDefaultDecimals(address tokenAddress, uint256 amount) internal virtual view returns(uint256) {
        uint256 remainingDecimals = DECIMALS;
        IERC20 token = IERC20(tokenAddress);
        remainingDecimals -= token.decimals();

        if(remainingDecimals == 0) {
            return amount;
        }

        return amount * (remainingDecimals == 0 ? 1 : (10**remainingDecimals));
    }
}

// File: contracts\WUSD\util\DFOHub.sol

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
    function isAuthorizedFunctionality(address functionality) external view returns(bool);
}

interface IStateHolder {
    function getUint256(string calldata name) external view returns(uint256);
    function getAddress(string calldata name) external view returns(address);
    function clear(string calldata varName) external returns(string memory oldDataType, bytes memory oldVal);
}

// File: contracts\WUSD\util\ERC1155Receiver.sol

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

// File: contracts\WUSD\util\IERC20WrapperV1.sol

//SPDX_License_Identifier: MIT

pragma solidity ^0.7.6;


interface IERC20WrapperV1 is IEthItem {

    function source(uint256 objectId) external view returns (address erc20TokenAddress);

    function object(address erc20TokenAddress) external view returns (uint256 objectId);

    function mint(address erc20TokenAddress, uint256 amount) external returns (uint256 objectId, address wrapperAddress);

    function mintETH() external payable returns (uint256 objectId, address wrapperAddress);
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

// File: contracts\WUSD\IWUSDExtensionController.sol

//SPDX_License_Identifier: MIT

pragma solidity ^0.7.6;
//pragma abicoder v2;

interface IWUSDExtensionController {

    function rebalanceByCreditBlockInterval() external view returns(uint256);

    function lastRebalanceByCreditBlock() external view returns(uint256);

    function wusdInfo() external view returns (address, uint256, address);
}

// File: contracts\WUSD\WUSDExtensionController.sol

//SPDX_License_Identifier: MIT

pragma solidity ^0.7.6;
//pragma abicoder v2;












contract WUSDExtensionController is IWUSDExtensionController, ERC1155Receiver {

    uint256 public constant ONE_HUNDRED = 1e18;

    uint256 private constant DECIMALS = 18;

    address private _doubleProxy;

    uint256 public override rebalanceByCreditBlockInterval;

    address private _extension;

    address private _collection;

    uint256 private _wusdObjectId;
    address private _wusdInteroperableInterfaceAddress;

    uint256 private _wusdNote2ObjectId;
    address private _wusdNote2InteroperableInterfaceAddress;
    address private _wusdNote2Controller;
    uint256 private _wusdNote2Percentage;

    uint256 private _wusdNote5ObjectId;
    address private _wusdNote5InteroperableInterfaceAddress;
    address private _wusdNote5Controller;
    uint256 private _wusdNote5Percentage;

    uint256 public override lastRebalanceByCreditBlock;

    AllowedAMM[] private _allowedAMMs;

    uint256[] private _rebalanceByCreditPercentages;

    address[] private _rebalanceByCreditReceivers;

    uint256 private _rebalanceByCreditPercentageForCaller;

    struct WUSDInitializer {
        address doubleProxyAddress;
        address[] rebalanceByCreditReceivers;
        uint256[] rebalanceByCreditPercentages;
        uint256 rebalanceByCreditPercentageForCaller;
        uint256 rebalanceByCreditBlockInterval;
        bytes allowedAMMsBytes;
        address wusdExtension;
        uint256 wusdNote2ObjectId;
        address wusdNote2Controller;
        uint256 wusdNote2Percentage;
        uint256 wusdNote5ObjectId;
        address wusdNote5Controller;
        uint256 wusdNote5Percentage;
        address orchestratorAddress;
        string[] names;
        string[] symbols;
        string[] uris;
    }

    constructor(bytes memory wusdInitializerBytes) {
        WUSDInitializer memory wusdInitializer = abi.decode(wusdInitializerBytes, (WUSDInitializer));
        _doubleProxy = wusdInitializer.doubleProxyAddress;
        rebalanceByCreditBlockInterval = wusdInitializer.rebalanceByCreditBlockInterval;
        WUSDExtension wusdExtension = WUSDExtension(_extension = wusdInitializer.wusdExtension != address(0) ? wusdInitializer.wusdExtension : address(new WUSDExtension(wusdInitializer.orchestratorAddress, wusdInitializer.names[0], wusdInitializer.symbols[0], wusdInitializer.uris[0], wusdInitializer.names[1], wusdInitializer.symbols[1], wusdInitializer.uris[1])));
        (_collection, _wusdObjectId, _wusdInteroperableInterfaceAddress) = wusdExtension.data();
        if(wusdInitializer.wusdNote2ObjectId != 0) {
            _wusdNote2InteroperableInterfaceAddress = address(INativeV1(_collection).asInteroperable(_wusdNote2ObjectId = wusdInitializer.wusdNote2ObjectId));
            _checkNoteController(_wusdNote2Controller = wusdInitializer.wusdNote2Controller, _wusdNote2ObjectId, 2);
        }
        if(wusdInitializer.wusdNote5ObjectId != 0) {
            _wusdNote5InteroperableInterfaceAddress = address(INativeV1(_collection).asInteroperable(_wusdNote5ObjectId = wusdInitializer.wusdNote5ObjectId));
            _checkNoteController(_wusdNote5Controller = wusdInitializer.wusdNote5Controller, _wusdNote5ObjectId, 5);
        }
        _wusdNote2Percentage = wusdInitializer.wusdNote2Percentage;
        _wusdNote5Percentage = wusdInitializer.wusdNote5Percentage;
        _setRebalanceByCreditData(wusdInitializer.rebalanceByCreditReceivers, wusdInitializer.rebalanceByCreditPercentages, wusdInitializer.rebalanceByCreditPercentageForCaller);
        _setAllowedAMMs(wusdInitializer.allowedAMMsBytes);
    }

    function initNotes(address[] memory controllers, string[] memory names, string[] memory symbols, string[] memory uris) public {
        require(_wusdNote2InteroperableInterfaceAddress == address(0), "already init");
        WUSDExtension wusdExtension = WUSDExtension(_extension);
        (_wusdNote2ObjectId, _wusdNote2InteroperableInterfaceAddress) = wusdExtension.mintEmpty(names[0], symbols[0], uris[0], true);
        (_wusdNote5ObjectId, _wusdNote5InteroperableInterfaceAddress) = wusdExtension.mintEmpty(names[1], symbols[1], uris[1], true);
        IWUSDNoteController(_wusdNote2Controller = controllers[0]).init(_collection, _wusdObjectId, _wusdNote2ObjectId, 2);
        IWUSDNoteController(_wusdNote5Controller = controllers[1]).init(_collection, _wusdObjectId, _wusdNote5ObjectId, 5);
    }

    receive() external payable {
    }

    function _checkNoteController(address noteController, uint256 wusdNoteObjectIdInput, uint256 multiplierInput) private {
        (address collectionAddress, uint256 wusdObjectId, uint256 wusdNoteObjectId, uint256 multiplier) = IWUSDNoteController(noteController).info();
        if(collectionAddress == address(0)) {
            IWUSDNoteController(noteController).init(_collection, _wusdObjectId, wusdNoteObjectIdInput, multiplierInput);
            (collectionAddress, wusdObjectId, wusdNoteObjectId, multiplier) = IWUSDNoteController(noteController).info();
        }
        require(collectionAddress == _collection, "Wrong collection");
        require(wusdObjectId == _wusdObjectId, "Wrong WUSD Object Id");
        require(wusdNoteObjectId == wusdNoteObjectIdInput, "Wrong WUSD Note Object Id");
        require(multiplier == multiplierInput, "Wrong WUSD Note multiplier");
    }

    function _setRebalanceByCreditData(address[] memory rebalanceByCreditReceivers, uint256[] memory rebalanceByCreditPercentages, uint256 rebalanceByCreditPercentageForCaller) private {
        require((_rebalanceByCreditPercentages = rebalanceByCreditPercentages).length == (_rebalanceByCreditReceivers = rebalanceByCreditReceivers).length, "Invalid lengths");
        uint256 percentage = _rebalanceByCreditPercentageForCaller = rebalanceByCreditPercentageForCaller + _wusdNote2Percentage + _wusdNote5Percentage;
        for(uint256 i = 0; i < rebalanceByCreditReceivers.length; i++) {
            require(rebalanceByCreditReceivers[i] != address(0), "Void address");
            require(rebalanceByCreditPercentages[i] > 0, "Zero percentage");
            percentage += rebalanceByCreditPercentages[i];
        }
        require(percentage <= ONE_HUNDRED, "More than one hundred");
        _rebalanceByCreditPercentages = rebalanceByCreditPercentages;
        _rebalanceByCreditReceivers = rebalanceByCreditReceivers;
    }

    function _setAllowedAMMs(bytes memory data) private {
        AllowedAMM[] memory amms = abi.decode(data, (AllowedAMM[]));
        delete _allowedAMMs;
        for(uint256 i = 0; i < amms.length; i++) {
            _allowedAMMs.push(amms[i]);
        }
    }

    function doubleProxy() public view returns (address) {
        return _doubleProxy;
    }

    function extension() public view returns (address) {
        return _extension;
    }

    function collection() public view returns (address) {
        return _collection;
    }

    function wusdInfo() public override view returns (address, uint256, address) {
        return (_collection, _wusdObjectId, _wusdInteroperableInterfaceAddress);
    }

    function wusdNote2Info() public view returns (address, uint256, address, address, uint256) {
        return (_collection, _wusdNote2ObjectId, _wusdNote2InteroperableInterfaceAddress, _wusdNote2Controller, _wusdNote2Percentage);
    }

    function wusdNote5Info() public view returns (address, uint256, address, address, uint256) {
        return (_collection, _wusdNote5ObjectId, _wusdNote5InteroperableInterfaceAddress, _wusdNote5Controller, _wusdNote5Percentage);
    }

    function rebalanceByCreditReceiversInfo() public view returns (address[] memory, uint256[] memory, uint256, address) {
        return (_rebalanceByCreditReceivers, _rebalanceByCreditPercentages, _rebalanceByCreditPercentageForCaller, IMVDProxy(IDoubleProxy(_doubleProxy).proxy()).getMVDWalletAddress());
    }

    modifier byDFO virtual {
        require(_isFromDFO(msg.sender), "Unauthorized action");
        _;
    }

    function _isFromDFO(address sender) private view returns(bool) {
        return IMVDFunctionalitiesManager(IMVDProxy(IDoubleProxy(_doubleProxy).proxy()).getMVDFunctionalitiesManagerAddress()).isAuthorizedFunctionality(sender);
    }

    function setDoubleProxy(address newDoubleProxy) public byDFO {
        _doubleProxy = newDoubleProxy;
    }

    function setRebalanceByCreditData(address[] memory rebalanceByCreditReceivers, uint256[] memory rebalanceByCreditPercentages, uint256 rebalanceByCreditPercentageForCaller) public byDFO {
        _setRebalanceByCreditData(rebalanceByCreditReceivers, rebalanceByCreditPercentages, rebalanceByCreditPercentageForCaller);
    }

    function setCollectionUri(string memory uri) public byDFO {
        WUSDExtension(_extension).setCollectionUri(uri);
    }

    function setItemUri(uint256 existingObjectId, string memory uri) public byDFO {
        WUSDExtension(_extension).setItemUri(existingObjectId, uri);
    }

    function setrebalanceByCreditBlockInterval(uint256 newrebalanceByCreditBlockInterval) public byDFO {
        rebalanceByCreditBlockInterval = newrebalanceByCreditBlockInterval;
    }

    function allowedAMMs() public view returns(AllowedAMM[] memory) {
        return _allowedAMMs;
    }

    function setAllowedAMMs(AllowedAMM[] memory newAllowedAMMs) public byDFO {
        _setAllowedAMMs(abi.encode(newAllowedAMMs));
    }

    function differences()
        public
        view
        returns (uint256 credit, uint256 debt)
    {
        uint256 totalSupply = INativeV1(_collection).totalSupply(_wusdObjectId);
        uint256 effectiveAmount = 0;
        for(uint256 i = 0; i < _allowedAMMs.length; i++) {
            for(uint256 j = 0; j < _allowedAMMs[i].liquidityPools.length; j++) {
                effectiveAmount += _normalizeAndSumAmounts(i, j, 0);
            }
        }
        credit = effectiveAmount > totalSupply
            ? effectiveAmount - totalSupply
            : 0;
        debt = totalSupply > effectiveAmount
            ? totalSupply - effectiveAmount
            : 0;
    }

    function fromTokenToStable(address tokenAddress, uint256 amount)
        public
        view
        returns (uint256)
    {
        IERC20 token = IERC20(tokenAddress);
        uint256 tokenDecimals = token.decimals();
        uint256 remainingDecimals = DECIMALS - tokenDecimals;
        uint256 result = amount == 0 ? token.balanceOf(_extension) : amount;
        if (remainingDecimals == 0) {
            return result;
        }
        return result * 10**remainingDecimals;
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
            require(msg.sender == _collection, "Only WUSD collection allowed here");
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

        require(msg.sender == _collection, "Only WUSD collection allowed here");
        bytes[] memory payloads = abi.decode(data, (bytes[]));
        require(payloads.length == ids.length, "Wrong payloads length");
        for(uint256 i = 0; i < ids.length; i++) {
            _onSingleReceived(from, ids[i], values[i], payloads[i]);
        }
        return this.onERC1155BatchReceived.selector;
    }

    function _onSingleReceived(
        address from,
        uint256 id,
        uint256 value,
        bytes memory data) private {
            require(id == _wusdObjectId, "Only WUSD id allowed here");
            if(from == _extension) {
                return;
            }
            (uint256 action, bytes memory payload) = abi.decode(data, (uint256, bytes));
            if(action == 1) {
                _rebalanceByDebt(from, value, payload);
            } else {
                _burn(from, value, payload);
            }
    }

    function _burn(address from, uint256 value, bytes memory payload) private {
        (uint256 ammPosition, uint256 liquidityPoolPosition, uint256 liquidityPoolAmount, bool keepLiquidityPool) = abi.decode(payload, (uint256, uint256, uint256, bool));
        _safeApprove(_wusdInteroperableInterfaceAddress, _extension, INativeV1(_collection).toInteroperableInterfaceAmount(_wusdObjectId, value));
        WUSDExtension(_extension).burnFor(from, value, _allowedAMMs[ammPosition].ammAddress, _allowedAMMs[ammPosition].liquidityPools[liquidityPoolPosition], liquidityPoolAmount, keepLiquidityPool ? from : address(this));
        if(!keepLiquidityPool) {
            IAMM amm = IAMM(_allowedAMMs[ammPosition].ammAddress);
            _checkAllowance(_allowedAMMs[ammPosition].liquidityPools[liquidityPoolPosition], liquidityPoolAmount, address(amm));
            amm.removeLiquidity(LiquidityPoolData(
                _allowedAMMs[ammPosition].liquidityPools[liquidityPoolPosition],
                liquidityPoolAmount,
                address(0),
                true,
                false,
                from
            ));
        }
    }

    function _rebalanceByDebt(address from, uint256 value, bytes memory payload) private {
        (, uint256 debt) = differences();
        require(value <= debt, "Cannot Burn this amount");
        uint256 note = abi.decode(payload, (uint256));
        _safeApprove(_wusdInteroperableInterfaceAddress, _extension, INativeV1(_collection).toInteroperableInterfaceAmount(_wusdObjectId, value));
        WUSDExtension(_extension).burnFor(note == 2 ? _wusdNote2ObjectId : _wusdNote5ObjectId, value, from);
    }

    function rebalanceByCredit() public {
        require(block.number >= (lastRebalanceByCreditBlock + rebalanceByCreditBlockInterval), "Unauthorized action");
        lastRebalanceByCreditBlock = block.number;
        uint256 credit = WUSDExtension(_extension).mintForRebalanceByCredit(_allowedAMMs);
        uint256 availableCredit = credit;
        uint256 reward = 0;
        if(_rebalanceByCreditPercentageForCaller > 0) {
            IERC20(_wusdInteroperableInterfaceAddress).transfer(msg.sender, reward = _calculatePercentage(credit, _rebalanceByCreditPercentageForCaller));
            availableCredit -= reward;
        }
        if(_wusdNote2Percentage > 0) {
            IERC20(_wusdInteroperableInterfaceAddress).transfer(_wusdNote2Controller, reward = _calculatePercentage(credit, _wusdNote2Percentage));
            availableCredit -= reward;
        }
        if(_wusdNote5Percentage > 0) {
            IERC20(_wusdInteroperableInterfaceAddress).transfer(_wusdNote5Controller, reward = _calculatePercentage(credit, _wusdNote5Percentage));
            availableCredit -= reward;
        }
        for(uint256 i = 0; i < _rebalanceByCreditReceivers.length; i++) {
            IERC20(_wusdInteroperableInterfaceAddress).transfer(_rebalanceByCreditReceivers[i], reward = _calculatePercentage(credit, _rebalanceByCreditPercentages[i]));
            availableCredit -= reward;
        }
        if(availableCredit > 0) {
            IERC20(_wusdInteroperableInterfaceAddress).transfer(IMVDProxy(IDoubleProxy(_doubleProxy).proxy()).getMVDWalletAddress(), availableCredit);
        }
    }

    function _calculatePercentage(uint256 total, uint256 percentage) private pure returns (uint256) {
        return (total * ((percentage * 1e18) / ONE_HUNDRED)) / 1e18;
    }

    modifier _forAllowedAMMAndLiquidityPool(uint256 ammIndex, uint256 liquidityPoolIndex) {
        require(
            ammIndex >= 0 && ammIndex < _allowedAMMs.length,
            "Unknown AMM!"
        );
        require(
            liquidityPoolIndex >= 0 && liquidityPoolIndex < _allowedAMMs[ammIndex].liquidityPools.length,
            "Unknown Liquidity Pool!"
        );
        _;
    }

    function addLiquidity(
        uint256 ammPosition,
        uint256 liquidityPoolPosition,
        uint256 liquidityPoolAmount,
        bool byLiquidityPool
    )
        public
        _forAllowedAMMAndLiquidityPool(ammPosition, liquidityPoolPosition)
        returns(uint256 toMint)
    {
        address liquidityPoolAddress = _allowedAMMs[ammPosition].liquidityPools[liquidityPoolPosition];
        uint256[] memory spent;
        uint256[] memory amounts;
        address[] memory tokens;
        if(byLiquidityPool) {
            _safeTransferFrom(liquidityPoolAddress, msg.sender, address(this), toMint = liquidityPoolAmount);
        } else {
            IAMM amm = IAMM(_allowedAMMs[ammPosition].ammAddress);
            (amounts, tokens) = amm.byLiquidityPoolAmount(liquidityPoolAddress, liquidityPoolAmount);
            for(uint256 i = 0; i < tokens.length; i++) {
                _safeTransferFrom(tokens[i], msg.sender, address(this), amounts[i]);
                _safeApprove(tokens[i], address(amm), amounts[i]);
            }
            (toMint, spent,) = IAMM(_allowedAMMs[ammPosition].ammAddress).addLiquidity(LiquidityPoolData(
                liquidityPoolAddress,
                liquidityPoolAmount,
                address(0),
                true,
                false,
                address(this)
            ));
        }

        _safeApprove(liquidityPoolAddress, _extension, toMint);
        WUSDExtension(_extension).mintFor(_allowedAMMs[ammPosition].ammAddress, liquidityPoolAddress, toMint, msg.sender);

        for(uint256 i = 0; i < spent.length; i++) {
            uint256 difference = amounts[i] - spent[i];
            if(difference > 0) {
                _safeTransfer(tokens[i], msg.sender, difference);
            }
        }
    }

    function _checkAllowance(address tokenAddress, uint256 value, address operator) internal virtual {
        if(tokenAddress == address(0) || operator == address(0)) {
            return;
        }
        IERC20 token = IERC20(tokenAddress);
        if(token.allowance(address(this), operator) <= value) {
            _safeApprove(tokenAddress, operator, token.totalSupply());
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

    function _flushBack(address payable sender, address[] memory tokens) internal virtual {
        for(uint256 i = 0; i < tokens.length; i++) {
            if(tokens[i] != address(0)) {
                _flushBack(sender, tokens[i]);
            }
        }
        _flushBack(sender, address(0));
    }

    function _flushBack(address payable sender, address tokenAddress) internal virtual {
        uint256 balance = tokenAddress == address(0) ? address(this).balance : IERC20(tokenAddress).balanceOf(address(this));

        if(balance == 0) {
            return;
        }

        if(tokenAddress == address(0)) {
            return sender.transfer(balance);
        }
        _safeTransfer(tokenAddress, sender, balance);
    }

    function _normalizeAndSumAmounts(uint256 ammPosition, uint256 liquidityPoolPosition, uint256 liquidityPoolAmount)
        private
        view
        returns(uint256 amount) {
            IERC20 liquidityPool = IERC20(_allowedAMMs[ammPosition].liquidityPools[liquidityPoolPosition]);
            (uint256[] memory amounts, address[] memory tokens) = IAMM(_allowedAMMs[ammPosition].ammAddress).byLiquidityPoolAmount(address(liquidityPool), liquidityPoolAmount != 0 ? liquidityPoolAmount : liquidityPool.balanceOf(_extension));
            for(uint256 i = 0; i < amounts.length; i++) {
                amount += _normalizeTokenAmountToDefaultDecimals(tokens[i], amounts[i]);
            }
    }

    function _normalizeTokenAmountToDefaultDecimals(address tokenAddress, uint256 amount) internal virtual view returns(uint256) {
        uint256 remainingDecimals = DECIMALS;
        IERC20 token = IERC20(tokenAddress);
        remainingDecimals -= token.decimals();

        if(remainingDecimals == 0) {
            return amount;
        }

        return amount * (remainingDecimals == 0 ? 1 : (10**remainingDecimals));
    }
}