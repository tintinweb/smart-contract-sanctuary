/**
 *Submitted for verification at Etherscan.io on 2021-05-12
*/

pragma solidity ^0.8.2;
pragma experimental ABIEncoderV2;

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract CommissionsStudio {
    
    using SafeMath for uint256;
    
    enum CommissionStatus { queued, accepted, removed  }
    
    struct Creator {
        uint newQueueId;
        mapping (uint => Queue) queues;
    }
    
    struct Queue {
        uint minBid;
        uint newCommissionId;
        mapping (uint => Commission) commissions;
    }
    
    struct Commission {
        address payable recipient;
        uint bid;
        CommissionStatus status;
    }

    address payable public admin; // the recipient of all fees
    uint public fee; // stored as basis points
    
    mapping(address => Creator) public creators;
        
    bool public callStarted; // ensures no re-entrancy can occur

    modifier callNotStarted () {
      require(!callStarted);
      callStarted = true;
      _;
      callStarted = false;
    }
    
    modifier onlyAdmin () {
        require(msg.sender == admin, "not the admin");
        _;
    }
    
    modifier isValidQueue (address _creator, uint _queueId) {
        require(_queueId < creators[_creator].newQueueId, "queue not valid");
        _;
    }
    
    modifier isValidCommission (address _creator, uint _queueId, uint _commissionId) {
        require(_commissionId < creators[_creator].queues[_queueId].newCommissionId, "commission not valid");
        _;
    }
    
    constructor(address payable _admin, uint _fee) {
        admin = _admin;
        fee = _fee;
    }
     
    function updateAdmin (address payable _newAdmin)
    public
    callNotStarted
    onlyAdmin
    {
        admin = _newAdmin;
        emit AdminUpdated(_newAdmin);
    }
    
    function updateFee (uint _newFee)
    public
    callNotStarted
    onlyAdmin
    {
        fee = _newFee;
        emit FeeUpdated(_newFee);
    }
    
    function registerQueue(uint _minBid, string memory _queueHash) 
    public
    callNotStarted
    {        
        Queue storage newQueue = creators[msg.sender].queues[creators[msg.sender].newQueueId];
        newQueue.minBid = _minBid;
        
        emit QueueRegistered(msg.sender, creators[msg.sender].newQueueId, _minBid, _queueHash);
        creators[msg.sender].newQueueId++;
    }
    
    function updateQueueMinBid(uint _queueId, uint _newMinBid)
    public
    callNotStarted
    isValidQueue(msg.sender, _queueId)
    {
        Queue storage queue = creators[msg.sender].queues[_queueId];        
        queue.minBid = _newMinBid;
        
        emit MinBidUpdated(msg.sender, _queueId, _newMinBid);
    }
    
    function commission (address _creator, uint _queueId, string memory _hash)
    public
    payable
    callNotStarted
    isValidQueue(_creator, _queueId)
    {
        Queue storage queue = creators[_creator].queues[_queueId];        
        require(msg.value >= queue.minBid, "bid below minimum for this queue"); // must send the proper amount of into the bid
        
        // Next, initialize the new commission
        Commission storage newCommission = queue.commissions[queue.newCommissionId];
        newCommission.recipient = payable(msg.sender);
        newCommission.bid = msg.value;
        newCommission.status = CommissionStatus.queued;
                      
        emit NewCommission(_creator, _queueId, queue.newCommissionId, _hash);
        
        queue.newCommissionId++;
    }
    
    function rescindCommission (address _creator, uint _queueId, uint _commissionId) 
    public
    callNotStarted
    isValidQueue(_creator, _queueId)
    {
        Queue storage queue = creators[_creator].queues[_queueId];        
        require(_commissionId < queue.newCommissionId, "commission not valid"); // must be a valid previously instantiated commission
        Commission storage selectedCommission = queue.commissions[_commissionId];
        require(msg.sender == selectedCommission.recipient, "commission not yours"); // may only be performed by the person who commissioned it
        require(selectedCommission.status == CommissionStatus.queued, "commission not in queue"); // the commission must still be queued
      
        // we mark it as removed and return the individual their bid
        selectedCommission.status = CommissionStatus.removed;
        selectedCommission.recipient.transfer(selectedCommission.bid);
        
        emit CommissionRescinded(_creator, _queueId, _commissionId);
    }
    
    function increaseCommissionBid (address _creator, uint _queueId, uint _commissionId)
    public
    payable
    callNotStarted
    isValidQueue(_creator, _queueId)
    {
        Queue storage queue = creators[_creator].queues[_queueId];        
        require(_commissionId < queue.newCommissionId, "commission not valid"); // must be a valid previously instantiated commission
        Commission storage selectedCommission = queue.commissions[_commissionId];
        require(msg.sender == selectedCommission.recipient, "commission not yours"); // may only be performed by the person who commissioned it
        require(selectedCommission.status == CommissionStatus.queued, "commission not in queue"); // the commission must still be queued

        // then we update the commission's bid
        selectedCommission.bid = msg.value + selectedCommission.bid;
        
        emit CommissionBidUpdated(_creator, _queueId, _commissionId, selectedCommission.bid);
    }
    
    function processCommissions(uint _queueId, uint[] memory _commissionIds)
    public
    callNotStarted
    isValidQueue(msg.sender, _queueId)
    {
        Queue storage queue = creators[msg.sender].queues[_queueId];        
        for (uint i = 0; i < _commissionIds.length; i++){
            require(_commissionIds[i] < queue.newCommissionId, "commission not valid"); // must be a valid previously instantiated commission
            Commission storage selectedCommission = queue.commissions[_commissionIds[i]];
            require(selectedCommission.status == CommissionStatus.queued, "commission not in queue");  
            
            uint feePaid = (selectedCommission.bid * fee) / 10000;
            admin.transfer(feePaid);
            
            selectedCommission.status = CommissionStatus.accepted; // first, we change the status of the commission to accepted
            payable(msg.sender).transfer(selectedCommission.bid - feePaid); // next we accept the payment for the commission
            
            emit CommissionProcessed(msg.sender, _queueId, _commissionIds[i]);
        }
    }
    
    function getCreator(address _creator)
    public
    view
    returns (uint)
    {
        return creators[_creator].newQueueId;
    }
    
    function getQueue(address _creator, uint _queueId)
    public
    view
    returns (uint, uint)
    {
        return ( creators[_creator].queues[_queueId].minBid, creators[_creator].queues[_queueId].newCommissionId );
    }
    
    function getCommission(address _creator, uint _queueId, uint _commissionId)
    public
    view
    returns (Commission memory)
    {
        return creators[_creator].queues[_queueId].commissions[_commissionId];
    }
    
    event AdminUpdated(address _newAdmin);
    event FeeUpdated(uint _newFee);
    event MinBidUpdated(address _creator, uint _queueId, uint _newMinBid);
    event QueueRegistered(address _creator, uint _queueId, uint _minBid, string _hash);
    event NewCommission(address _creator, uint _queueId, uint _commissionId, string _hash);
    event CommissionBidUpdated(address _creator, uint _queueId, uint _commissionId, uint _newBid);
    event CommissionRescinded(address _creator, uint _queueId, uint _commissionId);
    event CommissionProcessed(address _creator, uint _queueId, uint _commissionId);
}