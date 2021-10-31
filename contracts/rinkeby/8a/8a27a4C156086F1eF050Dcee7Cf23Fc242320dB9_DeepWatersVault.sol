/**
 *Submitted for verification at Etherscan.io on 2021-10-31
*/

// File: contracts/access/Ownable.sol

pragma solidity ^0.5.16;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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

// File: contracts/token/ERC20.sol

pragma solidity ^0.5.16;



/**
 * @dev Implementation of the `IERC20` interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using `_mint`.
 * For a generic mechanism see `ERC20Mintable`.
 *
 * *For a detailed writeup see our guide [How to implement supply
 * mechanisms](https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226).*
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an `Approval` event is emitted on calls to `transferFrom`.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard `decreaseAllowance` and `increaseAllowance`
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See `IERC20.approve`.
 */
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See `IERC20.totalSupply`.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See `IERC20.balanceOf`.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See `IERC20.transfer`.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See `IERC20.allowance`.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See `IERC20.approve`.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev See `IERC20.transferFrom`.
     *
     * Emits an `Approval` event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of `ERC20`;
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `value`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to `transfer`, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a `Transfer` event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a `Transfer` event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

     /**
     * @dev Destoys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a `Transfer` event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an `Approval` event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Destoys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See `_burn` and `_approve`.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
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

// File: contracts/libraries/SafeERC20.sol

pragma solidity ^0.5.16;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts/interfaces/IDeepWatersPriceOracle.sol

pragma solidity ^0.5.16;

/**
 * @dev Interface for a DeepWaters price oracle.
 */
interface IDeepWatersPriceOracle {
    function getAssetPrice(address asset) external view returns (uint256);
    function getAssetsPrices(address[] calldata assets) external view returns (uint256[] memory);
    function getFallbackAssetPrice(address asset) external view returns (uint256);
    function getFallbackAssetsPrices(address[] calldata assets) external view returns (uint256[] memory);
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

// File: contracts/interfaces/IDeepWatersLending.sol

pragma solidity ^0.5.16;

/**
* @dev Interface for a DeepWatersLending contract
 **/

interface IDeepWatersLending {
    function setVault(address payable _newVault) external;
    function setDataAggregator(address _newDataAggregator) external;
    function getDataAggregator() external view returns (address);
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

// File: contracts/DeepWatersVault.sol

pragma solidity ^0.5.16;









/**
* @title DeepWatersVault contract
* @author DeepWaters
* @notice Holds all the funds deposited
**/
contract DeepWatersVault is IDeepWatersVault, Ownable {
    using SafeERC20 for ERC20;
    using SafeMath for uint256;
    using Address for address payable;

    struct Asset {
        uint256 decimals; // the decimals of the asset
        address dTokenAddress; // @dev address of the dToken representing the asset
        bool isActive; // isActive = true means the asset has been activated
    }

    address public lendingContractAddress;
    address public previousVaultAddress;
    
    /**
    * @dev only lending contract can use functions affected by this modifier
    **/
    modifier onlyLendingContract {
        require(lendingContractAddress == msg.sender, "The caller must be a lending contract");
        _;
    }

    // the address used to identify ETH
    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    
    mapping(address => Asset) internal assets;
    mapping(address => mapping(address => uint256)) internal usersBorrowBalances;
    mapping(address => bool) internal users;
    
    address[] public addedAssetsList;
    address[] public usersList;
    
    address priceOracleAddress = 0x9402FF6EEDF8DEAc71A1F854fB6A7CC54aAB8733;
    
    constructor(address _previousVaultAddress) public {
        previousVaultAddress = _previousVaultAddress;
    }
    
    /**
    * @dev update lendingContractAddress
    * @param _newLendingContract the address of the DeepWatersLending contract
    **/
    function setLendingContract(address _newLendingContract) external onlyOwner {
        lendingContractAddress = _newLendingContract;
        
        Asset memory asset;
        IDToken dToken;
        
        for (uint256 i = 0; i < addedAssetsList.length; i++) {
            asset = assets[addedAssetsList[i]];
           
            dToken = IDToken(asset.dTokenAddress);
            dToken.changeDeepWatersContracts(_newLendingContract, address(this));
        }
    }
    
    /**
    * @dev fallback function enforces that the caller is a contract
    **/
    function() external payable {
        require(msg.sender.isContract(), "Only contracts can send ETH to the DeepWatersVault contract");
    }

    /**
    * @dev transfers an asset from a depositor to the DeepWatersVault contract
    * @param _asset the address of the asset where the amount is being transferred
    * @param _depositor the address of the depositor from where the transfer is happening
    * @param _amount the asset amount being transferred
    **/
    function transferToVault(address _asset, address payable _depositor, uint256 _amount) external onlyLendingContract {
        ERC20(_asset).safeTransferFrom(_depositor, address(this), _amount);
    }
    
    /**
    * @dev transfers to the user a specific amount of asset from the DeepWatersVault contract.
    * @param _asset the address of the asset
    * @param _user the address of the user receiving the transfer
    * @param _amount the amount being transferred
    **/
    function transferToUser(address _asset, address payable _user, uint256 _amount) external onlyLendingContract {
        if (_asset == ETH_ADDRESS) {
            _user.transfer(_amount);
        } else {
            ERC20(_asset).safeTransfer(_user, _amount);
        }
    }

    /**
    * @dev updates the user's borrow balance
    * @param _asset the address of the borrowed asset
    * @param _user the address of the borrower
    * @param _newBorrowBalance new value of borrow balance
    **/
    function updateBorrowBalance(address _asset, address _user, uint256 _newBorrowBalance) external {
        require(
            msg.sender == lendingContractAddress || msg.sender == previousVaultAddress,
            "The caller must be a lending contract or previous vault contract"
        );
    
        if (!users[_user]) {
            users[_user] = true;
            usersList.push(_user);
        }
        
        usersBorrowBalances[_asset][_user] = _newBorrowBalance;
    }
   
    /**
    * @dev gets the basic asset balance of a user based on the corresponding dToken balance.
    * @param _asset the asset address
    * @param _user the user address
    * @return the basic asset balance of the user
    **/
    function getUserAssetBalance(address _asset, address _user) public view returns (uint256) {
        IDToken dToken = IDToken(assets[_asset].dTokenAddress);
        return dToken.balanceOf(_user);
    }
    
    /**
    * @dev gets the borrow balance of a user for the asset
    * @param _asset the asset address
    * @param _user the user address
    * @return borrow balance of the user
    **/
    function getUserBorrowBalance(address _asset, address _user) external view returns (uint256) {
        return usersBorrowBalances[_asset][_user];
    }

    /**
    * @dev gets the dToken contract address for the asset
    * @param _asset the asset address
    * @return the address of the dToken contract
    **/
    function getAssetDTokenAddress(address _asset) public view returns (address) {
        Asset storage asset = assets[_asset];
        return asset.dTokenAddress;
    }

    /**
    * @dev gets the asset total liquidity.
    *   The total liquidity is the balance of the asset in the DeepWatersVault contract
    * @param _asset the asset address
    * @return the asset total liquidity
    **/
    function getAssetTotalLiquidity(address _asset) public view returns (uint256) {
        uint256 balance;

        if (_asset == ETH_ADDRESS) {
            balance = address(this).balance;
        } else {
            balance = IERC20(_asset).balanceOf(address(this));
        }
        return balance;
    }

    /**
    * @dev returns the decimals of the asset
    * @param _asset the asset address
    * @return the asset decimals
    **/
    function getAssetDecimals(address _asset) external view returns (uint256) {
        return assets[_asset].decimals;
    }

    /**
    * @dev returns true if the asset is active
    * @param _asset the asset address
    * @return true if the asset is active, false otherwise
    **/
    function getAssetIsActive(address _asset) external view returns (bool) {
        Asset storage asset = assets[_asset];
        return asset.isActive;
    }

    /**
    * @return the array of assets added on the vault
    **/
    function getAssets() external view returns (address[] memory) {
        return addedAssetsList;
    }

    /**
    * @dev initializes an asset
    * @param _asset the address of the asset
    * @param _dTokenAddress the address of the corresponding dToken contract
    * @param _decimals the number of decimals of the asset
    **/
    function initAsset(
        address _asset,
        address _dTokenAddress,
        uint256 _decimals,
        bool _isActive
    ) public {
        require(
            isOwner() || msg.sender == previousVaultAddress,
            "The caller must be owner or previous vault contract"
        );
        
        Asset storage asset = assets[_asset];
        require(asset.dTokenAddress == address(0), "Asset has already been initialized");

        asset.dTokenAddress = _dTokenAddress;
        asset.decimals = _decimals;
        asset.isActive = _isActive;
        
        bool currentAssetAdded = false;
        for (uint256 i = 0; i < addedAssetsList.length; i++) {
            if (addedAssetsList[i] == _asset) {
                currentAssetAdded = true;
            }
        }
        
        if (!currentAssetAdded) {
            addedAssetsList.push(_asset);
        }
    }

    /**
    * @dev activates an asset
    * @param _asset the address of the asset
    **/
    function activateAsset(address _asset) external onlyOwner {
        Asset storage asset = assets[_asset];

        require(asset.dTokenAddress != address(0), "Asset has not been initialized");
        
        asset.isActive = true;
    }
    
    /**
    * @dev deactivates an asset
    * @param _asset the address of the asset
    **/
    function deactivateAsset(address _asset) external onlyOwner {
        Asset storage asset = assets[_asset];
        asset.isActive = false;
    }
    
    function getAssetPriceUSD(address _asset) external view returns (uint256) {
        IDeepWatersPriceOracle priceOracle = IDeepWatersPriceOracle(priceOracleAddress);
        return priceOracle.getAssetPrice(_asset);
    }
    
    /**
    * @notice migration vault
    * @param _newLendingContract the address of new DeepWatersLending contract
    * @param _newVault the address of new DeepWatersVault contract
    **/
    function migrationToNewVault(address _newLendingContract, address payable _newVault) external onlyOwner {
        DeepWatersVault newVault = DeepWatersVault(_newVault);
        
        address assetAddress;
        Asset memory asset;
        IDToken dToken;
        address user;
        uint256 userBorrowBalance;
        
        IDeepWatersLending lendingContract = IDeepWatersLending(_newLendingContract);
        lendingContract.setVault(_newVault);
        
        IDeepWatersDataAggregator dataAggregator = IDeepWatersDataAggregator(lendingContract.getDataAggregator());
        dataAggregator.setVault(_newVault);
        
        for (uint256 i = 0; i < addedAssetsList.length; i++) {
            assetAddress = addedAssetsList[i];
            asset = assets[assetAddress];
           
            newVault.initAsset(assetAddress, asset.dTokenAddress, asset.decimals, asset.isActive);
            
            dToken = IDToken(asset.dTokenAddress);
            dToken.changeDeepWatersContracts(_newLendingContract, _newVault);
            
            for (uint256 j = 0; j < usersList.length; j++) {
                user = usersList[j];
                userBorrowBalance = usersBorrowBalances[assetAddress][user];
                
                if (userBorrowBalance > 0) {
                    newVault.updateBorrowBalance(assetAddress, user, userBorrowBalance);
                }
            }
        }
    }
    
    function setDataAggregator(address _newDataAggregator) external onlyOwner {
        IDeepWatersLending lendingContract = IDeepWatersLending(lendingContractAddress);
        lendingContract.setDataAggregator(_newDataAggregator);
    }
}