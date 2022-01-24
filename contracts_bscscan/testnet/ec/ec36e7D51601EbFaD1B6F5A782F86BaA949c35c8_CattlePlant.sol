// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

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
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721HolderUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    function __ERC721Holder_init() internal onlyInitializing {
        __ERC721Holder_init_unchained();
    }

    function __ERC721Holder_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interface/IPlant721.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../interface/IBvInfo.sol";

contract CattlePlant is OwnableUpgradeable, ERC721HolderUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    IERC20Upgradeable public BVG;
    IERC20Upgradeable public BVT;
    IPlant721 public plant;
    IBvInfo public bvInfo;
    uint public febLimit;
    uint public battleTaxRate;
    uint public federalPrice;
    address public banker;
    uint[] public currentPlant;
    uint public technologyCost;
    uint public upGradePlantPrice;
    function initialize() public initializer{
        __Context_init_unchained();
        __Ownable_init_unchained();
        battleTaxRate = 30;
        federalPrice = 500 ether;
        technologyCost = 100 ether;
        upGradePlantPrice = 500 ether;
    }
    struct PlantInfo {
        address owner;
        uint tax;
        uint population;
        mapping(uint => uint) technology;
        uint normalTaxAmount;
        uint battleTaxAmount;
        uint motherPlant;
        uint types;
        uint membershipFee;
        uint populationLimit;
        uint federalLimit;
        uint federalAmount;
    }

    struct PlantType {
        uint populationLimit;
        uint federalLimit;
        uint plantTax;
    }

    struct UserInfo {
        uint level;
        uint plant;
    }

    struct ApplyInfo {
        uint applyAmount;
        uint applyTax;
        uint lockAmount;

    }

    mapping(uint => PlantInfo) public plantInfo;
    mapping(address => UserInfo) public userInfo;
    mapping(address => uint) public ownerOfPlant;
    mapping(address => ApplyInfo) public applyInfo;
    mapping(address => bool) public admin;
    mapping(uint => PlantType) public plantType;
    mapping(uint => uint) public technologyPrice;

    event BondPlant(address indexed player, uint indexed tokenId);
    event ApplyFederalPlant (address indexed player, uint indexed amount, uint tax);
    event CancelApply(address indexed player);
    event NewPlant(uint indexed tokenId, uint indexed types_);
    event UpGradeTechnology(uint indexed tokenId, uint indexed tecNum);
    event UpGradePlant(uint indexed tokenId);

    modifier onlyPlantOwner(uint tokenId) {
        require(msg.sender == plantInfo[tokenId].owner, 'not plant Owner');
        _;
    }

    modifier onlyAdmin(){
        require(admin[msg.sender], 'not admin');
        _;

    }
    
    function setTechnologyPrice(uint tecNum, uint price_) external onlyOwner{
        technologyPrice[tecNum] = price_;
    }

    function setAdmin(address addr, bool b) external onlyOwner{
        admin[addr] = b;
    }

    function setBanker(address banker_) external onlyOwner {
        banker = banker_;
    }

    function setToken(address BVG_, address BVT_) external onlyOwner {
        BVG = IERC20Upgradeable(BVG_);
        BVT = IERC20Upgradeable(BVT_);
    }

    function setPlant721(address plant721_) external onlyOwner {
        plant = IPlant721(plant721_);
    }
    
    function setBvInfo(address BvInfo) external onlyOwner{
        bvInfo = IBvInfo(BvInfo);
    }

    function setPlantType(uint types_, uint populationLimit_, uint federalLimit_, uint plantTax_) external onlyOwner {
        plantType[types_] = PlantType({
        populationLimit : populationLimit_,
        federalLimit : federalLimit_,
        plantTax : plantTax_
        });
    }

    function getBVTPrice() public view returns (uint){
        return bvInfo.getBVTPrice();
    }


    function bondPlant(uint tokenId) external {
        require(userInfo[msg.sender].plant == 0, 'already bond');
        require(plantInfo[tokenId].tax > 0, 'none exits plant');
        require(plantInfo[tokenId].population < plantInfo[tokenId].populationLimit, 'out of population limit');
        if (plantInfo[tokenId].membershipFee > 0) {
            uint need = plantInfo[tokenId].membershipFee * 1e18 / getBVTPrice();
            BVT.safeTransferFrom(msg.sender, plant.ownerOf(tokenId), need);
        }
        plantInfo[tokenId].population ++;
        userInfo[msg.sender].plant = tokenId;
        emit BondPlant(msg.sender, tokenId);
    }


    function applyFederalPlant(uint amount, uint tax_) external {
        require(userInfo[msg.sender].plant != 0, 'not bond plant');
        require(applyInfo[msg.sender].applyAmount == 0, 'have apply, cancel frist');
        applyInfo[msg.sender].applyTax = tax_;
        applyInfo[msg.sender].applyAmount = amount;
        applyInfo[msg.sender].lockAmount = federalPrice *1e18 / getBVTPrice();
        BVT.safeTransferFrom(msg.sender, address(this), amount + applyInfo[msg.sender].lockAmount);
        emit ApplyFederalPlant(msg.sender, amount, tax_);
    }

    function cancelApply() external {
        require(userInfo[msg.sender].plant != 0, 'not bond plant');
        require(applyInfo[msg.sender].applyAmount > 0, 'have apply, cancel frist');
        BVT.safeTransfer(msg.sender, applyInfo[msg.sender].applyAmount + applyInfo[msg.sender].lockAmount);
        delete applyInfo[msg.sender];
        emit CancelApply(msg.sender);

    }
    
    function approveFedApply(address addr_, uint tokenId) onlyPlantOwner(tokenId) external {
        require(applyInfo[msg.sender].applyAmount > 0, 'wrong apply address');
        require(plantInfo[tokenId].federalAmount < plantInfo[tokenId].federalLimit, 'out of federal Plant limit');
        BVT.safeTransfer(msg.sender, applyInfo[msg.sender].applyAmount);
        BVT.safeTransfer(address(0),applyInfo[msg.sender].lockAmount);
        uint id = plant.mint(addr_, 2, false);
        uint temp = ownerOfPlant[msg.sender];
        require(temp == 0 || plant.ownerOf(id) != addr_, 'already have 1 plant');
        plantInfo[id].tax = applyInfo[addr_].applyTax;
        plantInfo[id].motherPlant = tokenId;
        plantInfo[tokenId].federalAmount ++;
        ownerOfPlant[addr_] = id;
        plantInfo[id].federalLimit = plantType[2].federalLimit;
        plantType[id].populationLimit = plantType[2].populationLimit;
        delete applyInfo[addr_];
        emit CancelApply(msg.sender);
    }

    function createNewPlant(uint tokenId) external {
        require(msg.sender == plant.ownerOf(tokenId), 'not plant owner');
        require(plantInfo[tokenId].tax == 0, 'created');
        uint temp = ownerOfPlant[msg.sender];
        require(temp == 0 , 'already have 1 plant');
        uint types = plant.plantIdMap(tokenId);
        plant.safeTransferFrom(msg.sender, address(this), tokenId);
        plantInfo[tokenId].tax = plantType[plant.plantIdMap(tokenId)].plantTax;
        plantInfo[tokenId].types = types;
        plantInfo[tokenId].federalLimit = plantType[types].federalLimit;
        plantInfo[tokenId].populationLimit = plantType[types].populationLimit;
        ownerOfPlant[msg.sender] = tokenId;
        plantInfo[tokenId].owner = msg.sender;
        currentPlant.push(tokenId);
        emit NewPlant(tokenId, plantInfo[tokenId].types);
    }

    function pullOutPlantCard(uint tokenId) external {
        require(msg.sender == plantInfo[tokenId].owner, 'not the owner');
        plant.safeTransferFrom(address(this), msg.sender, tokenId);
        ownerOfPlant[msg.sender] == 0;
        plantInfo[tokenId].owner == address(0);
        
    }
    
    function replaceOwner(uint tokenId) external{
        require(msg.sender == plant.ownerOf(tokenId), 'not plant owner');
        require(plantInfo[tokenId].tax != 0, 'new plant need create');
        require(ownerOfPlant[msg.sender] == 0,'already have 1 plant');
        plant.safeTransferFrom(msg.sender, address(this), tokenId);
        plantInfo[tokenId].owner = msg.sender;
        ownerOfPlant[msg.sender] = tokenId;
    }

    function setMemberShipFee(uint tokenId, uint price_) onlyPlantOwner(tokenId) external {
        plantInfo[tokenId].membershipFee = price_;
    }


    

    function addTaxAmount(address addr, uint amount) external onlyAdmin {
        uint tokenId = userInfo[addr].plant;
        plantInfo[tokenId].battleTaxAmount += amount * battleTaxRate / 100;
        amount = amount * (100 - battleTaxRate) / 100;
        if (plantInfo[tokenId].motherPlant != 0) {
            plantInfo[tokenId].normalTaxAmount += amount;

        } else {
            uint motherPlant = plantInfo[tokenId].motherPlant;
            uint feb = plantInfo[tokenId].tax;
            uint home = plantInfo[motherPlant].tax;
            uint temp = amount * feb / home;
            plantInfo[tokenId].normalTaxAmount += temp;
            plantInfo[motherPlant].normalTaxAmount += amount - temp;
        }

    }
    
    function coutingUpGradeTechnology(address addr_, uint tecNum) public view returns(uint){
        uint plantId = ownerOfPlant[addr_];
        if(plantId == 0){
            return 0;
        }
        uint level = getTechnology(plantId,tecNum);
        uint cost =  technologyCost * (100 + (50 * level)) / 100;
        return cost;
        
    }
    
    function upGradePlant(uint tokenId) external onlyPlantOwner(tokenId){
        require(plantInfo[tokenId].types == 3,'can not upgrade');
        uint cost = upGradePlantPrice * 1e18 / getBVTPrice();
        BVT.safeTransferFrom(msg.sender,address(0),cost);
        IPlant721(plant).changeType(tokenId,1);
        plantInfo[tokenId].types = 1;
        plantInfo[tokenId].tax = plantType[1].plantTax;
        plantInfo[tokenId].federalLimit = plantType[1].federalLimit;
        plantInfo[tokenId].populationLimit = plantType[1].populationLimit;
        emit UpGradePlant(tokenId);
    }
    
    function upGradeTechnology(uint tokenId ,uint tecNum) external onlyPlantOwner(tokenId) {
        uint cost = coutingUpGradeTechnology(msg.sender,tecNum);
        require(cost > 0 ,'no plant');
        PlantInfo storage info = plantInfo[tokenId];
        require(info.normalTaxAmount >= cost,'not enough tax');
        info.normalTaxAmount -= cost;
        emit UpGradeTechnology(tokenId,tecNum);
    }

    function findTax(address addr_) public view returns (uint){
        uint tokenId = userInfo[addr_].plant;
        if (plantInfo[tokenId].motherPlant != 0) {
            uint motherPlant = plantInfo[tokenId].motherPlant;
            return plantInfo[motherPlant].tax;
        }
        return plantInfo[tokenId].tax;
    }

    // function battleReward(uint[])

    function isBonding(address addr_) external view returns (bool){
        if (userInfo[addr_].plant != 0) {
            return true;
        } else {
            return false;
        }
    }

    function getTechnology(uint tokenId, uint tecNum) public view returns (uint){
        return plantInfo[tokenId].technology[tecNum];
    }

    function getUserTechnology(address addr, uint tecNum) external view returns (uint){
        if (plantInfo[userInfo[addr].plant].motherPlant != 0) {
            return plantInfo[plantInfo[userInfo[addr].plant].motherPlant].technology[tecNum];
        }
        return plantInfo[userInfo[addr].plant].technology[tecNum];
    }

    function getUserPlant(address addr_) external view returns (uint){
        return userInfo[addr_].plant;
    }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBvInfo{
    function addPrice() external;
    function getBVTPrice() external view returns(uint);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

interface IPlant721 {
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256 balance);

    function plantIdMap(uint tokenId) external view returns (uint256 cardId);

    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    
    function ownerOf(uint256 tokenId) external view returns (address owner);
    
    function mint(address player_, uint type_, bool uriInTokenId_) external returns (uint256);
    
    function changeType(uint tokenId, uint type_) external;
}