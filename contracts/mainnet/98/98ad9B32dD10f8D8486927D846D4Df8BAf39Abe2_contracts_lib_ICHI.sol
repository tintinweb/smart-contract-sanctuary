pragma solidity ^0.5.17;

interface ICHI {
    function mint(uint256 value) external;
    function transfer(address, uint256) external returns(bool);
    function balanceOf(address) external view returns(uint256);
}
