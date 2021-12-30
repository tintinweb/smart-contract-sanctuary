/**
 *Submitted for verification at polygonscan.com on 2021-12-30
*/

// Sources flattened with hardhat v2.6.8 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/access/[email protected]


pragma solidity ^0.8.0;

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File contracts/interface/IChainlinkAggregator.sol

pragma solidity ^0.8.0;

interface IChainlinkAggregator {
    function decimals() external view returns (uint8);

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}


// File @openzeppelin/contracts/token/ERC20/[email protected]


pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


// File contracts/interface/IERC20Extented.sol

pragma solidity ^0.8.0;

interface IERC20Extented is IERC20 {
    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);
}


// File contracts/interface/IAssetToken.sol

pragma solidity ^0.8.0;

interface IAssetToken is IERC20Extented {
    function mint(address to, uint256 amount) external;

    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;

    function owner() external view;
}


// File contracts/interface/IAsset.sol


pragma solidity ^0.8.2;

// import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


struct IPOParams {
    uint256 mintEnd;
    uint256 preIPOPrice;
    // >= 1000
    uint16 minCRatioAfterIPO;
}

struct AssetConfig {
    IAssetToken token;
    IChainlinkAggregator oracle;
    uint16 auctionDiscount;
    uint16 minCRatio;
    uint16 targetRatio;
    uint256 endPrice;
    uint8 endPriceDecimals;
    // is in preIPO stage
    bool isInPreIPO;
    IPOParams ipoParams;
    // is it been delisted
    bool delisted;
    // the Id of the pool in ShortStaking contract.
    uint256 poolId;
    // if it has been assined
    bool assigned;
}

// Collateral Asset Config
struct CAssetConfig {
    IERC20Extented token;
    IChainlinkAggregator oracle;
    uint16 multiplier;
    // if it has been assined
    bool assigned;
}

interface IAsset {
    function asset(address nToken) external view returns (AssetConfig memory);

    function cAsset(address token) external view returns (CAssetConfig memory);

    function isCollateralInPreIPO(address cAssetToken)
        external
        view
        returns (bool);
}


// File contracts/Asset.sol


pragma solidity ^0.8.2;


contract Asset is IAsset, Ownable {
    // Store registered n asset configuration information
    mapping(address => AssetConfig) private _assetsMap;

    // Store registered collateral asset configuration information
    mapping(address => CAssetConfig) private _cAssetsMap;

    // Determine whether the collateral is available in the PreIPO stage
    mapping(address => bool) private _isCollateralInPreIPO;

    /// @notice Triggered when register a new nAsset.
    /// @param assetToken nAsset token address
    event RegisterAsset(address assetToken);

    constructor() {}

    function asset(address nToken)
        external
        view
        override
        returns (AssetConfig memory)
    {
        return _assetsMap[nToken];
    }

    function cAsset(address token)
        external
        view
        override
        returns (CAssetConfig memory)
    {
        return _cAssetsMap[token];
    }

    /// @notice Register a new nAsset. Only owner
    /// @param assetToken nAsset token address
    /// @param assetOracle the oracle address of the nAsset
    /// @param auctionDiscount discount when liquidation
    /// @param minCRatio min c-ratio
    /// @param isInPreIPO is in PreIPO stage
    /// @param poolId The index of a pool in the ShortStaking contract.
    /// @param ipoParams PreIPO params
    function registerAsset(
        address assetToken,
        address assetOracle,
        uint16 auctionDiscount,
        uint16 minCRatio,
        uint16 targetRatio,
        bool isInPreIPO,
        uint256 poolId,
        IPOParams memory ipoParams
    ) external onlyOwner {
        require(
            auctionDiscount > 0 && auctionDiscount < 1000,
            "Auction discount is out of range."
        );
        require(minCRatio >= 1000, "C-Ratio is out of range.");
        require(
            !_assetsMap[assetToken].assigned,
            "This asset has already been registered"
        );

        if (isInPreIPO) {
            require(ipoParams.mintEnd > block.timestamp, "wrong mintEnd");
            require(
                ipoParams.preIPOPrice > 0,
                "The price in PreIPO couldn't be 0."
            );
            require(
                ipoParams.minCRatioAfterIPO > 0 &&
                    ipoParams.minCRatioAfterIPO < 1000,
                "C-Ratio(after IPO) is out of range."
            );
        }

        _assetsMap[assetToken] = AssetConfig(
            IAssetToken(assetToken),
            IChainlinkAggregator(assetOracle),
            auctionDiscount,
            minCRatio,
            targetRatio,
            0,
            8,
            isInPreIPO,
            ipoParams,
            false,
            poolId,
            true
        );

        emit RegisterAsset(assetToken);
    }

    /// @notice update nAsset params. Only owner
    /// @param assetToken nAsset token address
    /// @param assetOracle oracle address
    /// @param auctionDiscount discount
    /// @param minCRatio min c-ratio
    /// @param isInPreIPO is in PreIPO stage
    /// @param ipoParams PreIPO params
    function updateAsset(
        address assetToken,
        address assetOracle,
        uint16 auctionDiscount,
        uint16 minCRatio,
        uint16 targetRatio,
        bool isInPreIPO,
        uint256 poolId,
        IPOParams memory ipoParams
    ) external onlyOwner {
        require(
            auctionDiscount > 0 && auctionDiscount < 1000,
            "Auction discount is out of range."
        );
        require(minCRatio >= 1000, "C-Ratio is out of range.");
        require(
            _assetsMap[assetToken].assigned,
            "This asset are not registered yet."
        );

        if (isInPreIPO) {
            require(
                ipoParams.mintEnd > block.timestamp,
                "mintEnd in PreIPO needs to be greater than current time."
            );
            require(
                ipoParams.preIPOPrice > 0,
                "The price in PreIPO couldn't be 0."
            );
            require(
                ipoParams.minCRatioAfterIPO > 0 &&
                    ipoParams.minCRatioAfterIPO < 1000,
                "C-Ratio(after IPO) is out of range."
            );
        }

        _assetsMap[assetToken] = AssetConfig(
            IAssetToken(assetToken),
            IChainlinkAggregator(assetOracle),
            auctionDiscount,
            minCRatio,
            targetRatio,
            0,
            8,
            isInPreIPO,
            ipoParams,
            false,
            poolId,
            true
        );
    }

    /// @notice Register a new clollateral. Only owner.
    /// @param cAssetToken Collateral Token address
    /// @param oracle oracle of collateral,if “0x0”, it's a stable coin
    /// @param multiplier collateral multiplier
    function registerCollateral(
        address cAssetToken,
        address oracle,
        uint16 multiplier
    ) external onlyOwner {
        require(
            !_cAssetsMap[cAssetToken].assigned,
            "Collateral was already registered."
        );
        require(multiplier > 0, "A multiplier of collateral can not be 0.");
        _cAssetsMap[cAssetToken] = CAssetConfig(
            IERC20Extented(cAssetToken),
            IChainlinkAggregator(oracle),
            multiplier,
            true
        );
    }

    /// @notice update collateral info, Only owner.
    /// @param cAssetToken collateral Token address
    /// @param oracle collateral oracle
    /// @param multiplier collateral multiplier
    function updateCollateral(
        address cAssetToken,
        address oracle,
        uint16 multiplier
    ) external onlyOwner {
        require(
            _cAssetsMap[cAssetToken].assigned,
            "Collateral are not registered yet."
        );
        require(multiplier > 0, "A multiplier of collateral can not be 0.");
        _cAssetsMap[cAssetToken] = CAssetConfig(
            IERC20Extented(cAssetToken),
            IChainlinkAggregator(oracle),
            multiplier,
            true
        );
    }

    /// @notice revoke a collateral, only owner
    /// @param cAssetToken collateral address
    function revokeCollateral(address cAssetToken) external onlyOwner {
        require(
            _cAssetsMap[cAssetToken].assigned,
            "Collateral are not registered yet."
        );
        delete _cAssetsMap[cAssetToken];
    }

    /// @notice When the time for an n-asset PreIPO phase has ended, this function can be called to trigger the IPO event, and Mint can continue after the IPO.
    /// @dev An n asset cannot perform any Mint operations after the PreIPO time ends and before the IPO event.
    /// @param assetToken nAsset token address
    function triggerIPO(address assetToken) external onlyOwner {
        AssetConfig memory assetConfig = _assetsMap[assetToken];
        require(assetConfig.assigned, "Asset was not registered yet.");
        require(assetConfig.isInPreIPO, "Asset is not in PreIPO.");

        require(assetConfig.ipoParams.mintEnd < block.timestamp);

        assetConfig.isInPreIPO = false;
        assetConfig.minCRatio = assetConfig.ipoParams.minCRatioAfterIPO;
        _assetsMap[assetToken] = assetConfig;
    }

    /// @notice Delisting an n asset will not continue Mint after delisting.
    /// @dev 1. Set the end price. 2. Set the minimum c-ratio to 100%.
    /// @param assetToken nAsset token address
    /// @param endPrice an end price after delist
    /// @param endPriceDecimals endPrice decimals
    function registerMigration(
        address assetToken,
        uint256 endPrice,
        uint8 endPriceDecimals
    ) external onlyOwner {
        require(_assetsMap[assetToken].assigned, "Asset not registered yet.");
        _assetsMap[assetToken].endPrice = endPrice;
        _assetsMap[assetToken].endPriceDecimals = endPriceDecimals;
        _assetsMap[assetToken].minCRatio = 1000; // 1000 / 1000 = 1
        _assetsMap[assetToken].delisted = true;
    }

    /// @notice Set up collateral applicable to the PreIPO stage
    /// @param cAssetToken collateral token address
    /// @param value true or false
    function setCollateralInPreIPO(address cAssetToken, bool value)
        external
        onlyOwner
    {
        _isCollateralInPreIPO[cAssetToken] = value;
    }

    function isCollateralInPreIPO(address cAssetToken)
        external
        view
        override
        returns (bool)
    {
        return _isCollateralInPreIPO[cAssetToken];
    }
}