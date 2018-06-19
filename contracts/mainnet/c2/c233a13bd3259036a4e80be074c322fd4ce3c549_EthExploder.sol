pragma solidity ^0.4.21;


contract Owned {
     address public owner;
    address public newOwner;
    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }

    function transferOwnership(address _newOwner) onlyOwner {
        newOwner = _newOwner;
    }
 
    function acceptOwnership() {
        if (msg.sender == newOwner) {
            OwnershipTransferred(owner, newOwner);
            owner = newOwner;
        }
    }
    
}


contract EthExploder is Owned { 
    uint256 public jackpotSmall;
    uint256 public jackpotMedium; 
    uint256 public jackpotLarge; 
    
    uint256 public houseEarnings; 
    uint256 public houseTotal; 
    
    uint256 public gameCount; 
    
    uint16 public smallCount; 
    uint16 public mediumCount; 
    uint16 public largeCount; 
    
    uint16 public smallSize; 
    uint16 public mediumSize;
    uint16 public largeSize; 
    
    uint256 public seed; 
    
    mapping (uint16 => address) playersSmall; 
    mapping (uint16 => address) playersMedium; 
    mapping (uint16 => address) playersLarge; 
    
    function enterSmall() payable {
        require(msg.value > 0);
        
        jackpotSmall += msg.value; 
        playersSmall[smallCount] = msg.sender; 
        seed += uint256(msg.sender);
        
        if (smallCount < smallSize-1) { 
            smallCount++;
        } else { 
            seed += gameCount + mediumCount + largeCount;
            houseEarnings += (jackpotSmall*3)/100;
            jackpotSmall -= (jackpotSmall*3)/100;
            
            uint16 winner = uint16(seed % smallSize); 
            address winning = playersSmall[winner]; 
           
            
            //Reset the game: 
            smallCount = 0; 
            uint256 amt = jackpotSmall;
            jackpotSmall = 0; 
            winning.transfer(amt);
            gameCount++;
            emit GameWon(0,winning,amt); 
        }
    }
    
    function enterMedium() payable { 
        require(msg.value > 0); 
        
        jackpotMedium += msg.value; 
        playersMedium[mediumCount] = msg.sender; 
        seed += uint256(msg.sender);
         
        if (mediumCount < mediumSize-1) { 
            mediumCount++;
        } else { 
            seed += gameCount + smallCount + largeCount;
            houseEarnings += (jackpotMedium*3)/100;
            jackpotMedium -= (jackpotMedium*3)/100;
            
            uint16 winner = uint16(seed % mediumSize); 
            address winning = playersMedium[winner];
            //winning.transfer(jackpotMedium); 
            
            //Reset the game 
            mediumCount = 0; 
            uint256 amt = jackpotMedium;
            jackpotMedium = 0; 
            winning.transfer(amt);
            gameCount++;
            emit GameWon(1,winning,amt); 

        }
    }
    
    function enterLarge() payable { 
        require(msg.value > 0); 
        
        jackpotLarge += msg.value; 
        playersLarge[largeCount] = msg.sender; 
        seed += uint256(msg.sender);
        
        if (largeCount < largeSize-1) { 
            largeCount++; 
        } else { 
            seed += gameCount + mediumCount + largeCount; 
            houseEarnings += (jackpotLarge*3)/100;
            jackpotLarge -= (jackpotLarge*3)/100;
            
            uint16 winner = uint16(seed % largeSize); 
            address winning = playersLarge[winner];
            
            //Reset the game 
            largeCount = 0; 
            uint256 amt = jackpotLarge;
            jackpotLarge = 0; 
            winning.transfer(amt);
            gameCount++;
            emit GameWon(2,winning,amt); 

        }
        
    }
    
    function setPools(uint16 sm, uint16 med, uint16 lrg) onlyOwner { 
        smallSize = sm; 
        mediumSize = med; 
        largeSize = lrg; 
    }
    
    function claim(address payment) onlyOwner { 
        payment.transfer(houseEarnings); 
        houseTotal += houseEarnings; 
        houseEarnings = 0; 
    }
    
    //Prevent accidental ether sending 
    function () payable { 
     revert(); 
 }

 event GameWon(uint8 gameType, address winner, uint256 winnings); 
    
}