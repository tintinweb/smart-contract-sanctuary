// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/utils/Address.sol";

import './interfaces/IManagementCompany.sol';

contract ManagementCompany is IManagementCompany {
    using Address for address;

    address[] public MCBoard;
    uint public override minApprovalRequired;
    mapping(address => uint) indexOfMCBoard;
    address public override SPVWalletAddress;
    address public override LOSCAddress;

    uint public override pendingMinApprovalRequired;
    address public override pendingMCBoardMember;
    address public override pendingRemoveMember;
    address public override pendingSPVWalletAddress;
    address public override pendingLOSCAddress;

    address[] public boardMemberVoteFlags;
    address[] public minApprovalRequiredVoteFlags;
    address[] public removeMemberVoteFlags;
    address[] public SPVWalletAddressVoteFlags;
    address[] public LOSCAddressVoteFlags;
    

    modifier onlyAdmin {
        require(indexOfMCBoard[msg.sender] != 0, "Invalid msg.sender: only board member can modify MC smart contract.");
        _;
    }

    constructor(address admin1, address admin2, address admin3) public {
        // init the smart contract with a zero address (for place offset) and 3 MC Board member;
        MCBoard.push(address(0));
        MCBoard.push(admin1);
        indexOfMCBoard[admin1] = 1;
        MCBoard.push(admin2);
        indexOfMCBoard[admin2] = 2;
        MCBoard.push(admin3);
        indexOfMCBoard[admin3] = 3;
        // init with minimum 2 approval required.
        minApprovalRequired = 2;
    }

    function isMCAdmin(address account) external view override returns (bool) {
        return (account != address(0) && indexOfMCBoard[account] != 0);
    }

    function proposeNewAdmin(address newAdmin) external override onlyAdmin {
        require(newAdmin != pendingMCBoardMember, "Invalid parameter: please propose a different admin account.");
        pendingMCBoardMember = newAdmin;
        boardMemberVoteFlags = [msg.sender];
        emit newAdminProposed(msg.sender, newAdmin);
    }

    function proposeNewSPVWalletAddress(address newSPVWalletAddress) external override onlyAdmin {
        require(newSPVWalletAddress != SPVWalletAddress, "Invalid parameter: please propose a different admin account.");
        require(newSPVWalletAddress.isContract() == true, "Invalid address: address should be contract address");
        pendingSPVWalletAddress = newSPVWalletAddress;
        SPVWalletAddressVoteFlags = [msg.sender];
        emit newSPVWalletAddressProposed(msg.sender, newSPVWalletAddress);
    }

    function proposeNewLOSCAddress(address newLOSCAddress) external override onlyAdmin {
        require(newLOSCAddress != LOSCAddress, "Invalid parameter: please propose a different LOSC address.");
        require(newLOSCAddress.isContract() == true, "Invalid address: address should be contract address");
        pendingLOSCAddress = newLOSCAddress;
        LOSCAddressVoteFlags = [msg.sender];
        emit newLOSCAddressProposed(msg.sender, newLOSCAddress);
    }

    function proposeNewApprovalRequiredNumber(uint number) external override onlyAdmin {
        require(number != pendingMinApprovalRequired, "Invalid parameter: please propose a different minimum required approval number.");
        require(number <= MCBoard.length - 1 && number > 0, "Invalid number: the minimum approval required number should be greater than 0, less than or equal to the number of MC board members.");
        pendingMinApprovalRequired = number;
        minApprovalRequiredVoteFlags = [msg.sender];
        emit newMinApprovalRequiredProposed(msg.sender, number);
    }

    function proposeRemoveAdmin(address adminToBeRemoved) external override onlyAdmin {
        require(adminToBeRemoved != pendingRemoveMember, "Invalid parameter: please propose a different to-be-removed board member.");
        require(adminToBeRemoved != address(0), "Invalid parameter: zero address is not removable.");
        //Should we consider also updating minApprovalRequired for some removal cases?
        require(MCBoard.length  > minApprovalRequired, "Invalid request: the minApprovalRequired exceeds the number of board members after member removal.");
        require(indexOfMCBoard[adminToBeRemoved] != 0, "Invalid request: the account is not in MC Board.");
        pendingRemoveMember = adminToBeRemoved;
        removeMemberVoteFlags = [msg.sender];
        emit newMemberRemovalProposed(msg.sender, adminToBeRemoved);
    }

    function approveNewAdmin() external override onlyAdmin {
        require(pendingMCBoardMember != address(0), "Invalid request: no propose found.");
        
        bool foundVote = false;

        for(uint i = 0; i < boardMemberVoteFlags.length; i++) {
            if(boardMemberVoteFlags[i] == msg.sender) {
                foundVote = true;
            }
        }

        if(foundVote == false) {
            boardMemberVoteFlags.push(msg.sender);
            emit newAdminApproval(msg.sender, pendingMCBoardMember);
        }
        
        if (isVotesSufficient(boardMemberVoteFlags)) {
            // reset vote
            delete boardMemberVoteFlags;

            // update MC Board
            MCBoard.push(pendingMCBoardMember);
            indexOfMCBoard[pendingMCBoardMember] = MCBoard.length - 1;
            // reset to zero account
            pendingMCBoardMember = address(0);
            emit newAdminAppended(MCBoard[MCBoard.length - 1]);
        }
    }

    function approveNewSPVWalletAddress() external override onlyAdmin {
        require(pendingSPVWalletAddress != address(0), "Invalid request: no propose found.");
        
        bool foundVote = false;

        for(uint i = 0; i < SPVWalletAddressVoteFlags.length; i++) {
            if(SPVWalletAddressVoteFlags[i] == msg.sender) {
                foundVote = true;
            }
        }

        if(foundVote == false) {
            SPVWalletAddressVoteFlags.push(msg.sender);
            emit newSPVWalletAddressApproval(msg.sender, pendingSPVWalletAddress);
        }
        
        if (isVotesSufficient(SPVWalletAddressVoteFlags)) {
            // reset vote
            delete SPVWalletAddressVoteFlags;

            // update SPVWallet address
            SPVWalletAddress = pendingSPVWalletAddress;
            // reset to zero account
            pendingSPVWalletAddress = address(0);
            emit newSPVWalletAddressApproved(SPVWalletAddress);
        }
    }

    function approveNewLOSCAddress() external override onlyAdmin {
        require(pendingLOSCAddress != address(0), "Invalid request: no propose found.");
        
        bool foundVote = false;

        for(uint i = 0; i < LOSCAddressVoteFlags.length; i++) {
            if(LOSCAddressVoteFlags[i] == msg.sender) {
                foundVote = true;
            }
        }

        if(foundVote == false) {
            LOSCAddressVoteFlags.push(msg.sender);
            emit newLOSCAddressApproval(msg.sender, pendingLOSCAddress);
        }
        
        if (isVotesSufficient(LOSCAddressVoteFlags)) {
            // reset vote
            delete LOSCAddressVoteFlags;

            // update LOSC address
            LOSCAddress = pendingLOSCAddress;
            // reset to zero account
            pendingLOSCAddress = address(0);
            emit newLOSCAddressApproved(LOSCAddress);
        }
    }

    function approveNewApprovalRequiredNumber() external override onlyAdmin {
        require(pendingMinApprovalRequired > 0, "Please propose a minApprovalRequired number first.");

        bool foundVote = false;

        for(uint i = 0; i < minApprovalRequiredVoteFlags.length; i++) {
            if(minApprovalRequiredVoteFlags[i] == msg.sender) {
                foundVote = true;
            }
        }

        if(foundVote == false) {
            minApprovalRequiredVoteFlags.push(msg.sender);
            emit newMinApprovalRequiredApproval(msg.sender, pendingMinApprovalRequired);
        }

        if (isVotesSufficient(minApprovalRequiredVoteFlags)) {
            // reset vote
            delete minApprovalRequiredVoteFlags;
            //update minApprovalRequired
            minApprovalRequired = pendingMinApprovalRequired;
            // reset to zero
            pendingMinApprovalRequired = 0;
            emit newMinApprovalRequiredUpdated(minApprovalRequired);
        }
    }

    function approveAdminRemoval() external override onlyAdmin {
        require(pendingRemoveMember != address(0), "Invalid request: no propose found.");

        bool foundVote = false;

        for(uint i = 0; i < removeMemberVoteFlags.length; i++) {
            if(removeMemberVoteFlags[i] == msg.sender) {
                foundVote = true;
            }
        }

        if(foundVote == false) {
            removeMemberVoteFlags.push(msg.sender);
            emit newMemberRemovalApproval(msg.sender, pendingRemoveMember);
        }

        if (isVotesSufficient(removeMemberVoteFlags)) {
            // reset the vote
            delete removeMemberVoteFlags;
            address _pendingRemoveMember = pendingRemoveMember;
            // reset to zero
            pendingRemoveMember = address(0);

            //swap delete
            uint indexOfLastMCBoard = MCBoard.length - 1;
            address lastMemberAddress = MCBoard[indexOfLastMCBoard];
            uint indexOfRemoveMember = indexOfMCBoard[_pendingRemoveMember];
            MCBoard[indexOfRemoveMember] = lastMemberAddress;
            indexOfMCBoard[lastMemberAddress] = indexOfRemoveMember;
            indexOfMCBoard[_pendingRemoveMember] = 0;
            MCBoard.pop();
            delete removeMemberVoteFlags;
            
            emit memberRemoved(_pendingRemoveMember);
        }
    }

    function isVotesSufficient(address[] memory votingFlags) public override returns (bool) {
        uint numOfVotes = 0;
        for (uint i = 0; i < votingFlags.length; i++) {
            for (uint j = 0; j < MCBoard.length; j++) {
                if(votingFlags[i] == MCBoard[j]) {
                    numOfVotes++;
                }
            }
        }
        return numOfVotes >= minApprovalRequired;

    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
pragma solidity ^0.7.6;

interface IManagementCompany {
    event newAdminProposed(address indexed proposer, address indexed newPendingAdmin);
    event newSPVWalletAddressProposed(address indexed proposer, address indexed newSPVWalletAddress);
    event newLOSCAddressProposed(address indexed proposer, address indexed newSPVWalletAddress);
    event newMinApprovalRequiredProposed(address indexed proposer, uint indexed newNumber);
    event newMemberRemovalProposed(address indexed proposer, address indexed newPendingRemoveMember);

    event newAdminApproval(address indexed proposer, address indexed newPendingAdmin);
    event newSPVWalletAddressApproval(address indexed proposer, address indexed newSPVWalletAddress);
    event newLOSCAddressApproval(address indexed proposer, address indexed newSPVWalletAddress);
    event newMinApprovalRequiredApproval(address indexed proposer, uint indexed newNumber);
    event newMemberRemovalApproval(address indexed proposer, address indexed newPendingRemoveMember);

    event newAdminAppended(address indexed newPendingAdmin);
    event newSPVWalletAddressApproved(address indexed newSPVWalletAddress);
    event newLOSCAddressApproved(address indexed newSPVWalletAddress);
    event newMinApprovalRequiredUpdated(uint indexed newNumber);
    event memberRemoved(address indexed newPendingRemoveMember);

    function minApprovalRequired() external view returns (uint);
    function SPVWalletAddress() external returns (address);
    function LOSCAddress() external returns (address);
    function isMCAdmin(address admin) external returns (bool);


    function pendingMinApprovalRequired() external view returns (uint);
    function pendingSPVWalletAddress() external view returns (address);
    function pendingLOSCAddress() external view returns (address);
    function pendingMCBoardMember() external view returns (address);
    function pendingRemoveMember() external view returns (address);

    function proposeNewAdmin(address newAdmin) external;
    function proposeNewSPVWalletAddress(address newAdmin) external;
    function proposeNewLOSCAddress(address newAdmin) external;
    function proposeNewApprovalRequiredNumber(uint number) external;
    function proposeRemoveAdmin(address adminToBeRemoved) external;

    function approveNewAdmin() external;
    function approveNewSPVWalletAddress() external;
    function approveNewLOSCAddress() external;
    function approveNewApprovalRequiredNumber() external;
    function approveAdminRemoval() external;

    function isVotesSufficient(address[] memory votingFlags) external returns (bool);
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
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