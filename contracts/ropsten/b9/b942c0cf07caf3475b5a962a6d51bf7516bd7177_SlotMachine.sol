// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./IBEP20.sol";
import "./Ownable.sol";

contract SlotMachine is Ownable{
    using SafeMath for uint256;
    
    uint256 betNo  = 0 ;
    uint256 userId = 0 ;
    bool initialized = false;

    IBEP20 private token;
    
    struct UserStruct {
        bool isExist;
        uint256 totalBet;
        uint256 win;
        uint256 lose;
        uint256 winAmount;
        uint256 loseAmount;
    }
    struct BetStruct{
        address user;
        uint256 betAmount;
        uint256 randomNumber;
        uint256 betTime;
        uint256 blocknumber;
    }
    
    mapping ( uint256 => BetStruct )  public betdetails;
    
    mapping ( address => UserStruct ) public user;
    
    mapping ( address => uint256[] ) public bet;

    event PlaceBet(address _user, uint256 _betId, uint256 _amount, uint256 time);
    event ExecuteBet(address indexed _user, uint256 indexed _betId, uint256 indexed _randomNumber, uint256 time);
    
    function initialize(address _token) public onlyOwner returns(bool){
        require(!initialized);
		require(_token != address(0));
		token = IBEP20(_token);
		initialized = true;
		return true;
	}
    
    function placeBet(uint256 amount) public {
        require(amount > 0, "Less Amount");
        if(user[msg.sender].isExist){
            user[msg.sender].totalBet++;
        }else{
            UserStruct memory userInfo;
            userInfo = UserStruct({
                isExist    : true,
                totalBet   : 1,
                win        : 0,
                lose       : 0,
                winAmount  : 0,
                loseAmount : 0
            });
            user[msg.sender] = userInfo;
            userId++;
        }
        betNo++;
        BetStruct memory betInfo;
        betInfo = BetStruct({
             user         : msg.sender,
             betAmount    : amount,
             randomNumber : 0,
             betTime      : block.timestamp,
             blocknumber  : block.number
        });
        betdetails[betNo] = betInfo;
        bet[msg.sender].push(betNo);
        token.transferFrom(msg.sender, address(this), amount);
        emit PlaceBet(msg.sender, betNo, amount, block.timestamp);
    }
    
    function executeBet(uint256 betId) public {
        uint256 randomNo = random(betId);
        betdetails[betId].randomNumber = randomNo;
        if(randomNo < 4){
            user[msg.sender].loseAmount += betdetails[betId].betAmount;
            user[msg.sender].lose++;
        } else if (randomNo >= 4){                           
            user[msg.sender].winAmount += betdetails[betId].betAmount;
            // token.transfer(betdetails[betId].user, betdetails[betId].betAmount.mul(2));
            user[msg.sender].win++;
        }
        emit ExecuteBet(msg.sender, betId, randomNo, block.timestamp);
    }
    
    function random (uint256 betId) internal view returns (uint256){
        if(blockhash(betdetails[betId].blocknumber + 1) != 0){
            return (uint256(keccak256(abi.encodePacked(blockhash(betdetails[betId].blocknumber + 1)))).mod(10) + 1);
        } else {
            return 1;
        }
    }
    
     function userBet (address _address) public view returns (uint256 _totalBet, uint256 _lastBet){
        return (bet[_address].length, bet[_address][bet[_address].length - 1] );
    }

    // function withdrawal(uint256 amount, address toAddress) public onlyOwner {
    //     token.transfer(toAddress, amount);
    // }
    
}