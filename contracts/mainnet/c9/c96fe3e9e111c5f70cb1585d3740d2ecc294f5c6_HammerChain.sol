pragma solidity ^0.4.20;


interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract Token{
    uint256 public totalSupply;

    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed from, uint256 value);
}

contract HammerChain is Token {

    address  owner;  // owner address
    address INCENTIVE_POOL_ADDR = 0x0;
    address FOUNDATION_POOL_ADDR = 0xE4ae52AeC7359c145f4aEeBEFA59fC6F181a4e43;
    address COMMUNITY_POOL_ADDR = 0x611C1e09589d658c6881B3966F42bEA84d0Fab82;
    address FOUNDERS_POOL_ADDR = 0x59556f481FF8d1f0C55926f981070Aa8f767922b;

    bool releasedFoundation = false;
    bool releasedCommunity = false;
    uint256  timeIncentive = 0x0;
    uint256 limitIncentive=0x0;
    uint256 timeFounders= 0x0;
    uint256 limitFounders=0x0;

    string public name;                 //HRC name 
    uint8 public decimals;              //token decimals with HRC
    string public symbol;               //token symbol with HRC

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    modifier onlyOwner { 
        require(msg.sender == owner);
        _;
    }


    function HammerChain() public {
        owner = msg.sender;
        uint8 _decimalUnits = 18; // 18 decimals is the strongly suggested default, avoid changing it
        totalSupply = 512000000 * 10 ** uint256(_decimalUnits); // iniliatized total supply token
        balances[msg.sender] = totalSupply; 

        name = "HammerChain";
        decimals = _decimalUnits;
        symbol = "HRC";
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        // default is totalSupply not of out (2^256 - 1).
        require(balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]);
        require(_to != 0x0);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_to != 0x0);
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

    function approve(address _spender, uint256 _value) public returns (bool success)   
    { 
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];//allow _spender from _owner send out token
    }

    function sendIncentive() onlyOwner public{
        require(limitIncentive < totalSupply/2);
        if (timeIncentive < now){
            if (timeIncentive == 0x0){
                transfer(INCENTIVE_POOL_ADDR,totalSupply/10);
                limitIncentive += totalSupply/10;
            }
            else{
                transfer(INCENTIVE_POOL_ADDR,totalSupply/20);
                limitIncentive += totalSupply/20;
            }
            timeIncentive = now + 365 days;
        }
    }

    function sendFounders() onlyOwner public{
        require(limitFounders < totalSupply/20);
        if (timeFounders== 0x0 || timeFounders < now){
            transfer(FOUNDERS_POOL_ADDR,totalSupply/100);
            timeFounders = now + 365 days;
            limitFounders += totalSupply/100;
        }
    }

    function sendFoundation() onlyOwner public{
        require(releasedFoundation == false);
        transfer(FOUNDATION_POOL_ADDR,totalSupply/4);
        releasedFoundation = true;
    }


    function sendCommunity() onlyOwner public{
        require(releasedCommunity == false);
        transfer(COMMUNITY_POOL_ADDR,totalSupply/5);
        releasedCommunity = true;
    }

    function setINCENTIVE_POOL_ADDR(address addr) onlyOwner public{
        INCENTIVE_POOL_ADDR = addr;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }

    function burn(uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);   // Check if the sender has enough
        balances[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balances[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowed[_from][msg.sender]);    // Check allowed
        balances[_from] -= _value;                         // Subtract from the targeted balance
        allowed[_from][msg.sender] -= _value;             // Subtract from the sender&#39;s allowance
        totalSupply -= _value;                              // Update totalSupply
        emit Burn(_from, _value);
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
        return false;
    }

}