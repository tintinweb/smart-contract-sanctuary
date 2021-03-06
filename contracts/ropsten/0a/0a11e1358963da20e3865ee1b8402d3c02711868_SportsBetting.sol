/**
 *Submitted for verification at Etherscan.io on 2021-03-06
*/

/**
 *Submitted for verification at Etherscan.io on 2021-02-04
*/

pragma solidity ^0.6.12;

//SPDX-License-Identifier: UNLICENSED

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}


contract SportsBetting {
    
    using SafeMath for uint256;
    
    struct game {
        uint256 gameId;
        uint256 startTime;
        uint256 oddHome;
        uint256 oddAway;
        uint256 oddDraw;
        uint256 oddHomeDraw;
        uint256 oddDrawAway;
        uint256 oddHomeAway;
        uint256 oddStatus;
        bool isPaid;
    }
    
    struct betting{
        uint256 userId;
        address payable player;
        uint256 gameId;
        uint256 betAmount;
        uint256 oddAmount;
        uint256 selectedOdd;
    }
    
    struct multipleBet {
        uint256 userId;
        address payable player;
        uint256[] multiplegameId;
        uint256 multipleBetAmount;
        uint256[] multipleOddAmount;
        uint256[] multiplSelectedOdd;
        bool isDone;
    }
    
    mapping(uint256=>game) public gameDetails;
    mapping(uint256=>betting[]) public bettingDetails;
    mapping(uint256=>multipleBet[]) public multiBetDetails;
    
    address payable owner;
    
    event gameInfo(uint256 indexed _gameId,uint256 _startTime, uint256 _oddHome,uint256 _oddAway, uint256 _oddDraw, uint256 _oddHomeDraw, uint256 _oddDrawAway, uint256 _oddHomeAway);
    event changeGameInfo(uint256 indexed _gameId, uint256 _oddHome,uint256 _oddAway, uint256 _oddDraw, uint256 _oddHomeDraw, uint256 _oddDrawAway, uint256 _oddHomeAway);
    event sigleBet(uint256 indexed _gameId,uint256 _userId,uint256 _selectedTeam, uint256 _oddAmount, uint256 _betAmount);
    event multiBet(uint256 indexed _userId, uint256[]  _gameId, uint256[]  _oddAmount, uint256 _betAmount,uint256[]  _selectedTeam);
    event singleBetWin(uint256 indexed _gameId, uint256 _homeDrawAway);
    event multiBetWin(uint256  indexed _userId,uint256 index, uint256[]  _homeDrawAway);
    event ownerChange(address _owner, uint256 _timeStamp);
    event withDraw(address indexed _owner,uint256 _amount, uint256 _timeStamp);
    
    modifier onlyOwner {
        require(msg.sender == owner, "Only Owner" );
        _;
    }
    
    constructor() public {
        owner = msg.sender;
    }
    
    
    mapping(address=>uint256) public balanceOf;
    
    function deposit() payable public returns(bool) {
        require(msg.value>0, "Invalid Amount");
        balanceOf[msg.sender] = balanceOf[msg.sender].add(msg.value);
        return true;
    }
    
    
    /**
    * @dev addGame Add the game in contract.
    * @param _gameId Unique Game Id
    * @param _startTime Start Time of that Game
    * @param _oddHome Odd Amount for Home Team
    * @param _oddAway Odd Amount for Away Team
    * @param _oddDraw Odd Amount for Draw Team
    * @param _oddHomeDraw Odd Amount for Home/Draw Team
    * @param _oddDrawAway Odd Amount for Draw/Away Team
    * @param _oddHomeAway Odd Amount for Home/Away Team
    * @param _oddStatus Status of that Game 1- pending 2- done
    */
    function addGame(uint256 _gameId,uint256 _startTime, uint256 _oddHome,uint256 _oddAway, uint256 _oddDraw, uint256 _oddHomeDraw,
                        uint256 _oddDrawAway, uint256 _oddHomeAway, uint256 _oddStatus) onlyOwner public returns(bool) {
        gameDetails[_gameId].gameId = _gameId;
        gameDetails[_gameId].startTime = _startTime;
        gameDetails[_gameId].oddHome = _oddHome;
        gameDetails[_gameId].oddAway = _oddAway;
        gameDetails[_gameId].oddDraw = _oddDraw;
        gameDetails[_gameId].oddHomeDraw = _oddHomeDraw;
        gameDetails[_gameId].oddDrawAway = _oddDrawAway;
        gameDetails[_gameId].oddHomeAway = _oddHomeAway;
        gameDetails[_gameId].oddStatus = _oddStatus;
        gameDetails[_gameId].isPaid = false;
        
        emit gameInfo(_gameId,_startTime,_oddHome,_oddAway,_oddDraw,_oddHomeDraw,_oddDrawAway,_oddHomeAway);
        return true;
    }
    
    
    /**
    * @dev changeOddDetails Change the Odd Details.
    * @param _gameId Unique Game Id
    * @param _oddHome Odd Amount for Home Team
    * @param _oddAway Odd Amount for Away Team
    * @param _oddDraw Odd Amount for Draw Team
    * @param _oddHomeDraw Odd Amount for Home/Draw Team
    * @param _oddDrawAway Odd Amount for Draw/Away Team
    * @param _oddHomeAway Odd Amount for Home/Away Team
    */
    function changeOddDetails(uint256 _gameId,uint256 _oddHome,uint256 _oddAway, uint256 _oddDraw, uint256 _oddHomeDraw,
                        uint256 _oddDrawAway, uint256 _oddHomeAway) onlyOwner public returns(bool) {
        gameDetails[_gameId].oddHome = _oddHome;
        gameDetails[_gameId].oddAway = _oddAway;
        gameDetails[_gameId].oddDraw = _oddDraw;
        gameDetails[_gameId].oddHomeDraw = _oddHomeDraw;
        gameDetails[_gameId].oddDrawAway = _oddDrawAway;
        gameDetails[_gameId].oddHomeAway = _oddHomeAway;
        
        emit changeGameInfo(_gameId,_oddHome,_oddAway,_oddDraw,_oddHomeDraw,_oddDrawAway,_oddHomeAway);
        return true;
    }
    
    
    /**
    * @dev placeSingleBet Place the Single Bet by User.
    * @param _gameId Unique Game Id
    * @param _userId Unique User Id
    * @param _selectedTeam Selected Team Index Number  (1 to 6) 1- Home 2- Away 3-Draw 4-Home/Draw 5-Draw/Away 6-Home/Away
    * @param _oddAmount Odd Amount for Selected Team
    * @param _betAmount amount for singlebet
    */
    function placeSingleBet(uint256 _gameId,uint256 _userId,uint256 _selectedTeam, uint256 _oddAmount, uint256 _betAmount) public returns(bool) {
        require(_betAmount<= balanceOf[msg.sender], "Insufficient Blance to Bet");
        
        // Compare to match mainnet odds with was submitted odds by betting type
        if(_selectedTeam == 1 ) {
            require(gameDetails[_gameId].oddHome == _oddAmount);
        } else if ( _selectedTeam == 2) {
            require(gameDetails[_gameId].oddAway == _oddAmount);
        } else if ( _selectedTeam == 3) {
            require(gameDetails[_gameId].oddDraw == _oddAmount);
        } else if ( _selectedTeam == 4) {
            require(gameDetails[_gameId].oddHomeDraw == _oddAmount);
        } else if ( _selectedTeam == 5) {
            require(gameDetails[_gameId].oddDrawAway == _oddAmount);
        } else if ( _selectedTeam == 6) {
            require(gameDetails[_gameId].oddHomeAway == _oddAmount);
        } else {
            revert("Invalid Data");
        }
       
       require(gameDetails[_gameId].oddStatus == 1);
       require( now < (gameDetails[_gameId].startTime.sub(10 minutes)), "Time is Ended");
    
       bettingDetails[_gameId].push(betting(_userId,msg.sender,_gameId,_betAmount,_oddAmount,_selectedTeam));
       balanceOf[msg.sender] = balanceOf[msg.sender].sub(_betAmount);
       
       emit sigleBet(_gameId,_userId,_selectedTeam,_oddAmount, _betAmount);
       return true;
    }
    
    
    /**
    * @dev placeMultipleBet Place the Multiple Bet by User.
    * @param _userId Unique User Id
    * @param _gameId array of Unique Game Id
    * @param _oddAmount array of Odd Amount for Selected Team
    * @param _selectedTeam array of Selected Team Index Number  (1 to 6) 1- Home 2- Away 3-Draw 4-Home/Draw 5-Draw/Away 6-Home/Away
    * @param _betAmount amount for multiple bet
    */
    function placeMultipleBet(uint256 _userId, uint256[] memory _gameId, uint256[] memory _oddAmount, uint256[] memory _selectedTeam, uint256 _betAmount) public returns(bool) {
        require(_betAmount<= balanceOf[msg.sender], "Insufficient Blance to Bet");
         
        for(uint256 i=0; i<_gameId.length; i++)
        {
            if (_selectedTeam[i] == 1 ) {
                require(gameDetails[_gameId[i]].oddHome == _oddAmount[i]);
            } else if ( _selectedTeam[i] == 2) {
                require(gameDetails[_gameId[i]].oddAway == _oddAmount[i]);
            } else if ( _selectedTeam[i] == 3) {
                require(gameDetails[_gameId[i]].oddDraw == _oddAmount[i]);
            } else if ( _selectedTeam[i] == 4) {
                require(gameDetails[_gameId[i]].oddHomeDraw == _oddAmount[i]);
            } else if ( _selectedTeam[i] == 5) {
                require(gameDetails[_gameId[i]].oddDrawAway == _oddAmount[i]);
            } else if ( _selectedTeam[i] == 6) {
                require(gameDetails[_gameId[i]].oddHomeAway == _oddAmount[i]);
            } else {
                revert("Invalid Data");
            }
           require(gameDetails[_gameId[i]].oddStatus == 1);
           require( now < ( gameDetails[_gameId[i]].startTime.sub(10 minutes)),"Time is Ended");
        }
        
        
        multiBetDetails[_userId].push(multipleBet(_userId,msg.sender,_gameId,_betAmount,_oddAmount,_selectedTeam,false));
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_betAmount);
        emit multiBet(_userId,_gameId,_oddAmount,_betAmount,_selectedTeam);
        return true;
    }
    
    
    /**
    * @dev sendGameWinningAmount Anounce the Winner of Game and distribute the Amount to Users. (Single Bet)
    * @param _gameId array of Unique Game Id
    * @param _homeDrawAway  Won Team Index Number  (1 to 3) 1- Home 2- Away 3-Draw 
    */
    function sendGameWinningAmount(uint256 _gameId, uint256 _homeDrawAway) public onlyOwner payable returns(bool){
        require(gameDetails[_gameId].oddStatus == 1 && gameDetails[_gameId].isPaid==false,"Status Failed");
         
         // Give the prize money!
        for (uint i= 0 ; i < bettingDetails[_gameId].length; i++){
          uint256 selectedTeam = bettingDetails[_gameId][i].selectedOdd;
          uint256 returnEth = (bettingDetails[_gameId][i].betAmount * bettingDetails[_gameId][i].oddAmount) / 10**18;
          
        if((selectedTeam == 1 && _homeDrawAway == 1) 
          || (selectedTeam == 2 && _homeDrawAway == 2) 
          || (selectedTeam == 3 && _homeDrawAway == 3) 
          || (selectedTeam == 4 && ( _homeDrawAway == 1 || _homeDrawAway == 3) )
          || (selectedTeam == 5 && ( _homeDrawAway == 3 || _homeDrawAway == 2) )
          || (selectedTeam == 6 && ( _homeDrawAway == 1 || _homeDrawAway == 2) ) 
          ) { 
                require(returnEth <= getContractBalance(), "Insufficient Contract Balance");
               // bettingDetails[_gameId][i].player.transfer(returnEth);
                balanceOf[bettingDetails[_gameId][i].player] = balanceOf[bettingDetails[_gameId][i].player].add(returnEth);
            }
        }
        
        gameDetails[_gameId].oddStatus = 2; //paid
        gameDetails[_gameId].isPaid = true; 
        
        emit singleBetWin(_gameId,_homeDrawAway);
        return true;
        
    }
    
    
    /**
    * @dev sendGameWinningAmount Anounce the Winner of Game and distribute the Amount to Users. (Multiple Bet)
    * @param _userId array of Unique User Id
    * @param index count of multiple bets for that user which is not processed done.
    * @param _homeDrawAway array of Won Team Index Number  (1 to 3) 1- Home 2- Away 3-Draw 
    */
    function sendMultiGameWinningAmount(uint256  _userId,uint256 index, uint256[] memory _homeDrawAway) public onlyOwner payable returns(bool) { 
        uint256[] memory _gameId;
        uint256[] memory selectedTeam;
        uint256 returnEth;
        uint8 count = 0;
        
            require(multiBetDetails[_userId][index].isDone==false, "Invalid Status");
            _gameId =  multiBetDetails[_userId][index].multiplegameId;
            
            for(uint256 j=0; j< _gameId.length;j++) {
                
               require(gameDetails[_gameId[j]].oddStatus == 1 && gameDetails[_gameId[j]].isPaid==false,"Status Failed");
                selectedTeam = multiBetDetails[_userId][index].multiplSelectedOdd;
                returnEth = returnEth.add(multiBetDetails[_userId][index].multipleOddAmount[j]);
                
                if((selectedTeam[j] == 1 && _homeDrawAway[j] == 1) 
                || (selectedTeam[j] == 2 && _homeDrawAway[j] == 2) 
                || (selectedTeam[j] == 3 && _homeDrawAway[j] == 3) 
                || (selectedTeam[j] == 4 && ( _homeDrawAway[j] == 1 || _homeDrawAway[j] == 3) )
                || (selectedTeam[j] == 5 && ( _homeDrawAway[j] == 3 || _homeDrawAway[j] == 2) )
                || (selectedTeam[j] == 6 && ( _homeDrawAway[j] == 1 || _homeDrawAway[j] == 2) ) 
                )
                {
                    count = count + 1;
                
                }
                
                gameDetails[_gameId[j]].oddStatus = 2;
                gameDetails[_gameId[j]].isPaid = true;
         
            
            if(count == _gameId.length)  {
                require(returnEth <= getContractBalance(), "Insufficient Contract Balance");
                returnEth = (returnEth.mul(multiBetDetails[_userId][index].multipleBetAmount)).div(10**18);
                // multiBetDetails[_userId][index].player.transfer(returnEth);
                balanceOf[multiBetDetails[_userId][index].player] = balanceOf[multiBetDetails[_userId][index].player].add(returnEth);
            }
            
                multiBetDetails[_userId][index].isDone = true; //paid
        
        }
        
        emit multiBetWin(_userId,index,_homeDrawAway);
        return true;
    }
    
    
    /**
    * @dev getContractBalance To get  the Contract Balance
    */
    function getContractBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
    
    /**
    * @dev changeOwner To change the Owner
    * @param _newOwner address  of new Owner
    */
    function changeOwner(address payable _newOwner) public onlyOwner returns(bool) {
        require(_newOwner!=address(0), "Invalid Address");
        owner = _newOwner;
        emit ownerChange(_newOwner,now);
        return true;
    }
    
    
    
    /**
    * @dev withdraw To withdraw the amount by owner
    * @param _amount withdrawal amount
    */
    function withdraw(uint256 _amount) public returns(bool) {
         require(_amount > 0 && _amount <=balanceOf[msg.sender], "Insufficient Balance");
         (msg.sender).transfer(_amount);
         balanceOf[msg.sender] = balanceOf[msg.sender].sub(_amount);
         emit withDraw(msg.sender,_amount,now);
         return true;
    }
    
    
    /**
    * @dev withdraw To withdraw the amount by owner
    * @param _amount withdrawal amount
    */
    function adminWithdraw(uint256 _amount) external  onlyOwner returns(bool){
        require(_amount > 0 && _amount <= address(this).balance, "Insufficient Balance");
        owner.transfer(_amount);
        emit withDraw(msg.sender,_amount,now);
        return true;
    }
    
    
}