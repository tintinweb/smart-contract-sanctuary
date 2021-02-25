/**
 *Submitted for verification at Etherscan.io on 2021-02-25
*/

pragma solidity ^0.5.16;

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
        uint256 gameStatus;
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

    mapping(uint256=>game) public gameDetails;
    mapping(uint256=>betting[]) public bettingDetails;

    address payable owner;
    
    event gameInfo(uint256 indexed _gameId,uint256 _startTime, uint256 _oddHome,uint256 _oddAway);
    event sigleBet(uint256 indexed _gameId,uint256 _userId,uint256 _selectedTeam, uint256 _oddAmount, uint256 _betAmount);
    event singleBetWin(uint256 indexed _gameId, uint256 _homeDrawAway);
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
    * @param _gameStatus Status of that Game 1- pending 2- done
    */
    function addGame(uint256 _gameId,uint256 _startTime, uint256 _oddHome,uint256 _oddAway, uint256 _gameStatus) onlyOwner public returns(bool) {
        gameDetails[_gameId].gameId = _gameId;
        gameDetails[_gameId].startTime = _startTime;
        gameDetails[_gameId].oddHome = _oddHome;
        gameDetails[_gameId].oddAway = _oddAway;
        gameDetails[_gameId].gameStatus = _gameStatus;
        gameDetails[_gameId].isPaid = false;
        
        emit gameInfo(_gameId,_startTime,_oddHome,_oddAway);
        return true;
    }
    
    /**
    * @dev getGameInfo fetches corresponding game in contract
    * @param _gameId Unique Game Id
    */
    function getGameInfo(uint256 _gameId) onlyOwner public view returns(
        uint256 startTime, uint256 oddHome,uint256 oddAway, uint256 gameStatus, bool isPaid) {

        startTime = gameDetails[_gameId].startTime;
        oddHome = gameDetails[_gameId].oddHome;
        oddAway = gameDetails[_gameId].oddAway;
        gameStatus = gameDetails[_gameId].gameStatus;
        isPaid = gameDetails[_gameId].isPaid;

    }
    
    /**
    * @dev placeSingleBet Place the Single Bet by User.
    * @param _gameId Unique Game Id
    * @param _userId Unique User Id
    * @param _selectedTeam Selected Team Index Number  (1 or 2) 1- Home 2- Away 
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
        } else {
            revert("Invalid Data");
        }
       
        require(gameDetails[_gameId].gameStatus == 1);
        require( now < (gameDetails[_gameId].startTime.sub(10 minutes)), "Time is Ended");
        
        bettingDetails[_gameId].push(betting(_userId,msg.sender,_gameId,_betAmount,_oddAmount,_selectedTeam));
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_betAmount);
        
        emit sigleBet(_gameId,_userId,_selectedTeam,_oddAmount, _betAmount);
        return true;
    }

    /**
    * @dev sendGameWinningAmount Anounce the Winner of Game and distribute the Amount to Users. (Single Bet)
    * @param _gameId array of Unique Game Id
    * @param _homeDrawAway  Won Team Index Number  (1 to 3) 1- Home 2- Away 3-Draw 
    */
    function sendGameWinningAmount(uint256 _gameId, uint256 _homeDrawAway) public onlyOwner payable returns(bool){
        require(gameDetails[_gameId].gameStatus == 1 
        && gameDetails[_gameId].isPaid==false,"Status Failed");
        
        // Give the prize money!
        for (uint i= 0 ; i < bettingDetails[_gameId].length; i++){
            uint256 selectedTeam = bettingDetails[_gameId][i].selectedOdd;
            uint256 returnEth = (bettingDetails[_gameId][i].betAmount * bettingDetails[_gameId][i].oddAmount) / 10**18;
            
            if((selectedTeam == 1 && _homeDrawAway == 1) || (selectedTeam == 2 && _homeDrawAway == 2)  
            ) { 
                require(returnEth <= getContractBalance(), "Insufficient Contract Balance");
                balanceOf[bettingDetails[_gameId][i].player] = balanceOf[bettingDetails[_gameId][i].player].add(returnEth);
            }
        }
        
        gameDetails[_gameId].gameStatus = 2; //paid
        gameDetails[_gameId].isPaid = true; 
        
        emit singleBetWin(_gameId,_homeDrawAway);
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