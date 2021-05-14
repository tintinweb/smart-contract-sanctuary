pragma solidity ^0.4.26;

contract AIDToken {

    string public name;
    uint8 public decimals;
    string public symbol;
    uint256 public totalSupply;

    // Attempt on initial wallet seperation
    uint256 public heldTotal; 
    uint256 public maxMintable;
    uint256 public totalMinted;

    function totalSupply() constant returns (uint256 totalSupply) {}
    event Transfer(address indexed _from,address indexed _to,uint256 _value);
    event Approval(address indexed _owner,address indexed _spender,uint256 _value);

    // Attempt on initial wallet seperation
    event Contribution(address from, uint256 amount);
    event ReleaseTokens(address from, uint256 amount);

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;


    // Attempt on initial wallet seperation
    mapping (address => uint256) public heldTokens;
    mapping (address => uint) public heldTimeline;

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);

        balances[msg.sender] -= _value;
        balances[_to] += _value;

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] -= _value;
        balances[_to] += _value;

        allowed[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);

        return true;
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    function createHeldCoins() internal {
        // TOTAL SUPPLY = 8,000,000,000
        //createHoldToken(msg.sender, 1000);
        createHoldToken(0xeaed58451fC430EF8b5235D3c5e1Cd451A09AA77, 80000000000000000000000000);
        //createHoldToken(0x393c82c7Ae55B48775f4eCcd2523450d291f2418, 80000000000000000000000000);
        //createHoldToken(0x393c82c7Ae55B48775f4eCcd2523450d291f2418, 80000000000000000000000000);
    }

    function getHeldCoin(address _address) public constant returns (uint256) {
        return heldTokens[_address];
    }

    function createHoldToken(address _to, uint256 amount) internal {
        heldTokens[_to] = amount;
        heldTimeline[_to] = block.number + 0;
        heldTotal += amount;
        totalMinted += heldTotal;
    }

    function AIDToken() {
        decimals = 9;
        totalSupply = 8000000000 * (10 ** uint256(decimals));
        balances[this] = totalSupply;
        //balances[msg.sender] = 240000000;
        name = "AID Token";
        symbol = "AID";                       
    }

    /* Approves and then calls the receiving contract */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

        //call the receiveApproval function on the contract you want to be notified. This crafts the function signature manually so one doesn't have to include a contract in here just for this.
        //receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
        //it is assumed that when does this that the call *should* succeed, otherwise one would use vanilla approve instead.
        if(!_spender.call(bytes4(bytes32(keccak256("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { revert(); }
        return true;
    }
}