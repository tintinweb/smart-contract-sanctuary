pragma solidity ^0.4.21;

interface token {
  function transfer(address receiver, uint amount) external;
}

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract KeplerTokenExtraSale is Ownable {

  using SafeMath for uint256;

    uint256 public TokensPerETH;
    token public tokenReward;
    event FundTransfer(address backer, uint256 amount, bool isContribution);

    function KeplerTokenExtraSale(
        uint256 etherPrice,
        address addressOfTokenUsedAsReward
    ) public {
        TokensPerETH = etherPrice * 130 / 125;
        tokenReward = token(addressOfTokenUsedAsReward);
    }

    function () payable public {
    	require(msg.value != 0);
        uint256 amount = msg.value;
        tokenReward.transfer(msg.sender, amount * TokensPerETH);
        emit FundTransfer(msg.sender, amount, true);
    }

    function changeEtherPrice(uint256 newEtherPrice) onlyOwner public {
        TokensPerETH = newEtherPrice * 130 / 125;
    }

    function withdraw(uint256 value) onlyOwner public {
        uint256 amount = value * 10**16;
        owner.transfer(amount);
        emit FundTransfer(owner, amount, false);
    }

    function withdrawTokens(address otherTokenAddress, uint256 amount) onlyOwner public {
        token otherToken = token(otherTokenAddress);
        otherToken.transfer(owner, amount);
    }

    function destroy() onlyOwner public {
        selfdestruct(owner);
    }
}