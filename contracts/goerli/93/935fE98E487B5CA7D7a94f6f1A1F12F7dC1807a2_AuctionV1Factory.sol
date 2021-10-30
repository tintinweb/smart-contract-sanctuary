/**
 *Submitted for verification at Etherscan.io on 2021-10-28
*/

/*
 * Auction V1 Factory for cryptoWine project
 *
 * Developed by Capacity Blockchain Solutions GmbH <capacity.at>
 * for Cryptoagri GmbH <cryptowine.at>
 *
 * Any usage of or interaction with this set of contracts is subject to the
 * Terms & Conditions available at https://cryptowine.at/
 */

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol

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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol

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

// File: @openzeppelin/contracts/proxy/Clones.sol

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// File: contracts/ENSReverseRegistrarI.sol

/*
 * Interfaces for ENS Reverse Registrar
 * See https://github.com/ensdomains/ens/blob/master/contracts/ReverseRegistrar.sol for full impl
 * Also see https://github.com/wealdtech/wealdtech-solidity/blob/master/contracts/ens/ENSReverseRegister.sol
 *
 * Use this as follows (registryAddress is the address of the ENS registry to use):
 * -----
 * // This hex value is caclulated by namehash('addr.reverse')
 * bytes32 public constant ENS_ADDR_REVERSE_NODE = 0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2;
 * function registerReverseENS(address registryAddress, string memory calldata) external {
 *     require(registryAddress != address(0), "need a valid registry");
 *     address reverseRegistrarAddress = ENSRegistryOwnerI(registryAddress).owner(ENS_ADDR_REVERSE_NODE)
 *     require(reverseRegistrarAddress != address(0), "need a valid reverse registrar");
 *     ENSReverseRegistrarI(reverseRegistrarAddress).setName(name);
 * }
 * -----
 * or
 * -----
 * function registerReverseENS(address reverseRegistrarAddress, string memory calldata) external {
 *    require(reverseRegistrarAddress != address(0), "need a valid reverse registrar");
 *     ENSReverseRegistrarI(reverseRegistrarAddress).setName(name);
 * }
 * -----
 * ENS deployments can be found at https://docs.ens.domains/ens-deployments
 * E.g. Etherscan can be used to look up that owner on those contracts.
 * namehash.hash("addr.reverse") == "0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2"
 * Ropsten: ens.owner(namehash.hash("addr.reverse")) == "0x6F628b68b30Dc3c17f345c9dbBb1E483c2b7aE5c"
 * Mainnet: ens.owner(namehash.hash("addr.reverse")) == "0x084b1c3C81545d370f3634392De611CaaBFf8148"
 */

interface ENSRegistryOwnerI {
    function owner(bytes32 node) external view returns (address);
}

interface ENSReverseRegistrarI {
    event NameChanged(bytes32 indexed node, string name);
    /**
     * @dev Sets the `name()` record for the reverse ENS record associated with
     * the calling account.
     * @param name The name to set for this address.
     * @return The ENS node hash of the reverse record.
     */
    function setName(string calldata name) external returns (bytes32);
}

// File: contracts/AgriDataI.sol

/*
 * Interface for data storage of the cryptoAgri system.
 */

interface AgriDataI {

    event AddressChanged(string name, address previousAddress, address newAddress);

    /**
     * @dev Set an address for a name.
     */
    function setAddress(string memory name, address newAddress) external;

    /**
     * @dev Get an address for a name.
     */
    function getAddress(string memory name) external view returns (address);
}

// File: contracts/MultiOracleRequestI.sol

/*
 * Interface for requests to the multi-rate oracle (for EUR/ETH and ERC20)
 * Copy this to projects that need to access the oracle.
 * This is a strict superset of OracleRequestI to ensure compatibility.
 * See rate-oracle project for implementation.
 */

interface MultiOracleRequestI {

    /**
     * @dev Number of wei per EUR
     */
    function EUR_WEI() external view returns (uint256); // solhint-disable func-name-mixedcase

    /**
     * @dev Timestamp of when the last update for the ETH rate occurred
     */
    function lastUpdate() external view returns (uint256);

    /**
     * @dev Number of EUR per ETH (rounded down!)
     */
    function ETH_EUR() external view returns (uint256); // solhint-disable func-name-mixedcase

    /**
     * @dev Number of EUR cent per ETH (rounded down!)
     */
    function ETH_EURCENT() external view returns (uint256); // solhint-disable func-name-mixedcase

    /**
     * @dev True for ERC20 tokens that are supported by this oracle, false otherwise
     */
    function tokenSupported(address tokenAddress) external view returns(bool);

    /**
     * @dev Number of token units per EUR
     */
    function eurRate(address tokenAddress) external view returns(uint256);

    /**
     * @dev Timestamp of when the last update for the specific ERC20 token rate occurred
     */
    function lastRateUpdate(address tokenAddress) external view returns (uint256);

    /**
     * @dev Emitted on rate update - using address(0) as tokenAddress for ETH updates
     */
    event RateUpdated(address indexed tokenAddress, uint256 indexed eurRate);

}

// File: contracts/ShippingManagerI.sol

/*
 * Interface for shipping manager.
 */

interface ShippingManagerI {

    enum ShippingStatus{
        Initial,
        Sold,
        ShippingSubmitted,
        ShippingConfirmed
    }

    /**
     * @dev Emitted when an authorizer is set (or unset).
     */
    event AuthorizerSet(address indexed tokenAddress, address indexed authorizerAddress, bool enabled);

    /**
     * @dev Emitted when a token gets enabled (or disabled).
     */
    event TokenSupportSet(address indexed tokenAddress, bool enabled);

    /**
     * @dev Emitted when a shop authorization is set (or unset).
     */
    event ShopAuthorizationSet(address indexed tokenAddress, address indexed shopAddress, bool authorized);

    /**
     * @dev Emitted when the shipping status is set directly.
     */
    event ShippingStatusSet(address indexed tokenAddress, uint256 indexed tokenId, ShippingStatus shippingStatus);

    /**
     * @dev Emitted when the owner submits shipping data.
     */
    event ShippingSubmitted(address indexed owner, address[] tokenAddresses, uint256[][] tokenIds, uint256 shippingId, uint256 shippingPaymentWei);

    /**
     * @dev Emitted when the shipping service failed to ship the physical item and re-set the status.
     */
    event ShippingFailed(address indexed owner, address indexed tokenAddress, uint256 indexed tokenId, string reason);

    /**
     * @dev Emitted when the shipping service confirms they can and will ship the physical item with the provided delivery information.
     */
    event ShippingConfirmed(address indexed owner, address indexed tokenAddress, uint256 indexed tokenId);

    /**
     * @dev True if the given `authorizerAddress` can authorize shops for the given `tokenAddress`.
     */
    function isAuthorizer(address tokenAddress, address authorizerAddress) external view returns(bool);

    /**
     * @dev Set an address as being able to authorize shops for the given token.
     */
    function setAuthorizer(address tokenAddress, address authorizerAddress, bool enabled) external;

    /**
     * @dev True for ERC-721 tokens that are supported by this shipping manager, false otherwise.
     */
    function tokenSupported(address tokenAddress) external view returns(bool);

    /**
     * @dev Set a token as (un)supported.
     */
    function setTokenSupported(address tokenAddress, bool enabled) external;

    /**
     * @dev True if the given `shopAddress` is authorized as a shop for the given `tokenAddress`.
     */
    function authorizedShop(address tokenAddress, address shopAddress) external view returns(bool);

    /**
     * @dev Set a shop as (un)authorized for a specific token. When enabling, also sets token as supported if it is not yet.
     */
    function setShopAuthorized(address tokenAddress, address shopAddress, bool authorized) external;

    /**
     * @dev The current delivery status for the given asset.
     */
    function deliveryStatus(address tokenAddress, uint256 tokenId) external view returns(ShippingStatus);

    /**
     * @dev Set the shipping status directly. Can only be called by an authorized on-chain shop.
     */
    function setShippingStatus(address tokenAddress, uint256 tokenId, ShippingStatus newStatus) external;

    /**
     * @dev For token owner (after successful purchase): Request shipping.
     * To make sure the correct amount of currency is being paid here (or has already been paid via other means),
     * a signature from shippingControl is required.
     */
    function shipToMe(address[] memory tokenAddresses, uint256[][] memory tokenIds, uint256 shippingId, bytes memory signature) external payable;

    /**
     * @dev For shipping service: Mark shipping as completed/confirmed.
     */
    function confirmShipping(address[] memory tokenAddresses, uint256[][] memory tokenIds) external;

    /**
     * @dev For shipping service: Mark shipping as failed/rejected (due to invalid address).
     */
    function rejectShipping(address[] memory tokenAddresses, uint256[][] memory tokenIds, string memory reason) external;

}

// File: contracts/TaxRegionsI.sol

/*
 * Interface for tax regions list.
 */

interface TaxRegionsI {

    /**
     * @dev Return the VAT permil rate for a given tax region.
     */
    function vatPermilForRegionId(string memory taxRegionIdentifier) external view returns(uint256);

    /**
     * @dev Return the VAT permil rate for a given tax region.
     */
    function vatPermilForRegionHash(bytes32 taxRegionHash) external view returns(uint256);

    /**
     * @dev Get Region Hash for a region identifier string.
     */
    function getRegionHash(string memory taxRegionIdentifier) external view returns(bytes32);

}

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// File: contracts/ERC721SignedTransferI.sol

/*
 * Interface for ERC721 Signed Transfers.
 */

/**
 * @dev Outward-facing interface of a Collections contract.
 */
interface ERC721SignedTransferI is IERC721 {

    /**
     * @dev Emitted when a signed transfer is being executed.
     */
    event SignedTransfer(address operator, address indexed from, address indexed to, uint256 indexed tokenId, uint256 signedTransferNonce);

    /**
     * @dev The signed transfer nonce for an account.
     */
    function signedTransferNonce(address account) external view returns (uint256);

    /**
     * @dev Outward-facing function for signed transfer: assembles the expected data and then calls the internal function to do the rest.
     * Can called by anyone knowing about the right signature, but can only transfer to the given specific target.
     */
    function signedTransfer(uint256 tokenId, address to, bytes memory signature) external;

    /**
     * @dev Outward-facing function for operator-driven signed transfer: assembles the expected data and then calls the internal function to do the rest.
     * Can transfer to any target, but only be called by the trusted operator contained in the signature.
     */
    function signedTransferWithOperator(uint256 tokenId, address to, bytes memory signature) external;

}

// File: contracts/ERC721ExistsI.sol

/*
 * Interface for an ERC721 compliant contract with an exists() function.
 */

/**
 * @dev ERC721 compliant contract with an exists() function.
 */
interface ERC721ExistsI is IERC721 {

    // Returns whether the specified token exists
    function exists(uint256 tokenId) external view returns (bool);

}

// File: contracts/CryptoWineTokenI.sol

/*
 * Interface for functions of the cryptoWine token that need to be accessed by
 * other contracts.
 */

interface CryptoWineTokenI is IERC721Enumerable, ERC721ExistsI, ERC721SignedTransferI {

    /**
     * @dev The base URI of the token.
     */
    function baseURI() external view returns (string memory);

    /**
     * @dev The storage fee per year in EUR cent.
     */
    function storageFeeYearlyEurCent() external view returns (uint256);

    /**
     * @dev The wine ID for a specific asset / token ID.
     */
    function wineID(uint256 tokenId) external view returns (uint256);

    /**
     * @dev The deposit in EUR cent that is available for storage, shipping, etc.
     */
    function depositEurCent(uint256 tokenId) external view returns (uint256);

    /**
     * @dev The start timestamp (unix format, seconds) for storage.
     */
    function storageStart(uint256 tokenId) external view returns (uint256);

    /**
     * @dev Start storage for a specific asset / token ID, with an initial deposit.
     */
    function startStorage(uint256 tokenId, uint256 depositEurCent) external;

    /**
     * @dev The timestamp (unix format, seconds) until which that storage is paid with the deposit.
     */
    function storageValidUntil(uint256 tokenId) external view returns (uint256);

    /**
     * @dev Prolong storage for specific assets / token IDs by depositing more funds via native currency.
     */
    function depositStorageFunds(uint256[] memory _tokenIds, uint256[] memory _amounts) external payable;

    /**
     * @dev Prolong storage for specific assets / token IDs by depositing more funds via an ERC20 token.
     */
    function depositStorageFundTokens(address _payTokenAddress, uint256[] memory _tokenIds, uint256[] memory _payTokenAmounts) external;

}

// File: contracts/AuctionV1FactoryI.sol

/*
 * Interface for cryptoWine auctions V1 Factory.
 */

interface AuctionV1FactoryI {

    /**
     * @dev Emitted when a new auction is created.
     */
    event NewAuction(address auctionAddress);

    /**
     * @dev The agri data contract used with the tokens.
     */
    function agriData() external view returns (AgriDataI);

}

// File: contracts/AuctionV1DeployI.sol

/*
 * cryptoWine Auction V1 deployment interface
 */

interface AuctionV1DeployI {

    function initialRegister() external;

}

// File: contracts/AuctionV1Factory.sol

/*
 * Factory for cryptoWine auctions V1.
 */

contract AuctionV1Factory is AuctionV1FactoryI {

    AgriDataI public agriData;

    address public auctionPrototypeAddress;

    address[] public deployedAuctions;

    constructor(address _agriDataAddress, address _auctionPrototypeAddress)
    {
        agriData = AgriDataI(_agriDataAddress);
        require(address(agriData) != address(0x0), "You need to provide an actual agri data contract.");
        auctionPrototypeAddress = _auctionPrototypeAddress;
        require(auctionPrototypeAddress != address(0x0), "You need to provide an actual prototype address.");
    }

    modifier onlyCreateControl() {
        require(msg.sender == agriData.getAddress("auctionCreateControl"), "Auction createControl key required for this function.");
        _;
    }

    modifier onlyTokenAssignmentControl() {
        require(msg.sender == agriData.getAddress("tokenAssignmentControl"), "tokenAssignmentControl key required for this function.");
        _;
    }

    /*** Get contracts with their ABI ***/

    function oracle()
    public view
    returns (MultiOracleRequestI)
    {
        return MultiOracleRequestI(agriData.getAddress("Oracle"));
    }

    function shippingManager()
    public view
    returns (ShippingManagerI)
    {
        return ShippingManagerI(agriData.getAddress("ShippingManager"));
    }

    function taxRegions()
    public view
    returns (TaxRegionsI)
    {
        return TaxRegionsI(agriData.getAddress("TaxRegions"));
    }

    function assetToken()
    public view
    returns (CryptoWineTokenI)
    {
        return CryptoWineTokenI(agriData.getAddress("CryptoWineToken"));
    }

    /*** Manage auctions ***/

    // Create a new auction, which can own currency and tokens.
    function create()
    public
    onlyCreateControl
    returns (address)
    {
        address newAuctionAddress = Clones.clone(auctionPrototypeAddress);
        emit NewAuction(newAuctionAddress);
        AuctionV1DeployI(newAuctionAddress).initialRegister();
        shippingManager().setShopAuthorized(agriData.getAddress("CryptoWineToken"), newAuctionAddress, true);
        deployedAuctions.push(newAuctionAddress);
        return newAuctionAddress;
    }

    function deployedAuctionsCount()
    public view
    returns (uint256)
    {
        return deployedAuctions.length;
    }

    /*** Enable reverse ENS registration ***/

    // Call this with the address of the reverse registrar for the respecitve network and the ENS name to register.
    // The reverse registrar can be found as the owner of 'addr.reverse' in the ENS system.
    // See https://docs.ens.domains/ens-deployments for address of ENS deployments, e.g. Etherscan can be used to look up that owner on those.
    // namehash.hash("addr.reverse") == "0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2"
    // Ropsten: ens.owner(namehash.hash("addr.reverse")) == "0x6F628b68b30Dc3c17f345c9dbBb1E483c2b7aE5c"
    // Mainnet: ens.owner(namehash.hash("addr.reverse")) == "0x084b1c3C81545d370f3634392De611CaaBFf8148"
    function registerReverseENS(address _reverseRegistrarAddress, string calldata _name)
    external
    onlyTokenAssignmentControl
    {
       require(_reverseRegistrarAddress != address(0), "need a valid reverse registrar");
       ENSReverseRegistrarI(_reverseRegistrarAddress).setName(_name);
    }

    /*** Make sure currency doesn't get stranded in this contract ***/

    // If this contract gets a balance in some ERC20 contract after it's finished, then we can rescue it.
    function rescueToken(IERC20 _foreignToken, address _to)
    external
    onlyTokenAssignmentControl
    {
        _foreignToken.transfer(_to, _foreignToken.balanceOf(address(this)));
    }

    // If this contract gets a balance in some ERC721 contract after it's finished, then we can rescue it.
    function approveNFTrescue(IERC721 _foreignNFT, address _to)
    external
    onlyTokenAssignmentControl
    {
        _foreignNFT.setApprovalForAll(_to, true);
    }

}