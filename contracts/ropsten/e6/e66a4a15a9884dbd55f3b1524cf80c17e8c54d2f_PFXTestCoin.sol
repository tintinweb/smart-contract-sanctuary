pragma solidity ^0.4.4;


//通过log函数重载，对不同类型的变量trigger不同的event，实现solidity打印效果，使用方法为：log(string name, var value)
contract Console {
    event LogUint(string, uint);
    function log(string s , uint x) internal {
      emit LogUint(s, x);
    }
    
    event LogInt(string, int);
    function log(string s , int x) internal {
      emit LogInt(s, x);
    }
    
    event LogBytes(string, bytes);
    function log(string s , bytes x) internal {
      emit LogBytes(s, x);
    }
    
    event LogBytes32(string, bytes32);
    function log(string s , bytes32 x) internal {
      emit LogBytes32(s, x);
    }

    event LogAddress(string, address);
    function log(string s , address x) internal {
      emit LogAddress(s, x);
    }

    event LogBool(string, bool);
    function log(string s , bool x) internal {
      emit LogBool(s, x);
    }
}

contract Token is Console {

    /// @return total amount of tokens 
    /// 返回值：发行代币总数量
    function totalSupply() constant returns (uint256 supply) {}

    /// @param _owner The address from which the balance will be retrieved 
    /// 参数 _owner 钱包地址 _owner
    /// @return The balance 
    /// 返回值：代币数量
    function balanceOf(address _owner) constant returns (uint256 balance) {}

    /// @notice send `_value` token to `_to` from `msg.sender` 
    /// 说明：从调用者 &#39;msg.sender&#39; 发送 &#39;_value&#39; 数量的代币给 &#39;_to&#39;
    /// @param _to The address of the recipient 
    /// 参数 _to 代币接收者的地址
    /// @param _value The amount of token to be transferred 发送代币数量
    /// 参数 _value 发送代币数量
    /// @return Whether the transfer was successful or not 
    /// 返回值：转账是否成功
    function transfer(address _to, uint256 _value) returns (bool success) {}

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from` 
    /// 说明：地址 &#39;_from&#39; 转账 &#39;_value&#39; 数量的代币给 地址 &#39;_to&#39;
    /// @param _from The address of the sender
    /// 参数 _from 交易发起者的地址
    /// @param _to The address of the recipient
    /// 参数 _to 代币接收者的地址
    /// @param _value The amount of token to be transferred
    /// 参数 _value 发送代币数量
    /// @return Whether the transfer was successful or not
    /// 返回值：转账是否成功
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// 说明：地址 `msg.sender` 批准 &#39;_addr&#39; 花费`_value`数量的代币
    /// @param _spender The address of the account able to transfer the tokens
    /// 参数 _value 发送代币数量
    /// @param _value The amount of wei to be approved for transfer
    /// 参数 _value 发送代币数量
    /// @return Whether the approval was successful or not
    /// 返回值：转账是否成功
    function approve(address _spender, uint256 _value) returns (bool success) {}

    /// @param _owner The address of the account owning tokens
    /// 参数 _owner 代币拥有者地址
    /// @param _spender The address of the account able to transfer the tokens
    /// 参数 _spender 能够转移代币的帐户的地址
    /// @return Amount of remaining tokens allowed to spent
    /// 返回值：允许使用的剩余代币数量
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

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

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        //same as above. Replace this line with the following if you want to protect against wrapping uints.
        //if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        log("_owner:",_owner);
        log("balances:",balances[_owner]);
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
}

contract PFXTestCoin is StandardToken { // CHANGE THIS. Update the contract name.

    /* Public variables of the token */

    /*
    NOTE:
    The following variables are OPTIONAL vanities. One does not have to include them.
    They allow one to customise the token contract & in no way influences the core functionality.
    Some wallets/interfaces might not even bother to look at this information.
    */
    string public name;                   // Token Name
    uint8 public decimals;                // How many decimals to show. To be standard complicant keep it 18
    string public symbol;                 // An identifier: eg SBX, XPR etc..
    string public version = "v1.0.0"; 
    uint256 public unitsOneEthCanBuy;     // How many units of your coin can be bought by 1 ETH?
    uint256 public totalEthInWei;         // WEI is the smallest unit of ETH (the equivalent of cent in USD or satoshi in BTC). We&#39;ll store the total ETH raised via our ICO here.  
    address public fundsWallet;           // Where should the raised ETH go?

    // This is a constructor function 
    // which means the following function name has to match the contract name declared above
    function PFXTestCoin() {
        balances[msg.sender] = 1000000 * (10 ** 18);// 1000000000000000000000;               // Give the creator all initial tokens. This is set to 1000 for example. If you want your initial tokens to be X and your decimal is 5, set this value to X * 100000. (CHANGE THIS)
        totalSupply = 1000000 * (10 ** 18);                          // Update total supply (1000 for example) (CHANGE THIS)
        name = "PFXCoin";                                            // Set the name for display purposes (CHANGE THIS)
        decimals = 18;                                               // Amount of decimals for display purposes (CHANGE THIS)
        symbol = "PFX";                                              // Set the symbol for display purposes (CHANGE THIS)
        unitsOneEthCanBuy = 10;                                      // Set the price of your token for the ICO (CHANGE THIS)
        fundsWallet = msg.sender;                                    // The owner of the contract gets ETH
    }

    function() payable {
        totalEthInWei = totalEthInWei + msg.value;
        uint256 amount = msg.value * unitsOneEthCanBuy;
        require(balances[fundsWallet] >= amount);

        balances[fundsWallet] = balances[fundsWallet] - amount;
        balances[msg.sender] = balances[msg.sender] + amount;

        Transfer(fundsWallet, msg.sender, amount); // Broadcast a message to the blockchain

        //Transfer ether to fundsWallet
        fundsWallet.transfer(msg.value);                               
    }

    /* Approves and then calls the receiving contract */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        //call the receiveApproval function on the contract you want to be notified. This crafts the function signature manually so one doesn&#39;t have to include a contract in here just for this.
        //receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
        //it is assumed that when does this that the call *should* succeed, otherwise one would use vanilla approve instead.
        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }
}