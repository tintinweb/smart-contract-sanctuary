pragma solidity ^0.8.6;

contract Modifier1 {
    address internal owner;
    address public admin;
    uint16 public contractsNumber; 
    //адреса будут по умолчанию, тк конструктор выполняется до главного
    event SecondConstructor(uint16 contractsNumber, address owner, address admin);
    
    constructor(uint16 _contractsNumber) { 
        contractsNumber = _contractsNumber;
        emit SecondConstructor(contractsNumber, owner, admin);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "You aren't allowed to call this function.");
        _;
    }
   
    modifier onlyOwnerOrAdmin {
        require(msg.sender == owner || msg.sender == admin,
        "You aren't allowed to call this function.");
        _;
    }

    function changeAdmin(address _admin) public onlyOwner {
        admin = _admin;
    }
}


contract Modifier2 {
    event FirstConstructor(uint8 executedConstructors);
    
    constructor(uint8 _executedConstructors) {
        emit FirstConstructor(_executedConstructors);
    }
}


//Конструкторы выполняются в следующей последовательности: Modifier2, Modifier1, Complex.
//реализовала 2 способа вызова конструктора связанных контрактов
contract Complex is Modifier2(1), Modifier1 {
    mapping(address => uint256) private insuranceCost;
    event ThirdConstructor(uint16 contractsNumber, address owner, address admin);

    constructor(address _owner, address _admin, uint16 numberOfPreviousContracts) 
        Modifier1 (numberOfPreviousContracts + 2) 
    {
        owner = _owner;
        admin = _admin;
        contractsNumber += 1;     
        emit ThirdConstructor(contractsNumber, owner, admin);
    }

    function addInsuranceToDatabase(address client, uint256 cost) public onlyOwnerOrAdmin {
        insuranceCost[client] = cost;
    }

    function getInsuranceCost(address client) public view onlyOwnerOrAdmin returns (uint256) {
        return insuranceCost[client];
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
  }
}