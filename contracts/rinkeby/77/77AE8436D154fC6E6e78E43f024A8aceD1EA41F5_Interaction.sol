/**
 *Submitted for verification at Etherscan.io on 2021-07-27
*/

pragma solidity >=0.4.24 <0.6.0;


interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Interaction {
    IERC20 private _token= IERC20(0x21F62f22F61913eB77feb9533B8F6e3634B4Fe08);
    function approve(address spender, uint256 value) public returns (bool) {
        _token.approve(spender,value);
        return true;
    }
    function balanceOf(address owner) public view returns (uint256) {
       return _token.balanceOf(owner);
    }

    function transfer(address to, uint256 value) public returns (bool) {
        return _token.transfer(to,value);
    }
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        return _token.increaseAllowance(spender,addedValue);
    }
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        return _token.transferFrom(from, to, value);
    }
}