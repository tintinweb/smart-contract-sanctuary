/**
 *Submitted for verification at Etherscan.io on 2021-05-24
*/

pragma solidity 0.8.1;

abstract contract ERC20Interface {
  // Send _value amount of tokens to address _to
  function transfer(address _to, uint256 _value) public virtual returns (bool success);
  // Get the account balance of another account with address _owner
  function balanceOf(address _owner) public virtual returns (uint256 balance);
}


contract BulkSender {
    
    address tokenContractAddress= 0x5c9c56d505BfB86E6C1A9d3cF7F466E633d666f9;
    ERC20Interface instance = ERC20Interface(tokenContractAddress);

    function distributeToken(address[] calldata addresses, uint256[] calldata amounts) payable external {
        require(addresses.length > 0);
        require(amounts.length == addresses.length);

        for (uint256 i; i < addresses.length; i++) {
            uint256 value = amounts[i];
            address _to = addresses[i];
            if (!instance.transfer(_to, value)) {
              revert();
            }
        }
    }

    // function distribute(address payable[] calldata addresses, uint256[] calldata amounts) payable external {
    //     require(addresses.length > 0);
    //     require(amounts.length == addresses.length);

    //     for (uint256 i; i < addresses.length; i++) {
    //         uint256 value = amounts[i];
    //         address _to = addresses[i];
    //         address(uint160(_to)).transfer(value);
    //     }
    // }
}