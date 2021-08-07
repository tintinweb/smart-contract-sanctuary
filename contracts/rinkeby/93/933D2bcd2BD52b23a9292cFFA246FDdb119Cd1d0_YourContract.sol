pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

contract YourContract {

  //variables
  address payable public payer; //this is the person giving funds.
  address payable public payee; //this is the person receiving funds.
  bool public payer_approved; //the person giving funds gives consent to transfer funds out of the smart contracts.
  bool public payee_approved; //the person receiving funds gives consent to transfer funds out of the smart contracts.
  bool public payee_set;

  constructor() payable {
    payer = payable(msg.sender);
  }
  
  function setPayee(address payable _payee) public onlyPayer {
      require(!payee_set, "payee is already set");
      payee = _payee;
      payee_set = true;
  }

  modifier onlyPayer() {
    require(msg.sender == payer, "you are not the payer");

    _; //required for every modifier function.
  }

  modifier onlyPayee() {
    require(msg.sender == payee, "you are not the payee");

    _; //required for every modifier function.
  }

  function payerApprovedPayout() public onlyPayer{
      payer_approved = true;
  }

  function payeeApprovedPayout() public onlyPayee{
      payee_approved = true;
  }

  function payout() public {
    if (msg.sender == payer) {
      payPayer();
    }

    if (msg.sender == payee) {
      payPayee();
    }
  }

  function payPayer() internal {
    require(payee_approved, "payee has not approved.");
    payer.transfer(address(this).balance);
  }

  function payPayee() internal {
    require(payer_approved, "payer has not approved.");
    payee.transfer(address(this).balance);
  }
  
  fallback() external payable {}

}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}