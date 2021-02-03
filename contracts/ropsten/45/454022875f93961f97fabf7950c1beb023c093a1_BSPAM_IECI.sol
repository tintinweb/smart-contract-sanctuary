/**
 *Submitted for verification at Etherscan.io on 2021-02-03
*/

pragma solidity ^0.4.16;
contract BSPAM_IECI {
    
    bool public BSPAM_IECI_Network_Activation;
    address public SP;

   uint public Registered_Clients;
   uint public Provisioned_Clients;
   
    mapping (address => uint) public clientId;
    mapping (address => uint) public provisionedId;

Client[99] public clients;

Client_Provisioned[99] public client_provisioned;

    event Registeration_Request(address UserAddress, string hash_Data);
    event Updated_Registeration_Request(address UserAddress, string hash_Data);
    event Registeration_Request_Revoked(address UserAddress);

    event Service_Provisioned(address clientID,uint block_timestamp,uint Expiry, string clientresource,string clientpermission);
    event Service_Provisioned_Updated(address clientID,uint block_timestamp,uint Expiry, string clientresource,string clientpermission);
    event Service_De_Provisioned(address clientID);
    

    struct Client {
        address client;
        string IPFS_hash_or_Data;
        }
    
    struct Client_Provisioned {
        address client;
        string resource;
        string permissions;
        uint client_Activation;
        uint Valid_Until;
    }
    

    modifier onlyOwner {
        require(msg.sender == SP);
        _;
    }
    
    modifier onlyUsers {
      require((clientId[msg.sender] >= 0) && msg.sender != SP && BSPAM_IECI_Network_Activation==true);
        _;
    }
    
function  BSPAM_IECI() public {
       SP = msg.sender;
        BSPAM_IECI_Network_Activation = true;
        Registered_Clients=0;
        Provisioned_Clients=0;
        }

function Client_Registeration(address clientID, string hash_Data) onlyUsers public {
        require(BSPAM_IECI_Network_Activation = true);
        uint id = clientId[clientID];
        if (id == 0) {
            clientId[clientID] = Registered_Clients;
            id = Registered_Clients;
            clients[id] = Client({client: clientID, IPFS_hash_or_Data:hash_Data});
            Registeration_Request(clientID, hash_Data);
            Registered_Clients++;
            //numberOfUsers++;
        }
        else {
            clients[id] = Client({client: clientID, IPFS_hash_or_Data: hash_Data});
             Updated_Registeration_Request(clientID,hash_Data);
        }
    }
    
function Revoke_Client_Registeration(address clientID) onlyOwner public {
        require(BSPAM_IECI_Network_Activation = true && clientId[clientID] >= 0);
        address ad;
        for (uint i = clientId[clientID]; i<Registered_Clients-1; i++){
            clients[i] = clients[i+1];
            ad = clients[i].client;
            clientId[ad] = i;
        }
        delete clients[Registered_Clients-1];
        Registered_Clients--;
        clientId[clientID] = 0;
Registeration_Request_Revoked(clientID);
    }

    
function Service_Provisioning(address clientID, string memory clientresource, string memory clientpermission, uint Expiry) onlyOwner public {
        require(BSPAM_IECI_Network_Activation = true);
        require(clientId[clientID] >= 0);
        uint id = provisionedId[clientID];
        if (id == 0) {
            provisionedId[clientID] = Provisioned_Clients;
            id = Provisioned_Clients;
            client_provisioned[id] = Client_Provisioned({client: clientID, client_Activation: block.timestamp, Valid_Until: Expiry ,resource: clientresource, permissions: clientpermission});
            Service_Provisioned(clientID,block.timestamp,Expiry, clientresource, clientpermission);
            Provisioned_Clients++;
        }
        else {
            client_provisioned[id] = Client_Provisioned({client: clientID, client_Activation: block.timestamp, Valid_Until: Expiry, resource: clientresource, permissions: clientpermission});
        Service_Provisioned_Updated(clientID,block.timestamp, Expiry, clientresource, clientpermission);

        }
    }
    
function Service_De_Provisioning(address clientID) onlyOwner public {
        require(BSPAM_IECI_Network_Activation = true);
        require(provisionedId[clientID] >= 0);
        address ad;
        for (uint i = provisionedId[clientID]; i<Provisioned_Clients-1; i++){
            client_provisioned[i] = client_provisioned[i+1];
            ad = client_provisioned[i].client;
            provisionedId[ad] = i;
        }
        delete client_provisioned[Provisioned_Clients-1];
        Provisioned_Clients--;
        provisionedId[clientID] = 0;
        Service_De_Provisioned(clientID);
    }
    
  }
//BSPAM_IECI_SP: 0x89dC4cfb04B34729ec2854A9A72802a388c164f2
//BSPAM_IECI_Client: 0x0D83083Db7c2935Dd7708D34BeAd74Cc29ff8396