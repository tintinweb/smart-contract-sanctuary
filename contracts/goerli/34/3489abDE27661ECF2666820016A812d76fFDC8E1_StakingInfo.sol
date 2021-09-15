/**
 *Submitted for verification at Etherscan.io on 2021-09-15
*/

/**
 *Submitted for verification at Etherscan.io on 2020-06-30
*/

// File: contracts/common/governance/IGovernance.sol

pragma solidity ^0.5.2;

interface IGovernance {
    function update(address target, bytes calldata data) external;
}

// File: contracts/common/governance/Governable.sol

pragma solidity ^0.5.2;


contract Governable {
    IGovernance public governance;

    constructor(address _governance) public {
        governance = IGovernance(_governance);
    }

    modifier onlyGovernance() {
        require(
            msg.sender == address(governance),
            "Only governance contract is authorized"
        );
        _;
    }
}

// File: contracts/root/withdrawManager/IWithdrawManager.sol

pragma solidity ^0.5.2;

contract IWithdrawManager {
    function createExitQueue(address token) external;

    function verifyInclusion(
        bytes calldata data,
        uint8 offset,
        bool verifyTxInclusion
    ) external view returns (uint256 age);

    function addExitToQueue(
        address exitor,
        address childToken,
        address rootToken,
        uint256 exitAmountOrTokenId,
        bytes32 txHash,
        bool isRegularExit,
        uint256 priority
    ) external;

    function addInput(
        uint256 exitId,
        uint256 age,
        address utxoOwner,
        address token
    ) external;

    function challengeExit(
        uint256 exitId,
        uint256 inputId,
        bytes calldata challengeData,
        address adjudicatorPredicate
    ) external;
}

// File: contracts/common/Registry.sol

pragma solidity ^0.5.2;




contract Registry is Governable {
    // @todo hardcode constants
    bytes32 private constant WETH_TOKEN = keccak256("wethToken");
    bytes32 private constant DEPOSIT_MANAGER = keccak256("depositManager");
    bytes32 private constant STAKE_MANAGER = keccak256("stakeManager");
    bytes32 private constant VALIDATOR_SHARE = keccak256("validatorShare");
    bytes32 private constant WITHDRAW_MANAGER = keccak256("withdrawManager");
    bytes32 private constant CHILD_CHAIN = keccak256("childChain");
    bytes32 private constant STATE_SENDER = keccak256("stateSender");
    bytes32 private constant SLASHING_MANAGER = keccak256("slashingManager");

    address public erc20Predicate;
    address public erc721Predicate;

    mapping(bytes32 => address) public contractMap;
    mapping(address => address) public rootToChildToken;
    mapping(address => address) public childToRootToken;
    mapping(address => bool) public proofValidatorContracts;
    mapping(address => bool) public isERC721;

    enum Type {Invalid, ERC20, ERC721, Custom}
    struct Predicate {
        Type _type;
    }
    mapping(address => Predicate) public predicates;

    event TokenMapped(address indexed rootToken, address indexed childToken);
    event ProofValidatorAdded(address indexed validator, address indexed from);
    event ProofValidatorRemoved(address indexed validator, address indexed from);
    event PredicateAdded(address indexed predicate, address indexed from);
    event PredicateRemoved(address indexed predicate, address indexed from);
    event ContractMapUpdated(bytes32 indexed key, address indexed previousContract, address indexed newContract);

    constructor(address _governance) public Governable(_governance) {}

    function updateContractMap(bytes32 _key, address _address) external onlyGovernance {
        emit ContractMapUpdated(_key, contractMap[_key], _address);
        contractMap[_key] = _address;
    }

    /**
     * @dev Map root token to child token
     * @param _rootToken Token address on the root chain
     * @param _childToken Token address on the child chain
     * @param _isERC721 Is the token being mapped ERC721
     */
    function mapToken(
        address _rootToken,
        address _childToken,
        bool _isERC721
    ) external onlyGovernance {
        require(_rootToken != address(0x0) && _childToken != address(0x0), "INVALID_TOKEN_ADDRESS");
        rootToChildToken[_rootToken] = _childToken;
        childToRootToken[_childToken] = _rootToken;
        isERC721[_rootToken] = _isERC721;
        IWithdrawManager(contractMap[WITHDRAW_MANAGER]).createExitQueue(_rootToken);
        emit TokenMapped(_rootToken, _childToken);
    }

    function addErc20Predicate(address predicate) public onlyGovernance {
        require(predicate != address(0x0), "Can not add null address as predicate");
        erc20Predicate = predicate;
        addPredicate(predicate, Type.ERC20);
    }

    function addErc721Predicate(address predicate) public onlyGovernance {
        erc721Predicate = predicate;
        addPredicate(predicate, Type.ERC721);
    }

    function addPredicate(address predicate, Type _type) public onlyGovernance {
        require(predicates[predicate]._type == Type.Invalid, "Predicate already added");
        predicates[predicate]._type = _type;
        emit PredicateAdded(predicate, msg.sender);
    }

    function removePredicate(address predicate) public onlyGovernance {
        require(predicates[predicate]._type != Type.Invalid, "Predicate does not exist");
        delete predicates[predicate];
        emit PredicateRemoved(predicate, msg.sender);
    }

    function getValidatorShareAddress() public view returns (address) {
        return contractMap[VALIDATOR_SHARE];
    }

    function getWethTokenAddress() public view returns (address) {
        return contractMap[WETH_TOKEN];
    }

    function getDepositManagerAddress() public view returns (address) {
        return contractMap[DEPOSIT_MANAGER];
    }

    function getStakeManagerAddress() public view returns (address) {
        return contractMap[STAKE_MANAGER];
    }

    function getSlashingManagerAddress() public view returns (address) {
        return contractMap[SLASHING_MANAGER];
    }

    function getWithdrawManagerAddress() public view returns (address) {
        return contractMap[WITHDRAW_MANAGER];
    }

    function getChildChainAndStateSender() public view returns (address, address) {
        return (contractMap[CHILD_CHAIN], contractMap[STATE_SENDER]);
    }

    function isTokenMapped(address _token) public view returns (bool) {
        return rootToChildToken[_token] != address(0x0);
    }

    function isTokenMappedAndIsErc721(address _token) public view returns (bool) {
        require(isTokenMapped(_token), "TOKEN_NOT_MAPPED");
        return isERC721[_token];
    }

    function isTokenMappedAndGetPredicate(address _token) public view returns (address) {
        if (isTokenMappedAndIsErc721(_token)) {
            return erc721Predicate;
        }
        return erc20Predicate;
    }

    function isChildTokenErc721(address childToken) public view returns (bool) {
        address rootToken = childToRootToken[childToken];
        require(rootToken != address(0x0), "Child token is not mapped");
        return isERC721[rootToken];
    }
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.5.2;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

pragma solidity ^0.5.2;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     * @notice Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/common/lib/BytesLib.sol

pragma solidity ^0.5.2;


library BytesLib {
    function concat(bytes memory _preBytes, bytes memory _postBytes)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;
        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(
                0x40,
                and(
                    add(add(end, iszero(add(length, mload(_preBytes)))), 31),
                    not(31) // Round down to the nearest 32 bytes.
                )
            )
        }
        return tempBytes;
    }

    function slice(bytes memory _bytes, uint256 _start, uint256 _length)
        internal
        pure
        returns (bytes memory)
    {
        require(_bytes.length >= (_start + _length));
        bytes memory tempBytes;
        assembly {
            switch iszero(_length)
                case 0 {
                    // Get a location of some free memory and store it in tempBytes as
                    // Solidity does for memory variables.
                    tempBytes := mload(0x40)

                    // The first word of the slice result is potentially a partial
                    // word read from the original array. To read it, we calculate
                    // the length of that partial word and start copying that many
                    // bytes into the array. The first word we copy will start with
                    // data we don't care about, but the last `lengthmod` bytes will
                    // land at the beginning of the contents of the new array. When
                    // we're done copying, we overwrite the full first word with
                    // the actual length of the slice.
                    let lengthmod := and(_length, 31)

                    // The multiplication in the next line is necessary
                    // because when slicing multiples of 32 bytes (lengthmod == 0)
                    // the following copy loop was copying the origin's length
                    // and then ending prematurely not copying everything it should.
                    let mc := add(
                        add(tempBytes, lengthmod),
                        mul(0x20, iszero(lengthmod))
                    )
                    let end := add(mc, _length)

                    for {
                        // The multiplication in the next line has the same exact purpose
                        // as the one above.
                        let cc := add(
                            add(
                                add(_bytes, lengthmod),
                                mul(0x20, iszero(lengthmod))
                            ),
                            _start
                        )
                    } lt(mc, end) {
                        mc := add(mc, 0x20)
                        cc := add(cc, 0x20)
                    } {
                        mstore(mc, mload(cc))
                    }

                    mstore(tempBytes, _length)

                    //update free-memory pointer
                    //allocating the array padded to 32 bytes like the compiler does now
                    mstore(0x40, and(add(mc, 31), not(31)))
                }
                //if we want a zero-length slice let's just return a zero-length array
                default {
                    tempBytes := mload(0x40)
                    mstore(0x40, add(tempBytes, 0x20))
                }
        }

        return tempBytes;
    }

    // Pad a bytes array to 32 bytes
    function leftPad(bytes memory _bytes) internal pure returns (bytes memory) {
        // may underflow if bytes.length < 32. Hence using SafeMath.sub
        bytes memory newBytes = new bytes(SafeMath.sub(32, _bytes.length));
        return concat(newBytes, _bytes);
    }

    function toBytes32(bytes memory b) internal pure returns (bytes32) {
        require(b.length >= 32, "Bytes array should atleast be 32 bytes");
        bytes32 out;
        for (uint256 i = 0; i < 32; i++) {
            out |= bytes32(b[i] & 0xFF) >> (i * 8);
        }
        return out;
    }

    function toBytes4(bytes memory b) internal pure returns (bytes4 result) {
        assembly {
            result := mload(add(b, 32))
        }
    }

    function fromBytes32(bytes32 x) internal pure returns (bytes memory) {
        bytes memory b = new bytes(32);
        for (uint256 i = 0; i < 32; i++) {
            b[i] = bytes1(uint8(uint256(x) / (2**(8 * (31 - i)))));
        }
        return b;
    }

    function fromUint(uint256 _num) internal pure returns (bytes memory _ret) {
        _ret = new bytes(32);
        assembly {
            mstore(add(_ret, 32), _num)
        }
    }

    function toUint(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint256)
    {
        require(_bytes.length >= (_start + 32));
        uint256 tempUint;
        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }
        return tempUint;
    }

    function toAddress(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (address)
    {
        require(_bytes.length >= (_start + 20));
        address tempAddress;
        assembly {
            tempAddress := div(
                mload(add(add(_bytes, 0x20), _start)),
                0x1000000000000000000000000
            )
        }

        return tempAddress;
    }
}

// File: contracts/common/lib/ECVerify.sol

pragma solidity ^0.5.2;


library ECVerify {
    function ecrecovery(bytes32 hash, bytes memory sig)
        public
        pure
        returns (address)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (sig.length != 65) {
            return address(0x0);
        }

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := and(mload(add(sig, 65)), 255)
        }

        // https://github.com/ethereum/go-ethereum/issues/2053
        if (v < 27) {
            v += 27;
        }

        if (v != 27 && v != 28) {
            return address(0x0);
        }

        // get address out of hash and signature
        address result = ecrecover(hash, v, r, s);

        // ecrecover returns zero on error
        require(result != address(0x0));

        return result;
    }

    function ecrecovery(bytes32 hash, uint8 v, bytes32 r, bytes32 s)
        public
        pure
        returns (address)
    {
        // get address out of hash and signature
        address result = ecrecover(hash, v, r, s);

        // ecrecover returns zero on error
        require(result != address(0x0), "signature verification failed");

        return result;
    }

    function ecverify(bytes32 hash, bytes memory sig, address signer)
        public
        pure
        returns (bool)
    {
        return signer == ecrecovery(hash, sig);
    }
}

// File: contracts/staking/StakingInfo.sol

pragma solidity ^0.5.2;







// dummy interface to avoid cyclic dependency
contract IStakeManagerLocal {
    enum Status {Inactive, Active, Locked, Unstaked}

    struct Validator {
        uint256 amount;
        uint256 reward;
        uint256 activationEpoch;
        uint256 deactivationEpoch;
        uint256 jailTime;
        address signer;
        address contractAddress;
        Status status;
    }

    mapping(uint256 => Validator) public validators;
    bytes32 public accountStateRoot;
    uint256 public activeAmount; // delegation amount from validator contract
    uint256 public validatorRewards;

    function currentValidatorSetTotalStake() public view returns (uint256);

    // signer to Validator mapping
    function signerToValidator(address validatorAddress)
        public
        view
        returns (uint256);

    function isValidator(uint256 validatorId) public view returns (bool);
}


contract StakingInfo is Ownable {
    using SafeMath for uint256;
    mapping(uint256 => uint256) public validatorNonce;

    /// @dev Emitted when validator stakes in '_stakeFor()' in StakeManager.
    /// @param signer validator address.
    /// @param validatorId unique integer to identify a validator.
    /// @param nonce to synchronize the events in heimdal.
    /// @param activationEpoch validator's first epoch as proposer.
    /// @param amount staking amount.
    /// @param total total staking amount.
    /// @param signerPubkey public key of the validator
    event Staked(
        address indexed signer,
        uint256 indexed validatorId,
        uint256 nonce,
        uint256 indexed activationEpoch,
        uint256 amount,
        uint256 total,
        bytes signerPubkey
    );

    /// @dev Emitted when validator unstakes in 'unstakeClaim()'
    /// @param user address of the validator.
    /// @param validatorId unique integer to identify a validator.
    /// @param amount staking amount.
    /// @param total total staking amount.
    event Unstaked(
        address indexed user,
        uint256 indexed validatorId,
        uint256 amount,
        uint256 total
    );

    /// @dev Emitted when validator unstakes in '_unstake()'.
    /// @param user address of the validator.
    /// @param validatorId unique integer to identify a validator.
    /// @param nonce to synchronize the events in heimdal.
    /// @param deactivationEpoch last epoch for validator.
    /// @param amount staking amount.
    event UnstakeInit(
        address indexed user,
        uint256 indexed validatorId,
        uint256 nonce,
        uint256 deactivationEpoch,
        uint256 indexed amount
    );

    /// @dev Emitted when the validator public key is updated in 'updateSigner()'.
    /// @param validatorId unique integer to identify a validator.
    /// @param nonce to synchronize the events in heimdal.
    /// @param oldSigner old address of the validator.
    /// @param newSigner new address of the validator.
    /// @param signerPubkey public key of the validator.
    event SignerChange(
        uint256 indexed validatorId,
        uint256 nonce,
        address indexed oldSigner,
        address indexed newSigner,
        bytes signerPubkey
    );
    event Restaked(uint256 indexed validatorId, uint256 amount, uint256 total);
    event Jailed(
        uint256 indexed validatorId,
        uint256 indexed exitEpoch,
        address indexed signer
    );
    event UnJailed(uint256 indexed validatorId, address indexed signer);
    event Slashed(uint256 indexed nonce, uint256 indexed amount);
    event ThresholdChange(uint256 newThreshold, uint256 oldThreshold);
    event DynastyValueChange(uint256 newDynasty, uint256 oldDynasty);
    event ProposerBonusChange(
        uint256 newProposerBonus,
        uint256 oldProposerBonus
    );

    event RewardUpdate(uint256 newReward, uint256 oldReward);

    /// @dev Emitted when validator confirms the auction bid and at the time of restaking in confirmAuctionBid() and restake().
    /// @param validatorId unique integer to identify a validator.
    /// @param newAmount the updated stake amount.
    event StakeUpdate(
        uint256 indexed validatorId,
        uint256 indexed newAmount
    );
    event ClaimRewards(
        uint256 indexed validatorId,
        uint256 indexed amount,
        uint256 indexed totalAmount
    );
    event StartAuction(
        uint256 indexed validatorId,
        uint256 indexed amount,
        uint256 indexed auctionAmount
    );
    event ConfirmAuction(
        uint256 indexed newValidatorId,
        uint256 indexed oldValidatorId,
        uint256 indexed amount
    );
    event TopUpFee(address indexed user, uint256 indexed fee);
    event ClaimFee(address indexed user, uint256 indexed fee);
    // Delegator events
    event ShareMinted(
        uint256 indexed validatorId,
        address indexed user,
        uint256 indexed amount,
        uint256 tokens
    );
    event ShareBurned(
        uint256 indexed validatorId,
        address indexed user,
        uint256 indexed amount,
        uint256 tokens
    );
    event DelegatorClaimedRewards(
        uint256 indexed validatorId,
        address indexed user,
        uint256 indexed rewards
    );
    event DelegatorRestaked(
        uint256 indexed validatorId,
        address indexed user,
        uint256 indexed totalStaked
    );
    event DelegatorUnstaked(
        uint256 indexed validatorId,
        address indexed user,
        uint256 amount
    );
    event UpdateCommissionRate(
        uint256 indexed validatorId,
        uint256 indexed newCommissionRate,
        uint256 indexed oldCommissionRate
    );
    event StakeAck(
        uint256 indexed validatorId,
        uint256 indexed nonce
    );
    event CheckpointSyncAck(
        address indexed proposer,
        uint256 indexed chainId,
        uint256 indexed checkpointId,
        uint256 start,
        uint256 end
    );

    Registry public registry;

    modifier onlyValidatorContract(uint256 validatorId) {
        address _contract;
        (, , , , , , _contract, ) = IStakeManagerLocal(
            registry.getStakeManagerAddress()
        )
            .validators(validatorId);
        require(_contract == msg.sender,
        "Invalid sender, not validator");
        _;
    }

    modifier StakeManagerOrValidatorContract(uint256 validatorId) {
        address _contract;
        address _stakeManager = registry.getStakeManagerAddress();
        (, , , , , , _contract, ) = IStakeManagerLocal(_stakeManager).validators(
            validatorId
        );
        require(_contract == msg.sender || _stakeManager == msg.sender,
        "Invalid sender, not stake manager or validator contract");
        _;
    }

    modifier onlyStakeManager() {
        require(registry.getStakeManagerAddress() == msg.sender,
        "Invalid sender, not stake manager");
        _;
    }
    modifier onlySlashingManager() {
        require(registry.getSlashingManagerAddress() == msg.sender,
        "Invalid sender, not slashing manager");
        _;
    }

    constructor(address _registry) public {
        registry = Registry(_registry);
    }

    function updateNonce(
        uint256[] calldata validatorIds,
        uint256[] calldata nonces
    ) external onlyOwner {
        require(validatorIds.length == nonces.length, "args length mismatch");

        for (uint256 i = 0; i < validatorIds.length; ++i) {
            validatorNonce[validatorIds[i]] = nonces[i];
        }
    } 

    function getValidatorNonce(
        uint256 validatorId
    ) public onlyStakeManager returns (uint256) {
        return validatorNonce[validatorId];
    }

    function logStaked(
        address signer,
        bytes memory signerPubkey,
        uint256 validatorId,
        uint256 activationEpoch,
        uint256 amount,
        uint256 total
    ) public onlyStakeManager {
        validatorNonce[validatorId] = validatorNonce[validatorId].add(1);
        emit Staked(
            signer,
            validatorId,
            validatorNonce[validatorId],
            activationEpoch,
            amount,
            total,
            signerPubkey
        );
    }

    function logUnstaked(
        address user,
        uint256 validatorId,
        uint256 amount,
        uint256 total
    ) public onlyStakeManager {
        emit Unstaked(user, validatorId, amount, total);
    }

    function logUnstakeInit(
        address user,
        uint256 validatorId,
        uint256 deactivationEpoch,
        uint256 amount
    ) public onlyStakeManager {
        validatorNonce[validatorId] = validatorNonce[validatorId].add(1);
        emit UnstakeInit(
            user,
            validatorId,
            validatorNonce[validatorId],
            deactivationEpoch,
            amount
        );
    }

    function logSignerChange(
        uint256 validatorId,
        address oldSigner,
        address newSigner,
        bytes memory signerPubkey
    ) public onlyStakeManager {
        validatorNonce[validatorId] = validatorNonce[validatorId].add(1);
        emit SignerChange(
            validatorId,
            validatorNonce[validatorId],
            oldSigner,
            newSigner,
            signerPubkey
        );
    }

    function logRestaked(uint256 validatorId, uint256 amount, uint256 total)
        public
        onlyStakeManager
    {
        emit Restaked(validatorId, amount, total);
    }

    function logJailed(uint256 validatorId, uint256 exitEpoch, address signer)
        public
        onlyStakeManager
    {
        emit Jailed(validatorId, exitEpoch, signer);
    }

    function logUnjailed(uint256 validatorId, address signer)
        public
        onlyStakeManager
    {
        emit UnJailed(validatorId, signer);
    }

    function logSlashed(uint256 nonce, uint256 amount)
        public
        onlySlashingManager
    {
        emit Slashed(nonce, amount);
    }

    function logThresholdChange(uint256 newThreshold, uint256 oldThreshold)
        public
        onlyStakeManager
    {
        emit ThresholdChange(newThreshold, oldThreshold);
    }

    function logDynastyValueChange(uint256 newDynasty, uint256 oldDynasty)
        public
        onlyStakeManager
    {
        emit DynastyValueChange(newDynasty, oldDynasty);
    }

    function logProposerBonusChange(
        uint256 newProposerBonus,
        uint256 oldProposerBonus
    ) public onlyStakeManager {
        emit ProposerBonusChange(newProposerBonus, oldProposerBonus);
    }

    function logRewardUpdate(uint256 newReward, uint256 oldReward)
        public
        onlyStakeManager
    {
        emit RewardUpdate(newReward, oldReward);
    }

    function logStakeUpdate(uint256 validatorId)
        public
        StakeManagerOrValidatorContract(validatorId)
    {
        emit StakeUpdate(
            validatorId,
            totalValidatorStake(validatorId)
        );
    }

    function logClaimRewards(
        uint256 validatorId,
        uint256 amount,
        uint256 totalAmount
    ) public onlyStakeManager {
        emit ClaimRewards(validatorId, amount, totalAmount);
    }

    function logStartAuction(
        uint256 validatorId,
        uint256 amount,
        uint256 auctionAmount
    ) public onlyStakeManager {
        emit StartAuction(validatorId, amount, auctionAmount);
    }

    function logConfirmAuction(
        uint256 newValidatorId,
        uint256 oldValidatorId,
        uint256 amount
    ) public onlyStakeManager {
        emit ConfirmAuction(newValidatorId, oldValidatorId, amount);
    }

    function logTopUpFee(address user, uint256 fee) public onlyStakeManager {
        emit TopUpFee(user, fee);
    }

    function logClaimFee(address user, uint256 fee) public onlyStakeManager {
        emit ClaimFee(user, fee);
    }

    function getStakerDetails(uint256 validatorId)
        public
        view
        returns (
            uint256 amount,
            uint256 reward,
            uint256 activationEpoch,
            uint256 deactivationEpoch,
            address signer,
            uint256 _status
        )
    {
        IStakeManagerLocal stakeManager = IStakeManagerLocal(
            registry.getStakeManagerAddress()
        );
        address _contract;
        IStakeManagerLocal.Status status;
        (
            amount,
            reward,
            activationEpoch,
            deactivationEpoch,
            ,
            signer,
            _contract,
            status
        ) = stakeManager.validators(validatorId);
        _status = uint256(status);
        if (_contract != address(0x0)) {
            reward += IStakeManagerLocal(_contract).validatorRewards();
        }
    }

    function totalValidatorStake(uint256 validatorId)
        public
        view
        returns (uint256 validatorStake)
    {
        address contractAddress;
        (validatorStake, , , , , , contractAddress, ) = IStakeManagerLocal(
            registry.getStakeManagerAddress()
        )
            .validators(validatorId);
        if (contractAddress != address(0x0)) {
            validatorStake += IStakeManagerLocal(contractAddress).activeAmount();
        }
    }

    function getAccountStateRoot()
        public
        view
        returns (bytes32 accountStateRoot)
    {
        accountStateRoot = IStakeManagerLocal(registry.getStakeManagerAddress())
            .accountStateRoot();
    }

    function getValidatorContractAddress(uint256 validatorId)
        public
        view
        returns (address ValidatorContract)
    {
        (, , , , , , ValidatorContract, ) = IStakeManagerLocal(
            registry.getStakeManagerAddress()
        )
            .validators(validatorId);
    }

    // validator Share contract logging func
    function logShareMinted(
        uint256 validatorId,
        address user,
        uint256 amount,
        uint256 tokens
    ) public onlyValidatorContract(validatorId) {
        emit ShareMinted(validatorId, user, amount, tokens);
    }

    function logShareBurned(
        uint256 validatorId,
        address user,
        uint256 amount,
        uint256 tokens
    ) public onlyValidatorContract(validatorId) {
        emit ShareBurned(validatorId, user, amount, tokens);
    }

    function logDelegatorClaimRewards(
        uint256 validatorId,
        address user,
        uint256 rewards
    ) public onlyValidatorContract(validatorId) {
        emit DelegatorClaimedRewards(validatorId, user, rewards);
    }

    function logDelegatorRestaked(
        uint256 validatorId,
        address user,
        uint256 totalStaked
    ) public onlyValidatorContract(validatorId) {
        emit DelegatorRestaked(validatorId, user, totalStaked);
    }

    function logDelegatorUnstaked(uint256 validatorId, address user, uint256 amount)
        public
        onlyValidatorContract(validatorId)
    {
        emit DelegatorUnstaked(validatorId, user, amount);
    }

    function logUpdateCommissionRate(
        uint256 validatorId,
        uint256 newCommissionRate,
        uint256 oldCommissionRate
    ) public onlyValidatorContract(validatorId) {
        emit UpdateCommissionRate(
            validatorId,
            newCommissionRate,
            oldCommissionRate
        );
    }

    function logStakeAck(uint256 validatorId) public onlyStakeManager {
        validatorNonce[validatorId] = validatorNonce[validatorId].add(1);
        emit StakeAck(
            validatorId,
              validatorNonce[validatorId]
        );
    }

    function logCheckpointAck(
        address proposer,
        uint256 chainId,
        uint256 checkpointId,
        uint256 start,
        uint256 end
    ) public onlyStakeManager {
        emit CheckpointSyncAck(
            proposer,
            chainId,
            checkpointId,
            start,
            end
        );
    }
}