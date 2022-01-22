pragma solidity ^0.5.8;

contract Test {

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    function fundTransferFrom(address token, address from, address to, uint value) public returns (bool){
        (bool success, bytes memory data) = address(token).delegatecall(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success, string(abi.encodePacked("fc_10", data)));
        return success;}

}