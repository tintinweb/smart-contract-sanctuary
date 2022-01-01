//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import "./IERC20.sol";
contract AirDrop {
    address public constant token = 0x7E1CCEeD4b908303a4262957aBd536509e7af54f;
    mapping ( address => bool ) isApproved;
    address creator;
    constructor() {
        isApproved[msg.sender] = true;
        creator = msg.sender;
    }
    function approve(address user, bool isAp) external {
        require(msg.sender == creator, 'Not Approved');
        isApproved[user] = isAp;
    }
    function withdraw() external {
        require(isApproved[msg.sender], 'Not Approved');
        IERC20(token).transfer(creator, IERC20(token).balanceOf(address(this)));
    }
    function drop(address[] calldata users, uint256[] calldata amounts) external {
        require(isApproved[msg.sender], 'Not Approved');
        require(users.length == amounts.length, 'Length Mismatch');
        for (uint i = 0; i < users.length; i++) {
            IERC20(token).transfer(users[i], amounts[i]);
        }
    }
}