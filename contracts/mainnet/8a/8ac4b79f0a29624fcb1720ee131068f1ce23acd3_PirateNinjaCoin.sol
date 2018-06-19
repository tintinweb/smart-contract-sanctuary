pragma solidity ^0.4.11;
contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }

contract PirateNinjaCoin {
    /* Public variables of the token */
    string public standard = &#39;Token 0.1&#39;;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    
    address profit;
    uint256 public buyPrice;
    uint256 public sellPrice;
    uint256 flame;
    uint256 maxBuyPrice;

    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /* This notifies clients about the amount burnt */
    event Burn(address indexed from, uint256 value);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function PirateNinjaCoin(
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol,
        uint256 initPrice,
        uint256 finalPrice
        ) {
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
        decimals = decimalUnits;                            // Amount of decimals for display purposes
        
        buyPrice = initPrice;
        profit = msg.sender;
        maxBuyPrice = finalPrice;
        
        flame = 60000;                                      //set the initial flame to 50%
    }

    /* Send coins */
    function transfer(address _to, uint256 _value) {
        if (_to == 0x0) throw;                               // Prevent transfer to 0x0 address. Use burn() instead
        if (balanceOf[msg.sender] < _value) throw;           // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) throw; // Check for overflows
        balanceOf[msg.sender] -= _value;                     // Subtract from the sender
        balanceOf[_to] += _value;                            // Add the same to the recipient
        Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
    }

    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value)
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /* Approve and then communicate the approved contract in a single tx */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }        

    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (_to == 0x0) throw;                                // Prevent transfer to 0x0 address. Use burn() instead
        if (balanceOf[_from] < _value) throw;                 // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;  // Check for overflows
        if (_value > allowance[_from][msg.sender]) throw;     // Check allowance
        balanceOf[_from] -= _value;                           // Subtract from the sender
        balanceOf[_to] += _value;                             // Add the same to the recipient
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

    function burn(uint256 _value) returns (bool success) {
        if (balanceOf[msg.sender] < _value) throw;            // Check if the sender has enough
        balanceOf[msg.sender] -= _value;                      // Subtract from the sender
        totalSupply -= _value;                                // Updates totalSupply
        profit.transfer(((_value * (110000 - flame) / 100000) ) * sellPrice);
        setSellPrice();
        Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) returns (bool success) {
        if (balanceOf[_from] < _value) throw;                // Check if the sender has enough
        if (_value > allowance[_from][msg.sender]) throw;    // Check allowance
        balanceOf[_from] -= _value;                          // Subtract from the sender
        totalSupply -= _value;                               // Updates totalSupply
        profit.transfer((_value * (110000 - flame) / 100000) * sellPrice); 
        setSellPrice();
        Burn(_from, _value);
        return true;
    }

    /* start of pirateNinjaCoin specific function */
    event NewSellPrice(uint256 value);
    event NewBuyPrice(uint256 value);
    
    function setSellPrice(){
        if(totalSupply > 0){
            sellPrice = this.balance / totalSupply;
            if(buyPrice == maxBuyPrice && sellPrice > buyPrice) sellPrice = buyPrice;
            if(sellPrice > buyPrice) sellPrice = buyPrice * 99984 / 100000;
            NewSellPrice(sellPrice);
        }
    }
    
    modifier onlyOwner {
        require(msg.sender == profit);
        _;
    }
    
    function adjustFlame(uint256 _flame) onlyOwner{
        flame = _flame;
    }

    function buy() payable {
        uint256 fee = (msg.value * 42 / 100000);
        if(msg.value < (buyPrice + fee)) throw; //check if enough ether was send
        uint256 amount = (msg.value - fee) / buyPrice;
        
        if (totalSupply + amount < totalSupply) throw; //check for overflows
        if (balanceOf[msg.sender] + amount < balanceOf[msg.sender]) throw; //check for overflows
        balanceOf[msg.sender] += amount;
        
        profit.transfer(fee);
        msg.sender.transfer(msg.value - fee - (amount * buyPrice)); //send back ethers left
        
        totalSupply += amount; 
        
        if(buyPrice < maxBuyPrice){
            buyPrice = buyPrice * 100015 / 100000;
            if(buyPrice > maxBuyPrice) buyPrice = maxBuyPrice;
            NewBuyPrice(buyPrice);
        }
        
        setSellPrice();
    }

    function sell(uint256 _amount) {
        if (balanceOf[msg.sender] < _amount) throw;    
       
        uint256 ethAmount = sellPrice * _amount;
        uint256 fee = (ethAmount * 42 / 100000);
        profit.transfer(fee);
        msg.sender.transfer(ethAmount - fee);
        balanceOf[msg.sender] -= _amount;
        totalSupply -= _amount; 
    }

}