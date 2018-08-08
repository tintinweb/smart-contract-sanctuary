///File: giveth-common-contracts/contracts/ERC20.sol

pragma solidity ^0.4.19;


/**
 * @title ERC20
 * @dev A standard interface for tokens.
 * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
 */
contract ERC20 {
  
    /// @dev Returns the total token supply
    function totalSupply() public constant returns (uint256 supply);

    /// @dev Returns the account balance of the account with address _owner
    function balanceOf(address _owner) public constant returns (uint256 balance);

    /// @dev Transfers _value number of tokens to address _to
    function transfer(address _to, uint256 _value) public returns (bool success);

    /// @dev Transfers _value number of tokens from address _from to address _to
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    /// @dev Allows _spender to withdraw from the msg.sender&#39;s account up to the _value amount
    function approve(address _spender, uint256 _value) public returns (bool success);

    /// @dev Returns the amount which _spender is still allowed to withdraw from _owner
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}


///File: giveth-common-contracts/contracts/Owned.sol

pragma solidity ^0.4.19;


/// @title Owned
/// @author Adri&#224; Massanet <adria@codecontext.io>
/// @notice The Owned contract has an owner address, and provides basic 
///  authorization control functions, this simplifies & the implementation of
///  user permissions; this contract has three work flows for a change in
///  ownership, the first requires the new owner to validate that they have the
///  ability to accept ownership, the second allows the ownership to be
///  directly transfered without requiring acceptance, and the third allows for
///  the ownership to be removed to allow for decentralization 
contract Owned {

    address public owner;
    address public newOwnerCandidate;

    event OwnershipRequested(address indexed by, address indexed to);
    event OwnershipTransferred(address indexed from, address indexed to);
    event OwnershipRemoved();

    /// @dev The constructor sets the `msg.sender` as the`owner` of the contract
    function Owned() public {
        owner = msg.sender;
    }

    /// @dev `owner` is the only address that can call a function with this
    /// modifier
    modifier onlyOwner() {
        require (msg.sender == owner);
        _;
    }
    
    /// @dev In this 1st option for ownership transfer `proposeOwnership()` must
    ///  be called first by the current `owner` then `acceptOwnership()` must be
    ///  called by the `newOwnerCandidate`
    /// @notice `onlyOwner` Proposes to transfer control of the contract to a
    ///  new owner
    /// @param _newOwnerCandidate The address being proposed as the new owner
    function proposeOwnership(address _newOwnerCandidate) public onlyOwner {
        newOwnerCandidate = _newOwnerCandidate;
        OwnershipRequested(msg.sender, newOwnerCandidate);
    }

    /// @notice Can only be called by the `newOwnerCandidate`, accepts the
    ///  transfer of ownership
    function acceptOwnership() public {
        require(msg.sender == newOwnerCandidate);

        address oldOwner = owner;
        owner = newOwnerCandidate;
        newOwnerCandidate = 0x0;

        OwnershipTransferred(oldOwner, owner);
    }

    /// @dev In this 2nd option for ownership transfer `changeOwnership()` can
    ///  be called and it will immediately assign ownership to the `newOwner`
    /// @notice `owner` can step down and assign some other address to this role
    /// @param _newOwner The address of the new owner
    function changeOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != 0x0);

        address oldOwner = owner;
        owner = _newOwner;
        newOwnerCandidate = 0x0;

        OwnershipTransferred(oldOwner, owner);
    }

    /// @dev In this 3rd option for ownership transfer `removeOwnership()` can
    ///  be called and it will immediately assign ownership to the 0x0 address;
    ///  it requires a 0xdece be input as a parameter to prevent accidental use
    /// @notice Decentralizes the contract, this operation cannot be undone 
    /// @param _dac `0xdac` has to be entered for this function to work
    function removeOwnership(address _dac) public onlyOwner {
        require(_dac == 0xdac);
        owner = 0x0;
        newOwnerCandidate = 0x0;
        OwnershipRemoved();     
    }
} 


///File: giveth-common-contracts/contracts/Escapable.sol

pragma solidity ^0.4.19;
/*
    Copyright 2016, Jordi Baylina
    Contributor: Adri&#224; Massanet <adria@codecontext.io>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/





/// @dev `Escapable` is a base level contract built off of the `Owned`
///  contract; it creates an escape hatch function that can be called in an
///  emergency that will allow designated addresses to send any ether or tokens
///  held in the contract to an `escapeHatchDestination` as long as they were
///  not blacklisted
contract Escapable is Owned {
    address public escapeHatchCaller;
    address public escapeHatchDestination;
    mapping (address=>bool) private escapeBlacklist; // Token contract addresses

    /// @notice The Constructor assigns the `escapeHatchDestination` and the
    ///  `escapeHatchCaller`
    /// @param _escapeHatchCaller The address of a trusted account or contract
    ///  to call `escapeHatch()` to send the ether in this contract to the
    ///  `escapeHatchDestination` it would be ideal that `escapeHatchCaller`
    ///  cannot move funds out of `escapeHatchDestination`
    /// @param _escapeHatchDestination The address of a safe location (usu a
    ///  Multisig) to send the ether held in this contract; if a neutral address
    ///  is required, the WHG Multisig is an option:
    ///  0x8Ff920020c8AD673661c8117f2855C384758C572 
    function Escapable(address _escapeHatchCaller, address _escapeHatchDestination) public {
        escapeHatchCaller = _escapeHatchCaller;
        escapeHatchDestination = _escapeHatchDestination;
    }

    /// @dev The addresses preassigned as `escapeHatchCaller` or `owner`
    ///  are the only addresses that can call a function with this modifier
    modifier onlyEscapeHatchCallerOrOwner {
        require ((msg.sender == escapeHatchCaller)||(msg.sender == owner));
        _;
    }

    /// @notice Creates the blacklist of tokens that are not able to be taken
    ///  out of the contract; can only be done at the deployment, and the logic
    ///  to add to the blacklist will be in the constructor of a child contract
    /// @param _token the token contract address that is to be blacklisted 
    function blacklistEscapeToken(address _token) internal {
        escapeBlacklist[_token] = true;
        EscapeHatchBlackistedToken(_token);
    }

    /// @notice Checks to see if `_token` is in the blacklist of tokens
    /// @param _token the token address being queried
    /// @return False if `_token` is in the blacklist and can&#39;t be taken out of
    ///  the contract via the `escapeHatch()`
    function isTokenEscapable(address _token) view public returns (bool) {
        return !escapeBlacklist[_token];
    }

    /// @notice The `escapeHatch()` should only be called as a last resort if a
    /// security issue is uncovered or something unexpected happened
    /// @param _token to transfer, use 0x0 for ether
    function escapeHatch(address _token) public onlyEscapeHatchCallerOrOwner {   
        require(escapeBlacklist[_token]==false);

        uint256 balance;

        /// @dev Logic for ether
        if (_token == 0x0) {
            balance = this.balance;
            escapeHatchDestination.transfer(balance);
            EscapeHatchCalled(_token, balance);
            return;
        }
        /// @dev Logic for tokens
        ERC20 token = ERC20(_token);
        balance = token.balanceOf(this);
        require(token.transfer(escapeHatchDestination, balance));
        EscapeHatchCalled(_token, balance);
    }

    /// @notice Changes the address assigned to call `escapeHatch()`
    /// @param _newEscapeHatchCaller The address of a trusted account or
    ///  contract to call `escapeHatch()` to send the value in this contract to
    ///  the `escapeHatchDestination`; it would be ideal that `escapeHatchCaller`
    ///  cannot move funds out of `escapeHatchDestination`
    function changeHatchEscapeCaller(address _newEscapeHatchCaller) public onlyEscapeHatchCallerOrOwner {
        escapeHatchCaller = _newEscapeHatchCaller;
    }

    event EscapeHatchBlackistedToken(address token);
    event EscapeHatchCalled(address token, uint amount);
}


///File: ./contracts/lib/Pausable.sol

pragma solidity ^0.4.21;



/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Owned {
    event Pause();
    event Unpause();

    bool public paused = false;

    /**
    * @dev Modifier to make a function callable only when the contract is not paused.
    */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
    * @dev Modifier to make a function callable only when the contract is paused.
    */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
    * @dev called by the owner to pause, triggers stopped state
    */
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

    /**
    * @dev called by the owner to unpause, returns to normal state
    */
    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}

///File: ./contracts/lib/Vault.sol

pragma solidity ^0.4.21;

/*
    Copyright 2018, Jordi Baylina, RJ Ewing

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

/// @title Vault Contract
/// @author Jordi Baylina, RJ Ewing
/// @notice This contract holds funds for Campaigns and automates payments. For
///  this iteration the funds will come straight from the Giveth Multisig as a
///  safety precaution, but once fully tested and optimized this contract will
///  be a safe place to store funds equipped with optional variable time delays
///  to allow for an optional escape hatch




/// @dev `Vault` is a higher level contract built off of the `Escapable`
///  contract that holds funds for Campaigns and automates payments.
contract Vault is Escapable, Pausable {

    /// @dev `Payment` is a public structure that describes the details of
    ///  each payment making it easy to track the movement of funds
    ///  transparently
    struct Payment {
        string name;              // What is the purpose of this payment
        bytes32 reference;        // Reference of the payment.
        address spender;          // Who is sending the funds
        uint earliestPayTime;     // The earliest a payment can be made (Unix Time)
        bool canceled;            // If True then the payment has been canceled
        bool paid;                // If True then the payment has been paid
        address recipient;        // Who is receiving the funds
        address token;            // Token this payment represents
        uint amount;              // The amount of wei sent in the payment
        uint securityGuardDelay;  // The seconds `securityGuard` can delay payment
    }

    Payment[] public authorizedPayments;

    address public securityGuard;
    uint public absoluteMinTimeLock;
    uint public timeLock;
    uint public maxSecurityGuardDelay;
    bool public allowDisbursePaymentWhenPaused;

    /// @dev The white list of approved addresses allowed to set up && receive
    ///  payments from this vault
    mapping (address => bool) public allowedSpenders;

    // @dev Events to make the payment movements easy to find on the blockchain
    event PaymentAuthorized(uint indexed idPayment, address indexed recipient, uint amount, address token, bytes32 reference);
    event PaymentExecuted(uint indexed idPayment, address indexed recipient, uint amount, address token);
    event PaymentCanceled(uint indexed idPayment);
    event SpenderAuthorization(address indexed spender, bool authorized);

    /// @dev The address assigned the role of `securityGuard` is the only
    ///  addresses that can call a function with this modifier
    modifier onlySecurityGuard { 
        require(msg.sender == securityGuard);
        _;
    }

    /// By default, we dis-allow payment disburements if the contract is paused.
    /// However, to facilitate a migration of the bridge, we can allow
    /// disbursements when paused if explicitly set
    modifier disbursementsAllowed {
        require(!paused || allowDisbursePaymentWhenPaused);
        _;
    }

    /// @notice The Constructor creates the Vault on the blockchain
    /// @param _escapeHatchCaller The address of a trusted account or contract to
    ///  call `escapeHatch()` to send the ether in this contract to the
    ///  `escapeHatchDestination` it would be ideal if `escapeHatchCaller` cannot move
    ///  funds out of `escapeHatchDestination`
    /// @param _escapeHatchDestination The address of a safe location (usu a
    ///  Multisig) to send the ether held in this contract in an emergency
    /// @param _absoluteMinTimeLock The minimum number of seconds `timelock` can
    ///  be set to, if set to 0 the `owner` can remove the `timeLock` completely
    /// @param _timeLock Initial number of seconds that payments are delayed
    ///  after they are authorized (a security precaution)
    /// @param _securityGuard Address that will be able to delay the payments
    ///  beyond the initial timelock requirements; can be set to 0x0 to remove
    ///  the `securityGuard` functionality
    /// @param _maxSecurityGuardDelay The maximum number of seconds in total
    ///   that `securityGuard` can delay a payment so that the owner can cancel
    ///   the payment if needed
    function Vault(
        address _escapeHatchCaller,
        address _escapeHatchDestination,
        uint _absoluteMinTimeLock,
        uint _timeLock,
        address _securityGuard,
        uint _maxSecurityGuardDelay
    ) Escapable(_escapeHatchCaller, _escapeHatchDestination) public
    {
        absoluteMinTimeLock = _absoluteMinTimeLock;
        timeLock = _timeLock;
        securityGuard = _securityGuard;
        maxSecurityGuardDelay = _maxSecurityGuardDelay;
    }

/////////
// Helper functions
/////////

    /// @notice States the total number of authorized payments in this contract
    /// @return The number of payments ever authorized even if they were canceled
    function numberOfAuthorizedPayments() public view returns (uint) {
        return authorizedPayments.length;
    }

////////
// Spender Interface
////////

    /// @notice only `allowedSpenders[]` Creates a new `Payment`
    /// @param _name Brief description of the payment that is authorized
    /// @param _reference External reference of the payment
    /// @param _recipient Destination of the payment
    /// @param _amount Amount to be paid in wei
    /// @param _paymentDelay Number of seconds the payment is to be delayed, if
    ///  this value is below `timeLock` then the `timeLock` determines the delay
    /// @return The Payment ID number for the new authorized payment
    function authorizePayment(
        string _name,
        bytes32 _reference,
        address _recipient,
        address _token,
        uint _amount,
        uint _paymentDelay
    ) whenNotPaused external returns(uint) {

        // Fail if you arent on the `allowedSpenders` white list
        require(allowedSpenders[msg.sender]);
        uint idPayment = authorizedPayments.length;       // Unique Payment ID
        authorizedPayments.length++;

        // The following lines fill out the payment struct
        Payment storage p = authorizedPayments[idPayment];
        p.spender = msg.sender;

        // Overflow protection
        require(_paymentDelay <= 10**18);

        // Determines the earliest the recipient can receive payment (Unix time)
        p.earliestPayTime = _paymentDelay >= timeLock ?
                                _getTime() + _paymentDelay :
                                _getTime() + timeLock;
        p.recipient = _recipient;
        p.amount = _amount;
        p.name = _name;
        p.reference = _reference;
        p.token = _token;
        emit PaymentAuthorized(idPayment, p.recipient, p.amount, p.token, p.reference);
        return idPayment;
    }

    /// Anyone can call this function to disburse the payment to 
    ///  the recipient after `earliestPayTime` has passed
    /// @param _idPayment The payment ID to be executed
    function disburseAuthorizedPayment(uint _idPayment) disbursementsAllowed public {
        // Check that the `_idPayment` has been added to the payments struct
        require(_idPayment < authorizedPayments.length);

        Payment storage p = authorizedPayments[_idPayment];

        // Checking for reasons not to execute the payment
        require(allowedSpenders[p.spender]);
        require(_getTime() >= p.earliestPayTime);
        require(!p.canceled);
        require(!p.paid);

        p.paid = true; // Set the payment to being paid

        // Make the payment
        if (p.token == 0) {
            p.recipient.transfer(p.amount);
        } else {
            require(ERC20(p.token).transfer(p.recipient, p.amount));
        }

        emit PaymentExecuted(_idPayment, p.recipient, p.amount, p.token);
    }

    /// convience function to disburse multiple payments in a single tx
    function disburseAuthorizedPayments(uint[] _idPayments) public {
        for (uint i = 0; i < _idPayments.length; i++) {
            uint _idPayment = _idPayments[i];
            disburseAuthorizedPayment(_idPayment);
        }
    }

/////////
// SecurityGuard Interface
/////////

    /// @notice `onlySecurityGuard` Delays a payment for a set number of seconds
    /// @param _idPayment ID of the payment to be delayed
    /// @param _delay The number of seconds to delay the payment
    function delayPayment(uint _idPayment, uint _delay) onlySecurityGuard external {
        require(_idPayment < authorizedPayments.length);

        // Overflow test
        require(_delay <= 10**18);

        Payment storage p = authorizedPayments[_idPayment];

        require(p.securityGuardDelay + _delay <= maxSecurityGuardDelay);
        require(!p.paid);
        require(!p.canceled);

        p.securityGuardDelay += _delay;
        p.earliestPayTime += _delay;
    }

////////
// Owner Interface
///////

    /// @notice `onlyOwner` Cancel a payment all together
    /// @param _idPayment ID of the payment to be canceled.
    function cancelPayment(uint _idPayment) onlyOwner external {
        require(_idPayment < authorizedPayments.length);

        Payment storage p = authorizedPayments[_idPayment];

        require(!p.canceled);
        require(!p.paid);

        p.canceled = true;
        emit PaymentCanceled(_idPayment);
    }

    /// @notice `onlyOwner` Adds a spender to the `allowedSpenders[]` white list
    /// @param _spender The address of the contract being authorized/unauthorized
    /// @param _authorize `true` if authorizing and `false` if unauthorizing
    function authorizeSpender(address _spender, bool _authorize) onlyOwner external {
        allowedSpenders[_spender] = _authorize;
        emit SpenderAuthorization(_spender, _authorize);
    }

    /// @notice `onlyOwner` Sets the address of `securityGuard`
    /// @param _newSecurityGuard Address of the new security guard
    function setSecurityGuard(address _newSecurityGuard) onlyOwner external {
        securityGuard = _newSecurityGuard;
    }

    /// @notice `onlyOwner` Changes `timeLock`; the new `timeLock` cannot be
    ///  lower than `absoluteMinTimeLock`
    /// @param _newTimeLock Sets the new minimum default `timeLock` in seconds;
    ///  pending payments maintain their `earliestPayTime`
    function setTimelock(uint _newTimeLock) onlyOwner external {
        require(_newTimeLock >= absoluteMinTimeLock);
        timeLock = _newTimeLock;
    }

    /// @notice `onlyOwner` Changes the maximum number of seconds
    /// `securityGuard` can delay a payment
    /// @param _maxSecurityGuardDelay The new maximum delay in seconds that
    ///  `securityGuard` can delay the payment&#39;s execution in total
    function setMaxSecurityGuardDelay(uint _maxSecurityGuardDelay) onlyOwner external {
        maxSecurityGuardDelay = _maxSecurityGuardDelay;
    }

    /// @dev called by the owner to pause the contract. Triggers a stopped state 
    ///  and resets allowDisbursePaymentWhenPaused to false
    function pause() onlyOwner whenNotPaused public {
        allowDisbursePaymentWhenPaused = false;
        super.pause();
    }

    /// Owner can allow payment disbursement when the contract is paused. This is so the
    /// bridge can be upgraded without having to migrate any existing authorizedPayments
    /// @dev only callable whenPaused b/c pausing the contract will reset `allowDisbursePaymentWhenPaused` to false
    /// @param allowed `true` if allowing payments to be disbursed when paused, otherwise &#39;false&#39;
    function setAllowDisbursePaymentWhenPaused(bool allowed) onlyOwner whenPaused public {
        allowDisbursePaymentWhenPaused = allowed;
    }

    // for overidding during testing
    function _getTime() internal view returns (uint) {
        return now;
    }

}

///File: ./contracts/lib/FailClosedVault.sol

pragma solidity ^0.4.21;

/*
    Copyright 2018, RJ Ewing

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */



/**
* @dev `FailClosedVault` is a version of the vault that requires
*  the securityGuard to "see" each payment before it can be collected
*/
contract FailClosedVault is Vault {
    uint public securityGuardLastCheckin;

    /**
    * @param _absoluteMinTimeLock For this version of the vault, it is recommended
    *   that this value is > 24hrs. If not, it will require the securityGuard to checkIn
    *   multiple times a day. Also consider that `securityGuardLastCheckin >= payment.earliestPayTime - timelock + 30mins);`
    *   is the condition to allow payments to be payed. The additional 30 mins is to reduce (not eliminate)
    *   the risk of front-running
    */
    function FailClosedVault(
        address _escapeHatchCaller,
        address _escapeHatchDestination,
        uint _absoluteMinTimeLock,
        uint _timeLock,
        address _securityGuard,
        uint _maxSecurityGuardDelay
    ) Vault(
        _escapeHatchCaller,
        _escapeHatchDestination, 
        _absoluteMinTimeLock,
        _timeLock,
        _securityGuard,
        _maxSecurityGuardDelay
    ) public {
    }

/////////////////////
// Spender Interface
/////////////////////

    /**
    * Disburse an authorizedPayment to the recipient if all checks pass.
    *
    * @param _idPayment The payment ID to be disbursed
    */
    function disburseAuthorizedPayment(uint _idPayment) disbursementsAllowed public {
        // Check that the `_idPayment` has been added to the payments struct
        require(_idPayment < authorizedPayments.length);

        Payment storage p = authorizedPayments[_idPayment];
        // The current minimum delay for a payment is `timeLock`. Thus the following ensuress
        // that the `securityGuard` has checked in after the payment was created
        // @notice earliestPayTime is updated when a payment is delayed. Which may require
        // another checkIn before the payment can be collected.
        // @notice We add 30 mins to this to reduce (not eliminate) the risk of front-running
        require(securityGuardLastCheckin >= p.earliestPayTime - timeLock + 30 minutes);

        super.disburseAuthorizedPayment(_idPayment);
    }

///////////////////////////
// SecurityGuard Interface
///////////////////////////

    /**
    * @notice `onlySecurityGuard` can checkin. If they fail to checkin,
    * payments will not be allowed to be disbursed, unless the payment has
    * an `earliestPayTime` <= `securityGuardLastCheckin`.
    * @notice To reduce the risk of a front-running attack on payments, it
    * is important that this is called with a resonable gasPrice set for the
    * current network congestion. If this tx is not mined, within 30 mins
    * of being sent, it is possible that a payment can be authorized w/o the
    * securityGuard&#39;s knowledge
    */
    function checkIn() onlySecurityGuard external {
        securityGuardLastCheckin = _getTime();
    }
}

///File: ./contracts/GivethBridge.sol

pragma solidity ^0.4.21;

/*
    Copyright 2017, RJ Ewing <perissology@protonmail.com>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/





/**
* @notice It is not recommened to call this function outside of the giveth dapp (giveth.io)
* this function is bridged to a side chain. If for some reason the sidechain tx fails, the donation
* will end up in the givers control inside LiquidPledging contract. If you do not use the dapp, there
* will be no way of notifying the sender/giver that the giver has to take action (withdraw/donate) in
* the dapp
*/
contract GivethBridge is FailClosedVault {

    mapping(address => bool) tokenWhitelist;

    event Donate(uint64 giverId, uint64 receiverId, address token, uint amount);
    event DonateAndCreateGiver(address giver, uint64 receiverId, address token, uint amount);
    event EscapeFundsCalled(address token, uint amount);

    //== constructor

    /**
    * @param _escapeHatchCaller The address of a trusted account or contract to
    *  call `escapeHatch()` to send the ether in this contract to the
    *  `escapeHatchDestination` in the case on an emergency. it would be ideal 
    *  if `escapeHatchCaller` cannot move funds out of `escapeHatchDestination`
    * @param _escapeHatchDestination The address of a safe location (usually a
    *  Multisig) to send the ether held in this contract in the case of an emergency
    * @param _absoluteMinTimeLock The minimum number of seconds `timelock` can
    *  be set to, if set to 0 the `owner` can remove the `timeLock` completely
    * @param _timeLock Minimum number of seconds that payments are delayed
    *  after they are authorized (a security precaution)
    * @param _securityGuard Address that will be able to delay the payments
    *  beyond the initial timelock requirements; can be set to 0x0 to remove
    *  the `securityGuard` functionality
    * @param _maxSecurityGuardDelay The maximum number of seconds in total
    *   that `securityGuard` can delay a payment so that the owner can cancel
    *   the payment if needed
    */
    function GivethBridge(
        address _escapeHatchCaller,
        address _escapeHatchDestination,
        uint _absoluteMinTimeLock,
        uint _timeLock,
        address _securityGuard,
        uint _maxSecurityGuardDelay
    ) FailClosedVault(
        _escapeHatchCaller,
        _escapeHatchDestination,
        _absoluteMinTimeLock,
        _timeLock,
        _securityGuard,
        _maxSecurityGuardDelay
    ) public
    {
        tokenWhitelist[0] = true; // enable eth transfers
    }

    //== public methods

    /**
    * @notice It is not recommened to call this function outside of the giveth dapp (giveth.io)
    * this function is bridged to a side chain. If for some reason the sidechain tx fails, the donation
    * will end up in the givers control inside LiquidPledging contract. If you do not use the dapp, there
    * will be no way of notifying the sender/giver that the giver has to take action (withdraw/donate) in
    * the dapp
    *
    * @param giver The address to create a &#39;giver&#39; pledge admin for in the liquidPledging contract
    * @param receiverId The adminId of the liquidPledging pledge admin receiving the donation
    */
    function donateAndCreateGiver(address giver, uint64 receiverId) payable external {
        donateAndCreateGiver(giver, receiverId, 0, 0);
    }

    /**
    * @notice It is not recommened to call this function outside of the giveth dapp (giveth.io)
    * this function is bridged to a side chain. If for some reason the sidechain tx fails, the donation
    * will end up in the givers control inside LiquidPledging contract. If you do not use the dapp, there
    * will be no way of notifying the sender/giver that the giver has to take action (withdraw/donate) in
    * the dapp
    *
    * @param giver The address to create a &#39;giver&#39; pledge admin for in the liquidPledging contract
    * @param receiverId The adminId of the liquidPledging pledge admin receiving the donation
    * @param token The token to donate. If donating ETH, then 0x0. Note: the token must be whitelisted
    * @param _amount The amount of the token to donate. If donating ETH, then 0x0 as the msg.value will be used instead.
    */
    function donateAndCreateGiver(address giver, uint64 receiverId, address token, uint _amount) whenNotPaused payable public {
        require(giver != 0);
        require(receiverId != 0);
        uint amount = _receiveDonation(token, _amount);
        emit DonateAndCreateGiver(giver, receiverId, token, amount);
    }

    /**
    * @notice It is not recommened to call this function outside of the giveth dapp (giveth.io)
    * this function is bridged to a side chain. If for some reason the sidechain tx fails, the donation
    * will end up in the givers control inside LiquidPledging contract. If you do not use the dapp, there
    * will be no way of notifying the sender/giver that the giver has to take action (withdraw/donate) in
    * the dapp
    *
    * @param giverId The adminId of the liquidPledging pledge admin who is donating
    * @param receiverId The adminId of the liquidPledging pledge admin receiving the donation
    */
    function donate(uint64 giverId, uint64 receiverId) payable external {
        donate(giverId, receiverId, 0, 0);
    }

    /**
    * @notice It is not recommened to call this function outside of the giveth dapp (giveth.io)
    * this function is bridged to a side chain. If for some reason the sidechain tx fails, the donation
    * will end up in the givers control inside LiquidPledging contract. If you do not use the dapp, there
    * will be no way of notifying the sender/giver that the giver has to take action (withdraw/donate) in
    * the dapp
    *
    * @param giverId The adminId of the liquidPledging pledge admin who is donating
    * @param receiverId The adminId of the liquidPledging pledge admin receiving the donation
    * @param token The token to donate. If donating ETH, then 0x0. Note: the token must be whitelisted
    * @param _amount The amount of the token to donate. If donating ETH, then 0x0 as the msg.value will be used instead.
    */
    function donate(uint64 giverId, uint64 receiverId, address token, uint _amount) whenNotPaused payable public {
        require(giverId != 0);
        require(receiverId != 0);
        uint amount = _receiveDonation(token, _amount);
        emit Donate(giverId, receiverId, token, amount);
    }

    /**
    * The `owner` can call this function to add/remove a token from the whitelist
    *
    * @param token The address of the token to update
    * @param accepted Wether or not to accept this token for donations
    */
    function whitelistToken(address token, bool accepted) whenNotPaused onlyOwner external {
        tokenWhitelist[token] = accepted;
    }

    /**
    * Transfer tokens/eth to the escapeHatchDestination.
    * Used as a safety mechanism to prevent the bridge from holding too much value
    *
    * before being thoroughly battle-tested.
    * @param _token the token to transfer. 0x0 for ETH
    * @param _amount the amount to transfer
    */
    function escapeFunds(address _token, uint _amount) external onlyEscapeHatchCallerOrOwner {
        // @dev Logic for ether
        if (_token == 0) {
            escapeHatchDestination.transfer(_amount);
        // @dev Logic for tokens
        } else {
            ERC20 token = ERC20(_token);
            require(token.transfer(escapeHatchDestination, _amount));
        }
        emit EscapeFundsCalled(_token, _amount);
    }

    /**
    * Allow the escapeHatchDestination to deposit eth into this contract w/o calling donate method
    */
    function depositEscapedFunds() external payable {
        require(msg.sender == escapeHatchDestination);
    }

    //== internal methods

    /**
    * @dev used to actually receive the donation. Will transfer the token to to this contract
    */
    function _receiveDonation(address token, uint _amount) internal returns(uint amount) {
        require(tokenWhitelist[token]);
        amount = _amount;

        // eth donation
        if (token == 0) {
            amount = msg.value;
        }

        require(amount > 0);

        if (token != 0) {
            require(ERC20(token).transferFrom(msg.sender, this, amount));
        }
    }
}