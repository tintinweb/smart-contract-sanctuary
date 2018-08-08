pragma solidity ^0.4.21;

/*
  
    ****************************************************************
    AVALANCHE BLOCKCHAIN GENESIS BLOCK COIN ALLOCATION TOKEN CONTRACT
    ****************************************************************

    The Genesis Block in the Avalanche will deploy with pre-filled addresses
    according to the results of this token sale.
    
    The Avalanche tokens will be sent to the Ethereum address that buys them.
    
    When the Avalanche blockchain deploys, all ethereum addresses that contains
    Avalanche tokens will be credited with the equivalent AVALANCHE ICE (XAI) in the Genesis Block.

    There will be no developer premine. There will be no private presale. This is it.

    WARNING!! When the Avalanche Blockchain deploys this token contract will terminate!!
    You will no longer be able to transfer or sell your tokens on the Ethereum Network.
    Instead you will be the proud owner of native currency of the Avalanche Blockchain.
    You will be able to recover Avalanche Funds using your Ethereum keys. DO NOT LOSE YOUR KEYS!
    
    @author CHRIS DCOSTA For Meek Inc 2018.
    
    Reference Code by Hunter Long
    @repo https://github.com/hunterlong/ethereum-ico-contract

*/


contract BasicXAIToken {
    uint256 public totalSupply;
    bool public allowTransfer;

    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardXAIToken is BasicXAIToken {

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(allowTransfer);
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(allowTransfer);
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(allowTransfer);
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}


contract XAIToken is StandardXAIToken {

    string public name = "AVALANCHE TOKEN";
    uint8 public decimals = 18;
    string public symbol = "XAIT";
    string public version = &#39;XAIT 0.1&#39;;
    address public mintableAddress;
    address public creator;

    constructor(address sale_address) public {
        balances[msg.sender] = 0;
        totalSupply = 0;
        name = name;
        decimals = decimals;
        symbol = symbol;
        mintableAddress = sale_address; // sale contract address
        allowTransfer = true;
        creator = msg.sender;
        createTokens();
    }

    // creates AVALANCHE ICE Tokens
    // this address will hold all tokens
    // all community contrubutions coins will be taken from this address
    function createTokens() internal {
        uint256 total = 4045084999529091000000000000;
        balances[this] = total;
        totalSupply = total;
    }

    function changeTransfer(bool allowed) external {
        require(msg.sender == mintableAddress);
        require(allowTransfer);
        allowTransfer = allowed;
    }

    function mintToken(address to, uint256 amount) external returns (bool success) {
        require(msg.sender == mintableAddress);
        require(balances[this] >= amount);
        balances[this] -= amount;
        balances[to] += amount;
        emit Transfer(this, to, amount);
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

        require(_spender.call(bytes4(bytes32(keccak256("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData));
        return true;
    }

    // This function kills the token when Avalanche Blockchain is deployed
    function killAllXAITActivity() public {
      require(msg.sender==creator);
      allowTransfer = false;
    }
}