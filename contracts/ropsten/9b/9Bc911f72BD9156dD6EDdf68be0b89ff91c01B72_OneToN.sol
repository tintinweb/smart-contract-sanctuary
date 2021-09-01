/**
 *Submitted for verification at Etherscan.io on 2021-09-01
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
pragma abicoder v2;

/* solium-disable error-reason */

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
        assembly { // solium-disable-line security/no-inline-assembly
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
/* solium-disable error-reason */

library MessageType {

    enum MessageTypeId {
        None,
        BalanceProof,
        BalanceProofUpdate,
        Withdraw,
        CooperativeSettle,
        IOU,
        MSReward
    }
}

/// @title Utils
/// @notice Utils contract for various helpers used by the Raiden Network smart
/// contracts.
contract Utils {

    uint256 constant MAX_SAFE_UINT256 = 2**256 - 1;

    /// @notice Check if a contract exists
    /// @param contract_address The address to check whether a contract is
    /// deployed or not
    /// @return True if a contract exists, false otherwise
    function contractExists(address contract_address) public view returns (bool) {
        uint size;

        assembly { // solium-disable-line security/no-inline-assembly
            size := extcodesize(contract_address)
        }

        return size > 0;
    }

    string public constant signature_prefix = "\x19Ethereum Signed Message:\n";

    function min(uint256 a, uint256 b) public pure returns (uint256)
    {
        return a > b ? b : a;
    }

    function max(uint256 a, uint256 b) public pure returns (uint256)
    {
        return a > b ? a : b;
    }

    /// @dev Special subtraction function that does not fail when underflowing.
    /// @param a Minuend
    /// @param b Subtrahend
    /// @return Minimum between the result of the subtraction and 0, the maximum
    /// subtrahend for which no underflow occurs
    function failsafe_subtract(uint256 a, uint256 b)
        public
        pure
        returns (uint256, uint256)
    {
        unchecked {
            return a > b ? (a - b, b) : (0, a);
        }
    }

    /// @dev Special addition function that does not fail when overflowing.
    /// @param a Addend
    /// @param b Addend
    /// @return Maximum between the result of the addition or the maximum
    /// uint256 value
    function failsafe_addition(uint256 a, uint256 b)
        public
        pure
        returns (uint256)
    {
        unchecked {
            uint256 sum = a + b;
            return sum >= a ? sum : MAX_SAFE_UINT256;
        }
    }
}
/* solium-disable indentation */
/* solium-disable security/no-block-members */


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

contract Controllable {

    address public controller;

    modifier onlyController() {
        require(msg.sender == controller, "Can only be called by controller");
        _;
    }

    /// @notice Changes the controller who is allowed to deprecate or remove limits.
    /// Can only be called by the controller.
    function changeController(address new_controller)
        external
        onlyController
    {
        controller = new_controller;
    }
}

contract ServiceRegistryConfigurableParameters is Controllable {

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
        set_price_at = block.timestamp;
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
        require(block.timestamp >= set_price_at, "An underflow in price computation");
        uint256 seconds_passed = block.timestamp - set_price_at;

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
    constructor(
        Token _token,
        uint256 _release_at,
        address _withdrawer,
        ServiceRegistryConfigurableParameters _service_registry
    ) {
        token = _token;
        // Don't care even if it's in the past.
        release_at = _release_at;
        withdrawer = _withdrawer;
        service_registry = _service_registry;
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
        require(block.timestamp >= release_at || service_registry.deprecated(), "deposit not released yet");
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
            Token _token_for_registration,
            address _controller,
            uint256 _initial_price,
            uint256 _price_bump_numerator,
            uint256 _price_bump_denominator,
            uint256 _decay_constant,
            uint256 _min_price,
            uint256 _registration_duration
    ) {
        require(address(_token_for_registration) != address(0x0), "token at address zero");
        require(contractExists(address(_token_for_registration)), "token has no code");
        require(_initial_price >= min_price, "initial price too low");
        require(_initial_price <= 2 ** 90, "intiial price too high");

        token = _token_for_registration;
        // Check if the contract is indeed a token contract
        require(token.totalSupply() > 0, "total supply zero");
        controller = _controller;

        // Set up the price and the set price timestamp
        set_price = _initial_price;
        set_price_at = block.timestamp;

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
        if (valid_till < block.timestamp) { // a first time joiner or an expired service.
            valid_till = block.timestamp;
        }
        // Check against overflow.
        unchecked {
            require(valid_till < valid_till + registration_duration, "overflow during extending the registration");
        }
        valid_till = valid_till + registration_duration;
        assert(valid_till > service_valid_till[msg.sender]);
        service_valid_till[msg.sender] = valid_till;

        // Record the price
        set_price = amount * price_bump_numerator / price_bump_denominator;
        if (set_price > 2 ** 90) {
            set_price = 2 ** 90; // Preventing overflows.
        }
        set_price_at = block.timestamp;

        // Move the deposit in a new Deposit contract.
        assert(block.timestamp < valid_till);
        Deposit depo = new Deposit(token, valid_till, msg.sender, this);
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
        return block.timestamp < service_valid_till[_address];
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
        external
        canTransfer()
        returns (bool success)
    {
        require(sender != receiver, "sender == receiver");
        if (balances[sender] >= amount && amount > 0) {
            balances[sender] -= amount;
            // This can overflow in theory, but this is checked by solidity since 0.8.0.
            // In practice, with any reasonable token, where the supply is limited to uint256,
            // this can never overflow.
            // See https://github.com/raiden-network/raiden-contracts/pull/448#discussion_r250609178
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
    /// @param beneficiary Address to send withdrawn tokens to
    function withdrawToBeneficiary(uint256 amount, address beneficiary)
        external
    {
        withdrawHelper(amount, msg.sender, beneficiary);
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
        withdrawHelper(amount, msg.sender, msg.sender);
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

    function withdrawHelper(uint256 amount, address deposit_holder, address beneficiary)
        internal
    {
        require(beneficiary != address(0x0), "beneficiary is zero");
        WithdrawPlan storage withdraw_plan = withdraw_plans[deposit_holder];
        require(amount <= withdraw_plan.amount, "withdrawing more than planned");
        require(withdraw_plan.withdraw_block <= block.number, "withdrawing too early");
        uint256 withdrawable = min(amount, balances[deposit_holder]);
        balances[deposit_holder] -= withdrawable;

        // Update whole_balance, but take care against underflows.
        require(whole_balance - withdrawable <= whole_balance, "underflow in whole_balance");
        whole_balance -= withdrawable;

        emit BalanceReduced(deposit_holder, balances[deposit_holder]);
        delete withdraw_plans[deposit_holder];

        require(token.transfer(beneficiary, withdrawable), "tokens didn't transfer");
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

contract OneToN is Utils {
    UserDeposit public deposit_contract;
    ServiceRegistry public service_registry_contract;

    // The signature given to claim() has to be computed with
    // this chain_id.  Otherwise the call fails.
    uint256 public chain_id;

    // Indicates which sessions have already been settled by storing
    // keccak256(receiver, sender, expiration_block) => expiration_block.
    mapping (bytes32 => uint256) public settled_sessions;

    /*
     *  Events
     */

    // The session has been settled and can't be claimed again. The receiver is
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
    /// @param _service_registry_contract Address of ServiceRegistry contract
    constructor(
        address _deposit_contract,
        uint256 _chain_id,
        address _service_registry_contract
    ) {
        deposit_contract = UserDeposit(_deposit_contract);
        chain_id = _chain_id;
        service_registry_contract = ServiceRegistry(_service_registry_contract);
    }

    /// @notice Submit an IOU to claim the owed amount.
    /// If the deposit is smaller than the claim, the remaining deposit is
    /// claimed. If no tokens are claimed, `claim` may be retried, later.
    /// @param sender Address from which the amount is transferred
    /// @param receiver Address to which the amount is transferred
    /// @param amount Owed amount of tokens
    /// @param expiration_block Tokens can only be claimed before this time
    /// @param signature Sender's signature over keccak256(sender, receiver, amount, expiration_block)
    /// @return Amount of transferred tokens
    function claim(
        address sender,
        address receiver,
        uint256 amount,
        uint256 expiration_block,
        bytes memory signature
    )
        public
        returns (uint)
    {
        require(service_registry_contract.hasValidRegistration(receiver), "receiver not registered");
        require(block.number <= expiration_block, "IOU expired");

        // validate signature
        address addressFromSignature = recoverAddressFromSignature(
            sender,
            receiver,
            amount,
            expiration_block,
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

            require(deposit_contract.transfer(sender, receiver, transferable), "deposit did not transfer");
        }
        return transferable;
    }

    /// @notice Submit multiple IOUs to claim the owed amount.
    /// This is the same as calling `claim` multiple times, except for the reduced gas cost.
    /// @param senders Addresses from which the amounts are transferred
    /// @param receivers Addresses to which the amounts are transferred
    /// @param amounts Owed amounts of tokens
    /// @param expiration_blocks Tokens can only be claimed before this time
    /// @param signatures Sender's signatures concatenated into a single bytes array
    /// @return Amount of transferred tokens
    function bulkClaim(
        address[] calldata senders,
        address[] calldata receivers,
        uint256[] calldata amounts,
        uint256[] calldata expiration_blocks,
        bytes calldata signatures
    )
        external
        returns (uint)
    {
        uint256 transferable = 0;
        require(
            senders.length == receivers.length &&
            senders.length == amounts.length &&
            senders.length == expiration_blocks.length,
            "Same number of elements required for all input parameters"
        );
        require(
            signatures.length == senders.length * 65,
            "`signatures` should contain 65 bytes per IOU"
        );
        for (uint256 i = 0; i < senders.length; i++) {
            transferable += claim(
                senders[i],
                receivers[i],
                amounts[i],
                expiration_blocks[i],
                getSingleSignature(signatures, i)
            );
        }
        return transferable;
    }

    /*
     *  Internal Functions
     */

    /// @notice Get a single signature out of a byte array that contains concatenated signatures.
    /// @param signatures Multiple signatures concatenated into a single byte array
    /// @param i Index of the requested signature (zero based; the caller must check ranges)
    function getSingleSignature(
        bytes memory signatures,
        uint256 i
    )
        internal
        pure
        returns (bytes memory)
    {
        assert(i < signatures.length);
        uint256 offset = i * 65;
        // We need only 65, but we can access only whole words, so the next usable size is 3 * 32.
        bytes memory signature = new bytes(96);
        assembly { // solium-disable-line security/no-inline-assembly
            // Copy the 96 bytes, using `offset` to start at the beginning
            // of the requested signature.
            mstore(add(signature, 32), mload(add(add(signatures, 32), offset)))
            mstore(add(signature, 64), mload(add(add(signatures, 64), offset)))
            mstore(add(signature, 96), mload(add(add(signatures, 96), offset)))

            // The first 32 bytes store the length of the dynamic array.
            // Since a signature is 65 bytes, we set the length to 65, so
            // that only the signature is returned.
            mstore(signature, 65)
        }
        return signature;
    }

    function recoverAddressFromSignature(
        address sender,
        address receiver,
        uint256 amount,
        uint256 expiration_block,
        uint256 chain_id,
        bytes memory signature
    )
        internal
        view
        returns (address signature_address)
    {
        bytes32 message_hash = keccak256(
            abi.encodePacked(
                signature_prefix,
                "188",
                address(this),
                chain_id,
                uint256(MessageType.MessageTypeId.IOU),
                sender,
                receiver,
                amount,
                expiration_block
            )
        );
        return ECVerify.ecverify(message_hash, signature);
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