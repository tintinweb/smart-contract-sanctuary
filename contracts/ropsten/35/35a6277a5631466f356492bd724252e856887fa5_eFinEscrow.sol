pragma solidity ^0.4.23;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

contract Pausible is Ownable {
    bool public isPaused = false;

    modifier onlyPaused() {
        require(isPaused);
        _;
    }

    modifier onlyInService() {
        require(!isPaused);
        _;
    }

    function pause() public onlyInService onlyOwner {
        isPaused = true;
    }

    function unpause() public onlyPaused onlyOwner {
        isPaused = false;
    }
}

contract Escrows is Pausible {
    using SafeMath for uint256;

    uint8 constant OWNER_CREATED = 0;
    uint8 constant DEPOSITED = 1;
    uint8 constant OWNER_APPROVED = 2;
    uint8 constant TAKER_APPROVED = 3;
    uint8 constant CANCELLED = 4;
    uint8 constant COMPLETED = 5;
    uint8 constant REFUNDED = 6;
    uint8 constant IN_DISPUTE = 7;

    struct Escrow {
        uint createdAt;
        address owner;
        address taker;
        address arbitrator;
        uint balance;
        uint8 status;
        uint withdrawAmountOwner;
        uint withdrawAmountTaker;
        uint withdrawAmountArbitrator;
        bool ownerApproved;
        bool takerApproved;
        address withdrawRequestSender;
    }
    
    struct Dispute {
        uint ownerAmountDispute;
        uint takerAmountDispute;
        uint arbitratorAmountDisputeOwner;
        uint arbitratorAmountDisputeTaker;
    }

    Escrow[] public escrows;
    Dispute public dispute;
    
    uint public totalEscrowsCount;

    mapping (address => uint) escrowCountByOwner;
    mapping (address => uint) escrowCountByTaker;
    mapping (uint => Dispute) escrowDispute;

    /* Loggers */
    event LogEscrow(uint escrowId, address owner, address taker, address arbitrator, uint balance, uint8 status);
    event LogDepositEscrow(uint escrowId, address owner, address taker, address arbitrator, uint balance);
    event LogCompleteEscrow(uint escrowId, address owner, address taker, address arbitrator, uint balance);
    event LogDisputeEscrow(uint escrowId, address owner, address taker, address arbitrator, uint balance);

    function logEscrow(uint _id, Escrow _escrow) internal {

        emit LogEscrow(_id, _escrow.owner, _escrow.taker, _escrow.arbitrator, _escrow.balance, _escrow.status);

        if (_escrow.status == DEPOSITED) {
            emit LogDepositEscrow(_id, _escrow.owner, _escrow.taker, _escrow.arbitrator, _escrow.balance);
        } else if (_escrow.status == COMPLETED) {
            emit LogCompleteEscrow(_id, _escrow.owner, _escrow.taker, _escrow.arbitrator, _escrow.balance);
        } else if (_escrow.status == IN_DISPUTE) {
            emit LogDisputeEscrow(_id, _escrow.owner, _escrow.taker, _escrow.arbitrator, _escrow.balance);
        }
    }

    /* Modifiers */
    modifier onlyStatus(uint _id, uint _status) {
        require(escrows[_id].status == _status);
        _;
    }

    modifier onlyAuthorized(uint _id) {
        Escrow memory escrow = escrows[_id];
        require(msg.sender == escrow.owner || msg.sender == escrow.taker);
        _;
    }

    modifier onlyTaker(uint _id) {
        Escrow memory escrow = escrows[_id];
        require(msg.sender == escrow.taker);
        _;
    }

    modifier onlyArbitrator(uint _id) {
        Escrow memory escrow = escrows[_id];
        require(msg.sender == escrow.arbitrator);
        _;
    }

    modifier onlyCreator(uint _id) {
        Escrow memory escrow = escrows[_id];
        require(msg.sender == escrow.owner);
        _;
    }

    modifier requireBalance(uint _id) {
        Escrow memory escrow = escrows[_id];
        require(escrow.balance > 0);
        _;
    }

    /* Utility Modifiers */
    modifier onlyValidAddress(address _address) {
        require(_address != 0x0);
        _;
    }

    /* Creator */
    function _addNewEscrow(
        address _owner,
        address _taker,
        address _arbitrator,
        uint8 _status
        ) internal {
        require(_owner != _taker);
        uint id = escrows.push(Escrow(now, _owner, _taker, _arbitrator, _status, 0, 0, 0, 0, false, false,0x0));
        totalEscrowsCount++;
        escrowCountByOwner[_owner] = escrowCountByOwner[_owner].add(1);
        escrowCountByTaker[_taker] = escrowCountByTaker[_taker].add(1);

        emit LogEscrow(id, _owner, _taker, _arbitrator, 0, _status);
    }
}

contract eFinEscrow is Escrows {

    function createNewEscrow(address owner, address taker, address arbitrator) external onlyValidAddress(owner) {
        require(owner != taker);
        _addNewEscrow(owner, taker, arbitrator, OWNER_CREATED);
    }

    // Owner/Taker deposits into the Escrow
    function deposit(uint _id) external payable onlyAuthorized(_id) {
        Escrow storage escrow = escrows[_id];
        escrow.balance += msg.value;
        logEscrow(_id, escrow);
    }
    
    function getEscrowById(uint _id) external view returns(
        uint createdAt,
        address owner,
        address taker,
        address arbitrator,
        uint balance,
        uint8 status,
        uint withdrawAmountOwner,
        uint withdrawAmountTaker,
        uint withdrawAmountArbitrator,
        bool ownerApproved,
        bool takerApproved) {
        Escrow storage escrow = escrows[_id];

        return(
            escrow.createdAt,
            escrow.owner,
            escrow.taker,
            escrow.arbitrator,
            escrow.balance,
            escrow.status,
            escrow.withdrawAmountOwner,
            escrow.withdrawAmountTaker,
            escrow.withdrawAmountArbitrator,
            escrow.ownerApproved,
            escrow.takerApproved
        );
        
    }

    // Seller Approves the Escrow Transaction // After the Buyer deposits.
    function ownerApproves(uint _id) external onlyCreator(_id) requireBalance(_id) {
        escrows[_id].status = OWNER_APPROVED;
        escrows[_id].ownerApproved = true;
        logEscrow(_id, escrows[_id]);
    }

    // Buyer Approves the Escrow Transaction // After the Seller approves
    function takerApproves(uint _id) external onlyTaker(_id) requireBalance(_id) {
        escrows[_id].status = TAKER_APPROVED;
        escrows[_id].takerApproved = true;
        logEscrow(_id, escrows[_id]);
    }

    // Owner or Taker cancels the Escrow Transaction // Escrow Status must be CREATED or DEPOSITED
    function cancel(uint _id) external onlyAuthorized(_id) {
        Escrow storage escrow = escrows[_id];
        require(escrow.status <= DEPOSITED);
        escrow.status = CANCELLED;

        logEscrow(_id, escrow);
    }
    
    function withdrawRequest(uint _id, 
                             uint _ownerAmount, 
                             uint _takerAmount, 
                             uint _arbitratorAmount) external onlyAuthorized(_id){
                                 
        Escrow storage escrow = escrows[_id];
        require(escrow.takerApproved && escrow.ownerApproved);
        escrow.withdrawAmountOwner = _ownerAmount;
        escrow.withdrawAmountTaker = _takerAmount;
        escrow.withdrawAmountArbitrator = _arbitratorAmount;
        escrow.withdrawRequestSender = msg.sender;
    }

    // Owner/Taker/Arbitrator withdraws the Escrow balance // Escrow status must be APPROVED
    function withdraw(uint _id) external requireBalance(_id) {
        Escrow storage escrow = escrows[_id];
        require(escrow.withdrawRequestSender != msg.sender); //Withdraw could not be completed by the same user that requested it
        require(escrow.takerApproved && escrow.ownerApproved);
        escrow.owner.transfer(escrow.withdrawAmountOwner);
        escrow.taker.transfer(escrow.withdrawAmountTaker);
        escrow.arbitrator.transfer(escrow.withdrawAmountArbitrator);
        escrow.balance = 0;
        escrow.status = COMPLETED;
        
        logEscrow(_id, escrow);
    }



    function ownerDispute(uint _id, uint _ownerAmount, uint _arbitratorAmount) external onlyCreator(_id) {
        Escrow storage escrow = escrows[_id];
        uint incomingBalance = _ownerAmount.add(_arbitratorAmount);
        require(incomingBalance == escrow.balance); // incoming values should be equal to escrow balance
        escrow.status = IN_DISPUTE;
        Dispute storage dispute = escrowDispute[_id];
        dispute.ownerAmountDispute = _ownerAmount;
        dispute.arbitratorAmountDisputeOwner = _arbitratorAmount;
        
        logEscrow(_id, escrow);
    }
    
    function takerDispute(uint _id, uint _takerAmount, uint _arbitratorAmount) external onlyTaker(_id) {
        Escrow storage escrow = escrows[_id];
        uint incomingBalance = _takerAmount.add(_arbitratorAmount);
        require(incomingBalance == escrow.balance); // incoming values should be equal to escrow balance
        escrow.status = IN_DISPUTE;
        Dispute storage dispute = escrowDispute[_id];
        dispute.takerAmountDispute = _takerAmount;
        dispute.arbitratorAmountDisputeTaker = _arbitratorAmount;

        logEscrow(_id, escrow);
    }
    
    

    // Owner decides if the decision is to Approve or Cancel the Escrow
    function arbitrate(uint _id, bool ownerWin) external onlyArbitrator(_id) onlyStatus(_id, IN_DISPUTE) {
        
        Escrow storage escrow = escrows[_id];
        Dispute storage dispute = escrowDispute[_id];
        
        if(ownerWin){
            escrow.owner.transfer(dispute.ownerAmountDispute);
            escrow.arbitrator.transfer(dispute.arbitratorAmountDisputeOwner);
            escrow.balance = 0;
            escrow.status = COMPLETED;
        } else {
            escrow.taker.transfer(dispute.takerAmountDispute);
            escrow.arbitrator.transfer(dispute.arbitratorAmountDisputeTaker);
            escrow.balance = 0;
            escrow.status = COMPLETED;
        }

        logEscrow(_id, escrow);
    }

    function getBalanceByEscrowId(uint _id) external view returns (uint) {
        return escrows[_id].balance;
    }

    function getEscrowsByOwner(address _owner) external view returns (uint[]) {
        uint[] memory result = new uint[](escrowCountByOwner[_owner]);

        uint counter = 0;
        for (uint i = 0; i < escrows.length; i++) {
            if (escrows[i].owner == _owner) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }

    function getEscrowsByTaker(address _taker) external view returns (uint[]) {
        uint[] memory result = new uint[](escrowCountByTaker[_taker]);

        uint counter = 0;
        for (uint i = 0; i < escrows.length; i++) {
            if (escrows[i].taker == _taker) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }

    function getBalance() external view onlyOwner returns (uint) {
        return address(this).balance;
    }
}