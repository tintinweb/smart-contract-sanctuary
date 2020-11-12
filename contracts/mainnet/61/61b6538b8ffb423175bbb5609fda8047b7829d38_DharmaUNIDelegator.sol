pragma solidity 0.6.12; // optimization runs: 200, evm version: istanbul


interface IDharmaUNIDelegator {
    function getDefaultDelegationPayload() external pure returns (bytes32);
    function validateDefaultPayload(address delegator, bytes calldata signature) external view returns (bool valid);
    function delegateToDharmaViaDefault(bytes calldata signature) external returns (bool ok);
    
    function getCustomDelegationPayload(address delegator, uint256 expiry) external view returns (bytes32);
    function validateCustomPayload(address delegator, uint256 expiry, bytes calldata signature) external view returns (bool valid);
    function delegateToDharmaViaCustom(address delegator, uint256 expiry, bytes calldata signature) external returns (bool ok);
}


interface IUNI {
    function nonces(address account) external view returns (uint256);
    function delegateBySig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) external;
}


/// @title DharmaUNIDelegator
/// @author 0age
/// @notice This contract facilitates UNI delegation to Dharma via meta-transaction,
/// using the `delegateBySig` pattern first established by Compound on their COMP
/// token. Two methods are available — a "default" method, which assumes that the
/// delegator is making their first meta-transaction on UNI and does not desire the
/// deletation meta-transaction to expire, and a "custom" method that utilizes the
/// current nonce for the delegator in question and allows for specification of any
/// expiration. First, call `getDefaultDelegationPayload` to retrieve the payload
/// that needs to be signed. Next, the delegator signs the payload via `eth_sign`.
/// Finally, validate the signature via `validateDefaultPayload` and relay the
/// delegation via `delegateToDharmaViaDefault`. (The same sequence applies for
/// custom delegation, using the corresponding custom methods.) Finally, note that
/// delegation can be modified at any point, but that any proposals that are made
/// will "lock in" delegation as of the proposal time in the context of the vote
/// in question.
contract DharmaUNIDelegator is IDharmaUNIDelegator {
    /// @notice The EIP-712 typehash for UNI's domain
    bytes32 internal constant DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
    );

    /// @notice UNI's EIP-712 domain separator, computed from parameters in typehash
    bytes32 internal constant DOMAIN_SEPARATOR = bytes32(
        0x28e9a6a663fbec82798f959fbf7b0805000a2aa21154d62a24be5f2a8716bf81
    );

    /// @notice The EIP-712 typehash for the delegation struct used by UNI
    bytes32 internal constant DELEGATION_TYPEHASH = keccak256(
        "Delegation(address delegatee,uint256 nonce,uint256 expiry)"
    );

    /// @notice The EIP-712 typehash for the initial delegation struct to Dharma
    bytes32 internal constant STRUCT_HASH_FOR_ZERO_NONCE_AND_DISTANT_EXPIRY = bytes32(
        0x8e3dad336fbf63723cdd6a970ccff74331f69d237e030433c4fb2d299d44fdd6
    );
    
    /// @notice The EIP-712 payload to sign for delegation to Dharma with default parameters
    bytes32 internal constant DEFAULT_DELEGATION_PAYLOAD = bytes32(
        0x96b14b7fefb98540ed60068884902ad2b61901691cd14a23fdd0e24bc7515f24
    );

    /// @notice The address and relevant interface of UNI
    IUNI public constant UNI = IUNI(0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984);
    
    /// @notice The Dharma Delegatee address
    address public constant DHARMA_DELEGATEE = address(
        0x7e4A8391C728fEd9069B2962699AB416628B19Fa
    );
    
    /// @notice The default nonce (zero)
    uint256 internal constant ZERO_NONCE = uint256(0);
    
    /// @notice The default expiration (a long, long time from now)
    uint256 internal constant DISTANT_EXPIRY = uint256(999999999999999999);
    
    /// @notice Validate the computation of defined constants during deployment
    constructor() public {
        require(
            DOMAIN_SEPARATOR == keccak256(
                abi.encode(
                    DOMAIN_TYPEHASH, keccak256(bytes("Uniswap")), uint256(1), address(UNI)
                )
            ),
            "Domain Separator does not match computed domain separator."
        );
        
        require(
            STRUCT_HASH_FOR_ZERO_NONCE_AND_DISTANT_EXPIRY == keccak256(
                abi.encode(
                    DELEGATION_TYPEHASH, DHARMA_DELEGATEE, ZERO_NONCE, DISTANT_EXPIRY
                )
            ),
            "Default struct hash does not match computed default struct hash."
        );
        
        require(
            DEFAULT_DELEGATION_PAYLOAD == keccak256(
                abi.encodePacked(
                    "\x19\x01", DOMAIN_SEPARATOR, STRUCT_HASH_FOR_ZERO_NONCE_AND_DISTANT_EXPIRY
                )
            ),
            "Default initial delegation payload does not match computed default payload."
        );
    }
    
    /// @notice Get default payload to sign for delegating to Dharma — note that it must be the
    /// first UNI meta-transaction from the delegator.
    function getDefaultDelegationPayload() external pure override returns (bytes32) {
        return DEFAULT_DELEGATION_PAYLOAD;
    }

    /// @notice Confirm that a given signature for default delegation resolves to a specific delegator
    /// and is currently valid.
    function validateDefaultPayload(
        address delegator, bytes calldata signature
    ) external view override returns (bool valid) {
        uint256 delegatorNonce = UNI.nonces(delegator);
        (uint8 v, bytes32 r, bytes32 s) = _unpackSignature(signature);
        valid = (delegatorNonce == 0 && ecrecover(DEFAULT_DELEGATION_PAYLOAD, v, r, s) == delegator);
    }

    /// @notice Provide a valid signature to delegate to Dharma — delegation can be reassigned to
    /// another account at any time, but any votes that have already occurred will persist.
    function delegateToDharmaViaDefault(bytes calldata signature) external override returns (bool ok) {
        (uint8 v, bytes32 r, bytes32 s) = _unpackSignature(signature);
        UNI.delegateBySig(DHARMA_DELEGATEE, ZERO_NONCE, DISTANT_EXPIRY, v, r, s);
        ok = true;
    }
    
    /// @notice Get a custom payload to sign for delegating to Dharma — this supports non-zero nonces,
    /// and any expiration can be specified.
    function getCustomDelegationPayload(
        address delegator, uint256 expiry
    ) public view override returns (bytes32) {
        uint256 nonce = UNI.nonces(delegator);
        bytes32 structHash = keccak256(
            abi.encode(
                DELEGATION_TYPEHASH, DHARMA_DELEGATEE, nonce, expiry
            )
        );
        return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash));
    }

    /// @notice Confirm that a given signature for custom delegation resolves to a specific delegator
    /// and is currently valid.
    function validateCustomPayload(
        address delegator, uint256 expiry, bytes calldata signature
    ) external view override returns (bool valid) {
        bytes32 customPayload = getCustomDelegationPayload(delegator, expiry);
        (uint8 v, bytes32 r, bytes32 s) = _unpackSignature(signature);
        valid = (block.timestamp <= expiry && ecrecover(customPayload, v, r, s) == delegator);
    }

    /// @notice Provide a valid signature and custom arguments to delegate to Dharma — delegation
    /// can be reassigned to another account at any time, but any votes that have already occurred
    /// will persist.
    function delegateToDharmaViaCustom(
        address delegator, uint256 expiry, bytes calldata signature
    ) external override returns (bool ok) {
        uint256 delegatorNonce = UNI.nonces(delegator);
        (uint8 v, bytes32 r, bytes32 s) = _unpackSignature(signature);
        UNI.delegateBySig(DHARMA_DELEGATEE, delegatorNonce, expiry, v, r, s);
        ok = true;
    }
    
    /// @notice Internal function to deconstruct an aggregated signature into r, s, and v values.
    function _unpackSignature(
        bytes memory signature
    ) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
        require(signature.length == 65, "Signature length is incorrect.");

        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }
    }
}