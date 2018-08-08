pragma solidity ^0.4.4;

/*

 _____ ___ ______ _____ _____ _____ _____    ___ ____________ _____
|_   _/ _ \| ___ |  __ |  ___|_   _|  _  |  / _ \| ___ | ___ /  ___|
  | |/ /_\ | |_/ | |  \| |__   | | | | | | / /_\ | |_/ | |_/ \ `--.
  | ||  _  |    /| | __|  __|  | | | | | | |  _  |  __/|  __/ `--. \
  | || | | | |\ \| |_\ | |___  | | \ \_/ / | | | | |   | |   /\__/ /
  \_/\_| |_\_| \_|\____\____/  \_/  \___/  \_| |_\_|   \_|   \____/

*/

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

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) returns (bool success) {}

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
        require( now > 1548979261 );
        //Default assumes totalSupply can&#39;t be over max (2^256 - 1).
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
}

contract AtpcCoin is StandardToken {

    /* Public variables of the token */

    string public name;
    uint8 public decimals;
    string public symbol;
    string public version = &#39;H1.0&#39;;
    uint256 public unitsOneEthCanBuy;     // How many units of your coin can be bought by 1 ETH?
    uint256 public totalEthInWei;
    address public fundsWallet;           // Where should the raised ETH go?
    address public owner;
    bool public isICOOver;
    bool public isICOActive;


    constructor() public {
        balances[msg.sender] = 190800000000000000000000000;
        totalSupply = 190800000000000000000000000;
        name = "ATPC Coin";
        decimals = 18;
        symbol = "ATPC";
        unitsOneEthCanBuy = 1460;
        fundsWallet = msg.sender;
        owner = msg.sender;
        isICOOver = false;
        isICOActive = true;
    }

    modifier ownerFunc(){
      require(msg.sender == owner);
      _;
    }

    function transferAdmin(address _to, uint256 _value) ownerFunc returns (bool success) {
        //Default assumes totalSupply can&#39;t be over max (2^256 - 1).
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function changeICOState(bool isActive, bool isOver) public ownerFunc payable {
      isICOOver = isOver;
      isICOActive = isActive;
    }

    function changePrice(uint256 price) public ownerFunc payable {
      unitsOneEthCanBuy = price;
    }

    function() public payable {
        require(!isICOOver);
        require(isICOActive);

        totalEthInWei = totalEthInWei + msg.value;
        uint256 amount = msg.value * unitsOneEthCanBuy;
        require(balances[fundsWallet] >= amount);

        balances[fundsWallet] = balances[fundsWallet] - amount;
        balances[msg.sender] = balances[msg.sender] + amount;
        emit Transfer(fundsWallet, msg.sender, amount); // Broadcast a message to the blockchain

        //Transfer ether to fundsWallet
        fundsWallet.transfer(msg.value);
    }

    /* Approves and then calls the receiving contract */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

        //call the receiveApproval function on the contract you want to be notified. This crafts the function signature manually so one doesn&#39;t have to include a contract in here just for this.
        //receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
        //it is assumed that when does this that the call *should* succeed, otherwise one would use vanilla approve instead.
        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }
}