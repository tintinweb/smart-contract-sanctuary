/**
 *Submitted for verification at Etherscan.io on 2021-04-21
*/

pragma solidity >=0.4.21 <0.6.0;
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
contract Ownable {
    address private _contract_owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = msg.sender;
        _contract_owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _contract_owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_contract_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_contract_owner, newOwner);
        _contract_owner = newOwner;
    }
}

contract ProgramProxyInterface{
  function is_program_hash_available(bytes32 hash) public view returns(bool);
  function program_price(bytes32 hash) public view returns(uint256);
}

contract YZData is Ownable{
  using SafeMath for uint256;
    bytes32 public data_hash;
    string public data_name;
    string public data_description;
    bytes public data_sample;
    string public env_info; //os, sgx sdk, cpu, compiler
    uint256 public price;
    bytes32 public format_lib_hash;
    bytes public pkey;

    address payable public bank_account;

    uint public total_deposit;

    address public program_proxy;
    address public request_proxy;

    constructor(bytes32 _hash,
               string memory _name,
               string memory _desc,
               bytes memory _sample,
               string memory _env_info,
               uint _price,
               address _program_proxy,
               bytes memory _pkey) public{
      data_hash = _hash;
      data_name = _name;
      data_description = _desc;
      data_sample = _sample;
      env_info = _env_info;
      price = _price;
      pkey = _pkey;

      program_proxy = _program_proxy;
      total_deposit = 0;
    }

    function is_program_hash_available(bytes32 program_hash) public view returns(bool) {
      return ProgramProxyInterface(program_proxy).is_program_hash_available(program_hash);
    }

    function program_price(bytes32 program_hash) public view returns(uint256){
      return ProgramProxyInterface(program_proxy).program_price(program_hash);
    }

    event ChangeRequestProxy(address _old, address _new);
    function change_request_proxy(address _addr) public onlyOwner{
      address old = request_proxy;
      request_proxy = _addr;
      emit ChangeRequestProxy(old, request_proxy);
    }

    event ChangeProgramProxy(address _old, address _new);
    function change_program_proxy(address _addr) public onlyOwner {
      address old = program_proxy;
      program_proxy = _addr;
      emit ChangeProgramProxy(old, program_proxy);
    }
}

contract YZDataRequestFactoryInterface{
  function createYZDataRequest(address data) public returns(address);
}

contract YZVerifierInterface{
  function verify(bytes memory pkey, bytes memory pkey_sig) public returns(bool);
}

contract YZDataFactory is Ownable{
  event NewYZData(address addr);
  YZDataRequestFactoryInterface public request_factory;
  YZVerifierInterface public verifier_proxy;
  address public verify_addr;

  bool public paused;

  constructor(address _request_factory, address _verifier_addr) public{
    request_factory = YZDataRequestFactoryInterface(_request_factory);
    verifier_proxy = YZVerifierInterface(_verifier_addr);
    paused = false;
  }

  function pause(bool _paused) public onlyOwner{
    paused = _paused;
  }

  function createYZData(bytes32 _hash,
               string memory _name,
               string memory _desc,
               bytes memory _sample,
               string memory _env_info,
               uint _price,
               address _program_proxy,
               bytes memory _pkey,
               bytes memory _pkey_sig) public returns(address){
    require(!paused, "already paused to use");

    require(verifier_proxy.verify(_pkey, _pkey_sig), "invalid pkey");
    YZData y = new YZData(_hash, _name, _desc, _sample, _env_info, _price, _program_proxy, _pkey);

    address req = request_factory.createYZDataRequest(address(y));
    y.change_request_proxy(req);
    y.transferOwnership(msg.sender);
    emit NewYZData(address(y));
    return address(y);
  }
}