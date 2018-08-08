pragma solidity ^0.4.14;
   
  // ----------------------------------------------------------------------------------------------
  // Sample fixed supply token contract
  // Enjoy. (c) BokkyPooBah 2017. The MIT Licence.
  // ----------------------------------------------------------------------------------------------
  
  //contract address: 0xb266026d8d7accb6c0201315c3f4efa9dc8baaf1
  //contract owner: 0x00AE0163Bcd00fB8d669f5aABCD0e93Dff180E3f
  //sol: [{"constant":true,"inputs":[],"name":"name","outputs":[{"name":"","type":"string"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_spender","type":"address"},{"name":"_amount","type":"uint256"}],"name":"approve","outputs":[{"name":"success","type":"bool"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"totalSupply","outputs":[{"name":"totalSupply","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"selling","outputs":[{"name":"","type":"bool"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_from","type":"address"},{"name":"_to","type":"address"},{"name":"_amount","type":"uint256"}],"name":"transferFrom","outputs":[{"name":"success","type":"bool"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"decimals","outputs":[{"name":"","type":"uint8"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_sale","type":"bool"}],"name":"changeSale","outputs":[],"payable":false,"type":"function"},{"constant":false,"inputs":[],"name":"sale","outputs":[],"payable":true,"type":"function"},{"constant":false,"inputs":[{"name":"newcloudworth","type":"uint256"}],"name":"changeCloudsPerEth","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"_owner","type":"address"}],"name":"balanceOf","outputs":[{"name":"balance","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"cloudsPerEth","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"owner","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"symbol","outputs":[{"name":"","type":"string"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_to","type":"address"},{"name":"_amount","type":"uint256"}],"name":"transfer","outputs":[{"name":"success","type":"bool"}],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"_owner","type":"address"},{"name":"_spender","type":"address"}],"name":"allowance","outputs":[{"name":"remaining","type":"uint256"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"newOwner","type":"address"}],"name":"transferOwnership","outputs":[],"payable":false,"type":"function"},{"inputs":[],"payable":false,"type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"name":"_from","type":"address"},{"indexed":true,"name":"_to","type":"address"},{"indexed":false,"name":"_value","type":"uint256"}],"name":"Transfer","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"_owner","type":"address"},{"indexed":true,"name":"_spender","type":"address"},{"indexed":false,"name":"_value","type":"uint256"}],"name":"Approval","type":"event"}]
//byte: 0x606060405266038d7ea4c68000600055620493e06001556002805460a060020a60ff0219169055341561003157600080fd5b5b60028054600160a060020a03191633600160a060020a03908116919091179182905560008054929091168152600360205260409020555b5b610981806100796000396000f300606060405236156100e35763ffffffff7c010000000000000000000000000000000000000000000000000000000060003504166306fdde0381146100e8578063095ea7b31461017357806318160ddd146101a957806323aed228146101ce57806323b872dd146101f5578063313ce5671461023157806342be93071461025a5780636ad1fe0214610274578063702c728e1461027e57806370a0823114610296578063883cd1a5146102c75780638da5cb5b146102ec57806395d89b411461031b578063a9059cbb146103a6578063dd62ed3e146103dc578063f2fde38b14610413575b600080fd5b34156100f357600080fd5b6100fb610434565b60405160208082528190810183818151815260200191508051906020019080838360005b838110156101385780820151818401525b60200161011f565b50505050905090810190601f1680156101655780820380516001836020036101000a031916815260200191505b509250505060405180910390f35b341561017e57600080fd5b610195600160a060020a036004351660243561046b565b604051901515815260200160405180910390f35b34156101b457600080fd5b6101bc6104d8565b60405190815260200160405180910390f35b34156101d957600080fd5b6101956104df565b604051901515815260200160405180910390f35b341561020057600080fd5b610195600160a060020a0360043581169060243516604435610500565b604051901515815260200160405180910390f35b341561023c57600080fd5b61024461061c565b60405160ff909116815260200160405180910390f35b341561026557600080fd5b6102726004351515610621565b005b61027261067a565b005b341561028957600080fd5b610272600435610757565b005b34156102a157600080fd5b6101bc600160a060020a036004351661077c565b60405190815260200160405180910390f35b34156102d257600080fd5b6101bc61079b565b60405190815260200160405180910390f35b34156102f757600080fd5b6102ff6107a1565b604051600160a060020a03909116815260200160405180910390f35b341561032657600080fd5b6100fb6107b0565b60405160208082528190810183818151815260200191508051906020019080838360005b838110156101385780820151818401525b60200161011f565b50505050905090810190601f1680156101655780820380516001836020036101000a031916815260200191505b509250505060405180910390f35b34156103b157600080fd5b610195600160a060020a03600435166024356107e7565b604051901515815260200160405180910390f35b34156103e757600080fd5b6101bc600160a060020a03600435811690602435166108b6565b60405190815260200160405180910390f35b341561041e57600080fd5b610272600160a060020a03600435166108e3565b005b60408051908101604052601181527f4150492048656176656e20636c6f756473000000000000000000000000000000602082015281565b600160a060020a03338116600081815260046020908152604080832094871680845294909152808220859055909291907f8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b9259085905190815260200160405180910390a35060015b92915050565b6000545b90565b60025474010000000000000000000000000000000000000000900460ff1681565b600160a060020a0383166000908152600360205260408120548290108015906105505750600160a060020a0380851660009081526004602090815260408083203390941683529290522054829010155b801561055c5750600082115b80156105815750600160a060020a038316600090815260036020526040902054828101115b1561061057600160a060020a0380851660008181526003602081815260408084208054899003905560048252808420338716855282528084208054899003905594881680845291905290839020805486019055917fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef9085905190815260200160405180910390a3506001610614565b5060005b5b9392505050565b600081565b60025433600160a060020a0390811691161461063c57600080fd5b6002805474ff0000000000000000000000000000000000000000191674010000000000000000000000000000000000000000831515021790555b5b50565b60025460009074010000000000000000000000000000000000000000900460ff1615156106a657600080fd5b60015466038d7ea4c68000345b600254600160a060020a0316600090815260036020526040902054919004919091029150819010156106e457600080fd5b600160a060020a03338116600081815260036020526040808220805486019055600280548516835291819020805486900390559054919291909116907fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef9084905190815260200160405180910390a35b50565b60025433600160a060020a0390811691161461077257600080fd5b60018190555b5b50565b600160a060020a0381166000908152600360205260409020545b919050565b60015481565b600254600160a060020a031681565b60408051908101604052600381527fe298810000000000000000000000000000000000000000000000000000000000602082015281565b600160a060020a0333166000908152600360205260408120548290108015906108105750600082115b80156108355750600160a060020a038316600090815260036020526040902054828101115b156108a757600160a060020a033381166000818152600360205260408082208054879003905592861680825290839020805486019055917fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef9085905190815260200160405180910390a35060016104d2565b5060006104d2565b5b92915050565b600160a060020a038083166000908152600460209081526040808320938516835292905220545b92915050565b60025433600160a060020a039081169116146108fe57600080fd5b60028054600160a060020a03908116600090815260036020526040808220548584168084528284209190915584549093168252812055815473ffffffffffffffffffffffffffffffffffffffff19161790555b5b505600a165627a7a72305820615f701bdd9ad5304f6de811ef48b9f48581e54c4792b8d629462caf33c82bab0029
  //ideen: variable f&#252;r (pre)sale, damit es in schritten gemacht werden kann
   
  // ERC Token Standard #20 Interface
  // https://github.com/ethereum/EIPs/issues/20
 contract ERC20Interface {
     // Get the total token supply
     function totalSupply() constant returns (uint256 totalSupply);
  
     // Get the account balance of another account with address _owner
     function balanceOf(address _owner) constant returns (uint256 balance);
  
     // Send _value amount of tokens to address _to
     function transfer(address _to, uint256 _value) returns (bool success);
  
     // Send _value amount of tokens from address _from to address _to
     function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
  
     // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
     // If this function is called again it overwrites the current allowance with _value.
     // this function is required for some DEX functionality
     function approve(address _spender, uint256 _value) returns (bool success);
  
     // Returns the amount which _spender is still allowed to withdraw from _owner
     function allowance(address _owner, address _spender) constant returns (uint256 remaining);
  
     // Triggered when tokens are transferred.
     event Transfer(address indexed _from, address indexed _to, uint256 _value);
  
     // Triggered whenever approve(address _spender, uint256 _value) is called.
     event Approval(address indexed _owner, address indexed _spender, uint256 _value);
 }
  
 contract APIHeaven is ERC20Interface {
     string public constant symbol = "☁";
     string public constant name = "API Heaven clouds";
     uint8 public constant decimals = 0;
     uint256 _totalSupply = 1000000000000000; //1 quadrillion
     //uint256 public constant mintPerTransaction = 1;
     uint256 public cloudsPerEth = 300000;
     
     // Owner of this contract
     address public owner;

     // Is the sale active?
     bool public selling = false;
  
     // Balances for each account
     mapping(address => uint256) balances;
  
     // Owner of account approves the transfer of an amount to another account
     mapping(address => mapping (address => uint256)) allowed;
  
     // Functions with this modifier can only be executed by the owner
     modifier onlyOwner() {
         if (msg.sender != owner) {
             revert();
         }
         _;
     }

    //in case the contract owner has to be moved
     function transferOwnership(address newOwner) onlyOwner {
        balances[newOwner] = balances[owner];
        balances[owner] = 0;
        owner = newOwner;
    }

    //change clouds per eth
     function changeCloudsPerEth(uint256 newcloudworth) onlyOwner {
        cloudsPerEth = newcloudworth;
    }

    //in case the contract owner has to be moved
    function changeSale(bool _sale) onlyOwner {
        selling = _sale;
    }
  
     // Constructor
     function APIHeaven() {
         owner = msg.sender;
         balances[owner] = _totalSupply;
     }
  
     function totalSupply() constant returns (uint256 totalSupply) {
         totalSupply = _totalSupply;
     }
  
     // What is the balance of a particular account?
     function balanceOf(address _owner) constant returns (uint256 balance) {
         return balances[_owner];
     }

    // Transfer the balance from owner&#39;s account to another account
    function transfer(address _to, uint256 _amount) returns (bool success) {
        //if(msg.data.length < (3 * 32) + 4) { throw; } //check for invalid length
        if (balances[msg.sender] >= _amount 
            && _amount > 0
            && balances[_to] + _amount > balances[_to]) {
            balances[msg.sender] -= _amount;
            balances[_to] += _amount;

            //after a successful transfer, generate new clouds
            //according to the mintPerTransaction variable
            //_totalSupply += mintPerTransaction;
            //balances[owner] += mintPerTransaction;

            Transfer(msg.sender, _to, _amount);
            
            return true;
        } else {
            return false;
        }
    }

    // for the presale the buyer gets 1 cloud for every 10 finney they SEND
    // 1eur = 1000 clouds
    // 1eth = 300000
    function sale() payable {
        if(selling == false) revert();     //only presale when selling flag is set to true
        uint256 amount = (msg.value / 1000000000000000) * cloudsPerEth;                 // calculates the amount
        if (balances[owner] < amount) revert();               // checks if it has enough to sell
        balances[msg.sender] += amount;                   // adds the amount to buyer&#39;s balance
        balances[owner] -= amount;                         // subtracts amount from seller&#39;s balance
        Transfer(owner, msg.sender, amount);                // execute an event reflecting the change
    }
  
     // Send _value amount of tokens from address _from to address _to
     // The transferFrom method is used for a withdraw workflow, allowing contracts to send
     // tokens on your behalf, for example to "deposit" to a contract address and/or to charge
     // fees in sub-currencies; the command should fail unless the _from account has
     // deliberately authorized the sender of the message via some mechanism; we propose
     // these standardized APIs for approval:
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
            Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }
 
    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    function approve(address _spender, uint256 _amount) returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }
 
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}