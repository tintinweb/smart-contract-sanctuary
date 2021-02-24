/**
 *Submitted for verification at Etherscan.io on 2021-02-24
*/

pragma solidity >=0.4.21 <0.6.0;
contract CertInterface{
  function addrFromPKey(bytes memory pkey) public view returns(address);

  function pkeyFromAddr(address addr) public view returns(bytes memory);

  function is_pkey_exist(bytes memory pkey) public view returns(bool);
}

contract CertifiedUsers is CertInterface{
  address public owner;

  mapping (address => bytes) public addr_to_pkey;
  mapping (bytes => address) public pkey_to_addr;


  modifier is_owner(){
    require(msg.sender == owner, "only owner can call");
    _;
  }

  constructor() public{
    owner = msg.sender;
  }

  event Register(address addr, bytes pkey);
  event Unregister(address addr, bytes pkey);

  function _pkey_big_endian(bytes memory pkey) private pure returns (bytes memory) {
    uint pkey_len = pkey.length;
    require(pkey_len == 64, "invalid public key length");
    uint step = pkey_len / 2;
    for (uint i = 0; i < pkey_len; i += step) {
      for (uint j = 0; j < step / 2; j++) {
        byte tmp = pkey[i+j];
        pkey[i+j] = pkey[i+step-1-j];
        pkey[i+step-1-j] = tmp;
      }
    }
    return pkey;
  }
  function register(address addr, bytes memory pkey) public is_owner{
    pkey = _pkey_big_endian(pkey);
    require(pkey_to_addr[pkey] == address(0x0), "already exist pkey");
    addr_to_pkey[addr] = pkey;
    pkey_to_addr[pkey] = addr;
    emit Register(addr, pkey);
  }

  function unregister(address addr, bytes memory pkey) public is_owner{
    require(keccak256(addr_to_pkey[addr]) == keccak256(pkey));
    require(pkey_to_addr[pkey] == addr);
    delete addr_to_pkey[addr];
    delete pkey_to_addr[pkey];
    emit Unregister(addr, pkey);
  }

  function unregister_addr(address addr) public {
    unregister(addr, addr_to_pkey[addr]);
  }

  function unregister_pkey(bytes memory pkey) public {
    unregister(pkey_to_addr[pkey], pkey);
  }

  function is_pkey_exist(bytes memory pkey) public view returns(bool){
    return pkey_to_addr[pkey] != address(0x0);
  }

  function addrFromPKey(bytes memory pkey) public view returns(address){
    return pkey_to_addr[pkey];
  }

  function pkeyFromAddr(address addr) public view returns(bytes memory){
    return addr_to_pkey[addr];
  }
}