/**
 *Submitted for verification at Etherscan.io on 2021-02-06
*/

pragma solidity ^0.4.16;
contract BSPAM_IECI_PC {
    
bool public BSPAM_IECI_PC_Network_Activation;
address public SP;

uint public Provisioned_Clients;
   
mapping (address => uint) public provisionedId;

Client_Provisioned[99] public client_provisioned_ID;


    event BSPAM_IECI_PC_Avtivated(address sp);
    event Service_Provisioned(address clientID,uint block_timestamp,uint Expiry, string resource_or_service,string clientpermission);
    event Service_Provisioned_Updated(address clientID,uint block_timestamp,uint Expiry, string resource_or_service,string clientpermission);
    event Service_De_Provisioned(address clientID);
    event BSPAM_IECI_PC_Deactivated(bool deactivate);
    
    struct Client_Provisioned {
        address client;
        string resource;
        string permissions;
        uint client_Activation;
        uint Valid_Until;
    }
    
    modifier onlySP {
        require(msg.sender == SP);
        _;
    }

function  BSPAM_IECI_PC() public {
        SP = msg.sender;
        BSPAM_IECI_PC_Network_Activation = true;
        BSPAM_IECI_PC_Avtivated(SP);
}

function Service_Provisioning(address clientID, string memory resource_or_service, string memory clientpermission, uint Expiry) onlySP public {
        require(BSPAM_IECI_PC_Network_Activation = true);
        uint id = provisionedId[clientID];
        if (id == 0) {
            provisionedId[clientID] = Provisioned_Clients;
            id = Provisioned_Clients;
            client_provisioned_ID[id] = Client_Provisioned({client: clientID, client_Activation: block.timestamp, Valid_Until: Expiry ,resource: resource_or_service, permissions: clientpermission});
            Service_Provisioned(clientID,block.timestamp,Expiry, resource_or_service, clientpermission);
            Provisioned_Clients++;
        }
        else {
            client_provisioned_ID[id] = Client_Provisioned({client: clientID, client_Activation: block.timestamp, Valid_Until: Expiry, resource: resource_or_service, permissions: clientpermission});
        Service_Provisioned_Updated(clientID,block.timestamp, Expiry, resource_or_service, clientpermission);

        }
    }
    
function Service_De_Provisioning(address clientID) onlySP public {
        require(BSPAM_IECI_PC_Network_Activation = true && provisionedId[clientID] >= 0);
        address ID;
        for (uint i = provisionedId[clientID]; i<Provisioned_Clients-1; i++){
            client_provisioned_ID[i] = client_provisioned_ID[i+1];
            ID = client_provisioned_ID[i].client;
            provisionedId[ID] = i;
        }
        delete client_provisioned_ID[Provisioned_Clients-1];
        Provisioned_Clients--;
        provisionedId[clientID] = 0;
        Service_De_Provisioned(clientID);
    }
    
function Deactivate (bool deactivate) onlySP public {
        if (deactivate)
        {BSPAM_IECI_PC_Network_Activation = false;}
        BSPAM_IECI_PC_Deactivated(deactivate);
    }
}
  
//SP: 0x89dC4cfb04B34729ec2854A9A72802a388c164f2
//Client: 0x0D83083Db7c2935Dd7708D34BeAd74Cc29ff8396