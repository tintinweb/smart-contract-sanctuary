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
        uint noOfJackpot;
        address referral;
    }

    uint public noOfUser = 0;
    uint public totalplayedgames= 0;
    mapping (address => userStruct) public user;

    struct gameStruct {
        uint id;
        uint bidAmount;
        uint noOfBid;
        uint startTime;
        uint randomTime;
        uint jackpot;
        address lastBid;
    }
    mapping (uint => gameStruct) private game;

    struct winStruct {
        uint bidAmount;
        uint startTime;
        uint jackpot;
        address lastBid;
    }
    mapping (uint => mapping (uint => winStruct)) public win;

    
    event NewUser(address _user, string _name);
    event Bid(address _user, uint256 _amount, uint256 _game, uint256 _time);
    event Deposit(address _user, uint256 _amount, uint256 _time);
    event Withdrawal(address _user, uint256 _amount, uint256 _time);

    constructor(address payable _admin) public{
        admin = _admin;
        gameStruct memory gameInfo;

        gameInfo = gameStruct({
            id: 0,
            bidAmount: 10, 
            noOfBid: 0,
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

    function contract_balance() view public returns (uint) {
        return address(this).balance;
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
            noOfJackpot: 0,
            referral: _referral
        });
        user[_msgSender()] = userInfo;
        emit NewUser(_msgSender(),_name);
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
        user[_msgSender()].noOfGame++;
        game[_game].randomTime = random();
        
        if(game[_game].startTime + game[_game].randomTime + gameTime < now){
            endGame();
           
            game[_game].jackpot = game[_game].bidAmount;
            game[_game].startTime = now;
            game[_game].id++;
            game[_game].lastBid = _msgSender();
            totalplayedgames++;
        }else{
            game[_game].jackpot += game[_game].bidAmount;
            game[_game].lastBid = _msgSender();
        }
        game[_game].noOfBid++;
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

    function getBalance(address _user) public view returns(uint){
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
                user[game[_game].lastBid].noOfJackpot++;
                // admin.transfer(game[_game].jackpot / 20); // 5% admin fee

                if(user[game[_game].lastBid].referral != address(0)){
                    user[user[game[_game].lastBid].referral].totalAmount = user[user[game[_game].lastBid].referral].totalAmount.add(game[_game].jackpot.mul(3).sub(100));
                    if(user[user[game[_game].lastBid].referral].referral != address(0)){
                        user[user[user[game[_game].lastBid].referral].referral].totalAmount += game[_game].jackpot / 100;
                        if(user[user[user[game[_game].lastBid].referral].referral].referral != address(0)){
                            user[user[user[user[game[_game].lastBid].referral].referral].referral].totalAmount += game[_game].jackpot / 100;
                            admin.transfer(game[_game].jackpot / 20); // 5% admin fee and 3% 1 level referral and 1% 2nd level referral and 1% 3rd level referral
                        }else{
                            admin.transfer(game[_game].jackpot * 6 / 100); // 6% admin fee and 3% 1 level referral and 1% 2nds level referral
                        }
                    }else{
                        admin.transfer(game[_game].jackpot * 7 / 100); // 7% admin fee and 3% 1 level referral
                    }
                }else{
                    admin.transfer(game[_game].jackpot / 10); // 10% admin fee if there is no referral
                }
                
                winStruct memory winInfo;
                winInfo = winStruct({
                    bidAmount: game[_game].bidAmount,
                    startTime: game[_game].startTime,
                    jackpot: game[_game].jackpot,
                    lastBid: game[_game].lastBid
                });
                win[_game][game[_game].id] = winInfo;

                game[_game].noOfBid = 0;
                game[_game].jackpot = 0;
                game[_game].startTime = 0;
                game[_game].randomTime = 0;
                game[_game].lastBid = address(0);
            }
        }
        return true;
    }
     
    function getgameinfo(uint _id) public view returns(uint,uint256,uint,address){
              return (game[_id].bidAmount,
              game[_id].startTime,
              game[_id].jackpot,
              game[_id].lastBid
            );
    }
    
    function totalgameplayeduser(address _user) public view returns(uint,uint){
        return (user[_user].noOfGame,
        user[_user].noOfJackpot
        );
    }
    
   
    function random() private view returns(uint){
        return uint(now % 60);
    }

}