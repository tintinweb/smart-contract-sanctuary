pragma solidity ^0.7.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



import "./zksync/Config.sol";
import "./nft/IZkLinkNFT.sol";
import "./oracle/ICrtReporter.sol";

/// @title Governance Contract
/// @author zk.link
contract Governance is Config {
    /// @notice Token added to Franklin net
    event NewToken(address indexed token, uint16 indexed tokenId, bool mappable);

    /// @notice Governor changed
    event NewGovernor(address newGovernor);

    /// @notice Validator's status changed
    event ValidatorStatusUpdate(address indexed validatorAddress, bool isActive);

    event TokenPausedUpdate(address indexed token, bool paused);

    event TokenMappingUpdate(address indexed token, bool isMapping);

    /// @notice Nft address changed
    event NftUpdate(address indexed nft);

    /// @notice Crt crt reporters changed
    event CrtReporterUpdate(ICrtReporter[] crtReporters);

    /// @notice Crt verified
    event CrtVerified(uint256 indexed crtBlock);

    /// @notice Address which will exercise governance over the network i.e. add tokens, change validator set, conduct upgrades
    address public networkGovernor;

    /// @notice Total number of ERC20 tokens registered in the network (excluding ETH, which is hardcoded as tokenId = 0)
    uint16 public totalTokens;

    /// @notice List of registered tokens by tokenId
    mapping(uint16 => address) public tokenAddresses;

    /// @notice List of registered tokens by address
    mapping(address => uint16) public tokenIds;

    /// @notice List of permitted validators
    mapping(address => bool) public validators;

    /// @notice Paused tokens list, deposits are impossible to create for paused tokens
    mapping(uint16 => bool) public pausedTokens;

    /// @notice Mapping tokens list
    mapping(uint16 => bool) public mappingTokens;

    /// @notice ZkLinkNFT mint to user when add liquidity
    IZkLinkNFT public nft;

    /// @notice Verified crt block height
    uint32 public verifiedCrtBlock;

    /// @notice Crt if verified reporters
    ICrtReporter[] public crtReporters;

    /// @notice Governance contract initialization. Can be external because Proxy contract intercepts illegal calls of this function.
    /// @param initializationParameters Encoded representation of initialization parameters:
    ///     _networkGovernor The address of network governor
    function initialize(bytes calldata initializationParameters) external {
        address _networkGovernor = abi.decode(initializationParameters, (address));

        networkGovernor = _networkGovernor;
    }

    /// @notice Governance contract upgrade. Can be external because Proxy contract intercepts illegal calls of this function.
    /// @param upgradeParameters Encoded representation of upgrade parameters
    function upgrade(bytes calldata upgradeParameters) external {}

    /// @notice Change current governor
    /// @param _newGovernor Address of the new governor
    function changeGovernor(address _newGovernor) external {
        requireGovernor(msg.sender);
        require(_newGovernor != address(0), "z0");
        if (networkGovernor != _newGovernor) {
            networkGovernor = _newGovernor;
            emit NewGovernor(_newGovernor);
        }
    }

    /// @notice Add token to the list of networks tokens，token must not be taken fees when transfer
    /// @param _token Token address
    /// @param _mappable Is token mappable
    function addToken(address _token, bool _mappable) external {
        requireGovernor(msg.sender);
        require(tokenIds[_token] == 0, "1e"); // token exists
        require(totalTokens < MAX_AMOUNT_OF_REGISTERED_TOKENS, "1f"); // no free identifiers for tokens

        totalTokens++;
        uint16 newTokenId = totalTokens; // it is not `totalTokens - 1` because tokenId = 0 is reserved for eth

        tokenAddresses[newTokenId] = _token;
        tokenIds[_token] = newTokenId;
        mappingTokens[newTokenId] = _mappable;
        emit NewToken(_token, newTokenId, _mappable);
    }

    /// @notice Pause token deposits for the given token
    /// @param _tokenAddr Token address
    /// @param _tokenPaused Token paused status
    function setTokenPaused(address _tokenAddr, bool _tokenPaused) external {
        requireGovernor(msg.sender);

        uint16 tokenId = this.validateTokenAddress(_tokenAddr);
        if (pausedTokens[tokenId] != _tokenPaused) {
            pausedTokens[tokenId] = _tokenPaused;
            emit TokenPausedUpdate(_tokenAddr, _tokenPaused);
        }
    }

    /// @notice Set token mapping
    /// @param _tokenAddr Token address
    /// @param _tokenMapping Token mapping status
    function setTokenMapping(address _tokenAddr, bool _tokenMapping) external {
        requireGovernor(msg.sender);

        uint16 tokenId = this.validateTokenAddress(_tokenAddr);
        if (mappingTokens[tokenId] != _tokenMapping) {
            mappingTokens[tokenId] = _tokenMapping;
            emit TokenMappingUpdate(_tokenAddr, _tokenMapping);
        }
    }

    /// @notice Change validator status (active or not active)
    /// @param _validator Validator address
    /// @param _active Active flag
    function setValidator(address _validator, bool _active) external {
        requireGovernor(msg.sender);
        if (validators[_validator] != _active) {
            validators[_validator] = _active;
            emit ValidatorStatusUpdate(_validator, _active);
        }
    }

    /// @notice Change nft
    /// @param _newNft ZKLinkNFT address
    function changeNft(address _newNft) external {
        requireGovernor(msg.sender);
        require(_newNft != address(0), "Governance: zero nft address");

        if (_newNft != address(nft)) {
            nft = IZkLinkNFT(_newNft);
            emit NftUpdate(_newNft);
        }
    }

    /// @notice Change crt reporters
    /// @param _newCrtReporters Crt reporters
    function changeCrtReporters(ICrtReporter[] memory _newCrtReporters) external {
        requireGovernor(msg.sender);
        require(_newCrtReporters.length > 1, "Governance: no crt reporter");

        crtReporters = _newCrtReporters;
        emit CrtReporterUpdate(_newCrtReporters);
    }

    /// @notice Check if specified address is is governor
    /// @param _address Address to check
    function requireGovernor(address _address) public view {
        require(_address == networkGovernor, "1g"); // only by governor
    }

    /// @notice Checks if validator is active
    /// @param _address Validator address
    function requireActiveValidator(address _address) external view {
        require(validators[_address], "1h"); // validator is not active
    }

    /// @notice Validate token id (must be less than or equal to total tokens amount)
    /// @param _tokenId Token id
    /// @return bool flag that indicates if token id is less than or equal to total tokens amount
    function isValidTokenId(uint16 _tokenId) external view returns (bool) {
        return _tokenId <= totalTokens;
    }

    /// @notice Validate token address
    /// @param _tokenAddr Token address
    /// @return tokens id
    function validateTokenAddress(address _tokenAddr) external view returns (uint16) {
        uint16 tokenId = tokenIds[_tokenAddr];
        require(tokenId != 0, "1i"); // 0 is not a valid token
        return tokenId;
    }

    /// @notice Update verified crt block
    function updateVerifiedCrtBlock(uint32 crtBlock) external {
        require(crtBlock > verifiedCrtBlock, 'Governance: crtBlock');

        // every reporter of any chain should report the same verify result of target block number
        for (uint256 i = 0; i < crtReporters.length; i++) {
            require(crtReporters[i].isCrtVerified(crtBlock), 'Governance: crt not verify');
        }
        verifiedCrtBlock = crtBlock;
        emit CrtVerified(verifiedCrtBlock);
    }
}

pragma solidity ^0.7.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



/// @title zkSync configuration constants
/// @author Matter Labs
contract Config {
    /// @dev None LP ERC20 tokens and ETH withdrawals gas limit, used only for complete withdrawals
    uint256 constant WITHDRAWAL_FROM_VAULT_GAS_LIMIT = 300000;

    /// @dev Bytes in one chunk
    uint8 constant CHUNK_BYTES = 9;

    /// @dev zkSync address length
    uint8 constant ADDRESS_BYTES = 20;

    uint8 constant PUBKEY_HASH_BYTES = 20;

    /// @dev Public key bytes length
    uint8 constant PUBKEY_BYTES = 32;

    /// @dev Ethereum signature r/s bytes length
    uint8 constant ETH_SIGN_RS_BYTES = 32;

    /// @dev Success flag bytes length
    uint8 constant SUCCESS_FLAG_BYTES = 1;

    /// @dev Max amount of tokens registered in the network (excluding ETH, which is hardcoded as tokenId = 0)
    uint16 constant MAX_AMOUNT_OF_REGISTERED_TOKENS = 127;

    /// @dev Max account id that could be registered in the network
    uint32 constant MAX_ACCOUNT_ID = (2**24) - 1;

    /// @dev Expected average period of block creation
    uint256 constant BLOCK_PERIOD = 3 seconds;

    /// @dev ETH blocks verification expectation
    /// @dev Blocks can be reverted if they are not verified for at least EXPECT_VERIFICATION_IN.
    /// @dev If set to 0 validator can revert blocks at any time.
    uint256 constant EXPECT_VERIFICATION_IN = 0 hours / BLOCK_PERIOD;

    uint256 constant NOOP_BYTES = 1 * CHUNK_BYTES;
    uint256 constant DEPOSIT_BYTES = 6 * CHUNK_BYTES;
    uint256 constant QUICK_SWAP_BYTES = 16 * CHUNK_BYTES;
    uint256 constant TRANSFER_TO_NEW_BYTES = 6 * CHUNK_BYTES;
    uint256 constant PARTIAL_EXIT_BYTES = 6 * CHUNK_BYTES;
    uint256 constant TRANSFER_BYTES = 2 * CHUNK_BYTES;
    uint256 constant FORCED_EXIT_BYTES = 6 * CHUNK_BYTES;

    /// @dev Full exit operation length
    uint256 constant FULL_EXIT_BYTES = 6 * CHUNK_BYTES;

    /// @dev ChangePubKey operation length
    uint256 constant CHANGE_PUBKEY_BYTES = 6 * CHUNK_BYTES;
    uint256 constant MAPPING_BYTES = 10 * CHUNK_BYTES;
    uint256 constant L1ADDLQ_BYTES = 11 * CHUNK_BYTES;
    uint256 constant L1REMOVELQ_BYTES = 11 * CHUNK_BYTES;

    /// @dev Expiration delta for priority request to be satisfied (in seconds)
    /// @dev NOTE: Priority expiration should be > (EXPECT_VERIFICATION_IN * BLOCK_PERIOD)
    /// @dev otherwise incorrect block with priority op could not be reverted.
    uint256 constant PRIORITY_EXPIRATION_PERIOD = 3 days;

    /// @dev Expiration delta for priority request to be satisfied (in ETH blocks)
    uint256 constant PRIORITY_EXPIRATION =
        PRIORITY_EXPIRATION_PERIOD/BLOCK_PERIOD;

    /// @dev Maximum number of priority request to clear during verifying the block
    /// @dev Cause deleting storage slots cost 5k gas per each slot it's unprofitable to clear too many slots
    /// @dev Value based on the assumption of ~750k gas cost of verifying and 5 used storage slots per PriorityOperation structure
    uint64 constant MAX_PRIORITY_REQUESTS_TO_DELETE_IN_VERIFY = 6;

    /// @dev Reserved time for users to send full exit priority operation in case of an upgrade (in seconds)
    uint256 constant MASS_FULL_EXIT_PERIOD = 9 days;

    /// @dev Reserved time for users to withdraw funds from full exit priority operation in case of an upgrade (in seconds)
    uint256 constant TIME_TO_WITHDRAW_FUNDS_FROM_FULL_EXIT = 2 days;

    /// @dev Notice period before activation preparation status of upgrade mode (in seconds)
    /// @dev NOTE: we must reserve for users enough time to send full exit operation, wait maximum time for processing this operation and withdraw funds from it.
    uint256 constant UPGRADE_NOTICE_PERIOD =
        0;

    /// @dev Timestamp - seconds since unix epoch
    uint256 constant COMMIT_TIMESTAMP_NOT_OLDER = 24 hours;

    /// @dev Maximum available error between real commit block timestamp and analog used in the verifier (in seconds)
    /// @dev Must be used cause miner's `block.timestamp` value can differ on some small value (as we know - 15 seconds)
    uint256 constant COMMIT_TIMESTAMP_APPROXIMATION_DELTA = 15 minutes;

    /// @dev Bit mask to apply for verifier public input before verifying.
    uint256 constant INPUT_MASK = 14474011154664524427946373126085988481658748083205070504932198000989141204991;

    /// @dev Auth fact reset timelock
    uint256 constant AUTH_FACT_RESET_TIMELOCK = 1 days;

    /// @dev When set fee = 100, it means 1%
    uint16 constant MAX_WITHDRAW_FEE = 10000;

    /// @dev Chain id
    uint8 constant CHAIN_ID = 4;
}

pragma solidity ^0.7.0;
pragma abicoder v2;

// SPDX-License-Identifier: MIT OR Apache-2.0





/// @title Interface of the ZkLinkNFT
/// @author zk.link
interface IZkLinkNFT {

    enum LqStatus { NONE, ADD_PENDING, FINAL, ADD_FAIL, REMOVE_PENDING }

    // liquidity info
    struct Lq {
        uint16 tokenId; // token in l2 cross chain pair
        uint128 amount; // liquidity add amount, this is the mine power in stake pool
        address pair; // l2 cross chain pair token address
        LqStatus status;
        uint128 lpTokenAmount; // l2 cross chain pair token amount
    }

    function tokenLq(uint32 nftTokenId) external view returns (Lq memory);
    function addLq(address to, uint16 tokenId, uint128 amount, address pair) external returns (uint32);
    function confirmAddLq(uint32 nftTokenId, uint128 lpTokenAmount) external;
    function revokeAddLq(uint32 nftTokenId) external;
    function removeLq(uint32 nftTokenId) external;
    function confirmRemoveLq(uint32 nftTokenId) external;
    function revokeRemoveLq(uint32 nftTokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
}

pragma solidity ^0.7.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



/// @title Interface of the crt reporter contract
/// @author zk.link
interface ICrtReporter {

    /// @notice return true if crt of chain at target l2 block number is verified
    /// @param _crtBlock crt block number of l2
    function isCrtVerified(uint32 _crtBlock) external view returns (bool);
}