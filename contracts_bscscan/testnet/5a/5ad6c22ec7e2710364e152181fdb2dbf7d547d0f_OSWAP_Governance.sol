/**
 *Submitted for verification at BscScan.com on 2021-10-15
*/

// Sources flattened with hardhat v2.6.6 https://hardhat.org

// File contracts/libraries/TransferHelper.sol

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >= 0.6.11;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}


// File contracts/OSWAP_Governance.sol


pragma solidity >= 0.8.6;

contract OSWAP_Governance {
    uint256 public superTrollMinStake;
    uint256 public generalTrollMinStake;
    uint256 public superTrollMinCount;
    uint256 public superTrollCount;
    address public govToken;

    mapping(address => address) public trollStakingAddress; 
    mapping(address => uint256) public trollStakingBalance;
    mapping(address => uint256) public stakingBalance;

    mapping(address => bool) public superTrollCandidates;
    mapping(address => bool) public isSuperTroll;

    event Stake(         
        address troll,
        uint256 amount,
        bool isSuperTroll,
        bool isGeneralTroll
    );
    event Unstake(         
        address troll,
        uint256 amount,
        bool isSuperTroll,
        bool isGeneralTroll
    );
    constructor(address _govToken, uint256 _minSuperTrollCount, uint256 _superTrollMinStake, uint256 _generalTrollMinStake){
        require(_superTrollMinStake > 1, "OSWAP_Governance: ");
        govToken = _govToken;
        superTrollMinCount = _minSuperTrollCount;
        superTrollMinStake = _superTrollMinStake;
        generalTrollMinStake = _generalTrollMinStake;
        superTrollCandidates[msg.sender] = true;
        isSuperTroll[msg.sender] = true;
        superTrollCount = 1;
    }
    function registerSuperTroll(address troll) external{
        require(isSuperTroll[msg.sender] == true, "OSWAP_Governance: ");
        superTrollCandidates[troll] = true;
        if (isSuperTroll[troll] == false && trollStakingBalance[troll] >= superTrollMinStake){
            isSuperTroll[troll] = true;
            superTrollCount ++;
        }
    }
    function isGeneralTroll(address troll) public view returns(bool){
        return isSuperTroll[troll] == false && trollStakingBalance[troll] >= generalTrollMinStake;
    }
    function stake(address troll, uint256 amount) external {      
        TransferHelper.safeTransferFrom(govToken, msg.sender, address(this), amount);
        uint256 stakedAmount = stakingBalance[msg.sender];
        address stakedAddress = trollStakingAddress[msg.sender];
        trollStakingBalance[stakedAddress] -= stakedAmount;

        if (isSuperTroll[stakedAddress] == true && trollStakingBalance[stakedAddress] < superTrollMinStake){
            isSuperTroll[stakedAddress] = false;
            superTrollCount --;
        }
        trollStakingAddress[msg.sender] = troll;
        stakingBalance[msg.sender] += amount;
        trollStakingBalance[troll] = stakingBalance[msg.sender];
        
        if (isSuperTroll[troll] == false && superTrollCandidates[troll] == true && trollStakingBalance[troll] >= superTrollMinStake){
            isSuperTroll[troll] = true;
            superTrollCount ++;
        }
        require(superTrollCount >= superTrollMinCount, "OSWAP_Governance: ");
        emit Stake(troll, amount, isSuperTroll[troll], isGeneralTroll(troll));
    }
    function unstake(uint256 amount) external {
        address stakedAddress = trollStakingAddress[msg.sender];
        stakingBalance[msg.sender] -= amount;
        trollStakingBalance[stakedAddress] -= amount;
        TransferHelper.safeTransfer(govToken, msg.sender, amount);
        if (isSuperTroll[stakedAddress] && trollStakingBalance[stakedAddress] < superTrollMinStake){
            isSuperTroll[stakedAddress] = false;
            superTrollCount --;
        }
        require(superTrollCount >= superTrollMinCount, "OSWAP_Governance: ");
        emit Unstake(stakedAddress, amount, isSuperTroll[stakedAddress], isGeneralTroll(stakedAddress));
    }
}