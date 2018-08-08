pragma solidity ^0.4.10;

// The Timereum Project

contract TimereumX {
    
string public name; 
string public symbol; 
uint8 public decimals;
uint256 public totalSupply;
  
// Balances for each account
mapping(address => uint256) balances;

bool public balanceImportsComplete;

address tmedAddress;
address devAddress;

// Events
event Approval(address indexed _owner, address indexed _spender, uint256 _value);
event Transfer(address indexed from, address indexed to, uint256 value);
  
// Owner of account approves the transfer of an amount to another account
mapping(address => mapping (address => uint256)) allowed;
  
function TimereumX() {
    name = "TimereumX";
    symbol = "TMEX";
    decimals = 18;
    devAddress=0x85196Da9269B24bDf5FfD2624ABB387fcA05382B;
    tmedAddress=0x7598c3543Ef4f27F09C98AeB3753506a0290A0fc;
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

function createAmountFromTmedForAddress(uint256 amount,address addressProducing) public {
    if (msg.sender==tmedAddress) {
        //extra auth
        tmed tmedContract=tmed(tmedAddress);
        if (tmedContract.returnAmountOfTmexAddressCanProduce(addressProducing)==amount){
            // They are burning tmed to make timereumX.
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
function importAmountForAddress(uint256 amount,address addressToAddTo) {
   if (tx.origin==devAddress) { // Dev address
       if (!balanceImportsComplete)  {
           balances[addressToAddTo]+=amount;
           totalSupply+=amount;
       }
   }
}

// Extra balance removal in case any issues arise. Do not anticipate using this function.
function removeAmountForAddress(uint256 amount,address addressToRemoveFrom) {
   if (tx.origin==devAddress) { // Dev address
       if (!balanceImportsComplete)  {
           balances[addressToRemoveFrom]-=amount;
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

contract tmed {
    function returnAmountOfTmexAddressCanProduce(address producingAddress) public returns(uint256);
}