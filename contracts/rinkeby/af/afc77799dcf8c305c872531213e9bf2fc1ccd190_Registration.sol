/**
 *Submitted for verification at Etherscan.io on 2022-01-23
*/

pragma solidity >=0.4.22 <0.8.0;
pragma experimental ABIEncoderV2;
contract Registration { 
  address public admin;
  uint public ManufacturerCount=0;
  uint public InsuranceProviderCount=0;
  uint public VehicleCount=0;
  uint public PolicyCount=0;
  uint public totalUser=0;
  uint public vehicleOwnerCount=0;
  uint public juristrictionCount=0;
  uint public rtoCount=0;
  uint public lawCount=0;
  uint public policeCount=0;
  uint public forensicCount=0;  
  uint public vehicleSellerCount=0;
  uint public ServiceCenterCount=0;
  uint public ServiceCount=0;
  uint public RSUCount=0;
  mapping(address=>uint) public sellerid;
  struct Juristriction{
    uint id;
    string jname;
    uint rtoid;
    uint lawid;
    uint policeid;
    uint forensicid;
  }
  mapping(uint=>Juristriction) public juristrictions;
  struct RTO{
    uint id;
    string jname;
    address rtoaddress;
  }
  mapping(uint=>RTO)public rtos;

  struct ServiceCenter{
    uint id;
    string centername;
    address centeraddress;
  }
  mapping(uint=>ServiceCenter)public servicecenters;

  struct LAW{
    uint id;
    string jname;
    address lawaddress;
  }
  mapping(uint=>LAW)public laws;
  struct Police{
    uint id;
    string jname;
    address policeaddress;
  }
  mapping(uint=>Police)public polices;
  struct Owner {
    uint id;
    string name;
    string adr;
    string phno;
    address owneraddress;
  }
  mapping(uint=>Owner) public vehicleowners;
  struct Status {
    uint id;
    string role;
    address user;
    bool status;
  }
  mapping(uint=>Status) public statusroles;
  struct Manufacturer {
    uint id;
    string name;
  }
  mapping(address => Manufacturer) public manufactures;
  struct InsuranceProvider {
    uint id;
    string name;  
  }
  mapping(address => InsuranceProvider) public insuranceproviders ;
  struct VehicleInfo {
    uint id;
    address manufacturer;
    string chasisno;
    string engineno;
    string color;
    uint model;
    uint sid;
  }
  mapping(uint => VehicleInfo) public vehicleinfos;
  struct Policy {
    uint id;       
    uint policyno; 
    string provider;  
    uint vehicleno; 
    string startdate;     
    string expirydate;       
  }
  mapping(uint => Policy) public policies;
  mapping(address=>string) public roles;  
  mapping(uint=>string) public manufacturenames;
  mapping(uint=>string) public insuranceprovidernames; 
  mapping(uint => uint) public allpolicies; 
  //mapping vehicle manufacurer  
  mapping(address=>bool) public statusroles1;// For check admin verified user
  mapping(address=>string) public vehiclesellers;//seller address to his name mapping

  mapping(string=>uint) public juristrictionid; 
  struct VehicleMapping{
    uint vid;
    uint oid;
    uint jid;
    string manufacturer;
    string Insurance;
  }
  mapping(uint=>VehicleMapping) public vehiclemapping;//vehicle id to Vehicle details
  struct ServiceHistory{
    uint id;
    uint vid;
    uint sid;//Service Center ID    
    string sdate;
    string stype;
  }
  mapping(uint=>ServiceHistory) public servicehistories;//Store all vehicle service ServiceHistory

   struct ServiceHistoryVehicle{
    uint vid;
    uint sid;//Service Center ID    
    string sdate;
    string stype;
  }
  mapping(uint=>ServiceHistoryVehicle[]) private servicehistoriesvehicle;//Store all vehicle service ServiceHistory

  struct RSU{
    uint id;//RSU ID
    uint jid;//Juristriction ID
    address rsuaddress;
  }
  mapping(uint=>RSU) public allrsus;//Store all RSU
  mapping(uint=>bool)public vehiclesold;//Info about vehicle mapped with owner
  mapping(address=>uint) public rsujid;// RSU adress to JID
  //Forensic Informations
  struct Forensic{
    uint id;
    uint [] jids;
    address forensicaddress;
  }
  mapping(uint=>Forensic)public forensics;
  

  function RegisterForensic (uint[] memory _jids) public {       
      // require(juristrictionid[_jurstriction]>0);//Juristriction should be registered
        forensicCount++;
        totalUser++;                 
        roles[msg.sender]="8"; 
        statusroles[totalUser]=Status(totalUser,"FORENSIC",msg.sender,false);
        //Registering LAW
        forensics[forensicCount]=Forensic(forensicCount,_jids,msg.sender);

        //update in Juristricts
        for(uint i=0;i<_jids.length;i++){
          juristrictions[_jids[i]].forensicid=forensicCount;
        }
  }
  
  constructor() public { 
    admin=msg.sender;
  }

  function approveUser(uint _id) public{
    require(msg.sender==admin);
    statusroles[_id].status=true;
    address ad=statusroles[_id].user;
    statusroles1[ad]=true;
  }
  function RegisterRTO (string memory _jurstriction) public {       
        require(!(juristrictionid[_jurstriction]>0));// should not register already
        rtoCount++;
        totalUser++;                 
        roles[msg.sender]="4"; 
        statusroles[totalUser]=Status(totalUser,"RTO",msg.sender,false);
        juristrictionCount++;
        //Registering new Juristriction
        juristrictions[juristrictionCount]=Juristriction(juristrictionCount,_jurstriction,rtoCount,0,0,0);
        juristrictionid[_jurstriction]=juristrictionCount;
        //Registering RTO
        rtos[rtoCount]=RTO(rtoCount,_jurstriction,msg.sender);
  } 

   function RegisterServiceCenter (string memory _sname) public { 
        ServiceCenterCount++;
        totalUser++;                 
        roles[msg.sender]="7"; 
        statusroles[totalUser]=Status(totalUser,"Serice Center",msg.sender,false); 
        servicecenters[ServiceCenterCount]=ServiceCenter(ServiceCenterCount,_sname,msg.sender);
  } 

  

   function RegisterLAW (string memory _jurstriction) public {       
       require(juristrictionid[_jurstriction]>0);//Juristriction should be registered
        lawCount++;
        totalUser++;                 
        roles[msg.sender]="5"; 
        statusroles[totalUser]=Status(totalUser,"LAW",msg.sender,false);
        //Registering LAW
        laws[lawCount]=LAW(lawCount,_jurstriction,msg.sender);
         //Uupdate  Juristriction
        uint jid=juristrictionid[_jurstriction];
        juristrictions[jid].lawid=lawCount;
  } 
    function RegisterPolice (string memory _jurstriction) public {       
       require(juristrictionid[_jurstriction]>0);//Juristriction should be registered
        policeCount++;
        totalUser++;                 
        roles[msg.sender]="6"; 
        statusroles[totalUser]=Status(totalUser,"Police",msg.sender,false);
       
        //Registering Police
        polices[policeCount]=Police(policeCount,_jurstriction,msg.sender);
         //Uupdate  Juristriction
        uint jid=juristrictionid[_jurstriction];
        juristrictions[jid].policeid=policeCount;
  } 
  function RegisterVehicleAtRTO (uint _vid,uint _jid) public {  
        require(keccak256(abi.encodePacked((roles[msg.sender]))) == keccak256(abi.encodePacked(("4")))) ;//should be RTO
        require(statusroles1[msg.sender]==true);//Admin verified user        
        //Vehicle  JID mapping
        //vehicle shoul be sold
        require(vehiclesold[_vid]=true);
        vehiclemapping[_vid].jid=_jid;        
  }
  function RegisterRSU (uint _jid,address _rsuaddress) public {  
        require(keccak256(abi.encodePacked((roles[msg.sender]))) == keccak256(abi.encodePacked(("4")))) ;//should be RTO
        require(statusroles1[msg.sender]==true);//Admin verified user 
        RSUCount++;
        allrsus[RSUCount]=RSU(RSUCount,_jid,_rsuaddress);
        roles[_rsuaddress]="9"; // set the address as RSU
        rsujid[_rsuaddress]=_jid; //Return JID of RSU
  }
  function serviceVehicle (uint _vid,uint _sid,string memory _sdate,string memory _stype)  public {  
        require(keccak256(abi.encodePacked((roles[msg.sender]))) == keccak256(abi.encodePacked(("7")))) ;//should be RTO
        require(statusroles1[msg.sender]==true);//Admin verified user        
        //Vehicle  JID mapping
        //vehicle shoul be sold
        require(vehiclesold[_vid]=true);
        ServiceCount++;
        servicehistories[ServiceCount]=ServiceHistory(ServiceCount,_vid,_sid,_sdate,_stype); 
        ServiceHistoryVehicle memory  _s=ServiceHistoryVehicle(_vid,_sid,_sdate,_stype);
        servicehistoriesvehicle[_vid].push(_s)  ;
  }


  function RegisterVehicleOwner (string memory _name,string memory _adr,string memory _phno) public {       
        vehicleOwnerCount ++;
        totalUser++;
        vehicleowners[vehicleOwnerCount] = Owner(vehicleOwnerCount,_name,_adr,_phno,msg.sender);          
        roles[msg.sender]="0"; 
        statusroles[totalUser]=Status(totalUser,"VehicleOwner",msg.sender,false);
  } 

   function RegisterVehicleSeller (string memory _name) public {  
        totalUser++;
        vehiclesellers[msg.sender] = _name;          
        roles[msg.sender]="3"; 
        statusroles[totalUser]=Status(totalUser,"VehicleSeller",msg.sender,false);
        vehicleSellerCount++;
        sellerid[msg.sender]=vehicleSellerCount;
  } 
   function SellVehicle (uint _vid,uint _oid) public {  
        require(keccak256(abi.encodePacked((roles[msg.sender]))) == keccak256(abi.encodePacked(("3")))) ;//should be Seller
        require(statusroles1[msg.sender]==true);//Admin verified user
        require(vehiclesold[_vid]==false); //Vehicle should not be sold before
        //Correct seller can sell this vehicle
        require(vehicleinfos[_vid].sid==sellerid[msg.sender]);
        //Vehicle  Owner mapped
        vehiclemapping[_vid].oid=_oid;
        vehiclesold[_vid]=true;
  }

  function RegisterManufacturer (string memory _name) public {       
        ManufacturerCount ++;
        totalUser++;
        manufactures[msg.sender] = Manufacturer(ManufacturerCount,_name);   
        manufacturenames[ManufacturerCount]=_name; 
        roles[msg.sender]="1"; 
        statusroles[totalUser]=Status(totalUser,"Manufacturer",msg.sender,false);
  } 
  function RegisterInsuranceProvider (string memory _name) public {       
        InsuranceProviderCount ++;
        totalUser++;
        insuranceproviders[msg.sender] = InsuranceProvider(InsuranceProviderCount,_name);   
        insuranceprovidernames[InsuranceProviderCount]=_name;  
        roles[msg.sender]="2"; 
        statusroles[totalUser]=Status(totalUser,"Insurance Provider",msg.sender,false);
  }

   function RegisterVehicle (string memory _chasis,string memory _engine, string memory _color, uint _model,uint _sid) public {  
        require(keccak256(abi.encodePacked((roles[msg.sender]))) == keccak256(abi.encodePacked(("1")))) ;//should be manufacturer
        require(statusroles1[msg.sender]==true);//Admin verified user
        VehicleCount ++;

        vehicleinfos[VehicleCount] = VehicleInfo(VehicleCount,msg.sender,_chasis,_engine,_color,_model,_sid);      
        vehiclesold[VehicleCount]=false  ;
        //Mapping to Vehicle
        vehiclemapping[VehicleCount]=VehicleMapping(VehicleCount,0,0,manufactures[msg.sender].name,"");
        
  } 

   function RegisterPolicy (uint _policyno,string memory _provider,uint _vno,string memory _sdate,string memory _edate) public {       
        PolicyCount ++;
        policies[_policyno] = Policy(PolicyCount,_policyno,_provider,_vno,_sdate,_edate);
        allpolicies[PolicyCount]=_policyno;
        //Vehicle Mapping
         vehiclemapping[_vno].Insurance=_provider;
        //Aslo update in Vehicle       
        //uint _id=vehicleinfos[_vno].id;
        //address _owner=vehicleinfos[_vno].owner;        
        //string memory _manufacturer=vehicleinfos[_vno].manufacturer;        
        //vehicleinfos[_vno] = VehicleInfo(_id,_owner,_vno,_manufacturer,_provider,_policyno);
        //vehicleinfos[_vno].insusrancecompany=_provider;
        //vehicleinfos[_vno].policyno=_policyno;
  } 
   function getRSUJID(address _caller) public view  returns (uint) {
      return (rsujid[_caller]);
  }
  function getVehicleMapping(uint _vid) public view returns (uint){
      return (vehiclemapping[_vid].oid);
  }
  function getJuristrictionPoliceID(uint _jid) public view returns (uint){
      return (juristrictions[_jid].policeid);
  }
  function getJuristrictionForensicID(uint _jid) public view returns (uint){
      return (juristrictions[_jid].forensicid);
  }
  function getJuristrictionLawID(uint _jid) public view returns (uint){
      return (juristrictions[_jid].lawid);
  }
  function getOwnerAddress(uint _oid) public view returns (address){
      return (vehicleowners[_oid].owneraddress);
  }
 function getForensicAddress(uint _fid) public view returns (address){
      return (forensics[_fid].forensicaddress);
  }
   function getPoliceAddress(uint _pid) public view returns (address){
      return (polices[_pid].policeaddress);
  }
   function getLawAddress(uint _lid) public view returns (address){
      return (laws[_lid].lawaddress);
  }
   function getManufacturerAddress(uint _vid) public view returns (address){
      return (vehicleinfos[_vid].manufacturer);
  }
  function getTotalUsers() public view returns (uint){
      return (totalUser);
  }
  function getRoles(address _t) public view returns (string memory){
      return (roles[_t]);
  }
}