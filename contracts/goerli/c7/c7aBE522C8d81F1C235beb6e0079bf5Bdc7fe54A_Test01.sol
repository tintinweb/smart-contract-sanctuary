interface ERC20 {
    function transfer(address to, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
}

contract Test01 {
  
  address tracker_0x_address = 0xAc1F2ad0599752E7c65Da6E26806b37DAe3b6c42; // Name (SYMBOL) Address
  
  mapping (address => uint256) public balances;

  function transfer(uint tokens) public {

    balances[msg.sender] += tokens;

    ERC20(tracker_0x_address).transferFrom(msg.sender, address(this), tokens);
  }
  
  function returnTokens() public {
    uint256 amount = balances[msg.sender];
    balances[msg.sender] = 0;
    ERC20(tracker_0x_address).transfer(msg.sender, amount);
  }

}

