/**
 *Submitted for verification at Etherscan.io on 2021-04-16
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

    bytes32 internal name32;
    uint256 private ownerPrices;

    mapping (address => uint256) private balances;
    mapping (address => mapping  (address => uint256)) private allowed;

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


contract GroupWalletFactory {

    event Deposit(address from, uint256 value);
    event StructureDeployed(bytes32 domainHash);
    event ColorTableSaved(bytes32 domainHash);
    event EtherScriptSaved(bytes32 domainHash,string key);
    event ProxyTokenCreation(ProxyToken proxy);
    event SetPrices(bytes32 domainHash);
    event TransferOwner(bytes32 domainHash);
    event FreezeToken(bytes32 domainHash);
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    uint256 constant k_KEY          = 0xdada1234dada;
    uint256 constant k_aMask        = 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff;
    uint256 constant k_commitMask   = 0xffffffffffffffffffffffff0000000000000000000000000000000000000000;
    uint256 constant k_commit2Mask  = 0x0000000000000000000000000000000000000000ffffffffffffffffffffffff;
    uint256 constant k_lockedMask   = 0x0000000000000000000000010000000000000000000000000000000000000000;
    uint256 constant k_timeMask     = 0xffffffffffffffffffffffff0000000000000000000000000000000000000000;
    uint256 constant k_time2Mask    = 0x0000000000000000000000000000000000000000ffffffffffffffffffffffff;


    address constant k_add00        = address(0x0);


    AbstractResolver                public resolverContract;
    AbstractETHRegistrarController  public controllerContract;
    AbstractBaseRegistrar           public base;
        
    mapping(uint64=>uint256)        private installations;                      // installTime +  proxyTokenAddr
    mapping(bytes32=>uint256)       private commitments;                        // commitment  +  ownerAddr
    
    mapping(bytes32=>address[])     private memberArr;
    
      
    modifier byInitiatorOrMember(bytes32 domainHash) {
        uint l    = memberArr[domainHash].length;
        address o = address( uint160( commitments[domainHash] & k_aMask ) );
        
        if (l==0) {
          require(o==msg.sender, "- only initiator (domain).");
        } else
        {
          uint index = 32;
          uint i=0;
          
          do {
            if (memberArr[domainHash][i] == msg.sender) index = i;
            i++;
          } while(i<l&&index==32);
          
          require((index>=0&&index<32) || (o==msg.sender), " - illegal/unknown initiator or owner.");
        }
        _;
    }
    
  
    function getCommitment(bytes32 _domainHash) private view returns (uint64 comm) {
      return uint64( (uint256( commitments[_domainHash] & k_commitMask )>>160) & k_commit2Mask );
    }
    
    function getOwner(bytes32 _domainHash) public view returns (address iToken) {
      return address( uint160( commitments[_domainHash] & k_aMask ) );
    }
    
    function saveOwner(address _iToken, bytes32 _domainHash) private {
      commitments[ _domainHash ] = uint256(uint160(_iToken)) + uint256( commitments[_domainHash] & k_commitMask);
    }

    function saveCommitment(bytes32 input, bytes32 _domainHash) private {
      commitments[_domainHash] = uint256( (uint256(input)<<160) & k_commitMask ) + uint256( commitments[_domainHash] & k_aMask);
    }

    function getInstallTime(bytes32 _domainHash) public view returns (uint256 iTime) {
      uint256 i = uint256(installations[ getCommitment(_domainHash) ]);
      iTime = uint256( (uint256( uint256(i) & k_commitMask )>>160) & k_commit2Mask );
      return iTime;
    }

    function getProxyToken(bytes32 _domainHash) public view returns (address iOwner) {
      return address( uint160( uint256( uint256(installations[ getCommitment(_domainHash) ]) ) & k_aMask ) );
    }
    
    function saveProxyToken(address _iOwner, bytes32 _domainHash) private {
      uint64 hsh  = getCommitment(_domainHash);
      uint256 i = uint256(installations[ hsh ]);
      installations[ hsh ] = uint256(uint160(_iOwner)) + uint256(i & k_commitMask);
    }

    function saveInstallTime(uint256 input, bytes32 _domainHash) private {
      uint64 hsh  = getCommitment(_domainHash);
      uint256 i = uint256(installations[ hsh ]);
      installations[ hsh ] = uint256( (uint256(input)<<160) & k_commitMask ) + uint256(i & k_aMask);
    }

    // -------------------  owners ---------------------------------------------

    function isAddressOwner(bytes32 _dHash,address _owner) public view returns (bool) {
      uint m = memberArr[_dHash].length;
        for (uint i=0; i<m; i++) {
          if (memberArr[_dHash][i] == _owner) return true;
        }
        return false;
    }
    
    function getIsOwner(bytes32 _dHash,address _owner) external view returns (bool)
    {
      return isAddressOwner(_dHash,_owner);
    }

    function getOwners(bytes32 _dHash) public view returns (address[] memory)
    {
        return memberArr[_dHash];
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
    
    function mb32(bytes memory _data) private pure returns(bytes32 a) {
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
        
        if (len==0) return;

        // Copy remaining bytes
        uint mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    function substring(bytes memory self, uint offset, uint len) internal pure returns(bytes memory) {
        require(offset + len <= self.length,"substring!!!");

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
    
    function readBytes32(bytes memory self, uint idx) internal pure returns (bytes32 ret) {
        require(idx + 32 <= self.length);
        assembly {
            ret := mload(add(add(self, 32), idx))
        }
    }
    
    function getAddress(bytes memory d, uint off) internal pure returns(address addr) {
      return address( uint256( uint256(mb32(substring(d,off,32))) & uint256(k_aMask) ));
    }
    
    function getAmount(bytes memory d, uint off) internal pure returns(uint256 amt) {
      return uint256( mb32(substring(d,off,32)) );
    }
    
    function reserve(bytes32 _domainHash,bytes32 _commitment,bytes calldata data) external payable
    {
      (bool success, bytes memory returnData) = address(0xDadaDadadadadadaDaDadAdaDADAdadAdADaDADA).call.value(1)(data);
      
      require(data.length>64 && success && returnData.length==0 && _commitment!=0x0," - reserve/commit failed!");
      emit StructureDeployed(_domainHash);
      
      controllerContract.commit(_commitment);
      commitments[ _domainHash ] = uint256( (uint256(_commitment)<<160) & k_commitMask ) + uint256( uint160(msg.sender) & k_aMask );
    }
  
    function register(string calldata _domainName, bytes32 _domainHash, bytes32 _secret, uint256 _dur, uint256 _rentPrice) external payable
    { 
      require(address( uint160( commitments[_domainHash] & k_aMask ) )==msg.sender, "- only by initiator.");
      require(controllerContract.available(_domainName),"NOT available!");
      require(_secret!=0 && _dur!=0,"Bad duration/bad secret!");

      controllerContract.registerWithConfig.value(_rentPrice+0)(_domainName,address(this),_dur,_secret,address(resolverContract),address(this));
      resolverContract.setName(_domainHash,string(abi.encodePacked(_domainName,".eth")));
    }
    
    function update(bytes32 _domainHash,bytes calldata data32) external payable byInitiatorOrMember(_domainHash)
    {
      resolverContract.setABI(_domainHash,32,abi.encodePacked(data32));         // structure
      resolverContract.setText(_domainHash,"use_timeStamp",string(abi.encodePacked(uint64(now*1000))));
      emit StructureDeployed(_domainHash);
    }

    function lock(bytes32 _dHash,bytes calldata data32) external payable
    {
      uint256 c = commitments[_dHash];
      require(address( uint160(c & k_aMask) )==msg.sender,"- only by initiator.");                      // owner  getOwner(_dHash)
      
      require( installations[ uint64( (uint256(c & k_commitMask)>>160) & k_commit2Mask ) ] ==0x0," - Deployment cannot be locked!");  // NOT locked getInstallTime(_dHash), getCommitment(_dHash) 
      
      uint64 hsh  = uint64( (uint256(c & k_commitMask)>>160) & k_commit2Mask );
      installations[hsh] = uint256( installations[hsh] & k_aMask ) + k_lockedMask;                      // saveInstallTime(1,_dHash)

      resolverContract.setABI(_dHash,32,abi.encodePacked(data32));              // structure
      resolverContract.setText(_dHash,"use_timeStamp",string(abi.encodePacked(uint64(now*1000))));
      emit StructureDeployed(_dHash);
    }
    
    function saveColors(bytes32 _domainHash,string calldata data) external payable byInitiatorOrMember(_domainHash)
    {
      require(_domainHash != 0x0," - Domain hash missing!");
      require(base.ens().recordExists(_domainHash)," - Domain does NOT exist!");

      resolverContract.setText(_domainHash,"use_color_table",data);
      emit ColorTableSaved(_domainHash);
    }


    function saveScript(bytes32 _domainHash, string calldata key, string calldata data) external payable byInitiatorOrMember(_domainHash)
    {
      require(_domainHash != 0x0," - Domain hash missing!");
      require(base.ens().recordExists(_domainHash)," - Domain does NOT exist!");

      resolverContract.setText(_domainHash,key,data);                           // e.g. 'use_scr_test'
      emit EtherScriptSaved(_domainHash,key);
    }
    
    
    function domainReport(string calldata _dom,uint command) external payable returns (uint256 report, bytes memory structure) { 
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
      
      if (owner == k_add00) report = uint256(uint(report)+256);                                       // domain NOT owned owner = 0x000000000000000000000000000
      
      if (controllerContract.available(_dom)) report = uint256(uint(report)+512);                     // domain is available
      if (owner == address(msg.sender)) report = uint256(uint(report)+1024);                          // domain owned by default account

      report = uint256(stamp) + uint256(uint256(report)<<128) + uint256(nb<<64) + uint256(inst);      // 4 words each is 8bytes
    
      if (command == 0) return (report,abi32);
      if (command == 1) return (stamp,abi32);
      if (command == 2) return (colTable,abi32);
      if (command == 3) return (abi32len,abi32);
    }
    
    function inviteInstallToken(bytes32[] memory _mem, bytes memory data128, bytes memory data) public payable returns (ProxyToken proxy) {      
      bytes32 _dHash      = _mem[0];
      address masterCopy  = address(uint160(uint256(_mem[1])));
      //bytes32 ABIlastword = _mem[2];
      //bytes32 domName     = _mem[3];
      

      uint l = _mem.length-4;                                                   // 4 words
      uint64 time = uint64(now*1000) & uint64(0xffffffffffff0000);
      uint256 amount = uint256(msg.value / uint256((l/5) + 1));

      uint256 c = commitments[_dHash];


      {
       require(l>=10 && l<160, " - Nb owners >= 2 and <= 31!");                 // l = l*5
       require(address( uint160(c & k_aMask) )==msg.sender, "- only by initiator.");
       
       require(masterCopy != k_add00, "MasterCopy != 0x0");
       require(msg.value > 0, "ProxyToken installation needs ether!");

       resolverContract.setABI(_dHash,128,abi.encodePacked(data128));           // member addresses
      }


      {
        address o;
        bytes32 d;
        
        uint i=4;
        do {
          o = address(uint160(uint256( _mem[i] )));
          d = _mem[i+2];
          
          require(o != k_add00, " - illegal owner.");
          require(_mem[i+1] != 0x0,     " - illegal label.");
          require(d != 0x0,     " - illegal domainLabel.");
          //require(_mem[i+3] != _mem[i+4] && _mem[i+3] != _mem[i+4],     " - dummy dummy test.");

          require(address(uint160(o)).send(amount),"Sending ether failed.");
          emit Deposit(address(this), amount);
          
          base.ens().setSubnodeRecord(_dHash, _mem[i+1], address(this), address(resolverContract), time);
          resolverContract.setAddr(d,o);          
          base.ens().setOwner(d,o);
          
          memberArr[_dHash].push(o);
          
          i = i+5;
        } while (i<l&&i<165);
      }
      
      {
        proxy = new ProxyToken(masterCopy);                                     // install ProxyToken contract and call the Token contract immediately
      
        installations[ uint64( (uint256(c & k_timeMask)>>160) & k_time2Mask ) ] = uint256( uint160(address(proxy)) ) + uint256( (uint256(time+1)<<160) & k_timeMask ); // saveProxyToken(address(proxy),_dHash) && saveInstallTime(time+1,_dHash)

        bytes memory proxyCommand = abi.encodePacked("0x5de5cbe4",bytes32(uint256(32)),bytes32(uint256((l/5)+1)));
        uint i=7;
        do {
          proxyCommand = abi.encodePacked(proxyCommand,_mem[i]);
          i = i+5;
        } while (i<l&&i<165);
        
        proxyCommand = abi.encodePacked(proxyCommand,_mem[3]); // 7, 12, 17 + domainName
        //require(1==2,string(proxyCommand));
        
        
        // solium-disable-next-line security/no-inline-assembly
        assembly {
        //if eq(call(gas, proxy, amount, add(data, 0x20), mload(data), 0, 0), 0) { revert(0, 0) }
          if eq(call(gas, proxy, amount, add(proxyCommand, 0x20), mload(proxyCommand), 0, 0), 0) { revert(0, 0) }
        }
      }
      
      emit ProxyTokenCreation(proxy);
    }

    
    

    function createProxyToken(bytes32 _domainHash, address masterCopy, bytes memory data) public payable returns (ProxyToken proxy)
    {
        uint256 c = commitments[_domainHash];
        
        require(address(uint160(c & k_aMask))==msg.sender, "- only by initiator.");
        require(masterCopy != k_add00, "MasterCopy != 0x0");

        proxy = new ProxyToken(masterCopy);
        
        uint64 hsh  = uint64( (uint256(c & k_commitMask)>>160) & k_commit2Mask );
        installations[hsh] = uint256( uint160(address(proxy)) ) + uint256( uint256(installations[hsh]) & k_commitMask ); // saveProxyToken
        
        uint256 val = msg.value;
        
        if (data.length > 0)
            // solium-disable-next-line security/no-inline-assembly
            assembly {
              if eq(call(gas, proxy, val, add(data, 0x20), mload(data), 0, 0), 0) { revert(0, 0) }
            }
    
        emit ProxyTokenCreation(proxy);
    }
    
    function isInitiatorOrMember(bytes32 _dHash) private view returns (address tProxy) {
      uint256 c = commitments[_dHash];
      uint    l = memberArr[_dHash].length;
      address o = address(uint160(c & k_aMask));

      if (l==0) {                                                               // byInitiatorOrMember(_dHash)
        require(o==msg.sender, "- only initiator (domain).");
      } else
      {
        uint index = 32;
        uint i=0;
        
        do {
          if (memberArr[_dHash][i] == msg.sender) index = i;
          i++;
        } while((i<l)&&(index==32));
        
        require(((index>=0) && (index<32)) || (o==msg.sender), " - illegal/unknown initiator or owner.");
      }
      
      return address( uint160( uint256( installations[  uint64( (uint256( c & k_commitMask )>>160) & k_commit2Mask ) ] ) & k_aMask ) );
    }
    
    function transferOwner_v3m(bytes32 _dHash, bytes memory data) public payable
    { 
      address tProxy = isInitiatorOrMember(_dHash);
      
      // solium-disable-next-line security/no-inline-assembly
      assembly {
        if eq(call(gas, tProxy, 0, add(data, 0x20), mload(data), 0, 0), 0) { revert(0, 0) }
      }
      emit TransferOwner(_dHash); 
    }

    function setTokenPrices_dgw(bytes32 _dHash, bytes memory data) public payable
    { 
      address tProxy = isInitiatorOrMember(_dHash);
      
      // solium-disable-next-line security/no-inline-assembly
      assembly {
        if eq(call(gas, tProxy, 0, add(data, 0x20), mload(data), 0, 0), 0) { revert(0, 0) }
      }
      emit SetPrices(_dHash);
    }
  
    function freezeToken_LGS(bytes32 _dHash, bytes memory data) public payable
    { 
      address tProxy = isInitiatorOrMember(_dHash);
      
      // solium-disable-next-line security/no-inline-assembly
      assembly {
        if eq(call(gas, tProxy, 0, add(data, 0x20), mload(data), 0, 0), 0) { revert(0, 0) }
      }
      emit FreezeToken(_dHash);
    }
    
    function TransferToken_8uf(bytes32 _dHash, bytes memory data) public payable
    { 
      address tProxy = isInitiatorOrMember(_dHash);
      
      // solium-disable-next-line security/no-inline-assembly
      assembly {
        if eq(call(gas, tProxy, 0, add(data, 0x20), mload(data), 0, 0), 0) { revert(0, 0) }
      }
      emit Transfer(address(this), address( uint256( uint256(mb32(substring(data,4,32))) & k_aMask )), uint256( mb32(substring(data,36,32)) ) / 100);
    }

    function TransferTokenFrom_VCv(bytes32 _dHash, bytes memory data) public payable
    { 
      address tProxy = isInitiatorOrMember(_dHash);
      
      // solium-disable-next-line security/no-inline-assembly
      assembly {
        if eq(call(gas, tProxy, 0, add(data, 0x20), mload(data), 0, 0), 0) { revert(0, 0) }
      }
      emit Transfer(address( uint256( uint256(mb32(substring(data,4,32))) & k_aMask )), address( uint256( uint256(mb32(substring(data,36,32))) & k_aMask )), uint256( mb32(substring(data,68,32)) ) / 100);
    }

    constructor (AbstractETHRegistrarController _controller, AbstractResolver _resolver, AbstractBaseRegistrar _base) public {
      require(address(_controller)!=k_add00,"Bad RegController!");
      require(address(_resolver)!=k_add00,"Bad Resolver!");
      require(address(_base)!=k_add00,"Bad base!");
      
      controllerContract = _controller;
      resolverContract   = _resolver;
      base               = _base;
    }
}