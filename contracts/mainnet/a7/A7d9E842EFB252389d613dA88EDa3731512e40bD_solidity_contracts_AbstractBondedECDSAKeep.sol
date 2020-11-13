/**
▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
  ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
  ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
  ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓▌        ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
  ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
  ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓

                           Trust math, not hardware.
*/

pragma solidity 0.5.17;

import "./api/IBondedECDSAKeep.sol";
import "./api/IBondingManagement.sol";

import "@keep-network/keep-core/contracts/utils/AddressArrayUtils.sol";

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";

contract AbstractBondedECDSAKeep is IBondedECDSAKeep {
    using AddressArrayUtils for address[];
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Status of the keep.
    // Active means the keep is active.
    // Closed means the keep was closed happily.
    // Terminated means the keep was closed due to misbehavior.
    enum Status {Active, Closed, Terminated}

    // Address of the keep's owner.
    address public owner;

    // List of keep members' addresses.
    address[] public members;

    // Minimum number of honest keep members required to produce a signature.
    uint256 public honestThreshold;

    // Keep's ECDSA public key serialized to 64-bytes, where X and Y coordinates
    // are padded with zeros to 32-byte each.
    bytes public publicKey;

    // Latest digest requested to be signed. Used to validate submitted signature.
    bytes32 public digest;

    // Map of all digests requested to be signed. Used to validate submitted
    // signature. Holds the block number at which the signature over the given
    // digest was requested
    mapping(bytes32 => uint256) public digests;

    // The timestamp at which keep has been created and key generation process
    // started.
    uint256 internal keyGenerationStartTimestamp;

    // The timestamp at which signing process started. Used also to track if
    // signing is in progress. When set to `0` indicates there is no
    // signing process in progress.
    uint256 internal signingStartTimestamp;

    // Map stores public key by member addresses. All members should submit the
    // same public key.
    mapping(address => bytes) internal submittedPublicKeys;

    // Map stores amount of wei stored in the contract for each member address.
    mapping(address => uint256) internal memberETHBalances;

    // Map stores preimages that have been proven to be fraudulent. This is needed
    // to prevent from slashing members multiple times for the same fraudulent
    // preimage.
    mapping(bytes => bool) internal fraudulentPreimages;

    // The current status of the keep.
    // If the keep is Active members monitor it and support requests from the
    // keep owner.
    // If the owner decides to close the keep the flag is set to Closed.
    // If the owner seizes member bonds the flag is set to Terminated.
    Status internal status;

    IBondingManagement internal bonding;

    // Flags execution of contract initialization.
    bool internal isInitialized;

    // Notification that the keep was requested to sign a digest.
    event SignatureRequested(bytes32 indexed digest);

    // Notification that the submitted public key does not match a key submitted
    // by other member. The event contains address of the member who tried to
    // submit a public key and a conflicting public key submitted already by other
    // member.
    event ConflictingPublicKeySubmitted(
        address indexed submittingMember,
        bytes conflictingPublicKey
    );

    // Notification that keep's ECDSA public key has been successfully established.
    event PublicKeyPublished(bytes publicKey);

    // Notification that ETH reward has been distributed to keep members.
    event ETHRewardDistributed(uint256 amount);

    // Notification that ERC20 reward has been distributed to keep members.
    event ERC20RewardDistributed(address indexed token, uint256 amount);

    // Notification that the keep was closed by the owner.
    // Members no longer need to support this keep.
    event KeepClosed();

    // Notification that the keep has been terminated by the owner.
    // Members no longer need to support this keep.
    event KeepTerminated();

    // Notification that the signature has been calculated. Contains a digest which
    // was used for signature calculation and a signature in a form of r, s and
    // recovery ID values.
    // The signature is chain-agnostic. Some chains (e.g. Ethereum and BTC) requires
    // `v` to be calculated by increasing recovery id by 27. Please consult the
    // documentation about what the particular chain expects.
    event SignatureSubmitted(
        bytes32 indexed digest,
        bytes32 r,
        bytes32 s,
        uint8 recoveryID
    );

    /// @notice Returns keep's ECDSA public key.
    /// @return Keep's ECDSA public key.
    function getPublicKey() external view returns (bytes memory) {
        return publicKey;
    }

    /// @notice Submits a public key to the keep.
    /// @dev Public key is published successfully if all members submit the same
    /// value. In case of conflicts with others members submissions it will emit
    /// `ConflictingPublicKeySubmitted` event. When all submitted keys match
    /// it will store the key as keep's public key and emit a `PublicKeyPublished`
    /// event.
    /// @param _publicKey Signer's public key.
    function submitPublicKey(bytes calldata _publicKey) external onlyMember {
        require(
            !hasMemberSubmittedPublicKey(msg.sender),
            "Member already submitted a public key"
        );

        require(_publicKey.length == 64, "Public key must be 64 bytes long");

        submittedPublicKeys[msg.sender] = _publicKey;

        // Check if public keys submitted by all keep members are the same as
        // the currently submitted one.
        uint256 matchingPublicKeysCount = 0;
        for (uint256 i = 0; i < members.length; i++) {
            if (
                keccak256(submittedPublicKeys[members[i]]) !=
                keccak256(_publicKey)
            ) {
                // Emit an event only if compared member already submitted a value.
                if (hasMemberSubmittedPublicKey(members[i])) {
                    emit ConflictingPublicKeySubmitted(
                        msg.sender,
                        submittedPublicKeys[members[i]]
                    );
                }
            } else {
                matchingPublicKeysCount++;
            }
        }

        if (matchingPublicKeysCount != members.length) {
            return;
        }

        // All submitted signatures match.
        publicKey = _publicKey;
        emit PublicKeyPublished(_publicKey);
    }

    /// @notice Calculates a signature over provided digest by the keep.
    /// @dev Only one signing process can be in progress at a time.
    /// @param _digest Digest to be signed.
    function sign(bytes32 _digest) external onlyOwner onlyWhenActive {
        require(publicKey.length != 0, "Public key was not set yet");
        require(!isSigningInProgress(), "Signer is busy");

        /* solium-disable-next-line */
        signingStartTimestamp = block.timestamp;

        digests[_digest] = block.number;
        digest = _digest;

        emit SignatureRequested(_digest);
    }

    /// @notice Checks if keep is currently awaiting a signature for the given digest.
    /// @dev Validates if the signing is currently in progress and compares provided
    /// digest with the one for which the latest signature was requested.
    /// @param _digest Digest for which to check if signature is being awaited.
    /// @return True if the digest is currently expected to be signed, else false.
    function isAwaitingSignature(bytes32 _digest) external view returns (bool) {
        return isSigningInProgress() && digest == _digest;
    }

    /// @notice Submits a signature calculated for the given digest.
    /// @dev Fails if signature has not been requested or a signature has already
    /// been submitted.
    /// Validates s value to ensure it's in the lower half of the secp256k1 curve's
    /// order.
    /// @param _r Calculated signature's R value.
    /// @param _s Calculated signature's S value.
    /// @param _recoveryID Calculated signature's recovery ID (one of {0, 1, 2, 3}).
    function submitSignature(
        bytes32 _r,
        bytes32 _s,
        uint8 _recoveryID
    ) external onlyMember {
        require(isSigningInProgress(), "Not awaiting a signature");
        require(_recoveryID < 4, "Recovery ID must be one of {0, 1, 2, 3}");

        // Validate `s` value for a malleability concern described in EIP-2.
        // Only signatures with `s` value in the lower half of the secp256k1
        // curve's order are considered valid.
        require(
            uint256(_s) <=
                0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "Malleable signature - s should be in the low half of secp256k1 curve's order"
        );

        // We add 27 to the recovery ID to align it with ethereum and bitcoin
        // protocols where 27 is added to recovery ID to indicate usage of
        // uncompressed public keys.
        uint8 _v = 27 + _recoveryID;

        // Validate signature.
        require(
            publicKeyToAddress(publicKey) == ecrecover(digest, _v, _r, _s),
            "Invalid signature"
        );

        signingStartTimestamp = 0;

        emit SignatureSubmitted(digest, _r, _s, _recoveryID);
    }

    /// @notice Distributes ETH reward evenly across all keep signer beneficiaries.
    /// If the value cannot be divided evenly across all signers, it sends the
    /// remainder to the last keep signer.
    /// @dev Only the value passed to this function is distributed. This
    /// function does not transfer the value to beneficiaries accounts; instead
    /// it holds the value in the contract until withdraw function is called for
    /// the specific signer.
    function distributeETHReward() external payable {
        uint256 memberCount = members.length;
        uint256 dividend = msg.value.div(memberCount);

        require(dividend > 0, "Dividend value must be non-zero");

        for (uint16 i = 0; i < memberCount - 1; i++) {
            memberETHBalances[members[i]] += dividend;
        }

        // Give the dividend to the last signer. Remainder might be equal to
        // zero in case of even distribution or some small number.
        uint256 remainder = msg.value.mod(memberCount);
        memberETHBalances[members[memberCount - 1]] += dividend.add(remainder);

        emit ETHRewardDistributed(msg.value);
    }

    /// @notice Distributes ERC20 reward evenly across all keep signer beneficiaries.
    /// @dev This works with any ERC20 token that implements a transferFrom
    /// function similar to the interface imported here from
    /// OpenZeppelin. This function only has authority over pre-approved
    /// token amount. We don't explicitly check for allowance, SafeMath
    /// subtraction overflow is enough protection. If the value cannot be
    /// divided evenly across the signers, it submits the remainder to the last
    /// keep signer.
    /// @param _tokenAddress Address of the ERC20 token to distribute.
    /// @param _value Amount of ERC20 token to distribute.
    function distributeERC20Reward(address _tokenAddress, uint256 _value)
        external
    {
        IERC20 token = IERC20(_tokenAddress);

        uint256 memberCount = members.length;
        uint256 dividend = _value.div(memberCount);

        require(dividend > 0, "Dividend value must be non-zero");

        for (uint16 i = 0; i < memberCount - 1; i++) {
            token.safeTransferFrom(
                msg.sender,
                beneficiaryOf(members[i]),
                dividend
            );
        }

        // Transfer of dividend for the last member. Remainder might be equal to
        // zero in case of even distribution or some small number.
        uint256 remainder = _value.mod(memberCount);
        token.safeTransferFrom(
            msg.sender,
            beneficiaryOf(members[memberCount - 1]),
            dividend.add(remainder)
        );

        emit ERC20RewardDistributed(_tokenAddress, _value);
    }

    /// @notice Gets current amount of ETH hold in the keep for the member.
    /// @param _member Keep member address.
    /// @return Current balance in wei.
    function getMemberETHBalance(address _member)
        external
        view
        returns (uint256)
    {
        return memberETHBalances[_member];
    }

    /// @notice Withdraws amount of ether hold in the keep for the member.
    /// The value is sent to the beneficiary of the specific member.
    /// @param _member Keep member address.
    function withdraw(address _member) external {
        uint256 value = memberETHBalances[_member];

        require(value > 0, "No funds to withdraw");

        memberETHBalances[_member] = 0;

        /* solium-disable-next-line security/no-call-value */
        (bool success, ) = beneficiaryOf(_member).call.value(value)("");

        require(success, "Transfer failed");
    }

    /// @notice Submits a fraud proof for a valid signature from this keep that was
    /// not first approved via a call to sign. If fraud is detected it tries to
    /// slash members' KEEP tokens. For each keep member tries slashing amount
    /// equal to the member stake set by the factory when keep was created.
    /// @dev The function expects the signed digest to be calculated as a sha256
    /// hash of the preimage: `sha256(_preimage))`. The function reverts if the
    /// signature is not fraudulent. The function does not revert if KEEP slashing
    /// failed but emits an event instead. In practice, KEEP slashing should
    /// never fail.
    /// @param _v Signature's header byte: `27 + recoveryID`.
    /// @param _r R part of ECDSA signature.
    /// @param _s S part of ECDSA signature.
    /// @param _signedDigest Digest for the provided signature. Result of hashing
    /// the preimage with sha256.
    /// @param _preimage Preimage of the hashed message.
    /// @return True if fraud, error otherwise.
    function submitSignatureFraud(
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        bytes32 _signedDigest,
        bytes calldata _preimage
    ) external onlyWhenActive returns (bool _isFraud) {
        bool isFraud = checkSignatureFraud(
            _v,
            _r,
            _s,
            _signedDigest,
            _preimage
        );

        require(isFraud, "Signature is not fraudulent");

        if (!fraudulentPreimages[_preimage]) {
            slashForSignatureFraud();

            fraudulentPreimages[_preimage] = true;
        }

        return isFraud;
    }

    /// @notice Gets the owner of the keep.
    /// @return Address of the keep owner.
    function getOwner() external view returns (address) {
        return owner;
    }

    /// @notice Gets the timestamp the keep was opened at.
    /// @return Timestamp the keep was opened at.
    function getOpenedTimestamp() external view returns (uint256) {
        return keyGenerationStartTimestamp;
    }

    /// @notice Returns the amount of the keep's ETH bond in wei.
    /// @return The amount of the keep's ETH bond in wei.
    function checkBondAmount() external view returns (uint256) {
        uint256 sumBondAmount = 0;
        for (uint256 i = 0; i < members.length; i++) {
            sumBondAmount += bonding.bondAmount(
                members[i],
                address(this),
                uint256(address(this))
            );
        }

        return sumBondAmount;
    }

    /// @notice Seizes the signers' ETH bonds. After seizing bonds keep is
    /// closed so it will no longer respond to signing requests. Bonds can be
    /// seized only when there is no signing in progress or requested signing
    /// process has timed out. This function seizes all of signers' bonds.
    /// The application may decide to return part of bonds later after they are
    /// processed using returnPartialSignerBonds function.
    function seizeSignerBonds() external onlyOwner onlyWhenActive {
        terminateKeep();

        for (uint256 i = 0; i < members.length; i++) {
            uint256 amount = bonding.bondAmount(
                members[i],
                address(this),
                uint256(address(this))
            );

            bonding.seizeBond(
                members[i],
                uint256(address(this)),
                amount,
                address(uint160(owner))
            );
        }
    }

    /// @notice Returns partial signer's ETH bonds to the pool as an unbounded
    /// value. This function is called after bonds have been seized and processed
    /// by the privileged application after calling seizeSignerBonds function.
    /// It is entirely up to the application if a part of signers' bonds is
    /// returned. The application may decide for that but may also decide to
    /// seize bonds and do not return anything.
    function returnPartialSignerBonds() external payable {
        uint256 memberCount = members.length;
        uint256 bondPerMember = msg.value.div(memberCount);

        require(bondPerMember > 0, "Partial signer bond must be non-zero");

        for (uint16 i = 0; i < memberCount - 1; i++) {
            bonding.deposit.value(bondPerMember)(members[i]);
        }

        // Transfer of dividend for the last member. Remainder might be equal to
        // zero in case of even distribution or some small number.
        uint256 remainder = msg.value.mod(memberCount);
        bonding.deposit.value(bondPerMember.add(remainder))(
            members[memberCount - 1]
        );
    }

    /// @notice Closes keep when owner decides that they no longer need it.
    /// Releases bonds to the keep members.
    /// @dev The function can be called only by the owner of the keep and only
    /// if the keep has not been already closed.
    function closeKeep() public onlyOwner onlyWhenActive {
        markAsClosed();
        freeMembersBonds();
    }

    /// @notice Returns true if the keep is active.
    /// @return true if the keep is active, false otherwise.
    function isActive() public view returns (bool) {
        return status == Status.Active;
    }

    /// @notice Returns true if the keep is closed and members no longer support
    /// this keep.
    /// @return true if the keep is closed, false otherwise.
    function isClosed() public view returns (bool) {
        return status == Status.Closed;
    }

    /// @notice Returns true if the keep has been terminated.
    /// Keep is terminated when bonds are seized and members no longer support
    /// this keep.
    /// @return true if the keep has been terminated, false otherwise.
    function isTerminated() public view returns (bool) {
        return status == Status.Terminated;
    }

    /// @notice Returns members of the keep.
    /// @return List of the keep members' addresses.
    function getMembers() public view returns (address[] memory) {
        return members;
    }

    /// @notice Checks a fraud proof for a valid signature from this keep that was
    /// not first approved via a call to sign.
    /// @dev The function expects the signed digest to be calculated as a sha256 hash
    /// of the preimage: `sha256(_preimage))`. The digest is verified against the
    /// preimage to ensure the security of the ECDSA protocol. Verifying just the
    /// signature and the digest is not enough and leaves the possibility of the
    /// the existential forgery. If digest and preimage verification fails the
    /// function reverts.
    /// Reverts if a public key has not been set for the keep yet.
    /// @param _v Signature's header byte: `27 + recoveryID`.
    /// @param _r R part of ECDSA signature.
    /// @param _s S part of ECDSA signature.
    /// @param _signedDigest Digest for the provided signature. Result of hashing
    /// the preimage with sha256.
    /// @param _preimage Preimage of the hashed message.
    /// @return True if fraud, false otherwise.
    function checkSignatureFraud(
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        bytes32 _signedDigest,
        bytes memory _preimage
    ) public view returns (bool _isFraud) {
        require(publicKey.length != 0, "Public key was not set yet");

        bytes32 calculatedDigest = sha256(_preimage);
        require(
            _signedDigest == calculatedDigest,
            "Signed digest does not match sha256 hash of the preimage"
        );

        bool isSignatureValid = publicKeyToAddress(publicKey) ==
            ecrecover(_signedDigest, _v, _r, _s);

        // Check if the signature is valid but was not requested.
        return isSignatureValid && digests[_signedDigest] == 0;
    }

    /// @notice Initialization function.
    /// @dev We use clone factory to create new keep. That is why this contract
    /// doesn't have a constructor. We provide keep parameters for each instance
    /// function after cloning instances from the master contract.
    /// Initialization must happen in the same transaction in which the clone is
    /// created.
    /// @param _owner Address of the keep owner.
    /// @param _members Addresses of the keep members.
    /// @param _honestThreshold Minimum number of honest keep members.
    function initialize(
        address _owner,
        address[] memory _members,
        uint256 _honestThreshold,
        address _bonding
    ) internal {
        require(!isInitialized, "Contract already initialized");

        owner = _owner;
        members = _members;
        honestThreshold = _honestThreshold;

        status = Status.Active;
        isInitialized = true;

        /* solium-disable-next-line security/no-block-members*/
        keyGenerationStartTimestamp = block.timestamp;

        bonding = IBondingManagement(_bonding);
    }

    /// @notice Checks if the member already submitted a public key.
    /// @param _member Address of the member.
    /// @return True if member already submitted a public key, else false.
    function hasMemberSubmittedPublicKey(address _member)
        internal
        view
        returns (bool)
    {
        return submittedPublicKeys[_member].length != 0;
    }

    /// @notice Returns true if signing of a digest is currently in progress.
    function isSigningInProgress() internal view returns (bool) {
        return signingStartTimestamp != 0;
    }

    /// @notice Marks the keep as closed.
    /// Keep can be marked as closed only when there is no signing in progress
    /// or the requested signing process has timed out.
    function markAsClosed() internal {
        status = Status.Closed;
        emit KeepClosed();
    }

    /// @notice Marks the keep as terminated.
    /// Keep can be marked as terminated only when there is no signing in progress
    /// or the requested signing process has timed out.
    function markAsTerminated() internal {
        status = Status.Terminated;
        emit KeepTerminated();
    }

    /// @notice Coverts a public key to an ethereum address.
    /// @param _publicKey Public key provided as 64-bytes concatenation of
    /// X and Y coordinates (32-bytes each).
    /// @return Ethereum address.
    function publicKeyToAddress(bytes memory _publicKey)
        internal
        pure
        returns (address)
    {
        // We hash the public key and then truncate last 20 bytes of the digest
        // which is the ethereum address.
        return address(uint160(uint256(keccak256(_publicKey))));
    }

    /// @notice Returns bonds to the keep members.
    function freeMembersBonds() internal {
        for (uint256 i = 0; i < members.length; i++) {
            bonding.freeBond(members[i], uint256(address(this)));
        }
    }

    /// @notice Terminates the keep.
    function terminateKeep() internal {
        markAsTerminated();
    }

    /// @notice Punishes keep members after proving a signature fraud.
    function slashForSignatureFraud() internal;

    /// @notice Gets the beneficiary for the specified member address.
    /// @param _member Member address.
    /// @return Beneficiary address.
    function beneficiaryOf(address _member)
        internal
        view
        returns (address payable);

    /// @notice Checks if the caller is the keep's owner.
    /// @dev Throws an error if called by any account other than owner.
    modifier onlyOwner() {
        require(owner == msg.sender, "Caller is not the keep owner");
        _;
    }

    /// @notice Checks if the caller is a keep member.
    /// @dev Throws an error if called by any account other than one of the members.
    modifier onlyMember() {
        require(members.contains(msg.sender), "Caller is not the keep member");
        _;
    }

    /// @notice Checks if the keep is currently active.
    /// @dev Throws an error if called when the keep has been already closed.
    modifier onlyWhenActive() {
        require(isActive(), "Keep is not active");
        _;
    }
}
