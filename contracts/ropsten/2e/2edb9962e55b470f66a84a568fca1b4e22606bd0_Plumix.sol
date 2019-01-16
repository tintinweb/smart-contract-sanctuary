pragma solidity ^0.4.24;

contract Token {

    /// @return total amount of tokens
    function totalSupply() constant returns (uint256 supply) {}
    

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant returns (uint256 balance) {}

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) returns (bool success) {}



    event Transfer(address indexed _from, address indexed _to, uint256 _value);

}

contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
        //Default assumes totalSupply can&#39;t be over max (2^256 - 1).
        //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn&#39;t wrap.
        //Replace the if with this one instead.
        //if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }


    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }


    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
}

contract Plumix is StandardToken { 

    /* Public variables of the token */

   
    string public name;                   
    uint8 public decimals;                
    string public symbol;                 
    uint256 public unitsOneEthCanBuy;     // How many units of your coin can be bought by 1 ETH?
    uint256 public minSales;                 // Minimum amount to be bought (0.01ETH)
    uint256 public totalEthInWei;         
    address internal fundsWallet;           
    uint256 public airDropBal;
    uint256 public icoSales;
    uint256 public icoSalesBal;
    uint256 public icoSalesCount;
    bool public distributionClosed;

    
    modifier canDistr() {
        require(!distributionClosed);
        _;
    }
    
    address owner = msg.sender;
    
     modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    
    event Airdrop(address indexed _owner, uint _amount, uint _balance);
    event DistrClosed();
    event DistrStarted();
    event Burn(address indexed burner, uint256 value);
    
    
    function endDistribution() onlyOwner canDistr public returns (bool) {
        distributionClosed = true;
        emit DistrClosed();
        return true;
    }
    
    function startDistribution() onlyOwner public returns (bool) {
        distributionClosed = false;
        emit DistrStarted();
        return true;
    }
    

    function Plumix() {
        balances[msg.sender] = 10000000000e18;               
        totalSupply = 10000000000e18;                        
        airDropBal = 1500000000e18;
        icoSales = 5000000000e18;
        icoSalesBal = 5000000000e18;
        name = "Plumix";                                   
        decimals = 18;                                               
        symbol = "PLXT";                                             
        unitsOneEthCanBuy = 10000000;
        minSales = 1 ether / 100; // 0.01ETH
        icoSalesCount = 0;
        fundsWallet = msg.sender;                                   
        distributionClosed = true;
        
    }

    function() public canDistr payable{
        totalEthInWei = totalEthInWei + msg.value;
        uint256 amount = msg.value * unitsOneEthCanBuy;
        require(msg.value >= minSales);
        require(amount <= icoSalesBal);
        

        balances[fundsWallet] = balances[fundsWallet] - amount;
        balances[msg.sender] = balances[msg.sender] + amount;

        Transfer(fundsWallet, msg.sender, amount); // Broadcast a message to the blockchain

        
        fundsWallet.transfer(msg.value);
        
        icoSalesCount = icoSalesCount + amount;
        icoSalesBal = icoSalesBal - amount;
        if (icoSalesCount >= icoSales) {
            distributionClosed = true;
        }
    }
    
    
 function doAirdrop(address _participant, uint _amount) internal {

        require( _amount > 0 );      

        require( _amount <= airDropBal );
        
        balances[_participant] = balances[_participant] + _amount;
        airDropBal = airDropBal - _amount ;
     
     // Airdrop log
    emit Airdrop(_participant, _amount, balances[_participant]);  
     }
     
     
         function adminClaimAirdrop(address _participant, uint _amount) public onlyOwner {        
        doAirdrop(_participant, _amount);
    }

    function adminClaimAirdropMultiple(address[] _addresses, uint _amount) public onlyOwner {        
        for (uint i = 0; i < _addresses.length; i++) doAirdrop(_addresses[i], _amount);
    }
     
    
    function burn(uint256 _value) onlyOwner public {
        require(_value <= balances[msg.sender]);


        address burner = msg.sender;
        balances[burner] = balances[burner] - _value;
        totalSupply = totalSupply - _value;
        emit Burn(burner, _value);
    }

}