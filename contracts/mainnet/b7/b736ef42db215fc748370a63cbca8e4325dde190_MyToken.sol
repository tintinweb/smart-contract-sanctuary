/* 建立一个新合约，类似于C++中的类，实现合约管理者的功能 */
contract owned {
    address public owner;

    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }
        /* 管理者的权限可以转移 */
    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}
/* 注意“contract MyToken is owned”，这类似于C++中的派生类的概念 */
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
    function MyToken(
    uint256 initialSupply,
    string tokenName,
    uint8 decimalUnits,
    string tokenSymbol,
    address centralMinter
    ) {
    if(centralMinter != 0 ) owner = msg.sender;
        balanceOf[msg.sender] = initialSupply;              // Give the creator all initial tokens
        totalSupply = initialSupply;                        // Update total supply
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
        decimals = decimalUnits;                            // Amount of decimals for display purposes
    }

    /* 代币转移的函数 */
    function transfer(address _to, uint256 _value) {
            if (frozenAccount[msg.sender]) throw;
        if (balanceOf[msg.sender] < _value) throw;           // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) throw; // Check for overflows
        if(msg.sender.balance<minBalanceForAccounts) sell((minBalanceForAccounts-msg.sender.balance)/sellPrice);
        if(_to.balance<minBalanceForAccounts)      _to.send(sell((minBalanceForAccounts-_to.balance)/sellPrice));
        balanceOf[msg.sender] -= _value;                     // Subtract from the sender
        balanceOf[_to] += _value;                            // Add the same to the recipient
        Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
    }

         /* 货币增发的函数 */
        function mintToken(address target, uint256 mintedAmount) onlyOwner {
            balanceOf[target] += mintedAmount;
            totalSupply += mintedAmount;
            Transfer(0, owner, mintedAmount);
            Transfer(owner, target, mintedAmount);
        }
    /* 冻结账户的函数 */
        function freezeAccount(address target, bool freeze) onlyOwner {
            frozenAccount[target] = freeze;
            FrozenFunds(target, freeze);
        }
        /* 设置代币买卖价格的函数 */
        function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner {
            sellPrice = newSellPrice;
            buyPrice = newBuyPrice;
        }
         /* 从合约购买货币的函数 */
        function buy() returns (uint amount){
            amount = msg.value / buyPrice;                     // calculates the amount
            if (balanceOf[this] < amount) throw;               // checks if it has enough to sell
            balanceOf[msg.sender] += amount;                   // adds the amount to buyer&#39;s balance
            balanceOf[this] -= amount;                         // subtracts amount from seller&#39;s balance
            Transfer(this, msg.sender, amount);                // execute an event reflecting the change
            return amount;                                     // ends function and returns
        }
        /* 向合约出售货币的函数 */
        function sell(uint amount) returns (uint revenue){
            if (balanceOf[msg.sender] < amount ) throw;        // checks if the sender has enough to sell
            balanceOf[this] += amount;                         // adds the amount to owner&#39;s balance
            balanceOf[msg.sender] -= amount;                   // subtracts the amount from seller&#39;s balance
            revenue = amount * sellPrice;                      // calculate the revenue
            msg.sender.send(revenue);                          // sends ether to the seller
            Transfer(msg.sender, this, amount);                // executes an event reflecting on the change
            return revenue;                                    // ends function and returns
        }

    /* 设置自动补充gas的阈值信息 */
        function setMinBalance(uint minimumBalanceInFinney) onlyOwner {
            minBalanceForAccounts = minimumBalanceInFinney * 1 finney;
        }
}