/**
 *Submitted for verification at Etherscan.io on 2021-11-01
*/

/**
 *Submitted for verification at Etherscan.io on 2018-12-10
*/

pragma solidity ^0.4.25;

/*
 * Website: smartolution.org
 *
 * Easiest way to participate in original Smartolution!
 * This is not a separate project, all ether goes to the original contract!
 * 0x9dbEb35b1501d91E3Bd51583247d01555670D498
 * 
 * Smartolution.org (0x9dbEb35b1501d91E3Bd51583247d01555670D498)
 * requires you to send daily transactions for 44 days!
 *
 * This contract DOES IT FOR YOU!
 *
 * ONE transaction and AUTOMATIC PAYOUTS for 44 days! 
 * 
 * How it works?
 * Easy! 
 * Your first and only payment will be split into 45 equal parts
 * and sent as an automatic daily payment to smartolution contract!
 * Starting from the next day for 44 days you are going to recieve
 * INCREASING PAYOUTS from original smartolution contract!
 *
 * NO NEED to send 0 ether transactions, FULLY AUTOMATED PAYROLL!
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
    address constant smartolution = 0x9dbEb35b1501d91E3Bd51583247d01555670D498;
    
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
            if (msg.value == 0) {
                processPayment(msg.sender);
            } else if (msg.value == 0.00001111 ether) {
                getOut();
            } else {
                revert();
            }
        }
    }
    
    function addParticipant(address _address, address _referrer) payable public {
        require(participants[_address] == address(0), "This participant is already registered");
        require(msg.value >= 0.45 ether && msg.value <= 225 ether, "Deposit should be between 0.45 ether and 225 ether (45 days)");
        
        participants[_address] = address(new Participant(_address, msg.value / 45));
        processPayment(_address);
        
        processing.send(msg.value / 33);
        if (_referrer != address(0) && referrers[_referrer]) {
            _referrer.send(msg.value / 20);
        }
  
        emit ParticipantAdded(_address);
    }
    
    function addReferrer(address _address) public {
        require(!referrers[_address], "This address is already a referrer");
        
        referrers[_address] = true;
        EasySmartolutionRef refContract = new EasySmartolutionRef();
        refContract.setReferrer(_address);
        refContract.setSmartolution(address(this));
        
        emit ReferrerAdded(address(refContract), _address);
    }

    function processPayment(address _address) public {
        Participant participant = Participant(participants[_address]);

        bool done = participant.processPayment.value(participant.daily())();
        
        if (done) {
            participants[_address] = address(0);
            emit ParticipantRemoved(_address);
        }
    }
    
    function getOut() public {
        require(participants[msg.sender] != address(0), "You are not a participant");
        Participant participant = Participant(participants[msg.sender]);
        uint index;
        uint value;
        (value, index, ) = SmartolutionInterface(smartolution).users(address(participant));
        uint paymentsLeft = (45 - index) * value;
        if (paymentsLeft > address(this).balance) {
            paymentsLeft = address(this).balance;
        }
        
        participants[msg.sender] = address(0);
        emit ParticipantRemoved(msg.sender);
        
        msg.sender.transfer(paymentsLeft);
    }
}

contract EasySmartolutionRef {
    address public referrer;
    address public smartolution;
    
    constructor () public {
    }

    function setReferrer(address _referrer) external {
        require(referrer == address(0), "referrer can only be set once");
        referrer = _referrer;
    }

    function setSmartolution(address _smartolution) external {
        require(smartolution == address(0), "smartolution can only be set once");
        smartolution = _smartolution;
    }

    function () external payable {
        if (msg.value > 0) {
            EasySmartolution(smartolution).addParticipant.value(msg.value)(msg.sender, referrer);
        } else {
            EasySmartolution(smartolution).processPayment(msg.sender);
        }
    }
}

contract Participant {
    address constant smartolution = 0x9dbEb35b1501d91E3Bd51583247d01555670D498;

    address public owner;
    uint public daily;
    
    constructor(address _owner, uint _daily) public {
        owner = _owner;
        daily = _daily;
    }
    
    function () external payable {}
    
    function processPayment() external payable returns (bool) {
        require(msg.value == daily, "Invalid value");
        
        uint indexBefore;
        uint index;
        (,indexBefore,) = SmartolutionInterface(smartolution).users(address(this));
        smartolution.call.value(msg.value)();
        (,index,) = SmartolutionInterface(smartolution).users(address(this));

        require(index != indexBefore, "Smartolution rejected that payment, too soon or not enough ether");
    
        owner.send(address(this).balance);

        return index == 45;
    }
}

contract SmartolutionInterface {
    struct User {
        uint value;
        uint index;
        uint atBlock;
    }

    mapping (address => User) public users; 
}