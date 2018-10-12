pragma solidity ^0.4.25;

contract CentWallet {

    struct Wallet {
        uint256 balance;
        mapping(address => bool) linked;
        // prevent signature replay:
        uint64 debitNonce;
        uint64 withdrawNonce;
    }

    address[] public admins;

    mapping(bytes32 => Wallet) private wallets;
    mapping(address => bool) private isAdmin;

    uint256 private escrowBalance;

    modifier onlyAdmin {
        require(isAdmin[msg.sender]);
        _;
    }

    modifier onlyRootAdmin {
        require(msg.sender == admins[0]);
        _;
    }

    event Deposit(
        bytes32 indexed walletID,
        address indexed sender,
        uint256 indexed value
    );

    event Link(
        bytes32 indexed walletID,
        address indexed agent
    );

    event Debit(
        bytes32 indexed walletID,
        uint256 indexed nonce,
        uint256 indexed value
    );

    event Settle(
        bytes32 indexed walletID,
        uint256 indexed requestID,
        uint256 indexed value
    );

    event Withdraw(
        bytes32 indexed walletID,
        uint256 indexed nonce,
        uint256 indexed value,
        address recipient
    );

    constructor() public
    {
        admins.push(msg.sender);
        isAdmin[msg.sender] = true;
    }

//  PUBLIC CALLABLE BY ANYONE
    /**
     * Add funds to the wallet associated with an address + username
     * Create a wallet if none exists.
     */
    function deposit(
        bytes32 walletID) payable public
    {
        wallets[walletID].balance += msg.value;

        emit Deposit(walletID, msg.sender, msg.value);
    }

//  PUBLIC CALLABLE BY ADMIN
    /**
     * Add an authorized signer to a wallet.
     */
    function link(
        bytes32[] walletIDs,
        bytes32[] nameIDs,
        address[] agents,
        uint8[] v, bytes32[] r, bytes32[] s) onlyAdmin public
    {
        require(
            walletIDs.length == nameIDs.length &&
            walletIDs.length == agents.length &&
            walletIDs.length == v.length &&
            walletIDs.length == r.length &&
            walletIDs.length == s.length
        );

        for (uint i = 0; i < walletIDs.length; i++) {
            bytes32 walletID = walletIDs[i];
            address agent = agents[i];

            address signer = getMessageSigner(
                getLinkDigest(walletID, agent), v[i], r[i], s[i]
            );

            Wallet storage wallet = wallets[walletID];

            if (wallet.linked[signer] || walletID == getWalletDigest(nameIDs[i], signer)) {
                wallet.linked[agent] = true;

                emit Link(walletID, agent);
            }
        }
    }

    /**
     * Debit funds from a user&#39;s balance and add them to the escrow balance.
     */
    function debit(
        bytes32[] walletIDs,
        uint256[] values,
        uint64[] nonces,
        uint8[] v, bytes32[] r, bytes32[] s) onlyAdmin public
    {
        require(
            walletIDs.length == values.length &&
            walletIDs.length == nonces.length &&
            walletIDs.length == v.length &&
            walletIDs.length == r.length &&
            walletIDs.length == s.length
        );

        uint256 additionalEscrow = 0;

        for (uint i = 0; i < walletIDs.length; i++) {
            bytes32 walletID = walletIDs[i];
            uint256 value = values[i];
            uint64 nonce = nonces[i];

            address signer = getMessageSigner(
                getDebitDigest(walletID, value, nonce), v[i], r[i], s[i]
            );

            Wallet storage wallet = wallets[walletID];

            if (
                wallet.debitNonce < nonce &&
                wallet.balance >= value &&
                wallet.linked[signer]
            ) {
                wallet.debitNonce = nonce;
                wallet.balance -= value;

                emit Debit(walletID, nonce, value);

                additionalEscrow += value;
            }
        }

        escrowBalance += additionalEscrow;
    }

    /**
     * Withdraws funds from this contract, debiting the user&#39;s wallet.
     */
    function withdraw(
        bytes32[] walletIDs,
        address[] recipients,
        uint256[] values,
        uint64[] nonces,
        uint8[] v, bytes32[] r, bytes32[] s) onlyAdmin public
    {
        require(
            walletIDs.length == recipients.length &&
            walletIDs.length == values.length &&
            walletIDs.length == nonces.length &&
            walletIDs.length == v.length &&
            walletIDs.length == r.length &&
            walletIDs.length == s.length
        );

        for (uint i = 0; i < walletIDs.length; i++) {
            bytes32 walletID = walletIDs[i];
            address recipient = recipients[i];
            uint256 value = values[i];
            uint64 nonce = nonces[i];

            address signer = getMessageSigner(
                getWithdrawDigest(walletID, recipient, value, nonce), v[i], r[i], s[i]
            );

            Wallet storage wallet = wallets[walletID];

            if (
                wallet.withdrawNonce < nonce &&
                wallet.balance >= value &&
                wallet.linked[signer] &&
                recipient.send(value)
            ) {
                wallet.withdrawNonce = nonce;
                wallet.balance -= value;

                emit Withdraw(walletID, nonce, value, recipient);
            }
        }
    }

    /**
     * Settles funds from admin escrow into user wallets.
     */
    function settle(
        bytes32[] walletIDs,
        uint256[] requestIDs,
        uint256[] values) onlyAdmin public
    {
        require(
            walletIDs.length == requestIDs.length &&
            walletIDs.length == values.length
        );

        uint256 remainingEscrow = escrowBalance;

        for (uint i = 0; i < walletIDs.length; i++) {
            bytes32 walletID = walletIDs[i];
            uint256 value = values[i];

            require(value <= remainingEscrow);

            wallets[walletID].balance += value;
            remainingEscrow -= value;

            emit Settle(walletID, requestIDs[i], value);
        }

        escrowBalance = remainingEscrow;
    }

//  PURE GETTERS - FOR SIGNATURE GENERATION / VERIFICATION
    function getMessageSigner(
        bytes32 message,
        uint8 v, bytes32 r, bytes32 s) public pure returns(address)
    {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedMessage = keccak256(
            abi.encodePacked(prefix, message)
        );
        return ecrecover(prefixedMessage, v, r, s);
    }

    function getNameDigest(
        string name) public pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(name));
    }

    function getWalletDigest(
        bytes32 name,
        address root) public pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(
            name, root
        ));
    }

    function getLinkDigest(
        bytes32 walletID,
        address agent) public pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(
            walletID, agent
        ));
    }

    function getDebitDigest(
        bytes32 walletID,
        uint256 value,
        uint64 nonce) public pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(
            walletID, value, nonce
        ));
    }

    function getWithdrawDigest(
        bytes32 walletID,
        address recipient,
        uint256 value,
        uint64 nonce) public pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(
            walletID, recipient, value, nonce
        ));
    }

//  VIEW GETTERS - READ WALLET STATE
    function getDebitNonce(
        bytes32 walletID) public view returns (uint256)
    {
        return wallets[walletID].debitNonce + 1;
    }

    function getWithdrawNonce(
        bytes32 walletID) public view returns (uint256)
    {
        return wallets[walletID].withdrawNonce + 1;
    }

    function getLinkStatus(
        bytes32 walletID,
        address member) public view returns (bool)
    {
        return wallets[walletID].linked[member];
    }

    function getBalance(
        bytes32 walletID) public view returns (uint256)
    {
        return wallets[walletID].balance;
    }

    function getEscrowBalance() public view returns (uint256)
    {
      return escrowBalance;
    }

//  ADMIN MANAGEMENT
    function addAdmin(
        address newAdmin) onlyRootAdmin public
    {
        require(!isAdmin[newAdmin]);

        isAdmin[newAdmin] = true;
        admins.push(newAdmin);
    }

    function removeAdmin(
        address oldAdmin) onlyRootAdmin public
    {
        require(isAdmin[oldAdmin] && admins[0] != oldAdmin);

        bool found = false;
        for (uint i = 1; i < admins.length - 1; i++) {
            if (!found && admins[i] == oldAdmin) {
                found = true;
            }
            if (found) {
                admins[i] = admins[i + 1];
            }
        }

        admins.length--;
        isAdmin[oldAdmin] = false;
    }

    function changeRootAdmin(
        address newRootAdmin) onlyRootAdmin public
    {
        if (isAdmin[newRootAdmin] && admins[0] != newRootAdmin) {
            // Remove them & shorten the array so long as they are not currently root
            removeAdmin(newRootAdmin);
        }
        admins[0] = newRootAdmin;
        isAdmin[newRootAdmin] = true;
    }
}