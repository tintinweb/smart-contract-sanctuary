pragma solidity 0.8.0;

import "./ERC20.sol";
import "./IERC20.sol";


contract BillionTokenPool {

    Token public token;

    uint256 public contractCreationTime;

    address public owner;
    
    mapping(address => uint256) public addressToBalance;

    address[] public users;
    
    uint256 totalStackedEth = 0;
    
    uint256 layer = 0;
    
    constructor() {
        owner = msg.sender;
        token = new Token();
        contractCreationTime = block.timestamp;
    }
    
    function currentTokenAmount() view public returns(uint256) {
        if(block.timestamp < contractCreationTime + 864000)
        {
            return(200);
        }
        else if(block.timestamp < contractCreationTime + 2592000)
        {
            return(150);
        }
        else if(block.timestamp < contractCreationTime + 13824000)
        {
            return(100);
        }
        else if(block.timestamp < contractCreationTime + 20736000)
        {
            return(50);
        }
        else if(block.timestamp < contractCreationTime + 25920000)
        {
            return(30);
        }
        else
        {
            return(15);
        }
    }
    
    
    function payContract() payable external {
        require(msg.value == 0.25 ether);
        
        uint256 numberOfNewTokens = currentTokenAmount();
        
        token.mint(address(this), numberOfNewTokens);
        
        if(layer == 0)
        {
            addressToBalance[owner] += msg.value * 85 / 100;
            
            token.transferFrom(address(this), msg.sender, numberOfNewTokens / 2);
            token.transferFrom(address(this), owner, numberOfNewTokens / 2);
        }
        else if(layer == 1)
        {
            addressToBalance[owner] += msg.value * 75 / 100;

            token.transferFrom(address(this), msg.sender, numberOfNewTokens / 2);
            token.transferFrom(address(this), users[0], numberOfNewTokens * 35 / 100);
            token.transferFrom(address(this), owner, numberOfNewTokens * 30 / 100);
        }
        else if(layer == 2)
        {
            addressToBalance[owner] += msg.value * 65 / 100;
            
            token.transferFrom(address(this), msg.sender, numberOfNewTokens / 2);
            token.transferFrom(address(this), users[0], numberOfNewTokens * 15 / 100);
            token.transferFrom(address(this), users[1], numberOfNewTokens * 35 / 100);
        }
        else if(layer == 3)
        {
            addressToBalance[owner] += msg.value * 55 / 100;
            
            token.transferFrom(address(this), msg.sender, numberOfNewTokens / 2);
            token.transferFrom(address(this), users[1], numberOfNewTokens * 15 / 100);
            token.transferFrom(address(this), users[2], numberOfNewTokens * 35 / 100);
        }
        else if(layer == 4)
        {
            addressToBalance[owner] += msg.value * 45 / 100;
            
            token.transferFrom(address(this), msg.sender, numberOfNewTokens / 2);
            token.transferFrom(address(this), users[1], numberOfNewTokens * 15 / 100);
            token.transferFrom(address(this), users[2], numberOfNewTokens * 35 / 100);
        }
        else if(layer == 5)
        {
            addressToBalance[owner] += msg.value * 35 / 100;
            
            token.transferFrom(address(this), msg.sender, numberOfNewTokens / 2);
            token.transferFrom(address(this), users[1], numberOfNewTokens * 15 / 100);
            token.transferFrom(address(this), users[2], numberOfNewTokens * 35 / 100);
        }
        else if(layer == 6)
        {
            addressToBalance[owner] += msg.value * 25 / 100;
            
            token.transferFrom(address(this), msg.sender, numberOfNewTokens / 2);
            token.transferFrom(address(this), users[1], numberOfNewTokens * 15 / 100);
            token.transferFrom(address(this), users[2], numberOfNewTokens * 35 / 100);
        }
        else if(layer > 6)
        {
            addressToBalance[owner] += msg.value * 15 / 100;
            
            token.transferFrom(address(this), msg.sender, numberOfNewTokens / 2);
            token.transferFrom(address(this), users[1], numberOfNewTokens * 15 / 100);
            token.transferFrom(address(this), users[2], numberOfNewTokens * 35 / 100);
        }
        
        for(uint256 i=0;i<users.length;i++)
        {
            addressToBalance[users[i]] += msg.value * 10 / 100;
        }
        
        if(layer <= 6)
        {
            users.push(msg.sender);   
        }
        
        totalStackedEth += msg.value * 15 / 100;
        
        layer++;
    }
    
    //////////////////////////////
    //Exchange tokens for ethereum
    function exchangeTokens() payable external {
        require(block.timestamp > contractCreationTime + 31536000);
        addressToBalance[msg.sender] += totalStackedEth / token.totalSupply();
        token.transferFrom(msg.sender, 0x0000000000000000000000000000000000000000, token.balanceOf(msg.sender));
        
    }
    
    /////////////////////////////////
    //Withdraw ethereum from contract
    function withdrawEthereum() external {
        payable(msg.sender).transfer(addressToBalance[msg.sender]);
        addressToBalance[msg.sender] = 0;
    }
    
}

contract Token is ERC20 {
    
    constructor() ERC20("BilionToken", "BLT") {
        
    }
    
}