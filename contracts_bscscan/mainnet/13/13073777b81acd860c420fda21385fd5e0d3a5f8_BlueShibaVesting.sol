pragma solidity 0.8.10;

import "SafeMath.sol";
import "IBEP20.sol";


contract BlueShibaVesting {
    string public name ="";
    IBEP20 public token;
    address public owner;
    uint256 public contractCreated;
    uint256 public lockedInDays;
    uint256 public totalLockedTokens;
    uint256 public releasePerDay;
    uint256 public releasedCoins;
    
    using SafeMath for uint256;
    
    event Withdraw(address indexed from, uint256 amount);
    
    constructor(string memory _name, uint256 _totalLockedTokens, uint256 _lockedInDays){
        token = IBEP20(0x0a98e7C9CB29ac8116d9F40eeDbFDFfD0a791E8F); // Blue Shiba Contract
        contractCreated = block.timestamp;
        owner = msg.sender;
        name = _name;
        lockedInDays = _lockedInDays;
        totalLockedTokens = _totalLockedTokens;
        releasePerDay = totalLockedTokens.div(lockedInDays);
    }
    
    function unlockCoins() external {
        require(msg.sender == owner, "Only the owner can withdraw the vested coins");
        uint daysElapsed = block.timestamp.sub(contractCreated).div(86400); // a day has 86400 seconds
        uint256 availableCoins = daysElapsed.mul(releasePerDay).sub(releasedCoins);
        require(availableCoins > 0, "No Tokens to withdraw, try tomorrow");
        if(availableCoins > token.balanceOf(address(this))){
            availableCoins = token.balanceOf(address(this));
        }
        releasedCoins = releasedCoins.add(availableCoins);
        token.transfer(owner, availableCoins);
        emit Withdraw(msg.sender, availableCoins);
    }
    
    //In the case when the balance of the contract is more than 'totalLockedTokens'.
    //Might happen if we accidentally send too many flokis.
    //BUT: The token amount in 'totalLockedTokens' is still vested and cannot be withdrawn early.
    function recoverTokens(address tokenaddress) external{
        require(msg.sender == owner, "Only the owner can call this function");
        if(tokenaddress == address(token)){
            require(token.balanceOf(address(this)) > totalLockedTokens);
            uint256 toomany = token.balanceOf(address(this)).sub(totalLockedTokens);
            token.transfer(owner, toomany);
        }else{
            IBEP20 othertoken = IBEP20(tokenaddress);
            othertoken.transfer(owner, othertoken.balanceOf(address(this)));
        }
    }
}