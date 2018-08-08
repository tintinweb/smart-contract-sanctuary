pragma solidity ^0.4.11;
contract owned {
    address public owner;
    address public authorisedContract;
    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    modifier onlyAuthorisedAddress{
        require(msg.sender == authorisedContract);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
    modifier onlyPayloadSize(uint size) {
     assert(msg.data.length == size + 4);
     _;
    }
}

contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }

contract MyToken is owned {
    /* Public variables of the token */
    string public name = "DankToken";
    string public symbol = "DANK";
    uint8 public decimals = 18;
    uint256 _totalSupply;
    uint256 public amountRaised = 0;
    uint256 public amountOfTokensPerEther = 500;
        /* this makes an array with all frozen accounts. This is needed so voters can not send their funds while the vote is going on and they have already voted      */
    mapping (address => bool) public frozenAccounts;
        /* This creates an array with all balances */ 
    mapping (address => uint256) _balanceOf;
    mapping (address => mapping (address => uint256)) _allowance;
    bool public crowdsaleClosed = false;
    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event FrozenFunds(address target, bool frozen);
    /* Initializes contract with initial supply tokens to the creator of the contract */
    function MyToken() {
        _balanceOf[msg.sender] = 4000000000000000000000;              
        _totalSupply = 4000000000000000000000;                 
        Transfer(this, msg.sender,4000000000000000000000);
    }
    function changeAuthorisedContract(address target) onlyOwner
    {
        authorisedContract = target;
    }
    function() payable{
        require(!crowdsaleClosed);
        uint amount = msg.value;
        amountRaised += amount;
        uint256 totalTokens = amount * amountOfTokensPerEther;
        _balanceOf[msg.sender] += totalTokens;
        _totalSupply += totalTokens;
        Transfer(this,msg.sender, totalTokens);
    }
     function totalSupply() constant returns (uint TotalSupply){
        TotalSupply = _totalSupply;
     }
      function balanceOf(address _owner) constant returns (uint balance) {
        return _balanceOf[_owner];
     }
     function closeCrowdsale() onlyOwner{
         crowdsaleClosed = true;
     }
     function openCrowdsale() onlyOwner{
         crowdsaleClosed = false;
     }
     function changePrice(uint newAmountOfTokensPerEther) onlyOwner{
         require(newAmountOfTokensPerEther <= 500);
         amountOfTokensPerEther = newAmountOfTokensPerEther;
     }
     function withdrawal(uint256 amountOfWei) onlyOwner{
         if(owner.send(amountOfWei)){}
     }
     function freezeAccount(address target, bool freeze) onlyAuthorisedAddress
     {
         frozenAccounts[target] = freeze;
         FrozenFunds(target, freeze);
     } 
     
    /* Send coins */
    function transfer(address _to, uint256 _value) onlyPayloadSize(2*32) {
        require(!frozenAccounts[msg.sender]);
        require(_balanceOf[msg.sender] > _value);          // Check if the sender has enough
        require(_balanceOf[_to] + _value > _balanceOf[_to]); // Check for overflows
        _balanceOf[msg.sender] -= _value;                     // Subtract from the sender
        _balanceOf[_to] += _value;                            // Add the same to the recipient
        Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
    }
    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value)onlyPayloadSize(2*32)
        returns (bool success)  {
        _allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    } 

    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success)  {
        require(!frozenAccounts[_from]);
        require(_balanceOf[_from] > _value);                 // Check if the sender has enough
        require(_balanceOf[_to] + _value > _balanceOf[_to]);  // Check for overflows
        require(_allowance[_from][msg.sender] >= _value);     // Check allowance
        _balanceOf[_from] -= _value;                           // Subtract from the sender
        _balanceOf[_to] += _value;                             // Add the same to the recipient
        _allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }
    function allowance(address _owner, address _spender) constant returns (uint remaining) {
        return _allowance[_owner][_spender];
    }
}