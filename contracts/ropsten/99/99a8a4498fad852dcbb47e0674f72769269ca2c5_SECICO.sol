/**
 *Submitted for verification at Etherscan.io on 2021-04-10
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    
    function balanceOf(address account) external view returns (uint256);
    
}

contract SECICO {
    using SafeMath for uint256;

    address public token;
    address public owner;
    address payable public development;
    address payable public investment;
    uint256 public phaseNow;
    uint256 public lastPhase;
    uint256 public state;
    uint256 public constant minDeposit = 1000000000000000;

    struct UserInfo {
        uint256 amount;
    }

    struct PhaseInfo {
        uint256 allocToken;
        uint256 totalDeposit;
        uint256 tokenPerWEI;
    }

    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    PhaseInfo[] public phaseInfo;

    constructor(address _token, address payable _dev,address payable _invest) public {
        owner = msg.sender;
        token = _token;
        development = _dev;
        investment = _invest;
        state = 2;
    }

    event Deposit(uint256,uint256);
    event NewICO(uint256,uint256);
    event ICOEnded(uint256,uint256,uint256);
    event Claimed(uint256);
    event NewAddressSet(address,address);

    /**
     * @dev Fallback function receives ether and calls depositX
     */
    receive() external payable {
        require(state == 1,"NO:ICO");
        depositX();
    }

    /**
     * @dev Modifier for onlyOwner
     */    
    modifier onlyOwner() {
        require(msg.sender == owner,"OnlyOwner");
        _;
    }


    /**
     * @dev Deposits ether to ICO
     * there must be an ongoing ICO, (state==1)
     * splits ether at 70/30 to development and investment wallet.
     */
    function depositX() public payable returns(bool) {
        require(state == 1 && msg.value >= minDeposit,"NO:ICO||LESS_THAN::minDeposit");
        require(msg.sender != owner,"Owner can't deposit");
        uint256 _phase = phaseNow;
        UserInfo storage user = userInfo[_phase][msg.sender];
        PhaseInfo storage phase = phaseInfo[_phase];
        uint256 eps = msg.value.div(minDeposit);
        uint256 acMount = eps.mul(minDeposit);
        uint256 remainder = msg.value.sub(acMount);

        if(remainder > 0) {
            msg.sender.transfer(remainder);
        }

        user.amount = user.amount.add(eps);
        phase.totalDeposit = phase.totalDeposit.add(eps);
        
        uint256 getDev = acMount.div(100).mul(30);
        uint256 getInvest = acMount.div(100).mul(70);
        development.transfer(getDev);
        investment.transfer(getInvest);

        emit Deposit(msg.value,eps);
        return true;
    }
    
    /**
     * @dev Starts a new ICO
     * there must be no ICO running, or if there is any
     * that needs to be ended first, (endICO).
     */
    function setICO() onlyOwner external returns(bool) {
        require(state==2,"ICO is ACTIVE:END First");
        phaseInfo.push(PhaseInfo({
            allocToken: 0,
            totalDeposit: 0,
            tokenPerWEI: 0
        }));
        state = 1;

        emit NewICO(block.timestamp,phaseNow);
        return true;
    }

    /**
     * @dev Ends an existing ICO
     * there must an ICO already running,
     * Send the corresponding token to contract
     * @param _allocToken Number of tokens * 10 ** 18
     */
    function endICO(uint256 _allocToken) onlyOwner external returns (bool){
        require(state==1,"No ACTIVE ICO found");
        require(IERC20(token).balanceOf(address(this)) >= _allocToken,"Insufficient Token balance in contract");
        PhaseInfo storage phase = phaseInfo[phaseNow];
        require(phase.totalDeposit > 0,"Atleast one deposit");
        phase.allocToken = _allocToken;
        phase.tokenPerWEI = phase.allocToken.div(phase.totalDeposit);
        state = 2;
        lastPhase = phaseNow;
        phaseNow++;

        emit ICOEnded(_allocToken,phase.tokenPerWEI,lastPhase);
        return true;
    }

    /**
     * @dev Batch Claims previously ended ICO rewards.
     * the currently running ICO must be ended before,
     * being able to Claim that reward.
     */
    function Claim() external returns (bool){
        require(state==2,"ICO is ACTIVE:Wait till its finished");
        uint256 rewardSum;
        for(uint i=0; i<=lastPhase; i++) {
            UserInfo storage user = userInfo[i][msg.sender];
            PhaseInfo storage phase = phaseInfo[i];

            uint256 reward = phase.tokenPerWEI.mul(user.amount);

            user.amount = 0;     
            if (reward > 0) {
               require(IERC20(token).transfer(msg.sender, reward),"FAILED"); 
               rewardSum = rewardSum.add(reward);
            }
             
        }

        emit Claimed(rewardSum);
        return true;
    }

    /**
     * @dev view function to get the number of Batch Claimable tokens
     */
    function getClaim() external view returns (uint256) {
        uint256 rewardSum;
        for(uint i=0; i<=lastPhase; i++) {
            UserInfo storage user = userInfo[i][msg.sender];
            PhaseInfo storage phase = phaseInfo[i];
            uint256 reward = phase.tokenPerWEI.mul(user.amount);

            if (reward > 0) {
               rewardSum = rewardSum.add(reward);
            }
             
        }

        return rewardSum;
    }

    /**
     * @dev Claims previously ended specified phase reward.
     * @param _phase Corresponding phase number, cannot be greater than currnet phase
     */
    function ClaimX(uint256 _phase) external returns(bool) {
        require(state==2,"ICO is ACTIVE:Wait till its finished");
        require(_phase <= lastPhase,"Phase:NOT::END");
        UserInfo storage user = userInfo[_phase][msg.sender];
        PhaseInfo storage phase = phaseInfo[_phase];
        uint256 reward = phase.tokenPerWEI.mul(user.amount);

        if (reward > 0) {
            require(IERC20(token).transfer(msg.sender, reward),"FAILED"); 
        }
        user.amount = 0;

        emit Claimed(reward);
        return true;
    }

    /**
     * @dev view function to get the number of specified phase's Claimable tokens
     */
    function getClaimX(uint256 _phase) external view returns(uint256) {
        require(_phase <= lastPhase,"Phase:NOT::END");
        UserInfo storage user = userInfo[_phase][msg.sender];
        PhaseInfo storage phase = phaseInfo[_phase];
        uint256 reward = phase.tokenPerWEI.mul(user.amount);

        return reward;
    }

    /**
     * @dev Sets Addresses for SECToken, development and investment wallet
     * @param _development Development Wallet address
     * @param _investment Interested Wallet address
     */   
    function setAddresses(address payable _development,address payable _investment) onlyOwner external returns (bool) {

        development = _development;
        investment = _investment;

        emit NewAddressSet(_development, _investment);
        return true;
    }

    function transferAnyERC20(address _tokenAddress, address _to, uint _amount) public onlyOwner {
        IERC20(_tokenAddress).transfer(_to, _amount);
    }
    
    function transferOwnership(address newOwner) external {
        require(msg.sender == owner,"Only owner");
        require(newOwner != address(0),"Cannot set empty owner");
        owner = newOwner;
    }
}