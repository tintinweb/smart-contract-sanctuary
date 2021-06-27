/**
 *Submitted for verification at Etherscan.io on 2021-06-27
*/

pragma solidity >=0.7.0 <0.9.0;

// import "./TokenFactory.sol"

contract Swapper {
    uint fromToken;
    uint toToken;
    address fromTokenAddress;
    address toTokenAddress;
 
    // mapping (uint => address) public zombieToOwner;
    mapping (address => uint) tokensAmount;
    uint tokenCount;
    
     mapping(uint=>address) addresses;

   constructor() {
        fromToken = 100;
        toToken = 0;
        
    }
    
    /**
     * Has a provide(amount) function that will take the amount of the fromToken from the function caller.
     * saca la guita de fromAmount y se la da al msg.sender
     **/
     
    function provide(uint amount) public {
        // fromToken can't have negative amount
        require(fromToken >= amount);
        tokensAmount[msg.sender] =  tokensAmount[msg.sender] + amount;
        addresses[tokenCount] = msg.sender;
        tokenCount++;
        fromToken = fromToken - amount;
    }
    
    /**
     * Has a swap function that will exchange all provided tokens into the toToken
     * de todos los ownerTokenAmount manda la guita a toToken
     **/
    function swap() public {
        
    }
    
    /**
     * Has a withdraw function that allows the user that provided the tokens to withdraw the toTokens that he should be allowed to withdraw.
     * permite retirar la guita de toToken si tiene permisos y se los manda 
     * pero no se donde lo manda. supongo q al msg.sender
     **/
    function withdraw() public {
        
    }
    
    // helpers views
    function listAddress() public view returns (address[] memory) {
        address[] memory ret = new address[](tokenCount);
        for (uint i = 0; i < tokenCount; i++) {
            ret[i] = addresses[i];
        }
        return ret;
        
    }
}