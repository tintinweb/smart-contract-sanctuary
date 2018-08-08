pragma solidity ^0.4.16;

contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

/**
 * Math operations with safety checks
 */
contract SafeMath {
  function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b > 0);
    uint256 c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c>=a && c>=b);
    return c;
  }
}
interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external ; }

contract TokenERC20 is SafeMath {
    // Public variables of the token
    string public name = "World Trading Unit";
    string public symbol = "WTU";
    uint8 public decimals = 8;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public TotalToken = 21000000;
    uint256 public RemainingTokenStockForSale;

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    /**
     * Constructor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    function TokenERC20() public {
        RemainingTokenStockForSale = safeMul(TotalToken,10 ** uint256(decimals));  // Update total supply with the decimal amount
        balanceOf[msg.sender] = RemainingTokenStockForSale;                    // Give the creator all initial tokens
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Save this for an assertion in the future
        uint previousBalances = safeAdd(balanceOf[_from],balanceOf[_to]);
        // Subtract from the sender
        balanceOf[_from] =  safeSub(balanceOf[_from], _value);
        // Add the same to the recipient
        balanceOf[_to] = safeAdd(balanceOf[_to],_value);
        Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(safeAdd(balanceOf[_from],balanceOf[_to]) == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` in behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] = safeSub(allowance[_from][msg.sender],_value);
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender],_value);      // Subtract from the sender
        RemainingTokenStockForSale = safeSub(RemainingTokenStockForSale,_value);                // Updates RemainingTokenStockForSale
        Burn(msg.sender, _value);
        return true;
    }

    /**
     * Destroy tokens from other account
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] -= _value;                         // Subtract from the targeted balance
        allowance[_from][msg.sender]  = safeSub(allowance[_from][msg.sender],_value);             // Subtract from the sender&#39;s allowance
        RemainingTokenStockForSale = safeSub(RemainingTokenStockForSale,_value);                              // Update RemainingTokenStockForSale
        Burn(_from, _value);
        return true;
    }
}

/******************************************/
/*       ADVANCED TOKEN STARTS HERE       */
/******************************************/

contract MyAdvancedToken is owned, TokenERC20 {

    uint256 public sellPrice = 0.001 ether;
    uint256 public buyPrice = 0.001 ether;

    mapping (address => bool) public frozenAccount;

    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address target, bool frozen);

    /* Internal transfer, only can be called by this contract */
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                               // Prevent transfer to 0x0 address. Use burn() instead
        require (balanceOf[_from] >= _value);               // Check if the sender has enough
        require (safeAdd(balanceOf[_to],_value) > balanceOf[_to]); // Check for overflows
        require(!frozenAccount[_from]);                     // Check if sender is frozen
        require(!frozenAccount[_to]);                       // Check if recipient is frozen
        balanceOf[_from] = safeSub(balanceOf[_from],_value);                         // Subtract from the sender
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);                           // Add the same to the recipient
        Transfer(_from, _to, _value);
    }

    /// @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
    /// @param target Address to be frozen
    /// @param freeze either to freeze it or not
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

    /// @notice Allow users to buy tokens for `newBuyPrice` eth and sell tokens for `newSellPrice` eth
    /// @param newSellPrice Price the users can sell to the contract
    /// @param newBuyPrice Price users can buy from the contract
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }

    /// @notice Buy tokens from contract by sending ether
    function buy() payable public {
        uint amount = safeDiv(msg.value, buyPrice);               // calculates the amount
        _transfer(this, msg.sender, amount);              // makes the transfers
    }

    /// @notice Sell `amount` tokens to contract
    /// @param amount amount of tokens to be sold
    function sell(uint256 amount) public {
        require(this.balance >= safeMul(amount,sellPrice));      // checks if the contract has enough ether to buy
        _transfer(msg.sender, this, amount);              // makes the transfers
        msg.sender.transfer(safeMul(amount, sellPrice));          // sends ether to the seller. It&#39;s important to do this last to avoid recursion attacks
    }
    //FallBack 
    function () payable public {
        
    }
/*
Fonction de repli FallBack (fonction sans nom)
Un contrat peut avoir exactement une fonction sans nom. Cette fonction ne peut pas avoir d&#39;arguments et ne peut rien retourner. Il est ex&#233;cut&#233; sur un appel au contrat si aucune des autres fonctions ne correspond &#224; l&#39;identificateur de fonction donn&#233; (ou si aucune donn&#233;e n&#39;a &#233;t&#233; fournie).

De plus, cette fonction est ex&#233;cut&#233;e chaque fois que le contrat re&#231;oit un Ether (sans donn&#233;es). De plus, afin de recevoir Ether, la fonction de repli doit &#234;tre marqu&#233;e payable. Si aucune fonction n&#39;existe, le contrat ne peut pas recevoir Ether via des transactions r&#233;guli&#232;res.

Dans le pire des cas, la fonction de repli ne peut compter que sur 2300 gaz disponibles (par exemple lorsque l&#39;envoi ou le transfert est utilis&#233;), ne laissant pas beaucoup de place pour effectuer d&#39;autres op&#233;rations sauf la journalisation de base.
Les op&#233;rations suivantes consomment plus de gaz que l&#39;allocation de gaz 2300:

 - Ecrire dans le stockage
 - Cr&#233;er un contrat
 - Appel d&#39;une fonction externe qui consomme une grande quantit&#233; de gaz
 - Envoyer Ether
 
Comme toute fonction, la fonction de repli peut ex&#233;cuter des op&#233;rations complexes tant qu&#39;il y a suffisamment de gaz.

Remarque
 M&#234;me si la fonction de remplacement ne peut pas avoir d&#39;arguments, vous pouvez toujours utiliser msg.data pour r&#233;cup&#233;rer les donn&#233;es utiles fournies avec l&#39;appel.

Attention
 Les contrats qui re&#231;oivent directement Ether 
 (sans appel de fonction, c&#39;est-&#224;-dire en utilisant send ou transfer)
 mais ne d&#233;finissent pas de fonction de repli jettent une exception,
 renvoyant l&#39;Ether (ceci &#233;tait diff&#233;rent avant Solidity v0.4.0).
 Donc, si vous voulez que votre contrat re&#231;oive Ether, 
 vous devez impl&#233;menter une fonction de repli.
 

Attention
 Un contrat sans fonction de repli payable peut recevoir Ether 
 en tant que destinataire d&#39;une transaction coinbase 
 (r&#233;compense de bloc minier) 
 ou en tant que destination d&#39;un selfdestruct.

Un contrat ne peut pas r&#233;agir &#224; ces transferts Ether et ne peut donc pas les rejeter.
C&#39;est un choix de conception de l&#39;EVM et Solidity ne peut pas contourner ce probl&#232;me.

Cela signifie &#233;galement que cette valeur peut &#234;tre sup&#233;rieure &#224; la somme de certains comptes manuels impl&#233;ment&#233;s dans un contrat (c&#39;est-&#224;-dire avoir un compteur mis &#224; jour dans la fonction de repli).
*/


}