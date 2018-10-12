pragma solidity ^0.4.24;

contract _2Percent {
    address public owner;
    uint public investedAmount;
    address[] public addresses;
    uint public lastPaymentDate;
    uint constant public interest = 2;
    uint constant public transactions_limit = 100;
    mapping(address => Member) public members;
    uint constant public min_withdraw = 100000000000000 wei;
    uint constant public min_invest = 10000000000000000 wei;

    struct Member
    {
        uint id;
        address referrer;
        uint deposit;
        uint deposits;
        uint date;
    }

    constructor() public {
        owner = msg.sender;
        addresses.length = 1;
    }

    function getMemberCount() public view returns (uint) {
        return addresses.length - 1;
    }

    function getMemberDividendsAmount(address addr) public view returns (uint) {
        return members[addr].deposit / 100 * interest * (now - members[addr].date) / 1 days;
    }

    function bytesToAddress(bytes bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }

    function selfPayout() private {
        require(members[msg.sender].id > 0, "Member not found.");
        uint amount = getMemberDividendsAmount(msg.sender);
        require(amount >= min_withdraw, "Too small amount, minimum 0.0001 ether");
        members[msg.sender].date = now;
        msg.sender.transfer(amount);
    }

    function() payable public {
        if (owner == msg.sender) {
            return;
        }

        if (0 == msg.value) {
            selfPayout();
            return;
        }

        require(msg.value >= min_invest, "Too small amount, minimum 0.01 ether");

        Member storage user = members[msg.sender];

        if (user.id == 0) {
            msg.sender.transfer(0 wei);
            user.date = now;
            user.id = addresses.length;
            addresses.push(msg.sender);

            address referrer = bytesToAddress(msg.data);

            if (members[referrer].deposit > 0 && referrer != msg.sender) {
                user.referrer = referrer;
            }
        } else {
            selfPayout();
        }

        user.deposits += 1;
        user.deposit += msg.value;

        lastPaymentDate = now;
        investedAmount += msg.value;

        owner.transfer(msg.value / 5);

        if (user.referrer > 0x0) {
            uint bonusAmount = (msg.value / 100) * interest;
            user.referrer.send(bonusAmount);

            if (user.deposits == 1) {
                msg.sender.send(bonusAmount);
            }
        }
    }
}