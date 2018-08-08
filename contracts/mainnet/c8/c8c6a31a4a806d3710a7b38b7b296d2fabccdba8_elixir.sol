pragma solidity ^0.4.10;

// Elixir (ELIX)

contract elixir {
    
string public name; 
string public symbol; 
uint8 public decimals;
uint256 public totalSupply;
  
// Balances for each account
mapping(address => uint256) balances;

bool public balanceImportsComplete;

address exorAddress;
address devAddress;

// Events
event Approval(address indexed _owner, address indexed _spender, uint256 _value);
event Transfer(address indexed from, address indexed to, uint256 value);
  
// Owner of account approves the transfer of an amount to another account
mapping(address => mapping (address => uint256)) allowed;
  
function elixir() {
    name = "elixir";
    symbol = "ELIX";
    decimals = 18;
    devAddress=0x85196Da9269B24bDf5FfD2624ABB387fcA05382B;
    exorAddress=0x898bF39cd67658bd63577fB00A2A3571dAecbC53;
}

function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
}

// Transfer the balance from owner&#39;s account to another account
function transfer(address _to, uint256 _amount) returns (bool success) {
    if (balances[msg.sender] >= _amount 
        && _amount > 0
        && balances[_to] + _amount > balances[_to]) {
        balances[msg.sender] -= _amount;
        balances[_to] += _amount;
        Transfer(msg.sender, _to, _amount); 
        return true;
    } else {
        return false;
    }
}

function createAmountFromEXORForAddress(uint256 amount,address addressProducing) public {
    if (msg.sender==exorAddress) {
        //extra auth
        elixor EXORContract=elixor(exorAddress);
        if (EXORContract.returnAmountOfELIXAddressCanProduce(addressProducing)==amount){
            // They are burning EXOR to make ELIX
            balances[addressProducing]+=amount;
            totalSupply+=amount;
        }
    }
}

function transferFrom(
    address _from,
    address _to,
    uint256 _amount
) returns (bool success) {
    if (balances[_from] >= _amount
        && allowed[_from][msg.sender] >= _amount
        && _amount > 0
        && balances[_to] + _amount > balances[_to]) {
        balances[_from] -= _amount;
        allowed[_from][msg.sender] -= _amount;
        balances[_to] += _amount;
        return true;
    } else {
        return false;
    }
}

// Locks up all changes to balances
function lockBalanceChanges() {
    if (tx.origin==devAddress) { // Dev address
       balanceImportsComplete=true;
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

// Manual override for total supply in case any issues arise. Do not anticipate using this function.
function removeFromTotalSupply(uint256 amount) public {
   if (tx.origin==devAddress) { // Dev address
       if (!balanceImportsComplete)  {
            totalSupply-=amount;
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
}

contract elixor {
    function returnAmountOfELIXAddressCanProduce(address producingAddress) public returns(uint256);
}