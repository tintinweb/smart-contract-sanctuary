// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import '@openzeppelin/contracts/access/Ownable.sol';

/**
* @dev This interacts with the specified squeeth protocol controller functions
*/

interface ControllerInterface{
    function getIndex(uint256 _period) external view returns(uint256);
    function getDenormalizedMark(uint32 _period) external view returns(uint256);
    function getExpectedNormalizationFactor() external view returns (uint256);
    function getDenormalizedMarkForFunding(uint32 _period) external view returns (uint256);
}

/**
* @dev This interacts with the specified squeeth protocol oracle functions
*/
interface OracleIterface{
    function getTwap(
        address _pool,
        address _base,
        address _quote,
        uint _period,
        bool _checkPeriod
    )external view returns(uint256);

    function getHistoricalTwap(
        address _pool,
        address _base,
        address _quote,
        uint32 _secondsAgoToStartOfTwap,
        uint32 _secondsAgoToEndOfTwap
    ) external view returns(uint256);

    function getMaxPeriod(address _pool) external view returns (uint32);
}

/**
* @title NewPriceFeedConsumer
* @notice intercacts with the squeeth protocol and oracle to fetch Opyn Squeeth and ETH^2 prices
* and historical data
*/
contract MainPriceFeedConsumer is Ownable{

    address public immutable controller; //the controller address
    address public immutable oracle; // the oracle address

    address public immutable squeethControllerAddress = 0x64187ae08781B09368e6253F9E94951243A493D5;
    address public immutable squeethOracleAddress = 0x65D66c76447ccB45dAf1e8044e918fA786A483A1;
    address public immutable squeethTokenAddress = 0xf1B99e3E573A1a9C5E6B2Ce818b617F0E664E86B;
    address public immutable wethTokenAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public immutable usdcTokenAddress = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public immutable squeethETHUniswapV3Pool = 0x82c427AdFDf2d245Ec51D8046b41c4ee87F0d29C;
    address public immutable ethUSDCUniswapV3Pool = 0x8ad599c3A0ff1De082011EFDDc58f1908eb6e6D8;
    address public immutable ropstenNetControllerAddress = 0x59F0c781a6eC387F09C40FAA22b7477a2950d209;
    address public immutable ropstenNetSqueethUniPoolAddress = 0x921c384F79de1BAe96d6f33E3E5b8d0B2B34cb68;
    address public immutable ropstenEthUsdcPoolAddress = 0x8356AbC730a218c24446C2c85708F373f354F0D8;
    address public immutable ropstenOracleAddress = 0xBD9F4bE886653177D22fA9c79FD0DFc41407fC89;
    address public immutable ropstenQuoterAddress = 0x267aEB76BEb6DC7Ab0D88FeEaC8A948e237e2d69;
    //address public immutable ropstenUsdcAddress = 0x27415c30d8c87437becbd4f98474f26e712047f4;
    address public immutable ropstenSqueethAddress = 0xa4222f78d23593e82Aa74742d25D06720DCa4ab7;
    //address public immutable ropstenWethAddress = 0xc778417e063141139fce010982780140aa0cd5ab;
    address public immutable ropstenSwapRouterAddress = 0x528a19A3e88861E7298C86fE5490B8Ec007a4204;

    constructor(address _controller, address _oracle){
        controller = _controller;
        oracle = _oracle;
    }

    /**
     * @notice get the index price of the powerPerp, scaled down
     * @dev the index price is scaled down by INDEX_SCALE in the associated PowerXBase library
     * @dev this is the index price used when calculating funding and for collateralization
     * @param _period period which you want to calculate twap with
     * @return index price denominated in $USD, scaled by 1e18
     */
    function getIndexPrice(uint32 _period) public view returns(uint256){
        return ControllerInterface(controller).getIndex(_period);
    }

    /**
     * @notice get the expected mark price of powerPerp after funding has been applied
     * @param _period period of time for the twap in seconds
     * @return mark price denominated in $USD, scaled by 1e18
     */
    function getDenormalizedMarkPrice(uint32 _period) public view returns(uint256){
        return ControllerInterface(controller).getDenormalizedMark(_period);
    }

    /**
     * @notice get twap converted with base & quote token decimals
     * @dev if period is longer than the current timestamp - first timestamp stored in the pool, this will revert with "OLD"
     * @param _pool uniswap pool address
     * @param _base base currency. to get eth/usd price, eth is base token
     * @param _quote quote currency. to get eth/usd price, usd is the quote currency
     * @param _period number of seconds in the past to start calculating time-weighted average
     * @return price of 1 base currency in quote currency. scaled by 1e18
     */
    function getTwap(
        address _pool,
        address _base,
        address _quote,
        uint32 _period,
        bool _checkPeriod
    ) public view returns(uint256){
        return OracleIterface(oracle).getTwap(_pool, _base, _quote,_period, _checkPeriod) ;
    }

    /**
     * @notice get twap for a specific period of time, converted with base & quote token decimals
     * @dev if the _secondsAgoToStartOfTwap period is longer than the current timestamp - first timestamp stored in the pool, this will revert with "OLD"
     * @param _pool uniswap pool address
     * @param _base base currency. to get eth/usd price, eth is base token
     * @param _quote quote currency. to get eth/usd price, usd is the quote currency
     * @param _secondsAgoToStartOfTwap amount of seconds in the past to start calculating time-weighted average
     * @param _secondsAgoToEndOfTwap amount of seconds in the past to end calculating time-weighted average
     * @return price of 1 base currency in quote currency. scaled by 1e18
     */
    function getHistoricalTwap(
        address _pool,
        address _base,
        address _quote,
        uint32 _secondsAgoToStartOfTwap,
        uint32 _secondsAgoToEndOfTwap
        ) public view returns(uint256 ){
            return OracleIterface(oracle).getHistoricalTwap(_pool,_base,_quote,_secondsAgoToStartOfTwap,_secondsAgoToEndOfTwap);
    }

    /**
     * @notice get the max period that can be used to request twap
     * @param _pool uniswap pool address
     * @return max period can be used to request twap
     */
    function getMaxPeriod(address _pool) public view returns (uint32) {
        return OracleIterface(oracle).getMaxPeriod(_pool);
    }

    /**
     * @notice returns the expected normalization factor, if the funding is paid right now
     * @dev can be used for on-chain and off-chain calculations
     */
    function getCurrentFundingRate() public view returns (uint256) {
        return ControllerInterface(controller).getExpectedNormalizationFactor();
    }

    /**
     * @notice get the mark price of powerPerp before funding has been applied
     * @dev this is the mark that would be used to calculate a new normalization factor if funding was calculated now
     * @param _period period which you want to calculate twap with
     * @return mark price denominated in $USD, scaled by 1e18
     */
    function getDenormalizedMarkForFunding(uint32 _period) external view returns (uint256) {
        return ControllerInterface(controller).getDenormalizedMarkForFunding(_period);
    }
 }

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}