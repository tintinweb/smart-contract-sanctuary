contract Test {
    
    function payme() payable public {}
    
    function withdraw() public {
    	payable(msg.sender).transfer(address(this).balance);
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