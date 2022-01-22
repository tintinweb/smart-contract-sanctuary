/**
 *Submitted for verification at Etherscan.io on 2022-01-22
*/

pragma solidity >=0.4.22 <0.8.0;
pragma experimental ABIEncoderV2;
contract Registration{
   struct ServiceHistory{
    uint id;
    uint vid;
    uint sid;//Service Center ID    
    string sdate;
    string stype;
  }
  mapping(uint=>ServiceHistory) public servicehistories;//Store all vehicle service ServiceHistory
  function RegisterForensic (uint[] memory _jids) public { }
  function approveUser(uint _id) public{}
  function RegisterRTO (string memory _jurstriction) public { }
  function RegisterServiceCenter (string memory _sname) public { }
  function RegisterLAW (string memory _jurstriction) public { } 
  function RegisterPolice (string memory _jurstriction) public {  }
  function RegisterVehicleAtRTO (uint _vid,uint _jid) public { }
  function RegisterRSU (uint _jid,address _rsuaddress) public { }
  function serviceVehicle (uint _vid,uint _sid,string memory _sdate,string memory _stype)  public {}
  function RegisterVehicleOwner (string memory _name,string memory _adr,string memory _phno) public { }
  function RegisterVehicleSeller (string memory _name) public {  }
  function SellVehicle (uint _vid,uint _oid) public { }
  function RegisterManufacturer (string memory _name) public { }
  function RegisterInsuranceProvider (string memory _name) public {  }
  function RegisterVehicle (string memory _chasis,string memory _engine, string memory _color, uint _model,uint _sid) public {  }   
  function RegisterPolicy (uint _policyno,string memory _provider,uint _vno,string memory _sdate,string memory _edate) public {  }
  function getRSUJID(address _caller) public view  returns (uint) {  }
  function getVehicleMapping(uint _vid) public view returns (uint){}
  function getJuristrictionPoliceID(uint _jid) public view returns (uint){}
  function getJuristrictionForensicID(uint _jid) public view returns (uint){}
  function getJuristrictionLawID(uint _jid) public view returns (uint){}
  function getOwnerAddress(uint _oid) public view returns (address){}
  function getForensicAddress(uint _fid) public view returns (address){}
   function getPoliceAddress(uint _pid) public view returns (address){}
   function getLawAddress(uint _lid) public view returns (address){}
    function getManufacturerAddress(uint _vid) public view returns (address){}
    function getTotalUsers() public view returns (uint){}
}
contract Vehicle { 

  Registration r;
  constructor(address _registration) public { 
      r = Registration(_registration);
  }
//PHASE 2 declarations
uint public incidentCount =0;
mapping (uint=>uint[]) private incidentToVids;

//V2V data
  struct V2VData{
    uint incidentid;
    //uint [] vids;
    string triggertype;
    uint roadsegmentid;
    string date;
    string time;
    string weather;
    string roadcondition;
    string driverhealthcondition;
    string vehiclevideohash;
    string bsmmessagehash;
  }
mapping (uint=>mapping(uint=>V2VData)) private v2vdatas;//incident id to vid to data

//V2V comparison data
  struct V2VShortData{
    uint incidentid;
    //uint[] vids;
    uint roadsegmentid;
    string time;
    string evidencehash;
  }
mapping (uint=>mapping(uint=>V2VShortData)) private v2vshortdatas; //incident id to vid to short data
mapping(uint=>uint) private incidentjid; //incident id to jid
//PHASE 2 functions
function V2VMethod1 (uint [] memory _vids,V2VData [] memory _v2vdata ) public {  
        //require(keccak256(abi.encodePacked((roles[msg.sender]))) == keccak256(abi.encodePacked(("9")))) ;//should be RSU
        
        incidentCount++ ; 
        
        //uint jid=rsujid[msg.sender];
        uint jid=r.getRSUJID(msg.sender);
        incidentjid[incidentCount]=jid;
        incidentToVids[incidentCount]=_vids;
        for (uint i=0;i<_vids.length;i++){
           //V2VData memory _v=V2VData(incidentCount,_v2vdata[i][0],_v2vdata[i][1],_v2vdata[i][2],_v2vdata[i][3],_v2vdata[i][4],_v2vdata[i][5],_v2vdata[i][6],_v2vdata[i][7],_v2vdata[i][8]);

            V2VData memory _v=V2VData(incidentCount,_v2vdata[i].triggertype,_v2vdata[i].roadsegmentid,_v2vdata[i].date,_v2vdata[i].time,_v2vdata[i].weather,_v2vdata[i].roadcondition,_v2vdata[i].driverhealthcondition,_v2vdata[i].vehiclevideohash,_v2vdata[i].bsmmessagehash);
           
            v2vdatas[incidentCount][_vids[i]]=_v;
        }

        // v2vdatas[incidentCount]=V2VData(incidentCount,_vid,_triggertype,_roadsegmentid,_date,_time,_weather,_roadcondition,_driverhealthcondition,_vehiclevideohash,_bsmmessagehash) ;    
  }
function V2VMethod2 (uint _incidentCount ,uint   _vid,V2VData memory _v2vdata ) public {  
        //require(keccak256(abi.encodePacked((roles[msg.sender]))) == keccak256(abi.encodePacked(("9")))) ;//should be RSU
        
        //incidentCount++ ; 
        //uint jid=rsujid[msg.sender];
         uint jid=r.getRSUJID(msg.sender);
        incidentjid[_incidentCount]=jid;
        //for (uint i=0;i<_vids.length;i++){
           //V2VData memory _v=V2VData(incidentCount,_v2vdata[i][0],_v2vdata[i][1],_v2vdata[i][2],_v2vdata[i][3],_v2vdata[i][4],_v2vdata[i][5],_v2vdata[i][6],_v2vdata[i][7],_v2vdata[i][8]);

            V2VData memory _v=V2VData(_incidentCount,_v2vdata.triggertype,_v2vdata.roadsegmentid,_v2vdata.date,_v2vdata.time,_v2vdata.weather,_v2vdata.roadcondition,_v2vdata.driverhealthcondition,_v2vdata.vehiclevideohash,_v2vdata.bsmmessagehash);
           
            v2vdatas[_incidentCount][_vid]=_v;
        //}

        // v2vdatas[incidentCount]=V2VData(incidentCount,_vid,_triggertype,_roadsegmentid,_date,_time,_weather,_roadcondition,_driverhealthcondition,_vehiclevideohash,_bsmmessagehash) ;    
  }

  function V2VShortdata (uint [] memory _vids,V2VShortData [] memory _v2vdata ) public {  
        //require(keccak256(abi.encodePacked((roles[msg.sender]))) == keccak256(abi.encodePacked(("9")))) ;//should be RSU
        
        incidentCount++ ; 
        //uint jid=rsujid[msg.sender];
         uint jid=r.getRSUJID(msg.sender);
        incidentjid[incidentCount]=jid;
        incidentToVids[incidentCount]=_vids;
        for (uint i=0;i<_vids.length;i++){
           //V2VData memory _v=V2VData(incidentCount,_v2vdata[i][0],_v2vdata[i][1],_v2vdata[i][2],_v2vdata[i][3],_v2vdata[i][4],_v2vdata[i][5],_v2vdata[i][6],_v2vdata[i][7],_v2vdata[i][8]);

            V2VShortData memory _v=V2VShortData(incidentCount,_v2vdata[i].roadsegmentid,_v2vdata[i].time,_v2vdata[i].evidencehash);
           
            v2vshortdatas[incidentCount][_vids[i]]=_v;
        }

        // v2vdatas[incidentCount]=V2VData(incidentCount,_vid,_triggertype,_roadsegmentid,_date,_time,_weather,_roadcondition,_driverhealthcondition,_vehiclevideohash,_bsmmessagehash) ;    
  }

  function readV2V(uint _incidenid,uint _vid) public view returns (V2VData memory){

    //return (v2vdatas[_incidenid].vids,v2vdatas[_incidenid].triggertype,v2vdatas[_incidenid].roadsegmentid,string(abi.encodePacked(v2vdatas[_incidenid].date,v2vdatas[_incidenid].time,v2vdatas[_incidenid].weather,v2vdatas[_incidenid].roadcondition,v2vdatas[_incidenid].driverhealthcondition,v2vdatas[_incidenid].vehiclevideohash,v2vdatas[_incidenid].bsmmessagehash)));
    //ACCESS CONTROL   
    //uint _oid=vehiclemapping[_vid].oid;//Reading Owner Id of the Vehicle   
     uint _oid=r.getVehicleMapping(_vid);//Reading Owner Id of the Vehicle   
    uint jid=incidentjid[_incidenid];
    //uint policeid=juristrictions[jid].policeid;
    uint policeid=r.getJuristrictionPoliceID(jid);    
    //uint forensicid=juristrictions[jid].forensicid;
    uint forensicid=r.getJuristrictionForensicID(jid);
     //Vehicle Owner can read or forensic or Police
    require((r.getOwnerAddress(_oid)==msg.sender)||(r.getForensicAddress(forensicid)==msg.sender)||(r.getPoliceAddress(policeid)==msg.sender));
    return (v2vdatas[_incidenid][_vid]);
  }
  function readV2VShortData(uint _incidenid,uint _vid) public view returns (V2VShortData memory){

    //return (v2vdatas[_incidenid].vids,v2vdatas[_incidenid].triggertype,v2vdatas[_incidenid].roadsegmentid,string(abi.encodePacked(v2vdatas[_incidenid].date,v2vdatas[_incidenid].time,v2vdatas[_incidenid].weather,v2vdatas[_incidenid].roadcondition,v2vdatas[_incidenid].driverhealthcondition,v2vdatas[_incidenid].vehiclevideohash,v2vdatas[_incidenid].bsmmessagehash)));
    //ACCESS CONTROL   
    //uint _oid=vehiclemapping[_vid].oid;//Reading Owner Id of the Vehicle 
     uint _oid=r.getVehicleMapping(_vid);//Reading Owner Id of the Vehicle   
    uint jid=incidentjid[_incidenid];
    //uint policeid=juristrictions[jid].policeid;
    uint policeid=r.getJuristrictionPoliceID(jid);
    uint forensicid=r.getJuristrictionForensicID(jid);
     //Vehicle Owner can read or forensic or Police
    require((r.getOwnerAddress(_oid)==msg.sender)||(r.getForensicAddress(forensicid)==msg.sender)||(r.getPoliceAddress(policeid)==msg.sender));
    return (v2vshortdatas[_incidenid][_vid]);

  }
//V2p starting
//V2P data
  struct V2PData{
    uint incidentid;    
    uint ownerid;
    uint roadsegmentid;
    string location;
    string date;
    string time;
    string mobileevidencehash;   
    string bsmmessagehash;
  }
mapping (uint=>V2PData) private v2pdatas;//incident id to Pedestrian data

//V2P comparison data

  struct V2PShortData{
    uint incidentid;    
    uint ownerid;    
    string evidencehash;
  }
  mapping (uint=>V2PShortData) private v2pshortdatas; //incident id to Pedestrian short data
function V2P (uint _incidentId ,uint _oid,uint _roadsegmentid,string memory _location,string memory _date,string memory _time, string memory _mobileevidencehash,string memory _bsmmessagehash ) public {

        //require(keccak256(abi.encodePacked((roles[msg.sender]))) == keccak256(abi.encodePacked(("9")))) 

        //uint jid=rsujid[msg.sender];
         uint jid=r.getRSUJID(msg.sender);
        incidentjid[incidentCount]=jid;
       
        V2PData memory _v=V2PData(_incidentId,_oid,_roadsegmentid,_location,_date,_time,_mobileevidencehash,_bsmmessagehash);
        v2pdatas[_incidentId]=_v;
  }

  function V2PShortdata (uint _incidentId ,uint _oid,string memory _evidencehash ) public {  
        //require(keccak256(abi.encodePacked((roles[msg.sender]))) == keccak256(abi.encodePacked(("9")))) ;//should be RSU
        
        V2PShortData memory _v=V2PShortData(_incidentId,_oid,_evidencehash);           
        v2pshortdatas[_incidentId]=_v;
  }
   function readV2P(uint _incidenid) public view returns (V2PData memory){

    //return (v2vdatas[_incidenid].vids,v2vdatas[_incidenid].triggertype,v2vdatas[_incidenid].roadsegmentid,string(abi.encodePacked(v2vdatas[_incidenid].date,v2vdatas[_incidenid].time,v2vdatas[_incidenid].weather,v2vdatas[_incidenid].roadcondition,v2vdatas[_incidenid].driverhealthcondition,v2vdatas[_incidenid].vehiclevideohash,v2vdatas[_incidenid].bsmmessagehash)));
    //ACCESS CONTROL   
    uint _oid=v2pdatas[_incidenid].ownerid;//Reading Owner Id of the Vehicle   
    uint jid=incidentjid[_incidenid];
    //uint policeid=juristrictions[jid].policeid;
    uint policeid=r.getJuristrictionPoliceID(jid);
   uint forensicid=r.getJuristrictionForensicID(jid);
     //Vehicle Owner can read or forensic or Police
    require((r.getOwnerAddress(_oid)==msg.sender)||(r.getForensicAddress(forensicid)==msg.sender)||(r.getPoliceAddress(policeid)==msg.sender));
    return (v2pdatas[_incidenid]);
  }
    function readV2PShort(uint _incidenid) public view returns (V2PShortData memory){

    //return (v2vdatas[_incidenid].vids,v2vdatas[_incidenid].triggertype,v2vdatas[_incidenid].roadsegmentid,string(abi.encodePacked(v2vdatas[_incidenid].date,v2vdatas[_incidenid].time,v2vdatas[_incidenid].weather,v2vdatas[_incidenid].roadcondition,v2vdatas[_incidenid].driverhealthcondition,v2vdatas[_incidenid].vehiclevideohash,v2vdatas[_incidenid].bsmmessagehash)));
    //ACCESS CONTROL   
    uint _oid=v2pshortdatas[_incidenid].ownerid;//Reading Owner Id of the Vehicle   
    uint jid=incidentjid[_incidenid];
    //uint policeid=juristrictions[jid].policeid;
    uint policeid=r.getJuristrictionPoliceID(jid);
    uint forensicid=r.getJuristrictionForensicID(jid);
     //Vehicle Owner can read or forensic or Police
    require((r.getOwnerAddress(_oid)==msg.sender)||(r.getForensicAddress(forensicid)==msg.sender)||(r.getPoliceAddress(policeid)==msg.sender));
    return (v2pshortdatas[_incidenid]);
  }
  //V2P Ends

//Additional Evidence
//Additional Evidence Starting


  struct AdditionalEvidence{
    uint incidentid;    
    uint vid;
    string bsmipfshash;
    string videoipfshash;
    string location;
    uint roadsegmentid;
    string date;
    string time;
  }
mapping (uint=>mapping(uint=>AdditionalEvidence)) private additionalevidences;//incident id,vid to Data

//Additioanl Evidence comparison data

  struct AdditionalEvidenceShortData{
    uint incidentid;    
    uint vid;    
    string evidencehash;
  }
  mapping (uint=>mapping (uint=>AdditionalEvidenceShortData)) private additionalevidencesshort;//incident id,vid to Data
function additionalEvidences (uint _incidentId ,uint _vid,string memory _bsmipfshash,string memory _videoipfshash,string memory _location,uint _roadsegmentid, string memory _date,string memory _time ) public {

        //require(keccak256(abi.encodePacked((roles[msg.sender]))) == keccak256(abi.encodePacked(("9")))) 
      
        AdditionalEvidence memory _v=AdditionalEvidence(_incidentId,_vid,_bsmipfshash,_videoipfshash,_location,_roadsegmentid,_date,_time);
        additionalevidences[_incidentId][_vid]=_v;
  }

  function shortAdditionalEvidencs (uint _incidentId ,uint _vid,string memory _evidencehash ) public {  
        //require(keccak256(abi.encodePacked((roles[msg.sender]))) == keccak256(abi.encodePacked(("9")))) ;//should be RSU
        AdditionalEvidenceShortData memory _v=AdditionalEvidenceShortData(_incidentId,_vid,_evidencehash);           
        additionalevidencesshort[_incidentId][_vid]=_v;
  }
    
  function readAdditionalEvidence(uint _incidenid,uint _vid) public view returns (AdditionalEvidence memory){
    //ACCESS CONTROL   
    //uint _oid=vehiclemapping[_vid].oid;//Reading Owner Id of the Vehicle 
     uint _oid=r.getVehicleMapping(_vid);//Reading Owner Id of the Vehicle   
    uint jid=incidentjid[_incidenid];
    //uint policeid=juristrictions[jid].policeid;
    uint policeid=r.getJuristrictionPoliceID(jid);
    uint forensicid=r.getJuristrictionForensicID(jid);
     //Vehicle Owner can read or forensic or Police
    require((r.getOwnerAddress(_oid)==msg.sender)||(r.getForensicAddress(forensicid)==msg.sender)||(r.getPoliceAddress(policeid)==msg.sender));
    return (additionalevidences[_incidenid][_vid]);
  }
  function readAdditionalEvidenceShort(uint _incidenid,uint _vid) public view returns (AdditionalEvidenceShortData memory){
    //ACCESS CONTROL   
    //uint _oid=vehiclemapping[_vid].oid;//Reading Owner Id of the Vehicle   
     uint _oid=r.getVehicleMapping(_vid);//Reading Owner Id of the Vehicle 
    uint jid=incidentjid[_incidenid];
    //uint policeid=juristrictions[jid].policeid;
    uint policeid=r.getJuristrictionPoliceID(jid);
    uint forensicid=r.getJuristrictionForensicID(jid);
     //Vehicle Owner can read or forensic or Police
    require((r.getOwnerAddress(_oid)==msg.sender)||(r.getForensicAddress(forensicid)==msg.sender)||(r.getPoliceAddress(policeid)==msg.sender));
    return (additionalevidencesshort[_incidenid][_vid]);
  }
function testData() public view returns (uint){
  uint _a=r.getTotalUsers();
  return (_a);
}
//Additional Evience Ends
  function getIncidentJid(uint _incidentid) public view returns (uint){
      return (incidentjid[_incidentid]);
  }
   function getincidentToVids(uint _incidentid) public view returns (uint[] memory){
      return (incidentToVids[_incidentid]);
  }

}