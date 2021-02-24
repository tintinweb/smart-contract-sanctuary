/**
 *Submitted for verification at Etherscan.io on 2021-02-24
*/

pragma solidity >=0.4.21 <0.6.0;
contract CertInterface{
  function addrFromPKey(bytes memory pkey) public view returns(address);

  function pkeyFromAddr(address addr) public view returns(bytes memory);

  function is_pkey_exist(bytes memory pkey) public view returns(bool);
}

library SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a, "add");
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a, "sub");
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b, "mul");
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0, "div");
        c = a / b;
    }
}

contract ProgramProxyInterface{
  function is_program_hash_available(bytes32 hash) public view returns(bool);
  function program_price(bytes32 hash) public view returns(uint256);
}

contract YZData {
  using SafeMath for uint256;
    bytes32 public data_hash;
    string public data_name;
    string public data_description;
    bytes public data_sample;
    string public env_info; //os, sgx sdk, cpu, compiler
    uint256 public price;
    bytes32 public format_lib_hash;

    address payable public bank_account;

    uint public total_deposit;

    address public program_proxy;
    address public request_proxy;

    CertInterface public cert_contract_addr;

    address payable public owner;

    modifier is_owner(){
      require(msg.sender == owner, "only owner can call");
      _;
    }
    function transferOwner(address payable newOwner) public is_owner{
      owner = newOwner;
    }

    constructor(bytes32 _hash,
               string memory _name,
               string memory _desc,
               bytes memory _sample,
               string memory _env_info,
               uint _price,
               address _cert_addr, address _program_proxy) public{
      data_hash = _hash;
      data_name = _name;
      data_description = _desc;
      data_sample = _sample;
      env_info = _env_info;
      price = _price;
      owner = msg.sender;
      cert_contract_addr = CertInterface(_cert_addr);

      program_proxy = _program_proxy;
      total_deposit = 0;
    }

    function is_program_hash_available(bytes32 program_hash) public view returns(bool) {
      return ProgramProxyInterface(program_proxy).is_program_hash_available(program_hash);
    }

    function get_cert_proxy() public view returns(address){
      return address(cert_contract_addr);
    }

    function program_price(bytes32 program_hash) public view returns(uint256){
      return ProgramProxyInterface(program_proxy).program_price(program_hash);
    }

    event ChangeRequestProxy(address _old, address _new);
    function change_request_proxy(address _addr) public is_owner{
      address old = request_proxy;
      request_proxy = _addr;
      emit ChangeRequestProxy(old, request_proxy);
    }

    event ChangeProgramProxy(address _old, address _new);
    function change_program_proxy(address _addr) public is_owner{
      address old = program_proxy;
      program_proxy = _addr;
      emit ChangeProgramProxy(old, program_proxy);
    }
}

contract YZDataRequestFactoryInterface{
  function createYZDataRequest(address data) public returns(address);
}

contract YZDataFactory{
  event NewYZData(address addr);
  address public cert_addr;
  YZDataRequestFactoryInterface public request_factory;

  constructor(address addr, address _request_factory) public{
    cert_addr = addr;
    request_factory = YZDataRequestFactoryInterface(_request_factory);
  }

  function createYZData(bytes32 _hash,
               string memory _name,
               string memory _desc,
               bytes memory _sample,
               string memory _env_info,
               uint _price,
               address _cert_addr, address _program_proxy
               ) public returns(address){
    YZData y = new YZData(_hash, _name, _desc, _sample, _env_info, _price, _cert_addr, _program_proxy);

    address req = request_factory.createYZDataRequest(address(y));
    y.change_request_proxy(req);
    y.transferOwner(msg.sender);
    emit NewYZData(address(y));
    return address(y);
  }
}