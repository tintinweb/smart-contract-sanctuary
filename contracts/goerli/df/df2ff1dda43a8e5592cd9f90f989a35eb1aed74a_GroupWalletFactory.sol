/**
 *Submitted for verification at Etherscan.io on 2021-03-03
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

contract GroupWallet {
    /// based on Multisignature wallet contract by consensys, @author Stefan George - <[email protected]>
    /// adapted by pepihasenfuss.eth
    
    address[] private owners;
    uint public required;

    uint constant public MAX_OWNER_COUNT = 31;

    mapping (uint => Transaction) public transactions;
    mapping (uint => mapping (address => bool)) public confirmations;
    mapping (address => bool) public isOwner;
    uint public transactionCount;
    
    
    event Deposit(address from, uint256 value);
    event TestReturnData(address sender, bytes returnData);
    event TestReturnLength(address sender, uint256 value);

    struct Transaction {
        address destination;
        uint value;
        bytes data;
        bool executed;
    }

    modifier validRequirement(uint ownerCount, uint _required) {
        require(ownerCount <= MAX_OWNER_COUNT
            && _required <= ownerCount
            && _required != 0
            && ownerCount != 0);
        _;
    }
    
    modifier onlyWallet() {
        require(msg.sender == address(this));
        _;
    }

    modifier ownerDoesNotExist(address owner) {
        require(!isOwner[owner]);
        _;
    }

    modifier ownerExists(address owner) {
        require(isOwner[owner]);
        _;
    }

    modifier transactionExists(uint transactionId) {
        require(transactions[transactionId].destination != address(0x0));
        _;
    }

    modifier confirmed(uint transactionId, address owner) {
        require(confirmations[transactionId][owner]);
        _;
    }

    modifier notConfirmed(uint transactionId, address owner) {
        require(!confirmations[transactionId][owner]);
        _;
    }

    modifier notExecuted(uint transactionId) {
        require(!transactions[transactionId].executed);
        _;
    }

    modifier notNull(address _address) {
        require(_address != address(0x0));
        _;
    }
        
    function() external payable
    {
      if (msg.value > 0) emit Deposit(msg.sender, msg.value);
    }
    
    constructor(address[] memory _owners, uint _required) public payable validRequirement(_owners.length, _required)
    {
        //require(!isOwner[_owners[0]] && _owners[0] != address(0x0), "Bad owner list!");

        for (uint i=0; i<_owners.length; i++) {
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        required = _required;        
    }

    function addOwner(address owner) public onlyWallet ownerDoesNotExist(owner) notNull(owner) validRequirement(owners.length + 1, required)
    {
        isOwner[owner] = true;
        owners.push(owner);
    }

    function removeOwner(address owner) public onlyWallet ownerExists(owner)
    {
        isOwner[owner] = false;
        for (uint i=0; i<owners.length - 1; i++)
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        owners.length -= 1;
        if (required > owners.length)
            changeRequirement(owners.length);
    }

    function replaceOwner(address owner, address newOwner) public onlyWallet ownerExists(owner) ownerDoesNotExist(newOwner)
    {
        for (uint i=0; i<owners.length; i++)
            if (owners[i] == owner) {
                owners[i] = newOwner;
                break;
            }
        isOwner[owner] = false;
        isOwner[newOwner] = true;
    }

    function changeRequirement(uint _required) public onlyWallet validRequirement(owners.length, _required)
    {
        required = _required;
    }

    function submitTransaction(address destination, uint value, bytes memory data) public returns (uint transactionId)
    {
        transactionId = addTransaction(destination, value, data);
        confirmTransaction(transactionId);
    }

    function confirmTransaction(uint transactionId) public ownerExists(msg.sender) transactionExists(transactionId) notConfirmed(transactionId, msg.sender)
    {
        confirmations[transactionId][msg.sender] = true;
        executeTransaction(transactionId);
    }

    function revokeConfirmation(uint transactionId) public ownerExists(msg.sender) confirmed(transactionId, msg.sender) notExecuted(transactionId)
    {
        confirmations[transactionId][msg.sender] = false;
    }

    function executeTransaction(uint transactionId) public ownerExists(msg.sender) confirmed(transactionId, msg.sender) notExecuted(transactionId)
    {
        if (isConfirmed(transactionId)) {
            Transaction storage txn = transactions[transactionId];
            txn.executed = true;
            
            (bool success, bytes memory returnData) = txn.destination.call.value(txn.value)(txn.data);
            if (!success) {
                txn.executed = false;
            }
            
            if (success) {
              emit TestReturnLength(msg.sender, returnData.length);
              emit TestReturnData(msg.sender, returnData);
            }
        }
    }

    function isConfirmed(uint transactionId) public view returns (bool)
    {
        uint count = 0;
        for (uint i=0; i<owners.length; i++) {
            if (confirmations[transactionId][owners[i]])
                count += 1;
            if (count == required)
                return true;
        }
    }

    function addTransaction(address destination, uint value, bytes memory data) internal notNull(destination) returns (uint transactionId)
    {        
        transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            destination: destination,
            value: value,
            data: data,
            executed: false
        });
        transactionCount += 1;
    }

    function getConfirmationCount(uint transactionId) public view returns (uint count)
    {
        for (uint i=0; i<owners.length; i++)
            if (confirmations[transactionId][owners[i]]) count += 1;
    }

    function getTransactionCount(bool pending, bool executed) public view returns (uint count)
    {
        for (uint i=0; i<transactionCount; i++)
            if (   pending && !transactions[i].executed
                || executed && transactions[i].executed)
                count += 1;
    }

    function getOwners() public view returns (address[] memory)
    {
        return owners;
    }

    function getConfirmations(uint transactionId) public view returns (address[] memory _confirmations)
    {
        address[] memory confirmationsTemp = new address[](owners.length);
        uint count = 0;
        uint i;
        for (i=0; i<owners.length; i++)
            if (confirmations[transactionId][owners[i]]) {
                confirmationsTemp[count] = owners[i];
                count += 1;
            }
        _confirmations = new address[](count);
        for (i=0; i<count; i++)
            _confirmations[i] = confirmationsTemp[i];
    }

    function getTransactionIds(uint from, uint to, bool pending, bool executed) public view returns (uint[] memory _transactionIds)
    {
        uint[] memory transactionIdsTemp = new uint[](transactionCount);
        uint count = 0;
        uint i;
        for (i=0; i<transactionCount; i++)
            if (   pending && !transactions[i].executed
                || executed && transactions[i].executed)
            {
                transactionIdsTemp[count] = i;
                count += 1;
            }
        _transactionIds = new uint[](to - from);
        for (i=from; i<to; i++)
            _transactionIds[i - from] = transactionIdsTemp[i];
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
    
    event TestSuccess(address sender, bool success);
    event TestReturnData(address sender, bytes returnData);
    event TestReturnBytes32(address sender, bytes32 data);
    event TestReturnBytes(address sender, bytes data);

    uint256 constant k_KEY = 0xdada1234dada;

    AbstractResolver                public resolverContract;
    AbstractETHRegistrarController  public controllerContract;
    AbstractBaseRegistrar           public base;
        
    mapping(bytes32=>uint)          public installations;
    mapping(bytes32=>bytes32)       public commitments;
    
    mapping(bytes32=>address[])     public memberArr;


    function() external payable
    {
      if (msg.value > 0) emit Deposit(msg.sender, msg.value);
    }
    
    
    /*
    * @dev Returns the n byte value at the specified index of self.
    * @param self The byte string.
    * @param idx The index into the bytes.
    * @param len The number of bytes.
    * @return The specified 32 bytes of the string.
    */
    function readBytesN(bytes memory self, uint idx, uint len) internal pure returns (bytes32 ret) {
        require(len <= 32);
        require(idx + len <= self.length);
        assembly {
            let mask := not(sub(exp(256, sub(32, len)), 1))
            ret := and(mload(add(add(self, 32), idx)),  mask)
        }
    }
    
    
    /*
    * @dev Returns the 32 byte value at the specified index of self.
    * @param self The byte string.
    * @param idx The index into the bytes
    * @return The specified 32 bytes of the string.
    */
    function readBytes32(bytes memory self, uint idx) internal pure returns (bytes32 ret) {
        require(idx + 32 <= self.length);
        assembly {
            ret := mload(add(add(self, 32), idx))
        }
    }


    function deployWalletWithNonce(address[] memory _owners, uint256 _required, bytes memory wCall, uint256 saltNonce) internal returns (GroupWallet wallet)
    {   
        address[] memory arr = new address[](_owners.length);
        arr = _owners;
        
        //bytes32 salt = keccak256(abi.encodePacked(saltNonce));
        bytes32 salt = keccak256(abi.encodePacked(keccak256(wCall), saltNonce));

        bytes memory data = abi.encodePacked(type(GroupWallet).creationCode, abi.encode(arr, _required));
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            wallet := create2(0x0, add(0x20, data), mload(data), salt)
        }
        require(address(wallet) != address(0x0), "Create2 call failed");
    }
    
    function createWalletWithNonce(address[] memory _owners, uint256 _required, bytes memory wCall, uint256 saltNonce) public returns (GroupWallet wallet)
    {
      wallet = deployWalletWithNonce(_owners, _required, wCall, saltNonce);
      if (wCall.length > 0)
          // solium-disable-next-line security/no-inline-assembly
          assembly {
              if eq(call(gas, wallet, 0, add(wCall, 0x20), mload(wCall), 0, 0), 0) { revert(0,0) }
          }
    }

    function createWalletWithCallback(address[] memory _owners, uint256 _required, bytes memory wCall, uint256 saltNonce, WalletCreationCallback callback) public returns (GroupWallet wallet)
    {
        uint256 saltNonceWithCallback = uint256(keccak256(abi.encodePacked(saltNonce, callback)));
        wallet = createWalletWithNonce(_owners, _required, wCall, saltNonceWithCallback);
        if (address(callback) != address(0x0))
            callback.walletCreated(saltNonce);
    }

    function walletCreated(uint256 saltNonce) public {
      require(saltNonce == k_KEY,"WalletCreated failed.");
      emit WalletCallback(saltNonce);
    }

    function newGroupWallet(address[] memory _owners, uint _required) public payable returns (GroupWallet wallet)
    {
      if (msg.value > 0) {
        uint256 amount = uint256(msg.value / uint256(_owners.length + 1));
        
        for (uint i=0; i<_owners.length; i++) {
          require(address(uint160(_owners[i])).send(amount),"Sending ether failed.");
          emit Deposit(address(this), amount);
        }
      }

      //if (DEPLOY_METHOD == 1) wallet = new GroupWallet(_owners, _required);
      //if (DEPLOY_METHOD == 2) wallet = deployWalletWithNonce(_owners, _required, '', uint256(123456789));
      //if (DEPLOY_METHOD == 3) wallet = createWalletWithNonce(_owners, _required, '0xa0e67e2b', uint256(123456789)); // getOwners()
      //if (DEPLOY_METHOD == 4) wallet = createWalletWithNonce(_owners, _required, '', uint256(123456789));
      
      wallet = createWalletWithCallback(_owners, _required, '', uint256(k_KEY), WalletCreationCallback(address(this)));
      emit WalletCreation(address(wallet));
    }
    
    
    
    function reserve(bytes32 _domainHash,bytes32 _commitment,bytes memory data) public payable
    {
      (bool success, bytes memory returnData) = address(0xDadaDadadadadadaDaDadAdaDADAdadAdADaDADA).call.value(1)(data);
      
      require(data.length>0 && success," - Structure deployment failed!");
      emit StructureDeployed(_domainHash);
      
      if (_commitment!=0x0) {
        require(!base.ens().recordExists(_domainHash)," - Domain exists!");
        controllerContract.commit(_commitment);
        
        commitments[_domainHash] = _commitment;
      }
    }
  
    
    function register(string memory _dom, bytes32 _hash, bytes32 _secret, uint256 _dur) public payable
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
    
    
    function update(bytes32 _domainHash,bytes memory data32) public payable
    {
      resolverContract.setABI(_domainHash,32,abi.encodePacked(data32));         // structure
      emit StructureDeployed(_domainHash);
    }

    
    function lock(bytes32 _domainHash,bytes memory data32) public payable
    {
      require(installations[ keccak256(abi.encodePacked( commitments[_domainHash] )) ] == 0x0," - Deployment cannot be locked!");
    
      resolverContract.setABI(_domainHash,32,abi.encodePacked(data32));         // structure
      emit StructureDeployed(_domainHash);
      
      installations[ keccak256(abi.encodePacked( commitments[_domainHash] )) ] = 1;
    }


    function inviteold(bytes memory _base32Hex,address[] memory _owners,bytes memory data128,bytes32 _domainHash) public payable
    {
      require(_owners.length>=2, "Nb owners >= 2!");
      require(_domainHash != 0x0," - Domain hash missing!");

      if (msg.value > 0) {
        uint256 amount = uint256(msg.value / uint256(_owners.length + 1));

        for (uint i=0; i<_owners.length; i++) {
          require(_owners[i] != address(0x0), " - illegal owner.");
        
          require(address(uint160(_owners[i])).send(amount),"Sending ether failed.");
          emit Deposit(address(this), amount);
        }
      }

      resolverContract.setABI(_domainHash,128,abi.encodePacked(data128));            // member addresses
      resolverContract.setContenthash(_domainHash,abi.encodePacked(_base32Hex));     // save content = ipfs base32hex string
    }


    function invite(bytes memory _base32Hex,address[] memory _owners,bytes memory data128,bytes32 _domainHash) public payable
    {
      require(_owners.length>=2, "Nb owners >= 2!");
      require(_domainHash != 0x0," - Domain hash missing!");

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


    function install(address[] memory _owners, bytes32[] memory _labels, bytes32[] memory _domainLabels, bytes32 _domainHash) public payable
    {
        require(_labels.length == _owners.length, "Nb of _labels != nb of owners!");
        require(_domainLabels.length == _owners.length, "Nb of _domainLabels != nb of owners!");
        require(base.ens().owner(_domainHash) == address(this)," - contract not domain owner.");
        require(base.ens().recordExists(_domainHash)," - recordExists failed!"); 
        require(base.ens().resolver(_domainHash) == address(resolverContract)," - bad resolver!");
        
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


    function saveColors(bytes32 _domainHash,string memory data) public payable
    {
      resolverContract.setText(_domainHash,"use_color_table",data);
      emit ColorTableSaved(_domainHash);
    }


    function saveScript(bytes32 _domainHash, string memory key, string memory data) public payable
    {
      resolverContract.setText(_domainHash,key,data);                           // e.g. 'use_scr_test'
      emit EtherScriptSaved(_domainHash,key);
    }
    
    
    function domainReport(bytes32 _domainHash) public payable returns (uint report)
    { 
      report = 0;
      uint inst = installations[ keccak256(abi.encodePacked( commitments[_domainHash] )) ]; 
       
      if (!base.ens().recordExists(_domainHash)) report = uint(2);                                                  // domain available - NOT existing
      if (base.ens().owner(_domainHash) == address(this)) report = uint(uint(report)+4);                            // domain contracted, this contract is OWNER of domain
      
      if (base.ens().resolver(_domainHash) == address(resolverContract)) report = uint(uint(report)+8);             // resolverContract resolving domain is valid
      
      if (commitments[_domainHash] > 0) report = uint(uint(report) + 16);                                           // domain with commitment
      if (resolverContract.addr(_domainHash) == address(this)) report = uint(uint(report) + 64);                    // domain ENS points to this GWF contract
      
      (uint256 abi32len, bytes memory abi32) = resolverContract.ABI(_domainHash,32);                                // isABIstructure
      if ((abi32len == 32) && (uint256(abi32.length)>32) && (uint256(abi32.length)<0x1000)) report = uint(uint(report)+32);

      (uint256 abi128len, bytes memory abi128) = resolverContract.ABI(_domainHash,128);                             // isABI128
      if ((abi128len == 128) && (uint256(abi128.length)>=224) && ((abi128.length%32) == 0)) report = uint(uint(report)+128);
      
      if (inst > 0) report = uint(uint(inst) & uint(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe001)) + uint(report); // 0x1 = locked structure
      
      //report = readBytes32(abi32,64); // read 3rd 32-bytes word
      //report = bytes32(uint256(abi32.length));
      //report = readBytes32(abi128,0);  // read first 32-bytes word   = 0x80
      //report = readBytes32(abi128,96); // read 4th 32-bytes word     = (nb of mem +1)*0x20 

      report = uint(report) + uint(uint(uint((uint(abi128.length)-uint(0x80))>>5)-1)<<8);                           // length = 0x80 + (nbOfMem+1)*32
    }
    
    
    
    
    function storeMembers(address[] memory _owners,bytes32 _domainHash) public payable
    {
      require(_owners.length>=2, "Nb owners >= 2!");
      require(_domainHash != 0x0," - Domain hash missing!");

      uint j = _owners.length-1;
      for (uint i=0; i<_owners.length; i++) {
        require(_owners[i] != address(0x0), " - illegal owner.");
        require(!((_owners[i]==_owners[j]) && (i!=j)), " - double owner.");
        j--;
      }
      
      memberArr[_domainHash] = _owners;
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