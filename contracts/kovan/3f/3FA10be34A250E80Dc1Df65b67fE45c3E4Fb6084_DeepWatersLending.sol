/**
 *Submitted for verification at Etherscan.io on 2021-12-22
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
    * @param _interestOnDeposit the interest paid on the deposit
    * @param _cumulatedLiquidityIndex the cumulated liquidity index
    * @param _timestamp the timestamp of the action
    **/
    event DepositEther(
        address indexed _depositor,
        uint256 _amount,
        uint256 _interestOnDeposit,
        uint256 _cumulatedLiquidityIndex,
        uint256 _timestamp
    );
    
    /**
    * @dev emitted on deposit of basic asset
    * @param _asset the address of the basic asset
    * @param _depositor the address of the depositor
    * @param _amount the amount to be deposited
    * @param _interestOnDeposit the interest paid on the deposit
    * @param _cumulatedLiquidityIndex the cumulated liquidity index
    * @param _timestamp the timestamp of the action
    **/
    event DepositAsset(
        address indexed _asset,
        address indexed _depositor,
        uint256 _amount,
        uint256 _interestOnDeposit,
        uint256 _cumulatedLiquidityIndex,
        uint256 _timestamp
    );

    /**
    * @dev emitted on redeem of basic asset
    * @param _asset the address of the basic asset
    * @param _user the address of the user
    * @param _amount the amount to be redeemed
    * @param _interestOnDeposit the interest paid on the deposit
    * @param _cumulatedLiquidityIndex the cumulated liquidity index
    * @param _timestamp the timestamp of the action
    **/
    event Redeem(
        address indexed _asset,
        address indexed _user,
        uint256 _amount,
        uint256 _interestOnDeposit,
        uint256 _cumulatedLiquidityIndex,
        uint256 _timestamp
    );
    
    /**
    * @dev emitted on minting interest on deposit
    * @param _asset the address of the basic asset
    * @param _user the address of the user
    * @param _interestOnDeposit the interest paid on the deposit
    * @param _timestamp the timestamp of the action
    **/
    event MintInterestOnDeposit(
        address indexed _asset,
        address indexed _user,
        uint256 _interestOnDeposit,
        uint256 _timestamp
    );
    
    /**
    * @dev emitted on update the cumulated liquidity index after transfer dToken
    * @param _asset the address of the basic asset
    * @param _fromUser the address of the transfer sender
    * @param _toUser the address of the transfer recipient
    * @param _cumulatedLiquidityIndex the cumulated liquidity index
    * @param _timestamp the timestamp of the action
    **/
    event updateIndexesAfterTransferDToken(
        address indexed _asset,
        address indexed _fromUser,
        address indexed _toUser,
        uint256 _cumulatedLiquidityIndex,
        uint256 _timestamp
    );
    
    /**
    * @dev emitted on borrow of basic asset
    * @param _asset the address of the basic asset
    * @param _user the address of the user
    * @param _amount the amount to be deposited
    * @param _isStableRateBorrow the true for stable mode and the false for variable mode
    * @param _linearInterest the linear interest of user borrow
    * @param _newBorrowBalance new value of borrow balance
    * @param _cumulatedLiquidityIndex the cumulated liquidity index
    * @param _timestamp the timestamp of the action
    **/
    event Borrow(
        address indexed _asset,
        address indexed _user,
        uint256 _amount,
        bool _isStableRateBorrow,
        uint256 _linearInterest,
        uint256 _newBorrowBalance,
        uint256 _cumulatedLiquidityIndex,
        uint256 _timestamp
    );
    
    /**
    * @dev emitted on repay of ETH
    * @param _user the address of the user
    * @param _amount the amount repaid
    * @param _linearInterest the linear interest of user borrow
    * @param _newBorrowBalance new value of borrow balance
    * @param _cumulatedLiquidityIndex the cumulated liquidity index
    * @param _timestamp the timestamp of the action
    **/
    event RepayEther(
        address indexed _user,
        uint256 _amount,
        uint256 _linearInterest,
        uint256 _newBorrowBalance,
        uint256 _cumulatedLiquidityIndex,
        uint256 _timestamp
    );
    
    /**
    * @dev emitted on repay of basic asset
    * @param _asset the address of the basic asset
    * @param _user the address of the user
    * @param _amount the amount repaid
    * @param _linearInterest the linear interest of user borrow
    * @param _newBorrowBalance new value of borrow balance
    * @param _cumulatedLiquidityIndex the cumulated liquidity index
    * @param _timestamp the timestamp of the action
    **/
    event RepayAsset(
        address indexed _asset,
        address indexed _user,
        uint256 _amount,
        uint256 _linearInterest,
        uint256 _newBorrowBalance,
        uint256 _cumulatedLiquidityIndex,
        uint256 _timestamp
    );
    
    /**
    * @dev emitted on user liquidation
    * @param _user the address of the user
    * @param _collateralBalanceUSD the total deposit balance of the user in USD before liquidation
    * @param _borrowBalanceUSD the total borrow balance of the user in USD before liquidation
    * @param _healthFactor the health factor of the user before liquidation
    * @param _cumulatedLiquidityIndex the cumulated liquidity index after liquidation
    * @param _timestamp the timestamp of the action
    **/
    event UserLiquidation(
        address indexed _user,
        uint256 _collateralBalanceUSD,
        uint256 _borrowBalanceUSD,
        uint256 _healthFactor,
        uint256 _cumulatedLiquidityIndex,
        uint256 _timestamp
    );
    
    // the address used to identify ETH
    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    
    uint256 internal constant MIN_C_RATIO = 150; // 150%
    
    modifier onlyVault {
        require(msg.sender == address(vault), "The caller of this function must be a DeepWatersVault contract");
        _;
    }

    address internal liquidator;
    
    /**
    * @dev only liquidator can use functions affected by this modifier
    **/
    modifier onlyLiquidator {
        require(liquidator == msg.sender, "The caller must be a liquidator");
        _;
    }
    
    /**
    * @dev only dToken contract can use functions affected by this modifier
    **/
    modifier onlyDTokenContract(address _asset) {
        require(
            vault.getAssetDTokenAddress(_asset) == msg.sender,
            "The caller must be a dToken contract"
        );
        _;
    }
    
    constructor(
        address payable _vault,
        address _dataAggregator,
        address _liquidator
    ) public {
        vault = IDeepWatersVault(_vault);
        dataAggregator = IDeepWatersDataAggregator(_dataAggregator);
        liquidator = _liquidator;
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

        uint256 interestOnDeposit = vault.getInterestOnDeposit(ETH_ADDRESS, msg.sender);
        
        // minting corresponding DToken amount to depositor
        dToken.mint(msg.sender, msg.value.add(interestOnDeposit));

        // transfer deposit to the DeepWatersVault contract
        address(vault).transfer(msg.value);

        uint256 cumulatedLiquidityIndex = vault.updateCumulatedLiquidityIndex(ETH_ADDRESS);
        
        vault.updateUserCumulatedLiquidityIndex(ETH_ADDRESS, msg.sender);
        
        emit DepositEther(msg.sender, msg.value, interestOnDeposit, cumulatedLiquidityIndex, block.timestamp);
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

        uint256 interestOnDeposit = vault.getInterestOnDeposit(_asset, msg.sender);
        
        // minting corresponding DToken amount to depositor
        dToken.mint(msg.sender, _amount.add(interestOnDeposit));

        // transfer deposit to the DeepWatersVault contract
        vault.transferToVault(_asset, msg.sender, _amount);

        uint256 cumulatedLiquidityIndex = vault.updateCumulatedLiquidityIndex(_asset);
        
        vault.updateUserCumulatedLiquidityIndex(_asset, msg.sender);
        
        emit DepositAsset(_asset, msg.sender, _amount, interestOnDeposit, cumulatedLiquidityIndex, block.timestamp);
    }
    
    /**
    * @dev redeems all user deposit of the asset with interest
    * @param _asset the address of the basic asset
    **/
    function redeemAllDepositWithInterest(
        address _asset
    )
        external
        nonReentrant
    {
        require(vault.getAssetIsActive(_asset), "Action requires an active asset");

        uint256 dTokenBalance = vault.getUserAssetBalance(_asset, msg.sender);
        uint256 interestOnDeposit = vault.getInterestOnDeposit(_asset, msg.sender);
        
        redeemCall(_asset, msg.sender, dTokenBalance.add(interestOnDeposit));
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
        
        redeemCall(_asset, msg.sender, _amount);
    }
    
    /**
    * @dev internal function redeem
    * @param _asset the address of the basic asset
    * @param _user the address of the user
    * @param _amount the amount being redeemed
    **/
    function redeemCall(
        address _asset,
        address payable _user,
        uint256 _amount
    )
        internal
    {
        require(_amount > 0, "Amount must be greater than 0");

        uint256 currentAssetLiquidity = vault.getAssetTotalLiquidity(_asset);
        require(_amount <= currentAssetLiquidity, "There is not enough asset liquidity to redeem");
        
        uint256 interestOnDeposit = vault.getInterestOnDeposit(_asset, _user);
        
        uint256 dTokenBalance = vault.getUserAssetBalance(_asset, _user);
        require(_amount <= dTokenBalance.add(interestOnDeposit), "Amount more than the user deposit of asset");
        
        checkNewCRatio( _asset, _user, _amount);
        
        IDToken dToken = IDToken(vault.getAssetDTokenAddress(_asset));
        
        // minting interest on deposit (corresponding DToken amount) to depositor
        dToken.mint(_user, interestOnDeposit);
        
        dToken.burn(_user, _amount);
        
        vault.transferToUser(_asset, _user, _amount);
        
        uint256 cumulatedLiquidityIndex = vault.updateCumulatedLiquidityIndex(_asset);
        
        vault.updateUserCumulatedLiquidityIndex(_asset, _user);
        
        emit Redeem(_asset, _user, _amount, interestOnDeposit, cumulatedLiquidityIndex, block.timestamp);
    }

    /**
    * @dev Before transfer dToken checks balance (including interest)
    * and new collateral ratio of user who makes the transfer.
    * If the conditions are met, then users are minted interest on the deposit.
    * The caller must be a dToken contract.
    * @param _asset the address of the basic asset
    * @param _fromUser the address of the transfer sender
    * @param _toUser the address of the transfer recipient
    * @param _amount the transfer amount
    **/
    function beforeTransferDToken(address _asset, address _fromUser, address _toUser, uint256 _amount)
        external
        onlyDTokenContract(_asset)
    {
        require(vault.getAssetIsActive(_asset), "Action requires an active asset");
        
        uint256 fromUserInterestOnDeposit = vault.getInterestOnDeposit(_asset, _fromUser);
        
        uint256 dTokenBalance = vault.getUserAssetBalance(_asset, _fromUser);
        require(_amount <= dTokenBalance.add(fromUserInterestOnDeposit), "Amount more than the user deposit of asset");
        
        checkNewCRatio( _asset, _fromUser, _amount);
        
        IDToken dToken = IDToken(vault.getAssetDTokenAddress(_asset));
        
        // minting interest on deposit (corresponding DToken amount) to transfer sender
        dToken.mint(_fromUser, fromUserInterestOnDeposit);
        
        emit MintInterestOnDeposit(_asset, _fromUser, fromUserInterestOnDeposit, block.timestamp);
        
        uint256 toUserInterestOnDeposit = vault.getInterestOnDeposit(_asset, _toUser);
        
        // minting interest on deposit (corresponding DToken amount) to transfer recipient
        dToken.mint(_toUser, toUserInterestOnDeposit);
        
        emit MintInterestOnDeposit(_asset, _toUser, toUserInterestOnDeposit, block.timestamp);
    }
    
    /**
    * @dev After transfer dToken updates cumulated liquidity index of asset
    * and cumulated liquidity index of sender and recipient of transfer
    * The caller must be a dToken contract.
    * @param _asset the address of the basic asset
    * @param _fromUser the address of the transfer sender
    * @param _toUser the address of the transfer recipient
    **/
    function afterTransferDToken(address _asset, address _fromUser, address _toUser)
        external
        onlyDTokenContract(_asset)
    {
        require(vault.getAssetIsActive(_asset), "Action requires an active asset");
        
        uint256 cumulatedLiquidityIndex = vault.updateCumulatedLiquidityIndex(_asset);
        
        vault.updateUserCumulatedLiquidityIndex(_asset, _fromUser);
        vault.updateUserCumulatedLiquidityIndex(_asset, _toUser);
        
        emit updateIndexesAfterTransferDToken(_asset, _fromUser, _toUser, cumulatedLiquidityIndex, block.timestamp);
    }
    
    /**
    * @dev check new collateral ratio
    * @param _asset the address of the basic asset
    * @param _user the address of the user
    * @param _amount the amount by which user want to decrease the collateral balance
    **/
    function checkNewCRatio(
        address _asset,
        address _user,
        uint256 _amount
    ) 
        internal
        view
    {
        (uint256 collateralBalanceUSD, uint256 borrowBalanceUSD, , , ) = dataAggregator.getUserData(_user);
        
        if (borrowBalanceUSD > 0) {
            require(
                collateralBalanceUSD.
                    sub(_amount.
                          mul(vault.getAssetPriceUSD(_asset)).
                          div(10**vault.getAssetDecimals(_asset))).
                    mul(100).
                    div(borrowBalanceUSD) >= MIN_C_RATIO,
                "New collateral ratio is less than the MIN_C_RATIO"
            );
        }
    }
    
    /**
    * @dev struct to hold borrow data
    */
    struct BorrowData {
        uint256 collateralBalanceUSD;
        uint256 borrowBalanceUSD;
        uint256 amountUSD;
        uint256 currentBorrowBalance;
        uint256 linearInterest;
        uint256 newBorrowBalance;
        uint256 newAverageStableInterestRate;
        uint256 cumulatedLiquidityIndex;
    }
    
    /**
    * @dev allows users to borrow specific amount of the basic asset
    * @param _asset the address of the basic asset
    * @param _amount the amount to be borrowed
    * @param isStableRateBorrow the true for stable mode and the false for variable mode
    **/
    function borrow(
        address _asset,
        uint256 _amount,
        bool isStableRateBorrow
    )
        external
        nonReentrant
    {
        require(msg.sender != liquidator, "Liquidator cannot borrow");
        
        require(vault.getAssetIsActive(_asset), "Action requires an active asset");
        require(_amount > 0, "Amount must be greater than 0");
        require(
            vault.getAssetTotalLiquidity(_asset) >= _amount,
            "Insufficient liquidity of the asset"
        );
        
        // Usage of a memory struct to avoid "Stack too deep" errors
        BorrowData memory data;
        
        (data.collateralBalanceUSD, data.borrowBalanceUSD, , , ) = dataAggregator.getUserData(msg.sender);
        
        require(data.collateralBalanceUSD > 0, "Zero collateral balance");
        
        data.amountUSD = vault.getAssetPriceUSD(_asset)
            .mul(_amount)
            .div(10**vault.getAssetDecimals(_asset));
        
        require(data.collateralBalanceUSD.mul(10) >= (data.borrowBalanceUSD.add(data.amountUSD)).mul(15), "Insufficient collateral ratio");
        
        data.currentBorrowBalance = vault.getUserBorrowBalance(_asset, msg.sender);
        
        require(
            data.currentBorrowBalance == 0 ||
            isStableRateBorrow == vault.isUserStableRateBorrow(_asset, msg.sender),
            "Borrow rate mode does not correspond to the already taken loan"
        );

        if (data.currentBorrowBalance == 0) {
            vault.setBorrowRateMode(_asset, msg.sender, isStableRateBorrow);
        } else {
            data.linearInterest = vault.getUserBorrowCurrentLinearInterest(_asset, msg.sender);
        }
        
        data.newBorrowBalance = data.currentBorrowBalance.add(data.linearInterest).add(_amount);
        
        if (isStableRateBorrow) {
            data.newAverageStableInterestRate = 
                _amount.mul(vault.getAssetCurrentStableInterestRate(_asset)).
                add(data.currentBorrowBalance.add(data.linearInterest).mul(vault.getUserBorrowAverageStableInterestRate(_asset, msg.sender))).
                div(data.newBorrowBalance);
            
            vault.setAverageStableInterestRate(_asset, msg.sender, data.newAverageStableInterestRate);
        }
        
        vault.updateBorrowBalance(_asset, msg.sender, data.newBorrowBalance);

        vault.transferToUser(_asset, msg.sender, _amount);
        
        data.cumulatedLiquidityIndex = vault.updateCumulatedLiquidityIndex(_asset);
        
        emit Borrow(
            _asset,
            msg.sender,
            _amount,
            isStableRateBorrow,
            data.linearInterest,
            data.newBorrowBalance,
            data.cumulatedLiquidityIndex,
            block.timestamp
        );
    }
    
    /**
    * @notice repays specified amount of ETH
    **/
    function repayEther()
        external
        payable
        nonReentrant
    {
        require(vault.getAssetIsActive(ETH_ADDRESS), "Action requires an active asset");
        require(msg.value > 0, "ETH value must be greater than 0");

        uint256 linearInterest = vault.getUserBorrowCurrentLinearInterest(ETH_ADDRESS, msg.sender);
        
        uint256 currentBorrowBalance = 
            vault.getUserBorrowBalance(ETH_ADDRESS, msg.sender).
            add(linearInterest);
            
        require(msg.value <= currentBorrowBalance, "Amount exceeds borrow");

        uint256 newBorrowBalance = currentBorrowBalance.sub(msg.value);
        
        vault.updateBorrowBalance(ETH_ADDRESS, msg.sender, newBorrowBalance);
        
        // transfer ETH to the DeepWatersVault contract
        address(vault).transfer(msg.value);
        
        uint256 cumulatedLiquidityIndex = vault.updateCumulatedLiquidityIndex(ETH_ADDRESS);
        
        emit RepayEther(
            msg.sender,
            msg.value,
            linearInterest,
            newBorrowBalance,
            cumulatedLiquidityIndex,
            block.timestamp
        );
    }
    
    /**
    * @notice repays all user borrow of the asset with interest
    * @param _asset the address of the basic asset
    **/
    function repayAllAssetBorrowWithInterest(address _asset)
        external
        nonReentrant
    {
        require(vault.getAssetIsActive(_asset), "Action requires an active asset");
        
        uint256 currentBorrowBalance = vault.getUserBorrowBalance(_asset, msg.sender);
        uint256 linearInterest = vault.getUserBorrowCurrentLinearInterest(_asset, msg.sender);
        
        repayAssetCall(_asset, msg.sender, currentBorrowBalance.add(linearInterest));
    }
    
    /**
    * @notice repays specified amount of the asset borrow
    * @param _asset the address of the basic asset
    * @param _amount the amount to be repaid
    **/
    function repayAsset(address _asset, uint256 _amount)
        external
        nonReentrant
    {
        require(vault.getAssetIsActive(_asset), "Action requires an active asset");
        
        repayAssetCall(_asset, msg.sender, _amount);
    }
    
    /**
    * @notice internal function repay for the basic asset
    * @param _asset the address of the basic asset
    * @param _user the address of the user
    * @param _amount the amount to be repaid
    **/
    function repayAssetCall(address _asset, address payable _user, uint256 _amount)
        internal
    {
        require(_amount > 0, "Amount must be greater than 0");
 
        uint256 linearInterest = vault.getUserBorrowCurrentLinearInterest(_asset, _user);
        
        uint256 currentBorrowBalance = 
            vault.getUserBorrowBalance(_asset, _user).
            add(linearInterest);
        
        require(_amount <= currentBorrowBalance, "Amount exceeds borrow");
        
        uint256 newBorrowBalance = currentBorrowBalance.sub(_amount);
        
        vault.updateBorrowBalance(_asset, _user, newBorrowBalance);

        // transfer asset to the DeepWatersVault contract
        vault.transferToVault(_asset, _user, _amount);

        uint256 cumulatedLiquidityIndex = vault.updateCumulatedLiquidityIndex(_asset);
        
        emit RepayAsset(
            _asset,
            _user,
            _amount,
            linearInterest,
            newBorrowBalance,
            cumulatedLiquidityIndex,
            block.timestamp
        );
    }
    
    /**
    * @dev struct to hold liquidation data
    */
    struct LiquidationData {
        uint256 collateralBalanceUSD;
        uint256 borrowBalanceUSD;
        uint256 healthFactor;
        address assetAddress;
        uint256 cumulatedLiquidityIndex;
    }
    
    /**
    * @dev liquidates the user if his health factor is less than 1
    * @param _user the address of the user to be liquidated
    **/
    function liquidation(address _user) external onlyLiquidator {
        require(_user != liquidator, "Liquidator cannot be liquidated");
        
        // Usage of a memory struct to avoid "Stack too deep" errors
        LiquidationData memory data;
        
        (data.collateralBalanceUSD, data.borrowBalanceUSD, , data.healthFactor, ) = dataAggregator.getUserData(_user);

        require(data.healthFactor < 100, "Health Factor is fine. The liquidation was canceled.");
        
        address[] memory assetsList = vault.getAssets();
        
        for (uint256 i = 0; i < assetsList.length; i++) {
            data.assetAddress = assetsList[i];
            
            vault.liquidationUserBorrow(data.assetAddress, _user);
            
            transferDepositToLiquidator(data.assetAddress, _user);
            
            data.cumulatedLiquidityIndex = vault.updateCumulatedLiquidityIndex(data.assetAddress);
            
            vault.updateUserCumulatedLiquidityIndex(data.assetAddress, liquidator);
        }
        
        emit UserLiquidation(_user, data.collateralBalanceUSD, data.borrowBalanceUSD, data.healthFactor, data.cumulatedLiquidityIndex, block.timestamp);
    }
    
    /**
    * @dev transfers user dTokens (as well as interest on diposite) to the liquidator
    * @param _asset the address of the basic asset
    * @param _user the address of the user to be liquidated
    **/
    function transferDepositToLiquidator(address _asset, address _user)
        internal
    {
        uint256 dTokenBalance = vault.getUserAssetBalance(_asset, _user);
        
        if (dTokenBalance > 0) {
            uint256 interestOnDeposit = vault.getInterestOnDeposit(_asset, _user);
            
            IDToken dToken = IDToken(vault.getAssetDTokenAddress(_asset));
            dToken.burn(_user, dTokenBalance);
            dToken.mint(liquidator, dTokenBalance.add(interestOnDeposit));
        }
    }
    
    
    /**
    * @notice get list of addresses of the basic assets
    **/
    function getAssets() external view returns (address[] memory) {
        return vault.getAssets();
    }
    
    function setVault(address payable _newVault) external onlyVault {
        vault = IDeepWatersVault(_newVault);
    }
    
    function setDataAggregator(address _newDataAggregator) external onlyVault {
        dataAggregator = IDeepWatersDataAggregator(_newDataAggregator);
    }
    
    function getDataAggregator() external view returns (address) {
        return address(dataAggregator);
    }
    
    function getLiquidator() external view returns (address) {
        return liquidator;
    }
}