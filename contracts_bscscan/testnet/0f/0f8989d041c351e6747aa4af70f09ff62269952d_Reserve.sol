/**
 *Submitted for verification at BscScan.com on 2022-01-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ERC20 {
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool); 
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
}

interface AdminRouter {
    function isManager(address account) external view returns(bool);
    function isContract(address account) external view returns(bool);
    function isSuperManager(address account) external view returns(bool);
}

interface Policy_Interface{
    function isBuy(address user,address CU) external view returns (bool);
    function MaxCoverofUser(address user,address CU) external view returns(uint256);
    function isBlacklistUser(address user) external view returns(bool);
    function isBlacklistAssetsofUser(address user,address CU) external view returns(bool);
    function DataofPolicy(string memory PolicyId) external view returns(address who,
        address CU,
        string memory policyId,
        uint256 startdate,
        uint256 untildate,
        bool isActive);
    function GetPolicyId(address user,address CU) external view returns(string memory PolicyId);
}

interface NameRegistry_Interface {
    function Control() external view returns (address);
    function Policy() external view returns (address);
    function CA() external view returns (address);
}

interface ClaimAssessors_Interface {
    function isClaimAssessors(address user) external view returns(bool);
    function AllCA() external view returns(address[] memory);
    function CountCA() external view returns(uint256);
}

contract Reserve {
    
    event In_Event(address CU, address from, uint256 value);
    event Out_Event(address CU,address from,uint256 value);
    event Withdraw_Event(address CU,address to, uint256 value,uint256 remain);
    event ClaimRequest_Event(address CU,uint256 valueforrequest,uint256 timeout,Status Status);
    event PercentagePassChange_Event(uint256 before_value,uint256 after_value);
    event ClaimRequest1st_Event(address CU,uint256 valueforrequest,bool _bool,uint256 valueforapprove,uint256 timeout,Status Status);
    event CA_Proposal_Event(address CU,uint256 caseid,bool _bool);
    event Finalize_Event(address CU,uint256 caseid,Status Status);

    mapping(address => mapping(address => uint256)) internal HistoryValueOfUser;
    mapping(address => mapping(string => uint256)) internal balanceoftypes;
    mapping(address => mapping(address => uint256)) internal HistoryofRequest;
    mapping(address => mapping(address => uint256)) internal PendingRequest;
    mapping(address => mapping(address => uint256)) internal CountofRequest;
    mapping(address => mapping(uint256 => address)) internal caseidforwho;
    mapping(address => mapping(uint256 => uint256)) internal caseidtimeout;
    mapping(address => mapping(uint256 => uint256)) internal caseidrequestamount;
    mapping(address => mapping(uint256 => uint256)) internal caseidapproveamount;
    mapping(address => mapping(uint256 => address)) internal caseid1stchecker;
    mapping(address => mapping(uint256 => bool)) internal caseid1stcheckerbool;
    mapping(address => mapping(uint256 => uint256)) internal caseidcasnapshotcount;
    mapping(address => mapping(uint256 => uint256)) internal caseidcasnapshotvotecount;
     struct snapcaforapprove {
        bool haveaccess; // มีสิทธิ์ป่าว
        bool alreadyvote; // โหวตไปยัง
    }

    enum Status {
        Pending,
        Voting,
        Accepted,
        Rejected,
        Canceled
    }

    mapping(address => mapping(uint256 => mapping(address => snapcaforapprove))) internal caseidcasnapshotaddress;
    mapping(address => mapping(uint256 => Status)) internal _caseidstatus;
    mapping(address => mapping(uint256 => uint256)) internal caseidvoting;

    uint256 public CountCaseforRequest;
    uint256 public PercentagewillPasswhenRequest;

    address internal Nameregis;

    constructor(address _regis,uint256 percentage) {
        require(percentage > 0 && percentage <= 100,"Invaild Percentage");
        Nameregis = _regis;
        PercentagewillPasswhenRequest = percentage;

        emit PercentagePassChange_Event(0,percentage);
    }



    modifier Contract {
         require(AdminRouter(NameRegistry_Interface(Nameregis).Control()).isContract(msg.sender),"AdminRouter: You aren't Bpolicy.");
        _;
    }

    modifier ThisContract{
        require(msg.sender == address(this) ,"Your aren't ContractReserve.");
        _;
    }

    modifier SuperManager {
        require(AdminRouter(NameRegistry_Interface(Nameregis).Control()).isSuperManager(msg.sender), "You're not Super Manager.");
        _;
    }

    modifier ForFinalize {
        require(msg.sender == address(this) || AdminRouter(NameRegistry_Interface(Nameregis).Control()).isManager(msg.sender), "You are not Contract Reserve or You not have access for Manager.");
        _;
    }

    modifier isCA {
        require(ClaimAssessors_Interface(NameRegistry_Interface(Nameregis).CA()).isClaimAssessors(msg.sender), "You're not ClaimAssessors.");
        _;
    }

    function In(address CU, address from, uint256 value) public Contract { // only Policy can Manage // 
      PendingRequest[CU][from] = 0;
      HistoryofRequest[CU][from] = 0;
      HistoryValueOfUser[CU][from] = value;

      emit In_Event(CU, from, value);
    }

    function Out(address CU,address from,uint256 value) public Contract { // only Policy can Manage // // Type ยังไ่ม่ต้องโอนเงินไปเฉยๆ รวมเป็นก้อนเดียว //
        require(ERC20(CU).balanceOf(address(this)) >= value,"Balance of Contract Not Enough.");
        require(HistoryValueOfUser[CU][from] >= value,"Balance Not Enough.");
        require(PendingRequest[CU][msg.sender] == 0,"You are on PendingRequest.");
        HistoryValueOfUser[CU][from] = 0;
        HistoryofRequest[CU][msg.sender] = 0;
        PendingRequest[CU][msg.sender] = 0;

        ERC20(CU).transfer(from,value); // Payment

        emit Out_Event(CU,from,value);
    }

    function Withdraw(address CU,address to,uint256 value) public SuperManager {
        require(ERC20(CU).balanceOf(address(this)) >= value,"Balance Not Enough.");

        ERC20(CU).transfer(to,value); // Payment

        emit Withdraw_Event(CU,to,value,ERC20(CU).balanceOf(address(this)));
    }

    function policyClaimRequest(address CU, uint256 value) public { //คิดไวก่อน//
        require(Policy_Interface(NameRegistry_Interface(Nameregis).Policy()).isBuy(msg.sender,CU) == true,"You aren't buy");
        require(PendingRequest[CU][msg.sender] == 0,"You are on Pending please wait for the lasted Pending Request.");
        require(Policy_Interface(NameRegistry_Interface(Nameregis).Policy()).MaxCoverofUser(msg.sender,CU) > 0 ,"You Doesn't Buy Policy.");
        require(Policy_Interface(NameRegistry_Interface(Nameregis).Policy()).isBlacklistUser(msg.sender) != true,"Policy: This user are Blacklist.");
        require(Policy_Interface(NameRegistry_Interface(Nameregis).Policy()).isBlacklistAssetsofUser(msg.sender,CU) != true,"Policy: This Assets of you are Blacklist.");
        require(Policy_Interface(NameRegistry_Interface(Nameregis).Policy()).MaxCoverofUser(msg.sender,CU) - HistoryofRequest[CU][msg.sender] > 0,"Your Amount Request have a limit.");
        require(Policy_Interface(NameRegistry_Interface(Nameregis).Policy()).MaxCoverofUser(msg.sender,CU) - HistoryofRequest[CU][msg.sender] >= value,"Now you have a max for request.");
        require(Policy_Interface(NameRegistry_Interface(Nameregis).Policy()).MaxCoverofUser(msg.sender,CU) - HistoryofRequest[CU][msg.sender] - PendingRequest[CU][msg.sender] >= value,"PendingRequest: ERROR.");
        (,,,,,bool Policyisactive) =  Policy_Interface(NameRegistry_Interface(Nameregis).Policy()).DataofPolicy(Policy_Interface(NameRegistry_Interface(Nameregis).Policy()).GetPolicyId(msg.sender,CU));
        require(Policyisactive == true,"Policy: Your Policy is not active this moment.");
        PendingRequest[CU][msg.sender] += value;
        uint256 caseid = CountCaseforRequest + 1; 
        CountCaseforRequest += 1;
        caseidforwho[CU][caseid] = msg.sender;
        caseidtimeout[CU][caseid] = block.timestamp + (60*60*24*1);
        caseidrequestamount[CU][caseid] = value;
        _caseidstatus[CU][caseid] = Status.Pending;


        emit ClaimRequest_Event(CU,value,caseidtimeout[CU][caseid],_caseidstatus[CU][caseid]);
    }

    function CA_1st(address CU,uint256 caseid,bool _bool,uint256 valueapprove) public isCA {
        require(_caseidstatus[CU][caseid] == Status.Pending,"Status: it not Pending...");
        require(caseidforwho[CU][caseid] != msg.sender,"You can't access your caseid.");
        require(caseidrequestamount[CU][caseid] >= valueapprove,"You can't approve value more than user request.");
        (,,,,,bool Policyisactive) =  Policy_Interface(NameRegistry_Interface(Nameregis).Policy()).DataofPolicy(Policy_Interface(NameRegistry_Interface(Nameregis).Policy()).GetPolicyId( caseidforwho[CU][caseid],CU));
        require(Policyisactive == true,"Policy: Your Policy is not active this moment.");
        caseid1stchecker[CU][caseid] = msg.sender;
        caseid1stcheckerbool[CU][caseid] = _bool;
        caseidapproveamount[CU][caseid] = valueapprove;
        caseidtimeout[CU][caseid] += (60*60*24); //บวก 1 วัน
        caseidcasnapshotcount[CU][caseid] = ClaimAssessors_Interface(NameRegistry_Interface(Nameregis).CA()).CountCA();
       
        address[] memory allareca = ClaimAssessors_Interface(NameRegistry_Interface(Nameregis).CA()).AllCA();
     
        for (uint256 i = 0; i < allareca.length; i++) {

            if(allareca[i] == msg.sender) {
                caseidcasnapshotaddress[CU][caseid][allareca[i]].haveaccess = true;
                caseidcasnapshotaddress[CU][caseid][allareca[i]].alreadyvote = true;
            }else {
                caseidcasnapshotaddress[CU][caseid][allareca[i]].haveaccess = true;
                caseidcasnapshotaddress[CU][caseid][allareca[i]].alreadyvote = false;
            }
        }


        if(_bool = true) {
            caseidvoting[CU][caseid] += 1;
        }else{
            caseidvoting[CU][caseid] -= 1;
        }

        caseidcasnapshotvotecount[CU][caseid] += 1;
        _caseidstatus[CU][caseid] = Status.Voting;
  
        emit ClaimRequest1st_Event(CU,caseidrequestamount[CU][caseid],_bool,valueapprove,caseidtimeout[CU][caseid],_caseidstatus[CU][caseid]);
    }
    
    function CA_Proposal(address CU,uint256 caseid,bool _bool) public isCA {
        require(_caseidstatus[CU][caseid] == Status.Voting,"Status: it not Going...");
        require(caseidtimeout[CU][caseid] >= block.timestamp,"This proposal it was timeout.");
        require(caseidcasnapshotaddress[CU][caseid][msg.sender].haveaccess == true,"You not have access for this proposal.");
        require(caseidcasnapshotaddress[CU][caseid][msg.sender].alreadyvote == false,"You already vote for this proposal.");
        (,,,,,bool Policyisactive) =  Policy_Interface(NameRegistry_Interface(Nameregis).Policy()).DataofPolicy(Policy_Interface(NameRegistry_Interface(Nameregis).Policy()).GetPolicyId( caseidforwho[CU][caseid],CU));
        require(Policyisactive == true,"Policy: Your Policy is not active this moment.");

        if(_bool = true) {
            caseidvoting[CU][caseid] += 1;
            caseidcasnapshotaddress[CU][caseid][msg.sender].alreadyvote = true;
        }else{
            caseidvoting[CU][caseid] -= 1;
            caseidcasnapshotaddress[CU][caseid][msg.sender].alreadyvote = true;
        }

        caseidcasnapshotvotecount[CU][caseid] += 1;

        emit CA_Proposal_Event(CU,caseid,_bool);

        if(caseidcasnapshotvotecount[CU][caseid] == caseidcasnapshotcount[CU][caseid]) { // vote ทุกคนแล้ว
            Finalize(CU,caseid);
        }
    }

    function ChangePassPercentage(uint256 percent) public SuperManager{
        require(percent > 0 && percent <= 100,"Invaild Percentage.");
        uint256 before = PercentagewillPasswhenRequest;
        PercentagewillPasswhenRequest = percent;

        emit PercentagePassChange_Event(before,percent);
    }

    function User_Cancel(address CU,uint caseid) public {
        require(caseidforwho[CU][caseid] == msg.sender,"Reserve: You are not owner of this case id.");
        require(_caseidstatus[CU][caseid] == Status.Pending,"Can't Cancel this case id.");
        require(caseidtimeout[CU][caseid] >= block.timestamp,"case id was closed.");
        PendingRequest[CU][msg.sender] -= caseidrequestamount[CU][caseid];
        _caseidstatus[CU][caseid] = Status.Canceled;
    }
 
    function Finalize(address CU,uint256 caseid) public ForFinalize {
        require(_caseidstatus[CU][caseid] == Status.Voting,"Status: it not Voting...");
        (,,,,,bool Policyisactive) =  Policy_Interface(NameRegistry_Interface(Nameregis).Policy()).DataofPolicy(Policy_Interface(NameRegistry_Interface(Nameregis).Policy()).GetPolicyId( caseidforwho[CU][caseid],CU));
        require(Policyisactive == true,"Policy: Your Policy is not active this moment.");
        uint256 pass = caseidcasnapshotcount[CU][caseid]*PercentagewillPasswhenRequest/100;

        if(caseidvoting[CU][caseid] >= pass){ // pass
            ERC20(CU).transfer(caseidforwho[CU][caseid],caseidapproveamount[CU][caseid]);
            _caseidstatus[CU][caseid] = Status.Accepted;
            HistoryofRequest[CU][msg.sender] += caseidapproveamount[CU][caseid];
        }else{
            _caseidstatus[CU][caseid] = Status.Rejected;
        }

        PendingRequest[CU][caseidforwho[CU][caseid]] = 0;

        emit Finalize_Event(CU,caseid,_caseidstatus[CU][caseid]);
    }

    function caseidstatus(address CU,uint256 caseid) public view returns(Status) {
        return _caseidstatus[CU][caseid];
    }

}