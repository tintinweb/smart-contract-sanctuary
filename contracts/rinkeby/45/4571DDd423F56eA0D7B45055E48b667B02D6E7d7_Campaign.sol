// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;


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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "./IERC20.sol";
import "./Context.sol";
import "./SafeMath.sol";


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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
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

        _balances[account] = _balances[account].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// File: @openzeppelin/contracts/utils/Address.sol

//  : MIT

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;


import "./../Staker.sol";
import { SafeERC20 } from "./../SafeERC20.sol";
import './IFactoryGetters.sol';

contract ReEntrancyGuard {
    bool internal locked;

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }
}

// Uniswap v2
interface IUniswapV2Router02 {
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}


contract Campaign is ReEntrancyGuard {
    using Address for address;
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    address public factory;
    address public campaignOwner;
    address public token;
    uint256 public softCap;
    uint256 public hardCap;
    uint256 public tokenSalesQty;
    uint256 public feePcnt;
    uint256 public startDate;
    uint256 public endDate;
    uint256 public regEndDate;
    uint256 public tierSaleEndDate;
    uint256 public tokenLockTime;

    struct TierProfile {
        uint256 weight;
        uint256 minTokens;
        uint256 noOfParticipants;
    } 
    mapping(uint256 => TierProfile) public indexToTier;
    uint256 private totalWeight = 0;

    struct UserProfile {
        bool isRegisterd;
        uint256 inTier;
        bool hasPurchased;
    }
    mapping(address => UserProfile) public allUserProfile;

    // Liquidity
    uint256 public lpBnbQty;
    uint256 public lpTokenQty;
    uint256 public lpLockDuration;
    uint256[2] private lpInPool; // This is the actual LP provided in pool.
    bool private recoveredUnspentLP;

    // Config
    bool public burnUnSold;

    // Misc variables //
    uint256 public unlockDate;
    uint256 public collectedMATIC;
    uint256 public lpTokenAmount;

    // States
    bool public tokenFunded;
    bool public finishUpSuccess;
    bool public liquidityCreated;
    bool public cancelled;

   // Token claiming by users
    mapping(address => bool) public claimedRecords;
    bool public tokenReadyToClaim;

    // Map user address to amount invested in MATIC //
    mapping(address => uint256) public participants;
    uint256 public numOfParticipants;

    address public constant BURN_ADDRESS = address(0x000000000000000000000000000000000000dEaD);

    uint256 public numOfWhitelisted;
    mapping(address => bool) public whitelistedMap;

    // Events
    event Registered(
        address indexed user,
        uint256 timeStamp,
        uint256 tierIndex
    );

    event Purchased(
        address indexed user,
        uint256 timeStamp,
        uint256 amountBnb,
        uint256 amountToken
    );

    event LiquidityAdded(
        uint256 amountBnb,
        uint256 amountToken,
        uint256 amountLPToken
    );

    event LiquidityLocked(
        uint256 timeStampStart,
        uint256 timeStampExpiry
    );

    event LiquidityWithdrawn(
        uint256 amount
    );

    event TokenClaimed(
        address indexed user,
        uint256 timeStamp,
        uint256 amountToken
    );

    event Refund(
        address indexed user,
        uint256 timeStamp,
        uint256 amountBnb
    );

    modifier onlyFactory() {
        require(msg.sender == factory, "Only factory can call");
        _;
    }

    modifier onlyCampaignOwner() {
        require(msg.sender == campaignOwner, "Only campaign owner can call");
        _;
    }

    modifier onlyFactoryOrCampaignOwner() {
        require(msg.sender == factory || msg.sender == campaignOwner, "Only factory or campaign owner can call");
        _;
    }

    constructor() public{
        factory = msg.sender;
    }

    /**
     * @dev Initialize  a new campaign.
     * @notice - Access control: External. Can only be called by the factory contract.
     */
    function initialize
    (
        address _token,
        address _campaignOwner,
        uint256[4] calldata _stats,
        uint256[4] calldata _dates,
        uint256[3] calldata _liquidity,
        bool _burnUnSold,
        uint256 _tokenLockTime,
        uint256[6] calldata _tierWeights,
        uint256[6] calldata _tierMinTokens
    ) external
    {
        require(msg.sender == factory,'Only factory allowed to initialize');
        token = _token;
        campaignOwner = _campaignOwner;
        softCap = _stats[0];
        hardCap = _stats[1];
        tokenSalesQty = _stats[2];
        feePcnt = _stats[3];
        startDate = _dates[0];
        endDate = _dates[1];
        regEndDate = _dates[2];
        tierSaleEndDate = _dates[3];
        lpBnbQty = _liquidity[0];
        lpTokenQty = _liquidity[1];
        lpLockDuration = _liquidity[2];
        burnUnSold = _burnUnSold;
        tokenLockTime = block.timestamp + _tokenLockTime;

        uint256 _tWeight = 0;
        for(uint256 i=0; i<_tierWeights.length; i++) {
            _tWeight = _tWeight.add(_tierWeights[i]);
            indexToTier[i+1] = TierProfile(_tierWeights[i], _tierMinTokens[i], 0);
        }

        totalWeight = _tWeight;
    }

    function isInRegistration() public view returns(bool) {
        uint256 timeNow = block.timestamp;
        return (timeNow >= startDate) && (timeNow < regEndDate);
    }

    function isInTierSale() public view returns(bool) {
        uint256 timeNow = block.timestamp;
        return (timeNow >= regEndDate) && (timeNow < tierSaleEndDate);
    }

    function isInFCFS() public view returns(bool) {
        uint256 timeNow = block.timestamp;
        return (timeNow >= tierSaleEndDate) && (timeNow < endDate);
    }

    function isInEnd() public view returns(bool) {
        uint256 timeNow = block.timestamp;
        return (timeNow >= endDate);
    }

    function currentPeriod() public view returns(uint256 period) {
        if(isInRegistration()) period = 0; 
        else if(isInTierSale()) period = 1;
        else if(isInFCFS()) period = 2;
        else if(isInEnd()) period = 3;
    }

    function userRegistered(address account) public view returns(bool) {
        return allUserProfile[account].isRegisterd;
    }

    function userPurchased(address account) public view returns(bool) {
        return allUserProfile[account].hasPurchased;
    }

    function userTier(address account) public view returns(uint256) {
        return allUserProfile[account].inTier;
    }

    function tierPerUserAllocation(uint256 _tierIndex) public view returns(uint256, uint256) {
        uint256 noOfParticipants = indexToTier[_tierIndex].noOfParticipants;
        uint256 weight = indexToTier[_tierIndex].noOfParticipants;
        uint256 tokensAllocated = tokenSalesQty.mul(weight).div(totalWeight.mul(noOfParticipants));
        uint256 priceInMATIC = hardCap.mul(weight).div(totalWeight.mul(noOfParticipants));

        return (tokensAllocated, priceInMATIC);
    }

    function userMaxInvest(address account) public view returns(uint256) {
        (, uint256 inv) = tierPerUserAllocation(userTier(account));
        return inv;
    }

    function userMaxTokens(address account) public view returns(uint256) {
        return calculateTokenAmount(userMaxInvest(account));
    }

    /**
     * @dev Set the token lock time
     */
    function setTokenLockTime(uint256 _tokenLockTime) public {
        tokenLockTime = block.timestamp + _tokenLockTime;
    }

    /**
     * @dev Allows campaign owner to fund in his token.
     * @notice - Access control: External, OnlyCampaignOwner
     */
    function fundIn() external onlyCampaignOwner {
        require(!tokenFunded, "Campaign is already funded");
        uint256 amt = getCampaignFundInTokensRequired();
        require(amt > 0, "Invalid fund in amount");

        tokenFunded = true;
        ERC20(token).safeTransferFrom(msg.sender, address(this), amt);
    }

    // In case of a "cancelled" campaign, or softCap not reached,
    // the campaign owner can retrieve back his funded tokens.
    function fundOut() external onlyCampaignOwner {
        require(failedOrCancelled(), "Only failed or cancelled campaign can un-fund");
        tokenFunded = false;
        ERC20 ercToken = ERC20(token);
        uint256 totalTokens = ercToken.balanceOf(address(this));
        sendTokensTo(campaignOwner, totalTokens);

    }

    /**
     * @dev To Register In The Campaign In Reg Period
     * @param _tierIndex - The tier index to participate in
     * @notice - Valid tier indexes are, 1, 2, 3 ... 6
     * @notice - Access control: Public
     */
    function registerForIDO(uint256 _tierIndex) public noReentrant {
        require(tokenFunded, "Campaign is not funded yet");
        address account = msg.sender;
        require(isInRegistration(), "Not In Registration Period");
        require(!userRegistered(account), "Already regisered");
        require(_tierIndex >= 1 && _tierIndex <= 6, "Invalid tier index");
        

        IFactoryGetters fact = IFactoryGetters(factory);
        address stakerAddress = fact.getStakerAddress();

        Staker stakerContract = Staker(stakerAddress);
        uint256 stakedBal = stakerContract.stakedBalance(account);

        TierProfile storage tier = indexToTier[_tierIndex];
        require(tier.weight <= stakedBal, "Not eligible forthe tier");
        tier.noOfParticipants = (tier.noOfParticipants).add(1);

        allUserProfile[account] = UserProfile(true, _tierIndex, false);
        lockTokens(account);

        emit Registered(account, block.timestamp, _tierIndex);
    }

    /**
     * @dev Allows registered user to buy token in tiers.
     * @notice - Access control: Public
     */
    function buyTierTokens() public payable noReentrant {

        require(tokenFunded, "Campaign is not funded yet");
        require(isLive(), "Campaign is not live");
        require(isInTierSale(), "Not in tier sale period");
        require(userRegistered(msg.sender), "Not regisered");

        // Check for over purchase
        require(msg.value != 0, "Value Can't be 0");
        require(msg.value <= getRemaining(),"Insufficent token left");
        uint256 invested =  participants[msg.sender].add(msg.value);
        require(invested <= userMaxInvest(msg.sender), "Investment is more than allocated");

        participants[msg.sender] = invested;
        collectedMATIC = collectedMATIC.add(msg.value);

        emit Purchased(msg.sender, block.timestamp, msg.value, calculateTokenAmount(msg.value));
    }

    /**
     * @dev Allows registered user to buy token in FCFS.
     * @notice - Access control: Public
     */
    function buyFCFSTokens() public payable noReentrant {

        require(tokenFunded, "Campaign is not funded yet");
        require(isLive(), "Campaign is not live");
        require(isInFCFS(), "Not in FCFS sale period");
        require(userRegistered(msg.sender), "Not regisered");

        // Check for over purchase
        require(msg.value != 0, "Value Can't be 0");
        require(msg.value <= getRemaining(),"Insufficent token left");
        uint256 invested =  participants[msg.sender].add(msg.value);

        participants[msg.sender] = invested;
        collectedMATIC = collectedMATIC.add(msg.value);

        emit Purchased(msg.sender, block.timestamp, msg.value, calculateTokenAmount(msg.value));
    }

    /**
     * @dev Add liquidity and lock it up. Called after a campaign has ended successfully.
     * @notice - Access control: internal
     */

    function addAndLockLP() internal {

        require(!isLive(), "Presale is still live");
        require(!failedOrCancelled(), "Presale failed or cancelled , can't provide LP");
        require(softCap <= collectedMATIC, "Did not reach soft cap");

        if ((lpBnbQty > 0 && lpTokenQty > 0) && !liquidityCreated) {

            liquidityCreated = true;

            unlockDate = (block.timestamp).add(lpLockDuration);
            emit LiquidityLocked(block.timestamp, unlockDate);

            IFactoryGetters fact = IFactoryGetters(factory);
            address lpRouterAddress = fact.getLpRouter();
            require(ERC20(address(token)).approve(lpRouterAddress, lpTokenQty), "Failed to approve"); // Uniswap doc says this is required //

            (uint256 retTokenAmt, uint256 retMATICAmt, uint256 retLpTokenAmt) = IUniswapV2Router02(lpRouterAddress).addLiquidityETH
                {value : lpBnbQty}
                (address(token),
                lpTokenQty,
                0,
                0,
                address(this),
                block.timestamp + 100000000);

            lpTokenAmount = retLpTokenAmt;
            lpInPool[0] = retMATICAmt;
            lpInPool[1] = retTokenAmt;

            emit LiquidityAdded(retMATICAmt, retTokenAmt, retLpTokenAmt);


        }
    }

    /**
     * @dev Get the actual liquidity added to LP Pool
     * @return - uint256[2] consist of MATIC amount, Token amount.
     * @notice - Access control: Public, View
     */
    function getPoolLP() public view returns (uint256, uint256) {
        return (lpInPool[0], lpInPool[1]);
    }

    /**
     * @dev There are situations that the campaign owner might call this.
     * @dev 1: Pancakeswap pool SC failure when we call addAndLockLP().
     * @dev 2: Pancakeswap pool already exist. After we provide LP, thee's some excess bnb/tokens
     * @dev 3: Campaign owner decided to change LP arrangement after campaign is successful.
     * @dev In that case, campaign owner might recover it and provide LP manually.
     * @dev Note: This function can only be called once by factory, as this is not a normal workflow.
     * @notice - Access control: External, onlyFactory
     */
    function recoverUnspentLp() external onlyFactory {

        require(!recoveredUnspentLP, "You have already recovered unspent LP");
        recoveredUnspentLP = true;

        uint256 bnbAmt;
        uint256 tokenAmt;

        if (liquidityCreated) {
            // Find out any excess bnb/tokens after LP provision is completed.
            bnbAmt = lpBnbQty.sub(lpInPool[0]);
            tokenAmt = lpTokenQty.sub(lpInPool[1]);
        } else {
            // liquidity not created yet. Just returns the full portion of the planned LP
            // Only finished success campaign can recover Unspent LP
            require(finishUpSuccess, "Campaign not finished successfully yet");
            bnbAmt = lpBnbQty;
            tokenAmt = lpTokenQty;
        }

        // Return bnb, token if any
        if (bnbAmt > 0) {
            (bool ok, ) = campaignOwner.call{value: bnbAmt}("");
            require(ok, "Failed to return MATIC Lp");
        }

        if (tokenAmt > 0) {
            ERC20(token).safeTransfer(campaignOwner, tokenAmt);
        }
    }

    /**
     * @dev When a campaign reached the endDate, this function is called.
     * @dev Add liquidity to uniswap and burn the remaining tokens.
     * @dev Can be only executed when the campaign completes.
     * @dev Anyone can call. Only called once.
     * @notice - Access control: Public
     */
    function finishUp() public {

        require(!finishUpSuccess, "finishUp is already called");
        require(!isLive(), "Presale is still live");
        require(!failedOrCancelled(), "Presale failed or cancelled , can't call finishUp");
        require(softCap <= collectedMATIC, "Did not reach soft cap");
        finishUpSuccess = true;

        addAndLockLP(); // Add and lock liquidity

        uint256 feeAmt = getFeeAmt(collectedMATIC);
        uint256 unSoldAmtBnb = getRemaining();
        uint256 remainMATIC = collectedMATIC.sub(feeAmt);

        // If lpBnbQty, lpTokenQty is 0, we won't provide LP.
        if ((lpBnbQty > 0 && lpTokenQty > 0)) {
            remainMATIC = remainMATIC.sub(lpBnbQty);
        }

        // Send fee to fee address
        if (feeAmt > 0) {
            (bool sentFee, ) = getFeeAddress().call{value: feeAmt}("");
            require(sentFee, "Failed to send Fee to platform");
        }

        // Send remain bnb to campaign owner
        (bool sentBnb, ) = campaignOwner.call{value: remainMATIC}("");
        require(sentBnb, "Failed to send remain MATIC to campaign owner");

        // Calculate the unsold amount //
        if (unSoldAmtBnb > 0) {
            uint256 unsoldAmtToken = calculateTokenAmount(unSoldAmtBnb);
            // Burn or return UnSold token to owner
            sendTokensTo(burnUnSold ? BURN_ADDRESS : campaignOwner, unsoldAmtToken);
        }
    }


    /**
     * @dev Allow either Campaign owner or Factory owner to call this
     * @dev to set the flag to enable token claiming.
     * @dev This is useful when 1 project has multiple campaigns that
     * @dev to sync up the timing of token claiming After LP provision.
     * @notice - Access control: External,  onlyFactoryOrCampaignOwner
     */
    function setTokenClaimable() external onlyFactoryOrCampaignOwner {

        require(finishUpSuccess, "Campaign not finished successfully yet");
        tokenReadyToClaim = true;
    }

    /**
     * @dev Allow users to claim their tokens.
     * @notice - Access control: External
     */
    function claimTokens() external noReentrant {
        require(tokenReadyToClaim, "Tokens not ready to claim yet");
        require(!claimedRecords[msg.sender], "You have already claimed");

        uint256 amtBought = getClaimableTokenAmt(msg.sender);
        if (amtBought > 0) {
            claimedRecords[msg.sender] = true;
            emit TokenClaimed(msg.sender, block.timestamp, amtBought);
            ERC20(token).safeTransfer(msg.sender, amtBought);

        }
    }

     /**
     * @dev Allows campaign owner to withdraw LP after the lock duration.
     * @dev Only able to withdraw LP if lockActivated and lock duration has expired.
     * @dev Can call multiple times to withdraw a portion of the total lp.
     * @param _lpToken - The LP token address
     * @notice - Access control: Internal, OnlyCampaignOwner
     */
    function withdrawLP(address _lpToken,uint256 _amount) public onlyCampaignOwner {
        require(liquidityCreated, "liquidity is not yet created");
        require(block.timestamp >= unlockDate ,"Unlock date not reached");

        emit LiquidityWithdrawn( _amount);
        ERC20(_lpToken).safeTransfer(msg.sender, _amount);

    }

    /**
     * @dev Allows Participants to withdraw/refunds when campaign fails
     * @notice - Access control: Public
     */
    function refund() public {
        require(failedOrCancelled(),"Can refund for failed or cancelled campaign only");

        uint256 investAmt = participants[msg.sender];
        require(investAmt > 0 ,"You didn't participate in the campaign");

        if (numOfParticipants > 0) {
            numOfParticipants -= 1;
        }

        participants[msg.sender] = 0;
        (bool ok, ) = msg.sender.call{value: investAmt}("");
        require(ok, "Failed to refund MATIC to user");

        emit Refund(msg.sender, block.timestamp, investAmt);
    }

    /**
     * @dev To calculate the calimable token amount based on user's total invested MATIC
     * @param _user - The user's wallet address
     * @return - The total amount of token
     * @notice - Access control: Public
     */
    function getClaimableTokenAmt(address _user) public view returns (uint256) {
        uint256 investAmt = participants[_user];
        return calculateTokenAmount(investAmt);
    }

    // Helpers //
    /**
     * @dev To send all XYZ token to either campaign owner or burn address when campaign finishes or cancelled.
     * @param _to - The destination address
     * @param _amount - The amount to send
     * @notice - Access control: Internal
     */
    function sendTokensTo(address _to, uint256 _amount) internal {

        // Security: Can only be sent back to campaign owner or burned //
        require((_to == campaignOwner)||(_to == BURN_ADDRESS), "Can only be sent to campaign owner or burn address");

         // Burn or return UnSold token to owner
        ERC20 ercToken = ERC20(token);
        ercToken.safeTransfer(_to, _amount);
    }

    /**
     * @dev To calculate the amount of fee in MATIC
     * @param _amt - The amount in MATIC
     * @return - The amount of fee in MATIC
     * @notice - Access control: Internal
     */
    function getFeeAmt(uint256 _amt) internal view returns (uint256) {
        return _amt.mul(feePcnt).div(1e6);
    }

    /**
     * @dev To get the fee address
     * @return - The fee address
     * @notice - Access control: Internal
     */
    function getFeeAddress() internal view returns (address) {
        IFactoryGetters fact = IFactoryGetters(factory);
        return fact.getFeeAddress();
    }

    /**
     * @dev To check whether the campaign failed (softcap not met) or cancelled
     * @return - Bool value
     * @notice - Access control: Public
     */
    function failedOrCancelled() public view returns(bool) {
        if (cancelled) return true;

        return (block.timestamp >= endDate) && (softCap > collectedMATIC) ;
    }

    /**
     * @dev To check whether the campaign is isLive? isLive means a user can still invest in the project.
     * @return - Bool value
     * @notice - Access control: Public
     */
    function isLive() public view returns(bool) {
        if (!tokenFunded || cancelled) return false;
        if((block.timestamp < startDate)) return false;
        if((block.timestamp >= endDate)) return false;
        if((collectedMATIC >= hardCap)) return false;
        return true;
    }

    /**
     * @dev Calculate amount of token receivable.
     * @param _bnbInvestment - Amount of MATIC invested
     * @return - The amount of token
     * @notice - Access control: Public
     */
    function calculateTokenAmount(uint256 _bnbInvestment) public view returns(uint256) {
        return _bnbInvestment.mul(tokenSalesQty).div(hardCap);
    }


    /**
     * @dev Gets remaining MATIC to reach hardCap.
     * @return - The amount of MATIC.
     * @notice - Access control: Public
     */
    function getRemaining() public view returns (uint256){
        return (hardCap).sub(collectedMATIC);
    }

    /**
     * @dev Set a campaign as cancelled.
     * @dev This can only be set before tokenReadyToClaim, finishUpSuccess, liquidityCreated .
     * @dev ie, the users can either claim tokens or get refund, but Not both.
     * @notice - Access control: Public, OnlyFactory
     */
    function setCancelled() onlyFactory public {

        require(!tokenReadyToClaim, "Too late, tokens are claimable");
        require(!finishUpSuccess, "Too late, finishUp called");
        require(!liquidityCreated, "Too late, Lp created");

        cancelled = true;
    }

    /**
     * @dev Calculate and return the Token amount need to be deposit by the project owner.
     * @return - The amount of token required
     * @notice - Access control: Public
     */
    function getCampaignFundInTokensRequired() public view returns(uint256) {
        return tokenSalesQty.add(lpTokenQty);
    }

    function lockTokens(address _user) internal returns (bool){

        IFactoryGetters fact = IFactoryGetters(factory);
        address stakerAddress = fact.getStakerAddress();

        Staker stakerContract = Staker(stakerAddress);
        stakerContract.lock(_user, tokenLockTime);

    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;


interface IFactoryGetters {
    function getLpRouter() external view returns(address);
    function getFeeAddress() external view returns(address);
    function getLauncherToken() external view returns(address);
    function getStakerAddress() external view returns(address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

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

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "./SafeMath.sol";
import "./Address.sol";
import "./IERC20.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: contracts/interfaces/IStaker.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./Ownable.sol";
import "./Address.sol";
import "./ERC20.sol";



contract Staker is Context, Ownable {
    using SafeMath for uint256;
    using Address for address;
    
    IERC20 _token; 
    mapping (address => uint256) _balances;
    mapping (address => uint256) _unlockTime;
    mapping (address => bool) _isIDO;
    bool halted;

    event Stake(address indexed account, uint256 timestamp, uint256 value);
    event Unstake(address indexed account, uint256 timestamp, uint256 value);
    event Lock(address indexed account, uint256 timestamp, uint256 unlockTime, address locker);

    constructor(address _tokenAddress) public {
        _token = IERC20(_tokenAddress);
    }

    function stakedBalance(address account) external view returns (uint256) {
        return _balances[account];
    }

    function unlockTime(address account) external view returns (uint256) {
        return _unlockTime[account];
    }

    function isIDO(address account) external view returns (bool) {
        return _isIDO[account];
    }

    function stake(uint256 value) external notHalted {
        require(value > 0, "Staker: stake value should be greater than 0");
        _token.transferFrom(_msgSender(), address(this), value);

        _balances[_msgSender()] = _balances[_msgSender()].add(value);
        emit Stake(_msgSender(), block.timestamp, value);
    }

    function unstake(uint256 value) external lockable {
        require(_balances[_msgSender()] >= value, 'Staker: insufficient staked balance');

        _balances[_msgSender()] = _balances[_msgSender()].sub(value);
        _token.transfer(_msgSender(), value);
        emit Unstake(_msgSender(), block.timestamp, value);
    }

    function lock(address user, uint256 unlock_time) external onlyIDO {
        require(unlock_time >  block.timestamp, "Staker: unlock is in the past");
        if (_unlockTime[user] < unlock_time) {
            _unlockTime[user] = unlock_time;
            emit Lock(user, block.timestamp, unlock_time, _msgSender());
        }
    }

    function halt(bool status) external onlyOwner {
        halted = status;
    }

    function addIDO(address account) external onlyOwner {
        require(account != address(0), "Staker: cannot be zero address");
        _isIDO[account] = true;
    }

    modifier onlyIDO() {
        require(_isIDO[_msgSender()],"Staker: only IDOs can lock");
        _;
    }

    modifier lockable() {
        require(_unlockTime[_msgSender()] <=  block.timestamp, "Staker: account is locked");
        _;
    }

    modifier notHalted() {
        require(!halted, "Staker: Deposits are paused");
        _;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}