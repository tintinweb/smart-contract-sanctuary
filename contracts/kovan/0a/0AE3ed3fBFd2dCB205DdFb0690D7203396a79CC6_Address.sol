/**
 *Submitted for verification at Etherscan.io on 2021-08-18
*/

pragma solidity ^0.6.2;

library Address {
    
    function isContract(address account) internal view returns (bool) {
       
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

pragma solidity ^0.6.0;

contract Context {
    
    constructor () internal { }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; 
        return msg.data;
    }
}



pragma solidity ^0.6.0;

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.6.0;

interface STAKETOKEN {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract Stake is Ownable {

    
    STAKETOKEN public token;
    address public mainWallet;
    uint256 public totalStakedTokens = 0;
    
    
    mapping(address => bool) public HasStake;
    
    struct stakeInfo{
        uint256 StartDate;
        uint256 LastWithdrawDate;
        uint256 Claimed;
        uint256 Staked;
    }
    mapping(address => stakeInfo[]) StakingInfo;
    
    uint public dailyEarningPercent  = 80;
    uint public stakeDuration = 300;
    uint256 public limitStakeTokens = 10000 * (10 ** 5);
    
    constructor(STAKETOKEN _token) public {
        token = _token;
        
        mainWallet = 0xB425dc48b4cac24ef67a2feAE6d648a9A2b3A9fb;

    }
    
    function balanceOf(address account) public view returns (uint256) {
        return token.balanceOf(account);
    }
    
    function createStake(uint256 _amount) public 
    {
        address sender = msg.sender;
        require(totalStakedTokens + _amount < limitStakeTokens, "Stake Amount must be less than MAX_STAKEABLE_NUMBER");
        
        token.transferFrom(sender, mainWallet, _amount);
        
        totalStakedTokens = totalStakedTokens + _amount;

        HasStake[sender] = true;
        StakingInfo[sender].push(stakeInfo(now, 0, 0, _amount));
    }
    

    function setWithdrawAddress(address payable _address) external onlyOwner {
        mainWallet = _address;
    }

    function setTokenAddress(STAKETOKEN tokenAddr) external onlyOwner {
        token = tokenAddr;
    }
    
    function setDailyEarningPercent (uint _percent) public onlyOwner {
        dailyEarningPercent = _percent;
    }
    
    function setStakeDuration (uint duration) public onlyOwner {
        stakeDuration = duration;
    }
    
    function setLimitStakeTokens (uint256 limit) public onlyOwner {
        limitStakeTokens = limit;
    }
    
    event Deposited(address indexed user, uint256 amount);
    event Recovered(address token, uint256 amount);
}