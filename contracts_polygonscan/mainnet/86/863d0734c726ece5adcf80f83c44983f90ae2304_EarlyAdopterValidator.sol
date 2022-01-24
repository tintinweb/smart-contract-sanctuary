/**
 *Submitted for verification at polygonscan.com on 2022-01-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable  is Context{


    uint256 public constant delay = 172_800; // delay for admin change
    address private admin;
    address public pendingAdmin; // pending admin variable
    uint256 public changeAdminDelay; // admin change delay variable

    event ChangeAdmin(address sender, address newOwner);
    event RejectPendingAdmin(address sender, address newOwner);
    event AcceptPendingAdmin(address sender, address newOwner);

    function onlyOwner() internal view {
        require(_msgSender() == admin, "Ownable: caller is not the owner");
        
    }

    constructor ()  {
        admin = _msgSender();
    }

    function changeAdmin(address _admin) external  {
    onlyOwner();
        pendingAdmin = _admin;
        changeAdminDelay = block.timestamp + delay;
        emit ChangeAdmin(_msgSender(), pendingAdmin);
    }

    function rejectPendingAdmin() external  {
        onlyOwner();
        if (pendingAdmin != address(0)) {
            pendingAdmin = address(0);
            changeAdminDelay = 0;
        }
        emit RejectPendingAdmin(_msgSender(), pendingAdmin);
    }

    function owner () external  view returns (address){
        return admin;
    }

    function acceptPendingAdmin() external    {
        onlyOwner();
        if (changeAdminDelay > 0 && pendingAdmin != address(0)) {
            require(
               block.timestamp > changeAdminDelay,
                "CoterieMarket: owner apply too early"
            );
            admin = pendingAdmin;
            changeAdminDelay = 0;
            pendingAdmin = address(0);
        }
        emit AcceptPendingAdmin(_msgSender(), admin);
    }
}

contract EarlyAdopterValidator is Ownable{
    
    bytes32 public immutable DOMAIN_SEPARATOR;
        
    bytes32 public constant DOMAIN_TYPEHASH =keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        
    bytes32 public constant EARLYADOPTER_TYPEHASH = keccak256(
            "EarlyAdopter(address user,string attestation)"
            );
    string public name = "Coterie Early Adopter";
    string public version = "1";     
      mapping(address=>  bool) public isEarlyAdopter;      
            
    constructor() {
        
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name)), // name
                keccak256(bytes(version)), // version
                getChainId(),
                address(this)
            )
        );
    }
    
    
    function verify(address user, string calldata attestation,uint8 v, bytes32 r, bytes32 s )view  public returns(bool) {
        bytes32 hashStruct = keccak256(abi.encode(EARLYADOPTER_TYPEHASH,user,keccak256(bytes(attestation))));
           return (verifyEIP712(user, hashStruct, v,r,s)|| verifyPersonalSign(user, hashStruct, v,r,s));
            
    }

    function addEarlyAdopters(address[] calldata users, string calldata attestation, uint8[] calldata v, bytes32[] calldata r, bytes32 [] calldata s) external {
        require(users.length==r.length && users.length ==v.length && users.length ==s.length, "invalid array");
        for(uint256 i=0; i<users.length; i++){
            require(verify(users[i], attestation, v[i], r[i], s[i]), "not early user");
            isEarlyAdopter[users[i]] = true;
        }
    }

   
    
    function splitSignature(bytes memory sig)
       public
       pure
       returns (uint8, bytes32, bytes32)
   {
       require(sig.length == 65);

       bytes32 r;
       bytes32 s;
       uint8 v;

       assembly {
           // first 32 bytes, after the length prefix
           r := mload(add(sig, 32))
           // second 32 bytes
           s := mload(add(sig, 64))
           // final byte (first byte of the next 32 bytes)
           v := byte(0, mload(add(sig, 96)))
       }
     
       return (v, r, s);
   }
    
    
    function verifyEIP712(
        address source,
        bytes32 hashStruct,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view returns (bool) {
        bytes32 hash =
            keccak256(
                abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hashStruct)
            );
        address signer = ecrecover(hash, v, r, s);
        return (signer != address(0) && signer == source);
    }
    
    function verifyPersonalSign(
        address source,
        bytes32 hashStruct,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view returns (bool) {
        bytes32 hash = prefixed(hashStruct);
        address signer = ecrecover(hash, v, r, s);
        return (signer != address(0) && signer == source);
    }

    // Builds a prefixed hash to mimic the behavior of eth_sign.
    function prefixed(bytes32 hash) internal view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    DOMAIN_SEPARATOR,
                    hash
                )
            );
    }
    
    function getChainId () public view returns(uint256){
       return block.chainid;
    }
          
}