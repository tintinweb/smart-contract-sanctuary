/**
 *Submitted for verification at BscScan.com on 2021-08-13
*/

// SPDX-License-Identifier: 0BSD

pragma solidity ^0.8.7;

interface ERC20 {
    function transfer(address to, uint tokens) external;
    function transferFrom(address from, address to, uint tokens) external;
}

contract TangleV1 {

    uint8 public decimals;
    uint public totalSupply;
    string public name;
    string public symbol;
    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint)) private allowed;

    mapping(uint => uint) public tax;
    address public gamemaster;
    address public liquidityAddress;
    uint public totalPieces;
    uint public piecesPerUnit;
    uint public minHoldAmount;
    mapping(uint => uint) public rewardMax;
    mapping(uint => uint) public rewardConst;
    mapping(uint => uint) public rewardsLastRewardChange;
    mapping(uint => uint) public timeFromInitToLastRewardChange;
    uint public distributionRewardThreshold;
    mapping(address => bool) public hasReceivedPieces;
    mapping(uint => mapping(address => uint)) public rewardableEvents;
    mapping(uint => uint) public totalRewardableEvents;
    mapping(uint => uint) public startTime;
    mapping(uint => mapping(address => uint)) public emissionInit; 
    mapping(address => uint) public totalBuyVolume;
    mapping(address => uint) public totalSellVolume;
    address public owner;

    constructor() {
        name = "TangleV1";
        symbol = "TNGL";
        decimals = 9;
        totalSupply = 1e9 * 1*10**(decimals);
        totalPieces = type(uint128).max - (type(uint128).max % totalSupply);
        piecesPerUnit = totalPieces / totalSupply;
        balances[msg.sender] = totalPieces;
        gamemaster = msg.sender;
        owner = msg.sender;
        minHoldAmount = 1;
        distributionRewardThreshold = 1e9;

        // INITIAL REWARDCONST MAP {
            rewardConst[0] = 300000; // Market Maker
            rewardConst[1] = 300000; // Distributor
            rewardConst[2] = 300000; // Staker
        // }

        // INITIAL TAX MAP {
            tax[100] =  5e9;  // Transfer Multiplier
            tax[101] =  1e11; // Transfer Divisor
            tax[200] =  1e9;  // Market Maker Transfer Multiplier
            tax[201] =  1e11; // Market Maker Transfer Divisor
            tax[210] = 10e9;  // Market Maker Withdraw Multiplier
            tax[211] =  1e11; // Market Maker Withdraw Divisor
            tax[220] =  4e9;  // Market Maker To Distributor Multiplier
            tax[221] =  1e11; // Market Maker To Distributor Divisor
            tax[230] =  4e9;  // Market Maker To Staker Multiplier
            tax[231] =  1e11; // Market Maker To Staker Divisor
            tax[240] =  1e9;  // Market Maker To Reflect Multiplier
            tax[241] =  1e11; // Market Maker To Reflect Divisor
            tax[250] =  1e9;  // Market Maker To Gamemaster Multiplier
            tax[251] =  1e11; // Market Maker To Gamemaster Divisor
            tax[300] =  1e9;  // Distributor Transfer Multiplier
            tax[301] =  1e11; // Distributor Transfer Divisor
            tax[310] = 10e9;  // Distributor Withdraw Multiplier
            tax[311] =  1e11; // Distributor Withdraw Divisor
            tax[320] =  4e9;  // Distributor To Market Maker Multiplier
            tax[321] =  1e11; // Distributor To Market Maker Divisor
            tax[330] =  4e9;  // Distributor To Staker Multiplier
            tax[331] =  1e11; // Distributor To Staker Divisor
            tax[340] =  1e9;  // Distributor To Reflect Multiplier
            tax[341] =  1e11; // Distributor To Reflect Divisor
            tax[350] =  1e9;  // Distributor To Gamemaster Multiplier
            tax[351] =  1e11; // Distributor To Gamemaster Divisor
            tax[400] =  1e9;  // Staker Transfer Multiplier
            tax[401] =  1e11; // Staker Transfer Divisor
            tax[410] = 10e9;  // Staker Withdraw Multiplier
            tax[411] =  1e11; // Staker Withdraw Divisor
            tax[420] =  4e9;  // Staker To Market Maker Multiplier
            tax[421] =  1e11; // Staker To Market Maker Divisor
            tax[430] =  4e9;  // Staker To Distributor Multiplier
            tax[431] =  1e11; // Staker To Distributor Divisor
            tax[440] =  1e9;  // Staker To Reflect Multiplier
            tax[441] =  1e11; // Staker To Reflect Divisor
            tax[450] =  1e9;  // Staker To Gamemaster Multiplier
            tax[451] =  1e11; // Staker To Gamemaster Divisor
            tax[500] =  1e9;  // Reflect Transfer Multiplier
            tax[501] =  1e11; // Reflect Transfer Divisor
            tax[600] =  1e9;  // Gamemaster Transfer Multiplier
            tax[601] =  1e11; // Gamemaster Transfer Divisor
        // }

    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner] / piecesPerUnit;
    }

    function allowance(address _owner, address spender) public view returns (uint256) {
        return allowed[_owner][spender];
    }

    function transfer(address to, uint value) public returns (bool) {
        value = enforceMinHold(msg.sender, value);
        uint pieceValue = value * piecesPerUnit;
        balances[msg.sender] -= pieceValue;
        balances[to] += pieceValue - taxify(pieceValue, 10);
        balances[address(this)] += taxify(pieceValue, 20) + taxify(pieceValue, 30) + taxify(pieceValue, 40);
        balances[gamemaster] += taxify(pieceValue, 60);
        for (uint i = 0; i < 3; i++) { changeRewardMax(i, rewardMax[i] + taxify(pieceValue, 20 + i * 10)); }
        reflect(taxify(pieceValue, 50));
        distributionCheck(msg.sender, to, value);
        if (msg.sender == liquidityAddress)
            adjustMarketMakerRewardableEvents(to, pieceValue, false);
        if (to == liquidityAddress)
            adjustMarketMakerRewardableEvents(msg.sender, pieceValue, true);
        emit Transfer(msg.sender, to, value - taxify(value, 10));
        emit Tax(taxify(value, 10));
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        value = enforceMinHold(from, value);
        allowed[from][msg.sender] = allowed[from][msg.sender] - value;
        uint pieceValue = value * piecesPerUnit;
        balances[from] -= pieceValue;
        balances[to] += pieceValue - taxify(pieceValue, 10);
        balances[address(this)] += taxify(pieceValue, 20) + taxify(pieceValue, 30) + taxify(pieceValue, 40);
        balances[gamemaster] += taxify(pieceValue, 60);
        for (uint i = 0; i < 3; i++) { changeRewardMax(i, rewardMax[i] + taxify(pieceValue, 20 + i * 10)); }
        reflect(taxify(pieceValue, 50));
        distributionCheck(from, to, value);
        if (from == liquidityAddress)
            adjustMarketMakerRewardableEvents(to, pieceValue, false);
        if (to == liquidityAddress)
            adjustMarketMakerRewardableEvents(from, pieceValue, true);
        emit Transfer(from, to, value - taxify(value, 10));
        emit Tax(taxify(value, 10));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        allowed[msg.sender][spender] = allowed[msg.sender][spender] + addedValue;
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        allowed[msg.sender][spender] = allowed[msg.sender][spender] - subtractedValue;
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    function taxify(uint value, uint id) internal view returns (uint) {
        return value * tax[id * 10] / tax[id * 10 + 1];
    }
    
    function reflect(uint reflectAmount) internal {
        uint FTPXA = totalSupply * piecesPerUnit - balances[liquidityAddress];
        uint FFTPXARA = FTPXA - reflectAmount;
        piecesPerUnit = piecesPerUnit * FFTPXARA / FTPXA;
        if (piecesPerUnit < 1) 
            piecesPerUnit = 1;
        balances[liquidityAddress] = balances[liquidityAddress] * FFTPXARA / FTPXA;
    }
    
    function enforceMinHold(address sender, uint value) internal view returns (uint) {
        if (balances[sender] / piecesPerUnit - value < minHoldAmount && sender != liquidityAddress)
            value = balances[sender] / piecesPerUnit - minHoldAmount;
        return value;
    }
    
    function rewardTheoretical(uint id) public view returns (uint) {
        if (startTime[id] == 0) return 0;
        return rewardMax[id] - (rewardMax[id] - rewardsLastRewardChange[id]) * rewardConst[id] / (block.timestamp - startTime[id] + rewardConst[id] - timeFromInitToLastRewardChange[id]);
    }
    
    function changeRewardMax(uint id, uint newRewardMax) internal {
        if (startTime[id] > 0) {
            rewardsLastRewardChange[id] = rewardTheoretical(id);
            timeFromInitToLastRewardChange[id] = block.timestamp - startTime[id];
        }
        rewardMax[id] = newRewardMax;
    }
    
    function distributionCheck(address sender, address receiver, uint value) internal {
        if (hasReceivedPieces[receiver] == false && value >= distributionRewardThreshold && sender != liquidityAddress && receiver != liquidityAddress) {
            if (startTime[1] == 0)
                startTime[1] = block.timestamp;
            if (getAvailableRewards(1, msg.sender) > 0) withdrawRewards(1);
            emissionInit[1][msg.sender] = rewardTheoretical(1);
            rewardableEvents[1][sender] += 1;
            totalRewardableEvents[1] += 1;
            hasReceivedPieces[receiver] = true;
        }
    }
    
    function withdrawRewards(uint id) public {
        uint availableRewards = rewardableEvents[id][msg.sender] * (rewardTheoretical(id) - emissionInit[id][msg.sender]) / totalRewardableEvents[id];
        emissionInit[id][msg.sender] = rewardTheoretical(id);
        uint id2 = (id + 2) * 10;
        balances[msg.sender] += availableRewards - taxify(availableRewards, id2 + 1);
        balances[gamemaster] += taxify(availableRewards, id2 + 5);
        balances[address(this)] -= availableRewards - taxify(availableRewards, id2 + 2) - taxify(availableRewards, id2 + 3);
        for (uint i = 0; i < 2; i++) { changeRewardMax(id != i * 2 ? i * 2 : 1, rewardMax[id] + taxify(availableRewards, id2 + 2 + i)); }
        reflect(taxify(availableRewards, id2 + 4));
    }
    
    function withdrawAllRewards() public {
        if (getAvailableRewards(0, msg.sender) > 0) withdrawRewards(0);
        if (getAvailableRewards(1, msg.sender) > 0) withdrawRewards(1);
        if (getAvailableRewards(2, msg.sender) > 0) withdrawRewards(2);
        return;
    }
    
    function getAvailableRewards(uint id, address _address) public view returns (uint) {
        if (totalRewardableEvents[id] == 0 || rewardableEvents[id][_address] == 0) return 0;
        uint availableRewards = rewardableEvents[id][_address] * (rewardTheoretical(id) - emissionInit[id][_address]) / totalRewardableEvents[id];
        return (availableRewards - taxify(availableRewards, (id + 2) * 10 + 1)) / piecesPerUnit;
    }
    
    function getAllAvailableRewards(address _address) public view returns(uint, uint, uint, uint) {
        return (getAvailableRewards(0, _address), getAvailableRewards(1, _address), getAvailableRewards(2, _address), getAvailableRewards(0, _address) + getAvailableRewards(1, _address) + getAvailableRewards(2, _address));
    }
    
    function stake(uint amount) public {
        require(rewardableEvents[2][msg.sender] == 0, "staking position already exists");
        ERC20(liquidityAddress).transferFrom(msg.sender, address(this), amount);
        if (startTime[2] == 0)
            startTime[2] = block.timestamp;
        emissionInit[2][msg.sender] = rewardTheoretical(2);
        totalRewardableEvents[2] += amount;
        rewardableEvents[2][msg.sender] = amount;
    }
    
    function unstake() public {
        require(rewardableEvents[2][msg.sender] > 0, "no current staking position");
        if (getAvailableRewards(2, msg.sender) > 0) withdrawRewards(2);
        ERC20(liquidityAddress).transfer(msg.sender, rewardableEvents[2][msg.sender]);
        totalRewardableEvents[2] -= rewardableEvents[2][msg.sender];
        rewardableEvents[2][msg.sender] = 0;
    }
    
    function updatePosition(uint amount) public {
        unstake();
        stake(amount);
    }
    
    function adjustMarketMakerRewardableEvents(address _address, uint adjustmentAmount, bool buyOrSell) internal {
        if (!buyOrSell)
            totalBuyVolume[_address] += adjustmentAmount;
        if (buyOrSell)
            totalSellVolume[_address] += adjustmentAmount;
        uint totalBuySellVolumeDiff;
        if (totalSellVolume[_address] > totalBuyVolume[_address]) {
            totalBuySellVolumeDiff = totalSellVolume[_address] - totalBuyVolume[_address];
        }
        if (totalBuyVolume[_address] > totalSellVolume[_address]) {
            totalBuySellVolumeDiff = totalBuyVolume[_address] - totalSellVolume[_address];
        }
        uint balancedBuySellVolume = totalBuyVolume[_address] + totalSellVolume[_address] - totalBuySellVolumeDiff;
        if (balancedBuySellVolume > rewardableEvents[0][_address]) {
            uint eventDiff = balancedBuySellVolume - rewardableEvents[0][_address];
            if (startTime[0] == 0)
                startTime[0] = block.timestamp;
            if (getAvailableRewards(0, msg.sender) > 0) withdrawRewards(0);
            emissionInit[0][msg.sender] = rewardTheoretical(0);
            rewardableEvents[0][_address] += eventDiff;
            totalRewardableEvents[0] += eventDiff;
        } else if (rewardableEvents[0][_address] > balancedBuySellVolume) {
            uint eventDiff = rewardableEvents[0][_address] - balancedBuySellVolume;
            if (getAvailableRewards(0, msg.sender) > 0) withdrawRewards(0);
            emissionInit[0][msg.sender] = rewardTheoretical(0);
            rewardableEvents[0][_address] -= eventDiff;
            totalRewardableEvents[0] -= eventDiff;
        }
    }
    
    function changeMinHoldAmount(uint newMinHoldAmount) public {
        require(msg.sender == owner, "not owner");
        minHoldAmount = newMinHoldAmount;
    }
    
    function changeTaxDetail(uint id, uint value) public {
        require(msg.sender == owner, "not owner");
        tax[id] = value;
    }
    
    function changeRewardConstant(uint newRewardConstant, uint id) public {
        require(msg.sender == owner, "not owner");
        rewardConst[id] = newRewardConstant;
    }
    
    function changeLiquidityAddress(address newLiquidityAddress) public {
        require(msg.sender == owner, "not owner");
        liquidityAddress = newLiquidityAddress;
        for (uint i = 0; i < 3; i++) { rewardableEvents[i][liquidityAddress] = 0; }
    }
    
    function changeOwner(address newOwner) public {
        require(msg.sender == owner, "not owner");
        owner = newOwner;
    }
    
    function donate(uint id, uint value) public {
        uint pieceValue = value * piecesPerUnit;
        balances[msg.sender] -= pieceValue;
        balances[address(this)] += pieceValue;
        changeRewardMax(id, rewardMax[id] + pieceValue);
    }

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Tax(uint tokens);

}