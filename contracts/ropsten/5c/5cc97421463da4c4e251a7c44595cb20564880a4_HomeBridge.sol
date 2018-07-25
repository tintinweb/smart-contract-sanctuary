pragma solidity ^0.4.17;


/// general helpers.
/// `internal` so they get compiled into contracts using them.
library Helpers {
    /// returns whether `array` contains `value`.
    function addressArrayContains(address[] array, address value) internal pure returns (bool) {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == value) {
                return true;
            }
        }
        return false;
    }

    // returns the digits of `inputValue` as a string.
    // example: `uintToString(12345678)` returns `&quot;12345678&quot;`
    function uintToString(uint256 inputValue) internal pure returns (string) {
        // figure out the length of the resulting string
        uint256 length = 0;
        uint256 currentValue = inputValue;
        do {
            length++;
            currentValue /= 10;
        } while (currentValue != 0);
        // allocate enough memory
        bytes memory result = new bytes(length);
        // construct the string backwards
        uint256 i = length - 1;
        currentValue = inputValue;
        do {
            result[i--] = byte(48 + currentValue % 10);
            currentValue /= 10;
        } while (currentValue != 0);
        return string(result);
    }

    /// returns whether signatures (whose components are in `vs`, `rs`, `ss`)
    /// contain `requiredSignatures` distinct correct signatures
    /// where signer is in `allowed_signers`
    /// that signed `message`
    function hasEnoughValidSignatures(bytes message, uint8[] vs, bytes32[] rs, bytes32[] ss, address[] allowed_signers, uint256 requiredSignatures) internal pure returns (bool) {
        // not enough signatures
        if (vs.length < requiredSignatures) {
            return false;
        }

        var hash = MessageSigning.hashMessage(message);
        var encountered_addresses = new address[](allowed_signers.length);

        for (uint256 i = 0; i < requiredSignatures; i++) {
            var recovered_address = ecrecover(hash, vs[i], rs[i], ss[i]);
            // only signatures by addresses in `addresses` are allowed
            if (!addressArrayContains(allowed_signers, recovered_address)) {
                return false;
            }
            // duplicate signatures are not allowed
            if (addressArrayContains(encountered_addresses, recovered_address)) {
                return false;
            }
            encountered_addresses[i] = recovered_address;
        }
        return true;
    }

}


/// Library used only to test Helpers library via rpc calls
library HelpersTest {
    function addressArrayContains(address[] array, address value) public pure returns (bool) {
        return Helpers.addressArrayContains(array, value);
    }

    function uintToString(uint256 inputValue) public pure returns (string str) {
        return Helpers.uintToString(inputValue);
    }

    function hasEnoughValidSignatures(bytes message, uint8[] vs, bytes32[] rs, bytes32[] ss, address[] addresses, uint256 requiredSignatures) public pure returns (bool) {
        return Helpers.hasEnoughValidSignatures(message, vs, rs, ss, addresses, requiredSignatures);
    }
}


// helpers for message signing.
// `internal` so they get compiled into contracts using them.
library MessageSigning {
    function recoverAddressFromSignedMessage(bytes signature, bytes message) internal pure returns (address) {
        require(signature.length == 65);
        bytes32 r;
        bytes32 s;
        bytes1 v;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := mload(add(signature, 0x60))
        }
        return ecrecover(hashMessage(message), uint8(v), r, s);
    }

    function hashMessage(bytes message) internal pure returns (bytes32) {
        bytes memory prefix = &quot;\x19Ethereum Signed Message:\n&quot;;
        return keccak256(prefix, Helpers.uintToString(message.length), message);
    }
}


/// Library used only to test MessageSigning library via rpc calls
library MessageSigningTest {
    function recoverAddressFromSignedMessage(bytes signature, bytes message) public pure returns (address) {
        return MessageSigning.recoverAddressFromSignedMessage(signature, message);
    }
}


library Message {
    // layout of message :: bytes:
    // offset  0: 32 bytes :: uint256 (big endian) - message length (not part of message. any `bytes` begins with the length in memory)
    // offset 32: 20 bytes :: address - recipient address
    // offset 52: 32 bytes :: uint256 (big endian) - value
    // offset 84: 32 bytes :: bytes32 - transaction hash
    // offset 116: 32 bytes :: uint256 (big endian) - home gas price

    // mload always reads 32 bytes.
    // if mload reads an address it only interprets the last 20 bytes as the address.
    // so we can and have to start reading recipient at offset 20 instead of 32.
    // if we were to read at 32 the address would contain part of value and be corrupted.
    // when reading from offset 20 mload will ignore 12 bytes followed
    // by the 20 recipient address bytes and correctly convert it into an address.
    // this saves some storage/gas over the alternative solution
    // which is padding address to 32 bytes and reading recipient at offset 32.
    // for more details see discussion in:
    // https://github.com/paritytech/parity-bridge/issues/61

    function getRecipient(bytes message) internal pure returns (address) {
        address recipient;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            recipient := mload(add(message, 20))
        }
        return recipient;
    }

    function getValue(bytes message) internal pure returns (uint256) {
        uint256 value;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            value := mload(add(message, 52))
        }
        return value;
    }

    function getTransactionHash(bytes message) internal pure returns (bytes32) {
        bytes32 hash;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            hash := mload(add(message, 84))
        }
        return hash;
    }

    function getHomeGasPrice(bytes message) internal pure returns (uint256) {
        uint256 gasPrice;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            gasPrice := mload(add(message, 116))
        }
        return gasPrice;
    }
}


/// Library used only to test Message library via rpc calls
library MessageTest {
    function getRecipient(bytes message) public pure returns (address) {
        return Message.getRecipient(message);
    }

    function getValue(bytes message) public pure returns (uint256) {
        return Message.getValue(message);
    }

    function getTransactionHash(bytes message) public pure returns (bytes32) {
        return Message.getTransactionHash(message);
    }

    function getHomeGasPrice(bytes message) public pure returns (uint256) {
        return Message.getHomeGasPrice(message);
    }
}


contract HomeBridge {
    /// Number of authorities signatures required to withdraw the money.
    ///
    /// Must be lesser than number of authorities.
    uint256 public requiredSignatures;

    /// The gas cost of calling `HomeBridge.withdraw`.
    ///
    /// Is subtracted from `value` on withdraw.
    /// recipient pays the relaying authority for withdraw.
    /// this shuts down attacks that exhaust authorities funds on home chain.
    uint256 public estimatedGasCostOfWithdraw;

    /// reject deposits that would increase `this.balance` beyond this value.
    /// security feature:
    /// limits the total amount of home/mainnet ether that can be lost
    /// if the bridge is faulty or compromised in any way!
    /// set to 0 to disable.
    uint256 public maxTotalHomeContractBalance;

    /// reject deposits whose `msg.value` is higher than this value.
    /// security feature.
    /// set to 0 to disable.
    uint256 public maxSingleDepositValue;

    /// Contract authorities.
    address[] public authorities;

    /// Used foreign transaction hashes.
    mapping (bytes32 => bool) withdraws;

    /// Event created on money deposit.
    event Deposit (address recipient, uint256 value);

    /// Event created on money withdraw.
    event Withdraw (address recipient, uint256 value, bytes32 transactionHash);

    /// Constructor.
    function HomeBridge(
        uint256 requiredSignaturesParam,
        address[] authoritiesParam,
        uint256 estimatedGasCostOfWithdrawParam,
        uint256 maxTotalHomeContractBalanceParam,
        uint256 maxSingleDepositValueParam
    ) public
    {
        require(requiredSignaturesParam != 0);
        require(requiredSignaturesParam <= authoritiesParam.length);
        requiredSignatures = requiredSignaturesParam;
        authorities = authoritiesParam;
        estimatedGasCostOfWithdraw = estimatedGasCostOfWithdrawParam;
        maxTotalHomeContractBalance = maxTotalHomeContractBalanceParam;
        maxSingleDepositValue = maxSingleDepositValueParam;
    }

    /// Should be used to deposit money.
    function () public payable {
        require(maxSingleDepositValue == 0 || msg.value <= maxSingleDepositValue);
        // the value of `this.balance` in payable methods is increased
        // by `msg.value` before the body of the payable method executes
        require(maxTotalHomeContractBalance == 0 || this.balance <= maxTotalHomeContractBalance);
        Deposit(msg.sender, msg.value);
    }

    /// final step of a withdraw.
    /// checks that `requiredSignatures` `authorities` have signed of on the `message`.
    /// then transfers `value` to `recipient` (both extracted from `message`).
    /// see message library above for a breakdown of the `message` contents.
    /// `vs`, `rs`, `ss` are the components of the signatures.

    /// anyone can call this, provided they have the message and required signatures!
    /// only the `authorities` can create these signatures.
    /// `requiredSignatures` authorities can sign arbitrary `message`s
    /// transfering any ether `value` out of this contract to `recipient`.
    /// bridge users must trust a majority of `requiredSignatures` of the `authorities`.
    function withdraw(uint8[] vs, bytes32[] rs, bytes32[] ss, bytes message) public {
        require(message.length == 116);

        // check that at least `requiredSignatures` `authorities` have signed `message`
        require(Helpers.hasEnoughValidSignatures(message, vs, rs, ss, authorities, requiredSignatures));

        address recipient = Message.getRecipient(message);
        uint256 value = Message.getValue(message);
        bytes32 hash = Message.getTransactionHash(message);
        uint256 homeGasPrice = Message.getHomeGasPrice(message);

        // if the recipient calls `withdraw` they can choose the gas price freely.
        // if anyone else calls `withdraw` they have to use the gas price
        // `homeGasPrice` specified by the user initiating the withdraw.
        // this is a security mechanism designed to shut down
        // malicious senders setting extremely high gas prices
        // and effectively burning recipients withdrawn value.
        // see https://github.com/paritytech/parity-bridge/issues/112
        // for further explanation.
        require((recipient == msg.sender) || (tx.gasprice == homeGasPrice));

        // The following two statements guard against reentry into this function.
        // Duplicated withdraw or reentry.
        require(!withdraws[hash]);
        // Order of operations below is critical to avoid TheDAO-like re-entry bug
        withdraws[hash] = true;

        uint256 estimatedWeiCostOfWithdraw = estimatedGasCostOfWithdraw * homeGasPrice;

        // charge recipient for relay cost
        uint256 valueRemainingAfterSubtractingCost = value - estimatedWeiCostOfWithdraw;

        // pay out recipient
        recipient.transfer(valueRemainingAfterSubtractingCost);

        // refund relay cost to relaying authority
        msg.sender.transfer(estimatedWeiCostOfWithdraw);

        Withdraw(recipient, valueRemainingAfterSubtractingCost, hash);
    }
}


contract ForeignBridge {
    // following is the part of ForeignBridge that implements an ERC20 token.
    // ERC20 spec: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md

    uint256 public totalSupply;

    string public name = &quot;ForeignBridge&quot;;
    // BETH = bridged ether
    string public symbol = &quot;BETH&quot;;
    // 1-1 mapping of ether to tokens
    uint8 public decimals = 18;

    /// maps addresses to their token balances
    mapping (address => uint256) public balances;

    // owner of account approves the transfer of an amount by another account
    mapping(address => mapping (address => uint256)) allowed;

    /// Event created on money transfer
    event Transfer(address indexed from, address indexed to, uint256 tokens);

    // returns the ERC20 token balance of the given address
    function balanceOf(address tokenOwner) public view returns (uint256) {
        return balances[tokenOwner];
    }

    /// Transfer `value` to `recipient` on this `foreign` chain.
    ///
    /// does not affect `home` chain. does not do a relay.
    /// as specificed in ERC20 this doesn&#39;t fail if tokens == 0.
    function transfer(address recipient, uint256 tokens) public returns (bool) {
        require(balances[msg.sender] >= tokens);
        // fails if there is an overflow
        require(balances[recipient] + tokens >= balances[recipient]);

        balances[msg.sender] -= tokens;
        balances[recipient] += tokens;
        Transfer(msg.sender, recipient, tokens);
        return true;
    }

    // following is the part of ForeignBridge that is concerned
    // with the part of the ERC20 standard responsible for giving others spending rights
    // and spending others tokens

    // created when `approve` is executed to mark that
    // `tokenOwner` has approved `spender` to spend `tokens` of his tokens
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);

    // allow `spender` to withdraw from your account, multiple times, up to the `tokens` amount.
    // calling this function repeatedly overwrites the current allowance.
    function approve(address spender, uint256 tokens) public returns (bool) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }

    // returns how much `spender` is allowed to spend of `owner`s tokens
    function allowance(address owner, address spender) public view returns (uint256) {
        return allowed[owner][spender];
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool) {
        // `from` has enough tokens
        require(balances[from] >= tokens);
        // `sender` is allowed to move `tokens` from `from`
        require(allowed[from][msg.sender] >= tokens);
        // fails if there is an overflow
        require(balances[to] + tokens >= balances[to]);

        balances[to] += tokens;
        balances[from] -= tokens;
        allowed[from][msg.sender] -= tokens;

        Transfer(from, to, tokens);
        return true;
    }

    // following is the part of ForeignBridge that is
    // no longer part of ERC20 and is concerned with
    // with moving tokens from and to HomeBridge

    struct SignaturesCollection {
        /// Signed message.
        bytes message;
        /// Authorities who signed the message.
        address[] signed;
        /// Signatures
        bytes[] signatures;
    }

    /// Number of authorities signatures required to withdraw the money.
    ///
    /// Must be less than number of authorities.
    uint256 public requiredSignatures;

    uint256 public estimatedGasCostOfWithdraw;

    /// Contract authorities.
    address[] public authorities;

    /// Pending deposits and authorities who confirmed them
    mapping (bytes32 => address[]) deposits;

    /// Pending signatures and authorities who confirmed them
    mapping (bytes32 => SignaturesCollection) signatures;

    /// triggered when an authority confirms a deposit
    event DepositConfirmation(address recipient, uint256 value, bytes32 transactionHash);

    /// triggered when enough authorities have confirmed a deposit
    event Deposit(address recipient, uint256 value, bytes32 transactionHash);

    /// Event created on money withdraw.
    event Withdraw(address recipient, uint256 value, uint256 homeGasPrice);

    event WithdrawSignatureSubmitted(bytes32 messageHash);

    /// Collected signatures which should be relayed to home chain.
    event CollectedSignatures(address authorityResponsibleForRelay, bytes32 messageHash);

    function ForeignBridge(
        uint256 _requiredSignatures,
        address[] _authorities,
        uint256 _estimatedGasCostOfWithdraw
    ) public
    {
        require(_requiredSignatures != 0);
        require(_requiredSignatures <= _authorities.length);
        requiredSignatures = _requiredSignatures;
        authorities = _authorities;
        estimatedGasCostOfWithdraw = _estimatedGasCostOfWithdraw;
    }

    /// require that sender is an authority
    modifier onlyAuthority() {
        require(Helpers.addressArrayContains(authorities, msg.sender));
        _;
    }

    /// Used to deposit money to the contract.
    ///
    /// deposit recipient (bytes20)
    /// deposit value (uint256)
    /// mainnet transaction hash (bytes32) // to avoid transaction duplication
    function deposit(address recipient, uint256 value, bytes32 transactionHash) public onlyAuthority() {
        // Protection from misbehaving authority
        var hash = keccak256(recipient, value, transactionHash);

        // don&#39;t allow authority to confirm deposit twice
        require(!Helpers.addressArrayContains(deposits[hash], msg.sender));

        deposits[hash].push(msg.sender);

        // TODO: this may cause troubles if requiredSignatures len is changed
        if (deposits[hash].length != requiredSignatures) {
            DepositConfirmation(recipient, value, transactionHash);
            return;
        }

        balances[recipient] += value;
        // mints tokens
        totalSupply += value;
        // ERC20 specifies: a token contract which creates new tokens
        // SHOULD trigger a Transfer event with the _from address
        // set to 0x0 when tokens are created.
        Transfer(0x0, recipient, value);
        Deposit(recipient, value, transactionHash);
    }

    /// Transfer `value` from `msg.sender`s local balance (on `foreign` chain) to `recipient` on `home` chain.
    ///
    /// immediately decreases `msg.sender`s local balance.
    /// emits a `Withdraw` event which will be picked up by the bridge authorities.
    /// bridge authorities will then sign off (by calling `submitSignature`) on a message containing `value`,
    /// `recipient` and the `hash` of the transaction on `foreign` containing the `Withdraw` event.
    /// once `requiredSignatures` are collected a `CollectedSignatures` event will be emitted.
    /// an authority will pick up `CollectedSignatures` an call `HomeBridge.withdraw`
    /// which transfers `value - relayCost` to `recipient` completing the transfer.
    function transferHomeViaRelay(address recipient, uint256 value, uint256 homeGasPrice) public {
        require(balances[msg.sender] >= value);
        // don&#39;t allow 0 value transfers to home
        require(value > 0);

        uint256 estimatedWeiCostOfWithdraw = estimatedGasCostOfWithdraw * homeGasPrice;
        require(value > estimatedWeiCostOfWithdraw);

        balances[msg.sender] -= value;
        // burns tokens
        totalSupply -= value;
        // in line with the transfer event from `0x0` on token creation
        // recommended by ERC20 (see implementation of `deposit` above)
        // we trigger a Transfer event to `0x0` on token destruction
        Transfer(msg.sender, 0x0, value);
        Withdraw(recipient, value, homeGasPrice);
    }

    /// Should be used as sync tool
    ///
    /// Message is a message that should be relayed to main chain once authorities sign it.
    ///
    /// for withdraw message contains:
    /// withdrawal recipient (bytes20)
    /// withdrawal value (uint256)
    /// foreign transaction hash (bytes32) // to avoid transaction duplication
    function submitSignature(bytes signature, bytes message) public onlyAuthority() {
        // ensure that `signature` is really `message` signed by `msg.sender`
        require(msg.sender == MessageSigning.recoverAddressFromSignedMessage(signature, message));

        require(message.length == 116);
        var hash = keccak256(message);

        // each authority can only provide one signature per message
        require(!Helpers.addressArrayContains(signatures[hash].signed, msg.sender));
        signatures[hash].message = message;
        signatures[hash].signed.push(msg.sender);
        signatures[hash].signatures.push(signature);

        // TODO: this may cause troubles if requiredSignatures len is changed
        if (signatures[hash].signed.length == requiredSignatures) {
            CollectedSignatures(msg.sender, hash);
        } else {
            WithdrawSignatureSubmitted(hash);
        }
    }

    /// Get signature
    function signature(bytes32 hash, uint256 index) public view returns (bytes) {
        return signatures[hash].signatures[index];
    }

    /// Get message
    function message(bytes32 hash) public view returns (bytes) {
        return signatures[hash].message;
    }
}