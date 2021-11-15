// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

 //import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// import "@openzeppelin/contracts/utils/Context.sol";
// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "@openzeppelin/contracts/utils/math/SafeMath.sol";
// import "./gau.sol";
// import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract TokenSwap {
  // Upgradeable,
  // ERC20BurnableUpgradeable,
  // ERC20PermitUpgradeable

  // using SafeERC20 for ERC20;
  // using SafeMath for uint256;
  // Gaugecash private _gau;
  // ERC20 private _stable;
  // uint256 private _amount;
  // uint256 private _gauRate;
  // uint256 private _stableRate;
  address private _owner;

  function hello(address owner) public  {
    _owner = owner;
  }

  // event GauPurchased(
  //   address indexed purchaser,
  //   address indexed _owner,
  //   uint256 value,
  //   uint256 _amount
  // );

  // function setStablecoin(ERC20 stable) public {
  //   _stable = stable;
  // }

  // function getOwner() public view returns (address) {
  //   return _owner;
  // }

  // function getRate() public view returns (uint256) {
  //   uint256 amount = 10;

  //   uint256 gauInt = 177;
  //   uint256 _gauRate = gauInt.div(100);
  //   // calculate GAU amount
  //   uint256 _gauAmount = amount.div(_gauRate);

  //   return _gauAmount;
  // }

  // function _preValidatePurchase(address _owner, uint256 Amount) internal view {
  //   require(_owner != address(0), "beneficiary is the zero address");
  //   require(Amount != 0, " Amount is 0");
  //   this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
  // }

  // function _processPurchase(address _owner, uint256 _gauAmount) internal {
  //   _gau.mint(_owner, _gauAmount);
  // }

  // function buyGauWithStable(uint256 stableAmount) public {
  //   //  address _owner;
  //   uint256 allowance = _stable.allowance(_owner, address(this));
  //   require(stableAmount > 0, "You need to send at least one link");
  //   require(allowance >= stableAmount, "Check the Stable allowance");
  //   uint256 gauInt = 177;
  //   uint256 _gauRate = gauInt.div(100);
  //   // calculate GAU amount
  //   uint256 _gauAmount = stableAmount.div(_gauRate);

  //   _preValidatePurchase(_owner, _gauAmount);

  //   _stable.safeTransferFrom(_owner, address(this), stableAmount);
  //   _processPurchase(_owner, _gauAmount);

  //   emit GauPurchased(_msgSender(), _owner, stableAmount, _gauAmount);
  // }
}

