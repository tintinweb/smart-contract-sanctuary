pragma solidity ^0.4.10;

contract timereum {

string public name; 
string public symbol; 
uint8 public decimals; 
uint256 public maxRewardUnitsAvailable;
uint256 public startTime;
uint256 public initialSupplyPerChildAddress;
uint256 public numImports;
uint256 public maxImports;

mapping (address => uint256) public balanceOf;
mapping (address => bool) public parentAddress;
mapping (address => address) public returnChildAddressForParent;
mapping (address => uint256) public numRewardsUsed;

event Transfer(address indexed from, address indexed to, uint256 value);
event addressesImported(address importedFrom,uint256 numPairsImported,uint256 numImported); 

function timereum() {
name = "timereum";
symbol = "TME";
decimals = 18;
initialSupplyPerChildAddress = 1000000000000000000;
maxRewardUnitsAvailable=10; //10 batches
startTime=1500307354; //Time contract went online.
maxImports=107; //5 extra imports in case issues arise. All imports recorded and remaining maxImports used at end to prevent injection.
}

function transfer(address _to, uint256 _value) { 
if (balanceOf[msg.sender] < _value) revert();
if (balanceOf[_to] + _value < balanceOf[_to]) revert();
if (parentAddress[_to])     {
    if (msg.sender==returnChildAddressForParent[_to])  {
        if (numRewardsUsed[msg.sender]<maxRewardUnitsAvailable)    {
            uint256 currDate=block.timestamp;
            uint256 returnMaxPerBatchGenerated=5000000000000000000000; //max 5000 coins per batch
            uint256 deployTime=10*365*86400; //10 years
            uint256 secondsSinceStartTime=currDate-startTime;
            uint256 maximizationTime=deployTime+startTime;
            uint256 coinsPerBatchGenerated;
            if (currDate>=maximizationTime)  {
                coinsPerBatchGenerated=returnMaxPerBatchGenerated;
            } else  {
                uint256 b=(returnMaxPerBatchGenerated/4);
                uint256 m=(returnMaxPerBatchGenerated-b)/deployTime;
                coinsPerBatchGenerated=secondsSinceStartTime*m+b;
            }
            numRewardsUsed[msg.sender]+=1;
            balanceOf[msg.sender]+=coinsPerBatchGenerated;
        }
    }
}
balanceOf[msg.sender] -= _value;
balanceOf[_to] += _value;
Transfer(msg.sender, _to, _value); 
}

//Storage of addresses is broken into smaller contracts.
function importAddresses(address[] parentsArray,address[] childrenArray)	{
	if (numImports<maxImports)	{
		numImports++;
		addressesImported(msg.sender,childrenArray.length,numImports); //Details of import
		balanceOf[0x000000000000000000000000000000000000dEaD]=numImports*initialSupplyPerChildAddress; //Easy way for people to check numImports without debugger after launch.
		for (uint i=0;i<childrenArray.length;i++)   {
				address child=childrenArray[i];
				address parent=parentsArray[i];
				parentAddress[parent]=true;
				returnChildAddressForParent[parent]=child;
				balanceOf[child]=initialSupplyPerChildAddress;
		}
	}
}
}