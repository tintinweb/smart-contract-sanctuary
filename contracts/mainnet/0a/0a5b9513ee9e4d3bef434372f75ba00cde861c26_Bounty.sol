// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./external/interfaces/IERC721VaultFactory.sol";
import "./external/interfaces/ITokenVault.sol";

interface IBounty {
    function redeemBounty(
        IBountyRedeemer redeemer,
        uint256 amount,
        bytes calldata data
    ) external;
}

interface IBountyRedeemer {
    function onRedeemBounty(address initiator, bytes calldata data)
        external
        payable
        returns (bytes32);
}

// @notice Bounty isn't upgradeable, but because it is deploys as a
// static proxy, needs to extend upgradeable contracts.
contract Bounty is
    ReentrancyGuardUpgradeable,
    ERC721HolderUpgradeable,
    IBounty
{
    using Counters for Counters.Counter;

    enum BountyStatus {
        ACTIVE,
        ACQUIRED,
        EXPIRED
    }

    struct Contribution {
        uint256 priorTotalContributed;
        uint256 amount;
    }

    // tokens are minted at a rate of 1 ETH : 1000 tokens
    uint16 internal constant TOKEN_SCALE = 1000;
    uint8 internal constant RESALE_MULTIPLIER = 2;

    // immutable (across clones)
    address public immutable gov;
    IERC721VaultFactory public immutable tokenVaultFactory;

    // immutable (at clone level)
    IERC721 public nftContract;
    uint256 public nftTokenID;
    string public name;
    string public symbol;
    uint256 public contributionCap;
    uint256 public expiryTimestamp;

    // mutables
    mapping(address => Contribution[]) public contributions;
    mapping(address => uint256) public totalContributedByAddress;
    mapping(address => bool) public claimed;
    uint256 public totalContributed;
    uint256 public totalSpent;
    ITokenVault public tokenVault;
    Counters.Counter public contributors;

    event Contributed(
        address indexed contributor,
        uint256 amount,
        uint256 totalContributedByAddress,
        uint256 totalContributed
    );

    event Acquired(uint256 amount);

    event Fractionalized(address tokenVault);

    event Claimed(
        address indexed contributor,
        uint256 tokenAmount,
        uint256 ethAmount
    );

    modifier onlyGov() {
        require(msg.sender == gov, "Bounty:: only callable by gov");
        _;
    }

    constructor(address _gov, IERC721VaultFactory _tokenVaultFactory) {
        gov = _gov;
        tokenVaultFactory = _tokenVaultFactory;
    }

    function initialize(
        IERC721 _nftContract,
        uint256 _nftTokenID,
        string memory _name,
        string memory _symbol,
        uint256 _contributionCap,
        uint256 _duration
    ) external initializer {
        __ReentrancyGuard_init();
        __ERC721Holder_init();

        nftContract = _nftContract;
        nftTokenID = _nftTokenID;
        name = _name;
        symbol = _symbol;
        contributionCap = _contributionCap;
        expiryTimestamp = block.timestamp + _duration;

        require(
            IERC721(nftContract).ownerOf(nftTokenID) != address(0),
            "Bounty::initialize: Token does not exist"
        );
    }

    // @notice contribute (via msg.value) to active bounty as long as the contribution cap has not been reached
    function contribute() external payable nonReentrant {
        require(
            status() == BountyStatus.ACTIVE,
            "Bounty::contribute: bounty not active"
        );
        address _contributor = msg.sender;
        uint256 _amount = msg.value;
        require(_amount > 0, "Bounty::contribute: must contribute more than 0");
        require(
            totalContributed < contributionCap,
            "Bounty::contribute: at max contributions"
        );

        if (contributions[_contributor].length == 0) {
            contributors.increment();
        }

        Contribution memory _contribution = Contribution({
            amount: _amount,
            priorTotalContributed: totalContributed
        });
        contributions[_contributor].push(_contribution);
        totalContributedByAddress[_contributor] =
            totalContributedByAddress[_contributor] +
            _amount;
        totalContributed = totalContributed + _amount;
        emit Contributed(
            _contributor,
            _amount,
            totalContributedByAddress[_contributor],
            totalContributed
        );
    }

    // @notice uses the redeemer to swap `_amount` ETH for the NFT
    // @param _redeemer The callback to acquire the NFT
    // @param _amount The amount of the bounty to redeem. Must be <= MIN(totalContributed, contributionCap)
    // @param _data Arbitrary calldata for the callback
    function redeemBounty(
        IBountyRedeemer _redeemer,
        uint256 _amount,
        bytes calldata _data
    ) external override nonReentrant {
        require(
            status() == BountyStatus.ACTIVE,
            "Bounty::redeemBounty: bounty isn't active"
        );
        require(totalSpent == 0, "Bounty::redeemBounty: already acquired");
        require(_amount > 0, "Bounty::redeemBounty: cannot redeem for free");
        require(
            _amount <= totalContributed && _amount <= contributionCap,
            "Bounty::redeemBounty: not enough funds"
        );
        totalSpent = _amount;
        require(
            _redeemer.onRedeemBounty{value: _amount}(msg.sender, _data) ==
                keccak256("IBountyRedeemer.onRedeemBounty"),
            "Bounty::redeemBounty: callback failed"
        );
        require(
            IERC721(nftContract).ownerOf(nftTokenID) == address(this),
            "Bounty::redeemBounty: NFT not delivered"
        );
        emit Acquired(_amount);
    }

    // @notice Kicks off fractionalization once the NFT is acquired
    // @dev Also triggered by the first claim()
    function fractionalize() external nonReentrant {
        require(
            status() == BountyStatus.ACQUIRED,
            "Bounty::fractionalize: NFT not yet acquired"
        );
        _fractionalizeNFTIfNeeded();
    }

    // @notice Claims any tokens or eth for `_contributor` from active or expired bounties
    // @dev msg.sender does not necessarily match `_contributor`
    // @dev O(N) where N = number of contributions by `_contributor`
    // @param _contributor The address of the contributor to claim tokens for
    function claim(address _contributor) external nonReentrant {
        BountyStatus _status = status();
        require(
            _status != BountyStatus.ACTIVE,
            "Bounty::claim: bounty still active"
        );
        require(
            totalContributedByAddress[_contributor] != 0,
            "Bounty::claim: not a contributor"
        );
        require(
            !claimed[_contributor],
            "Bounty::claim: bounty already claimed"
        );
        claimed[_contributor] = true;

        if (_status == BountyStatus.ACQUIRED) {
            _fractionalizeNFTIfNeeded();
        }

        (uint256 _tokenAmount, uint256 _ethAmount) = claimAmounts(_contributor);

        if (_ethAmount > 0) {
            _transferETH(_contributor, _ethAmount);
        }
        if (_tokenAmount > 0) {
            _transferTokens(_contributor, _tokenAmount);
        }
        emit Claimed(_contributor, _tokenAmount, _ethAmount);
    }

    // @notice (GOV ONLY) emergency: withdraw stuck ETH
    function emergencyWithdrawETH(uint256 _value) external onlyGov {
        _transferETH(gov, _value);
    }

    // @notice (GOV ONLY) emergency: execute arbitrary calls from contract
    function emergencyCall(address _contract, bytes memory _calldata)
        external
        onlyGov
        returns (bool _success, bytes memory _returnData)
    {
        (_success, _returnData) = _contract.call(_calldata);
        require(_success, string(_returnData));
    }

    // @notice (GOV ONLY) emergency: immediately expires bounty
    function emergencyExpire() external onlyGov {
        expiryTimestamp = block.timestamp;
    }

    // @notice The amount of tokens and ETH that can or have been claimed by `_contributor`
    // @dev Check `claimed(address)` to see if already claimed
    // @param _contributor The address of the contributor to compute amounts for.
    function claimAmounts(address _contributor)
        public
        view
        returns (uint256 _tokenAmount, uint256 _ethAmount)
    {
        require(
            status() != BountyStatus.ACTIVE,
            "Bounty::claimAmounts: bounty still active"
        );
        if (totalSpent > 0) {
            uint256 _ethUsed = ethUsedForAcquisition(_contributor);
            if (_ethUsed > 0) {
                _tokenAmount = valueToTokens(_ethUsed);
            }
            _ethAmount = totalContributedByAddress[_contributor] - _ethUsed;
        } else {
            _ethAmount = totalContributedByAddress[_contributor];
        }
    }

    // @notice The amount of the contributor's ETH used to acquire the NFT
    // @notice Tokens owed will be proportional to eth used.
    // @notice ETH contributed = ETH used in acq + ETH left to be claimed
    // @param _contributor The address of the contributor to compute eth usd
    function ethUsedForAcquisition(address _contributor)
        public
        view
        returns (uint256 _total)
    {
        require(
            totalSpent > 0,
            "Bounty::ethUsedForAcquisition: NFT not acquired yet"
        );
        // load from storage once and reuse
        uint256 _totalSpent = totalSpent;
        Contribution[] memory _contributions = contributions[_contributor];
        for (uint256 _i = 0; _i < _contributions.length; _i++) {
            Contribution memory _contribution = _contributions[_i];
            if (
                _contribution.priorTotalContributed + _contribution.amount <=
                _totalSpent
            ) {
                _total = _total + _contribution.amount;
            } else if (_contribution.priorTotalContributed < _totalSpent) {
                uint256 _amountUsed = _totalSpent -
                    _contribution.priorTotalContributed;
                _total = _total + _amountUsed;
                break;
            } else {
                break;
            }
        }
    }

    // @notice Computes the status of the bounty
    // Valid state transitions:
    // EXPIRED
    // ACTIVE -> EXPIRED
    // ACTIVE -> ACQUIRED
    function status() public view returns (BountyStatus) {
        if (totalSpent > 0) {
            return BountyStatus.ACQUIRED;
        } else if (block.timestamp >= expiryTimestamp) {
            return BountyStatus.EXPIRED;
        } else {
            return BountyStatus.ACTIVE;
        }
    }

    // @dev Helper function for translating ETH contributions into token amounts
    function valueToTokens(uint256 _value)
        public
        pure
        returns (uint256 _tokens)
    {
        _tokens = _value * TOKEN_SCALE;
    }

    function _transferETH(address _to, uint256 _value) internal {
        // guard against rounding errors
        uint256 _balance = address(this).balance;
        if (_value > _balance) {
            _value = _balance;
        }
        payable(_to).transfer(_value);
    }

    function _transferTokens(address _to, uint256 _value) internal {
        // guard against rounding errors
        uint256 _balance = tokenVault.balanceOf(address(this));
        if (_value > _balance) {
            _value = _balance;
        }
        tokenVault.transfer(_to, _value);
    }

    function _fractionalizeNFTIfNeeded() internal {
        if (address(tokenVault) != address(0)) {
            return;
        }
        IERC721(nftContract).approve(address(tokenVaultFactory), nftTokenID);
        uint256 _vaultNumber = tokenVaultFactory.mint(
            name,
            symbol,
            address(nftContract),
            nftTokenID,
            valueToTokens(totalSpent),
            totalSpent * RESALE_MULTIPLIER,
            0 // fees
        );
        tokenVault = ITokenVault(tokenVaultFactory.vaults(_vaultNumber));
        tokenVault.updateCurator(address(0));
        emit Fractionalized(address(tokenVault));
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

pragma solidity ^0.8.0;

import "../IERC721ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721HolderUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    function __ERC721Holder_init() internal initializer {
        __ERC721Holder_init_unchained();
    }

    function __ERC721Holder_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

interface IERC721VaultFactory {
    /// @notice the mapping of vault number to vault address
    function vaults(uint256) external returns (address);

    /// @notice the function to mint a new vault
    /// @param _name the desired name of the vault
    /// @param _symbol the desired sumbol of the vault
    /// @param _token the ERC721 token address fo the NFT
    /// @param _id the uint256 ID of the token
    /// @param _listPrice the initial price of the NFT
    /// @return the ID of the vault
    function mint(
        string memory _name,
        string memory _symbol,
        address _token,
        uint256 _id,
        uint256 _supply,
        uint256 _listPrice,
        uint256 _fee
    ) external returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

interface ITokenVault {
    /// @notice allow curator to update the curator address
    /// @param _curator the new curator
    function updateCurator(address _curator) external;

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) external view returns (uint256);
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

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
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

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
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