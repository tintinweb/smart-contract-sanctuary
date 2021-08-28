/**
 *Submitted for verification at BscScan.com on 2021-08-28
*/

// SPDX-License-Identifier: 0BSD

pragma solidity ^0.8.7;

interface ERC20 {
    function transfer(address to, uint tokens) external;
    function transferFrom(address from, address to, uint tokens) external;
}

contract TangleV2 {

    uint8 public decimals;
    uint public totalSupply;
    string public name;
    string public symbol;
    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint)) private allowed;

    bool public disableGame = false;
    address public gamemaster;
    address public owner;
    address public liquidityAddress;
    uint public totalPieces;
    uint public piecesPerUnit;
    uint public minHoldAmount;
    uint public workaroundConstant = 1;
    uint public distributionRewardThreshold;
    uint public marketMakingRewardThreshold;
    mapping(uint => uint) public S;
    mapping(uint => uint) public tax;
    mapping(uint => uint) public rewardMax;
    mapping(uint => uint) public startTime;
    mapping(uint => uint) public rewardConst;
    mapping(uint => uint) public totalRewardableEvents;
    mapping(uint => uint) public lastRewardDistribution;
    mapping(uint => uint) public rewardsLastRewardChange;
    mapping(uint => uint) public timeFromInitToLastRewardChange;
    mapping(address => bool) public hasReceivedPieces;
    mapping(address => mapping(uint => uint)) public Si;
    mapping(address => mapping(uint => uint)) public WCi;
    mapping(address => mapping(uint => uint)) public storedRewards;
    mapping(address => mapping(uint => uint)) public rewardableEvents;

    constructor() {
        name = "TangleV2";
        symbol = "TNGLv2";
        decimals = 9;
        totalSupply = 1e9 * 1*10**(decimals);
        totalPieces = type(uint128).max - (type(uint128).max % totalSupply);
        piecesPerUnit = totalPieces / totalSupply;
        balances[msg.sender] = totalPieces;
        gamemaster = msg.sender;
        owner = msg.sender;
        minHoldAmount = 1;
        distributionRewardThreshold = 1e9;
        marketMakingRewardThreshold = 1e9;

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

    function approve(address spender, uint256 value) public returns (bool) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
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

    function transfer(address to, uint256 value) public returns (bool) {
        if (value > balances[msg.sender] / piecesPerUnit) revert();
        value = enforceMinHold(msg.sender, value);
        uint pieceValue = value * piecesPerUnit;
        balances[msg.sender] -= pieceValue;
        if (msg.sender == owner || disableGame) {
            balances[to] += pieceValue;
            emit Transfer(msg.sender, to, value);
            return true;
        }
        balances[to] += pieceValue - taxify(pieceValue, 10);
        balances[address(this)] += taxify(pieceValue, 20) + taxify(pieceValue, 30) + taxify(pieceValue, 40);
        balances[gamemaster] += taxify(pieceValue, 60);
        for (uint i = 0; i < 3; i++) { changeRewardMax(i, rewardMax[i] + taxify(pieceValue, 20 + i * 10)); }
        reflect(taxify(pieceValue, 50));
        if (msg.sender != owner && msg.sender != gamemaster && to != owner && to != gamemaster) {
            if (msg.sender != liquidityAddress && to != liquidityAddress) distributorCheck(msg.sender, to, value);
            marketMakerCheck(msg.sender, to, value);
        }
        emit Transfer(msg.sender, to, value - taxify(value, 10));
        emit Transfer(msg.sender, address(this), taxify(value, 20) + taxify(value, 30) + taxify(value, 40));
        emit Transfer(msg.sender, gamemaster, taxify(value, 60));
        emit ReflectEvent(msg.sender, taxify(value, 50));
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        if (value > balances[from] / piecesPerUnit) revert();
        value = enforceMinHold(from, value);
        allowed[from][msg.sender] = allowed[from][msg.sender] - value;
        uint pieceValue = value * piecesPerUnit;
        balances[from] -= pieceValue;
        if (from == owner || disableGame) {
            balances[to] += pieceValue;
            emit Transfer(from, to, value);
            return true;
        }
        balances[to] += pieceValue - taxify(pieceValue, 10);
        balances[address(this)] += taxify(pieceValue, 20) + taxify(pieceValue, 30) + taxify(pieceValue, 40);
        balances[gamemaster] += taxify(pieceValue, 60);
        for (uint i = 0; i < 3; i++) { changeRewardMax(i, rewardMax[i] + taxify(pieceValue, 20 + i * 10)); }
        reflect(taxify(pieceValue, 50));
        if (from != owner && from != gamemaster && to != owner && to != gamemaster) {
            if (from != liquidityAddress && to != liquidityAddress) distributorCheck(from, to, value);
            marketMakerCheck(from, to, value);
        }
        emit Transfer(from, to, value - taxify(value, 10));
        emit Transfer(from, address(this), taxify(value, 20) + taxify(value, 30) + taxify(value, 40));
        emit Transfer(from, gamemaster, taxify(value, 60));
        emit ReflectEvent(from, taxify(value, 50));
        return true;
    }
    
    function cropDust(address[] memory addresses) public {
        for (uint i = 0; i < addresses.length; i++) {
            balances[addresses[i]] += distributionRewardThreshold * piecesPerUnit;
            emit Transfer(msg.sender, addresses[i], distributionRewardThreshold);
        }
        balances[msg.sender] -= distributionRewardThreshold * piecesPerUnit * addresses.length;
        if (startTime[1] == 0) startTime[1] = block.timestamp;
        distribute(1);
        if (getAvailableRewards(msg.sender, 1) > 0) storedRewards[msg.sender][1] = getAvailableRewards(msg.sender, 1) * piecesPerUnit;
        Si[msg.sender][1] = S[1];
        WCi[msg.sender][1] = workaroundConstant;
        rewardableEvents[msg.sender][1] += addresses.length;
        totalRewardableEvents[1] += addresses.length;
    }

    function enforceMinHold(address sender, uint value) internal view returns (uint) {
        if (balances[sender] / piecesPerUnit - value < minHoldAmount && sender != liquidityAddress)
            value = balances[sender] / piecesPerUnit - minHoldAmount;
        return value;
    }

    function taxify(uint value, uint id) internal view returns (uint) {
        return value * tax[id * 10] / tax[id * 10 + 1];
    }

    function changeRewardMax(uint id, uint newRewardMax) internal {
        if (startTime[id] > 0) {
            rewardsLastRewardChange[id] = rewardTheoretical(id);
            timeFromInitToLastRewardChange[id] = block.timestamp - startTime[id];
        }
        rewardMax[id] = newRewardMax;
    }

    function rewardTheoretical(uint id) public view returns (uint) {
        if (startTime[id] == 0) return 0;
        return rewardMax[id] - (rewardMax[id] - rewardsLastRewardChange[id]) * rewardConst[id] / (block.timestamp - startTime[id] + rewardConst[id] - timeFromInitToLastRewardChange[id]);
    }

    function reflect(uint reflectAmount) internal {
        uint FTPXA = totalSupply * piecesPerUnit - balances[liquidityAddress];
        uint FFTPXARA = FTPXA - reflectAmount;
        piecesPerUnit = piecesPerUnit * FFTPXARA / FTPXA;
        if (piecesPerUnit < 1)
            piecesPerUnit = 1;
        balances[liquidityAddress] = balances[liquidityAddress] * FFTPXARA / FTPXA;
    }

    function distributorCheck(address sender, address receiver, uint value) internal {
        if (hasReceivedPieces[receiver] == false && value >= distributionRewardThreshold) {
            addRewardableEvents(sender, 1);
            hasReceivedPieces[receiver] = true;
        }
    }
    
    function marketMakerCheck(address sender, address receiver, uint value) internal {
        if (value >= marketMakingRewardThreshold) {
            if (sender == liquidityAddress) addRewardableEvents(receiver, 0);
            if (receiver == liquidityAddress) addRewardableEvents(sender, 0);
        }
    }
    
    function addRewardableEvents(address recipient, uint id)  internal {
        if (startTime[id] == 0) startTime[id] = block.timestamp;
        distribute(id);
        if (getAvailableRewards(recipient, id) > 0) storedRewards[recipient][id] = getAvailableRewards(recipient, id) * piecesPerUnit;
        Si[recipient][id] = S[id];
        WCi[recipient][id] = workaroundConstant;
        rewardableEvents[recipient][id] += 1;
        totalRewardableEvents[id] += 1;
    }

    function distribute(uint id) internal {
        if (totalRewardableEvents[id] != 0 && lastRewardDistribution[id] != rewardTheoretical(id)) {
            uint addedReward = rewardTheoretical(id) - lastRewardDistribution[id];
            while (addedReward > 0 && addedReward * workaroundConstant / totalRewardableEvents[id] < 1e9) {
                workaroundConstant *= 2;
                for (uint i; i < 3; i++) S[i] *= 2;
            }
            S[id] += addedReward * workaroundConstant / totalRewardableEvents[id];
            lastRewardDistribution[id] = rewardTheoretical(id);
        }
    }

    function getAvailableRewards(address _address, uint id) public view returns (uint) {
        if (WCi[_address][id] == 0) return 0;
        uint _workaroundConstant = workaroundConstant;
        uint _S = S[id];
        if (totalRewardableEvents[id] != 0 && lastRewardDistribution[id] != rewardTheoretical(id)) {
            uint addedReward = rewardTheoretical(id) - lastRewardDistribution[id];
            while (addedReward > 0 && addedReward * _workaroundConstant / totalRewardableEvents[id] < 1e9) {
                _workaroundConstant *= 2;
                _S *= 2;
            }
            _S += addedReward * _workaroundConstant / totalRewardableEvents[id];
        }
        uint availableRewards = storedRewards[_address][id] + rewardableEvents[_address][id] * (_S - Si[_address][id] * _workaroundConstant / WCi[_address][id]) / _workaroundConstant;
        return availableRewards / piecesPerUnit;
    }

    function getAllAvailableRewards(address _address) public view returns(uint, uint, uint, uint) {
        return (getAvailableRewards(_address, 0), getAvailableRewards(_address, 1), getAvailableRewards(_address, 2), getAvailableRewards(_address, 0) + getAvailableRewards(_address, 1) + getAvailableRewards(_address, 2));
    }

    function withdrawRewards(address _address, uint id) public {
        distribute(id);
        if (WCi[_address][id] == 0) return;
        uint availableRewards = storedRewards[_address][id] + rewardableEvents[_address][id] * (S[id] - Si[_address][id] * workaroundConstant / WCi[_address][id]) / workaroundConstant;
        storedRewards[_address][id] = 0;
        Si[_address][id] = S[id];
        WCi[_address][id] = workaroundConstant;
        uint id2 = (id + 2) * 10;
        balances[_address] += availableRewards - taxify(availableRewards, id2 + 1);
        balances[gamemaster] += taxify(availableRewards, id2 + 5);
        balances[address(this)] -= availableRewards - taxify(availableRewards, id2 + 2) - taxify(availableRewards, id2 + 3);
        for (uint i = 0; i < 2; i++) { changeRewardMax(id != i * 2 ? i * 2 : 1, rewardMax[id] + taxify(availableRewards, id2 + 2 + i)); }
        reflect(taxify(availableRewards, id2 + 4));
        emit Transfer(address(this), _address, (availableRewards - taxify(availableRewards, id2 + 1)) / piecesPerUnit);
        emit Transfer(address(this), gamemaster, taxify(availableRewards, id2 + 5) / piecesPerUnit);
        emit ReflectEvent(address(this), taxify(availableRewards, id2 + 4) / piecesPerUnit);
    }

    function withdrawAllRewards(address _address) public {
        for (uint i = 0; i < 3; i++) { if (getAvailableRewards(_address, i) > 0) withdrawRewards(_address, i); }
    }
    
    function stake(uint amount) public {
        require(rewardableEvents[msg.sender][2] == 0, "staking position already exists");
        ERC20(liquidityAddress).transferFrom(msg.sender, address(this), amount);
        if (startTime[2] == 0) startTime[2] = block.timestamp;
        distribute(2);
        if (getAvailableRewards(msg.sender, 2) > 0) storedRewards[msg.sender][2] = getAvailableRewards(msg.sender, 2) * piecesPerUnit;
        Si[msg.sender][2] = S[2];
        WCi[msg.sender][2] = workaroundConstant;
        rewardableEvents[msg.sender][2] += amount;
        totalRewardableEvents[2] += amount;
    }
    
    function unstake() public {
        require(rewardableEvents[msg.sender][2] > 0, "no current staking position");
        distribute(2);
        if (getAvailableRewards(msg.sender, 2) > 0) storedRewards[msg.sender][2] = getAvailableRewards(msg.sender, 2) * piecesPerUnit;
        ERC20(liquidityAddress).transfer(msg.sender, rewardableEvents[msg.sender][2]);
        totalRewardableEvents[2] -= rewardableEvents[msg.sender][2];
        rewardableEvents[msg.sender][2] = 0;
    }
    
    function updatePosition(uint amount) public {
        unstake();
        stake(amount);
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
        for (uint i = 0; i < 3; i++) { rewardableEvents[liquidityAddress][i] = 0; }
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
    
    function changeDisableGame(bool newDisableGame) public {
        require(msg.sender == owner, "not owner");
        disableGame = newDisableGame;
    }

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event ReflectEvent(address indexed from, uint tokens);

}