/**
 *Submitted for verification at Etherscan.io on 2019-07-04
*/

pragma solidity 0.4.24;

library RLPReader {

    uint8 constant STRING_SHORT_START = 0x80;
    uint8 constant STRING_LONG_START = 0xb8;
    uint8 constant LIST_SHORT_START = 0xc0;
    uint8 constant LIST_LONG_START = 0xf8;
    uint8 constant WORD_SIZE = 32;

    struct RLPItem {
        uint len;
        uint memPtr;
    }

    using RLPReader for bytes;
    using RLPReader for uint;
    using RLPReader for RLPReader.RLPItem;

    // helper function to decode rlp encoded  ethereum transaction
    /*
    * @param raw_transaction RLP encoded ethereum transaction
    * @return tuple (nonce,gas_price,gas_limit,to,value,data)
    */

    function decode_transaction(bytes memory raw_transaction) public pure returns (uint, uint, uint, address, uint, bytes memory){
        RLPReader.RLPItem[] memory values = raw_transaction.toRlpItem().toList(); // must convert to an rlpItem first!
        return (values[0].toUint(), values[1].toUint(), values[2].toUint(), values[3].toAddress(), values[4].toUint(), values[5].toBytes());
    }

    function bytesToBytes32(bytes memory b, uint offset) private pure returns (bytes32) {
        bytes32 out;
        for (uint i = 0; i < 32; i++) {
            out |= bytes32(b[offset + i] & 0xFF) >> (i * 8);
        }
        return out;
    }

    /*
    * @param item RLP encoded bytes
    */
    function toRlpItem(bytes memory item) internal pure returns (RLPItem memory) {
        if (item.length == 0)
            return RLPItem(0, 0);
        uint memPtr;
        assembly {
            memPtr := add(item, 0x20)
        }
        return RLPItem(item.length, memPtr);
    }
    /*
    * @param item RLP encoded list in bytes
    */
    function toList(RLPItem memory item) internal pure returns (RLPItem[] memory result) {
        require(isList(item), "isList failed");
        uint items = numItems(item);
        result = new RLPItem[](items);
        uint memPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint dataLen;
        for (uint i = 0; i < items; i++) {
            dataLen = _itemLength(memPtr);
            result[i] = RLPItem(dataLen, memPtr);
            memPtr = memPtr + dataLen;
        }
    }
    /*
    * Helpers
    */
    // @return indicator whether encoded payload is a list. negate this function call for isData.
    function isList(RLPItem memory item) internal pure returns (bool) {
        uint8 byte0;
        uint memPtr = item.memPtr;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }
        if (byte0 < LIST_SHORT_START)
            return false;
        return true;
    }
    // @return number of payload items inside an encoded list.
    function numItems(RLPItem memory item) internal pure returns (uint) {
        uint count = 0;
        uint currPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint endPtr = item.memPtr + item.len;
        while (currPtr < endPtr) {
            currPtr = currPtr + _itemLength(currPtr);
            // skip over an item
            count++;
        }
        return count;
    }
    // @return entire rlp item byte length
    function _itemLength(uint memPtr) internal pure returns (uint len) {
        uint byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }
        if (byte0 < STRING_SHORT_START)
            return 1;
        else if (byte0 < STRING_LONG_START)
            return byte0 - STRING_SHORT_START + 1;
        else if (byte0 < LIST_SHORT_START) {
            assembly {
                let byteLen := sub(byte0, 0xb7) // # of bytes the actual length is
                memPtr := add(memPtr, 1) // skip over the first byte
            /* 32 byte word size */
                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to get the len
                len := add(dataLen, add(byteLen, 1))
            }
        }
        else if (byte0 < LIST_LONG_START) {
            return byte0 - LIST_SHORT_START + 1;
        }
        else {
            assembly {
                let byteLen := sub(byte0, 0xf7)
                memPtr := add(memPtr, 1)
                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to the correct length
                len := add(dataLen, add(byteLen, 1))
            }
        }
    }
    // @return number of bytes until the data
    function _payloadOffset(uint memPtr) internal pure returns (uint) {
        uint byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }
        if (byte0 < STRING_SHORT_START)
            return 0;
        else if (byte0 < STRING_LONG_START || (byte0 >= LIST_SHORT_START && byte0 < LIST_LONG_START))
            return 1;
        else if (byte0 < LIST_SHORT_START)  // being explicit
            return byte0 - (STRING_LONG_START - 1) + 1;
        else
            return byte0 - (LIST_LONG_START - 1) + 1;
    }
    /** RLPItem conversions into data types **/
    // @returns raw rlp encoding in bytes
    function toRlpBytes(RLPItem memory item) internal pure returns (bytes memory) {
        bytes memory result = new bytes(item.len);
        uint ptr;
        assembly {
            ptr := add(0x20, result)
        }
        copy(item.memPtr, ptr, item.len);
        return result;
    }

    function toBoolean(RLPItem memory item) internal pure returns (bool) {
        require(item.len == 1, "Invalid RLPItem. Booleans are encoded in 1 byte");
        uint result;
        uint memPtr = item.memPtr;
        assembly {
            result := byte(0, mload(memPtr))
        }
        return result == 0 ? false : true;
    }

    function toAddress(RLPItem memory item) internal pure returns (address) {
        // 1 byte for the length prefix according to RLP spec
        require(item.len <= 21, "Invalid RLPItem. Addresses are encoded in 20 bytes or less");
        return address(toUint(item));
    }

    function toUint(RLPItem memory item) internal pure returns (uint) {
        uint offset = _payloadOffset(item.memPtr);
        uint len = item.len - offset;
        uint memPtr = item.memPtr + offset;
        uint result;
        assembly {
            result := div(mload(memPtr), exp(256, sub(32, len))) // shift to the correct location
        }
        return result;
    }

    function toBytes(RLPItem memory item) internal pure returns (bytes memory) {
        uint offset = _payloadOffset(item.memPtr);
        uint len = item.len - offset;
        // data length
        bytes memory result = new bytes(len);
        uint destPtr;
        assembly {
            destPtr := add(0x20, result)
        }
        copy(item.memPtr + offset, destPtr, len);
        return result;
    }
    /*
    * @param src Pointer to source
    * @param dest Pointer to destination
    * @param len Amount of memory to copy from the source
    */
    function copy(uint src, uint dest, uint len) internal pure {
        // copy as many word sizes as possible
        for (; len >= WORD_SIZE; len -= WORD_SIZE) {
            assembly {
                mstore(dest, mload(src))
            }
            src += WORD_SIZE;
            dest += WORD_SIZE;
        }
        // left over bytes. Mask is used to remove unwanted bytes from the word
        uint mask = 256 ** (WORD_SIZE - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask)) // zero out src
            let destpart := and(mload(dest), mask) // retrieve the bytes
            mstore(dest, or(destpart, srcpart))
        }
    }
}

contract RelayRecipientApi {

    /**
     * return the relayHub of this contract.
     */
    function get_hub_addr() public view returns (address);

    /**
     * return the contract&#39;s balance on the RelayHub.
     * can be used to determine if the contract can pay for incoming calls,
     * before making any.
     */
    function get_recipient_balance() public view returns (uint);
}

contract  RelayHubApi {

    event Staked(address indexed relay, uint stake);
    event Unstaked(address indexed relay, uint stake);

    /* RelayAdded is emitted whenever a relay [re-]registers with the RelayHub.
     * filtering on these events (and filtering out RelayRemoved events) lets the client
     * find which relays are currently registered.
     */
    event RelayAdded(address indexed relay, address indexed owner, uint transactionFee, uint stake, uint unstakeDelay, string url);

    // emitted when a relay is removed
    event RelayRemoved(address indexed relay, uint unstake_time);

    /**
     * this events is emited whenever a transaction is relayed.
     * notice that the actual function call on the target contract might be reverted - in that case, the "success"
     * flag will be set to false.
     * the client uses this event so it can report correctly transaction complete (or revert) to the application.
     * Monitoring tools can use this event to detect liveliness of clients and relays.
     */
    event TransactionRelayed(address indexed relay, address indexed from, address indexed target, bytes32 hash, bool success, uint charge);
    event Deposited(address src, uint amount);
    event Withdrawn(address dest, uint amount);
    event Penalized(address indexed relay, address sender, uint amount);

    function get_nonce(address from) view external returns (uint);
    function relay(address from, address to, bytes memory encoded_function, uint transaction_fee, uint gas_price, uint gas_limit, uint nonce, bytes memory sig) public;
    
    function depositFor(address target) public payable;
    function balanceOf(address target) external view returns (uint256);

    function stake(address relayaddr, uint unstake_delay) external payable;
    function stakeOf(address relayaddr) external view returns (uint256);
    function ownerOf(address relayaddr) external view returns (address);
}

contract RelayHub is RelayHubApi {

    // Anyone can call certain functions in this singleton and trigger relay processes.

    uint constant timeout = 5 days; // XXX TBD
    uint constant minimum_stake = 1;    // XXX TBD
    uint constant minimum_unstake_delay = 0;    // XXX TBD
    uint constant minimum_relay_balance = 0.5 ether;  // XXX TBD - can&#39;t register/refresh below this amount.
    uint constant low_ether = 1 ether;    // XXX TBD - relay still works, but owner should be notified to fund the relay soon.
    uint constant public gas_reserve = 99999; // XXX TBD - calculate how much reserve we actually need, to complete the post-call part of relay().
    uint constant public gas_overhead = 47382;  // the total gas overhead of relay(), before the first gasleft() and after the last gasleft(). Assume that relay has non-zero balance (costs 15&#39;000 more otherwise).

    mapping (address => uint) public nonces;    // Nonces of senders, since their ether address nonce may never change.

    struct Relay {
        uint timestamp;
        uint transaction_fee;
    }

    mapping (address => Relay) public relays;

    struct Stake {
        uint stake;             // Size of the stake
        uint unstake_delay;     // How long between removal and unstaking
        uint unstake_time;      // When is the stake released.  Non-zero means that the relay has been removed and is waiting for unstake.
        address owner;
        bool removed;
    }

    mapping (address => Stake) public stakes;
    mapping (address => uint) public balances;

    function validate_stake(address relay) private view {
        require(stakes[relay].stake >= minimum_stake,"stake lower than minimum");  // Has enough stake?
        require(stakes[relay].unstake_delay >= minimum_unstake_delay,"delay lower than minimum");  // Locked for enough time?
    }
    modifier lock_stake() {
        validate_stake(msg.sender);
        require(msg.sender.balance >= minimum_relay_balance,"balance lower than minimum");
        stakes[msg.sender].unstake_time = 0;    // Activate the lock
        _;
    }

    function safe_add(uint a, uint b) internal pure returns (uint) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function safe_sub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function get_nonce(address from) view external returns (uint) {
        return nonces[from];
    }

    /**
     * deposit ether for a contract.
     * This ether will be used to repay relay calls into this contract.
     * Contract owner should monitor the balance of his contract, and make sure
     * to deposit more, otherwise the contract won&#39;t be able to receive relayed calls.
     * Unused deposited can be withdrawn with `withdraw()`
     */
    function depositFor(address target) public payable {
        balances[target] += msg.value;
        require (balances[target] >= msg.value);
        emit Deposited(target, msg.value);
    }

    function deposit() public payable {
        depositFor(msg.sender);
    }

    /**
     * withdraw funds.
     * caller is either a relay owner, withdrawing collected transaction fees.
     * or a RelayRecipient contract, withdrawing its deposit.
     * note that while everyone can `depositFor()` a contract, only
     * the contract itself can withdraw its funds.
     */
    function withdraw(uint amount) public {
        require(balances[msg.sender] >= amount, "insufficient funds");
        balances[msg.sender] -= amount;
        msg.sender.transfer(amount);
        emit Withdrawn(msg.sender, amount);
    }

    //check the deposit balance of a contract.
    function balanceOf(address target) external view returns (uint256) {
        return balances[target];
    }

    function stakeOf(address relay) external view returns (uint256) {
        return stakes[relay].stake;
    }

    function ownerOf(address relay) external view returns (address) {
        return stakes[relay].owner;
    }


    function stake(address relay, uint unstake_delay) external payable {
        // Create or increase the stake and unstake_delay
        require(stakes[relay].owner == address(0) || stakes[relay].owner == msg.sender, "not owner");
        stakes[relay].owner = msg.sender;
        stakes[relay].stake += msg.value;
        // Make sure that the relay doesn&#39;t decrease his delay if already registered
        require(unstake_delay >= stakes[relay].unstake_delay, "unstake_delay cannot be decreased");
        stakes[relay].unstake_delay = unstake_delay;
        validate_stake(relay);
        emit Staked(relay, msg.value);
    }

    function can_unstake(address relay) public view returns(bool) {
        // Only owner can unstake
        if (stakes[relay].owner != msg.sender) {
            return false;
        }
        if (relays[relay].timestamp != 0 || stakes[relay].unstake_time == 0)  // Relay still registered so unstake time hasn&#39;t been set
            return false;
        return stakes[relay].unstake_time <= now;  // Finished the unstaking delay period?
    }

    modifier unstake_allowed(address relay) {
        require(can_unstake(relay));
        _;
    }

    function unstake(address relay) public unstake_allowed(relay) {
        uint amount = stakes[relay].stake;
        msg.sender.transfer(stakes[relay].stake);
        delete stakes[relay];
        emit Unstaked(relay, amount);
    }

    function register_relay(uint transaction_fee, string memory url, address optional_relay_removal) public lock_stake {
        // Anyone with a stake can register a relay.  Apps choose relays by their transaction fee, stake size and unstake delay,
        // optionally crossed against a blacklist.  Apps verify the relay&#39;s action in realtime.

        Stake storage relay_stake = stakes[msg.sender];
        // Penalized relay cannot reregister
        require(!relay_stake.removed, "Penalized relay cannot reregister");
        relays[msg.sender] = Relay(now, transaction_fee);
        emit RelayAdded(msg.sender, relay_stake.owner, transaction_fee, relay_stake.stake, relay_stake.unstake_delay, url);

        // @optional_relay_removal is unrelated to registration, but incentivizes relays to help purging stale relays from the list.
        // Providing a stale relay will cause its removal, and offset the gas price of registration.
        if (optional_relay_removal != address(0))
            remove_stale_relay(optional_relay_removal);
    }

    function remove_relay_internal(address relay) internal {
        delete relays[relay];
        stakes[relay].unstake_time = stakes[relay].unstake_delay + now;   // Start the unstake counter
        stakes[relay].removed = true;
        emit RelayRemoved(relay, stakes[relay].unstake_time);
    }

    function remove_stale_relay(address relay) public { // Trustless, assumed to be called by anyone willing to pay for the gas.  Verifies staleness.  Normally called by relays to keep the list current.
        require(relays[relay].timestamp != 0, "not a relay");  // Relay exists?
        require(relays[relay].timestamp + timeout < now, "not stale");  // Did relay send a keeplive recently?
        // Anyone can remove a stale relay.
        remove_relay_internal(relay);
    }

    modifier relay_owner(address relay) {
        require(stakes[relay].owner == msg.sender, "not owner");
        _;
    }

    function remove_relay_by_owner(address relay) public relay_owner(relay) {
        // The relay&#39;s owner can remove it at any time, to start the unstake countdown.
        remove_relay_internal(relay);
    }

    function check_sig(address signer, bytes32 hash, bytes memory sig) pure internal returns (bool) {
        // Check if @v,@r,@s are a valid signature of @signer for @hash
        return signer == ecrecover(hash, uint8(sig[0]), bytesToBytes32(sig,1), bytesToBytes32(sig,33));
    }

    //check if the Hub can accept this relayed operation.
    // it validates the caller&#39;s signature and nonce, and then delegates to the destination&#39;s accept_relayed_call
    // for contract-specific checks.
    // returns "0" if the relay is valid. other values represent errors.
    // values 1..10 are reserved for can_relay. other values can be used by accept_relayed_call of target contracts.
    function can_relay(address relay, address from, RelayRecipient to, bytes memory transaction, uint transaction_fee, uint gas_price, uint gas_limit, uint nonce, bytes memory sig) public view returns(uint32) {
        bytes memory packed = abi.encodePacked("rlx:", from, to, transaction, transaction_fee, gas_price, gas_limit, nonce, address(this));
        bytes32 hashed_message = keccak256(abi.encodePacked(packed, relay));
        bytes32 signed_message = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hashed_message));
        if (!check_sig(from, signed_message,  sig))  // Verify the sender&#39;s signature on the transaction
            return 1;   // @from hasn&#39;t signed the transaction properly
        if (nonces[from] != nonce)
            return 2;   // Not a current transaction.  May be a replay attempt.
        // XXX check @to&#39;s balance, roughly estimate if it has enough balance to pay the transaction fee.  It&#39;s the relay&#39;s responsibility to verify, but check here too.
        return to.accept_relayed_call(relay, from, transaction, gas_price, transaction_fee); // Check to.accept_relayed_call, see if it agrees to accept the charges.
    }

    /**
     * relay a transaction.
     * @param from the client originating the request.
     * @param to the target RelayRecipient contract.
     * @param encoded_function the function call to relay.
     * @param transaction_fee fee (%) the relay takes over actual gas cost.
     * @param gas_price gas price the client is willing to pay
     * @param gas_limit limit the client want to put on its transaction
     * @param transaction_fee fee (%) the relay takes over actual gas cost.
     * @param nonce sender&#39;s nonce (in nonces[])
     * @param sig client&#39;s signature over all params
     */
    function relay(address from, address to, bytes memory encoded_function, uint transaction_fee, uint gas_price, uint gas_limit, uint nonce, bytes memory sig) public {
        uint initial_gas = gasleft();
        require(relays[msg.sender].timestamp > 0, "Unknown relay");  // Must be from a known relay
        require(gas_price <= tx.gasprice, "Invalid gas price");      // Relay must use the gas price set by the signer
        relays[msg.sender].timestamp = now;

        require(0 == can_relay(msg.sender, from, RelayRecipient(to), encoded_function, transaction_fee, gas_price, gas_limit, nonce, sig), "can_relay failed");

        // ensure that the last bytes of @transaction are the @from address.
        // Recipient will trust this reported sender when msg.sender is the known RelayHub.
        bytes memory transaction = abi.encodePacked(encoded_function,from);

        // gas_reserve must be high enough to complete relay()&#39;s post-call execution.
        require(safe_sub(initial_gas,gas_limit) >= gas_reserve, "Not enough gasleft()");
        bool success = executeCallWithGas(gas_limit, to, 0, transaction); // transaction must end with @from at this point
        nonces[from]++;
        RelayRecipient(to).post_relayed_call(msg.sender, from, encoded_function, success, (gas_overhead+initial_gas-gasleft()), transaction_fee );
        // Relay transaction_fee is in %.  E.g. if transaction_fee=40, payment will be 1.4*used_gas.
        uint charge = (gas_overhead+initial_gas-gasleft())*gas_price*(100+transaction_fee)/100;
        emit TransactionRelayed(msg.sender, from, to, keccak256(encoded_function), success, charge);
        require(balances[to] >= charge, "insufficient funds");
        balances[to] -= charge;
        balances[stakes[msg.sender].owner] += charge;
    }

    function executeCallWithGas(uint allowed_gas, address to, uint256 value, bytes memory data) internal returns (bool success) {
        assembly {
            success := call(allowed_gas, to, value, add(data, 0x20), mload(data), 0, 0)
        }
    }

    struct Transaction {
        uint nonce;
        uint gas_price;
        uint gas_limit;
        address to;
        uint value;
        bytes data;
    }

    function decode_transaction (bytes memory raw_transaction) private pure returns ( Transaction memory transaction) {
        (transaction.nonce,transaction.gas_price,transaction.gas_limit,transaction.to, transaction.value, transaction.data) = RLPReader.decode_transaction(raw_transaction);
        return transaction;

    }

    function penalize_repeated_nonce(bytes memory unsigned_tx1, bytes memory sig1 ,bytes memory unsigned_tx2, bytes memory sig2) public {
        // Can be called by anyone.  
        // If a relay attacked the system by signing multiple transactions with the same nonce (so only one is accepted), anyone can grab both transactions from the blockchain and submit them here.
        // Check whether unsigned_tx1 != unsigned_tx2, that both are signed by the same address, and that unsigned_tx1.nonce == unsigned_tx2.nonce.  If all conditions are met, relay is considered an "offending relay".
        // The offending relay will be unregistered immediately, its stake will be forfeited and given to the address who reported it (msg.sender), thus incentivizing anyone to report offending relays.
        // If reported via a relay, the forfeited stake is split between msg.sender (the relay used for reporting) and the address that reported it.

        Transaction memory decoded_tx1 = decode_transaction(unsigned_tx1);
        Transaction memory decoded_tx2 = decode_transaction(unsigned_tx2);

        bytes32 hash1 = keccak256(abi.encodePacked(unsigned_tx1));
        address addr1 = ecrecover(hash1, uint8(sig1[0]), bytesToBytes32(sig1,1), bytesToBytes32(sig1,33));

        bytes32 hash2 = keccak256(abi.encodePacked(unsigned_tx2));
        address addr2 = ecrecover(hash2, uint8(sig2[0]), bytesToBytes32(sig2,1), bytesToBytes32(sig2,33));

        //checking that the same nonce is used in both transaction, with both signed by the same address and the actual data is different
        // note: we compare the hash of the data to save gas over iterating both byte arrays
        require( decoded_tx1.nonce == decoded_tx2.nonce, "Different nonce");
        require(addr1 == addr2, "Different signer");
        require(keccak256(abi.encodePacked(decoded_tx1.data)) != keccak256(abi.encodePacked(decoded_tx2.data)), "tx.data is equal" ) ;
        // Checking that we do have addr1 as a staked relay
        require( stakes[addr1].stake > 0, "Unstaked relay" );
        // Checking that the relay wasn&#39;t penalized yet
        require(!stakes[addr1].removed, "Relay already penalized");
        // compensating the sender with the stake of the relay
        uint amount = stakes[addr1].stake;
        // move ownership of relay
        stakes[addr1].owner = msg.sender;
        emit Penalized(addr1, msg.sender, amount);
        remove_relay_by_owner(addr1);
    }

    function bytesToBytes32(bytes memory b, uint offset) private pure returns (bytes32) {
        bytes32 out;
        for (uint i = 0; i < 32; i++) {
            out |= bytes32(b[offset + i] & 0xFF) >> (i * 8);
        }
        return out;
    }

}

contract RelayRecipient is RelayRecipientApi {

    RelayHub private relay_hub; // The RelayHub singleton which is allowed to call us

    function get_hub_addr() public view returns (address) {
        return address(relay_hub);
    }

    /**
     * initialize the relayhub.
     * contracts usually call this method from the constructor (using a constract RelayHub, or receiving
     * one in the constructor)
     * This method might also be called by the owner, in order to use a new RelayHub - since the RelayHub
     * itself is not an upgradable contract.
     */
    function init_relay_hub(RelayHub _rhub) internal {
        require(relay_hub == RelayHub(0), "init_relay_hub: rhub already set");
        set_relay_hub(_rhub);
    }
    
    function set_relay_hub(RelayHub _rhub) internal {
        // Normally called just once, during init_relay_hub.
        // Left as a separate internal function, in case a contract wishes to have its own update mechanism for RelayHub.
        relay_hub = _rhub;

        //attempt a read method, just to validate the relay is a valid RelayHub contract.
        get_recipient_balance();
    }

    function get_relay_hub() internal view returns (RelayHub) {
        return relay_hub;
    }

    /**
     * return the balance of this contract.
     * Note that this method will revert on configuration error (invalid relay address)
     */
    function get_recipient_balance() public view returns (uint) {
        return get_relay_hub().balanceOf(address(this));
    }

    function get_sender_from_data(address orig_sender, bytes memory msg_data) public view returns(address) {
        address sender = orig_sender;
        if (orig_sender == get_hub_addr() ) {
            // At this point we know that the sender is a trusted RelayHub, so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            bytes memory from = new bytes(20);
            for (uint256 i = 0; i < from.length; i++)
            {
                from[i] = msg_data[msg_data.length - from.length + i];
            }
            sender = bytesToAddress(from);
        }
        return sender;
    }

    function get_sender() public view returns(address) {
        return get_sender_from_data(msg.sender, msg.data);
    }

    function get_message_data() public view returns(bytes memory) {
        bytes memory orig_msg_data = msg.data;
        if (msg.sender == get_hub_addr()) {
            // At this point we know that the sender is a trusted RelayHub, so we trust that the last bytes of msg.data are the verified sender address.
            // extract original message data from the start of msg.data
            orig_msg_data = new bytes(msg.data.length - 20);
            for (uint256 i = 0; i < orig_msg_data.length; i++)
            {
                orig_msg_data[i] = msg.data[i];
            }
        }
        return orig_msg_data;
    }

    /*
     * Contract must inherit and re-implement this method.
     *  @return "0" if the the contract is willing to accept the charges from this sender, for this function call.
     *      any other value is a failure. actual value is for diagnostics only.
     *   values below 10 are reserved by can_relay
     *  @param relay the relay that attempts to relay this function call.
     *          the contract may restrict some encoded functions to specific known relays.
     *  @param from the sender (signer) of this function call.
     *  @param encoded_function the encoded function call (without any ethereum signature).
     *          the contract may check the method-id for valid methods
     *  @param gas_price - the gas price for this transaction
     *  @param transaction_fee - the relay compensation (in %) for this transaction
     */
    function accept_relayed_call(address relay, address from, bytes memory encoded_function, uint gas_price, uint transaction_fee ) public view returns(uint32);

    /**
     * This method is called after the relayed call.
     * It may be used to record the transaction (e.g. charge the caller by some contract logic) for this call.
     * the method is given all parameters of accept_relayed_call, and also the success/failure status and actual used gas.
     * - success - true if the relayed call succeeded, false if it reverted
     * - used_gas - gas used up to this point. Note that gas calculation (for the purpose of compensation
     *   to the relay) is done after this method returns.
     */
    function post_relayed_call(address relay, address from, bytes memory encoded_function, bool success, uint used_gas, uint transaction_fee ) public;

    function bytesToAddress(bytes memory b) private pure returns (address addr) {
        assembly {
            addr := mload(add(b,20))
        }
    }
}


contract ProofOfLove is RelayRecipient {
    
    uint32 public count = 0;

    event Love(string name1, string name2);

    constructor(address hubAddress) public {
        init_relay_hub(RelayHub(hubAddress));
    }

    function prove(string name1, string name2) external {
        count += 1;
        emit Love(name1, name2);
    }

    function accept_relayed_call(address relay, address from, bytes memory encoded_function, uint gas_price, uint transaction_fee)
    public view returns(uint32) {
        return 0;
    }

    function post_relayed_call(address relay, address from, bytes memory encoded_function, bool success, uint used_gas, uint transaction_fee)
    public {
    }

    function deposit()
    public payable {
        get_relay_hub().depositFor.value(msg.value)(address(this));
    }
}