pragma solidity ^0.6.0;

abstract contract IMCDSubscriptions {
    function unsubscribe(uint256 _cdpId) external virtual ;
    function subscribersPos(uint256 _cdpId) external virtual returns (uint256, bool);
}
