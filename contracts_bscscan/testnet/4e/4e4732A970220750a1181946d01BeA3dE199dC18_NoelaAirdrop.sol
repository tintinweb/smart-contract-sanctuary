// SPDX-License-Identifier: MIT
pragma solidity ^0.4.25;

import "./IERC20.sol";

contract NoelaAirdrop {
    function noelaAirdropEther(address[] recipients, uint256[] values)
        external
        payable
    {
        for (uint256 i = 0; i < recipients.length; i++)
            recipients[i].transfer(values[i]);
        uint256 balance = address(this).balance;
        if (balance > 0) msg.sender.transfer(balance);
    }

    function noelaAirdropToken(
        IERC20 token,
        address[] recipients,
        uint256[] values
    ) external {
        uint256 total = 0;
        for (uint256 i = 0; i < recipients.length; i++) total += values[i];
        require(token.transferFrom(msg.sender, address(this), total));
        for (i = 0; i < recipients.length; i++)
            require(token.transfer(recipients[i], values[i]));
    }

    function noelaAirdropTokenSimple(
        IERC20 token,
        address[] recipients,
        uint256[] values
    ) external {
        for (uint256 i = 0; i < recipients.length; i++)
            require(token.transferFrom(msg.sender, recipients[i], values[i]));
    }
}

pragma solidity ^0.4.25;

/**
 * @title ERC20 interface
 * @dev see https://github.com/binance-chain/ERCs/blob/master/ERC20.md#52-implementation
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    event ProposalUpdated(
        address indexed owner,
        uint256 proposalID,
        bool result,
        uint256 value
    );
}

