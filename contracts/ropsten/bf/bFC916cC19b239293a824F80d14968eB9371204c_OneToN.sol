/**
 *Submitted for verification at Etherscan.io on 2019-07-11
*/

pragma solidity 0.5.4;


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


interface Token {

    /// @return total amount of tokens
    function totalSupply() external view returns (uint256 supply);

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) external view returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) external returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) external returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // Optionally implemented function to show the number of decimals for the token
    function decimals() external view returns (uint8 decimals);
}

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
    // Current user&#39;s balance, ignoring planned withdraws
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
        require(token.transferFrom(msg.sender, address(this), added_deposit), "tokens didn&#39;t transfer");
    }

    /// @notice Internally transfer deposits between two addresses.
    /// Sender and receiver must be different or the transaction will fail.
    /// @param sender Account from which the amount will be deducted
    /// @param receiver Account to which the amount will be credited
    /// @param amount Amount of tokens to be transferred
    /// @return true if transfer has been done successfully, otherwise false
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

        require(token.transfer(msg.sender, withdrawable), "tokens didn&#39;t transfer");
    }

    /// @notice The owner&#39;s balance with planned withdrawals deducted
    /// @param owner Address for which the balance should be returned
    /// @return The remaining balance after planned withdrawals
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

contract OneToN is Utils {
    UserDeposit public deposit_contract;

    // The signature given to claim() has to be computed with
    // this chain_id.  Otherwise the call fails.
    uint256 public chain_id;

    // Indicates which sessions have already been settled by storing
    // keccak256(receiver, sender, expiration_block) => expiration_block.
    mapping (bytes32 => uint256) public settled_sessions;

    /*
     *  Events
     */

    // The session has been settled and can&#39;t be claimed again. The receiver is
    // indexed to allow services to know when claims have been successfully
    // processed.
    // When users want to get notified about low balances, they should listen
    // for UserDeposit.BalanceReduced, instead.
    // The first three values identify the session, `transferred` is the amount
    // of tokens that has actually been transferred during the claim.
    event Claimed(
        address sender,
        address indexed receiver,
        uint256 expiration_block,
        uint256 transferred
    );

    /*
     *  Constructor
     */

    /// @param _deposit_contract Address of UserDeposit contract
    constructor(
        address _deposit_contract,
        uint256 _chain_id
    )
        public
    {
        deposit_contract = UserDeposit(_deposit_contract);
        chain_id = _chain_id;
    }

    /// @notice Submit an IOU to claim the owed amount.
    /// If the deposit is smaller than the claim, the remaining deposit is
    /// claimed. If no tokens are claimed, `claim` may be retried, later.
    /// @param sender Address from which the amount is transferred
    /// @param receiver Address to which the amount is transferred
    /// @param amount Owed amount of tokens
    /// @param expiration_block Tokens can only be claimed before this time
    /// @param signature Sender&#39;s signature over keccak256(sender, receiver, amount, expiration_block)
    /// @return Amount of transferred tokens
    function claim(
        address sender,
        address receiver,
        uint256 amount,
        uint256 expiration_block,
        address one_to_n_address,
        bytes memory signature
    )
        public
        returns (uint)
    {
        require(one_to_n_address == address(this), "IOU for another OneToN address");
        require(block.number <= expiration_block, "IOU expired");

        // validate signature
        address addressFromSignature = recoverAddressFromSignature(
            sender,
            receiver,
            amount,
            expiration_block,
            one_to_n_address,
            chain_id,
            signature
        );
        require(addressFromSignature == sender, "Signature mismatch");

        // must not be claimed before
        bytes32 _key = keccak256(abi.encodePacked(receiver, sender, expiration_block));
        require(settled_sessions[_key] == 0, "Already settled session");

        // claim as much as possible
        uint256 transferable = min(amount, deposit_contract.balances(sender));
        if (transferable > 0) {
            // register to avoid double claiming
            settled_sessions[_key] = expiration_block;
            assert(expiration_block > 0);
            emit Claimed(sender, receiver, expiration_block, transferable);

            // event SessionSettled(_key, expiration_block);
            require(deposit_contract.transfer(sender, receiver, transferable), "deposit did not transfer");
        }
        return transferable;
    }

    // TODO: gas saving function to claim multiple IOUs and free space in one transaction

    /*
     *  Internal Functions
     */

    function recoverAddressFromSignature(
        address sender,
        address receiver,
        uint256 amount,
        uint256 expiration_block,
        address one_to_n_address,
        uint256 chain_id,
        bytes memory signature
    )
        internal
        pure
        returns (address signature_address)
    {
        bytes32 message_hash = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n188",
            one_to_n_address,
            chain_id,
            uint256(MessageTypeId.IOU),
            sender,
            receiver,
            amount,
            expiration_block
        ));
        return ECVerify.ecverify(message_hash, signature);
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256)
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