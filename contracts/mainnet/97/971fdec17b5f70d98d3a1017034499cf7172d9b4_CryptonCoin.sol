pragma solidity ^0.4.4;

contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

contract Token {
    /// @return total amount of tokens
    function totalSupply() public constant returns (uint256 supply) {}

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) public constant returns (uint256 balance) {}

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) public returns (bool success) {}

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {}

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) public returns (bool success) {}

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    event Burn(address indexed from, uint256 value);
}


contract StandardToken is Token, SafeMath {
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;

    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);

        emit Transfer(msg.sender, to, tokens);

        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);

        emit Transfer(from, to, tokens);

        return true;
    }

    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;

        emit Approval(msg.sender, spender, tokens);

        return true;
    }

    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


    function burn(uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);                         // Check if the sender has enough
        balances[msg.sender] = safeSub(balances[msg.sender], _value);    // Subtract from the sender
        totalSupply = safeSub(totalSupply,_value);                       // Updates totalSupply

        emit Burn(msg.sender, _value);

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
        require(balances[_from] >= _value);                                        // Check if the targeted balance is enough
        require(_value <= allowed[_from][msg.sender]);                             // Check allowance
        balances[_from] = safeSub(balances[_from],_value);                         // Subtract from the targeted balance
        allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender],_value);   // Subtract from the sender&#39;s allowance
        totalSupply = safeSub(totalSupply,_value);                                 // Update totalSupply
        emit    Burn(_from, _value);
        return true;
    }
}

contract CryptonCoin is StandardToken {
    string public name;
    uint8 public decimals;
    string public symbol;
    string public version = &#39;H1.0&#39;;
    address public fundsWallet;
    address public contractAddress;

    uint256 public preIcoSupply;
    uint256 public preIcoTotalSupply;

    uint256 public IcoSupply;
    uint256 public IcoTotalSupply;

    uint256 public maxSupply;
    uint256 public totalSupply;

    uint256 public unitsOneEthCanBuy;
    uint256 public totalEthInWei;

    bool public ico_finish;
    bool public token_was_created;

    uint256 public preIcoFinishTimestamp;
    uint256 public fundingEndTime;
    uint256 public finalTokensIssueTime;

    function CryptonCoin() public {
        fundsWallet = msg.sender;

        name = "CRYPTON";
        symbol = "CRN";
        decimals = 18;

        balances[fundsWallet] = 0;
        totalSupply       = 0;
        preIcoTotalSupply = 14400000000000000000000000;
        IcoTotalSupply    = 36000000000000000000000000;
        maxSupply         = 72000000000000000000000000;
        unitsOneEthCanBuy = 377;

        preIcoFinishTimestamp = 1524785992; // Thu Apr 26 23:39:52 UTC 2018
        fundingEndTime        = 1528587592; // Sat Jun  9 23:39:52 UTC 2018
        finalTokensIssueTime  = 1577921992; // Wed Jan  1 23:39:52 UTC 2020

        contractAddress = address(this);
    }

    function() public payable {
        require(!ico_finish);
        require(block.timestamp < fundingEndTime);
        require(msg.value != 0);

        totalEthInWei = totalEthInWei + msg.value;
        uint256  amount = 0;
        uint256 tokenPrice = unitsOneEthCanBuy;

        if (block.timestamp < preIcoFinishTimestamp) {
            require(msg.value * tokenPrice * 13 / 10 <= (preIcoTotalSupply - preIcoSupply));

            tokenPrice = safeMul(tokenPrice,13);
            tokenPrice = safeDiv(tokenPrice,10);

            amount = safeMul(msg.value,tokenPrice);
            preIcoSupply = safeAdd(preIcoSupply,amount);

            balances[msg.sender] = safeAdd(balances[msg.sender],amount);
            totalSupply = safeAdd(totalSupply,amount);

            emit Transfer(contractAddress, msg.sender, amount);
        } else {
            require(msg.value * tokenPrice <= (IcoTotalSupply - IcoSupply));

            amount = safeMul(msg.value,tokenPrice);
            IcoSupply = safeAdd(IcoSupply,amount);
            balances[msg.sender] = safeAdd(balances[msg.sender],amount);
            totalSupply = safeAdd(totalSupply,amount);

            emit Transfer(contractAddress, msg.sender, amount);
        }
    }

    function withdraw() public {
            require(msg.sender == fundsWallet);
            fundsWallet.transfer(contractAddress.balance);

    }

    function createTokensForCrypton() public returns (bool success) {
        require(ico_finish);
        require(!token_was_created);

        if (block.timestamp > finalTokensIssueTime) {
            uint256 amount = safeAdd(preIcoSupply, IcoSupply);
            amount = safeMul(amount,3);
            amount = safeDiv(amount,10);

            balances[fundsWallet] = safeAdd(balances[fundsWallet],amount);
            totalSupply = safeAdd(totalSupply,amount);
            emit Transfer(contractAddress, fundsWallet, amount);
            token_was_created = true;
            return true;
        }
    }

    function stopIco() public returns (bool success) {
        if (block.timestamp > fundingEndTime) {
            ico_finish = true;
            return true;
        }
    }

    function setTokenPrice(uint256 _value) public returns (bool success) {
        require(msg.sender == fundsWallet);
        require(_value < 1500);
        unitsOneEthCanBuy = _value;
        return true;
    }
}
//Based on the source from hashnode.com
//CREATED BY MICHAŁ MICHALSKI @YSZTY with CRYPTON.VC