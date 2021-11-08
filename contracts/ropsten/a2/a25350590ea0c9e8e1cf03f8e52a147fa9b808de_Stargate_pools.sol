/**
 *Submitted for verification at Etherscan.io on 2021-11-08
*/

pragma solidity 0.8.7;

contract Ownable {

  address public owner;

  constructor() public {
     owner = msg.sender;
   }

   modifier onlyOwner {
     require(msg.sender == owner, "You are not the owner, sorry");
     _;
   }
   
    function transferOwnership(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }
}

contract Stargate_pools is Ownable {

  struct Single_Pool {
      string protocol_name;
      string deposited_token;
      string pool_description;
      address deposited_token_address;
      address contract_address;
  }

  struct LP_Pool {
      string protocol_name;
      string deposited_token_A;
      string deposited_token_B;
      string pool_description;
      address deposited_token_A_address;
      address deposited_token_B_address;
      address contract_address;
  }

  Single_Pool [] public single_pools;
  LP_Pool [] public LP_pools;

  function add_single_pool(string memory protocol_name, string memory deposited_token, string memory pool_description, address deposited_token_address, address contract_address) public {
      Single_Pool memory new_single_pool = Single_Pool(protocol_name,deposited_token,pool_description,deposited_token_address,contract_address);
      single_pools.push(new_single_pool);
  }

  function add_LP_pool(string memory protocol_name, string memory deposited_token_A, string memory deposited_token_B, string memory pool_description, address deposited_token_A_address, address deposited_token_B_address, address contract_address) public {
      LP_Pool memory new_LP_pool = LP_Pool(protocol_name,deposited_token_A,deposited_token_B,pool_description,deposited_token_A_address,deposited_token_B_address,contract_address);
      LP_pools.push(new_LP_pool);
  }

  function del_single_pool(uint index) public onlyOwner {
      require(index >= single_pools.length,'Pool not found');
      delete single_pools[index];
  }

  function del_LP_pool(uint index) public onlyOwner {
      require(index >= LP_pools.length,'Pool not found');
      delete LP_pools[index];
  }

  function get_single_pool(uint id) public view returns(string memory protocol_name, string memory deposited_token, string memory pool_description, address deposited_token_address, address contract_address) {
      require(id >= single_pools.length,'Pool not found');
      return(single_pools[id].protocol_name, single_pools[id].deposited_token,single_pools[id].pool_description,single_pools[id].deposited_token_address,single_pools[id].contract_address);
  }

  function get_LP_pool(uint id) public view returns(string memory protocol_name, string memory deposited_token_A, string memory deposited_token_B, string memory pool_description, address deposited_token_A_address, address deposited_token_B_address, address contract_address) {
      require(id >= LP_pools.length,'Pool not found');
      return(LP_pools[id].protocol_name, LP_pools[id].deposited_token_A,LP_pools[id].deposited_token_B,LP_pools[id].pool_description,LP_pools[id].deposited_token_A_address,LP_pools[id].deposited_token_B_address,LP_pools[id].contract_address);
  }

  function num_single_pools() public view returns(uint256 number_pools) {
      return(single_pools.length);
  }

  function num_LP_pools() public view returns(uint256 number_pools) {
      return(LP_pools.length);
  }

  function update_single_pool_description(uint id, string memory new_description) public {
      single_pools[id].pool_description = new_description;
  }

  function update_LP_pool_description(uint id, string memory new_description) public {
      LP_pools[id].pool_description = new_description;
  }

}