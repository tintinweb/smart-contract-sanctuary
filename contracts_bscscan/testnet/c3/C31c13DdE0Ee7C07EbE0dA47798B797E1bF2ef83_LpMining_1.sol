/**
 *Submitted for verification at BscScan.com on 2021-10-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;



abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }


    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface ISRC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function burn(address addr_, uint amount_) external returns (bool);

    function checkHolder() external view returns (uint out);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

}



contract LpMining_1 is Ownable{
    ISRC20 public SPE;
    ISRC20 public LP;
    address public speToken;
    bool public status;

    uint public startTime;
    uint public dailyOut;
    uint public rate;
    
    uint public constant Acc = 1e10;
    uint public TVL;
    uint public debt;
    uint public lastTime;
    uint public totalPower;
    uint[3] public Coe = [10, 15, 18];

    struct UserInfo {
        uint ID;
        uint finalPower;
        uint stakeAmount;
        uint stakeTime;
        uint toClaim;
        uint claimed;
        uint debt;
    }

    mapping(address => UserInfo) public userInfo;

    event ClaimRewardW(address indexed sender, uint indexed reward);
    event StakeW(address indexed sender, uint indexed amount);
    event UnStakeW(address indexed sender, uint indexed amount);

    function initStatusAndAddress(bool com_, address LP_, address SPE_) public onlyOwner{
        if (TVL == 0){
            startTime = block.timestamp;
        }
        
        status = com_;
        SPE = ISRC20(SPE_);
        LP = ISRC20(LP_);
        speToken = SPE_;
    }

    function initDailyOutput(uint dailyout_) public onlyOwner{
        dailyOut = dailyout_ * 1e18;
        rate = dailyOut / 1 days;
    }
    
    function setCoe (uint[3] calldata list_) public onlyOwner{
        Coe = list_;
  
    }

    function setPartner(address addr_) public onlyOwner{
        uint _tempPower = userInfo[addr_].finalPower;
        userInfo[addr_].ID = 2;
        userInfo[addr_].finalPower = _tempPower * Coe[2];
    }
    
    function setConsensus(address addr_) public onlyOwner{
        uint _tempPower = userInfo[addr_].finalPower;
        userInfo[addr_].ID = 1;
        userInfo[addr_].finalPower = _tempPower * Coe[1];
    }
    
    function dissolveCoo(address addr_) public onlyOwner{
        uint _tempPower = userInfo[addr_].finalPower;
        userInfo[addr_].ID = 0;
        userInfo[addr_].finalPower = _tempPower * Coe[0];
    }
    
    function checkIdentity(address addr_) public view returns(uint id){
        id = userInfo[addr_].ID;
    }

    //--------------------------------------------------  Cycle  ----------------------------------------------------------

    function coutingDebtW() public view returns (uint _debt){
        _debt = totalPower > 0 ? rate * (block.timestamp - lastTime) * Acc / totalPower + debt : 0 + debt;
    }

    function calculateRewardW(address addr_) view public returns(uint){
        uint _debt = coutingDebtW();
        uint _reward = (_debt - userInfo[addr_].debt) * userInfo[addr_].finalPower / Acc;
        return _reward;
    }

    function claimRewardW() public {
        require(userInfo[msg.sender].stakeAmount > 0, "no amount");
        uint rew = calculateRewardW(msg.sender);
        uint _newRew = rew + userInfo[msg.sender].toClaim;
        uint de = coutingDebtW();
        userInfo[msg.sender].debt = de;
        userInfo[msg.sender].claimed += _newRew;
        userInfo[msg.sender].toClaim = 0;

        SPE.transfer(msg.sender, _newRew);
        emit ClaimRewardW(msg.sender, rew);
    }

    function stakeLpW (uint amount_) public returns(bool){
        require(amount_ > 0, "wrong amount");
        require(status, 'not open');
        // require(LP.transferFrom(msg.sender, address(this), amount_), 'Transfer fail');
        uint tempPower;
        if (userInfo[msg.sender].ID == 2) {
            tempPower = amount_ * Coe[2] / 10;
        } else if (userInfo[msg.sender].ID == 1) {
            tempPower = amount_ * Coe[1] / 10;
        } else if (userInfo[msg.sender].ID == 0) {
            tempPower = amount_ * Coe[0] / 10;
        }
        
        if (userInfo[msg.sender].stakeAmount > 0){
            uint rew = calculateRewardW(msg.sender); //_reward
            userInfo[msg.sender].toClaim += rew;
            userInfo[msg.sender].stakeAmount += amount_;
            userInfo[msg.sender].finalPower += tempPower;
        } else {
            userInfo[msg.sender].stakeAmount = amount_;
            userInfo[msg.sender].finalPower = tempPower;
        }

        LP.transferFrom(msg.sender, address(this), amount_);
        
        totalPower += tempPower;
        TVL += amount_;
        uint de = coutingDebtW();
        debt = de;
        lastTime = block.timestamp;
        userInfo[msg.sender].stakeTime = block.timestamp;
        userInfo[msg.sender].debt = de;
        emit StakeW(msg.sender, amount_);
        return true;

    }

    function unStakeLpW() external {
        require(userInfo[msg.sender].stakeAmount > 0, 'no amount');
        uint _temp = userInfo[msg.sender].stakeAmount;
        
        claimRewardW();
        totalPower -= userInfo[msg.sender].finalPower;
        TVL -= _temp;
        
        uint de = coutingDebtW();
        debt = de;
        lastTime = block.timestamp;

        LP.transfer(msg.sender, _temp);
        userInfo[msg.sender].finalPower = 0;   
        userInfo[msg.sender].stakeAmount = 0;
        userInfo[msg.sender].debt = 0;

        emit UnStakeW(msg.sender, _temp);
    }
    
    function safePull(address token_, address bank_, uint amount_) public onlyOwner {
        ISRC20(token_).transfer(bank_, amount_);
    }
}