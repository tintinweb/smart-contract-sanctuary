pragma solidity ^0.4.24;

// File: contracts/ERC20BasicCutted.sol

contract ERC20BasicCutted {
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
}

// File: contracts/IntermediateWallet.sol

pragma solidity ^0.4.24;

contract IntermediateWallet {
    
  address public wallet =0x0B18Ed2b002458e297ed1722bc5599E98AcEF9a5;

  function () payable public {
    wallet.transfer(msg.value);
  }
  
  function tokenFallback(address _from, uint _value) public {
    ERC20BasicCutted(msg.sender).transfer(wallet, _value);
  }

}