/**
 *Submitted for verification at Etherscan.io on 2021-07-21
*/

// SPDX-License-Identifier: UNLICENSED

interface ILinkOracle {
  function latestAnswer() external view returns(uint);
  function decimals() external view returns(int256);
}

contract Ownable {

  address public owner;
  address public pendingOwner;

  event OwnershipTransferInitiated(address indexed previousOwner, address indexed newOwner);
  event OwnershipTransferConfirmed(address indexed previousOwner, address indexed newOwner);

  constructor() {
    owner = msg.sender;
    emit OwnershipTransferConfirmed(address(0), owner);
  }

  modifier onlyOwner() {
    require(isOwner(), "Ownable: caller is not the owner");
    _;
  }

  function isOwner() public view returns (bool) {
    return msg.sender == owner;
  }

  function transferOwnership(address _newOwner) external onlyOwner {
    require(_newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferInitiated(owner, _newOwner);
    pendingOwner = _newOwner;
  }

  function acceptOwnership() external {
    require(msg.sender == pendingOwner, "Ownable: caller is not pending owner");
    emit OwnershipTransferConfirmed(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

contract LinkPriceOracle is Ownable {

  mapping(address => ILinkOracle) public linkOracles;
  mapping(address => uint) private tokenPrices;

  event AddLinkOracle(address indexed token, address oracle);
  event RemoveLinkOracle(address indexed token);
  event PriceUpdate(address indexed token, uint amount);

  function addLinkOracle(address _token, ILinkOracle _linkOracle) external onlyOwner {
    require(_linkOracle.decimals() == 8, "LinkPriceOracle: non-usd pairs not allowed");
    linkOracles[_token] = _linkOracle;

    emit AddLinkOracle(_token, address(_linkOracle));
  }

  function removeLinkOracle(address _token) external onlyOwner {
    linkOracles[_token] = ILinkOracle(address(0));
    emit RemoveLinkOracle(_token);
  }

  function setTokenPrice(address _token, uint _value) external onlyOwner {
    tokenPrices[_token] = _value;
    emit PriceUpdate(_token, _value);
  }

  // _token price in USD with 18 decimals
  function tokenPrice(address _token) external view returns(uint) {

    if (address(linkOracles[_token]) != address(0)) {
      uint latestAnswer = linkOracles[_token].latestAnswer();
      require(latestAnswer > 1, "LinkPriceOracle: invalid oracle value");

      return latestAnswer * 1e10;

    } else if (tokenPrices[_token] != 0) {
      return tokenPrices[_token];

    } else {
      revert("LinkPriceOracle: token not supported");
    }
  }

  function tokenSupported(address _token) external view returns(bool) {
    return (
      address(linkOracles[_token]) != address(0) ||
      tokenPrices[_token] != 0
    );
  }
}