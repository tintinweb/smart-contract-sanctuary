/**
 *Submitted for verification at Etherscan.io on 2021-02-06
*/

pragma solidity 0.4.16;
contract BPMI_ICE_PC{

bool BPMI_ICE_PC_Network_Activation;

address public SP; 

uint public Privilege_Certificate_Issued; 
uint public Privilege_Certificate_Revoked;

struct Privilege_Certificate 
{
address signer ;
address clientID ;
string resource;
string permissions;
uint Client_Activation;
uint expiry;
}

struct Revocation 
{
uint Privilege_CertificateID ;
}

Privilege_Certificate [] public Privilege_Certificate_Verification;
Revocation [] public Revocation_Privilege_Certificate;

    modifier onlySP {
        require(msg.sender == SP);
        _;
  }

event BSPAM_IECI_PC_Avtivated(address sp);
event Privilege_Certificate_Issued ( uint indexed CertificateID , address indexed signer , address clientID ,
string resource, string permissions,uint client_activation, uint expiry);
event Privilege_Certificate_Revoked( uint indexed De_ProvisioningID , uint indexed Privilege_CertificateID);
event BPMI_ICE_PC_Deactivated(bool deactivate);

function BPMI_ICE_PC() public {
SP = msg.sender;
BPMI_ICE_PC_Network_Activation=true;
Privilege_Certificate_Issued=0;
Privilege_Certificate_Revoked=0;
BSPAM_IECI_PC_Avtivated(SP);
    
}

function Privilege_Certificate_Provisioning ( address clientID ,string resource, string permissions,  uint expiry) 
onlySP returns ( uint Privilege_CertificateID) 
{
require(BPMI_ICE_PC_Network_Activation==true);
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
require(BPMI_ICE_PC_Network_Activation==true);
De_ProvisioningID = Revocation_Privilege_Certificate . length++;
Revocation revocation =Revocation_Privilege_Certificate [ De_ProvisioningID ];
revocation . Privilege_CertificateID = Privilege_CertificateID ;
Privilege_Certificate_Issued--;
Privilege_Certificate_Revoked++;
Privilege_Certificate_Revoked(De_ProvisioningID ,Privilege_CertificateID ) ;
}
function Deactivate (bool deactivate) onlySP public {
        if (deactivate)
        {BPMI_ICE_PC_Network_Activation = false;}
        BPMI_ICE_PC_Deactivated(deactivate);
    }
}

//SP: 0x89dC4cfb04B34729ec2854A9A72802a388c164f2
//Client: 0x0D83083Db7c2935Dd7708D34BeAd74Cc29ff8396