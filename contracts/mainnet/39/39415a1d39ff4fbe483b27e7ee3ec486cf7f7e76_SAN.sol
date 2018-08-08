pragma solidity ^0.4.11;

contract Base {

    function max(uint a, uint b) returns (uint) { return a >= b ? a : b; }
    function min(uint a, uint b) returns (uint) { return a <= b ? a : b; }

    modifier only(address allowed) {
        if (msg.sender != allowed) throw;
        _;
    }


    ///@return True if `_addr` is a contract
    function isContract(address _addr) constant internal returns (bool) {
        if (_addr == 0) return false;
        uint size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    // *************************************************
    // *          reentrancy handling                  *
    // *************************************************

    //@dev predefined locks (up to uint bit length, i.e. 256 possible)
    uint constant internal L00 = 2 ** 0;
    uint constant internal L01 = 2 ** 1;
    uint constant internal L02 = 2 ** 2;
    uint constant internal L03 = 2 ** 3;
    uint constant internal L04 = 2 ** 4;
    uint constant internal L05 = 2 ** 5;

    //prevents reentrancy attacs: specific locks
    uint private bitlocks = 0;
    modifier noReentrancy(uint m) {
        var _locks = bitlocks;
        if (_locks & m > 0) throw;
        bitlocks |= m;
        _;
        bitlocks = _locks;
    }

    modifier noAnyReentrancy {
        var _locks = bitlocks;
        if (_locks > 0) throw;
        bitlocks = uint(-1);
        _;
        bitlocks = _locks;
    }

    ///@dev empty marking modifier signaling to user of the marked function , that it can cause an reentrant call.
    ///     developer should make the caller function reentrant-safe if it use a reentrant function.
    modifier reentrant { _; }

}

contract Owned is Base {

    address public owner;
    address public newOwner;

    function Owned() {
        owner = msg.sender;
    }

    function transferOwnership(address _newOwner) only(owner) {
        newOwner = _newOwner;
    }

    function acceptOwnership() only(newOwner) {
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    event OwnershipTransferred(address indexed _from, address indexed _to);

}


contract ERC20 is Owned {

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function transfer(address _to, uint256 _value) isStartedOnly returns (bool success) {
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) isStartedOnly returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) isStartedOnly returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    uint256 public totalSupply;
    bool    public isStarted = false;

    modifier onlyHolder(address holder) {
        if (balanceOf(holder) == 0) throw;
        _;
    }

    modifier isStartedOnly() {
        if (!isStarted) throw;
        _;
    }

}


contract SubscriptionModule {
    function attachToken(address addr) public ;
}

contract SAN is Owned, ERC20 {

    string public constant name     = "SANtiment TEST token";
    string public constant symbol   = "SAN.TEST.MAX.2";
    uint8  public constant decimals = 15;

    address CROWDSALE_MINTER = 0x2eCae89ebd1DdE40E39D04f515E1f8E64AB939bd;
    address public SUBSCRIPTION_MODULE = 0x00000000;
    address public beneficiary;

    uint public PLATFORM_FEE_PER_10000 = 1; //0.01%
    uint public totalOnDeposit;
    uint public totalInCirculation;

    ///@dev constructor
    function SAN() {
        beneficiary = owner = msg.sender;
    }

    // ------------------------------------------------------------------------
    // Don&#39;t accept ethers
    // ------------------------------------------------------------------------
    function () {
        throw;
    }

    //======== SECTION Configuration: Owner only ========
    //
    ///@notice set beneficiary - the account receiving platform fees.
    function setBeneficiary(address newBeneficiary)
    external
    only(owner) {
        beneficiary = newBeneficiary;
    }


    ///@notice attach module managing subscriptions. if subModule==0x0, then disables subscription functionality for this token.
    /// detached module can usually manage subscriptions, but all operations changing token balances are disabled.
    function attachSubscriptionModule(SubscriptionModule subModule)
    noAnyReentrancy
    external
    only(owner) {
        SUBSCRIPTION_MODULE = subModule;
        if (address(subModule) > 0) subModule.attachToken(this);
    }

    ///@notice set platform fee denominated in 1/10000 of SAN token. Thus "1" means 0.01% of SAN token.
    function setPlatformFeePer10000(uint newFee)
    external
    only(owner) {
        require (newFee <= 10000); //formally maximum fee is 100% (completely insane but technically possible)
        PLATFORM_FEE_PER_10000 = newFee;
    }


    //======== Interface XRateProvider: a trivial exchange rate provider. Rate is 1:1 and SAN symbol as the code
    //
    ///@dev used as a default XRateProvider (id==0) by subscription module.
    ///@notice returns always 1 because exchange rate of the token to itself is always 1.
    function getRate() returns(uint32 ,uint32) { return (1,1);  }
    function getCode() public returns(string)  { return symbol; }


    //==== Interface ERC20ModuleSupport: Subscription, Deposit and Payment Support =====
    ///
    ///@dev used by subscription module to operate on token balances.
    ///@param msg_sender should be an original msg.sender provided to subscription module.
    function _fulfillPreapprovedPayment(address _from, address _to, uint _value, address msg_sender)
    public
    onlyTrusted
    returns(bool success) {
        success = _from != msg_sender && allowed[_from][msg_sender] >= _value;
        if (!success) {
            Payment(_from, _to, _value, _fee(_value), msg_sender, PaymentStatus.APPROVAL_ERROR, 0);
        } else {
            success = _fulfillPayment(_from, _to, _value, 0, msg_sender);
            if (success) {
                allowed[_from][msg_sender] -= _value;
            }
        }
        return success;
    }

    ///@dev used by subscription module to operate on token balances.
    ///@param msg_sender should be an original msg.sender provided to subscription module.
    function _fulfillPayment(address _from, address _to, uint _value, uint subId, address msg_sender)
    public
    onlyTrusted
    returns (bool success) {
        var fee = _fee(_value);
        assert (fee <= _value); //internal sanity check
        if (balances[_from] >= _value && balances[_to] + _value > balances[_to]) {
            balances[_from] -= _value;
            balances[_to] += _value - fee;
            balances[beneficiary] += fee;
            Payment(_from, _to, _value, fee, msg_sender, PaymentStatus.OK, subId);
            return true;
        } else {
            Payment(_from, _to, _value, fee, msg_sender, PaymentStatus.BALANCE_ERROR, subId);
            return false;
        }
    }

    function _fee(uint _value) internal constant returns (uint fee) {
        return _value * PLATFORM_FEE_PER_10000 / 10000;
    }

    ///@notice used by subscription module to re-create token from returning deposit.
    ///@dev a subscription module is responsible to correct deposit management.
    function _mintFromDeposit(address owner, uint amount)
    public
    onlyTrusted {
        balances[owner] += amount;
        totalOnDeposit -= amount;
        totalInCirculation += amount;
    }

    ///@notice used by subscription module to burn token while creating a new deposit.
    ///@dev a subscription module is responsible to create and maintain the deposit record.
    function _burnForDeposit(address owner, uint amount)
    public
    onlyTrusted
    returns (bool success) {
        if (balances[owner] >= amount) {
            balances[owner] -= amount;
            totalOnDeposit += amount;
            totalInCirculation -= amount;
            return true;
        } else { return false; }
    }

    //========= Crowdsale Only ===============
    ///@notice mint new token for given account in crowdsale stage
    ///@dev allowed only if token not started yet and only for registered minter.
    ///@dev tokens are become in circulation after token start.
    function mint(uint amount, address account)
    onlyCrowdsaleMinter
    isNotStartedOnly
    {
        totalSupply += amount;
        balances[account]+=amount;
    }

    ///@notice start normal operation of the token. No minting is possible after this point.
    function start()
    isNotStartedOnly
    only(owner) {
        totalInCirculation = totalSupply;
        isStarted = true;
    }

    //========= SECTION: Modifier ===============

    modifier onlyCrowdsaleMinter() {
        if (msg.sender != CROWDSALE_MINTER) throw;
        _;
    }

    modifier onlyTrusted() {
        if (msg.sender != SUBSCRIPTION_MODULE) throw;
        _;
    }

    ///@dev token not started means minting is possible, but usual token operations are not.
    modifier isNotStartedOnly() {
        if (isStarted) throw;
        _;
    }

    enum PaymentStatus {OK, BALANCE_ERROR, APPROVAL_ERROR}
    ///@notice event issued on any fee based payment (made of failed).
    ///@param subId - related subscription Id if any, or zero otherwise.
    event Payment(address _from, address _to, uint _value, uint _fee, address caller, PaymentStatus status, uint subId);

}//contract SAN