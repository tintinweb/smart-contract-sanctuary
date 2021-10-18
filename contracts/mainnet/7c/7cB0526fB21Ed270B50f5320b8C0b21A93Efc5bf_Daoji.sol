// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./ERC20.sol";
import "./Ownable.sol";
import "./IERC721.sol";
import "./Address.sol";


contract Daoji is ERC20, Ownable {
    using Address for address;
    
    address public EmojiMinter;
    
    uint256 public rewardRate = 5 ether;
    uint256 public initialization;
    
    mapping(address => uint256) pendingRewards;
    mapping(address => uint256) lastClaimed;
    mapping(address => bool) trusted;
    
    
    bool pauseRewards = false;
    
    constructor(address Emojiverse) ERC20("Daoji", "DAOJI") {
        EmojiMinter = Emojiverse;
        initialization = block.timestamp;
    }
    
    function setTrusted(address _account, bool _trueOrFalse) external onlyOwner {
        trusted[_account] = _trueOrFalse;
    }
    
    function setRewardState() external onlyOwner {
        pauseRewards = !pauseRewards;
    }
    
    function changeEmojiMinter(address Emojiverse) external onlyOwner {
        EmojiMinter = Emojiverse;
    }
    
    function claimDaoji() external {
        require(pauseRewards != false, "Reward Claiming Is Paused");
        uint256 reward = pendingRewards[msg.sender] + pendingAmountEligible(msg.sender);
        pendingRewards[msg.sender] = 0;
        lastClaimed[msg.sender] = block.timestamp;
        _mint(msg.sender, reward);
    }    
    
    function updateRewards(address _sender, address _reciever) external {
        require(msg.sender == EmojiMinter, "Only Callable by Minter Contract");
        
        uint256 sender = pendingAmountEligible(_sender);
        lastClaimed[_sender] = block.timestamp;
        uint256 reciever = pendingAmountEligible(_reciever);
        lastClaimed[_reciever] = block.timestamp;
        
        pendingRewards[_sender] = pendingRewards[_sender] + sender;
        pendingRewards[_reciever] = pendingRewards[_reciever] + reciever;
    }
    
    function burnDaoji(address _account, uint256 _number) external {
        require(trusted[msg.sender] == true || msg.sender == address(EmojiMinter));
        _burn(_account, _number);
    }
    
    function totalClaimEligible(address _account) public view returns(uint256) {
        return pendingRewards[_account] + pendingAmountEligible(_account);
    }
    
    function viewTotalHeld(address _account) public view returns(uint256) {
        return IERC721(EmojiMinter).balanceOf(_account);
    }
    
    function pendingAmountEligible(address _account) public view returns(uint256) {
        uint256 rewardPeriod;
        
        if(lastClaimed[_account] > initialization) {
            rewardPeriod = lastClaimed[_account];
        } else
        if(lastClaimed[_account] < initialization) {
            rewardPeriod = initialization;
        }
        
        return viewTotalHeld(_account) * rewardRate * (block.timestamp - rewardPeriod) / 86400;
    }
    
    
}