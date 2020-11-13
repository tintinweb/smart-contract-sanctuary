pragma solidity ^0.4.18;

import "./StandardToken.sol";
import "./Ownable.sol";
import "./Claimable.sol";

contract MintableToken is StandardToken, Ownable, Claimable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;
  uint public maxSupply = 400000000 * (10 ** 18);


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    if (maxSupply < totalSupply_.add(_amount) ) {
        revert();
    }

    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
  }