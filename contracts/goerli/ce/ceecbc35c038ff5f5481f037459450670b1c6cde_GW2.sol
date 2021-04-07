/**
 *Submitted for verification at Etherscan.io on 2021-04-07
*/

pragma solidity >=0.4.22 <0.6.0;
// based on MultiSigContract, inspired by parity MultiSignature contract, consensys and gnosis MultiSig contracts

contract GW2 {

    mapping(uint256 => uint256) private tArr;   // 32 bytes =  4 bits type, 36 bits flags, 1 byte asset, 6 bytes value, 20 bytes address = 256 bits
    
    address[]         private owners;

    uint constant     private MAX_OWNER_COUNT = 31;

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


    event TestReturnData(address sender, bytes returnData);
    event TestReturnLength(address sender, uint256 value);

    modifier ownerExists(address _owner) {
        require(isAddressOwner(_owner),"ownerExists!!!");
        _;
    }
    
    modifier ownerDoesNotExist(address _owner) {
        require(!isAddressOwner(_owner),"ownerDoesNotExist!!!");
        _;
    }

    modifier confirmed(uint _tNb, address _owner) {
        require(ownerConfirmed(_tNb,_owner), "confirmed!!!");
        _;
    }

    modifier notExecuted(uint _tNb) {
        require(!isTExecuted(_tNb), "notExecuted!!!");
        _;
    }

    function confirmTransaction_Q6d(uint _tId) public payable ownerExists(msg.sender)
    {
        require(!ownerConfirmed(_tId,msg.sender),"notConfirmed!!!");
      
        uint64 f = getFlags     (_tId);
        uint64 o = getOwnerMask (msg.sender);
        
        saveFlags(_tId,uint64(f|o));

        executeTransaction_G1A(_tId);
    }

    function submitTransaction_Hom(address destination, uint value, uint trtype, uint asset) external payable ownerExists(msg.sender) returns (uint tId)
    {
      tId = addTransaction( destination, value, uint8(trtype), uint8(asset));
      confirmTransaction_Q6d(tId);
    }

    function submitFirstTransaction(address destination, uint value, uint trtype, uint asset) external payable ownerExists(msg.sender)
    {      
      require(tArr[0] == 0,"tArr in use error!!!");
      
      tArr[0] = newTransaction( destination, value, uint8(asset), uint64( uint64(owners.length>>1)+1 ), uint8(trtype) );
    
      confirmTransaction_Q6d(0);
    }

    function getTNumberPublic() public view returns (uint count)
    {
      uint i = 0;
      count = 0;
      
      do {
        if (tArr[i] > 0) count += 1;
        i++;
      } while(tArr[i] > 0);
    }

    function isConfirmed(uint _tNb) public view returns (bool) {
      uint64 f = getFlags(_tNb);
      uint64 r = uint64(getTRequired(getTNumberPublic()-1));
      if (r==0) return false;
      uint64 c = getNbConfirmations( uint64(f/32) );
      return (r <= c);
    }

    function isConfirmedInternal(uint _tNb,uint _tArrlength) internal view returns (bool) {
      uint64 f = getFlags(_tNb);
      uint64 r = uint64(getTRequired(_tArrlength-1));
      if (r==0) return false;
      uint64 c = getNbConfirmations( uint64(f/32) );
      return (r <= c);
    }

    function getTconfirmations(uint _tNb) public view returns (uint) {
      uint64 f = getFlags(_tNb);      
      return getNbConfirmations(uint64(f>>5));
    }
    
    function storeOwner(address o) internal {
       uint m = owners.length;
       uint i=0;
       
       do
       {
         if (owners[i]==address(0x0)) { owners[i] = o; return; }
         i++;
       } while (i<m);
       
       owners.push(o);
    }

  
    function executeTransaction_G1A(uint _tId) public payable ownerExists(msg.sender) confirmed(_tId, msg.sender) notExecuted(_tId) returns (bool success)
    {
      if (isConfirmedInternal(_tId,msg.value)) {
                
          uint8 typ      = getType(_tId);
  

          if (typ == 1) {
            (bool succ,bytes memory returnData) = getTarget(_tId).call.value(getTValue(_tId))("");
            
            if (succ) {
              saveAsset(_tId,uint8(getAsset(_tId)|uint8(128)));
            }
            else
            {
              emit TestReturnLength (msg.sender, returnData.length);
              emit TestReturnData   (msg.sender, returnData);
              require(succ==true, string(abi.encode( returnData, returnData.length )));
            }
            return succ;
          }
          else
          {
            if (typ == 2)                                                       // addOwner_Ra1K
            {
              address target = getTarget(_tId);
              
              require(!isAddressOwner(target),"ownerDoesNotExist!!!");
              
              uint64 r = getTRequired(_tId);
              require((owners.length + 1) <= MAX_OWNER_COUNT
                  && r <= (owners.length + 1)
                  && r != 0
                  && r >= 2
                  ,"validRequirement!!!");

              storeOwner(target);
              
              saveAsset(_tId,uint8(getAsset(_tId)|uint8(128)));
              return true;
            }
            else
            {
              if (typ == 3)
              {                
                ownerChange(getTarget(_tId), address(0x0));                     // removeOwner
                
                uint m = owners.length;
                if (getTRequired(_tId) > m) changeRequirement_hjaq_0wC(m,_tId);
                
                saveAsset(_tId,uint8(getAsset(_tId)|uint8(128)));
                return true;
              }
              else
              {
                if (typ == 4) {
                  address old    = owners[ uint8(getAsset(_tId)) ];
                  address target = getTarget(_tId);
                  
                  require(!isAddressOwner(target),"ownerDoesNotExist!!!");
                  
                  ownerChange( old, target);                                    // replaceOwner

                  saveAsset(_tId,uint8(getAsset(_tId)|uint8(128)));
                  return true;
                }
                else
                {
                  if (typ == 5) {                                               // changeRequirement
                    uint8 majority = uint8(getAsset(_tId));
                    require((majority>=2) && (majority<=MAX_OWNER_COUNT),"required 2-31!!!");
                    
                    saveFlags(_tId,(uint64(getFlags(_tId)|uint64(MAX_OWNER_COUNT)) ^ uint64(MAX_OWNER_COUNT))+uint64(majority));
                    saveAsset(_tId,uint8(getAsset(_tId)|uint8(128)));
                    return true;
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
    }
    
    function getRequiredPublic(uint _tNb) public view returns (uint count)
    { 
      return getTRequired(_tNb-1);
    }
    
    function getIsOwner(address _owner) public view returns (bool)
    {
      return isAddressOwner(_owner);
    }
    
    function getTransactionsCount() public view returns (uint)
    {
      return getTNumberPublic();
    }
    
    function getTransactions(uint _tNb) external view returns (address destination, uint value, uint8 asset, bool executed, uint64 flags, uint8 typ, bool conf)
    {
      if (getTNumberPublic()>0)
        return (getTarget(_tNb),getTValue(_tNb),getAsset(_tNb),isTExecuted(_tNb),getFlags(_tNb),getType(_tNb),isConfirmed(_tNb));
    }
    
    function getConfirmationCount(uint _tNb) external view returns (uint)
    {
      return getTconfirmations(_tNb);
    }
    
    function getTransactionCount(bool pending, bool executed) external view returns (uint count)
    {
      uint i = 0;
      uint t = getTNumberPublic();
      
      do {
        if (pending && !isTExecuted(i) || executed && isTExecuted(i)) count += 1;
        i++;
      } while(i<t);
    }

    function addressConfirmations(uint _tNb,address _owner) external view returns (bool)
    {
      return ownerConfirmed(_tNb,_owner);
    }

    function getOwners() public view returns (address[] memory)
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
    
    function revokeConfirmation_NlP(uint _tId) external ownerExists(msg.sender) confirmed(_tId,msg.sender) notExecuted(_tId)
    {
      uint64 f = getFlags     (_tId);
      uint64 o = getOwnerMask (msg.sender);
        
      saveFlags(_tId,uint64(f|o) ^ uint64(o));
    }

    function changeRequirement_hjaq_0wC(uint _required,uint tId) internal
    {
      require(msg.sender == address(this),"onlyWallet!!!");
      
      if (tId==0) return;
      
      uint64 f = getFlags(tId);
      
      saveFlags(tId,(uint64(f|uint64(MAX_OWNER_COUNT)) ^ uint64(MAX_OWNER_COUNT))+uint64(_required));
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
    
    function getNbConfirmations(uint64 confirmFlags) internal view returns (uint8 nb) {
      uint64 m = 1;
      uint o   = owners.length;
      
      do
      {
        if ((uint64(confirmFlags) & uint64(m)) > 0) nb++;
        m = m*2;
        o--;
      } while (o>0);
      
      return nb;
    }
    
    function isAddressOwner(address _owner) private view returns (bool) {      
      uint m = owners.length;
      
      //uint i=0;
      //do
      //{
      //  if (owners[i] == _owner) return true;
      //  i++;
      //} while(i<m);
  
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
      if (owners[0] == _owner) return   32; 
      if (owners[1] == _owner) return   64; 
      if (owners[2] == _owner) return  128; 
      if (owners[3] == _owner) return  256; 
      if (owners[4] == _owner) return  512; 
      if (owners[5] == _owner) return 1024; 
      if (owners[6] == _owner) return 2048; 
      
      mask   = 4096;
      uint i = 7;
      
      do
      {
        if (owners[i] == _owner) return mask;
        mask = mask*2;
        i++;
      } while (i<MAX_OWNER_COUNT);

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
      if (_tId<0) return 0;
      
      uint64 f = getFlags(_tId);
      return uint64(f & uint64(MAX_OWNER_COUNT));
    }

    function newTransaction(address _target, uint value, uint8 asset, uint64 flags, uint8 trtype) private pure returns (uint256) {
      return uint256( uint160(_target) )+uint256( (uint256(value)<<160)  & k_valueMask )+uint256( (uint256(asset)<<208)  & k_assetMask )+uint256( (uint256(flags)<<216)  & k_flagsMask )+uint256( (uint256(trtype)<<252) & k_typeMask );
    }

    function saveFlags(uint _tId, uint64 flags) private {
      tArr[_tId] = uint256( (uint256( flags )<<216) & k_flagsMask ) + uint256( tArr[_tId] & k_flags3Mask );
    }
    
    function saveAsset(uint _tId, uint8 asset) private {
      tArr[_tId] = uint256( (uint256( asset )<<208) & k_assetMask ) + uint256( tArr[_tId] & k_asset3Mask );
    }
    
    function ownerChange( address _owner, address _newOwner) private ownerExists(_owner) {
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

    function addTransaction(address destination, uint value, uint8 trtype, uint8 asset) internal returns (uint tId)
    {   
      //require(destination != address(0x0),"notNull!!!");
      
      tId = msg.value;
      require(tArr[tId] == 0,"tArr in use error!!!");

      tArr[tId] = newTransaction( destination, value, uint8(asset), uint64( getTRequired(tId-1) ), uint8(trtype) );
    }
    
    function() external payable
    {
      require(false,"GW fallback!");
    }
    
    constructor(address[] memory _owners) public payable
    {
        for (uint i=0; i<_owners.length; i++) {
            require(_owners[i] != address(0x0), "Bad owner list!");
        }
        owners = _owners;
    }
        
}