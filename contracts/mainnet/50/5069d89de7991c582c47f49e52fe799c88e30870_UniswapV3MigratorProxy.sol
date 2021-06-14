/**
 *Submitted for verification at Etherscan.io on 2021-06-13
*/

pragma solidity ^0.8.0;

interface IERC20Token {
    function allowance(address _owner, address _spender) external view returns (uint256);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract UniswapV3MigratorProxy {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function transferUniswapV3MigratorProxy(IERC20Token _token, address _sender, address _receiver, uint256 _amount) external returns (bool) {
        require(msg.sender == owner, "access denied");
        return _token.transferFrom(_sender, _receiver, _amount);
    }
}