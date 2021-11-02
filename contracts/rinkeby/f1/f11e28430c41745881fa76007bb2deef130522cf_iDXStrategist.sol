// contracts/iDXStrategist.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "./interfaces/protocols/compound/CErc20.sol";
import "./interfaces/protocols/compound/CEther.sol";
import "./interfaces/protocols/compound/Comptroller.sol";
import "./interfaces/protocols/idx/IVault.sol";
import "./interfaces/protocols/idfi/IDNFT.sol";

/**
IDX Digital Labs Strategist Smart Contract
Author: Ian Decentralize
*/

contract iDXStrategist is Initializable {

    using SafeERC20Upgradeable for IERC20Upgradeable;

    CErc20 cCOMP;
    IERC20Upgradeable COMP;
    IDNFT iDNFT;
    address public STRATEGIST;
    uint256 public vaultCount;

    mapping(address => uint256) public vaultsIds;
    mapping(uint256 => Vaults) public vaults;
    mapping(uint256 => bool) registeredIDNFT;
    mapping(uint256 => uint256) tierId;

    mapping(address => address) public cTokenAddr;
   
    struct  Vaults {
        uint256 id;
        IVault logic;
    }

    event VaultAdded(uint256 id, address logic);
    event Registered(uint256 id, address to);

     modifier onlyStrategist() {
        require(msg.sender == STRATEGIST,'IDXS Acces Control!');
        _;
    }

    function initialize (address startegist, address _idnft) public initializer{
        STRATEGIST = payable(startegist);
        COMP = IERC20Upgradeable(0xc00e94Cb662C3520282E6f5717214004A7f26888);
        cCOMP = CErc20(0x70e36f6BF80a52b3B46b3aF8e106CC0ed743E8e4);
        iDNFT = IDNFT(_idnft);
    }

    /// @notice Create and Deploy a new vault
    /// @dev Will add a contract vault to the vaults
    /// @param _vault Address of the vault
  
    function addVault(
        address _vault
    ) public 
      onlyStrategist
     {
        
        Vaults storage vault = vaults[vaultCount];
        vault.id = vaultCount;
        vault.logic = IVault(_vault);
        vaultsIds[_vault] = vaultCount;
        vaultCount += 1;
        emit VaultAdded(vault.id, _vault);
    }

    /// @notice Enter and exit Market con Com Vault
    /// @dev Borrowing from a vault increase it's yield in Comp

    function enterVaultMarket(address _vault, address cAsset) public onlyStrategist {
        Vaults memory vault = vaults[vaultsIds[_vault]];
        vault.logic._enterMarket(cAsset);
    }

    function exitCompMarket(address _vault, address cAsset) public onlyStrategist {
        Vaults memory vault = vaults[vaultsIds[_vault]];
        vault.logic._exitMarket(cAsset);
    }

    /// @notice Get Vault Return
    /// @dev Borrowing from a vault increase it's yield in Comp
    /// @param fromVault vault we borrow from
    /// @param asset asset to repay / must not be farming asset
    /// @param amount to repay
    /// @dev the funds must be in this contract

    function _VaultSwap(
        address fromVault,
        address asset,
        address cToken,
        uint256 amount
    ) public onlyStrategist returns(bool){
        Vaults memory vaultOut = vaults[vaultsIds[fromVault]];
        uint256 returnedAmount = vaultOut.logic._borrow(amount, cToken, asset);
        require(returnedAmount == amount, 'iStrategist : Borrow failed!');
        return true;
    }

    /// @notice REPAY IN A VAULT
    /// @dev The funds must be in this contract
    /// @param vaultAddress address of the vault
    /// @param cAsset asset to repay
    /// @param asset asset to repay
    /// @param amount to repay
    /// @dev the funds must be in this contract

    function _RepayCompVaultValue(
        address vaultAddress,
        address cAsset,
        address asset,
        uint256 amount
    ) public onlyStrategist {
        Vaults memory vault = vaults[vaultsIds[vaultAddress]];
        IERC20Upgradeable _asset = IERC20Upgradeable(asset);
        CErc20 _cAsset = CErc20(cAsset);
        _asset.safeApprove(address(_cAsset), amount);
        require(
            _cAsset.repayBorrowBehalf(address(vault.logic), amount) == 0,
            "iStrategist : Repay failed!"
        );
    }

    /// @notice Liquidate an account on Compound.
    /// @dev fees are already deducted on the share value based on earning
    /// @param _borrower address of the Borrower
    /// @param _amount to be repayed
    /// @param _collateral the asset to be received
    /// @param _repayed the contract to be repayed (cToken)
    /// @return value the amount transfered to this contract

     function liquidateBorrow(
            address _borrower, 
            uint _amount, 
            address _collateral, 
            address _repayed
        ) 
        public
        onlyStrategist
        returns (uint256)
    {   
        CErc20 repayedAsset = CErc20(_repayed);
        repayedAsset.approve(address(repayedAsset), _amount); 
        return  repayedAsset.liquidateBorrow(_borrower, _amount, _collateral);
        
    }

    /// @notice Create an ID NFT
    /// @param _id address of the Borrower
    /// @param _hash They Metadata for the Key
    /// @param _for the recipient of the Key
    /// @param _tier tier of the token 
    /// @return Id of the NFT just minted

        function createId(
            uint256 _id, 
            string memory _hash, 
            address _for, 
            uint256 _tier
        ) 
        public
        onlyStrategist
        returns (uint256)
    {   
        
        iDNFT.create(_id,_hash,_for,_tier);
        tierId[_id] = _tier;
        registeredIDNFT[_id] = true;
        emit Registered(_id,_for);

        return _id;
    }

    /// @notice Redeem and Withdraw fees.
    /// @dev INTERFACE 
    /// @param _vaultAddress address of the vault

    function collectFees(address _vaultAddress)
        public
        onlyStrategist 
    {
        Vaults memory vault = vaults[vaultsIds[_vaultAddress]];
        vault.logic._getFees();
        
    }

    /// @notice Redeem and Withdraw fees.
    /// @dev fees are already deducted on the share value based on earning
    /// @param _vaultAddress address of the vault

    function setFees(address _vaultAddress)
        public
        onlyStrategist 
    {
        Vaults memory vault = vaults[vaultsIds[_vaultAddress]];
        vault.logic._setFees();
        
    }

    /// @notice Pause and unPause a vault.
    /// @dev Will pause the vault preventing any transfer
    /// @param _vaultAddress address of the vault

    function pauseVault(address _vaultAddress)
        public
        onlyStrategist 
    {
        Vaults memory vault = vaults[vaultsIds[_vaultAddress]];
        vault.logic.pause();
        
    }
    
    function unpauseVault(address _vaultAddress)
        public
        onlyStrategist 
    {
        Vaults memory vault = vaults[vaultsIds[_vaultAddress]];
        vault.logic.unpause();
        
    }
    
    /// @notice Fees and claim will be sent here
    function withdraw(address _asset, uint256 _amount) public onlyStrategist {
           if(_asset == address(0)){
                payable(msg.sender).transfer(_amount);
           }else{
                IERC20Upgradeable asset = IERC20Upgradeable(_asset);
                asset.transfer(msg.sender, _amount);
           }
    }

    /// @notice Transfer ownership of the strategist role (only apply to strategist contract)
    function transferOwnership(address newStrategist) public onlyStrategist {
         STRATEGIST = payable(newStrategist);
    }

    /// @notice THIS VAULT ACCEPT ETHER
    receive() external payable {
        // nothing to do
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface CErc20 {
    function mint(uint256 mintAmount) external returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address to, uint256 amount) external;

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function borrow(uint256 borrowAmount) external returns (uint256);

    function repayBorrow(uint256 repayAmount) external returns (uint256);

    function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint);

    function exchangeRateStored() external view returns (uint256);

    function balanceOf(address _owner) external view returns (uint256);

    function borrowBalanceCurrent(address account) external returns (uint);

    function borrowBalanceStored(address account) external view returns (uint);

    function underlying() external view returns (address);

    function getCash() external view returns (uint);

    function supplyRatePerBlock() external view returns (uint);

    function borrowRatePerBlock() external view returns (uint);

    function totalBorrowsCurrent() external view returns (uint);

    function totalSupply() external view returns (uint);

    function decimals() external view returns (uint);

    function totalReserves() external view returns (uint);

    function exchangeRateCurrent() external ;

    function balanceOfUnderlying(address account) external view returns (uint);

    function liquidateBorrow(address borrower, uint amount, address collateral) external returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface CEther {
    
    function balanceOf(address owner) external view returns (uint);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address to, uint256 amount) external;

    function mint() external payable;

    function redeem(uint) external returns (uint);

    function redeemUnderlying(uint) external returns (uint);

    function exchangeRateStored() external view returns (uint256);

    function borrowBalanceCurrent(address account) external returns (uint);

    function borrow(uint borrowAmount) external returns (uint);

    function repayBorrow() external payable;

    function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint);

    function getCash() external view returns (uint);

    function supplyRatePerBlock() external view returns (uint);

    function borrowRatePerBlock() external view returns (uint);

    function totalBorrowsCurrent() external view returns (uint);

    function totalSupply() external view returns (uint);

    function totalReserves() external view returns (uint);

    function decimals() external view returns (uint);

    function exchangeRateCurrent() external;

    function balanceOfUnderlying(address account) external view returns (uint);

    function liquidateBorrow(address borrower, uint amount, address collateral) external returns (uint);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface Comptroller {

    function enterMarkets(address[] calldata) external returns (uint256[] memory);

    function exitMarket(address cToken) external returns (uint);

    function claimComp(address holder, address[] calldata) external;

    function getAssetsIn(address account) external view returns (address[] memory);

    function markets(address cTokenAddress) external view returns (bool, uint, bool);

    function getAccountLiquidity(address account) external view returns (uint, uint, uint);

    function liquidationIncentiveMantissa() external view returns (uint);

    function closeFactorMantissa() external returns (uint);

}

// CompoundVault.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IVault {

    function mint(uint256 _amount, uint256 _id) external payable returns (uint256 returnedCollateral);

    function redeem(uint256 _amount, uint256 _id) external returns (uint256 transferedAmount);

    function mintOnBehalfOf(uint256 _amount, uint256 _id) external returns (uint256 returnedCollateral);

    function vaultTier() external returns (uint256);

    function symbol() external returns (string memory);

    function fees() external view returns(uint256);

    function farming() external view returns(address);

    function collateral() external view returns(address);

    function collaterals(uint256 _id) external view returns(uint256);

    function balanceOf(uint256 _id) external view returns(uint256);

    function borrowed() external returns(address);

    function borrowedAmount() external view returns(uint256 _borrowedAmount);

    function _borrow(
        uint256 amount, 
        address cAsset, 
        address asset
        ) external  returns (uint256 _borrowed);

    function _setFees() external;  
    
    function _getFees() external;

    function _enterMarket(address cToken) external;

    function _exitMarket(address cToken) external;

    function pause() external;
    
    function unpause() external;

    function _transferOwnership(address newStrategist) external;

    function _getAssetAmount(uint256 _amount)
        external
        view
        returns (uint256 assetAmount);
    
    function claimUnderlyingReward() external returns (uint256);

    event Mint(address user, uint256 id, address asset, uint256 amount);
    event Redeem(address user, uint256 id, address asset, uint256 amount);
    event CompoundClaimed(address caller, uint256 amount);
    event Borrowed(address asset, uint256 amount);
    event Repayed(address asset, uint256 amount);
    event VaultOwnershipTransferred(address oldStrategist, address newStrategist);
 }

// CompoundVault.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IDNFT{ 

    function exchange(uint256 _amount) external;

    function claimPendingReward() external;

    function create(uint256 id_, string memory _tokenHash, address _for, uint256 _tier) external payable;

    function ownerOf(uint256 _tokenId) external view returns (address);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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