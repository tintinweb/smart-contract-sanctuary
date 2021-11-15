pragma solidity ^0.8.6;

contract Modifiers {
    address internal owner;
    address public admin;

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

contract Main is Modifiers {
    uint16 public connectedContracts;  //сколько контрактов создано от Main и как номер 
                                       //созданного контракта в event'e
    event SecondaryCreated(uint16 indexed connectedContracts, address connectedContract);
    
    constructor(address _admin) {
        owner = msg.sender;
        admin = _admin;
        connectedContracts = 0;
        generate();
    }

    //создает Secondary контракты и выпускает событие 
    function generate() public onlyOwnerOrAdmin {
        connectedContracts += 1;
        Secondary secondary = new Secondary(msg.sender, admin, connectedContracts);
        emit SecondaryCreated(connectedContracts, address(secondary)); 
    }
}

contract Secondary is Modifiers {
    uint16 public number;
    mapping(address => uint256) private insuranceCost;

    constructor(address _owner, address _admin, uint16 num) {
        owner = _owner;
        admin = _admin;
        number = num;
    }

    function addInsuranceToDatabase(address client, uint256 cost) public onlyOwnerOrAdmin {
        insuranceCost[client] = cost;
    }

    function getInsuranceCost(address client) public view onlyOwnerOrAdmin returns (uint256) {
        return insuranceCost[client];
    }
}

