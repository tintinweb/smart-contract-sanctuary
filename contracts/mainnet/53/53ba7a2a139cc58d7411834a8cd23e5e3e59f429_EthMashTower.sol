pragma solidity ^0.4.23;

contract EthMashTower {

    address public owner;
    mapping (address => uint) public withdrawals;

    int round;
    uint registered;
    mapping (int => address[7]) public participants;

    constructor() public {
        owner = msg.sender;
        round = 1;
        registered = 0;
    }

    function publicGetBalance(address player) view public returns (uint) {
        return withdrawals[player];
    }

    function publicGetState() view public returns (address[7][2]) {
        return [
            participants[round - 1],
            participants[round]
        ];
    }

    function userWithdraw() public {
        require(withdrawals[msg.sender] > 0);
        uint amount = withdrawals[msg.sender];
        withdrawals[msg.sender] = 0;
        msg.sender.transfer(amount);
    }

    function userRegister() public payable {
        require(msg.value == 105 finney);
        require(registered < 4);

        withdrawals[owner] += 5 finney;
        participants[round][registered] = msg.sender;

        if (registered == 1) {
            calcWinner(0, 1, 4, 150 finney);
        } else if (registered == 3) {
            calcWinner(2, 3, 5, 150 finney);
            calcWinner(4, 5, 6, 100 finney);
        }

        if (registered < 3) {
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
        } else {
            participants[round][winner] = participants[round][second];
            withdrawals[participants[round][second]] += reward;
        }
    }
}