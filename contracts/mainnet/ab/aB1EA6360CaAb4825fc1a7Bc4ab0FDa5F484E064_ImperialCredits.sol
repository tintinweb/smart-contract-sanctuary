pragma solidity ^0.4.11;

contract Erc20Token {
    /* Map all our our balances for issued tokens */
    mapping (address => uint256) balances;

    /* Map between users and their approval addresses and amounts */
    mapping(address => mapping (address => uint256)) allowed;

    /* List of all token holders */
    address[] allTokenHolders;

    /* The name of the contract */
    string public name;

    /* The symbol for the contract */
    string public symbol;

    /* How many DPs are in use in this contract */
    uint8 public decimals;

    /* Defines the current supply of the token in its own units */
    uint256 totalSupplyAmount = 0;

    /* Our transfer event to fire whenever we shift SMRT around */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /* Our approval event when one user approves another to control */
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    /* Create a new instance of the token with the specified details. */
    function Erc20Token(string _name, string _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

     /* Transfer funds between two addresses that are not the current msg.sender - this requires approval to have been set separately and follows standard ERC20 guidelines */
     function transferFrom(address _from, address _to, uint256 _amount) returns (bool success) {
        if (balances[_from] >= _amount && allowed[_from][msg.sender] >= _amount && _amount > 0 && balances[_to] + _amount > balances[_to]) {
            bool isNew = balances[_to] < 1;
            balances[_from] -= _amount;
            allowed[_from][msg.sender] -= _amount;
            balances[_to] += _amount;
            if (isNew)
                tokenOwnerAdd(_to);
            if (balances[_from] < 1)
                tokenOwnerRemove(_from);
            Transfer(_from, _to, _amount);
            return true;
        }
        return false;
    }

    /* Adds an approval for the specified account to spend money of the message sender up to the defined limit */
    function approve(address _spender, uint256 _amount) returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

    /* Gets the current allowance that has been approved for the specified spender of the owner address */
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /* Gets the total supply available of this token */
    function totalSupply() constant returns (uint256) {
        return totalSupplyAmount;
    }

    /* Gets the balance of a specified account */
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    /* Transfer the balance from owner&#39;s account to another account */
    function transfer(address _to, uint256 _amount) returns (bool success) {
        /* Check if sender has balance and for overflows */
        if (balances[msg.sender] < _amount || balances[_to] + _amount < balances[_to])
            throw;

        /* Do a check to see if they are new, if so we&#39;ll want to add it to our array */
        bool isRecipientNew = balances[_to] < 1;

        /* Add and subtract new balances */
        balances[msg.sender] -= _amount;
        balances[_to] += _amount;

        /* Consolidate arrays if they are new or if sender now has empty balance */
        if (isRecipientNew)
            tokenOwnerAdd(_to);
        if (balances[msg.sender] < 1)
            tokenOwnerRemove(msg.sender);

        /* Fire notification event */
        Transfer(msg.sender, _to, _amount);
        success = true;
    }

    /* If the specified address is not in our owner list, add them - this can be called by descendents to ensure the database is kept up to date. */
    function tokenOwnerAdd(address _addr) internal {
        /* First check if they already exist */
        uint256 tokenHolderCount = allTokenHolders.length;
        for (uint256 i = 0; i < tokenHolderCount; i++)
            if (allTokenHolders[i] == _addr)
                /* Already found so we can abort now */
                return;

        /* They don&#39;t seem to exist, so let&#39;s add them */
        allTokenHolders.length++;
        allTokenHolders[allTokenHolders.length - 1] = _addr;
    }

    /* If the specified address is in our owner list, remove them - this can be called by descendents to ensure the database is kept up to date. */
    function tokenOwnerRemove(address _addr) internal {
        /* Find out where in our array they are */
        uint256 tokenHolderCount = allTokenHolders.length;
        uint256 foundIndex = 0;
        bool found = false;
        uint256 i;
        for (i = 0; i < tokenHolderCount; i++)
            if (allTokenHolders[i] == _addr) {
                foundIndex = i;
                found = true;
                break;
            }

        /* If we didn&#39;t find them just return */
        if (!found)
            return;

        /* We now need to shuffle down the array */
        for (i = foundIndex; i < tokenHolderCount - 1; i++)
            allTokenHolders[i] = allTokenHolders[i + 1];
        allTokenHolders.length--;
    }
}

contract ImperialCredits is Erc20Token("Imperial Credits", "XIC", 0) {
    address owner;
    bool public isIco  = true;

    function icoWithdraw() {
      if (this.balance == 0 || msg.sender != owner)
        throw;
      if (!owner.send(this.balance))
        throw;
    }

    function icoClose() {
      if (msg.sender != owner || !isIco)
        throw;
      if (this.balance > 0)
        if (!owner.send(this.balance))
          throw;
      uint256 remaining = 1000000000 - totalSupplyAmount;
      if (remaining > 0) {
        balances[msg.sender] += remaining;
        totalSupplyAmount = 1000000000;
      }
      isIco = false;
    }

    function destroyCredits(uint256 amount) {
      if (balances[msg.sender] < amount)
        throw;
      balances[msg.sender] -= amount;
      totalSupplyAmount -= amount;
    }

    function ImperialCredits() {
      owner=msg.sender;
      balances[msg.sender] = 100000;
      totalSupplyAmount = 100000;
    }

    function () payable {
        if (totalSupplyAmount >= 1000000000 || !isIco)
          throw;
        uint256 mintAmount = msg.value / 100000000000000;
        uint256 maxMint = 1000000000 - totalSupplyAmount;
        if (mintAmount > maxMint)
          mintAmount = maxMint;
        uint256 change = msg.value - (100000000000000 * mintAmount);
        if (!msg.sender.send(change))
          throw;
        balances[msg.sender] += mintAmount;
        totalSupplyAmount += mintAmount;
    }
}