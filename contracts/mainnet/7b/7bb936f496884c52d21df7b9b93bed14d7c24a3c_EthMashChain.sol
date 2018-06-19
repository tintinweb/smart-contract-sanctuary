pragma solidity ^0.4.22;

contract EthMashChain {

    address public owner;
    mapping (address => uint) public withdrawals;

    uint round;
    mapping (uint => address[3]) participants;
    
    event Log(address indexed user, uint action, uint price);

    constructor() public {
        owner = msg.sender;
        round = 1;
        participants[1][0] = owner;
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

    function publicGetParticipants(uint index) view public returns (address[3]) {
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
        emit Log(msg.sender, 1, msg.value);
        participants[round][1] = msg.sender;

        uint reward = 100 finney;
        uint random = (uint(blockhash(block.number - 1)) + uint(participants[round][0]) + uint(participants[round][1]));

        if (random % 2 == 0) {
            participants[round][2] = participants[round][0];
            withdrawals[participants[round][0]] += reward;
            emit Log(participants[round][0], 2, reward);
        } else {
            participants[round][2] = participants[round][1];
            withdrawals[participants[round][1]] += reward;
            emit Log(participants[round][1], 2, reward);
        }
        
        round++;
        participants[round][0] = msg.sender;
    }
}