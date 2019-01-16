pragma solidity 0.4.24;

interface KyberRelationInterface {
    function getMaster(address _slave) constant external returns (address);
}
interface KyberKYCInterface {
    function isUserExisted(address _userAddr) constant external returns (bool);
    function getUserInfo(address _userAddr) constant external returns (address, string, string);    
}


contract KyberLeave {
    
    KyberKYCInterface public kyberKYCContract;
    KyberRelationInterface public kyberRelationContract;

    mapping (bytes32 => bool) public requestList;    

    address public admin;    

    event LeaveRequest(address indexed slave, address indexed master, uint dateLeaves, string reason, bytes32 proofLeave);
    event ApproveRequest(address indexed master, bytes32 proofLeave);

    // Constructor
    constructor () public {
        admin = msg.sender;
    }

    function requestLeave(uint _dateLeaves, string _reason) public{
        require(kyberKYCContract.isUserExisted(msg.sender));
        address _master = kyberRelationContract.getMaster(msg.sender);
        bytes32 _proofLeave = keccak256(abi.encodePacked(msg.sender, _master, _dateLeaves, _reason, block.number));
        requestList[_proofLeave] = true;
        emit LeaveRequest(msg.sender, _master, _dateLeaves, _reason, _proofLeave);
    }

    function approveLeave(address _slave, uint _dateLeaves, string _reason, uint _blockNumber, bytes32 _proofLeave) public{
         bytes32 _proofBytes = keccak256(abi.encodePacked(_slave, msg.sender, _dateLeaves, _reason, _blockNumber));
        require(_proofBytes == _proofLeave);        
        requestList[_proofLeave] = false;
        emit ApproveRequest(msg.sender, _proofLeave);
    }

    function  isRequestApprove(bytes32 _proofLeave) constant public returns (bool) {
        return requestList[_proofLeave];
    }

    function setKycContract(KyberKYCInterface _kyberKycContract) public {
         require(
            msg.sender == address(admin),
            "Only admin can call this."
        );
        kyberKYCContract = _kyberKycContract;
    }    

    function setRelationContract(KyberRelationInterface _kyberRelativeContract) public {
         require(
            msg.sender == address(admin),
            "Only admin can call this."
        );
        kyberRelationContract = _kyberRelativeContract;
    }    

    function  transferAdmin(address _adminAddr) public {
        require(
            msg.sender == address(admin),
            "Only admin can call this."
        );
        admin = _adminAddr;
    }

}