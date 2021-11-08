pragma solidity =0.8.9;

interface IERC20 {
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function mint(uint256 _value, address _beneficiary) external;

    function burn(uint256 _value, address _beneficiary) external;
}

contract BscBridgeOptimized {
    event BurnTokens(bytes32 txHash, bytes tx);
    event MintTokens(
        uint256 amountToUnlock,
        uint256 _nonce,
        address targetContract,
        address receiver
    );

    //custom errors
    error HashMismatched(bytes32 h1, bytes32 h2);
    error signatureInvalid(bytes sig1, bytes sig2);
    error InvalidContractAddress(
        address invalidAddress,
        address expectedAddress
    );
    error SignatureLength(uint256 actual, uint256 expected);
    error AllowanceInsufficient(
        uint256 actualAllowance,
        uint256 expectedAllowance
    );
    error ZeroAddressPassed();
    error ZeroAmount();
    error ThresholdNotMet(uint256 actual, uint256 expected);
    error InvalidThreshold();
    error SignatureVerificationFailed();
    error DupilcateSignature();
    error DoubleClaimDetected();
    error InvalidMessage();
    error MaxOwners(uint256 actual, uint256 expected);
    error OwnerAlreadyExists();
    error NotOwner();
    //state variables

    uint256 internal nonce;
    uint256 internal threshold;

    address internal BSCTOKEN;
    address internal ethereumBridgeAdd;
    address internal owner;

    //validators
    mapping(address => bool) internal validators;

    mapping(bytes32 => bool) internal txStore;

    // only 5 owners allowed
    constructor(
        address[] memory _validators,
        address _BSCTOKEN,
        address _owner,
        address __ETHADD,
        uint256 _multiSigThreshold
    ) {
        if (_validators.length != 5) revert MaxOwners(_validators.length, 5);
        if (_multiSigThreshold < 3)
            revert ThresholdNotMet(_multiSigThreshold, 3);

        threshold = _multiSigThreshold;
        BSCTOKEN = _BSCTOKEN;
        owner = _owner;
        ethereumBridgeAdd = __ETHADD;
        for (uint256 i = 0; i < _validators.length; i++) {
            validators[_validators[i]] = true;
        }
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only Owner can call this function");
        _;
    }

    //set binance add

    function nonceIncrement() internal {
        nonce++;
    }

    function checkTx(bytes32 txClaim) external view returns (bool) {
        return (txStore[txClaim]);
    }

    //onlyOwner
    function setTargetChainContractAdd(address _ethAdd) external onlyOwner {
        ethereumBridgeAdd = _ethAdd;
    }

    function viewOwners(address checkAddress) external view returns (bool) {
        return validators[checkAddress];
    }

    function setThreshold(uint256 _newThreshold) external onlyOwner {
        if (!(_newThreshold >= 3 && _newThreshold <= 5)) revert InvalidThreshold();
        threshold = _newThreshold;
    }

    function changeToken(address _newToken) external onlyOwner {
        BSCTOKEN = _newToken;
    }

    function addAndRemoveOwner(
        address removeOwnerAddress,
        address addOwnerAddress
    ) external onlyOwner {
        if (removeOwnerAddress == address(0) || addOwnerAddress == address(0))
            revert ZeroAddressPassed();
        if (validators[addOwnerAddress]) revert OwnerAlreadyExists();
        if (!validators[removeOwnerAddress]) revert NotOwner();
        validators[removeOwnerAddress] = false;
        validators[addOwnerAddress] = true;
    }

    function burnTokens(uint256 amount, address targetChain) external {
        if (!(amount > 0)) revert ZeroAmount();
        if (targetChain == address(0)) revert ZeroAddressPassed();

        if (IERC20(BSCTOKEN).allowance(msg.sender, address(this)) < amount)
            revert AllowanceInsufficient(
                IERC20(BSCTOKEN).allowance(msg.sender, address(this)),
                amount
            );

        IERC20(BSCTOKEN).burn(amount, msg.sender);
        uint256 oldNonce = nonce;
        nonceIncrement();

        emit BurnTokens(
            keccak256(
                abi.encode(amount, oldNonce, ethereumBridgeAdd, targetChain)
            ),
            abi.encode(amount, oldNonce, ethereumBridgeAdd, targetChain)
        );
    }

    function mintTokens(
        bytes32 messageHash,
        bytes calldata message,
        bytes[] calldata claimedSig
    ) external {
        if (txStore[keccak256(message)] == true) revert DoubleClaimDetected();
        if (message.length <= 32) revert InvalidMessage();
        (
            uint256 amount,
            uint256 _nonce,
            address targetContract,
            address to
        ) = abi.decode(message, (uint256, uint256, address, address));

        if (targetContract != address(this))
            revert InvalidContractAddress(targetContract, address(this));
        if (messageHash != prefixed(keccak256(message)))
            revert HashMismatched(messageHash, prefixed(keccak256(message)));
        //signature check
        if (signaturesVerifier(claimedSig, messageHash) == true)
            _mintTokens(amount, _nonce, targetContract, to, keccak256(message));
    }

    function _mintTokens(
        uint256 amountToMint,
        uint256 _nonce,
        address targetContract,
        address to,
        bytes32 _tX
    ) internal {
        txStore[_tX] = true;
        IERC20(BSCTOKEN).mint(amountToMint, to);
        emit MintTokens(amountToMint, _nonce, targetContract, to);
    }

    //utilities

    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
        require(sig.length == 65);

        assembly {
            // first 32 bytes, after the length prefix.
            r := mload(add(sig, 32))
            // second 32 bytes.
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 byt (es).
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    function recoverSigner(bytes32 message, bytes memory sig)
        internal
        pure
        returns (address)
    {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);

        return ecrecover(message, v, r, s);
    }

    function signaturesVerifier(
        bytes[] calldata claimedSignatures,
        bytes32 prefixedHash
    ) internal view returns (bool) {
        //further optimized to reduce loops
        uint256 _threshold = threshold;
        address lastOwner;
        address currentOwner;
        //threshold check, signatures should be more than or equal to threshold
        if (claimedSignatures.length < _threshold)
            revert ThresholdNotMet(claimedSignatures.length, _threshold);

        //sorted signatures, first address is less than second, so check directly instead of extra loop usage
        //minimum threshold 3

        lastOwner = recoverSigner(prefixedHash, claimedSignatures[0]);
        currentOwner = recoverSigner(prefixedHash, claimedSignatures[1]);
        if (
            !(currentOwner > lastOwner &&
                validators[currentOwner] &&
                validators[lastOwner])
        ) revert SignatureVerificationFailed();
        else lastOwner = currentOwner;

        for (uint256 i = 2; i < claimedSignatures.length; i++) {
            currentOwner = recoverSigner(prefixedHash, claimedSignatures[i]);
            if (!(currentOwner > lastOwner && validators[currentOwner] == true))
                revert SignatureVerificationFailed();
            lastOwner = currentOwner;
        }
        return true;
    }
}