interface ERC20 {
    function transfer(address to, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
}

contract Test01 {

  //event Output(uint256 tokens);
  
  address tracker_0x_address = 0xAc1F2ad0599752E7c65Da6E26806b37DAe3b6c42; // Name (SYMBOL) Address
  
  mapping (address => uint256) public balances;
  
  function approve(uint tokens) public {

    // add the deposited tokens into existing balance 
    balances[msg.sender] += tokens;

    // transfer the tokens from the sender to this contract
    // ERC20(tracker_0x_address).transferFrom(msg.sender, address(this), tokens);
    // ERC20(tracker_0x_address).transfer(address(this), tokens);


    // tracker_0x_address is the address of the ERC20 contract they want to deposit tokens from ( ContractA )
    // spender is your deployed escrow contract address

    //ERC20(tracker_0x_address).approve(address(this), tokens);


    //ERC20(tracker_0x_address).transferFrom(msg.sender, address(this), tokens);
    msg.sender.delegatecall(abi.encodeWithSignature("approve(address,uint256)", address(this), tokens));
    //(abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, address(this), tokens));
  }

  function transfer(uint tokens) public {

    ERC20(tracker_0x_address).transferFrom(msg.sender, address(this), tokens);
  }
  
  function returnTokens() public {
    uint256 amount = balances[msg.sender];
    balances[msg.sender] = 0;
    ERC20(tracker_0x_address).transfer(msg.sender, amount);
  }

}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}