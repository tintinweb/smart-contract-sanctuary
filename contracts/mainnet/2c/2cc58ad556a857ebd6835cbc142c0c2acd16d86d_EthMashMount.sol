pragma solidity ^0.4.22;

contract EthMashMount {

    address public owner;
    mapping (address => uint) public withdrawals;

    uint round;
    mapping (uint => address[]) participants;
    
    event Log(address indexed user, uint action, uint price);

    constructor() public {
        owner = msg.sender;
        round = 1;
        participants[1].push(owner);
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

    function publicGetParticipants(uint index) view public returns (uint) {
        return participants[index].length;
    }

    function publicGetParticipant(uint index, uint participant) view public returns (address) {
        return participants[index][participant];
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
        emit Log(msg.sender, 1, msg.value);
        participants[round].push(msg.sender);

        uint reward = 100 finney;
        uint random = (uint(blockhash(block.number - 1)) + uint(participants[round][0]) + uint(msg.sender));

        if (random % 2 == 0) {
            withdrawals[participants[round][0]] += reward;
            emit Log(participants[round][0], 2, reward);
        } else {
            round++;
            participants[round].push(msg.sender);
            withdrawals[msg.sender] += reward;
            emit Log(msg.sender, 2, reward);
        }
    }
}