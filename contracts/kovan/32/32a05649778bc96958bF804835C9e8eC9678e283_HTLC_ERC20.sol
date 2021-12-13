// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.10;

import "./erc20.sol";

/**
 * @title Hash Time Lock Contract (HTLC) ERC20
 *
 * @author Meheret Tesfaye Batu <[email protected]>
 *
 * HTLC -> A Hash Time Lock Contract is essentially a type of payment in which two people
 * agree to a financial arrangement where one party will pay the other party a certain amount
 * of cryptocurrencies, such as Bitcoin or Ethereum assets.
 * However, because these contracts are Time-Locked, the receiving party only has a certain
 * amount of time to accept the payment, otherwise the money can be returned to the sender.
 *
 * Hash-Locked -> A Hash locked functions like “two-factor authentication” (2FA). It requires
 * the intended recipient to provide the correct secret passphrase to withdraw the funds.
 *
 * Time-Locked -> A Time locked adds a “timeout” expiration date to a payment. It requires
 * the intended recipient to claim the funds prior to the expiry. Otherwise, the transaction
 * defaults to enabling the original sender of funds to withdraw a refund.
 */
contract HTLC_ERC20 {

    struct LockContract {
        address token;
        bytes32 secret_hash;
        address payable recipient;
        address payable sender;
        uint256 endtime;
        uint256 amount;
        bool withdrawn;
        bool refunded;
        string preimage;
    }

    mapping (bytes32 => LockContract) locked_contracts;

    event log_fund (
        bytes32 indexed locked_contract_id,
        address token,
        bytes32 secret_hash,
        address indexed recipient,
        address indexed sender,
        uint256 endtime,
        uint256 amount
    );
    event log_withdraw (
        bytes32 indexed locked_contract_id
    );
    event log_refund (
        bytes32 indexed locked_contract_id
    );

    modifier is_token_transferable (address token, address sender, uint256 amount) {
        require(amount > 0, "token amount must be > 0");
        require(ERC20(token).allowance(sender, address(this)) >= amount, "token allowance must be >= amount");
        _;
    }
    modifier future_endtime (uint256 endtime) {
        require(endtime > block.timestamp, "endtime time must be in the future");
        _;
    }
    modifier is_locked_contract_exist (bytes32 locked_contract_id) {
        require(have_locked_contract(locked_contract_id), "locked_contract_id does not exist");
        _;
    }
    modifier check_secret_hash_matches (bytes32 locked_contract_id, string memory preimage) {
        require(locked_contracts[locked_contract_id].secret_hash == sha256(abi.encodePacked(preimage)), "secret hash hash does not match");
        _;
    }
    modifier withdrawable (bytes32 locked_contract_id) {
        require(locked_contracts[locked_contract_id].recipient == msg.sender, "withdrawable: not recipient");
        require(locked_contracts[locked_contract_id].withdrawn == false, "withdrawable: already withdrawn");
        require(locked_contracts[locked_contract_id].refunded == false, "withdrawable: already refunded");
        _;
    }
    modifier refundable (bytes32 locked_contract_id) {
        require(locked_contracts[locked_contract_id].sender == msg.sender, "refundable: not sender");
        require(locked_contracts[locked_contract_id].refunded == false, "refundable: already refunded");
        require(locked_contracts[locked_contract_id].withdrawn == false, "refundable: already withdrawn");
        require(locked_contracts[locked_contract_id].endtime <= block.timestamp, "refundable: endtime not yet passed");
        _;
    }

    /**
     * @dev Sender sets up a new Hash Time Lock Contract (HTLC) and depositing the ERC20 token.
     *
     * @param token ERC20 Token contract address.
     * @param secret_hash A sha256 secret hash.
     * @param recipient Recipient account of the ERC20 token.
     * @param sender Sender account of the ERC20 token.
     * @param endtime The timestamp that the lock expires at.
     * @param amount Amount of the token to lock up.
     *
     * @return locked_contract_id of the new HTLC.
     */
    function fund (
        address token, bytes32 secret_hash, address payable recipient, address payable sender, uint256 endtime, uint256 amount
    ) external is_token_transferable (token, msg.sender, amount) future_endtime (endtime) returns (bytes32 locked_contract_id) {
        
        require(msg.sender == sender, "msg.sender must be same with sender address");
        
        locked_contract_id = sha256(abi.encodePacked(
            token, secret_hash, recipient, sender, endtime, amount
        ));

        if (have_locked_contract(locked_contract_id))
            revert("this locked contract already exists");

        if (!ERC20(token).transferFrom(sender, address(this), amount))
            revert("transferFrom sender to this failed");

        locked_contracts[locked_contract_id] = LockContract(
            token, secret_hash, recipient, sender, endtime, amount, false, false, ""
        );

        emit log_fund (
            locked_contract_id, token, secret_hash, recipient, sender, endtime, amount
        );
        return locked_contract_id;
    }

    /**
     * @dev Called by the recipient once they know the preimage (secret key) of the secret hash.
     *
     * @param locked_contract_id of HTLC to withdraw.
     * @param preimage sha256(preimage) hash should equal the contract secret hash.
     *
     * @return bool true on success or false on failure.
     */
    function withdraw (bytes32 locked_contract_id, string memory preimage) external is_locked_contract_exist (locked_contract_id) check_secret_hash_matches (locked_contract_id, preimage) withdrawable (locked_contract_id) returns (bool) {
        
        LockContract storage locked_contract = locked_contracts[locked_contract_id];
        
        locked_contract.preimage = preimage;
        locked_contract.withdrawn = true;
        ERC20(locked_contract.token).transfer(
            locked_contract.recipient, locked_contract.amount
        );
        
        emit log_withdraw(
            locked_contract_id
        );
        return true;
    }

    /**
     * @dev Called by the sender if there was no withdraw and the time lock has expired.
     *
     * @param locked_contract_id of HTLC to refund.
     *
     * @return bool true on success or false on failure.
     */
    function refund (bytes32 locked_contract_id) external is_locked_contract_exist (locked_contract_id) refundable (locked_contract_id) returns (bool) {
        
        LockContract storage locked_contract = locked_contracts[locked_contract_id];
        
        locked_contract.refunded = true;
        ERC20(locked_contract.token).transfer(
            locked_contract.sender, locked_contract.amount
        );
        
        emit log_refund(
            locked_contract_id
        );
        return true;
    }

    /**
     * @dev Get HTLC ERC20 contract details.
     *
     * @param locked_contract_id of HTLC ERC20 to get details.
     *
     * @return id token secret_hash recipient sender endtime amount withdrawn refunded preimage locked HTLC ERC20 contract data's.
     */
    function get_locked_contract (bytes32 locked_contract_id) public view returns (
        bytes32 id, address token, bytes32 secret_hash, address recipient, address sender, uint256 endtime, uint256 amount, bool withdrawn, bool refunded, string memory preimage
    ) {
        if (have_locked_contract(locked_contract_id) == false)
            return (0, address(0), 0, address(0), address(0), 0, 0, false, false, "");

        LockContract storage locked_contract = locked_contracts[locked_contract_id];

        return (
            locked_contract_id,
            locked_contract.token,
            locked_contract.secret_hash,
            locked_contract.recipient,
            locked_contract.sender,
            locked_contract.endtime,
            locked_contract.amount,
            locked_contract.withdrawn,
            locked_contract.refunded,
            locked_contract.preimage
        );
    }

    /**
     * @dev Is there a locked contract with HTLC contract id.
     *
     * @param locked_contract_id of HTLC to find it exists.
     *
     * @return exists boolean true or false.
     */
    function have_locked_contract(bytes32 locked_contract_id) internal view returns (bool exists){
        exists = (locked_contracts[locked_contract_id].sender != address(0));
    }
}