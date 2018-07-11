pragma solidity 0.4.24 ;

contract Bit {
    address public moderator;
    address public p1;
    address public p2;
    address public winner;
    uint public amount;
    bool public outcome;
    bool public c1;
    bool public c2;
    uint public commission;
    
    constructor(address _p1, address _p2, uint _amount, uint _commission) public {
        moderator = msg.sender;
        p1 = _p1;
        p2 = _p2;
        amount = _amount;
        commission = ((_amount*2)/100)*_commission;
    }
    
    modifier isMod {
        require(moderator==msg.sender);
        _;
    }
    
    function placeBet(bool _c) payable public {
        if(msg.sender==p1 && msg.value==amount) {
            c1 = _c;
            return;
        }
        else if(msg.sender==p2 && msg.value==amount) {
            c2 = _c;
            return;
        }
        else 
            return;
    }
    
    function toss(bool _outcome) isMod public {
        outcome = _outcome;
        if(_outcome==c1 && _outcome!=c2) {
            winner = p1;
            moderator.transfer(commission);
            return;
        }
        else if(_outcome==c2 && _outcome!=c1) {
            winner = p2;
            moderator.transfer(commission);
            return;
        }
        else if(_outcome==c1 && _outcome==c2) {
            return;
        }
        else {
            moderator.transfer(amount*2);
            return;
        }
    }
    function takeMoney() public {
        if(msg.sender==winner) {
            winner.transfer((amount*2)-commission);
            return;
        }
        else if (outcome == c1 && outcome == c2) {
            p1.transfer(amount);
            p2.transfer(amount);
            return;
        }
        if(msg.sender!=winner) {
            return;
        }
    }
}