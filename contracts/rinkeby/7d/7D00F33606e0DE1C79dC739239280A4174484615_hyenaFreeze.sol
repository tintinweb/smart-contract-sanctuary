pragma solidity 0.6.4;

import "./SafeMath.sol";
import "./IERC20.sol";

////////////////////////////////////////////////
////////////////////EVENTS/////////////////////
//////////////////////////////////////////////

contract TokenEvents {

    //when a user freezes tokens
    event TokenFreeze(
        address indexed user,
        uint value,
        uint length
    );

    //when a user unfreezes tokens
    event TokenUnfreeze(
        address indexed user,
        uint value,
        uint length
    );

}

//////////////////////////////////////
//////////hyenaFREEZE CONTRACT////////
////////////////////////////////////
contract hyenaFreeze is TokenEvents {

    using SafeMath for uint256;

    address public hyenaAddress = 0xE102c5F87537927A1B5378151594C8D6B4f00450;
    IERC20 hyenaInterface = IERC20(hyenaAddress);
    //freeze setup
    uint internal daySeconds = 1; // 86400; // seconds in a day
    uint public totalFrozen;
    uint public total90Frozen;
    uint public total180Frozen;
    uint public total270Frozen;
    uint public total365Frozen;
    
    mapping (address => uint) public token90FrozenBalances;//balance of hyena frozen mapped by user
    mapping (address => uint) public token180FrozenBalances;//balance of hyena frozen mapped by user
    mapping (address => uint) public token270FrozenBalances;//balance of hyena frozen mapped by user
    mapping (address => uint) public token365FrozenBalances;//balance of hyena frozen mapped by user
    
    bool private sync;

    mapping (address => Frozen) public frozen;

    struct Frozen{
        uint256 freeze90StartTimestamp;
        uint256 freeze180StartTimestamp;
        uint256 freeze270StartTimestamp;
        uint256 freeze365StartTimestamp;
    }
    
    //protects against potential reentrancy
    modifier synchronized {
        require(!sync, "Sync lock");
        sync = true;
        _;
        sync = false;
    }

    constructor() public {

    }

    ////////////////////////////////////////////////////////
    /////////////////PUBLIC FACING - hyena FREEZE CONTROL//////////
    //////////////////////////////////////////////////////

    //freeze hyena tokens to contract
    function FreezeTokens(uint amt, uint dayLength)
        public
    {
        require(amt > 0, "zero input");
        require(hyenaInterface.balanceOf(msg.sender) >= amt, "Error: insufficient balance");//ensure user has enough funds
        if(isFreezeFinished(msg.sender, dayLength)){
            UnfreezeTokens(dayLength);//unfreezes all currently frozen tokens + profit
        }
        //update balances
        if(dayLength == 90){
            token90FrozenBalances[msg.sender] = token90FrozenBalances[msg.sender].add(amt);
            total90Frozen = total90Frozen.add(amt);
            totalFrozen = totalFrozen.add(amt);
            frozen[msg.sender].freeze90StartTimestamp = now;
            hyenaInterface.transferFrom(msg.sender, address(this), amt);//make transfer
        }
        else if(dayLength == 180){
            token180FrozenBalances[msg.sender] = token180FrozenBalances[msg.sender].add(amt);
            total180Frozen = total180Frozen.add(amt);
            totalFrozen = totalFrozen.add(amt);
            frozen[msg.sender].freeze180StartTimestamp = now;
            hyenaInterface.transferFrom(msg.sender, address(this), amt);//make transfer
        }
        else if(dayLength == 270){
            token270FrozenBalances[msg.sender] = token270FrozenBalances[msg.sender].add(amt);
            total270Frozen = total270Frozen.add(amt);
            totalFrozen = totalFrozen.add(amt);
            frozen[msg.sender].freeze270StartTimestamp = now;
            hyenaInterface.transferFrom(msg.sender, address(this), amt);//make transfer
        }
        else if(dayLength == 365){
            token365FrozenBalances[msg.sender] = token365FrozenBalances[msg.sender].add(amt);
            total365Frozen = total365Frozen.add(amt);
            totalFrozen = totalFrozen.add(amt);
            frozen[msg.sender].freeze365StartTimestamp = now;
            hyenaInterface.transferFrom(msg.sender, address(this), amt);//make transfer
        }
        else{
            revert();
        }
        emit TokenFreeze(msg.sender, amt, dayLength);
    }
    
    //unfreeze hyena tokens from contract
    function UnfreezeTokens(uint dayLength)
        public
        synchronized
    {
        uint amt = 0;
        if(dayLength == 90){
            require(token90FrozenBalances[msg.sender] > 0,"Error: unsufficient frozen balance");//ensure user has enough frozen funds
            require(isFreezeFinished(msg.sender, dayLength), "tokens cannot be unfrozen yet, min 90 days");
            amt = token90FrozenBalances[msg.sender];
            token90FrozenBalances[msg.sender] = 0;
            frozen[msg.sender].freeze90StartTimestamp = 0;
            total90Frozen = total90Frozen.sub(amt);
            totalFrozen = totalFrozen.sub(amt);
            hyenaInterface.transfer(msg.sender, amt);//make transfer
        }
        else if(dayLength == 180){
            require(token180FrozenBalances[msg.sender] > 0,"Error: unsufficient frozen balance");//ensure user has enough frozen funds
            require(isFreezeFinished(msg.sender, dayLength), "tokens cannot be unfrozen yet, min 180 days");
            amt = token180FrozenBalances[msg.sender];
            token180FrozenBalances[msg.sender] = 0;
            frozen[msg.sender].freeze180StartTimestamp = 0;
            total180Frozen = total180Frozen.sub(amt);
            totalFrozen = totalFrozen.sub(amt);
            hyenaInterface.transfer(msg.sender, amt);//make transfer
        }
        else if(dayLength == 270){
            require(token270FrozenBalances[msg.sender] > 0,"Error: unsufficient frozen balance");//ensure user has enough frozen funds
            require(isFreezeFinished(msg.sender, dayLength), "tokens cannot be unfrozen yet, min 270 days");
            amt = token270FrozenBalances[msg.sender];
            token270FrozenBalances[msg.sender] = 0;
            frozen[msg.sender].freeze270StartTimestamp = 0;
            total270Frozen = total270Frozen.sub(amt);
            totalFrozen = totalFrozen.sub(amt);
            hyenaInterface.transfer(msg.sender, amt);//make transfer
        }
        else if(dayLength == 365){
            require(token365FrozenBalances[msg.sender] > 0,"Error: unsufficient frozen balance");//ensure user has enough frozen funds
            require(isFreezeFinished(msg.sender, dayLength), "tokens cannot be unfrozen yet, min 365 days");
            amt = token365FrozenBalances[msg.sender];
            token365FrozenBalances[msg.sender] = 0;
            frozen[msg.sender].freeze365StartTimestamp = 0;
            total365Frozen = total365Frozen.sub(amt);
            totalFrozen = totalFrozen.sub(amt);
            hyenaInterface.transfer(msg.sender, amt);//make transfer
        }
        else{
            revert();
        }

        emit TokenUnfreeze(msg.sender, amt, dayLength);
    }
    
    ///////////////////////////////
    ////////VIEW ONLY//////////////
    ///////////////////////////////

    function isFreezeFinished(address _user, uint freezeDayLength)
        public
        view
        returns(bool)
    {
        if(freezeDayLength == 90){
            if(frozen[_user].freeze90StartTimestamp == 0){
                return false;
            }
            else{
               return frozen[_user].freeze90StartTimestamp.add(freezeDayLength.mul(daySeconds)) <= now;               
            }
        }
        else if(freezeDayLength == 180){
            if(frozen[_user].freeze180StartTimestamp == 0){
                return false;
            }
            else{
               return frozen[_user].freeze180StartTimestamp.add(freezeDayLength.mul(daySeconds)) <= now;               
            }
        }
        else if(freezeDayLength == 270){
            if(frozen[_user].freeze270StartTimestamp == 0){
                return false;
            }
            else{
               return frozen[_user].freeze270StartTimestamp.add(freezeDayLength.mul(daySeconds)) <= now;               
            }
        }
        else if(freezeDayLength == 365){
            if(frozen[_user].freeze365StartTimestamp == 0){
                return false;
            }
            else{
               return frozen[_user].freeze365StartTimestamp.add(freezeDayLength.mul(daySeconds)) <= now;               
            }
        }
        else{
            return false;
        }
    }
}