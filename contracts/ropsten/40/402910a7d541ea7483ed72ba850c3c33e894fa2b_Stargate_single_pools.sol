/**
 *Submitted for verification at Etherscan.io on 2021-11-06
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
}

contract Stargate_single_pools is Ownable {

  struct Pool {
      string protocol_name;
      string deposited_token;
      string pool_description;
      address deposited_token_address;
      address pool_address;
  }

  Pool [] public pools;

  function addPool(string memory protocol_name, string memory deposited_token, string memory pool_description, address deposited_token_address, address pool_address) public {
      Pool memory new_pool = Pool(protocol_name,deposited_token,pool_description,deposited_token_address,pool_address);
      pools.push(new_pool);
  }

  function getPool(uint id) public view returns(string memory protocol_name, string memory deposited_token, string memory pool_description, address deposited_token_address, address pool_address) {
      return(pools[id].protocol_name, pools[id].deposited_token,pools[id].pool_description,pools[id].deposited_token_address,pools[id].pool_address);
  }
  
  function numPools() public view returns(uint256 number_pools) {
      return(pools.length);
  }
  
}