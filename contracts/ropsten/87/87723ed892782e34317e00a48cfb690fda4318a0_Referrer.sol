pragma solidity ^0.4.25;

/*
 * Website: easy.smartolution.org
 *
 * Easiest way to participate in original Smartolution!
 * 
 * Smartolution.org (0xe0ae35fe7Df8b86eF08557b535B89bB6cb036C23)
 * requires daily transactions for 45 days to make a living.
 *
 * This one automates this process:
 * ONE transaction AND 44 automatic payouts! 
 * 
 * How it works?
 * Easy! 
 * Your first and only payment will be split into 45 equal parts
 * and used every day for an automatic payment to smartolution contract!
 * Starting from the day first for 44 days you are going to recieve
 * INCREASING PAYOUTS from original smartolution contract!
 *
 * Send any amount inbetween 0.45 and 225 ether!
 *
 * Minimum: 0.45 ether (0.01 ether daily) ~170% payout @ 45th day
 * Maximum: 225 ehter (5 ether daily) ~155% payout @ 45th day
 * Gas limit: 500 000
 * Recommended gas price: https://ethgasstation.info/
 * 
 */
contract EasySmartolution {

    event ParticipantAdded(address _sender);
    event ParticipantRemoved(address _sender);
    event ReferrerAdded(address _contract, address _sender);

    mapping (address => address) public participants; 
    mapping (address => bool) public referrers;
    
    address private processing;
 
    constructor(address _processing) public {
        processing = _processing;
    }
    
    function () external payable {
        if (participants[msg.sender] == address(0)) {
            addParticipant(msg.sender, address(0));
        } else {
            require(msg.value == 0, "0 ether to manually make a daily payment");

            payment(msg.sender);
        }
    }
    
    function addParticipant(address _sender, address _referrer) payable public {
        require(participants[_sender] == address(0), "This participant is already registered");
        require(msg.value >= 0.45 ether && msg.value <= 225 ether, "Deposit should be between 0.45 ether and 225 ether (45 days)");
        
        participants[_sender] = address(new Participant(_sender, msg.value / 45));
        payment(_sender);
        
        processing.send(msg.value / 20);
        if (_referrer != address(0) && referrers[_referrer]) {
            _referrer.send(msg.value / 20);
        }
  
        emit ParticipantAdded(_sender);
    }
    
    function addReferrer(address _sender) public {
        require(!referrers[_sender], "This address is already a referrer");
        
        referrers[_sender] = true;
        Referrer referrer = new Referrer(address(this), _sender);
        emit ReferrerAdded(address(referrer), _sender);
    }

    function payment(address _sender) public {
        Participant participant = Participant(participants[_sender]);

        bool done = participant.process.value(participant.daily())();
        
        if (done) {
            participants[_sender] = address(0);
            emit ParticipantRemoved(_sender);
        }
    }
}

contract Referrer {
    address public sender;
    address public smartolution;
    
    constructor (address _smartolution, address _sender) public {
        sender = _sender;
        smartolution = _smartolution;
    }
    
    function () external payable {
        if (msg.value > 0) {
            EasySmartolution(smartolution).addParticipant.value(msg.value)(msg.sender, sender);
        } else {
            EasySmartolution(smartolution).payment(msg.sender);
        }
    }
}

contract Participant {
    address constant smartolution = 0xe0ae35fe7Df8b86eF08557b535B89bB6cb036C23;

    address public owner;
    uint public daily;
    uint public index;
    
    constructor(address _owner, uint _daily) public {
        owner = _owner;
        daily = _daily;
        index = 0;
    }
    
    function () external payable {}
    
    function process() external payable returns (bool) {
        require(msg.value == daily, "Invalid value");
        
        smartolution.call.value(msg.value)();
        owner.send(address(this).balance);
        
        return ++index == 45;
    }
    
    function destory() external {
        require(msg.sender == owner, "Only owner can destroy it");
        selfdestruct(msg.sender);
    }
}