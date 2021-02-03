/**
 *Submitted for verification at Etherscan.io on 2021-02-02
*/

// File: contracts\fixed-inflation\FixedInflationData.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

struct FixedInflationEntryConfiguration {
    bool add;
    bool remove;
    FixedInflationEntry data;
}

struct FixedInflationEntry {
    uint256 lastBlock;
    bytes32 id;
    string name;
    uint256 blockInterval;
    uint256 callerRewardPercentage;
}

struct FixedInflationOperation {

    address inputTokenAddress;
    uint256 inputTokenAmount;
    bool inputTokenAmountIsPercentage;
    bool inputTokenAmountIsByMint;

    address ammPlugin;
    address[] liquidityPoolAddresses;
    address[] swapPath;
    bool enterInETH;
    bool exitInETH;

    address[] receivers;
    uint256[] receiversPercentages;
}

// File: contracts\fixed-inflation\IFixedInflationExtension.sol

//SPDX_License_Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;


interface IFixedInflationExtension {

    function init(address host) external;

    function setHost(address host) external;

    function data() external view returns(address fixedInflationContract, address host);

    function receiveTokens(address[] memory tokenAddresses, uint256[] memory transferAmounts, uint256[] memory amountsToMint) external;

    function setEntries(FixedInflationEntryConfiguration[] memory newEntries, FixedInflationOperation[][] memory operationSets) external;
}

// File: contracts\fixed-inflation\util\IERC20.sol

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

// File: contracts\fixed-inflation\IFixedInflationFactory.sol

//SPDX_License_Identifier: MIT
pragma solidity ^0.7.6;

interface IFixedInflationFactory {

    function fixedInflationDefaultExtension() external view returns (address);

    function feePercentageInfo() external view returns (uint256, address);
}

// File: contracts\fixed-inflation\IFixedInflation.sol

//SPDX_License_Identifier: MIT
pragma solidity ^0.7.6;
//pragma abicoder v2;


interface IFixedInflation {

    function setEntries(FixedInflationEntryConfiguration[] memory newEntries, FixedInflationOperation[][] memory operationSets) external;
}

// File: contracts\fixed-inflation\FixedInflation.sol

//SPDX_License_Identifier: MIT
pragma solidity ^0.7.6;
//pragma abicoder v2;







contract FixedInflation is IFixedInflation {

    event Entry(bytes32 indexed id);

    uint256 public constant ONE_HUNDRED = 1e18;

    address public _factory;

    mapping(address => uint256) private _tokenIndex;
    mapping(address => uint256) private _tokenTotalSupply;
    address[] private _tokensToTransfer;
    uint256[] private _tokenAmounts;
    uint256[] private _tokenMintAmounts;

    address public extension;

    mapping(bytes32 => FixedInflationEntry) private _entries;
    mapping(bytes32 => FixedInflationOperation[]) private _operations;

    function init(address _extension, bytes memory extensionPayload, FixedInflationEntry[] memory newEntries, FixedInflationOperation[][] memory operationSets) public returns(bytes memory extensionInitResult) {
        require(_factory == address(0), "Already init");
        require(_extension != address(0), "Blank extension");
        _factory = msg.sender;
        extension = _extension;
        if(_extension == address(0)) {
            _extension = _clone(IFixedInflationFactory(_factory).fixedInflationDefaultExtension());
        }
        if(keccak256(extensionPayload) != keccak256("")) {
            extensionInitResult = _call(_extension, extensionPayload);
        }
        require(newEntries.length > 0 && newEntries.length == operationSets.length, "Same length > 0");
        (uint256 dfoFeePercentage,) = IFixedInflationFactory(_factory).feePercentageInfo();
        for(uint256 i = 0; i < newEntries.length; i++) {
            _add(newEntries[i], operationSets[i], dfoFeePercentage);
        }
    }

    receive() external payable {
    }

    modifier extensionOnly() {
        require(msg.sender == extension, "Unauthorized");
        _;
    }

    function entry(bytes32 key) public view returns(FixedInflationEntry memory entriesArray, FixedInflationOperation[] memory operations) {
        return (_entries[key], _operations[key]);
    }

    function setEntries(FixedInflationEntryConfiguration[] memory newEntries, FixedInflationOperation[][] memory operationSets) public override extensionOnly {
        require(newEntries.length > 0 && newEntries.length == operationSets.length, "Same length > 0");
        (uint256 dfoFeePercentage,) = IFixedInflationFactory(_factory).feePercentageInfo();
        for(uint256 i = 0; i < newEntries.length; i++) {
            FixedInflationEntryConfiguration memory entryConfiguration = newEntries[i];
            if(entryConfiguration.add) {
                _add(entryConfiguration.data, operationSets[i], dfoFeePercentage);
                continue;
            }
            require(_entries[entryConfiguration.data.id].id == entryConfiguration.data.id, "Invalid id");
            if(entryConfiguration.remove) {
                _remove(entryConfiguration.data.id);
                continue;
            }
            entryConfiguration.data.lastBlock = _entries[entryConfiguration.data.id].lastBlock;
            _entries[entryConfiguration.data.id] = entryConfiguration.data;
            if(operationSets[i].length > 0) {
                _setOperations(entryConfiguration.data.id, operationSets[i], dfoFeePercentage);
            }
        }
    }

    function nextBlock(bytes32 id) public view returns(uint256) {
        return _entries[id].lastBlock == 0 ? block.number : (_entries[id].lastBlock + _entries[id].blockInterval);
    }

    function execute(bytes32[] memory ids, bool[] memory earnByAmounts) public {
        require(ids.length > 0 && ids.length == earnByAmounts.length, "Invalid input data");
        for(uint256 i = 0; i < ids.length; i++) {
            require(_entries[ids[i]].id == ids[i], "Invalid id");
            require(block.number >= nextBlock(ids[i]), "Too early to call index");
            FixedInflationEntry storage fixedInflationEntry = _entries[ids[i]];
            fixedInflationEntry.lastBlock = block.number;
            _collectFixedInflationOperationsTokens(_operations[ids[i]]);
        }
        IFixedInflationExtension(extension).receiveTokens(_tokensToTransfer, _tokenAmounts, _tokenMintAmounts);
        for(uint256 i = 0; i < ids.length; i++) {
            _execute(_entries[ids[i]], _operations[ids[i]], earnByAmounts[i], msg.sender);
        }
        _clearVars();
    }

    function _collectFixedInflationOperationsTokens(FixedInflationOperation[] memory operations) private {
        for(uint256 i = 0; i < operations.length; i++) {
            FixedInflationOperation memory operation = operations[i];
            _collectTokenData(operation.ammPlugin != address(0) && operation.enterInETH ? address(0) : operation.inputTokenAddress, operation.inputTokenAmount, operation.inputTokenAmountIsPercentage, operation.inputTokenAmountIsByMint);
        }
    }

    function _collectTokenData(address inputTokenAddress, uint256 inputTokenAmount, bool inputTokenAmountIsPercentage, bool inputTokenAmountIsByMint) private {
        if(inputTokenAmount == 0) {
            return;
        }

        uint256 position = _tokenIndex[inputTokenAddress];

        if(_tokensToTransfer.length == 0 || _tokensToTransfer[position] != inputTokenAddress) {
            _tokenIndex[inputTokenAddress] = (position = _tokensToTransfer.length);
            _tokensToTransfer.push(inputTokenAddress);
            _tokenAmounts.push(0);
            _tokenMintAmounts.push(0);
        }
        uint256 amount = _calculateTokenAmount(inputTokenAddress, inputTokenAmount, inputTokenAmountIsPercentage);
        if(inputTokenAmountIsByMint) {
            _tokenMintAmounts[position] = _tokenMintAmounts[position] + amount;
        } else {
            _tokenAmounts[position] = _tokenAmounts[position] + amount;
        }
    }

    function _calculateTokenAmount(address tokenAddress, uint256 tokenAmount, bool tokenAmountIsPercentage) private returns(uint256) {
        if(!tokenAmountIsPercentage) {
            return tokenAmount;
        }
        _tokenTotalSupply[tokenAddress] = _tokenTotalSupply[tokenAddress] != 0 ? _tokenTotalSupply[tokenAddress] : IERC20(tokenAddress).totalSupply();
        return (_tokenTotalSupply[tokenAddress] * ((tokenAmount * 1e18) / ONE_HUNDRED)) / 1e18;
    }

    function _execute(FixedInflationEntry memory fixedInflationEntry, FixedInflationOperation[] memory operations, bool earnByInput, address rewardReceiver) private {
        for(uint256 i = 0 ; i < operations.length; i++) {
            FixedInflationOperation memory operation = operations[i];
            uint256 amountIn = _calculateTokenAmount(operation.inputTokenAddress, operation.inputTokenAmount, operation.inputTokenAmountIsPercentage);
            if(operation.ammPlugin == address(0)) {
                _transferTo(operation.inputTokenAddress, amountIn, rewardReceiver, fixedInflationEntry.callerRewardPercentage, operation.receivers, operation.receiversPercentages);
            } else {
                _swap(operation, amountIn, rewardReceiver, fixedInflationEntry.callerRewardPercentage, earnByInput);
            }
        }
    }

    function _swap(FixedInflationOperation memory operation, uint256 amountIn, address rewardReceiver, uint256 callerRewardPercentage, bool earnByInput) private {

        uint256 inputReward = earnByInput ? _calculateRewardPercentage(amountIn, callerRewardPercentage) : 0;

        (address ethereumAddress,,) = IAMM(operation.ammPlugin).data();

        if(operation.exitInETH) {
            operation.swapPath[operation.swapPath.length - 1] = ethereumAddress;
        }

        address outputToken = operation.swapPath[operation.swapPath.length - 1];

        SwapData memory swapData = SwapData(
            operation.enterInETH,
            operation.exitInETH,
            operation.liquidityPoolAddresses,
            operation.swapPath,
            operation.enterInETH ? ethereumAddress : operation.inputTokenAddress,
            amountIn - inputReward,
            address(this)
        );

        if(swapData.inputToken != address(0) && !swapData.enterInETH) {
            _safeApprove(swapData.inputToken, operation.ammPlugin, swapData.amount);
        }

        uint256 amountOut;
        if(swapData.enterInETH) {
            amountOut = IAMM(operation.ammPlugin).swapLiquidity{value : amountIn}(swapData);
        } else {
            amountOut = IAMM(operation.ammPlugin).swapLiquidity(swapData);
        }

        if(earnByInput) {
            _transferTo(operation.enterInETH ? address(0) : operation.inputTokenAddress, rewardReceiver, inputReward);
        }
        _transferTo(operation.exitInETH ? address(0) : outputToken, amountOut, earnByInput ? address(0) : rewardReceiver, earnByInput ? 0 : callerRewardPercentage, operation.receivers, operation.receiversPercentages);
    }

    function _calculateRewardPercentage(uint256 totalAmount, uint256 rewardPercentage) private pure returns (uint256) {
        return (totalAmount * ((rewardPercentage * 1e18) / ONE_HUNDRED)) / 1e18;
    }

    function _transferTo(address erc20TokenAddress, uint256 totalAmount, address rewardReceiver, uint256 callerRewardPercentage, address[] memory receivers, uint256[] memory receiversPercentages) private {
        uint256 availableAmount = totalAmount;

        uint256 currentPartialAmount = rewardReceiver == address(0) ? 0 : _calculateRewardPercentage(totalAmount, callerRewardPercentage);
        _transferTo(erc20TokenAddress, rewardReceiver, currentPartialAmount);
        availableAmount -= currentPartialAmount;

        (uint256 dfoFeePercentage, address dfoWallet) = IFixedInflationFactory(_factory).feePercentageInfo();
        currentPartialAmount = dfoFeePercentage == 0 || dfoWallet == address(0) ? 0 : _calculateRewardPercentage(totalAmount, dfoFeePercentage);
        _transferTo(erc20TokenAddress, dfoWallet, currentPartialAmount);
        availableAmount -= currentPartialAmount;

        for(uint256 i = 0; i < receiversPercentages.length; i++) {
            _transferTo(erc20TokenAddress, receivers[i], currentPartialAmount = _calculateRewardPercentage(totalAmount, receiversPercentages[i]));
            availableAmount -= currentPartialAmount;
        }

        _transferTo(erc20TokenAddress, receivers[receivers.length - 1], availableAmount);
    }

    function _transferTo(address erc20TokenAddress, address to, uint256 value) private {
        if(value == 0) {
            return;
        }
        if(erc20TokenAddress == address(0)) {
            payable(to).transfer(value);
            return;
        }
        _safeTransfer(erc20TokenAddress, to, value);
    }

    function _safeApprove(address erc20TokenAddress, address to, uint256 value) internal {
        bytes memory returnData = _call(erc20TokenAddress, abi.encodeWithSelector(IERC20(erc20TokenAddress).approve.selector, to, value));
        require(returnData.length == 0 || abi.decode(returnData, (bool)), 'APPROVE_FAILED');
    }

    function _safeTransfer(address erc20TokenAddress, address to, uint256 value) private {
        bytes memory returnData = _call(erc20TokenAddress, abi.encodeWithSelector(IERC20(erc20TokenAddress).transfer.selector, to, value));
        require(returnData.length == 0 || abi.decode(returnData, (bool)), 'TRANSFER_FAILED');
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

    function _clearVars() private {
        for(uint256 i = 0; i < _tokensToTransfer.length; i++) {
            if(_tokensToTransfer[i] == address(0) && _tokenAmounts[i] == 0 && _tokenMintAmounts[i] == 0) {
                break;
            }
            delete _tokenIndex[_tokensToTransfer[i]];
            delete _tokenTotalSupply[_tokensToTransfer[i]];
        }
        delete _tokensToTransfer;
        delete _tokenAmounts;
        delete _tokenMintAmounts;
    }

    function _add(FixedInflationEntry memory fixedInflationEntry, FixedInflationOperation[] memory operations, uint256 dfoFeePercentage) private {
        emit Entry(fixedInflationEntry.id = keccak256(abi.encode(fixedInflationEntry, operations, dfoFeePercentage, msg.sender, block.number, block.timestamp)));
        _entries[fixedInflationEntry.id] = fixedInflationEntry;
        _setOperations(fixedInflationEntry.id, operations, dfoFeePercentage);
    }

    function _setOperations(bytes32 id, FixedInflationOperation[] memory operations, uint256 dfoFeePercentage) private {
        require(_entries[id].id == id, "Invalid id");
        require(operations.length > 0, "Length > 0");
        delete _operations[id];
        for(uint256 i = 0; i < operations.length; i++) {
            FixedInflationOperation memory operation = operations[i];
            require(operation.receivers.length > 0, "No receivers");
            require(operation.receiversPercentages.length == (operation.receivers.length - 1), "Percentages must be less than receivers");
            uint256 percentage = dfoFeePercentage + _entries[id].callerRewardPercentage;
            for(uint256 j = 0; j < operation.receiversPercentages.length; j++) {
                percentage += operation.receiversPercentages[j];
                require(operation.receivers[j] != address(0), "Void receiver");
            }
            require(operation.receivers[operation.receivers.length - 1] != address(0), "Void receiver");
            require(percentage < ONE_HUNDRED, "More than one hundred");
            _operations[id].push(operations[i]);
        }
    }

    function _remove(bytes32 id) private {
        require(_entries[id].id == id, "Invalid id");
        delete _entries[id];
        delete _operations[id];
    }

    /** @dev clones the input contract address and returns the copied contract address.
     * @param original address of the original contract.
     * @return copy copied contract address.
     */
    function _clone(address original) private returns (address copy) {
        assembly {
            mstore(
                0,
                or(
                    0x5880730000000000000000000000000000000000000000803b80938091923cF3,
                    mul(original, 0x1000000000000000000)
                )
            )
            copy := create(0, 0, 32)
            switch extcodesize(copy)
                case 0 {
                    invalid()
                }
        }
    }
}