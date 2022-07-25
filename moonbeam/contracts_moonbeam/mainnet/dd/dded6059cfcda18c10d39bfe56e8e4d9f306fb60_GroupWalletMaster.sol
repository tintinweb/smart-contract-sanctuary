/**
 *Submitted for verification at moonbeam.moonscan.io on 2022-05-25
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9 <0.8.10;

// ungravel.eth, GroupWallet, GroupWalletMaster, GroupWalletFactory, ProxyWallet, TokenMaster, ProxyToken by pepihasenfuss.eth 2017-2022, Copyright (c) 2022

// GroupWalletMaster is based on MultiSigContracts inspired by Parity MultiSignature contract, consensys and gnosis MultiSig contracts.
// GroupWallet and ungravel is entirely based on Ethereum Name Service, "ENS", the domain name registry.

//   ENS, ENSRegistryWithFallback, PublicResolver, Resolver, FIFS-Registrar, Registrar, AuctionRegistrar, BaseRegistrar, ReverseRegistrar, DefaultReverseResolver, ETHRegistrarController,
//   PriceOracle, SimplePriceOracle, StablePriceOracle, ENSMigrationSubdomainRegistrar, CustomRegistrar, Root, RegistrarMigration are contracts of "ENS", by Nick Johnson. ENS-License:
//
//   Copyright (c) 2018, True Names Limited
//
//   Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//   The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


abstract contract AbstractGroupWalletFactory {
  AbstractResolver                public  resolverContract;
  AbstractETHRegistrarController  public  controllerContract;
  AbstractBaseRegistrar           public  base;
  AbstractENS                     public  ens;

  function getProxyToken(bytes32 _domainHash) external view virtual returns (address p);
  function reserve_replicate(bytes32 _domainHash,bytes32 _commitment) external virtual payable;
  function replicate_group_l9Y(bytes32[] calldata _m, bytes calldata data32, bytes32[] calldata _mem) external virtual payable;
}

abstract contract AbstractTokenMaster {  
  function transfer_G8l(address toReceiver, uint amount) external virtual;
  function drainShares(bytes32 dHash, address _GWF, address from, address toReceiver) external virtual;
}

abstract contract AbstractTokenProxy {
  function balanceOf(address tokenOwner) external virtual view returns (uint thebalance);
  function drainShares(bytes32 dHash, address _GWF, address from, address toReceiver) external virtual;
  function name() external virtual view returns (string memory);
  function drainLegacyShares(bytes32 dHash, address _GWF, address from, address toReceiver) external virtual;
}

interface ENS {
  event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);
  event Transfer(bytes32 indexed node, address owner);
  event NewResolver(bytes32 indexed node, address resolver);
  event NewTTL(bytes32 indexed node, uint64 ttl);
  event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

  function setSubnodeRecord(bytes32 node, bytes32 label, address owner, address resolver, uint64 ttl) external;
  function setOwner(bytes32 node, address owner) external;
  function owner(bytes32 node) external view returns (address);
  function recordExists(bytes32 node) external view returns (bool);
}

contract AbstractBaseRegistrar {
  event NameMigrated(uint256 indexed id, address indexed owner, uint expires);
  event NameRegistered(uint256 indexed id, address indexed owner, uint expires);
  event NameRenewed(uint256 indexed id, uint expires);

  bytes32 public baseNode;   // The namehash of the TLD this registrar owns (eg, .eth)
  ENS public ens;
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

  function setABI(bytes32 node, uint256 contentType, bytes calldata data) external virtual;
  function setAddr(bytes32 node, address r_addr) external virtual;
  function setAddr(bytes32 node, uint coinType, bytes calldata a) external virtual;
  function setName(bytes32 node, string calldata _name) external virtual;
  function setText(bytes32 node, string calldata key, string calldata value) external virtual;
  function setAuthorisation(bytes32 node, address target, bool isAuthorised) external virtual;
  function addr(bytes32 node) external virtual view returns (address payable);
}

abstract contract AbstractENS {
  event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);
  event Transfer(bytes32 indexed node, address owner);
  event NewResolver(bytes32 indexed node, address resolver);
  event NewTTL(bytes32 indexed node, uint64 ttl);
  event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

  function setSubnodeRecord(bytes32 node, bytes32 label, address owner, address resolver, uint64 ttl) external virtual;
  function setOwner(bytes32 node, address owner) external virtual;
  function owner(bytes32 node) external view virtual returns (address);
  function recordExists(bytes32 node) external view virtual returns (bool);
}

abstract contract AbstractETHRegistrarController {
  mapping(bytes32=>uint) public commitments;

  uint public minCommitmentAge;
  uint public maxCommitmentAge;

  event NameRegistered(string name, bytes32 indexed label, address indexed owner, uint cost, uint expires);
  event NameRenewed(string name, bytes32 indexed label, uint cost, uint expires);

  function rentPrice(string memory name, uint duration) view external virtual returns(uint);
  function registerWithConfig(string memory name, address owner, uint duration, bytes32 secret, address resolver, address addr) external virtual payable;
}

abstract contract AbstractGroupWalletProxy {
  function submitFirstTransaction_gm(uint firstTRecord, uint256 dhash) external virtual payable;
  function submitLegacyTransaction(uint tNb,uint tRecord) external virtual payable;
}


contract GroupWalletMaster {
    address internal masterCopy;                                                // ProxyGroupWallet needs this ******* DO NOT CHANGE ORDER ******

    mapping(uint256 => uint256) private  tArr;                                  // transaction records, 32 bytes store any transaction
    address[]                   private  owners;                                // contract owners = members of the group (2-31)

    address internal GWF;                                                       // GWF - GroupWalletFactory master contract
    mapping(uint256 => bytes)   private  structures;                            // saving encoded group structure for addUser()
    
                                                                                // ******* DO NOT CHANGE ORDER ******

    event TestReturn(uint256 v1, uint256 v2, uint256 v3, uint256 v4);
    event GroupWalletDeployed(address sender, uint256 members, uint256 timeStamp);
    event GroupWalletMessage(bytes32 msg);
    event Deposit(address from, uint256 value);
    event ColorTableSaved(bytes32 domainHash);
    event EtherScriptSaved(bytes32 domainHash,string key);

    // ----------------------  GWM ---------------------------------------------


    function getMasterCopy() external view returns (address) {
      return masterCopy;
    }

    function getGWF() external view returns (address) {
      return GWF;
    }
    
    function getENS() internal view returns (AbstractENS) {
      return AbstractENS( AbstractGroupWalletFactory(GWF).ens() );
    }

    function getRsv() internal view returns (AbstractResolver) {
      return AbstractGroupWalletFactory(GWF).resolverContract();
    }

    function getCtrl() internal view returns (AbstractETHRegistrarController) {
      return AbstractGroupWalletFactory(GWF).controllerContract();
    }

    function getTarget(uint tNb) private view returns (address) {
      return address( uint160( uint256( uint256( tArr[tNb] ) & k_addressMask ) ) );
    }

    function getTValue(uint tNb) private view returns (uint64) {
      return uint64( uint256( (uint256( uint256( tArr[tNb] ) & k_valueMask )>>160) & k_value2Mask ) );
    }

    function getAsset(uint tNb) private view returns (uint8) {
      return uint8( uint256( uint256(uint256( uint256( tArr[tNb] ) & k_assetMask )>>208) & k_asset2Mask ) );
    }

    function getFlags(uint tNb) private view returns (uint64) {
      return uint64( uint256( uint256(uint256( uint256( tArr[tNb] ) & k_flagsMask )>>216) & k_flags2Mask ) );
    }

    function getType(uint tNb) private view returns (uint8) {
      return uint8( uint256( uint256(uint256( uint256( tArr[tNb] ) & k_typeMask )>>252) & k_type2Mask ) );
    }
    
    function saveFlags(uint _tId, uint64 flags) private {
      tArr[_tId] = uint256( uint256(uint256( flags )<<216) & k_flagsMask ) + uint256( tArr[_tId] & k_flags3Mask );
    }
    
    function saveAsset(uint _tId, uint8 asset) private {
      tArr[_tId] = uint256( uint256(uint256( asset )<<208) & k_assetMask ) + uint256( tArr[_tId] & k_asset3Mask );
    }
    
    function saveExecuted(uint _tId, uint64 f, uint t) private {
       tArr[_tId] = uint256( uint256( uint256((uint256(f)<<216) & k_flagsMask) + uint256( t & k_flags3Mask ) ) | k_executeFlag );
    }
    
    // -------------------  strings --------------------------------------------

    function my_require(bool b, string memory str) private pure {
      require(b,str);
    }

    function char(bytes1 b) private pure returns (bytes1 c) {
        if (uint8(b) < uint8(10)) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
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
    
    function bytes32ToStr(bytes32 _b) internal pure returns (string memory)
    {
      bytes memory bArr = new bytes(32);
      uint256 i;
      
      uint off = 0;
      do
       { 
        if (_b[i] != 0) bArr[i] = _b[i];
        else off = i;
        i++;
      } while(i<32&&off==0);
      
      
      bytes memory rArr = new bytes(off);
      
      i=0;
      do
       { 
        if (bArr[i] != 0) rArr[i] = bArr[i];
        off--;
        i++;
      } while(i<32&&off>0);
      
      return string(rArr); 
    }
    
    function toLowerCaseString(bytes32 _b) internal pure returns (string memory)
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

      bytes memory rArr = new bytes(off);
      i = 0;
      do
       { 
        if (bArr[i]!=0) {
          if ((uint8(bArr[i]) < 97) && (uint8(bArr[i]) != 45)) rArr[i] = bytes1(uint8(rArr[i])+uint8(32));
          else rArr[i] = bArr[i];
        }
        
        i++;
      } while(i>32);

      return string(rArr); 
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
    
    function strlen(string memory s) internal pure returns (uint) {
        uint len;
        uint i = 0;
        
        uint bytelength = bytes(s).length;
        if (bytelength==0) return 0;
        
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
      if (len==0) return string(bArr);
      
      do
       { 
        bArr[off+i] = bytes(_str)[i];
        i++;
      } while(i<len&&i<32);
      
      return string(bArr); 
    }
    
    function toLowerCaseBytes32(bytes32 _in) internal pure returns (bytes32 _out){
      if ( uint256(uint256(uint256(_in) & k_typeMask) >> 252) < 6 ) return bytes32(uint256(uint256(_in) | 0x2000000000000000000000000000000000000000000000000000000000000000 ));
      return _in;
    }
    
    // -------------------  transactions ---------------------------------------

    function getT(uint _tId) internal view returns (uint256 t) {
      my_require(isAddressOwner(msg.sender)," no owner");
      if (_tId>0) my_require(msg.value>0," value=0");
      return tArr[_tId];
    }
    
    function dHashFromLabelBytes32(bytes32 _name) internal view returns (bytes32 hsh) {
     return keccak256(abi.encodePacked( AbstractGroupWalletFactory(GWF).base().baseNode(), keccak256(bytes(bytesToStr(_name, uint(_name)&0xff))) )); // dhash e.g. group-rebels.eth
    }

    function getdHashFromTRecord(uint256 t) internal view returns (bytes32 hsh) {
      uint256 target = uint256(uint160( uint256( t ) & k_addressMask ) + 1);
      return dHashFromLabelBytes32(bytes32(tArr[target]));
    }
    
    function checkPreconditions(uint tNb, uint tRecord, uint cmd) private view {
      my_require(tNb>0,"value=0 !");
      my_require(isAddressOwner(msg.sender),"ownerExists!!!");
      my_require(tArr[tNb] == 0,"tArr overwrite error!!!");
      
      if (cmd==0) return;
      
      my_require(uint(uint256(tRecord & k_typeMask)>>252) == cmd,"action nb!");
    }
    
    function checkSplitPreconditions(uint tNb, uint8 exec) private view returns (uint) {
      my_require(owners.length>3,"group too small!");
    
      return getOpenSplitTransactionNb(tNb-1,exec);
    }
    
    function tldOfChain() internal view returns (string memory) {
      uint chainId = block.chainid;
      if (chainId==1284) return ".glmr";
      if (chainId==61)   return ".etc";
      return ".eth";
    }
    
    // -------------------  multiSig wallet ------------------------------------

    function confirmTransaction_Q6d(uint _tId) external payable
    {
        uint256 t = getT(_tId);

        uint64 f = uint64( (uint256( uint256( t ) & k_flagsMask )>>216) & k_flags2Mask );
        uint64 o = getOwnerMask(msg.sender);
        my_require(uint64(f&o)==0,"notConfirmed!!!");
        
        my_require(uint8( (uint256( uint256( t ) & k_assetMask )>>208) & k_asset2Mask )<128, "Q6d notExecuted!!!");
        
        f = uint64(f|o);                                                        // confirm f|o

        if ( ( getFlags(msg.value-1) & uint64(MAX_OWNER_COUNT) ) <= nbOfConfirmations( uint64(f/32) ) ) callExecution(_tId,t,f);
        else tArr[_tId] = uint256( ((uint256(f)<<216) & k_flagsMask) + uint256( t & k_flags3Mask ) );
    }
  
    function storeLegacyProxyToken(bytes32 spinName,uint64 flags) internal returns (address){
      bytes32 newHash = keccak256( abi.encodePacked( AbstractGroupWalletFactory(GWF).base().baseNode(), keccak256( bytes( bytes32ToStr( toLowerCaseBytes32(spinName) ) ) ) ) );     // dhash e.g. group-rebels.eth
      address gwp = getENS().owner( newHash );                                                                                                                                      // GroupWalletProxy contract address of spin-off group
      
      address legacyToken = AbstractGroupWalletFactory(GWF).getProxyToken( bytes32(tArr[uint256(uint160(GWF))]) );                                                                  // legacyToken contract of legacy group before spin-off
      uint256 tRecord     = uint256(uint256(uint256(k_legacyToken & k_type2Mask)<<252)&k_typeMask) + uint256(uint256(uint256(flags)<<216)&k_flagsMask) + uint256( uint256(uint256( nbOfConfirmations(uint64(flags/32)) )<<208) & k_assetMask ) + uint256(uint160(legacyToken)) | k_executeFlag; // t type == 0xb, store legacy tokenContract for legacy assets

      AbstractGroupWalletProxy(gwp).submitFirstTransaction_gm{value:0}(tRecord, uint256(newHash));
      
      return gwp;
    }
    
    function sendSpinoffAssets(uint _tId, uint64 f, bytes32[] calldata _mem, uint totalGas) internal returns (bool) {
      uint sum  = 0;
      uint cost = 0;
      uint nbSpinOwners;
      
      // ------- shares to new addresses, drain legacy shares ------------------

      {
        uint64  o  =1;                                                             // drainShares to leaving members
        uint64 f_s =0;
        uint256 t  = 0;
        uint    i  =0;
        bytes32 hash = bytes32(tArr[uint256(uint160(GWF))]);
        do {
          if ((uint64(f>>5)&o)==o) {
            t =  uint256(_mem[7+(f_s*4)]) & k_addressMask;                      // receiver
            f_s++;
            
            AbstractTokenMaster(AbstractGroupWalletFactory(GWF).getProxyToken( hash )).drainShares(hash,GWF,owners[i],address(uint160(t)));
            
            drainLegacyShares(hash,i,address(uint160(t)));
            
            ownerChange(owners[i], address(0x0));                               // remove spin-off group member
          }
          
          o = o*2;
          i++;
        } while(i<owners.length);
        
        
        nbSpinOwners = f_s;

        f_s = uint64(uint64(f|uint64(MAX_OWNER_COUNT)) ^ uint64(MAX_OWNER_COUNT))+((uint64(activeOwners())/2)+1); // reset majority spinOff CMD
        saveFlags(_tId,f_s);
      }


      // ---------------- store legacy token contract adddress -----------------
      
      address gwp = storeLegacyProxyToken(_mem[3],f);                           // spin-off group name, spinOff flags

    
      // ------------------------- sum up deposits  ----------------------------
      
      {
        uint256 t = 0;
        uint i=0;
        uint cmd;
        do {
          t   = tArr[i];
          cmd = (t & k_typeMask)>>252;
          
          if (cmd==k_legacyToken) AbstractGroupWalletProxy(gwp).submitLegacyTransaction{value:0}(i+1,t);  // legacy token, legacyTransactionRecords
          
          if ((cmd==10) && (t&k_executeFlag==0)) sum = sum + uint(uint256(t) & k_addressMask);            // cmd type = 10 = deposit ether/funds, not yet executed
          
         i++;
        } while(t>0);

        sum = sum + uint256(msg.sender.balance) + uint256(msg.value*9/10);      // add deposits + sender balance + msg.value - 10% group contract tax
      }


      // --------------------- compute member share of cost  -------------------
      
      uint nbm = uint64((_mem.length-5)/4);                                     // nb of members of spinoff group

      {
        cost = uint256( uint256(uint256(totalGas-gasleft()-uint( 23504 * nbm )) * tx.gasprice)) + uint256( msg.value ); // cost of this spinoff transaction in wei + msg.value
        cost = uint256( cost / uint(nbm) );                                     // cost of spinoff transaction in wei per member of the spinoff group
        sum  = sum - (cost*uint(nbm));                                          // total refund amount

        //emit TestReturn(uint256 ( msg.value ), uint256 (nbm), uint256 ( sum ), uint256( cost ) );
      }
      

      // ---------------------- send back deposits  ----------------------------

      uint64 ownerId = 0;

      {
        uint flag = uint64(uint64(2**uint64(nbm))-1);                           // 2**nb -1 = all members mask, e.g. 0x7 for 3 members
        uint i=1;                                                               // pay back deposits to leaving members (ex-members)
        uint64 o;
        uint256 t = 0;
        
        do {
          t = tArr[i];
          
          if (((t & k_typeMask)>>252==10) && (t&k_executeFlag==0)) {            // cmd type = 10 = deposit ether/funds, not yet executed
            o = uint8((uint256( uint256(t)&k_assetMask )>>208)&k_asset2Mask);   // nb/id of new owner
        
            if (uint(uint256(t) & k_addressMask) > cost) {
              my_require(payable(address(uint160(uint256(_mem[7+(o*4)]) & k_addressMask))).send( uint(uint256(t) & k_addressMask)-cost ),"Forwarding failed.");  
              emit Deposit(address(uint160(uint256(_mem[7+(o*4)]) & k_addressMask)), uint(uint256(t) & k_addressMask)-cost);
              sum = sum - uint( uint(uint256(t) & k_addressMask)-cost );
            }
            
            tArr[i] = uint256(uint256( (uint256( uint64(uint64(nbSpinOwners)/2)+1 )<<216) & k_flagsMask ) + uint256( t & k_flags3Mask )) | k_executeFlag; // deposit ether/funds DONE
            flag = flag ^ uint64(2**uint64(o));                                 // computes new member nb of sender in spinoff group
          }
      
         i++;
        } while(t>0);
        
        ownerId = uint64(ownerIdFromFlag(uint64(flag)));
      }

      
      // -------------------- compensate msg.sender ----------------------------
      
      sum = sum + uint256(msg.sender.balance);                                  // compensate transaction sender
      
      {
        uint256 target =  uint256(_mem[7+(ownerId*4)]) & k_addressMask;         // receiver of new spinoff address, new address of sending member
        
        if (payable(this).balance >= sum) {
          my_require(payable(address(uint160(target))).send( sum ),"Payback sender failed.");
          emit Deposit(address(uint160(target)), sum);
        }
        else
        {
          my_require(payable(address(uint160(target))).send( payable(this).balance ),"Payback failed.");
          emit Deposit(address(uint160(target)), payable(this).balance);
        }

        //emit TestReturn(uint256 ( uint160(msg.sender) ), uint256 (ownerId), uint256 ( target ), uint256( sum ) );
      }
      
      return true;
    }
    
    function confirmSpinOffGroup_L51b(bytes32[] calldata _in, bytes calldata data32, bytes32[] calldata _mem, bytes32[] calldata _abi) external payable
    {
        uint totalGas = gasleft();
        
        uint _tId = uint256(_in[0]);
        uint256 t = getT(_tId);
    
        uint64 f = uint64( (uint256( uint256( t ) & k_flagsMask )>>216) & k_flags2Mask );
        my_require(uint64(f&getOwnerMask(msg.sender))==0 && uint8( (uint256( uint256( t ) & k_assetMask )>>208) & k_asset2Mask )<128 && (((t & k_typeMask)>>252) == 8) && isAddressOwner(msg.sender),"notConfirmed,notExecuted,nb,owner");

        uint64 f_s = uint64( (uint256( uint256( tArr[checkSplitPreconditions(_tId,128)] ) & k_flagsMask )>>216) & k_flags2Mask );
        if ((f_s&getOwnerMask(msg.sender))==0) return;                                                   // ignore non-eligable votes 

        f  = uint64(f|getOwnerMask(msg.sender));                                                         // confirm spin-off transaction

        if (uint64(uint64(f>>5) & uint64(f_s>>5))==uint64(f_s>>5)) {                                     // callExecution(_tId,t,f) immediately
          
          getRsv().setABI(bytes32(tArr[uint256(uint160(GWF))]),128,abi.encodePacked(_abi));              // update current group - before executing spin-off
          
          AbstractGroupWalletFactory(GWF).replicate_group_l9Y{value: msg.value*9/10}(_in,data32,_mem);   // *** NOT 100% = msg.value, but 90% - 10% remains in old GroupWallet ***
          
          saveExecuted(_tId,f,t);                                                                        // spinoff transaction saved as executed and completed
          
          require(sendSpinoffAssets(_tId, f, _mem, totalGas),"sendSpinoffAssets failed");                // pay back deposits, transfer legacy shares and contracts
          
        }
        else {
          tArr[_tId] = uint256( ((uint256(f)<<216) & k_flagsMask) + uint256( t & k_flags3Mask ) );
        }
    }
    
    function drainLegacyShares(bytes32 dhash,uint nb,address target) internal {
      uint256 tt;      
      uint i=0;
      do {
        tt = tArr[i];

        if ((tt & k_typeMask)>>252==k_legacyToken) {                            // cmd type = 11 = legacy token contract
          address legacyTokenContract = address(uint160(uint(uint256(tt) & k_addressMask)));

          //emit TestReturn(uint256(uint160(legacyTokenContract)), uint256( uint160(target) ), uint256(uint160(owners[nb])), uint256(dhash));

          AbstractTokenProxy(legacyTokenContract).drainLegacyShares(dhash,GWF,owners[nb],target);
        }

        i++;
       } while(tt>0);
    }

    function submitFirstTransaction_gm(uint firstTRecord, uint256 dhash) external payable
    { 
      bool isLegacyToken = ( uint8( uint256( uint256(uint256( uint256( firstTRecord ) & k_typeMask )>>252) & k_type2Mask ) )==k_legacyToken );
      my_require(isAddressOwner(msg.sender) || isLegacyToken,"not an owner or no legacyProxy!");
      my_require(tArr[0] == 0,"tArr in use error!!!");                          // only first transaction
      
      if (isLegacyToken) 
        tArr[0] = uint256( (uint256( uint64( uint64(owners.length>>1)+1 ) | getOwnerMask(msg.sender) )<<216) & k_flagsMask ) + uint256( uint256(firstTRecord) & k_flags4Mask );
      else
        tArr[0] = uint256( (uint256( uint64( uint64(owners.length>>1)+1 ) | getOwnerMask(msg.sender) )<<216) & k_flagsMask ) + uint256( uint256(firstTRecord) & k_flags3Mask );
      
      tArr[uint256(uint160(GWF))] = dhash;                                      // project domain hash
      
      emit GroupWalletDeployed(msg.sender,owners.length,uint256(block.timestamp));
    }
    
    function submitLegacyTransaction(uint tNb,uint tRecord) external payable
    {
      bool isLegacyToken = ( uint8( uint256( uint256(uint256( uint256( tRecord ) & k_typeMask )>>252) & k_type2Mask ) )==k_legacyToken );
      my_require(isLegacyToken,"no legacy transaction!");
      my_require(tNb>0,"tNb=0 !");
      my_require(tArr[tNb] == 0,"tArr overwrite error!!!");
      
      tArr[tNb] = uint256(uint256( uint256(uint256( uint64( uint64(owners.length>>1)+1 ) )<<216) & k_flagsMask ) + uint256( uint256(tRecord) & k_flags4Mask )) | k_executeFlag;
    }

    function submitTransaction_Hom(uint aTRecord) external payable
    {
      checkPreconditions(msg.value,aTRecord,0);
      tArr[msg.value] = uint256( (uint256( uint64( getTRequired(msg.value-1) ) | getOwnerMask(msg.sender) )<<216) & k_flagsMask ) + uint256( uint256(aTRecord) & k_flags3Mask );
    }
    
    function submitSplitTransaction(uint aTRecord, bytes32 _commitment, bytes32 _dname) external payable
    { 
      checkPreconditions(msg.value,aTRecord,7);
      my_require(checkSplitPreconditions(msg.value,0)==0,"split 0!");

      tArr[msg.value] = uint256( (uint256( uint64( getTRequired(msg.value-1) ) | getOwnerMask(msg.sender) )<<216) & k_flagsMask ) + uint256( uint256(aTRecord) & k_flags3Mask ); // transaction type 7 will NOT be executed by majority vote
      
      tArr[uint256(_commitment)&k_addressMask]     = uint256(_commitment);                           // save 32-byte commitment
      tArr[(uint256(_commitment)&k_addressMask)+1] = uint256(_dname);                                // save spinOff / split project domain name
      
      AbstractGroupWalletFactory(GWF).reserve_replicate(dHashFromLabelBytes32(_dname), _commitment); // commitment = reserve new spinOff domain
    }
    
    function submitExecuteSplitTransaction(uint aTRecord, uint256 _secret) external payable
    { 
      uint tNb = msg.value&0x000000000000000000000000000000000000000000000000000000ffffffffff;

      checkPreconditions(tNb,aTRecord,8);      
      my_require( uint256(tArr[uint160(aTRecord)&k_addressMask]&k_addressMask) == (uint256(aTRecord)&k_addressMask), string(abi.encodePacked( bytes32ToAsciiString(bytes32( uint256(tArr[uint160(aTRecord)&k_addressMask]&k_addressMask) ),32), " unknown domain!!!")) );
      
      uint splitTNb = checkSplitPreconditions(tNb,0);
      my_require(splitTNb>0, string(abi.encodePacked( bytes32ToAsciiString(bytes32( splitTNb ),32), " no split")) );
      
      
      tArr[splitTNb] = uint256( uint256(tArr[splitTNb]) | k_executeFlag);       // mark: split transaction type 7 = executed
      
      // -------------- register new domain ------------------------------------
      
      uint256 target       = uint256(uint160( uint256( aTRecord ) & k_addressMask ) + 1);
      string memory _dname = bytesToStr(bytes32(tArr[target]),uint(tArr[target])&0xff);                           // domainName, length
      
      uint _rent           = getCtrl().rentPrice(_dname,365*86400);                                               // rent rebel groupname for 1 year
      
      bytes32 dHash        = dHashFromLabelBytes32(bytes32(tArr[target]));

      getCtrl().registerWithConfig{value: _rent}(_dname,address(this),uint(365*86400),bytes32(_secret),address(getRsv()),GWF);
      getRsv().setName(dHash,string(abi.encodePacked(_dname,tldOfChain())));
      getENS().setOwner(dHash,GWF);
      
      tArr[tNb] = uint256( (uint256( uint64( getTRequired(tNb-1) ) | getOwnerMask(msg.sender) )<<216) & k_flagsMask ) + uint256( uint256(aTRecord) & k_flags3Mask );
    }

    function getMemberWelcome(address target) external view returns (bytes memory) { // ** problem ** ********** only for addMember() members *****
      my_require(isAddressOwner(target),"NOT an owner!!!");
      return abi.encode( tArr[uint256(uint160(target)+2)], tArr[uint256(uint160(target)+3)] );
    }
  
    function submitTransaction_addUser(uint256 aTRecord, uint256 dhash, uint256 labelHash, uint256 memK1, uint256 memK2, bytes calldata data) external payable
    {
      my_require(msg.value>0 || (msg.value==0 && dhash>0x0),"bad msg.value!!!");
      my_require(isAddressOwner(msg.sender) && ( ((aTRecord & k_typeMask)>>252 == 2) || ((aTRecord & k_typeMask)>>252 == 4) ),"only owner, bad cmd");
  
      uint256 targetId = uint256(aTRecord&k_addressMask);
      
      tArr[targetId+1] = labelHash;
      
      tArr[targetId+2] = memK1;
      tArr[targetId+3] = memK2;
      
      structures[targetId] = data;                                              // save new structure with added member
      
      if (dhash>0x0) {                                                          // is first first transaction nb = 0
        tArr[0]            = uint256( (uint256( uint64( uint64(owners.length>>1)+1 ) | getOwnerMask(msg.sender) )<<216) & k_flagsMask ) + uint256( uint256(aTRecord) & k_flags3Mask );
        tArr[uint256(uint160(GWF))] = dhash;                                    // store project domain hash
        emit GroupWalletDeployed(msg.sender,owners.length,uint256(block.timestamp));
      } else
      {
        tArr[msg.value]    = uint256( uint256(uint256( uint64( getTRequired(msg.value-1) ) | getOwnerMask(msg.sender) )<<216) & k_flagsMask ) + uint256( uint256(aTRecord) & k_flags3Mask );
      }
      
      my_require(getENS().owner( bytes32(tArr[uint256(uint160(GWF))]) ) == address(this), " - GWP contract is NOT domain owner!");
    }
  
    function executeTransaction_G1A(uint _tId) external payable
    {
      my_require(isAddressOwner(msg.sender),"only by owner!");
      if (msg.value==0) return;
      
      uint256 t = tArr[_tId];

      uint64 f = uint64( (uint256( uint256( t ) & k_flagsMask )>>216) & k_flags2Mask );
      uint64 o = getOwnerMask(msg.sender);
      my_require(uint64(f&o)>0,"confirmed!!!");
      
      my_require(uint8( (uint256( uint256( t ) & k_assetMask )>>208) & k_asset2Mask )<128, "G1a notExecuted!!!");

      f = uint64( uint64( (uint256( uint256( t ) & k_flagsMask )>>216) & k_flags2Mask) );

      if ( ( getFlags((msg.value-1)) & uint64(MAX_OWNER_COUNT) ) <= nbOfConfirmations( uint64(f/32) ) ) callExecution(_tId,t,f);
    }
    
    
    function welcomeOneNewOwner(address target, uint ownerId) internal {
      bytes32 l_dHash         = bytes32( tArr[uint256(uint160(GWF))] );
      bytes32 l_label         = bytes32( tArr[uint256(uint160(target)+1)] );
      bytes32 l_dlabelHash    = keccak256( abi.encodePacked(l_dHash,l_label) );

      getENS().setSubnodeRecord(l_dHash,l_label,address(this),address(getRsv()),uint64(block.timestamp*1000) & uint64(0xffffffffffff0000)); // e.g joe.ethereum.eth
      getRsv().setAddr(l_dlabelHash,target);
      getRsv().setABI (l_dHash,32,abi.encodePacked(structures[uint256(uint160(target))]));                                                  // update group structure
      getENS().setOwner(l_dlabelHash,target);
      
      if (address(this).balance>welcomeBudget) {
        my_require(payable(address(uint160(target))).send(welcomeBudget),"Funding new member failed.");
        emit Deposit(target, welcomeBudget);          
      }
      
      if (ownerId <  MAX_OWNER_COUNT) AbstractTokenMaster( AbstractGroupWalletFactory(GWF).getProxyToken(l_dHash) ).drainShares(l_dHash,GWF,owners[ownerId],target);

      if (ownerId == MAX_OWNER_COUNT) AbstractTokenMaster( AbstractGroupWalletFactory(GWF).getProxyToken(l_dHash) ).transfer_G8l(target, 10000); // 100 welcome shares
    }
    
    
    function callExecution(uint _tId,uint256 t,uint64 f) internal {
    
      uint8 typ =  uint8( (uint256( uint256( t ) & k_typeMask )>>252) & k_type2Mask ); // cmd type 0..15


      if (typ == 5) {                                                           // changeRequirement
        uint8 newMaj = uint8( (uint256( uint256( t ) & k_assetMask )>>208) & k_asset2Mask );
        my_require((newMaj>=2) && (newMaj<=MAX_OWNER_COUNT),"required 2-31!!!");

        f = (uint64(f|uint64(MAX_OWNER_COUNT)) ^ uint64(MAX_OWNER_COUNT))+uint64(newMaj);
        saveExecuted(_tId,f,t);
        return;
      }

      address target = address(uint160( uint256( t ) & k_addressMask ));

      if (typ == 1) {
        (bool succ,bytes memory returnData) = target.call{value: uint64( (uint256( uint256( t ) & k_valueMask )>>160) & k_value2Mask)<<20 }(""); // mul 1.048.576 = 2**20
        
        if (succ) {
          emit Deposit(target, uint256(uint64( (uint256( uint256( t ) & k_valueMask )>>160) & k_value2Mask)<<20) );
          tArr[_tId] = uint256( ((uint256(f)<<216) & k_flagsMask) + uint256( t & k_flags3Mask ) ) | k_executeFlag;
        }
        else
        {
          my_require(false, string(abi.encode( returnData, returnData.length )));
        }
        return;
      }
      else
      {
        if (typ == 2)                                                           // addOwner
        {
          my_require(!isAddressOwner(target),"ownerDoesNotExist!!!");
          
          uint64 r = uint64(f & uint64(MAX_OWNER_COUNT));
          my_require(owners.length < MAX_OWNER_COUNT && r >= 2 && r <= owners.length,"addOwner requirement!!!");

          owners.push(target);
          welcomeOneNewOwner(target,MAX_OWNER_COUNT);
          
          f = (uint64(f|uint64(MAX_OWNER_COUNT)) ^ uint64(MAX_OWNER_COUNT))+((uint64(activeOwners())/2)+1);
          saveExecuted(_tId,f,t);
          return;
        }
        else
        {
          if (typ == 3)                                                         // removeOwner
          {
            removeOneOwner(target);
            f = (uint64(f|uint64(MAX_OWNER_COUNT)) ^ uint64(MAX_OWNER_COUNT))+((uint64(activeOwners())/2)+1);
            saveExecuted  (_tId,f,t);
            return;
          }
          else
          {
            if (typ == 4) {
              my_require(!isAddressOwner(target),"ownerDoesNotExist!!!");
              
              uint8 ownerNb = uint8( (uint256( uint256( t ) & k_assetMask )>>208) & k_asset2Mask );
              welcomeOneNewOwner(target,ownerNb);
            
              ownerChange( owners[ownerNb], target);                            // replaceOwner
              
              saveExecuted(_tId,f,t);
              return;
            }
            else
            {
              if (typ == 6) {                                                   // transferShares / transfer GroupWallet Token
                uint value = uint64( (uint256( uint256( t ) & k_valueMask )>>160) & k_value2Mask); // nb of token/shares to be transferred
                my_require(value>0,"nb shares = 0!!!");
                
                bytes32             l_dHash = bytes32( tArr[uint256(uint160(GWF))] );                                        // project domain hash
                AbstractTokenMaster l_token = AbstractTokenMaster( AbstractGroupWalletFactory(GWF).getProxyToken(l_dHash) ); // project ProxyToken contract
                
                l_token.transfer_G8l(target, value);

                saveExecuted(_tId,f,t);
                return;
              }
              else
              {
                if (typ == 7) {                                                 // split-group
                  tArr[_tId] = uint256( ((uint256(f)<<216) & k_flagsMask) + uint256( t & k_flags3Mask ) ); // DO NOT execute split-group yet
                  return;
                }
  
                if (typ == 8) {                                                 // spin-off
                  tArr[_tId] = uint256( ((uint256(f)<<216) & k_flagsMask) + uint256( t & k_flags3Mask ) );
                  return;
                }

                if (typ == 9) {                                                 // migrate group to another chain
                  saveExecuted(_tId,f,t);
                  return;
                }

                if (typ == 11) {                                                // legacy token
                  saveExecuted(_tId,f,t);
                  return;
                }

                my_require(false,"cmd type!!!");
              }
            }
          }
        }
      }
    }
    
    function removeOneOwner(address target) internal {
    
      ownerChange(target, address(0x0));                                        // removeOwner
    
      uint bal = address(this).balance;
      
      if (bal>lowBudget) {
        uint val = (bal-lowBudget) / owners.length;
        my_require(payable(address(uint160(target))).send(val),"Refunding ex-member failed.");
        emit Deposit(target, val);          
      }
    }
    
    function activeOwners() private view returns (uint8 count) {
      count = 0;
      
      uint i=0;
      do {
        if (uint160(owners[i])!=0x0) count++; 
        i++;
      } while(i<owners.length);

      return count;
    }

    function revokeConfirmation_NlP(uint _tId) external 
    {
      my_require(isAddressOwner(msg.sender),"not an owner!");

      uint256 t = tArr[_tId];
      uint64 f  = uint64(uint256( uint256(uint256( uint256( t ) & k_flagsMask )>>216) & k_flags2Mask));
      uint64 o  = getOwnerMask(msg.sender);

      my_require(o>0,"no OwnerMask!!!");
      my_require(uint64(f&o)>0,"confirmed!!!");
      my_require((uint256(t) & k_executeFlag)==0, "cannot revoke executed!!!");
      
      tArr[_tId] = uint256( (uint256( uint64(f|o) ^ uint64(o) )<<216) & k_flagsMask ) + uint256( t & k_flags3Mask );
    }

    function getTNumberPublic() public view returns (uint count)
    {
      count = 0;
      
      if (tArr[0]==0) return count;
      
      uint i = 0;
      do {
        if (tArr[i] > 0) count += 1;
        i++;
      } while(tArr[i] > 0);
    }

    function isConfirmed(uint _tNb) public view returns (bool) {
      uint64 r;
      uint64 f = getFlags(_tNb);
      if (_tNb==0) r = uint64(owners.length>>1)+1;
      if (_tNb >0) r = uint64(getTRequired(_tNb-1));
      if (r==0) r = uint64(owners.length>>1)+1;
      uint64 c = nbOfConfirmations( uint64(f/32) );
      return (r <= c);
    }

    function getRequiredPublic(uint _tNb) external view returns (uint count)
    { 
      if (_tNb==0) return uint( uint64(owners.length>>1)+1 );
      else return getTRequired(_tNb-1);
    }
    
    function getIsOwner(address _owner) external view returns (bool)
    {
      return isAddressOwner(_owner);
    }
    
    function getTransactionsCount() external view returns (uint)
    {
      return getTNumberPublic();
    }
    
    function getTransactions(uint _tNb) external view returns (address destination, uint value, uint8 asset, bool executed, uint64 flags, uint8 typ, bool conf)
    {
      if (getTNumberPublic()>0)
        return (getTarget(_tNb),getTValue(_tNb),getAsset(_tNb),isTExecuted(_tNb),getFlags(_tNb),getType(_tNb),isConfirmed(_tNb));
    }
    
    function getTransactionRecord(uint _tNb) external view returns (uint256)
    {
      if (getTNumberPublic()>0) return tArr[_tNb];
      return 0;
    }
    
    function getAllTransactions() public view returns (uint256[] memory transArr)
    {
      if (tArr[0]==0) return new uint256[](0);
      
      uint count = 0;
      uint i = 0;
      do {
        if (tArr[i] > 0) count += 1;
        i++;
      } while(tArr[i] > 0);
      
      uint256[] memory resultArr = new uint256[](count);

      i = 0;
      uint256 t;
      address token;
      do {
        t = tArr[i];
        
        if (uint8(uint256((uint256( uint256( t ) & k_typeMask )>>252) & k_type2Mask))==k_legacyToken) { // legacy token
          token = address( uint160( uint256( t & k_addressMask ) ) );
          resultArr[i] = uint256(t & k_value3Mask) + uint256(uint256( uint256(AbstractTokenProxy(token).balanceOf(tx.origin)) << 160 ) & k_valueMask); // legacy token balance of current member
        }
        else
        {
          resultArr[i] = t;                                                     // transaction record
        }
        
        i++;
      } while(i<count);

      return resultArr;
    }

    function getConfirmationCount(uint _tNb) external view returns (uint)
    {
      uint64 f = getFlags(_tNb);      
      return uint(nbOfConfirmations(uint64(f>>5)));
    }
    
    function getTransactionCount(bool pending, bool executed) external view returns (uint count)
    {
      uint i = 0;
      uint t = getTNumberPublic();
      
      if (t==0) return 0;
      
      do {
        if (pending && !isTExecuted(i) || executed && isTExecuted(i)) count += 1;
        i++;
      } while(i<t);
    }

    function addressConfirmations(uint _tNb,address _owner) external view returns (bool)
    {
      return ownerConfirmed(_tNb,_owner);
    }

    function getOwners() external view returns (address[] memory)
    {
      return owners;
    }

    function getConfirmations(uint _tId) external view returns (address[] memory _confirmations)
    {   
      uint m = owners.length;
      address[] memory confirmationsTemp = new address[](m);
      uint count = 0;
      uint i=0;
      
      do
      {
        if (ownerConfirmed(_tId,owners[i])) confirmationsTemp[count++] = owners[i];
        i++;
      } while (i<m);
      
      _confirmations = new address[](count);
      
      i=0;
      do
      {
        _confirmations[i] = confirmationsTemp[i];
        i++;
      } while (i<count);      
    }
    
    function nbOfConfirmations(uint64 confirmFlags) internal view returns (uint64 nb) {
      uint64 m = 1;
      uint o   = owners.length;
      
      do
      {
        if ((confirmFlags & m) > 0) nb++;
        m = m*2;
        o--;
      } while (o>0);
      
      return nb;
    }
    
    function isAddressOwner(address _owner) private view returns (bool) {      
      uint m = owners.length;
      if (m==0) return false;
  
      uint i=0;
      do {
        if (owners[i]==_owner) return true;
        i++;
      } while(i<m&&i<MAX_OWNER_COUNT);

      return false;
    }
    
    function ownerChange( address _owner, address _newOwner) private {
      uint i=0;
      do {
        if (owners[i]==_owner) { owners[i] = _newOwner; return; } 
        i++;
      } while(i<owners.length&&i<MAX_OWNER_COUNT);

      my_require(false,"ownerChange illegal owner!!!");
    }
    
    function getOwnerMask(address _owner) private view returns (uint64 mask) {
      mask=32;
      uint i=0;
      do {
        if (owners[i]==_owner) return mask;
        mask = mask*2;
        i++;
      } while(i<owners.length&&i<MAX_OWNER_COUNT);

      return 0;
    }
    
    function ownerIdFromFlag(uint64 _ownerFlag) private pure returns (uint64 id) {
      id=1;
      uint64 i=0;
      do {
        if (_ownerFlag==id) return i;
        id = id*2;
        i++;
      } while(i<MAX_OWNER_COUNT);

      return 0;
    }

    
    function isTExecuted(uint _tNb) private view returns (bool) {
      return (getAsset(_tNb)>127);
    }

    function getOpenSplitTransactionNb(uint _tNb, uint8 executed) private view returns (uint idx)
    {
      idx    = 0;
      
      uint256 t;
      uint64 f;
      uint8 a;
      
      if ((tArr[0]==0) || (_tNb<=0)) return 0;
      
      uint i = _tNb;
      do {
        t = tArr[i];
        f = uint64(uint256( (uint256( uint256( t ) & k_flagsMask )>>216) & k_flags2Mask ));
        a = uint8 (uint256( (uint256( uint256( t ) & k_assetMask )>>208) & k_asset2Mask ));
        if ( (t!=0) && (uint8(uint256((uint256( uint256( t ) & k_typeMask )>>252) & k_type2Mask)) == 7) && ((a&128)==executed) && (nbOfConfirmations(uint64(f/32))>0)) return i;
        i--;
      } while(i>0);
      
      return 0;
    }

    function ownerConfirmed(uint _tNb, address _owner) private view returns (bool) {
      uint64 f = getFlags(_tNb);
      uint64 o = getOwnerMask(_owner);
      return (uint64(f&o)>0);
    }
    
    function getTRequired(uint _tId) private view returns (uint64)
    {
      return uint64(getFlags(_tId) & uint64(MAX_OWNER_COUNT));
    }
    
    function newProxyGroupWallet_j5O(address[] calldata _owners) external payable {
      uint l = _owners.length;
    
      uint i;
      do {
        my_require(_owners[i] != address(0x0), "Bad owner list!");
        owners.push(_owners[i]);
        i++;
      } while(i<l);
      
      GWF = msg.sender;
    }
    
    function saveAsset(bytes32 dhash, uint256 asset, string calldata key, string calldata data) external payable
    {
      my_require(isAddressOwner(msg.sender)&&dhash!=0x0&&getENS().recordExists(dhash)&&getENS().owner(dhash)==address(this),"- owner,domain hash,domain exist,only owner");
      
      if (asset!=3) {
        uint256 pHash = tArr[uint256(uint160(GWF))];
        my_require(pHash>0&&getENS().owner(bytes32(pHash))==address(this)&&bytes32(pHash)==dhash, " - pHash,GWP NOT owner/hash unexpected");
      }

      getRsv().setText(dhash,key,data);
        
      if (asset==1) emit ColorTableSaved (dhash);
      if (asset==2) emit EtherScriptSaved(dhash,key);
    }

    function forwardEther(address payable receiver) external payable
    {
      my_require(msg.value>0&&receiver.send(msg.value),"Forwarding failed.");
      emit Deposit(receiver, msg.value);
    }
    
    function depositEther(uint aTRecord, uint tNb) external payable
    {
      my_require(tNb>0 && tArr[tNb]==0,"depositEther failed.");
      
      address commit = address( uint160( uint256(uint256(aTRecord) & k_addressMask) ) );
      my_require(msg.value>0 && uint160(commit)!=0x0 && uint256(uint256(aTRecord & k_typeMask)>>252)==10,"value=0,address,cmd");
      
      uint64 o = getOwnerMask(msg.sender);
      tArr[tNb] = uint256( uint256(uint256( uint64(uint64( getTRequired(tNb-1) ) | o) )<<216) & k_flagsMask ) + uint256(uint256(uint256(aTRecord) & k_address2Mask) + uint256(msg.value));

      emit Deposit(address(payable(this)), uint256(msg.value));
    }

    fallback() external payable
    {
      if (msg.value > 0) {
        emit Deposit(address(this), msg.value);
        return;
      }
      my_require(false,"GWM fallback!");
    }
    
    receive() external payable { emit Deposit(msg.sender, msg.value); }

    function version() external pure returns(uint256 v) {
      return 20010010;
    }
    
    constructor(address[] memory _owners) payable
    {
      uint i;
      do {
        my_require(_owners[i] != address(0x0), "Bad owner list!");              // only for unit tests of the master contract, owners NOT needed 
        owners.push(_owners[i]);
        i++;
      } while(i<_owners.length);
      
      masterCopy       = address(msg.sender);                                   // save owner of GroupWalletMaster
    }
    
    uint constant     private MAX_OWNER_COUNT = 31;
    uint constant     private welcomeBudget   = 0.025 ether;                    // new member gets welcome ether
    uint constant     private lowBudget       = 0.200 ether;                    // GWP - GroupWalletProxy contract keeps ether if members depart

    uint256 constant k_legacyToken  = 11;                                       // cmd type of the legacyToken transaction type

    uint256 constant k_addressMask  = 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff;
    uint256 constant k_address2Mask = 0xffffffffffffffffffffffff0000000000000000000000000000000000000000;
        
    uint256 constant k_valueMask    = 0x000000000000ffffffffffff0000000000000000000000000000000000000000;
    uint256 constant k_value3Mask   = 0xffffffffffff000000000000ffffffffffffffffffffffffffffffffffffffff;
    uint256 constant k_value2Mask   = 0x0000000000000000000000000000000000000000000000000000ffffffffffff;

    uint256 constant k_flagsMask    = 0x0fffffffff000000000000000000000000000000000000000000000000000000;
    uint256 constant k_flags2Mask   = 0x0000000000000000000000000000000000000000000000000000000fffffffff;
    uint256 constant k_flags3Mask   = 0xf000000000ffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    uint256 constant k_flags4Mask   = 0xffffffffe0ffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    
    uint256 constant k_assetMask    = 0x0000000000ff0000000000000000000000000000000000000000000000000000;
    uint256 constant k_asset2Mask   = 0x00000000000000000000000000000000000000000000000000000000000000ff;
    uint256 constant k_asset3Mask   = 0xffffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff;
    uint256 constant k_executeFlag  = 0x0000000000800000000000000000000000000000000000000000000000000000;
    
    uint256 constant k_typeMask     = 0xf000000000000000000000000000000000000000000000000000000000000000;
    uint256 constant k_type2Mask    = 0x000000000000000000000000000000000000000000000000000000000000000f;
}