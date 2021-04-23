/**
 *Submitted for verification at Etherscan.io on 2021-04-23
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract AirDrop {
    address private _owner;
    IERC20 private _token;

    constructor(IERC20 token) {
        _owner = msg.sender;
        _token = token;
    }
    modifier onlyAdmin() {
        require(msg.sender == _owner, "!owner");
        _;
    }
    event TokenAirDropped(address account, uint256 amount);

    function airDropAll(address sender, address[] memory recipients, uint256[] memory amounts) public onlyAdmin {
        require(recipients.length == amounts.length, "recipients length != amounts length");
        for (uint8 i = 0; i < recipients.length; i++) {
            IERC20(_token).transferFrom(sender ,recipients[i], amounts[i]);
            emit TokenAirDropped(recipients[i], amounts[i]);
        }
    }

    function kill() public onlyAdmin {
        IERC20(_token).transfer(_owner, IERC20(_token).balanceOf(address(this)));
        selfdestruct(payable(_owner));
    }
}