pragma solidity ^0.4.4;

contract Token {
    function totalSupply() constant returns (uint256 supply) {}
    function balanceOf(address _owner) constant returns (uint256 balance) {}
    function transfer(address _to, uint256 _value) returns (bool success) {}
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}
    function approve(address _spender, uint256 _value) returns (bool success) {}
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardToken is Token {
    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] &gt;= _value &amp;&amp; _value &gt; 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] &gt;= _value &amp;&amp; allowed[_from][msg.sender] &gt;= _value &amp;&amp; _value &gt; 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }
    function balanceOf(address _owner) constant returns (uint256 balance) {
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
    mapping (address =&gt; uint256) balances;
    mapping (address =&gt; mapping (address =&gt; uint256)) allowed;
    uint256 public totalSupply;
}


contract Fouracoin is StandardToken {
    //Verify tokenname is ERC20Token
    //http://remix.ethereum.org/#optimize=false&amp;version=soljson-v0.4.13+commit.fb4cb1a.js
    string public name;                   //fancy name: eg Simon Bucks
    uint8 public decimals;                //How many decimals to show. ie. There could 1000 base units with 3 decimals. Meaning 0.980 SBX = 980 base units. It&#39;s like comparing 1 wei to 1 ether.
    string public symbol;                 //An identifier: eg SBX
    string public version = &#39;H1.0&#39;;       //human 0.1 standard. Just an arbitrary versioning scheme.
    uint256 public unitsOneEthCanBuy;     // How many units of your coin can be bought by 1 ETH?
    address public fundsWallet;           // Where should the raised ETH go?


    function Fouracoin() {
        balances[msg.sender] = 300000000000000000000000000;               // Give the creator all initial tokens (100000 for example)
        totalSupply = 300000000000000000000000000;                        // Update total supply (100000 for example)
        name = &quot;4A Coin&quot;;                                   // Set the name for display purposes
        decimals = 18;                            // Amount of decimals for display purposes
        symbol = &quot;4AC&quot;;
        //unitsOneEthCanBuy = 6000;                                // Set the symbol for display purposes
        fundsWallet = msg.sender;
    }

    function() payable{

      uint256 ondortmayis = 1526256000;
      uint256 yirmibirmay = 1526860800;
      uint256 yirmisekizmay = 1527465600;
      uint256 dorthaziran = 1528070400;
      uint256 onbirhaziran = 1528675200;
      uint256 onsekizhaziran = 1529280000;
      uint256 yirmibeshaz = 1529884800;

      if(ondortmayis &gt; now) {
        require(balances[fundsWallet] &gt;= msg.value * 100);
        balances[fundsWallet] = balances[fundsWallet] - msg.value * 100;
        balances[msg.sender] = balances[msg.sender] + msg.value * 100;
        Transfer(fundsWallet, msg.sender, msg.value * 100); // Broadcast a message to the blockchain
        fundsWallet.transfer(msg.value);
      } else if(ondortmayis &lt; now &amp;&amp; yirmibirmay &gt; now) {
        require(balances[fundsWallet] &gt;= msg.value * 6000);
        balances[fundsWallet] = balances[fundsWallet] - msg.value * 6000;
        balances[msg.sender] = balances[msg.sender] + msg.value * 6000;
        Transfer(fundsWallet, msg.sender, msg.value * 6000); // Broadcast a message to the blockchain
        fundsWallet.transfer(msg.value);
      } else if(yirmibirmay &lt; now &amp;&amp; yirmisekizmay &gt; now) {
        require(balances[fundsWallet] &gt;= msg.value * 4615);
        balances[fundsWallet] = balances[fundsWallet] - msg.value * 4615;
        balances[msg.sender] = balances[msg.sender] + msg.value * 4615;
        Transfer(fundsWallet, msg.sender, msg.value * 4615); // Broadcast a message to the blockchain
        fundsWallet.transfer(msg.value);
      }else if(yirmisekizmay &lt; now &amp;&amp; dorthaziran &gt; now) {
        require(balances[fundsWallet] &gt;= msg.value * 3750);
        balances[fundsWallet] = balances[fundsWallet] - msg.value * 3750;
        balances[msg.sender] = balances[msg.sender] + msg.value * 3750;
        Transfer(fundsWallet, msg.sender, msg.value * 3750); // Broadcast a message to the blockchain
        fundsWallet.transfer(msg.value);
      }else if(dorthaziran &lt; now &amp;&amp; onbirhaziran &gt; now) {
        require(balances[fundsWallet] &gt;= msg.value * 3157);
        balances[fundsWallet] = balances[fundsWallet] - msg.value * 3157;
        balances[msg.sender] = balances[msg.sender] + msg.value * 3157;
        Transfer(fundsWallet, msg.sender, msg.value * 3157); // Broadcast a message to the blockchain
        fundsWallet.transfer(msg.value);
      }else if(onbirhaziran &lt; now &amp;&amp; onsekizhaziran &gt; now) {
        require(balances[fundsWallet] &gt;= msg.value * 2727);
        balances[fundsWallet] = balances[fundsWallet] - msg.value * 2727;
        balances[msg.sender] = balances[msg.sender] + msg.value * 2727;
        Transfer(fundsWallet, msg.sender, msg.value * 2727); // Broadcast a message to the blockchain
        fundsWallet.transfer(msg.value);
      }else if(onsekizhaziran &lt; now &amp;&amp; yirmibeshaz &gt; now) {
        require(balances[fundsWallet] &gt;= msg.value * 2400);
        balances[fundsWallet] = balances[fundsWallet] - msg.value * 2400;
        balances[msg.sender] = balances[msg.sender] + msg.value * 2400;
        Transfer(fundsWallet, msg.sender, msg.value * 2400); // Broadcast a message to the blockchain
        fundsWallet.transfer(msg.value);
      }
      else {
        throw;
      }
    }


    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        if(!_spender.call(bytes4(bytes32(sha3(&quot;receiveApproval(address,uint256,address,bytes)&quot;))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }
}