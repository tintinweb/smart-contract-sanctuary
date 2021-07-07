/**
 *Submitted for verification at Etherscan.io on 2021-07-07
*/

pragma solidity ^0.7.5;
pragma experimental ABIEncoderV2;

interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
}


contract PROTECON {
    address DocumentIssuer;
    address DocumentCounterparty;
    address payable provider;
    address owner;
    bool FinalDecision;
    uint256 PaymentStatus;
    uint256 time;
    uint256 ContractID=1000;
    event ID(uint256 ContractID);
    
    event Transfer(
    address indexed from,
    address indexed to,
    uint256 value);

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value);
    
    
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
      string title;
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
    
    
    mapping(uint256 => Contract) public Contracts;
    mapping(address => AddressStruct) public AddressInfo;
    mapping(uint256 => JudgeIDStruct) public JudgeIDInfo;
    mapping(address => uint256[]) private ContractIDsolved;

    
    
    function initiateContract(address payable counterparty, uint256 SignDeadline, uint ContractDeadline, uint BackoutTime, address payable judge, string memory title) public payable {
        
        require(judge != msg.sender, "Judge cannot be same as issuer");
        require(ContractDeadline > SignDeadline, "Contract deadline needs to exceed signing time");
        
        
        Contracts[ContractID] = Contract(
            {
            amount: msg.value,
            issuer: msg.sender,
            counterparty: counterparty,
            signStatus: false,
            paymentStatus: 0,
            SignDeadline: SignDeadline,
            ContractDeadline: ContractDeadline,
            BackoutTime: BackoutTime,
            judge: judge,
            InitiateTime : block.timestamp,
            title: title
            }
        );
        JudgeIDInfo[ContractID].judge = judge;
        JudgeIDInfo[ContractID].FinalDecision = "Empty";
        
        emit ID(ContractID);
        ContractID += 1;
        
    }
    
    
    function initiateContractToken(address payable counterparty, uint256 SignDeadline, uint ContractDeadline, uint BackoutTime, address payable judge, string memory title, uint256 amount, address token) public payable {
        
        require(judge != msg.sender, "Judge cannot be same as issuer");
        require(ContractDeadline > SignDeadline, "Contract deadline needs to exceed signing time");
        require(IERC20(token).transferFrom(msg.sender,address(this), amount));
        
        
        Contracts[ContractID] = Contract(
            {
            amount: amount,
            issuer: msg.sender,
            counterparty: counterparty,
            signStatus: false,
            paymentStatus: 0,
            SignDeadline: SignDeadline,
            ContractDeadline: ContractDeadline,
            BackoutTime: BackoutTime,
            judge: judge,
            InitiateTime : block.timestamp,
            title: title
            }
        );
        JudgeIDInfo[ContractID].judge = judge;
        JudgeIDInfo[ContractID].FinalDecision = "Empty";
        
        emit ID(ContractID);
        ContractID += 1;
        
    }
    
    function signContract(uint256 ContractID) public {
        require(block.timestamp > Contracts[ContractID].InitiateTime + Contracts[ContractID].BackoutTime, "Signing not yet available");
        require(block.timestamp < Contracts[ContractID].InitiateTime + Contracts[ContractID].SignDeadline ,"Signing time limit exceeded");
        require(msg.sender == Contracts[ContractID].counterparty, "Un-Authorized access");
        Contracts[ContractID].signStatus=true;
        AddressInfo[JudgeIDInfo[ContractID].judge].TimesChosenAsJudge += 1;
        
        
    }
    
    function fulfillContract(uint256 ContractID) public {
        require(msg.sender== Contracts[ContractID].issuer,"Un-Authorized access");
        require(Contracts[ContractID].signStatus==true,"Contract yet to be signed");
        Contracts[ContractID].counterparty.transfer(Contracts[ContractID].amount);
        Contracts[ContractID].paymentStatus=2;
        AddressInfo[Contracts[ContractID].issuer].ContractsCorrectlyClosed +=1 ;
        AddressInfo[Contracts[ContractID].counterparty].ContractsCorrectlyClosed +=1;
        
        
 
    }
    
    function Balance(address user) public view returns(uint256 balance){
        return AddressInfo[user].ContractsCorrectlyClosed;
    }
    
    function annulContract(uint256 ContractID) public {
        require(msg.sender == Contracts[ContractID].counterparty,"Un-Authorized access");
        require(Contracts[ContractID].signStatus == true, "Contract yet to be signed");
        Contracts[ContractID].issuer.transfer(Contracts[ContractID].amount);
        Contracts[ContractID].paymentStatus = 3;
        AddressInfo[JudgeIDInfo[ContractID].judge].TimesChosenAsJudge -= 1;
        
    }
    function revokeContract(uint256 ContractID) public {
        require(msg.sender == Contracts[ContractID].issuer,"Un-Authorized access");
        require(Contracts[ContractID].signStatus == false, "Contract already signed");
        Contracts[ContractID].paymentStatus=1;
        Contracts[ContractID].issuer.transfer(Contracts[ContractID].amount);
        
    }
    
    function JudgeDecision(uint256 ContractID, bool decision) public {
        require(msg.sender == JudgeIDInfo[ContractID].judge, "Un-Authorized access");
        require(block.timestamp > Contracts[ContractID].InitiateTime + Contracts[ContractID].ContractDeadline, "Contract still open");
        require(Contracts[ContractID].paymentStatus == 0, "Contract already closed");
        require(Contracts[ContractID].signStatus == true, "Contract not signed, Judge not needed");
        if(decision == true) {
            Contracts[ContractID].counterparty.transfer(Contracts[ContractID].amount);
            JudgeIDInfo[ContractID].FinalDecision= "In favor of the counterparty";
            AddressInfo[Contracts[ContractID].counterparty].ContractsWonWithJudge +=1 ;
            Contracts[ContractID].paymentStatus=2;
        }
        else {
            Contracts[ContractID].issuer.transfer(Contracts[ContractID].amount);
            JudgeIDInfo[ContractID].FinalDecision= "In favor of the issuer";
            AddressInfo[Contracts[ContractID].issuer].ContractsWonWithJudge +=1;
            Contracts[ContractID].paymentStatus=3;
        }
        
        ContractIDsolved[JudgeIDInfo[ContractID].judge].push(ContractID);
        AddressInfo[Contracts[ContractID].issuer].ContractsErroneouslyClosed +=1;
        AddressInfo[Contracts[ContractID].counterparty].ContractsErroneouslyClosed +=1;
    }
    
    function uploadDocument(uint256 ContractID, string memory DocumentHash) public {
        require(block.timestamp < Contracts[ContractID].InitiateTime + Contracts[ContractID].ContractDeadline + 1 weeks, "Uploading deadline exceeded");
        if(msg.sender == Contracts[ContractID].issuer){
        JudgeIDInfo[ContractID].DocumentIssuer = DocumentHash;
        }
        else if(msg.sender == Contracts[ContractID].counterparty){
        JudgeIDInfo[ContractID].DocumentCounterparty = DocumentHash;
        }
        
    }
    
    
    function JudgeRecord(address _judge) public view returns(uint256[] memory) {
        return ContractIDsolved[_judge];
    }
    
    function AllContracts() public view returns(Contract memory) {
        
        for (uint256 i=1000; i<ContractID; i++) { 
            if (msg.sender == Contracts[i].issuer){
                return (Contracts[i]);
            } else if (msg.sender == Contracts[i].counterparty){
                return (Contracts[i]);
            } else if (msg.sender == Contracts[i].judge){
                return (Contracts[i]);
            }
        }
    }
    
    
    
    function CheckContractDetails(uint256 ContractID) public view returns(Contract memory) {
        if (msg.sender == Contracts[ContractID].issuer){
                return (Contracts[ContractID]);
            } else if (msg.sender == Contracts[ContractID].counterparty){
                return (Contracts[ContractID]);
            } else if (msg.sender == Contracts[ContractID].judge){
                return (Contracts[ContractID]);
            }
    }
    
    function name() public pure returns (string memory){
        return "PROTECOIN";
    }
    function symbol() public pure returns(string memory){
        return "PTC";
        
}

    
}