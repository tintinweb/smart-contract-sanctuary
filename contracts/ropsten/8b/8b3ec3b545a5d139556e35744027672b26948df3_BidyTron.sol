// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./SafeMath.sol";
import "./Context.sol";

contract BidyTron is Context {

    using SafeMath for uint256;

    uint public gameTime = 5 minutes;
    address payable admin;

    struct userStruct {
        bool isExist;
        uint id;
        string name;
        uint totalAmount;
        uint noOfGame;
        address referral;
    }

    uint public noOfUser = 0;
    mapping (address => userStruct) public user;

    struct gameStruct {
        uint bidAmount;
        uint noOfGame;
        uint startTime;
        uint randomTime;
        uint jackpot;
        address lastBid;
    }

    mapping (uint => gameStruct) public game;
    
    event NewUser(address _user, string _name);
    event Referal(address _user, uint256 _referral);
    event Bid(address _user, uint256 _amount, uint256 _game, uint256 _time);
    event Deposit(address _user, uint256 _amount, uint256 _time);
    event Withdrawal(address _user, uint256 _amount, uint256 _time);

    constructor(address payable _admin) public{
        admin = _admin;
        gameStruct memory gameInfo;

        gameInfo = gameStruct({
            bidAmount: 10, 
            noOfGame: 0,
            startTime: 0,
            randomTime: 0,
            jackpot: 0,
            lastBid: address(0)
        });
        game[1] = gameInfo;
        
        gameInfo.bidAmount = 20;
        game[2] = gameInfo;
        gameInfo.bidAmount = 50;
        game[3] = gameInfo;
        gameInfo.bidAmount = 100;
        game[4] = gameInfo;
    }

    function signup(string memory _name, address _referral) public returns (bool) {
        require(_referral != _msgSender(), "ha ha ha");
        userStruct memory userInfo;
        noOfUser++;
        userInfo = userStruct({
            isExist: true,
            id: noOfUser,
            name: _name,
            totalAmount: 0,
            noOfGame: 0,
            referral: _referral
        });
        user[_msgSender()] = userInfo;
        return true;
    }

    function deposit () public payable returns (bool) {
        user[_msgSender()].totalAmount += msg.value;
        emit Deposit(_msgSender(),  msg.value, now);
        return true;
    }

    function bid (uint _game) public returns (bool) {
        require(user[_msgSender()].isExist, "Not a User");
        require(getBalance(_msgSender()) >= game[_game].bidAmount, "Not Enough Balance");

        if(user[_msgSender()].totalAmount < game[_game].bidAmount){
            endGame();
        }
        
        user[_msgSender()].totalAmount -= game[_game].bidAmount;
        
        if(game[_game].startTime + game[_game].randomTime + gameTime < now){
            // 10% fee
            user[game[_game].lastBid].totalAmount += game[_game].jackpot * 90 / 100;
            admin.transfer(game[_game].jackpot / 20); // 5% admin fee
            user[user[game[_game].lastBid].referral].totalAmount += game[_game].jackpot * 3 / 100;
            user[user[user[game[_game].lastBid].referral].referral].totalAmount += game[_game].jackpot / 100;
            user[user[user[user[game[_game].lastBid].referral].referral].referral].totalAmount += game[_game].jackpot / 100;
            
            game[_game].noOfGame++;
            game[_game].jackpot = game[_game].bidAmount;
            game[_game].startTime = now;
            game[_game].randomTime = random();
            game[_game].lastBid = _msgSender();
        }else{
            game[_game].jackpot += game[_game].bidAmount;
            game[_game].lastBid = _msgSender();
        }
        emit Bid(_msgSender(), game[_game].bidAmount, _game, now);
        return true;
    }

    function withdrawal (uint _amount) public returns (bool) {
        require(user[_msgSender()].isExist, "Not a User");
        require(getBalance(_msgSender()) >= _amount, "Not Enough Balance");
        
        if(user[_msgSender()].totalAmount < _amount){
            endGame();
        }

        user[_msgSender()].totalAmount -= _amount;
        _msgSender().transfer(_amount);

        emit Withdrawal(_msgSender(), _amount, now);
        return true;
    }
    
    function getBalance(address _user) private view returns(uint){
        uint balance = user[_user].totalAmount;

        for(uint _game = 1; _game <= 4; _game++){
            if(game[_game].startTime + game[_game].randomTime + gameTime < now){
                if(game[_game].lastBid == _user){
                    balance += game[_game].jackpot * 9 / 10; // 10% 
                }else{
                    if(user[game[_game].lastBid].referral == _user){
                        balance += game[_game].jackpot * 3 / 100;
                    }else{
                        if(user[user[game[_game].lastBid].referral].referral == _user){
                            balance += game[_game].jackpot / 100; // 1%
                        }else{
                            if(user[user[user[game[_game].lastBid].referral].referral].referral == _user){
                                balance += game[_game].jackpot / 100; // 1%
                            }
                        }
                    }
                    
                }
            }
        }
        return balance;
    }

    function endGame() internal returns(bool){
        for(uint _game = 1; _game <= 4; _game++){
            if(game[_game].startTime + game[_game].randomTime + gameTime < now){
                user[game[_game].lastBid].totalAmount += game[_game].jackpot * 90 / 100;
                admin.transfer(game[_game].jackpot / 20); // 5% admin fee
                user[user[game[_game].lastBid].referral].totalAmount += game[_game].jackpot * 3 / 100;
                user[user[user[game[_game].lastBid].referral].referral].totalAmount += game[_game].jackpot / 100;
                user[user[user[user[game[_game].lastBid].referral].referral].referral].totalAmount += game[_game].jackpot / 100;

                game[_game].jackpot = 0;
                game[_game].startTime = 0;
                game[_game].randomTime = 0;
                game[_game].lastBid = address(0);
            }
        }
        return true;
    }

    function random() private view returns(uint){
        return uint(now % 60);
    }

}