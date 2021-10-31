/**
 *Submitted for verification at Etherscan.io on 2021-10-31
*/

// File: contracts/security/ReentrancyGuard.sol

pragma solidity ^0.5.16;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the `nonReentrant` modifier
 * available, which can be aplied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 */
contract ReentrancyGuard {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    constructor () internal {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}

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

// File: contracts/libraries/Address.sol

pragma solidity ^0.5.16;

/**
 * @dev Collection of functions related to the address type,
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * > It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

// File: contracts/interfaces/IDToken.sol

pragma solidity ^0.5.16;

/**
* @dev Interface for a DToken contract
 **/

interface IDToken {
    function balanceOf(address _user) external view returns(uint256);
    function changeDeepWatersContracts(address _newLendingContract, address payable _newVault) external;
    function mint(address _user, uint256 _amount) external;
    function burn(address _user, uint256 _amount) external;
}

// File: contracts/interfaces/IDeepWatersVault.sol

pragma solidity ^0.5.16;

/**
* @dev Interface for a DeepWatersVault contract
 **/

interface IDeepWatersVault {
    function getAssetDecimals(address _asset) external view returns (uint256);
    function getAssetIsActive(address _asset) external view returns (bool);
    function getAssetDTokenAddress(address _asset) external view returns (address);
    function getAssetTotalLiquidity(address _asset) external view returns (uint256);
    function getAssetPriceUSD(address _asset) external view returns (uint256);
    function getUserAssetBalance(address _asset, address _user) external view returns (uint256);
    function getUserBorrowBalance(address _asset, address _user) external view returns (uint256);
    function getAssets() external view returns (address[] memory);
    function transferToVault(address _asset, address payable _depositor, uint256 _amount) external;
    function transferToUser(address _asset, address payable _user, uint256 _amount) external;
    function updateBorrowBalance(address _asset, address _user, uint256 _newBorrowBalance) external;
    function() external payable;
}

// File: contracts/interfaces/IDeepWatersDataAggregator.sol

pragma solidity ^0.5.16;

/**
* @dev Interface for a DeepWatersDataAggregator contract
 **/

interface IDeepWatersDataAggregator {
    function getAssetData(address _asset)
        external
        view
        returns (
            string memory assetName,
            string memory assetSymbol,
            uint256 decimals,
            bool isActive,
            address dTokenAddress,
            uint256 totalLiquidity,
            uint256 totalLiquidityUSD,
            uint256 assetPriceUSD
        );
        
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
        );
        
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

// File: contracts/DeepWatersLending.sol

pragma solidity ^0.5.16;







/**
* @title DeepWatersLending contract
* @notice Implements the lending actions
* @author DeepWaters
 **/
contract DeepWatersLending is ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address;

    IDeepWatersVault public vault;
    IDeepWatersDataAggregator public dataAggregator;

    /**
    * @dev emitted on deposit of ETH
    * @param _depositor the address of the depositor
    * @param _amount the amount to be deposited
    * @param _timestamp the timestamp of the action
    **/
    event DepositEther(
        address indexed _depositor,
        uint256 _amount,
        uint256 _timestamp
    );
    
    /**
    * @dev emitted on deposit of basic asset
    * @param _asset the address of the basic asset
    * @param _depositor the address of the depositor
    * @param _amount the amount to be deposited
    * @param _timestamp the timestamp of the action
    **/
    event DepositAsset(
        address indexed _asset,
        address indexed _depositor,
        uint256 _amount,
        uint256 _timestamp
    );

    /**
    * @dev emitted on redeem of basic asset
    * @param _asset the address of the basic asset
    * @param _user the address of the user
    * @param _amount the amount to be redeemed
    * @param _timestamp the timestamp of the action
    **/
    event Redeem(
        address indexed _asset,
        address indexed _user,
        uint256 _amount,
        uint256 _timestamp
    );
    
    /**
    * @dev emitted on borrow of basic asset
    * @param _asset the address of the basic asset
    * @param _user the address of the user
    * @param _amount the amount to be deposited
    * @param _timestamp the timestamp of the action
    **/
    event Borrow(
        address indexed _asset,
        address indexed _user,
        uint256 _amount,
        uint256 _timestamp
    );
    
    /**
    * @dev emitted on repay of ETH
    * @param _user the address of the user
    * @param _amount the amount repaid
    * @param _timestamp the timestamp of the action
    **/
    event RepayEther(
        address indexed _user,
        uint256 _amount,
        uint256 _timestamp
    );
    
    /**
    * @dev emitted on repay of basic asset
    * @param _asset the address of the basic asset
    * @param _user the address of the user
    * @param _amount the amount repaid
    * @param _timestamp the timestamp of the action
    **/
    event RepayAsset(
        address indexed _asset,
        address indexed _user,
        uint256 _amount,
        uint256 _timestamp
    );
    
    // the address used to identify ETH
    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    
    modifier onlyVault {
        require(msg.sender == address(vault), "The caller of this function must be a DeepWatersVault contract");
        _;
    }
    
    constructor(
        address payable _vault,
        address _dataAggregator
    ) public {
        vault = IDeepWatersVault(_vault);
        dataAggregator = IDeepWatersDataAggregator(_dataAggregator);
    }
    
    /**
    * @dev deposits ETH into the vault.
    * A corresponding amount of the derivative token is minted.
    **/
    function depositEther()
        external
        payable
        nonReentrant
    {
        require(vault.getAssetIsActive(ETH_ADDRESS), "Action requires an active asset");
        require(msg.value > 0, "ETH value must be greater than 0");
        
        IDToken dToken = IDToken(vault.getAssetDTokenAddress(ETH_ADDRESS));

        // minting corresponding DToken amount to depositor
        dToken.mint(msg.sender, msg.value);

        // transfer deposit to the DeepWatersVault contract
        address(vault).transfer(msg.value);

        emit DepositEther(msg.sender, msg.value, block.timestamp);
    }
    
    /**
    * @dev deposits the supported basic asset into the vault. 
    * A corresponding amount of the derivative token is minted.
    * @param _asset the address of the basic asset
    * @param _amount the amount to be deposited
    **/
    function depositAsset(address _asset, uint256 _amount)
        external
        nonReentrant
    {
        require(vault.getAssetIsActive(_asset), "Action requires an active asset");
        require(_amount > 0, "Amount must be greater than 0");
        require(_asset != ETH_ADDRESS, "For deposit ETH use function depositEther");
        
        IDToken dToken = IDToken(vault.getAssetDTokenAddress(_asset));

        // minting corresponding DToken amount to depositor
        dToken.mint(msg.sender, _amount);

        // transfer deposit to the DeepWatersVault contract
        vault.transferToVault(_asset, msg.sender, _amount);

        emit DepositAsset(_asset, msg.sender, _amount, block.timestamp);
    }
    
    /**
    * @dev redeems a specific amount of basic asset
    * @param _asset the address of the basic asset
    * @param _amount the amount being redeemed
    **/
    function redeem(
        address _asset,
        uint256 _amount
    )
        external
        nonReentrant
    {
        require(vault.getAssetIsActive(_asset), "Action requires an active asset");
        require(_amount > 0, "Amount must be greater than 0");

        uint256 currentAssetLiquidity = vault.getAssetTotalLiquidity(_asset);
        require(_amount <= currentAssetLiquidity, "There is not enough asset liquidity to redeem");
        
        (uint256 dTokenBalance, , , , uint256 availableToBorrow, , ) = getUserAssetData(_asset, msg.sender);
        
        require(_amount <= dTokenBalance, "Amount more than the user deposit of asset");
        require(_amount <= availableToBorrow, "Amount more than the user available balance of asset");
        
        IDToken dToken = IDToken(vault.getAssetDTokenAddress(_asset));
        dToken.burn(msg.sender, _amount);
        
        vault.transferToUser(_asset, msg.sender, _amount);

        emit Redeem(_asset, msg.sender, _amount, block.timestamp);
    }

    /**
    * @dev allows users to borrow a specific amount of the basic asset
    * @param _asset the address of the basic asset
    * @param _amount the amount to be borrowed
    **/
    function borrow(
        address _asset,
        uint256 _amount
    )
        external
        nonReentrant
    {
        require(vault.getAssetIsActive(_asset), "Action requires an active asset");
        require(_amount > 0, "Amount must be greater than 0");
        require(
            vault.getAssetTotalLiquidity(_asset) >= _amount,
            "Insufficient liquidity of the asset"
        );
        
        (uint256 collateralBalanceUSD, uint256 borrowBalanceUSD, , , ) = getUserData(msg.sender);
        
        require(collateralBalanceUSD > 0, "Zero collateral balance");
        
        uint256 amountUSD = vault.getAssetPriceUSD(_asset)
            .mul(_amount)
            .div(10**vault.getAssetDecimals(_asset));
        
        require(collateralBalanceUSD.mul(10) >= (borrowBalanceUSD.add(amountUSD)).mul(15), "Insufficient collateral ratio");
        
        uint256 newBorrowBalance = vault.getUserBorrowBalance(_asset, msg.sender).add(_amount);
        
        vault.updateBorrowBalance(_asset, msg.sender, newBorrowBalance);
        vault.transferToUser(_asset, msg.sender, _amount);
        
        emit Borrow(
            _asset,
            msg.sender,
            _amount,
            block.timestamp
        );
    }
    
    /**
    * @notice repays a specified amount of ETH
    **/
    function repayEther()
        external
        payable
        nonReentrant
    {
        require(vault.getAssetIsActive(ETH_ADDRESS), "Action requires an active asset");
        require(msg.value > 0, "ETH value must be greater than 0");

        uint256 borrowBalance = vault.getUserBorrowBalance(ETH_ADDRESS, msg.sender);
        
        require(msg.value <= borrowBalance, "Amount exceeds borrow");

        uint256 newBorrowBalance = borrowBalance.sub(msg.value);
        
        vault.updateBorrowBalance(ETH_ADDRESS, msg.sender, newBorrowBalance);
       
        // transfer ETH to the DeepWatersVault contract
        address(vault).transfer(msg.value);

        emit RepayEther(
            msg.sender,
            msg.value,
            block.timestamp
        );
    }
    
    /**
    * @notice repays a specified amount of the asset borrow
    * @param _asset the address of the basic asset
    * @param _amount the amount to be repaid
    **/
    function repayAsset(address _asset, uint256 _amount)
        external
        nonReentrant
    {
        require(vault.getAssetIsActive(_asset), "Action requires an active asset");
        require(_amount > 0, "Amount must be greater than 0");
 
        uint256 borrowBalance = vault.getUserBorrowBalance(_asset, msg.sender);
        
        require(_amount <= borrowBalance, "Amount exceeds borrow");

        uint256 newBorrowBalance = borrowBalance.sub(_amount);
        
        vault.updateBorrowBalance(_asset, msg.sender, newBorrowBalance);
        
        // transfer asset to the DeepWatersVault contract
        vault.transferToVault(_asset, msg.sender, _amount);

        emit RepayAsset(
            _asset,
            msg.sender,
            _amount,
            block.timestamp
        );
    }
    
    function getAssetData(address _asset)
        external
        view
        returns (
            string memory assetName,
            string memory assetSymbol,
            uint256 decimals,
            bool isActive,
            address dTokenAddress,
            uint256 totalLiquidity,
            uint256 totalLiquidityUSD,
            uint256 assetPriceUSD
        )
    {
        (assetName, assetSymbol, decimals, isActive, dTokenAddress, totalLiquidity, totalLiquidityUSD, assetPriceUSD) = dataAggregator.getAssetData(_asset);
    }

    function getUserAssetData(address _asset, address _user)
        public
        view
        returns (
            uint256 dTokenBalance,
            uint256 dTokenBalanceUSD,
            uint256 borrowBalance,
            uint256 borrowBalanceUSD,
            uint256 availableToBorrow,
            uint256 availableToBorrowUSD,
            uint256 assetPriceUSD
        )
    {
        (
          , , , dTokenBalance, dTokenBalanceUSD, 
          borrowBalance, borrowBalanceUSD, 
          availableToBorrow, availableToBorrowUSD, assetPriceUSD
        ) = dataAggregator.getUserAssetData(_asset, _user);
    }

    function getAssets() external view returns (address[] memory) {
        return vault.getAssets();
    }
    
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
        (collateralBalanceUSD, borrowBalanceUSD, collateralRatio, healthFactor, availableToBorrowUSD) = dataAggregator.getUserData(_user);
    }
    
    function setVault(address payable _newVault) external onlyVault {
        vault = IDeepWatersVault(_newVault);
    }
    
    function setDataAggregator(address _newDataAggregator) external onlyVault {
        dataAggregator = IDeepWatersDataAggregator(_newDataAggregator);
    }
    
    function getDataAggregator() external view returns (address) {
        address(dataAggregator);
    }
}