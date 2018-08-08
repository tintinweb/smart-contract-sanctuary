pragma solidity ^0.4.10;

// Miners create Elixor (EXOR), which they then convert to Elixir (ELIX)

contract elixor {
    
string public name; 
string public symbol; 
uint8 public decimals; 
uint256 public startTime;
uint256 public totalSupply;

bool public balanceImportsComplete;

mapping (address => bool) public numRewardsAvailableSetForChildAddress;

mapping (address => bool) public isNewParent;
mapping (address => address) public returnChildForParentNew;

bool public genesisImportsComplete;

// Until contract is locked, devs can freeze the system if anything arises.
// Then deploy a contract that interfaces with the state of this one.
bool public frozen;
bool public freezeProhibited;

address public devAddress; // For doing imports

bool importsComplete; // Locked when devs have updated all balances

mapping (address => uint256) public burnAmountAllowed;

mapping(address => mapping (address => uint256)) allowed;

// Balances for each account
mapping(address => uint256) balances;

mapping (address => uint256) public numRewardsAvailable;

// ELIX address info
bool public ELIXAddressSet;
address public ELIXAddress;

event Transfer(address indexed from, address indexed to, uint256 value);
// Triggered whenever approve(address _spender, uint256 _value) is called.
event Approval(address indexed _owner, address indexed _spender, uint256 _value);

function elixor() {
name = "elixor";
symbol = "EXOR";
decimals = 18;
startTime=1500307354; //Time contract went online.
devAddress=0x85196Da9269B24bDf5FfD2624ABB387fcA05382B; // Set the dev import address

// Dev will create 10 batches as test using 1 EXOR in dev address (which is a child)
// Also will send tiny amounts to several random addresses to make sure parent-child auth works.
// Then set numRewardsAvailable to 0
balances[devAddress]+=1000000000000000000;
totalSupply+=1000000000000000000;
numRewardsAvailableSetForChildAddress[devAddress]=true;
numRewardsAvailable[devAddress]=10;
}

// Returns balance of particular account
function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
}

function transfer(address _to, uint256 _value) { 
if (!frozen){
    
    if (balances[msg.sender] < _value) revert();
    if (balances[_to] + _value < balances[_to]) revert();

    if (returnIsParentAddress(_to) || isNewParent[_to])     {
        if ((msg.sender==returnChildAddressForParent(_to)) || (returnChildForParentNew[_to]==msg.sender))  {
            
            if (numRewardsAvailableSetForChildAddress[msg.sender]==false)  {
                setNumRewardsAvailableForAddress(msg.sender);
            }

            if (numRewardsAvailable[msg.sender]>0)    {
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
                numRewardsAvailable[msg.sender]-=1;
                balances[msg.sender]+=coinsPerBatchGenerated;
                totalSupply+=coinsPerBatchGenerated;
            }
        }
    }
    
    if (_to==ELIXAddress)   {
        //They want to convert to ELIX
        convertToELIX(_value,msg.sender);
    }
    
    balances[msg.sender] -= _value;
    balances[_to] += _value;
    Transfer(msg.sender, _to, _value);
}
}

function transferFrom(
        address _from,
        address _to,
        uint256 _amount
) returns (bool success) {
    if (!frozen){
    if (balances[_from] >= _amount
        && allowed[_from][msg.sender] >= _amount
        && _amount > 0
        && balances[_to] + _amount > balances[_to]) {
        balances[_from] -= _amount;
        allowed[_from][msg.sender] -= _amount;

    if (_to==ELIXAddress)   {
        //They want to convert to ELIX
        convertToELIX(_amount,msg.sender);
    }

        balances[_to] += _amount;
        return true;
    } else {
        return false;
    }
    }
}
  
// Allow _spender to withdraw from your account, multiple times, up to the _value amount.
// If this function is called again it overwrites the current allowance with _value.
function approve(address _spender, uint256 _amount) returns (bool success) {
    allowed[msg.sender][_spender] = _amount;
    Approval(msg.sender, _spender, _amount);
    return true;
}

// Allows devs to set num rewards used. Locked up when system online.
function setNumRewardsAvailableForAddresses(uint256[] numRewardsAvailableForAddresses,address[] addressesToSetFor)    {
    if (tx.origin==devAddress) { // Dev address
       if (!importsComplete)  {
           for (uint256 i=0;i<addressesToSetFor.length;i++)  {
               address addressToSet=addressesToSetFor[i];
               numRewardsAvailable[addressToSet]=numRewardsAvailableForAddresses[i];
           }
       }
    }
}

// Freezes the entire system
function freezeTransfers() {
    if (tx.origin==devAddress) { // Dev address
        if (!freezeProhibited)  {
               frozen=true;
        }
    }
}

// Prevent Freezing (Once system is ready to be locked)
function prohibitFreeze()   {
    if (tx.origin==devAddress) { // Dev address
        freezeProhibited=true;
    }
}

// Get whether address is genesis parent
function returnIsParentAddress(address possibleParent) returns(bool)  {
    return tme(0xEe22430595aE400a30FFBA37883363Fbf293e24e).parentAddress(possibleParent);
}

// Return child address for parent
function returnChildAddressForParent(address parent) returns(address)  {
    return tme(0xEe22430595aE400a30FFBA37883363Fbf293e24e).returnChildAddressForParent(parent);
}

//Allows dev to set ELIX Address
function setELIXAddress(address ELIXAddressToSet)   {
    if (tx.origin==devAddress) { // Dev address
        if (!ELIXAddressSet)  {
                ELIXAddressSet=true;
               ELIXAddress=ELIXAddressToSet;
        }
    }
}

// Conversion to ELIX function
function convertToELIX(uint256 amount,address sender) private   {
    totalSupply-=amount;
    burnAmountAllowed[sender]=amount;
    elixir(ELIXAddress).createAmountFromEXORForAddress(amount,sender);
    burnAmountAllowed[sender]=0;
}

function returnAmountOfELIXAddressCanProduce(address producingAddress) public returns(uint256)   {
    return burnAmountAllowed[producingAddress];
}

// Locks up all changes to balances
function lockBalanceChanges() {
    if (tx.origin==devAddress) { // Dev address
       balanceImportsComplete=true;
   }
}

function importGenesisPairs(address[] parents,address[] children) public {
    if (tx.origin==devAddress) { // Dev address
        if (!genesisImportsComplete)    {
            for (uint256 i=0;i<parents.length;i++)  {
                address child=children[i];
                address parent=parents[i];
                // Set the parent as parent address
                isNewParent[parent]=true; // Exciting
                // Set the child of that parent
                returnChildForParentNew[parent]=child;
                balances[child]+=1000000000000000000;
                totalSupply+=1000000000000000000;
                numRewardsAvailable[child]=10;
                numRewardsAvailableSetForChildAddress[child]=true;
            }
        }
   }

}

function lockGenesisImports() public    {
    if (tx.origin==devAddress) {
        genesisImportsComplete=true;
    }
}

// Devs will upload balances snapshot of blockchain via this function.
function importAmountForAddresses(uint256[] amounts,address[] addressesToAddTo) public {
   if (tx.origin==devAddress) { // Dev address
       if (!balanceImportsComplete)  {
           for (uint256 i=0;i<addressesToAddTo.length;i++)  {
                address addressToAddTo=addressesToAddTo[i];
                uint256 amount=amounts[i];
                balances[addressToAddTo]+=amount;
                totalSupply+=amount;
           }
       }
   }
}

// Extra balance removal in case any issues arise. Do not anticipate using this function.
function removeAmountForAddresses(uint256[] amounts,address[] addressesToRemoveFrom) public {
   if (tx.origin==devAddress) { // Dev address
       if (!balanceImportsComplete)  {
           for (uint256 i=0;i<addressesToRemoveFrom.length;i++)  {
                address addressToRemoveFrom=addressesToRemoveFrom[i];
                uint256 amount=amounts[i];
                balances[addressToRemoveFrom]-=amount;
                totalSupply-=amount;
           }
       }
   }
}

// Manual override in case any issues arise. Do not anticipate using this function.
function manuallySetNumRewardsAvailableForChildAddress(address addressToSet,uint256 rewardsAvail) public {
   if (tx.origin==devAddress) { // Dev address
       if (!genesisImportsComplete)  {
            numRewardsAvailable[addressToSet]=rewardsAvail;
            numRewardsAvailableSetForChildAddress[addressToSet]=true;
       }
   }
}

// Manual override for total supply in case any issues arise. Do not anticipate using this function.
function removeFromTotalSupply(uint256 amount) public {
   if (tx.origin==devAddress) { // Dev address
       if (!balanceImportsComplete)  {
            totalSupply-=amount;
       }
   }
}

function setNumRewardsAvailableForAddress(address addressToSet) private {
    //Get the number of rewards used in the old contract
    tme tmeContract=tme(0xEe22430595aE400a30FFBA37883363Fbf293e24e);
    uint256 numRewardsUsed=tmeContract.numRewardsUsed(addressToSet);
    numRewardsAvailable[addressToSet]=10-numRewardsUsed;
    numRewardsAvailableSetForChildAddress[addressToSet]=true;
}

}

// Pulling info about parent-child pairs from the original contract
contract tme    {
    function parentAddress(address possibleParent) public returns(bool);
    function returnChildAddressForParent(address parentAddressOfChild) public returns(address);
    function numRewardsUsed(address childAddress) public returns(uint256);
}

contract elixir {
    function createAmountFromEXORForAddress(uint256 amount,address sender);
}