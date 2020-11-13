pragma solidity >=0.6.0 <0.7.0;

import "../external/yearn/yVaultInterface.sol";
import "./ERC20Mintable.sol";
import "../external/pooltogether/FixedPoint.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol";

contract yVaultMock is yVaultInterface, ERC20UpgradeSafe {

  ERC20UpgradeSafe private asset;
  uint256 public vaultFeeMantissa;

  constructor (ERC20Mintable _asset) public {
    asset = _asset;
    vaultFeeMantissa = 0.05 ether;
  }

  function token() external override view returns (address) {
    return address(asset);
  }

  function balance() public override view returns (uint) {
    return asset.balanceOf(address(this));
  }

  function removeLiquidity(uint _amount) external {
    asset.transfer(msg.sender, _amount);
  }

  function setVaultFeeMantissa(uint256 _vaultFeeMantissa) external {
    vaultFeeMantissa = _vaultFeeMantissa;
  }

  function deposit(uint _amount) external override {
    uint _pool = balance();
    uint _before = asset.balanceOf(address(this));
    asset.transferFrom(msg.sender, address(this), _amount);
    uint _after = asset.balanceOf(address(this));
    uint diff = _after.sub(_before); // Additional check for deflationary assets
    uint shares = 0;
    if (totalSupply() == 0) {
      shares = diff;
    } else {
      shares = (diff.mul(totalSupply())).div(_pool);
    }
    _mint(msg.sender, shares);
  }

  function withdraw(uint _shares) external override {
    uint256 sharesFee = FixedPoint.multiplyUintByMantissa(_shares, vaultFeeMantissa);

    uint256 withdrawal = (balance().mul(_shares.sub(sharesFee))).div(totalSupply());
    asset.transfer(msg.sender, withdrawal);

    _mint(address(this), sharesFee);
    _burn(msg.sender, _shares);
  }

  function getPricePerFullShare() external override view returns (uint) {
    return balance().mul(1e18).div(totalSupply());
  }
}
