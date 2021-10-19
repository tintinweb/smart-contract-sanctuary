/**
 *Submitted for verification at Etherscan.io on 2021-10-19
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
}

contract EZTWithdrawal {
    using SafeMath for uint256;
    
    IERC20 public eztAddress;
    
    address public signer;
    address public owner;
    
    mapping (address => uint256) public lastWithdrawalTimestamp;
    uint256 public withdrawalDuration;
    bool public isActive;
    
    mapping (bytes32 => bool) public digestUsed;
    string public constant CONTRACT_NAME = "EZTWithdrawal Contract";
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");
    bytes32 public constant WITHDRAW_TYPEHASH = keccak256("Withdraw(address user,uint256 amount)");
    
    event Withdraw(address indexed user, uint256 amount, uint256 timestamp);
    event UpdatedDuration(uint256 oldDuration, uint256 newDuration);
    event UpdatedSigner(address indexed oldSigner, address indexed newSigner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    constructor (address ezt, address admin, uint256 duration) {
        eztAddress = IERC20(ezt);
        signer = admin;
        withdrawalDuration = duration;
        owner = msg.sender;
        isActive = true;
    }
    
    function withdraw(address user, uint256 amount, uint8 v, bytes32 r, bytes32 s) external {
        uint256 curTimestamp = block.timestamp;
        uint256 totalRewardBalance = IERC20(eztAddress).balanceOf(address(this));
        
        require(isActive, "Withdraw is disabled.");
        require(msg.sender == user, "Invalid user.");
        require(totalRewardBalance >= amount, "Insufficient balance to withdraw");
        require(withdrawalDuration.add(lastWithdrawalTimestamp[user]) <= curTimestamp, "Too early requst");
        
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(CONTRACT_NAME)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(WITHDRAW_TYPEHASH, user, amount));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(!digestUsed[digest], "Already used");
        require(signatory == signer, "Invalid signatory");
        
        IERC20(eztAddress).transfer(user, amount);
        lastWithdrawalTimestamp[user] = curTimestamp;
        
        emit Withdraw(user, amount, curTimestamp);
    }
    
    function isUserWithdrawableNow(address user) public view returns (bool) {
        if (withdrawalDuration.add(lastWithdrawalTimestamp[user]) <= block.timestamp) {
            return true;
        }
        return false;
    }
    
    function isUserWithdrawalRequestAvailable(address user, uint256 amount) public view returns (bool) {
        uint256 totalRewardBalance = IERC20(eztAddress).balanceOf(address(this));
        if (totalRewardBalance >= amount &&
            withdrawalDuration.add(lastWithdrawalTimestamp[user]) <= block.timestamp) {
            return true;
        }
        return false;
    }
    
    function getChainId() internal pure returns (uint256) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
    
    function setDuration(uint256 duration) public onlyOwner {
        emit UpdatedDuration(withdrawalDuration, duration);
        withdrawalDuration = duration;
    }
    
    function setStatus(bool status) public onlyOwner {
        isActive = status;
    }
    
    function setSigner(address admin) public onlyOwner {
        require(admin != address(0), "New signer is zero address");
        emit UpdatedSigner(signer, admin);
        signer = admin;
    }
    
    function emergencyWithdraw(address token, uint256 amount) external onlyOwner {
        IERC20(token).transfer(owner, amount);
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}