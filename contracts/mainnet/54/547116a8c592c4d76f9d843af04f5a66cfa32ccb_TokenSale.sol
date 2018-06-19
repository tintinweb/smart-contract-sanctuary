pragma solidity ^0.4.21;

contract ERC20 {
  function balanceOf(address _owner) public constant returns (uint balance);
  function transfer(address _to, uint _value) public returns (bool success);
}

contract TokenSale {
	address public owner;
	address public token = 0xCD8aAC9972dc4Ddc48d700bc0710C0f5223fBCfa;
	uint256 price = 24570000000000;
	event TokenSold(address indexed _buyer, uint256 _tokens);
	modifier onlyOwner() {
      if (msg.sender!=owner) revert();
      _;
    }
    
    function TokenSale() public {
        owner = msg.sender;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
    
    function setPrice(uint256 newPrice) public onlyOwner {
        if (newPrice<=0) revert();
        price = newPrice;
    }
    
    function withdrawTokens(address tadr, uint256 tkn) public onlyOwner  {
        if (tkn<=0 || ERC20(tadr).balanceOf(address(this))<tkn) revert();
        ERC20(tadr).transfer(owner, tkn);
    }
    
    function () payable public {
        if (msg.value<=0) revert();
        uint256 tokens = msg.value/price;
        uint256 max = ERC20(token).balanceOf(address(this));
        if (tokens>max) {
            tokens = max;
            msg.sender.transfer(msg.value-max*price);
        }
        ERC20(token).transfer(msg.sender, tokens);
        emit TokenSold(msg.sender,tokens);
        owner.transfer(address(this).balance);
    }
}