/**
 *Submitted for verification at Etherscan.io on 2021-04-26
*/

pragma solidity >= 0.5.0 < 0.6.0;

contract UsbekDrawLottery {
    uint public winnersAmount;
    uint public registeredUsers;
    uint public currLotteryId;
    uint public launchTime;
    string public lotteryName;
    uint[] public winnersId;
    address private owner = msg.sender;
    uint private nonce;
    uint private up;
    uint private down;

    event LogConstructorInitiated(string nextStep);
    event LogDrawLaunched(uint winAmount, uint regUser, uint lotteryId, uint256 date);

    constructor() public {
        emit LogConstructorInitiated("Constructor was initiated. Call 'launchDraw()' to start the lottery draw.");
        owner = msg.sender;
    }

    function launchDraw(uint _winAmount, uint _regUser, uint _lotteryId, string memory _name) public payable {
        require(owner == msg.sender, "Not valid address (only creator)");
        require(_winAmount >= 1, "Need at least 1 winner");
        require(_regUser >= 1, "Need at least 1 registered user");
        require(_regUser >= _winAmount, "Need at least same registered user amount than winner amount");
        require(_lotteryId >= 0, "A lottery id is mandatory");
        require(bytes(_name).length >= 1, "A lottery id is mandatory");

        delete winnersId;

        emit LogDrawLaunched(_winAmount, _regUser, _lotteryId, now);
        winnersAmount = _winAmount;
        registeredUsers = _regUser;
        currLotteryId = _lotteryId;
        launchTime = now;
        lotteryName = _name;
        setRandomNum(_winAmount, _regUser);
    }

    function setRandomNum(uint _winAmount, uint _users) private {
        uint rand = uint(keccak256(abi.encodePacked(now, nonce, msg.sender))) % _users;
        uint randNum = rand;

        nonce++;
        up = rand;
        down = rand;
        setWinnersId(randNum, _winAmount, _users);
    }

    function setWinnersId(uint _randNum, uint _winAmount, uint _users) private {
        winnersId.push(_randNum);

        while(winnersId.length < _winAmount) {
            if ((_winAmount % 2 == 0) && (winnersId.length == _winAmount - 1)) {
                setNext(_users);
                uint rand = uint(keccak256(abi.encodePacked(now, nonce, msg.sender))) % 1;
                if (rand == 1) {
                    winnersId.push(down);
                } else {
                    winnersId.push(up);
                }
            } else {
                setNext(_users);
                winnersId.push(down);
                winnersId.push(up);
            }
        }
    }

    function setNext(uint _users) private {
        if ((up + 1) > _users) {
            up = 1;
        } else {
            up += 1;
        }

        if ((down - 1) < 1) {
            down = _users;
        } else {
            down -= 1;
        }
    }

    function getWinnersId() public view returns(uint[] memory) {
        return winnersId;
    }
}