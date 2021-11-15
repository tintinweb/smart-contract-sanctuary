// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./../interfaces/ITerminalV1.sol";

/** 
  @notice A contract that inherits from JuiceboxProject can use Juicebox as a business-model-as-a-service.
  @dev The owner of the contract makes admin decisions such as:
    - Which address is the funding cycle owner, which can tap funds from the funding cycle.
    - Should this project's Tickets be migrated to a new TerminalV1. 
*/
abstract contract JuiceboxProject is IERC721Receiver, Ownable {
    /// @notice The direct deposit terminals.
    ITerminalDirectory public immutable terminalDirectory;

    /// @notice The ID of the project that should be used to forward this contract's received payments.
    uint256 public projectId;

    /** 
      @param _projectId The ID of the project that should be used to forward this contract's received payments.
      @param _terminalDirectory A directory of a project's current Juicebox terminal to receive payments in.
    */
    constructor(uint256 _projectId, ITerminalDirectory _terminalDirectory) {
        projectId = _projectId;
        terminalDirectory = _terminalDirectory;
    }

    receive() external payable {}

    /** 
      @notice Withdraws funds stored in this contract.
      @param _beneficiary The address to send the funds to.
      @param _amount The amount to send.
    */
    function withdraw(address payable _beneficiary, uint256 _amount)
        external
        onlyOwner
    {
        Address.sendValue(_beneficiary, _amount);
    }

    /** 
      @notice Allows the project that is being managed to be set.
      @param _projectId The ID of the project that is being managed.
    */
    function setProjectId(uint256 _projectId) external onlyOwner {
        projectId = _projectId;
    }

    /** 
      @notice Make a payment to this project.
      @param _beneficiary The address who will receive tickets from this fee.
      @param _memo A memo that will be included in the published event.
      @param _preferUnstakedTickets Whether ERC20's should be claimed automatically if they have been issued.
    */
    function pay(
        address _beneficiary,
        string calldata _memo,
        bool _preferUnstakedTickets
    ) external payable {
        require(projectId != 0, "JuiceboxProject::pay: PROJECT_NOT_FOUND");

        // Get the terminal for this contract's project.
        ITerminal _terminal = terminalDirectory.terminalOf(projectId);

        // There must be a terminal.
        require(
            _terminal != ITerminal(address(0)),
            "JuiceboxProject::pay: TERMINAL_NOT_FOUND"
        );

        _terminal.pay{value: msg.value}(
            projectId,
            _beneficiary,
            _memo,
            _preferUnstakedTickets
        );
    }

    /** 
        @notice Transfer the ownership of the project to a new owner.  
        @dev This contract will no longer be able to reconfigure or tap funds from this project.
        @param _projects The projects contract.
        @param _newOwner The new project owner.
        @param _projectId The ID of the project to transfer ownership of.
        @param _data Arbitrary data to include in the transaction.
    */
    function transferProjectOwnership(
        IProjects _projects,
        address _newOwner,
        uint256 _projectId,
        bytes calldata _data
    ) external onlyOwner {
        _projects.safeTransferFrom(address(this), _newOwner, _projectId, _data);
    }

    /** 
      @notice Allows this contract to receive a project.
    */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) public pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function setOperator(
        IOperatorStore _operatorStore,
        address _operator,
        uint256 _projectId,
        uint256[] calldata _permissionIndexes
    ) external onlyOwner {
        _operatorStore.setOperator(_operator, _projectId, _permissionIndexes);
    }

    function setOperators(
        IOperatorStore _operatorStore,
        address[] calldata _operators,
        uint256[] calldata _projectIds,
        uint256[][] calldata _permissionIndexes
    ) external onlyOwner {
        _operatorStore.setOperators(
            _operators,
            _projectIds,
            _permissionIndexes
        );
    }

    /** 
      @notice Take a fee for this project from this contract.
      @param _amount The payment amount.
      @param _beneficiary The address who will receive tickets from this fee.
      @param _memo A memo that will be included in the published event.
      @param _preferUnstakedTickets Whether ERC20's should be claimed automatically if they have been issued.
    */
    function _takeFee(
        uint256 _amount,
        address _beneficiary,
        string memory _memo,
        bool _preferUnstakedTickets
    ) internal {
        require(projectId != 0, "JuiceboxProject::takeFee: PROJECT_NOT_FOUND");
        // Find the terminal for this contract's project.
        ITerminal _terminal = terminalDirectory.terminalOf(projectId);

        // There must be a terminal.
        require(
            _terminal != ITerminal(address(0)),
            "JuiceboxProject::takeFee: TERMINAL_NOT_FOUND"
        );

        // There must be enough funds in the contract to take the fee.
        require(
            address(this).balance >= _amount,
            "JuiceboxProject::takeFee: INSUFFICIENT_FUNDS"
        );

        // Send funds to the terminal.
        _terminal.pay{value: _amount}(
            projectId,
            _beneficiary,
            _memo,
            _preferUnstakedTickets
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
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
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./ITicketBooth.sol";
import "./IFundingCycles.sol";
import "./IYielder.sol";
import "./IProjects.sol";
import "./IModStore.sol";
import "./ITerminal.sol";
import "./IOperatorStore.sol";

struct FundingCycleMetadata {
    uint256 reservedRate;
    uint256 bondingCurveRate;
    uint256 reconfigurationBondingCurveRate;
}

interface ITerminalV1 {
    event Configure(
        uint256 indexed fundingCycleId,
        uint256 indexed projectId,
        address caller
    );

    event Tap(
        uint256 indexed fundingCycleId,
        uint256 indexed projectId,
        address indexed beneficiary,
        uint256 amount,
        uint256 currency,
        uint256 netTransferAmount,
        uint256 beneficiaryTransferAmount,
        uint256 govFeeAmount,
        address caller
    );
    event Redeem(
        address indexed holder,
        address indexed beneficiary,
        uint256 indexed _projectId,
        uint256 amount,
        uint256 returnAmount,
        address caller
    );

    event PrintReserveTickets(
        uint256 indexed fundingCycleId,
        uint256 indexed projectId,
        address indexed beneficiary,
        uint256 count,
        uint256 beneficiaryTicketAmount,
        address caller
    );

    event DistributeToPayoutMod(
        uint256 indexed fundingCycleId,
        uint256 indexed projectId,
        PayoutMod mod,
        uint256 modCut,
        address caller
    );
    event DistributeToTicketMod(
        uint256 indexed fundingCycleId,
        uint256 indexed projectId,
        TicketMod mod,
        uint256 modCut,
        address caller
    );
    event AppointGovernance(address governance);

    event AcceptGovernance(address governance);

    event PrintPreminedTickets(
        uint256 indexed projectId,
        address indexed beneficiary,
        uint256 amount,
        uint256 currency,
        string memo,
        address caller
    );

    event Deposit(uint256 amount);

    event EnsureTargetLocalWei(uint256 target);

    event SetYielder(IYielder newYielder);

    event SetFee(uint256 _amount);

    event SetTargetLocalWei(uint256 amount);

    function governance() external view returns (address payable);

    function pendingGovernance() external view returns (address payable);

    function projects() external view returns (IProjects);

    function fundingCycles() external view returns (IFundingCycles);

    function ticketBooth() external view returns (ITicketBooth);

    function prices() external view returns (IPrices);

    function modStore() external view returns (IModStore);

    function reservedTicketBalanceOf(uint256 _projectId, uint256 _reservedRate)
        external
        view
        returns (uint256);

    function canPrintPreminedTickets(uint256 _projectId)
        external
        view
        returns (bool);

    function balanceOf(uint256 _projectId) external view returns (uint256);

    function currentOverflowOf(uint256 _projectId)
        external
        view
        returns (uint256);

    function claimableOverflowOf(
        address _account,
        uint256 _amount,
        uint256 _projectId
    ) external view returns (uint256);

    function fee() external view returns (uint256);

    function deploy(
        address _owner,
        bytes32 _handle,
        string calldata _uri,
        FundingCycleProperties calldata _properties,
        FundingCycleMetadata calldata _metadata,
        PayoutMod[] memory _payoutMods,
        TicketMod[] memory _ticketMods
    ) external;

    function configure(
        uint256 _projectId,
        FundingCycleProperties calldata _properties,
        FundingCycleMetadata calldata _metadata,
        PayoutMod[] memory _payoutMods,
        TicketMod[] memory _ticketMods
    ) external returns (uint256);

    function printPreminedTickets(
        uint256 _projectId,
        uint256 _amount,
        uint256 _currency,
        address _beneficiary,
        string memory _memo,
        bool _preferUnstakedTickets
    ) external;

    function tap(
        uint256 _projectId,
        uint256 _amount,
        uint256 _currency,
        uint256 _minReturnedWei
    ) external returns (uint256);

    function redeem(
        address _account,
        uint256 _projectId,
        uint256 _amount,
        uint256 _minReturnedWei,
        address payable _beneficiary,
        bool _preferUnstaked
    ) external returns (uint256 returnAmount);

    function printReservedTickets(uint256 _projectId)
        external
        returns (uint256 reservedTicketsToPrint);

    function setFee(uint256 _fee) external;

    function appointGovernance(address payable _pendingGovernance) external;

    function acceptGovernance() external;
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

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./IProjects.sol";
import "./IOperatorStore.sol";
import "./ITickets.sol";

interface ITicketBooth {
    event Issue(
        uint256 indexed projectId,
        string name,
        string symbol,
        address caller
    );
    event Print(
        address indexed holder,
        uint256 indexed projectId,
        uint256 amount,
        bool convertedTickets,
        bool preferUnstakedTickets,
        address controller
    );

    event Redeem(
        address indexed holder,
        uint256 indexed projectId,
        uint256 amount,
        uint256 stakedTickets,
        bool preferUnstaked,
        address controller
    );

    event Stake(
        address indexed holder,
        uint256 indexed projectId,
        uint256 amount,
        address caller
    );

    event Unstake(
        address indexed holder,
        uint256 indexed projectId,
        uint256 amount,
        address caller
    );

    event Lock(
        address indexed holder,
        uint256 indexed projectId,
        uint256 amount,
        address caller
    );

    event Unlock(
        address indexed holder,
        uint256 indexed projectId,
        uint256 amount,
        address caller
    );

    event Transfer(
        address indexed holder,
        uint256 indexed projectId,
        address indexed recipient,
        uint256 amount,
        address caller
    );

    function ticketsOf(uint256 _projectId) external view returns (ITickets);

    function projects() external view returns (IProjects);

    function lockedBalanceOf(address _holder, uint256 _projectId)
        external
        view
        returns (uint256);

    function lockedBalanceBy(
        address _operator,
        address _holder,
        uint256 _projectId
    ) external view returns (uint256);

    function stakedBalanceOf(address _holder, uint256 _projectId)
        external
        view
        returns (uint256);

    function stakedTotalSupplyOf(uint256 _projectId)
        external
        view
        returns (uint256);

    function totalSupplyOf(uint256 _projectId) external view returns (uint256);

    function balanceOf(address _holder, uint256 _projectId)
        external
        view
        returns (uint256 _result);

    function issue(
        uint256 _projectId,
        string calldata _name,
        string calldata _symbol
    ) external;

    function print(
        address _holder,
        uint256 _projectId,
        uint256 _amount,
        bool _preferUnstakedTickets
    ) external;

    function redeem(
        address _holder,
        uint256 _projectId,
        uint256 _amount,
        bool _preferUnstaked
    ) external;

    function stake(
        address _holder,
        uint256 _projectId,
        uint256 _amount
    ) external;

    function unstake(
        address _holder,
        uint256 _projectId,
        uint256 _amount
    ) external;

    function lock(
        address _holder,
        uint256 _projectId,
        uint256 _amount
    ) external;

    function unlock(
        address _holder,
        uint256 _projectId,
        uint256 _amount
    ) external;

    function transfer(
        address _holder,
        uint256 _projectId,
        uint256 _amount,
        address _recipient
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./IPrices.sol";
import "./IProjects.sol";
import "./IFundingCycleBallot.sol";

/// @notice The funding cycle structure represents a project stewarded by an address, and accounts for which addresses have helped sustain the project.
struct FundingCycle {
    // A unique number that's incremented for each new funding cycle, starting with 1.
    uint256 id;
    // The ID of the project contract that this funding cycle belongs to.
    uint256 projectId;
    // The number of this funding cycle for the project.
    uint256 number;
    // The ID of a previous funding cycle that this one is based on.
    uint256 basedOn;
    // The time when this funding cycle was last configured.
    uint256 configured;
    // The number of cycles that this configuration should last for before going back to the last permanent.
    uint256 cycleLimit;
    // A number determining the amount of redistribution shares this funding cycle will issue to each sustainer.
    uint256 weight;
    // The ballot contract to use to determine a subsequent funding cycle's reconfiguration status.
    IFundingCycleBallot ballot;
    // The time when this funding cycle will become active.
    uint256 start;
    // The number of seconds until this funding cycle's surplus is redistributed.
    uint256 duration;
    // The amount that this funding cycle is targeting in terms of the currency.
    uint256 target;
    // The currency that the target is measured in.
    uint256 currency;
    // The percentage of each payment to send as a fee to the Juicebox admin.
    uint256 fee;
    // A percentage indicating how much more weight to give a funding cycle compared to its predecessor.
    uint256 discountRate;
    // The amount of available funds that have been tapped by the project in terms of the currency.
    uint256 tapped;
    // A packed list of extra data. The first 8 bytes are reserved for versioning.
    uint256 metadata;
}

struct FundingCycleProperties {
    uint256 target;
    uint256 currency;
    uint256 duration;
    uint256 cycleLimit;
    uint256 discountRate;
    IFundingCycleBallot ballot;
}

interface IFundingCycles {
    event Configure(
        uint256 indexed fundingCycleId,
        uint256 indexed projectId,
        uint256 reconfigured,
        FundingCycleProperties _properties,
        uint256 metadata,
        address caller
    );

    event Tap(
        uint256 indexed fundingCycleId,
        uint256 indexed projectId,
        uint256 amount,
        uint256 newTappedAmount,
        address caller
    );

    event Init(
        uint256 indexed fundingCycleId,
        uint256 indexed projectId,
        uint256 number,
        uint256 previous,
        uint256 weight,
        uint256 start
    );

    function latestIdOf(uint256 _projectId) external view returns (uint256);

    function count() external view returns (uint256);

    function BASE_WEIGHT() external view returns (uint256);

    function MAX_CYCLE_LIMIT() external view returns (uint256);

    function get(uint256 _fundingCycleId)
        external
        view
        returns (FundingCycle memory);

    function queuedOf(uint256 _projectId)
        external
        view
        returns (FundingCycle memory);

    function currentOf(uint256 _projectId)
        external
        view
        returns (FundingCycle memory);

    function currentBallotStateOf(uint256 _projectId)
        external
        view
        returns (BallotState);

    function configure(
        uint256 _projectId,
        FundingCycleProperties calldata _properties,
        uint256 _metadata,
        uint256 _fee,
        bool _configureActiveFundingCycle
    ) external returns (FundingCycle memory fundingCycle);

    function tap(uint256 _projectId, uint256 _amount)
        external
        returns (FundingCycle memory fundingCycle);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./ITerminalV1.sol";

// In constructure, give unlimited access for TerminalV1 to take money from this.
interface IYielder {
    function deposited() external view returns (uint256);

    function getCurrentBalance() external view returns (uint256);

    function deposit() external payable;

    function withdraw(uint256 _amount, address payable _beneficiary) external;

    function withdrawAll(address payable _beneficiary)
        external
        returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./ITerminal.sol";
import "./IOperatorStore.sol";

interface IProjects is IERC721 {
    event Create(
        uint256 indexed projectId,
        address indexed owner,
        bytes32 indexed handle,
        string uri,
        ITerminal terminal,
        address caller
    );

    event SetHandle(
        uint256 indexed projectId,
        bytes32 indexed handle,
        address caller
    );

    event SetUri(uint256 indexed projectId, string uri, address caller);

    event TransferHandle(
        uint256 indexed projectId,
        address indexed to,
        bytes32 indexed handle,
        bytes32 newHandle,
        address caller
    );

    event ClaimHandle(
        address indexed account,
        uint256 indexed projectId,
        bytes32 indexed handle,
        address caller
    );

    event ChallengeHandle(
        bytes32 indexed handle,
        uint256 challengeExpiry,
        address caller
    );

    event RenewHandle(
        bytes32 indexed handle,
        uint256 indexed projectId,
        address caller
    );

    function count() external view returns (uint256);

    function uriOf(uint256 _projectId) external view returns (string memory);

    function handleOf(uint256 _projectId) external returns (bytes32 handle);

    function projectFor(bytes32 _handle) external returns (uint256 projectId);

    function transferAddressFor(bytes32 _handle)
        external
        returns (address receiver);

    function challengeExpiryOf(bytes32 _handle) external returns (uint256);

    function exists(uint256 _projectId) external view returns (bool);

    function create(
        address _owner,
        bytes32 _handle,
        string calldata _uri,
        ITerminal _terminal
    ) external returns (uint256 id);

    function setHandle(uint256 _projectId, bytes32 _handle) external;

    function setUri(uint256 _projectId, string calldata _uri) external;

    function transferHandle(
        uint256 _projectId,
        address _to,
        bytes32 _newHandle
    ) external returns (bytes32 _handle);

    function claimHandle(
        bytes32 _handle,
        address _for,
        uint256 _projectId
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./IOperatorStore.sol";
import "./IProjects.sol";
import "./IModAllocator.sol";

struct PayoutMod {
    bool preferUnstaked;
    uint16 percent;
    uint48 lockedUntil;
    address payable beneficiary;
    IModAllocator allocator;
    uint56 projectId;
}

struct TicketMod {
    bool preferUnstaked;
    uint16 percent;
    uint48 lockedUntil;
    address payable beneficiary;
}

interface IModStore {
    event SetPayoutMod(
        uint256 indexed projectId,
        uint256 indexed configuration,
        PayoutMod mods,
        address caller
    );

    event SetTicketMod(
        uint256 indexed projectId,
        uint256 indexed configuration,
        TicketMod mods,
        address caller
    );

    function projects() external view returns (IProjects);

    function payoutModsOf(uint256 _projectId, uint256 _configuration)
        external
        view
        returns (PayoutMod[] memory);

    function ticketModsOf(uint256 _projectId, uint256 _configuration)
        external
        view
        returns (TicketMod[] memory);

    function setPayoutMods(
        uint256 _projectId,
        uint256 _configuration,
        PayoutMod[] memory _mods
    ) external;

    function setTicketMods(
        uint256 _projectId,
        uint256 _configuration,
        TicketMod[] memory _mods
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ITerminalDirectory.sol";

interface ITerminal {
    event Pay(
        uint256 indexed fundingCycleId,
        uint256 indexed projectId,
        address indexed beneficiary,
        uint256 amount,
        string note,
        address caller
    );

    event AddToBalance(
        uint256 indexed projectId,
        uint256 value,
        address caller
    );

    event AllowMigration(ITerminal allowed);

    event Migrate(
        uint256 indexed projectId,
        ITerminal indexed to,
        uint256 _amount,
        address caller
    );

    function terminalDirectory() external view returns (ITerminalDirectory);

    function migrationIsAllowed(ITerminal _terminal)
        external
        view
        returns (bool);

    function pay(
        uint256 _projectId,
        address _beneficiary,
        string calldata _memo,
        bool _preferUnstakedTickets
    ) external payable returns (uint256 fundingCycleId);

    function addToBalance(uint256 _projectId) external payable;

    function allowMigration(ITerminal _contract) external;

    function migrate(uint256 _projectId, ITerminal _to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IOperatorStore {
    event SetOperator(
        address indexed operator,
        address indexed account,
        uint256 indexed domain,
        uint256[] permissionIndexes,
        uint256 packed
    );

    function permissionsOf(
        address _operator,
        address _account,
        uint256 _domain
    ) external view returns (uint256);

    function hasPermission(
        address _operator,
        address _account,
        uint256 _domain,
        uint256 _permissionIndex
    ) external view returns (bool);

    function hasPermissions(
        address _operator,
        address _account,
        uint256 _domain,
        uint256[] calldata _permissionIndexes
    ) external view returns (bool);

    function setOperator(
        address _operator,
        uint256 _domain,
        uint256[] calldata _permissionIndexes
    ) external;

    function setOperators(
        address[] calldata _operators,
        uint256[] calldata _domains,
        uint256[][] calldata _permissionIndexes
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITickets is IERC20 {
    function print(address _account, uint256 _amount) external;

    function redeem(address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./IDirectPaymentAddress.sol";
import "./ITerminal.sol";
import "./IProjects.sol";
import "./IProjects.sol";

interface ITerminalDirectory {
    event DeployAddress(
        uint256 indexed projectId,
        string memo,
        address indexed caller
    );

    event SetTerminal(
        uint256 indexed projectId,
        ITerminal indexed terminal,
        address caller
    );

    event SetPayerPreferences(
        address indexed account,
        address beneficiary,
        bool preferUnstakedTickets
    );

    function projects() external view returns (IProjects);

    function terminalOf(uint256 _projectId) external view returns (ITerminal);

    function beneficiaryOf(address _account) external returns (address);

    function unstakedTicketsPreferenceOf(address _account)
        external
        returns (bool);

    function addressesOf(uint256 _projectId)
        external
        view
        returns (IDirectPaymentAddress[] memory);

    function deployAddress(uint256 _projectId, string calldata _memo) external;

    function setTerminal(uint256 _projectId, ITerminal _terminal) external;

    function setPayerPreferences(
        address _beneficiary,
        bool _preferUnstakedTickets
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ITerminalDirectory.sol";
import "./ITerminal.sol";

interface IDirectPaymentAddress {
    event Forward(
        address indexed payer,
        uint256 indexed projectId,
        address beneficiary,
        uint256 value,
        string memo,
        bool preferUnstakedTickets
    );

    function terminalDirectory() external returns (ITerminalDirectory);

    function projectId() external returns (uint256);

    function memo() external returns (string memory);
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
pragma solidity 0.8.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

interface IPrices {
    event AddFeed(uint256 indexed currency, AggregatorV3Interface indexed feed);

    function feedDecimalAdjuster(uint256 _currency) external returns (uint256);

    function targetDecimals() external returns (uint256);

    function feedFor(uint256 _currency)
        external
        returns (AggregatorV3Interface);

    function getETHPriceFor(uint256 _currency) external view returns (uint256);

    function addFeed(AggregatorV3Interface _priceFeed, uint256 _currency)
        external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ITerminalV1.sol";

enum BallotState {
    Approved,
    Active,
    Failed,
    Standby
}

interface IFundingCycleBallot {
    function duration() external view returns (uint256);

    function state(uint256 _fundingCycleId, uint256 _configured)
        external
        view
        returns (BallotState);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IModAllocator {
    event Allocate(
        uint256 indexed projectId,
        uint256 indexed forProjectId,
        address indexed beneficiary,
        uint256 amount,
        address caller
    );

    function allocate(
        uint256 _projectId,
        uint256 _forProjectId,
        address _beneficiary
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "@paulrberg/contracts/math/PRBMath.sol";
import "@paulrberg/contracts/math/PRBMathUD60x18.sol";

import "./interfaces/ITerminalV1.sol";
import "./abstract/JuiceboxProject.sol";
import "./abstract/Operatable.sol";

import "./libraries/Operations.sol";

/**
  ─────────────────────────────────────────────────────────────────────────────────────────────────
  ─────────██████──███████──██████──██████████──██████████████──██████████████──████████████████───
  ─────────██░░██──███░░██──██░░██──██░░░░░░██──██░░░░░░░░░░██──██░░░░░░░░░░██──██░░░░░░░░░░░░██───
  ─────────██░░██──███░░██──██░░██──████░░████──██░░██████████──██░░██████████──██░░████████░░██───
  ─────────██░░██──███░░██──██░░██────██░░██────██░░██──────────██░░██──────────██░░██────██░░██───
  ─────────██░░██──███░░██──██░░██────██░░██────██░░██──────────██░░██████████──██░░████████░░██───
  ─────────██░░██──███░░██──██░░██────██░░██────██░░██──────────██░░░░░░░░░░██──██░░░░░░░░░░░░██───
  ─██████──██░░██──███░░██──██░░██────██░░██────██░░██──────────██░░██████████──██░░██████░░████───
  ─██░░██──██░░██──███░░██──██░░██────██░░██────██░░██──────────██░░██──────────██░░██──██░░██─────
  ─██░░██████░░██──███░░██████░░██──████░░████──██░░██████████──██░░██████████──██░░██──██░░██████─
  ─██░░░░░░░░░░██──███░░░░░░░░░░██──██░░░░░░██──██░░░░░░░░░░██──██░░░░░░░░░░██──██░░██──██░░░░░░██─
  ─██████████████──███████████████──██████████──██████████████──██████████████──██████──██████████─
  ───────────────────────────────────────────────────────────────────────────────────────────

  @notice 
  This contract manages the Juicebox ecosystem, serves as a payment terminal, and custodies all funds.

  @dev 
  A project can transfer its funds, along with the power to reconfigure and mint/burn their Tickets, from this contract to another allowed terminal contract at any time.
*/
contract TerminalV1 is Operatable, ITerminalV1, ITerminal, ReentrancyGuard {
    // Modifier to only allow governance to call the function.
    modifier onlyGov() {
        require(msg.sender == governance, "TerminalV1: UNAUTHORIZED");
        _;
    }

    // --- private stored properties --- //

    // The difference between the processed ticket tracker of a project and the project's ticket's total supply is the amount of tickets that
    // still need to have reserves printed against them.
    mapping(uint256 => int256) private _processedTicketTrackerOf;

    // The amount of ticket printed prior to a project configuring their first funding cycle.
    mapping(uint256 => uint256) private _preconfigureTicketCountOf;

    // --- public immutable stored properties --- //

    /// @notice The Projects contract which mints ERC-721's that represent project ownership and transfers.
    IProjects public immutable override projects;

    /// @notice The contract storing all funding cycle configurations.
    IFundingCycles public immutable override fundingCycles;

    /// @notice The contract that manages Ticket printing and redeeming.
    ITicketBooth public immutable override ticketBooth;

    /// @notice The contract that stores mods for each project.
    IModStore public immutable override modStore;

    /// @notice The prices feeds.
    IPrices public immutable override prices;

    /// @notice The directory of terminals.
    ITerminalDirectory public immutable override terminalDirectory;

    // --- public stored properties --- //

    /// @notice The amount of ETH that each project is responsible for.
    mapping(uint256 => uint256) public override balanceOf;

    /// @notice The percent fee the Juicebox project takes from tapped amounts. Out of 200.
    uint256 public override fee = 10;

    /// @notice The governance of the contract who makes fees and can allow new TerminalV1 contracts to be migrated to by project owners.
    address payable public override governance;

    /// @notice The governance of the contract who makes fees and can allow new TerminalV1 contracts to be migrated to by project owners.
    address payable public override pendingGovernance;

    // Whether or not a particular contract is available for projects to migrate their funds and Tickets to.
    mapping(ITerminal => bool) public override migrationIsAllowed;

    // --- external views --- //

    /** 
      @notice 
      Gets the current overflowed amount for a specified project.

      @param _projectId The ID of the project to get overflow for.

      @return overflow The current overflow of funds for the project.
    */
    function currentOverflowOf(uint256 _projectId)
        external
        view
        override
        returns (uint256 overflow)
    {
        // Get a reference to the project's current funding cycle.
        FundingCycle memory _fundingCycle = fundingCycles.currentOf(_projectId);

        // There's no overflow if there's no funding cycle.
        if (_fundingCycle.id == 0) return 0;

        return _overflowFrom(_fundingCycle);
    }

    /** 
      @notice 
      Gets the amount of reserved tickets that a project has.

      @param _projectId The ID of the project to get overflow for.
      @param _reservedRate The reserved rate to use to make the calculation.

      @return amount overflow The current overflow of funds for the project.
    */
    function reservedTicketBalanceOf(uint256 _projectId, uint256 _reservedRate)
        external
        view
        override
        returns (uint256)
    {
        return
            _reservedTicketAmountFrom(
                _processedTicketTrackerOf[_projectId],
                _reservedRate,
                ticketBooth.totalSupplyOf(_projectId)
            );
    }

    // --- public views --- //

    /**
      @notice 
      The amount of tokens that can be claimed by the given address.

      @dev The _account must have at least _count tickets for the specified project.
      @dev If there is a funding cycle reconfiguration ballot open for the project, the project's current bonding curve is bypassed.

      @param _account The address to get an amount for.
      @param _projectId The ID of the project to get a claimable amount for.
      @param _count The number of Tickets that would be redeemed to get the resulting amount.

      @return amount The amount of tokens that can be claimed.
    */
    function claimableOverflowOf(
        address _account,
        uint256 _projectId,
        uint256 _count
    ) public view override returns (uint256) {
        // The holder must have the specified number of the project's tickets.
        require(
            ticketBooth.balanceOf(_account, _projectId) >= _count,
            "TerminalV1::claimableOverflow: INSUFFICIENT_TICKETS"
        );

        // Get a reference to the current funding cycle for the project.
        FundingCycle memory _fundingCycle = fundingCycles.currentOf(_projectId);

        // There's no overflow if there's no funding cycle.
        if (_fundingCycle.id == 0) return 0;

        // Get the amount of current overflow.
        uint256 _currentOverflow = _overflowFrom(_fundingCycle);

        // If there is no overflow, nothing is claimable.
        if (_currentOverflow == 0) return 0;

        // Get the total number of tickets in circulation.
        uint256 _totalSupply = ticketBooth.totalSupplyOf(_projectId);

        // Get the number of reserved tickets the project has.
        // The reserved rate is in bits 8-15 of the metadata.
        uint256 _reservedTicketAmount = _reservedTicketAmountFrom(
            _processedTicketTrackerOf[_projectId],
            uint256(uint8(_fundingCycle.metadata >> 8)),
            _totalSupply
        );

        // If there are reserved tickets, add them to the total supply.
        if (_reservedTicketAmount > 0)
            _totalSupply = _totalSupply + _reservedTicketAmount;

        // If the amount being redeemed is the the total supply, return the rest of the overflow.
        if (_count == _totalSupply) return _currentOverflow;

        // Get a reference to the linear proportion.
        uint256 _base = PRBMath.mulDiv(_currentOverflow, _count, _totalSupply);

        // Use the reconfiguration bonding curve if the queued cycle is pending approval according to the previous funding cycle's ballot.
        uint256 _bondingCurveRate = fundingCycles.currentBallotStateOf(
            _projectId
        ) == BallotState.Active // The reconfiguration bonding curve rate is stored in bytes 24-31 of the metadata property.
            ? uint256(uint8(_fundingCycle.metadata >> 24)) // The bonding curve rate is stored in bytes 16-23 of the data property after.
            : uint256(uint8(_fundingCycle.metadata >> 16));

        // The bonding curve formula.
        // https://www.desmos.com/calculator/sp9ru6zbpk
        // where x is _count, o is _currentOverflow, s is _totalSupply, and r is _bondingCurveRate.

        // These conditions are all part of the same curve. Edge conditions are separated because fewer operation are necessary.
        if (_bondingCurveRate == 200) return _base;
        if (_bondingCurveRate == 0)
            return PRBMath.mulDiv(_base, _count, _totalSupply);
        return
            PRBMath.mulDiv(
                _base,
                _bondingCurveRate +
                    PRBMath.mulDiv(
                        _count,
                        200 - _bondingCurveRate,
                        _totalSupply
                    ),
                200
            );
    }

    /**
      @notice
      Whether or not a project can still print premined tickets.

      @param _projectId The ID of the project to get the status of.

      @return Boolean flag.
    */
    function canPrintPreminedTickets(uint256 _projectId)
        public
        view
        override
        returns (bool)
    {
        return
            // The total supply of tickets must equal the preconfigured ticket count.
            ticketBooth.totalSupplyOf(_projectId) ==
            _preconfigureTicketCountOf[_projectId] &&
            // The above condition is still possible after post-configured tickets have been printed due to ticket redeeming.
            // The only case when processedTicketTracker is 0 is before redeeming and printing reserved tickets.
            _processedTicketTrackerOf[_projectId] >= 0 &&
            uint256(_processedTicketTrackerOf[_projectId]) ==
            _preconfigureTicketCountOf[_projectId];
    }

    // --- external transactions --- //

    /** 
      @param _projects A Projects contract which mints ERC-721's that represent project ownership and transfers.
      @param _fundingCycles A funding cycle configuration store.
      @param _ticketBooth A contract that manages Ticket printing and redeeming.
      @param _operatorStore A contract storing operator assignments.
      @param _modStore A storage for a project's mods.
      @param _prices A price feed contract to use.
      @param _terminalDirectory A directory of a project's current Juicebox terminal to receive payments in.
    */
    constructor(
        IProjects _projects,
        IFundingCycles _fundingCycles,
        ITicketBooth _ticketBooth,
        IOperatorStore _operatorStore,
        IModStore _modStore,
        IPrices _prices,
        ITerminalDirectory _terminalDirectory,
        address payable _governance
    ) Operatable(_operatorStore) {
        require(
            _projects != IProjects(address(0)) &&
                _fundingCycles != IFundingCycles(address(0)) &&
                _ticketBooth != ITicketBooth(address(0)) &&
                _modStore != IModStore(address(0)) &&
                _prices != IPrices(address(0)) &&
                _terminalDirectory != ITerminalDirectory(address(0)) &&
                _governance != address(address(0)),
            "TerminalV1: ZERO_ADDRESS"
        );
        projects = _projects;
        fundingCycles = _fundingCycles;
        ticketBooth = _ticketBooth;
        modStore = _modStore;
        prices = _prices;
        terminalDirectory = _terminalDirectory;
        governance = _governance;
    }

    /**
      @notice 
      Deploys a project. This will mint an ERC-721 into the `_owner`'s account, configure a first funding cycle, and set up any mods.

      @dev
      Each operation withing this transaction can be done in sequence separately.

      @dev
      Anyone can deploy a project on an owner's behalf.

      @param _owner The address that will own the project.
      @param _handle The project's unique handle.
      @param _uri A link to information about the project and this funding cycle.
      @param _properties The funding cycle configuration.
        @dev _properties.target The amount that the project wants to receive in this funding cycle. Sent as a wad.
        @dev _properties.currency The currency of the `target`. Send 0 for ETH or 1 for USD.
        @dev _properties.duration The duration of the funding stage for which the `target` amount is needed. Measured in days. Send 0 for a boundless cycle reconfigurable at any time.
        @dev _properties.cycleLimit The number of cycles that this configuration should last for before going back to the last permanent. This has no effect for a project's first funding cycle.
        @dev _properties.discountRate A number from 0-200 indicating how valuable a contribution to this funding stage is compared to the project's previous funding stage.
          If it's 200, each funding stage will have equal weight.
          If the number is 180, a contribution to the next funding stage will only give you 90% of tickets given to a contribution of the same amount during the current funding stage.
          If the number is 0, an non-recurring funding stage will get made.
        @dev _properties.ballot The new ballot that will be used to approve subsequent reconfigurations.
      @param _metadata A struct specifying the TerminalV1 specific params _bondingCurveRate, and _reservedRate.
        @dev _metadata.reservedRate A number from 0-200 indicating the percentage of each contribution's tickets that will be reserved for the project owner.
        @dev _metadata.bondingCurveRate The rate from 0-200 at which a project's Tickets can be redeemed for surplus.
          The bonding curve formula is https://www.desmos.com/calculator/sp9ru6zbpk
          where x is _count, o is _currentOverflow, s is _totalSupply, and r is _bondingCurveRate.
        @dev _metadata.reconfigurationBondingCurveRate The bonding curve rate to apply when there is an active ballot.
      @param _payoutMods Any payout mods to set.
      @param _ticketMods Any ticket mods to set.
    */
    function deploy(
        address _owner,
        bytes32 _handle,
        string calldata _uri,
        FundingCycleProperties calldata _properties,
        FundingCycleMetadata calldata _metadata,
        PayoutMod[] memory _payoutMods,
        TicketMod[] memory _ticketMods
    ) external override {
        // Make sure the metadata checks out. If it does, return a packed version of it.
        uint256 _packedMetadata = _validateAndPackFundingCycleMetadata(
            _metadata
        );

        // Create the project for the owner.
        uint256 _projectId = projects.create(_owner, _handle, _uri, this);

        // Configure the funding stage's state.
        FundingCycle memory _fundingCycle = fundingCycles.configure(
            _projectId,
            _properties,
            _packedMetadata,
            fee,
            true
        );

        // Set payout mods if there are any.
        if (_payoutMods.length > 0)
            modStore.setPayoutMods(
                _projectId,
                _fundingCycle.configured,
                _payoutMods
            );

        // Set ticket mods if there are any.
        if (_ticketMods.length > 0)
            modStore.setTicketMods(
                _projectId,
                _fundingCycle.configured,
                _ticketMods
            );
    }

    /**
      @notice 
      Configures the properties of the current funding cycle if the project hasn't distributed tickets yet, or
      sets the properties of the proposed funding cycle that will take effect once the current one expires
      if it is approved by the current funding cycle's ballot.

      @dev
      Only a project's owner or a designated operator can configure its funding cycles.

      @param _projectId The ID of the project being reconfigured. 
      @param _properties The funding cycle configuration.
        @dev _properties.target The amount that the project wants to receive in this funding stage. Sent as a wad.
        @dev _properties.currency The currency of the `target`. Send 0 for ETH or 1 for USD.
        @dev _properties.duration The duration of the funding stage for which the `target` amount is needed. Measured in days. Send 0 for a boundless cycle reconfigurable at any time.
        @dev _properties.cycleLimit The number of cycles that this configuration should last for before going back to the last permanent. This has no effect for a project's first funding cycle.
        @dev _properties.discountRate A number from 0-200 indicating how valuable a contribution to this funding stage is compared to the project's previous funding stage.
          If it's 200, each funding stage will have equal weight.
          If the number is 180, a contribution to the next funding stage will only give you 90% of tickets given to a contribution of the same amount during the current funding stage.
          If the number is 0, an non-recurring funding stage will get made.
        @dev _properties.ballot The new ballot that will be used to approve subsequent reconfigurations.
      @param _metadata A struct specifying the TerminalV1 specific params _bondingCurveRate, and _reservedRate.
        @dev _metadata.reservedRate A number from 0-200 indicating the percentage of each contribution's tickets that will be reserved for the project owner.
        @dev _metadata.bondingCurveRate The rate from 0-200 at which a project's Tickets can be redeemed for surplus.
          The bonding curve formula is https://www.desmos.com/calculator/sp9ru6zbpk
          where x is _count, o is _currentOverflow, s is _totalSupply, and r is _bondingCurveRate.
        @dev _metadata.reconfigurationBondingCurveRate The bonding curve rate to apply when there is an active ballot.

      @return The ID of the funding cycle that was successfully configured.
    */
    function configure(
        uint256 _projectId,
        FundingCycleProperties calldata _properties,
        FundingCycleMetadata calldata _metadata,
        PayoutMod[] memory _payoutMods,
        TicketMod[] memory _ticketMods
    )
        external
        override
        requirePermission(
            projects.ownerOf(_projectId),
            _projectId,
            Operations.Configure
        )
        returns (uint256)
    {
        // Make sure the metadata is validated, and pack it into a uint256.
        uint256 _packedMetadata = _validateAndPackFundingCycleMetadata(
            _metadata
        );

        // If the project can still print premined tickets configure the active funding cycle instead of creating a standby one.
        bool _shouldConfigureActive = canPrintPreminedTickets(_projectId);

        // Configure the funding stage's state.
        FundingCycle memory _fundingCycle = fundingCycles.configure(
            _projectId,
            _properties,
            _packedMetadata,
            fee,
            _shouldConfigureActive
        );

        // Set payout mods for the new configuration if there are any.
        if (_payoutMods.length > 0)
            modStore.setPayoutMods(
                _projectId,
                _fundingCycle.configured,
                _payoutMods
            );

        // Set payout mods for the new configuration if there are any.
        if (_ticketMods.length > 0)
            modStore.setTicketMods(
                _projectId,
                _fundingCycle.configured,
                _ticketMods
            );

        return _fundingCycle.id;
    }

    /** 
      @notice 
      Allows a project to print tickets for a specified beneficiary before payments have been received.

      @dev 
      This can only be done if the project hasn't yet received a payment after configuring a funding cycle.

      @dev
      Only a project's owner or a designated operator can print premined tickets.

      @param _projectId The ID of the project to premine tickets for.
      @param _amount The amount to base the ticket premine off of.
      @param _currency The currency of the amount to base the ticket premine off of. 
      @param _beneficiary The address to send the printed tickets to.
      @param _memo A memo to leave with the printing.
      @param _preferUnstakedTickets If there is a preference to unstake the printed tickets.
    */
    function printPreminedTickets(
        uint256 _projectId,
        uint256 _amount,
        uint256 _currency,
        address _beneficiary,
        string memory _memo,
        bool _preferUnstakedTickets
    )
        external
        override
        requirePermission(
            projects.ownerOf(_projectId),
            _projectId,
            Operations.PrintPreminedTickets
        )
    {
        // Can't send to the zero address.
        require(
            _beneficiary != address(0),
            "TerminalV1::printTickets: ZERO_ADDRESS"
        );

        // Get the current funding cycle to read the weight and currency from.
        uint256 _weight = fundingCycles.BASE_WEIGHT();

        // Get the current funding cycle to read the weight and currency from.
        // Get the currency price of ETH.
        uint256 _ethPrice = prices.getETHPriceFor(_currency);

        // Multiply the amount by the funding cycle's weight to determine the amount of tickets to print.
        uint256 _weightedAmount = PRBMathUD60x18.mul(
            PRBMathUD60x18.div(_amount, _ethPrice),
            _weight
        );

        // Make sure the project hasnt printed tickets that werent preconfigure.
        // Do this check after the external calls above.
        require(
            canPrintPreminedTickets(_projectId),
            "TerminalV1::printTickets: ALREADY_ACTIVE"
        );

        // Set the preconfigure tickets as processed so that reserved tickets cant be minted against them.
        // Make sure int casting isnt overflowing the int. 2^255 - 1 is the largest number that can be stored in an int.
        require(
            _processedTicketTrackerOf[_projectId] < 0 ||
                uint256(_processedTicketTrackerOf[_projectId]) +
                    uint256(_weightedAmount) <=
                uint256(type(int256).max),
            "TerminalV1::printTickets: INT_LIMIT_REACHED"
        );

        _processedTicketTrackerOf[_projectId] =
            _processedTicketTrackerOf[_projectId] +
            int256(_weightedAmount);

        // Set the count of preconfigure tickets this project has printed.
        _preconfigureTicketCountOf[_projectId] =
            _preconfigureTicketCountOf[_projectId] +
            _weightedAmount;

        // Print the project's tickets for the beneficiary.
        ticketBooth.print(
            _beneficiary,
            _projectId,
            _weightedAmount,
            _preferUnstakedTickets
        );

        emit PrintPreminedTickets(
            _projectId,
            _beneficiary,
            _amount,
            _currency,
            _memo,
            msg.sender
        );
    }

    /**
      @notice 
      Contribute ETH to a project.

      @dev 
      Print's the project's tickets proportional to the amount of the contribution.

      @dev 
      The msg.value is the amount of the contribution in wei.

      @param _projectId The ID of the project being contribute to.
      @param _beneficiary The address to print Tickets for. 
      @param _memo A memo that will be included in the published event.
      @param _preferUnstakedTickets Whether ERC20's should be unstaked automatically if they have been issued.

      @return The ID of the funding cycle that the payment was made during.
    */
    function pay(
        uint256 _projectId,
        address _beneficiary,
        string calldata _memo,
        bool _preferUnstakedTickets
    ) external payable override returns (uint256) {
        // Positive payments only.
        require(msg.value > 0, "TerminalV1::pay: BAD_AMOUNT");

        // Cant send tickets to the zero address.
        require(_beneficiary != address(0), "TerminalV1::pay: ZERO_ADDRESS");

        return
            _pay(
                _projectId,
                msg.value,
                _beneficiary,
                _memo,
                _preferUnstakedTickets
            );
    }

    /**
      @notice 
      Tap into funds that have been contributed to a project's current funding cycle.

      @dev
      Anyone can tap funds on a project's behalf.

      @param _projectId The ID of the project to which the funding cycle being tapped belongs.
      @param _amount The amount being tapped, in the funding cycle's currency.
      @param _currency The expected currency being tapped.
      @param _minReturnedWei The minimum number of wei that the amount should be valued at.

      @return The ID of the funding cycle that was tapped.
    */
    function tap(
        uint256 _projectId,
        uint256 _amount,
        uint256 _currency,
        uint256 _minReturnedWei
    ) external override nonReentrant returns (uint256) {
        // Register the funds as tapped. Get the ID of the funding cycle that was tapped.
        FundingCycle memory _fundingCycle = fundingCycles.tap(
            _projectId,
            _amount
        );

        // If there's no funding cycle, there are no funds to tap.
        if (_fundingCycle.id == 0) return 0;

        // Make sure the currency's match.
        require(
            _currency == _fundingCycle.currency,
            "TerminalV1::tap: UNEXPECTED_CURRENCY"
        );

        // Get a reference to this project's current balance, including any earned yield.
        // Get the currency price of ETH.
        uint256 _ethPrice = prices.getETHPriceFor(_fundingCycle.currency);

        // Get the price of ETH.
        // The amount of ETH that is being tapped.
        uint256 _tappedWeiAmount = PRBMathUD60x18.div(_amount, _ethPrice);

        // The amount being tapped must be at least as much as was expected.
        require(
            _minReturnedWei <= _tappedWeiAmount,
            "TerminalV1::tap: INADEQUATE"
        );

        // Get a reference to this project's current balance, including any earned yield.
        uint256 _balance = balanceOf[_fundingCycle.projectId];

        // The amount being tapped must be available.
        require(
            _tappedWeiAmount <= _balance,
            "TerminalV1::tap: INSUFFICIENT_FUNDS"
        );

        // Removed the tapped funds from the project's balance.
        balanceOf[_projectId] = _balance - _tappedWeiAmount;

        // Get a reference to the project owner, which will receive the admin's tickets from paying the fee,
        // and receive any extra tapped funds not allocated to mods.
        address payable _projectOwner = payable(
            projects.ownerOf(_fundingCycle.projectId)
        );

        // Get a reference to the handle of the project paying the fee and sending payouts.
        bytes32 _handle = projects.handleOf(_projectId);

        // Take a fee from the _tappedWeiAmount, if needed.
        // The project's owner will be the beneficiary of the resulting printed tickets from the governance project.
        uint256 _feeAmount = _fundingCycle.fee > 0
            ? _takeFee(
                _tappedWeiAmount,
                _fundingCycle.fee,
                _projectOwner,
                string(bytes.concat("Fee from @", _handle))
            )
            : 0;

        // Payout to mods and get a reference to the leftover transfer amount after all mods have been paid.
        // The net transfer amount is the tapped amount minus the fee.
        uint256 _leftoverTransferAmount = _distributeToPayoutMods(
            _fundingCycle,
            _tappedWeiAmount - _feeAmount,
            string(bytes.concat("Payout from @", _handle))
        );

        // Transfer any remaining balance to the beneficiary.
        if (_leftoverTransferAmount > 0)
            Address.sendValue(_projectOwner, _leftoverTransferAmount);

        emit Tap(
            _fundingCycle.id,
            _fundingCycle.projectId,
            _projectOwner,
            _amount,
            _fundingCycle.currency,
            _tappedWeiAmount - _feeAmount,
            _leftoverTransferAmount,
            _feeAmount,
            msg.sender
        );

        return _fundingCycle.id;
    }

    /**
      @notice 
      Addresses can redeem their Tickets to claim the project's overflowed ETH.

      @dev
      Only a ticket's holder or a designated operator can redeem it.

      @param _account The account to redeem tickets for.
      @param _projectId The ID of the project to which the Tickets being redeemed belong.
      @param _count The number of Tickets to redeem.
      @param _minReturnedWei The minimum amount of Wei expected in return.
      @param _beneficiary The address to send the ETH to.
      @param _preferUnstaked If the preference is to redeem tickets that have been converted to ERC-20s.

      @return amount The amount of ETH that the tickets were redeemed for.
    */
    function redeem(
        address _account,
        uint256 _projectId,
        uint256 _count,
        uint256 _minReturnedWei,
        address payable _beneficiary,
        bool _preferUnstaked
    )
        external
        override
        nonReentrant
        requirePermissionAllowingWildcardDomain(
            _account,
            _projectId,
            Operations.Redeem
        )
        returns (uint256 amount)
    {
        // There must be an amount specified to redeem.
        require(_count > 0, "TerminalV1::redeem: NO_OP");

        // Can't send claimed funds to the zero address.
        require(_beneficiary != address(0), "TerminalV1::redeem: ZERO_ADDRESS");

        // The amount of ETH claimable by the message sender from the specified project by redeeming the specified number of tickets.
        amount = claimableOverflowOf(_account, _projectId, _count);

        // Nothing to do if the amount is 0.
        require(amount > 0, "TerminalV1::redeem: NO_OP");

        // The amount being claimed must be at least as much as was expected.
        require(amount >= _minReturnedWei, "TerminalV1::redeem: INADEQUATE");

        // Remove the redeemed funds from the project's balance.
        balanceOf[_projectId] = balanceOf[_projectId] - amount;

        // Get a reference to the processed ticket tracker for the project.
        int256 _processedTicketTracker = _processedTicketTrackerOf[_projectId];

        // Subtract the count from the processed ticket tracker.
        // Subtract from processed tickets so that the difference between whats been processed and the
        // total supply remains the same.
        // If there are at least as many processed tickets as there are tickets being redeemed,
        // the processed ticket tracker of the project will be positive. Otherwise it will be negative.
        _processedTicketTrackerOf[_projectId] = _processedTicketTracker < 0 // If the tracker is negative, add the count and reverse it.
            ? -int256(uint256(-_processedTicketTracker) + _count) // the tracker is less than the count, subtract it from the count and reverse it.
            : _processedTicketTracker < int256(_count)
            ? -(int256(_count) - _processedTicketTracker) // simply subtract otherwise.
            : _processedTicketTracker - int256(_count);

        // Redeem the tickets, which burns them.
        ticketBooth.redeem(_account, _projectId, _count, _preferUnstaked);

        // Transfer funds to the specified address.
        Address.sendValue(_beneficiary, amount);

        emit Redeem(
            _account,
            _beneficiary,
            _projectId,
            _count,
            amount,
            msg.sender
        );
    }

    /**
      @notice 
      Allows a project owner to migrate its funds and operations to a new contract.

      @dev
      Only a project's owner or a designated operator can migrate it.

      @param _projectId The ID of the project being migrated.
      @param _to The contract that will gain the project's funds.
    */
    function migrate(uint256 _projectId, ITerminal _to)
        external
        override
        requirePermission(
            projects.ownerOf(_projectId),
            _projectId,
            Operations.Migrate
        )
        nonReentrant
    {
        // This TerminalV1 must be the project's current terminal.
        require(
            terminalDirectory.terminalOf(_projectId) == this,
            "TerminalV1::migrate: UNAUTHORIZED"
        );

        // The migration destination must be allowed.
        require(migrationIsAllowed[_to], "TerminalV1::migrate: NOT_ALLOWED");

        // All reserved tickets must be printed before migrating.
        if (
            uint256(_processedTicketTrackerOf[_projectId]) !=
            ticketBooth.totalSupplyOf(_projectId)
        ) printReservedTickets(_projectId);

        // Get a reference to this project's current balance, included any earned yield.
        uint256 _balanceOf = balanceOf[_projectId];

        // Set the balance to 0.
        balanceOf[_projectId] = 0;

        // Move the funds to the new contract if needed.
        if (_balanceOf > 0) _to.addToBalance{value: _balanceOf}(_projectId);

        // Switch the direct payment terminal.
        terminalDirectory.setTerminal(_projectId, _to);

        emit Migrate(_projectId, _to, _balanceOf, msg.sender);
    }

    /** 
      @notice 
      Receives and allocates funds belonging to the specified project.

      @param _projectId The ID of the project to which the funds received belong.
    */
    function addToBalance(uint256 _projectId) external payable override {
        // The amount must be positive.
        require(msg.value > 0, "TerminalV1::addToBalance: BAD_AMOUNT");
        balanceOf[_projectId] = balanceOf[_projectId] + msg.value;
        emit AddToBalance(_projectId, msg.value, msg.sender);
    }

    /**
      @notice 
      Adds to the contract addresses that projects can migrate their Tickets to.

      @dev
      Only governance can add a contract to the migration allow list.

      @param _contract The contract to allow.
    */
    function allowMigration(ITerminal _contract) external override onlyGov {
        // Can't allow the zero address.
        require(
            _contract != ITerminal(address(0)),
            "TerminalV1::allowMigration: ZERO_ADDRESS"
        );

        // Can't migrate to this same contract
        require(_contract != this, "TerminalV1::allowMigration: NO_OP");

        // Set the contract as allowed
        migrationIsAllowed[_contract] = true;

        emit AllowMigration(_contract);
    }

    /** 
      @notice 
      Allow the admin to change the fee. 

      @dev
      Only funding cycle reconfigurations after the new fee is set will use the new fee.
      All future funding cycles based on configurations made in the past will use the fee that was set at the time of the configuration.
    
      @dev
      Only governance can set a new fee.

      @param _fee The new fee percent. Out of 200.
    */
    function setFee(uint256 _fee) external override onlyGov {
        // Fee must be under 100%.
        require(_fee <= 200, "TerminalV1::setFee: BAD_FEE");

        // Set the fee.
        fee = _fee;

        emit SetFee(_fee);
    }

    /** 
      @notice 
      Allows governance to transfer its privileges to another contract.

      @dev
      Only the currency governance can appoint a new governance.

      @param _pendingGovernance The governance to transition power to. 
        @dev This address will have to accept the responsibility in a subsequent transaction.
    */
    function appointGovernance(address payable _pendingGovernance)
        external
        override
        onlyGov
    {
        // The new governance can't be the zero address.
        require(
            _pendingGovernance != address(0),
            "TerminalV1::appointGovernance: ZERO_ADDRESS"
        );
        // The new governance can't be the same as the current governance.
        require(
            _pendingGovernance != governance,
            "TerminalV1::appointGovernance: NO_OP"
        );

        // Set the appointed governance as pending.
        pendingGovernance = _pendingGovernance;

        emit AppointGovernance(_pendingGovernance);
    }

    /** 
      @notice 
      Allows contract to accept its appointment as the new governance.
    */
    function acceptGovernance() external override {
        // Only the pending governance address can accept.
        require(
            msg.sender == pendingGovernance,
            "TerminalV1::acceptGovernance: UNAUTHORIZED"
        );

        // Get a reference to the pending governance.
        address payable _pendingGovernance = pendingGovernance;

        // Set the govenance to the pending value.
        governance = _pendingGovernance;

        emit AcceptGovernance(_pendingGovernance);
    }

    // --- public transactions --- //

    /**
      @notice 
      Prints all reserved tickets for a project.

      @param _projectId The ID of the project to which the reserved tickets belong.

      @return amount The amount of tickets that are being printed.
    */
    function printReservedTickets(uint256 _projectId)
        public
        override
        returns (uint256 amount)
    {
        // Get the current funding cycle to read the reserved rate from.
        FundingCycle memory _fundingCycle = fundingCycles.currentOf(_projectId);

        // If there's no funding cycle, there's no reserved tickets to print.
        if (_fundingCycle.id == 0) return 0;

        // Get a reference to new total supply of tickets before printing reserved tickets.
        uint256 _totalTickets = ticketBooth.totalSupplyOf(_projectId);

        // Get a reference to the number of tickets that need to be printed.
        // If there's no funding cycle, there's no tickets to print.
        // The reserved rate is in bits 8-15 of the metadata.
        amount = _reservedTicketAmountFrom(
            _processedTicketTrackerOf[_projectId],
            uint256(uint8(_fundingCycle.metadata >> 8)),
            _totalTickets
        );

        // If there's nothing to print, return.
        if (amount == 0) return amount;

        // Make sure int casting isnt overflowing the int. 2^255 - 1 is the largest number that can be stored in an int.
        require(
            _totalTickets + amount <= uint256(type(int256).max),
            "TerminalV1::printReservedTickets: INT_LIMIT_REACHED"
        );

        // Set the tracker to be the new total supply.
        _processedTicketTrackerOf[_projectId] = int256(_totalTickets + amount);

        // Distribute tickets to mods and get a reference to the leftover amount to print after all mods have had their share printed.
        uint256 _leftoverTicketAmount = _distributeToTicketMods(
            _fundingCycle,
            amount
        );

        // Get a reference to the project owner.
        address _owner = projects.ownerOf(_projectId);

        // Print any remaining reserved tickets to the owner.
        if (_leftoverTicketAmount > 0)
            ticketBooth.print(_owner, _projectId, _leftoverTicketAmount, false);

        emit PrintReserveTickets(
            _fundingCycle.id,
            _projectId,
            _owner,
            amount,
            _leftoverTicketAmount,
            msg.sender
        );
    }

    // --- private helper functions --- //

    /** 
      @notice
      Pays out the mods for the specified funding cycle.

      @param _fundingCycle The funding cycle to base the distribution on.
      @param _amount The total amount being paid out.
      @param _memo A memo to send along with project payouts.

      @return leftoverAmount If the mod percents dont add up to 100%, the leftover amount is returned.

    */
    function _distributeToPayoutMods(
        FundingCycle memory _fundingCycle,
        uint256 _amount,
        string memory _memo
    ) private returns (uint256 leftoverAmount) {
        // Set the leftover amount to the initial amount.
        leftoverAmount = _amount;

        // Get a reference to the project's payout mods.
        PayoutMod[] memory _mods = modStore.payoutModsOf(
            _fundingCycle.projectId,
            _fundingCycle.configured
        );

        if (_mods.length == 0) return leftoverAmount;

        //Transfer between all mods.
        for (uint256 _i = 0; _i < _mods.length; _i++) {
            // Get a reference to the mod being iterated on.
            PayoutMod memory _mod = _mods[_i];

            // The amount to send towards mods. Mods percents are out of 10000.
            uint256 _modCut = PRBMath.mulDiv(_amount, _mod.percent, 10000);

            if (_modCut > 0) {
                // Transfer ETH to the mod.
                // If there's an allocator set, transfer to its `allocate` function.
                if (_mod.allocator != IModAllocator(address(0))) {
                    _mod.allocator.allocate{value: _modCut}(
                        _fundingCycle.projectId,
                        _mod.projectId,
                        _mod.beneficiary
                    );
                } else if (_mod.projectId != 0) {
                    // Otherwise, if a project is specified, make a payment to it.

                    // Get a reference to the Juicebox terminal being used.
                    ITerminal _terminal = terminalDirectory.terminalOf(
                        _mod.projectId
                    );

                    // The project must have a terminal to send funds to.
                    require(
                        _terminal != ITerminal(address(0)),
                        "TerminalV1::tap: BAD_MOD"
                    );

                    // Save gas if this contract is being used as the terminal.
                    if (_terminal == this) {
                        _pay(
                            _mod.projectId,
                            _modCut,
                            _mod.beneficiary,
                            _memo,
                            _mod.preferUnstaked
                        );
                    } else {
                        _terminal.pay{value: _modCut}(
                            _mod.projectId,
                            _mod.beneficiary,
                            _memo,
                            _mod.preferUnstaked
                        );
                    }
                } else {
                    // Otherwise, send the funds directly to the beneficiary.
                    Address.sendValue(_mod.beneficiary, _modCut);
                }
            }

            // Subtract from the amount to be sent to the beneficiary.
            leftoverAmount = leftoverAmount - _modCut;

            emit DistributeToPayoutMod(
                _fundingCycle.id,
                _fundingCycle.projectId,
                _mod,
                _modCut,
                msg.sender
            );
        }
    }

    /** 
      @notice
      distributed tickets to the mods for the specified funding cycle.

      @param _fundingCycle The funding cycle to base the ticket distribution on.
      @param _amount The total amount of tickets to print.

      @return leftoverAmount If the mod percents dont add up to 100%, the leftover amount is returned.

    */
    function _distributeToTicketMods(
        FundingCycle memory _fundingCycle,
        uint256 _amount
    ) private returns (uint256 leftoverAmount) {
        // Set the leftover amount to the initial amount.
        leftoverAmount = _amount;

        // Get a reference to the project's ticket mods.
        TicketMod[] memory _mods = modStore.ticketModsOf(
            _fundingCycle.projectId,
            _fundingCycle.configured
        );

        //Transfer between all mods.
        for (uint256 _i = 0; _i < _mods.length; _i++) {
            // Get a reference to the mod being iterated on.
            TicketMod memory _mod = _mods[_i];

            // The amount to send towards mods. Mods percents are out of 10000.
            uint256 _modCut = PRBMath.mulDiv(_amount, _mod.percent, 10000);

            // Print tickets for the mod if needed.
            if (_modCut > 0)
                ticketBooth.print(
                    _mod.beneficiary,
                    _fundingCycle.projectId,
                    _modCut,
                    _mod.preferUnstaked
                );

            // Subtract from the amount to be sent to the beneficiary.
            leftoverAmount = leftoverAmount - _modCut;

            emit DistributeToTicketMod(
                _fundingCycle.id,
                _fundingCycle.projectId,
                _mod,
                _modCut,
                msg.sender
            );
        }
    }

    /** 
      @notice 
      See the documentation for 'pay'.
    */
    function _pay(
        uint256 _projectId,
        uint256 _amount,
        address _beneficiary,
        string memory _memo,
        bool _preferUnstakedTickets
    ) private returns (uint256) {
        // Get a reference to the current funding cycle for the project.
        FundingCycle memory _fundingCycle = fundingCycles.currentOf(_projectId);

        // Use the funding cycle's weight if it exists. Otherwise use the base weight.
        uint256 _weight = _fundingCycle.number == 0
            ? fundingCycles.BASE_WEIGHT()
            : _fundingCycle.weight;

        // Multiply the amount by the funding cycle's weight to determine the amount of tickets to print.
        uint256 _weightedAmount = PRBMathUD60x18.mul(_amount, _weight);

        // Use the funding cycle's reserved rate if it exists. Otherwise don't set a reserved rate.
        // The reserved rate is stored in bytes 8-15 of the metadata property.
        uint256 _reservedRate = _fundingCycle.number == 0
            ? 0
            : uint256(uint8(_fundingCycle.metadata >> 8));

        // Only print the tickets that are unreserved.
        uint256 _unreservedWeightedAmount = PRBMath.mulDiv(
            _weightedAmount,
            200 - _reservedRate,
            200
        );

        // Add to the balance of the project.
        balanceOf[_projectId] = balanceOf[_projectId] + _amount;

        // If theres an unreserved weighted amount, print tickets representing this amount for the beneficiary.
        if (_unreservedWeightedAmount > 0) {
            // If there's no funding cycle, track this payment as having been made before a configuration.
            if (_fundingCycle.number == 0) {
                // Mark the premined tickets as processed so that reserved tickets can't later be printed against them.
                // Make sure int casting isnt overflowing the int. 2^255 - 1 is the largest number that can be stored in an int.
                require(
                    _processedTicketTrackerOf[_projectId] < 0 ||
                        uint256(_processedTicketTrackerOf[_projectId]) +
                            uint256(_weightedAmount) <=
                        uint256(type(int256).max),
                    "TerminalV1::printTickets: INT_LIMIT_REACHED"
                );
                _processedTicketTrackerOf[_projectId] =
                    _processedTicketTrackerOf[_projectId] +
                    int256(_unreservedWeightedAmount);

                // If theres no funding cycle, add these tickets to the amount that were printed before a funding cycle was configured.
                _preconfigureTicketCountOf[_projectId] =
                    _preconfigureTicketCountOf[_projectId] +
                    _unreservedWeightedAmount;
            }

            // Print the project's tickets for the beneficiary.
            ticketBooth.print(
                _beneficiary,
                _projectId,
                _unreservedWeightedAmount,
                _preferUnstakedTickets
            );
        } else if (_weightedAmount > 0) {
            // If there is no unreserved weight amount but there is a weighted amount,
            // the full weighted amount should be explicitly tracked as reserved since no unreserved tickets were printed.

            // Subtract the total weighted amount from the tracker so the full reserved ticket amount can be printed later.
            // Make sure int casting isnt overflowing the int. 2^255 - 1 is the largest number that can be stored in an int.
            require(
                _processedTicketTrackerOf[_projectId] > 0 ||
                    uint256(-_processedTicketTrackerOf[_projectId]) +
                        uint256(_weightedAmount) <=
                    uint256(type(int256).max),
                "TerminalV1::printTickets: INT_LIMIT_REACHED"
            );
            _processedTicketTrackerOf[_projectId] =
                _processedTicketTrackerOf[_projectId] -
                int256(_weightedAmount);
        }

        emit Pay(
            _fundingCycle.id,
            _projectId,
            _beneficiary,
            _amount,
            _memo,
            msg.sender
        );

        return _fundingCycle.id;
    }

    /** 
      @notice 
      Gets the amount overflowed in relation to the provided funding cycle.

      @dev
      This amount changes as the price of ETH changes against the funding cycle's currency.

      @param _currentFundingCycle The ID of the funding cycle to base the overflow on.

      @return overflow The current overflow of funds.
    */
    function _overflowFrom(FundingCycle memory _currentFundingCycle)
        private
        view
        returns (uint256)
    {
        // Get the current price of ETH.
        uint256 _ethPrice = prices.getETHPriceFor(
            _currentFundingCycle.currency
        );

        // Get a reference to the amount still tappable in the current funding cycle.
        uint256 _limit = _currentFundingCycle.target -
            _currentFundingCycle.tapped;

        // The amount of ETH that the owner could currently still tap if its available. This amount isn't considered overflow.
        uint256 _ethLimit = _limit == 0
            ? 0
            : PRBMathUD60x18.div(_limit, _ethPrice);

        // Get the current balance of the project.
        uint256 _balanceOf = balanceOf[_currentFundingCycle.projectId];

        // Overflow is the balance of this project minus the reserved amount.
        return _balanceOf < _ethLimit ? 0 : _balanceOf - _ethLimit;
    }

    /** 
      @notice 
      Gets the amount of reserved tickets currently tracked for a project given a reserved rate.

      @param _processedTicketTracker The tracker to make the calculation with.
      @param _reservedRate The reserved rate to use to make the calculation.
      @param _totalEligibleTickets The total amount to make the calculation with.

      @return amount reserved ticket amount.
    */
    function _reservedTicketAmountFrom(
        int256 _processedTicketTracker,
        uint256 _reservedRate,
        uint256 _totalEligibleTickets
    ) private pure returns (uint256) {
        // Get a reference to the amount of tickets that are unprocessed.
        uint256 _unprocessedTicketBalanceOf = _processedTicketTracker >= 0 // preconfigure tickets shouldn't contribute to the reserved ticket amount.
            ? _totalEligibleTickets - uint256(_processedTicketTracker)
            : _totalEligibleTickets + uint256(-_processedTicketTracker);

        // If there are no unprocessed tickets, return.
        if (_unprocessedTicketBalanceOf == 0) return 0;

        // If all tickets are reserved, return the full unprocessed amount.
        if (_reservedRate == 200) return _unprocessedTicketBalanceOf;

        return
            PRBMath.mulDiv(
                _unprocessedTicketBalanceOf,
                200,
                200 - _reservedRate
            ) - _unprocessedTicketBalanceOf;
    }

    /**
      @notice 
      Validate and pack the funding cycle metadata.

      @param _metadata The metadata to validate and pack.

      @return packed The packed uint256 of all metadata params. The first 8 bytes specify the version.
     */
    function _validateAndPackFundingCycleMetadata(
        FundingCycleMetadata memory _metadata
    ) private pure returns (uint256 packed) {
        // The reserved project ticket rate must be less than or equal to 200.
        require(
            _metadata.reservedRate <= 200,
            "TerminalV1::_validateAndPackFundingCycleMetadata: BAD_RESERVED_RATE"
        );

        // The bonding curve rate must be between 0 and 200.
        require(
            _metadata.bondingCurveRate <= 200,
            "TerminalV1::_validateAndPackFundingCycleMetadata: BAD_BONDING_CURVE_RATE"
        );

        // The reconfiguration bonding curve rate must be less than or equal to 200.
        require(
            _metadata.reconfigurationBondingCurveRate <= 200,
            "TerminalV1::_validateAndPackFundingCycleMetadata: BAD_RECONFIGURATION_BONDING_CURVE_RATE"
        );

        // version 0 in the first 8 bytes.
        packed = 0;
        // reserved rate in bytes 8-15.
        packed |= _metadata.reservedRate << 8;
        // bonding curve in bytes 16-23.
        packed |= _metadata.bondingCurveRate << 16;
        // reconfiguration bonding curve rate in bytes 24-31.
        packed |= _metadata.reconfigurationBondingCurveRate << 24;
    }

    /** 
      @notice 
      Takes a fee into the Governance contract's project.

      @param _from The amount to take a fee from.
      @param _percent The percent fee to take. Out of 200.
      @param _beneficiary The address to print governance's tickets for.
      @param _memo A memo to send with the fee.

      @return feeAmount The amount of the fee taken.
    */
    function _takeFee(
        uint256 _from,
        uint256 _percent,
        address _beneficiary,
        string memory _memo
    ) private returns (uint256 feeAmount) {
        // The amount of ETH from the _tappedAmount to pay as a fee.
        feeAmount = _from - PRBMath.mulDiv(_from, 200, _percent + 200);

        // Nothing to do if there's no fee to take.
        if (feeAmount == 0) return 0;

        // When processing the admin fee, save gas if the admin is using this contract as its terminal.
        if (
            terminalDirectory.terminalOf(
                JuiceboxProject(governance).projectId()
            ) == this
        ) {
            // Use the local pay call.
            _pay(
                JuiceboxProject(governance).projectId(),
                feeAmount,
                _beneficiary,
                _memo,
                false
            );
        } else {
            // Use the external pay call of the governance contract.
            JuiceboxProject(governance).pay{value: feeAmount}(
                _beneficiary,
                _memo,
                false
            );
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "prb-math/contracts/PRBMath.sol";

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "prb-math/contracts/PRBMathUD60x18.sol";

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./../interfaces/IOperatable.sol";

abstract contract Operatable is IOperatable {
    modifier requirePermission(
        address _account,
        uint256 _domain,
        uint256 _index
    ) {
        require(
            msg.sender == _account ||
                operatorStore.hasPermission(
                    msg.sender,
                    _account,
                    _domain,
                    _index
                ),
            "Operatable: UNAUTHORIZED"
        );
        _;
    }

    modifier requirePermissionAllowingWildcardDomain(
        address _account,
        uint256 _domain,
        uint256 _index
    ) {
        require(
            msg.sender == _account ||
                operatorStore.hasPermission(
                    msg.sender,
                    _account,
                    _domain,
                    _index
                ) ||
                operatorStore.hasPermission(msg.sender, _account, 0, _index),
            "Operatable: UNAUTHORIZED"
        );
        _;
    }

    modifier requirePermissionAcceptingAlternateAddress(
        address _account,
        uint256 _domain,
        uint256 _index,
        address _alternate
    ) {
        require(
            msg.sender == _account ||
                operatorStore.hasPermission(
                    msg.sender,
                    _account,
                    _domain,
                    _index
                ) ||
                msg.sender == _alternate,
            "Operatable: UNAUTHORIZED"
        );
        _;
    }

    /// @notice A contract storing operator assignments.
    IOperatorStore public immutable override operatorStore;

    /** 
      @param _operatorStore A contract storing operator assignments.
    */
    constructor(IOperatorStore _operatorStore) {
        operatorStore = _operatorStore;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

library Operations {
    uint256 public constant Configure = 1;
    uint256 public constant PrintPreminedTickets = 2;
    uint256 public constant Redeem = 3;
    uint256 public constant Migrate = 4;
    uint256 public constant SetHandle = 5;
    uint256 public constant SetUri = 6;
    uint256 public constant ClaimHandle = 7;
    uint256 public constant RenewHandle = 8;
    uint256 public constant Issue = 9;
    uint256 public constant Stake = 10;
    uint256 public constant Unstake = 11;
    uint256 public constant Transfer = 12;
    uint256 public constant Lock = 13;
    uint256 public constant SetPayoutMods = 14;
    uint256 public constant SetTicketMods = 15;
    uint256 public constant SetTerminal = 16;
}

// SPDX-License-Identifier: WTFPL
pragma solidity >=0.8.4;

/// @notice Emitted when the result overflows uint256.
error PRBMath__MulDivFixedPointOverflow(uint256 prod1);

/// @notice Emitted when the result overflows uint256.
error PRBMath__MulDivOverflow(uint256 prod1, uint256 denominator);

/// @notice Emitted when one of the inputs is type(int256).min.
error PRBMath__MulDivSignedInputTooSmall();

/// @notice Emitted when the intermediary absolute result overflows int256.
error PRBMath__MulDivSignedOverflow(uint256 rAbs);

/// @notice Emitted when the input is MIN_SD59x18.
error PRBMathSD59x18__AbsInputTooSmall();

/// @notice Emitted when ceiling a number overflows SD59x18.
error PRBMathSD59x18__CeilOverflow(int256 x);

/// @notice Emitted when one of the inputs is MIN_SD59x18.
error PRBMathSD59x18__DivInputTooSmall();

/// @notice Emitted when one of the intermediary unsigned results overflows SD59x18.
error PRBMathSD59x18__DivOverflow(uint256 rAbs);

/// @notice Emitted when the input is greater than 133.084258667509499441.
error PRBMathSD59x18__ExpInputTooBig(int256 x);

/// @notice Emitted when the input is greater than 192.
error PRBMathSD59x18__Exp2InputTooBig(int256 x);

/// @notice Emitted when flooring a number underflows SD59x18.
error PRBMathSD59x18__FloorUnderflow(int256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format overflows SD59x18.
error PRBMathSD59x18__FromIntOverflow(int256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format underflows SD59x18.
error PRBMathSD59x18__FromIntUnderflow(int256 x);

/// @notice Emitted when the product of the inputs is negative.
error PRBMathSD59x18__GmNegativeProduct(int256 x, int256 y);

/// @notice Emitted when multiplying the inputs overflows SD59x18.
error PRBMathSD59x18__GmOverflow(int256 x, int256 y);

/// @notice Emitted when the input is less than or equal to zero.
error PRBMathSD59x18__LogInputTooSmall(int256 x);

/// @notice Emitted when one of the inputs is MIN_SD59x18.
error PRBMathSD59x18__MulInputTooSmall();

/// @notice Emitted when the intermediary absolute result overflows SD59x18.
error PRBMathSD59x18__MulOverflow(uint256 rAbs);

/// @notice Emitted when the intermediary absolute result overflows SD59x18.
error PRBMathSD59x18__PowuOverflow(uint256 rAbs);

/// @notice Emitted when the input is negative.
error PRBMathSD59x18__SqrtNegativeInput(int256 x);

/// @notice Emitted when the calculting the square root overflows SD59x18.
error PRBMathSD59x18__SqrtOverflow(int256 x);

/// @notice Emitted when addition overflows UD60x18.
error PRBMathUD60x18__AddOverflow(uint256 x, uint256 y);

/// @notice Emitted when ceiling a number overflows UD60x18.
error PRBMathUD60x18__CeilOverflow(uint256 x);

/// @notice Emitted when the input is greater than 133.084258667509499441.
error PRBMathUD60x18__ExpInputTooBig(uint256 x);

/// @notice Emitted when the input is greater than 192.
error PRBMathUD60x18__Exp2InputTooBig(uint256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format format overflows UD60x18.
error PRBMathUD60x18__FromUintOverflow(uint256 x);

/// @notice Emitted when multiplying the inputs overflows UD60x18.
error PRBMathUD60x18__GmOverflow(uint256 x, uint256 y);

/// @notice Emitted when the input is less than 1.
error PRBMathUD60x18__LogInputTooSmall(uint256 x);

/// @notice Emitted when the calculting the square root overflows UD60x18.
error PRBMathUD60x18__SqrtOverflow(uint256 x);

/// @notice Emitted when subtraction underflows UD60x18.
error PRBMathUD60x18__SubUnderflow(uint256 x, uint256 y);

/// @dev Common mathematical functions used in both PRBMathSD59x18 and PRBMathUD60x18. Note that this shared library
/// does not always assume the signed 59.18-decimal fixed-point or the unsigned 60.18-decimal fixed-point
/// representation. When it does not, it is explictly mentioned in the NatSpec documentation.
library PRBMath {
    /// STRUCTS ///

    struct SD59x18 {
        int256 value;
    }

    struct UD60x18 {
        uint256 value;
    }

    /// STORAGE ///

    /// @dev How many trailing decimals can be represented.
    uint256 internal constant SCALE = 1e18;

    /// @dev Largest power of two divisor of SCALE.
    uint256 internal constant SCALE_LPOTD = 262144;

    /// @dev SCALE inverted mod 2^256.
    uint256 internal constant SCALE_INVERSE = 78156646155174841979727994598816262306175212592076161876661508869554232690281;

    /// FUNCTIONS ///

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    /// @dev Has to use 192.64-bit fixed-point numbers.
    /// See https://ethereum.stackexchange.com/a/96594/24693.
    /// @param x The exponent as an unsigned 192.64-bit fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp2(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            // Start from 0.5 in the 192.64-bit fixed-point format.
            result = 0x800000000000000000000000000000000000000000000000;

            // Multiply the result by root(2, 2^-i) when the bit at position i is 1. None of the intermediary results overflows
            // because the initial result is 2^191 and all magic factors are less than 2^65.
            if (x & 0x8000000000000000 > 0) {
                result = (result * 0x16A09E667F3BCC909) >> 64;
            }
            if (x & 0x4000000000000000 > 0) {
                result = (result * 0x1306FE0A31B7152DF) >> 64;
            }
            if (x & 0x2000000000000000 > 0) {
                result = (result * 0x1172B83C7D517ADCE) >> 64;
            }
            if (x & 0x1000000000000000 > 0) {
                result = (result * 0x10B5586CF9890F62A) >> 64;
            }
            if (x & 0x800000000000000 > 0) {
                result = (result * 0x1059B0D31585743AE) >> 64;
            }
            if (x & 0x400000000000000 > 0) {
                result = (result * 0x102C9A3E778060EE7) >> 64;
            }
            if (x & 0x200000000000000 > 0) {
                result = (result * 0x10163DA9FB33356D8) >> 64;
            }
            if (x & 0x100000000000000 > 0) {
                result = (result * 0x100B1AFA5ABCBED61) >> 64;
            }
            if (x & 0x80000000000000 > 0) {
                result = (result * 0x10058C86DA1C09EA2) >> 64;
            }
            if (x & 0x40000000000000 > 0) {
                result = (result * 0x1002C605E2E8CEC50) >> 64;
            }
            if (x & 0x20000000000000 > 0) {
                result = (result * 0x100162F3904051FA1) >> 64;
            }
            if (x & 0x10000000000000 > 0) {
                result = (result * 0x1000B175EFFDC76BA) >> 64;
            }
            if (x & 0x8000000000000 > 0) {
                result = (result * 0x100058BA01FB9F96D) >> 64;
            }
            if (x & 0x4000000000000 > 0) {
                result = (result * 0x10002C5CC37DA9492) >> 64;
            }
            if (x & 0x2000000000000 > 0) {
                result = (result * 0x1000162E525EE0547) >> 64;
            }
            if (x & 0x1000000000000 > 0) {
                result = (result * 0x10000B17255775C04) >> 64;
            }
            if (x & 0x800000000000 > 0) {
                result = (result * 0x1000058B91B5BC9AE) >> 64;
            }
            if (x & 0x400000000000 > 0) {
                result = (result * 0x100002C5C89D5EC6D) >> 64;
            }
            if (x & 0x200000000000 > 0) {
                result = (result * 0x10000162E43F4F831) >> 64;
            }
            if (x & 0x100000000000 > 0) {
                result = (result * 0x100000B1721BCFC9A) >> 64;
            }
            if (x & 0x80000000000 > 0) {
                result = (result * 0x10000058B90CF1E6E) >> 64;
            }
            if (x & 0x40000000000 > 0) {
                result = (result * 0x1000002C5C863B73F) >> 64;
            }
            if (x & 0x20000000000 > 0) {
                result = (result * 0x100000162E430E5A2) >> 64;
            }
            if (x & 0x10000000000 > 0) {
                result = (result * 0x1000000B172183551) >> 64;
            }
            if (x & 0x8000000000 > 0) {
                result = (result * 0x100000058B90C0B49) >> 64;
            }
            if (x & 0x4000000000 > 0) {
                result = (result * 0x10000002C5C8601CC) >> 64;
            }
            if (x & 0x2000000000 > 0) {
                result = (result * 0x1000000162E42FFF0) >> 64;
            }
            if (x & 0x1000000000 > 0) {
                result = (result * 0x10000000B17217FBB) >> 64;
            }
            if (x & 0x800000000 > 0) {
                result = (result * 0x1000000058B90BFCE) >> 64;
            }
            if (x & 0x400000000 > 0) {
                result = (result * 0x100000002C5C85FE3) >> 64;
            }
            if (x & 0x200000000 > 0) {
                result = (result * 0x10000000162E42FF1) >> 64;
            }
            if (x & 0x100000000 > 0) {
                result = (result * 0x100000000B17217F8) >> 64;
            }
            if (x & 0x80000000 > 0) {
                result = (result * 0x10000000058B90BFC) >> 64;
            }
            if (x & 0x40000000 > 0) {
                result = (result * 0x1000000002C5C85FE) >> 64;
            }
            if (x & 0x20000000 > 0) {
                result = (result * 0x100000000162E42FF) >> 64;
            }
            if (x & 0x10000000 > 0) {
                result = (result * 0x1000000000B17217F) >> 64;
            }
            if (x & 0x8000000 > 0) {
                result = (result * 0x100000000058B90C0) >> 64;
            }
            if (x & 0x4000000 > 0) {
                result = (result * 0x10000000002C5C860) >> 64;
            }
            if (x & 0x2000000 > 0) {
                result = (result * 0x1000000000162E430) >> 64;
            }
            if (x & 0x1000000 > 0) {
                result = (result * 0x10000000000B17218) >> 64;
            }
            if (x & 0x800000 > 0) {
                result = (result * 0x1000000000058B90C) >> 64;
            }
            if (x & 0x400000 > 0) {
                result = (result * 0x100000000002C5C86) >> 64;
            }
            if (x & 0x200000 > 0) {
                result = (result * 0x10000000000162E43) >> 64;
            }
            if (x & 0x100000 > 0) {
                result = (result * 0x100000000000B1721) >> 64;
            }
            if (x & 0x80000 > 0) {
                result = (result * 0x10000000000058B91) >> 64;
            }
            if (x & 0x40000 > 0) {
                result = (result * 0x1000000000002C5C8) >> 64;
            }
            if (x & 0x20000 > 0) {
                result = (result * 0x100000000000162E4) >> 64;
            }
            if (x & 0x10000 > 0) {
                result = (result * 0x1000000000000B172) >> 64;
            }
            if (x & 0x8000 > 0) {
                result = (result * 0x100000000000058B9) >> 64;
            }
            if (x & 0x4000 > 0) {
                result = (result * 0x10000000000002C5D) >> 64;
            }
            if (x & 0x2000 > 0) {
                result = (result * 0x1000000000000162E) >> 64;
            }
            if (x & 0x1000 > 0) {
                result = (result * 0x10000000000000B17) >> 64;
            }
            if (x & 0x800 > 0) {
                result = (result * 0x1000000000000058C) >> 64;
            }
            if (x & 0x400 > 0) {
                result = (result * 0x100000000000002C6) >> 64;
            }
            if (x & 0x200 > 0) {
                result = (result * 0x10000000000000163) >> 64;
            }
            if (x & 0x100 > 0) {
                result = (result * 0x100000000000000B1) >> 64;
            }
            if (x & 0x80 > 0) {
                result = (result * 0x10000000000000059) >> 64;
            }
            if (x & 0x40 > 0) {
                result = (result * 0x1000000000000002C) >> 64;
            }
            if (x & 0x20 > 0) {
                result = (result * 0x10000000000000016) >> 64;
            }
            if (x & 0x10 > 0) {
                result = (result * 0x1000000000000000B) >> 64;
            }
            if (x & 0x8 > 0) {
                result = (result * 0x10000000000000006) >> 64;
            }
            if (x & 0x4 > 0) {
                result = (result * 0x10000000000000003) >> 64;
            }
            if (x & 0x2 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }
            if (x & 0x1 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }

            // We're doing two things at the same time:
            //
            //   1. Multiply the result by 2^n + 1, where "2^n" is the integer part and the one is added to account for
            //      the fact that we initially set the result to 0.5. This is accomplished by subtracting from 191
            //      rather than 192.
            //   2. Convert the result to the unsigned 60.18-decimal fixed-point format.
            //
            // This works because 2^(191-ip) = 2^ip / 2^191, where "ip" is the integer part "2^n".
            result *= SCALE;
            result >>= (191 - (x >> 64));
        }
    }

    /// @notice Finds the zero-based index of the first one in the binary representation of x.
    /// @dev See the note on msb in the "Find First Set" Wikipedia article https://en.wikipedia.org/wiki/Find_first_set
    /// @param x The uint256 number for which to find the index of the most significant bit.
    /// @return msb The index of the most significant bit as an uint256.
    function mostSignificantBit(uint256 x) internal pure returns (uint256 msb) {
        if (x >= 2**128) {
            x >>= 128;
            msb += 128;
        }
        if (x >= 2**64) {
            x >>= 64;
            msb += 64;
        }
        if (x >= 2**32) {
            x >>= 32;
            msb += 32;
        }
        if (x >= 2**16) {
            x >>= 16;
            msb += 16;
        }
        if (x >= 2**8) {
            x >>= 8;
            msb += 8;
        }
        if (x >= 2**4) {
            x >>= 4;
            msb += 4;
        }
        if (x >= 2**2) {
            x >>= 2;
            msb += 2;
        }
        if (x >= 2**1) {
            // No need to shift x any more.
            msb += 1;
        }
    }

    /// @notice Calculates floor(x*y÷denominator) with full precision.
    ///
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv.
    ///
    /// Requirements:
    /// - The denominator cannot be zero.
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The multiplicand as an uint256.
    /// @param y The multiplier as an uint256.
    /// @param denominator The divisor as an uint256.
    /// @return result The result as an uint256.
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
        // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2^256 + prod0.
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division.
        if (prod1 == 0) {
            unchecked {
                result = prod0 / denominator;
            }
            return result;
        }

        // Make sure the result is less than 2^256. Also prevents denominator == 0.
        if (prod1 >= denominator) {
            revert PRBMath__MulDivOverflow(prod1, denominator);
        }

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0].
        uint256 remainder;
        assembly {
            // Compute remainder using mulmod.
            remainder := mulmod(x, y, denominator)

            // Subtract 256 bit number from 512 bit number.
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
        // See https://cs.stackexchange.com/q/138556/92363.
        unchecked {
            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 lpotdod = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by lpotdod.
                denominator := div(denominator, lpotdod)

                // Divide [prod1 prod0] by lpotdod.
                prod0 := div(prod0, lpotdod)

                // Flip lpotdod such that it is 2^256 / lpotdod. If lpotdod is zero, then it becomes one.
                lpotdod := add(div(sub(0, lpotdod), lpotdod), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * lpotdod;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Now use Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /// @notice Calculates floor(x*y÷1e18) with full precision.
    ///
    /// @dev Variant of "mulDiv" with constant folding, i.e. in which the denominator is always 1e18. Before returning the
    /// final result, we add 1 if (x * y) % SCALE >= HALF_SCALE. Without this, 6.6e-19 would be truncated to 0 instead of
    /// being rounded to 1e-18.  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717.
    ///
    /// Requirements:
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - The body is purposely left uncommented; see the NatSpec comments in "PRBMath.mulDiv" to understand how this works.
    /// - It is assumed that the result can never be type(uint256).max when x and y solve the following two equations:
    ///     1. x * y = type(uint256).max * SCALE
    ///     2. (x * y) % SCALE >= SCALE / 2
    ///
    /// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function mulDivFixedPoint(uint256 x, uint256 y) internal pure returns (uint256 result) {
        uint256 prod0;
        uint256 prod1;
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        if (prod1 >= SCALE) {
            revert PRBMath__MulDivFixedPointOverflow(prod1);
        }

        uint256 remainder;
        uint256 roundUpUnit;
        assembly {
            remainder := mulmod(x, y, SCALE)
            roundUpUnit := gt(remainder, 499999999999999999)
        }

        if (prod1 == 0) {
            unchecked {
                result = (prod0 / SCALE) + roundUpUnit;
                return result;
            }
        }

        assembly {
            result := add(
                mul(
                    or(
                        div(sub(prod0, remainder), SCALE_LPOTD),
                        mul(sub(prod1, gt(remainder, prod0)), add(div(sub(0, SCALE_LPOTD), SCALE_LPOTD), 1))
                    ),
                    SCALE_INVERSE
                ),
                roundUpUnit
            )
        }
    }

    /// @notice Calculates floor(x*y÷denominator) with full precision.
    ///
    /// @dev An extension of "mulDiv" for signed numbers. Works by computing the signs and the absolute values separately.
    ///
    /// Requirements:
    /// - None of the inputs can be type(int256).min.
    /// - The result must fit within int256.
    ///
    /// @param x The multiplicand as an int256.
    /// @param y The multiplier as an int256.
    /// @param denominator The divisor as an int256.
    /// @return result The result as an int256.
    function mulDivSigned(
        int256 x,
        int256 y,
        int256 denominator
    ) internal pure returns (int256 result) {
        if (x == type(int256).min || y == type(int256).min || denominator == type(int256).min) {
            revert PRBMath__MulDivSignedInputTooSmall();
        }

        // Get hold of the absolute values of x, y and the denominator.
        uint256 ax;
        uint256 ay;
        uint256 ad;
        unchecked {
            ax = x < 0 ? uint256(-x) : uint256(x);
            ay = y < 0 ? uint256(-y) : uint256(y);
            ad = denominator < 0 ? uint256(-denominator) : uint256(denominator);
        }

        // Compute the absolute value of (x*y)÷denominator. The result must fit within int256.
        uint256 rAbs = mulDiv(ax, ay, ad);
        if (rAbs > uint256(type(int256).max)) {
            revert PRBMath__MulDivSignedOverflow(rAbs);
        }

        // Get the signs of x, y and the denominator.
        uint256 sx;
        uint256 sy;
        uint256 sd;
        assembly {
            sx := sgt(x, sub(0, 1))
            sy := sgt(y, sub(0, 1))
            sd := sgt(denominator, sub(0, 1))
        }

        // XOR over sx, sy and sd. This is checking whether there are one or three negative signs in the inputs.
        // If yes, the result should be negative.
        result = sx ^ sy ^ sd == 0 ? -int256(rAbs) : int256(rAbs);
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The uint256 number for which to calculate the square root.
    /// @return result The result as an uint256.
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        // Set the initial guess to the closest power of two that is higher than x.
        uint256 xAux = uint256(x);
        result = 1;
        if (xAux >= 0x100000000000000000000000000000000) {
            xAux >>= 128;
            result <<= 64;
        }
        if (xAux >= 0x10000000000000000) {
            xAux >>= 64;
            result <<= 32;
        }
        if (xAux >= 0x100000000) {
            xAux >>= 32;
            result <<= 16;
        }
        if (xAux >= 0x10000) {
            xAux >>= 16;
            result <<= 8;
        }
        if (xAux >= 0x100) {
            xAux >>= 8;
            result <<= 4;
        }
        if (xAux >= 0x10) {
            xAux >>= 4;
            result <<= 2;
        }
        if (xAux >= 0x8) {
            result <<= 1;
        }

        // The operations can never overflow because the result is max 2^127 when it enters this block.
        unchecked {
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1; // Seven iterations should be enough
            uint256 roundedDownResult = x / result;
            return result >= roundedDownResult ? roundedDownResult : result;
        }
    }
}

// SPDX-License-Identifier: WTFPL
pragma solidity >=0.8.4;

import "./PRBMath.sol";

/// @title PRBMathUD60x18
/// @author Paul Razvan Berg
/// @notice Smart contract library for advanced fixed-point math that works with uint256 numbers considered to have 18
/// trailing decimals. We call this number representation unsigned 60.18-decimal fixed-point, since there can be up to 60
/// digits in the integer part and up to 18 decimals in the fractional part. The numbers are bound by the minimum and the
/// maximum values permitted by the Solidity type uint256.
library PRBMathUD60x18 {
    /// @dev Half the SCALE number.
    uint256 internal constant HALF_SCALE = 5e17;

    /// @dev log2(e) as an unsigned 60.18-decimal fixed-point number.
    uint256 internal constant LOG2_E = 1442695040888963407;

    /// @dev The maximum value an unsigned 60.18-decimal fixed-point number can have.
    uint256 internal constant MAX_UD60x18 = 115792089237316195423570985008687907853269984665640564039457584007913129639935;

    /// @dev The maximum whole value an unsigned 60.18-decimal fixed-point number can have.
    uint256 internal constant MAX_WHOLE_UD60x18 = 115792089237316195423570985008687907853269984665640564039457000000000000000000;

    /// @dev How many trailing decimals can be represented.
    uint256 internal constant SCALE = 1e18;

    /// @notice Calculates arithmetic average of x and y, rounding down.
    /// @param x The first operand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The second operand as an unsigned 60.18-decimal fixed-point number.
    /// @return result The arithmetic average as an unsigned 60.18-decimal fixed-point number.
    function avg(uint256 x, uint256 y) internal pure returns (uint256 result) {
        // The operations can never overflow.
        unchecked {
            // The last operand checks if both x and y are odd and if that is the case, we add 1 to the result. We need
            // to do this because if both numbers are odd, the 0.5 remainder gets truncated twice.
            result = (x >> 1) + (y >> 1) + (x & y & 1);
        }
    }

    /// @notice Yields the least unsigned 60.18 decimal fixed-point number greater than or equal to x.
    ///
    /// @dev Optimised for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    ///
    /// Requirements:
    /// - x must be less than or equal to MAX_WHOLE_UD60x18.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number to ceil.
    /// @param result The least integer greater than or equal to x, as an unsigned 60.18-decimal fixed-point number.
    function ceil(uint256 x) internal pure returns (uint256 result) {
        if (x > MAX_WHOLE_UD60x18) {
            revert PRBMathUD60x18__CeilOverflow(x);
        }
        assembly {
            // Equivalent to "x % SCALE" but faster.
            let remainder := mod(x, SCALE)

            // Equivalent to "SCALE - remainder" but faster.
            let delta := sub(SCALE, remainder)

            // Equivalent to "x + delta * (remainder > 0 ? 1 : 0)" but faster.
            result := add(x, mul(delta, gt(remainder, 0)))
        }
    }

    /// @notice Divides two unsigned 60.18-decimal fixed-point numbers, returning a new unsigned 60.18-decimal fixed-point number.
    ///
    /// @dev Uses mulDiv to enable overflow-safe multiplication and division.
    ///
    /// Requirements:
    /// - The denominator cannot be zero.
    ///
    /// @param x The numerator as an unsigned 60.18-decimal fixed-point number.
    /// @param y The denominator as an unsigned 60.18-decimal fixed-point number.
    /// @param result The quotient as an unsigned 60.18-decimal fixed-point number.
    function div(uint256 x, uint256 y) internal pure returns (uint256 result) {
        result = PRBMath.mulDiv(x, SCALE, y);
    }

    /// @notice Returns Euler's number as an unsigned 60.18-decimal fixed-point number.
    /// @dev See https://en.wikipedia.org/wiki/E_(mathematical_constant).
    function e() internal pure returns (uint256 result) {
        result = 2718281828459045235;
    }

    /// @notice Calculates the natural exponent of x.
    ///
    /// @dev Based on the insight that e^x = 2^(x * log2(e)).
    ///
    /// Requirements:
    /// - All from "log2".
    /// - x must be less than 133.084258667509499441.
    ///
    /// @param x The exponent as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp(uint256 x) internal pure returns (uint256 result) {
        // Without this check, the value passed to "exp2" would be greater than 192.
        if (x >= 133084258667509499441) {
            revert PRBMathUD60x18__ExpInputTooBig(x);
        }

        // Do the fixed-point multiplication inline to save gas.
        unchecked {
            uint256 doubleScaleProduct = x * LOG2_E;
            result = exp2((doubleScaleProduct + HALF_SCALE) / SCALE);
        }
    }

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    ///
    /// @dev See https://ethereum.stackexchange.com/q/79903/24693.
    ///
    /// Requirements:
    /// - x must be 192 or less.
    /// - The result must fit within MAX_UD60x18.
    ///
    /// @param x The exponent as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp2(uint256 x) internal pure returns (uint256 result) {
        // 2^192 doesn't fit within the 192.64-bit format used internally in this function.
        if (x >= 192e18) {
            revert PRBMathUD60x18__Exp2InputTooBig(x);
        }

        unchecked {
            // Convert x to the 192.64-bit fixed-point format.
            uint256 x192x64 = (x << 64) / SCALE;

            // Pass x to the PRBMath.exp2 function, which uses the 192.64-bit fixed-point number representation.
            result = PRBMath.exp2(x192x64);
        }
    }

    /// @notice Yields the greatest unsigned 60.18 decimal fixed-point number less than or equal to x.
    /// @dev Optimised for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    /// @param x The unsigned 60.18-decimal fixed-point number to floor.
    /// @param result The greatest integer less than or equal to x, as an unsigned 60.18-decimal fixed-point number.
    function floor(uint256 x) internal pure returns (uint256 result) {
        assembly {
            // Equivalent to "x % SCALE" but faster.
            let remainder := mod(x, SCALE)

            // Equivalent to "x - remainder * (remainder > 0 ? 1 : 0)" but faster.
            result := sub(x, mul(remainder, gt(remainder, 0)))
        }
    }

    /// @notice Yields the excess beyond the floor of x.
    /// @dev Based on the odd function definition https://en.wikipedia.org/wiki/Fractional_part.
    /// @param x The unsigned 60.18-decimal fixed-point number to get the fractional part of.
    /// @param result The fractional part of x as an unsigned 60.18-decimal fixed-point number.
    function frac(uint256 x) internal pure returns (uint256 result) {
        assembly {
            result := mod(x, SCALE)
        }
    }

    /// @notice Converts a number from basic integer form to unsigned 60.18-decimal fixed-point representation.
    ///
    /// @dev Requirements:
    /// - x must be less than or equal to MAX_UD60x18 divided by SCALE.
    ///
    /// @param x The basic integer to convert.
    /// @param result The same number in unsigned 60.18-decimal fixed-point representation.
    function fromUint(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            if (x > MAX_UD60x18 / SCALE) {
                revert PRBMathUD60x18__FromUintOverflow(x);
            }
            result = x * SCALE;
        }
    }

    /// @notice Calculates geometric mean of x and y, i.e. sqrt(x * y), rounding down.
    ///
    /// @dev Requirements:
    /// - x * y must fit within MAX_UD60x18, lest it overflows.
    ///
    /// @param x The first operand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The second operand as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function gm(uint256 x, uint256 y) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        unchecked {
            // Checking for overflow this way is faster than letting Solidity do it.
            uint256 xy = x * y;
            if (xy / x != y) {
                revert PRBMathUD60x18__GmOverflow(x, y);
            }

            // We don't need to multiply by the SCALE here because the x*y product had already picked up a factor of SCALE
            // during multiplication. See the comments within the "sqrt" function.
            result = PRBMath.sqrt(xy);
        }
    }

    /// @notice Calculates 1 / x, rounding towards zero.
    ///
    /// @dev Requirements:
    /// - x cannot be zero.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the inverse.
    /// @return result The inverse as an unsigned 60.18-decimal fixed-point number.
    function inv(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            // 1e36 is SCALE * SCALE.
            result = 1e36 / x;
        }
    }

    /// @notice Calculates the natural logarithm of x.
    ///
    /// @dev Based on the insight that ln(x) = log2(x) / log2(e).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    /// - This doesn't return exactly 1 for 2.718281828459045235, for that we would need more fine-grained precision.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the natural logarithm.
    /// @return result The natural logarithm as an unsigned 60.18-decimal fixed-point number.
    function ln(uint256 x) internal pure returns (uint256 result) {
        // Do the fixed-point multiplication inline to save gas. This is overflow-safe because the maximum value that log2(x)
        // can return is 196205294292027477728.
        unchecked {
            result = (log2(x) * SCALE) / LOG2_E;
        }
    }

    /// @notice Calculates the common logarithm of x.
    ///
    /// @dev First checks if x is an exact power of ten and it stops if yes. If it's not, calculates the common
    /// logarithm based on the insight that log10(x) = log2(x) / log2(10).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the common logarithm.
    /// @return result The common logarithm as an unsigned 60.18-decimal fixed-point number.
    function log10(uint256 x) internal pure returns (uint256 result) {
        if (x < SCALE) {
            revert PRBMathUD60x18__LogInputTooSmall(x);
        }

        // Note that the "mul" in this block is the assembly multiplication operation, not the "mul" function defined
        // in this contract.
        // prettier-ignore
        assembly {
            switch x
            case 1 { result := mul(SCALE, sub(0, 18)) }
            case 10 { result := mul(SCALE, sub(1, 18)) }
            case 100 { result := mul(SCALE, sub(2, 18)) }
            case 1000 { result := mul(SCALE, sub(3, 18)) }
            case 10000 { result := mul(SCALE, sub(4, 18)) }
            case 100000 { result := mul(SCALE, sub(5, 18)) }
            case 1000000 { result := mul(SCALE, sub(6, 18)) }
            case 10000000 { result := mul(SCALE, sub(7, 18)) }
            case 100000000 { result := mul(SCALE, sub(8, 18)) }
            case 1000000000 { result := mul(SCALE, sub(9, 18)) }
            case 10000000000 { result := mul(SCALE, sub(10, 18)) }
            case 100000000000 { result := mul(SCALE, sub(11, 18)) }
            case 1000000000000 { result := mul(SCALE, sub(12, 18)) }
            case 10000000000000 { result := mul(SCALE, sub(13, 18)) }
            case 100000000000000 { result := mul(SCALE, sub(14, 18)) }
            case 1000000000000000 { result := mul(SCALE, sub(15, 18)) }
            case 10000000000000000 { result := mul(SCALE, sub(16, 18)) }
            case 100000000000000000 { result := mul(SCALE, sub(17, 18)) }
            case 1000000000000000000 { result := 0 }
            case 10000000000000000000 { result := SCALE }
            case 100000000000000000000 { result := mul(SCALE, 2) }
            case 1000000000000000000000 { result := mul(SCALE, 3) }
            case 10000000000000000000000 { result := mul(SCALE, 4) }
            case 100000000000000000000000 { result := mul(SCALE, 5) }
            case 1000000000000000000000000 { result := mul(SCALE, 6) }
            case 10000000000000000000000000 { result := mul(SCALE, 7) }
            case 100000000000000000000000000 { result := mul(SCALE, 8) }
            case 1000000000000000000000000000 { result := mul(SCALE, 9) }
            case 10000000000000000000000000000 { result := mul(SCALE, 10) }
            case 100000000000000000000000000000 { result := mul(SCALE, 11) }
            case 1000000000000000000000000000000 { result := mul(SCALE, 12) }
            case 10000000000000000000000000000000 { result := mul(SCALE, 13) }
            case 100000000000000000000000000000000 { result := mul(SCALE, 14) }
            case 1000000000000000000000000000000000 { result := mul(SCALE, 15) }
            case 10000000000000000000000000000000000 { result := mul(SCALE, 16) }
            case 100000000000000000000000000000000000 { result := mul(SCALE, 17) }
            case 1000000000000000000000000000000000000 { result := mul(SCALE, 18) }
            case 10000000000000000000000000000000000000 { result := mul(SCALE, 19) }
            case 100000000000000000000000000000000000000 { result := mul(SCALE, 20) }
            case 1000000000000000000000000000000000000000 { result := mul(SCALE, 21) }
            case 10000000000000000000000000000000000000000 { result := mul(SCALE, 22) }
            case 100000000000000000000000000000000000000000 { result := mul(SCALE, 23) }
            case 1000000000000000000000000000000000000000000 { result := mul(SCALE, 24) }
            case 10000000000000000000000000000000000000000000 { result := mul(SCALE, 25) }
            case 100000000000000000000000000000000000000000000 { result := mul(SCALE, 26) }
            case 1000000000000000000000000000000000000000000000 { result := mul(SCALE, 27) }
            case 10000000000000000000000000000000000000000000000 { result := mul(SCALE, 28) }
            case 100000000000000000000000000000000000000000000000 { result := mul(SCALE, 29) }
            case 1000000000000000000000000000000000000000000000000 { result := mul(SCALE, 30) }
            case 10000000000000000000000000000000000000000000000000 { result := mul(SCALE, 31) }
            case 100000000000000000000000000000000000000000000000000 { result := mul(SCALE, 32) }
            case 1000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 33) }
            case 10000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 34) }
            case 100000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 35) }
            case 1000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 36) }
            case 10000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 37) }
            case 100000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 38) }
            case 1000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 39) }
            case 10000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 40) }
            case 100000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 41) }
            case 1000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 42) }
            case 10000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 43) }
            case 100000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 44) }
            case 1000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 45) }
            case 10000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 46) }
            case 100000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 47) }
            case 1000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 48) }
            case 10000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 49) }
            case 100000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 50) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 51) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 52) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 53) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 54) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 55) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 56) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 57) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 58) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 59) }
            default {
                result := MAX_UD60x18
            }
        }

        if (result == MAX_UD60x18) {
            // Do the fixed-point division inline to save gas. The denominator is log2(10).
            unchecked {
                result = (log2(x) * SCALE) / 3321928094887362347;
            }
        }
    }

    /// @notice Calculates the binary logarithm of x.
    ///
    /// @dev Based on the iterative approximation algorithm.
    /// https://en.wikipedia.org/wiki/Binary_logarithm#Iterative_approximation
    ///
    /// Requirements:
    /// - x must be greater than or equal to SCALE, otherwise the result would be negative.
    ///
    /// Caveats:
    /// - The results are nor perfectly accurate to the last decimal, due to the lossy precision of the iterative approximation.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the binary logarithm.
    /// @return result The binary logarithm as an unsigned 60.18-decimal fixed-point number.
    function log2(uint256 x) internal pure returns (uint256 result) {
        if (x < SCALE) {
            revert PRBMathUD60x18__LogInputTooSmall(x);
        }
        unchecked {
            // Calculate the integer part of the logarithm and add it to the result and finally calculate y = x * 2^(-n).
            uint256 n = PRBMath.mostSignificantBit(x / SCALE);

            // The integer part of the logarithm as an unsigned 60.18-decimal fixed-point number. The operation can't overflow
            // because n is maximum 255 and SCALE is 1e18.
            result = n * SCALE;

            // This is y = x * 2^(-n).
            uint256 y = x >> n;

            // If y = 1, the fractional part is zero.
            if (y == SCALE) {
                return result;
            }

            // Calculate the fractional part via the iterative approximation.
            // The "delta >>= 1" part is equivalent to "delta /= 2", but shifting bits is faster.
            for (uint256 delta = HALF_SCALE; delta > 0; delta >>= 1) {
                y = (y * y) / SCALE;

                // Is y^2 > 2 and so in the range [2,4)?
                if (y >= 2 * SCALE) {
                    // Add the 2^(-m) factor to the logarithm.
                    result += delta;

                    // Corresponds to z/2 on Wikipedia.
                    y >>= 1;
                }
            }
        }
    }

    /// @notice Multiplies two unsigned 60.18-decimal fixed-point numbers together, returning a new unsigned 60.18-decimal
    /// fixed-point number.
    /// @dev See the documentation for the "PRBMath.mulDivFixedPoint" function.
    /// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
    /// @return result The product as an unsigned 60.18-decimal fixed-point number.
    function mul(uint256 x, uint256 y) internal pure returns (uint256 result) {
        result = PRBMath.mulDivFixedPoint(x, y);
    }

    /// @notice Returns PI as an unsigned 60.18-decimal fixed-point number.
    function pi() internal pure returns (uint256 result) {
        result = 3141592653589793238;
    }

    /// @notice Raises x to the power of y.
    ///
    /// @dev Based on the insight that x^y = 2^(log2(x) * y).
    ///
    /// Requirements:
    /// - All from "exp2", "log2" and "mul".
    ///
    /// Caveats:
    /// - All from "exp2", "log2" and "mul".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x Number to raise to given power y, as an unsigned 60.18-decimal fixed-point number.
    /// @param y Exponent to raise x to, as an unsigned 60.18-decimal fixed-point number.
    /// @return result x raised to power y, as an unsigned 60.18-decimal fixed-point number.
    function pow(uint256 x, uint256 y) internal pure returns (uint256 result) {
        if (x == 0) {
            result = y == 0 ? SCALE : uint256(0);
        } else {
            result = exp2(mul(log2(x), y));
        }
    }

    /// @notice Raises x (unsigned 60.18-decimal fixed-point number) to the power of y (basic unsigned integer) using the
    /// famous algorithm "exponentiation by squaring".
    ///
    /// @dev See https://en.wikipedia.org/wiki/Exponentiation_by_squaring
    ///
    /// Requirements:
    /// - The result must fit within MAX_UD60x18.
    ///
    /// Caveats:
    /// - All from "mul".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x The base as an unsigned 60.18-decimal fixed-point number.
    /// @param y The exponent as an uint256.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function powu(uint256 x, uint256 y) internal pure returns (uint256 result) {
        // Calculate the first iteration of the loop in advance.
        result = y & 1 > 0 ? x : SCALE;

        // Equivalent to "for(y /= 2; y > 0; y /= 2)" but faster.
        for (y >>= 1; y > 0; y >>= 1) {
            x = PRBMath.mulDivFixedPoint(x, x);

            // Equivalent to "y % 2 == 1" but faster.
            if (y & 1 > 0) {
                result = PRBMath.mulDivFixedPoint(result, x);
            }
        }
    }

    /// @notice Returns 1 as an unsigned 60.18-decimal fixed-point number.
    function scale() internal pure returns (uint256 result) {
        result = SCALE;
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Requirements:
    /// - x must be less than MAX_UD60x18 / SCALE.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the square root.
    /// @return result The result as an unsigned 60.18-decimal fixed-point .
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            if (x > MAX_UD60x18 / SCALE) {
                revert PRBMathUD60x18__SqrtOverflow(x);
            }
            // Multiply x by the SCALE to account for the factor of SCALE that is picked up when multiplying two unsigned
            // 60.18-decimal fixed-point numbers together (in this case, those two numbers are both the square root).
            result = PRBMath.sqrt(x * SCALE);
        }
    }

    /// @notice Converts a unsigned 60.18-decimal fixed-point number to basic integer form, rounding down in the process.
    /// @param x The unsigned 60.18-decimal fixed-point number to convert.
    /// @return result The same number in basic integer form.
    function toUint(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            result = x / SCALE;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./IOperatorStore.sol";

interface IOperatable {
    function operatorStore() external view returns (IOperatorStore);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./interfaces/ITicketBooth.sol";
import "./abstract/Operatable.sol";
import "./abstract/TerminalUtility.sol";

import "./libraries/Operations.sol";

import "./Tickets.sol";

/** 
  @notice 
  Manage Ticket printing, redemption, and account balances.

  @dev
  Tickets can be either represented internally staked, or as unstaked ERC-20s.
  This contract manages these two representations and the conversion between the two.

  @dev
  The total supply of a project's tickets and the balance of each account are calculated in this contract.
*/
contract TicketBooth is TerminalUtility, Operatable, ITicketBooth {
    // --- public immutable stored properties --- //

    /// @notice The Projects contract which mints ERC-721's that represent project ownership and transfers.
    IProjects public immutable override projects;

    // --- public stored properties --- //

    // Each project's ERC20 Ticket tokens.
    mapping(uint256 => ITickets) public override ticketsOf;

    // Each holder's balance of staked Tickets for each project.
    mapping(address => mapping(uint256 => uint256))
        public
        override stakedBalanceOf;

    // The total supply of 1155 tickets for each project.
    mapping(uint256 => uint256) public override stakedTotalSupplyOf;

    // The amount of each holders tickets that are locked.
    mapping(address => mapping(uint256 => uint256))
        public
        override lockedBalanceOf;

    // The amount of each holders tickets that are locked by each address.
    mapping(address => mapping(address => mapping(uint256 => uint256)))
        public
        override lockedBalanceBy;

    // --- external views --- //

    /** 
      @notice 
      The total supply of tickets for each project, including staked and unstaked tickets.

      @param _projectId The ID of the project to get the total supply of.

      @return supply The total supply.
    */
    function totalSupplyOf(uint256 _projectId)
        external
        view
        override
        returns (uint256 supply)
    {
        supply = stakedTotalSupplyOf[_projectId];
        ITickets _tickets = ticketsOf[_projectId];
        if (_tickets != ITickets(address(0)))
            supply = supply + _tickets.totalSupply();
    }

    /** 
      @notice 
      The total balance of tickets a holder has for a specified project, including staked and unstaked tickets.

      @param _holder The ticket holder to get a balance for.
      @param _projectId The project to get the `_hodler`s balance of.

      @return balance The balance.
    */
    function balanceOf(address _holder, uint256 _projectId)
        external
        view
        override
        returns (uint256 balance)
    {
        balance = stakedBalanceOf[_holder][_projectId];
        ITickets _ticket = ticketsOf[_projectId];
        if (_ticket != ITickets(address(0)))
            balance = balance + _ticket.balanceOf(_holder);
    }

    // --- external transactions --- //

    /** 
      @param _projects A Projects contract which mints ERC-721's that represent project ownership and transfers.
      @param _operatorStore A contract storing operator assignments.
      @param _terminalDirectory A directory of a project's current Juicebox terminal to receive payments in.
    */
    constructor(
        IProjects _projects,
        IOperatorStore _operatorStore,
        ITerminalDirectory _terminalDirectory
    ) Operatable(_operatorStore) TerminalUtility(_terminalDirectory) {
        projects = _projects;
    }

    /**
        @notice 
        Issues an owner's ERC-20 Tickets that'll be used when unstaking tickets.

        @dev 
        Deploys an owner's Ticket ERC-20 token contract.

        @param _projectId The ID of the project being issued tickets.
        @param _name The ERC-20's name. " Juicebox ticket" will be appended.
        @param _symbol The ERC-20's symbol. "j" will be prepended.
    */
    function issue(
        uint256 _projectId,
        string calldata _name,
        string calldata _symbol
    )
        external
        override
        requirePermission(
            projects.ownerOf(_projectId),
            _projectId,
            Operations.Issue
        )
    {
        // There must be a name.
        require((bytes(_name).length > 0), "TicketBooth::issue: EMPTY_NAME");

        // There must be a symbol.
        require(
            (bytes(_symbol).length > 0),
            "TicketBooth::issue: EMPTY_SYMBOL"
        );

        // Only one ERC20 ticket can be issued.
        require(
            ticketsOf[_projectId] == ITickets(address(0)),
            "TicketBooth::issue: ALREADY_ISSUED"
        );

        // Create the contract in this TerminalV1 contract in order to have mint and burn privileges.
        // Prepend the strings with standards.
        ticketsOf[_projectId] = new Tickets(_name, _symbol);

        emit Issue(_projectId, _name, _symbol, msg.sender);
    }

    /** 
      @notice 
      Print new tickets.

      @dev
      Only a project's current terminal can print its tickets.

      @param _holder The address receiving the new tickets.
      @param _projectId The project to which the tickets belong.
      @param _amount The amount to print.
      @param _preferUnstakedTickets Whether ERC20's should be converted automatically if they have been issued.
    */
    function print(
        address _holder,
        uint256 _projectId,
        uint256 _amount,
        bool _preferUnstakedTickets
    ) external override onlyTerminal(_projectId) {
        // An amount must be specified.
        require(_amount > 0, "TicketBooth::print: NO_OP");

        // Get a reference to the project's ERC20 tickets.
        ITickets _tickets = ticketsOf[_projectId];

        // If there exists ERC-20 tickets and the caller prefers these unstaked tickets.
        bool _shouldUnstakeTickets = _preferUnstakedTickets &&
            _tickets != ITickets(address(0));

        if (_shouldUnstakeTickets) {
            // Print the equivalent amount of ERC20s.
            _tickets.print(_holder, _amount);
        } else {
            // Add to the staked balance and total supply.
            stakedBalanceOf[_holder][_projectId] =
                stakedBalanceOf[_holder][_projectId] +
                _amount;
            stakedTotalSupplyOf[_projectId] =
                stakedTotalSupplyOf[_projectId] +
                _amount;
        }

        emit Print(
            _holder,
            _projectId,
            _amount,
            _shouldUnstakeTickets,
            _preferUnstakedTickets,
            msg.sender
        );
    }

    /** 
      @notice 
      Redeems tickets.

      @dev
      Only a project's current terminal can redeem its tickets.

      @param _holder The address that owns the tickets being redeemed.
      @param _projectId The ID of the project of the tickets being redeemed.
      @param _amount The amount of tickets being redeemed.
      @param _preferUnstaked If the preference is to redeem tickets that have been converted to ERC-20s.
    */
    function redeem(
        address _holder,
        uint256 _projectId,
        uint256 _amount,
        bool _preferUnstaked
    ) external override onlyTerminal(_projectId) {
        // Get a reference to the project's ERC20 tickets.
        ITickets _tickets = ticketsOf[_projectId];

        // Get a reference to the staked amount.
        uint256 _unlockedStakedBalance = stakedBalanceOf[_holder][_projectId] -
            lockedBalanceOf[_holder][_projectId];

        // Get a reference to the number of tickets there are.
        uint256 _unstakedBalanceOf = _tickets == ITickets(address(0))
            ? 0
            : _tickets.balanceOf(_holder);

        // There must be enough tickets.
        // Prevent potential overflow by not relying on addition.
        require(
            (_amount < _unstakedBalanceOf &&
                _amount < _unlockedStakedBalance) ||
                (_amount >= _unstakedBalanceOf &&
                    _unlockedStakedBalance >= _amount - _unstakedBalanceOf) ||
                (_amount >= _unlockedStakedBalance &&
                    _unstakedBalanceOf >= _amount - _unlockedStakedBalance),
            "TicketBooth::redeem: INSUFFICIENT_FUNDS"
        );

        // The amount of tickets to redeem.
        uint256 _unstakedTicketsToRedeem;

        // If there's no balance, redeem no tickets
        if (_unstakedBalanceOf == 0) {
            _unstakedTicketsToRedeem = 0;
            // If prefer converted, redeem tickets before redeeming staked tickets.
        } else if (_preferUnstaked) {
            _unstakedTicketsToRedeem = _unstakedBalanceOf >= _amount
                ? _amount
                : _unstakedBalanceOf;
            // Otherwise, redeem staked tickets before unstaked tickets.
        } else {
            _unstakedTicketsToRedeem = _unlockedStakedBalance >= _amount
                ? 0
                : _amount - _unlockedStakedBalance;
        }

        // The amount of staked tickets to redeem.
        uint256 _stakedTicketsToRedeem = _amount - _unstakedTicketsToRedeem;

        // Redeem the tickets.
        if (_unstakedTicketsToRedeem > 0)
            _tickets.redeem(_holder, _unstakedTicketsToRedeem);
        if (_stakedTicketsToRedeem > 0) {
            // Reduce the holders balance and the total supply.
            stakedBalanceOf[_holder][_projectId] =
                stakedBalanceOf[_holder][_projectId] -
                _stakedTicketsToRedeem;
            stakedTotalSupplyOf[_projectId] =
                stakedTotalSupplyOf[_projectId] -
                _stakedTicketsToRedeem;
        }

        emit Redeem(
            _holder,
            _projectId,
            _amount,
            _unlockedStakedBalance,
            _preferUnstaked,
            msg.sender
        );
    }

    /**
      @notice 
      Stakes ERC20 tickets by burning their supply and creating an internal staked version.

      @dev
      Only a ticket holder or an operator can stake its tickets.

      @param _holder The owner of the tickets to stake.
      @param _projectId The ID of the project whos tickets are being staked.
      @param _amount The amount of tickets to stake.
     */
    function stake(
        address _holder,
        uint256 _projectId,
        uint256 _amount
    )
        external
        override
        requirePermissionAllowingWildcardDomain(
            _holder,
            _projectId,
            Operations.Stake
        )
    {
        // Get a reference to the project's ERC20 tickets.
        ITickets _tickets = ticketsOf[_projectId];

        // Tickets must have been issued.
        require(
            _tickets != ITickets(address(0)),
            "TicketBooth::stake: NOT_FOUND"
        );

        // Get a reference to the holder's current balance.
        uint256 _unstakedBalanceOf = _tickets.balanceOf(_holder);

        // There must be enough balance to stake.
        require(
            _unstakedBalanceOf >= _amount,
            "TicketBooth::stake: INSUFFICIENT_FUNDS"
        );

        // Redeem the equivalent amount of ERC20s.
        _tickets.redeem(_holder, _amount);

        // Add the staked amount from the holder's balance.
        stakedBalanceOf[_holder][_projectId] =
            stakedBalanceOf[_holder][_projectId] +
            _amount;

        // Add the staked amount from the project's total supply.
        stakedTotalSupplyOf[_projectId] =
            stakedTotalSupplyOf[_projectId] +
            _amount;

        emit Stake(_holder, _projectId, _amount, msg.sender);
    }

    /**
      @notice 
      Unstakes internal tickets by creating and distributing ERC20 tickets.

      @dev
      Only a ticket holder or an operator can unstake its tickets.

      @param _holder The owner of the tickets to unstake.
      @param _projectId The ID of the project whos tickets are being unstaked.
      @param _amount The amount of tickets to unstake.
     */
    function unstake(
        address _holder,
        uint256 _projectId,
        uint256 _amount
    )
        external
        override
        requirePermissionAllowingWildcardDomain(
            _holder,
            _projectId,
            Operations.Unstake
        )
    {
        // Get a reference to the project's ERC20 tickets.
        ITickets _tickets = ticketsOf[_projectId];

        // Tickets must have been issued.
        require(
            _tickets != ITickets(address(0)),
            "TicketBooth::unstake: NOT_FOUND"
        );

        // Get a reference to the amount of unstaked tickets.
        uint256 _unlockedStakedTickets = stakedBalanceOf[_holder][_projectId] -
            lockedBalanceOf[_holder][_projectId];

        // There must be enough unlocked staked tickets to unstake.
        require(
            _unlockedStakedTickets >= _amount,
            "TicketBooth::unstake: INSUFFICIENT_FUNDS"
        );

        // Subtract the unstaked amount from the holder's balance.
        stakedBalanceOf[_holder][_projectId] =
            stakedBalanceOf[_holder][_projectId] -
            _amount;

        // Subtract the unstaked amount from the project's total supply.
        stakedTotalSupplyOf[_projectId] =
            stakedTotalSupplyOf[_projectId] -
            _amount;

        // Print the equivalent amount of ERC20s.
        _tickets.print(_holder, _amount);

        emit Unstake(_holder, _projectId, _amount, msg.sender);
    }

    /** 
      @notice 
      Lock a project's tickets, preventing them from being redeemed and from converting to ERC20s.

      @dev
      Only a ticket holder or an operator can lock its tickets.

      @param _holder The holder to lock tickets from.
      @param _projectId The ID of the project whos tickets are being locked.
      @param _amount The amount of tickets to lock.
    */
    function lock(
        address _holder,
        uint256 _projectId,
        uint256 _amount
    )
        external
        override
        requirePermissionAllowingWildcardDomain(
            _holder,
            _projectId,
            Operations.Lock
        )
    {
        // Amount must be greater than 0.
        require(_amount > 0, "TicketBooth::lock: NO_OP");

        // The holder must have enough tickets to lock.
        require(
            stakedBalanceOf[_holder][_projectId] -
                lockedBalanceOf[_holder][_projectId] >=
                _amount,
            "TicketBooth::lock: INSUFFICIENT_FUNDS"
        );

        // Update the lock.
        lockedBalanceOf[_holder][_projectId] =
            lockedBalanceOf[_holder][_projectId] +
            _amount;
        lockedBalanceBy[msg.sender][_holder][_projectId] =
            lockedBalanceBy[msg.sender][_holder][_projectId] +
            _amount;

        emit Lock(_holder, _projectId, _amount, msg.sender);
    }

    /** 
      @notice 
      Unlock a project's tickets.

      @dev
      The address that locked the tickets must be the address that unlocks the tickets.

      @param _holder The holder to unlock tickets from.
      @param _projectId The ID of the project whos tickets are being unlocked.
      @param _amount The amount of tickets to unlock.
    */
    function unlock(
        address _holder,
        uint256 _projectId,
        uint256 _amount
    ) external override {
        // Amount must be greater than 0.
        require(_amount > 0, "TicketBooth::unlock: NO_OP");

        // There must be enough locked tickets to unlock.
        require(
            lockedBalanceBy[msg.sender][_holder][_projectId] >= _amount,
            "TicketBooth::unlock: INSUFFICIENT_FUNDS"
        );

        // Update the lock.
        lockedBalanceOf[_holder][_projectId] =
            lockedBalanceOf[_holder][_projectId] -
            _amount;
        lockedBalanceBy[msg.sender][_holder][_projectId] =
            lockedBalanceBy[msg.sender][_holder][_projectId] -
            _amount;

        emit Unlock(_holder, _projectId, _amount, msg.sender);
    }

    /** 
      @notice 
      Allows a ticket holder to transfer its tickets to another account, without unstaking to ERC-20s.

      @dev
      Only a ticket holder or an operator can transfer its tickets.

      @param _holder The holder to transfer tickets from.
      @param _projectId The ID of the project whos tickets are being transfered.
      @param _amount The amount of tickets to transfer.
      @param _recipient The recipient of the tickets.
    */
    function transfer(
        address _holder,
        uint256 _projectId,
        uint256 _amount,
        address _recipient
    )
        external
        override
        requirePermissionAllowingWildcardDomain(
            _holder,
            _projectId,
            Operations.Transfer
        )
    {
        // Can't transfer to the zero address.
        require(
            _recipient != address(0),
            "TicketBooth::transfer: ZERO_ADDRESS"
        );

        // An address can't transfer to itself.
        require(_holder != _recipient, "TicketBooth::transfer: IDENTITY");

        // There must be an amount to transfer.
        require(_amount > 0, "TicketBooth::transfer: NO_OP");

        // Get a reference to the amount of unlocked staked tickets.
        uint256 _unlockedStakedTickets = stakedBalanceOf[_holder][_projectId] -
            lockedBalanceOf[_holder][_projectId];

        // There must be enough unlocked staked tickets to transfer.
        require(
            _amount <= _unlockedStakedTickets,
            "TicketBooth::transfer: INSUFFICIENT_FUNDS"
        );

        // Subtract from the holder.
        stakedBalanceOf[_holder][_projectId] =
            stakedBalanceOf[_holder][_projectId] -
            _amount;

        // Add the tickets to the recipient.
        stakedBalanceOf[_recipient][_projectId] =
            stakedBalanceOf[_recipient][_projectId] +
            _amount;

        emit Transfer(_holder, _projectId, _recipient, _amount, msg.sender);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./../interfaces/ITerminalUtility.sol";

abstract contract TerminalUtility is ITerminalUtility {
    modifier onlyTerminal(uint256 _projectId) {
        require(
            address(terminalDirectory.terminalOf(_projectId)) == msg.sender,
            "TerminalUtility: UNAUTHORIZED"
        );
        _;
    }

    /// @notice The direct deposit terminals.
    ITerminalDirectory public immutable override terminalDirectory;

    /** 
      @param _terminalDirectory A directory of a project's current Juicebox terminal to receive payments in.
    */
    constructor(ITerminalDirectory _terminalDirectory) {
        terminalDirectory = _terminalDirectory;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@paulrberg/contracts/token/erc20/Erc20Permit.sol";

import "./interfaces/ITickets.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

contract Tickets is ERC20, ERC20Permit, Ownable, ITickets {
    constructor(string memory _name, string memory _symbol)
        ERC20(_name, _symbol)
        ERC20Permit(_name)
    {}

    function print(address _account, uint256 _amount)
        external
        override
        onlyOwner
    {
        return _mint(_account, _amount);
    }

    function redeem(address _account, uint256 _amount)
        external
        override
        onlyOwner
    {
        return _burn(_account, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ITerminalDirectory.sol";

interface ITerminalUtility {
    function terminalDirectory() external view returns (ITerminalDirectory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./draft-IERC20Permit.sol";
import "../ERC20.sol";
import "../../../utils/cryptography/draft-EIP712.sol";
import "../../../utils/cryptography/ECDSA.sol";
import "../../../utils/Counters.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20Permit is ERC20, IERC20Permit, EIP712 {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private immutable _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    constructor(string memory name) EIP712(name, "1") {}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
}

// SPDX-License-Identifier: WTFPL
// solhint-disable var-name-mixedcase
pragma solidity >=0.8.4;

import "./Erc20.sol";
import "./IErc20Permit.sol";

/// @notice Emitted when the recovered owner does not match the actual owner.
error Erc20Permit__InvalidSignature(uint8 v, bytes32 r, bytes32 s);

/// @notice Emitted when the owner is the zero address.
error Erc20Permit__OwnerZeroAddress();

/// @notice Emitted when the permit expired.
error Erc20Permit__PermitExpired(uint256 deadline);

/// @notice Emitted when the recovered owner is the zero address.
error Erc20Permit__RecoveredOwnerZeroAddress();

/// @notice Emitted when the spender is the zero address.
error Erc20Permit__SpenderZeroAddress();

/// @title Erc20Permit
/// @author Paul Razvan Berg
contract Erc20Permit is
    IErc20Permit, // one dependency
    Erc20 // one dependency
{
    /// PUBLIC STORAGE ///

    /// @inheritdoc IErc20Permit
    bytes32 public immutable override DOMAIN_SEPARATOR;

    /// @inheritdoc IErc20Permit
    bytes32 public constant override PERMIT_TYPEHASH =
        0xfc77c2b9d30fe91687fd39abb7d16fcdfe1472d065740051ab8b13e4bf4a617f;

    /// @inheritdoc IErc20Permit
    mapping(address => uint256) public override nonces;

    /// @inheritdoc IErc20Permit
    string public constant override version = "1";

    /// CONSTRUCTOR ///

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) Erc20(_name, _symbol, _decimals) {
        uint256 chainId;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                chainId,
                address(this)
            )
        );
    }

    /// PUBLIC NON-CONSTANT FUNCTIONS ///

    /// @inheritdoc IErc20Permit
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        if (owner == address(0)) {
            revert Erc20Permit__OwnerZeroAddress();
        }
        if (spender == address(0)) {
            revert Erc20Permit__SpenderZeroAddress();
        }
        if (deadline < block.timestamp) {
            revert Erc20Permit__PermitExpired(deadline);
        }

        // It's safe to use the "+" operator here because the nonce cannot realistically overflow, ever.
        bytes32 hashStruct = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, amount, nonces[owner]++, deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hashStruct));
        address recoveredOwner = ecrecover(digest, v, r, s);

        if (recoveredOwner == address(0)) {
            revert Erc20Permit__RecoveredOwnerZeroAddress();
        }
        if (recoveredOwner != owner) {
            revert Erc20Permit__InvalidSignature(v, r, s);
        }

        approveInternal(owner, spender, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return recover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return recover(hash, r, vs);
        } else {
            revert("ECDSA: invalid signature length");
        }
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`, `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(
            uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "ECDSA: invalid signature 's' value"
        );
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: WTFPL
pragma solidity >=0.8.4;

import "./IErc20.sol";

/// @notice Emitted when the owner is the zero address.
error Erc20__ApproveOwnerZeroAddress();

/// @notice Emitted when the spender is the zero address.
error Erc20__ApproveSpenderZeroAddress();

/// @notice Emitted when burning more tokens than are in the account.
error Erc20__BurnUnderflow(uint256 accountBalance, uint256 burnAmount);

/// @notice Emitted when the holder is the zero address.
error Erc20__BurnZeroAddress();

/// @notice Emitted when the sender did not give the caller a sufficient allowance.
error Erc20__InsufficientAllowance(uint256 allowance, uint256 amount);

/// @notice Emitted when the beneficiary is the zero address.
error Erc20__MintZeroAddress();

/// @notice Emitted when tranferring more tokens than there are in the account.
error Erc20__TransferUnderflow(uint256 senderBalance, uint256 amount);

/// @notice Emitted when the sender is the zero address.
error Erc20__TransferSenderZeroAddress();

/// @notice Emitted when the recipient is the zero address.
error Erc20__TransferRecipientZeroAddress();

/// @title Erc20
/// @author Paul Razvan Berg
contract Erc20 is IErc20 {
    /// PUBLIC STORAGE ///

    /// @inheritdoc IErc20
    string public override name;

    /// @inheritdoc IErc20
    string public override symbol;

    /// @inheritdoc IErc20
    uint8 public immutable override decimals;

    /// @inheritdoc IErc20
    uint256 public override totalSupply;

    /// @inheritdoc IErc20
    mapping(address => uint256) public override balanceOf;

    /// @inheritdoc IErc20
    mapping(address => mapping(address => uint256)) public override allowance;

    /// CONSTRUCTOR ///

    /// @notice All three of these values are immutable: they can only be set once during construction.
    /// @param _name Erc20 name of this token.
    /// @param _symbol Erc20 symbol of this token.
    /// @param _decimals Erc20 decimal precision of this token.
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    /// PUBLIC NON-CONSTANT FUNCTIONS ///

    /// @inheritdoc IErc20
    function approve(address spender, uint256 amount) external virtual override returns (bool) {
        approveInternal(msg.sender, spender, amount);
        return true;
    }

    /// @inheritdoc IErc20
    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual override returns (bool) {
        uint256 newAllowance = allowance[msg.sender][spender] - subtractedValue;
        approveInternal(msg.sender, spender, newAllowance);
        return true;
    }

    /// @inheritdoc IErc20
    function increaseAllowance(address spender, uint256 addedValue) external virtual override returns (bool) {
        uint256 newAllowance = allowance[msg.sender][spender] + addedValue;
        approveInternal(msg.sender, spender, newAllowance);
        return true;
    }

    /// @inheritdoc IErc20
    function transfer(address recipient, uint256 amount) external virtual override returns (bool) {
        transferInternal(msg.sender, recipient, amount);
        return true;
    }

    /// @inheritdoc IErc20
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external virtual override returns (bool) {
        transferInternal(sender, recipient, amount);

        uint256 currentAllowance = allowance[sender][msg.sender];
        if (currentAllowance < amount) {
            revert Erc20__InsufficientAllowance(currentAllowance, amount);
        }
        approveInternal(sender, msg.sender, currentAllowance);
        return true;
    }

    /// INTERNAL NON-CONSTANT FUNCTIONS ///

    /// @notice Sets `amount` as the allowance of `spender` over the `owner`s tokens.
    ///
    /// @dev Emits an {Approval} event.
    ///
    /// This is internal function is equivalent to `approve`, and can be used to e.g. set automatic
    /// allowances for certain subsystems, etc.
    ///
    /// Requirements:
    ///
    /// - `owner` cannot be the zero address.
    /// - `spender` cannot be the zero address.
    function approveInternal(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        if (owner == address(0)) {
            revert Erc20__ApproveOwnerZeroAddress();
        }
        if (spender == address(0)) {
            revert Erc20__ApproveSpenderZeroAddress();
        }

        allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /// @notice Destroys `burnAmount` tokens from `holder`, reducing the token supply.
    ///
    /// @dev Emits a {Transfer} event.
    ///
    /// Requirements:
    ///
    /// - `holder` must have at least `amount` tokens.
    function burnInternal(address holder, uint256 burnAmount) internal {
        if (holder == address(0)) {
            revert Erc20__BurnZeroAddress();
        }

        uint256 accountBalance = balanceOf[holder];
        if (accountBalance < burnAmount) {
            revert Erc20__BurnUnderflow(accountBalance, burnAmount);
        }

        // Burn the tokens.
        unchecked {
            balanceOf[holder] = accountBalance - burnAmount;
        }

        // Reduce the total supply.
        totalSupply -= burnAmount;

        emit Transfer(holder, address(0), burnAmount);
    }

    /// @notice Prints new tokens into existence and assigns them to `beneficiary`, increasing the
    /// total supply.
    ///
    /// @dev Emits a {Transfer} event.
    ///
    /// Requirements:
    ///
    /// - The beneficiary's balance and the total supply cannot overflow.
    function mintInternal(address beneficiary, uint256 mintAmount) internal {
        if (beneficiary == address(0)) {
            revert Erc20__MintZeroAddress();
        }

        /// Mint the new tokens.
        balanceOf[beneficiary] += mintAmount;

        /// Increase the total supply.
        totalSupply += mintAmount;

        emit Transfer(address(0), beneficiary, mintAmount);
    }

    /// @notice Moves `amount` tokens from `sender` to `recipient`.
    ///
    /// @dev This is internal function is equivalent to {transfer}, and can be used to e.g. implement
    /// automatic token fees, slashing mechanisms, etc.
    ///
    /// Emits a {Transfer} event.
    ///
    /// Requirements:
    ///
    /// - `sender` cannot be the zero address.
    /// - `recipient` cannot be the zero address.
    /// - `sender` must have a balance of at least `amount`.
    function transferInternal(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        if (sender == address(0)) {
            revert Erc20__TransferSenderZeroAddress();
        }
        if (recipient == address(0)) {
            revert Erc20__TransferRecipientZeroAddress();
        }

        uint256 senderBalance = balanceOf[sender];
        if (senderBalance < amount) {
            revert Erc20__TransferUnderflow(senderBalance, amount);
        }
        unchecked {
            balanceOf[sender] = senderBalance - amount;
        }

        balanceOf[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }
}

// SPDX-License-Identifier: WTFPL
// solhint-disable func-name-mixedcase
pragma solidity >=0.8.4;

import "./IErc20.sol";

/// @title IErc20Permit
/// @author Paul Razvan Berg
/// @notice Extension of Erc20 that allows token holders to use their tokens without sending any
/// transactions by setting the allowance with a signature using the `permit` method, and then spend
/// them via `transferFrom`.
/// @dev See https://eips.ethereum.org/EIPS/eip-2612.
interface IErc20Permit is IErc20 {
    /// NON-CONSTANT FUNCTIONS ///

    /// @notice Sets `amount` as the allowance of `spender` over `owner`'s tokens, assuming the latter's
    /// signed approval.
    ///
    /// @dev Emits an {Approval} event.
    ///
    /// IMPORTANT: The same issues Erc20 `approve` has related to transaction
    /// ordering also apply here.
    ///
    /// Requirements:
    ///
    /// - `owner` cannot be the zero address.
    /// - `spender` cannot be the zero address.
    /// - `deadline` must be a timestamp in the future.
    /// - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner` over the Eip712-formatted
    /// function arguments.
    /// - The signature must use `owner`'s current nonce.
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /// CONSTANT FUNCTIONS ///

    /// @notice The Eip712 domain's keccak256 hash.
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    /// @notice Provides replay protection.
    function nonces(address account) external view returns (uint256);

    /// @notice keccak256("Permit(address owner,address spender,uint256 amount,uint256 nonce,uint256 deadline)");
    function PERMIT_TYPEHASH() external view returns (bytes32);

    /// @notice Eip712 version of this implementation.
    function version() external view returns (string memory);
}

// SPDX-License-Identifier: WTFPL
pragma solidity >=0.8.4;

/// @title IErc20
/// @author Paul Razvan Berg
/// @notice Implementation for the Erc20 standard.
///
/// We have followed general OpenZeppelin guidelines: functions revert instead of returning
/// `false` on failure. This behavior is nonetheless conventional and does not conflict with
/// the with the expectations of Erc20 applications.
///
/// Additionally, an {Approval} event is emitted on calls to {transferFrom}. This allows
/// applications to reconstruct the allowance for all accounts just by listening to said
/// events. Other implementations of the Erc may not emit these events, as it isn't
/// required by the specification.
///
/// Finally, the non-standard {decreaseAllowance} and {increaseAllowance} functions have been
/// added to mitigate the well-known issues around setting allowances.
///
/// @dev Forked from OpenZeppelin
/// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.4.0/contracts/token/ERC20/ERC20.sol
interface IErc20 {
    /// EVENTS ///

    /// @notice Emitted when an approval happens.
    /// @param owner The address of the owner of the tokens.
    /// @param spender The address of the spender.
    /// @param amount The maximum amount that can be spent.
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /// @notice Emitted when a transfer happens.
    /// @param from The account sending the tokens.
    /// @param to The account receiving the tokens.
    /// @param amount The amount of tokens transferred.
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /// CONSTANT FUNCTIONS ///

    /// @notice Returns the remaining number of tokens that `spender` will be allowed to spend
    /// on behalf of `owner` through {transferFrom}. This is zero by default.
    ///
    /// @dev This value changes when {approve} or {transferFrom} are called.
    function allowance(address owner, address spender) external view returns (uint256);

    /// @notice Returns the amount of tokens owned by `account`.
    function balanceOf(address account) external view returns (uint256);

    /// @notice Returns the number of decimals used to get its user representation.
    function decimals() external view returns (uint8);

    /// @notice Returns the name of the token.
    function name() external view returns (string memory);

    /// @notice Returns the symbol of the token, usually a shorter version of the name.
    function symbol() external view returns (string memory);

    /// @notice Returns the amount of tokens in existence.
    function totalSupply() external view returns (uint256);

    /// NON-CONSTANT FUNCTIONS ///

    /// @notice Sets `amount` as the allowance of `spender` over the caller's tokens.
    ///
    /// @dev Emits an {Approval} event.
    ///
    /// IMPORTANT: Beware that changing an allowance with this method brings the risk that someone may
    /// use both the old and the new allowance by unfortunate transaction ordering. One possible solution
    /// to mitigate this race condition is to first reduce the spender's allowance to 0 and set the desired
    /// value afterwards: https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    ///
    /// Requirements:
    ///
    /// - `spender` cannot be the zero address.
    ///
    /// @return a boolean value indicating whether the operation succeeded.
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice Atomically decreases the allowance granted to `spender` by the caller.
    ///
    /// @dev Emits an {Approval} event indicating the updated allowance.
    ///
    /// This is an alternative to {approve} that can be used as a mitigation for problems described
    /// in {Erc20Interface-approve}.
    ///
    /// Requirements:
    ///
    /// - `spender` cannot be the zero address.
    /// - `spender` must have allowance for the caller of at least `subtractedValue`.
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    /// @notice Atomically increases the allowance granted to `spender` by the caller.
    ///
    /// @dev Emits an {Approval} event indicating the updated allowance.
    ///
    /// This is an alternative to {approve} that can be used as a mitigation for the problems described above.
    ///
    /// Requirements:
    ///
    /// - `spender` cannot be the zero address.
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    /// @notice Moves `amount` tokens from the caller's account to `recipient`.
    ///
    /// @dev Emits a {Transfer} event.
    ///
    /// Requirements:
    ///
    /// - `recipient` cannot be the zero address.
    /// - The caller must have a balance of at least `amount`.
    ///
    /// @return a boolean value indicating whether the operation succeeded.
    function transfer(address recipient, uint256 amount) external returns (bool);

    /// @notice Moves `amount` tokens from `sender` to `recipient` using the allowance mechanism. `amount`
    /// `is then deducted from the caller's allowance.
    ///
    /// @dev Emits a {Transfer} event and an {Approval} event indicating the updated allowance. This is
    /// not required by the Erc. See the note at the beginning of {Erc20}.
    ///
    /// Requirements:
    ///
    /// - `sender` and `recipient` cannot be the zero address.
    /// - `sender` must have a balance of at least `amount`.
    /// - The caller must have approed `sender` to spent at least `amount` tokens.
    ///
    /// @return a boolean value indicating whether the operation succeeded.
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./TicketBooth.sol";

/** 
  @notice
  ERC20 wrapper for TicketBooth calls that return both staked + unstaked for a project's token supply.
*/
contract TokenRepresentationProxy is ERC20 {
    ITicketBooth ticketBooth;
    uint256 projectId;

    constructor(
        ITicketBooth _ticketBooth,
        uint256 _projectId,
        string memory name,
        string memory ticker
    ) ERC20(name, ticker) {
        ticketBooth = _ticketBooth;
        projectId = _projectId;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return ticketBooth.totalSupplyOf(projectId);
    }

    function balanceOf(address _account) public view virtual override returns (uint256) {
        return ticketBooth.balanceOf(_account, projectId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@paulrberg/contracts/math/PRBMath.sol";

import "./interfaces/IYielder.sol";
import "./interfaces/ITerminalV1.sol";
import "./interfaces/IyVaultV2.sol";
import "./interfaces/IWETH.sol";

contract YearnYielder is IYielder, Ownable {
    using SafeERC20 for IERC20;

    IyVaultV2 public wethVault =
        IyVaultV2(0xa9fE4601811213c340e850ea305481afF02f5b28);

    address public weth;

    uint256 public override deposited = 0;

    uint256 public decimals;

    constructor(address _weth) {
        require(wethVault.token() == _weth, "YearnYielder: INCOMPATIBLE");
        weth = _weth;
        decimals = IWETH(weth).decimals();
        updateApproval();
    }

    function getCurrentBalance() public view override returns (uint256) {
        return _sharesToTokens(wethVault.balanceOf(address(this)));
    }

    function deposit() external payable override onlyOwner {
        IWETH(weth).deposit{value: msg.value}();
        wethVault.deposit(msg.value);
        deposited = deposited + msg.value;
    }

    function withdraw(uint256 _amount, address payable _beneficiary)
        public
        override
        onlyOwner
    {
        // Reduce the proportional amount that has been deposited before the withdrawl.
        deposited =
            deposited -
            PRBMath.mulDiv(_amount, deposited, getCurrentBalance());

        // Withdraw the amount of tokens from the vault.
        wethVault.withdraw(_tokensToShares(_amount));

        // Convert weth back to eth.
        IWETH(weth).withdraw(_amount);

        // Move the funds to the TerminalV1.
        _beneficiary.transfer(_amount);
    }

    function withdrawAll(address payable _beneficiary)
        external
        override
        onlyOwner
        returns (uint256 _balance)
    {
        _balance = getCurrentBalance();
        withdraw(_balance, _beneficiary);
    }

    /// @dev Updates the vaults approval of the token to be the maximum value.
    function updateApproval() public {
        IERC20(weth).safeApprove(address(wethVault), type(uint256).max);
    }

    /// @dev Computes the number of tokens an amount of shares is worth.
    ///
    /// @param _sharesAmount the amount of shares.
    ///
    /// @return the number of tokens the shares are worth.
    function _sharesToTokens(uint256 _sharesAmount)
        private
        view
        returns (uint256)
    {
        return
            PRBMath.mulDiv(
                _sharesAmount,
                wethVault.pricePerShare(),
                10**decimals
            );
    }

    /// @dev Computes the number of shares an amount of tokens is worth.
    ///
    /// @param _tokensAmount the amount of shares.
    ///
    /// @return the number of shares the tokens are worth.
    function _tokensToShares(uint256 _tokensAmount)
        private
        view
        returns (uint256)
    {
        return
            PRBMath.mulDiv(
                _tokensAmount,
                10**decimals,
                wethVault.pricePerShare()
            );
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
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IyVaultV2 is IERC20 {
    function token() external view returns (address);

    function deposit() external returns (uint256);

    function deposit(uint256) external returns (uint256);

    function deposit(uint256, address) external returns (uint256);

    function withdraw() external returns (uint256);

    function withdraw(uint256) external returns (uint256);

    function withdraw(uint256, address) external returns (uint256);

    function withdraw(
        uint256,
        address,
        uint256
    ) external returns (uint256);

    function permit(
        address,
        address,
        uint256,
        uint256,
        bytes32
    ) external view returns (bool);

    function pricePerShare() external view returns (uint256);

    function apiVersion() external view returns (string memory);

    function totalAssets() external view returns (uint256);

    function maxAvailableShares() external view returns (uint256);

    function debtOutstanding() external view returns (uint256);

    function debtOutstanding(address strategy) external view returns (uint256);

    function creditAvailable() external view returns (uint256);

    function creditAvailable(address strategy) external view returns (uint256);

    function availableDepositLimit() external view returns (uint256);

    function expectedReturn() external view returns (uint256);

    function expectedReturn(address strategy) external view returns (uint256);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint256);

    function balanceOf(address owner) external view override returns (uint256);

    function totalSupply() external view override returns (uint256);

    function governance() external view returns (address);

    function management() external view returns (address);

    function guardian() external view returns (address);

    function guestList() external view returns (address);

    function strategies(address)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );

    function withdrawalQueue(uint256) external view returns (address);

    function emergencyShutdown() external view returns (bool);

    function depositLimit() external view returns (uint256);

    function debtRatio() external view returns (uint256);

    function totalDebt() external view returns (uint256);

    function lastReport() external view returns (uint256);

    function activation() external view returns (uint256);

    function rewards() external view returns (address);

    function managementFee() external view returns (uint256);

    function performanceFee() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IWETH {
    function decimals() external view returns (uint256);

    function deposit() external payable;

    function withdraw(uint256 wad) external;

    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./interfaces/ITerminal.sol";
import "./interfaces/ITerminalDirectory.sol";
import "./interfaces/IProjects.sol";

import "./abstract/Operatable.sol";

import "./libraries/Operations.sol";

import "./DirectPaymentAddress.sol";

/**
  @notice
  Allows project owners to deploy proxy contracts that can pay them when receiving funds directly.
*/
contract TerminalDirectory is ITerminalDirectory, Operatable {
    // --- private stored properties --- //

    // A list of contracts for each project ID that can receive funds directly.
    mapping(uint256 => IDirectPaymentAddress[]) private _addressesOf;

    // --- public immutable stored properties --- //

    /// @notice The Projects contract which mints ERC-721's that represent project ownership and transfers.
    IProjects public immutable override projects;

    // --- public stored properties --- //

    /// @notice For each project ID, the juicebox terminal that the direct payment addresses are proxies for.
    mapping(uint256 => ITerminal) public override terminalOf;

    /// @notice For each address, the address that will be used as the beneficiary of direct payments made.
    mapping(address => address) public override beneficiaryOf;

    /// @notice For each address, the preference of whether ticket will be auto claimed as ERC20s when a payment is made.
    mapping(address => bool) public override unstakedTicketsPreferenceOf;

    // --- external views --- //

    /** 
      @notice 
      A list of all direct payment addresses for the specified project ID.

      @param _projectId The ID of the project to get direct payment addresses for.

      @return A list of direct payment addresses for the specified project ID.
    */
    function addressesOf(uint256 _projectId)
        external
        view
        override
        returns (IDirectPaymentAddress[] memory)
    {
        return _addressesOf[_projectId];
    }

    // --- external transactions --- //

    /** 
      @param _projects A Projects contract which mints ERC-721's that represent project ownership and transfers.
      @param _operatorStore A contract storing operator assignments.
    */
    constructor(IProjects _projects, IOperatorStore _operatorStore)
        Operatable(_operatorStore)
    {
        projects = _projects;
    }

    /** 
      @notice 
      Allows anyone to deploy a new direct payment address for a project.

      @param _projectId The ID of the project to deploy a direct payment address for.
      @param _memo The note to use for payments made through the new direct payment address.
    */
    function deployAddress(uint256 _projectId, string calldata _memo)
        external
        override
    {
        require(
            _projectId > 0,
            "TerminalDirectory::deployAddress: ZERO_PROJECT"
        );

        // Deploy the contract and push it to the list.
        _addressesOf[_projectId].push(
            new DirectPaymentAddress(this, _projectId, _memo)
        );

        emit DeployAddress(_projectId, _memo, msg.sender);
    }

    /** 
      @notice 
      Update the juicebox terminal that payments to direct payment addresses will be forwarded for the specified project ID.

      @param _projectId The ID of the project to set a new terminal for.
      @param _terminal The new terminal to set.
    */
    function setTerminal(uint256 _projectId, ITerminal _terminal)
        external
        override
    {
        // Get a reference to the current terminal being used.
        ITerminal _currentTerminal = terminalOf[_projectId];

        address _projectOwner = projects.ownerOf(_projectId);

        // Either:
        // - case 1: the current terminal hasn't been set yet and the msg sender is either the projects contract or the terminal being set.
        // - case 2: the current terminal must not yet be set, or the current terminal is setting a new terminal.
        // - case 3: the msg sender is the owner or operator and either the current terminal hasn't been set, or the current terminal allows migration to the terminal being set.
        require(
            // case 1.
            (_currentTerminal == ITerminal(address(0)) &&
                (msg.sender == address(projects) ||
                    msg.sender == address(_terminal))) ||
                // case 2.
                msg.sender == address(_currentTerminal) ||
                // case 3.
                ((msg.sender == _projectOwner ||
                    operatorStore.hasPermission(
                        msg.sender,
                        _projectOwner,
                        _projectId,
                        Operations.SetTerminal
                    )) &&
                    (_currentTerminal == ITerminal(address(0)) ||
                        _currentTerminal.migrationIsAllowed(_terminal))),
            "TerminalDirectory::setTerminal: UNAUTHORIZED"
        );

        // The project must exist.
        require(
            projects.exists(_projectId),
            "TerminalDirectory::setTerminal: NOT_FOUND"
        );

        // Can't set the zero address.
        require(
            _terminal != ITerminal(address(0)),
            "TerminalDirectory::setTerminal: ZERO_ADDRESS"
        );

        // If the terminal is already set, nothing to do.
        if (_currentTerminal == _terminal) return;

        // Set the new terminal.
        terminalOf[_projectId] = _terminal;

        emit SetTerminal(_projectId, _terminal, msg.sender);
    }

    /** 
      @notice 
      Allows any address to pre set the beneficiary of their payments to any direct payment address,
      and to pre set whether to prefer to unstake tickets into ERC20's when making a payment.

      @param _beneficiary The beneficiary to set.
      @param _preferUnstakedTickets The preference to set.
    */
    function setPayerPreferences(
        address _beneficiary,
        bool _preferUnstakedTickets
    ) external override {
        beneficiaryOf[msg.sender] = _beneficiary;
        unstakedTicketsPreferenceOf[msg.sender] = _preferUnstakedTickets;

        emit SetPayerPreferences(
            msg.sender,
            _beneficiary,
            _preferUnstakedTickets
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./interfaces/IDirectPaymentAddress.sol";
import "./interfaces/ITerminalDirectory.sol";

/** 
  @notice
  A contract that can receive funds directly and forward to a project's current terminal.
*/
contract DirectPaymentAddress is IDirectPaymentAddress {
    // --- public immutable stored properties --- //

    /// @notice The directory to use when resolving which terminal to send the payment to.
    ITerminalDirectory public immutable override terminalDirectory;

    /// @notice The ID of the project to pay when this contract receives funds.
    uint256 public immutable override projectId;

    // --- public stored properties --- //

    /// @notice The memo to use when this contract forwards a payment to a terminal.
    string public override memo;

    // --- external transactions --- //

    /** 
      @param _terminalDirectory A directory of a project's current Juicebox terminal to receive payments in.
      @param _projectId The ID of the project to pay when this contract receives funds.
      @param _memo The memo to use when this contract forwards a payment to a terminal.
    */
    constructor(
        ITerminalDirectory _terminalDirectory,
        uint256 _projectId,
        string memory _memo
    ) {
        terminalDirectory = _terminalDirectory;
        projectId = _projectId;
        memo = _memo;
    }

    // Receive funds and make a payment to the project's current terminal.
    receive() external payable {
        // Check to see if the sender has configured a beneficiary.
        address _storedBeneficiary = terminalDirectory.beneficiaryOf(
            msg.sender
        );
        // If no beneficiary is configured, use the sender's address.
        address _beneficiary = _storedBeneficiary != address(0)
            ? _storedBeneficiary
            : msg.sender;

        bool _preferUnstakedTickets = terminalDirectory
        .unstakedTicketsPreferenceOf(msg.sender);

        terminalDirectory.terminalOf(projectId).pay{value: msg.value}(
            projectId,
            _beneficiary,
            memo,
            _preferUnstakedTickets
        );

        emit Forward(
            msg.sender,
            projectId,
            _beneficiary,
            msg.value,
            memo,
            _preferUnstakedTickets
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./interfaces/ITicketBooth.sol";
import "./interfaces/ITerminalDirectory.sol";
import "./interfaces/IProxyPaymentAddress.sol";
import "./interfaces/IProxyPaymentAddressManager.sol";

import "./ProxyPaymentAddress.sol";

/** 
  @notice
  Manages deploying proxy payment addresses for Juicebox projects.
*/
contract ProxyPaymentAddressManager is IProxyPaymentAddressManager {
    // --- private stored properties --- //

    // A mapping from project id to proxy payment addresses.
    mapping(uint256 => IProxyPaymentAddress[]) private _addressesOf;

    // --- public immutable stored properties --- //

    /// @notice The directory that will be injected into proxy payment addresses.
    ITerminalDirectory public immutable override terminalDirectory;

    /// @notice The ticket boot that will be injected into proxy payment addresses.
    ITicketBooth public immutable override ticketBooth;

    constructor(
        ITerminalDirectory _terminalDirectory,
        ITicketBooth _ticketBooth
    ) {
        terminalDirectory = _terminalDirectory;
        ticketBooth = _ticketBooth;
    }

    /** 
      @notice 
      A list of all proxy payment addresses for the specified project ID.

      @param _projectId The ID of the project to get proxy payment addresses for.

      @return A list of proxy payment addresses for the specified project ID.
    */
    function addressesOf(uint256 _projectId)
        external
        view
        override
        returns (IProxyPaymentAddress[] memory)
    {
        return _addressesOf[_projectId];
    }    

    /** 
      @notice Deploys a proxy payment address.
      @param _projectId ID of the project funds will be fowarded to.
      @param _memo Memo that will be attached withdrawal transactions.
    */
    function deploy(uint256 _projectId, string memory _memo) external override returns(address) {
        require(
            _projectId > 0,
            "ProxyPaymentAddressManager::deploy: ZERO_PROJECT"
        );

        // Create the proxy payment address contract.
        ProxyPaymentAddress proxyPaymentAddress = new ProxyPaymentAddress(
            terminalDirectory,
            ticketBooth,
            _projectId,
            _memo
        );

        // Transfer ownership to the caller of this tx.
        proxyPaymentAddress.transferOwnership(msg.sender);

        // Push it to the list for the corresponding project.
        _addressesOf[_projectId].push(proxyPaymentAddress);

        emit Deploy(_projectId, _memo, msg.sender);

        // Return the address of the proxy payment address.
        return address(proxyPaymentAddress);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ITerminalDirectory.sol";
import "./ITicketBooth.sol";

interface IProxyPaymentAddress {

    event Receive(
        address indexed caller,
        uint256 value
    );

    event Tap(
        address indexed caller,
        uint256 value
    );

    event TransferTickets(
        address indexed caller,
        address indexed beneficiary,
        uint256 indexed projectId,
        uint256 amount
    );

    function terminalDirectory() external returns (ITerminalDirectory);

    function ticketBooth() external returns (ITicketBooth);

    function projectId() external returns (uint256);

    function memo() external returns (string memory);

    function tap() external;

    function transferTickets(address _beneficiary, uint256 _amount) external;

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ITerminalDirectory.sol";
import "./ITicketBooth.sol";
import "./IProxyPaymentAddress.sol";

interface IProxyPaymentAddressManager {

    event Deploy(
        uint256 indexed projectId,
        string memo,
        address indexed caller
    );       

    function terminalDirectory() external returns (ITerminalDirectory);

    function ticketBooth() external returns (ITicketBooth);

    function addressesOf(uint256 _projectId)
        external
        view
        returns (IProxyPaymentAddress[] memory);    

    function deploy(uint256 _projectId, string memory _memo) external returns(address);

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IProxyPaymentAddress.sol";
import "./interfaces/ITerminalDirectory.sol";
import "./interfaces/ITicketBooth.sol";

/** 
  @notice
  A contract that can receive and hold funds for a given project.
  Once funds are tapped, tickets are printed and can be transferred out of the contract at a later date.

  Particularly useful for routing funds from third-party platforms (e.g., Open Sea).
*/
contract ProxyPaymentAddress is IProxyPaymentAddress, Ownable {
    // --- public immutable stored properties --- //

    /// @notice The directory to use when resolving which terminal to send the payment to.
    ITerminalDirectory public immutable override terminalDirectory;

    /// @notice The ticket booth to use when transferring tickets held by this contract to a beneficiary.
    ITicketBooth public immutable override ticketBooth;

    /// @notice The ID of the project tickets should be redeemed for.
    uint256 public immutable override projectId;

    /// @notice The memo to use when this contract forwards a payment to a terminal.
    string public override memo;

    constructor(
        ITerminalDirectory _terminalDirectory,
        ITicketBooth _ticketBooth,
        uint256 _projectId,
        string memory _memo
    ) {
        terminalDirectory = _terminalDirectory;
        ticketBooth = _ticketBooth;
        projectId = _projectId;
        memo = _memo;
    }

    // Receive funds and hold them in the contract until they are ready to be transferred.
    receive() external payable { 
        emit Receive(
            msg.sender,
            msg.value
        );
    }

    // Transfers all funds held in the contract to the terminal of the corresponding project.
    function tap() external override {
        uint256 amount = address(this).balance;

        terminalDirectory.terminalOf(projectId).pay{value: amount}(
            projectId,
            /*_beneficiary=*/address(this),
            memo,
            /*_preferUnstakedTickets=*/false
        );

        emit Tap(
            msg.sender,
            amount
        ); 
    }

    /** 
      @notice Transfers tickets held by this contract to a beneficiary.
      @param _beneficiary Address of the beneficiary tickets will be transferred to.
    */
    function transferTickets(address _beneficiary, uint256 _amount) external override onlyOwner {
        ticketBooth.transfer(
            address(this),
            projectId,
            _amount,
            _beneficiary
        );

        emit TransferTickets(
            msg.sender,
            _beneficiary,
            projectId,
            _amount
        );            
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./interfaces/IOperatorStore.sol";

/** 
  @notice
  Addresses can give permissions to any other address to take specific actions 
  throughout the Juicebox ecosystem on their behalf. These addresses are called `operators`.
  
  @dev
  Permissions are stored as a uint256, with each boolean bit representing whether or not
  an oporator has the permission identified by that bit's index in the 256 bit uint256.
  Indexes must be between 0 and 255.

  The directory of permissions, along with how they uniquely mapp to indexes, are managed externally.
  This contract doesn't know or care about specific permissions and their indexes.
*/
contract OperatorStore is IOperatorStore {
    // --- public stored properties --- //

    /** 
      @notice
      The permissions that an operator has to operate on a specific domain.
      
      @dev
      An account can give an operator permissions that only pertain to a specific domain.
      There is no domain with an ID of 0 -- accounts can use the 0 domain to give an operator
      permissions to operator on their personal behalf.
    */
    mapping(address => mapping(address => mapping(uint256 => uint256)))
        public
        override permissionsOf;

    // --- public views --- //

    /** 
      @notice 
      Whether or not an operator has the permission to take a certain action pertaining to the specified domain.

      @param _operator The operator to check.
      @param _account The account that has given out permission to the operator.
      @param _domain The domain that the operator has been given permissions to operate.
      @param _permissionIndex the permission to check for.

      @return Whether the operator has the specified permission.
    */
    function hasPermission(
        address _operator,
        address _account,
        uint256 _domain,
        uint256 _permissionIndex
    ) external view override returns (bool) {
        require(
            _permissionIndex <= 255,
            "OperatorStore::hasPermission: INDEX_OUT_OF_BOUNDS"
        );
        return
            ((permissionsOf[_operator][_account][_domain] >> _permissionIndex) &
                1) == 1;
    }

    /** 
      @notice 
      Whether or not an operator has the permission to take certain actions pertaining to the specified domain.

      @param _operator The operator to check.
      @param _account The account that has given out permissions to the operator.
      @param _domain The domain that the operator has been given permissions to operate.
      @param _permissionIndexes An array of permission indexes to check for.

      @return Whether the operator has all specified permissions.
    */
    function hasPermissions(
        address _operator,
        address _account,
        uint256 _domain,
        uint256[] calldata _permissionIndexes
    ) external view override returns (bool) {
        for (uint256 _i = 0; _i < _permissionIndexes.length; _i++) {
            uint256 _permissionIndex = _permissionIndexes[_i];

            require(
                _permissionIndex <= 255,
                "OperatorStore::hasPermissions: INDEX_OUT_OF_BOUNDS"
            );

            if (
                ((permissionsOf[_operator][_account][_domain] >>
                    _permissionIndex) & 1) == 0
            ) return false;
        }
        return true;
    }

    // --- external transactions --- //

    /** 
      @notice 
      Sets permissions for an operator.

      @param _operator The operator to give permission to.
      @param _domain The domain that the operator is being given permissions to operate.
      @param _permissionIndexes An array of indexes of permissions to set.
    */
    function setOperator(
        address _operator,
        uint256 _domain,
        uint256[] calldata _permissionIndexes
    ) external override {
        // Pack the indexes into a uint256.
        uint256 _packed = _packedPermissions(_permissionIndexes);

        // Store the new value.
        permissionsOf[_operator][msg.sender][_domain] = _packed;

        emit SetOperator(
            _operator,
            msg.sender,
            _domain,
            _permissionIndexes,
            _packed
        );
    }

    /** 
      @notice 
      Sets permissions for many operators.

      @param _operators The operators to give permission to.
      @param _domains The domains that can be operated. Set to 0 to allow operation of account level actions.
      @param _permissionIndexes The level of power each operator should have.
    */
    function setOperators(
        address[] calldata _operators,
        uint256[] calldata _domains,
        uint256[][] calldata _permissionIndexes
    ) external override {
        // There should be a level for each operator provided.
        require(
            _operators.length == _permissionIndexes.length &&
                _operators.length == _domains.length,
            "OperatorStore::setOperators: BAD_ARGS"
        );
        for (uint256 _i = 0; _i < _operators.length; _i++) {
            // Pack the indexes into a uint256.
            uint256 _packed = _packedPermissions(_permissionIndexes[_i]);
            // Store the new value.
            permissionsOf[_operators[_i]][msg.sender][_domains[_i]] = _packed;
            emit SetOperator(
                _operators[_i],
                msg.sender,
                _domains[_i],
                _permissionIndexes[_i],
                _packed
            );
        }
    }

    // --- private helper functions --- //

    /** 
      @notice 
      Converts an array of permission indexes to a packed int.

      @param _indexes The indexes of the permissions to pack.

      @return packed The packed result.
    */
    function _packedPermissions(uint256[] calldata _indexes)
        private
        pure
        returns (uint256 packed)
    {
        for (uint256 _i = 0; _i < _indexes.length; _i++) {
            uint256 _permissionIndex = _indexes[_i];
            require(
                _permissionIndex <= 255,
                "OperatorStore::_packedPermissions: INDEX_OUT_OF_BOUNDS"
            );
            // Turn the bit at the index on.
            packed |= 1 << _permissionIndex;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "./abstract/Operatable.sol";
import "./interfaces/IProjects.sol";

import "./libraries/Operations.sol";

/** 
  @notice 
  Stores project ownership and identifying information.

  @dev
  Projects are represented as ERC-721's.
*/
contract Projects is ERC721, IProjects, Operatable {
    // --- private stored properties --- //

    // The number of seconds in a day.
    uint256 private constant SECONDS_IN_YEAR = 31536000;

    // --- public stored properties --- //

    /// @notice A running count of project IDs.
    uint256 public override count = 0;

    /// @notice Optional mapping for project URIs
    mapping(uint256 => string) public override uriOf;

    /// @notice Each project's handle.
    mapping(uint256 => bytes32) public override handleOf;

    /// @notice The project that each unique handle represents.
    mapping(bytes32 => uint256) public override projectFor;

    /// @notice Handles that have been transfered to the specified address.
    mapping(bytes32 => address) public override transferAddressFor;

    /// @notice The timestamps when each handle is claimable. A value of 0 means a handle isn't being challenged.
    mapping(bytes32 => uint256) public override challengeExpiryOf;

    // --- external views --- //

    /** 
      @notice 
      Whether the specified project exists.

      @param _projectId The project to check the existence of.

      @return A flag indicating if the project exists.
    */
    function exists(uint256 _projectId) external view override returns (bool) {
        return _exists(_projectId);
    }

    // --- external transactions --- //

    /** 
      @param _operatorStore A contract storing operator assignments.
    */
    constructor(IOperatorStore _operatorStore)
        ERC721("Juicebox project", "JUICEBOX PROJECT")
        Operatable(_operatorStore)
    {}

    /**
        @notice 
        Create a new project.

        @dev 
        Anyone can create a project on an owner's behalf.

        @param _owner The owner of the project.
        @param _handle A unique handle for the project.
        @param _uri An ipfs CID to more info about the project.
        @param _terminal The terminal to set for this project so that it can start receiving payments.

        @return The new project's ID.
    */
    function create(
        address _owner,
        bytes32 _handle,
        string calldata _uri,
        ITerminal _terminal
    ) external override returns (uint256) {
        // Handle must exist.
        require(_handle != bytes32(0), "Projects::create: EMPTY_HANDLE");

        // Handle must be unique.
        require(
            projectFor[_handle] == 0 &&
                transferAddressFor[_handle] == address(0),
            "Projects::create: HANDLE_TAKEN"
        );

        // Increment the count, which will be used as the ID.
        count++;

        // Mint the project.
        _safeMint(_owner, count);

        // Set the handle stored values.
        handleOf[count] = _handle;
        projectFor[_handle] = count;

        // Set the URI if one was provided.
        if (bytes(_uri).length > 0) uriOf[count] = _uri;

        // Set the project's terminal if needed.
        if (_terminal != ITerminal(address(0)))
            _terminal.terminalDirectory().setTerminal(count, _terminal);

        emit Create(count, _owner, _handle, _uri, _terminal, msg.sender);

        return count;
    }

    /**
      @notice 
      Allows a project owner to set the project's handle.

      @dev 
      Only a project's owner or operator can set its handle.

      @param _projectId The ID of the project.
      @param _handle The new unique handle for the project.
    */
    function setHandle(uint256 _projectId, bytes32 _handle)
        external
        override
        requirePermission(ownerOf(_projectId), _projectId, Operations.SetHandle)
    {
        // Handle must exist.
        require(_handle != bytes32(0), "Projects::setHandle: EMPTY_HANDLE");

        // Handle must be unique.
        require(
            projectFor[_handle] == 0 &&
                transferAddressFor[_handle] == address(0),
            "Projects::setHandle: HANDLE_TAKEN"
        );

        // Register the change in the resolver.
        projectFor[handleOf[_projectId]] = 0;

        projectFor[_handle] = _projectId;
        handleOf[_projectId] = _handle;

        emit SetHandle(_projectId, _handle, msg.sender);
    }

    /**
      @notice 
      Allows a project owner to set the project's uri.

      @dev 
      Only a project's owner or operator can set its uri.

      @param _projectId The ID of the project.
      @param _uri An ipfs CDN to more info about the project. Don't include the leading ipfs://
    */
    function setUri(uint256 _projectId, string calldata _uri)
        external
        override
        requirePermission(ownerOf(_projectId), _projectId, Operations.SetUri)
    {
        // Set the new uri.
        uriOf[_projectId] = _uri;

        emit SetUri(_projectId, _uri, msg.sender);
    }

    /**
      @notice 
      Allows a project owner to transfer its handle to another address.

      @dev 
      Only a project's owner or operator can transfer its handle.

      @param _projectId The ID of the project to transfer the handle from.
      @param _to The address that can now reallocate the handle.
      @param _newHandle The new unique handle for the project that will replace the transfered one.
    */
    function transferHandle(
        uint256 _projectId,
        address _to,
        bytes32 _newHandle
    )
        external
        override
        requirePermission(ownerOf(_projectId), _projectId, Operations.SetHandle)
        returns (bytes32 _handle)
    {
        require(
            _newHandle != bytes32(0),
            "Projects::transferHandle: EMPTY_HANDLE"
        );

        require(
            projectFor[_newHandle] == 0 &&
                transferAddressFor[_handle] == address(0),
            "Projects::transferHandle: HANDLE_TAKEN"
        );

        // Get a reference to the project's currency handle.
        _handle = handleOf[_projectId];

        // Remove the resolver for the transfered handle.
        projectFor[_handle] = 0;

        // If the handle is changing, register the change in the resolver.
        projectFor[_newHandle] = _projectId;
        handleOf[_projectId] = _newHandle;

        // Transfer the current handle.
        transferAddressFor[_handle] = _to;

        emit TransferHandle(_projectId, _to, _handle, _newHandle, msg.sender);
    }

    /**
      @notice 
      Allows an address to claim and handle that has been transfered to them and apply it to a project of theirs.

      @dev 
      Only a project's owner or operator can claim a handle onto it.

      @param _handle The handle being claimed.
      @param _for The address that the handle has been transfered to.
      @param _projectId The ID of the project to use the claimed handle.
    */
    function claimHandle(
        bytes32 _handle,
        address _for,
        uint256 _projectId
    )
        external
        override
        requirePermissionAllowingWildcardDomain(
            _for,
            _projectId,
            Operations.ClaimHandle
        )
        requirePermission(
            ownerOf(_projectId),
            _projectId,
            Operations.ClaimHandle
        )
    {
        // The handle must have been transfered to the specified address,
        // or the handle challange must have expired before being renewed.
        require(
            transferAddressFor[_handle] == _for ||
                (challengeExpiryOf[_handle] > 0 &&
                    block.timestamp > challengeExpiryOf[_handle]),
            "Projects::claimHandle: UNAUTHORIZED"
        );

        // Register the change in the resolver.
        projectFor[handleOf[_projectId]] = 0;

        // Register the change in the resolver.
        projectFor[_handle] = _projectId;

        // Set the new handle.
        handleOf[_projectId] = _handle;

        // Set the handle as not being transfered.
        transferAddressFor[_handle] = address(0);

        // Reset the challenge to 0.
        challengeExpiryOf[_handle] = 0;

        emit ClaimHandle(_for, _projectId, _handle, msg.sender);
    }

    /** 
      @notice
      Allows anyone to challenge a project's handle. After one year, the handle can be claimed by the public if the challenge isn't answered by the handle's project.
      This can be used to make sure a handle belonging to an unattended to project isn't lost forever.

      @param _handle The handle to challenge.
    */
    function challengeHandle(bytes32 _handle) external {
        // No need to challenge a handle that's not taken.
        require(
            projectFor[_handle] > 0,
            "Projects::challenge: HANDLE_NOT_TAKEN"
        );

        // No need to challenge again if a handle is already being challenged.
        require(
            challengeExpiryOf[_handle] == 0,
            "Projects::challenge: HANDLE_ALREADY_BEING_CHALLENGED"
        );

        // The challenge will expire in a year, at which point the handle can be claimed if the challenge hasn't been answered.
        uint256 _challengeExpiry = block.timestamp + SECONDS_IN_YEAR;

        challengeExpiryOf[_handle] = _challengeExpiry;

        emit ChallengeHandle(_handle, _challengeExpiry, msg.sender);
    }

    /** 
      @notice
      Allows a project to renew its handle so it can't be claimed until a year after its challenged again.

      @dev 
      Only a project's owner or operator can renew its handle.

      @param _projectId The ID of the project that current has the handle being renewed.
    */
    function renewHandle(uint256 _projectId)
        external
        requirePermission(
            ownerOf(_projectId),
            _projectId,
            Operations.RenewHandle
        )
    {
        // Get the handle of the project.
        bytes32 _handle = handleOf[_projectId];

        // Reset the challenge to 0.
        challengeExpiryOf[_handle] = 0;

        emit RenewHandle(_handle, _projectId, msg.sender);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./interfaces/IModStore.sol";
import "./abstract/Operatable.sol";
import "./abstract/TerminalUtility.sol";

import "./libraries/Operations.sol";

/**
  @notice
  Stores mods for each project.

  @dev
  Mods can be used to distribute a percentage of payments or tickets to preconfigured beneficiaries.
*/
contract ModStore is IModStore, Operatable, TerminalUtility {
    // --- private stored properties --- //

    // All payout mods for each project ID's configurations.
    mapping(uint256 => mapping(uint256 => PayoutMod[])) private _payoutModsOf;

    // All ticket mods for each project ID's configurations.
    mapping(uint256 => mapping(uint256 => TicketMod[])) private _ticketModsOf;

    // --- public immutable stored properties --- //

    /// @notice The contract storing project information.
    IProjects public immutable override projects;

    // --- public views --- //

    /**
      @notice 
      Get all payout mods for the specified project ID.

      @param _projectId The ID of the project to get mods for.
      @param _configuration The configuration to get mods for.

      @return An array of all mods for the project.
     */
    function payoutModsOf(uint256 _projectId, uint256 _configuration)
        external
        view
        override
        returns (PayoutMod[] memory)
    {
        return _payoutModsOf[_projectId][_configuration];
    }

    /**
      @notice 
      Get all ticket mods for the specified project ID.

      @param _projectId The ID of the project to get mods for.
      @param _configuration The configuration to get mods for.

      @return An array of all mods for the project.
     */
    function ticketModsOf(uint256 _projectId, uint256 _configuration)
        external
        view
        override
        returns (TicketMod[] memory)
    {
        return _ticketModsOf[_projectId][_configuration];
    }

    // --- external transactions --- //

    /** 
      @param _projects The contract storing project information
      @param _operatorStore A contract storing operator assignments.
      @param _terminalDirectory A directory of a project's current Juicebox terminal to receive payments in.
    */
    constructor(
        IProjects _projects,
        IOperatorStore _operatorStore,
        ITerminalDirectory _terminalDirectory
    ) Operatable(_operatorStore) TerminalUtility(_terminalDirectory) {
        projects = _projects;
    }

    /** 
      @notice 
      Adds a mod to the payout mods list.

      @dev
      Only the owner or operator of a project can make this call, or the current terminal of the project.

      @param _projectId The project to add a mod to.
      @param _configuration The configuration to set the mods to be active during.
      @param _mods The payout mods to set.
    */
    function setPayoutMods(
        uint256 _projectId,
        uint256 _configuration,
        PayoutMod[] memory _mods
    )
        external
        override
        requirePermissionAcceptingAlternateAddress(
            projects.ownerOf(_projectId),
            _projectId,
            Operations.SetPayoutMods,
            address(terminalDirectory.terminalOf(_projectId))
        )
    {
        // There must be something to do.
        require(_mods.length > 0, "ModStore::setPayoutMods: NO_OP");

        // Get a reference to the project's payout mods.
        PayoutMod[] memory _currentMods = _payoutModsOf[_projectId][
            _configuration
        ];

        // Check to see if all locked Mods are included.
        for (uint256 _i = 0; _i < _currentMods.length; _i++) {
            if (block.timestamp < _currentMods[_i].lockedUntil) {
                bool _includesLocked = false;
                for (uint256 _j = 0; _j < _mods.length; _j++) {
                    // Check for sameness. Let the note change.
                    if (
                        _mods[_j].percent == _currentMods[_i].percent &&
                        _mods[_j].beneficiary == _currentMods[_i].beneficiary &&
                        _mods[_j].allocator == _currentMods[_i].allocator &&
                        _mods[_j].projectId == _currentMods[_i].projectId &&
                        // Allow lock expention.
                        _mods[_j].lockedUntil >= _currentMods[_i].lockedUntil
                    ) _includesLocked = true;
                }
                require(
                    _includesLocked,
                    "ModStore::setPayoutMods: SOME_LOCKED"
                );
            }
        }

        // Delete from storage so mods can be repopulated.
        delete _payoutModsOf[_projectId][_configuration];

        // Add up all the percents to make sure they cumulative are under 100%.
        uint256 _payoutModPercentTotal = 0;

        for (uint256 _i = 0; _i < _mods.length; _i++) {
            // The percent should be greater than 0.
            require(
                _mods[_i].percent > 0,
                "ModStore::setPayoutMods: BAD_MOD_PERCENT"
            );

            // Add to the total percents.
            _payoutModPercentTotal = _payoutModPercentTotal + _mods[_i].percent;

            // The total percent should be less than 10000.
            require(
                _payoutModPercentTotal <= 10000,
                "ModStore::setPayoutMods: BAD_TOTAL_PERCENT"
            );

            // The allocator and the beneficiary shouldn't both be the zero address.
            require(
                _mods[_i].allocator != IModAllocator(address(0)) ||
                    _mods[_i].beneficiary != address(0),
                "ModStore::setPayoutMods: ZERO_ADDRESS"
            );

            // Push the new mod into the project's list of mods.
            _payoutModsOf[_projectId][_configuration].push(_mods[_i]);

            emit SetPayoutMod(
                _projectId,
                _configuration,
                _mods[_i],
                msg.sender
            );
        }
    }

    /** 
      @notice 
      Adds a mod to the ticket mods list.

      @dev
      Only the owner or operator of a project can make this call, or the current terminal of the project.

      @param _projectId The project to add a mod to.
      @param _configuration The configuration to set the mods to be active during.
      @param _mods The ticket mods to set.
    */
    function setTicketMods(
        uint256 _projectId,
        uint256 _configuration,
        TicketMod[] memory _mods
    )
        external
        override
        requirePermissionAcceptingAlternateAddress(
            projects.ownerOf(_projectId),
            _projectId,
            Operations.SetTicketMods,
            address(terminalDirectory.terminalOf(_projectId))
        )
    {
        // There must be something to do.
        require(_mods.length > 0, "ModStore::setTicketMods: NO_OP");

        // Get a reference to the project's ticket mods.
        TicketMod[] memory _projectTicketMods = _ticketModsOf[_projectId][
            _configuration
        ];

        // Check to see if all locked Mods are included.
        for (uint256 _i = 0; _i < _projectTicketMods.length; _i++) {
            if (block.timestamp < _projectTicketMods[_i].lockedUntil) {
                bool _includesLocked = false;
                for (uint256 _j = 0; _j < _mods.length; _j++) {
                    // Check for the same values.
                    if (
                        _mods[_j].percent == _projectTicketMods[_i].percent &&
                        _mods[_j].beneficiary ==
                        _projectTicketMods[_i].beneficiary &&
                        // Allow lock extensions.
                        _mods[_j].lockedUntil >=
                        _projectTicketMods[_i].lockedUntil
                    ) _includesLocked = true;
                }
                require(
                    _includesLocked,
                    "ModStore::setTicketMods: SOME_LOCKED"
                );
            }
        }
        // Delete from storage so mods can be repopulated.
        delete _ticketModsOf[_projectId][_configuration];

        // Add up all the percents to make sure they cumulative are under 100%.
        uint256 _ticketModPercentTotal = 0;

        for (uint256 _i = 0; _i < _mods.length; _i++) {
            // The percent should be greater than 0.
            require(
                _mods[_i].percent > 0,
                "ModStore::setTicketMods: BAD_MOD_PERCENT"
            );

            // Add to the total percents.
            _ticketModPercentTotal = _ticketModPercentTotal + _mods[_i].percent;
            // The total percent should be less than 10000.
            require(
                _ticketModPercentTotal <= 10000,
                "ModStore::setTicketMods: BAD_TOTAL_PERCENT"
            );

            // The beneficiary shouldn't be the zero address.
            require(
                _mods[_i].beneficiary != address(0),
                "ModStore::setTicketMods: ZERO_ADDRESS"
            );

            // Push the new mod into the project's list of mods.
            _ticketModsOf[_projectId][_configuration].push(_mods[_i]);

            emit SetTicketMod(
                _projectId,
                _configuration,
                _mods[_i],
                msg.sender
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@paulrberg/contracts/math/PRBMath.sol";

import "./interfaces/IFundingCycles.sol";
import "./interfaces/IPrices.sol";
import "./abstract/TerminalUtility.sol";

/** 
  @notice Manage funding cycle configurations, accounting, and scheduling.
*/
contract FundingCycles is TerminalUtility, IFundingCycles {
    // --- private stored contants --- //

    // The number of seconds in a day.
    uint256 private constant SECONDS_IN_DAY = 86400;

    // --- private stored properties --- //

    // Stores the reconfiguration properties of each funding cycle, packed into one storage slot.
    mapping(uint256 => uint256) private _packedConfigurationPropertiesOf;

    // Stores the properties added by the mechanism to manage and schedule each funding cycle, packed into one storage slot.
    mapping(uint256 => uint256) private _packedIntrinsicPropertiesOf;

    // Stores the metadata for each funding cycle, packed into one storage slot.
    mapping(uint256 => uint256) private _metadataOf;

    // Stores the amount that each funding cycle can tap funding cycle.
    mapping(uint256 => uint256) private _targetOf;

    // Stores the amount that has been tapped within each funding cycle.
    mapping(uint256 => uint256) private _tappedOf;

    // --- public stored constants --- //

    /// @notice The weight used for each project's first funding cycle.
    uint256 public constant override BASE_WEIGHT = 1E24;

    /// @notice The maximum value that a cycle limit can be set to.
    uint256 public constant override MAX_CYCLE_LIMIT = 32;

    // --- public stored properties --- //

    /// @notice The ID of the latest funding cycle for each project.
    mapping(uint256 => uint256) public override latestIdOf;

    /// @notice The total number of funding cycles created, which is used for issuing funding cycle IDs.
    /// @dev Funding cycles have IDs > 0.
    uint256 public override count = 0;

    // --- external views --- //

    /**
        @notice 
        Get the funding cycle with the given ID.

        @param _fundingCycleId The ID of the funding cycle to get.

        @return _fundingCycle The funding cycle.
    */
    function get(uint256 _fundingCycleId)
        external
        view
        override
        returns (FundingCycle memory)
    {
        // The funding cycle should exist.
        require(
            _fundingCycleId > 0 && _fundingCycleId <= count,
            "FundingCycle::get: NOT_FOUND"
        );

        return _getStruct(_fundingCycleId);
    }

    /**
        @notice 
        The funding cycle that's next up for a project, and therefor not currently accepting payments.

        @dev 
        This runs roughly similar logic to `_configurable`.

        @param _projectId The ID of the project being looked through.

        @return _fundingCycle The queued funding cycle.
    */
    function queuedOf(uint256 _projectId)
        external
        view
        override
        returns (FundingCycle memory)
    {
        // The project must have funding cycles.
        if (latestIdOf[_projectId] == 0) return _getStruct(0);

        // Get a reference to the standby funding cycle.
        uint256 _fundingCycleId = _standby(_projectId);

        // If it exists, return it.
        if (_fundingCycleId > 0) return _getStruct(_fundingCycleId);

        // Get a reference to the eligible funding cycle.
        _fundingCycleId = _eligible(_projectId);

        // If an eligible funding cycle exists...
        if (_fundingCycleId > 0) {
            // Get the necessary properties for the standby funding cycle.
            FundingCycle memory _fundingCycle = _getStruct(_fundingCycleId);

            // There's no queued if the current has a duration of 0.
            if (_fundingCycle.duration == 0) return _getStruct(0);

            // Check to see if the correct ballot is approved for this funding cycle.
            // If so, return a funding cycle based on it.
            if (_isApproved(_fundingCycle))
                return _mockFundingCycleBasedOn(_fundingCycle, false);

            // If it hasn't been approved, set the ID to be its base funding cycle, which carries the last approved configuration.
            _fundingCycleId = _fundingCycle.basedOn;
        } else {
            // No upcoming funding cycle found that is eligible to become active,
            // so use the ID of the latest active funding cycle, which carries the last approved configuration.
            _fundingCycleId = latestIdOf[_projectId];
        }

        // A funding cycle must exist.
        if (_fundingCycleId == 0) return _getStruct(0);

        // Return a mock of what its second next up funding cycle would be.
        // Use second next because the next would be a mock of the current funding cycle.
        return _mockFundingCycleBasedOn(_getStruct(_fundingCycleId), false);
    }

    /**
        @notice 
        The funding cycle that is currently active for the specified project.

        @dev 
        This runs very similar logic to `_tappable`.

        @param _projectId The ID of the project being looked through.

        @return fundingCycle The current funding cycle.
    */
    function currentOf(uint256 _projectId)
        external
        view
        override
        returns (FundingCycle memory fundingCycle)
    {
        // The project must have funding cycles.
        if (latestIdOf[_projectId] == 0) return _getStruct(0);

        // Check for an active funding cycle.
        uint256 _fundingCycleId = _eligible(_projectId);

        // If no active funding cycle is found, check if there is a standby funding cycle.
        // If one exists, it will become active one it has been tapped.
        if (_fundingCycleId == 0) _fundingCycleId = _standby(_projectId);

        // Keep a reference to the eligible funding cycle.
        FundingCycle memory _fundingCycle;

        // If a standy funding cycle exists...
        if (_fundingCycleId > 0) {
            // Get the necessary properties for the standby funding cycle.
            _fundingCycle = _getStruct(_fundingCycleId);

            // Check to see if the correct ballot is approved for this funding cycle, and that it has started.
            if (
                _fundingCycle.start <= block.timestamp &&
                _isApproved(_fundingCycle)
            ) return _fundingCycle;

            // If it hasn't been approved, set the ID to be the based funding cycle,
            // which carries the last approved configuration.
            _fundingCycleId = _fundingCycle.basedOn;
        } else {
            // No upcoming funding cycle found that is eligible to become active,
            // so us the ID of the latest active funding cycle, which carries the last approved configuration.
            _fundingCycleId = latestIdOf[_projectId];
        }

        // The funding cycle cant be 0.
        if (_fundingCycleId == 0) return _getStruct(0);

        // The funding cycle to base a current one on.
        _fundingCycle = _getStruct(_fundingCycleId);

        // Return a mock of what the next funding cycle would be like,
        // which would become active one it has been tapped.
        return _mockFundingCycleBasedOn(_fundingCycle, true);
    }

    /** 
      @notice 
      The currency ballot state of the project.

      @param _projectId The ID of the project to check for a pending reconfiguration.

      @return The current ballot's state.
    */
    function currentBallotStateOf(uint256 _projectId)
        external
        view
        override
        returns (BallotState)
    {
        // The project must have funding cycles.
        require(
            latestIdOf[_projectId] > 0,
            "FundingCycles::currentBallotStateOf: NOT_FOUND"
        );

        // Get a reference to the latest funding cycle ID.
        uint256 _fundingCycleId = latestIdOf[_projectId];

        // Get the necessary properties for the latest funding cycle.
        FundingCycle memory _fundingCycle = _getStruct(_fundingCycleId);

        // If the latest funding cycle is the first, or if it has already started, it must be approved.
        if (_fundingCycle.basedOn == 0) return BallotState.Standby;

        return
            _ballotState(
                _fundingCycleId,
                _fundingCycle.configured,
                _fundingCycle.basedOn
            );
    }

    // --- external transactions --- //

    /** 
      @param _terminalDirectory A directory of a project's current Juicebox terminal to receive payments in.
    */
    constructor(ITerminalDirectory _terminalDirectory)
        TerminalUtility(_terminalDirectory)
    {}

    /**
        @notice 
        Configures the next eligible funding cycle for the specified project.

        @dev
        Only a project's current terminal can configure its funding cycles.

        @param _projectId The ID of the project being reconfigured.
        @param _properties The funding cycle configuration.
          @dev _properties.target The amount that the project wants to receive in each funding cycle. 18 decimals.
          @dev _properties.currency The currency of the `_target`. Send 0 for ETH or 1 for USD.
          @dev _properties.duration The duration of the funding cycle for which the `_target` amount is needed. Measured in days. 
            Set to 0 for no expiry and to be able to reconfigure anytime.
          @dev _cycleLimit The number of cycles that this configuration should last for before going back to the last permanent. This does nothing for a project's first funding cycle.
          @dev _properties.discountRate A number from 0-200 indicating how valuable a contribution to this funding cycle is compared to previous funding cycles.
            If it's 0, each funding cycle will have equal weight.
            If the number is 100, a contribution to the next funding cycle will only give you 90% of tickets given to a contribution of the same amount during the current funding cycle.
            If the number is 200, a contribution to the next funding cycle will only give you 80% of tickets given to a contribution of the same amoutn during the current funding cycle.
            If the number is 201, an non-recurring funding cycle will get made.
          @dev _ballot The new ballot that will be used to approve subsequent reconfigurations.
        @param _metadata Data to associate with this funding cycle configuration.
        @param _fee The fee that this configuration will incure when tapping.
        @param _configureActiveFundingCycle If a funding cycle that has already started should be configurable.

        @return fundingCycle The funding cycle that the configuration will take effect during.
    */
    function configure(
        uint256 _projectId,
        FundingCycleProperties calldata _properties,
        uint256 _metadata,
        uint256 _fee,
        bool _configureActiveFundingCycle
    )
        external
        override
        onlyTerminal(_projectId)
        returns (FundingCycle memory fundingCycle)
    {
        // Duration must fit in a uint16.
        require(
            _properties.duration <= type(uint16).max,
            "FundingCycles::configure: BAD_DURATION"
        );

        // Currency must be less than the limit.
        require(
            _properties.cycleLimit <= MAX_CYCLE_LIMIT,
            "FundingCycles::configure: BAD_CYCLE_LIMIT"
        );

        // Discount rate token must be less than or equal to 100%.
        require(
            _properties.discountRate <= 201,
            "FundingCycles::configure: BAD_DISCOUNT_RATE"
        );

        // Currency must fit into a uint8.
        require(
            _properties.currency <= type(uint8).max,
            "FundingCycles::configure: BAD_CURRENCY"
        );

        // Fee must be less than or equal to 100%.
        require(_fee <= 200, "FundingCycles::configure: BAD_FEE");

        // Set the configuration timestamp is now.
        uint256 _configured = block.timestamp;

        // Gets the ID of the funding cycle to reconfigure.
        uint256 _fundingCycleId = _configurable(
            _projectId,
            _configured,
            _configureActiveFundingCycle
        );

        // Store the configuration.
        _packAndStoreConfigurationProperties(
            _fundingCycleId,
            _configured,
            _properties.cycleLimit,
            _properties.ballot,
            _properties.duration,
            _properties.currency,
            _fee,
            _properties.discountRate
        );

        // Set the target amount.
        _targetOf[_fundingCycleId] = _properties.target;

        // Set the metadata.
        _metadataOf[_fundingCycleId] = _metadata;

        emit Configure(
            _fundingCycleId,
            _projectId,
            _configured,
            _properties,
            _metadata,
            msg.sender
        );

        return _getStruct(_fundingCycleId);
    }

    /** 
      @notice 
      Tap funds from a project's currently tappable funding cycle.

      @dev
      Only a project's current terminal can tap funds for its funding cycles.

      @param _projectId The ID of the project being tapped.
      @param _amount The amount being tapped.

      @return fundingCycle The tapped funding cycle.
    */
    function tap(uint256 _projectId, uint256 _amount)
        external
        override
        onlyTerminal(_projectId)
        returns (FundingCycle memory fundingCycle)
    {
        // Get a reference to the funding cycle being tapped.
        uint256 fundingCycleId = _tappable(_projectId);

        // Get a reference to how much has already been tapped from this funding cycle.
        uint256 _tapped = _tappedOf[fundingCycleId];

        // Amount must be within what is still tappable.
        require(
            _amount <= _targetOf[fundingCycleId] - _tapped,
            "FundingCycles::tap: INSUFFICIENT_FUNDS"
        );

        // The new amount that has been tapped.
        uint256 _newTappedAmount = _tapped + _amount;

        // Store the new amount.
        _tappedOf[fundingCycleId] = _newTappedAmount;

        emit Tap(
            fundingCycleId,
            _projectId,
            _amount,
            _newTappedAmount,
            msg.sender
        );

        return _getStruct(fundingCycleId);
    }

    // --- private helper functions --- //

    /**
        @notice 
        Returns the configurable funding cycle for this project if it exists, otherwise creates one.

        @param _projectId The ID of the project to find a configurable funding cycle for.
        @param _configured The time at which the configuration is occuring.
        @param _configureActiveFundingCycle If the active funding cycle should be configurable. Otherwise the next funding cycle will be used.

        @return fundingCycleId The ID of the configurable funding cycle.
    */
    function _configurable(
        uint256 _projectId,
        uint256 _configured,
        bool _configureActiveFundingCycle
    ) private returns (uint256 fundingCycleId) {
        // If there's not yet a funding cycle for the project, return the ID of a newly created one.
        if (latestIdOf[_projectId] == 0)
            return _init(_projectId, _getStruct(0), block.timestamp, false);

        // Get the standby funding cycle's ID.
        fundingCycleId = _standby(_projectId);

        // If it exists, make sure its updated, then return it.
        if (fundingCycleId > 0) {
            // Get the funding cycle that the specified one is based on.
            FundingCycle memory _baseFundingCycle = _getStruct(
                _getStruct(fundingCycleId).basedOn
            );

            // The base's ballot must have ended.
            _updateFundingCycle(
                fundingCycleId,
                _baseFundingCycle,
                _getTimeAfterBallot(_baseFundingCycle, _configured),
                false
            );
            return fundingCycleId;
        }

        // Get the active funding cycle's ID.
        fundingCycleId = _eligible(_projectId);

        // If the ID of an eligible funding cycle exists, it's approved, and active funding cycles are configurable, return it.
        if (fundingCycleId > 0) {
            if (!_isIdApproved(fundingCycleId)) {
                // If it hasn't been approved, set the ID to be the based funding cycle,
                // which carries the last approved configuration.
                fundingCycleId = _getStruct(fundingCycleId).basedOn;
            } else if (_configureActiveFundingCycle) {
                return fundingCycleId;
            }
        } else {
            // Get the ID of the latest funding cycle which has the latest reconfiguration.
            fundingCycleId = latestIdOf[_projectId];
        }

        // Determine if the configurable funding cycle can only take effect on or after a certain date.
        uint256 _mustStartOnOrAfter;

        // Base off of the active funding cycle if it exists.
        FundingCycle memory _fundingCycle = _getStruct(fundingCycleId);

        // Make sure the funding cycle is recurring.
        require(
            _fundingCycle.discountRate < 201,
            "FundingCycles::_configurable: NON_RECURRING"
        );

        if (_configureActiveFundingCycle) {
            // If the duration is zero, always go back to the original start.
            if (_fundingCycle.duration == 0) {
                _mustStartOnOrAfter = _fundingCycle.start;
            } else {
                // Set to the start time of the current active start time.
                uint256 _timeFromStartMultiple = (block.timestamp -
                    _fundingCycle.start) %
                    (_fundingCycle.duration * SECONDS_IN_DAY);
                _mustStartOnOrAfter = block.timestamp - _timeFromStartMultiple;
            }
        } else {
            // The ballot must have ended.
            _mustStartOnOrAfter = _getTimeAfterBallot(
                _fundingCycle,
                _configured
            );
        }

        // Return the newly initialized configurable funding cycle.
        fundingCycleId = _init(
            _projectId,
            _fundingCycle,
            _mustStartOnOrAfter,
            false
        );
    }

    /**
        @notice 
        Returns the funding cycle that can be tapped at the time of the call.

        @param _projectId The ID of the project to find a configurable funding cycle for.

        @return fundingCycleId The ID of the tappable funding cycle.
    */
    function _tappable(uint256 _projectId)
        private
        returns (uint256 fundingCycleId)
    {
        // Check for the ID of an eligible funding cycle.
        fundingCycleId = _eligible(_projectId);

        // No eligible funding cycle found, check for the ID of a standby funding cycle.
        // If this one exists, it will become eligible one it has started.
        if (fundingCycleId == 0) fundingCycleId = _standby(_projectId);

        // Keep a reference to the funding cycle eligible for being tappable.
        FundingCycle memory _fundingCycle;

        // If the ID of an eligible funding cycle exists,
        // check to see if it has been approved by the based funding cycle's ballot.
        if (fundingCycleId > 0) {
            // Get the necessary properties for the funding cycle.
            _fundingCycle = _getStruct(fundingCycleId);

            // Check to see if the cycle is approved. If so, return it.
            if (
                _fundingCycle.start <= block.timestamp &&
                _isApproved(_fundingCycle)
            ) return fundingCycleId;

            // If it hasn't been approved, set the ID to be the base funding cycle,
            // which carries the last approved configuration.
            fundingCycleId = _fundingCycle.basedOn;
        } else {
            // No upcoming funding cycle found that is eligible to become active, clone the latest active funding cycle.
            // which carries the last approved configuration.
            fundingCycleId = latestIdOf[_projectId];
        }

        // The funding cycle cant be 0.
        require(fundingCycleId > 0, "FundingCycles::_tappable: NOT_FOUND");

        // Set the eligible funding cycle.
        _fundingCycle = _getStruct(fundingCycleId);

        // Funding cycles with a discount rate of 100% are non-recurring.
        require(
            _fundingCycle.discountRate < 201,
            "FundingCycles::_tappable: NON_RECURRING"
        );

        // The time when the funding cycle immediately after the eligible funding cycle starts.
        uint256 _nextImmediateStart = _fundingCycle.start +
            (_fundingCycle.duration * SECONDS_IN_DAY);

        // The distance from now until the nearest past multiple of the cycle duration from its start.
        // A duration of zero means the reconfiguration can start right away.
        uint256 _timeFromImmediateStartMultiple = _fundingCycle.duration == 0
            ? 0
            : (block.timestamp - _nextImmediateStart) %
                (_fundingCycle.duration * SECONDS_IN_DAY);

        // Return the tappable funding cycle.
        fundingCycleId = _init(
            _projectId,
            _fundingCycle,
            block.timestamp - _timeFromImmediateStartMultiple,
            true
        );
    }

    /**
        @notice 
        Initializes a funding cycle with the appropriate properties.

        @param _projectId The ID of the project to which the funding cycle being initialized belongs.
        @param _baseFundingCycle The funding cycle to base the initialized one on.
        @param _mustStartOnOrAfter The time before which the initialized funding cycle can't start.
        @param _copy If non-intrinsic properties should be copied from the base funding cycle.

        @return newFundingCycleId The ID of the initialized funding cycle.
    */
    function _init(
        uint256 _projectId,
        FundingCycle memory _baseFundingCycle,
        uint256 _mustStartOnOrAfter,
        bool _copy
    ) private returns (uint256 newFundingCycleId) {
        // Increment the count of funding cycles.
        count++;

        // Set the project's latest funding cycle ID to the new count.
        latestIdOf[_projectId] = count;

        // If there is no base, initialize a first cycle.
        if (_baseFundingCycle.id == 0) {
            // Set fresh intrinsic properties.
            _packAndStoreIntrinsicProperties(
                count,
                _projectId,
                BASE_WEIGHT,
                1,
                0,
                block.timestamp
            );
        } else {
            // Update the intrinsic properties of the funding cycle being initialized.
            _updateFundingCycle(
                count,
                _baseFundingCycle,
                _mustStartOnOrAfter,
                _copy
            );
        }

        // Get a reference to the funding cycle with updated intrinsic properties.
        FundingCycle memory _fundingCycle = _getStruct(count);

        emit Init(
            count,
            _fundingCycle.projectId,
            _fundingCycle.number,
            _fundingCycle.basedOn,
            _fundingCycle.weight,
            _fundingCycle.start
        );

        return _fundingCycle.id;
    }

    /**
        @notice 
        The project's funding cycle that hasn't yet started, if one exists.

        @param _projectId The ID of project to look through.

        @return fundingCycleId The ID of the standby funding cycle.
    */
    function _standby(uint256 _projectId)
        private
        view
        returns (uint256 fundingCycleId)
    {
        // Get a reference to the project's latest funding cycle.
        fundingCycleId = latestIdOf[_projectId];

        // If there isn't one, theres also no standy funding cycle.
        if (fundingCycleId == 0) return 0;

        // Get the necessary properties for the latest funding cycle.
        FundingCycle memory _fundingCycle = _getStruct(fundingCycleId);

        // There is no upcoming funding cycle if the latest funding cycle has already started.
        if (block.timestamp >= _fundingCycle.start) return 0;
    }

    /**
        @notice 
        The project's funding cycle that has started and hasn't yet expired.

        @param _projectId The ID of the project to look through.

        @return fundingCycleId The ID of the active funding cycle.
    */
    function _eligible(uint256 _projectId)
        private
        view
        returns (uint256 fundingCycleId)
    {
        // Get a reference to the project's latest funding cycle.
        fundingCycleId = latestIdOf[_projectId];

        // If the latest funding cycle doesn't exist, return an undefined funding cycle.
        if (fundingCycleId == 0) return 0;

        // Get the necessary properties for the latest funding cycle.
        FundingCycle memory _fundingCycle = _getStruct(fundingCycleId);

        // If the latest is expired, return an undefined funding cycle.
        // A duration of 0 can not be expired.
        if (
            _fundingCycle.duration > 0 &&
            block.timestamp >=
            _fundingCycle.start + (_fundingCycle.duration * SECONDS_IN_DAY)
        ) return 0;

        // The first funding cycle when running on local can be in the future for some reason.
        // This will have no effect in production.
        if (
            _fundingCycle.basedOn == 0 || block.timestamp >= _fundingCycle.start
        ) return fundingCycleId;

        // The base cant be expired.
        FundingCycle memory _baseFundingCycle = _getStruct(
            _fundingCycle.basedOn
        );

        // If the current time is past the end of the base, return 0.
        // A duration of 0 is always eligible.
        if (
            _baseFundingCycle.duration > 0 &&
            block.timestamp >=
            _baseFundingCycle.start +
                (_baseFundingCycle.duration * SECONDS_IN_DAY)
        ) return 0;

        // Return the funding cycle immediately before the latest.
        fundingCycleId = _fundingCycle.basedOn;
    }

    /** 
        @notice 
        A view of the funding cycle that would be created based on the provided one if the project doesn't make a reconfiguration.

        @param _baseFundingCycle The funding cycle to make the calculation for.
        @param _allowMidCycle Allow the mocked funding cycle to already be mid cycle.

        @return The next funding cycle, with an ID set to 0.
    */
    function _mockFundingCycleBasedOn(
        FundingCycle memory _baseFundingCycle,
        bool _allowMidCycle
    ) internal view returns (FundingCycle memory) {
        // Can't mock a non recurring funding cycle.
        if (_baseFundingCycle.discountRate == 201) return _getStruct(0);

        // If the base has a limit, find the last permanent funding cycle, which is needed to make subsequent calculations.
        // Otherwise, the base is already the latest permanent funding cycle.
        FundingCycle memory _latestPermanentFundingCycle = _baseFundingCycle
        .cycleLimit > 0
            ? _latestPermanentCycleBefore(_baseFundingCycle)
            : _baseFundingCycle;

        // The distance of the current time to the start of the next possible funding cycle.
        uint256 _timeFromImmediateStartMultiple;

        if (_allowMidCycle && _baseFundingCycle.duration > 0) {
            // Get the end time of the last cycle.
            uint256 _cycleEnd = _baseFundingCycle.start +
                (_baseFundingCycle.cycleLimit *
                    _baseFundingCycle.duration *
                    SECONDS_IN_DAY);

            // If the cycle end time is in the past, the mock should start at a multiple of the last permanent cycle since the cycle ended.
            if (
                _baseFundingCycle.cycleLimit > 0 && _cycleEnd < block.timestamp
            ) {
                _timeFromImmediateStartMultiple = _latestPermanentFundingCycle
                .duration == 0
                    ? 0
                    : ((block.timestamp - _cycleEnd) %
                        (_latestPermanentFundingCycle.duration *
                            SECONDS_IN_DAY));
            } else {
                _timeFromImmediateStartMultiple =
                    _baseFundingCycle.duration *
                    SECONDS_IN_DAY;
            }
        } else {
            _timeFromImmediateStartMultiple = 0;
        }

        // Derive what the start time should be.
        uint256 _start = _deriveStart(
            _baseFundingCycle,
            _latestPermanentFundingCycle,
            block.timestamp - _timeFromImmediateStartMultiple
        );

        // Derive what the cycle limit should be.
        uint256 _cycleLimit = _deriveCycleLimit(_baseFundingCycle, _start);

        // Copy the last permanent funding cycle if the bases' limit is up.
        FundingCycle memory _fundingCycleToCopy = _cycleLimit == 0
            ? _latestPermanentFundingCycle
            : _baseFundingCycle;

        return
            FundingCycle(
                0,
                _fundingCycleToCopy.projectId,
                _deriveNumber(
                    _baseFundingCycle,
                    _latestPermanentFundingCycle,
                    _start
                ),
                _fundingCycleToCopy.id,
                _fundingCycleToCopy.configured,
                _cycleLimit,
                _deriveWeight(
                    _baseFundingCycle,
                    _latestPermanentFundingCycle,
                    _start
                ),
                _fundingCycleToCopy.ballot,
                _start,
                _fundingCycleToCopy.duration,
                _fundingCycleToCopy.target,
                _fundingCycleToCopy.currency,
                _fundingCycleToCopy.fee,
                _fundingCycleToCopy.discountRate,
                0,
                _fundingCycleToCopy.metadata
            );
    }

    /** 
      @notice
      Updates intrinsic properties for a funding cycle given a base cycle.

      @param _fundingCycleId The ID of the funding cycle to make sure is update.
      @param _baseFundingCycle The cycle that the one being updated is based on.
      @param _mustStartOnOrAfter The time before which the initialized funding cycle can't start.
      @param _copy If non-intrinsic properties should be copied from the base funding cycle.
    */
    function _updateFundingCycle(
        uint256 _fundingCycleId,
        FundingCycle memory _baseFundingCycle,
        uint256 _mustStartOnOrAfter,
        bool _copy
    ) private {
        // Get the latest permanent funding cycle.
        FundingCycle memory _latestPermanentFundingCycle = _baseFundingCycle
        .cycleLimit > 0
            ? _latestPermanentCycleBefore(_baseFundingCycle)
            : _baseFundingCycle;

        // Derive the correct next start time from the base.
        uint256 _start = _deriveStart(
            _baseFundingCycle,
            _latestPermanentFundingCycle,
            _mustStartOnOrAfter
        );

        // Derive the correct weight.
        uint256 _weight = _deriveWeight(
            _baseFundingCycle,
            _latestPermanentFundingCycle,
            _start
        );

        // Derive the correct number.
        uint256 _number = _deriveNumber(
            _baseFundingCycle,
            _latestPermanentFundingCycle,
            _start
        );

        // Copy if needed.
        if (_copy) {
            // Derive what the cycle limit should be.
            uint256 _cycleLimit = _deriveCycleLimit(_baseFundingCycle, _start);

            // Copy the last permanent funding cycle if the bases' limit is up.
            FundingCycle memory _fundingCycleToCopy = _cycleLimit == 0
                ? _latestPermanentFundingCycle
                : _baseFundingCycle;

            // Save the configuration efficiently.
            _packAndStoreConfigurationProperties(
                _fundingCycleId,
                _fundingCycleToCopy.configured,
                _cycleLimit,
                _fundingCycleToCopy.ballot,
                _fundingCycleToCopy.duration,
                _fundingCycleToCopy.currency,
                _fundingCycleToCopy.fee,
                _fundingCycleToCopy.discountRate
            );

            _metadataOf[count] = _metadataOf[_fundingCycleToCopy.id];
            _targetOf[count] = _targetOf[_fundingCycleToCopy.id];
        }

        // Update the intrinsic properties.
        _packAndStoreIntrinsicProperties(
            _fundingCycleId,
            _baseFundingCycle.projectId,
            _weight,
            _number,
            _baseFundingCycle.id,
            _start
        );
    }

    /**
      @notice 
      Efficiently stores a funding cycle's provided intrinsic properties.

      @param _fundingCycleId The ID of the funding cycle to pack and store.
      @param _projectId The ID of the project to which the funding cycle belongs.
      @param _weight The weight of the funding cycle.
      @param _number The number of the funding cycle.
      @param _basedOn The ID of the based funding cycle.
      @param _start The start time of this funding cycle.

     */
    function _packAndStoreIntrinsicProperties(
        uint256 _fundingCycleId,
        uint256 _projectId,
        uint256 _weight,
        uint256 _number,
        uint256 _basedOn,
        uint256 _start
    ) private {
        // weight in bytes 0-79 bytes.
        uint256 packed = _weight;
        // projectId in bytes 80-135 bytes.
        packed |= _projectId << 80;
        // basedOn in bytes 136-183 bytes.
        packed |= _basedOn << 136;
        // start in bytes 184-231 bytes.
        packed |= _start << 184;
        // number in bytes 232-255 bytes.
        packed |= _number << 232;

        // Set in storage.
        _packedIntrinsicPropertiesOf[_fundingCycleId] = packed;
    }

    /**
      @notice 
      Efficiently stores a funding cycles provided configuration properties.

      @param _fundingCycleId The ID of the funding cycle to pack and store.
      @param _configured The timestamp of the configuration.
      @param _cycleLimit The number of cycles that this configuration should last for before going back to the last permanent.
      @param _ballot The ballot to use for future reconfiguration approvals. 
      @param _duration The duration of the funding cycle.
      @param _currency The currency of the funding cycle.
      @param _fee The fee of the funding cycle.
      @param _discountRate The discount rate of the based funding cycle.
     */
    function _packAndStoreConfigurationProperties(
        uint256 _fundingCycleId,
        uint256 _configured,
        uint256 _cycleLimit,
        IFundingCycleBallot _ballot,
        uint256 _duration,
        uint256 _currency,
        uint256 _fee,
        uint256 _discountRate
    ) private {
        // ballot in bytes 0-159 bytes.
        uint256 packed = uint160(address(_ballot));
        // configured in bytes 160-207 bytes.
        packed |= _configured << 160;
        // duration in bytes 208-223 bytes.
        packed |= _duration << 208;
        // basedOn in bytes 224-231 bytes.
        packed |= _currency << 224;
        // fee in bytes 232-239 bytes.
        packed |= _fee << 232;
        // discountRate in bytes 240-247 bytes.
        packed |= _discountRate << 240;
        // cycleLimit in bytes 248-255 bytes.
        packed |= _cycleLimit << 248;

        // Set in storage.
        _packedConfigurationPropertiesOf[_fundingCycleId] = packed;
    }

    /**
        @notice 
        Unpack a funding cycle's packed stored values into an easy-to-work-with funding cycle struct.

        @param _id The ID of the funding cycle to get a struct of.

        @return _fundingCycle The funding cycle struct.
    */
    function _getStruct(uint256 _id)
        private
        view
        returns (FundingCycle memory _fundingCycle)
    {
        // Return an empty funding cycle if the ID specified is 0.
        if (_id == 0) return _fundingCycle;

        _fundingCycle.id = _id;

        uint256 _packedIntrinsicProperties = _packedIntrinsicPropertiesOf[_id];

        _fundingCycle.weight = uint256(uint80(_packedIntrinsicProperties));
        _fundingCycle.projectId = uint256(
            uint56(_packedIntrinsicProperties >> 80)
        );
        _fundingCycle.basedOn = uint256(
            uint48(_packedIntrinsicProperties >> 136)
        );
        _fundingCycle.start = uint256(
            uint48(_packedIntrinsicProperties >> 184)
        );
        _fundingCycle.number = uint256(
            uint24(_packedIntrinsicProperties >> 232)
        );


            uint256 _packedConfigurationProperties
         = _packedConfigurationPropertiesOf[_id];
        _fundingCycle.ballot = IFundingCycleBallot(
            address(uint160(_packedConfigurationProperties))
        );
        _fundingCycle.configured = uint256(
            uint48(_packedConfigurationProperties >> 160)
        );
        _fundingCycle.duration = uint256(
            uint16(_packedConfigurationProperties >> 208)
        );
        _fundingCycle.currency = uint256(
            uint8(_packedConfigurationProperties >> 224)
        );
        _fundingCycle.fee = uint256(
            uint8(_packedConfigurationProperties >> 232)
        );
        _fundingCycle.discountRate = uint256(
            uint8(_packedConfigurationProperties >> 240)
        );
        _fundingCycle.cycleLimit = uint256(
            uint8(_packedConfigurationProperties >> 248)
        );
        _fundingCycle.target = _targetOf[_id];
        _fundingCycle.tapped = _tappedOf[_id];
        _fundingCycle.metadata = _metadataOf[_id];
    }

    /** 
        @notice 
        The date that is the nearest multiple of the specified funding cycle's duration from its end.

        @param _baseFundingCycle The funding cycle to make the calculation for.
        @param _latestPermanentFundingCycle The latest funding cycle in the same project as `_baseFundingCycle` to not have a limit.
        @param _mustStartOnOrAfter A date that the derived start must be on or come after.

        @return start The next start time.
    */
    function _deriveStart(
        FundingCycle memory _baseFundingCycle,
        FundingCycle memory _latestPermanentFundingCycle,
        uint256 _mustStartOnOrAfter
    ) internal pure returns (uint256 start) {
        // A subsequent cycle to one with a duration of 0 should start as soon as possible.
        if (_baseFundingCycle.duration == 0) return _mustStartOnOrAfter;

        // Save a reference to the duration measured in seconds.
        uint256 _durationInSeconds = _baseFundingCycle.duration *
            SECONDS_IN_DAY;

        // The time when the funding cycle immediately after the specified funding cycle starts.
        uint256 _nextImmediateStart = _baseFundingCycle.start +
            _durationInSeconds;

        // If the next immediate start is now or in the future, return it.
        if (_nextImmediateStart >= _mustStartOnOrAfter)
            return _nextImmediateStart;

        uint256 _cycleLimit = _baseFundingCycle.cycleLimit;

        uint256 _timeFromImmediateStartMultiple;
        // Only use base
        if (
            _mustStartOnOrAfter <=
            _baseFundingCycle.start + _durationInSeconds * _cycleLimit
        ) {
            // Otherwise, use the closest multiple of the duration from the old end.
            _timeFromImmediateStartMultiple =
                (_mustStartOnOrAfter - _nextImmediateStart) %
                _durationInSeconds;
        } else {
            // If the cycle has ended, make the calculation with the latest permanent funding cycle.
            _timeFromImmediateStartMultiple = _latestPermanentFundingCycle
            .duration == 0
                ? 0
                : ((_mustStartOnOrAfter -
                    (_baseFundingCycle.start +
                        (_durationInSeconds * _cycleLimit))) %
                    (_latestPermanentFundingCycle.duration * SECONDS_IN_DAY));

            // Use the duration of the permanent funding cycle from here on out.
            _durationInSeconds =
                _latestPermanentFundingCycle.duration *
                SECONDS_IN_DAY;
        }

        // Otherwise use an increment of the duration from the most recent start.
        start = _mustStartOnOrAfter - _timeFromImmediateStartMultiple;

        // Add increments of duration as necessary to satisfy the threshold.
        while (_mustStartOnOrAfter > start) start = start + _durationInSeconds;
    }

    /** 
        @notice 
        The accumulated weight change since the specified funding cycle.

        @param _baseFundingCycle The funding cycle to make the calculation with.
        @param _latestPermanentFundingCycle The latest funding cycle in the same project as `_fundingCycle` to not have a limit.
        @param _start The start time to derive a weight for.

        @return weight The next weight.
    */
    function _deriveWeight(
        FundingCycle memory _baseFundingCycle,
        FundingCycle memory _latestPermanentFundingCycle,
        uint256 _start
    ) internal pure returns (uint256 weight) {
        // A subsequent cycle to one with a duration of 0 should have the next possible weight.
        if (_baseFundingCycle.duration == 0)
            return
                PRBMath.mulDiv(
                    _baseFundingCycle.weight,
                    1000 - _baseFundingCycle.discountRate,
                    1000
                );

        // The difference between the start of the base funding cycle and the proposed start.
        uint256 _startDistance = _start - _baseFundingCycle.start;

        // The number of seconds that the base funding cycle is limited to.
        uint256 _limitLength = _baseFundingCycle.cycleLimit == 0 ||
            _baseFundingCycle.basedOn == 0
            ? 0
            : _baseFundingCycle.cycleLimit *
                (_baseFundingCycle.duration * SECONDS_IN_DAY);

        // The weight should be based off the base funding cycle's weight.
        weight = _baseFundingCycle.weight;

        // If there's no limit or if the limit is greater than the start distance,
        // apply the discount rate of the base.
        if (_limitLength == 0 || _limitLength > _startDistance) {
            // If the discount rate is 0, return the same weight.
            if (_baseFundingCycle.discountRate == 0) return weight;

            uint256 _discountMultiple = _startDistance /
                (_baseFundingCycle.duration * SECONDS_IN_DAY);

            for (uint256 i = 0; i < _discountMultiple; i++) {
                // The number of times to apply the discount rate.
                // Base the new weight on the specified funding cycle's weight.
                weight = PRBMath.mulDiv(
                    weight,
                    1000 - _baseFundingCycle.discountRate,
                    1000
                );
            }
        } else {
            // If the time between the base start at the given start is longer than
            // the limit, the discount rate for the limited base has to be applied first,
            // and then the discount rate for the last permanent should be applied to
            // the remaining distance.

            // Use up the limited discount rate up until the limit.
            if (_baseFundingCycle.discountRate > 0) {
                for (uint256 i = 0; i < _baseFundingCycle.cycleLimit; i++) {
                    weight = PRBMath.mulDiv(
                        weight,
                        1000 - _baseFundingCycle.discountRate,
                        1000
                    );
                }
            }

            if (_latestPermanentFundingCycle.discountRate > 0) {
                // The number of times to apply the latest permanent discount rate.


                    uint256 _permanentDiscountMultiple
                 = _latestPermanentFundingCycle.duration == 0
                    ? 0
                    : (_startDistance - _limitLength) /
                        (_latestPermanentFundingCycle.duration *
                            SECONDS_IN_DAY);

                for (uint256 i = 0; i < _permanentDiscountMultiple; i++) {
                    // base the weight on the result of the previous calculation.
                    weight = PRBMath.mulDiv(
                        weight,
                        1000 - _latestPermanentFundingCycle.discountRate,
                        1000
                    );
                }
            }
        }
    }

    /** 
        @notice 
        The number of the next funding cycle given the specified funding cycle.

        @param _baseFundingCycle The funding cycle to make the calculation with.
        @param _latestPermanentFundingCycle The latest funding cycle in the same project as `_fundingCycle` to not have a limit.
        @param _start The start time to derive a number for.

        @return number The next number.
    */
    function _deriveNumber(
        FundingCycle memory _baseFundingCycle,
        FundingCycle memory _latestPermanentFundingCycle,
        uint256 _start
    ) internal pure returns (uint256 number) {
        // A subsequent cycle to one with a duration of 0 should be the next number.
        if (_baseFundingCycle.duration == 0)
            return _baseFundingCycle.number + 1;

        // The difference between the start of the base funding cycle and the proposed start.
        uint256 _startDistance = _start - _baseFundingCycle.start;

        // The number of seconds that the base funding cycle is limited to.
        uint256 _limitLength = _baseFundingCycle.cycleLimit == 0
            ? 0
            : _baseFundingCycle.cycleLimit *
                (_baseFundingCycle.duration * SECONDS_IN_DAY);

        if (_limitLength == 0 || _limitLength > _startDistance) {
            // If there's no limit or if the limit is greater than the start distance,
            // get the result by finding the number of base cycles that fit in the start distance.
            number =
                _baseFundingCycle.number +
                (_startDistance /
                    (_baseFundingCycle.duration * SECONDS_IN_DAY));
        } else {
            // If the time between the base start at the given start is longer than
            // the limit, first calculate the number of cycles that passed under the limit,
            // and add any cycles that have passed of the latest permanent funding cycle afterwards.

            number =
                _baseFundingCycle.number +
                (_limitLength / (_baseFundingCycle.duration * SECONDS_IN_DAY));

            number =
                number +
                (
                    _latestPermanentFundingCycle.duration == 0
                        ? 0
                        : ((_startDistance - _limitLength) /
                            (_latestPermanentFundingCycle.duration *
                                SECONDS_IN_DAY))
                );
        }
    }

    /** 
        @notice 
        The limited number of times a funding cycle configuration can be active given the specified funding cycle.

        @param _fundingCycle The funding cycle to make the calculation with.
        @param _start The start time to derive cycles remaining for.

        @return start The inclusive nunmber of cycles remaining.
    */
    function _deriveCycleLimit(
        FundingCycle memory _fundingCycle,
        uint256 _start
    ) internal pure returns (uint256) {
        if (_fundingCycle.cycleLimit <= 1 || _fundingCycle.duration == 0)
            return 0;
        uint256 _cycles = ((_start - _fundingCycle.start) /
            (_fundingCycle.duration * SECONDS_IN_DAY));

        if (_cycles >= _fundingCycle.cycleLimit) return 0;
        return _fundingCycle.cycleLimit - _cycles;
    }

    /** 
      @notice 
      Checks to see if the funding cycle of the provided ID is approved according to the correct ballot.

      @param _fundingCycleId The ID of the funding cycle to get an approval flag for.

      @return The approval flag.
    */
    function _isIdApproved(uint256 _fundingCycleId)
        private
        view
        returns (bool)
    {
        FundingCycle memory _fundingCycle = _getStruct(_fundingCycleId);
        return _isApproved(_fundingCycle);
    }

    /** 
      @notice 
      Checks to see if the provided funding cycle is approved according to the correct ballot.

      @param _fundingCycle The ID of the funding cycle to get an approval flag for.

      @return The approval flag.
    */
    function _isApproved(FundingCycle memory _fundingCycle)
        private
        view
        returns (bool)
    {
        return
            _ballotState(
                _fundingCycle.id,
                _fundingCycle.configured,
                _fundingCycle.basedOn
            ) == BallotState.Approved;
    }

    /**
        @notice 
        A funding cycle configuration's currency status.

        @param _id The ID of the funding cycle configuration to check the status of.
        @param _configuration The timestamp of when the configuration took place.
        @param _ballotFundingCycleId The ID of the funding cycle which is configured with the ballot that should be used.

        @return The funding cycle's configuration status.
    */
    function _ballotState(
        uint256 _id,
        uint256 _configuration,
        uint256 _ballotFundingCycleId
    ) private view returns (BallotState) {
        // If there is no ballot funding cycle, auto approve.
        if (_ballotFundingCycleId == 0) return BallotState.Approved;

        // Get the ballot funding cycle.
        FundingCycle memory _ballotFundingCycle = _getStruct(
            _ballotFundingCycleId
        );

        // If the configuration is the same as the ballot's funding cycle,
        // the ballot isn't applicable. Auto approve since the ballot funding cycle is approved.
        if (_ballotFundingCycle.configured == _configuration)
            return BallotState.Approved;

        // If there is no ballot, the ID is auto approved.
        // Otherwise, return the ballot's state.
        return
            _ballotFundingCycle.ballot == IFundingCycleBallot(address(0))
                ? BallotState.Approved
                : _ballotFundingCycle.ballot.state(_id, _configuration);
    }

    /** 
      @notice 
      Finds the last funding cycle that was permanent in relation to the specified funding cycle.

      @dev
      Determined what the latest funding cycle with a `cycleLimit` of 0 is, or isn't based on any previous funding cycle.


      @param _fundingCycle The funding cycle to find the most recent permanent cycle compared to.

      @return fundingCycle The most recent permanent funding cycle.
    */
    function _latestPermanentCycleBefore(FundingCycle memory _fundingCycle)
        private
        view
        returns (FundingCycle memory fundingCycle)
    {
        if (_fundingCycle.basedOn == 0) return _fundingCycle;
        fundingCycle = _getStruct(_fundingCycle.basedOn);
        if (fundingCycle.cycleLimit == 0) return fundingCycle;
        return _latestPermanentCycleBefore(fundingCycle);
    }

    /** 
      @notice
      The time after the ballot of the provided funding cycle has expired.

      @dev
      If the ballot ends in the past, the current block timestamp will be returned.

      @param _fundingCycle The ID funding cycle to make the caluclation the ballot of.
      @param _from The time from which the ballot duration should be calculated.

      @return The time when the ballot duration ends.
    */
    function _getTimeAfterBallot(
        FundingCycle memory _fundingCycle,
        uint256 _from
    ) private view returns (uint256) {
        // The ballot must have ended.
        uint256 _ballotExpiration = _fundingCycle.ballot !=
            IFundingCycleBallot(address(0))
            ? _from + _fundingCycle.ballot.duration()
            : 0;

        return
            block.timestamp > _ballotExpiration
                ? block.timestamp
                : _ballotExpiration;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IPrices.sol";

/** 
  @notice Manage and normalizes ETH price feeds.
*/
contract Prices is IPrices, Ownable {
    // --- public constant stored properties --- //

    /// @notice The target number of decimals the price feed results have.
    uint256 public constant override targetDecimals = 18;

    // --- public stored properties --- //

    /// @notice The number to multiply each price feed by to get to the target decimals.
    mapping(uint256 => uint256) public override feedDecimalAdjuster;

    /// @notice The available price feeds that can be used to get the price of ETH.
    mapping(uint256 => AggregatorV3Interface) public override feedFor;

    // --- external views --- //

    /** 
      @notice 
      Gets the current price of ETH for the provided currency.
      
      @param _currency The currency to get a price for.
      
      @return price The price of ETH with 18 decimals.
    */
    function getETHPriceFor(uint256 _currency)
        external
        view
        override
        returns (uint256)
    {
        // The 0 currency is ETH itself.
        if (_currency == 0) return 10**targetDecimals;

        // Get a reference to the feed.
        AggregatorV3Interface _feed = feedFor[_currency];

        // Feed must exist.
        require(
            _feed != AggregatorV3Interface(address(0)),
            "Prices::getETHPrice: NOT_FOUND"
        );

        // Get the lateset round information. Only need the price is needed.
        (, int256 _price, , , ) = _feed.latestRoundData();

        // Multiply the price by the decimal adjuster to get the normalized result.
        return uint256(_price) * feedDecimalAdjuster[_currency];
    }

    // --- external transactions --- //

    /** 
      @notice 
      Add a price feed for the price of ETH.

      @dev
      Current feeds can't be modified.

      @param _feed The price feed being added.
      @param _currency The currency that the price feed is for.
    */
    function addFeed(AggregatorV3Interface _feed, uint256 _currency)
        external
        override
        onlyOwner
    {
        // The 0 currency is reserved for ETH.
        require(_currency > 0, "Prices::addFeed: RESERVED");

        // There can't already be a feed for the specified currency.
        require(
            feedFor[_currency] == AggregatorV3Interface(address(0)),
            "Prices::addFeed: ALREADY_EXISTS"
        );

        // Get a reference to the number of decimals the feed uses.
        uint256 _decimals = _feed.decimals();

        // Decimals should be less than or equal to the target number of decimals.
        require(_decimals <= targetDecimals, "Prices::addFeed: BAD_DECIMALS");

        // Set the feed.
        feedFor[_currency] = _feed;

        // Set the decimal adjuster for the currency.
        feedDecimalAdjuster[_currency] = 10**(targetDecimals - _decimals);

        emit AddFeed(_currency, _feed);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./interfaces/ITerminal.sol";
import "./interfaces/IPrices.sol";
import "./abstract/JuiceboxProject.sol";

/// Owner should eventually change to a multisig wallet contract.
contract Governance is JuiceboxProject {
    // --- external transactions --- //

    constructor(uint256 _projectId, ITerminalDirectory _terminalDirectory)
        JuiceboxProject(_projectId, _terminalDirectory)
    {}

    /** 
      @notice Gives projects using one Terminal access to migrate to another Terminal.
      @param _from The terminal to allow a new migration from.
      @param _to The terminal to allow migration to.
    */
    function allowMigration(ITerminal _from, ITerminal _to) external onlyOwner {
        _from.allowMigration(_to);
    }

    /**
        @notice Adds a price feed.
        @param _prices The prices contract to add a feed to.
        @param _feed The price feed to add.
        @param _currency The currency the price feed is for.
    */
    function addPriceFeed(
        IPrices _prices,
        AggregatorV3Interface _feed,
        uint256 _currency
    ) external onlyOwner {
        _prices.addFeed(_feed, _currency);
    }

    /** 
      @notice Sets the fee of the TerminalV1.
      @param _terminalV1 The terminalV1 to change the fee of.
      @param _fee The new fee.
    */
    function setFee(ITerminalV1 _terminalV1, uint256 _fee) external onlyOwner {
        _terminalV1.setFee(_fee);
    }

    /** 
      @notice Appoints a new governance for the specified terminalV1.
      @param _terminalV1 The terminalV1 to change the governance of.
      @param _newGovernance The address to appoint as governance.
    */
    function appointGovernance(
        ITerminalV1 _terminalV1,
        address payable _newGovernance
    ) external onlyOwner {
        _terminalV1.appointGovernance(_newGovernance);
    }

    /** 
      @notice Accepts the offer to be the governance of a new terminalV1.
      @param _terminalV1 The terminalV1 to change the governance of.
    */
    function acceptGovernance(ITerminalV1 _terminalV1) external onlyOwner {
        _terminalV1.acceptGovernance();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./interfaces/ITerminalV1.sol";
import "./interfaces/IFundingCycleBallot.sol";

contract ExampleFailingFundingCycleBallot is IFundingCycleBallot {
    uint256 public constant reconfigurationDelay = 1209600;

    function duration() external pure override returns (uint256) {
        return reconfigurationDelay;
    }

    function state(uint256, uint256 _configured)
        external
        view
        override
        returns (BallotState)
    {
        return
            // Fails halfway through
            block.timestamp > _configured + (reconfigurationDelay / 2)
                ? BallotState.Failed
                : BallotState.Active;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./interfaces/ITerminalV1.sol";
import "./interfaces/IFundingCycleBallot.sol";

/** 
   @notice Manages votes towards approving funding cycle reconfigurations.
 */
contract Active7DaysFundingCycleBallot is IFundingCycleBallot {
    // --- public stored properties --- //

    /// @notice The number of seconds that must pass for a funding cycle reconfiguration to become active.
    uint256 public constant reconfigurationDelay = 604800; // 7 days

    // --- external views --- //

    /** 
      @notice The time that this ballot is active for.
      @dev A ballot should not be considered final until the duration has passed.
      @return The durection in seconds.
    */
    function duration() external pure override returns (uint256) {
        return reconfigurationDelay;
    }

    /**
      @notice The approval state of a particular funding cycle.
      @param _configured The configuration of the funding cycle to check the state of.
      @return The state of the provided ballot.
   */
    function state(uint256, uint256 _configured)
        external
        view
        override
        returns (BallotState)
    {
        return
            block.timestamp > _configured + reconfigurationDelay
                ? BallotState.Approved
                : BallotState.Active;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./interfaces/ITerminalV1.sol";
import "./interfaces/IFundingCycleBallot.sol";

/** 
   @notice Manages votes towards approving funding cycle reconfigurations.
 */
contract Active3DaysFundingCycleBallot is IFundingCycleBallot {
    // --- public stored properties --- //

    /// @notice The number of seconds that must pass for a funding cycle reconfiguration to become active.
    uint256 public constant reconfigurationDelay = 259200; // 3 days

    // --- external views --- //

    /** 
      @notice The time that this ballot is active for.
      @dev A ballot should not be considered final until the duration has passed.
      @return The durection in seconds.
    */
    function duration() external pure override returns (uint256) {
        return reconfigurationDelay;
    }

    /**
      @notice The approval state of a particular funding cycle.
      @param _configured The configuration of the funding cycle to check the state of.
      @return The state of the provided ballot.
   */
    function state(uint256, uint256 _configured)
        external
        view
        override
        returns (BallotState)
    {
        return
            block.timestamp > _configured + reconfigurationDelay
                ? BallotState.Approved
                : BallotState.Active;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./interfaces/ITerminalV1.sol";
import "./interfaces/IFundingCycleBallot.sol";

/** 
   @notice Manages votes towards approving funding cycle reconfigurations.
 */
contract Active14DaysFundingCycleBallot is IFundingCycleBallot {
    // --- public stored properties --- //

    /// @notice The number of seconds that must pass for a funding cycle reconfiguration to become active.
    uint256 public constant reconfigurationDelay = 1209600; // 14 days

    // --- external views --- //

    /** 
      @notice The time that this ballot is active for.
      @dev A ballot should not be considered final until the duration has passed.
      @return The durection in seconds.
    */
    function duration() external pure override returns (uint256) {
        return reconfigurationDelay;
    }

    /**
      @notice The approval state of a particular funding cycle.
      @param _configured The configuration of the funding cycle to check the state of.
      @return The state of the provided ballot.
   */
    function state(uint256, uint256 _configured)
        external
        view
        override
        returns (BallotState)
    {
        return
            block.timestamp > _configured + reconfigurationDelay
                ? BallotState.Approved
                : BallotState.Active;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./interfaces/IModAllocator.sol";

// A static mod allocator contract to use locally.
contract ExampleModAllocator is IModAllocator {
    function allocate(
        uint256 _projectId,
        uint256 _forProjectId,
        address _beneficiary
    ) external payable override {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./interfaces/IYielder.sol";

/// @dev For testing purposes.
contract ExampleYielder is IYielder {
    function deposited() external pure override returns (uint256) {
        return 0;
    }

    function getCurrentBalance() external pure override returns (uint256) {
        return 0;
    }

    function deposit() external payable override {}

    function withdraw(uint256 _amount, address payable _beneficiary)
        external
        override
    {}

    function withdrawAll(address payable _beneficiary)
        external
        override
        returns (uint256)
    {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

// A static price feed contract to use locally.
contract ExampleETHUSDPriceFeed is AggregatorV3Interface {
    function decimals() external pure override returns (uint8) {
        return 18;
    }

    function description() external pure override returns (string memory) {
        return "Static ETH/USD price feed. Do not use in production.";
    }

    function version() external pure override returns (uint256) {
        return 0;
    }

    function getRoundData(uint80)
        external
        pure
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (0, 2000E18, 0, 0, 0);
    }

    function latestRoundData()
        external
        pure
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (0, 2000E18, 0, 0, 0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@paulrberg/contracts/math/PRBMath.sol";

import "../abstract/JuiceboxProject.sol";

/** 
  @dev 
  Shwotime allows friends to commit to buying tickets to events together.
  They can commit to buying a ticket if a specified list of addresses also commit to buy the ticket.

  Not reliable for situations where networks dont entirely overlap.
*/
contract Shwotime is JuiceboxProject {
    using SafeERC20 for IERC20;

    struct Tix {
        address owner;
        uint256 max;
        uint256 sold;
        uint256 price;
        uint256 expiry;
        mapping(address => bool) committed;
        mapping(address => bool) paid;
        mapping(address => address[]) dependencies;
    }

    mapping(uint256 => Tix) public tickets;

    uint256 public ticketsCount = 0;

    IERC20 public dai;

    uint256 public fee;

    constructor(
        uint256 _projectId,
        ITerminalDirectory _terminalDirectory,
        IERC20 _dai,
        uint256 _fee
    ) JuiceboxProject(_projectId, _terminalDirectory) {
        dai = _dai;
        fee = _fee;
    }

    // Create tickets to sell.
    function createTickets(
        uint256 _price,
        uint256 _max,
        uint256 _expiry
    ) external {
        //Store the new ticket.
        ticketsCount++;
        Tix storage _tickets = tickets[ticketsCount];
        _tickets.price = _price;
        _tickets.max = _max;
        _tickets.sold = 0;
        _tickets.expiry = _expiry;
        _tickets.owner = msg.sender;
    }

    // commits to buying a ticket if the specified addresses also buy.
    function buyTicket(uint256 id, address[] calldata addresses) external {
        require(
            id > 0 && id <= ticketsCount,
            "Shwotime::buyTickets: NOT_FOUND"
        );

        //Mark the msg.sender as committed to buying.
        Tix storage _tickets = tickets[id];

        require(
            _tickets.expiry > block.timestamp,
            "Shwotime::buyTickets: EXPIRED"
        );
        require(
            _tickets.max >= _tickets.sold,
            "Shwotime::buyTickets: SOLD_OUT"
        );

        bool _transferFundsFromMsgSender = true;
        for (uint256 _i = 0; _i < addresses.length; _i++) {
            address _address = addresses[_i];
            if (!_tickets.committed[_address])
                _transferFundsFromMsgSender = false;
            if (_tickets.paid[_address]) continue;
            // Nest once.
            bool _transferFundsFromDependency = true;
            for (
                uint256 _j = 0;
                _j < _tickets.dependencies[_address].length;
                _j++
            ) {
                address _subAddress = _tickets.dependencies[_address][_j];
                if (
                    _subAddress != msg.sender &&
                    !_tickets.committed[_subAddress]
                ) _transferFundsFromDependency = false;
            }
            if (_transferFundsFromDependency) {
                // Transfer money from the committed buyer to this contract.
                dai.safeTransferFrom(_address, address(this), _tickets.price);
                _tickets.paid[_address] = true;
                _tickets.sold++;
            }
        }
        if (_transferFundsFromMsgSender) {
            // Transfer money from the msg sender to this contract.
            dai.safeTransferFrom(msg.sender, address(this), _tickets.price);
            //save the fact that msg.sender owes
            _tickets.paid[msg.sender] = true;
            _tickets.sold++;
        }

        // Check to see if its sold out once everyone has been given tickets.
        require(
            _tickets.max >= _tickets.sold,
            "Shwotime::buyTickets: SOLD_OUT"
        );

        _tickets.committed[msg.sender] = true;
    }

    //Allow a ticket owner to collect funds once the tickets expire.
    function collect(uint256 _id, string calldata _memo) external {
        require(_id > 0 && _id <= ticketsCount, "Shwotime::collect: NOT_FOUND");

        Tix storage _tickets = tickets[_id];

        require(
            msg.sender == _tickets.owner,
            "Shwotime::collect: UNAUTHORIZED"
        );

        require(
            _tickets.expiry <= block.timestamp,
            "Shwotime::collect: TOO_SOON"
        );

        uint256 _total = _tickets.price * _tickets.sold;
        uint256 _collectable = PRBMath.mulDiv(_total, 200 - fee, 200);
        dai.safeTransfer(msg.sender, _collectable);
        //Take your fee into Juicebox.
        _takeFee(_total - _collectable, msg.sender, _memo, false);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@paulrberg/contracts/token/erc20/Erc20Permit.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

contract Banny is ERC20, ERC20Permit, Ownable {
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    constructor() ERC20("Banny", "BANNY") ERC20Permit("Banny") {}

    function mint(address _account, uint256 _amount) external onlyOwner {
        return _mint(_account, _amount);
    }

    function burn(address _account, uint256 _amount) external onlyOwner {
        return _burn(_account, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "../abstract/JuiceboxProject.sol";

/// @dev This contract is an example of how you can use Juicebox to fund your own project.
contract YourContract is JuiceboxProject {
    constructor(uint256 _projectId, ITerminalDirectory _directory)
        JuiceboxProject(_projectId, _directory)
    {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./abstract/JuiceboxProject.sol";

/// @dev For testing purposes.
contract ExampleJuiceboxProject is JuiceboxProject {
    constructor(uint256 _projectId, ITerminalDirectory _terminalDirectory)
        JuiceboxProject(_projectId, _terminalDirectory)
    {}

    function takeFee(
        uint256 _amount,
        address _beneficiary,
        string calldata _memo,
        bool _preferUnstakedTickets
    ) external {
        _takeFee(_amount, _beneficiary, _memo, _preferUnstakedTickets);
    }
}

