pragma solidity =0.8.9;

//LETS PLAY OPTIMIZATION :)

interface IERC20 {
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract EthBridgeOptimized {
    event LockTokens(bytes32 txHash, bytes tx);
    event UnlockTokens(
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
    error TransferFromFailed();
    error ZeroAddressPassed();
    error ZeroAmount();
    error ThresholdNotMet(uint256 actual, uint256 expected);
    error SignatureVerificationFailed();
    error DupilcateSignature();
    error UnlockingTokensFailed();
    error DoubleClaimDetected();
    error InvalidMessage();
    //state variables

    uint256 internal nonce;
    uint256 internal threshold;

    address internal ETHTOKEN;
    address internal binanceBridgeAdd;
    address internal owner;

    //validators
    mapping(address => bool) internal validators;

    mapping(bytes32 => bool) internal txStore;

    //always min 5 address
    constructor(
        address[] memory _validators,
        address _ETHTOKEN,
        address _owner,
        address __BSCADD,
        uint256 _multiSigThreshold
    ) {
        ETHTOKEN = _ETHTOKEN;
        owner = _owner;
        binanceBridgeAdd = __BSCADD;
        threshold = _multiSigThreshold;

        validators[_validators[0]] = true;
        validators[_validators[1]] = true;
        validators[_validators[2]] = true;
        validators[_validators[3]] = true;
        validators[_validators[4]] = true;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only Owner can call this function");
        _;
    }

    //set binance add
    function setTargetChainContractAdd(address _binanceAdd) external onlyOwner {
        binanceBridgeAdd = _binanceAdd;
    }

    function nonceIncrement() internal {
        nonce++;
    }

    function checkTx(bytes32 txClaim) external view returns (bool) {
        return (txStore[txClaim]);
    }

    function viewOwners(address checkAddress) external view returns (bool) {
        return validators[checkAddress];
    }

    function lockTokens(uint256 amount, address targetChain) external {
        if (!(amount > 0)) revert ZeroAmount();
        if (targetChain == address(0)) revert ZeroAddressPassed();

        if (IERC20(ETHTOKEN).allowance(msg.sender, address(this)) < amount)
            revert AllowanceInsufficient(
                IERC20(ETHTOKEN).allowance(msg.sender, address(this)),
                amount
            );

        if (
            IERC20(ETHTOKEN).transferFrom(msg.sender, address(this), amount) ==
            false
        ) revert TransferFromFailed();
        uint256 oldNonce = nonce;
        nonceIncrement();

        emit LockTokens(
            keccak256(
                abi.encode(amount, oldNonce, binanceBridgeAdd, targetChain)
            ),
            abi.encode(amount, oldNonce, binanceBridgeAdd, targetChain)
        );
    }

    function unlockTokens(
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
            _unlockTokens(
                amount,
                _nonce,
                targetContract,
                to,
                keccak256(message)
            );
    }

    function _unlockTokens(
        uint256 amountToUnlock,
        uint256 _nonce,
        address targetContract,
        address to,
        bytes32 _tX
    ) internal {
        txStore[_tX] = true;
        if (IERC20(ETHTOKEN).transfer(to, amountToUnlock) == false)
            revert UnlockingTokensFailed();
        emit UnlockTokens(amountToUnlock, _nonce, targetContract, to);
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

        if (claimedSignatures.length < _threshold)
            revert ThresholdNotMet(claimedSignatures.length, _threshold);

        //sorted signatures, first addres is less than second, so check directly instead of extra loop usage
        //minimum threshold 3
        if (_threshold >= 2) {
            lastOwner = recoverSigner(prefixedHash, claimedSignatures[0]);
            currentOwner = recoverSigner(prefixedHash, claimedSignatures[1]);
            if (
                !(currentOwner > lastOwner &&
                    validators[currentOwner] &&
                    validators[lastOwner])
            ) revert SignatureVerificationFailed();
        }

        for (uint256 i = 2; i < claimedSignatures.length; i++) {
            currentOwner = recoverSigner(prefixedHash, claimedSignatures[i]);
            if (!(currentOwner > lastOwner && validators[currentOwner] == true))
                revert SignatureVerificationFailed();
            lastOwner = currentOwner;
        }
        return true;
    }
}

//bytes32 messageHash, bytes memory message, bytes[] memory signatures