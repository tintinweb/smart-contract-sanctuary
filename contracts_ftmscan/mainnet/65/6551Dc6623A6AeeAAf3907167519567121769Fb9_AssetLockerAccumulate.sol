/**
 *Submitted for verification at FtmScan.com on 2022-01-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IAssetBox {
    function getbalance(uint8 roleIndex, uint tokenID) external view returns (uint);
    function mint(uint8 roleIndex, uint tokenID, uint amount) external;
    function transfer(uint8 roleIndex, uint from, uint to, uint amount) external;
    function burn(uint8 roleIndex, uint tokenID, uint amount) external;
    function getRole(uint8 index) external view returns (address);
}

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

contract AssetLockerAccumulate {

    address public immutable assetBox; 
    address public immutable token;

    struct Lock {
        uint amount;
        uint lockedAt;
        uint lockDuration;
    }

    mapping(uint8 => mapping(uint => Lock)) public locksOf;

    uint public constant duration = 1 days;

    uint public constant minLockAmount = 1;

    bool public depositSwitch = true;

    address private immutable owner;

    event Deposited(uint8 indexed roleIndex, uint indexed tokenID, uint total, uint amount, uint lockDuration, address indexed owner);
    event Withdrawn(uint8 indexed roleIndex, uint indexed tokenID, uint total, uint amount, address indexed owner);

    constructor (address assetBox_, address token_) {
        assetBox = assetBox_;
        token = token_;

        owner = msg.sender;
    }

    function setDepositSwitch(bool depositSwitch_) external{
        require(msg.sender == owner, "Only Owner");

        depositSwitch = depositSwitch_;
    }

    function deposit(uint8 roleIndex, uint tokenID, uint amount) external {
        require(depositSwitch, "Can't deposit");
        require(amount >= minLockAmount, "Amount too small");
        address role = IAssetBox(assetBox).getRole(roleIndex);
        require(_isApprovedOrOwner(role, msg.sender, tokenID), 'Not approved');

        Lock storage lock = locksOf[roleIndex][tokenID];
        lock.amount += amount;
        lock.lockDuration = duration;
        lock.lockedAt = block.timestamp;
        
        IERC20(token).transferFrom(msg.sender, address(this), amount*1e18);
        IAssetBox(assetBox).mint(roleIndex, tokenID, amount);

        emit Deposited(roleIndex, tokenID, lock.amount, amount, duration, msg.sender);
    }

    function withdrawal(uint8 roleIndex, uint tokenID, uint amount) external {
        address role = IAssetBox(assetBox).getRole(roleIndex);
        require(_isApprovedOrOwner(role, msg.sender, tokenID), 'Not approved');

        Lock storage lock = locksOf[roleIndex][tokenID];
        require(lock.amount >= amount, "Not enough");

        uint256 unlockAt = lock.lockedAt + lock.lockDuration;
        require(block.timestamp > unlockAt, "lock not expired");

        IERC20(token).transfer(msg.sender, amount*1e18);
        IAssetBox(assetBox).burn(roleIndex, tokenID, amount);
        lock.amount -= amount;

        emit Withdrawn(roleIndex, tokenID, lock.amount, amount, msg.sender);
    }

    function _isApprovedOrOwner(address role, address operator, uint256 tokenId) private view returns (bool) {
        require(role != address(0), "Query for the zero address");
        address TokenOwner = IERC721(role).ownerOf(tokenId);
        return (operator == TokenOwner || IERC721(role).getApproved(tokenId) == operator || IERC721(role).isApprovedForAll(TokenOwner, operator));
    }
   
}