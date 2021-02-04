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