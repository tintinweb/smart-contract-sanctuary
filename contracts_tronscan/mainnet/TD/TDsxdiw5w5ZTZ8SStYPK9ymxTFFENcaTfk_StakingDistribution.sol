//SourceUnit: StakingDistribution.sol

pragma solidity ^0.5.10;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
      if (a == 0) {
        return 0;
      }
      c = a * b;
      assert(c / a == b);
      return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
      return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
      c = a + b;
      assert(c >= a);
      return c;
    }
}

contract StakingDistribution {
  using SafeMath for uint256;

  address payable public buyback1 = address(0x41b1747589f171bea6921bf7139c8308b0fed7a5ca);
  address payable public buyback2 = address(0x41b2e4c00df87a5623a9f371cf6013e6b6a74451c2);

  address payable public s = address(0x41a4f7f3b8b2984434d71b50c4127ecec3621c334b);
  address payable public cb = address(0x416e97504c70063c4acc1cd73b1d8fd7135153b921);
  address payable public n = address(0x419541eBF4b0A5018F65434f73d7fCa97A12F838EB);
  address payable public tr = address(0x41e706507dc83da296fa078775af38613413a43d6a);

  constructor() public {
  }

  function() payable external {
  }

  function accounting() public payable {
    uint256 balance = address(this).balance;

    if (balance >= 1000e6) {
      buyback1.transfer(balance.mul(40).div(100));
      buyback2.transfer(balance.mul(40).div(100));

      s.transfer(balance.mul(5).div(100));
      cb.transfer(balance.mul(5).div(100));
      n.transfer(balance.mul(5).div(100));
      tr.transfer(balance.mul(5).div(100));
    }
  }
}