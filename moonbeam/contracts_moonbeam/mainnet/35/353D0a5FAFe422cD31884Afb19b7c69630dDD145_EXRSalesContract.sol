// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/IEXRMintPass.sol";
import "./interfaces/IEXRGameAsset.sol";
import "./extensions/CouponSystem.sol";

error SalesRacecraftRedemptionNotActive();
error SalesPilotRedemptionNotActive();
error SalesExceededMintPassSupply();
error SalesAllottedClaimsExceeded();
error SalesInvalidFragmentSupply();
error SalesArrayLengthMismatch();
error SalesNonExistentFragment();
error SalesIncorrectEthAmount();
error SalesPassClaimNotActive();
error SalesInvalidStateValue();
error SalesMintpassQtyNotSet();
error SalesWithdrawalFailed();
error SalesInvalidCoupon();
error SalesRefundFailed();
error SalesZeroAddress();
error SalesNoMintPass();
error SalesInvalidQty();
error SalesReusedSeed();

/**
 * @title   Sales Contract
 * @author  RacerDev
 * @notice  This sales contract acts as an interface between the end user and the NFT
 *          contracts in the EXR ecosystem.  Users cannot mint from ERC721 and ERC1155 contracts
 *          directly, instead this contract provides controlled access to the
 *          collection Fragments for each contract.  All contract interactions with other token contracts
 *          happen via interfaces, for which the contract addresses must be set by an admin user.
 * @notice  There is no public mint or claim functions.  Claiming tokens requires the caller to pass in a signed
 *          coupon, which is used to recover the signers address on-chain to verify the validity
 *          of the Coupons.
 * @dev     This approach is designed to work with the ERC721Fragmentable extension, which allows for NFT Collections to be
 *          subdivided into smaller "Fragments", each released independently, but still part of the same contract.
 *          This is controlled via the `dedicatedFragment` variable that is set in the constructor at deploy time.
 * @dev     This contract enables gasless transactions for the end-user by replacing `msg.sender` if a trusted forwarder
 *          is the caller. This pattern allows the contract to be used with Biconomy's relayer protocol.
 */

contract EXRSalesContract is ERC2771Context, CouponSystem, ReentrancyGuard, AccessControl {
    bytes32 public constant SYS_ADMIN_ROLE = keccak256("SYS_ADMIN_ROLE");

    uint256 public constant pilotPassTokenId = 1;
    uint256 public constant racecraftPassTokenId = 2;

    // We set these in the constructor in the event the event the Sales contract is being replaced
    // for an alreaady active fragment. If not, the values will be overwritten when the fragment is created
    uint256 public pilotPassMaxSupply;
    uint256 public racecraftPassMaxSupply;

    uint8 public immutable dedicatedFragment;

    mapping(bytes32 => bool) public usedSeeds;
    struct SaleState {
        uint8 claimPilotPass;
        uint8 redeemPilot;
        uint8 redeemRacecraft;
    }

    SaleState public state;

    IEXRMintPass public mintPassContract;
    IEXRGameAsset public pilotContract;
    IEXRGameAsset public racecraftContract;

    event SalesFragmentCreated(
        uint256 supply,
        uint256 firstId,
        uint256 reservedPilots,
        uint256 reservedRacecrafts
    );
    event Airdrop(uint256 tokenId, uint256[] qtys, address[] indexed recipient);
    event RefundIssued(address indexed buyer, uint256 amount);
    event MintPassClaimed(address indexed user, uint256 qty);
    event RacecraftContractSet(address indexed racecraft);
    event MintPassContractSet(address indexed mintpass);
    event PilotStateChange(uint8 claim, uint8 redeem);
    event PilotContractSet(address indexed pilot);
    event MintPassBurned(address indexed user);
    event RacecraftStateChange(uint8 redeem);
    event AdminSignerUpdated(address signer);
    event RacecraftRedeemed();
    event BalanceWithdrawn();
    event PilotRedeemed();
    event EmergencyStop();

    /**
     * @dev     The Admin Signer is passed directly to the CouponSystem constructor where it's kept in storage.
     *          It's later used to compare against the signer recoverd from the Coupon signature.
     * @param   adminSigner The public address from the keypair whose private key signed the Coupon off-chain
     * @param   fragment    The identifier for the fragment being represented by this sales contract, which determines
     *                      which fragment of the target ERC721 contracts is used.
     */
    constructor(
        address adminSigner,
        address trustedForwarder,
        uint8 fragment,
        uint256 pilotPassMaxSupply_,
        uint256 racecraftPassMaxSupply_
    ) CouponSystem(adminSigner) ERC2771Context(trustedForwarder) {
        dedicatedFragment = fragment;
        pilotPassMaxSupply = pilotPassMaxSupply_;
        racecraftPassMaxSupply = racecraftPassMaxSupply_;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SYS_ADMIN_ROLE, msg.sender);
    }

    // ======================================================== EXTERNAL | USER FUNCTIONS

    /**
     * @notice Allows a whitelisted caller to claim a Pilot Mint Pass
     * @dev    Callers are able to claim a mint pass by passing in a signed Coupon that's created off-chain.
     *         The caller's address is encoded into the Coupon, so only the intended recipient can claim a pass.
     * @dev    This is a variable-pricing function.  The cost of the claim is encoded into the Coupon and passed in as
     *         as a param. This allows different "tiers" of coupons to use the same function, eg
     *         free vs. paid. The custom price that's passed in is validated against the price included in the coupon, then
     *         compared to the amount of Eth sent in msg.value;
     * @dev    The coupon does not contain a nonce, instead the number of claims is tracked against the caller's address
     *         using the {addressToClaims} mapping. This approach allows a user to claim their allotted mint masses over
     *         multiple transactions (if desired), without the need to generate a new coupon.
     * @dev    The MintPass is minted by the contract on the user's behalf using the `MintPassContract` interface.
     * @dev    Will refund the caller if they send the incorrect amount > `msg.value`.
     * @dev    It's possible for different users to be assigned a different number of mintpass claims, the total for each user
     *         is dictated by the `allotted` parameter, which is encoded into the coupon.
     * @param  coupon signed coupon generated using caller's address, price, qty, and allotted claims
     * @param  price the custom price the caller needs to pay per pass claimed
     * @param  qty the number of passes to claim
     * @param  allotted the max number of passes the caller's address is allowed to claim (over multiple TXs if desired)
     */
    function claimPilotPass(
        Coupon calldata coupon,
        uint256 price,
        uint256 qty,
        uint256 allotted
    ) external payable nonReentrant {
        if (state.claimPilotPass == 0) revert SalesPassClaimNotActive();
        if (!pilotContract.fragmentExists(dedicatedFragment)) revert SalesNonExistentFragment();
        if (pilotPassMaxSupply == 0) revert SalesMintpassQtyNotSet();
        if (qty == 0 || allotted == 0) revert SalesInvalidQty();
        if (
            mintPassContract.tokenMintCountsByFragment(dedicatedFragment, pilotPassTokenId) + qty >
            pilotPassMaxSupply
        ) revert SalesExceededMintPassSupply();

        uint256 amountOwed = price * qty;

        address caller = _msgSender();
        uint256 paid = msg.value;

        if (paid < amountOwed) revert SalesIncorrectEthAmount();

        if (
            qty + mintPassContract.addressToPilotPassClaimsByFragment(dedicatedFragment, caller) >
            allotted
        ) revert SalesAllottedClaimsExceeded();

        bytes32 digest = keccak256(
            abi.encode(address(this), block.chainid, CouponType.MintPass, price, allotted, caller)
        );
        if (!_verifyCoupon(digest, coupon)) revert SalesInvalidCoupon();

        mintPassContract.incrementPilotPassClaimCount(caller, dedicatedFragment, qty);
        mintPassContract.mint(caller, qty, pilotPassTokenId, dedicatedFragment);
        emit MintPassClaimed(caller, qty);

        if (amountOwed < paid) {
            refundCaller(caller, paid - amountOwed);
        }
    }

    /**
     * @notice  The caller can claim an EXRGameAsset token in exchange for burning their Pilot MintPass
     * @dev     Checks the balance of Mint Pass tokens for caller's address, burns the mint pass via
     *          the MintPass contract interface, and mints a Pilot to the callers address via the
     *          EXRGameAsset contract Interface
     * @dev     The EXRGameAsset token will be minted for the fragment of the collection determined by
     *          `dedicatedFragment`, which is set at deploy time.  Only tokens for this fragment can be minted
     *          using this Fragment Sales Contract.
     * @dev     At the time of writing, the Moonbeam network has no method of generating unpredictable randomness
     *          such as Chainlink's VRF.  For this reason, a random seed, generated off-chain, is supplied to the
     *          redeem method to allow for random token assignment of the pilot IDs.
     * @dev     We need to check {pilotPasssMaxSupply} in the event the sales contract was replaced for an existing fragment.
     * @param   seed Random seed generated off-chain
     * @param   coupon The coupon encoding the random seed signed by the admin's private key
     */
    function redeemPilot(bytes32 seed, Coupon calldata coupon)
        external
        nonReentrant
        hasValidOrigin
    {
        if (state.redeemPilot == 0) revert SalesPilotRedemptionNotActive();
        if (!pilotContract.fragmentExists(dedicatedFragment)) revert SalesNonExistentFragment();
        if (pilotPassMaxSupply == 0) revert SalesMintpassQtyNotSet();
        if (usedSeeds[seed]) revert SalesReusedSeed();

        usedSeeds[seed] = true;

        address caller = _msgSender();
        if (mintPassContract.balanceOf(caller, pilotPassTokenId) == 0) revert SalesNoMintPass();

        bytes32 digest = keccak256(
            abi.encode(address(this), block.chainid, CouponType.Pilot, seed, caller)
        );
        if (!_verifyCoupon(digest, coupon)) revert SalesInvalidCoupon();

        mintPassContract.burnToRedeemPilot(caller, dedicatedFragment);
        emit MintPassBurned(caller);

        pilotContract.mint(caller, 1, dedicatedFragment, seed);
        emit PilotRedeemed();
    }

    /**
     * @notice  Allows the holder of a Racecraft Mint Pass to exchange it for a Racecraft Token
     * @dev     There is no VRF available, so the caller includes a verifiably random seed generated
     *          off-chain in the calldata
     * @param   seed 32-byte hash of the random seed
     * @param   coupon Coupon containing the random seed and RandomSeed enum
     */
    function redeemRacecraft(bytes32 seed, Coupon calldata coupon)
        external
        nonReentrant
        hasValidOrigin
    {
        if (state.redeemRacecraft == 0) revert SalesRacecraftRedemptionNotActive();
        if (!racecraftContract.fragmentExists(dedicatedFragment))
            revert SalesNonExistentFragment();
        if (racecraftPassMaxSupply == 0) revert SalesMintpassQtyNotSet();
        if (usedSeeds[seed]) revert SalesReusedSeed();

        usedSeeds[seed] = true;

        address caller = _msgSender();
        if (mintPassContract.balanceOf(caller, racecraftPassTokenId) == 0)
            revert SalesNoMintPass();

        bytes32 digest = keccak256(
            abi.encode(address(this), block.chainid, CouponType.Racecraft, seed, caller)
        );
        if (!_verifyCoupon(digest, coupon)) revert SalesInvalidCoupon();

        mintPassContract.authorizedBurn(caller, racecraftPassTokenId);
        racecraftContract.mint(caller, 1, dedicatedFragment, seed);
        emit RacecraftRedeemed();
    }

    // ======================================================== EXTERNAL | OWNER FUNCTIONS

    /**
     *  @notice Allows an admin to set the address for the mint pass contract interface
     *  @dev    Sets the public address variable for visibility only, it's not actually used
     *  @param  contractAddress The address for the external EXRMintPass ERC1155 contract
     */
    function setMintPassContract(address contractAddress) external onlyRole(SYS_ADMIN_ROLE) {
        if (contractAddress == address(0)) revert SalesZeroAddress();
        mintPassContract = IEXRMintPass(contractAddress);
        emit MintPassContractSet(contractAddress);
    }

    /**
     *   @notice Allows an admin to set the address for the IEXRGameAsset contract interface
     *   @dev    Sets the public address variable for visibility only, it's not actually used
     *   @param  contractAddress The address for the external IEXRGameAsset ERC721 contract
     */
    function setPilotContract(address contractAddress) external onlyRole(SYS_ADMIN_ROLE) {
        if (contractAddress == address(0)) revert SalesZeroAddress();
        pilotContract = IEXRGameAsset(contractAddress);
        emit PilotContractSet(contractAddress);
    }

    /**
     *   @notice Allows an admin to set the address for the IEXRGameAsset contract interface
     *   @dev    Sets the public address variable for visibility only, it's not actually used
     *   @param  contractAddress The address for the external IEXRGameAsset ERC721 contract
     */
    function setRacecraftContract(address contractAddress) external onlyRole(SYS_ADMIN_ROLE) {
        if (contractAddress == address(0)) revert SalesZeroAddress();
        racecraftContract = IEXRGameAsset(contractAddress);
        emit RacecraftContractSet(contractAddress);
    }

    /**
     * @dev     Admin can replace signer public address from signer's keypair
     * @param   newSigner public address of the signer's keypair
     */
    function updateAdminSigner(address newSigner) external onlyRole(SYS_ADMIN_ROLE) {
        _replaceSigner(newSigner);
        emit AdminSignerUpdated(newSigner);
    }

    /**
     * @notice Used to toggle the claim state between true/false, which controls whether callers are able to claim a mint pass
     * @dev    Should generally be enabled using flashbots to avoid backrunning, though may not be an issue with no "public sale"
     */
    function setPilotState(uint8 passClaim, uint8 redemption) external onlyRole(SYS_ADMIN_ROLE) {
        if (passClaim > 1 || redemption > 1) revert SalesInvalidStateValue();
        state.claimPilotPass = passClaim;
        state.redeemPilot = redemption;
        emit PilotStateChange(passClaim, redemption);
    }

    /**
     * @notice Used to toggle the claim state between true/false, which controls whether callers are able to burn their mint passes
     * @dev Should generally be enabled using flashbots to avoid backrunning, though may not be an issue with no "public sale"
     */

    function setRacecraftState(uint8 redemption) external onlyRole(SYS_ADMIN_ROLE) {
        if (redemption > 1) revert SalesInvalidStateValue();
        state.redeemRacecraft = redemption;
        emit RacecraftStateChange(redemption);
    }

    /**
     * @notice  Allows an Admin user to airdrop Mintpass Tokens to known addresses
     * @param   tokenId the ID of the Mintpass token to be airdropped
     * @param   qtys array containting the number of passes to mint for the address
     *              at the corresponding index in the `recipients` array
     * @param   recipients array of addresses to mint tokens to
     */
    function airdropMintpass(
        uint256 tokenId,
        uint256[] calldata qtys,
        address[] calldata recipients
    ) external onlyRole(SYS_ADMIN_ROLE) {
        if (qtys.length != recipients.length) revert SalesArrayLengthMismatch();
        if (pilotPassMaxSupply == 0) revert SalesMintpassQtyNotSet();

        uint256 count = qtys.length;
        uint256 totalQty;
        for (uint256 i; i < count; i++) {
            totalQty += qtys[i];
        }
        if (
            mintPassContract.tokenMintCountsByFragment(dedicatedFragment, tokenId) + totalQty >
            pilotPassMaxSupply
        ) revert SalesExceededMintPassSupply();

        for (uint256 i; i < count; i++) {
            mintPassContract.mint(recipients[i], qtys[i], tokenId, dedicatedFragment);
        }
        emit Airdrop(tokenId, qtys, recipients);
    }

    /**
     * @notice   Allows the contract owner to create fragments of the same size simultaneously for the Pilot
     *           and Racecraft collections.
     * @dev      There may exist some scenarios where the number of reserved pilots and
     *           racecraft might differ for a given fragment. For this reason, separate reserve amounts
     *           can be supplied.
     * @param    fragmentSupply     The number of total tokens in the fragment.
     * @param    firstId            The first token ID in the fragment
     * @param    reservedPilots     The number of reserved tokens in the Pilot fragment.
     * @param    reservedRacecrafts The number of reserved tokens in the Racecraft fragment.
     */
    function createFragments(
        uint64 fragmentSupply,
        uint64 firstId,
        uint64 reservedPilots,
        uint64 reservedRacecrafts
    ) external onlyRole(SYS_ADMIN_ROLE) {
        if (fragmentSupply <= reservedPilots || fragmentSupply <= reservedRacecrafts)
            revert SalesInvalidFragmentSupply();
        pilotPassMaxSupply = fragmentSupply - reservedPilots;
        racecraftPassMaxSupply = fragmentSupply - reservedRacecrafts;
        pilotContract.createFragment(dedicatedFragment, fragmentSupply, firstId, reservedPilots);
        racecraftContract.createFragment(
            dedicatedFragment,
            fragmentSupply,
            firstId,
            reservedRacecrafts
        );
        emit SalesFragmentCreated(fragmentSupply, firstId, reservedPilots, reservedRacecrafts);
    }

    /**
     * @notice  Prevents any user-facing function from being called
     * @dev     Behaves similarly to Pausable
     */
    function emergencyStop() external onlyRole(SYS_ADMIN_ROLE) {
        state.claimPilotPass = 0;
        state.redeemPilot = 0;
        state.redeemRacecraft = 0;
        emit EmergencyStop();
    }

    /**
     * @notice  Withdraw the Eth stored in the contract to the owner's address.
     * @dev     User transfer() in favor of call() for the withdrawal as it's only to the owner's address.
     */
    function withdrawBalance() external onlyRole(SYS_ADMIN_ROLE) {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        if (!success) revert SalesWithdrawalFailed();
        emit BalanceWithdrawn();
    }

    // ======================================================== PRIVATE

    /**
     * @notice  Used to refund a caller who overpays for their mintpass.
     * @dev     Use `call` over `transfer`
     * @param   buyer The address/account to send the refund to
     * @param   amount The value (in wei) to refund to the caller
     * */
    function refundCaller(address buyer, uint256 amount) private {
        (bool success, ) = buyer.call{value: amount}("");
        if (!success) revert SalesRefundFailed();
        emit RefundIssued(buyer, amount);
    }

    // ======================================================== MODIFIERS

    /**
     * @dev Only allow contract calls from Biconomy's trusted forwarder
     */
    modifier hasValidOrigin() {
        require(
            isTrustedForwarder(msg.sender) || msg.sender == tx.origin,
            "Non-trusted forwarder contract not allowed"
        );
        _;
    }

    // ======================================================== OVERRIDES

    /**
     * @dev Override Context's _msgSender() to enable meta transactions for Biconomy
     *       relayer protocol, which allows for gasless TXs
     */
    function _msgSender()
        internal
        view
        virtual
        override(ERC2771Context, Context)
        returns (address)
    {
        return ERC2771Context._msgSender();
    }

    function _msgData()
        internal
        view
        virtual
        override(ERC2771Context, Context)
        returns (bytes calldata)
    {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
     * by making the `nonReentrant` function external, and making it call a
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (metatx/ERC2771Context.sol)

pragma solidity ^0.8.9;

import "../utils/Context.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context is Context {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable _trustedForwarder;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IEXRMintPass {
    function balanceOf(address account, uint256 id) external view returns (uint256);

    function totalSupply(uint256 id) external view returns (uint256);

    function mint(
        address recipient,
        uint256 qty,
        uint256 tokenId,
        uint256 fragment
    ) external;

    function burnToRedeemPilot(address account, uint256 fragment) external;

    function authorizedBurn(address account, uint256 tokenId) external;

    function tokenMintCountsByFragment(uint256 fragment, uint256 tokenId)
        external
        view
        returns (uint256);

    function addressToPilotPassClaimsByFragment(uint256 fragment, address caller)
        external
        view
        returns (uint256);

    function incrementPilotPassClaimCount(
        address caller,
        uint256 fragment,
        uint256 qty
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IEXRGameAsset {
    function mint(
        address recipient,
        uint256 count,
        uint8 fragment,
        bytes32 seed
    ) external;

    function createFragment(
        uint8 id,
        uint64 fragmentSupply,
        uint64 firstId,
        uint64 reserved
    ) external;

    function fragmentExists(uint256 fragmentNumber) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

error InvalidSignature();

/**
 * @title   Coupon System
 * @author  RacerDev
 * @notice  Helper contract for verifying signed coupons using `ecrecover` to match the coupon signer
 *          to the `_adminSigner` variable set during construction.
 * @dev     The Coupon struct represents a decoded signature that was created off-chain
 */
contract CouponSystem {
    address internal _adminSigner;

    enum CouponType {
        MintPass,
        Pilot,
        Racecraft,
        Inventory,
        Reward
    }

    struct Coupon {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    constructor(address signer) {
        _adminSigner = signer;
    }

    /**
     * @dev     Admin can replace the admin signer address in the event the private key is compromised
     * @param   newSigner The public key (address) of the new signer keypair
     */
    function _replaceSigner(address newSigner) internal {
        _adminSigner = newSigner;
    }

    /**
     * @dev     Accepts an already hashed set of data
     * @param   digest The hash of the abi.encoded coupon data
     * @param   coupon The decoded r,s,v components of the signature
     * @return  Whether the recovered signer address matches the `_adminSigner`
     */
    function _verifyCoupon(bytes32 digest, Coupon calldata coupon) internal view returns (bool) {
        address signer = ecrecover(digest, coupon.v, coupon.r, coupon.s);
        if (signer == address(0)) revert InvalidSignature();
        return signer == _adminSigner;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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