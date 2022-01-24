/**
 *Submitted for verification at BscScan.com on 2022-01-24
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IBEP20 {
    
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom( address sender, address recipient, uint256 amount) external returns (bool);
   
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Context {
    
    constructor()  {}

    function _msgSender() internal view returns (address ) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; 
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor()  {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Pausable is Context {
    
    event Paused(address account);

    event Unpaused(address account);

    bool private _paused;

    constructor () {
        _paused = false;
    }

    function paused() public view returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

contract Vesting is Ownable, Pausable {

    IBEP20 public AnationToken;
    uint256 public currentVestingID;
    uint256 public rewardPercentage = 8;
    uint256 public WithdrawFee = 50;
    uint256 public feeDays = 3;

    struct userInfo{
        address user;
        uint256 vestID;
        uint256 vestingTime;
        uint256 vestingAmount;
        uint256 lastRewardClaim;
        uint256 unVestingTime;
    }

    struct vestings{
        uint256[] VestingIDs;
    }

    mapping (address => mapping(uint256 => userInfo)) private userDetails;
    mapping (address => vestings) private vestingID;

    event VestTokens(address indexed user, uint256 stakeID, uint256 vestAmount);
    event UnVestTokens(address indexed user, uint256 stakeID, uint256 unVestAmount );
    event ClaimTokens(address indexed user, uint256 stakeID, uint256 claimAmount);
    event EmergencySafe(address indexed receiver, address indexed TokenAddress, uint tokenAmount);

    constructor (address _anationToken) {
        AnationToken = IBEP20(_anationToken);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unPause() external onlyOwner {
        _unpause();
    }

    function viewVestID(address _account) external view returns(uint256[] memory){
        return vestingID[_account].VestingIDs;
    }

    function updateFeeDays(uint256 _days) external onlyOwner {
        feeDays = _days;
    }

    function updateWithdrawFee(uint256 _fee) external onlyOwner {
        WithdrawFee = _fee;
    }

    function viewUserDetails(address _account, uint256 _vestID) external view returns(userInfo memory) {
        return userDetails[_account][_vestID];
    }

    function updatePercentage(uint256 _rewardPercentage) external onlyOwner {
        rewardPercentage = _rewardPercentage;
    }

    function vestToken(uint256 _amount) external whenNotPaused {
        currentVestingID++;
        userInfo storage user = userDetails[msg.sender][currentVestingID];
        user.user = msg.sender;
        user.vestID = currentVestingID;
        user.vestingAmount = _amount;
        user.vestingTime = block.timestamp;
        user.lastRewardClaim = block.timestamp;

        vestingID[msg.sender].VestingIDs.push(currentVestingID);

        AnationToken.transferFrom(msg.sender, address(this), _amount);
        emit VestTokens(msg.sender, currentVestingID, _amount);
    }

    function unVestToken(uint256 _vestID ) external whenNotPaused {
        userInfo storage user = userDetails[msg.sender][_vestID];
        require(user.user == msg.sender,"invalid ID");
        require(user.unVestingTime > 0,"user already unstaked");
        uint256 withdrawAmount = user.vestingAmount;
        if((feeDays * 86400) <= (block.timestamp - user.vestingTime)) { 
            withdrawAmount = withdrawAmount - (withdrawAmount * WithdrawFee / 1e3); 
        }
        claimReward( _vestID);
        user.unVestingTime = block.timestamp;
        AnationToken.transfer(user.user, withdrawAmount);

        emit UnVestTokens(user.user, _vestID, withdrawAmount );
    }

    function claimReward(uint256 _vestID) public whenNotPaused {
        userInfo storage user = userDetails[msg.sender][_vestID];
        require(user.user == msg.sender,"invalid ID");
        require(user.unVestingTime > 0,"user already unstaked");
        uint256 reward = user.vestingAmount * rewardPercentage / 1e4;
        uint256 count = (block.timestamp - user.lastRewardClaim) / 86400;
        user.lastRewardClaim += 86400 * count;
        AnationToken.transfer(user.user, reward * count);

        emit ClaimTokens(user.user, _vestID, reward * count);
    }

    function pendingRewards(address _account,uint256 _vestID) external view returns(uint256 ) {
        userInfo storage user = userDetails[_account][_vestID];
        require(user.unVestingTime > 0,"user already unstaked");
        uint256 reward = user.vestingAmount * rewardPercentage / 1e4;
        uint256 count = (block.timestamp - user.lastRewardClaim) / 86400;

        return reward*count;
    }

    function emergency(address _to, address _tokenAddress, uint256 _amount) external onlyOwner {
        if(_tokenAddress == address(0x0)){
            require(payable(_to).send(_amount),"transaction failed");
        } else {
            IBEP20(_tokenAddress).transfer(_to, _amount);
        }
        emit EmergencySafe(_to, _tokenAddress, _amount);
    }

}