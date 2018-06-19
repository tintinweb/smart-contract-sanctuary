pragma solidity ^0.4.4;

contract Token {
    function transfer(address _to, uint _value) returns (bool);
    function balanceOf(address owner) returns(uint);
}


contract Owned {
    address public owner;

    function Owned() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) throw;
        _;
    }

    address newOwner;

    function changeOwner(address _newOwner) onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() {
        if (msg.sender == newOwner) {
            owner = newOwner;
        }
    }
}

contract TokenReceivable is Owned {
    event logTokenTransfer(address token, address to, uint amount);

    function claimTokens(address _token, address _to) onlyOwner returns (bool) {
        Token token = Token(_token);
        uint balance = token.balanceOf(this);
        if (token.transfer(_to, balance)) {
            logTokenTransfer(_token, _to, balance);
            return true;
        }
        return false;
    }
}

contract FunFairSale is Owned, TokenReceivable {
    uint public deadline =  1499436000; // July 7th, 2017; 14:00 GMT
    uint public startTime = 1498140000; // June 22nd, 2017; 14:00 GMT
    uint public capAmount = 125000000 ether;

    // Don&#39;t allow contributions when the gas price is above
    // 50 Gwei to discourage gas price manipulation.
    uint constant MAX_GAS_PRICE = 50 * 1024 * 1024 * 1024 wei;

    function FunFairSale() {}

    function shortenDeadline(uint t) onlyOwner {
        // Used to shorten the deadline once (if) we&#39;ve hit the soft cap.
        if (t > deadline) throw;
        deadline = t;
    }

    function () payable {
        // Don&#39;t encourage gas price manipulation.
    	if (tx.gasprice > MAX_GAS_PRICE) throw;
        if (block.timestamp < startTime || block.timestamp >= deadline) throw;
        if (this.balance >= capAmount) throw;
        if (this.balance + msg.value >= capAmount) {
            deadline = block.timestamp;
        }
    }

    function withdraw() onlyOwner {
        if (!owner.call.value(this.balance)()) throw;
    }

    function setCap(uint _cap) onlyOwner {
        capAmount = _cap;
    }

    function setStartTime(uint _startTime, uint _deadline) onlyOwner {
        if (block.timestamp >= startTime) throw;
        startTime = _startTime;
        deadline = _deadline;
    }

}