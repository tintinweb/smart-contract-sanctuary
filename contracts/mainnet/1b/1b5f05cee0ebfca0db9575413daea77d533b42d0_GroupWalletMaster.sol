/**
 *Submitted for verification at Etherscan.io on 2021-06-14
*/

pragma solidity >=0.4.22 <0.6.0;
// GroupWalletMaster contract, based on MultiSigContracts inspired by parity MultiSignature contract, consensys and gnosis MultiSig contracts

contract AbstractGroupWalletFactory {
  AbstractResolver                public  resolverContract;
  AbstractETHRegistrarController  public  controllerContract;
  AbstractBaseRegistrar           public  base;
  AbstractENS                     public  ens;

  function getOwner(bytes32 _domainHash) external view returns (address);
}

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

  function setRecord(bytes32 node, address owner, address resolver, uint64 ttl) external;
  function setSubnodeRecord(bytes32 node, bytes32 label, address owner, address resolver, uint64 ttl) external;
  function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external returns(bytes32);
  function setResolver(bytes32 node, address resolver) external;
  function setOwner(bytes32 node, address owner) external;
  function setApprovalForAll(address operator, bool approved) external;
  function owner(bytes32 node) public view returns (address);
  function recordExists(bytes32 node) external view returns (bool);
  function isApprovedForAll(address ensowner, address operator) external view returns (bool);
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

contract GroupWalletMaster {
    address internal masterCopy;                                                // ******* DO NOT CHANGE ORDER ******

    mapping(uint256 => uint256) private  tArr;                                  // transaction records
    address[]                   private  owners;                                // contract owners = members of the group

    address internal GWF;                                                       // GWF - GroupWalletFactory master contract
    mapping(uint256 => bytes)   private  structures;                            // saving encoded group structure for addUser()
    
                                                                                // ******* DO NOT CHANGE ORDER ******

    event TestReturnData(address sender, bytes returnData);
    event TestReturnLength(address sender, uint256 value);
    event GroupWalletDeployed(address sender, uint256 members, uint256 timeStamp);
    event GroupWalletMessage(bytes32 msg);
    event Deposit(address from, uint256 value);
    event ColorTableSaved(bytes32 domainHash);
    event EtherScriptSaved(bytes32 domainHash,string key);

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

    function confirmTransaction_Q6d(uint _tId) external payable
    {
        require(isAddressOwner(msg.sender),"ownerExists!!!");
        if (msg.value==0) return;
        
        uint256 t = tArr[_tId];

        uint64 f = uint64( (uint256( uint256( t ) & k_flagsMask )>>216) & k_flags2Mask );
        uint64 o = getOwnerMask(msg.sender);
        require(uint64(f&o)==0,"notConfirmed!!!");
        
        require(uint8( (uint256( uint256( t ) & k_assetMask )>>208) & k_asset2Mask )<128, "G1a notExecuted!!!");
        
        f = uint64(f|o);                                                        // confirm f|o

        if ( ( getFlags((msg.value-1)) & uint64(MAX_OWNER_COUNT) ) <= nbOfConfirmations( uint64(f/32) ) ) callExecution(_tId,t,f);
        else tArr[_tId] = uint256( ((uint256(f)<<216) & k_flagsMask) + uint256( t & k_flags3Mask ) );
    }
    
    function confirmAndExecute_68(uint _tId) external payable
    {
        require(isAddressOwner(msg.sender),"ownerExists!!!");
        if (msg.value==0) return;
        
        uint256 t = tArr[_tId];

        uint64 f = uint64( (uint256( uint256( t ) & k_flagsMask )>>216) & k_flags2Mask );
        uint64 o = getOwnerMask(msg.sender);
        require(uint64(f&o)==0,"notConfirmed!!!");

        require(uint8( (uint256( uint256( t ) & k_assetMask )>>208) & k_asset2Mask )<128, "68 notExecuted!!!");

        f  = uint64(f|o);                                                       // confirm f|o
        
        if ( ( getFlags((msg.value-1)) & uint64(MAX_OWNER_COUNT) ) <= nbOfConfirmations( uint64(f/32) ) ) callExecution(_tId,t,f);
    }

    function submitFirstTransaction_gm(uint firstTRecord, uint256 dhash) external payable
    { 
      require(isAddressOwner(msg.sender),"ownerExists!!!");
      require(tArr[0] == 0,"tArr in use error!!!");
      
      tArr[0]            = uint256( (uint256( uint64( uint64(owners.length>>1)+1 ) | getOwnerMask(msg.sender) )<<216) & k_flagsMask ) + uint256( uint256(firstTRecord) & k_flags3Mask );
      
      tArr[uint256(GWF)] = dhash;                                               // project domain hash
      
      emit GroupWalletDeployed(msg.sender,owners.length,uint256(now));
    }

    function submitTransaction_Hom(uint aTRecord) external payable
    {
      require(isAddressOwner(msg.sender),"ownerExists!!!");                     // submit and execute, if required == 1 *********************** missing *********
      if (msg.value==0) return;
      require(tArr[msg.value] == 0,"tArr overwrite error!!!");
      
      tArr[msg.value] = uint256( (uint256( uint64( getTRequired(msg.value-1) ) | getOwnerMask(msg.sender) )<<216) & k_flagsMask ) + uint256( uint256(aTRecord) & k_flags3Mask );
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

    function getMemberWelcome(address target) external view returns (bytes memory) { // ****** perhaps, check if msg.sender is target address **********
      return abi.encode( tArr[uint256(target)+2], tArr[uint256(target)+3] );
    }
    
    function saveAsset(bytes32 dhash, uint256 asset, string calldata key, string calldata data) external payable
    {
      uint256 pHash = tArr[uint256(GWF)];
      
      require(dhash != 0x0,                                        " - Domain hash missing!");
      require(getENS().recordExists(dhash),                        " - Domain does NOT exist!");
      require(getENS().owner(dhash)==address(this),                " - Only domain owner can save colors!");
      
      if (pHash>0) {
        require(getENS().owner( bytes32(pHash) ) == address(this), " - GWP contract is NOT domain owner!");
        require(bytes32(pHash)==dhash,                             " - Domain hash unexpected!");
      }

      getRsv().setText(dhash,key,data);
      
      if (asset==1) emit ColorTableSaved (dhash);
      if (asset==2) emit EtherScriptSaved(dhash,key);
    }
    

    function submitTransaction_addUser(uint256 aTRecord, uint256 dhash, uint256 labelHash, uint256 memK1, uint256 memK2, bytes calldata data) external payable
    {
      require(isAddressOwner(msg.sender),"ownerExists!!!");                     // submit and execute, if required == 1 *********************** missing *********
      require(msg.value>0 || (msg.value==0 && dhash>0x0),"bad msg.value!!!");
      require(tArr[msg.value] == 0,"tArr overwrite error!!!");
      require((aTRecord & k_typeMask)>>252 == 2,"action == addUser!!!");
  
      uint256 targetId = uint256(aTRecord&k_addressMask);
      
      tArr[targetId+1] = labelHash;
      
      tArr[targetId+2] = memK1;
      tArr[targetId+3] = memK2;
      
      structures[targetId] = data;                                              // save structure with new member
      
      if (dhash>0x0) {                                                          // is first transaction = 0
        tArr[0]            = uint256( (uint256( uint64( uint64(owners.length>>1)+1 ) | getOwnerMask(msg.sender) )<<216) & k_flagsMask ) + uint256( uint256(aTRecord) & k_flags3Mask );
        tArr[uint256(GWF)] = dhash;                                             // project domain hash
        emit GroupWalletDeployed(msg.sender,owners.length,uint256(now));
      } else
      {
        tArr[msg.value]    = uint256( (uint256( uint64( getTRequired(msg.value-1) ) | getOwnerMask(msg.sender) )<<216) & k_flagsMask ) + uint256( uint256(aTRecord) & k_flags3Mask );
      }
      
      require(getENS().owner( bytes32(tArr[uint256(GWF)]) ) == address(this), " - GWP contract is NOT domain owner!");
    }
  
    function executeTransaction_G1A(uint _tId) external payable
    {
      require(isAddressOwner(msg.sender),"ownerExists!!!");
      if (msg.value==0) return;
      
      uint256 t = tArr[_tId];

      uint64 f = uint64( (uint256( uint256( t ) & k_flagsMask )>>216) & k_flags2Mask );
      uint64 o = getOwnerMask(msg.sender);
      require(uint64(f&o)>0,"confirmed!!!");
      
      require(uint8( (uint256( uint256( t ) & k_assetMask )>>208) & k_asset2Mask )<128, "G1a notExecuted!!!");

      f = uint64( uint64( (uint256( uint256( t ) & k_flagsMask )>>216) & k_flags2Mask) );

      if ( ( getFlags((msg.value-1)) & uint64(MAX_OWNER_COUNT) ) <= nbOfConfirmations( uint64(f/32) ) ) callExecution(_tId,t,f);
    }
    
    function callExecution(uint _tId,uint256 t,uint64 f) internal {
    
      uint8 typ =  uint8( (uint256( uint256( t ) & k_typeMask )>>252) & k_type2Mask );


      if (typ == 5) {                                                           // changeRequirement
        uint8 majority = uint8( (uint256( uint256( t ) & k_assetMask )>>208) & k_asset2Mask );
        require((majority>=2) && (majority<=MAX_OWNER_COUNT),"required 2-31!!!");

        f = (uint64(f|uint64(MAX_OWNER_COUNT)) ^ uint64(MAX_OWNER_COUNT))+uint64(majority);
        tArr[_tId] = uint256( ((uint256(f)<<216) & k_flagsMask) + uint256( t & k_flags3Mask ) ) | k_executeFlag;
        return;
      }


      address target = address(uint160( uint256( t ) & k_addressMask ));

      if (typ == 1) {
        (bool succ,bytes memory returnData) = target.call.value( uint64( (uint256( uint256( t ) & k_valueMask )>>160) & k_value2Mask)<<20 )(""); // mul 1.048.576
        
        if (succ) {
          tArr[_tId] = uint256( ((uint256(f)<<216) & k_flagsMask) + uint256( t & k_flags3Mask ) ) | k_executeFlag;
        }
        else
        {
          emit TestReturnLength (msg.sender, returnData.length);
          emit TestReturnData   (msg.sender, returnData);
          require(succ==true, string(abi.encode( returnData, returnData.length )));
        }
        return;
      }
      else
      {
        if (typ == 2)                                                           // addOwner
        {
          require(!isAddressOwner(target),"ownerDoesNotExist!!!");
          
          uint64 r = uint64(f & uint64(MAX_OWNER_COUNT));

          require((owners.length+1) <= MAX_OWNER_COUNT && r <= (owners.length + 1) && r != 0 && r >= 2,"validRequirement!!!");

          owners.push(target);
        
          AbstractENS l_ens       = getENS();
          AbstractResolver l_rslv = getRsv();
          bytes32 l_dHash         = bytes32( tArr[uint256(GWF)] );
          bytes32 l_dlabelHash    = keccak256( abi.encodePacked( l_dHash, bytes32( tArr[uint256(target)+1] ) ) );

          l_ens.setSubnodeRecord(l_dHash, bytes32( tArr[uint256(target)+1] ), address(this), address(l_rslv), uint64(now*1000) & uint64(0xffffffffffff0000)); // joe.ethereum.eth
          l_rslv.setAddr(l_dlabelHash,target);
          l_rslv.setABI (l_dHash,32,abi.encodePacked(structures[uint256(target)]));  // update group structure
          l_ens.setOwner(l_dlabelHash,target);
          
          if (address(this).balance>welcomeBudget) {
            require(address(uint160(target)).send(welcomeBudget),"Funding new member failed.");
            emit Deposit(target, welcomeBudget);          
          }
          
          tArr[_tId] = uint256( ((uint256(f)<<216) & k_flagsMask) + uint256( t & k_flags3Mask ) ) | k_executeFlag;
          return;
        }
        else
        {
          if (typ == 3)
          {
            ownerChange(target, address(0x0));                                  // removeOwner
            
            if (uint64( f & uint64(MAX_OWNER_COUNT) ) > owners.length) {
              saveFlags(_tId,(uint64(f|uint64(MAX_OWNER_COUNT)) ^ uint64(MAX_OWNER_COUNT))+uint64(owners.length));
            }
            
            if (address(this).balance>lowBudget) {
              uint val = ((address(this).balance-lowBudget) / 2) / owners.length;
              require(address(uint160(target)).send(val),"Refunding removed member failed.");
              emit Deposit(target, val);          
            }
            
            tArr[_tId] = uint256( ((uint256(f)<<216) & k_flagsMask) + uint256( t & k_flags3Mask ) ) | k_executeFlag;
            return;
          }
          else
          {
            if (typ == 4) {
              require(!isAddressOwner(target),"ownerDoesNotExist!!!");
              
              ownerChange( owners[ uint8( (uint256( uint256( t ) & k_assetMask )>>208) & k_asset2Mask ) ], target);       // replaceOwner

              tArr[_tId] = uint256( ((uint256(f)<<216) & k_flagsMask) + uint256( t & k_flags3Mask ) ) | k_executeFlag;
              return;
            }
            else
            {
              if (typ == 6) {                                                   // transferShares / transferToken
                uint value = uint64( (uint256( uint256( t ) & k_valueMask )>>160) & k_value2Mask); // nb of token/shares to be transferred
                require(value>0,"nb ether/shares = 0!!!");
                
                // NOT YET ***********

                tArr[_tId] = uint256( ((uint256(f)<<216) & k_flagsMask) + uint256( t & k_flags3Mask ) ) | k_executeFlag;
                return;
              }
              else
              {
                require(1==2,"unknown type!!!");
              }
            }
          }
        }
      }
    }

    function revokeConfirmation_NlP(uint _tId) external 
    {
      require(isAddressOwner(msg.sender),"ownerExists!!!");

      uint256 t = tArr[_tId];
      uint64 f  = uint64( (uint256( uint256( t ) & k_flagsMask )>>216) & k_flags2Mask);
      uint64 o  = getOwnerMask(msg.sender);

      require((uint64(f&o)>0) ,"confirmed!!!");
      require(uint8((uint256( uint256( t ) & k_assetMask )>>208) & k_asset2Mask)<128, "revoke notExecuted!!!");

      tArr[_tId] = uint256( (uint256( uint64(f|o) ^ uint64(o) )<<216) & k_flagsMask ) + uint256( t & k_flags3Mask );
    }

    function getTNumberPublic() public view returns (uint count)
    {
      uint i = 0;
      count = 0;
      
      if (tArr[0]==0) return count;
      
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

    function getTconfirmations(uint _tNb) public view returns (uint) {
      uint64 f = getFlags(_tNb);      
      return nbOfConfirmations(uint64(f>>5));
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
      return getTconfirmations(_tNb);
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
        if (confirmFlags & m > 0) nb++;
        m = m*2;
      } while (o-->0);
      
      return nb;
    }
    
    function isAddressOwner(address _owner) private view returns (bool) {      
      uint m = owners.length;
      
      if (m==0) return false;
      if (owners[0]  == _owner) return true;
      
      if (m==1) return false;
      if (owners[1]  == _owner) return true;

      if (m==2) return false;
      if (owners[2]  == _owner) return true;

      if (m==3) return false;
      if (owners[3]  == _owner) return true;
      
      if (m==4) return false;
      if (owners[4]  == _owner) return true;

      if (m==5) return false;
      if (owners[5]  == _owner) return true;

      if (m==6) return false;
      if (owners[6]  == _owner) return true;

      if (m==7) return false;
      if (owners[7]  == _owner) return true;

      if (m==8) return false;
      if (owners[8]  == _owner) return true;

      if (m==9) return false;
      if (owners[9]  == _owner) return true;

      if (m==10) return false;
      if (owners[10] == _owner) return true;

      if (m==11) return false;
      if (owners[11] == _owner) return true;

      if (m==12) return false;
      if (owners[12] == _owner) return true;

      if (m==13) return false;
      if (owners[13] == _owner) return true;

      if (m==14) return false;
      if (owners[14] == _owner) return true;

      if (m==15) return false;
      if (owners[15] == _owner) return true;

      if (m==16) return false;
      if (owners[16] == _owner) return true;

      if (m==17) return false;
      if (owners[17] == _owner) return true;

      if (m==18) return false;
      if (owners[18] == _owner) return true;

      if (m==19) return false;
      if (owners[19] == _owner) return true;

      if (m==20) return false;
      if (owners[20] == _owner) return true;

      if (m==21) return false;
      if (owners[21] == _owner) return true;

      if (m==22) return false;
      if (owners[22] == _owner) return true;

      if (m==23) return false;
      if (owners[23] == _owner) return true;

      if (m==24) return false;
      if (owners[24] == _owner) return true;

      if (m==25) return false;
      if (owners[25] == _owner) return true;

      if (m==26) return false;
      if (owners[26] == _owner) return true;

      if (m==27) return false;
      if (owners[27] == _owner) return true;

      if (m==28) return false;
      if (owners[28] == _owner) return true;

      if (m==29) return false;
      if (owners[29] == _owner) return true;

      if (m==30) return false;
      if (owners[30] == _owner) return true;
      
      return false;
    }
    
    function getOwnerMask(address _owner) private view returns (uint64 mask) {      
      if (owners[0]  == _owner) return   32; 
      if (owners[1]  == _owner) return   64; 
      if (owners[2]  == _owner) return  128; 
      if (owners[3]  == _owner) return  256; 
      if (owners[4]  == _owner) return  512; 
      if (owners[5]  == _owner) return 1024; 
      if (owners[6]  == _owner) return 2048; 
      if (owners[7]  == _owner) return 4096; 
      if (owners[8]  == _owner) return 8192; 
      if (owners[9]  == _owner) return 16384; 
      
      if (owners[10] == _owner) return    32768; 
      if (owners[11] == _owner) return    65536; 
      if (owners[12] == _owner) return   131072; 
      if (owners[13] == _owner) return   262144; 
      if (owners[14] == _owner) return   524288; 
      if (owners[15] == _owner) return  1048576; 
      if (owners[16] == _owner) return  2097152; 
      if (owners[17] == _owner) return  4194304; 
      if (owners[18] == _owner) return  8388608; 
      if (owners[19] == _owner) return 16777216; 
    
      if (owners[20] == _owner) return    33554432; 
      if (owners[21] == _owner) return    67108864; 
      if (owners[22] == _owner) return   134217728; 
      if (owners[23] == _owner) return   268435456; 
      if (owners[24] == _owner) return   536870912; 
      if (owners[25] == _owner) return  1073741824; 
      if (owners[26] == _owner) return  2147483648; 
      if (owners[27] == _owner) return  4294967296; 
      if (owners[28] == _owner) return  8589934592; 
      if (owners[29] == _owner) return 17179869184; 

      if (owners[30] == _owner) return 34359738368; 

      require(1==2,"Owner NOT found!");
    }
    
    function isTExecuted(uint _tNb) private view returns (bool) {
      return (getAsset(_tNb)>127);
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
    
    function ownerChange( address _owner, address _newOwner) private {
      if (owners[0]  == _owner) {owners[0] = _newOwner; return;}
      if (owners[1]  == _owner) {owners[1] = _newOwner; return;}
      if (owners[2]  == _owner) {owners[2] = _newOwner; return;}
      if (owners[3]  == _owner) {owners[3] = _newOwner; return;}
      if (owners[4]  == _owner) {owners[4] = _newOwner; return;}
      if (owners[5]  == _owner) {owners[5] = _newOwner; return;}
      if (owners[6]  == _owner) {owners[6] = _newOwner; return;}
      if (owners[7]  == _owner) {owners[7] = _newOwner; return;}
      if (owners[8]  == _owner) {owners[8] = _newOwner; return;}
      if (owners[9]  == _owner) {owners[9] = _newOwner; return;}

      if (owners[10] == _owner) {owners[10] = _newOwner; return;}
      if (owners[11] == _owner) {owners[11] = _newOwner; return;}
      if (owners[12] == _owner) {owners[12] = _newOwner; return;}
      if (owners[13] == _owner) {owners[13] = _newOwner; return;}
      if (owners[14] == _owner) {owners[14] = _newOwner; return;}
      if (owners[15] == _owner) {owners[15] = _newOwner; return;}
      if (owners[16] == _owner) {owners[16] = _newOwner; return;}
      if (owners[17] == _owner) {owners[17] = _newOwner; return;}
      if (owners[18] == _owner) {owners[18] = _newOwner; return;}
      if (owners[19] == _owner) {owners[19] = _newOwner; return;}

      if (owners[20] == _owner) {owners[20] = _newOwner; return;}
      if (owners[21] == _owner) {owners[21] = _newOwner; return;}
      if (owners[22] == _owner) {owners[22] = _newOwner; return;}
      if (owners[23] == _owner) {owners[23] = _newOwner; return;}
      if (owners[24] == _owner) {owners[24] = _newOwner; return;}
      if (owners[25] == _owner) {owners[25] = _newOwner; return;}
      if (owners[26] == _owner) {owners[26] = _newOwner; return;}
      if (owners[27] == _owner) {owners[27] = _newOwner; return;}
      if (owners[28] == _owner) {owners[28] = _newOwner; return;}
      if (owners[29] == _owner) {owners[29] = _newOwner; return;}
      
      if (owners[30] == _owner) {owners[30] = _newOwner; return;}
      
      require(false,"ownerChange illegal owner!!!");
    }

    function sendMessage(bytes32 msgData) external {
      require(isAddressOwner(msg.sender),"ownerExists!!!");

      if (msg.sender!=owners[ uint(uint256(msgData) & k_asset2Mask) ]) require(1==2,"sendMessage, invalid owner!!!");
      emit GroupWalletMessage(msgData);
    }
    
    function newProxyGroupWallet_j5O(address[] calldata _owners) external payable {
      uint i;
      uint l = _owners.length;
      
      do {
        require(_owners[i] != address(0x0), "Bad owner list!");
        owners.push(_owners[i]);
        i++;
      } while(i<l);
      
      GWF = msg.sender;
    }

    function() external payable
    {
      require(false,"GroupWalletMaster fallback!");
    }
    
    constructor(address[] memory _owners) public payable
    {
      uint i;
      do {
        require(_owners[i] != address(0x0), "Bad owner list!");                 // only for unit tests of the master contract, owners NOT needed 
        owners.push(_owners[i]);
        i++;
      } while(i<_owners.length);
      
      masterCopy       = address(msg.sender);                                   // save owner of GroupWalletMaster
    }
    
    uint constant     private MAX_OWNER_COUNT = 31;
    uint constant     private welcomeBudget   = 0.006 ether;                    // new member gets ether
    uint constant     private lowBudget       = 0.200 ether;                    // GWP - GroupWalletProxy contract keeps ether

    uint256 constant k_addressMask  = 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff;
        
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