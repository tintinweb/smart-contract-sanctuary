/**
 *Submitted for verification at Etherscan.io on 2021-08-30
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

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

// ============ External Imports: Inherited Contracts ============
// NOTE: we inherit from OpenZeppelin upgradeable contracts
// because of the proxy structure used for cheaper deploys
// (the proxies are NOT actually upgradeable)
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

// ============ External Imports: External Contracts & Contract Interfaces ============
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
    function mint(string memory _name, string memory _symbol, address _token, uint256 _id, uint256 _supply, uint256 _listPrice, uint256 _fee) external returns(uint256);
}

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
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) external view returns (uint256);
}

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}


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



interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);
}


// ============ Internal Imports ============
// import {RaribleWrapper} from "./RaribleWrapper.sol";

interface IExchangeV2 {

    struct AssetType {
        bytes4 assetClass;
        bytes data;
    }

    struct Asset {
        AssetType assetType;
        uint value;
    }

    struct Order {
        address maker;
        Asset makeAsset;
        address taker;
        Asset takeAsset;
        uint salt;
        uint start;
        uint end;
        bytes4 dataType;
        bytes data;
    }

    function upsertOrder(Order memory order) external payable;

    function cancel(Order memory order) external;

    function matchOrders(
        Order memory orderLeft,
        bytes memory signatureLeft,
        Order memory orderRight,
        bytes memory signatureRight
    ) external payable;

}


contract PartyRarible is ReentrancyGuardUpgradeable, ERC721HolderUpgradeable {
    // ============ Enums ============

    // State Transitions:
    //   (1) AUCTION_ACTIVE on deploy
    //   (2) AUCTION_WON or AUCTION_LOST on finalize()
    enum PartyStatus {AUCTION_ACTIVE, AUCTION_WON, AUCTION_LOST}

    // ============ Structs ============

    struct Contribution {
        uint256 amount;
        uint256 previousTotalContributedToParty;
    }

    // ============ Internal Constants ============

    // tokens are minted at a rate of 1 ETH : 1000 tokens
    uint16 internal constant TOKEN_SCALE = 1000;
    // PartyRarible pays a 5% fee to PartyDAO
    uint8 internal constant FEE_PERCENT = 5;

    // ============ Immutables ============

    address public immutable partyDAOMultisig;
    address public immutable tokenVaultFactory;
    address public immutable weth;

    // ============ Public Not-Mutated Storage ============

    // market wrapper contract exposing interface for
    // market auctioning the NFT
    address public exchange;
    // NFT contract
    address public nftContract;
    // Fractionalized NFT vault responsible for post-auction value capture
    address public tokenVault;
    // ID of token within NFT contract
    uint256 public tokenId;
    // ERC-20 name and symbol for fractional tokens
    string public name;
    string public symbol;

    // ============ Public Mutable Storage ============

    // state of the contract
    PartyStatus public partyStatus;
    // total ETH deposited by all contributors
    uint256 public totalContributedToParty;
    // the highest bid submitted by PartyRarible
    uint256 public highestBid;
    // the total spent by PartyRarible on the auction;
    // 0 if the NFT is lost; highest bid + 5% PartyDAO fee if NFT is won
    uint256 public totalSpent;
    // contributor => array of Contributions
    mapping(address => Contribution[]) public contributions;
    // contributor => total amount contributed
    mapping(address => uint256) public totalContributed;
    // contributor => true if contribution has been claimed
    mapping(address => bool) public claimed;

    IExchangeV2.AssetType public ethAssetType;
    IExchangeV2.AssetType public nftAssetType;
    // ============ Events ============

    event Contributed(
        address indexed contributor,
        uint256 amount,
        uint256 previousTotalContributedToParty,
        uint256 totalFromContributor
    );

    event Make(address maker, IExchangeV2.AssetType makeAsset, address taker, IExchangeV2.AssetType takeAsset, uint256 salt);

    event Bid(uint256 amount);

    event Finalized(PartyStatus result, uint256 totalSpent, uint256 fee, uint256 totalContributed);

    event Claimed(
        address indexed contributor,
        uint256 totalContributed,
        uint256 excessContribution,
        uint256 tokenAmount
    );

    // ======== Modifiers =========

    modifier onlyPartyDAO() {
        require(
            msg.sender == partyDAOMultisig,
            "PartyRarible:: only PartyDAO multisig"
        );
        _;
    }

    // ======== Constructor =========

    constructor(
        address _partyDAOMultisig,
        address _tokenVaultFactory,
        address _weth
    ) {
        partyDAOMultisig = _partyDAOMultisig;
        tokenVaultFactory = _tokenVaultFactory;
        weth = _weth;
    }

    // ======== Initializer =========

    function initialize(
        address _exchange,
        address _nftOwner,
        address _nftContract,
        uint256 _tokenId,
        IExchangeV2.AssetType memory _ethAssetType,
        IExchangeV2.AssetType memory _nftAssetType,
        string memory _name,
        string memory _symbol
    ) external initializer {
        // initialize ReentrancyGuard and ERC721Holder
        __ReentrancyGuard_init();
        __ERC721Holder_init();
        // set storage variables
        exchange = _exchange;
        nftContract = _nftContract;
        tokenId = _tokenId;
        ethAssetType = _ethAssetType;
        nftAssetType = _nftAssetType;
        _nftOwner = _getOwner();
        name = _name;
        symbol = _symbol;
        // validate token exists
        require(_nftOwner != address(0), "PartyRarible::initialize: NFT getOwner failed");
        // validate auction exists
        // require(
        //     ExchangeV2(_exchange).auctionIdMatchesToken(
        //         _auctionId,
        //         _nftContract,
        //         _tokenId
        //     ),
        //     "PartyRarible::initialize: auctionId doesn't match token"
        // );
    }

    // ======== External: Contribute =========

    /**
     * @notice Contribute to the PartyRarible's treasury
     * while the auction is still open
     * @dev Emits a Contributed event upon success; callable by anyone
     */
    function contribute() external payable nonReentrant {
        require(
            partyStatus == PartyStatus.AUCTION_ACTIVE,
            "PartyRarible::contribute: auction not active"
        );
        address _contributor = msg.sender;
        uint256 _amount = msg.value;
        require(_amount > 0, "PartyRarible::contribute: must contribute more than 0");
        // get the current contract balance
        uint256 _previousTotalContributedToParty = totalContributedToParty;
        // add contribution to contributor's array of contributions
        Contribution memory _contribution =
            Contribution({
                amount: _amount,
                previousTotalContributedToParty: _previousTotalContributedToParty
            });
        contributions[_contributor].push(_contribution);
        // add to contributor's total contribution
        totalContributed[_contributor] =
            totalContributed[_contributor] +
            _amount;
        // add to party's total contribution & emit event
        totalContributedToParty = totalContributedToParty + _amount;
        emit Contributed(
            _contributor,
            _amount,
            _previousTotalContributedToParty,
            totalContributed[_contributor]
        );
    }

    // ======== External: Bid =========

    /**
     * @notice Submit a bid to the Market
     * @dev Reverts if insufficient funds to place the bid and pay PartyDAO fees,
     * or if any external auction checks fail (including if PartyRarible is current high bidder)
     * Emits a Bid event upon success.
     * Callable by any contributor
     */
    function make() external nonReentrant {
        require(
            partyStatus == PartyStatus.AUCTION_ACTIVE,
            "PartyRarible::bid: auction not active"
        );
        require(
            totalContributed[msg.sender] > 0,
            "PartyRarible::bid: only contributors can bid"
        );
        uint256 _bid = totalContributedToParty;
        IExchangeV2.Asset memory makeAsset = IExchangeV2.Asset(ethAssetType, _bid);
        IExchangeV2.Asset memory takeAsset = IExchangeV2.Asset(nftAssetType, 1);
        bytes4 empty4;
        bytes memory empty;
        IExchangeV2.Order memory order = IExchangeV2.Order({
                maker: address(this),
                makeAsset: makeAsset,
                taker: address(0),
                takeAsset: takeAsset,
                salt: 0,
                start: 0,
                end: 0,
                dataType: empty4,
                data: empty
            });
        IExchangeV2(exchange).upsertOrder(order);
        // update highest bid submitted & emit success event
        highestBid = _bid;
        emit Make(address(this), makeAsset.assetType, address(0), takeAsset.assetType, 0);
    }

    function take(IExchangeV2.Order calldata makeOrder, bytes calldata makeSignature) external nonReentrant {
        require(
            partyStatus == PartyStatus.AUCTION_ACTIVE,
            "PartyRarible::bid: auction not active"
        );
        require(
            totalContributed[msg.sender] > 0,
            "PartyRarible::bid: only contributors can bid"
        );
        uint256 _bid = totalContributedToParty;
        IExchangeV2.Asset memory makeAsset = IExchangeV2.Asset(nftAssetType, 1);
        IExchangeV2.Asset memory takeAsset = IExchangeV2.Asset(ethAssetType, _bid);
        bytes4 empty4;
        bytes memory empty;
        IExchangeV2.Order memory takeOrder = IExchangeV2.Order({
                maker: _getOwner(),
                makeAsset: makeAsset,
                taker: address(this),
                takeAsset: takeAsset,
                salt: 0,
                start: 0,
                end: 0,
                dataType: empty4,
                data: empty
            });
        uint256 zero = 0;
        bytes memory takeSignature = abi.encodePacked(zero);
        IExchangeV2(exchange).matchOrders(makeOrder, makeSignature, takeOrder, takeSignature);
        // update highest bid submitted & emit success event
        highestBid = _bid;
        emit Bid(_bid);
    }
    // ======== External: Finalize =========

    bytes4 constant internal MAGICVALUE = 0x1626ba7e;
    function isValidSignature(
        bytes32 _hash,
        bytes memory _signature)
        public
        view
        returns (bytes4 magicValue) {
        return MAGICVALUE;
    }

    /**
     * @notice Finalize the state of the auction
     * @dev Emits a Finalized event upon success; callable by anyone
     */
    function finalize() external nonReentrant {
        require(
            partyStatus == PartyStatus.AUCTION_ACTIVE,
            "PartyRarible::finalize: auction not active"
        );
        // finalize auction if it hasn't already been done
        // if (!IExchangeV2(exchange).isFinalized(auctionId)) {
        //     IExchangeV2(exchange).finalize(auctionId);
        // }
        // after the auction has been finalized,
        // if the NFT is owned by the PartyRarible, then the PartyRarible won the auction
        address _owner = _getOwner();
        partyStatus = _owner == address(this) ? PartyStatus.AUCTION_WON : PartyStatus.AUCTION_LOST;
        uint256 _fee;
        // if the auction was won,
        if (partyStatus == PartyStatus.AUCTION_WON) {
            // transfer 5% fee to PartyDAO
            _fee = _getFee(highestBid);
            _transferETHOrWETH(partyDAOMultisig, _fee);
            // record total spent by auction + PartyDAO fees
            totalSpent = highestBid + _fee;
            // deploy fractionalized NFT vault
            // and mint fractional ERC-20 tokens
            _fractionalizeNFT(totalSpent);
        }
        // set the contract status & emit result
        emit Finalized(partyStatus, totalSpent, _fee, totalContributedToParty);
    }

    // ======== External: Claim =========

    /**
     * @notice Claim the tokens and excess ETH owed
     * to a single contributor after the auction has ended
     * @dev Emits a Claimed event upon success
     * callable by anyone (doesn't have to be the contributor)
     * @param _contributor the address of the contributor
     */
    function claim(address _contributor) external nonReentrant {
        // ensure auction has finalized
        require(
            partyStatus != PartyStatus.AUCTION_ACTIVE,
            "PartyRarible::claim: auction not finalized"
        );
        // ensure contributor submitted some ETH
        require(
            totalContributed[_contributor] != 0,
            "PartyRarible::claim: not a contributor"
        );
        // ensure the contributor hasn't already claimed
        require(
            !claimed[_contributor],
            "PartyRarible::claim: contribution already claimed"
        );
        // mark the contribution as claimed
        claimed[_contributor] = true;
        // calculate the amount of fractional NFT tokens owed to the user
        // based on how much ETH they contributed towards the auction,
        // and the amount of excess ETH owed to the user
        (uint256 _tokenAmount, uint256 _ethAmount) =
            _calculateTokensAndETHOwed(_contributor);
        // transfer tokens to contributor for their portion of ETH used
        if (_tokenAmount > 0) {
            _transferTokens(_contributor, _tokenAmount);
        }
        // if there is excess ETH, send it back to the contributor
        if (_ethAmount > 0) {
            _transferETHOrWETH(_contributor, _ethAmount);
        }
        emit Claimed(
            _contributor,
            totalContributed[_contributor],
            _ethAmount,
            _tokenAmount
        );
    }

    // ======== External: Emergency Escape Hatches (PartyDAO Multisig Only) =========

    /**
     * @notice Escape hatch: in case of emergency,
     * PartyDAO can use emergencyWithdrawEth to withdraw
     * ETH stuck in the contract
     */
    function emergencyWithdrawEth(uint256 _value)
        external
        onlyPartyDAO
    {
        _transferETHOrWETH(partyDAOMultisig, _value);
    }

    /**
     * @notice Escape hatch: in case of emergency,
     * PartyDAO can use emergencyCall to call an external contract
     * (e.g. to withdraw a stuck NFT or stuck ERC-20s)
     */
    function emergencyCall(address _contract, bytes memory _calldata)
        external
        onlyPartyDAO
        returns (bool _success, bytes memory _returnData)
    {
        (_success, _returnData) = _contract.call(_calldata);
        require(_success, string(_returnData));
    }

    /**
     * @notice Escape hatch: in case of emergency,
     * PartyDAO can force the PartyRarible to finalize with status LOST
     * (e.g. if finalize is not callable)
     */
    function emergencyForceLost()
        external
        onlyPartyDAO
    {
        // set partyStatus to LOST
        partyStatus = PartyStatus.AUCTION_LOST;
        // emit Finalized event
        emit Finalized(partyStatus, 0, 0, totalContributedToParty);
    }

    // ======== Public: Utility Calculations =========

    /**
     * @notice Convert ETH value to equivalent token amount
     */
    function valueToTokens(uint256 _value)
        public
        pure
        returns (uint256 _tokens)
    {
        _tokens = _value * TOKEN_SCALE;
    }

    // ============ Internal: Bid ============

    /**
     * @notice The maximum bid that can be submitted
     * while leaving 5% fee for PartyDAO
     * @return _maxBid the maximum bid
     */
    function _getMaximumBid() internal view returns (uint256 _maxBid) {
        _maxBid = (totalContributedToParty * 100) / (100 + FEE_PERCENT);
    }

    /**
     * @notice Calculate 5% fee for PartyDAO
     * NOTE: Remove this fee causes a critical vulnerability
     * allowing anyone to exploit a PartyRarible via price manipulation.
     * See Security Review in README for more info.
     * @return _fee 5% of the given amount
     */
    function _getFee(uint256 _amount) internal pure returns (uint256 _fee) {
        _fee = (_amount * FEE_PERCENT) / 100;
    }

    // ============ Internal: Finalize ============

    /**
    * @notice Query the NFT contract to get the token owner
    * @dev nftContract must implement the ERC-721 token standard exactly:
    * function ownerOf(uint256 _tokenId) external view returns (address);
    * See https://eips.ethereum.org/EIPS/eip-721
    * @dev Returns address(0) if NFT token or NFT contract
    * no longer exists (token burned or contract self-destructed)
    * @return _owner the owner of the NFT
    */
    function _getOwner() internal returns (address _owner) {
        (bool success, bytes memory returnData) =
            nftContract.call(
                abi.encodeWithSignature(
                    "ownerOf(uint256)",
                    tokenId
                )
        );
        if (success && returnData.length > 0) {
            _owner = abi.decode(returnData, (address));
        }
    }

    /**
     * @notice Upon winning the auction, transfer the NFT
     * to fractional.art vault & mint fractional ERC-20 tokens
     */
    function _fractionalizeNFT(uint256 _totalSpent) internal {
        // approve fractionalized NFT Factory to withdraw NFT
        IERC721Metadata(nftContract).approve(tokenVaultFactory, tokenId);
        // deploy fractionalized NFT vault
        uint256 vaultNumber =
            IERC721VaultFactory(tokenVaultFactory).mint(
                name,
                symbol,
                nftContract,
                tokenId,
                valueToTokens(_totalSpent),
                _totalSpent,
                0
            );
        // store token vault address to storage
        tokenVault = IERC721VaultFactory(tokenVaultFactory).vaults(vaultNumber);
        // transfer curator to null address
        ITokenVault(tokenVault).updateCurator(address(0));
    }

    // ============ Internal: Claim ============

    /**
     * @notice Calculate the amount of fractional NFT tokens owed to the contributor
     * based on how much ETH they contributed towards the auction,
     * and the amount of excess ETH owed to the contributor
     * based on how much ETH they contributed *not* used towards the auction
     * @param _contributor the address of the contributor
     * @return _tokenAmount the amount of fractional NFT tokens owed to the contributor
     * @return _ethAmount the amount of excess ETH owed to the contributor
     */
    function _calculateTokensAndETHOwed(address _contributor)
        internal
        view
        returns (uint256 _tokenAmount, uint256 _ethAmount)
    {
        uint256 _totalContributed = totalContributed[_contributor];
        if (partyStatus == PartyStatus.AUCTION_WON) {
            // calculate the amount of this contributor's ETH
            // that was used for the winning bid
            uint256 _totalUsedForBid = _totalEthUsedForBid(_contributor);
            if (_totalUsedForBid > 0) {
                _tokenAmount = valueToTokens(_totalUsedForBid);
            }
            // the rest of the contributor's ETH should be returned
            _ethAmount = _totalContributed - _totalUsedForBid;
        } else {
            // if the auction was lost, no ETH was spent;
            // all of the contributor's ETH should be returned
            _ethAmount = _totalContributed;
        }
    }

    /**
     * @notice Calculate the total amount of a contributor's funds that were
     * used towards the winning auction bid
     * @param _contributor the address of the contributor
     * @return _total the sum of the contributor's funds that were
     * used towards the winning auction bid
     */
    function _totalEthUsedForBid(address _contributor)
        internal
        view
        returns (uint256 _total)
    {
        // get all of the contributor's contributions
        Contribution[] memory _contributions = contributions[_contributor];
        for (uint256 i = 0; i < _contributions.length; i++) {
            // calculate how much was used from this individual contribution
            uint256 _amount = _ethUsedForBid(_contributions[i]);
            // if we reach a contribution that was not used,
            // no subsequent contributions will have been used either,
            // so we can stop calculating to save some gas
            if (_amount == 0) break;
            _total = _total + _amount;
        }
    }

    /**
     * @notice Calculate the amount that was used towards
     * the winning auction bid from a single Contribution
     * @param _contribution the Contribution struct
     * @return the amount of funds from this contribution
     * that were used towards the winning auction bid
     */
    function _ethUsedForBid(Contribution memory _contribution)
        internal
        view
        returns (uint256)
    {
        // load total amount spent once from storage
        uint256 _totalSpent = totalSpent;
        if (
            _contribution.previousTotalContributedToParty +
                _contribution.amount <=
            _totalSpent
        ) {
            // contribution was fully used
            return _contribution.amount;
        } else if (
            _contribution.previousTotalContributedToParty < _totalSpent
        ) {
            // contribution was partially used
            return _totalSpent - _contribution.previousTotalContributedToParty;
        }
        // contribution was not used
        return 0;
    }

    // ============ Internal: TransferTokens ============

    /**
    * @notice Transfer tokens to a recipient
    * @param _to recipient of tokens
    * @param _value amount of tokens
    */
    function _transferTokens(address _to, uint256 _value) internal {
        // guard against rounding errors;
        // if token amount to send is greater than contract balance,
        // send full contract balance
        uint256 _partyBidBalance = ITokenVault(tokenVault).balanceOf(address(this));
        if (_value > _partyBidBalance) {
            _value = _partyBidBalance;
        }
        ITokenVault(tokenVault).transfer(_to, _value);
    }

    // ============ Internal: TransferEthOrWeth ============

    /**
     * @notice Attempt to transfer ETH to a recipient;
     * if transferring ETH fails, transfer WETH insteads
     * @param _to recipient of ETH or WETH
     * @param _value amount of ETH or WETH
     */
    function _transferETHOrWETH(address _to, uint256 _value) internal {
        // guard against rounding errors;
        // if ETH amount to send is greater than contract balance,
        // send full contract balance
        if (_value > address(this).balance) {
            _value = address(this).balance;
        }
        // Try to transfer ETH to the given recipient.
        if (!_attemptETHTransfer(_to, _value)) {
            // If the transfer fails, wrap and send as WETH
            IWETH(weth).deposit{value: _value}();
            IWETH(weth).transfer(_to, _value);
            // At this point, the recipient can unwrap WETH.
        }
    }

    /**
     * @notice Attempt to transfer ETH to a recipient
     * @dev Sending ETH is not guaranteed to succeed
     * this method will return false if it fails.
     * We will limit the gas used in transfers, and handle failure cases.
     * @param _to recipient of ETH
     * @param _value amount of ETH
     */
    function _attemptETHTransfer(address _to, uint256 _value)
        internal
        returns (bool)
    {
        // Here increase the gas limit a reasonable amount above the default, and try
        // to send ETH to the recipient.
        // NOTE: This might allow the recipient to attempt a limited reentrancy attack.
        (bool success, ) = _to.call{value: _value, gas: 30000}("");
        return success;
    }
}