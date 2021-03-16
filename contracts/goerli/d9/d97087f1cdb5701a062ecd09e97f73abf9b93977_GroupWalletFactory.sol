/**
 *Submitted for verification at Etherscan.io on 2021-03-16
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.22 <0.6.0;

interface ENS {
  event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);
  event Transfer(bytes32 indexed node, address owner);
  event NewResolver(bytes32 indexed node, address resolver);
  event NewTTL(bytes32 indexed node, uint64 ttl);
  event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

  function setRecord(bytes32 node, address owner, address resolver, uint64 ttl) external;
  function setSubnodeRecord(bytes32 node, bytes32 label, address owner, address resolver, uint64 ttl) external;
  function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external returns(bytes32);
  function setResolver(bytes32 node, address resolver) external;
  function setOwner(bytes32 node, address owner) external;
  function setTTL(bytes32 node, uint64 ttl) external;
  function setApprovalForAll(address operator, bool approved) external;
  function owner(bytes32 node) external view returns (address);
  function resolver(bytes32 node) external view returns (address);
  function ttl(bytes32 node) external view returns (uint64);
  function recordExists(bytes32 node) external view returns (bool);
  function isApprovedForAll(address ensowner, address operator) external view returns (bool);
}

contract AbstractBaseRegistrar {
  event NameMigrated(uint256 indexed id, address indexed owner, uint expires);
  event NameRegistered(uint256 indexed id, address indexed owner, uint expires);
  event NameRenewed(uint256 indexed id, uint expires);

  bytes32 public baseNode;   // The namehash of the TLD this registrar owns (eg, .eth)
  ENS public ens;
}

contract AbstractETHRegistrarController {
  mapping(bytes32=>uint) public commitments;

  uint public minCommitmentAge;
  uint public maxCommitmentAge;

  event NameRegistered(string name, bytes32 indexed label, address indexed owner, uint cost, uint expires);
  event NameRenewed(string name, bytes32 indexed label, uint cost, uint expires);
  event NewPriceOracle(address indexed oracle);

  function rentPrice(string memory name, uint duration) view public returns(uint);
  function makeCommitmentWithConfig(string memory name, address owner, bytes32 secret, address resolver, address addr) pure public returns(bytes32);
  function commit(bytes32 commitment) public;
  function register(string calldata name, address owner, uint duration, bytes32 secret) external payable;
  function registerWithConfig(string memory name, address owner, uint duration, bytes32 secret, address resolver, address addr) public payable;
  function available(string memory name) public view returns(bool);
}

contract AbstractResolver {
  mapping(bytes32=>bytes) hashes;

  event AddrChanged(bytes32 indexed node, address a);
  event AddressChanged(bytes32 indexed node, uint coinType, bytes newAddress);
  event NameChanged(bytes32 indexed node, string name);
  event ABIChanged(bytes32 indexed node, uint256 indexed contentType);
  event PubkeyChanged(bytes32 indexed node, bytes32 x, bytes32 y);
  event TextChanged(bytes32 indexed node, string indexed indexedKey, string key);
  event ContenthashChanged(bytes32 indexed node, bytes hash);
  
  function ABI(bytes32 node, uint256 contentTypes) external view returns (uint256, bytes memory);
  function addr(bytes32 node) external view returns (address);
  function addr(bytes32 node, uint coinType) external view returns(bytes memory);
  function contenthash(bytes32 node) external view returns (bytes memory);
  function dnsrr(bytes32 node) external view returns (bytes memory);
  function name(bytes32 node) external view returns (string memory);
  function pubkey(bytes32 node) external view returns (bytes32 x, bytes32 y);
  function text(bytes32 node, string calldata key) external view returns (string memory);
  function interfaceImplementer(bytes32 node, bytes4 interfaceID) external view returns (address);

  function setABI(bytes32 node, uint256 contentType, bytes calldata data) external;
  function setAddr(bytes32 node, address r_addr) external;
  function setAddr(bytes32 node, uint coinType, bytes calldata a) external;
  function setContenthash(bytes32 node, bytes calldata hash) external;
  function setDnsrr(bytes32 node, bytes calldata data) external;
  function setName(bytes32 node, string calldata _name) external;
  function setPubkey(bytes32 node, bytes32 x, bytes32 y) external;
  function setText(bytes32 node, string calldata key, string calldata value) external;
  function setInterface(bytes32 node, bytes4 interfaceID, address implementer) external;

  function supportsInterface(bytes4 interfaceID) external pure returns (bool);
  
  function setAuthorisation(bytes32 node, address target, bool isAuthorised) external;
}

/// @title Proxy - Generic proxy contract allows to execute all transactions applying the code of a master contract.
/// @author Stefan George - <[email protected]> /// adapted by pepihasenfuss.eth
pragma solidity >=0.4.22 <0.6.0;

contract Proxy {
    address internal masterCopy;

    string  public constant standard    = 'ERC-20';
    string  public constant symbol      = "shares";
    uint8   public constant decimals    = 2;
    uint256 public constant totalSupply = 1000000;

    string  public name;
    address public owner;
    bytes32 public dHash;

    mapping (address => bool)    public frozenAccount;
    mapping (address => uint256) public balances;
    mapping (address => mapping  (address => uint256)) public allowed;

    uint256 public sellPrice =  20000;
    uint256 public buyPrice  =  20000;


    constructor(address _masterCopy) public payable
    {
      require(_masterCopy != address(0x0), "MasterCopy != 0x0");
      masterCopy = _masterCopy;
    }
    
    function () external payable
    {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let masterCopy := and(sload(0), 0xffffffffffffffffffffffffffffffffffffffff)
            if eq(calldataload(0), 0xa619486e00000000000000000000000000000000000000000000000000000000) {
                mstore(0, masterCopy)
                return(0, 0x20)
            }

            calldatacopy(0, 0, calldatasize())
            let success := delegatecall(gas, masterCopy, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            if eq(success, 0) { revert(0, returndatasize()) }
            return(0, returndatasize())
        }
    }
}


interface WalletCreationCallback {
  function walletCreated(uint256 saltNonce) external;
}

contract GroupWalletFactory {

    event Deposit(address from, uint256 value);
    event WalletCreation(address wallet);
    event WalletCallback(uint256 saltNonce);
    event StructureDeployed(bytes32 domainHash);
    event ColorTableSaved(bytes32 domainHash);
    event EtherScriptSaved(bytes32 domainHash,string key);
    event ProxyCreation(Proxy proxy);
    
    event TestSuccess(address sender, bool success);
    event TestReturnData(address sender, bytes returnData);
    event TestReturnBytes32(address sender, bytes32 data);
    event TestReturnBytes(address sender, bytes data);

    uint256 constant k_KEY          = 0xdada1234dada;

    AbstractResolver                public resolverContract;
    AbstractETHRegistrarController  public controllerContract;
    AbstractBaseRegistrar           public base;
        
    mapping(bytes32=>uint256)       public installations;
    mapping(bytes32=>bytes32)       public commitments;
    
    mapping(bytes32=>address)       public ownersAddr;
    mapping(bytes32=>address[])     public memberArr;
    mapping(bytes32=>address)       public proxyTokenAddr;

    
    modifier onlyInitiator(string memory _dom) {
        require(ownersAddr[keccak256(abi.encodePacked(base.baseNode(),keccak256(bytes(_dom))))]==msg.sender, "- only initiator.");
        _;
    }

    modifier byInitiator(bytes32 domainHash) {
        require(ownersAddr[domainHash]==msg.sender, "- only by initiator.");
        _;
    }
    
    modifier byInitiatorOrMember(bytes32 domainHash) {
    
        if (memberArr[domainHash].length==0) {
          require(ownersAddr[domainHash]==msg.sender, "- only initiator (domain).");
        }
        
        if (memberArr[domainHash].length>0) {
          uint index = 32;
          for (uint i=0; i<memberArr[domainHash].length; i++) {
            if (memberArr[domainHash][i] == msg.sender) index = i;
          }
          require(((index>=0) && (index<32)) || (ownersAddr[domainHash]==msg.sender), " - illegal/unknown initiator or owner.");
        }
        
        _;
    }
    
    modifier validOwners(address[] memory _owners) {
          require(_owners.length>=2 && _owners.length<32, " - Nb owners >= 2 and <= 31!");
        _;
    }
  
    modifier validDomain(bytes32 _domainHash) {
          require(_domainHash != 0x0," - Domain hash missing!");
          require(base.ens().recordExists(_domainHash)," - Domain does NOT exist!");
        _;
    }
  

    function() external payable
    {
      if (msg.value > 0) emit Deposit(msg.sender, msg.value);
    }
    
    
    function stringMemoryTobytes32(string memory _data) private pure returns(bytes32 a) {
      assembly {
          a := mload(add(_data, 32))
      }
    }

  //  function createWalletWithCallback(address[] memory _owners, uint256 _required, bytes memory wCall, uint256 saltNonce, WalletCreationCallback callback) public validOwners(_owners) returns (GroupWallet wallet)
  //  {
  //      uint256 saltNonceWithCallback = uint256(keccak256(abi.encodePacked(saltNonce, callback)));
  //      wallet = createWalletWithNonce(_owners, _required, wCall, saltNonceWithCallback);
  //      if (address(callback) != address(0x0))
  //          callback.walletCreated(saltNonce);
  //  }

    function walletCreated(uint256 saltNonce) public {
      require(saltNonce == k_KEY,"WalletCreated failed.");
      emit WalletCallback(saltNonce);
    }

  //  function newGroupWallet(address[] memory _owners, uint _required) public payable validOwners(_owners) returns (GroupWallet wallet)
  //  {
  //    if (msg.value > 0) {
  //      uint256 amount = uint256(msg.value / uint256(_owners.length + 1));
  //      
  //      for (uint i=0; i<_owners.length; i++) {
  //        require(address(uint160(_owners[i])).send(amount),"Sending ether failed.");
  //        emit Deposit(address(this), amount);
  //      }
  //    }

      //if (DEPLOY_METHOD == 1) wallet = new GroupWallet(_owners, _required);
      //if (DEPLOY_METHOD == 2) wallet = deployWalletWithNonce(_owners, _required, '', uint256(123456789));
      //if (DEPLOY_METHOD == 3) wallet = createWalletWithNonce(_owners, _required, '0xa0e67e2b', uint256(123456789)); // getOwners()
      //if (DEPLOY_METHOD == 4) wallet = createWalletWithNonce(_owners, _required, '', uint256(123456789));
      
  //    //wallet = createWalletWithCallback(_owners, _required, '', uint256(k_KEY), WalletCreationCallback(address(this)));
  //    emit WalletCreation(address(wallet));
  //  }
    
    
    
    function reserve(bytes32 _domainHash,bytes32 _commitment,bytes memory data) public payable
    {
      (bool success, bytes memory returnData) = address(0xDadaDadadadadadaDaDadAdaDADAdadAdADaDADA).call.value(1)(data);
      emit TestReturnData(msg.sender,returnData);
      
      require(data.length>0 && success && returnData.length==0," - Structure deployment failed!");
      emit StructureDeployed(_domainHash);
      
      if (_commitment!=0x0) {
        require(!base.ens().recordExists(_domainHash)," - Domain exists!");
        controllerContract.commit(_commitment);
        
        commitments[_domainHash] = _commitment;
        ownersAddr[_domainHash]  = msg.sender;
      }
    }
  
    
    function register(string memory _dom, bytes32 _hash, bytes32 _secret, uint256 _dur) public payable onlyInitiator(_dom)
    { 

      require(controllerContract.available(_dom),"NOT available!");
      require(_secret!=0,"Bad secret!");
      require(_dur!=0,"Bad duration!");

      uint min = controllerContract.minCommitmentAge();
      uint max = controllerContract.maxCommitmentAge();

      bytes32 dHash = keccak256(abi.encodePacked(base.baseNode(), keccak256(bytes(_dom))));

      uint rentPrice = controllerContract.rentPrice(_dom,_dur);
      require(address(this).balance>=rentPrice,"Contract NOT enough ether!");
      
      uint com = controllerContract.commitments( commitments[dHash] );
      require(com>0,"NO commitment found!");
      require(now>com+min&&now<com+max,"Wait 60 seconds - up to 24h !");

      controllerContract.registerWithConfig.value(rentPrice+0)(_dom,address(this),_dur,_secret,address(resolverContract),address(this));
      require(resolverContract.addr(dHash) == address(this), "register failed!");
      
      resolverContract.setName(dHash,string(abi.encodePacked(_dom,".eth")));
      if (_hash!=0) resolverContract.setContenthash(dHash,abi.encodePacked(_hash));// save content = structure hash

      base.ens().setTTL(dHash,uint64(now*1000));
    }
    
    
    function update(bytes32 _domainHash,bytes memory data32) public payable validDomain(_domainHash) byInitiatorOrMember(_domainHash)
    {
      resolverContract.setABI(_domainHash,32,abi.encodePacked(data32));         // structure
      
      resolverContract.setText(_domainHash,"use_timeStamp",string(abi.encodePacked(uint64(now*1000))));

      emit StructureDeployed(_domainHash);
    }

    
    function lock(bytes32 _domainHash,bytes memory data32) public payable validDomain(_domainHash) byInitiator(_domainHash)
    {
      require(installations[ keccak256(abi.encodePacked( commitments[_domainHash] )) ] == 0x0," - Deployment cannot be locked!");
    
      resolverContract.setABI(_domainHash,32,abi.encodePacked(data32));         // structure
      resolverContract.setText(_domainHash,"use_timeStamp",string(abi.encodePacked(uint64(now*1000))));

      emit StructureDeployed(_domainHash);
      
      installations[ keccak256(abi.encodePacked( commitments[_domainHash] )) ] = 1;
    }


    function invite(bytes memory _base32Hex,address[] memory _owners,bytes memory data128,bytes32 _domainHash) public payable validOwners(_owners) validDomain(_domainHash) byInitiator(_domainHash)
    {
      uint256 amount = 1;
      if (msg.value > 0) {
        amount = uint256(msg.value / uint256(_owners.length + 1));
      }

      uint j = _owners.length-1;
      
      for (uint i=0; i<_owners.length; i++) {
        require(_owners[i] != address(0x0), " - illegal owner.");
        require(!((_owners[i]==_owners[j]) && (i!=j)), " - double owner.");
        
        j--;
        
        if (msg.value > 0) {
          require(address(uint160(_owners[i])).send(amount),"Sending ether failed.");
          emit Deposit(address(this), amount);
        }
      }
      
      memberArr[_domainHash] = _owners;
      
      resolverContract.setABI(_domainHash,128,abi.encodePacked(data128));            // member addresses
      resolverContract.setContenthash(_domainHash,abi.encodePacked(_base32Hex));     // save content = ipfs base32hex string
    }


    function install(address[] memory _owners, bytes32[] memory _labels, bytes32[] memory _domainLabels, bytes32 _domainHash) public payable validOwners(_owners) validDomain(_domainHash) byInitiatorOrMember(_domainHash)
    {
        require(_labels.length                   == _owners.length, "Nb of _labels != nb of owners!");
        require(_domainLabels.length             == _owners.length, "Nb of _domainLabels != nb of owners!");
        require(base.ens().owner(_domainHash)    == address(this)," - contract not domain owner.");
        require(base.ens().resolver(_domainHash) == address(resolverContract)," - bad resolver!");
        require(base.ens().recordExists(_domainHash)," - recordExists failed!"); 
        
        uint64 time = uint64(now*1000);
        
        for (uint i=0; i<_owners.length; i++) {
          require(_labels[i] != 0x0, " - illegal label.");
          require(_domainLabels[i] != 0x0, " - illegal domainLabel.");
          base.ens().setSubnodeRecord(_domainHash, _labels[i], address(this), address(resolverContract), time);
          resolverContract.setAddr(_domainLabels[i], _owners[i]);          
          base.ens().setOwner(_domainLabels[i], _owners[i]);
        }
  
        installations[ keccak256(abi.encodePacked( commitments[_domainHash] )) ] = time+1;
    }


    function saveColors(bytes32 _domainHash,string memory data) public payable validDomain(_domainHash) byInitiatorOrMember(_domainHash)
    {
      resolverContract.setText(_domainHash,"use_color_table",data);
      emit ColorTableSaved(_domainHash);
    }


    function saveScript(bytes32 _domainHash, string memory key, string memory data) public payable validDomain(_domainHash) byInitiatorOrMember(_domainHash)
    {
      resolverContract.setText(_domainHash,key,data);                           // e.g. 'use_scr_test'
      emit EtherScriptSaved(_domainHash,key);
    }
    
    
    function domainReport(string memory _dom,uint command) public payable returns (uint256 report, bytes memory structure) { 
      uint256 nb = 32;
      uint256 stamp = 0;
      uint256 colTable = 0;
      uint256 abi32len = 0;
      address owner;
      bytes memory abi32;
      
      bytes32 dHash = keccak256(abi.encodePacked(base.baseNode(), keccak256(bytes(_dom))));

      bool hasCommitment = uint256(commitments[dHash])>0x0;
      
      uint256 inst = installations[ keccak256(abi.encodePacked( commitments[dHash] )) ];
      owner = base.ens().owner(dHash);
       
      report = uint256(inst & 0x1);                                                                   // locked group
      if (!base.ens().recordExists(dHash)) report = uint256(uint(report)+2);                          // domain available - NOT existing
      if (owner == address(this)) report = uint256(uint(report)+4);                                   // domain contracted, this contract is OWNER of domain
      
      if (base.ens().resolver(dHash) == address(resolverContract)) report = uint256(uint(report)+8);  // resolverContract resolving domain is valid
      
      if (hasCommitment) report = uint256(uint(report) + 16);                                         // domain with commitment
      if (resolverContract.addr(dHash) == address(this)) report = uint256(uint(report) + 64);         // domain ENS points to this GWF contract
      
      if (hasCommitment) {
        (abi32len, abi32) = resolverContract.ABI(dHash,32);                                           // isABIstructure
        if ((abi32len == 32) && (uint256(abi32.length)>32) && (uint256(abi32.length)<0x1000)) report = uint256(uint(report)+32);

        (uint256 abi128len, bytes memory abi128) = resolverContract.ABI(dHash,128);                   // isABI128
        if ((abi128len == 128) && (uint256(abi128.length)>=224) && ((abi128.length%32) == 0)) report = uint256(uint(report)+128);

        if (abi128.length>0) nb = uint256(uint256((uint256(abi128.length)-uint256(0x80))>>5)-1);      // nb of members derived from ABI128 // abi128len = 0x80 + (nbOfMem+1)*32

        stamp = uint256(stringMemoryTobytes32(resolverContract.text(dHash,"use_timeStamp")));
        if (stamp==0x0000000d7573655f74696d655374616d70000000000000000000000000000000) stamp = 0;
      }
      
      colTable = uint256(stringMemoryTobytes32(resolverContract.text(dHash,"use_color_table")));
      if (colTable!=0x0000000f7573655f636f6c6f725f7461626c6500000000000000000000000000) report = uint256(uint(report)+2048);
      
      if (owner == address(0x0)) report = uint256(uint(report)+256);                                  // domain NOT owned owner = 0x000000000000000000000000000
      
      if (controllerContract.available(_dom)) report = uint256(uint(report)+512);                     // domain is available
      if (owner == address(msg.sender)) report = uint256(uint(report)+1024);                          // domain owned by default account

      report = uint256(stamp) + uint256(uint256(report)<<128) + uint256(nb<<64) + uint256(inst);      // 4 words each is 8bytes
    
      if (command == 0) return (report,abi32);
      if (command == 1) return (stamp,abi32);
      if (command == 2) return (colTable,abi32);
      if (command == 3) return (abi32len,abi32);
    }
    
    
    function createProxy(bytes32 _domainHash, address masterCopy, bytes memory data) public payable returns (Proxy proxy)
    {
        proxy = new Proxy(masterCopy);
        
        proxyTokenAddr[_domainHash] = address(proxy);
        uint256 val = msg.value;
        
        if (data.length > 0)
            // solium-disable-next-line security/no-inline-assembly
            assembly {
              if eq(call(gas, proxy, val, add(data, 0x20), mload(data), 0, 0), 0) { revert(0, 0) }
            }
        emit ProxyCreation(proxy);
    }

    
    constructor (AbstractETHRegistrarController _controller, AbstractResolver _resolver, AbstractBaseRegistrar _base) public {
      require(address(_controller)!=address(0x0),"Bad RegController!");
      require(address(_resolver)!=address(0x0),"Bad Resolver!");
      require(address(_base)!=address(0x0),"Bad base!");
      
      controllerContract = _controller;
      resolverContract   = _resolver;
      base               = _base;
    }

}