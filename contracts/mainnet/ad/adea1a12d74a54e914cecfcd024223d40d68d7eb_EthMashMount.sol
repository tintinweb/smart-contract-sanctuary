pragma solidity ^0.4.23;

contract EthMashMount {

    address public owner;
    mapping (address => uint) public withdrawals;

    int round;
    mapping (int => address[3]) public participants;
    
    constructor() public {
        owner = msg.sender;
        round = 1;
        participants[1][0] = owner;
    }

    function publicGetBalance(address player) view public returns (uint) {
        return withdrawals[player];
    }

    function publicGetState() view public returns (address[3][7]) {
        return [
            participants[round - 6],
            participants[round - 5],
            participants[round - 4],
            participants[round - 3],
            participants[round - 2],
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
        
        withdrawals[owner] += 5 finney;
        participants[round][1] = msg.sender;

        uint random = (uint(blockhash(block.number - 1)) + uint(participants[round][0]) + uint(participants[round][1]));

        if (random % 2 == 0) {
            participants[round][2] = participants[round][0];
            withdrawals[participants[round][0]] += 100 finney;
            
        } else {
            participants[round][2] = participants[round][1];
            withdrawals[participants[round][1]] += 100 finney;
        }
        
        round++;
        participants[round][0] = participants[round - 1][2];
    }
}