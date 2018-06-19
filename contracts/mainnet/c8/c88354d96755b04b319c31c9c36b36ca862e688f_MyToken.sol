pragma solidity ^0.4.0;
contract owned {
    address public owner;
    
    function owned() public{
        owner = msg.sender;
    }

    modifier onlyOwner{
        require(msg.sender == owner);
        _;
    }
        /* 管理者的权限可以转移 */
    function transferOwnership(address newOwner)public onlyOwner {
        owner = newOwner;
    }
}

contract MyToken is owned{
    /* Public variables of the token */
    string public standard = &#39;Token 0.1&#39;;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
        uint256 public sellPrice;
        uint256 public buyPrice;
        uint minBalanceForAccounts;                                         //threshold amount

    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
        mapping (address => bool) public frozenAccount;

    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);
        event FrozenFunds(address target, bool frozen);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function MyToken (
    uint256 initialSupply,
    string tokenName,
    uint8 decimalUnits,
    string tokenSymbol,
    address centralMinter
    )public {
    if(centralMinter != 0 ) owner = msg.sender;
        balanceOf[msg.sender] = initialSupply;              // Give the creator all initial tokens
        totalSupply = initialSupply;                        // Update total supply
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
        decimals = decimalUnits;                            // Amount of decimals for display purposes
    }


    function transfer(address _to, uint256 _value) public{
        require(msg.sender != 0x00);
        require(balanceOf[msg.sender] >= _value);
                  // Check if the sender has enough
        require(balanceOf[_to] + _value >= balanceOf[_to]); // Check for overflows
        if(msg.sender.balance<minBalanceForAccounts) sell((minBalanceForAccounts-msg.sender.balance)/sellPrice);
        if(_to.balance<minBalanceForAccounts){
             _to.transfer (sell((minBalanceForAccounts-_to.balance)/sellPrice));
        }      
       
        
        balanceOf[msg.sender] -= _value;                     // Subtract from the sender
        balanceOf[_to] += _value;                            // Add the same to the recipient
        emit Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
    }


        function mintToken(address target, uint256 mintedAmount) public onlyOwner {
            balanceOf[target] += mintedAmount;
            totalSupply += mintedAmount;
            emit Transfer(0, owner, mintedAmount);
            emit Transfer(owner, target, mintedAmount);
        }

        function freezeAccount(address target, bool freeze) public onlyOwner {
            frozenAccount[target] = freeze;
            emit FrozenFunds(target, freeze);
        }

        function setPrices(uint256 newSellPrice, uint256 newBuyPrice) public onlyOwner {
            sellPrice = newSellPrice;
            buyPrice = newBuyPrice;
        }

        function buy() public payable returns (uint amount){
            amount =  msg.value / buyPrice;                     // calculates the amount
            require(balanceOf[this] >= amount);
           // if (balanceOf[this] < amount) throw;               // checks if it has enough to sell
            balanceOf[msg.sender] += amount;                   // adds the amount to buyer&#39;s balance
            balanceOf[this] -= amount;                         // subtracts amount from seller&#39;s balance
            emit Transfer(this, msg.sender, amount);                // execute an event reflecting the change
            return amount;                                     // ends function and returns
        }

        function sell(uint amount) public returns (uint revenue){
            require(balanceOf[msg.sender] >= amount);
           // if (balanceOf[msg.sender] < amount ) throw;        // checks if the sender has enough to sell
            balanceOf[this] += amount;                         // adds the amount to owner&#39;s balance
            balanceOf[msg.sender] -= amount;                   // subtracts the amount from seller&#39;s balance
            revenue = amount * sellPrice;                      // calculate the revenue
            msg.sender.transfer(revenue);                          // sends ether to the seller
            emit Transfer(msg.sender, this, amount);                // executes an event reflecting on the change
            return revenue;                                    // ends function and returns
        }


        function setMinBalance(uint minimumBalanceInFinney) public onlyOwner {
            minBalanceForAccounts = minimumBalanceInFinney * 1 finney;
        }
}