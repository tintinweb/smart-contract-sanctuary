pragma solidity ^0.4.23;

//A modern ERC-20 token
//The airdropper works on any ERC-20 token that implements approve(spender, tokens) 
//and transferFrom(from, to, tokens)
interface IStandardToken {
    function totalSupply() external constant returns (uint);
    function balanceOf(address tokenOwner) external constant returns (uint balance);
    function allowance(address tokenOwner, address spender) external constant returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    function decimals() external returns (uint256);
}

/*
 * A  simple airdrop contract for an ERC-20 tokenContract
 * Usage: 
 * 1) Pass the address of your token and the # tokens to dispense per user to the constructor.
 * 2) approve() the address of the newly created YeekAirdropper to 
 *    spend tokens on your behalf, amount to equal the total number of tokens
 *    you are airdropping
 * 3) Have your airdrop recipients call withdrawAirdropTokens() to get their free tokens
 * 4) Airdrop ends when the approved amount of tokens have been dispensed OR 
 *  your balance drops too low OR you call endAirdrop()
 */
 
contract YeekAirdropper {
    IStandardToken public tokenContract;  // the token being sold
    address public owner;
    uint256 public numberOfTokensPerUser;
    uint256 public tokensDispensed;
    mapping(address => bool) public airdroppedUsers;
    address[] public airdropRecipients;
    event Dispensed(address indexed buyer, uint256 amount);
    
    //Constructs an Airdropper for a given token contract
    constructor(IStandardToken _tokenContract, uint256 _numTokensPerUser) public {
        owner = msg.sender;
        tokenContract = _tokenContract;
        numberOfTokensPerUser = _numTokensPerUser * 10 ** tokenContract.decimals();
    }

    //Gets # of people that have already withdrawn their airdrop tokens
    //In a web3.js client, airdropRecipients.length is not available 
    //so we need to get the count this way. Any iteration over the 
    //airdropRecipients array will be done in JS so as not to waste gas
    function airdropRecipientCount() public view returns(uint) {
        return airdropRecipients.length;
    }

    //Transfers numberOfTokensPerUser from owner to msg.sender
    //if sufficient remaining tokens exist
    function withdrawAirdropTokens() public  {
        require(tokenContract.allowance(owner, this) >= numberOfTokensPerUser);
        require(tokenContract.balanceOf(owner) >= numberOfTokensPerUser);
        require(!airdroppedUsers[msg.sender]);  //Each address may only receive the airdrop one time
        
        tokensDispensed += numberOfTokensPerUser;

        airdroppedUsers[msg.sender]  = true;
        airdropRecipients.length++;
        airdropRecipients[airdropRecipients.length - 1]= msg.sender;
        
        emit Dispensed(msg.sender, numberOfTokensPerUser);
        tokenContract.transferFrom(owner, msg.sender, numberOfTokensPerUser);
    }

    //How many tokens are remaining to be airdropped
    function tokensRemaining() public view returns (uint256) {
        return tokenContract.allowance(owner, this);
    }

    //Causes this contract to suicide and send any accidentally 
    //acquired ether to its owner.
    function endAirdrop() public {
        require(msg.sender == owner);
        selfdestruct(msg.sender); //If any ethereum has been accidentally sent to the contract, withdraw it 
    }
}