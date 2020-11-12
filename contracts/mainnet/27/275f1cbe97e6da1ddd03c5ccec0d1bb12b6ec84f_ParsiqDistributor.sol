// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

contract ParsiqDistributor {
  using SafeMath for uint256;
  uint256 private constant _NOT_ENTERED = 1;
  uint256 private constant _ENTERED = 2;

  uint256 private _status;

  constructor () public {
      _status = _NOT_ENTERED;
  }

  function distributeTokensAndEth(
    address token,
    address[] calldata recipients,
    uint256[] calldata shares,
    uint256 tokensToDistribute
  )
    external
    payable
    nonReentrant
  {
    require(recipients.length == shares.length, "Invalid array length");

    IERC20TransferMany(token).transferFrom(
      msg.sender,
      address(this),
      tokensToDistribute
    );

    uint256[] memory tokens = new uint256[](recipients.length);
    uint256 ethToDistribute = msg.value;

    uint256 totalShares = 0;
    for (uint256 i = 0; i < shares.length; i++) {
      totalShares = totalShares.add(shares[i]);
    }
    require(totalShares > 0, "Zero shares");

    for (uint256 i = 0; i < shares.length; i++) {
      tokens[i] = shares[i].mul(tokensToDistribute).div(totalShares);
      uint256 ethers = shares[i].mul(ethToDistribute).div(totalShares);
      if (ethers > 0) {
        payable(recipients[i]).transfer(ethers);
      }
    }

    IERC20TransferMany(token).transferMany(recipients, tokens);
  }

  modifier nonReentrant() {
      require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
      _status = _ENTERED;
      _;
      _status = _NOT_ENTERED;
  }
}
interface IERC20TransferMany {
  function transferMany(
    address[] calldata recipients,
    uint256[] calldata amounts
  ) external;
  
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);
}


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}