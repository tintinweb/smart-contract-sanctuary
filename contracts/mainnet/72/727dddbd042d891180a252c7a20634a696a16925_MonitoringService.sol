/**
 *Submitted for verification at Etherscan.io on 2020-05-19
*/

pragma solidity 0.6.4;


library ECVerify {

    function ecverify(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address signature_address)
    {
        require(signature.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        // The signature format is a compact form of:
        //   {bytes32 r}{bytes32 s}{uint8 v}
        // Compact means, uint8 is not padded to 32 bytes.
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))

            // Here we are loading the last 32 bytes, including 31 bytes following the signature.
            v := byte(0, mload(add(signature, 96)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible
        if (v < 27) {
            v += 27;
        }

        require(v == 27 || v == 28);

        signature_address = ecrecover(hash, v, r, s);

        // ecrecover returns zero on error
        require(signature_address != address(0x0));

        return signature_address;
    }
}

interface Token {

    /// @return supply total amount of tokens
    function totalSupply() external view returns (uint256 supply);

    /// @param _owner The address from which the balance will be retrieved
    /// @return balance The balance
    function balanceOf(address _owner) external view returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return success Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) external returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return success Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return success Whether the approval was successful or not
    function approve(address _spender, uint256 _value) external returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return remaining Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // Optionally implemented function to show the number of decimals for the token
    function decimals() external view returns (uint8 decimals);
}

/// @title Utils
/// @notice Utils contract for various helpers used by the Raiden Network smart
/// contracts.
contract Utils {
    enum MessageTypeId {
        None,
        BalanceProof,
        BalanceProofUpdate,
        Withdraw,
        CooperativeSettle,
        IOU,
        MSReward
    }

    /// @notice Check if a contract exists
    /// @param contract_address The address to check whether a contract is
    /// deployed or not
    /// @return True if a contract exists, false otherwise
    function contractExists(address contract_address) public view returns (bool) {
        uint size;

        assembly {
            size := extcodesize(contract_address)
        }

        return size > 0;
    }
}


/// @title SecretRegistry
/// @notice SecretRegistry contract for registering secrets from Raiden Network
/// clients.
contract SecretRegistry {
    // sha256(secret) => block number at which the secret was revealed
    mapping(bytes32 => uint256) private secrethash_to_block;

    event SecretRevealed(bytes32 indexed secrethash, bytes32 secret);

    /// @notice Registers a hash time lock secret and saves the block number.
    /// This allows the lock to be unlocked after the expiration block
    /// @param secret The secret used to lock the hash time lock
    /// @return true if secret was registered, false if the secret was already
    /// registered
    function registerSecret(bytes32 secret) public returns (bool) {
        bytes32 secrethash = sha256(abi.encodePacked(secret));
        if (secrethash_to_block[secrethash] > 0) {
            return false;
        }
        secrethash_to_block[secrethash] = block.number;
        emit SecretRevealed(secrethash, secret);
        return true;
    }

    /// @notice Registers multiple hash time lock secrets and saves the block
    /// number
    /// @param secrets The array of secrets to be registered
    /// @return true if all secrets could be registered, false otherwise
    function registerSecretBatch(bytes32[] memory secrets) public returns (bool) {
        bool completeSuccess = true;
        for(uint i = 0; i < secrets.length; i++) {
            if(!registerSecret(secrets[i])) {
                completeSuccess = false;
            }
        }
        return completeSuccess;
    }

    /// @notice Get the stored block number at which the secret was revealed
    /// @param secrethash The hash of the registered secret `keccak256(secret)`
    /// @return The block number at which the secret was revealed
    function getSecretRevealBlockHeight(bytes32 secrethash) public view returns (uint256) {
        return secrethash_to_block[secrethash];
    }
}

// MIT License

// Copyright (c) 2018

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

/// @title TokenNetwork
/// @notice Stores and manages all the Raiden Network channels that use the
/// token specified
/// in this TokenNetwork contract.
contract TokenNetwork is Utils {
    // Instance of the token used by the channels
    Token public token;

    // Instance of SecretRegistry used for storing secrets revealed in a
    // mediating transfer.
    SecretRegistry public secret_registry;

    // Chain ID as specified by EIP155 used in balance proof signatures to
    // avoid replay attacks
    uint256 public chain_id;

    uint256 public settlement_timeout_min;
    uint256 public settlement_timeout_max;

    uint256 constant public MAX_SAFE_UINT256 = (
        115792089237316195423570985008687907853269984665640564039457584007913129639935
    );

    // The deposit limit per channel per participant.
    uint256 public channel_participant_deposit_limit;
    // The total combined deposit of all channels across the whole network
    uint256 public token_network_deposit_limit;

    // Global, monotonically increasing counter that keeps track of all the
    // opened channels in this contract
    uint256 public channel_counter;

    string public constant signature_prefix = '\x19Ethereum Signed Message:\n';

    // Only for the limited Red Eyes release
    address public deprecation_executor;
    bool public safety_deprecation_switch = false;

    // channel_identifier => Channel
    // channel identifier is the channel_counter value at the time of opening
    // the channel
    mapping (uint256 => Channel) public channels;

    // This is needed to enforce one channel per pair of participants
    // The key is keccak256(participant1_address, participant2_address)
    mapping (bytes32 => uint256) public participants_hash_to_channel_identifier;

    // We keep the unlock data in a separate mapping to allow channel data
    // structures to be removed when settling uncooperatively. If there are
    // locked pending transfers, we need to store data needed to unlock them at
    // a later time.
    // The key is `keccak256(uint256 channel_identifier, address participant,
    // address partner)` Where `participant` is the participant that sent the
    // pending transfers We need `partner` for knowing where to send the
    // claimable tokens
    mapping(bytes32 => UnlockData) private unlock_identifier_to_unlock_data;

    struct Participant {
        // Total amount of tokens transferred to this smart contract through
        // the `setTotalDeposit` function, for a specific channel, in the
        // participant's benefit.
        // This is a strictly monotonic value. Note that direct token transfer
        // into the contract cannot be tracked and will be stuck.
        uint256 deposit;

        // Total amount of tokens withdrawn by the participant during the
        // lifecycle of this channel.
        // This is a strictly monotonic value.
        uint256 withdrawn_amount;

        // This is a value set to true after the channel has been closed, only
        // if this is the participant who closed the channel.
        bool is_the_closer;

        // keccak256 of the balance data provided after a closeChannel or an
        // updateNonClosingBalanceProof call
        bytes32 balance_hash;

        // Monotonically increasing counter of the off-chain transfers,
        // provided along with the balance_hash
        uint256 nonce;
    }

    enum ChannelState {
        NonExistent, // 0
        Opened,      // 1
        Closed,      // 2
        Settled,     // 3; Note: The channel has at least one pending unlock
        Removed      // 4; Note: Channel data is removed, there are no pending unlocks
    }

    struct Channel {
        // After opening the channel this value represents the settlement
        // window. This is the number of blocks that need to be mined between
        // closing the channel uncooperatively and settling the channel.
        // After the channel has been uncooperatively closed, this value
        // represents the block number after which settleChannel can be called.
        uint256 settle_block_number;

        ChannelState state;

        mapping(address => Participant) participants;
    }

    struct SettlementData {
        uint256 deposit;
        uint256 withdrawn;
        uint256 transferred;
        uint256 locked;
    }

    struct UnlockData {
        // keccak256 hash of the pending locks from the Raiden client
        bytes32 locksroot;
        // Total amount of tokens locked in the pending locks corresponding
        // to the `locksroot`
        uint256 locked_amount;
    }

    event ChannelOpened(
        uint256 indexed channel_identifier,
        address indexed participant1,
        address indexed participant2,
        uint256 settle_timeout
    );

    event ChannelNewDeposit(
        uint256 indexed channel_identifier,
        address indexed participant,
        uint256 total_deposit
    );

    // Fires when the deprecation_switch's value changes
    event DeprecationSwitch(bool new_value);

    // total_withdraw is how much the participant has withdrawn during the
    // lifetime of the channel. The actual amount which the participant withdrew
    // is `total_withdraw - total_withdraw_from_previous_event_or_zero`
    event ChannelWithdraw(
        uint256 indexed channel_identifier,
        address indexed participant,
        uint256 total_withdraw
    );

    event ChannelClosed(
        uint256 indexed channel_identifier,
        address indexed closing_participant,
        uint256 indexed nonce,
        bytes32 balance_hash
    );

    event ChannelUnlocked(
        uint256 indexed channel_identifier,
        address indexed receiver,
        address indexed sender,
        bytes32 locksroot,
        uint256 unlocked_amount,
        uint256 returned_tokens
    );

    event NonClosingBalanceProofUpdated(
        uint256 indexed channel_identifier,
        address indexed closing_participant,
        uint256 indexed nonce,
        bytes32 balance_hash
    );

    event ChannelSettled(
        uint256 indexed channel_identifier,
        uint256 participant1_amount,
        bytes32 participant1_locksroot,
        uint256 participant2_amount,
        bytes32 participant2_locksroot
    );

    modifier onlyDeprecationExecutor() {
        require(msg.sender == deprecation_executor);
        _;
    }

    modifier isSafe() {
        require(safety_deprecation_switch == false);
        _;
    }

    modifier isOpen(uint256 channel_identifier) {
        require(channels[channel_identifier].state == ChannelState.Opened);
        _;
    }

    modifier settleTimeoutValid(uint256 timeout) {
        require(timeout >= settlement_timeout_min);
        require(timeout <= settlement_timeout_max);
        _;
    }

    /// @param _token_address The address of the ERC20 token contract
    /// @param _secret_registry The address of SecretRegistry contract that witnesses the onchain secret reveals
    /// @param _chain_id EIP-155 Chain ID of the blockchain where this instance is being deployed
    /// @param _settlement_timeout_min The shortest settlement period (in number of blocks)
    /// that can be chosen at the channel opening
    /// @param _settlement_timeout_max The longest settlement period (in number of blocks)
    /// that can be chosen at the channel opening
    /// @param _deprecation_executor The Ethereum address that can disable new deposits and channel creation
    /// @param _channel_participant_deposit_limit The maximum amount of tokens that can be deposited by each
    /// participant of each channel. MAX_SAFE_UINT256 means no limits
    /// @param _token_network_deposit_limit The maximum amount of tokens that this contract can hold
    /// MAX_SAFE_UINT256 means no limits
    constructor(
        address _token_address,
        address _secret_registry,
        uint256 _chain_id,
        uint256 _settlement_timeout_min,
        uint256 _settlement_timeout_max,
        address _deprecation_executor,
        uint256 _channel_participant_deposit_limit,
        uint256 _token_network_deposit_limit
    )
        public
    {
        require(_token_address != address(0x0));
        require(_secret_registry != address(0x0));
        require(_deprecation_executor != address(0x0));
        require(_chain_id > 0);
        require(_settlement_timeout_min > 0);
        require(_settlement_timeout_max > _settlement_timeout_min);
        require(contractExists(_token_address));
        require(contractExists(_secret_registry));
        require(_channel_participant_deposit_limit > 0);
        require(_token_network_deposit_limit > 0);
        require(_token_network_deposit_limit >= _channel_participant_deposit_limit);

        token = Token(_token_address);

        secret_registry = SecretRegistry(_secret_registry);
        chain_id = _chain_id;
        settlement_timeout_min = _settlement_timeout_min;
        settlement_timeout_max = _settlement_timeout_max;

        // Make sure the contract is indeed a token contract
        require(token.totalSupply() > 0);

        deprecation_executor = _deprecation_executor;
        channel_participant_deposit_limit = _channel_participant_deposit_limit;
        token_network_deposit_limit = _token_network_deposit_limit;
    }

    function deprecate() public isSafe onlyDeprecationExecutor {
        safety_deprecation_switch = true;
        emit DeprecationSwitch(safety_deprecation_switch);
    }

    /// @notice Opens a new channel between `participant1` and `participant2`.
    /// Can be called by anyone
    /// @param participant1 Ethereum address of a channel participant
    /// @param participant2 Ethereum address of the other channel participant
    /// @param settle_timeout Number of blocks that need to be mined between a
    /// call to closeChannel and settleChannel
    function openChannel(address participant1, address participant2, uint256 settle_timeout)
        public
        isSafe
        settleTimeoutValid(settle_timeout)
        returns (uint256)
    {
        bytes32 pair_hash;
        uint256 channel_identifier;

        // Red Eyes release token network limit
        require(token.balanceOf(address(this)) < token_network_deposit_limit);

        // First increment the counter
        // There will never be a channel with channel_identifier == 0
        channel_counter += 1;
        channel_identifier = channel_counter;

        pair_hash = getParticipantsHash(participant1, participant2);

        // There must only be one channel opened between two participants at
        // any moment in time.
        require(participants_hash_to_channel_identifier[pair_hash] == 0);
        participants_hash_to_channel_identifier[pair_hash] = channel_identifier;

        Channel storage channel = channels[channel_identifier];

        // We always increase the channel counter, therefore no channel data can already exist,
        // corresponding to this channel_identifier. This check must never fail.
        assert(channel.settle_block_number == 0);
        assert(channel.state == ChannelState.NonExistent);

        // Store channel information
        channel.settle_block_number = settle_timeout;
        channel.state = ChannelState.Opened;

        emit ChannelOpened(
            channel_identifier,
            participant1,
            participant2,
            settle_timeout
        );

        return channel_identifier;
    }

    /// @notice Sets the channel participant total deposit value.
    /// Can be called by anyone.
    /// @param channel_identifier Identifier for the channel on which this
    /// operation takes place
    /// @param participant Channel participant whose deposit is being set
    /// @param total_deposit The total amount of tokens that the participant
    /// will have as a deposit
    /// @param partner Channel partner address, needed to compute the total
    /// channel deposit
    function setTotalDeposit(
        uint256 channel_identifier,
        address participant,
        uint256 total_deposit,
        address partner
    )
        public
        isSafe
        isOpen(channel_identifier)
    {
        require(channel_identifier == getChannelIdentifier(participant, partner));
        require(total_deposit > 0);
        require(total_deposit <= channel_participant_deposit_limit);

        uint256 added_deposit;
        uint256 channel_deposit;

        Channel storage channel = channels[channel_identifier];
        Participant storage participant_state = channel.participants[participant];
        Participant storage partner_state = channel.participants[partner];

        // Calculate the actual amount of tokens that will be transferred
        added_deposit = total_deposit - participant_state.deposit;

        // The actual amount of tokens that will be transferred must be > 0
        require(added_deposit > 0);

        // Underflow check; we use <= because added_deposit == total_deposit for the first deposit

        require(added_deposit <= total_deposit);

        // This should never fail at this point. Added check for security, because we directly set
        // the participant_state.deposit = total_deposit, while we transfer `added_deposit` tokens
        assert(participant_state.deposit + added_deposit == total_deposit);

        // Red Eyes release token network limit
        require(token.balanceOf(address(this)) + added_deposit <= token_network_deposit_limit);

        // Update the participant's channel deposit
        participant_state.deposit = total_deposit;

        // Calculate the entire channel deposit, to avoid overflow
        channel_deposit = participant_state.deposit + partner_state.deposit;
        // Overflow check
        require(channel_deposit >= participant_state.deposit);

        emit ChannelNewDeposit(
            channel_identifier,
            participant,
            participant_state.deposit
        );

        // Do the transfer
        require(token.transferFrom(msg.sender, address(this), added_deposit));
    }

    /// @notice Allows `participant` to withdraw tokens from the channel that he
    /// has with `partner`, without closing it. Can be called by anyone. Can
    /// only be called once per each signed withdraw message
    /// @param channel_identifier Identifier for the channel on which this
    /// operation takes place
    /// @param participant Channel participant, who will receive the withdrawn
    /// amount
    /// @param total_withdraw Total amount of tokens that are marked as
    /// withdrawn from the channel during the channel lifecycle
    /// @param participant_signature Participant's signature on the withdraw
    /// data
    /// @param partner_signature Partner's signature on the withdraw data
    function setTotalWithdraw(
        uint256 channel_identifier,
        address participant,
        uint256 total_withdraw,
        uint256 expiration_block,
        bytes calldata participant_signature,
        bytes calldata partner_signature
    )
        external
        isOpen(channel_identifier)
    {
        uint256 total_deposit;
        uint256 current_withdraw;
        address partner;

        require(total_withdraw > 0);
        require(block.number < expiration_block);

        // Authenticate both channel partners via their signatures.
        // `participant` is a part of the signed message, so given in the calldata.
        require(participant == recoverAddressFromWithdrawMessage(
            channel_identifier,
            participant,
            total_withdraw,
            expiration_block,
            participant_signature
        ));
        partner = recoverAddressFromWithdrawMessage(
            channel_identifier,
            participant,
            total_withdraw,
            expiration_block,
            partner_signature
        );

        // Validate that authenticated partners and the channel identifier match
        require(channel_identifier == getChannelIdentifier(participant, partner));

        // Read channel state after validating the function input
        Channel storage channel = channels[channel_identifier];
        Participant storage participant_state = channel.participants[participant];
        Participant storage partner_state = channel.participants[partner];

        total_deposit = participant_state.deposit + partner_state.deposit;

        // Entire withdrawn amount must not be bigger than the current channel deposit
        require((total_withdraw + partner_state.withdrawn_amount) <= total_deposit);
        require(total_withdraw <= (total_withdraw + partner_state.withdrawn_amount));

        // Using the total_withdraw (monotonically increasing) in the signed
        // message ensures that we do not allow replay attack to happen, by
        // using the same withdraw proof twice.
        // Next two lines enforce the monotonicity of total_withdraw and check for an underflow:
        // (we use <= because current_withdraw == total_withdraw for the first withdraw)
        current_withdraw = total_withdraw - participant_state.withdrawn_amount;
        require(current_withdraw <= total_withdraw);

        // The actual amount of tokens that will be transferred must be > 0 to disable the reuse of
        // withdraw messages completely.
        require(current_withdraw > 0);

        // This should never fail at this point. Added check for security, because we directly set
        // the participant_state.withdrawn_amount = total_withdraw,
        // while we transfer `current_withdraw` tokens.
        assert(participant_state.withdrawn_amount + current_withdraw == total_withdraw);

        emit ChannelWithdraw(
            channel_identifier,
            participant,
            total_withdraw
        );

        // Do the state change and tokens transfer
        participant_state.withdrawn_amount = total_withdraw;
        require(token.transfer(participant, current_withdraw));

        // This should never happen, as we have an overflow check in setTotalDeposit
        assert(total_deposit >= participant_state.deposit);
        assert(total_deposit >= partner_state.deposit);

        // A withdraw should never happen if a participant already has a
        // balance proof in storage. This should never fail as we use isOpen.
        assert(participant_state.nonce == 0);
        assert(partner_state.nonce == 0);

    }

    /// @notice Close the channel defined by the two participant addresses.
    /// Anybody can call this function on behalf of a participant (called
    /// the closing participant), providing a balance proof signed by
    /// both parties. Callable only once
    /// @param channel_identifier Identifier for the channel on which this
    /// operation takes place
    /// @param closing_participant Channel participant who closes the channel
    /// @param non_closing_participant Channel partner of the `closing_participant`,
    /// who provided the balance proof
    /// @param balance_hash Hash of (transferred_amount, locked_amount,
    /// locksroot)
    /// @param additional_hash Computed from the message. Used for message
    /// authentication
    /// @param nonce Strictly monotonic value used to order transfers
    /// @param non_closing_signature Non-closing participant's signature of the balance proof data
    /// @param closing_signature Closing participant's signature of the balance
    /// proof data
    function closeChannel(
        uint256 channel_identifier,
        address non_closing_participant,
        address closing_participant,
        // The next four arguments form a balance proof.
        bytes32 balance_hash,
        uint256 nonce,
        bytes32 additional_hash,
        bytes memory non_closing_signature,
        bytes memory closing_signature
    )
        public
        isOpen(channel_identifier)
    {
        require(channel_identifier == getChannelIdentifier(closing_participant, non_closing_participant));

        address recovered_non_closing_participant_address;

        Channel storage channel = channels[channel_identifier];

        channel.state = ChannelState.Closed;
        channel.participants[closing_participant].is_the_closer = true;

        // This is the block number at which the channel can be settled.
        channel.settle_block_number += uint256(block.number);

        // The closing participant must have signed the balance proof.
        address recovered_closing_participant_address = recoverAddressFromBalanceProofCounterSignature(
            MessageTypeId.BalanceProof,
            channel_identifier,
            balance_hash,
            nonce,
            additional_hash,
            non_closing_signature,
            closing_signature
        );
        require(closing_participant == recovered_closing_participant_address);

        // Nonce 0 means that the closer never received a transfer, therefore
        // never received a balance proof, or he is intentionally not providing
        // the latest transfer, in which case the closing party is going to
        // lose the tokens that were transferred to him.
        if (nonce > 0) {
            recovered_non_closing_participant_address = recoverAddressFromBalanceProof(
                channel_identifier,
                balance_hash,
                nonce,
                additional_hash,
                non_closing_signature
            );
            // Signature must be from the channel partner
            require(non_closing_participant == recovered_non_closing_participant_address);

            updateBalanceProofData(
                channel,
                recovered_non_closing_participant_address,
                nonce,
                balance_hash
            );
        }

        emit ChannelClosed(channel_identifier, closing_participant, nonce, balance_hash);
    }

    /// @notice Called on a closed channel, the function allows the non-closing
    /// participant to provide the last balance proof, which modifies the
    /// closing participant's state. Can be called multiple times by anyone.
    /// @param channel_identifier Identifier for the channel on which this
    /// operation takes place
    /// @param closing_participant Channel participant who closed the channel
    /// @param non_closing_participant Channel participant who needs to update
    /// the balance proof
    /// @param balance_hash Hash of (transferred_amount, locked_amount,
    /// locksroot)
    /// @param additional_hash Computed from the message. Used for message
    /// authentication
    /// @param nonce Strictly monotonic value used to order transfers
    /// @param closing_signature Closing participant's signature of the balance
    /// proof data
    /// @param non_closing_signature Non-closing participant signature of the
    /// balance proof data
    function updateNonClosingBalanceProof(
        uint256 channel_identifier,
        address closing_participant,
        address non_closing_participant,
        // The next four arguments form a balance proof
        bytes32 balance_hash,
        uint256 nonce,
        bytes32 additional_hash,
        bytes calldata closing_signature,
        bytes calldata non_closing_signature
    )
        external
    {
        require(channel_identifier == getChannelIdentifier(
            closing_participant,
            non_closing_participant
        ));
        require(balance_hash != bytes32(0x0));
        require(nonce > 0);

        address recovered_non_closing_participant;
        address recovered_closing_participant;

        Channel storage channel = channels[channel_identifier];

        require(channel.state == ChannelState.Closed);

        // Calling this function after the settlement window is forbidden to
        // fix the following race condition:
        //
        // 1 A badly configured node A, that doesn't have a monitoring service
        //   and is temporarily offline does not call update during the
        //   settlement window.
        // 2 The well behaved partner B, who called close, sees the
        //   settlement window is over and calls settle. At this point the B's
        //   balance proofs which should be provided by A is missing, so B will
        //   call settle with its balance proof zeroed out.
        // 3 A restarts and calls update, which will change B's balance
        //   proof.
        // 4 At this point, the transactions from 2 and 3 are racing, and one
        //   of them will fail.
        //
        // To avoid the above race condition, which would require special
        // handling on both nodes, the call to update is forbidden after the
        // settlement window. This does not affect safety, since we assume the
        // nodes are always properly configured and have a monitoring service
        // available to call update on the user's behalf.
        require(channel.settle_block_number >= block.number);

        // We need the signature from the non-closing participant to allow
        // anyone to make this transaction. E.g. a monitoring service.
        recovered_non_closing_participant = recoverAddressFromBalanceProofCounterSignature(
            MessageTypeId.BalanceProofUpdate,
            channel_identifier,
            balance_hash,
            nonce,
            additional_hash,
            closing_signature,
            non_closing_signature
        );
        require(non_closing_participant == recovered_non_closing_participant);

        recovered_closing_participant = recoverAddressFromBalanceProof(
            channel_identifier,
            balance_hash,
            nonce,
            additional_hash,
            closing_signature
        );
        require(closing_participant == recovered_closing_participant);

        Participant storage closing_participant_state = channel.participants[closing_participant];
        // Make sure the first signature is from the closing participant
        require(closing_participant_state.is_the_closer);

        // Update the balance proof data for the closing_participant
        updateBalanceProofData(channel, closing_participant, nonce, balance_hash);

        emit NonClosingBalanceProofUpdated(
            channel_identifier,
            closing_participant,
            nonce,
            balance_hash
        );
    }

    /// @notice Settles the balance between the two parties. Note that arguments
    /// order counts: `participant1_transferred_amount +
    /// participant1_locked_amount` <= `participant2_transferred_amount +
    /// participant2_locked_amount`
    /// @param channel_identifier Identifier for the channel on which this
    /// operation takes place
    /// @param participant1 Channel participant
    /// @param participant1_transferred_amount The latest known amount of tokens
    /// transferred from `participant1` to `participant2`
    /// @param participant1_locked_amount Amount of tokens owed by
    /// `participant1` to `participant2`, contained in locked transfers that
    /// will be retrieved by calling `unlock` after the channel is settled
    /// @param participant1_locksroot The latest known hash of the
    /// pending hash-time locks of `participant1`, used to validate the unlocked
    /// proofs. If no balance_hash has been submitted, locksroot is ignored
    /// @param participant2 Other channel participant
    /// @param participant2_transferred_amount The latest known amount of tokens
    /// transferred from `participant2` to `participant1`
    /// @param participant2_locked_amount Amount of tokens owed by
    /// `participant2` to `participant1`, contained in locked transfers that
    /// will be retrieved by calling `unlock` after the channel is settled
    /// @param participant2_locksroot The latest known hash of the
    /// pending hash-time locks of `participant2`, used to validate the unlocked
    /// proofs. If no balance_hash has been submitted, locksroot is ignored
    function settleChannel(
        uint256 channel_identifier,
        address participant1,
        uint256 participant1_transferred_amount,
        uint256 participant1_locked_amount,
        bytes32 participant1_locksroot,
        address participant2,
        uint256 participant2_transferred_amount,
        uint256 participant2_locked_amount,
        bytes32 participant2_locksroot
    )
        public
    {
        // There are several requirements that this function MUST enforce:
        // - it MUST never fail; therefore, any overflows or underflows must be
        // handled gracefully
        // - it MUST ensure that if participants use the latest valid balance proofs,
        // provided by the official Raiden client, the participants will be able
        // to receive correct final balances at the end of the channel lifecycle
        // - it MUST ensure that the participants cannot cheat by providing an
        // old, valid balance proof of their partner; meaning that their partner MUST
        // receive at least the amount of tokens that he would have received if
        // the latest valid balance proofs are used.
        // - the contract cannot determine if a balance proof is invalid (values
        // are not within the constraints enforced by the official Raiden client),
        // therefore it cannot ensure correctness. Users MUST use the official
        // Raiden clients for signing balance proofs.

        require(channel_identifier == getChannelIdentifier(participant1, participant2));

        bytes32 pair_hash;

        pair_hash = getParticipantsHash(participant1, participant2);
        Channel storage channel = channels[channel_identifier];

        require(channel.state == ChannelState.Closed);

        // Settlement window must be over
        require(channel.settle_block_number < block.number);

        Participant storage participant1_state = channel.participants[participant1];
        Participant storage participant2_state = channel.participants[participant2];

        require(verifyBalanceHashData(
            participant1_state,
            participant1_transferred_amount,
            participant1_locked_amount,
            participant1_locksroot
        ));

        require(verifyBalanceHashData(
            participant2_state,
            participant2_transferred_amount,
            participant2_locked_amount,
            participant2_locksroot
        ));

        // We are calculating the final token amounts that need to be
        // transferred to the participants now and the amount of tokens that
        // need to remain locked in the contract. These tokens can be unlocked
        // by calling `unlock`.
        // participant1_transferred_amount = the amount of tokens that
        //   participant1 will receive in this transaction.
        // participant2_transferred_amount = the amount of tokens that
        //   participant2 will receive in this transaction.
        // participant1_locked_amount = the amount of tokens remaining in the
        //   contract, representing pending transfers from participant1 to participant2.
        // participant2_locked_amount = the amount of tokens remaining in the
        //   contract, representing pending transfers from participant2 to participant1.
        // We are reusing variables due to the local variables number limit.
        // For better readability this can be refactored further.
        (
            participant1_transferred_amount,
            participant2_transferred_amount,
            participant1_locked_amount,
            participant2_locked_amount
        ) = getSettleTransferAmounts(
            participant1_state,
            participant1_transferred_amount,
            participant1_locked_amount,
            participant2_state,
            participant2_transferred_amount,
            participant2_locked_amount
        );

        // Remove the channel data from storage
        delete channel.participants[participant1];
        delete channel.participants[participant2];
        delete channels[channel_identifier];

        // Remove the pair's channel counter
        delete participants_hash_to_channel_identifier[pair_hash];

        // Store balance data needed for `unlock`, including the calculated
        // locked amounts remaining in the contract.
        storeUnlockData(
            channel_identifier,
            participant1,
            participant2,
            participant1_locked_amount,
            participant1_locksroot
        );
        storeUnlockData(
            channel_identifier,
            participant2,
            participant1,
            participant2_locked_amount,
            participant2_locksroot
        );

        emit ChannelSettled(
            channel_identifier,
            participant1_transferred_amount,
            participant1_locksroot,
            participant2_transferred_amount,
            participant2_locksroot
        );

        // Do the actual token transfers
        if (participant1_transferred_amount > 0) {
            require(token.transfer(participant1, participant1_transferred_amount));
        }

        if (participant2_transferred_amount > 0) {
            require(token.transfer(participant2, participant2_transferred_amount));
        }
    }

    /// @notice Unlocks all pending off-chain transfers from `sender` to
    /// `receiver` and sends the locked tokens corresponding to locks with
    /// secrets registered on-chain to the `receiver`. Locked tokens
    /// corresponding to locks where the secret was not revealed on-chain will
    /// return to the `sender`. Anyone can call unlock.
    /// @param channel_identifier Identifier for the channel on which this
    /// operation takes place
    /// @param receiver Address who will receive the claimable unlocked
    /// tokens
    /// @param sender Address who sent the pending transfers and will receive
    /// the unclaimable unlocked tokens
    /// @param locks All pending locks concatenated in order of creation
    /// that `sender` sent to `receiver`
    function unlock(
        uint256 channel_identifier,
        address receiver,
        address sender,
        bytes memory locks
    )
        public
    {
        // Channel represented by channel_identifier must be settled and
        // channel data deleted
        require(channel_identifier != getChannelIdentifier(receiver, sender));

        // After the channel is settled the storage is cleared, therefore the
        // value will be NonExistent and not Settled. The value Settled is used
        // for the external APIs
        require(channels[channel_identifier].state == ChannelState.NonExistent);

        bytes32 unlock_key;
        bytes32 computed_locksroot;
        uint256 unlocked_amount;
        uint256 locked_amount;
        uint256 returned_tokens;

        // Calculate the locksroot for the pending transfers and the amount of
        // tokens corresponding to the locked transfers with secrets revealed
        // on chain.
        (computed_locksroot, unlocked_amount) = getHashAndUnlockedAmount(
            locks
        );

        // The sender must have a non-empty locksroot on-chain that must be
        // the same as the computed locksroot.
        // Get the amount of tokens that have been left in the contract, to
        // account for the pending transfers `sender` -> `receiver`.
        unlock_key = getUnlockIdentifier(channel_identifier, sender, receiver);
        UnlockData storage unlock_data = unlock_identifier_to_unlock_data[unlock_key];
        locked_amount = unlock_data.locked_amount;

        // Locksroot must be the same as the computed locksroot
        require(unlock_data.locksroot == computed_locksroot);

        // There are no pending transfers if the locked_amount is 0.
        // Transaction must fail
        require(locked_amount > 0);

        // Make sure we don't transfer more tokens than previously reserved in
        // the smart contract.
        unlocked_amount = min(unlocked_amount, locked_amount);

        // Transfer the rest of the tokens back to the sender
        returned_tokens = locked_amount - unlocked_amount;

        // Remove sender's unlock data
        delete unlock_identifier_to_unlock_data[unlock_key];

        emit ChannelUnlocked(
            channel_identifier,
            receiver,
            sender,
            computed_locksroot,
            unlocked_amount,
            returned_tokens
        );

        // Transfer the unlocked tokens to the receiver. unlocked_amount can
        // be 0
        if (unlocked_amount > 0) {
            require(token.transfer(receiver, unlocked_amount));
        }

        // Transfer the rest of the tokens back to the sender
        if (returned_tokens > 0) {
            require(token.transfer(sender, returned_tokens));
        }

        // At this point, this should always be true
        assert(locked_amount >= returned_tokens);
        assert(locked_amount >= unlocked_amount);
    }

    /* /// @notice Cooperatively settles the balances between the two channel
    /// participants and transfers the agreed upon token amounts to the
    /// participants. After this the channel lifecycle has ended and no more
    /// operations can be done on it.
    /// @param channel_identifier Identifier for the channel on which this
    /// operation takes place
    /// @param participant1_address Address of channel participant
    /// @param participant1_balance Amount of tokens that `participant1_address`
    /// must receive when the channel is settled and removed
    /// @param participant2_address Address of the other channel participant
    /// @param participant2_balance Amount of tokens that `participant2_address`
    /// must receive when the channel is settled and removed
    /// @param participant1_signature Signature of `participant1_address` on the
    /// cooperative settle message
    /// @param participant2_signature Signature of `participant2_address` on the
    /// cooperative settle message
    function cooperativeSettle(
        uint256 channel_identifier,
        address participant1_address,
        uint256 participant1_balance,
        address participant2_address,
        uint256 participant2_balance,
        bytes participant1_signature,
        bytes participant2_signature
    )
        public
    {
        require(channel_identifier == getChannelIdentifier(
            participant1_address,
            participant2_address
        ));
        bytes32 pair_hash;
        address participant1;
        address participant2;
        uint256 total_available_deposit;

        pair_hash = getParticipantsHash(participant1_address, participant2_address);
        Channel storage channel = channels[channel_identifier];

        require(channel.state == ChannelState.Opened);

        participant1 = recoverAddressFromCooperativeSettleSignature(
            channel_identifier,
            participant1_address,
            participant1_balance,
            participant2_address,
            participant2_balance,
            participant1_signature
        );
        // The provided address must be the same as the recovered one
        require(participant1 == participant1_address);

        participant2 = recoverAddressFromCooperativeSettleSignature(
            channel_identifier,
            participant1_address,
            participant1_balance,
            participant2_address,
            participant2_balance,
            participant2_signature
        );
        // The provided address must be the same as the recovered one
        require(participant2 == participant2_address);

        Participant storage participant1_state = channel.participants[participant1];
        Participant storage participant2_state = channel.participants[participant2];

        total_available_deposit = getChannelAvailableDeposit(
            participant1_state,
            participant2_state
        );
        // The sum of the provided balances must be equal to the total
        // available deposit
        require(total_available_deposit == (participant1_balance + participant2_balance));
        // Overflow check for the balances addition from the above check.
        // This overflow should never happen if the token.transfer function is implemented
        // correctly. We do not control the token implementation, therefore we add this
        // check for safety.
        require(participant1_balance <= participant1_balance + participant2_balance);

        // Remove channel data from storage before doing the token transfers
        delete channel.participants[participant1];
        delete channel.participants[participant2];
        delete channels[channel_identifier];

        // Remove the pair's channel counter
        delete participants_hash_to_channel_identifier[pair_hash];

        emit ChannelSettled(channel_identifier, participant1_balance, participant2_balance);

        // Do the token transfers
        if (participant1_balance > 0) {
            require(token.transfer(participant1, participant1_balance));
        }

        if (participant2_balance > 0) {
            require(token.transfer(participant2, participant2_balance));
        }
    } */

    /// @notice Returns the unique identifier for the channel given by the
    /// contract
    /// @param participant Address of a channel participant
    /// @param partner Address of the other channel participant
    /// @return Unique identifier for the channel. It can be 0 if channel does
    /// not exist
    function getChannelIdentifier(address participant, address partner)
        public
        view
        returns (uint256)
    {
        require(participant != address(0x0));
        require(partner != address(0x0));
        require(participant != partner);

        bytes32 pair_hash = getParticipantsHash(participant, partner);
        return participants_hash_to_channel_identifier[pair_hash];
    }

    /// @dev Returns the channel specific data.
    /// @param channel_identifier Identifier for the channel on which this
    /// operation takes place
    /// @param participant1 Address of a channel participant
    /// @param participant2 Address of the other channel participant
    /// @return Channel settle_block_number and state
    /// @notice The contract cannot really distinguish Settled and Removed
    /// states, especially when wrong participants are given as input.
    /// The contract does not remember the participants of the channel
    function getChannelInfo(
        uint256 channel_identifier,
        address participant1,
        address participant2
    )
        external
        view
        returns (uint256, ChannelState)
    {
        bytes32 unlock_key1;
        bytes32 unlock_key2;

        Channel storage channel = channels[channel_identifier];
        ChannelState state = channel.state;  // This must **not** update the storage

        if (state == ChannelState.NonExistent &&
            channel_identifier > 0 &&
            channel_identifier <= channel_counter
        ) {
            // The channel has been settled, channel data is removed Therefore,
            // the channel state in storage is actually `0`, or `NonExistent`
            // However, for this view function, we return `Settled`, in order
            // to provide a consistent external API
            state = ChannelState.Settled;

            // We might still have data stored for future unlock operations
            // Only if we do not, we can consider the channel as `Removed`
            unlock_key1 = getUnlockIdentifier(channel_identifier, participant1, participant2);
            UnlockData storage unlock_data1 = unlock_identifier_to_unlock_data[unlock_key1];

            unlock_key2 = getUnlockIdentifier(channel_identifier, participant2, participant1);
            UnlockData storage unlock_data2 = unlock_identifier_to_unlock_data[unlock_key2];

            if (unlock_data1.locked_amount == 0 && unlock_data2.locked_amount == 0) {
                state = ChannelState.Removed;
            }
        }

        return (
            channel.settle_block_number,
            state
        );
    }

    /// @dev Returns the channel specific data.
    /// @param channel_identifier Identifier for the channel on which this
    /// operation takes place
    /// @param participant Address of the channel participant whose data will be
    /// returned
    /// @param partner Address of the channel partner
    /// @return Participant's deposit, withdrawn_amount, whether the participant
    /// has called `closeChannel` or not, balance_hash, nonce, locksroot,
    /// locked_amount
    function getChannelParticipantInfo(
            uint256 channel_identifier,
            address participant,
            address partner
    )
        external
        view
        returns (uint256, uint256, bool, bytes32, uint256, bytes32, uint256)
    {
        bytes32 unlock_key;

        Participant storage participant_state = channels[channel_identifier].participants[
            participant
        ];
        unlock_key = getUnlockIdentifier(channel_identifier, participant, partner);
        UnlockData storage unlock_data = unlock_identifier_to_unlock_data[unlock_key];

        return (
            participant_state.deposit,
            participant_state.withdrawn_amount,
            participant_state.is_the_closer,
            participant_state.balance_hash,
            participant_state.nonce,
            unlock_data.locksroot,
            unlock_data.locked_amount
        );
    }

    /// @dev Get the hash of the participant addresses, ordered
    /// lexicographically
    /// @param participant Address of a channel participant
    /// @param partner Address of the other channel participant
    function getParticipantsHash(address participant, address partner)
        public
        pure
        returns (bytes32)
    {
        require(participant != address(0x0));
        require(partner != address(0x0));
        require(participant != partner);

        if (participant < partner) {
            return keccak256(abi.encodePacked(participant, partner));
        } else {
            return keccak256(abi.encodePacked(partner, participant));
        }
    }

    /// @dev Get the hash of the channel identifier and the participant
    /// addresses (whose ordering matters). The hash might be useful for
    /// the receiver to look up the appropriate UnlockData to claim
    /// @param channel_identifier Identifier for the channel which the
    /// UnlockData is about
    /// @param sender Sender of the pending transfers that the UnlockData
    /// represents
    /// @param receiver Receiver of the pending transfers that the UnlockData
    /// represents
    function getUnlockIdentifier(
        uint256 channel_identifier,
        address sender,
        address receiver
    )
        public
        pure
        returns (bytes32)
    {
        require(sender != receiver);
        return keccak256(abi.encodePacked(channel_identifier, sender, receiver));
    }

    function updateBalanceProofData(
        Channel storage channel,
        address participant,
        uint256 nonce,
        bytes32 balance_hash
    )
        internal
    {
        Participant storage participant_state = channel.participants[participant];

        // Multiple calls to updateNonClosingBalanceProof can be made and we
        // need to store the last known balance proof data.
        // This line prevents Monitoring Services from getting rewards
        // again and again using the same reward proof.
        require(nonce > participant_state.nonce);

        participant_state.nonce = nonce;
        participant_state.balance_hash = balance_hash;
    }

    function storeUnlockData(
        uint256 channel_identifier,
        address sender,
        address receiver,
        uint256 locked_amount,
        bytes32 locksroot
    )
        internal
    {
        // If there are transfers to unlock, store the locksroot and total
        // amount of tokens
        if (locked_amount == 0) {
            return;
        }

        bytes32 key = getUnlockIdentifier(channel_identifier, sender, receiver);
        UnlockData storage unlock_data = unlock_identifier_to_unlock_data[key];
        unlock_data.locksroot = locksroot;
        unlock_data.locked_amount = locked_amount;
    }

    function getChannelAvailableDeposit(
        Participant storage participant1_state,
        Participant storage participant2_state
    )
        internal
        view
        returns (uint256 total_available_deposit)
    {
        total_available_deposit = (
            participant1_state.deposit +
            participant2_state.deposit -
            participant1_state.withdrawn_amount -
            participant2_state.withdrawn_amount
        );
    }

    /// @dev Function that calculates the amount of tokens that the participants
    /// will receive when calling settleChannel.
    /// Check https://github.com/raiden-network/raiden-contracts/issues/188 for the settlement
    /// algorithm analysis and explanations.
    function getSettleTransferAmounts(
        Participant storage participant1_state,
        uint256 participant1_transferred_amount,
        uint256 participant1_locked_amount,
        Participant storage participant2_state,
        uint256 participant2_transferred_amount,
        uint256 participant2_locked_amount
    )
        private
        view
        returns (uint256, uint256, uint256, uint256)
    {
        // The scope of this function is to compute the settlement amounts that
        // the two channel participants will receive when calling settleChannel
        // and the locked amounts that remain in the contract, to account for
        // the pending, not finalized transfers, that will be received by the
        // participants when calling `unlock`.

        // The amount of tokens that participant1 MUST receive at the end of
        // the channel lifecycle (after settleChannel and unlock) is:
        // B1 = D1 - W1 + T2 - T1 + Lc2 - Lc1

        // The amount of tokens that participant2 MUST receive at the end of
        // the channel lifecycle (after settleChannel and unlock) is:
        // B2 = D2 - W2 + T1 - T2 + Lc1 - Lc2

        // B1 + B2 = TAD = D1 + D2 - W1 - W2
        // TAD = total available deposit at settlement time

        // L1 = Lc1 + Lu1
        // L2 = Lc2 + Lu2

        // where:
        // B1 = final balance of participant1 after the channel is removed
        // D1 = total amount deposited by participant1 into the channel
        // W1 = total amount withdrawn by participant1 from the channel
        // T2 = total amount transferred by participant2 to participant1 (finalized transfers)
        // T1 = total amount transferred by participant1 to participant2 (finalized transfers)
        // L1 = total amount of tokens locked in pending transfers, sent by
        //   participant1 to participant2
        // L2 = total amount of tokens locked in pending transfers, sent by
        //   participant2 to participant1
        // Lc2 = the amount that can be claimed by participant1 from the pending
        //   transfers (that have not been finalized off-chain), sent by
        //   participant2 to participant1. These are part of the locked amount
        //   value from participant2's balance proof. They are considered claimed
        //   if the secret corresponding to these locked transfers was registered
        //   on-chain, in the SecretRegistry contract, before the lock's expiration.
        // Lu1 = unclaimable locked amount from L1
        // Lc1 = the amount that can be claimed by participant2 from the pending
        //   transfers (that have not been finalized off-chain),
        //   sent by participant1 to participant2
        // Lu2 = unclaimable locked amount from L2

        // Notes:
        // 1) The unclaimble tokens from a locked amount will return to the sender.
        // At the time of calling settleChannel, the TokenNetwork contract does
        // not know what locked amounts are claimable or unclaimable.
        // 2) There are some Solidity constraints that make the calculations
        // more difficult: attention to overflows and underflows, that MUST be
        // handled without throwing.

        // Cases that require attention:
        // case1. If participant1 does NOT provide a balance proof or provides
        // an old balance proof.  participant2_transferred_amount can be [0,
        // real_participant2_transferred_amount) We MUST NOT punish
        // participant2.
        // case2. If participant2 does NOT provide a balance proof or provides
        // an old balance proof.  participant1_transferred_amount can be [0,
        // real_participant1_transferred_amount) We MUST NOT punish
        // participant1.
        // case3. If neither participants provide a balance proof, we just
        // subtract their withdrawn amounts from their deposits.

        // This is why, the algorithm implemented in Solidity is:
        // (explained at each step, below)
        // RmaxP1 = (T2 + L2) - (T1 + L1) + D1 - W1
        // RmaxP1 = min(TAD, RmaxP1)
        // RmaxP2 = TAD - RmaxP1
        // SL2 = min(RmaxP1, L2)
        // S1 = RmaxP1 - SL2
        // SL1 = min(RmaxP2, L1)
        // S2 = RmaxP2 - SL1

        // where:
        // RmaxP1 = due to possible over/underflows that only appear when using
        //    old balance proofs & the fact that settlement balance calculation
        //    is symmetric (we can calculate either RmaxP1 and RmaxP2 first,
        //    order does not affect result), this is a convention used to determine
        //    the maximum receivable amount of participant1 at settlement time
        // S1 = amount received by participant1 when calling settleChannel
        // SL1 = the maximum amount from L1 that can be locked in the
        //   TokenNetwork contract when calling settleChannel (due to overflows
        //   that only happen when using old balance proofs)
        // S2 = amount received by participant2 when calling settleChannel
        // SL2 = the maximum amount from L2 that can be locked in the
        //   TokenNetwork contract when calling settleChannel (due to overflows
        //   that only happen when using old balance proofs)

        uint256 participant1_amount;
        uint256 participant2_amount;
        uint256 total_available_deposit;

        SettlementData memory participant1_settlement;
        SettlementData memory participant2_settlement;

        participant1_settlement.deposit = participant1_state.deposit;
        participant1_settlement.withdrawn = participant1_state.withdrawn_amount;
        participant1_settlement.transferred = participant1_transferred_amount;
        participant1_settlement.locked = participant1_locked_amount;

        participant2_settlement.deposit = participant2_state.deposit;
        participant2_settlement.withdrawn = participant2_state.withdrawn_amount;
        participant2_settlement.transferred = participant2_transferred_amount;
        participant2_settlement.locked = participant2_locked_amount;

        // TAD = D1 + D2 - W1 - W2 = total available deposit at settlement time
        total_available_deposit = getChannelAvailableDeposit(
            participant1_state,
            participant2_state
        );

        // RmaxP1 = (T2 + L2) - (T1 + L1) + D1 - W1
        // This amount is the maximum possible amount that participant1 can
        // receive at settlement time and also contains the entire locked amount
        //  of the pending transfers from participant2 to participant1.
        participant1_amount = getMaxPossibleReceivableAmount(
            participant1_settlement,
            participant2_settlement
        );

        // RmaxP1 = min(TAD, RmaxP1)
        // We need to bound this to the available channel deposit in order to
        // not send tokens from other channels. The only case where TAD is
        // smaller than RmaxP1 is when at least one balance proof is old.
        participant1_amount = min(participant1_amount, total_available_deposit);

        // RmaxP2 = TAD - RmaxP1
        // Now it is safe to subtract without underflow
        participant2_amount = total_available_deposit - participant1_amount;

        // SL2 = min(RmaxP1, L2)
        // S1 = RmaxP1 - SL2
        // Both operations are done by failsafe_subtract
        // We take out participant2's pending transfers locked amount, bounding
        // it by the maximum receivable amount of participant1
        (participant1_amount, participant2_locked_amount) = failsafe_subtract(
            participant1_amount,
            participant2_locked_amount
        );

        // SL1 = min(RmaxP2, L1)
        // S2 = RmaxP2 - SL1
        // Both operations are done by failsafe_subtract
        // We take out participant1's pending transfers locked amount, bounding
        // it by the maximum receivable amount of participant2
        (participant2_amount, participant1_locked_amount) = failsafe_subtract(
            participant2_amount,
            participant1_locked_amount
        );

        // This should never throw:
        // S1 and S2 MUST be smaller than TAD
        assert(participant1_amount <= total_available_deposit);
        assert(participant2_amount <= total_available_deposit);
        // S1 + S2 + SL1 + SL2 == TAD
        assert(total_available_deposit == (
            participant1_amount +
            participant2_amount +
            participant1_locked_amount +
            participant2_locked_amount
        ));

        return (
            participant1_amount,
            participant2_amount,
            participant1_locked_amount,
            participant2_locked_amount
        );
    }

    function getMaxPossibleReceivableAmount(
        SettlementData memory participant1_settlement,
        SettlementData memory participant2_settlement
    )
        internal
        pure
        returns (uint256)
    {
        uint256 participant1_max_transferred;
        uint256 participant2_max_transferred;
        uint256 participant1_net_max_received;
        uint256 participant1_max_amount;

        // This is the maximum possible amount that participant1 could transfer
        // to participant2, if all the pending lock secrets have been
        // registered
        participant1_max_transferred = failsafe_addition(
            participant1_settlement.transferred,
            participant1_settlement.locked
        );

        // This is the maximum possible amount that participant2 could transfer
        // to participant1, if all the pending lock secrets have been
        // registered
        participant2_max_transferred = failsafe_addition(
            participant2_settlement.transferred,
            participant2_settlement.locked
        );

        // We enforce this check artificially, in order to get rid of hard
        // to deal with over/underflows. Settlement balance calculation is
        // symmetric (we can calculate either RmaxP1 and RmaxP2 first, order does
        // not affect result). This means settleChannel must be called with
        // ordered values.
        require(participant2_max_transferred >= participant1_max_transferred);

        assert(participant1_max_transferred >= participant1_settlement.transferred);
        assert(participant2_max_transferred >= participant2_settlement.transferred);

        // This is the maximum amount that participant1 can receive at settlement time
        participant1_net_max_received = (
            participant2_max_transferred -
            participant1_max_transferred
        );

        // Next, we add the participant1's deposit and subtract the already
        // withdrawn amount
        participant1_max_amount = failsafe_addition(
            participant1_net_max_received,
            participant1_settlement.deposit
        );

        // Subtract already withdrawn amount
        (participant1_max_amount, ) = failsafe_subtract(
            participant1_max_amount,
            participant1_settlement.withdrawn
        );
        return participant1_max_amount;
    }

    function verifyBalanceHashData(
        Participant storage participant,
        uint256 transferred_amount,
        uint256 locked_amount,
        bytes32 locksroot
    )
        internal
        view
        returns (bool)
    {
        // When no balance proof has been provided, we need to check this
        // separately because hashing values of 0 outputs a value != 0
        if (participant.balance_hash == 0 &&
            transferred_amount == 0 &&
            locked_amount == 0
            /* locksroot is ignored. */
        ) {
            return true;
        }

        // Make sure the hash of the provided state is the same as the stored
        // balance_hash
        return participant.balance_hash == keccak256(abi.encodePacked(
            transferred_amount,
            locked_amount,
            locksroot
        ));
    }

    function recoverAddressFromBalanceProof(
        uint256 channel_identifier,
        bytes32 balance_hash,
        uint256 nonce,
        bytes32 additional_hash,
        bytes memory signature
    )
        internal
        view
        returns (address signature_address)
    {
        // Length of the actual message: 20 + 32 + 32 + 32 + 32 + 32 + 32
        string memory message_length = '212';

        bytes32 message_hash = keccak256(abi.encodePacked(
            signature_prefix,
            message_length,
            address(this),
            chain_id,
            uint256(MessageTypeId.BalanceProof),
            channel_identifier,
            balance_hash,
            nonce,
            additional_hash
        ));

        signature_address = ECVerify.ecverify(message_hash, signature);
    }

    function recoverAddressFromBalanceProofCounterSignature(
        MessageTypeId message_type_id,
        uint256 channel_identifier,
        bytes32 balance_hash,
        uint256 nonce,
        bytes32 additional_hash,
        bytes memory closing_signature,
        bytes memory non_closing_signature
    )
        internal
        view
        returns (address signature_address)
    {
        // Length of the actual message: 20 + 32 + 32 + 32 + 32 + 32 + 32 + 65
        string memory message_length = '277';

        bytes32 message_hash = keccak256(abi.encodePacked(
            signature_prefix,
            message_length,
            address(this),
            chain_id,
            uint256(message_type_id),
            channel_identifier,
            balance_hash,
            nonce,
            additional_hash,
            closing_signature
        ));

        signature_address = ECVerify.ecverify(message_hash, non_closing_signature);
    }

    /* function recoverAddressFromCooperativeSettleSignature(
        uint256 channel_identifier,
        address participant1,
        uint256 participant1_balance,
        address participant2,
        uint256 participant2_balance,
        bytes signature
    )
        view
        internal
        returns (address signature_address)
    {
        // Length of the actual message: 20 + 32 + 32 + 32 + 20 + 32 + 20 + 32
        string memory message_length = '220';

        bytes32 message_hash = keccak256(abi.encodePacked(
            signature_prefix,
            message_length,
            address(this),
            chain_id,
            uint256(MessageTypeId.CooperativeSettle),
            channel_identifier,
            participant1,
            participant1_balance,
            participant2,
            participant2_balance
        ));

        signature_address = ECVerify.ecverify(message_hash, signature);
    } */

    function recoverAddressFromWithdrawMessage(
        uint256 channel_identifier,
        address participant,
        uint256 total_withdraw,
        uint256 expiration_block,
        bytes memory signature
    )
        internal
        view
        returns (address signature_address)
    {
        // Length of the actual message: 20 + 32 + 32 + 32 + 20 + 32 + 32
        string memory message_length = '200';

        bytes32 message_hash = keccak256(abi.encodePacked(
            signature_prefix,
            message_length,
            address(this),
            chain_id,
            uint256(MessageTypeId.Withdraw),
            channel_identifier,
            participant,
            total_withdraw,
            expiration_block
        ));

        signature_address = ECVerify.ecverify(message_hash, signature);
    }

    /// @dev Calculates the hash of the pending transfers data and
    /// calculates the amount of tokens that can be unlocked because the secret
    /// was registered on-chain.
    function getHashAndUnlockedAmount(bytes memory locks)
        internal
        view
        returns (bytes32, uint256)
    {
        uint256 length = locks.length;

        // each lock has this form:
        // (locked_amount || expiration_block || secrethash) = 3 * 32 bytes
        require(length % 96 == 0);

        uint256 i;
        uint256 total_unlocked_amount;
        uint256 unlocked_amount;
        bytes32 lockhash;
        bytes32 total_hash;

        for (i = 32; i < length; i += 96) {
            unlocked_amount = getLockedAmountFromLock(locks, i);
            total_unlocked_amount += unlocked_amount;
        }

        total_hash = keccak256(locks);

        return (total_hash, total_unlocked_amount);
    }

    function getLockedAmountFromLock(bytes memory locks, uint256 offset)
        internal
        view
        returns (uint256)
    {
        uint256 expiration_block;
        uint256 locked_amount;
        uint256 reveal_block;
        bytes32 secrethash;

        if (locks.length <= offset) {
            return 0;
        }

        assembly {
            expiration_block := mload(add(locks, offset))
            locked_amount := mload(add(locks, add(offset, 32)))
            secrethash := mload(add(locks, add(offset, 64)))
        }

        // Check if the lock's secret was revealed in the SecretRegistry The
        // secret must have been revealed in the SecretRegistry contract before
        // the lock's expiration_block in order for the hash time lock transfer
        // to be successful.
        reveal_block = secret_registry.getSecretRevealBlockHeight(secrethash);
        if (reveal_block == 0 || expiration_block <= reveal_block) {
            locked_amount = 0;
        }

        return locked_amount;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256)
    {
        return a > b ? b : a;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256)
    {
        return a > b ? a : b;
    }

    /// @dev Special subtraction function that does not fail when underflowing.
    /// @param a Minuend
    /// @param b Subtrahend
    /// @return Minimum between the result of the subtraction and 0, the maximum
    /// subtrahend for which no underflow occurs
    function failsafe_subtract(uint256 a, uint256 b)
        internal
        pure
        returns (uint256, uint256)
    {
        return a > b ? (a - b, b) : (0, a);
    }

    /// @dev Special addition function that does not fail when overflowing.
    /// @param a Addend
    /// @param b Addend
    /// @return Maximum between the result of the addition or the maximum
    /// uint256 value
    function failsafe_addition(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        uint256 sum = a + b;
        return sum >= a ? sum : MAX_SAFE_UINT256;
    }
}



/// @title TokenNetworkRegistry
/// @notice The TokenNetwork Registry deploys new TokenNetwork contracts for the
/// Raiden Network protocol.
contract TokenNetworkRegistry is Utils {
    address public secret_registry_address;
    uint256 public chain_id;
    uint256 public settlement_timeout_min;
    uint256 public settlement_timeout_max;
    uint256 public max_token_networks;

    // Only for the limited Red Eyes release
    address public deprecation_executor;
    uint256 public token_network_created = 0;

    // Token address => TokenNetwork address
    mapping(address => address) public token_to_token_networks;

    event TokenNetworkCreated(address indexed token_address, address indexed token_network_address);

    modifier canCreateTokenNetwork() {
        require(token_network_created < max_token_networks, "registry full");
        _;
    }

    /// @param _secret_registry_address The address of SecretRegistry that's used by all
    /// TokenNetworks created by this contract
    /// @param _chain_id EIP-155 Chain-ID of the chain where this contract is deployed
    /// @param _settlement_timeout_min The shortest settlement period (in number of blocks)
    /// that can be chosen at the channel opening
    /// @param _settlement_timeout_max The longest settlement period (in number of blocks)
    /// that can be chosen at the channel opening
    /// @param _max_token_networks the number of tokens that can be registered
    /// MAX_UINT256 means no limits
    constructor(
        address _secret_registry_address,
        uint256 _chain_id,
        uint256 _settlement_timeout_min,
        uint256 _settlement_timeout_max,
        uint256 _max_token_networks
    )
        public
    {
        require(_chain_id > 0);
        require(_settlement_timeout_min > 0);
        require(_settlement_timeout_max > 0);
        require(_settlement_timeout_max > _settlement_timeout_min);
        require(_secret_registry_address != address(0x0));
        require(contractExists(_secret_registry_address));
        require(_max_token_networks > 0);
        secret_registry_address = _secret_registry_address;
        chain_id = _chain_id;
        settlement_timeout_min = _settlement_timeout_min;
        settlement_timeout_max = _settlement_timeout_max;
        max_token_networks = _max_token_networks;

        deprecation_executor = msg.sender;
    }

    /// @notice Deploy a new TokenNetwork contract for the Token deployed at
    /// `_token_address`
    /// @param _token_address Ethereum address of an already deployed token, to
    /// be used in the new TokenNetwork contract
    function createERC20TokenNetwork(
        address _token_address,
        uint256 _channel_participant_deposit_limit,
        uint256 _token_network_deposit_limit
    )
        external
        canCreateTokenNetwork
        returns (address token_network_address)
    {
        require(token_to_token_networks[_token_address] == address(0x0));

        // We limit the number of token networks to 1 for the Bug Bounty release
        token_network_created = token_network_created + 1;

        TokenNetwork token_network;

        // Token contract checks are in the corresponding TokenNetwork contract
        token_network = new TokenNetwork(
            _token_address,
            secret_registry_address,
            chain_id,
            settlement_timeout_min,
            settlement_timeout_max,
            deprecation_executor,
            _channel_participant_deposit_limit,
            _token_network_deposit_limit
        );

        token_network_address = address(token_network);

        token_to_token_networks[_token_address] = token_network_address;
        emit TokenNetworkCreated(_token_address, token_network_address);

        return token_network_address;
    }
}

// MIT License

// Copyright (c) 2018

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.


contract ServiceRegistryConfigurableParameters {
    address public controller;

    modifier onlyController() {
        require(msg.sender == controller, "caller is not the controller");
        _;
    }

    // After a price is set to set_price at timestamp set_price_at,
    // the price decays according to decayedPrice().
    uint256 public set_price;
    uint256 public set_price_at;

    /// The amount of time (in seconds) till the price decreases to roughly 1/e.
    uint256 public decay_constant = 200 days;

    // Once the price is at min_price, it can't decay further.
    uint256 public min_price = 1000;

    // Whenever a deposit comes in, the price is multiplied by numerator / denominator.
    uint256 public price_bump_numerator = 1;
    uint256 public price_bump_denominator = 1;

    // The duration of service registration/extension in seconds
    uint256 public registration_duration = 180 days;

    // If true, new deposits are no longer accepted.
    bool public deprecated = false;

    function setDeprecationSwitch() public onlyController returns (bool _success) {
        deprecated = true;
        return true;
    }

    function changeParameters(
            uint256 _price_bump_numerator,
            uint256 _price_bump_denominator,
            uint256 _decay_constant,
            uint256 _min_price,
            uint256 _registration_duration
    ) public onlyController returns (bool _success) {
        changeParametersInternal(
            _price_bump_numerator,
            _price_bump_denominator,
            _decay_constant,
            _min_price,
            _registration_duration
        );
        return true;
    }

    function changeParametersInternal(
            uint256 _price_bump_numerator,
            uint256 _price_bump_denominator,
            uint256 _decay_constant,
            uint256 _min_price,
            uint256 _registration_duration
    ) internal {
        refreshPrice();
        setPriceBumpParameters(_price_bump_numerator, _price_bump_denominator);
        setMinPrice(_min_price);
        setDecayConstant(_decay_constant);
        setRegistrationDuration(_registration_duration);
    }

    // Updates set_price to be currentPrice() and set_price_at to be now
    function refreshPrice() private {
        set_price = currentPrice();
        set_price_at = now;
    }

    function setPriceBumpParameters(
            uint256 _price_bump_numerator,
            uint256 _price_bump_denominator
    ) private {
        require(_price_bump_denominator > 0, "divide by zero");
        require(_price_bump_numerator >= _price_bump_denominator, "price dump instead of bump");
        require(_price_bump_numerator < 2 ** 40, "price dump numerator is too big");
        price_bump_numerator = _price_bump_numerator;
        price_bump_denominator = _price_bump_denominator;
    }

    function setMinPrice(uint256 _min_price) private {
        // No checks.  Even allowing zero.
        min_price = _min_price;
        // No checks or modifications on set_price.
        // Even if set_price is smaller than min_price, currentPrice() function returns min_price.
    }

    function setDecayConstant(uint256 _decay_constant) private {
        require(_decay_constant > 0, "attempt to set zero decay constant");
        require(_decay_constant < 2 ** 40, "too big decay constant");
        decay_constant = _decay_constant;
    }

    function setRegistrationDuration(uint256 _registration_duration) private {
        // No checks.  Even allowing zero (when no new registrations are possible).
        registration_duration = _registration_duration;
    }


    /// @notice The amount to deposit for registration or extension
    /// Note: the price moves quickly depending on what other addresses do.
    /// The current price might change after you send a `deposit()` transaction
    /// before the transaction is executed.
    function currentPrice() public view returns (uint256) {
        require(now >= set_price_at, "An underflow in price computation");
        uint256 seconds_passed = now - set_price_at;

        return decayedPrice(set_price, seconds_passed);
    }


    /// @notice Calculates the decreased price after a number of seconds
    /// @param _set_price The initial price
    /// @param _seconds_passed The number of seconds passed since the initial
    /// price was set
    function decayedPrice(uint256 _set_price, uint256 _seconds_passed) public
        view returns (uint256) {
        // We are here trying to approximate some exponential decay.
        // exp(- X / A) where
        //   X is the number of seconds since the last price change
        //   A is the decay constant (A = 200 days corresponds to 0.5% decrease per day)

        // exp(- X / A) ~~ P / Q where
        //   P = 24 A^4
        //   Q = 24 A^4 + 24 A^3X + 12 A^2X^2 + 4 AX^3 + X^4
        // Note: swap P and Q, and then think about the Taylor expansion.

        uint256 X = _seconds_passed;

        if (X >= 2 ** 40) { // The computation below overflows.
            return min_price;
        }

        uint256 A = decay_constant;

        uint256 P = 24 * (A ** 4);
        uint256 Q = P + 24*(A**3)*X + 12*(A**2)*(X**2) + 4*A*(X**3) + X**4;

        // The multiplication below is not supposed to overflow because
        // _set_price should be at most 2 ** 90 and
        // P should be at most 24 * (2 ** 40).
        uint256 price = _set_price * P / Q;

        // Not allowing a price smaller than min_price.
        // Once it's too low it's too low forever.
        if (price < min_price) {
            price = min_price;
        }
        return price;
    }
}


contract Deposit {
    // This contract holds ERC20 tokens as deposit until a predetemined point of time.

    // The ERC20 token contract that the deposit is about.
    Token public token;

    // The address of ServiceRegistry contract that this deposit is associated with.
    // If the address has no code, service_registry.deprecated() call will fail.
    ServiceRegistryConfigurableParameters service_registry;

    // The address that can withdraw the deposit after the release time.
    address public withdrawer;

    // The timestamp after which the withdrawer can withdraw the deposit.
    uint256 public release_at;

    /// @param _token The address of the ERC20 token contract where the deposit is accounted
    /// @param _release_at The timestap after which the withdrawer can withdraw the deposit
    /// @param _withdrawer The address that can withdraw the deposit after the release time
    /// @param _service_registry The address of ServiceRegistry whose deprecation enables immediate withdrawals
    constructor(address _token, uint256 _release_at, address _withdrawer, address _service_registry) public {
        token = Token(_token);
        // Don't care even if it's in the past.
        release_at = _release_at;
        withdrawer = _withdrawer;
        service_registry = ServiceRegistryConfigurableParameters(_service_registry);
    }

    // In order to make a deposit, transfer the ERC20 token into this contract.
    // If you transfer a wrong kind of ERC20 token or ETH into this contract,
    // these tokens will be lost forever.

    /// @notice Withdraws the tokens that have been deposited
    /// Only `withdrawer` can call this.
    /// @param _to The address where the withdrawn tokens should go
    function withdraw(address payable _to) external {
        uint256 balance = token.balanceOf(address(this));
        require(msg.sender == withdrawer, "the caller is not the withdrawer");
        require(now >= release_at || service_registry.deprecated(), "deposit not released yet");
        require(balance > 0, "nothing to withdraw");
        require(token.transfer(_to, balance), "token didn't transfer");
        selfdestruct(_to); // The contract can disappear.
    }
}


contract ServiceRegistry is Utils, ServiceRegistryConfigurableParameters {
    Token public token;

    mapping(address => uint256) public service_valid_till;
    mapping(address => string) public urls;  // URLs of services for HTTP access

    // An append-only list of addresses that have ever made a deposit.
    // Starting from this list, all alive registrations can be figured out.
    address[] public ever_made_deposits;

    // @param service The address of the registered service provider
    // @param valid_till The timestamp of the moment when the registration expires
    // @param deposit_amount The amount of deposit transferred
    // @param deposit The address of Deposit instance where the deposit is stored
    event RegisteredService(address indexed service, uint256 valid_till, uint256 deposit_amount, Deposit deposit_contract);

    // @param _token_for_registration The address of the ERC20 token contract that services use for registration fees
    // @param _controller The address that can change parameters and deprecate the ServiceRegistry
    // @param _initial_price The amount of tokens needed initially for a slot
    // @param _price_bump_numerator The ratio of price bump after deposit is made (numerator)
    // @param _price_bump_denominator The ratio of price bump after deposit is made (denominator)
    // @param _decay_constant The number of seconds after which the price becomes roughly 1/e
    // @param _min_price The minimum amount of tokens needed for a slot
    // @param _registration_duration The number of seconds (roughly, barring block time & miners'
    // timestamp errors) of a slot gained for a successful deposit
    constructor(
            address _token_for_registration,
            address _controller,
            uint256 _initial_price,
            uint256 _price_bump_numerator,
            uint256 _price_bump_denominator,
            uint256 _decay_constant,
            uint256 _min_price,
            uint256 _registration_duration
    ) public {
        require(_token_for_registration != address(0x0), "token at address zero");
        require(contractExists(_token_for_registration), "token has no code");
        require(_initial_price >= min_price, "initial price too low");
        require(_initial_price <= 2 ** 90, "intiial price too high");

        token = Token(_token_for_registration);
        // Check if the contract is indeed a token contract
        require(token.totalSupply() > 0, "total supply zero");
        controller = _controller;

        // Set up the price and the set price timestamp
        set_price = _initial_price;
        set_price_at = now;

        // Set the parameters
        changeParametersInternal(_price_bump_numerator, _price_bump_denominator, _decay_constant, _min_price, _registration_duration);
    }

    // @notice Locks tokens and registers a service or extends the registration
    // @param _limit_amount The biggest amount of tokens that the caller is willing to deposit
    // The call fails if the current price is higher (this is always possible
    // when other parties have just called `deposit()`)
    function deposit(uint _limit_amount) public returns (bool _success) {
        require(! deprecated, "this contract was deprecated");

        uint256 amount = currentPrice();
        require(_limit_amount >= amount, "not enough limit");

        // Extend the service position.
        uint256 valid_till = service_valid_till[msg.sender];
        if (valid_till == 0) { // a first time joiner
            ever_made_deposits.push(msg.sender);
        }
        if (valid_till < now) { // a first time joiner or an expired service.
            valid_till = now;
        }
        // Check against overflow.
        require(valid_till < valid_till + registration_duration, "overflow during extending the registration");
        valid_till = valid_till + registration_duration;
        assert(valid_till > service_valid_till[msg.sender]);
        service_valid_till[msg.sender] = valid_till;

        // Record the price
        set_price = amount * price_bump_numerator / price_bump_denominator;
        if (set_price > 2 ** 90) {
            set_price = 2 ** 90; // Preventing overflows.
        }
        set_price_at = now;

        // Move the deposit in a new Deposit contract.
        assert(now < valid_till);
        Deposit depo = new Deposit(address(token), valid_till, msg.sender, address(this));
        require(token.transferFrom(msg.sender, address(depo), amount), "Token transfer for deposit failed");

        // Fire event
        emit RegisteredService(msg.sender, valid_till, amount, depo);

        return true;
    }

    /// @notice Sets the URL used to access a service via HTTP
    /// Only a currently registered service can call this successfully
    /// @param new_url The new URL string to be stored
    function setURL(string memory new_url) public returns (bool _success) {
        require(hasValidRegistration(msg.sender), "registration expired");
        require(bytes(new_url).length != 0, "new url is empty string");
        urls[msg.sender] = new_url;
        return true;
    }

    /// A getter function for seeing the length of ever_made_deposits array
    function everMadeDepositsLen() public view returns (uint256 _len) {
        return ever_made_deposits.length;
    }

    function hasValidRegistration(address _address) public view returns (bool _has_registration) {
        return now < service_valid_till[_address];
    }
}


// MIT License

// Copyright (c) 2018

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.


contract UserDeposit is Utils {
    uint constant public withdraw_delay = 100;  // time before withdraw is allowed in blocks

    // Token to be used for the deposit
    Token public token;

    // Trusted contracts (can execute `transfer`)
    address public msc_address;
    address public one_to_n_address;

    // Total amount of tokens that have been deposited. This is monotonous and
    // doing a transfer or withdrawing tokens will not decrease total_deposit!
    mapping(address => uint256) public total_deposit;
    // Current user's balance, ignoring planned withdraws
    mapping(address => uint256) public balances;
    mapping(address => WithdrawPlan) public withdraw_plans;

    // The sum of all balances
    uint256 public whole_balance = 0;
    // Deposit limit for this whole contract
    uint256 public whole_balance_limit;

    /*
     *  Structs
     */
    struct WithdrawPlan {
        uint256 amount;
        uint256 withdraw_block;  // earliest block at which withdraw is allowed
    }

    /*
     *  Events
     */

    event BalanceReduced(address indexed owner, uint newBalance);
    event WithdrawPlanned(address indexed withdrawer, uint plannedBalance);

    /*
     *  Modifiers
     */

    modifier canTransfer() {
        require(msg.sender == msc_address || msg.sender == one_to_n_address, "unknown caller");
        _;
    }

    /*
     *  Constructor
     */

    /// @notice Set the default values for the smart contract
    /// @param _token_address The address of the token to use for rewards
    constructor(address _token_address, uint256 _whole_balance_limit)
        public
    {
        // check token contract
        require(_token_address != address(0x0), "token at address zero");
        require(contractExists(_token_address), "token has no code");
        token = Token(_token_address);
        require(token.totalSupply() > 0, "token has no total supply"); // Check if the contract is indeed a token contract
        // check and set the whole balance limit
        require(_whole_balance_limit > 0, "whole balance limit is zero");
        whole_balance_limit = _whole_balance_limit;
    }

    /// @notice Specify trusted contracts. This has to be done outside of the
    /// constructor to avoid cyclic dependencies.
    /// @param _msc_address Address of the MonitoringService contract
    /// @param _one_to_n_address Address of the OneToN contract
    function init(address _msc_address, address _one_to_n_address)
        external
    {
        // prevent changes of trusted contracts after initialization
        require(msc_address == address(0x0) && one_to_n_address == address(0x0), "already initialized");

        // check monitoring service contract
        require(_msc_address != address(0x0), "MS contract at address zero");
        require(contractExists(_msc_address), "MS contract has no code");
        msc_address = _msc_address;

        // check one to n contract
        require(_one_to_n_address != address(0x0), "OneToN at address zero");
        require(contractExists(_one_to_n_address), "OneToN has no code");
        one_to_n_address = _one_to_n_address;
    }

    /// @notice Deposit tokens. The amount of transferred tokens will be
    /// `new_total_deposit - total_deposit[beneficiary]`. This makes the
    /// function behavior predictable and idempotent. Can be called several
    /// times and on behalf of other accounts.
    /// @param beneficiary The account benefiting from the deposit
    /// @param new_total_deposit The total sum of tokens that have been
    /// deposited by the user by calling this function.
    function deposit(address beneficiary, uint256 new_total_deposit)
        external
    {
        require(new_total_deposit > total_deposit[beneficiary], "deposit not increasing");

        // Calculate the actual amount of tokens that will be transferred
        uint256 added_deposit = new_total_deposit - total_deposit[beneficiary];

        balances[beneficiary] += added_deposit;
        total_deposit[beneficiary] += added_deposit;

        // Update whole_balance, but take care against overflows.
        require(whole_balance + added_deposit >= whole_balance, "overflowing deposit");
        whole_balance += added_deposit;

        // Decline deposit if the whole balance is bigger than the limit.
        require(whole_balance <= whole_balance_limit, "too much deposit");

        // Actual transfer.
        require(token.transferFrom(msg.sender, address(this), added_deposit), "tokens didn't transfer");
    }

    /// @notice Internally transfer deposits between two addresses.
    /// Sender and receiver must be different or the transaction will fail.
    /// @param sender Account from which the amount will be deducted
    /// @param receiver Account to which the amount will be credited
    /// @param amount Amount of tokens to be transferred
    /// @return success true if transfer has been done successfully, otherwise false
    function transfer(
        address sender,
        address receiver,
        uint256 amount
    )
        canTransfer()
        external
        returns (bool success)
    {
        require(sender != receiver, "sender == receiver");
        if (balances[sender] >= amount && amount > 0) {
            balances[sender] -= amount;
            balances[receiver] += amount;
            emit BalanceReduced(sender, balances[sender]);
            return true;
        } else {
            return false;
        }
    }

    /// @notice Announce intention to withdraw tokens.
    /// Sets the planned withdraw amount and resets the withdraw_block.
    /// There is only one planned withdrawal at a time, the old one gets overwritten.
    /// @param amount Maximum amount of tokens to be withdrawn
    function planWithdraw(uint256 amount)
        external
    {
        require(amount > 0, "withdrawing zero");
        require(balances[msg.sender] >= amount, "withdrawing too much");

        withdraw_plans[msg.sender] = WithdrawPlan({
            amount: amount,
            withdraw_block: block.number + withdraw_delay
        });
        emit WithdrawPlanned(msg.sender, balances[msg.sender] - amount);
    }

    /// @notice Execute a planned withdrawal
    /// Will only work after the withdraw_delay has expired.
    /// An amount lower or equal to the planned amount may be withdrawn.
    /// Removes the withdraw plan even if not the full amount has been
    /// withdrawn.
    /// @param amount Amount of tokens to be withdrawn
    function withdraw(uint256 amount)
        external
    {
        WithdrawPlan storage withdraw_plan = withdraw_plans[msg.sender];
        require(amount <= withdraw_plan.amount, "withdrawing more than planned");
        require(withdraw_plan.withdraw_block <= block.number, "withdrawing too early");
        uint256 withdrawable = min(amount, balances[msg.sender]);
        balances[msg.sender] -= withdrawable;

        // Update whole_balance, but take care against underflows.
        require(whole_balance - withdrawable <= whole_balance, "underflow in whole_balance");
        whole_balance -= withdrawable;

        emit BalanceReduced(msg.sender, balances[msg.sender]);
        delete withdraw_plans[msg.sender];

        require(token.transfer(msg.sender, withdrawable), "tokens didn't transfer");
    }

    /// @notice The owner's balance with planned withdrawals deducted
    /// @param owner Address for which the balance should be returned
    /// @return remaining_balance The remaining balance after planned withdrawals
    function effectiveBalance(address owner)
        external
        view
        returns (uint256 remaining_balance)
    {
        WithdrawPlan storage withdraw_plan = withdraw_plans[owner];
        if (withdraw_plan.amount > balances[owner]) {
            return 0;
        }
        return balances[owner] - withdraw_plan.amount;
    }

    function min(uint256 a, uint256 b) pure internal returns (uint256)
    {
        return a > b ? b : a;
    }
}


// MIT License

// Copyright (c) 2018

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

contract MonitoringService is Utils {
    // Token to be used for paying the rewards
    Token public token;

    // Raiden Service Bundle contract to use for checking if MS has deposits
    ServiceRegistry public service_registry;
    UserDeposit public user_deposit;
    TokenNetworkRegistry public token_network_registry;

    // keccak256(channel_identifier, token_network_address) => Struct
    // Keep track of the rewards per channel
    mapping(bytes32 => Reward) internal rewards;

    /*
     *  Structs
     */
    struct Reward{
        // The amount of tokens to be rewarded
        uint256 reward_amount;

        // Nonce of the most recently provided BP
        uint256 nonce;

        // Address of the Raiden Node that was monitored
        // This is also the address that has the reward deducted from its deposit
        address reward_sender_address;

        // Address of the Monitoring Service who is currently eligible to claim the reward
        address monitoring_service_address;
    }

    /*
     *  Events
     */

    event NewBalanceProofReceived(
        address token_network_address,
        uint256 channel_identifier,
        uint256 reward_amount,
        uint256 indexed nonce,
        address indexed ms_address,
        address indexed raiden_node_address
    );
    event RewardClaimed(address indexed ms_address, uint amount, bytes32 indexed reward_identifier);

    /*
     *  Constructor
     */

    /// @notice Set the default values for the smart contract
    /// @param _token_address The address of the token to use for rewards
    /// @param _service_registry_address The address of the ServiceRegistry contract
    /// @param _token_network_registry_address The address of the TokenNetworkRegistry for authenticating TokenNetworks
    constructor(
        address _token_address,
        address _service_registry_address,
        address _udc_address,
        address _token_network_registry_address
    )
        public
    {
        require(_token_address != address(0x0), "Token at address zero");
        require(_service_registry_address != address(0x0), "ServiceRegistry at address zero");
        require(_udc_address != address(0x0), "UDC at address zero");
        require(contractExists(_token_address), "token has no code");
        require(contractExists(_service_registry_address), "ServiceRegistry has no code");
        require(contractExists(_udc_address), "UDC has no code");
        require(contractExists(_token_network_registry_address), "TokenNetworkRegistry has no code");

        token = Token(_token_address);
        service_registry = ServiceRegistry(_service_registry_address);
        user_deposit = UserDeposit(_udc_address);
        token_network_registry = TokenNetworkRegistry(_token_network_registry_address);
        // Check if the contract is indeed a token contract
        require(token.totalSupply() > 0, "Token with zero total supply");
        // Check if the contract is indeed a service_registry contract
        // TODO: Check that some function exists in the contract
    }

    /// @notice Internal function that updates the Reward struct if a newer balance proof
    /// is provided in the monitor() function
    /// @param token_network_address Address of the TokenNetwork being monitored
    /// @param closing_participant The address of the participant who closed the channel
    /// @param non_closing_participant Address of the other channel participant. This is
    /// the participant on whose behalf the MS acts.
    /// @param reward_amount The amount of tokens to be rewarded
    /// @param nonce The nonce of the newly provided balance_proof
    /// @param monitoring_service_address The address of the MS calling monitor()
    /// @param non_closing_signature Non-closing participant signature of the
    /// balance proof data.
    /// @param reward_proof_signature The signature of the signed reward proof
    function updateReward(
        address token_network_address,
        address closing_participant,
        address non_closing_participant,
        uint256 reward_amount,
        uint256 nonce,
        address monitoring_service_address,
        bytes memory non_closing_signature,
        bytes memory reward_proof_signature
    )
        internal
    {
        TokenNetwork token_network = TokenNetwork(token_network_address);
        address token_network_token = address(token_network.token());
        require(
            token_network_registry.token_to_token_networks(token_network_token) ==
            address(token_network),
            "Unknown TokenNetwork"
        );
        uint256 channel_identifier = token_network.getChannelIdentifier(
            closing_participant, non_closing_participant
        );

        // Make sure that the reward proof is signed by the non_closing_participant
        address raiden_node_address = recoverAddressFromRewardProof(
            token_network.chain_id(),
            token_network_address,
            non_closing_participant,
            non_closing_signature,
            reward_amount,
            reward_proof_signature
        );
        require(raiden_node_address == non_closing_participant, "Bad reward proof");

        bytes32 reward_identifier = keccak256(abi.encodePacked(
            channel_identifier,
            token_network_address
        ));

        // Get the Reward struct for the correct channel
        Reward storage reward = rewards[reward_identifier];

        // Only allow BPs with higher nonce to be submitted
        require(reward.nonce < nonce, "stale nonce");

        // MSC stores channel_identifier, MS_address, reward_amount, nonce
        // of the MS that provided the balance_proof with highest nonce
        rewards[reward_identifier] = Reward({
            reward_amount: reward_amount,
            nonce: nonce,
            reward_sender_address: non_closing_participant,
            monitoring_service_address: monitoring_service_address
        });
    }

    /// @notice Called by a registered MS, when providing a new balance proof
    /// to a monitored channel.
    /// Can be called multiple times by different registered MSs as long as the BP provided
    /// is newer than the current newest registered BP.
    /// @param nonce Strictly monotonic value used to order BPs
    /// omitting PB specific params, since these will not be provided in the future
    /// @param reward_amount Amount of tokens to be rewarded
    /// @param token_network_address Address of the Token Network in which the channel
    /// being monitored exists.
    /// @param reward_proof_signature The signature of the signed reward proof
    function monitor(
        address closing_participant,
        address non_closing_participant,
        bytes32 balance_hash,
        uint256 nonce,
        bytes32 additional_hash,
        bytes memory closing_signature,
        bytes memory non_closing_signature,
        uint256 reward_amount,
        address token_network_address,
        bytes memory reward_proof_signature
    )
        public
    {
        // Here we're trying to do bookkeeping first, but updateReward() first calls
        // token_network_address.  So reentrancy is possible.
        // In that case, the outer frame fails and reverts the state
        // because token_network_address is not registered in the token_network_registry.
        //
        // Maybe it's simpler and safer to take the token address as an argument instead,
        // and ask the TokenNetworkRegistry for the token_network_address.
        updateReward(
            token_network_address,
            closing_participant,
            non_closing_participant,
            reward_amount,
            nonce,
            msg.sender,
            non_closing_signature,
            reward_proof_signature
        );

        TokenNetwork token_network = TokenNetwork(token_network_address);
        uint256 channel_identifier = token_network.getChannelIdentifier(
            closing_participant, non_closing_participant
        );
        require(isAllowedToMonitor(
            token_network, channel_identifier,
            closing_participant, non_closing_participant, msg.sender
        ), "not allowed to monitor");

        // Call updateTransfer in the corresponding TokenNetwork
        token_network.updateNonClosingBalanceProof(
            channel_identifier,
            closing_participant,
            non_closing_participant,
            balance_hash,
            nonce,
            additional_hash,
            closing_signature,
            non_closing_signature
        );

        emit NewBalanceProofReceived(
            token_network_address,
            channel_identifier,
            reward_amount,
            nonce,
            msg.sender,
            non_closing_participant
        );
    }

    function isAllowedToMonitor(
        TokenNetwork token_network,
        uint256 channel_identifier,
        address closing_participant,
        address non_closing_participant,
        address monitoring_service_address
    )
        internal
        returns (bool)
    {
        require(service_registry.hasValidRegistration(monitoring_service_address), "service not registered");

        TokenNetwork.ChannelState channel_state;
        uint256 settle_block_number;
        (settle_block_number, channel_state) = token_network.getChannelInfo(
            channel_identifier, closing_participant, non_closing_participant
        );
        require(channel_state == TokenNetwork.ChannelState.Closed, "channel not closed");

        // We don't actually know when the channel has been closed. So we'll
        // make a guess so that assumed_close_block >= real_close_block.
        uint256 assumed_settle_timeout = token_network.settlement_timeout_min();
        require(settle_block_number >= assumed_settle_timeout, "too low settle block number");
        uint256 assumed_close_block = settle_block_number - assumed_settle_timeout;

        return block.number >= firstBlockAllowedToMonitor(
            assumed_close_block,
            assumed_settle_timeout,
            closing_participant,
            non_closing_participant,
            monitoring_service_address
        );
    }

    function firstBlockAllowedToMonitor(
        uint256 closed_at_block,
        uint256 settle_timeout,
        address participant1,
        address participant2,
        address monitoring_service_address
    )
        public pure
        returns (uint256)
    {
        // avoid overflows when multiplying with percentages
        require(settle_timeout < uint256(2**256 - 1) / 100, "maliciously big settle timeout");
        require(closed_at_block < uint256(2**256 - 1) / 100, "maliciously big closed_at_block");

        // First allowed block as percentage of settle_timeout. We're using
        // integers here to avoid accuracy loss during calculations.
        uint256 BEST_CASE = 30;
        uint256 WORST_CASE = 80;

        // When is the first block that any MS might be allowed to monitor
        uint256 best_case_block = closed_at_block + BEST_CASE * settle_timeout / 100;
        // Length of the range into which the first allowed block will fall
        uint256 range_length = (WORST_CASE - BEST_CASE) * settle_timeout / 100;

        // Offset for this specific MS within the range
        uint256 ms_offset = (
            uint256(participant1)
            + uint256(participant2)
            + uint256(monitoring_service_address)
        ) % range_length;

        return best_case_block + ms_offset;
    }

    /// @notice Called after a monitored channel is settled in order for MS to claim the reward
    /// Can be called once per settled channel by everyone on behalf of MS
    /// @param token_network_address Address of the Token Network in which the channel exists
    /// @param closing_participant Address of the participant of the channel that called close
    /// @param non_closing_participant The other participant of the channel
    function claimReward(
        uint256 channel_identifier,
        address token_network_address,
        address closing_participant,
        address non_closing_participant
    )
        public
        returns (bool)
    {
        TokenNetwork token_network = TokenNetwork(token_network_address);
        bytes32 reward_identifier = keccak256(abi.encodePacked(
            channel_identifier,
            token_network_address
        ));

        // Only allowed to claim, if channel is settled
        // Channel is settled if it's data has been deleted
        TokenNetwork.ChannelState channel_state;
        uint256 settle_block_number;
        (settle_block_number, channel_state) = token_network.getChannelInfo(
            channel_identifier,
            closing_participant,
            non_closing_participant
        );
        // We are trying to figure out when the settlement period ends.
        // The meaning of settle_block_number is totally different depending on channel_state.
        // When channel_state is NonExistent, settle_block_number is zero so it's not useful.
        // When channel_state is Open, settle_block_number is the length of the settlement period.
        // In these cases, we don't want to proceed anyway because the settlement period has not even started.
        // We can only proceed with these other channel states.
        require(channel_state == TokenNetwork.ChannelState.Closed ||
            channel_state == TokenNetwork.ChannelState.Settled ||
            channel_state == TokenNetwork.ChannelState.Removed, "too early channel state");
        require(settle_block_number < block.number, "channel not settled yet");

        Reward storage reward = rewards[reward_identifier];

        // Make sure that the Reward exists
        require(reward.reward_sender_address != address(0x0), "reward_sender is zero");

        // Add reward to the monitoring service's balance
        require(user_deposit.transfer(
            reward.reward_sender_address,
            reward.monitoring_service_address,
            reward.reward_amount
        ), "UDC did not transfer");

        emit RewardClaimed(
            reward.monitoring_service_address,
            reward.reward_amount,
            reward_identifier
        );

        // delete storage
        delete rewards[reward_identifier];

        return true;
    }

    function recoverAddressFromRewardProof(
        uint256 chain_id,
        address token_network_address,
        address non_closing_participant,
        bytes memory non_closing_signature,
        uint256 reward_amount,
        bytes memory signature
    )
        internal
        view
        returns (address signature_address)
    {
        // This message shows the intention of the signer to pay
        // a reward to a Monitoring Service, provided that the
        // call of updateNonClosingBalanceProof() succeeds.
        // The triple (non_closing_participant, non_closing_signature, token_network_address)
        // uniquely identifies the call that's supposed to be made.
        // (Just checking non_closing_signature is not enough because
        // when an attacker tampers with the payload, the signature
        // verification doesn't fail but emits a different address.)
        // (Without a token_network, there will be some ambiguity
        // what the payload means.)
        bytes32 message_hash = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n221",  // 20 + 32 + 32 + 20 + 20 + 65 + 32
            address(this),
            chain_id,
            uint256(MessageTypeId.MSReward),
            token_network_address,
            non_closing_participant,
            non_closing_signature,
            reward_amount
        ));

        signature_address = ECVerify.ecverify(message_hash, signature);
        require(signature_address == non_closing_participant, "Reward proof with wrong non_closing_participant");
    }
}


// MIT License

// Copyright (c) 2018

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.