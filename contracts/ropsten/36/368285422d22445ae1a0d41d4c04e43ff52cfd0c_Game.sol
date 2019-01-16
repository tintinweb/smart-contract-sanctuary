pragma solidity 0.4.25;

contract Storage {

    address owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    struct Player {
        address addr;
        uint luckyNumber;
    }

    Player[] players;

    constructor() public {
        owner = msg.sender;
    }

    function addPlayer(address _player, uint _luckynumber) public onlyOwner {
        players.push(Player(_player, _luckynumber));
    }

    function addMegaPlayer(address _player, uint _luckynumber, uint _amount) public onlyOwner {
        players.length += _amount;
        players[players.length - 1] = (Player(_player, _luckynumber));
    }

    function getAmount() public view returns(uint) {
        return players.length;
    }

    function getPlayer(uint _id) public view returns(address) {
        return(players[_id].addr);
    }

    function getPlayerAndNumber(uint _id) public view returns(address, uint) {
        return(players[_id].addr, players[_id].luckyNumber);
    }

}

contract Game {

    address owner;

    uint public price = 50000000000000000;

    uint futureblock;

    uint public nextPayDay;

    Storage x;

    event number(address indexed _addr, uint _luckyNumber, uint _amount);
    event won(address indexed _addr, uint indexed _level, uint _wei);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() public {
        owner = msg.sender;
        /* nextPayDay = block.timestamp + 30 days; */
        x = new Storage();
    }

    function() external payable {
        uint _amount = msg.value / price;
        require(_amount >= 1 && _amount <= 500);
        uint luckyNumber = (uint(blockhash(block.number - 1))) * (x.getAmount() + 1) % 10000000;

        if (_amount == 1) {
            x.addPlayer(msg.sender, luckyNumber);
        } else {
            x.addMegaPlayer(msg.sender, luckyNumber, _amount);
        }

        emit number(msg.sender, luckyNumber, _amount);
    }

    function setPrice(uint _newPrice) external onlyOwner {
        require(_newPrice != 0);
        price = _newPrice;
    }

    function stepOne() external {
        /* require(block.number > futureblock + 240 && block.timestamp >= nextPayDay); */
        futureblock = block.number + 10;
    }

    function stepTwo() external {
        require(block.number > futureblock && block.number < futureblock + 240);

        uint balance = address(this).balance;

        uint winner1Id = (uint(blockhash(futureblock))) % x.getAmount();

        for (uint i1 = 0; i1 <= 500; i1++) {
            if (x.getPlayer(winner1Id + i1) != 0x0) {
                x.getPlayer(winner1Id + i1).transfer(balance * 40 / 100);
                emit won(x.getPlayer(winner1Id + i1), 1, balance * 40 / 100);
                break;
            }
        }

        uint winner2Id = (uint(blockhash(futureblock))) * winner1Id % x.getAmount();

        for (uint i2 = 0; i2 <= 500; i2++) {
            if (x.getPlayer(winner2Id + i2) != 0x0) {
                x.getPlayer(winner2Id + i2).transfer(balance * 25 / 100);
                emit won(x.getPlayer(winner2Id + i2), 2, balance * 25 / 100);
                break;
            }
        }


        uint winner3Id = (uint(blockhash(futureblock))) * winner2Id % x.getAmount();

        for (uint i3 = 0; i3 <= 500; i3++) {
            if (x.getPlayer(winner3Id + i3) != 0x0) {
                x.getPlayer(winner3Id + i3).transfer(balance * 15 / 100);
                emit won(x.getPlayer(winner3Id + i3), 3, balance * 15 / 100);
                break;
            }
        }


        uint winner4Id = (uint(blockhash(futureblock))) * winner3Id % x.getAmount();

        for (uint i4 = 0; i4 <= 500; i4++) {
            if (x.getPlayer(winner4Id + i4) != 0x0) {
                x.getPlayer(winner4Id + i4).transfer(balance * 10 / 100);
                emit won(x.getPlayer(winner4Id + i4), 4, balance * 10 / 100);
                break;
            }
        }

        uint winner5Id = (uint(blockhash(futureblock))) * winner4Id % x.getAmount();

        for (uint i5 = 0; i5 <= 500; i5++) {
            if (x.getPlayer(winner5Id + i5) != 0x0) {
                x.getPlayer(winner5Id + i5).transfer(balance * 5 / 100);
                emit won(x.getPlayer(winner5Id + i5), 5, balance * 5 / 100);
                break;
            }
        }

        owner.transfer(balance * 5 / 100);

        /* nextPayDay = block.timestamp + 30 days; */

        x = new Storage();
    }

    function areWeReadyForStepTwo() external view returns(bool) {
        return(block.number > futureblock && block.number < futureblock + 240);
    }

    /* function gethash() public view returns (uint current, uint next) {
        return(uint(blockhash(block.number - 1)), uint(blockhash(futureblock)));
    }

    function getnumb() public view returns (uint current, uint next) {
        return(block.number - 1, futureblock);
    } */

    function getAmountOfPlayers() external view returns(uint) {
        return x.getAmount();
    }

    function getPlayerAndNumber(uint _id) external view returns(address, uint) {
        return x.getPlayerAndNumber(_id);
    }
}