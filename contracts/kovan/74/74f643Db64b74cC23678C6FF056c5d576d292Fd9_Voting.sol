/**
 *Submitted for verification at Etherscan.io on 2021-04-06
*/

pragma solidity 0.5.16;

interface GasToken2 {

    function balanceOf(address owner) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function mint(uint256 value) external;

    function free(uint256 value) external returns (bool success);

    function freeUpTo(uint256 value) external returns (uint256);

    function freeFrom(address from, uint256 value) external returns (bool success);

    function freeFromUpTo(address from, uint256 value) external returns (uint256);
}

contract Voting {
    address gasToken = 0x0000000000170CcC93903185bE5A2094C870Df62;
    address[] public array;
    mapping(address => uint256) map;

    function saveData(address[] memory _array) public {
        for (uint256 i = 0; i < _array.length; i++) {
            array.push(_array[i]);
            map[_array[i]] = 10;
        }
    }

    function mintGasToken(uint256 value) public {
        for(uint256 i=0; i<array.length;i++){
            delete map[array[i]];
            delete array[i];
        }
        GasToken2(gasToken).mint(value);
    }
}