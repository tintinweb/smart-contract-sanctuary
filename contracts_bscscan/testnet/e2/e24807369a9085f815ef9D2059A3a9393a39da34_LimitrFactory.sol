/**
 *Submitted for verification at BscScan.com on 2021-10-01
*/

// SPDX-License-Identifier: BSD-3-Clause


pragma solidity ^0.8.0;


/// @author Limitr
/// @title factory contract interface for the Limitr main factory
interface ILimitrFactory {
    /// @notice NewFeeCollectorSetter is emitted when a new fee collector setter is set
    /// @param oldFeeCollectorSetter The old fee collector setter
    /// @param newFeeCollectorSetter The new fee collector setter
    event NewFeeCollectorSetter(address indexed oldFeeCollectorSetter, address indexed newFeeCollectorSetter);

    /// @notice NewFeeCollector is emitted when a new fee collector is set
    /// @param oldFeeCollector The old fee collector
    /// @param newFeeCollector The new fee collector
    event NewFeeCollector(address indexed oldFeeCollector, address indexed newFeeCollector);

    /// @notice MarketCreated is emitted when a new market is created
    /// @param baseToken The token to exchange
    /// @param counterToken The desired token
    event MarketCreated(address indexed baseToken, address indexed counterToken);


    /// @notice The address for WETH
    function weth() external view returns (address);

    /// @return The fee collector
    function feeCollector() external view returns (address);

    /// @return The fee collector setter
    function feeCollectorSetter() external view returns (address);

    /// @notice Set the fee collector (for the feeCollectorSetter only)
    /// @param newFeeCollector The new fee collector
    function setFeeCollector(address newFeeCollector) external;

    /// @notice Set the fee collector setter (for the feeCollectorSetter only)
    /// @param newFeeCollectorSetter The new fee collector setter
    function setFeeCollectorSetter(address newFeeCollectorSetter) external;

    /// @return The number of available markets
    function marketsCount() external view returns (uint256);

    /// @return The market at index idx
    /// @param idx The market index
    function market(uint256 idx) external view returns (address);

    /// @return The address for the market to trade baseToken for counterToken, may be 0
    /// @param baseToken The token owned by the trader
    /// @param counterToken The token desired by the trader
    function getMarket(address baseToken, address counterToken) external view returns (address);

    /// @return The address for the market with the provided hash
    /// @param hash The market hash
    function getMarketByHash(bytes32 hash) external view returns (address);

    /// @notice Create a new market
    /// @param baseToken The token owned by the trader
    /// @param counterToken The token desired by the trader
    /// @return The market address
    function createMarket(address baseToken, address counterToken) external returns (address);

    /// @notice Calculate the hash for a market
    /// @param baseToken The token owned by the trader
    /// @param counterToken The token desired by the trader
    /// @return The market hash
    function marketHash(address baseToken, address counterToken) external pure returns (bytes32);

    /// @notice Returns the addresses of the tokens with markets with baseToken as base
    /// @param baseToken The base token
    /// @return An array of counter token addresses
    function withBase(address baseToken) external view returns (address[] memory);

    /// @notice Returns the addresses of the tokens with markets with counterToken as counter
    /// @param counterToken The counter token
    /// @return An array of base token addresses
    function withCounter(address counterToken) external view returns (address[] memory);
}





pragma solidity ^0.8.0;


/// @author Limitr
/// @title factory contract interface for a Limitr factory
interface ILimitrDeployer {
    function createMarket(
        address factory,
        address baseToken,
        address counterToken
    ) external returns (address);
}





pragma solidity ^0.8.0;




/// @author Limitr
/// @title factory contract for Limitr
contract LimitrFactory is ILimitrFactory {

    /// @return The address for WETH
    address public override weth;

    /// @return The fee collector
    address public override feeCollector;

    /// @return The fee collector setter
    address public override feeCollectorSetter;

    /// @notice The market at index idx
    address[] public override market;

    /// @return The address for the market with the provided hash
    mapping(bytes32 => address) public override getMarketByHash;


    // factories
    address internal tokenTokenDeployer;
    address internal ETHTokenDeployer;
    address internal tokenETHDeployer;

    constructor(
        address _weth,
        address _feeCollectorSetter,
        address _feeCollector,
        address _tokenTokenDeployer,
        address _ETHTokenDeployer,
        address _tokenETHDeployer
    ) {
        weth = _weth;
        feeCollectorSetter = _feeCollectorSetter != address(0) ? _feeCollectorSetter : msg.sender;
        feeCollector = _feeCollector != address(0) ? _feeCollector : msg.sender;
        tokenTokenDeployer = _tokenTokenDeployer;
        ETHTokenDeployer = _ETHTokenDeployer;
        tokenETHDeployer = _tokenETHDeployer;
    }


    /// @notice Set the fee collector (for the feeCollectorSetter only). Emits
    ///         a NewFeeCollector
    /// @param newFeeCollector The new fee collector
    function setFeeCollector(address newFeeCollector)
        external override onlyFeeCollectorSetter
    {
        require(newFeeCollector != address(0), "Can't set to zero address");
        address oldReceiver = feeCollector;
        feeCollector = newFeeCollector;
        emit NewFeeCollector(oldReceiver, newFeeCollector);
    }

    /// @notice Set the fee collector setter (for the feeCollectorSetter only).
    ///         Emits a NewFeeCollectorSetter
    /// @param newFeeCollectorSetter The new fee collector setter
    function setFeeCollectorSetter(address newFeeCollectorSetter)
        external override onlyFeeCollectorSetter
    {
        require(newFeeCollectorSetter != address(0), "Can't set to zero address");
        address oldSetter = feeCollectorSetter;
        feeCollectorSetter = newFeeCollectorSetter;
        emit NewFeeCollectorSetter(oldSetter, newFeeCollectorSetter);
    }

    /// @return The number of available markets
    function marketsCount() external view override returns (uint256) {
        return market.length;
    }

    /// @return The address for the market to trade baseToken for counterToken, may be 0
    /// @param baseToken The token owned by the trader
    /// @param counterToken The token desired by the trader
    function getMarket(address baseToken, address counterToken)
        external view override
        noZeroAddress(baseToken)
        noZeroAddress(counterToken)
        returns (address)
    {
        require(baseToken != counterToken, "Equal base and counter tokens");
        return getMarketByHash[marketHash(baseToken, counterToken)];
    }

    /// @notice Create a new market
    /// @param baseToken The token owned by the trader
    /// @param counterToken The token desired by the trader
    /// @return The market address
    function createMarket(address baseToken, address counterToken)
        external override
        noZeroAddress(baseToken)
        noZeroAddress(counterToken)
        returns (address)
    {
        require(baseToken != counterToken, "Equal src and dst tokens");
        bytes32 hash = marketHash(baseToken, counterToken);
        require(getMarketByHash[hash] == address(0), 'Market already exists');
        address f;
        if (baseToken == weth) {
            f = ETHTokenDeployer;
        } else if (counterToken == weth) {
            f = tokenETHDeployer;
        } else {
            f = tokenTokenDeployer;
        }
        address addr = ILimitrDeployer(f).createMarket(address(this), baseToken, counterToken);
        getMarketByHash[hash] = addr;
        market.push(addr);
        _withBase[baseToken].push(counterToken);
        _withCounter[counterToken].push(baseToken);
        emit MarketCreated(baseToken, counterToken);
        return addr;
    }

    /// @dev Check for 0 address
    modifier noZeroAddress(address addr) {
        require(addr != address(0), "Zero address not allowed");
        _;
    }

    /// @dev Only allowed for the see collector setter
    modifier onlyFeeCollectorSetter {
        require(msg.sender == feeCollectorSetter, "Only for the fee collector setter");
        _;
    }

    /// @notice Calculate the hash for a market
    /// @param baseToken The token owned by the trader
    /// @param counterToken The token desired by the trader
    /// @return The market hash
    function marketHash(address baseToken, address counterToken) public pure override returns (bytes32) {
        return keccak256(abi.encodePacked(baseToken, counterToken));
    }

    /// @notice Returns the addresses of the tokens with markets with baseToken as base
    /// @param baseToken The base token
    /// @return An array of counter token addresses
    function withBase(address baseToken) external view override returns (address[] memory) {
        return _withBase[baseToken];
    }

    /// @notice Returns the addresses of the tokens with markets with counterToken as counter
    /// @param counterToken The counter token
    /// @return An array of base token addresses
    function withCounter(address counterToken) external view override returns (address[] memory) {
        return _withCounter[counterToken];
    }

    mapping(address => address[]) internal _withBase;
    mapping(address => address[]) internal _withCounter;
}