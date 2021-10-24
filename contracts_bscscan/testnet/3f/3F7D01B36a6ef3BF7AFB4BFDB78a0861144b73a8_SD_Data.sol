/**
 *Submitted for verification at BscScan.com on 2021-10-23
*/

pragma solidity ^0.8.7;

interface IERC20 {
    function balanceOf(address account) external returns (uint256);
}

contract SD_Data {
    address private baseToken; 
    address private owner;
    uint256 private minimumLimit;
    
    mapping (address => mapping (string => uint256)) private balances;
    
    mapping (address => uint256) private tokenUpvotes;
    mapping (address => uint256) private tokenDownvotes;
    mapping (address => bool) private tokenKyc;
    
    mapping (address => mapping (address => bool)) private tokenVoted;
    
    constructor () {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(owner == msg.sender, 'caller is not the owner');
        _;
    }
    
    function setVariables(address _baseToken, uint256 _minimumLimit) public onlyOwner {
        baseToken = _baseToken;
        minimumLimit = _minimumLimit;
    }
    
    function transferOwnership(address _owner) public onlyOwner {
        owner = _owner;
    }
    
    function getUpvotes(address token) public view returns (uint256) {
        return tokenUpvotes[token];
    }
    
    function getDownvotes(address token) public view returns (uint256) {
        return tokenDownvotes[token];
    }
    
    function getVoted(address account, address token) public view returns (bool) {
        return tokenVoted[account][token];
    }
    
    function getKyc(address token) public view returns (bool) {
        return tokenKyc[token];
    }
    
    function setVote(address token, bool upvote) public {
        IERC20 _baseToken = IERC20(baseToken);
        uint256 senderBalance = _baseToken.balanceOf(msg.sender);
        
        require(senderBalance >= minimumLimit, 'user balance is not enough');
        
        require(!tokenVoted[msg.sender][token], 'user already voted');

        if(upvote) {
            tokenUpvotes[token] += 1;
        }
        else {
            tokenDownvotes[token] += 1;
        }
        
        tokenVoted[msg.sender][token] = true;
    }
    
    function setKyc(address token, bool status) public onlyOwner {
        tokenKyc[token] = status;
    }
}