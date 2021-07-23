pragma solidity ^0.5.0;

import "./Config.sol";


/// @title Governance Contract
/// @author Matter Labs
/// @author ZKSwap L2 Labs
contract Governance is Config {

    /// @notice Token added to Franklin net
    event NewToken(
        address indexed token,
        uint16 indexed tokenId
    );

    /// @notice Governor changed
    event NewGovernor(
        address newGovernor
    );

    /// @notice tokenLister changed
    event NewTokenLister(
        address newTokenLister
    );

    /// @notice Validator's status changed
    event ValidatorStatusUpdate(
        address indexed validatorAddress,
        bool isActive
    );

    /// @notice Address which will exercise governance over the network i.e. add tokens, change validator set, conduct upgrades
    address public networkGovernor;

    /// @notice Total number of ERC20 fee tokens registered in the network (excluding ETH, which is hardcoded as tokenId = 0)
    uint16 public totalFeeTokens;

    /// @notice Total number of ERC20 user tokens registered in the network
    uint16 public totalUserTokens;

    /// @notice List of registered tokens by tokenId
    mapping(uint16 => address) public tokenAddresses;

    /// @notice List of registered tokens by address
    mapping(address => uint16) public tokenIds;

    /// @notice List of permitted validators
    mapping(address => bool) public validators;

    address public tokenLister;

    constructor() public {
        networkGovernor = msg.sender;
    }

    /// @notice Governance contract initialization. Can be external because Proxy contract intercepts illegal calls of this function.
    /// @param initializationParameters Encoded representation of initialization parameters:
    ///     _networkGovernor The address of network governor
    function initialize(bytes calldata initializationParameters) external {
        require(networkGovernor == address(0), "init0");
        (address _networkGovernor, address _tokenLister) = abi.decode(initializationParameters, (address, address));

        networkGovernor = _networkGovernor;
        tokenLister = _tokenLister;
    }

    /// @notice Governance contract upgrade. Can be external because Proxy contract intercepts illegal calls of this function.
    /// @param upgradeParameters Encoded representation of upgrade parameters
    function upgrade(bytes calldata upgradeParameters) external {}

    /// @notice Change current governor
    /// @param _newGovernor Address of the new governor
    function changeGovernor(address _newGovernor) external {
        requireGovernor(msg.sender);
        require(_newGovernor != address(0), "zero address is passed as _newGovernor");
        if (networkGovernor != _newGovernor) {
            networkGovernor = _newGovernor;
            emit NewGovernor(_newGovernor);
        }
    }

    /// @notice Change current governor
    /// @param _newTokenLister Address of the new governor
    function changeTokenLister(address _newTokenLister) external {
        requireGovernor(msg.sender);
        require(_newTokenLister != address(0), "zero address is passed as _newTokenLister");
        if (tokenLister != _newTokenLister) {
            tokenLister = _newTokenLister;
            emit NewTokenLister(_newTokenLister);
        }
    }

    /// @notice Add fee token to the list of networks tokens
    /// @param _token Token address
    function addFeeToken(address _token) external {
        requireGovernor(msg.sender);
        require(tokenIds[_token] == 0, "gan11"); // token exists
        require(totalFeeTokens < MAX_AMOUNT_OF_REGISTERED_FEE_TOKENS, "fee12"); // no free identifiers for tokens
	require(
            _token != address(0), "address cannot be zero"
        );

        totalFeeTokens++;
        uint16 newTokenId = totalFeeTokens; // it is not `totalTokens - 1` because tokenId = 0 is reserved for eth

        tokenAddresses[newTokenId] = _token;
        tokenIds[_token] = newTokenId;
        emit NewToken(_token, newTokenId);
    }

    /// @notice Add token to the list of networks tokens
    /// @param _token Token address
    function addToken(address _token) external {
        requireTokenLister(msg.sender);
        require(tokenIds[_token] == 0, "gan11"); // token exists
        require(totalUserTokens < MAX_AMOUNT_OF_REGISTERED_USER_TOKENS, "gan12"); // no free identifiers for tokens
        require(
            _token != address(0), "address cannot be zero"
        );

        uint16 newTokenId = USER_TOKENS_START_ID + totalUserTokens;
        totalUserTokens++;

        tokenAddresses[newTokenId] = _token;
        tokenIds[_token] = newTokenId;
        emit NewToken(_token, newTokenId);
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

    /// @notice Check if specified address is is governor
    /// @param _address Address to check
    function requireGovernor(address _address) public view {
        require(_address == networkGovernor, "grr11"); // only by governor
    }

    /// @notice Check if specified address can list token
    /// @param _address Address to check
    function requireTokenLister(address _address) public view {
        require(_address == networkGovernor || _address == tokenLister, "grr11"); // token lister or governor
    }

    /// @notice Checks if validator is active
    /// @param _address Validator address
    function requireActiveValidator(address _address) external view {
        require(validators[_address], "grr21"); // validator is not active
    }

    /// @notice Validate token id (must be less than or equal to total tokens amount)
    /// @param _tokenId Token id
    /// @return bool flag that indicates if token id is less than or equal to total tokens amount
    function isValidTokenId(uint16 _tokenId) external view returns (bool) {
        return (_tokenId <= totalFeeTokens) || (_tokenId >= USER_TOKENS_START_ID && _tokenId < (USER_TOKENS_START_ID + totalUserTokens  ));
    }

    /// @notice Validate token address
    /// @param _tokenAddr Token address
    /// @return tokens id
    function validateTokenAddress(address _tokenAddr) external view returns (uint16) {
        uint16 tokenId = tokenIds[_tokenAddr];
        require(tokenId != 0, "gvs11"); // 0 is not a valid token
	require(tokenId <= MAX_AMOUNT_OF_REGISTERED_TOKENS, "gvs12");
        return tokenId;
    }

    function getTokenAddress(uint16 _tokenId) external view returns (address) {
        address tokenAddr = tokenAddresses[_tokenId];
        return tokenAddr;
    }
}

pragma solidity ^0.5.0;


/// @title ZKSwap configuration constants
/// @author Matter Labs
/// @author ZKSwap L2 Labs
contract Config {

    /// @notice ERC20 token withdrawal gas limit, used only for complete withdrawals
    uint256 constant ERC20_WITHDRAWAL_GAS_LIMIT = 350000;

    /// @notice ETH token withdrawal gas limit, used only for complete withdrawals
    uint256 constant ETH_WITHDRAWAL_GAS_LIMIT = 10000;

    /// @notice Bytes in one chunk
    uint8 constant CHUNK_BYTES = 11;

    /// @notice ZKSwap address length
    uint8 constant ADDRESS_BYTES = 20;

    uint8 constant PUBKEY_HASH_BYTES = 20;

    /// @notice Public key bytes length
    uint8 constant PUBKEY_BYTES = 32;

    /// @notice Ethereum signature r/s bytes length
    uint8 constant ETH_SIGN_RS_BYTES = 32;

    /// @notice Success flag bytes length
    uint8 constant SUCCESS_FLAG_BYTES = 1;

    /// @notice Max amount of fee tokens registered in the network (excluding ETH, which is hardcoded as tokenId = 0)
    uint16 constant MAX_AMOUNT_OF_REGISTERED_FEE_TOKENS = 32 - 1;

    /// @notice start ID for user tokens
    uint16 constant USER_TOKENS_START_ID = 32;

    /// @notice Max amount of user tokens registered in the network
    uint16 constant MAX_AMOUNT_OF_REGISTERED_USER_TOKENS = 16352;

    /// @notice Max amount of tokens registered in the network
    uint16 constant MAX_AMOUNT_OF_REGISTERED_TOKENS = 16384 - 1;

    /// @notice Max account id that could be registered in the network
    uint32 constant MAX_ACCOUNT_ID = (2 ** 28) - 1;

    /// @notice Expected average period of block creation
    uint256 constant BLOCK_PERIOD = 15 seconds;

    /// @notice ETH blocks verification expectation
    /// Blocks can be reverted if they are not verified for at least EXPECT_VERIFICATION_IN.
    /// If set to 0 validator can revert blocks at any time.
    uint256 constant EXPECT_VERIFICATION_IN = 0 hours / BLOCK_PERIOD;

    uint256 constant NOOP_BYTES = 1 * CHUNK_BYTES;
    uint256 constant CREATE_PAIR_BYTES = 3 * CHUNK_BYTES;
    uint256 constant DEPOSIT_BYTES = 4 * CHUNK_BYTES;
    uint256 constant TRANSFER_TO_NEW_BYTES = 4 * CHUNK_BYTES;
    uint256 constant PARTIAL_EXIT_BYTES = 5 * CHUNK_BYTES;
    uint256 constant TRANSFER_BYTES = 2 * CHUNK_BYTES;
    uint256 constant UNISWAP_ADD_LIQ_BYTES = 3 * CHUNK_BYTES;
    uint256 constant UNISWAP_RM_LIQ_BYTES = 3 * CHUNK_BYTES;
    uint256 constant UNISWAP_SWAP_BYTES = 2 * CHUNK_BYTES;

    /// @notice Full exit operation length
    uint256 constant FULL_EXIT_BYTES = 4 * CHUNK_BYTES;

    /// @notice OnchainWithdrawal data length
    uint256 constant ONCHAIN_WITHDRAWAL_BYTES = 1 + 20 + 2 + 16; // (uint8 addToPendingWithdrawalsQueue, address _to, uint16 _tokenId, uint128 _amount)

    /// @notice ChangePubKey operation length
    uint256 constant CHANGE_PUBKEY_BYTES = 5 * CHUNK_BYTES;

    /// @notice Expiration delta for priority request to be satisfied (in seconds)
    /// NOTE: Priority expiration should be > (EXPECT_VERIFICATION_IN * BLOCK_PERIOD), otherwise incorrect block with priority op could not be reverted.
    uint256 constant PRIORITY_EXPIRATION_PERIOD = 3 days;

    /// @notice Expiration delta for priority request to be satisfied (in ETH blocks)
    uint256 constant PRIORITY_EXPIRATION = PRIORITY_EXPIRATION_PERIOD / BLOCK_PERIOD;

    /// @notice Maximum number of priority request to clear during verifying the block
    /// @dev Cause deleting storage slots cost 5k gas per each slot it's unprofitable to clear too many slots
    /// @dev Value based on the assumption of ~750k gas cost of verifying and 5 used storage slots per PriorityOperation structure
    uint64 constant MAX_PRIORITY_REQUESTS_TO_DELETE_IN_VERIFY = 6;

    /// @notice Reserved time for users to send full exit priority operation in case of an upgrade (in seconds)
    uint constant MASS_FULL_EXIT_PERIOD = 3 days;

    /// @notice Reserved time for users to withdraw funds from full exit priority operation in case of an upgrade (in seconds)
    uint constant TIME_TO_WITHDRAW_FUNDS_FROM_FULL_EXIT = 2 days;

    /// @notice Notice period before activation preparation status of upgrade mode (in seconds)
    // NOTE: we must reserve for users enough time to send full exit operation, wait maximum time for processing this operation and withdraw funds from it.
    uint constant UPGRADE_NOTICE_PERIOD = MASS_FULL_EXIT_PERIOD + PRIORITY_EXPIRATION_PERIOD + TIME_TO_WITHDRAW_FUNDS_FROM_FULL_EXIT;

    // @notice Default amount limit for each ERC20 deposit
    uint128 constant DEFAULT_MAX_DEPOSIT_AMOUNT = 2 ** 85;
}

{
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "optimizer": {
    "enabled": true,
    "runs": 200
  }
}