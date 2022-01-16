/**
 *Submitted for verification at Etherscan.io on 2022-01-16
*/

// File: contracts/core/market/interface/ProgramProxyInterface.sol

pragma solidity >=0.4.21 <0.6.0;
contract ProgramProxyInterface{
  function is_program_hash_available(bytes32 hash) public view returns(bool);
  function program_price(bytes32 hash) public view returns(uint256);
  function program_owner(bytes32 hash) public view returns(address payable);
  function enclave_hash(bytes32 hash) public view returns(bytes32);
}

// File: contracts/core/market/SGXProgramStore.sol

pragma solidity >=0.4.21 <0.6.0;


contract SGXProgramStore is ProgramProxyInterface{
    struct program_meta{
      address payable author;
      string program_url;
      uint256 price;
      bytes32 enclave_hash;
      bool exists;
    }

    mapping(bytes32 => program_meta) public program_info;
    bytes32[] public program_hashes;

    event UploadProgram(bytes32 hash, address author);
    function upload_program(string memory _url, uint256 _price, bytes32 _enclave_hash) public returns(bytes32){
      bytes32 _hash = keccak256(abi.encodePacked(msg.sender, _url, _price, _enclave_hash));
      require(!program_info[_hash].exists, "already exist");
      program_info[_hash].author = msg.sender;
      program_info[_hash].program_url = _url;
      program_info[_hash].price = _price;
      program_info[_hash].enclave_hash = _enclave_hash;
      program_info[_hash].exists = true;
      program_hashes.push(_hash);
      emit UploadProgram(_hash, msg.sender);
      return _hash;
    }

    event ChangeProgramOwner(address old_owner, address new_owner);
    function change_program_owner(bytes32 _hash, address payable _new_owner) public {
      require(program_info[_hash].exists, "program not exist");
      require(program_info[_hash].author == msg.sender, "only owner can change");
      address old = address(program_info[_hash].author);
      program_info[_hash].author = _new_owner;
      require(_new_owner != address (0x0));
      emit ChangeProgramOwner(old, address(_new_owner));
    }

    function program_price(bytes32 hash) public view returns(uint256){
      return program_info[hash].price;
    }

    function program_owner(bytes32 hash) public view returns(address payable){
      return program_info[hash].author;
    }

    function get_program_info(bytes32 hash) public view returns(address author,
                                                                string memory program_url,
                                                                uint256 price,
                                                                bytes32 enclave_hash){
      require(program_info[hash].exists, "program not exist");
      program_meta storage m = program_info[hash];
      author = m.author;
      program_url = m.program_url;
      price = m.price;
      enclave_hash = m.enclave_hash;
    }
    function enclave_hash(bytes32 hash) public view returns(bytes32){
      return program_info[hash].enclave_hash;
    }

    function change_program_url(bytes32 hash, string memory _new_url) public returns(bool){
      require(program_info[hash].exists, "program not exist");
      require(program_info[hash].author == msg.sender, "only owner can change this");
      program_info[hash].program_url= _new_url;
      return true;
    }

    function change_program_price(bytes32 hash, uint256 _new_price) public returns(bool){
      require(program_info[hash].exists, "program not exist");
      require(program_info[hash].author == msg.sender, "only owner can change this");
      program_info[hash].price = _new_price;
      return true;
    }

    function is_program_hash_available(bytes32 hash) public view returns(bool){
      if(!program_info[hash].exists){return false;}
      return true;
    }
}
contract SGXProgramStoreFactory{
  event NewSGXProgramStore(address addr);
  function createSGXProgramStore() public returns(address){
    SGXProgramStore m = new SGXProgramStore();
    //m.transferOwnership(msg.sender);
    emit NewSGXProgramStore(address(m));
    return address(m);
  }

}