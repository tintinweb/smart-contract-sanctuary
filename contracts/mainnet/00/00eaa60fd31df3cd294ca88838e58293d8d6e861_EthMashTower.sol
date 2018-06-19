pragma solidity ^0.4.22;

contract EthMashTower {

    address public owner;
    mapping (address => uint) public withdrawals;

    uint round;
    uint registered;
    mapping (uint => address[15]) participants;

    event Log(address indexed user, uint action, uint price);

    constructor() public {
        owner = msg.sender;
        round = 1;
        registered = 0;
    }

    modifier whenOwner() {
        require(msg.sender == owner);
        _;
    }

    function ownerWithdraw(uint amount) external whenOwner {
        owner.transfer(amount);
    }

    function ownerDestroy() external whenOwner {
        selfdestruct(owner);
    }

    function publicGetRound() view public returns (uint) {
        return round;
    }

    function publicGetParticipants(uint index) view public returns (address[15]) {
        return participants[index];
    }

    function publicGetBalance(address player) view public returns (uint) {
        return withdrawals[player];
    }

    function userWithdraw() public {
        require(withdrawals[msg.sender] > 0);
        uint amount = withdrawals[msg.sender];
        withdrawals[msg.sender] = 0;
        msg.sender.transfer(amount);
        emit Log(msg.sender, 0, amount);
    }

    function userRegister() public payable {
        require(msg.value == 105 finney);
        require(registered < 8);

        emit Log(msg.sender, 1, msg.value);

        participants[round][registered] = msg.sender;

        if (registered == 1) {
            calcWinner(0, 1, 8, 150 finney);
        } else if (registered == 3) {
            calcWinner(2, 3, 9, 150 finney);
            calcWinner(8, 9, 12, 50 finney);
        } else if (registered == 5) {
            calcWinner(4, 5, 10, 150 finney);
        }  else if (registered == 7) {
            calcWinner(6, 7, 11, 150 finney);
            calcWinner(10, 11, 13, 50 finney);
            calcWinner(12, 13, 14, 100 finney); 
        }

        if (registered < 7) {
            registered++;
        } else {
            round++;
            registered = 0;
        }
    }

    function calcWinner(uint first, uint second, uint winner, uint reward) private {
        uint random = (uint(blockhash(block.number - 1)) + uint(participants[round][first]) + uint(participants[round][second]));

        if (random % 2 == 0) {
            participants[round][winner] = participants[round][first];
            withdrawals[participants[round][first]] += reward;
            emit Log(participants[round][first], 2, reward);
        } else {
            participants[round][winner] = participants[round][second];
            withdrawals[participants[round][second]] += reward;
            emit Log(participants[round][second], 2, reward);
        }
    }
}