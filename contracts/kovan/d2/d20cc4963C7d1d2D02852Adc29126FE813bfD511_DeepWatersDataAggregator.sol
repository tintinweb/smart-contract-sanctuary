/**
 *Submitted for verification at Etherscan.io on 2022-01-21
*/

// File: ../deepwaters/contracts/interfaces/IERC20.sol

pragma solidity ^0.8.10;

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

// File: ../deepwaters/contracts/token/extensions/IERC20Metadata.sol

pragma solidity ^0.8.10;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: ../deepwaters/contracts/libraries/Context.sol

pragma solidity ^0.8.10;

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

// File: ../deepwaters/contracts/token/ERC20.sol

pragma solidity ^0.8.10;



/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
            unchecked {
                _approve(sender, _msgSender(), currentAllowance - amount);
            }
        }

        _transfer(sender, recipient, amount);

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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

// File: ../deepwaters/contracts/DeepWatersDataAggregator.sol

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;




/**
* @title DeepWatersDataAggregator contract
* @author DeepWaters
* @notice Implements functions to fetch aggregated data from the DeepWatersVault contract
**/
contract DeepWatersDataAggregator is IDeepWatersDataAggregator {
    IDeepWatersVault public vault;
    
    // the address used to identify ETH
    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    
    modifier onlyVault {
        require(msg.sender == address(vault), "The caller of this function must be a DeepWatersVault contract");
        _;
    }
    
    constructor(
        address payable _vault
    ) {
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
            assetName = ERC20(_asset).name();
            assetSymbol = ERC20(_asset).symbol();
        }

        decimals = vault.getAssetDecimals(_asset);
        isActive = vault.getAssetIsActive(_asset);
        dTokenAddress = vault.getAssetDTokenAddress(_asset);
        
        totalLiquidity = vault.getAssetTotalLiquidity(_asset);
        assetPriceUSD = vault.getAssetPriceUSD(_asset);
        totalLiquidityUSD = assetPriceUSD * totalLiquidity / 10**decimals;
        
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
    * @return assetName the basic asset name
    *         assetSymbol the basic asset symbol
    *         decimals the basic asset decimals
    *         dTokenBalance the user deposit balance of the asset
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
        
        dTokenBalance = vault.getUserAssetBalance(_asset, _user) + vault.getInterestOnDeposit(_asset, _user);
        dTokenBalanceUSD = assetPriceUSD * dTokenBalance / 10**decimals;
        
        borrowBalance = vault.getUserBorrowBalance(_asset, _user) + vault.getUserBorrowCurrentLinearInterest(_asset, _user);
        borrowBalanceUSD = assetPriceUSD * borrowBalance / 10**decimals;
        
        ( , , , , availableToBorrowUSD) = getUserData(_user);
        
        uint256 currentAssetLiquidity = vault.getAssetTotalLiquidity(_asset);
        uint256 currentAssetLiquidityUSD = assetPriceUSD * currentAssetLiquidity / 10**decimals;
        
        if (availableToBorrowUSD > currentAssetLiquidityUSD) {
            availableToBorrowUSD = currentAssetLiquidityUSD;
        }
        
        availableToBorrow = availableToBorrowUSD * 10**decimals / assetPriceUSD;
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
                vault.getUserAssetBalance(currentAssetUserData.assetAddress, _user) +
                vault.getInterestOnDeposit(currentAssetUserData.assetAddress, _user);
                
            currentAssetUserData.borrowBalance = 
                vault.getUserBorrowBalance(currentAssetUserData.assetAddress, _user) +
                vault.getUserBorrowCurrentLinearInterest(currentAssetUserData.assetAddress, _user);
            
            if (currentAssetUserData.balance == 0 && currentAssetUserData.borrowBalance == 0) {
                continue;
            }
            
            currentAssetUserData.decimals = vault.getAssetDecimals(currentAssetUserData.assetAddress);
            currentAssetUserData.assetPriceUSD = vault.getAssetPriceUSD(currentAssetUserData.assetAddress);
            
            collateralBalanceUSD = collateralBalanceUSD +
                currentAssetUserData.assetPriceUSD *
                    currentAssetUserData.balance /
                    10**currentAssetUserData.decimals;
            
            borrowBalanceUSD = borrowBalanceUSD +
                currentAssetUserData.assetPriceUSD *
                    currentAssetUserData.borrowBalance /
                    10**currentAssetUserData.decimals;
        }
        
        if (borrowBalanceUSD == 0) {
            collateralRatio = 0;
            healthFactor = 0;
        } else {
            collateralRatio = collateralBalanceUSD * 100 / borrowBalanceUSD;
            healthFactor = collateralBalanceUSD * 80 / borrowBalanceUSD;
        }
        
        availableToBorrowUSD = collateralBalanceUSD * 100 / 150 - borrowBalanceUSD;
    }
    
    function setVault(address payable _newVault) external onlyVault {
        vault = IDeepWatersVault(_newVault);
    }
}