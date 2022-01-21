/**
 *Submitted for verification at Etherscan.io on 2022-01-21
*/

// File: ../deepwaters/contracts/security/ReentrancyGuard.sol

pragma solidity ^0.8.10;

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

    constructor () {
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

// File: ../deepwaters/contracts/libraries/Address.sol

pragma solidity ^0.8.10;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: ../deepwaters/contracts/interfaces/IDToken.sol

pragma solidity ^0.8.10;

/**
* @dev Interface for a DToken contract
 **/

interface IDToken {
    function balanceOf(address _user) external view returns(uint256);
    function changeDeepWatersContracts(address _newLendingContract, address payable _newVault) external;
    function mint(address _user, uint256 _amount) external;
    function burn(address _user, uint256 _amount) external;
}

// File: ../deepwaters/contracts/interfaces/IDeepWatersVault.sol

pragma solidity ^0.8.10;

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
    function transferToRouter(address _asset, uint256 _amount) external;
    function updateBorrowBalance(address _asset, address _user, uint256 _newBorrowBalance) external;
    function setAverageStableInterestRate(address _asset, address _user, uint256 _newAverageStableInterestRate) external;
    function getUserBorrowCurrentLinearInterest(address _asset, address _user) external view returns (uint256);
    function setBorrowRateMode(address _asset, address _user, bool _isStableRateBorrow) external;
    receive() external payable;
}

// File: ../deepwaters/contracts/interfaces/IDeepWatersDataAggregator.sol

pragma solidity ^0.8.10;

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

// File: ../deepwaters/contracts/DeepWatersLending.sol

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;






/**
* @title DeepWatersLending contract
* @notice Implements the lending actions
* @author DeepWaters
 **/
contract DeepWatersLending is ReentrancyGuard {
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
    * @dev emitted before the transfer of the DToken
    * @param _asset the address of the basic asset
    * @param _fromUser the address of the transfer sender
    * @param _toUser the address of the transfer recipient
    * @param _cumulatedLiquidityIndex the cumulated liquidity index
    * @param _fromUserInterestOnDeposit the interest paid on the sender deposit
    * @param _toUserInterestOnDeposit the interest paid on the recipient deposit
    * @param _timestamp the timestamp of the action
    **/
    event BeforeTransferDToken(
        address indexed _asset,
        address indexed _fromUser,
        address indexed _toUser,
        uint256 _cumulatedLiquidityIndex,
        uint256 _fromUserInterestOnDeposit,
        uint256 _toUserInterestOnDeposit,
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
    * @param _timestamp the timestamp of the action
    **/
    event UserLiquidation(
        address indexed _user,
        uint256 _collateralBalanceUSD,
        uint256 _borrowBalanceUSD,
        uint256 _healthFactor,
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
    ) {
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
        
        uint256 cumulatedLiquidityIndex = vault.updateCumulatedLiquidityIndex(ETH_ADDRESS);
        vault.updateUserCumulatedLiquidityIndex(ETH_ADDRESS, msg.sender);
        
        // minting corresponding DToken amount to depositor
        dToken.mint(msg.sender, msg.value + interestOnDeposit);

        // transfer deposit to the DeepWatersVault contract
        payable(address(vault)).transfer(msg.value);        
        
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
        
        uint256 cumulatedLiquidityIndex = vault.updateCumulatedLiquidityIndex(_asset);
        vault.updateUserCumulatedLiquidityIndex(_asset, msg.sender);
        
        // minting corresponding DToken amount to depositor
        dToken.mint(msg.sender, _amount + interestOnDeposit);

        // transfer deposit to the DeepWatersVault contract
        vault.transferToVault(_asset, payable(msg.sender), _amount);
        
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
        
        redeemCall(_asset, payable(msg.sender), dTokenBalance + interestOnDeposit);
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
        
        redeemCall(_asset, payable(msg.sender), _amount);
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
        require(_amount <= dTokenBalance + interestOnDeposit, "Amount more than the user deposit of asset");
        
        checkNewCRatio( _asset, _user, _amount);
        
        uint256 cumulatedLiquidityIndex = vault.updateCumulatedLiquidityIndex(_asset);
        vault.updateUserCumulatedLiquidityIndex(_asset, _user);
        
        IDToken dToken = IDToken(vault.getAssetDTokenAddress(_asset));
        
        // minting interest on deposit (corresponding DToken amount) to depositor
        dToken.mint(_user, interestOnDeposit);
        
        dToken.burn(_user, _amount);
        
        vault.transferToUser(_asset, _user, _amount);
        
        emit Redeem(_asset, _user, _amount, interestOnDeposit, cumulatedLiquidityIndex, block.timestamp);
    }

    /**
    * @dev Before transfer dToken checks balance (including interest)
    * and new collateral ratio of user who makes the transfer.
    * Updates cumulated liquidity index of asset and cumulated liquidity index of sender and recipient of transfer.
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
        require(_fromUser != _toUser, "Sending tokens to the sender's address");
        require(vault.getAssetIsActive(_asset), "Action requires an active asset");
        
        uint256 fromUserInterestOnDeposit = vault.getInterestOnDeposit(_asset, _fromUser);
        uint256 toUserInterestOnDeposit = vault.getInterestOnDeposit(_asset, _toUser);
        
        uint256 dTokenBalance = vault.getUserAssetBalance(_asset, _fromUser);
        require(_amount <= dTokenBalance + fromUserInterestOnDeposit, "Amount more than the user deposit of asset");
        
        checkNewCRatio(_asset, _fromUser, _amount);
        
        uint256 cumulatedLiquidityIndex = vault.updateCumulatedLiquidityIndex(_asset);
        
        vault.updateUserCumulatedLiquidityIndex(_asset, _fromUser);
        vault.updateUserCumulatedLiquidityIndex(_asset, _toUser);
        
        IDToken dToken = IDToken(vault.getAssetDTokenAddress(_asset));
        
        // minting interest on deposit (corresponding DToken amount) to transfer sender
        dToken.mint(_fromUser, fromUserInterestOnDeposit);
        
        // minting interest on deposit (corresponding DToken amount) to transfer recipient
        dToken.mint(_toUser, toUserInterestOnDeposit);
        
        emit BeforeTransferDToken(_asset, _fromUser, _toUser, cumulatedLiquidityIndex, fromUserInterestOnDeposit, toUserInterestOnDeposit, block.timestamp);
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
                (collateralBalanceUSD -
                    (_amount * vault.getAssetPriceUSD(_asset) /
                      10**vault.getAssetDecimals(_asset))) *
                  100 / borrowBalanceUSD >= MIN_C_RATIO,
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
        _borrow(_asset, payable(msg.sender), _amount, isStableRateBorrow);
    }
    
    /**
    * @dev internal function to borrow specific amount of the basic asset by the user
    * @param _asset the address of the basic asset
    * @param _user the address of the user
    * @param _amount the amount to be borrowed
    * @param isStableRateBorrow the true for stable mode and the false for variable mode
    **/
    function _borrow(
        address _asset,
        address payable _user,
        uint256 _amount,
        bool isStableRateBorrow
    )
        internal
    {
        require(_user != liquidator, "Liquidator cannot borrow");
        
        require(vault.getAssetIsActive(_asset), "Action requires an active asset");
        require(_amount > 0, "Amount must be greater than 0");
        require(
            vault.getAssetTotalLiquidity(_asset) >= _amount,
            "Insufficient liquidity of the asset"
        );
        
        // Usage of a memory struct to avoid "Stack too deep" errors
        BorrowData memory data;
        
        (data.collateralBalanceUSD, data.borrowBalanceUSD, , , ) = dataAggregator.getUserData(_user);
        
        require(data.collateralBalanceUSD > 0, "Zero collateral balance");
        
        data.amountUSD = vault.getAssetPriceUSD(_asset) * _amount /
                            10**vault.getAssetDecimals(_asset);
        
        require(data.collateralBalanceUSD * 10 >= (data.borrowBalanceUSD + data.amountUSD) * 15, "Insufficient collateral ratio");
        
        data.currentBorrowBalance = vault.getUserBorrowBalance(_asset, _user);
        
        require(
            data.currentBorrowBalance == 0 ||
            isStableRateBorrow == vault.isUserStableRateBorrow(_asset, _user),
            "Borrow rate mode does not correspond to the already taken loan"
        );

        if (data.currentBorrowBalance == 0) {
            vault.setBorrowRateMode(_asset, _user, isStableRateBorrow);
        } else {
            data.linearInterest = vault.getUserBorrowCurrentLinearInterest(_asset, _user);
        }
        
        data.newBorrowBalance = data.currentBorrowBalance + data.linearInterest + _amount;
        
        data.cumulatedLiquidityIndex = vault.updateCumulatedLiquidityIndex(_asset);
        
        if (isStableRateBorrow) {
            data.newAverageStableInterestRate = 
                (_amount * vault.getAssetCurrentStableInterestRate(_asset) +
                    ((data.currentBorrowBalance + data.linearInterest) * vault.getUserBorrowAverageStableInterestRate(_asset, _user))) /
                  data.newBorrowBalance;
            
            vault.setAverageStableInterestRate(_asset, _user, data.newAverageStableInterestRate);
        }
        
        vault.updateBorrowBalance(_asset, _user, data.newBorrowBalance);

        vault.transferToUser(_asset, _user, _amount);
        
        emit Borrow(
            _asset,
            _user,
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
            vault.getUserBorrowBalance(ETH_ADDRESS, msg.sender) +
            linearInterest;
            
        require(msg.value <= currentBorrowBalance, "Amount exceeds borrow");

        uint256 newBorrowBalance = currentBorrowBalance - msg.value;

        uint256 cumulatedLiquidityIndex = vault.updateCumulatedLiquidityIndex(ETH_ADDRESS);
        
        vault.updateBorrowBalance(ETH_ADDRESS, msg.sender, newBorrowBalance);
        
        // transfer ETH to the DeepWatersVault contract
        payable(address(vault)).transfer(msg.value);
        
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
        
        repayAssetCall(_asset, payable(msg.sender), currentBorrowBalance + linearInterest);
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
        
        repayAssetCall(_asset, payable(msg.sender), _amount);
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
            vault.getUserBorrowBalance(_asset, _user) +
            linearInterest;
        
        require(_amount <= currentBorrowBalance, "Amount exceeds borrow");
        
        uint256 newBorrowBalance = currentBorrowBalance - _amount;
        
        uint256 cumulatedLiquidityIndex = vault.updateCumulatedLiquidityIndex(_asset);
        
        vault.updateBorrowBalance(_asset, _user, newBorrowBalance);

        // transfer asset to the DeepWatersVault contract
        vault.transferToVault(_asset, _user, _amount);

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
    * @dev allows borrowers to switch between stable and variable borrow rate modes.
    * @param _asset the address of the borrowed asset
    **/
    function switchBorrowRateMode(address _asset)
        external
        nonReentrant
    {
        require(vault.getAssetIsActive(_asset), "Action requires an active asset");
        
        uint256 borrowBalance = vault.getUserBorrowBalance(_asset, msg.sender) +
                                  vault.getUserBorrowCurrentLinearInterest(_asset, msg.sender);
        
        require(borrowBalance > 0, "The user has no borrow");
        
        bool newIsStableRateBorrow = !vault.isUserStableRateBorrow(_asset, msg.sender);
        
        repayAssetCall(_asset, payable(msg.sender), borrowBalance);
        
        _borrow(_asset, payable(msg.sender), borrowBalance, newIsStableRateBorrow);
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
            
            data.cumulatedLiquidityIndex = vault.updateCumulatedLiquidityIndex(data.assetAddress);
            vault.updateUserCumulatedLiquidityIndex(data.assetAddress, liquidator);
            
            vault.liquidationUserBorrow(data.assetAddress, _user);
            
            transferDepositToLiquidator(data.assetAddress, _user);
        }
        
        emit UserLiquidation(_user, data.collateralBalanceUSD, data.borrowBalanceUSD, data.healthFactor, block.timestamp);
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
            dToken.mint(liquidator, dTokenBalance + interestOnDeposit);
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