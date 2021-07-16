// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IERC20Extended.sol";
import "./lib/Initializable.sol";

contract SlotMarket is Initializable {
    struct Bid {
        address bidder;
        uint16 taxNumerator;
        uint16 taxDenominator;
        uint64 periodStart;
        uint128 bidAmount;
    }

    mapping (uint8 => uint64) public slotExpiration;
    mapping (uint8 => address) public slotDelegate;
    mapping (uint8 => address) public slotOwner;
    mapping (uint8 => Bid) public slotBid;
    mapping (address => uint128) public stakedBalance;

    IERC20Extended public token;
    address public admin;
    uint16 public taxNumerator;
    uint16 public taxDenominator;
    uint128 public MIN_BID;

    uint256 private _NOT_ENTERED;
    uint256 private _ENTERED;
    uint256 private _status;

    modifier onlyAdmin() {
        require(msg.sender == admin, "not admin");
        _;
    }

    modifier onlySlotOwner(uint8 slot) {
        require(msg.sender == slotOwner[slot], "not slot owner");
        _;
    }

    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    event AdminUpdated(address indexed newAdmin, address indexed oldAdmin);
    event TaxRateUpdated(uint16 newNumerator, uint16 newDenominator, uint16 oldNumerator, uint16 oldDenominator);
    event SlotClaimed(uint8 indexed slot, address indexed slotOwner, address indexed delegate, uint128 newBidAmount, uint128 oldBidAmount, uint16 taxNumerator, uint16 taxDenominator);
    event SlotDelegateUpdated(uint8 indexed slot, address indexed slotOwner, address indexed newDelegate, address oldDelegate);
    event Stake(address indexed claimer, uint256 stakeAmount);
    event Unstake(address indexed staker, uint256 unstakedAmount);
    event SlotCleared(uint8 indexed slot);

    function initialize(
        IERC20Extended _token,
        address _admin,
        uint16 _taxNumerator,
        uint16 _taxDenominator
    ) public initializer {
        token = _token;
        admin = _admin;
        emit AdminUpdated(_admin, address(0));

        taxNumerator = _taxNumerator;
        taxDenominator = _taxDenominator;
        emit TaxRateUpdated(_taxNumerator, _taxDenominator, 0, 0);

        MIN_BID = 10000000000000000;
        _NOT_ENTERED = 1;
        _ENTERED = 2;
        _status = _NOT_ENTERED;
    }

    function claimSlot(
        uint8 slot, 
        uint128 bid, 
        address delegate
    ) external nonReentrant {
        _claimSlot(slot, bid, delegate);
    }

    function claimSlotWithPermit(
        uint8 slot, 
        uint128 bid, 
        address delegate, 
        uint256 deadline, 
        uint8 v, 
        bytes32 r, 
        bytes32 s
    ) external nonReentrant {
        token.permit(msg.sender, address(this), bid, deadline, v, r, s);
        _claimSlot(slot, bid, delegate);
    }

    function slotBalance(uint8 slot) public view returns (uint128 balance) {
        Bid memory currentBid = slotBid[slot];
        if (currentBid.bidAmount == 0) {
            return 0;
        } else if (slotForeclosed(slot)) {
            return 0;
        } else if (block.timestamp == currentBid.periodStart) {
            return currentBid.bidAmount;
        } else {
            return uint128(uint256(currentBid.bidAmount) - (uint256(currentBid.bidAmount) * (block.timestamp - currentBid.periodStart) * currentBid.taxNumerator / (uint256(currentBid.taxDenominator) * 86400)));
        }
    }

    function slotForeclosed(uint8 slot) public view returns (bool) {
        if(slotExpiration[slot] <= block.timestamp) {
            return true;
        }
        return false;
    }

    function clearForeclosedSlot(uint8 slot) external {
        require(slotForeclosed(slot), "slot not foreclosed");
        Bid storage currentBid = slotBid[slot];
        currentBid.bidder = address(0);
        currentBid.periodStart = uint64(0);
        currentBid.bidAmount = 0;
        emit SlotCleared(slot);
    }

    function stake(uint128 amount) external nonReentrant {
        _stake(amount);
    }

    function stakeWithPermit(
        uint128 amount, 
        uint256 deadline, 
        uint8 v, 
        bytes32 r, 
        bytes32 s
    ) external nonReentrant {
        token.permit(msg.sender, address(this), amount, deadline, v, r, s);
        _stake(amount);
    }

    function unstake(uint128 amount) external nonReentrant {
        require(stakedBalance[msg.sender] >= amount, "amount > unlocked balance");
        stakedBalance[msg.sender] -= amount;
        token.transfer(msg.sender, amount);
        emit Unstake(msg.sender, amount);
    }

    function setSlotDelegate(uint8 slot, address delegate) external onlySlotOwner(slot) {
        require(delegate != address(0), "cannot delegate to 0 address");
        emit SlotDelegateUpdated(slot, msg.sender, delegate, slotDelegate[slot]);
        slotDelegate[slot] = delegate;
    }

    function setTaxRate(uint16 numerator, uint16 denominator) external onlyAdmin {
        require(denominator > numerator, "denominator must be > numerator");
        emit TaxRateUpdated(numerator, denominator, taxNumerator, taxDenominator);
        taxNumerator = numerator;
        taxDenominator = denominator;
    }

    function setAdmin(address newAdmin) external onlyAdmin {
        emit AdminUpdated(newAdmin, admin);
        admin = newAdmin;
    }

    function _claimSlot(uint8 slot, uint128 bid, address delegate) internal {
        require(delegate != address(0), "cannot delegate to 0 address");
        Bid storage currentBid = slotBid[slot];
        uint128 existingBidAmount = currentBid.bidAmount;
        uint128 existingSlotBalance = slotBalance(slot);
        require((existingSlotBalance == 0 && bid >= MIN_BID) || bid > existingBidAmount * 110 / 100, "bid too small");

        uint128 bidderStakedBalance = stakedBalance[msg.sender];
        uint128 bidIncrement = currentBid.bidder == msg.sender ? bid - existingSlotBalance : bid;
        if (bidderStakedBalance > 0) {
            if (bidderStakedBalance >= bidIncrement) {
                stakedBalance[msg.sender] -= bidIncrement;
            } else {
                stakedBalance[msg.sender] = 0;
                token.transferFrom(msg.sender, address(this), bidIncrement - bidderStakedBalance);
            }
        } else {
            token.transferFrom(msg.sender, address(this), bidIncrement);
        }
        if (currentBid.bidder != msg.sender) {
            stakedBalance[currentBid.bidder] += existingSlotBalance;
        }

        slotOwner[slot] = msg.sender;
        slotDelegate[slot] = delegate;

        currentBid.bidder = msg.sender;
        currentBid.periodStart = uint64(block.timestamp);
        currentBid.bidAmount = bid;
        currentBid.taxNumerator = taxNumerator;
        currentBid.taxDenominator = taxDenominator;

        slotExpiration[slot] = uint64(block.timestamp + uint256(taxDenominator) * 86400 / uint256(taxNumerator));

        emit SlotClaimed(slot, msg.sender, delegate, bid, existingBidAmount, taxNumerator, taxDenominator);
    }

    function _stake(uint128 amount) internal {
        token.transferFrom(msg.sender, address(this), amount);
        stakedBalance[msg.sender] += amount;
        emit Stake(msg.sender, amount);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IERC20Extended {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function version() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferWithAuthorization(address from, address to, uint256 value, uint256 validAfter, uint256 validBefore, bytes32 nonce, uint8 v, bytes32 r, bytes32 s) external;
    function receiveWithAuthorization(address from, address to, uint256 value, uint256 validAfter, uint256 validBefore, bytes32 nonce, uint8 v, bytes32 r, bytes32 s) external;
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    function nonces(address) external view returns (uint);
    function getDomainSeparator() external view returns (bytes32);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function DOMAIN_TYPEHASH() external view returns (bytes32);
    function VERSION_HASH() external view returns (bytes32);
    function PERMIT_TYPEHASH() external view returns (bytes32);
    function TRANSFER_WITH_AUTHORIZATION_TYPEHASH() external view returns (bytes32);
    function RECEIVE_WITH_AUTHORIZATION_TYPEHASH() external view returns (bytes32);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event AuthorizationUsed(address indexed authorizer, bytes32 indexed nonce);
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

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

import "./AddressUpgradeable.sol";

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

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 99999
  },
  "remappings": [],
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