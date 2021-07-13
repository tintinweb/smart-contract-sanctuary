pragma solidity ^0.7.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



import "./Governance.sol";
import "./IERC20.sol";
import "./Utils.sol";

/// @title Token Governance Contract
/// @author Matter Labs
/// @notice Contract is used to allow anyone to add new ERC20 tokens to zkSync given sufficient payment
contract TokenGovernance {
    /// @notice Token lister added or removed (see `tokenLister`)
    event TokenListerUpdate(address indexed tokenLister, bool isActive);

    /// @notice Listing fee token set
    event ListingFeeTokenUpdate(IERC20 indexed newListingFeeToken);

    /// @notice Listing fee set
    event ListingFeeUpdate(uint256 newListingFee);

    /// @notice Maximum number of listed tokens updated
    event ListingCapUpdate(uint16 newListingCap);

    /// @notice The treasury (the account which will receive the fee) was updated
    event TreasuryUpdate(address newTreasury);

    /// @notice zkSync governance contract
    Governance public governance;

    /// @notice Token used to collect listing fee for addition of new token to zkSync network
    IERC20 public listingFeeToken;

    /// @notice Token listing fee
    uint256 public listingFee;

    /// @notice Max number of tokens that can be listed using this contract
    uint16 public listingCap;

    /// @notice Addresses that can list tokens without fee
    mapping(address => bool) public tokenLister;

    /// @notice Address that collects listing payments
    address public treasury;

    constructor(
        Governance _governance,
        IERC20 _listingFeeToken,
        uint256 _listingFee,
        uint16 _listingCap,
        address _treasury
    ) {
        governance = _governance;
        listingFeeToken = _listingFeeToken;
        listingFee = _listingFee;
        listingCap = _listingCap;
        treasury = _treasury;

        address governor = governance.networkGovernor();
        // We add zkSync governor as a first token lister.
        tokenLister[governor] = true;
        emit TokenListerUpdate(governor, true);
    }

    /// @notice Adds new ERC20 token to zkSync network.
    /// @notice If caller is not present in the `tokenLister` map payment of `listingFee` in `listingFeeToken` should be made.
    /// @notice NOTE: before calling this function make sure to approve `listingFeeToken` transfer for this contract.
    function addToken(address _token) external {
        require(governance.totalTokens() < listingCap, "can't add more tokens"); // Impossible to add more tokens using this contract
        if (!tokenLister[msg.sender]) {
            // Collect fees
            bool feeTransferOk = Utils.transferFromERC20(listingFeeToken, msg.sender, treasury, listingFee);
            require(feeTransferOk, "fee transfer failed"); // Failed to receive payment for token addition.
        }
        governance.addToken(_token);
    }

    /// Governance functions (this contract is governed by zkSync governor)

    /// @notice Set new listing token and fee
    /// @notice Can be called only by zkSync governor
    function setListingFeeToken(IERC20 _newListingFeeToken, uint256 _newListingFee) external {
        governance.requireGovernor(msg.sender);
        listingFeeToken = _newListingFeeToken;
        listingFee = _newListingFee;

        emit ListingFeeTokenUpdate(_newListingFeeToken);
    }

    /// @notice Set new listing fee
    /// @notice Can be called only by zkSync governor
    function setListingFee(uint256 _newListingFee) external {
        governance.requireGovernor(msg.sender);
        listingFee = _newListingFee;

        emit ListingFeeUpdate(_newListingFee);
    }

    /// @notice Enable or disable token lister. If enabled new tokens can be added by that address without payment
    /// @notice Can be called only by zkSync governor
    function setLister(address _listerAddress, bool _active) external {
        governance.requireGovernor(msg.sender);
        if (tokenLister[_listerAddress] != _active) {
            tokenLister[_listerAddress] = _active;
            emit TokenListerUpdate(_listerAddress, _active);
        }
    }

    /// @notice Change maximum amount of tokens that can be listed using this method
    /// @notice Can be called only by zkSync governor
    function setListingCap(uint16 _newListingCap) external {
        governance.requireGovernor(msg.sender);
        listingCap = _newListingCap;

        emit ListingCapUpdate(_newListingCap);
    }

    /// @notice Change address that collects payments for listing tokens.
    /// @notice Can be called only by zkSync governor
    function setTreasury(address _newTreasury) external {
        governance.requireGovernor(msg.sender);
        treasury = _newTreasury;

        emit TreasuryUpdate(_newTreasury);
    }
}

pragma solidity ^0.7.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



import "./Config.sol";
import "./Utils.sol";
import "./NFTFactory.sol";
import "./TokenGovernance.sol";

/// @title Governance Contract
/// @author Matter Labs
contract Governance is Config {
    /// @notice Token added to Franklin net
    event NewToken(address indexed token, uint16 indexed tokenId);

    /// @notice Default nft factory has set
    event SetDefaultNFTFactory(address indexed factory);

    /// @notice NFT factory registered new creator account
    event NFTFactoryRegisteredCreator(
        uint32 indexed creatorAccountId,
        address indexed creatorAddress,
        address factoryAddress
    );

    /// @notice Governor changed
    event NewGovernor(address newGovernor);

    /// @notice Token Governance changed
    event NewTokenGovernance(TokenGovernance newTokenGovernance);

    /// @notice Validator's status changed
    event ValidatorStatusUpdate(address indexed validatorAddress, bool isActive);

    event TokenPausedUpdate(address indexed token, bool paused);

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

    /// @notice Address that is authorized to add tokens to the Governance.
    TokenGovernance public tokenGovernance;

    /// @notice NFT Creator address to factory address mapping
    mapping(uint32 => mapping(address => NFTFactory)) public nftFactories;

    /// @notice Address which will be used if NFT token has no factories
    NFTFactory public defaultFactory;

    /// @notice Governance contract initialization. Can be external because Proxy contract intercepts illegal calls of this function.
    /// @param initializationParameters Encoded representation of initialization parameters:
    ///     _networkGovernor The address of network governor
    function initialize(bytes calldata initializationParameters) external {
        address _networkGovernor = abi.decode(initializationParameters, (address));

        networkGovernor = _networkGovernor;
    }

    /// @notice Governance contract upgrade. Can be external because Proxy contract intercepts illegal calls of this function.
    /// @param upgradeParameters Encoded representation of upgrade parameters
    // solhint-disable-next-line no-empty-blocks
    function upgrade(bytes calldata upgradeParameters) external {}

    /// @notice Change current governor
    /// @param _newGovernor Address of the new governor
    function changeGovernor(address _newGovernor) external {
        requireGovernor(msg.sender);
        if (networkGovernor != _newGovernor) {
            networkGovernor = _newGovernor;
            emit NewGovernor(_newGovernor);
        }
    }

    /// @notice Change current token governance
    /// @param _newTokenGovernance Address of the new token governor
    function changeTokenGovernance(TokenGovernance _newTokenGovernance) external {
        requireGovernor(msg.sender);
        if (tokenGovernance != _newTokenGovernance) {
            tokenGovernance = _newTokenGovernance;
            emit NewTokenGovernance(_newTokenGovernance);
        }
    }

    /// @notice Add token to the list of networks tokens
    /// @param _token Token address
    function addToken(address _token) external {
        require(msg.sender == address(tokenGovernance), "1E");
        require(tokenIds[_token] == 0, "1e"); // token exists
        require(totalTokens < MAX_AMOUNT_OF_REGISTERED_TOKENS, "1f"); // no free identifiers for tokens

        totalTokens++;
        uint16 newTokenId = totalTokens; // it is not `totalTokens - 1` because tokenId = 0 is reserved for eth

        tokenAddresses[newTokenId] = _token;
        tokenIds[_token] = newTokenId;
        emit NewToken(_token, newTokenId);
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

    function packRegisterNFTFactoryMsg(
        uint32 _creatorAccountId,
        address _creatorAddress,
        address _factoryAddress
    ) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n141",
                "\nCreator's account ID in zkSync: ",
                Bytes.bytesToHexASCIIBytes(abi.encodePacked((_creatorAccountId))),
                "\nCreator: ",
                Bytes.bytesToHexASCIIBytes(abi.encodePacked((_creatorAddress))),
                "\nFactory: ",
                Bytes.bytesToHexASCIIBytes(abi.encodePacked((_factoryAddress)))
            );
    }

    /// @notice Register creator corresponding to the factory
    /// @param _creatorAccountId Creator's zkSync account ID
    /// @param _creatorAddress NFT creator address
    /// @param _signature Creator's signature
    function registerNFTFactoryCreator(
        uint32 _creatorAccountId,
        address _creatorAddress,
        bytes memory _signature
    ) external {
        require(address(nftFactories[_creatorAccountId][_creatorAddress]) == address(0), "Q");
        bytes32 messageHash = keccak256(packRegisterNFTFactoryMsg(_creatorAccountId, _creatorAddress, msg.sender));

        address recoveredAddress = Utils.recoverAddressFromEthSignature(_signature, messageHash);
        require(recoveredAddress == _creatorAddress && recoveredAddress != address(0), "ws");
        nftFactories[_creatorAccountId][_creatorAddress] = NFTFactory(msg.sender);
        emit NFTFactoryRegisteredCreator(_creatorAccountId, _creatorAddress, msg.sender);
    }

    //@notice Set default factory for our contract. This factory will be used to mint an NFT token that has no factory
    //@param _factory Address of NFT factory
    function setDefaultNFTFactory(address _factory) external {
        requireGovernor(msg.sender);
        require(address(_factory) != address(0), "mb1"); // Factory should be non zero
        require(address(defaultFactory) == address(0), "mb2"); // NFTFactory is already set
        defaultFactory = NFTFactory(_factory);
        emit SetDefaultNFTFactory(_factory);
    }

    function getNFTFactory(uint32 _creatorAccountId, address _creatorAddress) external view returns (NFTFactory) {
        NFTFactory _factory = nftFactories[_creatorAccountId][_creatorAddress];
        if (address(_factory) == address(0)) {
            require(address(defaultFactory) != address(0), "fs"); // NFTFactory does not set
            return defaultFactory;
        } else {
            return _factory;
        }
    }
}

pragma solidity ^0.7.0;

// SPDX-License-Identifier: UNLICENSED


/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

pragma solidity ^0.7.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



import "./IERC20.sol";
import "./Bytes.sol";

library Utils {
    /// @notice Returns lesser of two values
    function minU32(uint32 a, uint32 b) internal pure returns (uint32) {
        return a < b ? a : b;
    }

    /// @notice Returns lesser of two values
    function minU64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    /// @notice Sends tokens
    /// @dev NOTE: this function handles tokens that have transfer function not strictly compatible with ERC20 standard
    /// @dev NOTE: call `transfer` to this token may return (bool) or nothing
    /// @param _token Token address
    /// @param _to Address of recipient
    /// @param _amount Amount of tokens to transfer
    /// @return bool flag indicating that transfer is successful
    function sendERC20(
        IERC20 _token,
        address _to,
        uint256 _amount
    ) internal returns (bool) {
        (bool callSuccess, bytes memory callReturnValueEncoded) =
            address(_token).call(abi.encodeWithSignature("transfer(address,uint256)", _to, _amount));
        // `transfer` method may return (bool) or nothing.
        bool returnedSuccess = callReturnValueEncoded.length == 0 || abi.decode(callReturnValueEncoded, (bool));
        return callSuccess && returnedSuccess;
    }

    /// @notice Transfers token from one address to another
    /// @dev NOTE: this function handles tokens that have transfer function not strictly compatible with ERC20 standard
    /// @dev NOTE: call `transferFrom` to this token may return (bool) or nothing
    /// @param _token Token address
    /// @param _from Address of sender
    /// @param _to Address of recipient
    /// @param _amount Amount of tokens to transfer
    /// @return bool flag indicating that transfer is successful
    function transferFromERC20(
        IERC20 _token,
        address _from,
        address _to,
        uint256 _amount
    ) internal returns (bool) {
        (bool callSuccess, bytes memory callReturnValueEncoded) =
            address(_token).call(abi.encodeWithSignature("transferFrom(address,address,uint256)", _from, _to, _amount));
        // `transferFrom` method may return (bool) or nothing.
        bool returnedSuccess = callReturnValueEncoded.length == 0 || abi.decode(callReturnValueEncoded, (bool));
        return callSuccess && returnedSuccess;
    }

    /// @notice Recovers signer's address from ethereum signature for given message
    /// @param _signature 65 bytes concatenated. R (32) + S (32) + V (1)
    /// @param _messageHash signed message hash.
    /// @return address of the signer
    function recoverAddressFromEthSignature(bytes memory _signature, bytes32 _messageHash)
        internal
        pure
        returns (address)
    {
        require(_signature.length == 65, "P"); // incorrect signature length

        bytes32 signR;
        bytes32 signS;
        uint8 signV;
        assembly {
            signR := mload(add(_signature, 32))
            signS := mload(add(_signature, 64))
            signV := byte(0, mload(add(_signature, 96)))
        }

        return ecrecover(_messageHash, signV, signR, signS);
    }

    /// @notice Returns new_hash = hash(old_hash + bytes)
    function concatHash(bytes32 _hash, bytes memory _bytes) internal pure returns (bytes32) {
        bytes32 result;
        assembly {
            let bytesLen := add(mload(_bytes), 32)
            mstore(_bytes, _hash)
            result := keccak256(_bytes, bytesLen)
        }
        return result;
    }

    function hashBytesToBytes20(bytes memory _bytes) internal pure returns (bytes20) {
        return bytes20(uint160(uint256(keccak256(_bytes))));
    }
}

pragma solidity ^0.7.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



/// @title zkSync configuration constants
/// @author Matter Labs
contract Config {
    /// @dev ERC20 tokens and ETH withdrawals gas limit, used only for complete withdrawals
    uint256 internal constant WITHDRAWAL_GAS_LIMIT = 100000;

    /// @dev NFT withdrawals gas limit, used only for complete withdrawals
    uint256 internal constant WITHDRAWAL_NFT_GAS_LIMIT = 300000;

    /// @dev Bytes in one chunk
    uint8 internal constant CHUNK_BYTES = 10;

    /// @dev zkSync address length
    uint8 internal constant ADDRESS_BYTES = 20;

    uint8 internal constant PUBKEY_HASH_BYTES = 20;

    /// @dev Public key bytes length
    uint8 internal constant PUBKEY_BYTES = 32;

    /// @dev Ethereum signature r/s bytes length
    uint8 internal constant ETH_SIGN_RS_BYTES = 32;

    /// @dev Success flag bytes length
    uint8 internal constant SUCCESS_FLAG_BYTES = 1;

    /// @dev Max amount of tokens registered in the network (excluding ETH, which is hardcoded as tokenId = 0)
    uint16 internal constant MAX_AMOUNT_OF_REGISTERED_TOKENS = 1023;

    /// @dev Max account id that could be registered in the network
    uint32 internal constant MAX_ACCOUNT_ID = 16777215;

    /// @dev Expected average period of block creation
    uint256 internal constant BLOCK_PERIOD = 15 seconds;

    /// @dev ETH blocks verification expectation
    /// @dev Blocks can be reverted if they are not verified for at least EXPECT_VERIFICATION_IN.
    /// @dev If set to 0 validator can revert blocks at any time.
    uint256 internal constant EXPECT_VERIFICATION_IN = 0 hours / BLOCK_PERIOD;

    uint256 internal constant NOOP_BYTES = 1 * CHUNK_BYTES;
    uint256 internal constant DEPOSIT_BYTES = 6 * CHUNK_BYTES;
    uint256 internal constant MINT_NFT_BYTES = 5 * CHUNK_BYTES;
    uint256 internal constant TRANSFER_TO_NEW_BYTES = 6 * CHUNK_BYTES;
    uint256 internal constant PARTIAL_EXIT_BYTES = 6 * CHUNK_BYTES;
    uint256 internal constant TRANSFER_BYTES = 2 * CHUNK_BYTES;
    uint256 internal constant FORCED_EXIT_BYTES = 6 * CHUNK_BYTES;
    uint256 internal constant WITHDRAW_NFT_BYTES = 10 * CHUNK_BYTES;

    /// @dev Full exit operation length
    uint256 internal constant FULL_EXIT_BYTES = 11 * CHUNK_BYTES;

    /// @dev ChangePubKey operation length
    uint256 internal constant CHANGE_PUBKEY_BYTES = 6 * CHUNK_BYTES;

    /// @dev Expiration delta for priority request to be satisfied (in seconds)
    /// @dev NOTE: Priority expiration should be > (EXPECT_VERIFICATION_IN * BLOCK_PERIOD)
    /// @dev otherwise incorrect block with priority op could not be reverted.
    uint256 internal constant PRIORITY_EXPIRATION_PERIOD = 3 days;

    /// @dev Expiration delta for priority request to be satisfied (in ETH blocks)
    uint256 internal constant PRIORITY_EXPIRATION =
        PRIORITY_EXPIRATION_PERIOD/BLOCK_PERIOD;

    /// @dev Maximum number of priority request to clear during verifying the block
    /// @dev Cause deleting storage slots cost 5k gas per each slot it's unprofitable to clear too many slots
    /// @dev Value based on the assumption of ~750k gas cost of verifying and 5 used storage slots per PriorityOperation structure
    uint64 internal constant MAX_PRIORITY_REQUESTS_TO_DELETE_IN_VERIFY = 6;

    /// @dev Reserved time for users to send full exit priority operation in case of an upgrade (in seconds)
    uint256 internal constant MASS_FULL_EXIT_PERIOD = 9 days;

    /// @dev Reserved time for users to withdraw funds from full exit priority operation in case of an upgrade (in seconds)
    uint256 internal constant TIME_TO_WITHDRAW_FUNDS_FROM_FULL_EXIT = 2 days;

    /// @dev Notice period before activation preparation status of upgrade mode (in seconds)
    /// @dev NOTE: we must reserve for users enough time to send full exit operation, wait maximum time for processing this operation and withdraw funds from it.
    uint256 internal constant UPGRADE_NOTICE_PERIOD =
        MASS_FULL_EXIT_PERIOD+PRIORITY_EXPIRATION_PERIOD+TIME_TO_WITHDRAW_FUNDS_FROM_FULL_EXIT;

    /// @dev Timestamp - seconds since unix epoch
    uint256 internal constant COMMIT_TIMESTAMP_NOT_OLDER = 24 hours;

    /// @dev Maximum available error between real commit block timestamp and analog used in the verifier (in seconds)
    /// @dev Must be used cause miner's `block.timestamp` value can differ on some small value (as we know - 15 seconds)
    uint256 internal constant COMMIT_TIMESTAMP_APPROXIMATION_DELTA = 15 minutes;

    /// @dev Bit mask to apply for verifier public input before verifying.
    uint256 internal constant INPUT_MASK = 14474011154664524427946373126085988481658748083205070504932198000989141204991;

    /// @dev Auth fact reset timelock.
    uint256 internal constant AUTH_FACT_RESET_TIMELOCK = 1 days;

    /// @dev Max deposit of ERC20 token that is possible to deposit
    uint128 internal constant MAX_DEPOSIT_AMOUNT = 20282409603651670423947251286015;

    uint32 internal constant SPECIAL_ACCOUNT_ID = 16777215;
    address internal constant SPECIAL_ACCOUNT_ADDRESS = address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF);
    uint32 internal constant SPECIAL_NFT_TOKEN_ID = 2147483646;

    uint32 internal constant MAX_FUNGIBLE_TOKEN_ID = 65535;

    uint256 internal constant SECURITY_COUNCIL_MEMBERS_NUMBER = 15;
}

pragma solidity ^0.7.0;

// SPDX-License-Identifier: UNLICENSED


interface NFTFactory {
    function mintNFTFromZkSync(
        address creator,
        address recipient,
        uint32 creatorAccountId,
        uint32 serialId,
        bytes32 contentHash,
        // Even though the token id can fit into the uint32, we still use
        // the uint256 to preserve consistency with the ERC721 parent contract
        uint256 tokenId
    ) external;

    event MintNFTFromZkSync(
        address indexed creator,
        address indexed recipient,
        uint32 creatorAccountId,
        uint32 serialId,
        bytes32 contentHash,
        uint256 tokenId
    );
}

pragma solidity ^0.7.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



// Functions named bytesToX, except bytesToBytes20, where X is some type of size N < 32 (size of one word)
// implements the following algorithm:
// f(bytes memory input, uint offset) -> X out
// where byte representation of out is N bytes from input at the given offset
// 1) We compute memory location of the word W such that last N bytes of W is input[offset..offset+N]
// W_address = input + 32 (skip stored length of bytes) + offset - (32 - N) == input + offset + N
// 2) We load W from memory into out, last N bytes of W are placed into out

library Bytes {
    function toBytesFromUInt16(uint16 self) internal pure returns (bytes memory _bts) {
        return toBytesFromUIntTruncated(uint256(self), 2);
    }

    function toBytesFromUInt24(uint24 self) internal pure returns (bytes memory _bts) {
        return toBytesFromUIntTruncated(uint256(self), 3);
    }

    function toBytesFromUInt32(uint32 self) internal pure returns (bytes memory _bts) {
        return toBytesFromUIntTruncated(uint256(self), 4);
    }

    function toBytesFromUInt128(uint128 self) internal pure returns (bytes memory _bts) {
        return toBytesFromUIntTruncated(uint256(self), 16);
    }

    // Copies 'len' lower bytes from 'self' into a new 'bytes memory'.
    // Returns the newly created 'bytes memory'. The returned bytes will be of length 'len'.
    function toBytesFromUIntTruncated(uint256 self, uint8 byteLength) private pure returns (bytes memory bts) {
        require(byteLength <= 32, "Q");
        bts = new bytes(byteLength);
        // Even though the bytes will allocate a full word, we don't want
        // any potential garbage bytes in there.
        uint256 data = self << ((32 - byteLength) * 8);
        assembly {
            mstore(
                add(bts, 32), // BYTES_HEADER_SIZE
                data
            )
        }
    }

    // Copies 'self' into a new 'bytes memory'.
    // Returns the newly created 'bytes memory'. The returned bytes will be of length '20'.
    function toBytesFromAddress(address self) internal pure returns (bytes memory bts) {
        bts = toBytesFromUIntTruncated(uint256(self), 20);
    }

    // See comment at the top of this file for explanation of how this function works.
    // NOTE: theoretically possible overflow of (_start + 20)
    function bytesToAddress(bytes memory self, uint256 _start) internal pure returns (address addr) {
        uint256 offset = _start + 20;
        require(self.length >= offset, "R");
        assembly {
            addr := mload(add(self, offset))
        }
    }

    // Reasoning about why this function works is similar to that of other similar functions, except NOTE below.
    // NOTE: that bytes1..32 is stored in the beginning of the word unlike other primitive types
    // NOTE: theoretically possible overflow of (_start + 20)
    function bytesToBytes20(bytes memory self, uint256 _start) internal pure returns (bytes20 r) {
        require(self.length >= (_start + 20), "S");
        assembly {
            r := mload(add(add(self, 0x20), _start))
        }
    }

    // See comment at the top of this file for explanation of how this function works.
    // NOTE: theoretically possible overflow of (_start + 0x2)
    function bytesToUInt16(bytes memory _bytes, uint256 _start) internal pure returns (uint16 r) {
        uint256 offset = _start + 0x2;
        require(_bytes.length >= offset, "T");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // See comment at the top of this file for explanation of how this function works.
    // NOTE: theoretically possible overflow of (_start + 0x3)
    function bytesToUInt24(bytes memory _bytes, uint256 _start) internal pure returns (uint24 r) {
        uint256 offset = _start + 0x3;
        require(_bytes.length >= offset, "U");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // NOTE: theoretically possible overflow of (_start + 0x4)
    function bytesToUInt32(bytes memory _bytes, uint256 _start) internal pure returns (uint32 r) {
        uint256 offset = _start + 0x4;
        require(_bytes.length >= offset, "V");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // NOTE: theoretically possible overflow of (_start + 0x10)
    function bytesToUInt128(bytes memory _bytes, uint256 _start) internal pure returns (uint128 r) {
        uint256 offset = _start + 0x10;
        require(_bytes.length >= offset, "W");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // See comment at the top of this file for explanation of how this function works.
    // NOTE: theoretically possible overflow of (_start + 0x14)
    function bytesToUInt160(bytes memory _bytes, uint256 _start) internal pure returns (uint160 r) {
        uint256 offset = _start + 0x14;
        require(_bytes.length >= offset, "X");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // NOTE: theoretically possible overflow of (_start + 0x20)
    function bytesToBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32 r) {
        uint256 offset = _start + 0x20;
        require(_bytes.length >= offset, "Y");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // Original source code: https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol#L228
    // Get slice from bytes arrays
    // Returns the newly created 'bytes memory'
    // NOTE: theoretically possible overflow of (_start + _length)
    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_bytes.length >= (_start + _length), "Z"); // bytes length is less then start byte + length bytes

        bytes memory tempBytes = new bytes(_length);

        if (_length != 0) {
            assembly {
                let slice_curr := add(tempBytes, 0x20)
                let slice_end := add(slice_curr, _length)

                for {
                    let array_current := add(_bytes, add(_start, 0x20))
                } lt(slice_curr, slice_end) {
                    slice_curr := add(slice_curr, 0x20)
                    array_current := add(array_current, 0x20)
                } {
                    mstore(slice_curr, mload(array_current))
                }
            }
        }

        return tempBytes;
    }

    /// Reads byte stream
    /// @return newOffset - offset + amount of bytes read
    /// @return data - actually read data
    // NOTE: theoretically possible overflow of (_offset + _length)
    function read(
        bytes memory _data,
        uint256 _offset,
        uint256 _length
    ) internal pure returns (uint256 newOffset, bytes memory data) {
        data = slice(_data, _offset, _length);
        newOffset = _offset + _length;
    }

    // NOTE: theoretically possible overflow of (_offset + 1)
    function readBool(bytes memory _data, uint256 _offset) internal pure returns (uint256 newOffset, bool r) {
        newOffset = _offset + 1;
        r = uint8(_data[_offset]) != 0;
    }

    // NOTE: theoretically possible overflow of (_offset + 1)
    function readUint8(bytes memory _data, uint256 _offset) internal pure returns (uint256 newOffset, uint8 r) {
        newOffset = _offset + 1;
        r = uint8(_data[_offset]);
    }

    // NOTE: theoretically possible overflow of (_offset + 2)
    function readUInt16(bytes memory _data, uint256 _offset) internal pure returns (uint256 newOffset, uint16 r) {
        newOffset = _offset + 2;
        r = bytesToUInt16(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 3)
    function readUInt24(bytes memory _data, uint256 _offset) internal pure returns (uint256 newOffset, uint24 r) {
        newOffset = _offset + 3;
        r = bytesToUInt24(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 4)
    function readUInt32(bytes memory _data, uint256 _offset) internal pure returns (uint256 newOffset, uint32 r) {
        newOffset = _offset + 4;
        r = bytesToUInt32(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 16)
    function readUInt128(bytes memory _data, uint256 _offset) internal pure returns (uint256 newOffset, uint128 r) {
        newOffset = _offset + 16;
        r = bytesToUInt128(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 20)
    function readUInt160(bytes memory _data, uint256 _offset) internal pure returns (uint256 newOffset, uint160 r) {
        newOffset = _offset + 20;
        r = bytesToUInt160(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 20)
    function readAddress(bytes memory _data, uint256 _offset) internal pure returns (uint256 newOffset, address r) {
        newOffset = _offset + 20;
        r = bytesToAddress(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 20)
    function readBytes20(bytes memory _data, uint256 _offset) internal pure returns (uint256 newOffset, bytes20 r) {
        newOffset = _offset + 20;
        r = bytesToBytes20(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 32)
    function readBytes32(bytes memory _data, uint256 _offset) internal pure returns (uint256 newOffset, bytes32 r) {
        newOffset = _offset + 32;
        r = bytesToBytes32(_data, _offset);
    }

    /// Trim bytes into single word
    function trim(bytes memory _data, uint256 _newLength) internal pure returns (uint256 r) {
        require(_newLength <= 0x20, "10"); // new_length is longer than word
        require(_data.length >= _newLength, "11"); // data is to short

        uint256 a;
        assembly {
            a := mload(add(_data, 0x20)) // load bytes into uint256
        }

        return a >> ((0x20 - _newLength) * 8);
    }

    // Helper function for hex conversion.
    function halfByteToHex(bytes1 _byte) internal pure returns (bytes1 _hexByte) {
        require(uint8(_byte) < 0x10, "hbh11"); // half byte's value is out of 0..15 range.

        // "FEDCBA9876543210" ASCII-encoded, shifted and automatically truncated.
        return bytes1(uint8(0x66656463626139383736353433323130 >> (uint8(_byte) * 8)));
    }

    // Convert bytes to ASCII hex representation
    function bytesToHexASCIIBytes(bytes memory _input) internal pure returns (bytes memory _output) {
        bytes memory outStringBytes = new bytes(_input.length * 2);

        // code in `assembly` construction is equivalent of the next code:
        // for (uint i = 0; i < _input.length; ++i) {
        //     outStringBytes[i*2] = halfByteToHex(_input[i] >> 4);
        //     outStringBytes[i*2+1] = halfByteToHex(_input[i] & 0x0f);
        // }
        assembly {
            let input_curr := add(_input, 0x20)
            let input_end := add(input_curr, mload(_input))

            for {
                let out_curr := add(outStringBytes, 0x20)
            } lt(input_curr, input_end) {
                input_curr := add(input_curr, 0x01)
                out_curr := add(out_curr, 0x02)
            } {
                let curr_input_byte := shr(0xf8, mload(input_curr))
                // here outStringByte from each half of input byte calculates by the next:
                //
                // "FEDCBA9876543210" ASCII-encoded, shifted and automatically truncated.
                // outStringByte = byte (uint8 (0x66656463626139383736353433323130 >> (uint8 (_byteHalf) * 8)))
                mstore(
                    out_curr,
                    shl(0xf8, shr(mul(shr(0x04, curr_input_byte), 0x08), 0x66656463626139383736353433323130))
                )
                mstore(
                    add(out_curr, 0x01),
                    shl(0xf8, shr(mul(and(0x0f, curr_input_byte), 0x08), 0x66656463626139383736353433323130))
                )
            }
        }
        return outStringBytes;
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}