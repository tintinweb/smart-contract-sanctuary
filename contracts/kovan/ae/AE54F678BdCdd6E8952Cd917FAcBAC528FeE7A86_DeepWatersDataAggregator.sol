/**
 *Submitted for verification at Etherscan.io on 2021-12-22
*/

// File: contracts/libraries/SafeMath.sol

pragma solidity ^0.5.16;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

// File: contracts/interfaces/IERC20.sol

pragma solidity ^0.5.16;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
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
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/token/ERC20Detailed.sol

pragma solidity ^0.5.16;


/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * > Note that this information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * `IERC20.balanceOf` and `IERC20.transfer`.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

// File: contracts/interfaces/IDeepWatersDataAggregator.sol

pragma solidity ^0.5.16;

/**
* @dev Interface for a DeepWatersDataAggregator contract
 **/

interface IDeepWatersDataAggregator {
    function getUserData(address _user)
        external
        view
        returns (
            uint256 collateralBalanceUSD,
            uint256 borrowBalanceUSD,
            uint256 collateralRatio,
            uint256 healthFactor,
            uint256 availableToBorrowUSD
        );
        
    function setVault(address payable _newVault) external;
}

// File: contracts/interfaces/IDeepWatersVault.sol

pragma solidity ^0.5.16;

/**
* @dev Interface for a DeepWatersVault contract
 **/

interface IDeepWatersVault {
    function liquidationUserBorrow(address _asset, address _user) external;
    function getAssetDecimals(address _asset) external view returns (uint256);
    function getAssetIsActive(address _asset) external view returns (bool);
    function getAssetDTokenAddress(address _asset) external view returns (address);
    function getAssetTotalLiquidity(address _asset) external view returns (uint256);
    function getAssetTotalBorrowBalance(address _asset) external view returns (uint256);
    function getAssetScarcityRatio(address _asset) external view returns (uint256);
    function getAssetScarcityRatioTarget(address _asset) external view returns (uint256);
    function getAssetBaseInterestRate(address _asset) external view returns (uint256);
    function getAssetSafeBorrowInterestRateMax(address _asset) external view returns (uint256);
    function getAssetInterestRateGrowthFactor(address _asset) external view returns (uint256);
    function getAssetVariableInterestRate(address _asset) external view returns (uint256);
    function getAssetCurrentStableInterestRate(address _asset) external view returns (uint256);
    function getAssetLiquidityRate(address _asset) external view returns (uint256);
    function getAssetCumulatedLiquidityIndex(address _asset) external view returns (uint256);
    function updateCumulatedLiquidityIndex(address _asset) external returns (uint256);
    function getInterestOnDeposit(address _asset, address _user) external view returns (uint256);
    function updateUserCumulatedLiquidityIndex(address _asset, address _user) external;
    function getAssetPriceUSD(address _asset) external view returns (uint256);
    function getUserAssetBalance(address _asset, address _user) external view returns (uint256);
    function getUserBorrowBalance(address _asset, address _user) external view returns (uint256);
    function getUserBorrowAverageStableInterestRate(address _asset, address _user) external view returns (uint256);
    function isUserStableRateBorrow(address _asset, address _user) external view returns (bool);
    function getAssets() external view returns (address[] memory);
    function transferToVault(address _asset, address payable _depositor, uint256 _amount) external;
    function transferToUser(address _asset, address payable _user, uint256 _amount) external;
    function updateBorrowBalance(address _asset, address _user, uint256 _newBorrowBalance) external;
    function setAverageStableInterestRate(address _asset, address _user, uint256 _newAverageStableInterestRate) external;
    function getUserBorrowCurrentLinearInterest(address _asset, address _user) external view returns (uint256);
    function setBorrowRateMode(address _asset, address _user, bool _isStableRateBorrow) external;
    function() external payable;
}

// File: contracts/DeepWatersDataAggregator.sol

pragma solidity ^0.5.16;





/**
* @title DeepWatersDataAggregator contract
* @author DeepWaters
* @notice Implements functions to fetch aggregated data from the DeepWatersVault contract
**/
contract DeepWatersDataAggregator is IDeepWatersDataAggregator {
    using SafeMath for uint256;

    IDeepWatersVault public vault;
    
    // the address used to identify ETH
    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    
    modifier onlyVault {
        require(msg.sender == address(vault), "The caller of this function must be a DeepWatersVault contract");
        _;
    }
    
    constructor(
        address payable _vault
    ) public {
        vault = IDeepWatersVault(_vault);
    }

    /**
    * @notice get asset data
    * @param _asset the address of the basic asset
    * @return assetName the basic asset name
    *         assetSymbol the basic asset symbol
    *         decimals the basic asset decimals
    *         isActive true if the basic asset is activated
    *         dTokenAddress the basic asset dToken address
    *         totalLiquidity the basic asset total liquidity
    *         totalBorrowBalance the basic asset total borrow balance
    *         assetPriceUSD the basic asset price in USD
    **/
    function getAssetData(address _asset)
        public
        view
        returns (
            string memory assetName,
            string memory assetSymbol,
            uint256 decimals,
            bool isActive,
            address dTokenAddress,
            uint256 totalLiquidity,
            uint256 totalLiquidityUSD,
            uint256 totalBorrowBalance,
            uint256 assetPriceUSD
        )
    {
        if (_asset == ETH_ADDRESS) {
            assetName = 'Ether';
            assetSymbol = 'ETH';
        } else {
            assetName = ERC20Detailed(_asset).name();
            assetSymbol = ERC20Detailed(_asset).symbol();
        }

        decimals = vault.getAssetDecimals(_asset);
        isActive = vault.getAssetIsActive(_asset);
        dTokenAddress = vault.getAssetDTokenAddress(_asset);
        
        totalLiquidity = vault.getAssetTotalLiquidity(_asset);
        assetPriceUSD = vault.getAssetPriceUSD(_asset);
        totalLiquidityUSD = assetPriceUSD.mul(totalLiquidity).div(10**decimals);
        
        totalBorrowBalance = vault.getAssetTotalBorrowBalance(_asset);
    }
    
    /**
    * @notice get asset interest rate data
    * @param _asset the address of the basic asset
    * @return scarcityRatio the basic asset scarcity ratio
    *         scarcityRatioTarget the basic asset scarcity ratio target
    *         baseInterestRate the basic asset base interest rate
    *         safeBorrowInterestRateMax the basic asset safe borrow interest rate max
    *         interestRateGrowthFactor the basic asset interest rate growth factor
    *         variableInterestRate the basic asset variable interest rate
    *         stableInterestRate the basic asset stable interest rate
    *         liquidityRate the basic asset liquidity rate
    **/
    function getAssetInterestRateData(address _asset)
        external
        view
        returns (
            uint256 scarcityRatio,
            uint256 scarcityRatioTarget,
            uint256 baseInterestRate,
            uint256 safeBorrowInterestRateMax,
            uint256 interestRateGrowthFactor,
            uint256 variableInterestRate,
            uint256 stableInterestRate,
            uint256 liquidityRate
        )
    {
        scarcityRatio = vault.getAssetScarcityRatio(_asset);
        scarcityRatioTarget = vault.getAssetScarcityRatioTarget(_asset);
        baseInterestRate = vault.getAssetBaseInterestRate(_asset);
        safeBorrowInterestRateMax = vault.getAssetSafeBorrowInterestRateMax(_asset);
        interestRateGrowthFactor = vault.getAssetInterestRateGrowthFactor(_asset);
        variableInterestRate = vault.getAssetVariableInterestRate(_asset);
        stableInterestRate = vault.getAssetCurrentStableInterestRate(_asset);
        liquidityRate = vault.getAssetLiquidityRate(_asset);
    }

    /**
    * @notice get user asset data
    * @param _asset the address of the basic asset
    * @param _user the address of the user
    * @return dTokenBalance the user deposit balance of the asset
    *         dTokenBalanceUSD the user deposit balance of the asset in USD
    *         borrowBalance the user borrow balance of the asset
    *         borrowBalanceUSD the user borrow balance of the asset in USD
    *         availableToBorrow the amount of the asset available for borrowing by the user
    *         availableToBorrowUSD the amount of the asset available for borrowing by the user in USD
    *         assetPriceUSD the asset price in USD
    **/
    function getUserAssetData(address _asset, address _user)
        external
        view
        returns (
            string memory assetName,
            string memory assetSymbol,
            uint256 decimals,
            uint256 dTokenBalance,
            uint256 dTokenBalanceUSD,
            uint256 borrowBalance,
            uint256 borrowBalanceUSD,
            uint256 availableToBorrow,
            uint256 availableToBorrowUSD,
            uint256 assetPriceUSD
        )
    {
        (assetName, assetSymbol, decimals, , , , , , assetPriceUSD) = getAssetData(_asset);
        
        dTokenBalance = vault.getUserAssetBalance(_asset, _user).add(vault.getInterestOnDeposit(_asset, _user));
        dTokenBalanceUSD = assetPriceUSD.mul(dTokenBalance).div(10**decimals);
        
        borrowBalance = vault.getUserBorrowBalance(_asset, _user).add(vault.getUserBorrowCurrentLinearInterest(_asset, _user));
        borrowBalanceUSD = assetPriceUSD.mul(borrowBalance).div(10**decimals);
        
        ( , , , , availableToBorrowUSD) = getUserData(_user);
        
        uint256 currentAssetLiquidity = vault.getAssetTotalLiquidity(_asset);
        uint256 currentAssetLiquidityUSD = assetPriceUSD.mul(currentAssetLiquidity).div(10**decimals);
        
        if (availableToBorrowUSD > currentAssetLiquidityUSD) {
            availableToBorrowUSD = currentAssetLiquidityUSD;
        }
        
        availableToBorrow = availableToBorrowUSD.mul(10**decimals).div(assetPriceUSD);
    }
    
    /**
    * @dev struct to hold user data for an asset
    **/
    struct AssetUserData {
        address assetAddress;
        uint256 decimals;
        uint256 balance;
        uint256 borrowBalance;
        uint256 assetPriceUSD;
    }
    
    /**
    * @notice get user data
    * @param _user the address of the user
    * @return collateralBalanceUSD the total deposit balance of the user in USD,
    *         borrowBalanceUSD the total borrow balance of the user in USD,
    *         collateralRatio the collateral ratio of the user,
    *         healthFactor the health factor of the user,
    *         availableToBorrowUSD the amount of USD available to the user to borrow
    **/
    function getUserData(address _user)
        public
        view
        returns (
            uint256 collateralBalanceUSD,
            uint256 borrowBalanceUSD,
            uint256 collateralRatio,
            uint256 healthFactor,
            uint256 availableToBorrowUSD
        )
    {
        // Usage of a memory struct to avoid "Stack too deep" errors
        AssetUserData memory currentAssetUserData;
        
        address[] memory assets = vault.getAssets();
        
        for (uint256 i = 0; i < assets.length; i++) {
            currentAssetUserData.assetAddress = assets[i];
            
            currentAssetUserData.balance = 
                vault.getUserAssetBalance(currentAssetUserData.assetAddress, _user).
                add(vault.getInterestOnDeposit(currentAssetUserData.assetAddress, _user));
                
            currentAssetUserData.borrowBalance = 
                vault.getUserBorrowBalance(currentAssetUserData.assetAddress, _user).
                add(vault.getUserBorrowCurrentLinearInterest(currentAssetUserData.assetAddress, _user));
            
            if (currentAssetUserData.balance == 0 && currentAssetUserData.borrowBalance == 0) {
                continue;
            }
            
            currentAssetUserData.decimals = vault.getAssetDecimals(currentAssetUserData.assetAddress);
            currentAssetUserData.assetPriceUSD = vault.getAssetPriceUSD(currentAssetUserData.assetAddress);
            
            collateralBalanceUSD = collateralBalanceUSD.add(
                currentAssetUserData.assetPriceUSD
                    .mul(currentAssetUserData.balance)
                    .div(10**currentAssetUserData.decimals)
            );
            
            borrowBalanceUSD = borrowBalanceUSD.add(
                currentAssetUserData.assetPriceUSD
                    .mul(currentAssetUserData.borrowBalance)
                    .div(10**currentAssetUserData.decimals)
            );
        }
        
        if (borrowBalanceUSD == 0) {
            collateralRatio = 0;
            healthFactor = 0;
        } else {
            collateralRatio = collateralBalanceUSD.mul(100).div(borrowBalanceUSD);
            healthFactor = collateralBalanceUSD.mul(80).div(borrowBalanceUSD);
        }
        
        availableToBorrowUSD = collateralBalanceUSD.mul(100).div(150) - borrowBalanceUSD;
    }
    
    function setVault(address payable _newVault) external onlyVault {
        vault = IDeepWatersVault(_newVault);
    }
}