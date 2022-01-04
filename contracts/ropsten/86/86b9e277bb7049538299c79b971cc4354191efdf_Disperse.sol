/**
 *Submitted for verification at Etherscan.io on 2022-01-04
*/

pragma solidity ^0.8.0;


interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Disperse {

    function _disperseTokenInternal(IERC20 token, address[] calldata recipients, uint256[] calldata values) internal {

        uint256 total = 0;
        for (uint256 i = 0; i < recipients.length; i++)
            total += values[i];

        require(token.transferFrom(msg.sender, address(this), total));

        for (uint256 i = 0; i < recipients.length; i++)
            require(token.transfer(recipients[i], values[i]));
    }

    function disperseToken(IERC20 token, address[] calldata recipients, uint256[] calldata values) external {
        _disperseTokenInternal(token, recipients, values);
    }
    
    function dispersePOGToken(address[] calldata recipients, uint256[] calldata values) external {
        IERC20 token = IERC20(0xA4ECEC30Df4863aEE3c7125418f81eAa318730FA);
        _disperseTokenInternal(token, recipients, values);
    }
}