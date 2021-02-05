/**
 *Submitted for verification at Etherscan.io on 2021-02-05
*/

pragma solidity 0.4.16;
contract BPMI_ICE{

bool BPMI_ICE_Network_Activation;

address public SP; 

uint public Registered_Clients;
uint public Privilege_Certificate_Issued; 
uint public Privilege_Certificate_Revoked;

struct Registeration
{
address ClientID;
string Data;
}

struct Privilege_Certificate 
{
address signer ;
uint clientID ;
string resource;
string permissions;
uint Client_Activation;
uint expiry;
}

struct Revocation 
{
uint Privilege_CertificateID ;
}

Registeration [] public registerations ;
Privilege_Certificate [] public Privilege_Certificate_Verification;//signatures ;
Revocation [] public Revocation_Privilege_Certificate;

    modifier onlySP {
        require(msg.sender == SP);
        _;
  }

event Client_Registeration_and_Provisiong_Request_Received( uint indexed clientID, string data);
event Privilege_Certificate_Issued ( uint indexed CertificateID , address indexed signer , uint indexed clientID ,
string resource, string permissions,uint client_activation, uint expiry);
event Privilege_Certificate_Revoked( uint indexed De_ProvisioningID , uint indexed Privilege_CertificateID);

function BPMI_ICE() public {
SP = msg.sender;
BPMI_ICE_Network_Activation=true;
Registered_Clients=0;
Privilege_Certificate_Issued=0;
Privilege_Certificate_Revoked=0;
}


function Client_Registeration_and_Provisioning_Request(string data) returns (uint clientID ) 
{
require(BPMI_ICE_Network_Activation==true);
clientID = registerations . length ++;
Registeration registeration = registerations [clientID];
registeration . ClientID = msg.sender ;
registeration . Data = data;
Registered_Clients++;
Client_Registeration_and_Provisiong_Request_Received(clientID, data) ;
}


function Privilege_Certificate_Provisioning ( uint clientID ,string resource, string permissions,  uint expiry) 
onlySP returns ( uint Privilege_CertificateID) 
{
require(BPMI_ICE_Network_Activation==true);
Privilege_CertificateID = Privilege_Certificate_Verification . length ++;
Privilege_Certificate signature = Privilege_Certificate_Verification [Privilege_CertificateID ];
signature . signer = msg . sender ;
signature . clientID = clientID ;
signature. resource=resource;
signature.permissions=permissions;
signature.Client_Activation=block.timestamp;
signature . expiry = expiry ;
Privilege_Certificate_Issued++;
Privilege_Certificate_Issued( Privilege_CertificateID , msg .sender , clientID , resource, permissions, block.timestamp, expiry ) ;
}


function Privilege_Certificate_De_Provisioning ( uint Privilege_CertificateID ) onlySP
returns ( uint De_ProvisioningID) 
{
require(BPMI_ICE_Network_Activation==true);

De_ProvisioningID = Revocation_Privilege_Certificate . length++;
Revocation revocation =Revocation_Privilege_Certificate [ De_ProvisioningID ];
revocation . Privilege_CertificateID = Privilege_CertificateID ;
Privilege_Certificate_Issued--;
Privilege_Certificate_Revoked++;
Privilege_Certificate_Revoked(De_ProvisioningID ,Privilege_CertificateID ) ;
}
}

//SP: 0x89dC4cfb04B34729ec2854A9A72802a388c164f2
//Client: 0x0D83083Db7c2935Dd7708D34BeAd74Cc29ff8396