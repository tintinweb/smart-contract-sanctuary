pragma solidity ^0.4.24;
// Contract is owned by CryptX Financial 
// Owner ethereum address is 0x5F96FEC8db3548e0FC24C1ABe8C1a1eABd2Fad91
//Safe math ensures that the mathematical operations work as intended
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

// ERC20 Contract Interface for interacting with the Contract
contract Interface { 
    
    // Shows the total supply of token on the ethereum blockchain
    function Supply() public constant returns (uint);
    
    // Shows the token balance of the ethereum wallet address if any
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    
    // Transfering the token to any ethereum wallet address
    function transfer(address to, uint tokens) public returns (bool success);
    
    // This generates a public event on the ethereum blockchain for transfer notification
    event Transfer(address indexed from, address indexed to, uint tokens);

}
// CRYPTXFINANCIALToken contract
contract CRYPTXFINANCIALToken is Interface, SafeMath {
    string public symbol;
    string public name;
    uint8 public decimals;
    uint public totalSupply;
    address owner;

    mapping(address => uint) public balanceOf; // this creates an array of all the balances
    mapping (address => bool) public frozenAccount; // this creates an array of all frozen ethereum wallet address

    event Burn(address indexed from, uint256 value); // This generates a public event on the ethereum blockchain for burn notification
    event FrozenFunds(address target, bool frozen);  // This generates a public event on the ethereum blockchain for freeze notification

    constructor() public {
        symbol = "CRYPTX";
        name = "CRYPTX FINANCIAL Token";
        decimals = 18;
        owner = msg.sender; // Assigns the contract depoloyer as the contract owner
        totalSupply = 250000000000000000000000000; // Total number of tokens minted
        balanceOf[0x393869c02e4281144eDa540b35F306686D6DBc5c] = 162500000000000000000000000; // Number of tokens for the crowd sale
        balanceOf[0xd74Ac74CF89B3F4d6B0306fA044a81061E71ba35] = 87500000000000000000000000; // Number of tokens retained 
        emit Transfer(address(0), 0x393869c02e4281144eDa540b35F306686D6DBc5c, 162500000000000000000000000);
        emit Transfer(address(0), 0xd74Ac74CF89B3F4d6B0306fA044a81061E71ba35, 87500000000000000000000000);
    }

    // Shows the total supply of token on the ethereum blockchain
    function Supply() public constant returns (uint) {
        return totalSupply  - balanceOf[address(0)]; // totalSupply excluding the burnt tokens
    }

    // Shows the token balance of the ethereum wallet address if any 
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balanceOf[tokenOwner];  // ethereum wallet address is passed as argument
    }

    // Transfering the token to any ERC20 wallet address
    function transfer(address to, uint tokens) public returns (bool success) {
        require(to != 0x0); // Use burn function to do this 
        require(tokens > 0); // No 0 value transactions allowed
        require(!frozenAccount[msg.sender]); // Cannot send from a frozen wallet address
        require(!frozenAccount[to]); // Cannot send to a frozen wallet address
        require(balanceOf[msg.sender] >= tokens); // Check if enough balance is there from the sender
        require(safeAdd(balanceOf[to], tokens) > balanceOf[to]); // Cannot send 0 tokens
        uint256 previousBalances = safeAdd(balanceOf[msg.sender], balanceOf[to]); 
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], tokens); // Subract tokens from the sender wallet address
        balanceOf[to] = safeAdd(balanceOf[to], tokens); // Add the tokens to receiver wallet address
        emit Transfer(msg.sender, to, tokens); 
        require(balanceOf[msg.sender] + balanceOf[to] == previousBalances); // Checks intergrity of the Transfer
        return true; // Transfer done
    }

    // Not allowing a particular ethereum wallet address to send or receive tokens in case of blacklisting reactively
    function freezeAccount(address target, bool freeze)  public {
        require(msg.sender == owner); // Only the contract owner can freeze an ethereum wallet
        frozenAccount[target] = freeze; // Freezes the target ethereum wallet
        emit FrozenFunds(target, freeze); 
    }

    // Makes the token unusable
     function burn(uint256 amount) public returns (bool success) {
        require(balanceOf[msg.sender] >= amount); // Checks if the particular ethereum wallet address has enough tokens to Burn
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], amount); // Subract the tokens to be burnt from the user ethereum wallet address
        totalSupply = safeSub(totalSupply, amount); // Subract the tokens burnt from the total Supply
        emit Burn(msg.sender, amount); 
        return true; // tokens burnt successfully
    }

    // Cannot accept ethereum 
    //Please dont send ethereum to this contract address
    function () public payable {
        revert();
    }

}