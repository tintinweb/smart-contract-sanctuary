pragma solidity 0.7.3;


contract BatchEth {

    function batchTransfer(
        address[] memory _tos,
        uint256[] memory _amounts
    ) 
        public
        payable
    {
        for (uint256 i = 0; i < _tos.length; i++) {
            address payable currentTo = payable(_tos[i]);
            
            (bool success, ) = currentTo.call{ value: _amounts[i]}("");
            require(
                success,
                "batchTransfer::Transfer Error. Unable to send."
            );
        }
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