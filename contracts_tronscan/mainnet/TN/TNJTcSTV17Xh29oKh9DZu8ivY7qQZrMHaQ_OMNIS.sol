//SourceUnit: OMB.sol

pragma solidity 0.5.9;
/**

Website: www.omnis-bit.com

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error.
 */
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns(uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

/**
 * @title Admined
 * @dev The Admined contract has an owner address, can set administrators,
 * and provides authorization control functions. These features can be used in other contracts
 * through interfacing, so external contracts can check main contract admin levels
 */
contract Admined {
    address public owner; //named owner for etherscan compatibility
    mapping(address => uint256) public level;

    /**
     * @dev The Admined constructor sets the original `owner` of the contract to the sender
     * account and assing high level privileges.
     */
    constructor() public {
        owner = msg.sender;
        level[owner] = 3;
        emit OwnerSet(owner);
        emit LevelSet(owner, level[owner]);
    }

    /**
     * @dev Throws if called by any account with lower level than minLvl.
     * @param _minLvl Minimum level to use the function
     */
    modifier onlyAdmin(uint256 _minLvl) {
        require(level[msg.sender] >= _minLvl, 'You do not have privileges for this transaction');
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyAdmin(3) {
        require(newOwner != address(0), 'Address cannot be zero');

        owner = newOwner;
        level[owner] = 3;

        emit OwnerSet(owner);
        emit LevelSet(owner, level[owner]);

        level[msg.sender] = 0;
        emit LevelSet(msg.sender, level[msg.sender]);
    }

    /**
     * @dev Allows the assignment of new privileges to a new address.
     * @param userAddress The address to transfer ownership to.
     * @param lvl Lvl to assign.
     */
    function setLevel(address userAddress, uint256 lvl) public onlyAdmin(2) {
        require(userAddress != address(0), 'Address cannot be zero');
        require(lvl < level[msg.sender], 'You do not have privileges for this level assignment');
        require(level[msg.sender] > level[userAddress], 'You do not have privileges for this level change');

        level[userAddress] = lvl;
        emit LevelSet(userAddress, level[userAddress]);
    }

    event LevelSet(address indexed user, uint256 lvl);
    event OwnerSet(address indexed user);

}

/**
 * @title TRC20Basic
 * @dev Simpler version of TRC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract TRC20Basic {
    uint256 public totalSupply;

    function balanceOf(address who) public view returns(uint256);

    function transfer(address to, uint256 value) public returns(bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title TRC20 interface
 */
contract TRC20 is TRC20Basic {
    function allowance(address owner, address spender) public view returns(uint256);

    function transferFrom(address from, address to, uint256 value) public returns(bool);

    function approve(address spender, uint256 value) public returns(bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract OMNIS is TRC20, Admined {
    using SafeMath
    for uint256;
    string public name = "OMNIS-BIT";
    string public symbol = "OMB";
    uint8 public decimals = 6;
    uint public totalSupply;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    //AIRDROP RELATED
    struct Airdrop {
        uint value;
        bool claimed;
    }

    address public airdropWallet;

    mapping(address => Airdrop) public airdrops; //One airdrop at a time allowed
    //AIRDROP END

    //ESCROW RELATED
    enum PaymentStatus {
        Requested,
        Rejected,
        Pending,
        Completed,
        Refunded
    }

    struct Payment {
        address provider;
        address customer;
        uint value;
        string comment;
        PaymentStatus status;
        bool refundApproved;
    }

    uint escrowCounter;
    uint public escrowFeePercent = 2; //set to 0.2%

    mapping(uint => Payment) public payments;
    address public collectionAddress;
    //ESCROW END

    //EVENTS
    event NewCollectionWallet(address newWallet);
    event ClaimDrop(address indexed user, uint value);
    event NewAirdropWallet(address newWallet);
    event PaymentCreation(
        uint indexed orderId,
        address indexed provider,
        address indexed customer,
        uint value,
        string description
    );
    event PaymentUpdate(
        uint indexed orderId,
        address indexed provider,
        address indexed customer,
        uint value,
        PaymentStatus status
    );
    event PaymentRefundApprove(
        uint indexed orderId,
        address indexed provider,
        address indexed customer,
        bool status
    );
    ///////////////////////////////////////////////////////////////////

    constructor() public {

       totalSupply = 333333333000000;
        collectionAddress = msg.sender; //Initially fees collection wallet to creator
        airdropWallet = msg.sender; //Initially airdrop wallet to creator
        balances[msg.sender] = totalSupply;

        emit Transfer(address(0), msg.sender, totalSupply);
    }

    /**
     * @dev setCollectionWallet
     * @dev Allow an admin from level 3 to set the Escrow Service Fee Wallet
     * @param _newWallet The new fee wallet
     */
    function setCollectionWallet(address _newWallet) public onlyAdmin(3) {
        require(_newWallet != address(0), 'Address cannot be zero');
        collectionAddress = _newWallet;
        emit NewCollectionWallet(collectionAddress);
    }

    /**
     * @dev setAirDropWallet
     * @dev Allow an admin from level 3 to set the Airdrop Service Wallet
     * @param _newWallet The new Airdrop wallet
     */
    function setAirDropWallet(address _newWallet) public onlyAdmin(3) {
        require(_newWallet != address(0), 'Address cannot be zero');
        airdropWallet = _newWallet;
        emit NewAirdropWallet(airdropWallet);
    }

    //TRC20 FUNCTIONS
    function transfer(address _to, uint256 _value) public returns(bool) {
        require(_to != address(0), 'Address cannot be zero');
        require(_to != address(this), 'Address cannot be this contract');

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function balanceOf(address _owner) public view returns(uint256 balance) {
        return balances[_owner];
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns(bool) {
        require(_to != address(0), 'Address cannot be zero');

        uint256 _allowance = allowed[_from][msg.sender];
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        emit Transfer(_from, _to, _value);

        return true;
    }

    function approve(address _spender, uint256 _value) public returns(bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function allowance(address _owner, address _spender) public view returns(uint256 remaining) {
        return allowed[_owner][_spender];
    }
    //TRC20 END

    //UTILITY FUNCTIONS
    /**
     * @dev batchTransfer
     * @dev Used by the owner to deliver several transfers at the same time (Airdrop)
     * @param _recipients Array of addresses
     * @param _values Array of values
     */
    function batchTransfer(
        address[] calldata _recipients,
        uint[] calldata _values
    )
    external
    onlyAdmin(1)
    returns(bool) {
        //Check data sizes
        require(_recipients.length > 0 && _recipients.length == _values.length, 'Addresses and Values have wrong sizes');
        //Total value calc
        uint total = 0;
        for (uint i = 0; i < _values.length; i++) {
            total = total.add(_values[i]);
        }
        //Sender must hold funds
        require(total <= balances[msg.sender], 'Not enough funds for the transaction');
        //Make transfers
        uint64 _now = uint64(now);
        for (uint j = 0; j < _recipients.length; j++) {
            balances[_recipients[j]] = balances[_recipients[j]].add(_values[j]);
            emit Transfer(msg.sender, _recipients[j], _values[j]);
        }
        //Reduce all balance on a single transaction from sender
        balances[msg.sender] = balances[msg.sender].sub(total);
        return true;
    }

    /**
     * @dev dropSet
     * @dev Used by the owner to set several self-claiming drops at the same time (Airdrop)
     * @param _recipients Array of addresses
     * @param _values Array of values1
     */
    function dropSet(
        address[] calldata _recipients,
        uint[] calldata _values
    )
    external
    onlyAdmin(1)
    returns(bool) {
        //Check data sizes
        require(_recipients.length > 0 && _recipients.length == _values.length, 'Addresses and Values have wrong sizes');

        for (uint j = 0; j < _recipients.length; j++) {
            //Store user drop info
            airdrops[_recipients[j]].value = _values[j];
            airdrops[_recipients[j]].claimed = false;
        }

        return true;
    }

    /**
     * @dev claimAirdrop
     * @dev Allow any user with a drop set to claim it
     */
    function claimAirdrop() external returns(bool) {
        //Check if not claimed
        require(airdrops[msg.sender].claimed == false, 'Airdrop already claimed');
        require(airdrops[msg.sender].value != 0, 'No airdrop value to claim');

        //Original value
        uint _value = airdrops[msg.sender].value;

        //Set as Claimed
        airdrops[msg.sender].claimed = true;
        //Clear value
        airdrops[msg.sender].value = 0;

        //Tokens are on airdropWallet
        address _from = airdropWallet;
        //Tokens goes to costumer
        address _to = msg.sender;
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);

        emit Transfer(_from, _to, _value);
        emit ClaimDrop(_to, _value);

        return true;

    }
    //UTILITY ENDS
    
    //ESCROW FUNCTIONS
    /**
     * @dev createPaymentRequest
     * @dev Allow an user to request start a Escrow process
     * @param _customer Counterpart that will receive payment on success
     * @param _value Amount to be escrowed
     * @param _description Description
     */
    function createPaymentRequest(
        address _customer,
        uint _value,
        string calldata _description
    )
    external
    
    returns(uint) {

        require(_customer != address(0), 'Address cannot be zero');
        require(_value > 0, 'Value cannot be zero');

        payments[escrowCounter] = Payment(msg.sender, _customer, _value, _description, PaymentStatus.Requested, false);
        emit PaymentCreation(escrowCounter, msg.sender, _customer, _value, _description);

        escrowCounter = escrowCounter.add(1);
        return escrowCounter - 1;

    }

    /**
     * @dev answerPaymentRequest
     * @dev Allow a user to answer to a Escrow process
     * @param _orderId the request ticket number
     * @param _answer request answer
     */
    function answerPaymentRequest(uint _orderId, bool _answer) external returns(bool) {
        //Get Payment Handler
        Payment storage payment = payments[_orderId];

        require(payment.status == PaymentStatus.Requested, 'Ticket wrong status, expected "Requested"');
        require(payment.customer == msg.sender, 'You are not allowed to manage this ticket');

        if (_answer == true) {

            address _to = address(this);

            balances[payment.provider] = balances[payment.provider].sub(payment.value);
            balances[_to] = balances[_to].add(payment.value);
            emit Transfer(payment.provider, _to, payment.value);

            payments[_orderId].status = PaymentStatus.Pending;

            emit PaymentUpdate(_orderId, payment.provider, payment.customer, payment.value, PaymentStatus.Pending);

        } else {

            payments[_orderId].status = PaymentStatus.Rejected;

            emit PaymentUpdate(_orderId, payment.provider, payment.customer, payment.value, PaymentStatus.Rejected);

        }

        return true;
    }


    /**
     * @dev release
     * @dev Allow a provider or admin user to release a payment
     * @param _orderId Ticket number of the escrow service
     */
    function release(uint _orderId) external returns(bool) {
        //Get Payment Handler
        Payment storage payment = payments[_orderId];
        //Only if pending
        require(payment.status == PaymentStatus.Pending, 'Ticket wrong status, expected "Pending"');
        //Only owner or token provider
        require(level[msg.sender] >= 2 || msg.sender == payment.provider, 'You are not allowed to manage this ticket');
        //Tokens are on contract
        address _from = address(this);
        //Tokens goes to costumer
        address _to = payment.customer;
        //Original value
        uint _value = payment.value;
        //Fee calculation
        uint _fee = _value.mul(escrowFeePercent).div(1000);
        //Value less fees
        _value = _value.sub(_fee);
        //Costumer transfer
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
        //collectionAddress fee recolection
        balances[_from] = balances[_from].sub(_fee);
        balances[collectionAddress] = balances[collectionAddress].add(_fee);
        emit Transfer(_from, collectionAddress, _fee);



        //Payment Escrow Completed
        payment.status = PaymentStatus.Completed;
        //Emit Event
        emit PaymentUpdate(_orderId, payment.provider, payment.customer, payment.value, payment.status);

        return true;
    }

    /**
     * @dev refund
     * @dev Allow a user to refund a payment
     * @param _orderId Ticket number of the escrow service
     */
    function refund(uint _orderId) external returns(bool) {
        //Get Payment Handler
        Payment storage payment = payments[_orderId];
        //Only if pending
        require(payment.status == PaymentStatus.Pending, 'Ticket wrong status, expected "Pending"');
        //Only if refund was approved
        require(payment.refundApproved, 'Refund has not been approved yet');
        //Only owner or token provider
        require(level[msg.sender] >= 2 || msg.sender == payment.provider, 'You are not allowed to manage this ticket');
        //Tokens are on contract
        address _from = address(this);
        //Tokens go back to provider
        address _to = payment.provider;
        //Original value
        uint _value = payment.value;
        //Provider transfer
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
        
        
        //Payment Escrow Refunded
        payment.status = PaymentStatus.Refunded;
        //Emit Event
        emit PaymentUpdate(_orderId, payment.provider, payment.customer, payment.value, payment.status);

        return true;
    }

    /**
     * @dev approveRefund
     * @dev Allow a user to approve a refund
     * @param _orderId Ticket number of the escrow service
     */
    function approveRefund(uint _orderId) external returns(bool) {
        //Get Payment Handler
        Payment storage payment = payments[_orderId];
        //Only if pending
        require(payment.status == PaymentStatus.Pending, 'Ticket wrong status, expected "Pending"');
        //Only owner or costumer
        require(level[msg.sender] >= 2 || msg.sender == payment.customer, 'You are not allowed to manage this ticket');
        //Approve Refund
        payment.refundApproved = true;

        emit PaymentRefundApprove(_orderId, payment.provider, payment.customer, payment.refundApproved);

        return true;
    }

    //ESCROW END
}