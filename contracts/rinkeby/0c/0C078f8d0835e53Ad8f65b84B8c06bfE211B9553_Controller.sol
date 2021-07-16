/**
 *Submitted for verification at Etherscan.io on 2021-07-16
*/

// File: @openzeppelin\contracts\token\ERC20\IERC20.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;


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
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: node_modules\@openzeppelin\contracts-upgradeable\utils\AddressUpgradeable.sol


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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// File: node_modules\@openzeppelin\contracts-upgradeable\proxy\utils\Initializable.sol




/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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

// File: node_modules\@openzeppelin\contracts-upgradeable\utils\ContextUpgradeable.sol




/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// File: @openzeppelin\contracts-upgradeable\access\OwnableUpgradeable.sol




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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// File: contracts\interfaces\IController.sol


interface IController {
    function getClusterAmountFromEth(uint256 _ethAmount, address _cluster) external view returns (uint256);

    function addClusterToRegister(address indexAddr) external;

    function getDHVPrice(address _cluster) external view returns (uint256);

    function getUnderlyingsInfo(address _cluster, uint256 _ethAmount)
        external
        view
        returns (
            uint256[] memory,
            uint256[] memory,
            uint256
        );

    function getUnderlyingsAmountsFromClusterAmount(uint256 _clusterAmount, address _clusterAddress) external view returns (uint256[] memory);

    function getEthAmountFromUnderlyingsAmounts(uint256[] memory _underlyingsAmounts, address _cluster) external view returns (uint256);

    function adapters(address _cluster) external view returns (address);

    function dhvTokenInstance() external view returns (address);

    function getDepositComission(address _cluster, uint256 _ethValue) external view returns (uint256);

    function getRedeemComission(address _cluster, uint256 _ethValue) external view returns (uint256);

    function getClusterPrice(address _cluster) external view returns (uint256);
}

// File: contracts\interfaces\IClusterToken.sol



interface IClusterToken {
    function assemble(bool coverDhvWithEth) external payable returns (uint256);

    function disassemble(uint256 indexAmount, bool coverDhvWithEth) external payable;

    function withdrawToAccumulation(
        address[] calldata _tokens,
        uint256[] calldata _amounts,
        uint256 _clusterAmount
    ) external;

    function refundFromAccumulation(
        address[] calldata _tokens,
        uint256[] calldata _amounts,
        uint256 _clusterAmount
    ) external;

    function optimizeProportion(uint256[] memory updatedShares) external returns (uint256[] memory debt);

    function getUnderlyingShares() external view returns (uint256[] calldata);

    function getUnderlyings() external view returns (address[] calldata);

    function getUnderlyingBalance(address _underlying) external view returns (uint256);

    function getUnderlyingsAmountsFromClusterAmount(uint256 _clusterAmount) external view returns (uint256[] calldata);

    function clusterTokenLock() external view returns (uint256);

    function clusterLock(address _token) external view returns (uint256);

    function controllerChange(address) external;
}

// File: contracts\interfaces\IDexAdapter.sol

interface IDexAdapter {
    function swapETHToUnderlying(address underlying) external payable;

    function swapUndelyingsToETH(uint256[] memory underlyingAmounts, address[] memory underlyings) external;

    function swapTokenToToken(
        uint256 _amountToSwap,
        address _tokenToSwap,
        address _tokenToReceive
    ) external returns (uint256);

    function getUnderlyingAmount(
        uint256 _amount,
        address _tokenToSwap,
        address _tokenToReceive
    ) external view returns (uint256);

    function getPath(address _tokenToSwap, address _tokenToReceive) external view returns (address[] memory);

    function getTokensPrices(address[] memory _tokens) external view returns (uint256[] memory);

    function getEthPrice() external view returns (uint256);

    function getDHVPrice(address _dhvToken) external view returns (uint256);
}

// File: contracts\interfaces\IERC20Extend.sol



interface IERC20Extend {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Returns the amound of token's decimals.
     */

    function decimals() external view returns (uint8);

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

// File: contracts\Controller.sol



contract Controller is OwnableUpgradeable, IController {
    /// @notice Instance of the DHV token instance
    address public override dhvTokenInstance;
    /// @notice Coefficient decimal for underlyings proportion
    uint256 public constant SHARES_DECIMALS = 10**6;
    /// @notice cluster Tokens decimals
    uint256 public constant CLUSTER_TOKEN_DECIMALS = 10**18;
    /// @notice Address of the cluster Factory SC
    address public clusterFactoryAddress;
    address[] public clusterRegister;
    /// @notice Stores addreses or dex-adapters for clusters.
    mapping(address => address) public override adapters;

    /// @notice Stores deposit comissions for clusters
    mapping(address => uint256) public depositComission;

    /// @notice Stores redeem comissions for clusters
    mapping(address => uint256) public redeemComission;

    /// @notice Restricts from calling function anyone but clusterFactory contract.
    modifier onlyClusterFactory() {
        require(_msgSender() == owner() || _msgSender() == clusterFactoryAddress);
        _;
    }

    /// @notice Performs initial setup.
    /// @param _dhvTokenAddress Address of the DVH token SC.
    function initialize(address _dhvTokenAddress) public initializer {
        dhvTokenInstance = _dhvTokenAddress;

        __Ownable_init();
    }

    /**********
     * ADMIN INTERFACE
     **********/

    /// @notice Sets comission (less than accuracy decimals) for the cluster assemble.
    /// @param _cluster Cluster address.
    /// @param _comission Comission percent.
    function setDepositComission(address _cluster, uint256 _comission) external onlyOwner {
        require(_comission < SHARES_DECIMALS, "Incorrect number");
        depositComission[_cluster] = _comission;
    }

    /// @notice Sets comission (less than accuracy decimals) for the cluster disassemble.
    /// @param _cluster Cluster address.
    /// @param _comission Comission percent.
    function setRedeemComission(address _cluster, uint256 _comission) external onlyOwner {
        require(_comission < SHARES_DECIMALS, "Incorrect number");
        redeemComission[_cluster] = _comission;
    }

    /// @notice Sets an address of cluster factory contract.
    /// @param _clusterFactoryAddress Address of cluster factory.
    function setClusterFactoryAddress(address _clusterFactoryAddress) public onlyOwner {
        clusterFactoryAddress = _clusterFactoryAddress;
    }

    /// @notice Sets up a swap router for cluster.
    /// @param _cluster Address of an existing ClusterToken.
    /// @param _adapter Address of swap router.
    function setAdapterForCluster(address _cluster, address _adapter) external onlyOwner {
        adapters[_cluster] = _adapter;
    }

    /// @notice Add new cluster address to the list of all cluster addresses in DeHive system.
    /// @param clusterAddr Address of the new token cluster contract.
    function addClusterToRegister(address clusterAddr) public override onlyClusterFactory {
        clusterRegister.push(clusterAddr);
    }

    function controllerChange(address _cluster, address _controller) external onlyOwner {
        IClusterToken(_cluster).controllerChange(_controller);
        for (uint256 i = 0; i < clusterRegister.length; i++) {
            if (clusterRegister[i] == _cluster) {
                clusterRegister[i] = clusterRegister[clusterRegister.length - 1];
                clusterRegister.pop();
                break;
            }
        }
    }

    /**********
     * VIEW INTERFACE
     **********/

    /// @notice Get list of indices currently registered.
    /// @return clusterRegister array.
    function getIndicesList() public view returns (address[] memory) {
        return clusterRegister;
    }

    /// @notice Calculate amount of cluster user will receive from depositing certain amount of eth for specified cluster
    /// @param _ethAmount Eth amount user sent to purchase cluster.
    /// @param _cluster Cluster address.
    /// @return Amount of cluster user can get according to current underlyings rates
    function getClusterAmountFromEth(uint256 _ethAmount, address _cluster) public view override returns (uint256) {
        address adapter = adapters[_cluster];

        address[] memory _underlyings = IClusterToken(_cluster).getUnderlyings();
        uint256[] memory _shares = IClusterToken(_cluster).getUnderlyingShares();

        uint256[] memory prices = IDexAdapter(adapter).getTokensPrices(_underlyings);
        (, uint256 proportionDenominator) = _getTokensProportions(_shares, prices);
        return (_ethAmount * 10**18) / proportionDenominator;
    }

    /// @notice Calculates amounts of underlyings in some amount of cluster.
    /// @dev Currently, returns all underlyings with 18 decimals.
    /// @param _clusterAmount Amount of cluster to calculate underlyings from.
    /// @param _clusterAddress Address of cluster token.
    /// @return Array, which contains amounts of underlyings.
    function getUnderlyingsAmountsFromClusterAmount(uint256 _clusterAmount, address _clusterAddress)
        external
        view
        override
        returns (uint256[] memory)
    {
        uint256 totalCluster = IERC20(_clusterAddress).totalSupply();
        uint256 clusterShare = (_clusterAmount * CLUSTER_TOKEN_DECIMALS) / totalCluster;

        address[] memory _underlyings = IClusterToken(_clusterAddress).getUnderlyings();
        uint256[] memory underlyingsAmount = new uint256[](_underlyings.length);

        for (uint256 i = 0; i < _underlyings.length; i++) {
            uint256 amount = IClusterToken(_clusterAddress).getUnderlyingBalance(_underlyings[i]);
            underlyingsAmount[i] = (amount * clusterShare) / CLUSTER_TOKEN_DECIMALS;
        }

        return underlyingsAmount;
    }

    /// @notice Calculates the amount of ETH, which we can get from underlying tokens amounts.
    /// @param _underlyingsAmounts Array, which contains amount of each underlying.
    /// @param _cluster Cluster address.
    /// @return Amount of ETH, which can be got from underlyings amounts.
    function getEthAmountFromUnderlyingsAmounts(uint256[] memory _underlyingsAmounts, address _cluster)
        external
        view
        override
        returns (uint256)
    {
        address[] memory _underlyings = IClusterToken(_cluster).getUnderlyings();
        uint256[] memory prices = IDexAdapter(adapters[_cluster]).getTokensPrices(_underlyings);
        uint256 ethAmount = 0;
        for (uint256 i = 0; i < _underlyings.length; i++) {
            ethAmount += (_underlyingsAmounts[i] * prices[i]) / 10**(IERC20Extend(_underlyings[i]).decimals());
        }
        return ethAmount;
    }

    /// @notice Calculates an amount of underlyings in some amount of eth.
    /// @param _cluster Cluster to check info.
    /// @param _ethAmount Amount of eth.
    /// @return Array of underlyings amounts, array of portions of eth to spend on each underlying and the price of the cluster.
    function getUnderlyingsInfo(address _cluster, uint256 _ethAmount)
        public
        view
        override
        returns (
            uint256[] memory,
            uint256[] memory,
            uint256
        )
    {
        address adapter = adapters[_cluster];
        address[] memory _underlyings = IClusterToken(_cluster).getUnderlyings();
        uint256[] memory _shares = IClusterToken(_cluster).getUnderlyingShares();

        uint256[] memory prices = IDexAdapter(adapter).getTokensPrices(_underlyings);
        (uint256[] memory proportions, uint256 proportionDenominator) = _getTokensProportions(_shares, prices);

        uint256[] memory underlyingsAmounts = new uint256[](_underlyings.length);
        uint256[] memory ethPortions = new uint256[](_underlyings.length);

        for (uint256 i = 0; i < _underlyings.length; i++) {
            ethPortions[i] = (_ethAmount * proportions[i]) / proportionDenominator;
            underlyingsAmounts[i] = IDexAdapter(adapter).getUnderlyingAmount(ethPortions[i], address(0), _underlyings[i]);
        }

        return (underlyingsAmounts, ethPortions, proportionDenominator);
    }

    function getDHVPrice(address _cluster) public view override returns (uint256) {
        return IDexAdapter(adapters[_cluster]).getDHVPrice(dhvTokenInstance);
    }

    function getClusterPrice(address _cluster) external view override returns (uint256) {
        address adapter = adapters[_cluster];
        address[] memory _underlyings = IClusterToken(_cluster).getUnderlyings();
        uint256[] memory _shares = IClusterToken(_cluster).getUnderlyingShares();

        uint256[] memory prices = IDexAdapter(adapter).getTokensPrices(_underlyings);
        (, uint256 proportionDenominator) = _getTokensProportions(_shares, prices);

        return proportionDenominator;
    }

    /// @notice Calculates the proportions of underlyings.
    /// @param _shares Array of underlyings' shares in cluster token.
    /// @param _prices Array of underlyings' prices in $.
    /// @return Underlyings proportions based on shares and prices and proportion denominator.
    function _getTokensProportions(uint256[] memory _shares, uint256[] memory _prices) internal pure returns (uint256[] memory, uint256) {
        uint256[] memory proportions = new uint256[](_shares.length);
        uint256 proportionDenominator = 0;
        for (uint256 i = 0; i < _shares.length; i++) {
            proportions[i] = (_shares[i] * _prices[i]) / SHARES_DECIMALS;
            proportionDenominator += proportions[i];
        }
        return (proportions, proportionDenominator);
    }

    function getDepositComission(address _cluster, uint256 _ethValue) external view override returns (uint256) {
        return (_ethValue * depositComission[_cluster]) / SHARES_DECIMALS;
    }

    function getRedeemComission(address _cluster, uint256 _ethValue) external view override returns (uint256) {
        return (_ethValue * redeemComission[_cluster]) / SHARES_DECIMALS;
    }
}