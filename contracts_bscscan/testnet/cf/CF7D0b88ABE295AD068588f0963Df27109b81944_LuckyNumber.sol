// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;
import "./IERC20.sol";
import "./safeMath.sol";
contract LuckyNumber {
    using SafeMath for uint256;
    struct luckyCard {
        uint8 nowCardNumber; //当前的发放号码
        uint8 hasLucky; //本轮以中奖人数
        uint8 luckyMan; //本轮最多有几个中奖人数
        uint256[] rate; //奖励发放率
        uint256 luckyNo; //游戏编号
        uint256[] luckyNumbers;
    }

    struct buyUser {
        bool isLucky;
        uint8 getNumber;
        uint8 rateLucky;
        uint256 luckyNo;
    }
    struct userAccount {
        uint256 balance;
        buyUser[] userRecord;
    }
    IERC20 public gameTokenAddress;
    uint256 public gameTokenDecimal;
    address public owner;
    mapping(uint256 => luckyCard) private luckyGame;
    mapping(address => userAccount) private users;

    //mapping(address => buyUser[]) private userRecord; //用户购买记录
    //mapping(address => uint256) private userAmount; //用户金额

    uint256 public gameNo;
    uint256 luckyManMax; //中奖的最大人数
    uint256 buyGameCont; //单词买入量
    uint8[] luckNumber;

    function changeOwner(address newOwner) public ownerOnly {
        owner = newOwner;
    }

    modifier ownerOnly() {
        require(msg.sender == owner, "error address is not owner");
        _;
    }

    constructor(
        IERC20 _sendTokenAddress,
        uint256 _sendDecimal,
        uint256 _amount,
        uint256 _luckyManMax
    ) public {
        owner = msg.sender;
        gameTokenAddress = _sendTokenAddress;
        gameTokenDecimal = 10**_sendDecimal;
        luckyManMax = _luckyManMax;
        buyGameCont = _amount;
    }

    function startGame() external {
        gameTokenAddress.transferFrom(
            address(msg.sender),
            address(this),
            buyGameCont.mul(gameTokenDecimal)
        );
        

        if (luckyGame[gameNo].nowCardNumber == 0) {
            _makeRate();
        }

            _addLuckNumber();
        //购买完成后判断是否是最后一个参与人
        if (luckyGame[gameNo].nowCardNumber == 9) {
            makeNumber();
        }
    }

    function makeGame() public ownerOnly {
        makeNumber();
    }

    function makeNumber() private {
        gameNo++;
        luckyCard storage _luckyGame = luckyGame[gameNo];

        _luckyGame.luckyNo = gameNo;
        uint8 randNos = uint8(rand(luckyManMax - 1, 1).add(2));

        _luckyGame.luckyMan = randNos;

        luckNumber = [1, 2, 3, 4, 5, 6, 7, 8, 9];

        for (uint256 i = 0; i < randNos; i++) {
            uint8 randNo = uint8(rand(9 - i, i));
            _luckyGame.luckyNumbers.push(luckNumber[randNo]);
            luckNumber[randNo] = luckNumber[luckNumber.length - 1 - i];
        }
    }

    function _makeRate() private {
        luckyCard storage _luckyGame = luckyGame[gameNo];
        
        uint256 _rateAll;
        for (uint256 i = 0; i < _luckyGame.luckyMan; i++) {
            if (_luckyGame.rate.length == 0) {
                _rateAll = rand(
                    9 - (_luckyGame.luckyMan * 2) - 1,
                    _luckyGame.luckyMan
                ).add(2);
                _luckyGame.rate.push(_rateAll);
            } else {
                if (i == _luckyGame.luckyMan - 1) {
                    _luckyGame.rate.push(9 - _rateAll);
                } else {
                    // uint256 a = 9 - _rateAll;
                    // uint256 b = (randNos - i) * 2;
                    // uint256 c = a - b;
                    // uint256 d = rand(c - 1, i).add(2);
                    uint256 randRate = rand(
                        ((9 - _rateAll) - ((_luckyGame.luckyMan - i) * 2)) - 1,
                        i
                    ).add(2);
                    _rateAll = randRate + _rateAll;
                    _luckyGame.rate.push(randRate);
                }
            }
        }
    }

    function _addLuckNumber() private {
        luckyCard storage _luckyGame = luckyGame[gameNo];
        _luckyGame.nowCardNumber = _luckyGame.nowCardNumber + 1;
        userAccount storage _users = users[address(msg.sender)];
        uint256 rateLucky;
        uint256 _amount;
        uint256 buyPrice = gameTokenDecimal.mul(buyGameCont);
        
        bool check = _checking();
        if (check) {
            _luckyGame.hasLucky = _luckyGame.hasLucky + 1;
            rateLucky = _luckyGame.rate[_luckyGame.hasLucky - 1];
            _amount = rateLucky.mul(buyPrice);
        }
        _users.balance = _users.balance.add(_amount);
        buyUser[] storage _userRecord = _users.userRecord;
        _userRecord.push(
            buyUser(check, _luckyGame.nowCardNumber, uint8(rateLucky), gameNo)
        );
    }

    function getGameNumber() public view returns (uint256[] memory) {
        return luckyGame[gameNo].luckyNumbers;
    }

    function getAmountAll() public ownerOnly {
        uint256 amount = gameTokenAddress.balanceOf(address(this));
        gameTokenAddress.transfer(address(msg.sender), amount);
    }

    function getUserRecord() public view returns (buyUser[] memory) {
        return users[address(msg.sender)].userRecord;
    }

    function getUserAmount() public view returns (uint256) {
        return users[address(msg.sender)].balance;
    }

    // function getUserAmount()private view returns(uint256){
    //     uint256 _amount;
    //     for (uint256 i = 0; i < userRecord.length; ++i){
    //         buyUser[]
    //     }
    //     return _amount;
    // }

    function getGameInfo()
        public
        view
        returns (
            uint8,
            bool,
            uint8,
            uint256
        )
    {
        buyUser[] memory _buyUser = users[address(msg.sender)].userRecord;
        return (
            _buyUser[_buyUser.length - 1].getNumber,
            _buyUser[_buyUser.length - 1].isLucky,
            _buyUser[_buyUser.length - 1].rateLucky,
            _buyUser[_buyUser.length - 1].rateLucky * buyGameCont
        );
    }

    function _checking() private view returns (bool) {
        bool check = false;
        for (uint256 i = 0; i < luckyGame[gameNo].luckyNumbers.length; ++i) {
            if (
                luckyGame[gameNo].nowCardNumber ==
                luckyGame[gameNo].luckyNumbers[i]
            ) {
                check = true;
            }
        }
        return check;
    }

    function getMyLucky() public {
        require(users[address(msg.sender)].balance > 0, "No rewards available");
        userAccount storage _users = users[address(msg.sender)];
        uint256 amount = _users.balance;
        _users.balance = 0;
        gameTokenAddress.transfer(
            address(msg.sender),
            // buyGameCont.mul(
            //     luckyGame[gameNo].rate[luckyGame[gameNo].hasLucky - 1]
            // )
            amount
        );
    }

    function getGame(uint256 _no) public view returns (luckyCard memory) {
        return luckyGame[_no];
    }

    function getGameNo() public view returns (uint256) {
        return gameNo;
    }

    uint256 randomNonce;

    function rand(uint256 _length, uint256 _nonce) private returns (uint256) {
        uint256 random = uint256(
            keccak256(
                abi.encodePacked(block.difficulty, now, _nonce, randomNonce)
            )
        );
        randomNonce++;
        return random % _length;
    }
}