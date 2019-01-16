// Version 20.12.2018 V2

pragma solidity ^0.5.1;

contract ecert
{
    address superadmin;
    address admin;
    address user;

    struct Diploma
    {
        uint256 hash1;
        uint256 hash2;
        mapping(uint => Entry) entries;
        uint numberEntries;
    }

    enum Status { Fail, Valid, RevokeError, RevokeReplace, RevokeFraud, RevokeNoReason}
    mapping(uint24 => string) statusString;
    
    

    struct Entry
    {
        uint256 date;
        address origin;
        Status status;
    }
    
    mapping(uint256=>uint24) hashes;
    Diploma[] diplomas;
    
    modifier onlySuper()
    {
        if(!(msg.sender==superadmin)){emit ErrorMessage(&#39;Function reserved to Superadmin&#39;); return;}
        _;
    }
    
    modifier onlyAdmin()
    {
        if(!(admin!=address(0))){emit ErrorMessage(&#39;Function reserved to Admin but no Admin set&#39;); return;}
        if(!(msg.sender==admin)){emit ErrorMessage(&#39;Function reserved to Admin&#39;); return;}
        _;
    }
    
    modifier onlyUser()
    {
        if(!(admin!=address(0) || user!=address(0))){emit ErrorMessage(&#39;Function reserved to User or Admin but none is set&#39;); return;}
        if(!(msg.sender==admin || msg.sender==user)){emit ErrorMessage(&#39;Function reserved to User or Admin&#39;); return;}
        _;
    }
    
    constructor() public{
        superadmin=msg.sender;
        statusString[uint24(Status.Fail)]="Fail";
        statusString[uint24(Status.Valid)]="Valid";
        statusString[uint24(Status.RevokeError)]="RevokeError";
        statusString[uint24(Status.RevokeReplace)]="RevokeReplace";
        statusString[uint24(Status.RevokeFraud)]="RevokeFraud";
        statusString[uint24(Status.RevokeNoReason)]="RevokeNoReason";
    }

    event ErrorMessage(string message);

    
    function setAdmin(address _admin) onlySuper() external{
        admin=_admin;
    }
    
    function setUser(address _user) onlySuper() external {
        user=_user;
    }


    function addDiploma(uint256 _hash1,uint256 _hash2, Status _status) onlyUser() external
    {
        if(!(hashes[_hash1]==0)){emit ErrorMessage(&#39;hash1 already exists&#39;); return;}
        if(!(_hash2==0 || hashes[_hash2]==0)){emit ErrorMessage(&#39;hash2 already exists&#39;); return;}
        if(!(_hash1!=_hash2)){emit ErrorMessage(&#39;hash1 and hash2 need to be different. If only one hash leave hash2=0&#39;); return;}
        Diploma memory diploma = Diploma({hash1: _hash1, hash2: _hash2,numberEntries: 0});
        uint24 diplomaNr=uint24(diplomas.push(diploma));
        diplomas[diplomaNr-1].entries[0]=Entry(now,msg.sender,_status);
        diplomas[diplomaNr-1].numberEntries=1;
        hashes[_hash1]=diplomaNr;
        hashes[_hash2]=diplomaNr;
    }


    
    function changeDiploma(uint256 _hash, Status _status) onlyAdmin() external
    {
        if(!(hashes[_hash]!=0)){emit ErrorMessage(&#39;hash does not exist&#39;); return;}
        uint24 diplomaNr=hashes[_hash];
        diplomas[diplomaNr-1].entries[diplomas[diplomaNr-1].numberEntries]=Entry(now,msg.sender,_status);
        diplomas[diplomaNr-1].numberEntries++;
    }
    
    function requestDiploma(uint256 _hash) external view returns (Status, string memory, string memory, uint, uint)
    {
        if(hashes[_hash]==0) return(Status.Fail,statusString[uint24(Status.Fail)], &#39;No diploma registered with the hash given.&#39;,0,0);
        uint24 diplomaNr=hashes[_hash];
        Status status=diplomas[diplomaNr-1].entries[diplomas[diplomaNr-1].numberEntries-1].status;
        return (status, statusString[uint24(status)], string(abi.encodePacked(&#39;Diploma found with status &#39;, statusString[uint24(status)])), diplomaNr, diplomas[diplomaNr-1].numberEntries);
    }

    function requestDiplomaByNr(uint256 diplomaNr) external view returns (Status, string memory, string memory, uint, uint, uint)
    {
        if(diplomaNr==0||diplomaNr>diplomas.length) return(Status.Fail,statusString[uint24(Status.Fail)], &#39;Illegal DiplomaNumber&#39;,0,0,0);
        Status status=diplomas[diplomaNr-1].entries[diplomas[diplomaNr-1].numberEntries-1].status;
        return (status, statusString[uint24(status)], string(abi.encodePacked(&#39;Diploma found with status &#39;, statusString[uint24(status)])), diplomas[diplomaNr-1].hash1, diplomas[diplomaNr-1].hash2, diplomas[diplomaNr-1].numberEntries);
    }

 
    function requestDiplomaEntry(uint diplomaNr, uint256 _entry) external view returns (Status, string memory, address, uint)
    {
        if(diplomas[diplomaNr-1].numberEntries<=_entry) return(Status.Fail, &#39;Entry number given too high.&#39;,address(0),0);
        return(diplomas[diplomaNr-1].entries[_entry].status,statusString[uint24(diplomas[diplomaNr-1].entries[_entry].status)], diplomas[diplomaNr-1].entries[_entry].origin,diplomas[diplomaNr-1].entries[_entry].date);
    }
}