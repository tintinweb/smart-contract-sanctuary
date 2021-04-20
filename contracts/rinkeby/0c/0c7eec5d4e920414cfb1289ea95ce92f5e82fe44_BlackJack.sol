/**
 *Submitted for verification at Etherscan.io on 2021-04-20
*/

// SPDX-License-Identifier: WTFPL
pragma solidity ^0.7.6;

/*
Split under 21 rule:
If either of the player's hand in a split beats dealer, the player wins bet on both hands automatically.
But if the player busts on either deck, the dealer wins bet on both decks. If the player's first hand has a standoff with 
dealer, the player's other hand must beat dealer, otherwise the dealer wins.
If the player's second hand stands off with dealer, the player gets original bet back.
The player can either double down or split; the player cannot split then double down and vice versa.
*/

contract BlackJack {
    address private _player;

    bool private _roundInProgress;
    bool private _displayUpdate;
    bool private _dDown;
    bool private _insurance;
    bool private _insured;
    bool private _split;
    bool private _splitting;

    uint256 private _ethLimit = 100000000000000 wei;
    uint256 private _safeBalance;
    uint256 private _origBalance;
    uint256 private _splitCount;
    uint256 private _rngCounter;
    uint256 private _randNum;
    uint256 private _pBet;
    uint256 private _pCard1;
    uint256 private _pCard2;
    uint256 private _pNewCard;
    uint256 private _pCardTotal;
    uint256 private _pSplitTotal;
    uint256 private _dCard1;
    uint256 private _dCard2;
    uint256[2] private _dNewCard;
    uint256 private _dCardTotal;
    uint256 public _gamesPlayed;
    
    string private _dMsg;
    
    // Event logging
    event PlayerDeposit(address Contract, address Player, uint256 Amount);
    event PlayerWithdrawal(address Contract, address Player, uint256 Amount);
    
    // Modifiers
    modifier isValidAddr() {
        require(msg.sender != address(0), "Invalid Address.");
        _;
    }
    
    modifier isPlayer() {
        require(msg.sender == _player, "Only Player can use this function.");
        _;
    }
    
    modifier playerTurn() {
        require(_roundInProgress == true, "This Function can only be used while round is in progress.");
        _;
    }
    
    modifier newRound() {
        require(_roundInProgress == false, "This Function cannot be used while round is in progress.");
        _;
    }
    
    
    constructor() {
        _roundInProgress = false;
        _rngCounter = 1;
        _gamesPlayed = 0;
        _dMsg = " --> Bet Limits: 1 wei - 1000 wei.  Waiting for Player Bet.";
    }
        
    function payContract() isValidAddr newRound public payable returns (string memory) {
        
        // If the contract is in use, make sure it is player paying
        if(_safeBalance > 0)
            require(_player == msg.sender, "Only Player can pay this contract.");
        
        // Make sure contract cannot accept more than ether limit
        require((_safeBalance + msg.value) <= _ethLimit, "Too much Ether!");
        
        _safeBalance += msg.value;
        _origBalance += msg.value;
        
        // Register player's address
        _player = msg.sender;
        
        // Log event    
        emit PlayerDeposit(address(this), msg.sender, msg.value);
        
        _dMsg = "Contract Paid.";
            
        return _dMsg;
    }
    
    /* RNG
    Generates a random number from 0 to 13 b    ased on the last block hash.
    11 = Joker, 12 = Queen, 13 = King; each worth 10 points.
    counter is added to "block.timestamp" so that RNG doesnt produce same number if called twice in the same second
    */
    function RNG() internal returns (uint randomNumber) {
        uint seed;
        _rngCounter *= 2;
        seed = block.timestamp - _rngCounter;
        _randNum = (uint(keccak256(abi.encodePacked(blockhash(block.number - 1), seed))) % 13 + 1);
        
        // J, Q, K => 10
        if(_randNum > 10)
            _randNum = 10;
            
        // Reset RNG counter to prevent unecessary large number and overflow
        if(_rngCounter > 420000000)
            _rngCounter = _randNum;
            
        return _randNum;
    }
    
    
    /*
    GAME INTERFACE
    */
    
    // Place a bet
    function placeBet(uint256 bet) isValidAddr isPlayer newRound public returns (string memory) {
        uint256 betEth;
        
        // Only reset player's bet if not a double down or split or insurance bet
        if(_dDown == false && _split == false && _insurance == false)
            _pBet = 0;
        
        betEth = bet;
        
        // Make sure bet is within limits
        require(betEth >= 1 wei && betEth <= 1000 wei, "Bet Limits are 1 wei - 1000 wei.");
        
        // Make sure player can afford bet
        require(betEth <= _safeBalance, "Sorry, You don't have enough to place that bet.");
        
        // Update balance
        _safeBalance -= betEth;
        
        // Don't replace original bet with insurance bet
        if(_insurance == false)
            _pBet += betEth;
        
        // Start round
        _roundInProgress = true;
        
        // Update game counter
        _gamesPlayed += 1;
        
        // Only deal cards if this is not a Double Down or split or insurance bet
        if(_dDown == false && _split == false && _insurance == false)
            return deal();
        else {
            // Make sure player can only insure once
            if(_insurance == true)
                _insurance = false;
            _dMsg = "Bet Placed.";
            return _dMsg;
        }
    }
    
    // Cash out
    function cashOut() isValidAddr isPlayer newRound 
        public 
        returns (string memory) {
        
        uint256 tempBalance = 0;
        // If player lost money
        if(_safeBalance <= _origBalance)
            _dMsg = "You would have lost Ether! Good thing I'm a generous smart contract. Original bet returned.";
        else
            _dMsg = "You are a worthy advesary! Original bet returned.";
        
        // Log event
        emit PlayerWithdrawal(address(this), msg.sender, _origBalance);
        
        _safeBalance = 0;
        tempBalance = _origBalance;
        _origBalance = 0;
        
        // Transfer funds
        address payable sender = payable(msg.sender);
        sender.transfer(tempBalance);
        
        return _dMsg;
    }
    
    
    // Deal cards
    function deal() internal returns (string memory) {
        
        // Clear previous hand
        _pCard1 = 0;
        _pCard2 = 0;
        _pNewCard = 0;
        _pCardTotal = 0;
        _pSplitTotal = 0;
        _dCard1 = 0;
        _dCard2 = 0;
        _dNewCard[0] = 0;
        _dNewCard[1] = 0;
        _dCardTotal = 0;
        _dDown = false;
        _split = false;
        _insurance = false;
        _splitCount = 0;
        
        // Player card 1
        _pCard1 = RNG();
        // Ace
        if(_pCard1 == 1)
            _pCard1 = 11;
        
        // Dealer card 1
        _dCard1 = RNG();
        
        // Player card 2
        _pCard2 = RNG();
        // Ace is 1 unless Player has a total less than 11
        if(_pCard2 == 1 && _pCard1 < 11) {
            // Ace = 11
            _pCard2 = 11;
        }
        
        // Player's total
        _pCardTotal = _pCard1 + _pCard2;
        
        // Insurance
        if(_dCard1 == 1) {
            _dMsg = " --> Want Insurance?.";
            _dCard1 = 11;
            _insurance = true;
        }
        
        // Dealer's total
        _dCardTotal = _dCard1 + _dCard2;
        
        // BlackJack - Natural (1.5*Bet returned to player)
        if(_pCardTotal == 21) {
            // If there might be a standoff
            if(_dCard1 == 10) {
                // Show dealer's second card
                _dCard2 = RNG();
                // Ace is always 11 in this case
                if(_dCard2 == 1) 
                    _dCard2 = 11;
                
                _dCardTotal = _dCard1 + _dCard2;
            }
            
            // Choose winner
            if(_dCardTotal == _pCardTotal) {
                _dMsg = " --> StandOff!";
                // Update balance: bet
                _safeBalance += _pBet;
                _roundInProgress = false;
            }
            else {
                _dMsg = " --> BlackJack! Player Wins.";
                // Update balance: bet * 2.5 = original bet + bet * 1.5
                _safeBalance += ((_pBet * 2) + (_pBet/2));
                _roundInProgress = false;
            }
        }
        // Normal turn
        else
            _dMsg = " --> Player's Turn.";
        
        // Split
        if(_pCard1 == _pCard2) {
            if(_insurance == true)
                _dMsg = " --> Player's Turn. Want Insurance? Player can Split.";
            else
                _dMsg = " --> Player's Turn. Player can Split.";
            _split = true;
        }
        
        // Double down - Reno Rule (9 or 10 or 11)
        if(_pCardTotal == 9 || _pCardTotal == 10 || _pCardTotal == 11) {
            if(_insurance == true) {
                _dMsg = " --> Player's Turn. Want Insurance? Player can Double Down.";
                if(_split == true)
                    _dMsg = " --> Player's Turn. Want Insurance? Player can Split or Double Down.";
            } else {
                _dMsg = " --> Player's Turn. Player can Double Down.";
                if(_split == true)
                    _dMsg = " --> Player's Turn. Player can Split or Double Down.";
            }
            _dDown = true;
        }
        
        return _dMsg;
    }
    
    // Hit
    function hit() isValidAddr isPlayer playerTurn public returns (string memory) {
        
        // Handle double down, insurance and splitting
        dDownInsSplit();
        
        _pNewCard = RNG();
        // Ace is 1 unless Player has a total less than 11
        if(_pNewCard == 1 && _pCardTotal < 11) {
            // Ace = 11
            _pNewCard = 11;
        }
            
        // Choose for 1st round winner during split
        if(_splitting == true) {
            _pSplitTotal += _pNewCard;
            
            // Handle hit Win
            hitWin(_pSplitTotal);
            
        } else {
            // Choose winner for normal play or second round during split
            _pCardTotal += _pNewCard;
            
            // Handle hit win
            hitWin(_pCardTotal);
        }
        return _dMsg;
        
    }
    
    //Stand
    function stand() isValidAddr isPlayer playerTurn public returns (string memory) {
        
        // Handle double down, insurance and splitting
        dDownInsSplit();
        
        // Dealer's turn
        if(_splitCount < 2) {
            // Show Dealer Card 2
            _dCard2 = RNG();
            // Ace
            if(_dCard2 == 1 && _dCard1 < 11) {
                // Ace = 11
                _dCard2 = 11;
            }
         
            // Update Dealer's card Total
            _dCardTotal = _dCard1 + _dCard2;
        
            uint256 _dCardIndex = 0;        
            // Dealer must Hit to 16 and Stand on all 17's
            while(_dCardTotal < 17) {
                _dNewCard[_dCardIndex] = RNG();
                // Ace
                if(_dNewCard[_dCardIndex] == 1 && _dCardTotal < 11) {
                    // Ace = 11
                    _dNewCard[_dCardIndex] = 11;
                }
                
                _dCardTotal += _dNewCard[_dCardIndex];
                _dCardIndex += 1;
                if(_dCardIndex > 1)
                    _dCardIndex = 0;
            }
        }
        
        // Choose winner
        if(_dCardTotal == 21) {
            // For double down play 
            if(_pCardTotal == 21 || _pSplitTotal == 21) {
                _dMsg = " --> StandOff!";
                // Update balance
                _safeBalance += _pBet;
            } else {
                if(_splitting == true) {
                    _splitCount += 1;
                    _dMsg = " --> Player's Turn.";
                }
                else {
                    _dMsg = " --> BlackJack! Dealer Wins.";
                    _roundInProgress = false;
                    if(_insured == true) {
                        _insured = false;
                        // Bet has doubled so insurance is 1/2 * bet
                        _safeBalance += (_pBet/2);
                    }
                }
            }
            
        } else if(_dCardTotal > 21) {
            if(_splitting == true) {
                _splitCount += 1;
                _dMsg = " --> Player's Turn.";
                // Update balance
                _safeBalance += (_pBet * 2);
            }
            else {
                _dMsg = " --> Dealer Bust. Player Wins.";
                // Update balance: bet * 2
                _safeBalance += (_pBet * 2);
                _roundInProgress = false;
            }
            
        } else {
            if(_pCardTotal <= 21) {
                // If dealer wins
                if((21 - _dCardTotal) < (21 - _pCardTotal)) {
                    if(_splitting == true) {
                        _splitCount += 1;
                        _dMsg = " --> Player's Turn.";
                    }
                    else {
                        _dMsg = " --> Dealer Wins.";
                        _roundInProgress = false;
                    }
                // If player wins
                } else if((21 - _dCardTotal) > (21 - _pCardTotal)) {
                    if(_splitting == true) {
                        _splitCount += 1;
                        _dMsg = " --> Player's Turn.";
                        // Update balance
                        _safeBalance += (_pBet * 2);
                    }
                    else {
                        _dMsg = " --> Player Wins.";
                        // Update balance: bet * 2
                        _safeBalance += (_pBet * 2);
                        _roundInProgress = false;
                    }
                // If its a standoff
                } else {
                    if(_splitting == true) {
                        _splitCount += 1;
                        _dMsg = " --> Player's Turn.";
                        // Update balance
                        _safeBalance += _pBet;
                    }
                    else {
                        _dMsg = " --> StandOff!";
                        // End round
                        _roundInProgress = false;
                        // Update balance: bet
                        _safeBalance += _pBet;
                    }
                }
            // Player card can only be greater than 21 on double down hand
            } else {
                _dMsg = " --> Player Bust! Dealer Wins.";
            }
        }
        
        return _dMsg;
    }
    
    
    // Double down
    function doubleDown() isValidAddr isPlayer playerTurn 
        public returns (string memory) {
        // Make sure player can double down
        require(_dDown == true, "Player cannot Double Down right now.");
        
        // If player has a chance to split but doubles down
        if(_split == true) {
            // Remove chance to split
            _split = false;
        }
        // If player has a chance to get insurance but doesn't
        if(_insurance == true) {
            // Remove chance to get insurance
            _insurance = false;
        }
        
        // Place same amount as original Bet
        uint256 bet = _pBet; 
        
        // Pause game to place Bet
        _roundInProgress = false;
        
        // Place Bet and resume game
        placeBet(bet);
        
        // Deal extra card
        _pNewCard = RNG();
        // Ace is 1 unless Player has a total less than 11
        if(_pNewCard == 1 && _pCardTotal < 11) {
            // Ace = 11
            _pNewCard = 11;
        }
        
        // Update player's card total
        _pCardTotal += _pNewCard;
        
        // Let dealer finish his hand and end round
        return stand();
    }
    
    // Split
    function split() isValidAddr isPlayer playerTurn public returns (string memory) {
        // Make sure player can double down
        require(_split == true, "Player cannot Split right now.");
        
        // If player has a chance to double down but splits
        if(_dDown == true) {
            // Remove chance to double down
            _dDown = false;
        }
        // If player has a chance to get insurance but doesn't
        if(_insurance == true) {
            // Remove chance to get insurance
            _insurance = false;
        }
        
        // Update balances
        if(_pCard1 == 11) {
            _pCardTotal = 11;
            _pSplitTotal = 11;
        }
        else {
            _pCardTotal = _pCardTotal/2;
            _pSplitTotal = _pCardTotal;
        }
        
        // Place same amount as original Bet
        uint256 bet = _pBet;
        
        // Pause game to place Bet
        _roundInProgress = false;
        
        // Place bet and resume game
        placeBet(bet);
        
        // Turn splitting on
        _splitting = true;
        
        // Turn chance to split again off
        _split = false;
        
        // If player's cards are both Aces
        if(_pCard1 == 11) {
            // Deal only one more card for card 1
            _pNewCard = RNG();
            // Ace is always 1 in this case 
            
            // Update split card total
            _pSplitTotal += _pNewCard;
            
            // Then stand
            stand();
            
            // Turn splitting off
            _splitting = false;
            // Make sure dealer doesn't draw again
            _splitCount = 2;
            
            // Deal only one more card for card 2
            _pNewCard = RNG();
            // Ace is always 1 in this case 
            
            // Update player split total
            _pCardTotal += _pNewCard;
            
            // Then stand
            stand();
        }
    }
    
    // Insurance
    function insurance() isValidAddr isPlayer playerTurn 
        public returns (string memory) {
        // Make sure player can have insurance
        require(_insurance == true, "Player cannot have insurance right now.");
        
        // Place half amount as original Bet
        uint256 bet = _pBet/2; 
        
        // Insure
        _insured = true;
        
        // Pause game to place Bet
        _roundInProgress = false;
        
        // Place Bet and resume game
        placeBet(bet);
        
    }
    
    function dDownInsSplit() internal {
        // If player has a chance to double down but hits
        if(_dDown == true) {
            // Remove chance to double down
            _dDown = false;
        }
        
        // If player has a chance to split 
        if(_split == true || _splitting == true) {
            if(_splitCount >= 2) {
                // Remove chance to split after splitting
                _splitting = false;
                _split = false;
            }
            else if(_splitting == true) {
                // Start split counter if player is splitting
                _splitCount = 1;
            } else {
            
                // If not splitting, remove chance to split
                _split = false;
            }
        }
        
        // If player has a chance to get insurance but hits
        if(_insurance == true) {
            // Remove chance to get insurance
            _insurance = false;
        }
    }
    
    function hitWin(uint256 _cTotal) internal {
        
        // BlackJack or bust
        if(_cTotal == 21) {
            // If there might be a standoff
            if(_dCard1 >= 10) {
                // Show dealer's second card
                _dCard2 = RNG();
                // Update dealer card total
                _dCardTotal = _dCard1 + _dCard2;
            }
            
            // Choose winner
            if(_dCardTotal == _cTotal) {
                _dMsg = " --> StandOff!";
                // Update balance
                if(_insured == true) {
                    _insured = false;
                    _safeBalance += (_pBet/2);
                }
                _safeBalance += _pBet;
                _roundInProgress = false;
            }
            else {
                _dMsg = " --> BlackJack! Player Wins.";
                // Update balance: bet * 2
                _safeBalance += (_pBet * 2);
                _roundInProgress = false;
            }
        } else if(_cTotal > 21) {
            _dMsg = " --> Player Bust! Dealer Wins.";
            
            // If player was insured
            if(_insured == true) {
                _insured = false;
                // Show dealer's second card
                _dCard2 = RNG();
                // Update dealer card total
                _dCardTotal = _dCard1 + _dCard2;
                // Update balance
                if(_dCardTotal == 21)
                    _safeBalance += _pBet;
            }
            _roundInProgress = false; 
        }
        else
            _dMsg = " --> Player's Turn.";
        
    }
    
    function displayTable() 
        public 
        view 
        returns (string memory Message, uint256 PlayerBet, uint256 PlayerCard1, uint256 PlayerCard2, 
                    uint256 PlayerNewCard, uint256 PlayerCardTotal, uint256 PlayerSplitTotal, 
                    uint256 DealerCard1, uint256 DealerCard2, uint256 DealerNewCard1, 
                    uint256 DealerNewCard2, uint256 DealerCardTotal, uint256 Pot) {
                        
            
        return (_dMsg, _pBet, _pCard1, _pCard2, _pNewCard, _pCardTotal, _pSplitTotal, 
            _dCard1, _dCard2, _dNewCard[0], _dNewCard[1], _dCardTotal, _safeBalance);
    }
    
}