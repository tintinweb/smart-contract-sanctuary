// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import "./Auth.sol";
import "./libraries/EarnHubLib.sol";
import "./interfaces/ITransferGateway.sol";
import "./interfaces/IGatewayHook.sol";


// TODO Remove all comments + Scramble function names before deploying!
// This contract receives Transfer on the onTransfer events from the token Contract
// ✅ It should run process for each hooked contract
// ✅ It should also manage sending BNB to the hooked contracts based on the shares assigned to each of them
// ✅ These shares should be set on this same contract
// ✅ It should take into consideration gas limits for external contract calls
contract TransferGateway is ITransferGateway, Auth {
    // Event declarations
    event NewContractAdded(address hookedContract, uint shares, uint handicap);
    event OldContractRemoved(address unhookedContract);
    event SharesUpdated(address hookedContract, uint newShares, uint totalShares);
    event HandicapUpdated(address hookedContract, uint newHandicap);
    // ? Should these events convey more arguments based on Transfer struct from EarnHubLib.sol?
    event TransferReceived(address from, uint amount);
    event TransferReleased(address to, uint amount);
    event GenericErrorEvent(string reason);

    // Custom types
    struct HookedContract {
        IGatewayHook hookedContract;
        // * amount of BNB each contract is owed
        uint shares;
        // * amount of GasLimit each contract can consume
        uint handicap; //! measured in bp, 100 bcp = 1%. should then divide by 10000 (bpScale) whenever this is used
    }

    // State variables
    uint public totalShares;

    uint public minGas = 1;
    uint public maxGas = 1e15;
    uint public bpScale = 10000;

    mapping(address => uint) public shares;
    mapping(address => uint) public handicaps;

    uint public activeContractsCount;

    HookedContract[] public activeContracts;
    HookedContract[] public removedContracts;

    constructor(address[] memory _initialContracts, uint[] memory _shares, uint[] memory _handicaps) Auth(msg.sender) {
        require(_initialContracts.length == _shares.length, "_initialContracts and _shares length mismatch");
        require(_initialContracts.length == _handicaps.length, "_initialContracts and _handicaps length mismatch");

        _authorize(address(this));
        // * authorizing this contract to deploy hookedContracts

        for (uint i = 0; i < _initialContracts.length; i++) {
            require(_handicaps[i] > 0 && _handicaps[i] <= bpScale, "handicaps should be between 0 and bpScale");
            addHookedContract(IGatewayHook(_initialContracts[i]), _shares[i], _handicaps[i]);
        }
    }

    function addHookedContract(IGatewayHook _hookedContract, uint _shares, uint _handicap) public authorized {
        require(address(_hookedContract) != address(0), "_hookedContract is the zero address");
        require(_shares > 0, "_shares are 0");
        require(_handicap > 0, "_handicap is 0");

        activeContracts.push(HookedContract(_hookedContract, _shares, _handicap));
        activeContractsCount++;

        shares[address(_hookedContract)] = _shares;
        totalShares += _shares;

        handicaps[address(_hookedContract)] = _handicap;

        emit NewContractAdded(address(_hookedContract), _shares, _handicap);
    }

    function removeHookedContract(uint _hookedContractId) external authorized override {
        require(_hookedContractId < activeContracts.length, "_hookedcontractId doesn't exist in activeContracts");
        totalShares -= activeContracts[_hookedContractId].shares;
        activeContractsCount--;
        removedContracts.push(activeContracts[_hookedContractId]);
        delete activeContracts[_hookedContractId];
        emit OldContractRemoved(address(removedContracts[removedContracts.length].hookedContract));
    }

    function updateHookedContractShares(uint _hookedContractId, uint _newShares) external authorized override {
        totalShares -= activeContracts[_hookedContractId].shares;
        activeContracts[_hookedContractId].shares = _newShares;
        shares[address(activeContracts[_hookedContractId].hookedContract)] = _newShares;
        totalShares += _newShares;
        emit SharesUpdated(address(activeContracts[_hookedContractId].hookedContract), _newShares, totalShares);
    }

    function updateHookedContractHandicap(uint _hookedContractId, uint _newHandicap) external authorized override {
        activeContracts[_hookedContractId].handicap = _newHandicap;
        handicaps[address(activeContracts[_hookedContractId].hookedContract)] = _newHandicap;
        emit HandicapUpdated(address(activeContracts[_hookedContractId].hookedContract), _newHandicap);
    }

    function depositBNB() external payable override{
        // * Should be called only when BNBvalue > 0 and we can at least cover gas costs
        if (msg.value < 0 || activeContractsCount < 0) {
            emit GenericErrorEvent("depositBNB(): Failed");
            return;
        }

        // snapshotting balances
        uint balance = address(this).balance;
        uint maxLength = activeContracts.length;
        // distribution for all active contracts
        for (uint i = 0; i < maxLength; i++) {
            //! this check exists because a deleted entry in activeContracts[] results in the zero address
            if (address(activeContracts[i].hookedContract) != address(0)) {
                sendBNBToHookedContract(activeContracts[i], balance);
            }
        }
        emit TransferReceived(msg.sender, msg.value);
    }

    //TODO Authorize EarnHub to TransferGateway so that we can trigger onTransfer and gatewayHooks cant be manipulated
    // Forwards a Transfer struct from EarnHub token to IGatewayHook compliant contracts for use in their respective process() methods
    function onTransfer(EarnHubLib.Transfer memory _transfer) external override authorized {
        //TODO experiment with different propagation contract call patterns
        // * handicaps closer to 10000(bp) get mfore gas

        uint maxLength = activeContracts.length;
        uint gasLimit;
        for (uint i = 0; i < maxLength; i++) {
            gasLimit = maxGas * activeContracts[i].handicap / bpScale;
            activeContracts[i].hookedContract.process(_transfer, gasLimit);
        }
        emit TransferReceived(_transfer.from, _transfer.amt);
    }

    // Takes whole BNB batch to distribute, then internally distributes to subscribed contracts based on their shares/totalShares
    function sendBNBToHookedContract(HookedContract memory _hookedContract, uint _totalBNBToDistribute) public {
        if (_hookedContract.shares < 0) {
            emit GenericErrorEvent("sendBNBToHookedContract(): _hookedContract has no shares");
            return;
        }

        // calculating due amount based on contract shares
        uint accScale = 1 ether * 1 ether;
        // using ether as 1e18, accScale = 1e36
        uint allocatedBNB = (_hookedContract.shares * accScale) / totalShares;
        uint givenBNB = (allocatedBNB * _totalBNBToDistribute) / accScale;
        // sending BNB to HookedContract
        Address.sendValue(payable(address(_hookedContract.hookedContract)), givenBNB);
        emit TransferReleased(address(_hookedContract.hookedContract), givenBNB);
    }

    // * Getter (view only) Functions
    // total shares of HookedContracts accounted for in this contract
    function getTotalShares() public view returns (uint) {
        return totalShares;
    }

    // shares of a HookedContract
    function getSharesOfContract(address _hookedContract) external view returns (uint) {
        return shares[_hookedContract];
    }

    // handicap of a HookedContract
    function getHandicapOfContract(HookedContract memory _hookedContract) external view returns (uint) {
        return handicaps[address(_hookedContract.hookedContract)];
    }

    // address of the activeContracts[_hookedContractId]
    function getContractFromId(uint _hookedContractId) external view returns (address) {
        return address(activeContracts[_hookedContractId].hookedContract);
    }

    // * Setter (write only) Functions
    function setBpScale(uint _newBpScale) external authorized override {
        bpScale = _newBpScale;
    }

    function setMinGasThreshold(uint _newMinGas) external authorized override {
        minGas = _newMinGas;
    }

    function setMaxGas(uint _newMaxGas) external authorized override {
        maxGas = _newMaxGas;
    }

    // * Auxiliary functions
    function isContractActive(IGatewayHook _contractAddress) public view returns (bool) {
        for (uint i = 0; i < activeContracts.length; i++) {
            if (activeContracts[i].hookedContract == _contractAddress) return true;
        }
        return false;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Address.sol";
import "../utils/Context.sol";
import "../utils/math/SafeMath.sol";

/**
 * @title PaymentSplitter
 * @dev This contract allows to split Ether payments among a group of accounts. The sender does not need to be aware
 * that the Ether will be split in this way, since it is handled transparently by the contract.
 *
 * The split can be in equal parts or in any other arbitrary proportion. The way this is specified is by assigning each
 * account to a number of shares. Of all the Ether that this contract receives, each account will then be able to claim
 * an amount proportional to the percentage of total shares they were assigned.
 *
 * `PaymentSplitter` follows a _pull payment_ model. This means that payments are not automatically forwarded to the
 * accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling the {release}
 * function.
 */
contract PaymentSplitter is Context {
    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    uint256 private _totalShares;
    uint256 private _totalReleased;

    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;
    address[] private _payees;

    /**
     * @dev Creates an instance of `PaymentSplitter` where each account in `payees` is assigned the number of shares at
     * the matching position in the `shares` array.
     *
     * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in `payees`.
     */
    constructor (address[] memory payees, uint256[] memory shares_) payable {
        // solhint-disable-next-line max-line-length
        require(payees.length == shares_.length, "PaymentSplitter: payees and shares length mismatch");
        require(payees.length > 0, "PaymentSplitter: no payees");

        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], shares_[i]);
        }
    }

    /**
     * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
     * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
     * reliability of the events, and not the actual splitting of Ether.
     *
     * To learn more about this see the Solidity documentation for
     * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
     * functions].
     */
    receive () external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    /**
     * @dev Getter for the total shares held by payees.
     */
    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    /**
     * @dev Getter for the amount of shares held by an account.
     */
    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    /**
     * @dev Getter for the address of the payee number `index`.
     */
    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function release(address payable account) public virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 totalReceived = address(this).balance + _totalReleased;
        uint256 payment = totalReceived * _shares[account] / _totalShares - _released[account];

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _released[account] = _released[account] + payment;
        _totalReleased = _totalReleased + payment;

        Address.sendValue(account, payment);
        emit PaymentReleased(account, payment);
    }

    /**
     * @dev Add a new payee to the contract.
     * @param account The address of the payee to add.
     * @param shares_ The number of shares owned by the payee.
     */
    function _addPayee(address account, uint256 shares_) private {
        require(account != address(0), "PaymentSplitter: account is the zero address");
        require(shares_ > 0, "PaymentSplitter: shares are 0");
        require(_shares[account] == 0, "PaymentSplitter: account already has shares");

        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares + shares_;
        emit PayeeAdded(account, shares_);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
/**
 * Allows for contract ownership along with multi-address authorization
 */
abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    /**
     * Authorize address. Owner only. Calls internal _authorize method
     */
    function authorize(address adr) external onlyOwner {
        _authorize(adr);
    }
    
    function _authorize (address adr) internal {
        authorizations[adr] = true;
    }
    /**
     * Remove address' authorization. Owner only
     */
    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    /**
     * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
     */
    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library EarnHubLib {
    struct Address {
        uint lastPurchase;
    }

    enum TransferType {
        Sale,
        Purchase,
        Transfer
    }

    struct Transfer {
        Address user;
        uint amt;
        TransferType transferType;
        address from;
        address to;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "../libraries/EarnHubLib.sol";
import "./IGatewayHook.sol";

interface ITransferGateway {
    function removeHookedContract(uint256 _hookedContractId) external;
    function updateHookedContractShares(uint256 _hookedContractId, uint256 _newShares) external;
    function updateHookedContractHandicap(uint256 _hookedContractId, uint256 _newHandicap) external;
    function onTransfer(EarnHubLib.Transfer memory _transfer) external;
    function setBpScale(uint256 _newBpScale) external;
    function setMinGasThreshold(uint _newMinGas) external;
    function setMaxGas(uint256 _newMaxGas) external;
    function depositBNB() external payable;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "../libraries/EarnHubLib.sol";

interface IGatewayHook {
    //should be called only when depositBNB > 0
    function depositBNB(EarnHubLib.Transfer memory transfer) external payable;
    //should be called either case
    function process(EarnHubLib.Transfer memory transfer, uint gasLimit) external;
    function excludeFromProcess(bool val) external;
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}