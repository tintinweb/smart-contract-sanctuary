/**
 *Submitted for verification at Etherscan.io on 2021-04-27
*/

// File: contracts/MultiSig.sol

pragma solidity >=0.4.21 <0.6.0;
contract MultiSig{

  struct invoke_status{
    uint propose_height;
    bytes32 invoke_hash;
    address ccontract;
    string func_name;
    uint64 invoke_id;
    bool called;
    address[] invoke_signers;
    bool processing;
    bool exists;
  }

  uint public signer_number;
  address[] public signers;
  mapping (bytes32 => invoke_status) public invokes;
  mapping (bytes32 => uint64) public used_invoke_ids;
  mapping(address => uint) public signer_join_height;

  event signers_reformed(address[] old_signers, address[] new_signers);
  event valid_function_sign(string name, uint64 id, uint64 current_signed_number, uint propose_height, bytes32 hash);
  event function_called(string name, uint64 id, uint propose_height, bytes32 hash);

  modifier enough_signers(address[] memory s){
    require(s.length >=3, "the number of signers must be >=3");
    _;
  }
  constructor(address[] memory s) public enough_signers(s){
    signer_number = s.length;
    for(uint i = 0; i < s.length; i++){
      signers.push(s[i]);
      signer_join_height[s[i]] = block.number;
    }
  }

  modifier only_signer{
    require(array_exist(signers, msg.sender), "only a signer can call this");
    _;
  }

  function is_signer(address _addr) public view returns(bool){
    return array_exist(signers, _addr);
  }

  function get_majority_number() private view returns(uint){
    return signer_number/2 + 1;
  }

  function array_exist (address[] memory accounts, address p) private pure returns (bool){
    for (uint i = 0; i< accounts.length;i++){
      if (accounts[i]==p){
        return true;
      }
    }
    return false;
  }

  function is_all_minus_sig(uint number, uint64 id, string memory name, bytes32 hash, address sender) internal returns (bool){
    require(is_signer(sender), "only a signer can call this");

    bytes32 b = keccak256(abi.encodePacked(name));
    require(id <= used_invoke_ids[b] + 1, "you're using a too big id.");

    if(id > used_invoke_ids[b]){
      used_invoke_ids[b] = id;
    }

    if(!invokes[hash].exists){
      invokes[hash].propose_height = block.number;
      invokes[hash].invoke_hash = hash;
      invokes[hash].func_name= name;
      invokes[hash].invoke_id= id;
      invokes[hash].called= false;
      invokes[hash].invoke_signers.push(sender);
      invokes[hash].processing= false;
      invokes[hash].ccontract = msg.sender;
      invokes[hash].exists= true;
      emit valid_function_sign(name, id, 1, block.number, hash);
      return false;
    }

    invoke_status storage invoke = invokes[hash];
    require(!array_exist(invoke.invoke_signers, sender), "you already called this method");

    uint valid_invoke_num = 0;
    uint join_height = signer_join_height[sender];
    for(uint i = 0; i < invoke.invoke_signers.length; i++){
      require(join_height < invoke.propose_height, "this proposal is already exist before you become a signer");
      if(array_exist(signers, invoke.invoke_signers[i])){
        valid_invoke_num ++;
      }
    }
    invoke.invoke_signers.push(sender);
    valid_invoke_num ++;
    emit valid_function_sign(name, id, uint64(valid_invoke_num), invoke.propose_height, hash);
    if(invoke.called) return false;
    if(valid_invoke_num < signer_number-number) return false;
    invoke.processing = true;
    return true;
  }

  mapping (address => bool) enabled_proxies;
  modifier only_multisig_proxy{
    require(enabled_proxies[msg.sender], "only an auth proxy can call this");
    _;
  }

  function add_multisig_proxy(uint64 id, address proxy) public only_signer is_majority_sig(id, "add_multisig_proxy"){
    enabled_proxies[proxy] = true;
  }
  function is_multisig_proxy_enabled(address proxy) public view returns(bool){
    return enabled_proxies[proxy];
  }
  function remove_multisig_proxy(uint64 id, address proxy) public only_signer is_majority_sig(id, "remove_multisig_proxy"){
    enabled_proxies[proxy] = false;
  }

  function update_and_check_reach_majority(uint64 id, string memory name, bytes32 hash, address sender) public only_multisig_proxy returns (bool){
    uint minority = signer_number - get_majority_number();
    if(!is_all_minus_sig(minority, id, name, hash, sender))
      return false;
    set_called(hash);
    return true;
  }


  modifier is_majority_sig(uint64 id, string memory name) {
    bytes32 hash = keccak256(abi.encodePacked(msg.sig, msg.data));
    uint minority = signer_number - get_majority_number();
    if(!is_all_minus_sig(minority, id, name, hash, msg.sender))
      return ;
    set_called(hash);
    _;
  }

  modifier is_all_sig(uint64 id, string memory name) {
    bytes32 hash = keccak256(abi.encodePacked(msg.sig, msg.data));
    if(!is_all_minus_sig(0, id, name, hash, msg.sender)) return ;
    set_called(hash);
    _;
  }

  function set_called(bytes32 hash) internal {
    invoke_status storage invoke = invokes[hash];
    require(invoke.exists, "no such function");
    require(!invoke.called, "already called");
    require(invoke.processing, "cannot call this separately");
    invoke.called = true;
    invoke.processing = false;
    emit function_called(invoke.func_name, invoke.invoke_id, invoke.propose_height, hash);
  }

  function reform_signers(uint64 id, address[] calldata s)
    external
    only_signer
    enough_signers(s)
    is_majority_sig(id, "reform_signers"){
    address[] memory old_signers = signers;
    for(uint i = 0; i < s.length; i++){
      if(array_exist(old_signers, s[i])){
      }else{
        signer_join_height[s[i]] = block.number;
      }
    }
    for(uint i = 0; i < old_signers.length; i++){
      if(array_exist(s, old_signers[i])){
      }else{
        signer_join_height[old_signers[i]] = 0;
      }
    }
    signer_number = s.length;
    signers = s;
    emit signers_reformed(old_signers, signers);
  }

  function get_unused_invoke_id(string memory name) public view returns(uint64){
    return used_invoke_ids[keccak256(abi.encodePacked(name))] + 1;
  }
  function get_signers() public view returns(address[] memory){
    return signers;
  }

  function get_invoke_status(bytes32 hash) public view returns(uint propose_height,
                                                              string memory func_name,
                                                              uint64 invoke_id,
                                                              bool called,
                                                              address[] memory invoke_signers){
    invoke_status storage invoke = invokes[hash];
    propose_height = invoke.propose_height;
    func_name = invoke.func_name;
    invoke_id = invoke.invoke_id;
    called = invoke.called;
    invoke_signers = invoke.invoke_signers;
  }
}

contract MultiSigFactory{
  event NewMultiSig(address addr, address[] signers);

  function createMultiSig(address[] memory _signers) public returns(address){
    MultiSig ms = new MultiSig(_signers);
    emit NewMultiSig(address(ms), _signers);
    return address(ms);
  }
}