/**
 *Submitted for verification at Etherscan.io on 2021-09-11
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

contract BlackJack{
    
    address private _player;
    
    bool private _roundplaying;
    
    uint256 private _randNum;
    uint256 private _MoneyInGame;
    uint256 private _OriginalMoney;
    uint256 private _Bet;
    uint256 private _PlayerCard1;
    uint256 private _PlayerCard2;
    uint256 private _PlayerNewCard;
    uint256 private _PlayerCardTotal;
    uint256 private _DealerCard1;
    uint256 private _DealerCard2;
    uint256 private _DealerNewCard;
    uint256 private _DealerCardTotal;
    
    string private _dMsg;
    
    event PlayerPutMoney(address Contract, address Player, uint256 Amount);
    event PlayerGetMoney(address Contract, address Player, uint256 Amount);
    
    constructor() public {
        _roundplaying = false;
        _dMsg = " --> Bet Limits: 1 wei - 1000 wei.  Waiting for Player Bet.";
    }
    
     ///************pay the contract*************///
    function PayContract() public payable returns (string memory) {
        if(_MoneyInGame > 0)
            require(_player == msg.sender, "Only Player can pay this contract.");
        
        _MoneyInGame += msg.value;
        _OriginalMoney = _MoneyInGame;
        _player = msg.sender;
        emit PlayerPutMoney(address(this), msg.sender, msg.value);
        _dMsg = "Player Paid the Contract.";
        return _dMsg;
    }
    
    function RandomNumberGenerator() internal returns (uint randomNumber) {
        uint randNonce = 1;
        _randNum = (uint(keccak256(abi.encodePacked(blockhash(block.number - 1), randNonce)))%13 + 1);
        randNonce++;

        if(_randNum > 10)
            _randNum = 10;
    
        return _randNum;
    }
    
    ///***************Place a bet**************///
    //Limits: 1 wei - 1000 wei
    function PlaceBet(uint256 bet) public returns (string memory) {

        require(bet >= 1 wei && bet <= 1000 wei, "Bet Limits are 1 wei - 1000 wei.");
        require(bet <= _MoneyInGame, "You don't have enough money.");
        
        _MoneyInGame -= bet;
        _Bet = bet;
        _roundplaying = true;
        return Deal();
    }
    
    function MoneyBack() public returns (string memory) {
        
        if(_MoneyInGame <= _OriginalMoney)
            _dMsg = "You Loss Money.";
        else
            _dMsg = "You Win Money.";
            
        emit PlayerGetMoney(address(this), msg.sender, _MoneyInGame);
        msg.sender.transfer(_MoneyInGame);
        _MoneyInGame = 0;
        _PlayerCard1 = 0;
        _PlayerCard2 = 0;
        _PlayerNewCard = 0;
        _PlayerCardTotal = 0;
        _Bet = 0;
        _DealerCard1 = 0;
        _DealerCard2 = 0;
        _DealerNewCard = 0;
        _DealerCardTotal = 0;
        return _dMsg;
    }
    
    function Deal() internal returns (string memory) {
        _PlayerCard1 = 0;
        _PlayerCard2 = 0;
        _PlayerNewCard = 0;
        _PlayerCardTotal = 0;
 
        _DealerCard1 = 0;
        _DealerCard2 = 0;
        _DealerNewCard = 0;
        _DealerCardTotal = 0;
        
        _PlayerCard1 = RandomNumberGenerator();
        if(_PlayerCard1 == 1)
            _PlayerCard1 = 11;             //A=11
        
        _PlayerCard2 = RandomNumberGenerator();
        if(_PlayerCard2 == 1 && _PlayerCard1 < 11) {
           _PlayerCard2 = 11;               //A=11
        }
        
        _PlayerCardTotal = _PlayerCard1 + _PlayerCard2;
        
        _DealerCard1 = RandomNumberGenerator();
        if(_DealerCard1 == 1 ) 
           _DealerCard1 = 11;               //A=11

        if(_PlayerCardTotal == 21) {
            if(_DealerCard1 == 10) {
                _DealerCard2 = RandomNumberGenerator();
                if(_DealerCard2 == 1) 
                    _DealerCardTotal = 21;
            }
            
            if(_DealerCard1 == 1) {
                _DealerCard2 = RandomNumberGenerator();
                if(_DealerCard2 == 10) 
                    _DealerCardTotal = 21;
            }
            
            if(_DealerCardTotal == _PlayerCardTotal) {
                _dMsg = " --> StandOff!";
               _MoneyInGame += _Bet;
                _roundplaying = false;
            }
            else {
                _dMsg = " --> Player Wins.";
                _MoneyInGame += ((_Bet * 2) + (_Bet/2));
                _roundplaying = false;
            }
        }

        else
            _dMsg = " --> Player's Turn.";
        return _dMsg;
    }
    
    
    function Hit() public returns (string memory) {
        _PlayerNewCard = RandomNumberGenerator();
        if(_PlayerNewCard == 1 && _PlayerCardTotal < 11) {
            _PlayerNewCard = 11;
        }
        _PlayerCardTotal += _PlayerNewCard;
        HitWin(_PlayerCardTotal);
        return _dMsg;
    }
    
    function Stand() public returns (string memory) {
        _DealerCard2 = RandomNumberGenerator();
        if(_DealerCard2 == 1 && _DealerCard1 < 11) {
            _DealerCard2 = 11;
        }
        
        _DealerCardTotal = _DealerCard1 + _DealerCard2;
        while(_DealerCardTotal < 17) {
            _DealerNewCard = RandomNumberGenerator();
            if(_DealerNewCard == 1 && _DealerCardTotal < 11) 
                _DealerNewCard = 11;
            _DealerCardTotal += _DealerNewCard;
        }

        if(_DealerCardTotal == 21) {
            if(_PlayerCardTotal == 21 ) {
                _dMsg = " --> StandOff!";
                _MoneyInGame += _Bet;
            }
            else {
                _dMsg = " --> Dealer Wins.";
                _roundplaying = false;
            }
        }
            
        else if(_DealerCardTotal > 21) {
            _dMsg = " --> Dealer Bust. Player Wins.";
            _MoneyInGame += (_Bet * 2);
            _roundplaying = false;
        }
        
        else {
            if(_PlayerCardTotal <= 21) {
                if(_PlayerCardTotal < _DealerCardTotal) {
                    _dMsg = " --> Dealer Wins.";
                    _roundplaying = false;
                } 
                else if(_PlayerCardTotal > _DealerCardTotal) {
                    _dMsg = " --> Player Wins.";
                    _MoneyInGame += (_Bet * 2);
                    _roundplaying = false;
                } 
                else {
                    _dMsg = " --> StandOff!";
                    _MoneyInGame += _Bet;
                    _roundplaying = false;
                }
            }
            else {
                _dMsg = " --> Player Bust! Dealer Wins.";
            }
        }
        return _dMsg;
    }
    
    function HitWin(uint256 _PlayerTotal) internal {
        if(_PlayerTotal == 21) {
            
            _DealerCard2 = RandomNumberGenerator();
            if(_DealerCard2 == 1 && _DealerCard1 < 11) {
                _DealerCard2 = 11;
             }
        
             _DealerCardTotal = _DealerCard1 + _DealerCard2;
            while(_DealerCardTotal < 17) {
                _DealerNewCard = RandomNumberGenerator();
                if(_DealerNewCard == 1 && _DealerCardTotal < 11) 
                    _DealerNewCard = 11;
                _DealerCardTotal += _DealerNewCard;
            }

            if(_PlayerTotal == _DealerCardTotal ) {
                _dMsg = " --> StandOff!";
                _MoneyInGame += _Bet;
                _roundplaying = false;
            }
            else {
                _dMsg = " --> Hit 21 ! Player Wins.";
                _MoneyInGame += (_Bet * 2);
                _roundplaying = false;
            }
        } else if(_PlayerTotal > 21) {
            _dMsg = " --> Player Bust! Dealer Wins.";
            _roundplaying = false; 
        }
        else
            _dMsg = " --> Player's Turn.";
    }
    
     function displayTable() public view returns (string memory Message, uint256 PlayerBet, uint256 PlayerCard1, uint256 PlayerCard2, 
                    uint256 PlayerNewCard, uint256 PlayerCardTotal, 
                    uint256 DealerCard1, uint256 DealerCard2, uint256 DealerNewCard,
                    uint256 DealerCardTotal, uint256 Money) {

        return (_dMsg, _Bet, _PlayerCard1, _PlayerCard2, _PlayerNewCard, _PlayerCardTotal,
            _DealerCard1, _DealerCard2, _DealerNewCard, _DealerCardTotal, _MoneyInGame);
    }
}