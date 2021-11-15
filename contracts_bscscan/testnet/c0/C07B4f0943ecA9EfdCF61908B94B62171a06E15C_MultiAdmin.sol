// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

interface IBlindBox{function transferAdmin(address) external;}

interface IDefinaCard{function setAdmin(address) external;}

interface INFTMarket{function transferOwnership(address) external;}

interface INFTMaster{function transferOwnership(address) external;}

interface IFinaMaster{function transferOwnership(address) external;}

interface IFinaToken{function transferAdmin(address) external;}

/**
 * @dev Contract which allows majority of proposed admins to control the owned contracts.
 * 
 * Any admin can propose a superAdmin_, but minimum 3 admins out of 5 
 * are needed to confirm a SuperAdmin.
 * 
 * A SuperAdmin can be a wallet outside those 5 admins for access control proposes.
 * 
 * Any admin can make one vote. Mnimum 3 votes are needed to perform 
 * important transactions via modifier majority().
 * 
 * In case when 2 out of 5 admin wallets are compromised, the remaining 3 admins can propose
 * and confirm a SuperAdmin who can replace the comprosed admin wallets.
 * 
 * If 3 out of 5 admin wallets are compromised and as long as the 3 compromised wallets are not
 * controlled by the same party, the remaining 2 admins can propose the overturn() method, which
 * if not rejected by the other 3 admins at the same time (we allow for 60 seconds) within a month,
 * can appoint one admin out of the two admins as the new SuperAdmin.
 * 
 * To stop 2 compromised admin walltes from successfully overturning the SuperAdmin, all the remaining
 * admins are required to check back this contract at least twice a month to see if any overturn is proposed.
 * 
 * If 3 out of 5 admin wallets are compromised and controlled by the same party, it will be time for us to 
 * consider using another more secure blockchain.
 * 
 * @dev Remember for the SuperAdmin it is important to immediately reset votes after use.
 * This is to prevent the unlikely situation that SuperAdmin wallet may also be compromised.
 * 
 */
 
contract MultiAdmin is Pausable {
    
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    
    //contracts to be owned by this contract
    address public addrNFTMarket;
    address public addrNFTMaster;
    address public addrFinaToken;
    address public addrFinaMaster;
    address public addrDefinaCard;
    address public addrBlindBox;
    
    EnumerableSet.AddressSet private admins;
    EnumerableSet.AddressSet private proposedSuperAdmins;
    
    //there can only be one confirmed superAdmin which is processed via confirmSuperAdmin().
    address public superAdmin; 
    //counter mapping for admin votes, can only be 0 or 1.
    mapping(address => uint8) public adminVotes;
    //counter mapping for proposed superadmins and its vote by each admin, can only be 0 or 1.
    mapping(address => mapping(address => uint8)) public superAdminVotes; 
    //counter mapping for total votes for the proposed superAdmin.
    mapping(address => uint8) public totalSuperVotes;
    
    //remember to use resetVotes() after required transactions are finished.
    uint8 public totalVotes; 
    
    //counter for total overturn() Votes.
    uint8 public overturnTotalVotes;
    //counter mapping for overturn vote from each admin.
    mapping(address => uint8) public overturnAdminVote;
    //bool mapping for overturn vote from each admin. False = not proposed; True = proposed.
    mapping(address => bool) public overturnAdminPosition;
    //set for each proposed overturn timestamp from each admin (proposal start time plus one month).
    EnumerableSet.UintSet private overturnAdminEndtime;
    //set for each overturn rejection timestamp from each admin.
    EnumerableSet.UintSet private overturnRejectionTime;
    
    constructor(address[] memory admins_){
        //we use a total of 5 admins, and minimum 3 is required for proposed transactions.
        require(admins_.length == 5, "admin number must be 5"); 
        for (uint i = 0; i < admins_.length; i++){
            admins.add(admins_[i]);
            //set initial votes to 0.
            adminVotes[admins_[i]] = 0;
        }
    }
    
    modifier majority() {
        require(totalVotes >= 3, "majority votes not reached!");
        _;
    }

    modifier onlyAdmin() {
        require(admins.contains(_msgSender()), "not called by admin!");
        _;
    }
    
    modifier onlySuperAdmin() {
        require(_msgSender() == superAdmin, "not called by superAdmin!");
        _;
    }
    function inspectVotes() public view returns(uint) {
        return adminVotes[_msgSender()];
    }

    function endTimeAtIndex(uint index) public view returns(uint) {
        require(index < overturnAdminEndtime.length(), "index out of bounds!");
        return overturnAdminEndtime.at(index);
    }

    function rejectionTimeAtIndex(uint index) public view returns(uint) {
        require(index < overturnRejectionTime.length(), "index out of bounds!");
        return overturnRejectionTime.at(index);
    }
    function adminAtIndex(uint8 index) public view returns(address) {
        require(index < admins.length(), "index out of bounds!");
        return admins.at(index);
    }
    
    function isAdmin() view public returns (bool) {
        return admins.contains(_msgSender());
    }
    
    //Can be used to replace a compromised wallet
    function resetAdmin(address oldAdmin, address newAdmin) external majority onlySuperAdmin {
        require(admins.contains(oldAdmin), "oldAdmin not exists!");
        admins.remove(oldAdmin);
        admins.add(newAdmin);
        //reset votes also.
        totalVotes = 0;
        for (uint i = 0; i < admins.length(); i++){
            adminVotes[admins.at(i)] = 0;
        }
        for (uint i = 0; i < proposedSuperAdmins.length(); i++){
            totalSuperVotes[proposedSuperAdmins.at(i)] = 0;
            for (uint j = 0; j < admins.length(); j++){
                superAdminVotes[proposedSuperAdmins.at(i)][admins.at(j)] = 0;}
        }
    }

    function renounceSuperAdmin() public onlySuperAdmin {
        superAdmin = address(0);
    }

    /**
     * @dev This will also reset superAdmin for security purposes.
     * 
     */
    function resetVotes() external majority onlySuperAdmin {
        totalVotes = 0;
        for (uint i = 0; i < admins.length(); i++){
            adminVotes[admins.at(i)] = 0;
        }
        for (uint i = 0; i < proposedSuperAdmins.length(); i++){
            totalSuperVotes[proposedSuperAdmins.at(i)] = 0;
            for (uint j = 0; j < admins.length(); j++){
                superAdminVotes[proposedSuperAdmins.at(i)][admins.at(j)] = 0;}
        }
        renounceSuperAdmin();
    }
    
    function vote() external onlyAdmin {
        //double voting not allowed
        require(adminVotes[_msgSender()] == 0, "already voted!");
        adminVotes[_msgSender()] = 1;
        totalVotes += adminVotes[_msgSender()];
    }

    /**
     * @dev Use this function to propose a new superAdmin_ and vote for them. 
     */
    function voteSuperAdmin(address superAdmin_) external onlyAdmin {
        require(superAdminVotes[superAdmin_][_msgSender()] == 0, "already voted!");
        superAdminVotes[superAdmin_][_msgSender()] = 1;
        totalSuperVotes[superAdmin_] += 1;
        proposedSuperAdmins.add(superAdmin_);
    }
    
    /**
     * @dev Must be called by the proposed superAdmin_ wallet.
     * 
     * minimum 3 votes needed to confirm the superAdmin.
     */
    function confirmSuperAdmin(address superAdmin_) external {
        require(proposedSuperAdmins.contains(_msgSender()), "msg sender is not a proposed superAdmin");
        require(totalSuperVotes[superAdmin_] >= 3,"votes not reached majority");
        superAdmin = superAdmin_;
    }

    /**
     * @dev Must be called by two admins to propose an overturn.
     * Wait for a month before an overturn can be effective.
     */
    function overturnVote() external onlyAdmin {
        require(overturnAdminVote[_msgSender()] == 0, "already voted by msg sender!");
        require(overturnAdminPosition[_msgSender()] == false, "already proposed by msg sender!");
        require(overturnAdminEndtime.length() <=2, "max 2 admins can propose overturn!");
        overturnAdminVote[_msgSender()] = 1;
        overturnTotalVotes += overturnAdminVote[_msgSender()];
        overturnAdminEndtime.add(block.timestamp + 2592000);//after one month.
        overturnAdminPosition[_msgSender()] = true;
    }
    
    /**
     * @dev Must be called by one of the two admins who proposed an overturn.
     * However it is possible to reject the overturn when 3 other admins vote 
     * for rejection at nearly the same time (within 60 seconds).
     */
    function overturn() external onlyAdmin {
        require(overturnAdminEndtime.length() == 2, "2 admins must have proposed overturn!");
        require(block.timestamp >= overturnAdminEndtime.at(1), "can only be called after one month of initial proposal!");
        require(overturnAdminVote[_msgSender()] == 1, "can only be called by an overturn proposer!");
        require(overturnTotalVotes == 2, "2 admins votes are needed for this proposal");
        //three rejections must be done within one minute to void the overturn proposal.
        if(overturnRejectionTime.length() == 3){
            uint maxRejectionTime; uint minRejectionTime;
            for (uint i = 1; i < 3; i++){
                maxRejectionTime = overturnRejectionTime.at(i) > overturnRejectionTime.at(i-1) ? overturnRejectionTime.at(i) : overturnRejectionTime.at(i-1);
                minRejectionTime = overturnRejectionTime.at(i) < overturnRejectionTime.at(i-1) ? overturnRejectionTime.at(i) : overturnRejectionTime.at(i-1);
            }
            if(maxRejectionTime <= minRejectionTime + 60){
                //if rejection success, reset counters.
                resetOverturn();
            } else {
                //else just reset rejection counters
                for (uint i = 0; i < overturnRejectionTime.length(); i++){
                    overturnRejectionTime.remove(overturnRejectionTime.at(i));
                }
                for (uint i = 0; i < admins.length(); i++){
                    overturnAdminPosition[admins.at(i)] = false;
                }
            }
        }
        else {
            //if overturn success, set superAdmin and reset counters.
            superAdmin = _msgSender();
            resetOverturn();
        }
    }
    
    //reset overturn counters whether successful or not.
    function resetOverturn() internal {
        overturnTotalVotes = 0;
        for (uint i = 0; i < admins.length(); i++){
            overturnAdminVote[admins.at(i)] = 0;
            overturnAdminPosition[admins.at(i)] = false;
        }
        overturnAdminEndtime.remove(overturnAdminEndtime.at(0));
        overturnAdminEndtime.remove(overturnAdminEndtime.at(0));
        for (uint i = 0; i < overturnRejectionTime.length(); i++){
            overturnRejectionTime.remove(overturnRejectionTime.at(i));
        }
    }
    
    /**
     * @dev In case two compromised wallets propose an overturn, it is advised
     * for the remaining admins to keep regular checks on this contract, and Use
     * superAdmin to replace compromised wallets so they cannot propose overturn again.
     */    
    function rejectOverturn() external onlyAdmin{
        require(overturnAdminPosition[_msgSender()] == false, "already proposed by msg sender!");
        //get last recorded end time from overturn proposal
        uint lastRecordedEndTime = overturnAdminEndtime.at(1) > overturnAdminEndtime.at(0) ? overturnAdminEndtime.at(1) : overturnAdminEndtime.at(0);
        require(lastRecordedEndTime > 0, "lastRecordedEndTime cannot be zero!");
        require(block.timestamp <= lastRecordedEndTime, "one month has passed!");
        require(overturnRejectionTime.length() <=3, "max 3 admins can propose rejection of overturn!");
        overturnRejectionTime.add(block.timestamp);
        overturnAdminPosition[_msgSender()] = true;
    }
    
    function updateNFTMarket(address _new) external majority onlySuperAdmin whenPaused {
        addrNFTMarket = _new;
    }
    
    function updateNFTMaster(address _new) external majority onlySuperAdmin whenPaused {
        addrNFTMaster = _new;
    }

    function updateFinaToken(address _new) external majority onlySuperAdmin whenPaused {
        addrFinaToken = _new;
    }

    function updateFinaMaster(address _new) external majority onlySuperAdmin whenPaused {
        addrFinaMaster = _new;
    }

    function updateDefinaCard(address _new) external majority onlySuperAdmin whenPaused {
        addrDefinaCard = _new;
    }

    function updateBlindbox(address _new) external majority onlySuperAdmin whenPaused {
        addrBlindBox = _new;
    }

    //minimum 3 votes needed to pause
    function pause() external majority onlyAdmin whenNotPaused() {
        _pause();
    }

    function unpause() external majority onlyAdmin whenPaused {
        _unpause();
    }

    function changeAdminOfBlindBox(address newOwner) external majority onlySuperAdmin whenPaused {
        IBlindBox(addrBlindBox).transferAdmin(newOwner);
    }

    function changeAdminOfDefinaCard(address newOwner) external majority onlySuperAdmin whenPaused {
        IDefinaCard(addrDefinaCard).setAdmin(newOwner);
    }
    
    function changeOwnerOfNFTMarket(address newOwner) external majority onlySuperAdmin whenPaused {
        INFTMarket(addrNFTMarket).transferOwnership(newOwner);
    }

    function changeOwnerOfNFTMaster(address newOwner) external majority onlySuperAdmin whenPaused {
        INFTMaster(addrNFTMaster).transferOwnership(newOwner);
    }

    function changeOwnerOfFinaMaster(address newOwner) external majority onlySuperAdmin whenPaused {
        IFinaMaster(addrFinaMaster).transferOwnership(newOwner);
    }

    function changeOwnerOfFinaToken(address newOwner) external majority onlySuperAdmin whenPaused {
        IFinaToken(addrFinaToken).transferAdmin(newOwner);
    }
    
    /*
     * @dev Pull out all balance of token or BNB in this contract. When tokenAddress_ is 0x0, will transfer all BNB to the admin owner.
     */
    function pullFunds(address tokenAddress_) external majority onlySuperAdmin {
        if (tokenAddress_ == address(0)) {
            payable(_msgSender()).transfer(address(this).balance);
        } else {
            IERC20 token = IERC20(tokenAddress_);
            token.transfer(_msgSender(), token.balanceOf(address(this)));
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

