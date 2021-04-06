/**
 *Submitted for verification at Etherscan.io on 2021-04-05
*/

pragma solidity >=0.4.22 <0.6.0;
// based on MultiSigContract, inspired by parity MultiSignature contract, consensys and gnosis MultiSig contracts

contract GW {

    uint256[]         public trans32; // 32 bytes =  4 bits type, 36 bits flags, 1 byte asset, 6 bytes value, 20 bytes address = 256 bits
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


    function submitTransaction_Hom(address destination, uint value, uint trtype, uint asset) public ownerExists(msg.sender) returns (uint tId)
    {
      tId = addTransaction( destination, value, uint8(trtype), uint8(asset));
      confirmTransaction_Q6d(tId);
    }
    
    function confirmTransaction_Q6d(uint _tId) public ownerExists(msg.sender)
    {
        require(!ownerConfirmed(_tId,msg.sender),"notConfirmed!!!");
      
        uint64 f = getFlags     (_tId);
        uint64 o = getOwnerMask (msg.sender);
        
        saveFlags(_tId,uint64(f|o));

        executeTransaction_G1A(_tId);
    }
    
    function isConfirmed(uint _tNb) public view returns (bool) {
      uint64 f = getFlags(_tNb);
      uint64 r = uint64(getTRequired(trans32.length-1));
      if (r==0) return false;
      uint64 c = getNbConfirmations( uint64(f/32) );
      return (r <= c);
    }

    function getTconfirmations(uint _tNb) public view returns (uint) {
      uint64 f = getFlags(_tNb);      
      return getNbConfirmations(uint64(f>>5));
    }
    
    function addOwner_Ra1K(address _owner) public ownerDoesNotExist(_owner) validRequirement( owners.length + 1)
    {
        require(msg.sender == address(this),"onlyWallet!!!");
        
        require(_owner != address(0x0),"notNull!!!");
        owners.push(_owner);
    }

    function removeOwner_66A( address _owner) public
    {
      ownerChange(_owner, address(0x0));
      
      uint m = owners.length;
      if (getTRequired(trans32.length-1) > m) changeRequirement_hjaq_0wC(m);
    }
    
    function replaceOwner_NI( address _owner, address _newOwner) public ownerDoesNotExist(_newOwner)
    {
      ownerChange( _owner, _newOwner);
    }
    
    function getRequired() public view returns (uint count)
    { 
      if (trans32.length==0) return 0;
      return getTRequired(trans32.length-1);
    }
    
    function getIsOwner(address _owner) public view returns (bool)
    {
      return isAddressOwner(_owner);
    }
    
    function getTransactionsCount() public view returns (uint)
    {
      return trans32.length;
    }
    
    function getTransactions(uint _tNb) public view returns (address destination, uint value, uint8 asset, bool executed, uint64 flags, uint8 typ, bool conf)
    {
      if (trans32.length>0)
        return (getTarget(_tNb),getTValue(_tNb),getAsset(_tNb),isTExecuted(_tNb),getFlags(_tNb),getType(_tNb),isConfirmed(_tNb));
    }
    
    function getConfirmationCount(uint _tNb) public view returns (uint)
    {
      return getTconfirmations(_tNb);
    }
    
    function getTransactionCount(bool pending, bool executed) public view returns (uint count)
    {
      for (uint i=0; i<trans32.length; i++)
          if (pending && !isTExecuted(i) || executed && isTExecuted(i))
            count += 1;
    }

    function addressConfirmations(uint _tNb,address _owner) public view returns (bool)
    {
      return ownerConfirmed(_tNb,_owner);
    }

    function getOwners() public view returns (address[] memory)
    {
        return owners;
    }

    function getConfirmations(uint _tId) public view returns (address[] memory _confirmations)
    {   
        uint i;
        uint m = owners.length;
        address[] memory confirmationsTemp = new address[](m);
        uint count = 0;
        
        for (i=0; i<m; i++)
            if ( ownerConfirmed(_tId,owners[i]) ) {
                confirmationsTemp[count] = owners[i];
                count += 1;
            }
            
        _confirmations = new address[](count);
        
        for (i=0; i<count; i++)
            _confirmations[i] = confirmationsTemp[i];
    }

    function executeTransaction_G1A(uint _tId) public ownerExists(msg.sender) confirmed(_tId, msg.sender) notExecuted(_tId) returns (bool success)
    {
      if (isConfirmed(_tId)) {
          bytes memory data;
                
          uint8 typ      = getType(_tId);
  

          if (typ == 1) {
            (bool succ,bytes memory returnData) = getTarget(_tId).call.value(getTValue(_tId))("");
            
            if (succ) {
              typ = getAsset(_tId);
              saveAsset(_tId,uint8(typ|uint8(128)));
            }
            else
            {
              emit TestReturnLength (msg.sender, returnData.length);
              emit TestReturnData   (msg.sender, returnData);
            }
            return succ;
          }
          
          
          if (typ == 2) data = prepareCall("addOwner_Ra1K(address)",   bytes32(uint256(uint160(getTarget(_tId)))),0x0,36);   // addOwner
          
          
          if (typ == 3) data = prepareCall("removeOwner_66A(address)",bytes32(uint256(uint160(getTarget(_tId)))),0x0,36);   // removeOwner
          
      
          if (typ == 4) {
            bytes32 oldMem;
            
            {
              address old    = owners[ uint8(getAsset(_tId)) ];
              oldMem         = bytes32(uint256(uint160(old)));
            }
            
            bytes32 newMem   = bytes32(uint256(uint160(getTarget(_tId))));

            data = prepareCall("replaceOwner_NI(address,address)",oldMem,newMem,68);                                           // replaceOwner
          }


          if (typ == 5) {
            uint8 majority = uint8(getAsset(_tId));
            require((majority>=2) && (majority<=MAX_OWNER_COUNT),"required only 2-31!!!");
            data = prepareCall("changeRequirement_hjaq_0wC(uint256)",bytes32(uint256(majority)),0x0,36);                      // changeRequirement
          }


          address target = address(this);
            
          // solium-disable-next-line security/no-inline-assembly
          assembly {
            success := call(1250000, target, 0, add(data, 0x20), mload(data), 0, 0)
          }
          
                                                                                // uint256 t = owners[_tId];
          require(success==true,"fail!!!");                                     // debugging:  b_String( bytes32(t), 32, true)
          
          typ = getAsset(_tId);
          saveAsset(_tId,uint8(typ|uint8(128)));
      }
    }
    
    function revokeConfirmation_NlP(uint _tId) public ownerExists(msg.sender) confirmed(_tId,msg.sender) notExecuted(_tId)
    {
      uint64 f = getFlags     (_tId);
      uint64 o = getOwnerMask (msg.sender);
        
      saveFlags(_tId,uint64(f|o) ^ uint64(o));
    }

    function changeRequirement_hjaq_0wC(uint _required) public
    {
      require(msg.sender == address(this),"onlyWallet!!!");
      
      uint tId = trans32.length-1;
      if (tId==0) return;
      
      uint64 f = getFlags(tId);
      
      saveFlags(tId,(uint64(f|uint64(MAX_OWNER_COUNT)) ^ uint64(MAX_OWNER_COUNT))+uint64(_required));
    }
  
    
    function getTarget(uint tNb) private view returns (address) {
      return address( uint160( uint256( trans32[tNb] ) & k_addressMask ) );
    }

    function getTValue(uint tNb) private view returns (uint64) {
      return uint64( (uint256( uint256( trans32[tNb] ) & k_valueMask )>>160) & k_value2Mask);
    }

    function getAsset(uint tNb) private view returns (uint8) {
      return uint8(  (uint256( uint256( trans32[tNb] ) & k_assetMask )>>208) & k_asset2Mask);
    }

    function getFlags(uint tNb) private view returns (uint64) {
      return uint64( (uint256( uint256( trans32[tNb] ) & k_flagsMask )>>216) & k_flags2Mask);
    }

    function getType(uint tNb) private view returns (uint8) {
      return uint8(  (uint256( uint256( trans32[tNb] ) & k_typeMask )>>252) & k_type2Mask);
    }
    
    function getNbConfirmations(uint64 confirmFlags) private pure returns (uint8 nb) {
      uint64 m = 1;
      
      for (uint i=0; i<MAX_OWNER_COUNT; i++) {
        if ((uint64(confirmFlags) & uint64(m)) > 0) nb++;
        m = m*2;
      }
      return nb;
    }
    
    function isAddressOwner(address _owner) private view returns (bool) {
      uint m = owners.length;
        for (uint i=0; i<m; i++) {
          if (owners[i] == _owner) return true;
        }
        return false;
    }
    
    function getOwnerMask(address _owner) private view returns (uint64 mask) {
      mask = 32;
        
      for (uint i=0; i<MAX_OWNER_COUNT; i++) {
        if ( owners[i] == _owner) return mask;
        mask = mask*2;
      }
      
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
      trans32[_tId] = uint256( (uint256( flags )<<216) & k_flagsMask ) + uint256( trans32[_tId] & k_flags3Mask );
    }
    
    function saveAsset(uint _tId, uint8 asset) private {
      trans32[_tId] = uint256( (uint256( asset )<<208) & k_assetMask ) + uint256( trans32[_tId] & k_asset3Mask );
    }
    
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

    modifier validRequirement(uint ownerCount) {
        uint64 r = getTRequired(trans32.length-1);
        require(ownerCount <= MAX_OWNER_COUNT
            && r <= ownerCount
            && r != 0
            && r >= 2
            && ownerCount != 0,"validRequirement!!!");
        _;
    }


    function ownerChange( address _owner, address _newOwner) private ownerExists(_owner) {
      
      require(msg.sender == address(this),"onlyWallet!!!");
      
      uint m = owners.length;

      for (uint i=0; i<m; i++)
          if (owners[i] == _owner) {
              owners[i] = _newOwner;
              break;
          }
    }

    function addTransaction(address destination, uint value, uint8 trtype, uint8 asset) internal returns (uint tId)
    {   
      require(destination != address(0x0),"notNull!!!");
      uint64 req;
      
      tId = trans32.length;
      
      if (tId==0) req = uint64(owners.length>>1)+1;
      if (tId> 0) req = getTRequired(tId-1);
      
      trans32.push( newTransaction( destination, value, uint8(asset), uint64(req), uint8(trtype) ) );
    }
    
    function prepareCall(bytes memory theCall,bytes32 val1,bytes32 val2,uint length) private pure returns (bytes memory data) {
      if (length==36) data = abi.encodePacked( bytes4(keccak256(theCall)), val1 );
      if (length> 36) data = abi.encodePacked( bytes4(keccak256(theCall)), val1, val2 );
      require(data.length==length,'prepareCall!!!');
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