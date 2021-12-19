/**
 *Submitted for verification at BscScan.com on 2021-12-19
*/

pragma solidity ^0.5.0;

contract EthernalBird {
    uint public silverScore = 10;
    uint public goldScore = 40;
    uint public fee = 1 finney;
    uint public silverPrize = 1 finney;
    uint public goldPrize = 5 finney;
    uint public newRecordPrize = 10 finney;
    address public owner;

    uint[] public price = [0, 10 finney, 30 finney, 40 finney, 50 finney, 1 ether];
    mapping (address => bool) public isPlaying;

    mapping (address => mapping (uint => bool)) public ownedBirds;
    mapping (address => uint) public usingBird;

    modifier onlyOwner() {
        require(msg.sender == owner, 'only contract owner can peform this');
        _;
    }

    constructor () public {
        owner = msg.sender;
    }

    function setSilverPrize(uint prize)
        public
    {
        silverPrize = prize;
    }

    function setGoldPrize(uint prize)
        public
    {
        goldPrize = prize;
    }

    function setNewRecordPrize(uint prize)
        public
    {
        newRecordPrize = prize;
    }

    function getUsingBird()
        public
        view
        returns (uint)
    {
        return usingBird[msg.sender];
    }

    function useBird(uint birdId)
        public
    {
        require(birdId < price.length, 'invalid birdId');
        require(ownedBirds[msg.sender][birdId] || birdId == 0, 'this bird is not yours');
        usingBird[msg.sender] = birdId;
    }

    function play()
        public
        payable
    {
        // require(!isPlaying[msg.sender], 'player must not in game');
        require(msg.value >= fee, 'you must pay for playing');
        if (msg.value > fee) {
            msg.sender.transfer(msg.value - fee);
        }
        isPlaying[msg.sender] = true;
    }

    function endGame(uint score)
        public
    {
        require(isPlaying[msg.sender], 'player must be in game');
        isPlaying[msg.sender] = false;
        if (score >= goldScore) {
            msg.sender.transfer(goldPrize);
        } else if (score >= silverScore) {
            msg.sender.transfer(silverPrize);
        }
    }

    function quit()
        public
    {
        isPlaying[msg.sender] = false;
    }

    function purchase(uint birdId)
        public
        payable
    {
        require(msg.value >= price[birdId], 'value is not enough');
        require(birdId < price.length, 'invalid birdId');
       ownedBirds[msg.sender][birdId] = true;
    }

    function getMyBirds() public view returns (bool, bool, bool, bool, bool, bool)
    {
        return (true, ownedBirds[msg.sender][1], ownedBirds[msg.sender][2], ownedBirds[msg.sender][3], ownedBirds[msg.sender][4], ownedBirds[msg.sender][5]);
    }

    function withdrawal(uint amount)
        public
        onlyOwner
    {
        require(amount < address(this).balance, 'amount must be less than contract balance');
        selfdestruct(msg.sender);
    }

    function destroy()
        public
        onlyOwner
    {
        selfdestruct(msg.sender);
    }
}