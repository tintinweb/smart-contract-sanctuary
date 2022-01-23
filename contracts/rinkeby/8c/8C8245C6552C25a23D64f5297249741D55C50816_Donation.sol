/**
 *Submitted for verification at Etherscan.io on 2022-01-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

struct Manager
{
  string Username;
  string password;
  address manager; 
}
struct Incharge
{
    
    string firstname;
    string lastname;
    string username;
    string password;
    string contactNo;
    uint CNIC;
    address incharg;
    
}
struct DonateBlood
{
  uint CNIC;
  string firstname;
  string lastname;
  string bloodtype;
  string adress;
  string contact_No;
  uint NoOfBottles;
  uint id;


}
struct RequestBlood
{
  uint CNIC;
  string firstname;
  string lastname;
  string email;
  string bloodtype;
  string disease;
  string adress;
  string contact_No;
  string status;
  uint id;

}
contract Donation
{
   Manager public M1; //getter function of Manager

   Incharge[] public incharges;  //getter function of Incharge
   mapping(uint=>Incharge) public key; //mapping CNIC(I) to Incharge data 
   mapping(address=>Incharge) public  _whiteList;
   mapping(address => bool)  _addressExist;
   
   RequestBlood[] public requests;  //getter function of RequestBlood
   mapping (uint=>RequestBlood) public requesterid;//mapping CNIC(RB) to Requests blood data
   mapping (address=>mapping(uint=>RequestBlood)) public Inchargeadr_requester;//nested mapping Incharge adress to Blood requests(Accepted)

   DonateBlood[] public donates;
   mapping (uint=>DonateBlood) public donerid;
   mapping (address=>mapping(uint=>DonateBlood)) public Inchargeradr_doner;//nested mapping Incharge_adress donate Blood



  
   
   constructor ()
   {
     M1.manager=msg.sender;
     M1.Username="admin";
     M1.password="00000";
   }
  function  donation()external payable
  {

  }

   modifier onlyOwner(){
     require(msg.sender == M1.manager, "Not manager");
     _;
   }


   //update Manager user_name and password
   function updateManager(string memory _username, string memory _password) public onlyOwner 
   {
        // require(msg.sender==M1.manager);
        // Manager memory M2 = M1;
        M1.Username = _username;
        M1.password=_password;
    }


    //NEW Incharge Register
    function NewIncharge(address[] memory whiteAddress,string memory _firstname,string memory _lastname,string memory _username,string memory _password,string memory _contactNo,uint _CNIC) public onlyOwner
    {
       for (uint i = 0; i < whiteAddress.length; i++)
       {
       require(!_addressExist[whiteAddress[i]],"Incharge already Exist");
       key[_CNIC]=Incharge(_firstname,_lastname,_username,_password,_contactNo ,_CNIC,whiteAddress[i]);
       _whiteList[whiteAddress[i]]=Incharge(_firstname,_lastname,_username,_password,_contactNo ,_CNIC,whiteAddress[i]);
       Incharge memory incharge; 
       incharge.firstname=_firstname;
       incharge.lastname=_lastname;
       incharge.username=_username;
       incharge.password=_password;
       incharge.contactNo=_contactNo;
       incharge.CNIC=_CNIC;
       incharge.incharg=whiteAddress[i];
       incharges.push(incharge);
       _addressExist[whiteAddress[i]]=true;
       }
    }

    //request blood function
    function RequestForBlood(uint _CNIC,string memory _firstname,string memory _lastname,string memory _email,string memory _bloodtype,string memory _disease,string memory _adress,string memory _contact_No, string memory _status )public
    {
      require( _addressExist[msg.sender]=true);
      uint count;
      count=requests.length;
      requesterid[_CNIC]=RequestBlood(_CNIC,_firstname, _lastname, _email,_bloodtype,_disease,_adress,_contact_No, _status,count+1);
      Inchargeadr_requester[msg.sender][count+1]=RequestBlood(_CNIC,_firstname, _lastname, _email,_bloodtype,_disease,_adress,_contact_No, _status,count+1);
      RequestBlood memory request;
      request.CNIC=_CNIC;
      request.firstname=_firstname;
      request.lastname=_lastname;
      request.email=_email;
      request.bloodtype=_bloodtype;
      request.disease=_disease;
      request.adress=_adress;
      request.contact_No=_contact_No;
      request.status=_status;
      request.id=count+1;
      requests.push(request);

    }

   //Donate blood
   function Donateblood(uint _CNIC,string memory _firstname,string memory _lastname,string memory _bloodtype,string memory _adress,string memory _contact_No,uint _NoOfBottles)public
   {
     require( _addressExist[msg.sender]=true);
     uint count;
     count=donates.length;
     donerid[_CNIC]=DonateBlood(_CNIC,_firstname, _lastname,_bloodtype,_adress,_contact_No, _NoOfBottles,count+1);
     Inchargeradr_doner[msg.sender][count+1]=DonateBlood(_CNIC,_firstname, _lastname,_bloodtype,_adress,_contact_No, _NoOfBottles,count+1);
      DonateBlood memory donate;
      donate.CNIC=_CNIC;
      donate.firstname=_firstname;
      donate.lastname=_lastname;
      donate.bloodtype=_bloodtype;
      donate.adress=_adress;
      donate.contact_No=_contact_No;
      donate.NoOfBottles=_NoOfBottles;
      donate.id=count+1;
      donates.push(donate);
   }


}