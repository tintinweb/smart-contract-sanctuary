/**
 *Submitted for verification at Etherscan.io on 2021-06-11
*/

pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address _to, uint256 _amount) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool);
    function allowance(address _owner, address _spender) external view returns (uint256);
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);
    function mint(address _to, uint256 _amount) external returns (bool);
    function burn(uint256 _amount) external returns (bool);
}

contract transferTest {
    function trigger(address _token, address payable _to, uint256 _amount) external returns (bool) {
        IERC20(_token).transfer(_to, _amount);
        return true;
    }
}