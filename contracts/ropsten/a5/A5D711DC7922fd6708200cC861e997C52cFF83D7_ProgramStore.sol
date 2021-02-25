/**
 *Submitted for verification at Etherscan.io on 2021-02-25
*/

pragma solidity >=0.4.21 <0.6.0;

contract ProgramStore{
    struct program_meta{
      address payable author;
      string program_name;
      string program_desc;
      string program_url;
      uint256 price;
      bytes32 enclave_hash;
      bool exists;
    }

    mapping(bytes32 => program_meta) public program_info;
    bytes32[] public program_hashes;

    event UploadProgram(bytes32 hash, address author);
    function upload_program(string memory _name, string memory _desc, string memory _url, uint256 _price, bytes32 _enclave_hash) public returns(bytes32){
      bytes32 _hash = keccak256(abi.encodePacked(msg.sender, _name, _desc, _url, _price, _enclave_hash));
      require(!program_info[_hash].exists, "already exist");
      program_info[_hash].author = msg.sender;
      program_info[_hash].program_name = _name;
      program_info[_hash].program_desc = _desc;
      program_info[_hash].program_url = _url;
      program_info[_hash].price = _price;
      program_info[_hash].enclave_hash = _enclave_hash;
      program_info[_hash].exists = true;
      program_hashes.push(_hash);
      emit UploadProgram(_hash, msg.sender);
      return _hash;
    }

    function program_price(bytes32 hash) public view returns(uint256){
      return program_info[hash].price;
    }

    function get_program_info(bytes32 hash) public view returns(address author,
                                                                string memory program_name,
                                                                string memory program_desc,
                                                                string memory program_url,
                                                                uint256 price,
                                                                bytes32 enclave_hash){
      require(program_info[hash].exists, "program not exist");
      program_meta storage m = program_info[hash];
      author = m.author;
      program_name = m.program_name;
      program_desc = m.program_desc;
      program_url = m.program_url;
      price = m.price;
      enclave_hash = m.enclave_hash;
    }

    function change_program_desc(bytes32 hash, string memory _new_url) public returns(bool){
      require(program_info[hash].exists, "program not exist");
      require(program_info[hash].author == msg.sender, "only owner can change this");
      program_info[hash].program_url= _new_url;
      return true;
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