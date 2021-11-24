// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import "./Auth.sol";
import "./libraries/EarnHubLib.sol";
import "./interfaces/ITransferGateway.sol";
import "./interfaces/IGatewayHook.sol";


//! Remove all comments + Scramble function names before deploying!
// This contract receives Transfer on the onTransfer events from the token Contract
/*
- ✅ It should run process for each hooked contract
- ✅ It should also manage sending BNB to the hooked contracts based on the shares assigned to each of them
- ✅ These shares should be set on this same contract
- ✅ It should take into consideration gas limits for external contract calls
*/
contract TransferGateway is ITransferGateway, Auth {
    // * Event declarations
    event NewContractAdded(address hookedContract, uint256 shares, uint256 handicap);
    event SharesUpdated(address hookedContract, uint256 newShares, uint256 totalShares);
    event HandicapUpdated(address hookedContract, uint256 newHandicap);
    // ? Should these events convey more arguments based on Transfer struct from EarnHubLib.sol?
    event TransferReceived(address from, uint256 amount);
    event TransferReleased(address to, uint256 amount);
    event GenericErrorEvent(string reason);

    // Custom types
    struct HookedContract {
        IGatewayHook hookedContract;
        // * amount of BNB each contract is owed
        uint256 shares;
        // * amount of GasLimit each contract can consume
        uint256 handicap; //! measured in bp, 100 bcp = 1%. should then divide by 10000 (bpScale) whenever this is used
    }

    // State variables
    uint256 public totalShares;

    uint256 public minGas = 1;
    uint256 public maxGas = 1e15;
    uint256 public bpScale = 10000;

    mapping(address => uint256) public shares;
    mapping(address => uint256) public handicaps;

    uint256 public activeContractsCount;

    HookedContract[] public activeContracts;

    constructor(address[] memory _initialContracts, uint256[] memory _shares, uint256[] memory _handicaps) Auth(msg.sender) {
        require(_initialContracts.length == _shares.length, "_initialContracts and _shares length mismatch");
        require(_initialContracts.length == _handicaps.length, "_initialContracts and _handicaps length mismatch");

        _authorize(address(this));
        // * authorizing this contract to deploy hookedContracts

        for (uint256 i = 0; i < _initialContracts.length; i++) {
            require(_handicaps[i] > 0 && _handicaps[i] <= bpScale, "handicaps should be between 0 and bpScale");
            addHookedContract(IGatewayHook(_initialContracts[i]), _shares[i], _handicaps[i]);
        }
    }

    function addHookedContract(IGatewayHook _hookedContract, uint256 _shares, uint256 _handicap) public authorized {
        require(address(_hookedContract) != address(0), "_hookedContract is the zero address");
        require(_shares > 0, "_shares are 0");
        require(_handicap > 0 && _handicap <= bpScale, "handicap should be between 0 and bpScale");

        _authorize(address(_hookedContract));

        activeContracts.push(HookedContract(_hookedContract, _shares, _handicap));
        activeContractsCount++;

        shares[address(_hookedContract)] = _shares;
        totalShares += _shares;

        handicaps[address(_hookedContract)] = _handicap;

        emit NewContractAdded(address(_hookedContract), _shares, _handicap);
    }

    function removeHookedContract(uint256 _hookedContractId) external authorized override {
        updateHookedContractShares(_hookedContractId, 0);
        totalShares -= activeContracts[_hookedContractId].shares;

        updateHookedContractHandicap(_hookedContractId, 0);

        activeContractsCount--;

        delete activeContracts[_hookedContractId];
    }

    function updateHookedContractShares(uint256 _hookedContractId, uint256 _newShares) public authorized override {
        totalShares -= activeContracts[_hookedContractId].shares;
        activeContracts[_hookedContractId].shares = _newShares;
        shares[address(activeContracts[_hookedContractId].hookedContract)] = _newShares;
        totalShares += _newShares;
        emit SharesUpdated(address(activeContracts[_hookedContractId].hookedContract), _newShares, totalShares);
    }

    function updateHookedContractHandicap(uint256 _hookedContractId, uint256 _newHandicap) public authorized override {
        activeContracts[_hookedContractId].handicap = _newHandicap;
        handicaps[address(activeContracts[_hookedContractId].hookedContract)] = _newHandicap;
        emit HandicapUpdated(address(activeContracts[_hookedContractId].hookedContract), _newHandicap);
    }

    function depositBNB() external payable override {
        // * Should be called only when BNBvalue > 0 and we can at least cover gas costs



        if (msg.value < 0 || activeContractsCount < 0) {
            emit GenericErrorEvent("depositBNB(): Failed");
            return;
        }

        // snapshotting balances
        uint256 balance = address(this).balance;

        uint256 maxLength = activeContracts.length;

        // distribution for all active contracts
        for (uint256 i = 0; i < maxLength; i++) {
            //! this check exists because a deleted entry in activeContracts[] results in the zero address
            if (address(activeContracts[i].hookedContract) != address(0)) {
                sendBNBToHookedContract(activeContracts[i], balance);
            }
        }
        emit TransferReceived(msg.sender, msg.value);
    }

    // Forwards a Transfer struct from EarnHub token to IGatewayHook compliant contracts for use in their respective process() methods
    function onTransfer(EarnHubLib.Transfer memory _transfer) external override authorized {
        //TODO experiment with different propagation contract call patterns
        // * handicaps closer to 10000(bp) get mfore gas

        uint256 maxLength = activeContracts.length;
        uint256 gasLimit;
        for (uint256 i = 0; i < maxLength; i++) {
            gasLimit = maxGas * activeContracts[i].handicap / bpScale;
            try activeContracts[i].hookedContract.process(_transfer, gasLimit) {

            } catch Error (string memory reason) {

                emit GenericErrorEvent('onTransfer(): hookedContract.process() failed');
                emit GenericErrorEvent(reason);
            }
        }
        emit TransferReceived(_transfer.from, _transfer.amt);
    }

    // Takes whole BNB batch to distribute, then internally distributes to subscribed contracts based on their shares/totalShares
    function sendBNBToHookedContract(HookedContract memory _hookedContract, uint256 _totalBNBToDistribute) public {

        if (_hookedContract.shares < 0) {
            emit GenericErrorEvent("sendBNBToHookedContract(): _hookedContract has no shares");
            return;
        }

        // calculating due amount based on contract shares
        uint256 accScale = 1 ether * 1 ether;
        // using ether as 1e18, accScale = 1e36
        uint256 allocatedBNB = (_hookedContract.shares * accScale) / totalShares;

        uint256 givenBNB = (allocatedBNB * _totalBNBToDistribute) / accScale;

        // sending BNB to HookedContract

        //Address.sendValue(payable(address(_hookedContract.hookedContract)), givenBNB);
        try _hookedContract.hookedContract.depositBNB{value: givenBNB}(){

        } catch Error (string memory reason) {

            emit GenericErrorEvent('sendBNBToHookedContract(): hookedContract.depositBNB() failed');
            emit GenericErrorEvent(reason);
        }

        emit TransferReleased(address(_hookedContract.hookedContract), givenBNB);
    }

    // * Getter (view only) Functions
    // total shares of HookedContracts accounted for in this contract
    function getTotalShares() public view returns (uint256) {
        return totalShares;
    }

    // shares of a HookedContract
    function getSharesOfContract(address _hookedContract) external view returns (uint256) {
        return shares[_hookedContract];
    }

    // handicap of a HookedContract
    function getHandicapOfContract(HookedContract memory _hookedContract) external view returns (uint256) {
        return handicaps[address(_hookedContract.hookedContract)];
    }

    // address of the activeContracts[_hookedContractId]
    function getContractFromId(uint256 _hookedContractId) external view returns (address) {
        return address(activeContracts[_hookedContractId].hookedContract);
    }

    // * Setter (write only) Functions
    function setBpScale(uint256 _newBpScale) external authorized override {
        bpScale = _newBpScale;
    }

    function setMinGasThreshold(uint256 _newMinGas) external authorized override {
        minGas = _newMinGas;
    }

    function setMaxGas(uint256 _newMaxGas) external authorized override {
        maxGas = _newMaxGas;
    }

    // * Auxiliary functions
    function isContractActive(IGatewayHook _contractAddress) public view returns (bool) {
        for (uint256 i = 0; i < activeContracts.length; i++) {
            if (activeContracts[i].hookedContract == _contractAddress) return true;
        }
        return false;
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
    function depositBNB() external payable;
    //should be called either case
    function process(EarnHubLib.Transfer memory transfer, uint gasLimit) external;
    function excludeFromProcess(bool val) external;
}