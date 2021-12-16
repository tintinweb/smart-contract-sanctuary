/**
SPDX-License-Identifier: MIT
*/

pragma solidity ^0.8.0;

//ERC20 Interface
interface IERC20 {
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

contract NodeGame {
    IERC20 immutable nodeToken;
    uint256 constant TOTAL_NODES = 2592000;
    uint256 constant PSN = 10000;
    uint256 constant PSNH = 5000;
    bool public initialized = false;
    address immutable dev;
    address immutable futureFee;
    mapping (address => uint256) public nodes;
    mapping (address => uint256) public claimedRewards;
    mapping (address => uint256) public nodeTimer;
    mapping (address => address) public referrals;
    uint256 public marketNodes;
    event PowerUp(address user, address ref, uint256 power);
    event ClaimRewards(address user, uint256 amount);
    event NodesPurchased(address user, address ref, uint256 power);

    constructor(address _nodeToken, address _futureFee){
        dev = payable(msg.sender);
        futureFee = payable(_futureFee);
        nodeToken = IERC20(_nodeToken);
    }
    function powerUp(address ref) public {
        require(initialized, "Game has not begun.");
        if(ref == msg.sender) {
            ref = address(0);
        }

        if(referrals[msg.sender] == address(0) && referrals[msg.sender] != msg.sender) {
            referrals[msg.sender] = ref;
        }
        uint256 amountRewards = getMyRewards();
        uint256 newNodes = amountRewards / TOTAL_NODES;
        nodes[msg.sender] = nodes[msg.sender] + newNodes;
        claimedRewards[msg.sender] = 0;
        nodeTimer[msg.sender] = block.timestamp;
        
        claimedRewards[referrals[msg.sender]] = claimedRewards[referrals[msg.sender]] + amountRewards / 7;
        
        marketNodes = marketNodes + amountRewards / 5;
        emit PowerUp(msg.sender, ref, marketNodes);
    }

    function claimRewards() public {
        require(initialized, "Game has not begun.");
        uint256 amountRewards = getMyRewards();
        uint256 rewardValue = calculateClaimReward(amountRewards);
        claimedRewards[msg.sender] = 0;
        nodeTimer[msg.sender] = block.timestamp;
        marketNodes = marketNodes + amountRewards;
        uint256 fee = devFee(rewardValue);
        uint256 devShare = fee / 2;
        nodeToken.transfer(dev, devShare);
        nodeToken.transfer(futureFee, fee - devShare);
        nodeToken.transfer(msg.sender, rewardValue - fee);
        emit ClaimRewards(msg.sender, rewardValue - fee);
    }

    function buyNodes(address ref, uint256 amount) public {
        require(initialized, "Game has not begun.");
        nodeToken.transferFrom(msg.sender, address(this), amount);
        uint256 balance = nodeToken.balanceOf(address(this));
        uint256 powerBought = calculatePowerUp(amount, balance - amount);
        powerBought = powerBought - devFee(powerBought);
        uint256 fee = devFee(amount);
        uint256 devShare = fee / 2;
        nodeToken.transfer(dev, devShare);
        nodeToken.transfer(futureFee, fee - devShare);
        claimedRewards[msg.sender] = claimedRewards[msg.sender] + powerBought;
        powerUp(ref);
        emit NodesPurchased(msg.sender, ref, amount - fee);
    }

    function calculateExchange(uint256 rt, uint256 rs, uint256 bs) public pure returns(uint256) {
        return (PSN*bs)/(PSNH+((PSN*rs+PSNH*rt)/rt));
    }

    function calculateClaimReward(uint256 amount) public view returns(uint256) {
        return calculateExchange(amount, marketNodes, nodeToken.balanceOf(address(this)));
    }

    function calculatePowerUp(uint256 amount, uint256 contractBal) public view returns(uint256) {
        return calculateExchange(amount, contractBal, marketNodes);
    }

    function calculatePowerUpSimple(uint256 amount) public view returns(uint256){
        return calculatePowerUp(amount, nodeToken.balanceOf(address(this)));
    }

    function devFee(uint256 amount) public pure returns(uint256){
        return amount * 10 / 100;
    }

    function seedNodes(uint256 amount) public {
        nodeToken.transferFrom(msg.sender, address(this), amount);
        require(marketNodes == 0, "Game has already begun.");
        initialized = true;
        marketNodes = 259200000000;
    }

    function contractBalance() public view returns(uint256) {
        return nodeToken.balanceOf(address(this));
    }

    function getMyNodes() public view returns(uint256) {
        return nodes[msg.sender];
    }
    
    function getMyRewards() public view returns(uint256) {
        return claimedRewards[msg.sender] + getNodesSinceAction(msg.sender);
    }
    function getNodesSinceAction(address adr) public view returns(uint256) {
        uint256 secondsPassed = min(TOTAL_NODES, (block.timestamp - nodeTimer[adr]));
        return secondsPassed * nodes[adr];
    }
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}