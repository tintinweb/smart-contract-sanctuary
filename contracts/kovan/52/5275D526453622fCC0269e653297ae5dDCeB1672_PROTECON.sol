/**
 *Submitted for verification at Etherscan.io on 2021-06-28
*/

pragma solidity ^0.8.0;

contract PROTECON {
    
    address DocumentIssuer;
    address DocumentCounterparty;
    address payable provider;
    address public owner;
    bool FinalDecision;
    uint256 PaymentStatus;
    uint256 time;
    uint256 ContractID;
    uint256 fee;
    string ContractKey;
    event ID(string ContractKey);
    
    
    
    
    
    struct Contract {
      uint256 amount;
      address payable issuer;
      address payable counterparty;
      bool signStatus;
      uint256 paymentStatus;
      uint SignDeadline;
      uint ContractDeadline;
      uint BackoutTime;
      address payable judge;
      uint InitiateTime;
      string Title;
      string Key;
    }
    
    struct AddressStruct {
        uint256 ContractsCorrectlyClosed;
        uint256 ContractsErroneouslyClosed;
        uint256 ContractsWonWithJudge;
        uint256 TimesChosenAsJudge;
    }
    struct JudgeIDStruct {
        address payable judge;
        string DocumentIssuer;
        string DocumentCounterparty;
        string FinalDecision;
    }
    constructor(){
        owner=msg.sender;
    }
    
    mapping(string => Contract) public Contracts;
    mapping(address => AddressStruct) public AddressInfo;
    mapping(string => JudgeIDStruct) public JudgeIDInfo;
    mapping(address => string[]) private ContractIDsolved;
    
    
    
    function initiateContract(address payable counterparty, uint256 SignDeadline, uint ContractDeadline, uint BackoutTime, address payable judge, string memory Title, string memory Key) public payable {
        require(judge != owner, "Judge cannot be same as issuer");
        require(ContractDeadline > SignDeadline, "Contract deadline needs to exceed signing time");
        
        
        Contracts[ContractKey] = Contract(
            {
            amount: msg.value,
            issuer: payable(owner),
            counterparty: counterparty,
            signStatus: false,
            paymentStatus: 0,
            SignDeadline: SignDeadline,
            ContractDeadline: ContractDeadline,
            BackoutTime: BackoutTime,
            judge: judge,
            InitiateTime : block.timestamp,
            Title: Title,
            Key: Key
            }
        );
        JudgeIDInfo[ContractKey].judge = judge;
        JudgeIDInfo[ContractKey].FinalDecision = "Empty";
        
        emit ID(ContractKey);
        ContractID += 1;
        ContractKey = string(abi.encodePacked(ContractID, Key));
    }
    
    function signContract(string memory ContractKey) public {
        require(block.timestamp > Contracts[ContractKey].InitiateTime + Contracts[ContractKey].BackoutTime, "Signing not yet available");
        require(block.timestamp < Contracts[ContractKey].InitiateTime + Contracts[ContractKey].SignDeadline ,"Signing time limit exceeded");
        require(msg.sender == Contracts[ContractKey].counterparty, "Un-Authorized access");
        Contracts[ContractKey].signStatus=true;
        AddressInfo[JudgeIDInfo[ContractKey].judge].TimesChosenAsJudge += 1;
        
        
    }
    
    function fulfillContract(string memory ContractKey) public {
        require(msg.sender== Contracts[ContractKey].issuer,"Un-Authorized access");
        require(Contracts[ContractKey].signStatus==true,"Contract yet to be signed");
        Contracts[ContractKey].counterparty.transfer(Contracts[ContractKey].amount);
        Contracts[ContractKey].paymentStatus=2;
        AddressInfo[Contracts[ContractKey].issuer].ContractsCorrectlyClosed +=1 ;
        AddressInfo[Contracts[ContractKey].counterparty].ContractsCorrectlyClosed +=1;
        
 
    }
    
    function Balance(address user) public view returns(uint256 balance){
        return AddressInfo[user].ContractsCorrectlyClosed;
    }
    
    function annulContract(string memory ContractKey) public {
        require(msg.sender == Contracts[ContractKey].counterparty,"Un-Authorized access");
        require(Contracts[ContractKey].signStatus == true, "Contract yet to be signed");
        Contracts[ContractKey].issuer.transfer(Contracts[ContractKey].amount);
        Contracts[ContractKey].paymentStatus = 3;
        AddressInfo[JudgeIDInfo[ContractKey].judge].TimesChosenAsJudge -= 1;
        
    }
    function revokeContract(string memory ContractKey) public {
        require(msg.sender == Contracts[ContractKey].issuer,"Un-Authorized access");
        require(Contracts[ContractKey].signStatus == false, "Contract already signed");
        Contracts[ContractKey].paymentStatus= 1;
        Contracts[ContractKey].issuer.transfer(Contracts[ContractKey].amount);
        
    }
    
    function JudgeDecision(string memory ContractKey, bool decision) public {
        require(msg.sender == JudgeIDInfo[ContractKey].judge, "Un-Authorized access");
        require(block.timestamp > Contracts[ContractKey].InitiateTime + Contracts[ContractKey].ContractDeadline, "Contract still open");
        require(Contracts[ContractKey].paymentStatus == 0, "Contract already closed");
        require(Contracts[ContractKey].signStatus==true, "Contract not signed, Judge not needed");
        if(decision == true) {
            Contracts[ContractKey].counterparty.transfer(Contracts[ContractKey].amount);
            JudgeIDInfo[ContractKey].FinalDecision= "In favor of the counterparty";
            AddressInfo[Contracts[ContractKey].counterparty].ContractsWonWithJudge +=1 ;
            Contracts[ContractKey].paymentStatus=2;
        }
        else {
            Contracts[ContractKey].issuer.transfer(Contracts[ContractKey].amount);
            JudgeIDInfo[ContractKey].FinalDecision= "In favor of the issuer";
            AddressInfo[Contracts[ContractKey].issuer].ContractsWonWithJudge +=1;
            Contracts[ContractKey].paymentStatus=3;
        }
        
        ContractIDsolved[JudgeIDInfo[ContractKey].judge].push(ContractKey);
        AddressInfo[Contracts[ContractKey].issuer].ContractsErroneouslyClosed +=1;
        AddressInfo[Contracts[ContractKey].counterparty].ContractsErroneouslyClosed +=1;
    }
    
    function uploadDocument(string memory ContractKey, string memory DocumentHash) public {
        require(block.timestamp < Contracts[ContractKey].InitiateTime + Contracts[ContractKey].ContractDeadline + 1 weeks, "Uploading deadline exceeded");
        if(msg.sender == Contracts[ContractKey].issuer){
        JudgeIDInfo[ContractKey].DocumentIssuer = DocumentHash;
        }
        else if(msg.sender == Contracts[ContractKey].counterparty){
        JudgeIDInfo[ContractKey].DocumentCounterparty = DocumentHash;
        }
        
    }
    
    
    function JudgeRecord(address _judge) public view returns(string[] memory) {
        return ContractIDsolved[_judge];
    }
    
    function name() public pure returns (string memory){
        return "PROTECOIN";
    }
    function symbol() public pure returns(string memory){
        return "PTC";
        
}
    
}