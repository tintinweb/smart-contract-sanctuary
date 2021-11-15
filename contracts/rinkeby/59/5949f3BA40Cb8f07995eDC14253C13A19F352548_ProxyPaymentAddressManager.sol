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
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITickets is IERC20 {
    function print(address _account, uint256 _amount) external;

    function redeem(address _account, uint256 _amount) external;
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

