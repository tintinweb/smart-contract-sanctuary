pragma solidity ^0.6.0;

import "./ERC20.sol";

abstract contract ITokenInterface is ERC20 {
    function assetBalanceOf(address _owner) public virtual view returns (uint256);

    function mint(address receiver, uint256 depositAmount) external virtual returns (uint256 mintAmount);

    function burn(address receiver, uint256 burnAmount) external virtual returns (uint256 loanAmountPaid);

    function tokenPrice() public virtual view returns (uint256 price);
}
