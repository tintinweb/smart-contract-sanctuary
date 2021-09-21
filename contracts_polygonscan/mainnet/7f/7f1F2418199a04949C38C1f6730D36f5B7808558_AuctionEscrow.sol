// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./BaseRelayRecipient.sol";


contract AuctionEscrow is BaseRelayRecipient {
    using SafeERC20 for IERC20;

    //The wallet structure which holds information about user funds
    struct Wallet {
        address signer;
        uint256 totalBalance;
        uint256 reservedBalance;
    }

    //Mapping of addresses who have access tp system only functions
    mapping(address => bool) public systems;

    //Address of treasury where the funds will go once auction is closed
    address public treasury;

    //Token supported for deposit and withdrawal
    address immutable public token;

    //Mapping of userVsWallet(balances)
    mapping(address => Wallet) public balances;

    //Mapping of user versus nonce
    mapping(address => uint256) public nonces;

    bytes32 public immutable DOMAIN_SEPARATOR;
    // keccak256("Reserve(address user,uint256 amount,uint256 nonce,uint256 deadline)");
    bytes32 public constant RESERVE_TYPEHASH = keccak256("Reserve(address user,bytes32 id,uint256 amount,uint256 nonce,uint256 deadline)");


    event Deposit(address indexed user, address indexed signer, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Reserved(
        bytes32 id,
        address indexed user,
        address indexed system,
        uint256 amount
    );
    event Unreserved(address indexed user, address indexed system, uint256 amount);
    event Release(address indexed treasury, uint256 amount);
    event setSystemEmit(address addr, bool enabled);

    event CreditBid(
        bytes32 id,
        address indexed user,
        address indexed system,
        uint256 amount
    );

    event ChangeTreasury(
        address treasury
    );

    /** 
     * @param _trustedForwarder Address of trusted forwarder
     * @param _token Address of supported token for auction
     * @param _treasury Address of the treasury
     * @param chainId Id of the chain used for signing messages
     */ 
    constructor(
        address _trustedForwarder,
        address _token,
        address _treasury,
        uint256 chainId
    )
    {
        require(_trustedForwarder != address(0), "Invalid Forwarder");
        require(_token != address(0), "Invalid token");
        require(_treasury != address(0), "Invalid Treasury");

        trustedForwarder = _trustedForwarder;
        token = _token;
        treasury = _treasury;

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes("UNXD_AUCTION")),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
    }

    modifier onlySystem() {
        require(
            systems[_msgSender()],
            "SYSTEM: INVALID_ACCESS"
        );
        _;
    }

    modifier onlySystemOrOwner() {
        require(
            systems[_msgSender()] || owner() == _msgSender(), "UNAUTHORIZED_ACCESS"
        );
        _;
    }

    /**
    * @dev Allows owner to change treasury
    * @param _treasury New address of the treasury
    */
    function changeTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "Invalid Treasury");
        treasury = _treasury;
        emit ChangeTreasury(treasury);
    }

    /**
    * @dev Allows owner to add/remove system address
    * @param addr Address of the system
    * @param enabled Whether to enable or disable the system address access
     */
    function setSystem(address addr, bool enabled) external onlyOwner {
        require(addr != address(0), "zero address");
        systems[addr] = enabled;
        emit setSystemEmit(addr, enabled);
    }

    /**
    * @dev Returns the wallet/balance of the user
    * @param user Address of the user 
    */
    function getBalance(address user)
        external
        view
        returns (Wallet memory wallet)
    {
        return balances[user];
    }

    /**
    @dev Function to allow users to deposit wETH
    * @param signer Address who has authorization to reserve funds on the user's behalf
    * @param amount Amount of tokens to be deposited
    */
    function deposit(address signer, uint256 amount) external {
        require(amount > 0, "INAVLID_AMOUNT");
        address sender = _msgSender();
        if (signer == address(0)) {
            signer = sender;
        }
        balances[sender].totalBalance += amount;
        balances[sender].signer = signer;

        IERC20(token).safeTransferFrom(sender, address(this), amount);
        emit Deposit(sender, signer, amount);
    }

    /**
    * @dev Allows user to withdraw his/her funds which are not in reserved state
    * @param amount Amount of funds to be withdrawn
    */
    function withdraw(uint256 amount) external {
        require(amount > 0, "INAVLID_AMOUNT");
        address sender = _msgSender();
        
        Wallet storage wallet = balances[sender];
        uint256 withdrawableBalance = wallet.totalBalance - wallet.reservedBalance;

        require(amount <= withdrawableBalance, "Invalid amount");

        wallet.totalBalance = wallet.totalBalance - amount;
        IERC20(token).safeTransfer(sender, amount);

        emit Withdraw(sender, amount);
    }

    /**
    * @dev Allows system to submit a bid placed by credit user. Just to have info on blockchain
    * @param id Id associated with the nft being auctioned. NOTE- This is not actual NFT id
    * @param user Address of the user
    * @param amount Amount to be reserved
    * @param deadline Time upto which the signature is valid
    * @param v v component of the sign
    * @param r r component of the sign
    * @param s s component of the sign
    */
    function creditBid(
        bytes32 id,
        address user,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
        onlySystem
    {
        require(amount > 0, "INAVLID_AMOUNT");
        require(deadline >= block.timestamp, 'EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(RESERVE_TYPEHASH, user, id, amount, nonces[user]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == user, 'INVALID_SIGNATURE');

        emit CreditBid(
            id,
            user,
            _msgSender(),
            amount
        );
    }

    /**
    * @dev Allows system to reserver funds on behalf of the user when user places a successful bid
    * @param id Id associated with the nft being auctioned. NOTE- This is not actual NFT id
    * @param user Address of the user
    * @param amount Amount to be reserved
    * @param deadline Time upto which the signature is valid
    * @param v v component of the sign
    * @param r r component of the sign
    * @param s s component of the sign
    */
    function reserve(
        bytes32 id,
        address user,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
        onlySystem
    {
        require(amount > 0, "INAVLID_AMOUNT");
        require(deadline >= block.timestamp, 'EXPIRED');
        Wallet storage wallet = balances[user];

        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(RESERVE_TYPEHASH, user, id, amount, nonces[user]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == wallet.signer, 'INVALID_SIGNATURE');

        uint256 freeBalance = wallet.totalBalance - wallet.reservedBalance;
        
        require(amount <= freeBalance, "Invalid amount");

        wallet.reservedBalance = wallet.reservedBalance + amount;

        emit Reserved(
            id,
            user,
            _msgSender(),
            amount
        );
    }

    /**
    * @dev Allows system or owner to unreserve balance of multiple users
    * @param users Address of the user
    * @param amounts Amount to be unreserved for each user
    */
    function unreserveMultiple(
        address[] calldata users,
        uint256[] calldata amounts
    )
        external
        onlySystemOrOwner
    {
        require(users.length == amounts.length, "INVALID_DATA");
        for (uint256 i = 0; i < users.length; i++) {
            unreserve(users[i], amounts[i]);
        }
    }

    /**
    * @dev Allows system to unreserve user's reserved balance
    * Owner can also call this method under emergency circumstances
    * @param user Address of the user
    * @param amount Amount to be unreserved
    */
    function unreserve(
        address user,
        uint256 amount
    )
        public
        onlySystemOrOwner
    {
        require(amount > 0, "INAVLID_AMOUNT");
        Wallet storage wallet = balances[user];
        require(amount <= wallet.reservedBalance, "INAVLID_AMOUNT");

        wallet.reservedBalance = wallet.reservedBalance - amount;

        emit Unreserved(user, _msgSender(), amount);
    }

    /**
    * @dev Funds will be released to the treasury from the user's reserved balance
    *      Only owner can call this method
    * @param user Address of the user
    * @param amount Amount to be released
    */
    function release(
        address user,
        uint256 amount
    )
        external
        onlyOwner
    {

        Wallet storage wallet = balances[user];
        require(amount <= wallet.reservedBalance, "INVALID_AMOUNT");
        wallet.totalBalance = wallet.totalBalance - amount;
        wallet.reservedBalance = wallet.reservedBalance - amount;

        IERC20(token).safeTransfer(treasury, amount);
        emit Release(treasury, amount);

    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * a contract must implement this interface in order to support relayed transaction.
 * It is better to inherit the BaseRelayRecipient as its implementation.
 */
abstract contract IRelayRecipient {
    /**
     * return if the forwarder is trusted to forward relayed transactions to us.
     * the forwarder is required to verify the sender's signature, and verify
     * the call is not a replay.
     */
    function isTrustedForwarder(address forwarder)
        public
        view
        virtual
        returns (bool);

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, then the real sender is appended as the last 20 bytes
     * of the msg.data.
     * otherwise, return `msg.sender`
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal view virtual returns (address);

    function versionRecipient() external view virtual returns (string memory);
}

/**
 * A base contract to be inherited by any contract that want to receive relayed transactions
 * A subclass must use "_msgSender()" instead of "msg.sender"
 */
abstract contract BaseRelayRecipient is IRelayRecipient, Context, Ownable {
    /*
     * Forwarder singleton we accept calls from
     */
    address public trustedForwarder;

    function setTrustedForwarder(address _trustedForwarder) public onlyOwner {
        trustedForwarder = _trustedForwarder;
    }

    /*
     * require a function to be called through GSN only
     */
    modifier trustedForwarderOnly() {
        require(
            msg.sender == address(trustedForwarder),
            "Function can only be called through the trusted Forwarder"
        );
        _;
    }

    function isTrustedForwarder(address forwarder)
        public
        view
        override
        returns (bool)
    {
        return forwarder == trustedForwarder;
    }

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, return the original sender.
     * otherwise, return `msg.sender`.
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender()
        internal
        view
        virtual
        override(Context, IRelayRecipient)
        returns (address ret)
    {
        if (msg.data.length >= 24 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return payable(msg.sender);
        }
    }

    function versionRecipient() external pure override returns (string memory) {
        return "1";
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

pragma solidity ^0.8.0;

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
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

{
  "optimizer": {
    "enabled": true,
    "runs": 1000000
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}