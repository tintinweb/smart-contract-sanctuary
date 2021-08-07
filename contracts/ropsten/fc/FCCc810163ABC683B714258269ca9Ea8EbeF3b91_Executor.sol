/**
 *Submitted for verification at Etherscan.io on 2021-08-07
*/

pragma solidity ^0.8.0;


// 
interface ITokenContract {
  function mint(address _to, uint256 _amount) external;
  function burn(address _from, uint256 _amount) external;
  function transfer(address recipient, uint256 amount) external returns (bool);
}

contract Executor {
  address private timelockAddress;
  ITokenContract private tokenContract;

  constructor(
      address _timelockAdress,
      address _tokenAddress
  ) public {
      timelockAddress = _timelockAdress;
      tokenContract = ITokenContract(_tokenAddress);
  }

  function lockToken(uint256 _amount) public {
    tokenContract.transfer(timelockAddress, _amount);
  }

  function mintToken(uint256 _amount) public {
    tokenContract.mint(address(this), _amount);
  }

  function burnToken(uint256 _amount) public {
    tokenContract.burn(address(this), _amount);
  }
}