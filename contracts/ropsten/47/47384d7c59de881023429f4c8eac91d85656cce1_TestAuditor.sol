pragma solidity ^0.4.24;

contract TestAuditor{

    address private AUDITOR;
    
    event eventOWNER(address AUDITOR, address PROPIETARY);
    event eventAddONG(string ong_name, string ong_desc, uint256 date);
    event eventAddONG_AUDIT(string ong, string audit,  string audit_des,  uint256 date);
    
    
    function TestAuditor() {
         AUDITOR = msg.sender;
    }
    
    struct ONG_AUDIT {
        bytes32 id;
        ONG ong;
        string audit;
        string audit_des;
        uint256 date;
        bool activo;
    }
    
    struct ONG {
        bytes32 id;
        string ong_name;
        string ong_desc;
        uint256 date;
        bool activo;
    }
    
    mapping(bytes32 => ONG_AUDIT) private mapaONG_AUDIT;
    mapping(bytes32 => ONG) private mapaONG;
    
    function getONG_AUDIT(bytes32 id)  public view returns ( bytes32 i, string ong, string audit, string audit_des, uint256 date,  bool activo ) {
        return (mapaONG_AUDIT[id].id, mapaONG[id].ong_name, mapaONG_AUDIT[id].audit, mapaONG_AUDIT[id].audit_des, mapaONG_AUDIT[id].date, mapaONG_AUDIT[id].activo);
    }
        
    function getONG(bytes32 id)  public view returns ( bytes32 i, string ong_name, string ong_des, uint256 date,  bool activo ) {
        return (mapaONG[id].id, mapaONG[id].ong_name, mapaONG[id].ong_desc, mapaONG[id].date, mapaONG[id].activo);
    }
    
    function addONG_AUDIT(bytes32 id, string audit,  string audit_des, bool pass_audit)  public onlyOWNER(msg.sender) {
        
        if(mapaONG[id].activo){
            mapaONG_AUDIT[id] = ONG_AUDIT(id, mapaONG[id], audit, audit, block.timestamp, pass_audit);
            emit eventAddONG_AUDIT(mapaONG[id].ong_name, audit, audit_des, block.timestamp);
        }else{
            throw;
        }

    }
    
    function addONG(bytes32 id, string ong_name, string ong_desc)  public onlyOWNER(msg.sender) {
        
        if(!mapaONG[id].activo){
            mapaONG[id] = ONG(id, ong_name, ong_desc, block.timestamp, true);
            emit eventAddONG(ong_name, ong_desc, block.timestamp);
        }else{
            throw;
        }

    }
    
    /*modifier existONG(string ong) {
        require(bytes(ong).length > 0);
        _;
    }*/
    
    modifier onlyOWNER(address OWNER) {
        require(AUDITOR == OWNER);
        emit eventOWNER(AUDITOR, OWNER);
        _;
    }

}