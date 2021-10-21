/**
 *Submitted for verification at BscScan.com on 2021-10-21
*/

// SPDX-License-Identifier: MIT

/*
 *    SSSSSSSSSSSSSSS    SSSSSSSSSSSSSSS BBBBBBBBBBBBBBBBB   
 *  SS:::::::::::::::S SS:::::::::::::::SB::::::::::::::::B  
 * S:::::SSSSSS::::::SS:::::SSSSSS::::::SB::::::BBBBBB:::::B 
 * S:::::S     SSSSSSSS:::::S     SSSSSSSBB:::::B     B:::::B
 * S:::::S            S:::::S              B::::B     B:::::B
 * S:::::S            S:::::S              B::::B     B:::::B
 *  S::::SSSS          S::::SSSS           B::::BBBBBB:::::B 
 *   SS::::::SSSSS      SS::::::SSSSS      B:::::::::::::BB  
 *     SSS::::::::SS      SSS::::::::SS    B::::BBBBBB:::::B 
 *        SSSSSS::::S        SSSSSS::::S   B::::B     B:::::B
 *             S:::::S            S:::::S  B::::B     B:::::B
 *             S:::::S            S:::::S  B::::B     B:::::B
 * SSSSSSS     S:::::SSSSSSSS     S:::::SBB:::::BBBBBB::::::B
 * S::::::SSSSSS:::::SS::::::SSSSSS:::::SB:::::::::::::::::B 
 * S:::::::::::::::SS S:::::::::::::::SS B::::::::::::::::B  
 *  SSSSSSSSSSSSSSS    SSSSSSSSSSSSSSS   BBBBBBBBBBBBBBBBB
 *  
 * 
 * https://www.ssbtoken.com/
 * https://t.me/SSBTokenOfficial
 *
 */

pragma solidity 0.8.7;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Auth {
    address owner;
    mapping (address => bool) private authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender)); _;
    }

    modifier authorized() {
        require(isAuthorized(msg.sender)); _;
    }

    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
        emit Authorized(adr);
    }

    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
        emit Unauthorized(adr);
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    function transferOwnership(address newOwner) public onlyOwner {
        address oldOwner = owner;
        owner = newOwner;
        authorizations[oldOwner] = false;
        authorizations[newOwner] = true;
        emit Unauthorized(oldOwner);
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    event OwnershipTransferred(address oldOwner, address newOwner);
    event Authorized(address adr);
    event Unauthorized(address adr);
}

contract SSBVesting is Auth {
    address ssb;
    
    mapping (address => uint256) public shares;
    mapping (address => uint256) public claimed;
    uint256 public totalShares;
    uint256 public totalClaimed;
    uint256 public vestStart;
    uint256 public vestLength = 8 weeks;
    
    constructor(address _ssb) Auth(msg.sender) {
        ssb = _ssb;
    }
    
    bool seeded = false;
    modifier seeding(){
        require(!seeded); 
        _;
        seeded = true;
    }
    
    modifier canClaim(){
        require(vestStart>0); _;
    }
    
    function seed(address[] memory holders, uint256[] memory amounts) external authorized seeding {
        for(uint256 i; i<holders.length; i++){
            shares[holders[i]] = amounts[i];
            totalShares += amounts[i];
        }
    }
    
    function startVesting() external authorized {
        require(vestStart == 0);
        vestStart = block.timestamp;
    }
    
    function getClaimableShares(address holder) public view returns (uint256) {
        if(vestStart == 0) return 0;
        
        uint256 timeFromStart = block.timestamp - vestStart;
        uint256 unlocked = timeFromStart > vestLength ? shares[holder] : shares[holder] * timeFromStart / vestLength;
        uint256 unclaimed = unlocked - claimed[holder];
        return unclaimed;
    }
    
    function getPendingAmount(address holder) public view returns (uint256) {
        if(vestStart == 0) return 0;
        
        uint256 claimableShares = getClaimableShares(holder);
        uint256 remainingTotalShares = totalShares - totalClaimed;
        return claimableShares * getVestedTokenBalance() / remainingTotalShares;
    }
    
    function claim() external canClaim {
        uint256 amount = getPendingAmount(msg.sender);
        if(amount > 0){
            uint256 claiming = getClaimableShares(msg.sender);
            claimed[msg.sender] += claiming;
            totalClaimed += claiming;
            IBEP20(ssb).transfer(msg.sender, amount);
        }
    }
    
    function getVestedTokenBalance() public view returns (uint256) {
        return IBEP20(ssb).balanceOf(address(this));
    }
    
    function withdrawTokens(uint256 amount) external authorized {
        IBEP20(ssb).transfer(msg.sender, amount);
    }
}