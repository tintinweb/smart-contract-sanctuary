/**
 *Submitted for verification at Etherscan.io on 2021-07-25
*/

pragma solidity >=0.7.0 <0.9.0;


contract Supertask {
    
    address payable constant private creator = payable(0x92Bf51aB8C48B93a96F8dde8dF07A1504aA393fD);
    address payable private admin;
    bool initiated;
    uint fee;
    uint volume;
    address [] NewContracts;
    address [] ContractWriter;
    bool frozen;
    
    
    event Initialised(uint timestamp);
    
    event FeeSet(uint Fee, uint timestamp);
    
    event ContractCreation(address user, uint Fee, uint index, uint timestamp);
    
    event NewAdminAddress(address Admin, uint timestamp);
    
    event ContractFrozen(uint timestamp);
    
    event ContractUnfreeze(uint timestamp);
    
    event ContractInfo(address Admin, uint Fee, uint Volume, address [] contracts, address [] users, uint index, bool Frozen, uint timestamp);
    
    
    function Initialise(uint Fee) private {
        require(initiated == false, "The contract have been initiated.");
        require(msg.sender == creator, "You do not have the required authority!");
        admin = creator;
        fee = Fee;
        volume = 0;
        emit Initialised(block.timestamp);
        emit FeeSet(Fee, block.timestamp);
    }
    
    function CreateContract() public payable {
        require(initiated == true, "The contract have not been initaited yet.");
        require(frozen == false, "This contract is currently unavaliable, sorry for the inconvenience.");
        require(msg.value >= fee, "Payment not sufficient to cover the fees.");
        admin.transfer(msg.value);
        volume += msg.value;
        address newContract = address(new Contract(msg.sender));
        NewContracts.push(newContract);
        ContractWriter.push(msg.sender);
        emit ContractCreation(msg.sender, msg.value, NewContracts.length, block.timestamp);
    }
    
    function SetFee(uint Fee) private {
        require(initiated == true, "The contract have not been initaited yet.");
        require(msg.sender == admin, "You do not have the required authority!");
        fee = Fee;
        emit FeeSet(Fee, block.timestamp);
    }
    
    function SetAdminAddress(address payable NewAddress) private {
        require(initiated == true, "The contract have not been initaited yet.");
        require(msg.sender == admin, "You do not have the required authority!");
        admin = NewAddress;
        emit NewAdminAddress(NewAddress, block.timestamp);
    }
    
    function FreezeContract() private {
        require(initiated == true, "The contract have not been initaited yet.");
        require(msg.sender == admin, "You do not have the required authority!");
        require(frozen == false, "The contract is already frozen.");
        frozen = true;
        emit ContractFrozen(block.timestamp);
    }
    
    function UnfreezeContract() private {
        require(initiated == true, "The contract have not been initaited yet.");
        require(msg.sender == admin, "You do not have the required authority!");
        require(frozen == true, "The contract is not frozen.");
        frozen = false;
        emit ContractUnfreeze(block.timestamp);
    }
    
    function GetContractInfo() public {
        require(initiated == true, "The contract have not been initaited yet.");
        emit ContractInfo(admin, fee, volume, NewContracts, ContractWriter, NewContracts.length, frozen, block.timestamp);
    }
    
}


contract Contract {

    address [] stakeholders;
    address contractWriter;
    uint index;
    uint chainLength;
    bool initiated;
    bool dispatched;
    bool arrived;
    bool received;
    
    
    event ContractCreation(address user);
    
    event Dispatched(address user, bytes32 memo, uint timestamp);
    
    event Arrived(address user, bytes32 memo, uint timestamp);
    
    event Received(address user, bytes32 memo, uint timestamp);
    
    //event Confirmed(address appointer, address node, uint timestamp);
    
    //event Appointed(address user, address appointee, uint timestamp);
    
    event ChainEstablished(address [] users, uint ChainLength, uint timestamp);
    
    
    constructor(address ContractWriter) {
        stakeholders.push(ContractWriter);
        contractWriter = ContractWriter;
        index = 0;
        emit ContractCreation(ContractWriter);
    }
    
    function Dispatching(bytes32 Memo) public {
        require(initiated == true, "The chain has not been established yet.");
        require(received == true, "You do not have the good.");
        require(msg.sender == stakeholders[index], "You do not have the required authority.");
        require(index + 1 <= chainLength, "You have no one to dispatch the good to.");
        require(dispatched == false, "The good have been dispatched.");
        dispatched = true;
        received = false;
        emit Dispatched(msg.sender, Memo, block.timestamp);
    }
    
    function Arrival(bytes32 Memo) public {
        require(initiated == true, "The chain has not been established yet.");
        require(dispatched == true, "The good have not been dispatched yet.");
        require(msg.sender == stakeholders[index], "You do not have the required authority.");
        require(arrived == false,"The arrival of the good have been claimed already.");
        dispatched = false;
        arrived = true;
        emit Arrived(msg.sender, Memo, block.timestamp);
    }
    
    function Confirmation(bytes32 Memo) public {
        require(initiated == true, "The chain has not been established yet.");
        require(arrived == true, "The good have not arrived yet.");
        require(msg.sender == stakeholders[index + 1], "You do not have the required authority.");
        require(received == false, "You have already received the good.");
        arrived = false;
        received = true;
        if (index + 1 <= chainLength){
            index += 1;
        } else {
            index = 0;
        }
        emit Received(msg.sender, Memo, block.timestamp);
    }
    
    function AcceptAndAppoint(address Node) public {
        require(initiated == false, "The chain have been established.");
        require(msg.sender == stakeholders[index], "You do not have the required authority.");
        if (Node != contractWriter) {
            stakeholders.push(Node);
            index += 1;
        } else {
            initiated = true;
            received = true;
            chainLength = index + 1;
            index = 0;
            emit ChainEstablished(stakeholders, chainLength, block.timestamp);
        }
    }
}