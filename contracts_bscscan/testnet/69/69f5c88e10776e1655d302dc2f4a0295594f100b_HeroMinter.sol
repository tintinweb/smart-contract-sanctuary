/**
 *Submitted for verification at BscScan.com on 2022-01-05
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [////IMPORTANT]
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
     * ////IMPORTANT: because control is transferred to `recipient`, care must be
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
     * ////IMPORTANT: Beware that changing an allowance with this method brings the risk
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


interface IPairOracle {
    function consult(address token, uint256 amountIn) external view returns (uint256 amountOut);
}

interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

////import "../IERC20.sol";
////import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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

////import "../utils/Context.sol";

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


////import "@openzeppelin/contracts/access/Ownable.sol";
////import "@openzeppelin/contracts/utils/Context.sol";
////import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
////import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
////import "./IUniswapV2Router.sol";
////import "./IPairOracle.sol";

interface IOracle {
    function consult() external view returns (uint256);
    function consultBNB() external view returns (uint256);
}

interface IHero {
    function mint(address _to) external;
}
interface CustomERC20 {
    function burn(uint256 amount) external;
}

contract HeroMinter is  Context, Ownable {

    using SafeERC20 for IERC20;

    uint256 private constant SLIPPAGE_PRECISION = 1e5;
    uint256 private constant BURN_PRECISION = 1e5;

    address public immutable WETH;

    address public scsAddress;
    address public ckgAddress;
    address public heroAddress;

    address public oracleScs;
    address public oracleCkg;

    address public router; // Pancake Swap Router

    address public mintHelper; // AMM Helper contract, holds dust CKG / SCS

    uint256 public ratioScs; // USD Amount of SCS needed to mint ( * 1e6)
    uint256 public ratioCkg; // USD Amount of CKG needed to mint ( * 1e6)

    // AMM Slippage config
    // 0.1% = 100, 1% = 1000, 100% = 100000 [1e5]
    // Amount 50 with 0.1% slippage will be 50 * (100000 - 100) / 100000
    // Amount 50 with 1% slippage will be 50 * (100000 - 1000) / 100000
    uint256 public slippage;

    uint256 public burnPercent;

    constructor(
        address _WETH,
        address _scsAddress,
        address _ckgAddress,
        address _heroAddress,
        address _router,
        address _oracleScs, 
        address _oracleCkg,
        address _mintHelper
    ){
        WETH = _WETH;
        scsAddress = _scsAddress;
        ckgAddress = _ckgAddress;
        heroAddress = _heroAddress;

        router = _router;

        oracleScs = _oracleScs;
        oracleCkg = _oracleCkg;

        mintHelper = _mintHelper;
    }
    
    function initialize(
        uint256 _scsRatio, 
        uint256 _ckgRatio,
        uint256 _slippage,
        uint256 _burnPercent
    ) external onlyOwner
    {
            
        ratioScs = _scsRatio;
        ratioCkg = _ckgRatio;

        slippage = _slippage;
        burnPercent = _burnPercent;
        
    }

    function priceNative() public view returns (uint256 scsNeeded, uint256 ckgNeeded) {
        uint256 _scsRate = IOracle(oracleScs).consult();
        uint256 _ckgRate = IOracle(oracleCkg).consult();

        scsNeeded = ratioScs * 1 ether / _scsRate;
        ckgNeeded = ratioCkg * 1 ether / _ckgRate;
    }

    function priceBNB() external view returns (uint256){
        (uint256 _scsNeeded, uint256 _ckgNeeded) = priceNative();

        uint256 _bnbNeeded = (IOracle(oracleScs).consultBNB() * _scsNeeded) +  (IOracle(oracleCkg).consultBNB() * _ckgNeeded);
        return _bnbNeeded * (slippage + SLIPPAGE_PRECISION) / SLIPPAGE_PRECISION / 1 ether;
    }

    function priceBNBNative() public view returns (uint256 scsBnb, uint256 ckgBnb){
        (uint256 _scsNeeded, uint256 _ckgNeeded) = priceNative();

        scsBnb = IOracle(oracleScs).consultBNB() * _scsNeeded * (slippage + SLIPPAGE_PRECISION) / SLIPPAGE_PRECISION / 1 ether;
        ckgBnb = IOracle(oracleCkg).consultBNB() * _ckgNeeded * (slippage + SLIPPAGE_PRECISION) / SLIPPAGE_PRECISION / 1 ether;
    }


    function mintNative(uint8 amount) public {
        (uint256 _scsNeeded, uint256 _ckgNeeded) = priceNative();
        uint256 scsNeeded = amount * _scsNeeded;
        uint256 ckgNeeded = amount * _ckgNeeded;

        IERC20(scsAddress).safeTransferFrom(address(_msgSender()), address(this), scsNeeded);
        IERC20(ckgAddress).safeTransferFrom(address(_msgSender()), address(this), ckgNeeded);

        IERC20(scsAddress).safeTransfer(mintHelper, scsNeeded * slippage / SLIPPAGE_PRECISION);
        IERC20(ckgAddress).safeTransfer(mintHelper, ckgNeeded * slippage / SLIPPAGE_PRECISION);

        for(uint8 i = 0; i < amount; i++){
            IHero(heroAddress).mint(_msgSender());
        }
    }

    function mintBnb(uint8 amount) public payable {
        (uint256 _scsNeeded, uint256 _ckgNeeded) = priceNative();
        (uint256 _scsBnb, uint256 _ckgBnb) = priceBNBNative();

        uint256 scsNeeded = amount * _scsNeeded;
        uint256 ckgNeeded = amount * _ckgNeeded;

        uint256 scsBnb = _scsBnb * amount;
        uint256 ckgBnb = _ckgBnb * amount;

        require(
            msg.value >= scsBnb + ckgBnb,
            "CKH: Not enough BNB sent"
        );

        address[] memory _scspath = new address[](2);
        _scspath[0] = WETH;
        _scspath[1] = scsAddress;

        address[] memory _ckgpath = new address[](2);
        _ckgpath[0] = WETH;
        _ckgpath[1] = ckgAddress;


        uint256[] memory _received_scs = IUniswapV2Router(router).swapExactETHForTokens{value: scsBnb}(scsNeeded, _scspath, address(this), block.timestamp + 5 minutes);
        uint256[] memory _received_ckg = IUniswapV2Router(router).swapExactETHForTokens{value: msg.value - scsBnb}(ckgNeeded, _ckgpath, address(this), block.timestamp + 5 minutes);

        uint256 receivedScs = _received_scs[_received_scs.length - 1];
        uint256 receivedCkg = _received_ckg[_received_ckg.length - 1];

        require( receivedScs >= scsNeeded, "Insufficient SCS provided");
        require( receivedCkg >= ckgNeeded, "Insufficient CKG provided");

        IERC20(scsAddress).safeTransfer(mintHelper, receivedScs - scsNeeded + (scsNeeded * slippage / SLIPPAGE_PRECISION));
        IERC20(ckgAddress).safeTransfer(mintHelper, receivedCkg - ckgNeeded + (ckgNeeded * slippage / SLIPPAGE_PRECISION));

        for(uint8 i = 0; i < amount; i++){
            IHero(heroAddress).mint(_msgSender());
        }
    }

    /**
     * Administrative Functions
     */

    function adminMint(address _to) external onlyOwner {
        IHero(heroAddress).mint(_to);
    }

    function setHero(address _hero) external onlyOwner {
        heroAddress = _hero;
    }

    function setRouter(address _router) external onlyOwner {
        router = _router;
    }

    function setScsAddress(address _scsAddress) external onlyOwner {
        scsAddress = _scsAddress;
    }
    function setCkgAddress(address _ckgAddress) external onlyOwner {
        ckgAddress = _ckgAddress;
    }
    function setOracleScs(address _oracle) external onlyOwner {
        oracleScs = _oracle;
    }
    function setOracleCkg(address _oracle) external onlyOwner {
        oracleCkg = _oracle;
    }
    function setMintHelper(address _helper) external onlyOwner {
        mintHelper = _helper;
    }

    function setScsRatio(uint256 _scsRatio) external onlyOwner {
        ratioScs = _scsRatio;
    }
    function setCkgRatio(uint256 _ckgRatio) external onlyOwner {
        ratioCkg = _ckgRatio;
    }
    function setSlippage(uint256 _slippage) external onlyOwner {
        slippage = _slippage;
    }
    function setBurnPercent(uint256 _burnPercent) external onlyOwner {
        burnPercent = _burnPercent;
    }

    function withdraw(address _recipient) external onlyOwner {
        uint256 scsBalance = IERC20(scsAddress).balanceOf(address(this));
        uint256 ckgBalance = IERC20(ckgAddress).balanceOf(address(this));

        uint256 scsBurn = scsBalance * burnPercent / BURN_PRECISION;
        uint256 ckgBurn = ckgBalance * burnPercent / BURN_PRECISION;

        CustomERC20(scsAddress).burn(scsBurn);
        CustomERC20(ckgAddress).burn(ckgBurn);

        IERC20(scsAddress).safeTransfer(_recipient, scsBalance - scsBurn);
        IERC20(ckgAddress).safeTransfer(_recipient, ckgBalance - ckgBurn);
    }

    // Remove excess BNB from contract
    function rescueFunds() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}