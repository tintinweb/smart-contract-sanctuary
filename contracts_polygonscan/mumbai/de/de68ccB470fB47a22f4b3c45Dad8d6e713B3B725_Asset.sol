/**
 *Submitted for verification at polygonscan.com on 2021-11-25
*/

// Sources flattened with hardhat v2.6.5 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

// SPDX-License-Identifier: MIT

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


// File @chainlink/contracts/src/v0.8/interfaces/[email protected]


pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

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
    function decimals() external view returns(uint8);
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
struct IPOParams{
    uint mintEnd;
    uint preIPOPrice;
    // >= 1000
    uint16 minCRatioAfterIPO;
}

struct AssetConfig {
    IAssetToken token;
    AggregatorV3Interface oracle;
    uint16 auctionDiscount;
    uint16 minCRatio;
    uint endPrice;
    uint8 endPriceDecimals;
    // 鏄惁鍦≒reIPO闃舵
    bool isInPreIPO;
    IPOParams ipoParams;
    // 鏄惁宸查€€甯?
    bool delisted;
    // the Id of the pool in ShortStaking contract.
    uint poolId;
    // 鍒ゆ柇璇ョ┖闂存槸鍚﹀凡琚垎閰?
    bool assigned;
}

// Collateral Asset Config
struct CAssetConfig {
    IERC20Extented token;
    AggregatorV3Interface oracle;
    uint16 multiplier;
    // 鍒ゆ柇璇ョ┖闂存槸鍚﹀凡琚垎閰?
    bool assigned;
}

interface IAsset {
    function asset(address nToken) external view returns(AssetConfig memory);
    function cAsset(address token) external view returns(CAssetConfig memory);
    function isCollateralInPreIPO(address cAssetToken) external view returns(bool);
}


// File contracts/Asset.sol



pragma solidity ^0.8.2;
contract Asset is IAsset, Ownable {

    // 瀛樺偍宸叉敞鍐岀殑n璧勪骇閰嶇疆淇℃伅
    mapping(address => AssetConfig) private _assetsMap;

    // 瀛樺偍宸叉敞鍐岀殑鎶垫娂鐗╄祫浜ч厤缃俊鎭?
    mapping(address => CAssetConfig) private _cAssetsMap;

    // 鍒ゆ柇鎶垫娂鐗╂槸鍚﹀湪PreIPO闃舵鍙敤
    mapping(address => bool) private _isCollateralInPreIPO;

    /// @notice Triggered when register a new nAsset.
    /// @param assetToken 璧勪骇Token鍚堢害鍦板潃銆?
    event RegisterAsset(address assetToken);

    constructor() {

    }

    function asset(address nToken) external override view returns(AssetConfig memory) {
        return _assetsMap[nToken];
    }

    function cAsset(address token) external override view returns(CAssetConfig memory) {
        return _cAssetsMap[token];
    }

    /// @notice 娉ㄥ唽鏂扮殑鍚堟垚璧勪骇锛屽嵆n璧勪骇銆侽nly owner
    /// @dev 娉ㄥ唽鏃跺彲閫夋嫨鏄惁鍏?PreIPO锛?濡傛灉鍙傛暟ipoParams涓虹┖锛屽垯琛ㄧず娌℃湁PreIPO闃舵銆?
    /// @param assetToken 鏂扮殑n璧勪骇鐨凾oken鍚堢害鍦板潃銆?
    /// @param assetOracle 鏂扮殑n璧勪骇鐨勫瘬瑷€鏈哄湴鍧€銆?
    /// @param auctionDiscount 褰撲粨浣嶅浜庢竻绠楃姸鎬佹椂锛岀敤浜庤喘涔版姷鎶肩墿鐨勬姌鎵ｄ环銆?
    /// @param minCRatio 浠撲綅鏈€浣庢姷鎶肩巼銆?
    /// @param isInPreIPO 鏄惁鍦≒reIPO闃舵
    /// @param poolId The index of a pool in the ShortStaking contract.
    /// @param ipoParams PreIPO鍙傛暟锛屽鏋滀负绌猴紝鍒欒〃绀烘病鏈塒reIPO闃舵銆?
    function registerAsset(
        address assetToken, 
        address assetOracle, 
        uint16 auctionDiscount, 
        uint16 minCRatio, 
        bool isInPreIPO, 
        uint poolId, 
        IPOParams memory ipoParams
    ) external onlyOwner {
        require(auctionDiscount > 0 && auctionDiscount < 1000, "Auction discount is out of range.");
        require(minCRatio >= 1000, "C-Ratio is out of range.");
        require(!_assetsMap[assetToken].assigned, "This asset has already been registered");

        if(isInPreIPO) {
            require(ipoParams.mintEnd > block.timestamp, "wrong mintEnd");
            require(ipoParams.preIPOPrice > 0, "The price in PreIPO couldn't be 0.");
            require(ipoParams.minCRatioAfterIPO > 0 && ipoParams.minCRatioAfterIPO < 1000, "C-Ratio(after IPO) is out of range.");
        }
        // TODO 濡傛灉 isInPreIPO == false锛屽簲璇ユ妸璇璧勪骇鍒楀叆鎶垫娂鐗╃櫧鍚嶅崟锛屼絾姝ゅ姛鑳借浆绉诲埌澶栧眰鍘诲仛銆?

        _assetsMap[assetToken] = AssetConfig(
            IAssetToken(assetToken), 
            AggregatorV3Interface(assetOracle), 
            auctionDiscount, minCRatio, 
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

    /// @notice 鏇存柊n璧勪骇鐨勫弬鏁般€?Only owner
    /// @param assetToken 鏂扮殑n璧勪骇鐨凾oken鍚堢害鍦板潃銆?
    /// @param assetOracle 鏂扮殑n璧勪骇鐨勫瘬瑷€鏈哄湴鍧€銆?
    /// @param auctionDiscount 褰撲粨浣嶅浜庢竻绠楃姸鎬佹椂锛岀敤浜庤喘涔版姷鎶肩墿鐨勬姌鎵ｄ环銆?
    /// @param minCRatio 浠撲綅鏈€浣庢姷鎶肩巼銆?
    /// @param isInPreIPO 鏄惁鍦≒reIPO闃舵
    /// @param ipoParams PreIPO鍙傛暟锛屽鏋滀负绌猴紝鍒欒〃绀烘病鏈塒reIPO闃舵銆?
    function updateAsset(
        address assetToken, 
        address assetOracle, 
        uint16 auctionDiscount, 
        uint16 minCRatio, 
        bool isInPreIPO, 
        uint poolId, 
        IPOParams memory ipoParams
    ) external onlyOwner {
        require(auctionDiscount > 0 && auctionDiscount < 1000, "Auction discount is out of range.");
        require(minCRatio >= 1000, "C-Ratio is out of range.");
        require(_assetsMap[assetToken].assigned, "This asset are not registered yet.");

        if(isInPreIPO) {
            require(ipoParams.mintEnd > block.timestamp, "mintEnd in PreIPO needs to be greater than current time.");
            require(ipoParams.preIPOPrice > 0, "The price in PreIPO couldn't be 0.");
            require(ipoParams.minCRatioAfterIPO > 0 && ipoParams.minCRatioAfterIPO < 1000, "C-Ratio(after IPO) is out of range.");
        }

        _assetsMap[assetToken] = AssetConfig(
            IAssetToken(assetToken), 
            AggregatorV3Interface(assetOracle), 
            auctionDiscount, 
            minCRatio, 
            0, 
            8, 
            isInPreIPO, 
            ipoParams, 
            false, 
            poolId, 
            true
        );
    }

    /// @notice 娉ㄥ唽鎶垫娂鐗﹖oken锛屾敞鍐屽悗鎵嶈兘鐢ㄤ簬鍚堟垚璧勪骇鐨勬姷鎶硷紝Only owner.
    /// @param cAssetToken 鎶垫娂鐗㏕oken address
    /// @param oracle 鎶垫娂鐗╀环鏍煎瘬瑷€鏈哄湴鍧€锛屽oracle鍦板潃涓衡€?x0鈥濓紝鍒欒涓虹ǔ瀹氬竵
    /// @param multiplier 鎶垫娂鐜囦箻鏁板洜瀛?
    function registerCollateral(address cAssetToken, address oracle, uint16 multiplier) external onlyOwner {
        require(!_cAssetsMap[cAssetToken].assigned, "Collateral was already registered.");
        require(multiplier > 0, "A multiplier of collateral can not be 0.");
        _cAssetsMap[cAssetToken] = CAssetConfig(IERC20Extented(cAssetToken), AggregatorV3Interface(oracle), multiplier, true);
    }

    /// @notice 鏇存柊鎶垫娂鐗╅厤缃紝Only owner.
    /// @param cAssetToken 鎶垫娂鐗㏕oken address
    /// @param oracle 鎶垫娂鐗╀环鏍煎瘬瑷€鏈哄湴鍧€
    /// @param multiplier 鎶垫娂鐜囦箻鏁板洜瀛?
    function updateCollateral(address cAssetToken, address oracle, uint16 multiplier) external onlyOwner {
        require(_cAssetsMap[cAssetToken].assigned, "Collateral are not registered yet.");
        require(multiplier > 0, "A multiplier of collateral can not be 0.");
        _cAssetsMap[cAssetToken] = CAssetConfig(IERC20Extented(cAssetToken), AggregatorV3Interface(oracle), multiplier, true);
    }

    /// @notice 鎾ら攢涓€涓姷鎶肩墿锛宱nly owner
    /// @dev 鎾ら攢鍚庡皢涓嶈兘鍐嶈褰撲綔鎶垫娂鐗╀娇鐢ㄣ€?
    /// @param cAssetToken 鍗冲皢琚挙閿€鐨?
    function revokeCollateral(address cAssetToken) external onlyOwner {
        require(_cAssetsMap[cAssetToken].assigned, "Collateral are not registered yet.");
        delete _cAssetsMap[cAssetToken];

        // TODO 鑰冭檻褰撴鎶垫娂鐗╁凡缁忓湪浣跨敤涓紝璇ュ浣曞鐞?
    }

    /// @notice 褰撲竴涓猲璧勪骇PreIPO闃舵鐨勬椂闂村凡缁忕粨鏉燂紝鍙€氳繃璋冪敤姝ゅ嚱鏁版潵瑙﹀彂IPO浜嬩欢锛孖PO涔嬪悗鍙户缁璏int銆?
    /// @dev 涓€涓猲璧勪骇鍦?PreIPO鏃堕棿缁撴潫涔嬪悗锛孖PO浜嬩欢涔嬪墠锛屾槸涓嶈兘鎵ц浠讳綍Mint鎿嶄綔鐨勩€?
    /// @param assetToken n璧勪骇鐨則oken鍚堢害鍦板潃
    function triggerIPO(address assetToken) external onlyOwner {
        AssetConfig memory assetConfig = _assetsMap[assetToken];
        require(assetConfig.assigned, "Asset was not registered yet.");
        require(assetConfig.isInPreIPO, "Asset is not in PreIPO.");
        // TODO 鑰冭檻鏄惁瑕佸姞姝ゅ垽鏂?
        require(assetConfig.ipoParams.mintEnd < block.timestamp);

        assetConfig.isInPreIPO = false;
        assetConfig.minCRatio = assetConfig.ipoParams.minCRatioAfterIPO;
        _assetsMap[assetToken] = assetConfig;
    }
    
    /// @notice 瀵逛竴涓猲璧勪骇鎵ц閫€甯傛搷浣滐紝閫€甯傚悗涓嶈兘鍐嶇户缁璏int銆?
    /// @dev 1.璁剧疆end price銆?.灏嗘渶浣庢姷鎶肩巼璁剧疆涓?00%銆?
    /// @param assetToken n璧勪骇鐨則oken鍚堢害鍦板潃
    /// @param endPrice 閫€甯傚悗鐨勪竴涓渶缁堜环鏍硷紝鐢ㄤ簬Burn鎿嶄綔銆?
    /// @param endPriceDecimals endPrice鐨勫皬鏁颁綅鏁伴噺锛岀敤浜庣簿搴﹁绠?
    function registerMigration(address assetToken, uint endPrice, uint8 endPriceDecimals) external onlyOwner {
        require(_assetsMap[assetToken].assigned, "Asset not registered yet.");
        _assetsMap[assetToken].endPrice = endPrice;
        _assetsMap[assetToken].endPriceDecimals = endPriceDecimals;
        _assetsMap[assetToken].minCRatio = 1000; // 1000 / 1000 = 1
        _assetsMap[assetToken].delisted = true;

        // TODO 濡傛灉姝よ祫浜т篃琚垪鍏ヤ簡鎶垫娂鐗╃櫧鍚嶅崟锛屽垯杩樺簲灏嗘璧勪骇浠庢姷鎶肩墿鍒楄〃涓Щ闄ゃ€?
        // TODO 鑰冭檻濡傛灉姝よ祫浜ц繕澶勪簬PreIPO闃舵璇ュ浣曞鐞?
    }

    /// @notice 璁剧疆閫傜敤浜嶱reIPO闃舵鐨勬姷鎶肩墿
    /// @param cAssetToken 鎶垫娂鐗﹖oken
    /// @param value 鏄惁鍙敤
    function setCollateralInPreIPO(address cAssetToken, bool value) external onlyOwner {
        _isCollateralInPreIPO[cAssetToken] = value;
    }

    function isCollateralInPreIPO(address cAssetToken) external view override returns(bool) {
        return _isCollateralInPreIPO[cAssetToken];
    }

}