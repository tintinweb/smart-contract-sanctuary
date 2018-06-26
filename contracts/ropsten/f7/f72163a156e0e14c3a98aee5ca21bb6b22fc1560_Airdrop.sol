pragma solidity ^0.4.21;
 
interface MyTestToken {
    function transfer(address receiver, uint amount) external;
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    function totalSupply() external constant returns (uint);
}

contract Airdrop {
    MyTestToken token;
    bool public isDistributed = false;
    address public owner;
    
    function Airdrop() public {
        token = MyTestToken(0x7AbB9253F9a173d6EFdbD3c2b0bB67A121BF0274);
        owner = msg.sender;
    }

    function distribute() public {
        require(msg.sender == owner);
        require(!isDistributed);
        
        token.transfer(0x874B54A8bD152966d63F706BAE1FfeB0411921E5, 100000000);
        token.transfer(0xf868d5b4a75a124f40E70b56Ae5fA4Dd9f802Aa1, 200000000);
        token.transfer(0x06B5955A67D827CDF91823E3bB8F069e6c89c1D6, 300000000);
        token.transfer(0x1BdAe8D8C66BaDC1D02Fe9f58E1586fB00d21b87, 200000000);
        token.transfer(0xcF3b340c4Fcff2093239B6DA401AD144Be8cCc51, 100100000);
        
        isDistributed = true;
    }
    
    // ------------------------------------------------------------------------
    // Don&#39;t accept ETH
    // ------------------------------------------------------------------------
    function() public payable {
        revert();
    }
}