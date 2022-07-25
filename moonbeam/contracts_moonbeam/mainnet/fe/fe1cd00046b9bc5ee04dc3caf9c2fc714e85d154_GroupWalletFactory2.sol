/**
 *Submitted for verification at moonbeam.moonscan.io on 2022-05-25
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9 <0.8.10;

// ungravel.eth, GroupWallet, GroupWalletMaster, GroupWalletFactory, ProxyWallet, TokenMaster, ProxyToken by pepihasenfuss.eth 2017-2022, Copyright (c) 2022

// GroupWallet and ungravel is entirely based on Ethereum Name Service, "ENS", the domain name registry.

//   ENS, ENSRegistryWithFallback, PublicResolver, Resolver, FIFS-Registrar, Registrar, AuctionRegistrar, BaseRegistrar, ReverseRegistrar, DefaultReverseResolver, ETHRegistrarController,
//   PriceOracle, SimplePriceOracle, StablePriceOracle, ENSMigrationSubdomainRegistrar, CustomRegistrar, Root, RegistrarMigration are contracts of "ENS", by Nick Johnson. ENS-License:
//
//   Copyright (c) 2018, True Names Limited
//
//   Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//   The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

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

abstract contract AbstractENS {
  event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);
  event Transfer(bytes32 indexed node, address owner);
  event NewResolver(bytes32 indexed node, address resolver);
  event NewTTL(bytes32 indexed node, uint64 ttl);
  event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

  function setRecord(bytes32 node, address owner, address resolver, uint64 ttl) external virtual;
  function setSubnodeRecord(bytes32 node, bytes32 label, address owner, address resolver, uint64 ttl) external virtual;
  function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external virtual returns(bytes32);
  function setResolver(bytes32 node, address resolver) external virtual;
  function setOwner(bytes32 node, address owner) external virtual;
  function setApprovalForAll(address operator, bool approved) external virtual;
  function owner(bytes32 node) public view virtual returns (address);
  function recordExists(bytes32 node) external virtual view returns (bool);
  function isApprovedForAll(address ensowner, address operator) external virtual view returns (bool);
}

abstract contract AbstractReverseRegistrar {
  function claim(address owner) external virtual returns (bytes32);
  function claimWithResolver(address owner, address resolver) external virtual returns (bytes32);
  function setName(string memory name) external virtual returns (bytes32);
  function node(address addr) external virtual pure returns (bytes32);
}

abstract contract AbstractBaseRegistrar {
  event NameMigrated(uint256 indexed id, address indexed owner, uint expires);
  event NameRegistered(uint256 indexed id, address indexed owner, uint expires);
  event NameRenewed(uint256 indexed id, uint expires);

  bytes32 public baseNode;   // The namehash of the TLD this registrar owns eg, (.)eth
  ENS public ens;
}

abstract contract AbstractGroupWalletProxy {
  function getIsOwner(address _owner) external virtual view returns (bool);
  function getOwners()                external virtual view returns (address[] memory);
  function newProxyGroupWallet_j5O(address[] calldata _owners) external virtual payable;
}

abstract contract AbstractTokenProxy {
  function newToken(uint256[] calldata _data) external virtual payable;
}

abstract contract AbstractETHRegistrarController {
  mapping(bytes32=>uint) public commitments;

  uint public minCommitmentAge;
  uint public maxCommitmentAge;

  event NameRegistered(string name, bytes32 indexed label, address indexed owner, uint cost, uint expires);
  event NameRenewed(string name, bytes32 indexed label, uint cost, uint expires);
  event NewPriceOracle(address indexed oracle);

  function rentPrice(string memory name, uint duration) view external virtual returns(uint);
  function makeCommitmentWithConfig(string memory name, address owner, bytes32 secret, address resolver, address addr) pure external virtual returns(bytes32);
  function commit(bytes32 commitment) external virtual;
  function register(string calldata name, address owner, uint duration, bytes32 secret) external virtual payable;
  function registerWithConfig(string memory name, address owner, uint duration, bytes32 secret, address resolver, address addr) external virtual payable;
  function available(string memory name) external virtual view returns(bool);
}

abstract contract AbstractResolver {
  mapping(bytes32=>bytes) hashes;

  event AddrChanged(bytes32 indexed node, address a);
  event AddressChanged(bytes32 indexed node, uint coinType, bytes newAddress);
  event NameChanged(bytes32 indexed node, string name);
  event ABIChanged(bytes32 indexed node, uint256 indexed contentType);
  event PubkeyChanged(bytes32 indexed node, bytes32 x, bytes32 y);
  event TextChanged(bytes32 indexed node, string indexed indexedKey, string key);
  event ContenthashChanged(bytes32 indexed node, bytes hash);
  
  function ABI(bytes32 node, uint256 contentTypes) external virtual view returns (uint256, bytes memory);
  function addr(bytes32 node) external virtual view returns (address);
  function addr(bytes32 node, uint coinType) external virtual view returns(bytes memory);
  function name(bytes32 node) external virtual view returns (string memory);
  function text(bytes32 node, string calldata key) external virtual view returns (string memory);

  function setABI(bytes32 node, uint256 contentType, bytes calldata data) external virtual;
  function setAddr(bytes32 node, address r_addr) external virtual;
  function setAddr(bytes32 node, uint coinType, bytes calldata a) external virtual;
  function setName(bytes32 node, string calldata _name) external virtual;
  function setText(bytes32 node, string calldata key, string calldata value) external virtual;
}


/// @title Proxy - Generic proxy contract allows to execute all transactions applying the code of a master contract.
/// @author Stefan George - <[email protected]> /// ProxyToken adapted and applied for shares and token by pepihasenfuss.eth
pragma solidity ^0.8.9 <0.8.10;

contract ProxyToken {
    address internal masterCopy;

    bytes32 internal name32;
    uint256 private ownerPrices;

    mapping (address => uint256) private balances;
    mapping (address => mapping  (address => uint256)) private allowed;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event FrozenFunds(address target, bool frozen);
    event Deposit(address from, uint256 value);
    event Deployment(address owner, address theContract);
    event Approval(address indexed owner,address indexed spender,uint256 value);

    constructor(address _masterCopy) payable
    {
      masterCopy = _masterCopy;
    }
    
    fallback () external payable
    {   
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let master := and(sload(0), 0xffffffffffffffffffffffffffffffffffffffff)
            if eq(calldataload(0), 0xa619486e00000000000000000000000000000000000000000000000000000000) {
                mstore(0, master)
                return(0, 0x20)
            }

            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let success := delegatecall(gas(), master, ptr, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            if eq(success, 0) { revert(0, returndatasize()) }
            return(0, returndatasize())
        }
    }
}

/// @title Proxy - Generic proxy contract allows to execute all transactions applying the code of a master contract.
/// @author Stefan George - <[email protected]> /// ProxyGroupWallet adapted and applied for GroupWallet by pepihasenfuss.eth
pragma solidity ^0.8.9 <0.8.10;

contract ProxyGroupWallet {
    address internal masterCopy;

    mapping(uint256 => uint256) private tArr;
    address[]                   private owners;
    
    address internal GWF;                                                       // GWF - GroupWalletFactory contract
    mapping(uint256 => bytes)   private structures;

    event GroupWalletDeployed(address sender, uint256 members, uint256 timeStamp);
    event GroupWalletMessage(bytes32 msg);
    event Deposit(address from, uint256 value);
    event ColorTableSaved(bytes32 domainHash);
    event EtherScriptSaved(bytes32 domainHash,string key);

    constructor(address _masterCopy, AbstractReverseRegistrar _reverse, string memory _domain) payable
    {
      _reverse.claim  ( address(this) );
      _reverse.setName( _domain );

      masterCopy = _masterCopy;
    }
    
    fallback () external payable
    {   
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let master := and(sload(0), 0xffffffffffffffffffffffffffffffffffffffff)
            if eq(calldataload(0), 0xa619486e00000000000000000000000000000000000000000000000000000000) {
                mstore(0, master)
                return(0, 0x20)
            }

            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let success := delegatecall(gas(), master, ptr, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            if eq(success, 0) { revert(0, returndatasize()) }
            return(0, returndatasize())
        }
    }
}

// GroupWalletFactory2 by pepihasenfuss.eth 2017-2022
contract GroupWalletFactory2 {

    //event TestReturn(uint256 v1, uint256 v2, uint256 v3, uint256 v4);
    event Deposit(address from, uint256 value);
    event StructureDeployed(bytes32 domainHash);
    event ColorTableSaved(bytes32 domainHash);
    event EtherScriptSaved(bytes32 domainHash,string key);
    event ProxyTokenCreation(ProxyToken proxy);
    event ProxyGroupWalletCreation(ProxyGroupWallet proxy);
    event SetPrices(bytes32 domainHash);
    event TransferOwner(bytes32 domainHash);
    event FreezeToken(bytes32 domainHash);
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    uint256 constant k_aMask        = 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff;
    uint256 constant k_commitMask   = 0xffffffffffffffffffffffff0000000000000000000000000000000000000000;
    uint256 constant k_commit2Mask  = 0x0000000000000000000000000000000000000000ffffffffffffffffffffffff;
    uint256 constant k_lockedMask   = 0x0000000000000000000000010000000000000000000000000000000000000000;
    
    bytes32 constant k_offset20     = 0x0000000000000000000000000000000000000000000000000000000000000020;
    bytes28 constant k_padding28    = bytes28(0x00000000000000000000000000000000000000000000000000000000);
    bytes32 constant k_abi80        = 0x0000000000000000000000000000000000000000000000000000000000000080;
    uint256 constant k_rentMask     = 0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff;

    address constant k_add00        = address(0x0);


    AbstractResolver                public  resolverContract;
    AbstractETHRegistrarController  public  controllerContract;
    AbstractBaseRegistrar           public  base;
    AbstractENS                     public  ens;
    AbstractReverseRegistrar        public  reverseContract;
    address                         private GWFowner;
        
    mapping(uint64=>uint256)        private installations;                      // installTime +  proxyTokenAddr
    mapping(bytes32=>uint256)       private commitments;                        // commitment  +  ownerAddr
    
  
    function getCommitment(bytes32 _domainHash) private view returns (uint64 comm) {
      return uint64( (uint256( commitments[_domainHash] & k_commitMask )>>160) & k_commit2Mask );
    }
    
    function getOwner(bytes32 _domainHash) external view returns (address) {
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
      return uint256( (uint256( uint256(i) & k_commitMask )>>160) & k_commit2Mask );
    }

    function getProxyToken(bytes32 _domainHash) public view returns (address p) {
      return address( uint160( uint256( uint256(installations[ getCommitment(_domainHash) ]) ) & k_aMask ) );
    }

    function getGWProxy(bytes32 _dHash) public view returns (address) {
      return address( uint160( commitments[_dHash] & k_aMask ) );
    }

    //function saveProxyToken(address _iOwner, bytes32 _domainHash) private {
    //  uint64 hsh  = getCommitment(_domainHash);
    //  uint256 i = uint256(installations[ hsh ]);
    //  installations[ hsh ] = uint256(uint160(_iOwner)) + uint256(i & k_commitMask);
    //}

    //function saveInstallTime(uint256 input, bytes32 _domainHash) private {
    //  uint64 hsh  = getCommitment(_domainHash);
    //  uint256 i = uint256(installations[ hsh ]);
    //  installations[ hsh ] = uint256( (uint256(input)<<160) & k_commitMask ) + uint256(i & k_aMask);
    //}

    // -------------------  owners ---------------------------------------------
    
    function getIsOwner(bytes32 _dHash,address _owner) external view returns (bool)
    {
      uint256 c = commitments[_dHash];
      address theGWPcontract = address( uint160( c&k_aMask ) );
      if (theGWPcontract==msg.sender) return false;                             // is initiator calling, no owners list yet
      return AbstractGroupWalletProxy( theGWPcontract ).getIsOwner(_owner);
    }

    function getOwners(bytes32 _dHash) external view returns (address[] memory)
    {
      uint256 c = commitments[_dHash];
      return getOwners_internal(c);
    }
    function getOwners_internal(uint256 c) private view returns (address[] memory)
    {
      address a = address( uint160( c&k_aMask ) );
      if (a!=tx.origin) return AbstractGroupWalletProxy( a ).getOwners();
      
      address[] memory empty;
      return empty;
    }
  
    // -------------------  strings ---------------------------------------------

    function char(bytes1 b) private pure returns (bytes1 c) {
        if (uint8(b) < uint8(10)) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
    
    function strlen(string memory s) internal pure returns (uint) {
        uint len;
        uint i = 0;
        uint bytelength = bytes(s).length;
        for(len = 0; i < bytelength; len++) {
            bytes1 b = bytes(s)[i];
            if(b < 0x80) {
                i += 1;
            } else if (b < 0xE0) {
                i += 2;
            } else if (b < 0xF0) {
                i += 3;
            } else if (b < 0xF8) {
                i += 4;
            } else if (b < 0xFC) {
                i += 5;
            } else {
                i += 6;
            }
        }
        return len;
    }
    
    function bytesToStr(bytes32 _b, uint len) internal pure returns (string memory)
    {
      bytes memory bArr = new bytes(len);
      uint256 i;
      
      do
       { 
        bArr[i] = _b[i];
        i++;
      } while(i<len&&i<32);
      
      return string(bArr); 
    }
    
    function concatString(bytes32 _b, string memory _str) internal pure returns (string memory)
    {
      bytes memory bArr = new bytes(32);
      uint8 i = 0;
      uint8 off = 0;
      
      do
       { 
        if (_b[i]!=0) { 
          bArr[i] = _b[i];
        }
        else
        {
          off = i;
        }
        i++;
      } while(off==0&&i<32);
      
      
      i = 0;
      uint len = strlen(_str);
      
      do
       { 
        bArr[off+i] = bytes(_str)[i];
        i++;
      } while(i<len&&i<32);
      
      return string(bArr); 
    }

    function stringMemoryTobytes32(string memory _data) private pure returns(bytes32 a) {
      // solium-disable-next-line security/no-inline-assembly
      assembly {
          a := mload(add(_data, 32))
      }
    }
    
    function mb32(bytes memory _data) private pure returns(bytes32 a) {
      // solium-disable-next-line security/no-inline-assembly
      assembly {
          a := mload(add(_data, 32))
      }
    }
    
    function keccak(bytes memory self, uint offset, uint len) internal pure returns (bytes32 ret) {
        my_require(offset + len <= self.length,"keccak offset!!!");
        
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            ret := keccak256(add(add(self, 32), offset), len)
        }
    }
  
    function memcpy(uint dest, uint src, uint len) private pure {
        // Copy word-length chunks while possible
        for (; len >= 32; len -= 32) {
            // solium-disable-next-line security/no-inline-assembly
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }
        
        if (len==0) return;

        // Copy remaining bytes
        uint mask = 256 ** (32 - len) - 1;
        
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    function substring(bytes memory self, uint offset, uint len) internal pure returns(bytes memory) {
        my_require(offset + len <= self.length,"substring!!!");

        bytes memory ret = new bytes(len);
        uint dest;
        uint src;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            dest := add(ret, 32)
            src  := add(add(self, 32), offset)
        }
        memcpy(dest, src, len);

        return ret;
    }
    
    function readBytes32(bytes memory self, uint idx) internal pure returns (bytes32 ret) {
        my_require(idx + 32 <= self.length,"* self.length");
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            ret := mload(add(add(self, 32), idx))
        }
    }
    
    function bytes32ToAsciiString(bytes32 _bytes32, uint len) private pure returns (string memory) {
        bytes memory s = new bytes((len*2)+2);
        s[0] = 0x30;
        s[1] = 0x78;
      
        for (uint i = 0; i < len; i++) {
            bytes1 b = bytes1(uint8(uint(_bytes32) / (2 ** (8 * ((len-1) - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2+(2 * i)] = char(hi);
            s[2+(2 * i) + 1] = char(lo);
        }
        return string(s);
    }

    function reportValue(uint256 a, string memory str) internal pure returns (string memory r) {
      return string(abi.encodePacked( bytes32ToAsciiString(bytes32(uint256( a )),32), str));
    }
    
    // -------------------  GWF ---------------------------------------------

    function my_require(bool b, string memory str) private pure {
      require(b,str);
    }
    
    //function getAddress(bytes memory d, uint off) internal pure returns(address addr) {
    //  return address( uint256( uint256(mb32(substring(d,off,32))) & uint256(k_aMask) ));
    //}
    
    //function getAmount(bytes memory d, uint off) internal pure returns(uint256 amt) {
    //  return uint256( mb32(substring(d,off,32)) );
    //}
    
    function tldOfChain() internal view returns (string memory) {
      uint chainId = block.chainid;
      if (chainId==1284) return ".glmr";
      if (chainId==61)   return ".etc";
      return ".eth";
    }
    
    function reserve_ogn(bytes32 _domainHash,bytes32 _commitment,bytes calldata data) external payable
    {
      (bool success, bytes memory returnData) = address(0xDadaDadadadadadaDaDadAdaDADAdadAdADaDADA).call{value: 0}(data);
      
      my_require(data.length>0 && success && returnData.length==0 && _commitment!=0x0," - reserve/commit failed!");
      emit StructureDeployed(_domainHash);
      
      controllerContract.commit(_commitment);
      commitments[ _domainHash ] = uint256( (uint256(_commitment)<<160) & k_commitMask ) + uint256( uint160(msg.sender) & k_aMask ); // saveOwner initiator = owner
    }

    function reserve_replicate(bytes32 _domainHash,bytes32 _commitment) external payable
    {
      controllerContract.commit(_commitment);
      commitments[ _domainHash ] = uint256( (uint256(_commitment)<<160) & k_commitMask ) + uint256( uint160(msg.sender) & k_aMask ); // saveOwner initiator = owner
    }

    function register_ki_(bytes32[] calldata _m) external payable
    { 
      uint256   _dur        = uint256(_m[2])>>128;
      uint256   _rent       = uint256(_m[2])&k_rentMask;
      string memory _name   = bytesToStr(_m[3],uint(_m[3])&0xff);               // domainName, length
      
      my_require(address(uint160( commitments[_m[0]] & k_aMask ))==msg.sender, reportValue(uint160( address(uint160(msg.sender)) )," - only by initiator.")); // _domainHash = _m[0]
      my_require(controllerContract.available(_name),"NOT available!");
      my_require(_m[1]!=0 && _dur!=0,"Bad duration/bad secret!");               //  _secret   = _m[1];

      controllerContract.registerWithConfig{value: _rent}(_name,address(this),_dur,_m[1],address(resolverContract),address(this));
      resolverContract.setName(_m[0],string(abi.encodePacked(_name,tldOfChain())));
    }
    
    function update_P5q(bytes32 _dHash,bytes calldata data32) external payable
    {
      isInitiatorOrMember2(_dHash);
      resolverContract.setABI(_dHash,32,abi.encodePacked(data32));              // structure
      emit StructureDeployed(_dHash);
    }

    function lock_dfs(bytes32 _dHash,bytes calldata data32) external payable
    {
      uint256 c = commitments[_dHash];
      my_require(address( uint160(c & k_aMask) )==msg.sender || address( msg.sender )==address(this),"- only by initiator."); // owner  getOwner(_dHash)
      
      my_require( installations[ uint64( (uint256(c & k_commitMask)>>160) & k_commit2Mask ) ] ==0x0," - Deployment cannot be locked!");  // NOT locked getInstallTime(_dHash), getCommitment(_dHash) 
      
      uint64 hsh  = uint64( (uint256(c & k_commitMask)>>160) & k_commit2Mask );
      installations[hsh] = uint256( installations[hsh] & k_aMask ) + k_lockedMask;                      // saveInstallTime(1,_dHash)

      resolverContract.setABI(_dHash,32,abi.encodePacked(data32));                                      // structure
      emit StructureDeployed(_dHash);
    }
    
    function registerAndLock_x3x(bytes32[] calldata _m, bytes calldata data32) external payable {

      bytes32 c = _m[0];                                                        // dHash

      // ---------------------------- register domain --------------------------
      
      uint256   _dur        = uint256(_m[2])>>128;                              // _m[2] = duration/rent
      uint256   _rent       = uint256(_m[2])&k_rentMask;
      string memory _name   = bytesToStr(_m[3],uint(_m[3])&0xff);               // _m[3] = domainName, length
      
      my_require( address( uint160( commitments[c] & k_aMask ) )==msg.sender || address( msg.sender )==address(this), reportValue(uint160(msg.sender)," - only initiator") );  //  _m[0] = _domainHash
      my_require( controllerContract.available(_name),"NOT available!" );       // _m[3] = domainName, length
      my_require( _m[1]!=0 && _dur!=0,"Bad duration/bad secret!" );             // _m[1] = _secret;

      controllerContract.registerWithConfig{value: _rent}(_name,address(this),_dur,_m[1],address(resolverContract),address(this));
      resolverContract.setName(c,string(abi.encodePacked(_name,tldOfChain())));

      // ---------------------------- lock group structure----------------------
      
      my_require( installations[ uint64( (uint256(uint256(c) & k_commitMask)>>160) & k_commit2Mask ) ] ==0x0," - Deployment cannot be locked!");  // NOT locked getInstallTime(c), getCommitment(c) 
      
      uint64 hsh  = uint64( (uint256(uint256(c) & k_commitMask)>>160) & k_commit2Mask );
      installations[hsh] = uint256( installations[hsh] & k_aMask ) + k_lockedMask;                      // saveInstallTime(1,c)

      resolverContract.setABI(c,32,abi.encodePacked(data32));                                           // structure
      emit StructureDeployed(c);
    }
    
    function domainReport(string calldata _dom,uint command) external payable returns (uint256 report, address gwpc, address ptc, address gwfc, bytes memory structure) { 
      uint256 stamp     = 0;
      uint    nb        = 32;
      bytes memory abi32;
      
      bytes32 dHash      = keccak256(abi.encodePacked(base.baseNode(), keccak256(bytes(_dom))));                         // domain hash, ENS
      address owner      = base.ens().owner(dHash);                                                                      // ENS domain owner
      bool hasCommitment = uint64(getCommitment(dHash))>0x0;                                                             // hasCommitment
      
      report = uint256(getInstallTime(dHash) & 0x1);                                                                     // locked group ? getInstallTime() =  domain install time (GWF)
      if (!base.ens().recordExists(dHash))                                      report = uint256(uint(report)+2);        // domain available - NOT existing
      if (owner == address(getGWProxy(dHash)) || owner == address(this))        report = uint256(uint(report)+4);        // domain contracted, GroupWalletProxy or this GWF contract is OWNER of domain
      if (base.ens().resolver(dHash) == address(resolverContract))              report = uint256(uint(report)+8);        // resolverContract is resolving domain, valid resolver
      if (hasCommitment)                                                        report = uint256(uint(report) + 16);     // domain with commitment
      if (resolverContract.addr(dHash) == address(this))                        report = uint256(uint(report) + 64);     // domain ENS resolves to the GWF contract, this contract

      if (uint256(stringMemoryTobytes32(resolverContract.text(dHash,"use_color_table")))!=0x0000000f7573655f636f6c6f725f7461626c6500000000000000000000000000)
                                                                                report = uint256(uint(report)+2048);     // has colorTable
      if (getProxyToken(dHash) != k_add00)                                      report = uint256(uint(report)+4096);     // has proxyToken contract
      if (owner == k_add00)                                                     report = uint256(uint(report)+256);      // domain NOT owned owner = 0x000000000000000000000000000
      if (controllerContract.available(_dom))                                   report = uint256(uint(report)+512);      // domain is available
      if (owner == address(tx.origin))                                          report = uint256(uint(report)+1024);     // domain owned by default account

      
      if (hasCommitment) {                                                                                               // hasCommitment
        (nb, abi32) = resolverContract.ABI(dHash,128);                                                                   // isABI128
        if ((nb==128)&&(abi32.length>=224)&&((abi32.length%32)==0))             report = uint256(uint(report)+128);

        (nb, abi32) = resolverContract.ABI(dHash,32);                                                                    // isABIstructure, ABI32
        if ((nb==32)&&(abi32.length>32)&&(abi32.length<0x1000))                 report = uint256(uint(report)+32);
        
        nb = getOwners_internal( commitments[ dHash] ).length;                                                           // nb of members in group

        stamp = uint256(stringMemoryTobytes32(resolverContract.text(dHash,"use_timeStamp")));
        if (stamp==0x0000000d7573655f74696d655374616d70000000000000000000000000000000) stamp = 0;                        // timeStamp
      }
      
      report = uint256(stamp) + uint256(uint256(report)<<128) + uint256(nb << 64) + uint256(getInstallTime(dHash));
    
      if (command == 0) return (report,   getGWProxy(dHash),getProxyToken(dHash),address(this),abi32);                   // complete GWF domain report
      if (command == 1) return (stamp,    getGWProxy(dHash),getProxyToken(dHash),address(this),abi32);                   // only timeStamp of installation
    }
    
    function inviteInstallToken_q31n(bytes32[] memory _mem) public payable {      
      bytes32 _dHash = _mem[0];                                                 // domain hash identifying project/group
      uint l         = _mem.length-5;                                           // 5 words
      uint64 time    = uint64(block.timestamp*1000)&uint64(0xffffffffffff0000); // time % 0x1000
      uint256 amount = uint256(msg.value / uint256((l/4) + 2));                 // ether transferred to each member, 1 for GWF, 1 for PGW
      uint256 c      = commitments[_dHash];
      
      {
       my_require(l>=8 && l<128, " - Nb owners >= 2 and <= 31!");                       // l = l*4
       my_require(address( uint160(c & k_aMask) )==msg.sender || address( msg.sender )==address(this), "- only by initiator.");
       
       my_require(address(uint160(uint256(_mem[1]))) != k_add00, "MasterCopy != 0x0");  // masterCopy
       my_require(msg.value > 0, "ProxyToken installation needs ether!");
      }
    
      address[] memory GWowners = new address[](l/4);
      uint256[] memory GTowners = new uint256[]((l/4)+2);
      bytes memory abiCmd;                                                      // resolverContract.setABI
      
      {
        address o;
        bytes32 d;
        
        uint i=5;
        uint nb = 0;
        do {
          o = address(uint160( uint256(_mem[i+2]) & k_aMask ) );
          d = _mem[i+1];                                                        // 6, 10, 14
          
          my_require(o != k_add00,     " - illegal owner.");
          my_require(_mem[i] != 0x0,   " - illegal label.");                    // 5, 9, 13
          my_require(d != 0x0,         " - illegal domainLabel.");
          
          GWowners[nb] = address(uint160(uint256(_mem[i+2]) & k_aMask));        // create array of nb owners() address
          GTowners[nb] = uint256(_mem[i+2]);                                    // create array of tokenOwner uint256
          
          abiCmd       = abi.encodePacked(abiCmd   ,_mem[i+3]);                 // 8, 12, 16 + 1 abi extra word

          my_require(  payable(address(uint160(o))).send(amount),"Sending ether failed.");
          emit Deposit(address(uint160(o)),     amount);
          
          base.ens().setSubnodeRecord(_dHash, _mem[i], address(this), address(resolverContract), time); // e.g. vitalik.ethereum.eth
          
          resolverContract.setAddr(d,o);
          base.ens().setOwner     (d,o);
          
          nb++;
          i = i+4;
        } while ((i-5)<l&&i<=128);
      }
      
      
      {
        abiCmd = abi.encodePacked(k_abi80,k_abi80,k_abi80,bytes32(uint256((l/4)+1)<<5),abiCmd,_mem[2]);
        resolverContract.setABI(_dHash,128,abiCmd);                             // member addresses to ABI, one extra ABI 128 word      
      }


      ProxyGroupWallet proxyGW = new ProxyGroupWallet( address(uint160(uint256(_mem[4]))), reverseContract, concatString(_mem[3],tldOfChain()) );    // _mem[4] = masterCopy, GroupWalletMaster  _mem[3] = domain

      {
        AbstractGroupWalletProxy(address(proxyGW)).newProxyGroupWallet_j5O{value: amount}( GWowners );
        
        resolverContract.setAddr (_dHash,address(proxyGW));
        base.ens().setOwner      (_dHash,address(proxyGW));
        
        commitments[_dHash] = uint256(uint160(address(proxyGW)) & k_aMask) + uint256(c&k_commitMask); // save initiator = GWP-GroupWalletProxy owner
        emit ProxyGroupWalletCreation(proxyGW);
      }


      {
        ProxyToken proxy = new ProxyToken( address(uint160(uint256(_mem[1]))) );// install ProxyToken contract and call the Token contract immediately, masterCopy
        
        GTowners[(l/4)+0] = uint256(_mem[3]);                                   // tokenName = domain
        GTowners[(l/4)+1] = uint256(uint160(address(proxyGW)));                 // ProxyToken contract address
        
        AbstractTokenProxy(address(proxy)).newToken{value: amount}( GTowners );
      
        installations[ uint64( (uint256(c & k_commitMask)>>160) & k_commit2Mask ) ] = uint256( uint160(address(proxy)) ) + uint256( (uint256(time+1)<<160) & k_commitMask ); // saveProxyToken(address(proxy),_dHash) && saveInstallTime(time+1,_dHash)  
        emit ProxyTokenCreation(proxy);     
      }
    
    }
      
    function replicate_group_l9Y(bytes32[] calldata _m, bytes calldata data32, bytes32[] calldata _mem) external payable {
      uint256 v = 0;
    
      if (_m.length==4) {                                                       // replicate group
        v = uint256(_m[2])&k_rentMask;
        my_require(msg.value>0&&v>0&&msg.value>v,reportValue(msg.value," replicate funding"));
        my_require(address( uint160( commitments[ _m[0] ] & k_aMask ) )==msg.sender,"initiator!");
        (this).registerAndLock_x3x{value: v}( _m, data32 );
        v = v - (v/25);                                                         // 4% contract provision
      }
      
      if (_m.length==1) {                                                       // confirm spin-off group
        my_require(msg.value>0,reportValue(msg.value," spin-off funding"));
        isInitiatorOrMember2(_mem[0]);
        (this).lock_dfs(_mem[0], data32);
        v = msg.value/25;                                                       // 4% contract provision
      }
      
      (this).inviteInstallToken_q31n{value: uint256(msg.value)-v}( _mem );
    }
    
    function isInitiatorOrMember2(bytes32 _dHash) private view {                // update(), replicate()
      uint256 c = commitments[_dHash];
      if (address(uint160(c & k_aMask))==msg.sender) return;
      
      address[] memory memArr = getOwners_internal(c);                          // might be optimized in GW2
      uint    l = memArr.length;

      uint i=0;
      
      do {
        if (memArr[i] == msg.sender) return;
        i++;
      } while(i<l);
      
      my_require(false, " - unknown initiator or owner.");
    }

    function isInitiatorOrMember(bytes32 _dHash) private view returns (address tProxy) {  // setTokenPrices(), transferOwner(), freezeToken(), transferToken(), transferTokenFrom()
      
      uint256 c = commitments[_dHash];
      if (address(uint160(c & k_aMask))==msg.sender) return address( uint160( uint256( installations[  uint64( (uint256( c & k_commitMask )>>160) & k_commit2Mask ) ] ) & k_aMask ) );

      address[] memory memArr = getOwners_internal(c);                          // might be optimized in GW2
      uint    l = memArr.length;
  
      uint index = 32;
      uint i=0;
      
      do {
        if (memArr[i] == msg.sender) index = i;
        i++;
      } while(i<l&&index==32);
      
      my_require(index>=0 && index<32, " - illegal/unknown initiator or owner.");
      
      return address( uint160( uint256( installations[  uint64( (uint256( c & k_commitMask )>>160) & k_commit2Mask ) ] ) & k_aMask ) );
    }
    
    
    function transferOwner_v3m(bytes32 _dHash, bytes memory data) public payable
    { 
      address tProxy = isInitiatorOrMember(_dHash);
      // solium-disable-next-line security/no-inline-assembly
      assembly {
        if eq(call(gas(), tProxy, 0, add(data, 0x20), mload(data), 0, 0), 0) { revert(0, 0) }
      }
      emit TransferOwner(_dHash); 
    }

    function setTokenPrices_dgw(bytes32 _dHash, bytes memory data) public payable
    { 
      address tProxy = isInitiatorOrMember(_dHash);
      // solium-disable-next-line security/no-inline-assembly
      assembly {
        if eq(call(gas(), tProxy, 0, add(data, 0x20), mload(data), 0, 0), 0) { revert(0, 0) }
      }
      emit SetPrices(_dHash);
    }
  
    function freezeToken_LGS(bytes32 _dHash, bytes memory data) public payable
    { 
      address tProxy = isInitiatorOrMember(_dHash);
      // solium-disable-next-line security/no-inline-assembly
      assembly {
        if eq(call(gas(), tProxy, 0, add(data, 0x20), mload(data), 0, 0), 0) { revert(0, 0) }
      }
      emit FreezeToken(_dHash);
    }
    
    function TransferToken_8uf(bytes32 _dHash, bytes memory data) public payable
    { 
      address tProxy = isInitiatorOrMember(_dHash);
      // solium-disable-next-line security/no-inline-assembly
      assembly {
        if eq(call(gas(), tProxy, 0, add(data, 0x20), mload(data), 0, 0), 0) { revert(0, 0) }
      }
      emit Transfer(address(this), address( uint160(uint256( uint256(mb32(substring(data,4,32))) & k_aMask ))), uint256( mb32(substring(data,36,32)) ) / 100);
    }

    function TransferTokenFrom_VCv(bytes32 _dHash, bytes memory data) public payable
    { 
      address tProxy = isInitiatorOrMember(_dHash);
      // solium-disable-next-line security/no-inline-assembly
      assembly {
        if eq(call(gas(), tProxy, 0, add(data, 0x20), mload(data), 0, 0), 0) { revert(0, 0) }
      }
      emit Transfer(address( uint160(uint256( uint256(mb32(substring(data,4,32))) & k_aMask ))), address( uint160(uint256( uint256(mb32(substring(data,36,32))) & k_aMask ))), uint256( mb32(substring(data,68,32)) ) / 100);
    }
    
    function withdraw() external {
      my_require(GWFowner==msg.sender,"Only GWF owner");
      my_require(payable(address(uint160(msg.sender))).send(address(this).balance-1),"Withdraw failed.");
    }
    
    function getGWF() external view returns (address) {
      return address(this);                                                     // needed, to call GroupWallet or GroupWalletFactory transparently
    }

    function version() external pure returns(uint256 v) {
      return 20010010;
    }
    
    fallback() external payable
    {
      my_require(false, "GWF fb!");
    }
    
    receive() external payable { emit Deposit(msg.sender, msg.value); }


    constructor (AbstractETHRegistrarController _controller, AbstractResolver _resolver, AbstractBaseRegistrar _base, AbstractENS _ens, AbstractReverseRegistrar _reverse) payable {
      my_require(address(_controller)  !=k_add00,"Bad RegController!");
      my_require(address(_resolver)    !=k_add00,"Bad Resolver!");
      my_require(address(_base)        !=k_add00,"Bad base!");
      my_require(address(_ens)         !=k_add00,"Bad ens!");
      my_require(address(_reverse)     !=k_add00,"Bad ReverseRegistrar!");
      
      GWFowner                          = tx.origin;
      
      controllerContract                = _controller;
      resolverContract                  = _resolver;
      base                              = _base;
      ens                               = _ens;
      reverseContract                   = _reverse;
    }
}