pragma solidity ^0.4.23;

interface tokenRecipient {
    function receiveApproval (address from, uint256 value, address token, bytes extraData) external;
}

/**
 * DreamTeam token contract. It implements the next capabilities:
 * 1. Standard ERC20 functionality. [OK]
 * 2. Additional utility function approveAndCall. [OK]
 * 3. Function to rescue "lost forever" tokens, which were accidentally sent to the contract address. [OK]
 * 4. Additional transfer and approve functions which allow to distinct the transaction signer and executor,
 *    which enables accounts with no Ether on their balances to make token transfers and use DreamTeam services. [OK]
 * 5. Token sale distribution rules. [OK]
 * 
 * Testing DreamTeam Token distribution
 * Solidity contract by Nikita @ https://nikita.tk
 */
contract Pasadena {

    string public name;
    string public symbol;
    uint8 public decimals = 6; // Makes JavaScript able to handle precise calculations (until totalSupply < 9 milliards)
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => mapping(uint => bool)) public usedSigIds; // Used in *ViaSignature(..)
    address public tokenDistributor; // Account authorized to distribute tokens only during the token distribution event
    address public rescueAccount; // Account authorized to withdraw tokens accidentally sent to this contract

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    bytes public ethSignedMessagePrefix = "\x19Ethereum Signed Message:\n";
    enum sigStandard { typed, personal, stringHex }
    enum sigDestination { transfer, approve, approveAndCall, transferFrom }
    bytes32 public sigDestinationTransfer = keccak256(
        "address Token Contract Address",
        "address Sender&#39;s Address",
        "address Recipient&#39;s Address",
        "uint256 Amount to Transfer (last six digits are decimals)",
        "uint256 Fee in Tokens Paid to Executor (last six digits are decimals)",
        "uint256 Signature Expiration Timestamp (unix timestamp)",
        "uint256 Signature ID"
    ); // `transferViaSignature`: keccak256(address(this), from, to, value, fee, deadline, sigId)
    bytes32 public sigDestinationTransferFrom = keccak256(
        "address Token Contract Address",
        "address Address Approved for Withdraw",
        "address Account to Withdraw From",
        "address Withdrawal Recipient Address",
        "uint256 Amount to Transfer (last six digits are decimals)",
        "uint256 Fee in Tokens Paid to Executor (last six digits are decimals)",
        "uint256 Signature Expiration Timestamp (unix timestamp)",
        "uint256 Signature ID"
    ); // `transferFromViaSignature`: keccak256(address(this), signer, from, to, value, fee, deadline, sigId)
    bytes32 public sigDestinationApprove = keccak256(
        "address Token Contract Address",
        "address Withdrawal Approval Address",
        "address Withdrawal Recipient Address",
        "uint256 Amount to Transfer (last six digits are decimals)",
        "uint256 Fee in Tokens Paid to Executor (last six digits are decimals)",
        "uint256 Signature Expiration Timestamp (unix timestamp)",
        "uint256 Signature ID"
    ); // `approveViaSignature`: keccak256(address(this), from, spender, value, fee, deadline, sigId)
    bytes32 public sigDestinationApproveAndCall = keccak256( // `approveAndCallViaSignature`
        "address Token Contract Address",
        "address Withdrawal Approval Address",
        "address Withdrawal Recipient Address",
        "uint256 Amount to Transfer (last six digits are decimals)",
        "bytes Data to Transfer",
        "uint256 Fee in Tokens Paid to Executor (last six digits are decimals)",
        "uint256 Signature Expiration Timestamp (unix timestamp)",
        "uint256 Signature ID"
    ); // `approveAndCallViaSignature`: keccak256(address(this), from, spender, value, extraData, fee, deadline, sigId)

    constructor (string tokenName, string tokenSymbol) public {
        name = tokenName;
        symbol = tokenSymbol;
        rescueAccount = tokenDistributor = msg.sender;
    }

    /**
     * Utility internal function used to safely transfer `value` tokens `from` -> `to`. Throws if transfer is impossible.
     */
    function internalTransfer (address from, address to, uint value) internal {
        // Prevent people from accidentally burning their tokens + uint256 wrap prevention
        require(to != 0x0 && balanceOf[from] >= value && balanceOf[to] + value >= balanceOf[to]);
        balanceOf[from] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
    }

    /**
     * Utility internal function used to safely transfer `value1` tokens `from` -> `to1`, and `value2` tokens
     * `from` -> `to2`, minimizing gas usage (calling `internalTransfer` twice is more expensive). Throws if
     * transfers are impossible.
     */
    function internalDoubleTransfer (address from, address to1, uint value1, address to2, uint value2) internal {
        require( // Prevent people from accidentally burning their tokens + uint256 wrap prevention
            to1 != 0x0 && to2 != 0x0 && value1 + value2 >= value1 && balanceOf[from] >= value1 + value2
            && balanceOf[to1] + value1 >= balanceOf[to1] && balanceOf[to2] + value2 >= balanceOf[to2]
        );
        balanceOf[from] -= value1 + value2;
        balanceOf[to1] += value1;
        emit Transfer(from, to1, value1);
        if (value2 > 0) {
            balanceOf[to2] += value2;
            emit Transfer(from, to2, value2);
        }
    }

    /**
     * Internal method that makes sure that the given signature corresponds to a given data and is made by `signer`.
     * It utilizes three (four) standards of message signing in Ethereum, as at the moment of this smart contract
     * development there is no single signing standard defined. For example, Metamask and Geth both support
     * personal_sign standard, SignTypedData is only supported by Matamask, Trezor does not support "widely adopted"
     * Ethereum personal_sign but rather personal_sign with fixed prefix and so on.
     * Note that it is always possible to forge any of these signatures using the private key, the problem is that
     * third-party wallets must adopt a single standard for signing messages.
     */
    function requireSignature (
        bytes32 data, address signer, uint256 deadline, uint256 sigId, bytes sig, sigStandard std, sigDestination signDest
    ) internal {
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly { // solium-disable-line security/no-inline-assembly
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
        if (v < 27)
            v += 27;
        require(block.timestamp <= deadline && !usedSigIds[signer][sigId]); // solium-disable-line security/no-block-members
        if (std == sigStandard.typed) { // Typed signature. This is the most likely scenario to be used and accepted
            require(
                signer == ecrecover(
                    keccak256(
                        signDest == sigDestination.transfer
                            ? sigDestinationTransfer
                            : signDest == sigDestination.approve
                                ? sigDestinationApprove
                                : signDest == sigDestination.approveAndCall
                                    ? sigDestinationApproveAndCall
                                    : sigDestinationTransferFrom,
                        data
                    ),
                    v, r, s
                )
            );
        } else if (std == sigStandard.personal) { // Ethereum signed message signature (Geth and Trezor)
            require(
                signer == ecrecover(keccak256(ethSignedMessagePrefix, "32", data), v, r, s) // Geth-adopted
                ||
                signer == ecrecover(keccak256(ethSignedMessagePrefix, "\x20", data), v, r, s) // Trezor-adopted
            );
        } else { // == 2; Signed string hash signature (the most expensive but universal)
            require(
                signer == ecrecover(keccak256(ethSignedMessagePrefix, "64", hexToString(data)), v, r, s) // Geth
                ||
                signer == ecrecover(keccak256(ethSignedMessagePrefix, "\x40", hexToString(data)), v, r, s) // Trezor
            );
        }
        usedSigIds[signer][sigId] = true;
    }

    /**
     * Utility costly function to encode bytes HEX representation as string.
     * @param sig - signature to encode.
     */
    function hexToString (bytes32 sig) internal pure returns (bytes) { // /to-try/ convert to two uint256 and test gas
        bytes memory str = new bytes(64);
        for (uint8 i = 0; i < 32; ++i) {
            str[2 * i] = byte((uint8(sig[i]) / 16 < 10 ? 48 : 87) + uint8(sig[i]) / 16);
            str[2 * i + 1] = byte((uint8(sig[i]) % 16 < 10 ? 48 : 87) + (uint8(sig[i]) % 16));
        }
        return str;
    }

    /**
     * Transfer `value` tokens to `to` address from the account of sender.
     * @param to - the address of the recipient
     * @param value - the amount to send
     */
    function transfer (address to, uint256 value) public returns (bool) {
        internalTransfer(msg.sender, to, value);
        return true;
    }

    /**
     * This function distincts transaction signer from transaction executor. It allows anyone to transfer tokens
     * from the `from` account by providing a valid signature, which can only be obtained from the `from` account
     * owner.
     * Note that passed parameter sigId is unique and cannot be passed twice (prevents replay attacks). When there&#39;s
     * a need to make signature once again (because the first on is lost or whatever), user should sign the message
     * with the same sigId, thus ensuring that the previous signature won&#39;t be used if the new one passes.
     * Use case: the user wants to send some tokens to other user or smart contract, but don&#39;t have ether to do so.
     * @param from - the account giving its signature to transfer `value` tokens to `to` address
     * @param to - the account receiving `value` tokens
     * @param value - the value in tokens to transfer
     * @param fee - a fee to pay to transaction executor (`msg.sender`)
     * @param deadline - until when the signature is valid
     * @param sigId - signature unique ID. Signatures made with the same signature ID cannot be submitted twice
     * @param sig - signature made by `from`, which is the proof of `from`&#39;s agreement with the above parameters
     * @param sigStd - chosen standard for signature validation. The signer must explicitly tell which standard they use
     */
    function transferViaSignature (
        address     from,
        address     to,
        uint256     value,
        uint256     fee,
        uint256     deadline,
        uint256     sigId,
        bytes       sig,
        sigStandard sigStd
    ) external returns (bool) {
        requireSignature(
            keccak256(address(this), from, to, value, fee, deadline, sigId),
            from, deadline, sigId, sig, sigStd, sigDestination.transfer
        );
        internalDoubleTransfer(from, to, value, msg.sender, fee);
        return true;
    }

    /**
     * Allow `spender` to take `value` tokens from the transaction sender&#39;s account.
     * Beware that changing an allowance with this method brings the risk that `spender` may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender - the address authorized to spend
     * @param value - the maximum amount they can spend
     */
    function approve (address spender, uint256 value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * Same as `transferViaSignature`, but for `approve`.
     * Use case: the user wants to set an allowance for the smart contract or another user without having ether on their
     * balance.
     * @param from - the account to approve withdrawal from, which signed all below parameters
     * @param spender - the account allowed to withdraw tokens from `from` address
     * @param value - the value in tokens to approve to withdraw
     * @param fee - a fee to pay to transaction executor (`msg.sender`)
     * @param deadline - until when the signature is valid
     * @param sigId - signature unique ID. Signatures made with the same signature ID cannot be submitted twice
     * @param sig - signature made by `from`, which is the proof of `from`&#39;s agreement with the above parameters
     * @param sigStd - chosen standard for signature validation. The signer must explicitely tell which standard they use
     */
    function approveViaSignature (
        address     from,
        address     spender,
        uint256     value,
        uint256     fee,
        uint256     deadline,
        uint256     sigId,
        bytes       sig,
        sigStandard sigStd
    ) external returns (bool) {
        requireSignature(
            keccak256(address(this), from, spender, value, fee, deadline, sigId),
            from, deadline, sigId, sig, sigStd, sigDestination.approve
        );
        allowance[from][spender] = value;
        emit Approval(from, spender, value);
        internalTransfer(from, msg.sender, fee);
        return true;
    }

    /**
     * Transfer `value` tokens to `to` address from the `from` account, using the previously set allowance.
     * @param from - the address to transfer tokens from
     * @param to - the address of the recipient
     * @param value - the amount to send
     */
    function transferFrom (address from, address to, uint256 value) public returns (bool) {
        require(value <= allowance[from][msg.sender]); // Test whether allowance was set
        allowance[from][msg.sender] -= value;
        internalTransfer(from, to, value);
        return true;
    }

    /**
     * Same as `transferViaSignature`, but for `transferFrom`.
     * Use case: the user wants to withdraw tokens from a smart contract or another user who allowed the user to do so.
     * Important note: fee is subtracted from `value` before it reaches `to`.
     * @param from - the address to transfer tokens from
     * @param to - the address of the recipient
     * @param value - the amount to send
     */
    function transferFromViaSignature (
        address     signer,
        address     from,
        address     to,
        uint256     value,
        uint256     fee,
        uint256     deadline,
        uint256     sigId,
        bytes       sig,
        sigStandard sigStd
    ) external returns (bool) {
        requireSignature(
            keccak256(address(this), signer, from, to, value, fee, deadline, sigId),
            signer, deadline, sigId, sig, sigStd, sigDestination.transferFrom
        );
        require(value <= allowance[from][signer] && value >= fee);
        allowance[from][signer] -= value;
        internalDoubleTransfer(from, to, value - fee, msg.sender, fee);
        return true;
    }

    /**
     * Utility function, which acts the same as approve(...) does, but also calls `receiveApproval` function on a
     * `spender` address, which is usually the address of the smart contract. In the same call, smart contract can
     * withdraw tokens from the sender&#39;s account and receive additional `extraData` for processing.
     * @param spender - the address to be authorized to spend tokens
     * @param value - the max amount the `spender` can withdraw
     * @param extraData - some extra information to send to the approved contract
     */
    function approveAndCall (address spender, uint256 value, bytes extraData) public returns (bool) {
        approve(spender, value);
        tokenRecipient(spender).receiveApproval(msg.sender, value, this, extraData);
        return true;
    }

    /**
     * Same as `approveViaSignature`, but for `approveAndCall`.
     * Use case: the user wants to send tokens to the smart contract and pass additional data within one transaction.
     * @param from - the account to approve withdrawal from, which signed all below parameters
     * @param spender - the account allowed to withdraw tokens from `from` address (in this case, smart contract only)
     * @param value - the value in tokens to approve to withdraw
     * @param extraData - additional data to pass to the `spender` smart contract
     * @param fee - a fee to pay to transaction executor (`msg.sender`)
     * @param deadline - until when the signature is valid
     * @param sigId - signature unique ID. Signatures made with the same signature ID cannot be submitted twice
     * @param sig - signature made by `from`, which is the proof of `from`&#39;s agreement with the above parameters
     * @param sigStd - chosen standard for signature validation. The signer must explicitely tell which standard they use
     */
    function approveAndCallViaSignature (
        address     from,
        address     spender,
        uint256     value,
        bytes       extraData,
        uint256     fee,
        uint256     deadline,
        uint256     sigId,
        bytes       sig,
        sigStandard sigStd
    ) external returns (bool) {
        requireSignature(
            keccak256(address(this), from, spender, value, extraData, fee, deadline, sigId),
            from, deadline, sigId, sig, sigStd, sigDestination.approveAndCall
        );
        allowance[from][spender] = value;
        emit Approval(from, spender, value);
        tokenRecipient(spender).receiveApproval(from, value, this, extraData);
        internalTransfer(from, msg.sender, fee);
        return true;
    }

    /**
     * `tokenDistributor` is authorized to distribute tokens to the parties who participated in the token sale by the
     * time the `lastMint` function is triggered, which closes the ability to mint any new tokens forever.
     * @param recipients - Addresses of token recipients
     * @param amounts - Corresponding amount of each token recipient in `recipients`
     */
    function multiMint (address[] recipients, uint256[] amounts) external {
        
        // Once the token distribution ends, tokenDistributor will become 0x0 and multiMint will never work
        require(tokenDistributor != 0x0 && tokenDistributor == msg.sender && recipients.length == amounts.length);

        uint total = 0;

        for (uint i = 0; i < recipients.length; ++i) {
            balanceOf[recipients[i]] += amounts[i];
            total += amounts[i];
            emit Transfer(0x0, recipients[i], amounts[i]);
        }

        totalSupply += total;
        
    }

    /**
     * The last mint that will ever happen. Disables the multiMint function and mints remaining 40% of tokens (in
     * regard of 60% tokens minted before) to a `tokenDistributor` address.
     */
    function lastMint () external {

        require(tokenDistributor != 0x0 && tokenDistributor == msg.sender && totalSupply > 0);

        uint256 remaining = totalSupply * 40 / 60; // Portion of tokens for DreamTeam (40%)

        // To make the total supply rounded (no fractional part), subtract the fractional part from DreamTeam&#39;s balance
        uint256 fractionalPart = (remaining + totalSupply) % (uint256(10) ** decimals);
        if (fractionalPart <= remaining)
            remaining -= fractionalPart; // Remove the fractional part to round the totalSupply

        balanceOf[tokenDistributor] += remaining;
        emit Transfer(0x0, tokenDistributor, remaining);

        totalSupply += remaining;
        tokenDistributor = 0x0; // Disable multiMint and lastMint functions forever

    }

    /**
     * ERC20 token is not designed to hold any tokens itself. This function allows to rescue tokens accidentally sent
     * to the address of this smart contract.
     * @param tokenContract - ERC-20 compatible token
     * @param value - amount to rescue
     */
    function rescueTokens (Pasadena tokenContract, uint256 value) public {
        require(msg.sender == rescueAccount);
        tokenContract.approve(rescueAccount, value);
    }

    /**
     * Utility function that allows to change the rescueAccount address.
     * @param newRescueAccount - account which will be authorized to rescue tokens.
     */
    function changeRescueAccount (address newRescueAccount) public {
        require(msg.sender == rescueAccount);
        rescueAccount = newRescueAccount;
    }

}