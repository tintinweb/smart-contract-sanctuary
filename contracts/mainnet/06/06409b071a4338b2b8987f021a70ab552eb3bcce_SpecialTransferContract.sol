pragma solidity ^0.4.25;

/*
Version 1.0.14
This contract accepts ETH, and distributes tokens.
DBLK Airdrop Multiplier
 */


interface IERC20Token {
    function balanceOf(address owner) external returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function decimals() external returns (uint256);
}

contract SpecialTransferContract {
    IERC20Token public tokenContract;  // the address of the token
    address public owner;               // address of this contracts owner
    uint256 public tokensDistributed;          // tally of the number of tokens distributed
    uint256 public acceptableEthAmountInWei; //exact eth amount in wei this contract will accept
    uint256 public tokensPerContributor;    // number of tokens to distribute to each contributor
    uint256 public contributionsMade; // tally of all contributions 
    bytes32 contractOwner; // contract owner address, used during deploy

    event Contribution(address buyer, uint256 amount); //log contributions

    constructor(bytes32 _contractOwner, IERC20Token _tokenContract) public {
        owner = msg.sender;
        contractOwner = _contractOwner;
        tokenContract = _tokenContract; 
    }    

    
    function ConfigurableParameters(uint256 _tokensPerContributor, uint256 _acceptableEthAmountInWei) public {
        require(msg.sender == owner); //only owner can change these
        tokensPerContributor = _tokensPerContributor;
        acceptableEthAmountInWei = _acceptableEthAmountInWei;
    }
    
    
    function () payable public {
    // skip this function if owner calls the contract    
    require(msg.sender != owner);   

   //call the acceptContribution function to transfer tokens for eth
    acceptContribution();
    emit Contribution(msg.sender, tokensPerContributor); // create event
    owner.transfer(msg.value); // send received Eth to owner
    }
    
    
    function acceptContribution() public payable {
        // ensure contract holds enough tokens to send
        require(tokenContract.balanceOf(this) >= tokensPerContributor);
        
        // verify purchase amount is correct (eg.0.1ETH (100000000000000000)
        require(msg.value == acceptableEthAmountInWei);

        // keep a tally of distributions and tokens
        tokensDistributed += tokensPerContributor;
        contributionsMade += 1;

        require(tokenContract.transfer(msg.sender, tokensPerContributor));
    }

    function endSale() public {
        require(msg.sender == owner);

        // Send unsold tokens back to the owner.
        require(tokenContract.transfer(owner, tokenContract.balanceOf(this)));

        // Send any remaining Eth from contract to the owner.
        msg.sender.transfer(address(this).balance);
    }
}