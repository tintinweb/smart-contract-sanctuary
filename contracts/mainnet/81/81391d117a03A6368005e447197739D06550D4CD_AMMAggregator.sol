/**
 *Submitted for verification at Etherscan.io on 2021-02-02
*/

// File: contracts\amm-aggregator\common\AMMData.sol

//SPDX-License-Identifier: MIT
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

// File: contracts\amm-aggregator\aggregator\IAMMAggregator.sol

//SPDX_License_Identifier: MIT
pragma solidity ^0.7.6;
//pragma abicoder v2;


interface IAMMAggregator is IAMM {

    function doubleProxy() external view returns (address);

    function setDoubleProxy(address newDoubleProxy) external;

    function amms() external view returns (address[] memory);

    function remove(uint256) external;

    function add(address[] calldata) external;

    function findByLiquidityPool(address liquidityPoolAddress) external view returns(uint256, uint256[] memory, address[] memory, address);

    function info(address liquidityPoolAddress) external view returns(string memory name, uint256 version, address amm);

    function data(address liquidityPoolAddress) external view returns(address ethereumAddress, uint256 maxTokensPerLiquidityPool, bool hasUniqueLiquidityPools, address amm);

    event AMM(address indexed amm, string name, uint256 version);
}

interface IDoubleProxy {
    function proxy() external view returns (address);
}

interface IMVDProxy {
    function getMVDFunctionalitiesManagerAddress() external view returns(address);
    function getMVDWalletAddress() external view returns (address);
    function getStateHolderAddress() external view returns(address);
}

interface IMVDFunctionalitiesManager {
    function isAuthorizedFunctionality(address functionality) external view returns(bool);
}

interface IStateHolder {
    function getBool(string calldata varName) external view returns (bool);
    function getUint256(string calldata name) external view returns(uint256);
    function getAddress(string calldata name) external view returns(address);
    function clear(string calldata varName) external returns(string memory oldDataType, bytes memory oldVal);
}

// File: contracts\amm-aggregator\aggregator\AMMAggregator.sol

//SPDX_License_Identifier: MIT
pragma solidity ^0.7.6;
//pragma abicoder v2;


contract AMMAggregator is IAMMAggregator {

    address private _doubleProxy;

    uint256 private _ammsLength;
    mapping(uint256 => address) private _amms;

    constructor(address dFODoubleProxy, address[] memory ammsToAdd) {
        _doubleProxy = dFODoubleProxy;
        for(uint256 i = 0 ; i < ammsToAdd.length; i++) {
            IAMM amm = IAMM(_amms[_ammsLength++] = ammsToAdd[i]);
            (string memory name, uint256 version) = amm.info();
            emit AMM(ammsToAdd[i], name, version);
        }
    }

    modifier byDFO virtual {
        require(_isFromDFO(msg.sender), "Unauthorized action");
        _;
    }

    function _isFromDFO(address sender) private view returns(bool) {
        IMVDProxy proxy = IMVDProxy(IDoubleProxy(_doubleProxy).proxy());
        if(IMVDFunctionalitiesManager(proxy.getMVDFunctionalitiesManagerAddress()).isAuthorizedFunctionality(sender)) {
            return true;
        }
        return proxy.getMVDWalletAddress() == sender;
    }

    function doubleProxy() public view override returns (address) {
        return _doubleProxy;
    }

    function setDoubleProxy(address newDoubleProxy) public override byDFO {
        _doubleProxy = newDoubleProxy;
    }

    function amms() public override view returns (address[] memory returnData) {
        returnData = new address[](_ammsLength);
        for(uint256 i = 0 ; i < _ammsLength; i++) {
            returnData[i] = _amms[i];
        }
    }

    function remove(uint256 index) public override byDFO {
        require(index < _ammsLength--, "Invalid index");
        _amms[index] = _amms[_ammsLength];
        delete _amms[_ammsLength];
    }

    function add(address[] memory ammsToAdd) public override byDFO {
        for(uint256 i = 0 ; i < ammsToAdd.length; i++) {
            IAMM amm = IAMM(_amms[_ammsLength++] = ammsToAdd[i]);
            (string memory name, uint256 version) = amm.info();
            emit AMM(ammsToAdd[i], name, version);
        }
    }

    function findByLiquidityPool(address liquidityPoolAddress) public override view returns(uint256, uint256[] memory, address[] memory, address amm) {
        for(uint256 i = 0; i < _ammsLength; i++) {
            try IAMM(amm = _amms[i]).byLiquidityPool(liquidityPoolAddress) returns (uint256 liquidityPoolAmount, uint256[] memory tokensAmounts, address[] memory tokensAddresses) {
                if(tokensAddresses.length > 0) {
                    return (liquidityPoolAmount, tokensAmounts, tokensAddresses, amm);
                }
            } catch {
            }
            amm = address(0);
        }
    }

    function info() public override view returns(string memory, uint256) {}

    function data() public override view returns(address, uint256, bool) {}

    function info(address liquidityPoolAddress) public override view returns(string memory name, uint256 version, address amm) {
        (,,,amm) = findByLiquidityPool(liquidityPoolAddress);
        (name, version) = IAMM(amm).info();
    }

    function data(address liquidityPoolAddress) public override view returns(address ethereumAddress, uint256 maxTokensPerLiquidityPool, bool hasUniqueLiquidityPools, address amm) {
        (,,,amm) = findByLiquidityPool(liquidityPoolAddress);
        (ethereumAddress, maxTokensPerLiquidityPool, hasUniqueLiquidityPools) = IAMM(amm).data();
    }

    function balanceOf(address liquidityPoolAddress, address owner) public override view returns(uint256, uint256[] memory, address[] memory) {
        (,,,address amm) = findByLiquidityPool(liquidityPoolAddress);
        return IAMM(amm).balanceOf(liquidityPoolAddress, owner);
    }

    function byLiquidityPool(address liquidityPoolAddress) public override view returns(uint256 liquidityPoolAmount, uint256[] memory tokensAmounts, address[] memory tokensAddresses) {
        (liquidityPoolAmount, tokensAmounts, tokensAddresses,) = findByLiquidityPool(liquidityPoolAddress);
    }

    function byTokens(address[] calldata liquidityPoolTokens) public override view returns(uint256, uint256[] memory, address, address[] memory) {}

    function byPercentage(address liquidityPoolAddress, uint256 numerator, uint256 denominator) public override view returns (uint256, uint256[] memory, address[] memory) {
        (,,,address amm) = findByLiquidityPool(liquidityPoolAddress);
        return IAMM(amm).byPercentage(liquidityPoolAddress, numerator, denominator);
    }

    function byLiquidityPoolAmount(address liquidityPoolAddress, uint256 liquidityPoolAmount) public override view returns(uint256[] memory, address[] memory) {
        (,,,address amm) = findByLiquidityPool(liquidityPoolAddress);
        return IAMM(amm).byLiquidityPoolAmount(liquidityPoolAddress, liquidityPoolAmount);
    }

    function byTokenAmount(address liquidityPoolAddress, address tokenAddress, uint256 tokenAmount) public override view returns(uint256, uint256[] memory, address[] memory) {
        (,,,address amm) = findByLiquidityPool(liquidityPoolAddress);
        return IAMM(amm).byTokenAmount(liquidityPoolAddress, tokenAddress, tokenAmount);
    }

    function createLiquidityPoolAndAddLiquidity(address[] calldata tokenAddresses, uint256[] calldata amounts, bool involvingETH, address receiver) public override payable returns(uint256, uint256[] memory, address, address[] memory) {
        revert("Impossibru");
    }

    function addLiquidity(LiquidityPoolData calldata data) public override payable returns(uint256, uint256[] memory, address[] memory) {
        (,,,address amm) = findByLiquidityPool(data.liquidityPoolAddress);
        return IAMM(amm).addLiquidity(data);
    }

    function addLiquidityBatch(LiquidityPoolData[] calldata data) public override payable returns(uint256[] memory, uint256[][] memory, address[][] memory) {
        (,,,address amm) = findByLiquidityPool(data[0].liquidityPoolAddress);
        return IAMM(amm).addLiquidityBatch(data);
    }

    function removeLiquidity(LiquidityPoolData calldata data) public override returns(uint256, uint256[] memory, address[] memory) {
        (,,,address amm) = findByLiquidityPool(data.liquidityPoolAddress);
        return IAMM(amm).removeLiquidity(data);
    }

    function removeLiquidityBatch(LiquidityPoolData[] calldata data) public override returns(uint256[] memory, uint256[][] memory, address[][] memory) {
        (,,,address amm) = findByLiquidityPool(data[0].liquidityPoolAddress);
        return IAMM(amm).removeLiquidityBatch(data);
    }

    function getSwapOutput(address tokenAddress, uint256 tokenAmount, address[] calldata liquidityPoolAddresses, address[] calldata path) view public override returns(uint256[] memory) {
        (,,,address amm) = findByLiquidityPool(liquidityPoolAddresses[0]);
        return IAMM(amm).getSwapOutput(tokenAddress, tokenAmount, liquidityPoolAddresses, path);
    }

    function swapLiquidity(SwapData calldata data) public override payable returns(uint256) {
        (,,,address amm) = findByLiquidityPool(data.liquidityPoolAddresses[0]);
        return IAMM(amm).swapLiquidity(data);
    }

    function swapLiquidityBatch(SwapData[] calldata data) public override payable returns(uint256[] memory) {
        (,,,address amm) = findByLiquidityPool(data[0].liquidityPoolAddresses[0]);
        return IAMM(amm).swapLiquidityBatch(data);
    }
}