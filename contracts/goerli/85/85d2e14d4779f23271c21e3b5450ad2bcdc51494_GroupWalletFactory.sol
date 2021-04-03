/**
 *Submitted for verification at Etherscan.io on 2021-04-03
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

/// @title ProxyToken - Generic proxy contract allows to execute all transactions applying the code of a master contract.
/// @author Stefan George - <[email protected]> /// adapted and applied for token by pepihasenfuss.eth
pragma solidity >=0.4.22 <0.6.0;

contract ProxyToken {
    address internal masterCopy;

    string  public name;
    bytes32 private ownerPrices;

    mapping (address => bool)    public frozenAccount;
    mapping (address => uint256) public balances;
    mapping (address => mapping  (address => uint256)) public allowed;

    constructor(address _masterCopy) public payable
    {
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


//interface WalletCreationCallback {
//  function walletCreated(uint256 saltNonce) external;
//}

contract GroupWalletFactory {

    event Deposit(address from, uint256 value);
    event WalletCreation(address wallet);
    event WalletCallback(uint256 saltNonce);
    event StructureDeployed(bytes32 domainHash);
    event ColorTableSaved(bytes32 domainHash);
    event EtherScriptSaved(bytes32 domainHash,string key);
    event ProxyTokenCreation(ProxyToken proxy);
    event SetPrices(bytes32 domainHash);
    event EstimateSetPrices(bytes32 domainHash);
    event TransferOwner(bytes32 domainHash);
    event EstimateTransferOwner(bytes32 domainHash);
    event FreezeToken(bytes32 domainHash);
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    uint256 constant k_KEY          = 0xdada1234dada;
    uint256 constant k_addressMask  = 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff;
        
    uint256 constant k_valueMask    = 0x000000000000ffffffffffff0000000000000000000000000000000000000000;
    uint256 constant k_value2Mask   = 0x0000000000000000000000000000000000000000000000000000ffffffffffff;
    
    uint256 constant k_flagsMask    = 0x0fffffffff000000000000000000000000000000000000000000000000000000;
    uint256 constant k_flags2Mask   = 0x0000000000000000000000000000000000000000000000000000000fffffffff;
    uint256 constant k_flags3Mask   = 0xf000000000ffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    
    uint256 constant k_assetMask    = 0x0000000000ff0000000000000000000000000000000000000000000000000000;
    uint256 constant k_asset2Mask   = 0x00000000000000000000000000000000000000000000000000000000000000ff;
    uint256 constant k_asset3Mask   = 0xffffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff;
    
    uint256 constant k_typeMask     = 0xf000000000000000000000000000000000000000000000000000000000000000;
    uint256 constant k_type2Mask    = 0x000000000000000000000000000000000000000000000000000000000000000f;
    
    uint256 constant k_commitMask   = 0xffffffffffffffffffffffff0000000000000000000000000000000000000000;
    uint256 constant k_commit2Mask  = 0x0000000000000000000000000000000000000000ffffffffffffffffffffffff;


    AbstractResolver                public resolverContract;
    AbstractETHRegistrarController  public controllerContract;
    AbstractBaseRegistrar           public base;
        
    mapping(uint64=>uint256)        public installations;                       // installTime +  proxyTokenAddr
    mapping(bytes32=>bytes32)       public commitments;                         // commitment  +  ownerAddr
    
    mapping(bytes32=>address[])     public memberArr;
    
    
    event TestReturnData(address sender, bytes returnData);
    event TestReturnLength(address sender, uint256 value);
    
    uint constant                  private MAX_OWNER_COUNT = 31;
    mapping (bytes32 => uint256[]) public trans32;                              // transaction long word: 32 bytes =  4 bits type, 4 bits + 4 bytes flags, 1 bytes asset, 6 bytes value, 20 bytes address = 32 bytes


    modifier byInitiator(bytes32 domainHash) {
        require(getOwner(domainHash)==msg.sender, "- only by initiator.");
        _;
    }
    
    modifier byInitiatorOrMember(bytes32 domainHash) {
    
        if (memberArr[domainHash].length==0) {
          require(getOwner(domainHash)==msg.sender, "- only initiator (domain).");
        }
        
        if (memberArr[domainHash].length>0) {
          uint index = 32;
          for (uint i=0; i<memberArr[domainHash].length; i++) {
            if (memberArr[domainHash][i] == msg.sender) index = i;
          }
          require(((index>=0) && (index<32))   || (getOwner(domainHash)==msg.sender), " - illegal/unknown initiator or owner.");
        }
        
        _;
    }
    
    
    
    function getCommitment(bytes32 _domainHash) private view returns (uint64 comm) {
      comm = uint64( (uint256( uint256( commitments[_domainHash] ) & k_commitMask )>>160) & k_commit2Mask );
      return comm;
    }
    
    function getOwner(bytes32 _domainHash) public view returns (address iToken) {
          iToken = address( uint160( uint256( commitments[_domainHash] ) & k_addressMask ) );
          return iToken;
    }
    
    function saveOwner(address _iToken, bytes32 _domainHash) private {
          uint256 i = uint256(commitments[_domainHash]);
          commitments[ _domainHash ] = bytes32(uint256(uint160(_iToken)) + uint256(i & k_commitMask));
    }

    function saveCommitment(bytes32 input, bytes32 _domainHash) private {
          uint256 i = uint256(commitments[_domainHash]);
          commitments[_domainHash] = bytes32(uint256( (uint256(input)<<160) & k_commitMask ) + uint256(i & k_addressMask));
    }


    
    function getInstallTime(bytes32 _domainHash) public view returns (uint256 iTime) {
          uint256 i = uint256(installations[ getCommitment(_domainHash) ]);
          iTime = uint256( (uint256( uint256(i) & k_commitMask )>>160) & k_commit2Mask );
          return iTime;
    }

    function getProxyToken(bytes32 _domainHash) public view returns (address iOwner) {
          uint256 i = uint256(installations[ getCommitment(_domainHash) ]);
          iOwner = address( uint160( uint256(i) & k_addressMask ) );
          return iOwner;
    }
    
    function saveProxyToken(address _iOwner, bytes32 _domainHash) private {
          uint64 hsh  = getCommitment(_domainHash);
          uint256 i = uint256(installations[ hsh ]);
          installations[ hsh ] = uint256(uint160(_iOwner)) + uint256(i & k_commitMask);
    }

    function saveInstallTime(uint256 input, bytes32 _domainHash) private {
          uint64 hsh  = getCommitment(_domainHash);
          uint256 i = uint256(installations[ hsh ]);
          installations[ hsh ] = uint256( (uint256(input)<<160) & k_commitMask ) + uint256(i & k_addressMask);
    }
  
  
    function nbOfOwners(bytes32 _dHash) private view returns (uint nb) {
      uint m = memberArr[_dHash].length;
      for (uint i=0; i<m; i++) {
        if (memberArr[_dHash][i] != address(0x0)) nb++;
      }
    }

    function isAddressOwner(bytes32 _dHash,address _owner) public view returns (bool) {
      uint m = memberArr[_dHash].length;
        for (uint i=0; i<m; i++) {
          if (memberArr[_dHash][i] == _owner) return true;
        }
        return false;
    }
    
    function getTarget(bytes32 _dHash,uint tNb) private view returns (address) {
      return address( uint160( uint256( trans32[_dHash][tNb] ) & k_addressMask ) );
    }

    function getTValue(bytes32 _dHash,uint tNb) private view returns (uint64) {
      return uint64( (uint256( uint256( trans32[_dHash][tNb] ) & k_valueMask )>>160) & k_value2Mask);
    }

    function getAsset(bytes32 _dHash,uint tNb) private view returns (uint8) {
      return uint8(  (uint256( uint256( trans32[_dHash][tNb] ) & k_assetMask )>>208) & k_asset2Mask);
    }
  
    function getFlags(bytes32 _dHash,uint tNb) private view returns (uint64) {
      return uint64( (uint256( uint256( trans32[_dHash][tNb] ) & k_flagsMask )>>216) & k_flags2Mask);
    }

    function getType(bytes32 _dHash,uint tNb) private view returns (uint8) {
      return uint8(  (uint256( uint256( trans32[_dHash][tNb] ) & k_typeMask )>>252) & k_type2Mask);
    }
    
    function getNbConfirmations(uint64 confirmFlags) private pure returns (uint8 nb) {
      uint64 m = 1;
      
      for (uint i=0; i<MAX_OWNER_COUNT; i++) {
        if ((uint64(confirmFlags) & uint64(m)) > 0) nb++;
        m = m*2;
      }
      return nb;
    }
    
    function getOwnerMask(bytes32 _dHash, address _owner) private view returns (uint64 mask) {
      mask = 32;
        
      for (uint i=0; i<MAX_OWNER_COUNT; i++) {
        if ( memberArr[_dHash][i] == _owner) return mask;
        mask = mask*2;
      }
      
      require(1==2,"Owner NOT found!");
    }
    
    function isConfirmed(bytes32 _dHash, uint _tNb) public view returns (bool) {
      uint64 f = getFlags(_dHash,_tNb);
      uint64 r = uint64(getTRequired(_dHash,trans32[_dHash].length-1));
      if (r==0) return false;
      uint64 c = getNbConfirmations( uint64(f/32) );
      return (r <= c);
    }
  
    function getTconfirmations(bytes32 _dHash, uint _tNb) public view returns (uint) {
      uint64 f = getFlags(_dHash,_tNb);      
      return getNbConfirmations(uint64(f>>5));
    }
    
    function isTExecuted(bytes32 _dHash, uint _tNb) private view returns (bool) {
      return (getAsset(_dHash,_tNb)>127);
    }
  
    function ownerConfirmed(bytes32 _dHash, uint _tNb, address _owner) private view returns (bool) {
      uint64 f = getFlags(_dHash,_tNb);
      uint64 o = getOwnerMask(_dHash,_owner);
      return (uint64(f&o)>0);
    }
    
    function getTRequired(bytes32 _dHash,uint _tId) private view returns (uint64)
    {
      if (_tId<0) return 0;
      
      uint64 f = getFlags(_dHash,_tId);
      return uint64(f & uint64(MAX_OWNER_COUNT));
    }

    function newTransaction(address _target, uint value, uint8 asset, uint64 flags, uint8 trtype) private pure returns (uint256) {
      return uint256( uint160(_target) )+uint256( (uint256(value)<<160)  & k_valueMask )+uint256( (uint256(asset)<<208)  & k_assetMask )+uint256( (uint256(flags)<<216)  & k_flagsMask )+uint256( (uint256(trtype)<<252) & k_typeMask );
    }

    
    function saveFlags(bytes32 _dHash, uint _tId, uint64 flags) private {
      trans32[_dHash][_tId] = uint256( (uint256( flags )<<216) & k_flagsMask ) + uint256( trans32[_dHash][_tId] & k_flags3Mask );
    }
    
    function saveAsset(bytes32 _dHash, uint _tId, uint8 asset) private {
      trans32[_dHash][_tId] = uint256( (uint256( asset )<<208) & k_assetMask ) + uint256( trans32[_dHash][_tId] & k_asset3Mask);
    }
    
    modifier ownerExists(bytes32 _dHash, address _owner) {
        require(isAddressOwner(_dHash,_owner),"ownerExists!!!");
        _;
    }
    
    modifier ownerDoesNotExist(bytes32 _dHash, address _owner) {
        require(!isAddressOwner(_dHash,_owner),"ownerDoesNotExist!!!");
        _;
    }

    modifier confirmed(bytes32 _dHash,uint _tNb, address _owner) {
        require(ownerConfirmed(_dHash,_tNb,_owner), "confirmed!!!");
        _;
    }

    modifier notExecuted(bytes32 _dHash,uint _tNb) {
        require(!isTExecuted(_dHash,_tNb), "notExecuted!!!");
        _;
    }
  
    modifier validRequirement(bytes32 _dHash,uint ownerCount) {
        uint64 r = getTRequired(_dHash,trans32[_dHash].length-1);
        require(ownerCount <= MAX_OWNER_COUNT
            && r <= ownerCount
            && r != 0
            && r >= 2
            && ownerCount != 0,"validRequirement!!!");
        _;
    }

    function getRequired(bytes32 _dHash) public view returns (uint count)
    { 
      if (trans32[_dHash].length==0) return 0;
      return getTRequired(_dHash,trans32[_dHash].length-1);
    }
    
    function getIsOwner(bytes32 _dHash,address _owner) public view returns (bool)
    {
      return isAddressOwner(_dHash,_owner);
    }
    
    function getTransactionsCount(bytes32 _dHash) public view returns (uint)
    {
      return trans32[_dHash].length;
    }
    
    function getTransactions(bytes32 _dHash,uint _tNb) public view returns (address destination, uint value, uint8 asset, bool executed, uint64 flags, uint8 typ, bool conf)
    {
      if (trans32[_dHash].length>0)
        return (getTarget(_dHash,_tNb),getTValue(_dHash,_tNb),getAsset(_dHash,_tNb),isTExecuted(_dHash,_tNb),getFlags(_dHash,_tNb),getType(_dHash,_tNb),isConfirmed(_dHash,_tNb));
    }
    
    function getConfirmationCount(bytes32 _dHash,uint _tNb) public view returns (uint)
    {
      return getTconfirmations(_dHash,_tNb);
    }
    
    function getTransactionCount(bytes32 _dHash,bool pending, bool executed) public view returns (uint count)
    {
      for (uint i=0; i<trans32[_dHash].length; i++)
          if (pending && !isTExecuted(_dHash,i) || executed && isTExecuted(_dHash,i))
            count += 1;
    }


    // -------------------  owners ---------------------------------------------

    function addressConfirmations(bytes32 _dHash,uint _tNb,address _owner) public view returns (bool)
    {
      return ownerConfirmed(_dHash,_tNb,_owner);
    }

    function getOwners(bytes32 _dHash) public view returns (address[] memory)
    {
        return memberArr[_dHash];
    }
    
    function addOwner(bytes32 _dHash, address _owner) public ownerDoesNotExist(_dHash,_owner) validRequirement(_dHash, nbOfOwners(_dHash) + 1)
    {
        require(msg.sender == address(this),"onlyWallet!!!");
        
        require(_owner != address(0x0),"notNull!!!");
        memberArr[_dHash].push(_owner);
    }

    function ownerChange(bytes32 _dHash, address _owner, address _newOwner) public ownerExists(_dHash,_owner) {
      
      require(msg.sender == address(this),"onlyWallet!!!");
      
      uint m = memberArr[_dHash].length;

      for (uint i=0; i<m; i++)
          if (memberArr[_dHash][i] == _owner) {
              memberArr[_dHash][i] = _newOwner;
              break;
          }
    }

    function removeOwner(bytes32 _dHash, address _owner) public
    {
      ownerChange(_dHash, _owner, address(0x0));
      
      uint m = nbOfOwners(_dHash);
      if (getTRequired(_dHash,trans32[_dHash].length-1) > m) changeRequirement(_dHash,m);
    }
    
    function replaceOwner(bytes32 _dHash, address _owner, address _newOwner) public ownerDoesNotExist(_dHash,_newOwner)
    {
      ownerChange(_dHash, _owner, _newOwner);
    }
    
    function changeRequirement(bytes32 _dHash,uint _required) public
    {
      require(msg.sender == address(this),"onlyWallet!!!");
      
      uint tId = trans32[_dHash].length-1;
      if (tId==0) return;
      
      uint64 f = getFlags(_dHash,tId);
      
      saveFlags(_dHash,tId,(uint64(f|uint64(MAX_OWNER_COUNT)) ^ uint64(MAX_OWNER_COUNT))+uint64(_required));
    }

    
    function addTransaction(bytes32 _dHash, address destination, uint value, uint8 trtype, uint8 asset) internal returns (uint tId)
    {   
      require(destination != address(0x0),"notNull!!!");
      uint64 req;
      
      tId = trans32[_dHash].length;
      
      if (tId==0) req = uint64(memberArr[_dHash].length>>1)+1;
      if (tId> 0) req = getTRequired(_dHash,tId-1);
      
      trans32[_dHash].push( newTransaction( destination, value, uint8(asset), uint64(req), uint8(trtype) ) );
    }
    

    function submitTransaction(bytes32 _dHash, address destination, uint value, uint trtype, uint asset) public ownerExists(_dHash,msg.sender) returns (uint tId)
    {
      tId = addTransaction(_dHash, destination, value, uint8(trtype), uint8(asset));
      confirmTransaction(_dHash,tId);
    }
    
  
    function confirmTransaction(bytes32 _dHash, uint _tId) public ownerExists(_dHash,msg.sender)
    {
        require(!ownerConfirmed(_dHash,_tId,msg.sender),"notConfirmed!!!");
      
        uint64 f = getFlags     (_dHash,_tId);
        uint64 o = getOwnerMask (_dHash,msg.sender);
        
        saveFlags(_dHash,_tId,uint64(f|o));

        executeTransaction(_dHash,_tId);
    }
    

    function revokeConfirmation(bytes32 _dHash,uint _tId) public ownerExists(_dHash,msg.sender) confirmed(_dHash,_tId,msg.sender) notExecuted(_dHash,_tId)
    {
      uint64 f = getFlags     (_dHash,_tId);
      uint64 o = getOwnerMask (_dHash,msg.sender);
        
      saveFlags(_dHash,_tId,uint64(f|o) ^ uint64(o));
    }
    
    
    function getConfirmations(bytes32 _dHash,uint _tId) public view returns (address[] memory _confirmations)
    {   
        uint i;
        uint m = memberArr[_dHash].length;
        address[] memory confirmationsTemp = new address[](m);
        uint count = 0;
        
        for (i=0; i<m; i++)
            if ( ownerConfirmed(_dHash,_tId,memberArr[_dHash][i]) ) {
                confirmationsTemp[count] = memberArr[_dHash][i];
                count += 1;
            }
            
        _confirmations = new address[](count);
        
        for (i=0; i<count; i++)
            _confirmations[i] = confirmationsTemp[i];
    }
    
    
    function prepareCall(bytes32 _dHash,bytes memory theCall,bytes32 val1,bytes32 val2,uint length) private pure returns (bytes memory data) {
      if (length==68) data = abi.encodePacked( bytes4(keccak256(theCall)), bytes32(_dHash), val1 );
      if (length> 68) data = abi.encodePacked( bytes4(keccak256(theCall)), bytes32(_dHash), val1, val2 );
      require(data.length==length,'prepareCall!!!');
    }
    
    
    function executeTransaction(bytes32 _dHash,uint _tId) public ownerExists(_dHash,msg.sender) confirmed(_dHash,_tId, msg.sender) notExecuted(_dHash,_tId) returns (bool success)
    {
      if (isConfirmed(_dHash,_tId)) {
          bytes memory data;
                
          uint8 typ      = getType(_dHash,_tId);
  

          if (typ == 1) {
            (bool succ,bytes memory returnData) = getTarget(_dHash,_tId).call.value(getTValue(_dHash,_tId))("");
            
            if (succ) {
              emit TestReturnLength (msg.sender, returnData.length);
              emit TestReturnData   (msg.sender, returnData);
              typ = getAsset(_dHash,_tId);
              saveAsset(_dHash,_tId,uint8(typ|uint8(128)));
            }
            return succ;
          }
          
          
          if (typ == 2) data = prepareCall(_dHash,"addOwner(bytes32,address)",   bytes32(uint256(uint160(getTarget(_dHash,_tId)))),0x0,68);   // addOwner
          
          
          if (typ == 3) data = prepareCall(_dHash,"removeOwner(bytes32,address)",bytes32(uint256(uint160(getTarget(_dHash,_tId)))),0x0,68);   // removeOwner
          
      
          if (typ == 4) {
            bytes32 oldMem;
            
            {
              address old    = memberArr[_dHash][ uint8(getAsset(_dHash,_tId)) ];
              oldMem         = bytes32(uint256(uint160(old)));
            }
            
            bytes32 newMem   = bytes32(uint256(uint160(getTarget(_dHash,_tId))));

            data = prepareCall(_dHash,"replaceOwner(bytes32,address,address)",oldMem,newMem,100);                                             // replaceOwner
          }


          if (typ == 5) {
            uint8 majority = uint8(getAsset(_dHash,_tId));
            require((majority>=2) && (majority<=MAX_OWNER_COUNT),"required only 2-31!!!");
            data = prepareCall(_dHash,"changeRequirement(bytes32,uint256)",bytes32(uint256(majority)),0x0,68);                                // changeRequirement
          }


          address target = address(this);
            
          // solium-disable-next-line security/no-inline-assembly
          assembly {
            success := call(1250000, target, 0, add(data, 0x20), mload(data), 0, 0)
          }
          
                                                                                // uint256 t = trans32[_dHash][_tId];
          require(success==true,"fail!!!");                                     // debugging:  b_String( bytes32(t), 32, true)
          
          typ = getAsset(_dHash,_tId);
          saveAsset(_dHash,_tId,uint8(typ|uint8(128)));
      }
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
      require(false,"GroupWalletFactory fallback!");
    }
    
    function char(byte b) private pure returns (byte c) {
        if (uint8(b) < uint8(10)) return byte(uint8(b) + 0x30);
        else return byte(uint8(b) + 0x57);
    }

    function b_String(bytes32 _bytes32, uint len, bool isHex) private pure returns (string memory) {
        uint8 off = 0;
        if (isHex) off = 2;
        bytes memory s = new bytes((len*2)+off);

        if (isHex) {
          s[0] = 0x30;
          s[1] = 0x78;
        }
      
        for (uint i = 0; i < len; i++) {
            byte b = byte(uint8(uint(_bytes32) / (2 ** (8 * ((len-1) - i)))));
            byte hi = byte(uint8(b) / 16);
            byte lo = byte(uint8(b) - 16 * uint8(hi));
            s[off+(2 * i)] = char(hi);
            s[off+(2 * i) + 1] = char(lo);
        }
        return string(s);
    }

    function stringMemoryTobytes32(string memory _data) private pure returns(bytes32 a) {
      assembly {
          a := mload(add(_data, 32))
      }
    }
    
    function bytesMemoryTobytes32(bytes memory _data) private pure returns(bytes32 a) {
      assembly {
          a := mload(add(_data, 32))
      }
    }
    
    function memcpy(uint dest, uint src, uint len) private pure {
        // Copy word-length chunks while possible
        for (; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    function substring(bytes memory self, uint offset, uint len) internal pure returns(bytes memory) {
        require(offset + len <= self.length);

        bytes memory ret = new bytes(len);
        uint dest;
        uint src;

        assembly {
            dest := add(ret, 32)
            src  := add(add(self, 32), offset)
        }
        memcpy(dest, src, len);

        return ret;
    }
    
    function getAddress(bytes memory d, uint off) internal pure returns(address addr) {
      return address( uint256( uint256(bytesMemoryTobytes32(substring(d,off,32))) & uint256(k_addressMask) ));
    }
    
    function getAmount(bytes memory d, uint off) internal pure returns(uint256 amt) {
      return uint256( bytesMemoryTobytes32(substring(d,off,32)) );
    }
    
    function reserve(bytes32 _domainHash,bytes32 _commitment,bytes memory data) public payable
    {
      if (data.length>0) {
        (bool success, bytes memory returnData) = address(0xDadaDadadadadadaDaDadAdaDADAdadAdADaDADA).call.value(1)(data);
      
        require(data.length>0 && success && returnData.length==0," - Structure deployment failed!");
        emit StructureDeployed(_domainHash);
      }
    
      if (_commitment!=0x0) {
        controllerContract.commit(_commitment);
        
        saveCommitment(_commitment,_domainHash);
        
        saveOwner(msg.sender,_domainHash); 
      }
    }
  
    
    function register(string memory _dom, bytes32 _domainHash, bytes32 _hash, bytes32 _secret, uint256 _dur, uint256 _rentPrice) public payable byInitiator(_domainHash)
    { 
      require(controllerContract.available(_dom),"NOT available!");
      require(_secret!=0,"Bad secret!");
      require(_dur!=0,"Bad duration!");

      controllerContract.registerWithConfig.value(_rentPrice+0)(_dom,address(this),_dur,_secret,address(resolverContract),address(this));
      resolverContract.setName(_domainHash,string(abi.encodePacked(_dom,".eth")));
    }
    
    
    function update(bytes32 _domainHash,bytes memory data32) public payable byInitiatorOrMember(_domainHash)
    {
      resolverContract.setABI(_domainHash,32,abi.encodePacked(data32));         // structure
      resolverContract.setText(_domainHash,"use_timeStamp",string(abi.encodePacked(uint64(now*1000))));
      emit StructureDeployed(_domainHash);
    }

    
    function lock(bytes32 _domainHash,bytes memory data32) public payable byInitiator(_domainHash)
    {
      require(getInstallTime(_domainHash) == 0x0," - Deployment cannot be locked!");
      saveInstallTime(1,_domainHash);
      return update(_domainHash,data32);
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

      bool hasCommitment = uint64(getCommitment(dHash))>0x0;
      
      uint256 inst = getInstallTime(dHash);
      
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
      
      if (getProxyToken(dHash) != 0x0000000000000000000000000000000000000000) report = uint256(uint(report)+4096);
      
      if (owner == address(0x0)) report = uint256(uint(report)+256);                                  // domain NOT owned owner = 0x000000000000000000000000000
      
      if (controllerContract.available(_dom)) report = uint256(uint(report)+512);                     // domain is available
      if (owner == address(msg.sender)) report = uint256(uint(report)+1024);                          // domain owned by default account

      report = uint256(stamp) + uint256(uint256(report)<<128) + uint256(nb<<64) + uint256(inst);      // 4 words each is 8bytes
    
      if (command == 0) return (report,abi32);
      if (command == 1) return (stamp,abi32);
      if (command == 2) return (colTable,abi32);
      if (command == 3) return (abi32len,abi32);
    }
    
    
    
    function inviteInstallToken(address[] memory _owners, bytes32[] memory _labels, bytes32[] memory _domainLabels, bytes memory data128, bytes memory data, bytes32 _domainHash, address masterCopy) public payable validOwners(_owners) byInitiator(_domainHash) returns (ProxyToken proxy) {      
      require(_labels.length       == _owners.length, "Nb of _labels != nb of owners!");
      require(_domainLabels.length == _owners.length, "Nb of _domainLabels != nb of owners!");
      require(masterCopy != address(0x0), "MasterCopy != 0x0");
      require(msg.value > 0, "Installation needs ether!");

      uint64 time = uint64(now*1000) & uint64(0xffffffffffff0000);
      uint256 amount = uint256(msg.value / uint256(_owners.length + 1));
      
      for (uint i=0; i<_owners.length; i++) {
        require(_owners[i] != address(0x0), " - illegal owner.");
        require(_labels[i] != 0x0, " - illegal label.");
        require(_domainLabels[i] != 0x0, " - illegal domainLabel.");

        require(address(uint160(_owners[i])).send(amount),"Sending ether failed.");
        emit Deposit(address(this), amount);
        
        base.ens().setSubnodeRecord(_domainHash, _labels[i], address(this), address(resolverContract), time);
        resolverContract.setAddr(_domainLabels[i], _owners[i]);          
        base.ens().setOwner(_domainLabels[i], _owners[i]);
      }
      
      memberArr[_domainHash] = _owners;
      resolverContract.setABI(_domainHash,128,abi.encodePacked(data128));       // member addresses
      saveInstallTime(time+1,_domainHash);
      
      proxy = new ProxyToken(masterCopy);                                       // install ProxyToken contract and call the Token contract immediately
      saveProxyToken(address(proxy),_domainHash);
            
      if (data.length > 0)
          // solium-disable-next-line security/no-inline-assembly
          assembly {
            if eq(call(gas, proxy, amount, add(data, 0x20), mload(data), 0, 0), 0) { revert(0, 0) }
          }
        
      emit ProxyTokenCreation(proxy);
    }

    
    
    
    function createProxyToken(bytes32 _domainHash, address masterCopy, bytes memory data) public payable byInitiator(_domainHash) returns (ProxyToken proxy)
    {
        require(masterCopy != address(0x0), "MasterCopy != 0x0");

        proxy = new ProxyToken(masterCopy);
        
        saveProxyToken(address(proxy),_domainHash);
        
        uint256 val = msg.value;
        
        if (data.length > 0)
            // solium-disable-next-line security/no-inline-assembly
            assembly {
              if eq(call(gas, proxy, val, add(data, 0x20), mload(data), 0, 0), 0) { revert(0, 0) }
            }
    
        emit ProxyTokenCreation(proxy);
    }
    

    function setTokenProxy(bytes32 _domainHash, address tokenProxy, uint256 setProxyCommand, bytes memory data) public payable byInitiatorOrMember(_domainHash) returns (uint256)
    { 
      //revert(string(abi.encodePacked( b_String(bytes32( uint256( gasleft() ) ),32,true)))); // debugging
      //require(1==2,b_String(bytesMemoryTobytes32(substring(data,36,32)),32,true)); // debugging
      
      
      require(getProxyToken(_domainHash)==tokenProxy,"bad TokenProxy!");


      // solium-disable-next-line security/no-inline-assembly
      assembly {
        if eq(call(gas, tokenProxy, 0, add(data, 0x20), mload(data), 0, 0), 0) { revert(0, 0) }
      }
      
      if (setProxyCommand == 1) emit FreezeToken          (_domainHash);
      if (setProxyCommand == 2) emit EstimateSetPrices    (_domainHash);
      if (setProxyCommand == 3) emit EstimateTransferOwner(_domainHash);
      if (setProxyCommand == 4) emit TransferOwner        (_domainHash);
      if (setProxyCommand == 5) emit SetPrices            (_domainHash);  
      
      if (setProxyCommand == 6) emit Transfer (address(this),getAddress(data,4),getAmount(data,36)/100);       // transfer
      
      if (setProxyCommand == 7) emit Transfer (getAddress(data,4),getAddress(data,36),getAmount(data,68)/100); // transferFrom
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