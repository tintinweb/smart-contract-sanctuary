/**
 *Submitted for verification at Etherscan.io on 2021-03-03
*/

// File: contracts\presto\PrestoData.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

struct PrestoOperation {

    address inputTokenAddress;
    uint256 inputTokenAmount;

    address ammPlugin;
    address[] liquidityPoolAddresses;
    address[] swapPath;
    bool enterInETH;
    bool exitInETH;

    address[] receivers;
    uint256[] receiversPercentages;
}

// File: contracts\presto\IPresto.sol

//SPDX_License_Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;


interface IPresto {

    function ONE_HUNDRED() external view returns (uint256);
    function doubleProxy() external view returns (address);
    function feePercentage() external view returns (uint256);

    function feePercentageInfo() external view returns (uint256, address);

    function setDoubleProxy(address _doubleProxy) external;

    function setFeePercentage(uint256 _feePercentage) external;

    function execute(PrestoOperation[] memory operations) external payable;
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
//pragma abicoder v2;


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

// File: contracts\index\IIndex.sol

//SPDX_License_Identifier: MIT

pragma solidity ^0.7.6;

interface IIndex {

    function _doubleProxy() external view returns(address);

    function collection() external view returns(address);

    function setDoubleProxy(address newDoubleProxy) external;

    function setCollectionUri(string calldata uri) external;

    function info(uint256 objectId, uint256 value) external view returns(address[] memory _tokens, uint256[] memory _amounts);

    function mint(string calldata name, string calldata symbol, string calldata uri, address[] calldata _tokens, uint256[] calldata _amounts, uint256 value, address receiver) external payable returns(uint256 objectId, address interoperableInterfaceAddress);

    function mint(uint256 objectId, uint256 value, address receiver) external payable;
}

// File: contracts\presto\util\ERC1155Receiver.sol

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

// File: contracts\presto\util\IERC1155.sol

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

// File: contracts\presto\util\IERC20.sol

//SPDX_License_Identifier: MIT
pragma solidity ^0.7.6;

interface IERC20 {
    function totalSupply() external view returns(uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function decimals() external view returns (uint8);
}

// File: contracts\presto\util\IEthItemInteroperableInterface.sol

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

// File: contracts\presto\util\IEthItem.sol

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

// File: contracts\presto\util\INativeV1.sol

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

// File: contracts\presto\verticalizations\IndexPresto.sol

//SPDX_License_Identifier: MIT
pragma solidity ^0.7.6;
//pragma abicoder v2;






contract IndexPresto is ERC1155Receiver {

    mapping(address => uint256) private _tokenIndex;
    address[] private _tokensToTransfer;
    uint256[] private _tokenAmounts;
    PrestoOperation[] private _operations;

    receive() external payable {
    }

    function mint(
        address prestoAddress,
        PrestoOperation[] memory operations,
        address indexAddress,
        bytes memory indexData
    ) public payable returns(uint256 objectId, address interoperableInterfaceAddress) {
        uint256 eth = _transferToMeAndCheckAllowance(operations, prestoAddress);
        IPresto(prestoAddress).execute{value : eth}(_operations);
        address[] memory tokenAddresses;
        (objectId, interoperableInterfaceAddress, tokenAddresses) = _mint(indexAddress, indexData);
        _flushAndClear(interoperableInterfaceAddress, tokenAddresses, msg.sender);
    }

    function mint(
        address prestoAddress,
        PrestoOperation[] memory operations,
        address indexAddress,
        uint256 objectId, uint256 value, address receiver) public payable {
        uint256 eth = _transferToMeAndCheckAllowance(operations, prestoAddress);
        IPresto(prestoAddress).execute{value : eth}(_operations);
        (address[] memory tokenAddresses, uint256[] memory amounts) = IIndex(indexAddress).info(objectId, value);
        _approve(indexAddress, tokenAddresses, amounts);
        IIndex(indexAddress).mint{value : _balanceOf(address(0))}(objectId, value, receiver);
        _flushAndClear(address(INativeV1(IIndex(indexAddress).collection()).asInteroperable(objectId)), tokenAddresses, msg.sender);
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
            (address prestoAddress, PrestoOperation[] memory operations, bytes memory payload) = abi.decode(data, (address, PrestoOperation[], bytes));
            INativeV1(msg.sender).safeTransferFrom(address(this), INativeV1(msg.sender).extension(), id, value, payload);
            uint256[] memory ids = new uint256[](1);
            ids[0] = id;
            _afterBurn(prestoAddress, operations, ids, from);
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
            (address prestoAddress, PrestoOperation[] memory operations, bytes memory payload) = abi.decode(data, (address, PrestoOperation[], bytes));
            INativeV1(msg.sender).safeBatchTransferFrom(address(this), INativeV1(msg.sender).extension(), ids, values, payload);
            _afterBurn(prestoAddress, operations, ids, from);
            return this.onERC1155BatchReceived.selector;
    }

    function _afterBurn(
        address prestoAddress,
        PrestoOperation[] memory operations,
        uint256[] memory ids,
        address from) private {
            IPresto(prestoAddress).execute{value : _collectTokensAndCheckAllowance(operations, prestoAddress)}(operations);
            for(uint256 i = 0; i < ids.length; i++) {
                _collectTokenData(address(INativeV1(msg.sender).asInteroperable(ids[i])), 1);
            }
            _flushAndClear(address(0), new address[](0), from);
    }

    function _mint(address indexAddress, bytes memory indexData) private returns(uint256 objectId, address interoperableInterfaceAddress, address[] memory tokenAddresses) {
        (string memory name, string memory symbol, string memory uri, address[] memory _tokens, uint256[] memory _amounts, uint256 value, address receiver) = abi.decode(indexData, (string, string, string, address[], uint256[], uint256, address));
        _approve(indexAddress, tokenAddresses = _tokens, new uint256[](0));
        (objectId, interoperableInterfaceAddress) = IIndex(indexAddress).mint{value : _balanceOf(address(0))}(name, symbol, uri, _tokens, _amounts, value, receiver);
    }

    function _approve(address indexAddress, address[] memory tokenAddresses, uint256[] memory amounts) private {
        for(uint256 i = 0; i < tokenAddresses.length; i++) {
            _safeApprove(tokenAddresses[i], indexAddress, amounts.length > 0 ? amounts[i] : _balanceOf(tokenAddresses[i]));
        }
    }

    function _flushAndClear(address indexInteroperableInterfaceAddress, address[] memory tokenAddresses, address receiver) private {
        _safeTransfer(indexInteroperableInterfaceAddress, receiver, _balanceOf(indexInteroperableInterfaceAddress));
        for(uint256 i = 0; i < tokenAddresses.length; i++) {
            if(_tokensToTransfer.length == 0 || _tokensToTransfer[_tokenIndex[tokenAddresses[i]]] != tokenAddresses[i]) {
                _safeTransfer(tokenAddresses[i], receiver, _balanceOf(tokenAddresses[i]));
            }
        }
        if(_tokensToTransfer.length == 0 || _tokensToTransfer[_tokenIndex[address(0)]] != address(0)) {
            _safeTransfer(address(0), receiver, address(this).balance);
        }
        _flushAndClear();
    }

    function _transferToMeAndCheckAllowance(PrestoOperation[] memory operations, address operator) private returns (uint256 eth) {
        eth = _collectTokensAndCheckAllowance(operations, operator);
        for(uint256 i = 0; i < _tokensToTransfer.length; i++) {
            if(_tokensToTransfer[i] == address(0)) {
                require(msg.value == _tokenAmounts[i], "Incorrect ETH value");
            } else {
                _safeTransferFrom(_tokensToTransfer[i], msg.sender, address(this), _tokenAmounts[i]);
            }
        }
    }

    function _collectTokensAndCheckAllowance(PrestoOperation[] memory operations, address operator) private returns (uint256 eth) {
        for(uint256 i = 0; i < operations.length; i++) {
            PrestoOperation memory operation = operations[i];
            require(operation.ammPlugin == address(0) || operation.liquidityPoolAddresses.length > 0, "AddLiquidity not allowed"); 
            _collectTokenData(operation.ammPlugin != address(0) && operation.enterInETH ? address(0) : operation.inputTokenAddress, operation.inputTokenAmount);
            if(operation.ammPlugin != address(0)) {
                _operations.push(operation);
                if(operation.inputTokenAddress == address(0) || operation.enterInETH) {
                    eth += operation.inputTokenAmount;
                }
            }
        }
        for(uint256 i = 0 ; i < _tokensToTransfer.length; i++) {
            if(_tokensToTransfer[i] != address(0)) {
                _safeApprove(_tokensToTransfer[i], operator, _tokenAmounts[i]);
            }
        }
    }

    function _collectTokenData(address inputTokenAddress, uint256 inputTokenAmount) private {
        if(inputTokenAmount == 0) {
            return;
        }

        uint256 position = _tokenIndex[inputTokenAddress];

        if(_tokensToTransfer.length == 0 || _tokensToTransfer[position] != inputTokenAddress) {
            _tokenIndex[inputTokenAddress] = (position = _tokensToTransfer.length);
            _tokensToTransfer.push(inputTokenAddress);
            _tokenAmounts.push(0);
        }
        _tokenAmounts[position] = _tokenAmounts[position] + inputTokenAmount;
    }

    function _flushAndClear() private {
        for(uint256 i = 0; i < _tokensToTransfer.length; i++) {
            _safeTransfer(_tokensToTransfer[i], msg.sender, _balanceOf(_tokensToTransfer[i]));
            delete _tokenIndex[_tokensToTransfer[i]];
        }
        delete _tokensToTransfer;
        delete _tokenAmounts;
        delete _operations;
    }

    function _balanceOf(address tokenAddress) private view returns(uint256) {
        if(tokenAddress == address(0)) {
            return address(this).balance;
        }
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    function _safeApprove(address erc20TokenAddress, address to, uint256 value) internal {
        bytes memory returnData = _call(erc20TokenAddress, abi.encodeWithSelector(IERC20(erc20TokenAddress).approve.selector, to, value));
        require(returnData.length == 0 || abi.decode(returnData, (bool)), 'APPROVE_FAILED');
    }

    function _safeTransfer(address erc20TokenAddress, address to, uint256 value) private {
        if(value == 0) {
            return;
        }
        if(erc20TokenAddress == address(0)) {
            (bool result,) = to.call{value:value}("");
            require(result, "ETH transfer failed");
            return;
        }
        bytes memory returnData = _call(erc20TokenAddress, abi.encodeWithSelector(IERC20(erc20TokenAddress).transfer.selector, to, value));
        require(returnData.length == 0 || abi.decode(returnData, (bool)), 'TRANSFER_FAILED');
    }

    function _safeTransferFrom(address erc20TokenAddress, address from, address to, uint256 value) internal {
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