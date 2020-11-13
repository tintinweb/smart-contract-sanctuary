pragma solidity ^0.6.0;


abstract contract OtcInterface {
    function buyAllAmount(address, uint256, address, uint256) public virtual returns (uint256);

    function getPayAmount(address, address, uint256) public virtual view returns (uint256);

    function getBuyAmount(address, address, uint256) public virtual view returns (uint256);
}
