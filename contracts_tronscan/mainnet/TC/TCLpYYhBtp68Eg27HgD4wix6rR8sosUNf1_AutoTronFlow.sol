//SourceUnit: AutoTronFlow.sol

pragma solidity ^ 0.4.25;

library MathLib
{
    function mulitply(uint256 a, uint256 b) internal pure returns(uint256)
    {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function divide(uint256 a, uint256 b) internal pure returns(uint256)
    {
        uint256 c = a / b;
        return c;
    }

    function substract(uint256 a, uint256 b) internal pure returns(uint256)
    {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns(uint256)
    {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract OwnerChangeable
{
    address public owner;

    modifier fakathOwner()
    {
        require(msg.sender == owner, "only for owner");  // 0x0000000000000000000000000000000000000000
        _;
    }

    function changeOwner(address newOwner) public fakathOwner
    {
        owner = newOwner;
    }
}

contract AutoTronFlow is OwnerChangeable
{
    using MathLib for uint256;
    
    event registeredEvent(address indexed _user, address indexed _referrer, uint _time);
    event levelBuyEvent(address indexed _user, uint _level, uint amount, uint _time);
    event debugString(string _debugString);
    event lostMoneyForEvent(address indexed _user, uint level, uint amount, uint _time);
    event sentTrxEvent(address indexed _user, uint remaining, uint _time);

    struct User
    {
        bool isExist;
        uint uid;
        uint nextLevel;
        uint nextLevelReferralCount;
        uint totalEarnings;
        uint totalEarningsLost;
    }

    struct Creator
    {
        bool isExist;
        address wallet;
    }

    Creator creator;

    mapping(uint => uint) public PircesForLevels;
    mapping(uint => uint) public LevelCompletionPayouts;
    mapping(address => User) public MapByAddress_User;
    mapping(uint => address) public MapByIndex_Adderess;
    uint public nextUserIndex = 0;
    uint mult = 1000000;
    uint joiningPrice = 400 * mult;   

    constructor() public
    {
        owner = msg.sender;

        PircesForLevels[0] = 500 * mult;
        PircesForLevels[1] = 2000 * mult;
        PircesForLevels[2] = 4000 * mult;
        PircesForLevels[3] = 8000 * mult;
        PircesForLevels[4] = 16000 * mult;
        PircesForLevels[5] = 32000 * mult;
        PircesForLevels[6] = 64000 * mult;
        PircesForLevels[7] = 128000 * mult;
        PircesForLevels[8] = 256000 * mult;
        PircesForLevels[9] = 512000 * mult;
        PircesForLevels[10] = 1024000 * mult;
        PircesForLevels[11] = 2048000 * mult;
        PircesForLevels[12] = 4096000 * mult;

        LevelCompletionPayouts[0] = 1000 * mult;
        LevelCompletionPayouts[1] = 8000 * mult;
        LevelCompletionPayouts[2] = 16000 * mult;
        LevelCompletionPayouts[3] = 32000 * mult;
        LevelCompletionPayouts[4] = 64000 * mult;
        LevelCompletionPayouts[5] = 128000 * mult;
        LevelCompletionPayouts[6] = 256000 * mult;
        LevelCompletionPayouts[7] = 512000 * mult;
        LevelCompletionPayouts[8] = 1024000 * mult;
        LevelCompletionPayouts[9] = 2048000 * mult;
        LevelCompletionPayouts[10] = 4096000 * mult;
        LevelCompletionPayouts[11] = 8192000 * mult;
        LevelCompletionPayouts[12] = 16384000 * mult;

        creator = Creator({
            isExist : true,
            wallet : owner
            });
    }
    
    function registerNewUser(address _referrer) public payable returns(string)
    {
        require(!MapByAddress_User[msg.sender].isExist, 'User already exist');
        
        if(msg.sender == owner) revert('Owner cannot join');
    
    
        if(MapByAddress_User[_referrer].isExist)
        {
            
        }
        else if(_referrer == address(0) || _referrer == owner)
        {
            _referrer = owner;
        }
        else
        {
            revert('Referrer does not exist');
        }
    
        require(msg.value == joiningPrice, 'Incorrect Value');
    
        User memory newUser;
    
        newUser = User({
            isExist: true,
            uid: nextUserIndex,
            nextLevel: 0,
            nextLevelReferralCount: 0,
            totalEarnings: 0,
            totalEarningsLost: 0
        });
    
        MapByAddress_User[msg.sender] = newUser;
        MapByIndex_Adderess[nextUserIndex] = msg.sender;
        
        if(_referrer != owner) MapByAddress_User[_referrer].nextLevelReferralCount++;

        uint parentIndex = 0;

        if(isEven(nextUserIndex))
        {
            parentIndex = getParentsIndex(nextUserIndex);
            MapByAddress_User[MapByIndex_Adderess[parentIndex]].nextLevel++; 
            MapByAddress_User[MapByIndex_Adderess[parentIndex]].nextLevelReferralCount = 0;
            
            if (!isEven(parentIndex))
            {
                owner.transfer(joiningPrice.mulitply(15).divide(100));    
                
                _referrer.transfer(joiningPrice.mulitply(10).divide(100));
                MapByAddress_User[_referrer].totalEarnings += joiningPrice.mulitply(10).divide(100);
                
                if(nextUserIndex != 0)
                {
                    MapByIndex_Adderess[parentIndex].transfer(50 * mult);
                    MapByAddress_User[MapByIndex_Adderess[parentIndex]].totalEarnings += (50 * mult);
                }
                    
            }
            else
            {
                owner.transfer(joiningPrice.mulitply(15).divide(100));        
                
                _referrer.transfer(joiningPrice.mulitply(10).divide(100)); 
                MapByAddress_User[_referrer].totalEarnings += joiningPrice.mulitply(10).divide(100);
                
                if(nextUserIndex != 0) 
                {
                    MapByIndex_Adderess[parentIndex].transfer(50 * mult);
                    MapByAddress_User[MapByIndex_Adderess[parentIndex]].totalEarnings += (50 * mult);
                }
                
                uint[20] memory gggParents;
                uint gggparentCount = 0;
                uint level = 0;
                while (true)
                {
                    bool levelInc = false;
                    for (int i = 0; i < 3; i++)
                    {
                        if (parentIndex == 0)
                        {
                            break;
                        }
                        
                        parentIndex = getParentsIndex(parentIndex);
                        if (!isEven(parentIndex) && i == 2)
                        {
                            levelInc = true;
                            break;
                        }
                        
                        if (!isEven(parentIndex))
                        {
                            break;
                        }

                        if (parentIndex < 0)
                        {
                            break;
                        }
                        
                        if (parentIndex == 0 && i == 2)
                        {
                            levelInc = true;
                            break;
                        }
                        
                        if (i == 2)
                        {
                            levelInc = true;
                        }
                    }
                    
                    if (levelInc)
                    {
                        level++;
                        gggParents[gggparentCount] = parentIndex;
                        gggparentCount++;
                    }
                    
                    if (parentIndex == 0 || !isEven(parentIndex))
                    {
                       break;
                    }
                }
                
                for (uint index = 0; index < gggparentCount; index++)
                {
                    uint amount = LevelCompletionPayouts[index];
                    address levelPayoutAddress = MapByIndex_Adderess[gggParents[index]];
                        
                    if(index != 0)
                    {
                        if(MapByAddress_User[levelPayoutAddress].nextLevelReferralCount < uint(1 + i))
                        {
                            emit lostMoneyForEvent(levelPayoutAddress, index, amount, now);
                            MapByAddress_User[levelPayoutAddress].totalEarningsLost += amount;
                            levelPayoutAddress = owner;
                        }
                    }

                    emit levelBuyEvent(levelPayoutAddress, index, amount, now);

                    MapByAddress_User[MapByIndex_Adderess[gggParents[index]]].nextLevelReferralCount = 0;
                    MapByAddress_User[MapByIndex_Adderess[gggParents[index]]].nextLevel++;

                    levelPayoutAddress.transfer(amount);
                    MapByAddress_User[levelPayoutAddress].totalEarnings += amount;
                        
                    uint creatorCommission = (PircesForLevels[index]*8).mulitply(25).divide(100);
                    owner.transfer(creatorCommission);
                }
            }
        }
        else
        {
            parentIndex = getParentsIndex(nextUserIndex);
            owner.transfer(joiningPrice.mulitply(15).divide(100)); 
            
            _referrer.transfer(joiningPrice.mulitply(10).divide(100));
            MapByAddress_User[_referrer].totalEarnings += joiningPrice.mulitply(10).divide(100);
            
            if(nextUserIndex != 0) 
            {
                MapByIndex_Adderess[parentIndex].transfer(50 * mult);
                MapByAddress_User[MapByIndex_Adderess[parentIndex]].totalEarnings += (50 * mult);
            }
        }
        
        nextUserIndex++;
        emit registeredEvent(msg.sender, _referrer, now);
        return "User Registered";
        
    }
    
    function getReferrerIdByAddress(address referrerAddress) public view returns(uint)
    {
        return MapByAddress_User[referrerAddress].uid;
    }

    function isEven(uint number) private pure returns(bool)
    {
      uint remainder = number%2;
      if (remainder == 0)
        return true;
      else
        return false;
    }
    
    function getParentsIndex(uint myIndex) private pure returns(uint)
    {
        uint index = ((myIndex - 1) / 2);
        if(index < 0) 
            index = 0;
        return index;
    }
    
    function percent(uint inpput) private pure returns(uint)
    {
        return (inpput/100);
    }
    
    function uint2str(uint i) internal pure returns (string)
    {
        if (i == 0) return "0";
        uint j = i;
        uint length;
        while (j != 0)
        {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint k = length - 1;
        while (i != 0)
        {
            bstr[k--] = byte(48 + i % 10);
            i /= 10;
        }
        return string(bstr);
    }
    
    function sendPoishe(uint howmuch) public returns(string)
    { 
        require(msg.sender == owner, "Sorry, only for owner");
        require(address(this).balance >= howmuch, "Not Enough balance");
        owner.transfer(howmuch);
        emit sentTrxEvent(owner, howmuch, now);
        return "Poishe Dadle";
    }
}