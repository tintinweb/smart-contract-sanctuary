/**
 *Submitted for verification at Etherscan.io on 2021-03-20
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

// File: contracts\farming\FarmData.sol

//SPDX_License_Identifier: MIT
pragma solidity ^0.7.6;

struct FarmingPositionRequest {
    uint256 setupIndex; // index of the chosen setup.
    uint256 amount; // amount of main token or liquidity pool token.
    bool amountIsLiquidityPool; //true if user wants to directly share the liquidity pool token amount, false to add liquidity to AMM
    address positionOwner; // position extension or address(0) [msg.sender].
}

struct FarmingSetupConfiguration {
    bool add; // true if we're adding a new setup, false we're updating it.
    bool disable;
    uint256 index; // index of the setup we're updating.
    FarmingSetupInfo info; // data of the new or updated setup
}

struct FarmingSetupInfo {
    bool free; // if the setup is a free farming setup or a locked one.
    uint256 blockDuration; // duration of setup
    uint256 originalRewardPerBlock;
    uint256 minStakeable; // minimum amount of staking tokens.
    uint256 maxStakeable; // maximum amount stakeable in the setup (used only if free is false).
    uint256 renewTimes; // if the setup is renewable or if it's one time.
    address ammPlugin; // amm plugin address used for this setup (eg. uniswap amm plugin address).
    address liquidityPoolTokenAddress; // address of the liquidity pool token
    address mainTokenAddress; // eg. buidl address.
    address ethereumAddress;
    bool involvingETH; // if the setup involves ETH or not.
    uint256 penaltyFee; // fee paid when the user exits a still active locked farming setup (used only if free is false).
    uint256 setupsCount; // number of setups created by this info.
    uint256 lastSetupIndex; // index of last setup;
}

struct FarmingSetup {
    uint256 infoIndex; // setup info
    bool active; // if the setup is active or not.
    uint256 startBlock; // farming setup start block.
    uint256 endBlock; // farming setup end block.
    uint256 lastUpdateBlock; // number of the block where an update was triggered.
    uint256 objectId; // items object id for the liquidity pool token (used only if free is false).
    uint256 rewardPerBlock; // farming setup reward per single block.
    uint256 totalSupply; // If free it's the LP amount, if locked is currentlyStaked.
}

struct FarmingPosition {
    address uniqueOwner; // address representing the owner of the position.
    uint256 setupIndex; // the setup index related to this position.
    uint256 creationBlock; // block when this position was created.
    uint256 liquidityPoolTokenAmount; // amount of liquidity pool token in the position.
    uint256 mainTokenAmount; // amount of main token in the position (used only if free is false).
    uint256 reward; // position reward (used only if free is false).
    uint256 lockedRewardPerBlock; // position locked reward per block (used only if free is false).
}

// File: contracts\farming\IFarmMain.sol

//SPDX_License_Identifier: MIT
pragma solidity ^0.7.6;
//pragma abicoder v2;


interface IFarmMain {

    function ONE_HUNDRED() external view returns(uint256);
    function _rewardTokenAddress() external view returns(address);
    function position(uint256 positionId) external view returns (FarmingPosition memory);
    function setups() external view returns (FarmingSetup[] memory);
    function setup(uint256 setupIndex) external view returns (FarmingSetup memory, FarmingSetupInfo memory);
    function setFarmingSetups(FarmingSetupConfiguration[] memory farmingSetups) external;
    function openPosition(FarmingPositionRequest calldata request) external payable returns(uint256 positionId);
    function addLiquidity(uint256 positionId, FarmingPositionRequest calldata request) external payable;
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

// File: contracts\presto\verticalizations\FarmingPresto.sol

//SPDX_License_Identifier: MIT
pragma solidity ^0.7.6;
//pragma abicoder v2;






contract FarmingPresto {

    mapping(address => uint256) private _tokenIndex;
    address[] private _tokensToTransfer;
    uint256[] private _tokenAmounts;
    PrestoOperation[] private _operations;

    receive() external payable {
    }

    function openPosition(
        address prestoAddress,
        PrestoOperation[] memory operations,
        address farmMainAddress,
        FarmingPositionRequest memory request
    ) public payable returns(uint256 positionId) {
        request.positionOwner = request.positionOwner != address(0) ? request.positionOwner : msg.sender;
        uint256 eth = _transferToMeAndCheckAllowance(operations, prestoAddress);
        IPresto(prestoAddress).execute{value : eth}(_operations);
        IFarmMain farmMain = IFarmMain(farmMainAddress);
        (address[] memory tokenAddresses, uint256 ethereumValue) = _calculateAmountsAndApprove(farmMain, request.setupIndex, request.amount);
        positionId = farmMain.openPosition{value : ethereumValue}(request);
        _flushAndClear(tokenAddresses, msg.sender);
    }

    function _calculateAmountsAndApprove(IFarmMain farmMain, uint256 setupIndex, uint256 requestAmount) private returns(address[] memory tokenAddresses, uint256 ethereumValue) {
        (, FarmingSetupInfo memory setupInfo) = farmMain.setup(setupIndex);
        uint256[] memory tokensAmounts;
        (, tokensAmounts, tokenAddresses) = IAMM(setupInfo.ammPlugin).byTokenAmount(setupInfo.liquidityPoolTokenAddress, setupInfo.mainTokenAddress, requestAmount);
        for(uint256 i = 0; i < tokenAddresses.length; i++) {
            if(setupInfo.involvingETH && tokenAddresses[i] == setupInfo.ethereumAddress) {
                ethereumValue = tokensAmounts[i];
            }
            if(tokenAddresses[i] != address(0)) {
                _safeApprove(tokenAddresses[i], address(farmMain), tokensAmounts[i]);
            }
        }
    }

    function _flushAndClear(address[] memory tokenAddresses, address receiver) private {
        for(uint256 i = 0; i < tokenAddresses.length; i++) {
            if(_tokensToTransfer.length == 0 || _tokensToTransfer[_tokenIndex[tokenAddresses[i]]] != tokenAddresses[i]) {
                _safeTransfer(tokenAddresses[i], receiver, _balanceOf(tokenAddresses[i]));
            }
        }
        if(_tokensToTransfer.length == 0 || _tokensToTransfer[_tokenIndex[address(0)]] != address(0)) {
            _safeTransfer(address(0), receiver, address(this).balance);
        }
        _flushAndClear(receiver);
    }

    function _transferToMeAndCheckAllowance(PrestoOperation[] memory operations, address operator) private returns (uint256 eth) {
        eth = _collectTokensAndCheckAllowance(operations, operator);
        for(uint256 i = 0; i < _tokensToTransfer.length; i++) {
            if(_tokensToTransfer[i] == address(0)) {
                require(msg.value >= _tokenAmounts[i], "Incorrect ETH value");
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

    function _flushAndClear(address receiver) private {
        for(uint256 i = 0; i < _tokensToTransfer.length; i++) {
            _safeTransfer(_tokensToTransfer[i], receiver, _balanceOf(_tokensToTransfer[i]));
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