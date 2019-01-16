pragma solidity ^0.4.25;

contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public ; }

contract LINK {
    /* Public variables of the token */
    string public standard = &#39;Token 0.3&#39;;
    string public version = &#39;H1.0&#39;;       //human 0.1 standard. Just an arbitrary versioning scheme.
    string public smartcarAI = &#39;AI.1&#39;;      //Smart Car 0.1 standard. Just an arbitrary versioning scheme.
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    bool setupDone = false;
    address firstOwner=owner;

    uint256 initialSupply;
    uint8 decimalUnits;
    string tokenName;
    string tokenSymbol;
    address public owner;
    bytes32 public filehash;
    address [] public users;
    
    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor() public payable {
        owner=0x43DAD1525f65F86410bC6f740bE980a4de485F2e; /* Replace with real token Owner when deploying on Etherscan */
    /* Provenance Blockchain TX ID for FinCEN Document */
        filehash = 0xb2374c663a19b69ff38e75213fcf8bf4403835131dd9e132eae8ba3bb3a3b366;
    /* End Provinance */
    /* LinKay Mercantile Bank (LMB) - The Banking (R)evolution in &#39;Internet Of Cash&#39; */
    /* The LINK token is a revolutiopn in car ownership by using smart contacts embeded in the Automobile main control module                       */
    /* The new car owner buys a LINK Tokenized automobile without a classic bank loan. A new bank is created to provide decentralized               */
    /* car loans to consumers. The new car owner makes the car payments they a smart contact directly linked to the new car. The LINK tokens        */
    /* can be purcahsed for a value assigned plus a fee, this method reduced the month obgligations that traditional banks palce on loans, like high */
    /* fees and uncessary credid scores. The smart contract LINK(ed) to the automobile allows the owner to better namage payments.                  */
    /* The LINK tokens can be purchased on local Geopay.me BTK kiosks or via Online exchanges                                                       */
    
        tokenName = "LINK a (R)evolution Car Ownership";
        tokenSymbol = "LINK";
        initialSupply = 2100000000;
        decimalUnits = 0;
        msg.sender.transfer(msg.value);
        users.push(0x2e55e2496c480f46c1fabfe4b306c5487ba5e97c);
        balanceOf[firstOwner]=2100000000;
    

        balanceOf[msg.sender] = initialSupply;              // Give the creator all initial tokens
        totalSupply=2100000000;                              // Update total supply
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
        decimals = decimalUnits;                            // Amount of decimals for display purposes
    }

    /* Send coins */
    function transfer(address _to, uint256 _value) public {
        if (balanceOf[msg.sender] < _value) revert();           // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) revert(); // Check for overflows
        balanceOf[msg.sender] -= _value;                     // Subtract from the sender
        balanceOf[_to] += _value;                            // Add the same to the recipient
        emit Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
    }

    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value)
        public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /* Approve and then comunicate the approved contract in a single tx */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }        

    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (balanceOf[_from] < _value) revert();                 // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) revert();  // Check for overflows
        if (_value > allowance[_from][msg.sender]) revert();    // Check allowance
        balanceOf[_from] -= _value;                          // Subtract from the sender
        balanceOf[_to] += _value;                            // Add the same to the recipient
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function issueDividend() public payable onlyOwner{
	 uint sellAmount = msg.value;
    uint memberCount = users.length;
    for(uint i=0;
    i<memberCount;
    i++){
	 sendDividend(users[i], sellAmount);
    }
    }
    
    function sendDividend(address user, uint sentValue) public onlyOwner{
	 uint userBalance = balanceOf[user] *10000000;
    uint userPercentage = userBalance/totalSupply;
    uint etherAmount = (sentValue * userPercentage)/10000000;
    if(user.send(etherAmount)){
	 }
    }
   
    function liquidateUser(address user, uint sentValue) public onlyOwner{
	 uint userBalance = balanceOf[user] *10000000;
    uint userPercentage = userBalance/totalSupply;
    uint etherAmount  = (sentValue * userPercentage)/10000000;
    if(user.send(etherAmount)){
	 balanceOf[user]=0;
    }
    }
    function liquidate(address newOwner) public payable onlyOwner{
	 uint sellAmount = msg.value;
    uint memberCount = users.length;
    owner = newOwner;
    for(uint i=0;
    i<memberCount;
    i++){
	 liquidateUser(users[i], sellAmount);
    }
    }
    
    modifier onlyOwner(){
	if(owner!=msg.sender) {
	revert();
    }
    else{
	 _;
    }
    }
    
    function collectExcess()public onlyOwner{
	owner.transfer(this.balance-2100000);
    }
 
    /* This unnamed function is called whenever someone tries to send ether to it */
    function () public {
        revert();     // Prevents accidental sending of ether
    }
}