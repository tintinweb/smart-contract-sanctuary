pragma solidity ^0.4.11;

contract AutoSplit {

    address public a = 0xDeD5eCC268145e2BeeD2035DA984f134728d2166; // Emploee
    address public b = 0xfDE0E51c33C47b332626b16a2C1a4d17b84AFD74; // Boss
    uint public rate = 30;                                         // 30%
    
    modifier onlyOwner() {
        if (msg.sender != a || msg.sender != b) {
            throw;
        }
        _;
    }

    function () payable {
        a.transfer(msg.value * rate / 100);
        b.transfer(msg.value * (100 - rate) / 100);
    }
    
    function change_a(address new_a) onlyOwner {
        a = new_a;
    }
    
    function change_b(address new_b) onlyOwner {
        b = new_b;
    }
    
    function change_rate(uint new_rate) onlyOwner {
        rate = new_rate;
    }

    function collect() onlyOwner {
        msg.sender.transfer(this.balance);
    }
    
    function kill() onlyOwner {
        suicide(msg.sender);
    }
}