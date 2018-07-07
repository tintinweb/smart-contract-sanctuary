pragma solidity 0.4.24;

// Basic ICO for ERC20 tokens

interface iERC20 {
    function totalSupply() external constant returns (uint256 supply);
    function balanceOf(address owner) external constant returns (uint256 balance);    
    function transfer(address to, uint tokens) external returns (bool success);
}

contract MeerkatICO {
    iERC20 token;
    address owner;
    address tokenCo;
    uint rateMe;
    
    modifier ownerOnly() {
        require(msg.sender == owner);
        _;
    }

   constructor(address mainToken) public {
        token = iERC20(mainToken);
        tokenCo = mainToken;
        owner = msg.sender;
        rateMe = 0;
    }

    function withdrawETH() public ownerOnly {
        owner.transfer(address(this).balance);
    }

    function setRate(uint _rateMe) public ownerOnly {
        rateMe = _rateMe;
    }
    
    function CurrentRate() public constant returns (uint rate) {
        return rateMe;
    }
    
    function TokenLinked() public constant returns (address _token, uint _amountLeft) {
        return (tokenCo, (token.balanceOf(address(this)) / 10**18)) ;
    }
    
    function transferAnyERC20Token(address tokenAddress, uint tokens) public ownerOnly returns (bool success) {
        return iERC20(tokenAddress).transfer(owner, tokens);
    }

    function () public payable {
        require( (msg.value >= 100000000000000000) && (rateMe != 0) );
        
        uint value = msg.value * rateMe;

        require(value/msg.value == rateMe);
        
        token.transfer(msg.sender, value);
        
    }
}