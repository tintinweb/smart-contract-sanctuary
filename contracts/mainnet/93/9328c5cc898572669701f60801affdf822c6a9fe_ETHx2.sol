pragma solidity 0.4.18;

contract ETHx2 {
    event NewParticipant(address owner, uint256 cost, uint256 new_price);

    struct Cost {
        address owner;
        uint256 cost;
    }

    mapping(uint256 => Cost) public participant;
    mapping(address => string) public msgs;

    address public adminAddress;
    uint256 public seatPrice = 5000000000000000;

    modifier onlyAdmin() {
        require(msg.sender == adminAddress);
        _;
    }

    function ETHx2() public {
        adminAddress = msg.sender;
        participant[1] = Cost(msg.sender, 0);
        participant[2] = Cost(msg.sender, 0);
        participant[3] = Cost(msg.sender, 0);
        participant[4] = Cost(msg.sender, 0);
        participant[5] = Cost(msg.sender, 0);
        participant[6] = Cost(msg.sender, 0);
        participant[7] = Cost(msg.sender, 0);
        participant[8] = Cost(msg.sender, 0);
        participant[9] = Cost(msg.sender, 0);
        participant[10] = Cost(msg.sender, 0);
        msgs[msg.sender] = "Claim this spot!";
    }

    function getETHx2(uint256 _slot) public view returns(
        uint256 slot,
        address owner,
        uint256 cost,
        string message
    ) {
        slot = _slot;
        owner = participant[_slot].owner;
        cost = participant[_slot].cost;
        message = msgs[participant[_slot].owner];
    }

    function purchase() public payable {
        require(msg.sender != address(0));
        require(msg.value >= seatPrice);
        uint256 excess = SafeMath.sub(msg.value, seatPrice);
        participant[1].owner.transfer(uint256(SafeMath.mul(SafeMath.div(seatPrice, 100), SafeMath.div(100, SafeMath.div(200, 17)))));
        participant[2].owner.transfer(uint256(SafeMath.mul(SafeMath.div(seatPrice, 100), SafeMath.div(100, SafeMath.div(200, 17)))));
        participant[3].owner.transfer(uint256(SafeMath.mul(SafeMath.div(seatPrice, 100), SafeMath.div(100, SafeMath.div(200, 17)))));
        participant[4].owner.transfer(uint256(SafeMath.mul(SafeMath.div(seatPrice, 100), SafeMath.div(100, SafeMath.div(200, 17)))));
        participant[5].owner.transfer(uint256(SafeMath.mul(SafeMath.div(seatPrice, 100), SafeMath.div(100, SafeMath.div(200, 17)))));
        participant[6].owner.transfer(uint256(SafeMath.mul(SafeMath.div(seatPrice, 100), SafeMath.div(100, SafeMath.div(200, 17)))));
        participant[7].owner.transfer(uint256(SafeMath.mul(SafeMath.div(seatPrice, 100), SafeMath.div(100, SafeMath.div(200, 17)))));
        participant[8].owner.transfer(uint256(SafeMath.mul(SafeMath.div(seatPrice, 100), SafeMath.div(100, SafeMath.div(200, 17)))));
        participant[9].owner.transfer(uint256(SafeMath.mul(SafeMath.div(seatPrice, 100), SafeMath.div(100, SafeMath.div(200, 17)))));
        participant[10].owner.transfer(uint256(SafeMath.mul(SafeMath.div(seatPrice, 100), SafeMath.div(100, SafeMath.div(200, 17)))));
        participant[10] = participant[9];
        participant[9] = participant[8];
        participant[8] = participant[7];
        participant[7] = participant[6];
        participant[6] = participant[5];
        participant[5] = participant[4];
        participant[4] = participant[3];
        participant[3] = participant[2];
        participant[2] = participant[1];
        participant[1] = Cost(msg.sender, seatPrice);
        adminAddress.transfer(uint256(SafeMath.mul(SafeMath.div(seatPrice, 100), SafeMath.div(100, SafeMath.div(200, 17)))));
        NewParticipant(msg.sender, seatPrice, SafeMath.mul(SafeMath.div(seatPrice, 100), 115));
        seatPrice = SafeMath.mul(SafeMath.div(seatPrice, 100), 115);
        msg.sender.transfer(excess);
    }

    function setMessage(string message) public payable {
        msgs[msg.sender] = message;
    }

    function payout() public onlyAdmin {
        adminAddress.transfer(this.balance);
    }
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}