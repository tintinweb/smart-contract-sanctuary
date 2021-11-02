// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./BMBToken.sol";
import "./IERC721.sol";

contract ClaimBMB {
    address public owner;
    BMBToken public bmbToken;
    IERC721 public nftToken;
    uint256 public mintStart;
    uint256 private ONEDAY = 1 days;

    struct User {
        address userAddress;
        uint256 nftCount;
        uint256 lastTime;
    }

    mapping(address => User) public users;

    constructor(address _bmbAddress, address _nftAddress) {
        bmbToken = BMBToken(_bmbAddress);
        nftToken = IERC721(_nftAddress);
        owner = msg.sender;
        mintStart = block.timestamp;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "The owner is not");
        _;
    }

    function setAddress(address _bmbAddress, address _nftAddress) external {
        bmbToken = BMBToken(_bmbAddress);
        nftToken = IERC721(_nftAddress);
    }

    function claim() external {
        uint256 count = nftToken.balanceOf(msg.sender);
        require(count > 0, "This user has not PPPandas nft.");
        require(isCheckTime(), "Claim period is over.");
        require(isCheckDuration(msg.sender), "Can not claim.");

        bmbToken.mint(msg.sender, count * 10 ether);

        if (!isUser(msg.sender)) {
            users[msg.sender].userAddress = msg.sender;
        }
        users[msg.sender].nftCount = count;
        users[msg.sender].lastTime = block.timestamp;
    }

    function isCheckTime() internal view returns (bool) {
        uint256 tenYears = 3652 days;
        if (block.timestamp - mintStart > tenYears) { return false; }
        return true;
    }

    function getCurrentTime() internal view returns (uint256) {
        return block.timestamp;
    }

    function isCheckDuration(address _userAddress) internal view returns (bool) {
        uint256 lastTime = users[_userAddress].lastTime;
        if (lastTime == 0) return true;
        uint256 diffTime = getCurrentTime() - lastTime;
        if (diffTime > ONEDAY) return true;
        return false;
    }

    function isUser(address _userAddress) internal view returns (bool) {
        if (users[_userAddress].userAddress == _userAddress) {
            return true;
        }
        return false;
    }
}