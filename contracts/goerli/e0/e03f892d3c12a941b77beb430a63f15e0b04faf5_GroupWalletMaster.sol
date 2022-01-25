/**
 *Submitted for verification at Etherscan.io on 2022-01-25
*/

pragma solidity >=0.4.22 <0.6.0;
// ungravel.eth, GroupWallet, GroupWalletMaster, ProxyWallet, TokenMaster, ProxyToken and GroupWalletFactory by pepihasenfuss.eth 2017 - 2022

// GroupWalletMaster contract based on MultiSigContracts inspired by Parity MultiSignature contract, consensys and gnosis MultiSig contracts


contract AbstractGroupWalletFactory {
  AbstractResolver                public  resolverContract;
  AbstractETHRegistrarController  public  controllerContract;
  AbstractBaseRegistrar           public  base;
  AbstractENS                     public  ens;

  function getProxyToken(bytes32 _domainHash) public view returns (address p);
  function reserve_replicate(bytes32 _domainHash,bytes32 _commitment) external payable;
  function replicate_group_l9Y(bytes32[] calldata _m, bytes calldata data32, bytes32[] calldata _mem) external payable;
}

contract AbstractTokenMaster {  
  function transfer_G8l(address toReceiver, uint amount) external;
  function drainShares(bytes32 dHash, address _GWF, address from, address toReceiver) external;
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

contract AbstractResolver {
  mapping(bytes32=>bytes) hashes;

  event AddrChanged(bytes32 indexed node, address a);
  event AddressChanged(bytes32 indexed node, uint coinType, bytes newAddress);
  event NameChanged(bytes32 indexed node, string name);
  event ABIChanged(bytes32 indexed node, uint256 indexed contentType);
  event PubkeyChanged(bytes32 indexed node, bytes32 x, bytes32 y);
  event TextChanged(bytes32 indexed node, string indexed indexedKey, string key);
  event ContenthashChanged(bytes32 indexed node, bytes hash);

  function setABI(bytes32 node, uint256 contentType, bytes calldata data) external;
  function setAddr(bytes32 node, address r_addr) external;
  function setAddr(bytes32 node, uint coinType, bytes calldata a) external;
  function setName(bytes32 node, string calldata _name) external;
  function setText(bytes32 node, string calldata key, string calldata value) external;
  function setAuthorisation(bytes32 node, address target, bool isAuthorised) external;
}

contract AbstractENS {
  event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);
  event Transfer(bytes32 indexed node, address owner);
  event NewResolver(bytes32 indexed node, address resolver);
  event NewTTL(bytes32 indexed node, uint64 ttl);
  event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

  function setSubnodeRecord(bytes32 node, bytes32 label, address owner, address resolver, uint64 ttl) external;
  function setOwner(bytes32 node, address owner) external;
  function owner(bytes32 node) public view returns (address);
  function recordExists(bytes32 node) external view returns (bool);
}

contract AbstractETHRegistrarController {
  mapping(bytes32=>uint) public commitments;

  uint public minCommitmentAge;
  uint public maxCommitmentAge;

  event NameRegistered(string name, bytes32 indexed label, address indexed owner, uint cost, uint expires);
  event NameRenewed(string name, bytes32 indexed label, uint cost, uint expires);

  function rentPrice(string memory name, uint duration) view public returns(uint);
  function registerWithConfig(string memory name, address owner, uint duration, bytes32 secret, address resolver, address addr) public payable;
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
      return address( uint160( uint256( tArr[tNb] ) & k_addressMask ) );
    }

    function getTValue(uint tNb) private view returns (uint64) {
      return uint64( (uint256( uint256( tArr[tNb] ) & k_valueMask )>>160) & k_value2Mask);
    }

    function getAsset(uint tNb) private view returns (uint8) {
      return uint8(  (uint256( uint256( tArr[tNb] ) & k_assetMask )>>208) & k_asset2Mask);
    }

    function getFlags(uint tNb) private view returns (uint64) {
      return uint64( (uint256( uint256( tArr[tNb] ) & k_flagsMask )>>216) & k_flags2Mask);
    }

    function getType(uint tNb) private view returns (uint8) {
      return uint8(  (uint256( uint256( tArr[tNb] ) & k_typeMask )>>252) & k_type2Mask);
    }
    
    function saveFlags(uint _tId, uint64 flags) private {
      tArr[_tId] = uint256( (uint256( flags )<<216) & k_flagsMask ) + uint256( tArr[_tId] & k_flags3Mask );
    }
    
    function saveAsset(uint _tId, uint8 asset) private {
      tArr[_tId] = uint256( (uint256( asset )<<208) & k_assetMask ) + uint256( tArr[_tId] & k_asset3Mask );
    }
    
    function saveExecuted(uint _tId, uint64 f, uint t) private {
       tArr[_tId] = uint256( ((uint256(f)<<216) & k_flagsMask) + uint256( t & k_flags3Mask ) ) | k_executeFlag;
    }
    
    // -------------------  strings --------------------------------------------

    function my_require(bool b, string memory str) private pure {
      require(b,str);
    }

    function char(byte b) private pure returns (byte c) {
        if (uint8(b) < uint8(10)) return byte(uint8(b) + 0x30);
        else return byte(uint8(b) + 0x57);
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
    
    function bytes32ToAsciiString(bytes32 _bytes32, uint len) private pure returns (string memory) {
        bytes memory s = new bytes((len*2)+2);
        s[0] = 0x30;
        s[1] = 0x78;
      
        for (uint i = 0; i < len; i++) {
            byte b = byte(uint8(uint(_bytes32) / (2 ** (8 * ((len-1) - i)))));
            byte hi = byte(uint8(b) / 16);
            byte lo = byte(uint8(b) - 16 * uint8(hi));
            s[2+(2 * i)] = char(hi);
            s[2+(2 * i) + 1] = char(lo);
        }
        return string(s);
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
      
      my_require((tRecord & k_typeMask)>>252 == cmd,"action nb!");
    }
    
    function checkSplitPreconditions(uint tNb, uint8 exec) private view returns (uint) {
      my_require(owners.length>3,"group too small!");
    
      return getOpenSplitTransactionNb(tNb-1,exec);
    }

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
    
    function confirmSpinOffGroup_L51b(bytes32[] calldata _in, bytes calldata data32, bytes32[] calldata _mem, bytes32[] calldata _abi) external payable
    {
        uint _tId = uint256(_in[0]);
        uint256 t = getT(_tId);
    
        uint64 f = uint64( (uint256( uint256( t ) & k_flagsMask )>>216) & k_flags2Mask );
        uint64 o = getOwnerMask(msg.sender);
        my_require(uint64(f&o)==0 && uint8( (uint256( uint256( t ) & k_assetMask )>>208) & k_asset2Mask )<128 && (((t & k_typeMask)>>252) == 8) && isAddressOwner(msg.sender),"notConfirmed,notExecuted,nb,owner");

        uint64 f_s = uint64( (uint256( uint256( tArr[checkSplitPreconditions(_tId,128)] ) & k_flagsMask )>>216) & k_flags2Mask );
        if ((f_s&o)==0) return;                                                 // ignore non-eligable votes 

        f  = uint64(f|o);                                                       // confirm spin-off transaction

        if (uint64(uint64(f>>5) & uint64(f_s>>5))==uint64(f_s>>5)) {            // callExecution(_tId,t,f) locally
          
          getRsv().setABI(bytes32(tArr[uint256(GWF)]),128,abi.encodePacked(_abi));                      // update current group - before executing spin-off
          AbstractGroupWalletFactory(GWF).replicate_group_l9Y.value(msg.value*9/10)(_in,data32,_mem);   // *** NOT msg.value, but 90% - 10% remains in old GroupWallet ***
          
          saveExecuted(_tId,f,t);


          uint i=1;
          do {                                                                  // pay out deposits of leaving ex-members
            t = tArr[i];
            
            if (((t & k_typeMask)>>252==10) && (t&k_executeFlag==0)) {          // cmd type = 10 = deposit ether/funds, not yet executed
              o = uint8((uint256( uint256(t)&k_assetMask )>>208)&k_asset2Mask); // nb/id of new owner
          
              my_require(address(uint160(uint256(_mem[7+(o*4)]) & k_addressMask)).send(uint(uint256(t) & k_addressMask)),"Forwarding failed.");  
              emit Deposit(address(uint160(uint256(_mem[7+(o*4)]) & k_addressMask)), uint(uint256(t) & k_addressMask));
              
              tArr[i] = uint256(t) | k_executeFlag;
            }
            
           i++;
          } while(t>0);


          o=1;
          f_s=0;
          i=0;
          do {
            if ((uint64(f>>5)&o)==o) {
              t =  uint256(_mem[7+(f_s*4)]) & k_addressMask;                    // target / receiver of shares
              f_s++;
              
              AbstractTokenMaster(AbstractGroupWalletFactory(GWF).getProxyToken( bytes32(tArr[uint256(GWF)]) )).drainShares(bytes32(tArr[uint256(GWF)]),GWF,owners[i],address(uint160(t)));
              
              ownerChange(owners[i], address(0x0));                             // remove confirmed spin-off group member
              saveFlags(_tId,(uint64(f|uint64(MAX_OWNER_COUNT)) ^ uint64(MAX_OWNER_COUNT))+((uint64(activeOwners())/2)+1));
            }
            
            o = o*2;
            i++;
          } while(i<owners.length);
          
        }
        else tArr[_tId] = uint256( ((uint256(f)<<216) & k_flagsMask) + uint256( t & k_flags3Mask ) );
    }

    function submitFirstTransaction_gm(uint firstTRecord, uint256 dhash) external payable
    { 
      my_require(isAddressOwner(msg.sender),"ownerExists!!!");
      my_require(tArr[0] == 0,"tArr in use error!!!");                          // only first transaction
      
      tArr[0] = uint256( (uint256( uint64( uint64(owners.length>>1)+1 ) | getOwnerMask(msg.sender) )<<216) & k_flagsMask ) + uint256( uint256(firstTRecord) & k_flags3Mask );
      
      tArr[uint256(GWF)] = dhash;                                               // project domain hash
      
      emit GroupWalletDeployed(msg.sender,owners.length,uint256(now));
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
      
      uint _rent           = getCtrl().rentPrice(_dname,365*86400);
      
      bytes32 dHash        = dHashFromLabelBytes32(bytes32(tArr[target]));

      getCtrl().registerWithConfig.value(_rent)(_dname,address(this),uint(365*86400),bytes32(_secret),address(getRsv()),GWF);
      getRsv().setName(dHash,string(abi.encodePacked(_dname,".eth")));
      getENS().setOwner(dHash,GWF);
      
      tArr[tNb] = uint256( (uint256( uint64( getTRequired(tNb-1) ) | getOwnerMask(msg.sender) )<<216) & k_flagsMask ) + uint256( uint256(aTRecord) & k_flags3Mask );
    }

    function getMemberWelcome(address target) external view returns (bytes memory) { // ** problem ** ********** only for addMember() members *****
      my_require(isAddressOwner(target),"NOT an owner!!!");
      return abi.encode( tArr[uint256(target)+2], tArr[uint256(target)+3] );
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
        tArr[uint256(GWF)] = dhash;                                             // store project domain hash
        emit GroupWalletDeployed(msg.sender,owners.length,uint256(now));
      } else
      {
        tArr[msg.value]    = uint256( (uint256( uint64( getTRequired(msg.value-1) ) | getOwnerMask(msg.sender) )<<216) & k_flagsMask ) + uint256( uint256(aTRecord) & k_flags3Mask );
      }
      
      my_require(getENS().owner( bytes32(tArr[uint256(GWF)]) ) == address(this), " - GWP contract is NOT domain owner!");
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
      bytes32 l_dHash         = bytes32( tArr[uint256(GWF)] );
      bytes32 l_label         = bytes32( tArr[uint256(target)+1] );
      bytes32 l_dlabelHash    = keccak256( abi.encodePacked(l_dHash,l_label) );

      getENS().setSubnodeRecord(l_dHash,l_label,address(this),address(getRsv()),uint64(now*1000) & uint64(0xffffffffffff0000));       // e.g joe.ethereum.eth
      getRsv().setAddr(l_dlabelHash,target);
      getRsv().setABI (l_dHash,32,abi.encodePacked(structures[uint256(target)]));                                                     // update group structure
      getENS().setOwner(l_dlabelHash,target);
      
      if (address(this).balance>welcomeBudget) {
        my_require(address(uint160(target)).send(welcomeBudget),"Funding new member failed.");
        emit Deposit(target, welcomeBudget);          
      }
      
      if (ownerId <  MAX_OWNER_COUNT) AbstractTokenMaster( AbstractGroupWalletFactory(GWF).getProxyToken(l_dHash) ).drainShares(l_dHash,GWF,owners[ownerId],target);

      if (ownerId == MAX_OWNER_COUNT) AbstractTokenMaster( AbstractGroupWalletFactory(GWF).getProxyToken(l_dHash) ).transfer_G8l(target, 10000);                      // 100 welcome shares
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
        (bool succ,bytes memory returnData) = target.call.value( uint64( (uint256( uint256( t ) & k_valueMask )>>160) & k_value2Mask)<<20 )(""); // mul 1.048.576 = 2**20
        
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
                
                bytes32             l_dHash = bytes32( tArr[uint256(GWF)] );                                                 // project domain hash
                AbstractTokenMaster l_token = AbstractTokenMaster( AbstractGroupWalletFactory(GWF).getProxyToken(l_dHash) ); // project ProxyToken contract
                
                l_token.transfer_G8l(target, value);

                saveExecuted(_tId,f,t);
                return;
              }
              else
              {
                if (typ == 7) {
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
        my_require(address(uint160(target)).send(val),"Refunding ex-member failed.");
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
      uint64 f  = uint64( (uint256( uint256( t ) & k_flagsMask )>>216) & k_flags2Mask);
      uint64 o  = getOwnerMask(msg.sender);

      my_require((uint64(f&o)>0) ,"confirmed!!!");
      my_require(uint8((uint256( uint256( t ) & k_assetMask )>>208) & k_asset2Mask)<128, "revoke notExecuted!!!");
      
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
      uint64 f = getFlags(_tNb);
      uint64 r = uint64(getTRequired(_tNb-1));
      if (r==0) r = uint64(owners.length>>1)+1;
      uint64 c = nbOfConfirmations( uint64(f/32) );
      return (r <= c);
    }

    function getRequiredPublic(uint _tNb) external view returns (uint count)
    { 
      return getTRequired(_tNb-1);
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

    function getConfirmationCount(uint _tNb) external view returns (uint)
    {
      uint64 f = getFlags(_tNb);      
      return nbOfConfirmations(uint64(f>>5));
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
        
    function nbOfConfirmations(uint64 confirmFlags) internal view returns (uint8 nb) {
      uint64 m = 1;
      uint o   = owners.length;
      
      do
      {
        if ((confirmFlags & m) > 0) nb++;
        m = m*2;
      } while (o-->0);
      
      return nb;
    }
    
    function isAddressOwner(address _owner) private view returns (bool) {      
      uint m = owners.length;
      if (m==0) return false;
  
      uint i=0;
      do {
        if (owners[i]==_owner) return true;
        i++;
      } while(i<owners.length&&i<MAX_OWNER_COUNT);

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
      uint64 m=32;
      uint i=0;
      do {
        if (owners[i]==_owner) return m;
        m = m*2;
        i++;
      } while(i<owners.length&&i<MAX_OWNER_COUNT);

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
        f = uint64( (uint256( uint256( t ) & k_flagsMask )>>216) & k_flags2Mask );
        a = uint8 ( (uint256( uint256( t ) & k_assetMask )>>208) & k_asset2Mask );
        if ( (t!=0) && (uint8((uint256( uint256( t ) & k_typeMask )>>252) & k_type2Mask) == 7) && ((a&128)==executed) && (nbOfConfirmations(uint64(f/32))>0)) return i;
      } while(i-->0);
      
      return 0;
    }

    function ownerConfirmed(uint _tNb, address _owner) private view returns (bool) {
      uint64 f = getFlags(_tNb);
      uint64 o = getOwnerMask(_owner);
      return (uint64(f&o)>0);
    }
    
    function getTRequired(uint _tId) private view returns (uint64)
    {
      if ((_tId+1)==0) return uint64(owners.length>>1)+1;
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
        uint256 pHash = tArr[uint256(GWF)];
        my_require(pHash>0&&getENS().owner(bytes32(pHash))==address(this)&&bytes32(pHash)==dhash, " - pHash,GWP NOT owner/hash unexpected");
      }

      getRsv().setText(dhash,key,data);
        
      if (asset==1) emit ColorTableSaved (dhash);
      if (asset==2) emit EtherScriptSaved(dhash,key);
    }

    function version() external pure returns(uint256 v) {
      return 2001002;
    }

    function forwardEther(address payable receiver) external payable
    {
      my_require(msg.value>0&&receiver.send(msg.value),"Forwarding failed.");
      emit Deposit(receiver, msg.value);
    }
    
    function depositEther(uint aTRecord, uint tNb) external payable
    {
      my_require(tNb>0&&tArr[tNb]==0,"depositEther failed.");
      
      address commit = address(uint160( uint256(aTRecord) & k_addressMask ));
      my_require(msg.value>0&&uint160(commit)>0&&(aTRecord & k_typeMask)>>252==10&&tArr[tNb]==0,"value=0,address,cmd,tNb");
      
      tArr[tNb] = uint256((uint256( getOwnerMask(msg.sender) )<<216) & k_flagsMask) + ((uint256(aTRecord) & k_address2Mask) + uint256(msg.value));

      emit Deposit(msg.sender, msg.value);
    }

    function() external payable
    {
      if (msg.value > 0) {
        emit Deposit(msg.sender, msg.value);
        return;
      }
      my_require(false,"GWM fallback!");
    }
    
    constructor(address[] memory _owners) public payable
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

    uint256 constant k_addressMask  = 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff;
    uint256 constant k_address2Mask = 0xffffffffffffffffffffffff0000000000000000000000000000000000000000;
        
    uint256 constant k_valueMask    = 0x000000000000ffffffffffff0000000000000000000000000000000000000000;
    uint256 constant k_value2Mask   = 0x0000000000000000000000000000000000000000000000000000ffffffffffff;
    
    uint256 constant k_flagsMask    = 0x0fffffffff000000000000000000000000000000000000000000000000000000;
    uint256 constant k_flags2Mask   = 0x0000000000000000000000000000000000000000000000000000000fffffffff;
    uint256 constant k_flags3Mask   = 0xf000000000ffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    
    uint256 constant k_assetMask    = 0x0000000000ff0000000000000000000000000000000000000000000000000000;
    uint256 constant k_asset2Mask   = 0x00000000000000000000000000000000000000000000000000000000000000ff;
    uint256 constant k_asset3Mask   = 0xffffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffff;
    uint256 constant k_executeFlag  = 0x0000000000800000000000000000000000000000000000000000000000000000;
    
    uint256 constant k_typeMask     = 0xf000000000000000000000000000000000000000000000000000000000000000;
    uint256 constant k_type2Mask    = 0x000000000000000000000000000000000000000000000000000000000000000f;
}