pragma solidity ^0.4.19;

// copyright contact@emontalliance.com

contract BasicAccessControl {
    address public owner;
    // address[] public moderators;
    uint16 public totalModerators = 0;
    mapping (address => bool) public moderators;
    bool public isMaintaining = false;

    function BasicAccessControl() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyModerators() {
        require(msg.sender == owner || moderators[msg.sender] == true);
        _;
    }

    modifier isActive {
        require(!isMaintaining);
        _;
    }

    function ChangeOwner(address _newOwner) onlyOwner public {
        if (_newOwner != address(0)) {
            owner = _newOwner;
        }
    }


    function AddModerator(address _newModerator) onlyOwner public {
        if (moderators[_newModerator] == false) {
            moderators[_newModerator] = true;
            totalModerators += 1;
        }
    }
    
    function RemoveModerator(address _oldModerator) onlyOwner public {
        if (moderators[_oldModerator] == true) {
            moderators[_oldModerator] = false;
            totalModerators -= 1;
        }
    }

    function UpdateMaintaining(bool _isMaintaining) onlyOwner public {
        isMaintaining = _isMaintaining;
    }
}

contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
}


contract EmontFrenzy is BasicAccessControl {
    uint constant public HIGH = 20;
    uint constant public BASE_POS = 510;
    uint constant public ONE_EMONT = 10 ** 8;

    struct Fish {
        address player;
        uint weight;
        bool active; // location != 0
        uint blockNumber; // block number
    }

    // private
    uint private seed;

     // address
    address public tokenContract;
    
    // variable
    uint public addFee = 0.01 ether;
    uint public addWeight = 5 * 10 ** 8; // emont
    uint public addDrop = 5 * 10 ** 8; // emont
    uint public moveCharge = 5; // percentage
    uint public cashOutRate = 100; // to EMONT rate
    uint public cashInRate = 50; // from EMONT to fish weight 
    uint public width = 50;
    uint public minJump = 2 * 2;
    uint public maxPos = HIGH * width; // valid pos (0 -> maxPos - 1)
    uint public minCashout = 25 * 10 ** 8;
    uint public minEatable = 1 * 10 ** 8;
    uint public minWeightDeduct = 4 * 10 ** 8; // 0.2 EMONT
    
    uint public basePunish = 40000; // per block
    uint public oceanBonus = 125000; // per block
    uint public minWeightPunish = 1 * 10 ** 8;
    uint public maxWeightBonus = 25 * 10 ** 8;
    
    mapping(uint => Fish) fishMap;
    mapping(uint => uint) ocean; // pos => fish id
    mapping(uint => uint) bonus; // pos => emont amount
    mapping(address => uint) players;
    
    mapping(uint => uint) maxJumps; // weight in EMONT => square length
    
    uint public totalFish = 0;
    
    // event
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);

    event EventCashout(address indexed player, uint fishId, uint weight);
    event EventBonus(uint pos, uint value);
    event EventMove(address indexed player, uint fishId, uint fromPos, uint toPos, uint weight);
    event EventEat(address indexed player, address indexed defender, uint playerFishId, uint defenderFishId, uint fromPos, uint toPos, uint playerWeight);
    event EventFight(address indexed player, address indexed defender, uint playerFishId, uint defenderFishId, uint fromPos, uint toPos, uint playerWeight);
    event EventSuicide(address indexed player, address indexed defender, uint playerFishId, uint defenderFishId, uint fromPos, uint toPos, uint defenderWeight);
    
    
    // modifier
    modifier requireTokenContract {
        require(tokenContract != address(0));
        _;
    }
    
    function EmontFrenzy(address _tokenContract) public {
        tokenContract = _tokenContract;
        seed = getRandom(0);
    }
    
    function setRate(uint _moveCharge, uint _cashOutRate, uint _cashInRate) onlyModerators external {
        moveCharge = _moveCharge;
        cashOutRate = _cashOutRate;
        cashInRate = _cashInRate;
    }
    
    function setMaxConfig(uint _minWeightPunish, uint _maxWeightBonus) onlyModerators external {
        minWeightPunish = _minWeightPunish;
        maxWeightBonus = _maxWeightBonus;
    }
    
    function setConfig(uint _addFee, uint _addWeight, uint _addDrop,  uint _width) onlyModerators external {
        addFee = _addFee;
        addWeight = _addWeight;
        addDrop = _addDrop;
        width = _width;
        maxPos = HIGH * width;
    }
    
    function setExtraConfig(uint _minCashout, uint _minEatable, uint _minWeightDeduct, uint _basePunish, uint _oceanBonus) onlyModerators external {
        minCashout = _minCashout;
        minEatable = _minEatable;
        minWeightDeduct = _minWeightDeduct;
        basePunish = _basePunish;
        oceanBonus = _oceanBonus;
    }
    
    // weight in emont, x*x
    function updateMaxJump(uint _weight, uint _squareLength) onlyModerators external {
        maxJumps[_weight] = _squareLength;
    }
    
    function setDefaultMaxJump() onlyModerators external {
        maxJumps[0] = 50 * 50;
        maxJumps[1] = 30 * 30;
        maxJumps[2] = 20 * 20;
        maxJumps[3] = 15 * 15;
        maxJumps[4] = 12 * 12;
        maxJumps[5] = 9 * 9;
        maxJumps[6] = 7 * 7;
        maxJumps[7] = 7 * 7;
        maxJumps[8] = 6 * 6;
        maxJumps[9] = 6 * 6;
        maxJumps[10] = 6 * 6;
        maxJumps[11] = 5 * 5;
        maxJumps[12] = 5 * 5;
        maxJumps[13] = 5 * 5;
        maxJumps[14] = 5 * 5;
        maxJumps[15] = 4 * 4;
        maxJumps[16] = 4 * 4;
        maxJumps[17] = 4 * 4;
        maxJumps[18] = 4 * 4;
        maxJumps[19] = 4 * 4;
        maxJumps[20] = 3 * 3;
        maxJumps[21] = 3 * 3;
        maxJumps[22] = 3 * 3;
        maxJumps[23] = 3 * 3;
        maxJumps[24] = 3 * 3;
        maxJumps[25] = 3 * 3;
    }
    
    function updateMinJump(uint _minJump) onlyModerators external {
        minJump = _minJump;
    }
    
    // moderators
    
    function withdrawEther(address _sendTo, uint _amount) onlyModerators external {
        // no user money is kept in this contract, only trasaction fee
        if (_amount > address(this).balance) {
            revert();
        }
        _sendTo.transfer(_amount);
    }
    
    function withdrawToken(address _sendTo, uint _amount) onlyModerators requireTokenContract external {
        ERC20Interface token = ERC20Interface(tokenContract);
        if (_amount > token.balanceOf(address(this))) {
            revert();
        }
        token.transfer(_sendTo, _amount);
    }
    
    function addBonus(uint _pos, uint _amount) onlyModerators external {
        bonus[_pos] += _amount;
        EventBonus(_pos, _amount);
    }
    
    function refundFish(address _player, uint _weight) onlyModerators external {
         // max: one fish per address
        if (fishMap[players[_player]].weight > 0)
            revert();
        
        totalFish += 1;
        Fish storage fish = fishMap[totalFish];
        fish.player = _player;
        fish.weight = _weight;
        fish.active = false;
        fish.blockNumber = block.number;
        players[_player] = totalFish;
        
        seed = getRandom(seed);
        Transfer(address(0), _player, totalFish);
    }
    
    function cleanOcean(uint _pos1, uint _pos2, uint _pos3, uint _pos4, uint _pos5, uint _pos6, uint _pos7, uint _pos8, uint _pos9, uint _pos10) onlyModerators external {
        if (_pos1 > 0) {
            bonus[_pos1] = 0;
            EventBonus(_pos1, 0);
        }
        if (_pos2 > 0) {
            bonus[_pos2] = 0;
            EventBonus(_pos2, 0);
        }
        if (_pos3 > 0) {
            bonus[_pos3] = 0;
            EventBonus(_pos3, 0);
        }
        if (_pos4 > 0) {
            bonus[_pos4] = 0;
            EventBonus(_pos4, 0);
        }
        if (_pos5 > 0) {
            bonus[_pos5] = 0;
            EventBonus(_pos5, 0);
        }
        if (_pos6 > 0) {
            bonus[_pos6] = 0;
            EventBonus(_pos6, 0);
        }
        if (_pos7 > 0) {
            bonus[_pos7] = 0;
            EventBonus(_pos7, 0);
        }
        if (_pos8 > 0) {
            bonus[_pos8] = 0;
            EventBonus(_pos8, 0);
        }
        if (_pos9 > 0) {
            bonus[_pos9] = 0;
            EventBonus(_pos9, 0);
        }
        if (_pos10 > 0) {
            bonus[_pos10] = 0;
            EventBonus(_pos10, 0);
        }
    }
    
    // for payment contract to call
    function AddFishByToken(address _player, uint _tokens) onlyModerators external {
        uint weight = _tokens * cashInRate / 100;
        if (weight != addWeight) 
            revert();
        
         // max: one fish per address
        if (fishMap[players[_player]].weight > 0)
            revert();
        
        totalFish += 1;
        Fish storage fish = fishMap[totalFish];
        fish.player = _player;
        fish.weight = addWeight;
        fish.active = false;
        fish.blockNumber = block.number;
        players[_player] = totalFish;
        
        // airdrop
        if (addDrop > 0) {
            seed = getRandom(seed);
            uint temp = seed % (maxPos - 1);
            if (temp == BASE_POS) temp += 1;
            bonus[temp] += addDrop;
            EventBonus(temp, bonus[temp]);
        } else {
            seed = getRandom(seed);
        }
        Transfer(address(0), _player, totalFish);
    }
    
    // public functions
    function getRandom(uint _seed) constant public returns(uint) {
        return uint(keccak256(block.timestamp, block.difficulty)) ^ _seed;
    }
    
    function AddFish() isActive payable external {
        if (msg.value != addFee) revert();
        
        // max: one fish per address
        if (fishMap[players[msg.sender]].weight > 0)
            revert();
        
        totalFish += 1;
        Fish storage fish = fishMap[totalFish];
        fish.player = msg.sender;
        fish.weight = addWeight;
        fish.active = false;
        fish.blockNumber = block.number;
        players[msg.sender] = totalFish;
        
        // airdrop
        if (addDrop > 0) {
            seed = getRandom(seed);
            uint temp = seed % (maxPos - 1);
            if (temp == BASE_POS) temp += 1;
            bonus[temp] += addDrop;
            EventBonus(temp, bonus[temp]);
        } else {
            seed = getRandom(seed);
        }
        Transfer(address(0), msg.sender, totalFish);
    }
    
    function DeductABS(uint _a, uint _b) pure public returns(uint) {
        if (_a > _b) 
            return (_a - _b);
        return (_b - _a);
    }
    
    function SafeDeduct(uint _a, uint _b) pure public returns(uint) {
        if (_a > _b)
            return (_a - _b);
        return 0;
    }
    
    function MoveFromBase(uint _toPos) isActive external {
        // from = 0
        if (_toPos >= maxPos || _toPos == 0)
            revert();
        
        uint fishId = players[msg.sender];
        Fish storage fish = fishMap[fishId];
        if (fish.weight == 0)
            revert();
        // not from base
        if (fish.active)
            revert();
        
        // deduct weight
        if (fish.weight > minWeightPunish) {
            uint tempX = SafeDeduct(block.number, fish.blockNumber);
            tempX = SafeDeduct(fish.weight, tempX * basePunish);
            if (tempX < minWeightPunish) {
                fish.weight = minWeightPunish;
            } else {
                fish.weight = tempX;
            }
        }
        
        // check valid move
        tempX = DeductABS(BASE_POS / HIGH, _toPos / HIGH);
        uint tempY = DeductABS(BASE_POS % HIGH, _toPos % HIGH);
        uint squareLength = maxJumps[fish.weight / ONE_EMONT];
        if (squareLength == 0) squareLength = minJump;
        if (tempX * tempX + tempY * tempY > squareLength)
            revert();
        
        // can not attack
        if (ocean[_toPos] > 0)
            revert();
            
        // check target bonus 
        if (bonus[_toPos] > 0) {
            fish.weight += bonus[_toPos];
            bonus[_toPos] = 0;
        }
        
        fish.active = true;
        fish.blockNumber = block.number;
        ocean[_toPos] = fishId;
        EventMove(msg.sender, fishId, BASE_POS, _toPos, fish.weight);
    }
    
    function MoveToBase(uint _fromPos) isActive external {
        uint fishId = players[msg.sender];
        Fish storage fish = fishMap[fishId];
        if (fish.weight == 0)
            revert();
        if (!fish.active || ocean[_fromPos] != fishId)
            revert();
        
        // check valid move
        uint tempX = DeductABS(_fromPos / HIGH, BASE_POS / HIGH);
        uint tempY = DeductABS(_fromPos % HIGH, BASE_POS % HIGH);
        uint squareLength = maxJumps[fish.weight / ONE_EMONT];
        if (squareLength == 0) squareLength = minJump;
        if (tempX * tempX + tempY * tempY > squareLength)
            revert();
        
        if (fish.weight >= minWeightDeduct) {
            tempX = (moveCharge * fish.weight) / 100;
            bonus[_fromPos] += tempX;
            fish.weight -= tempX;
        }
        
        // add bonus
        if (fish.weight < maxWeightBonus) {
            uint temp = SafeDeduct(block.number, fish.blockNumber) * oceanBonus;
            if (fish.weight + temp > maxWeightBonus) {
                fish.weight = maxWeightBonus;
            } else {
                fish.weight += temp;
            }
        }
        
        ocean[_fromPos] = 0;
        fish.active = false;
        fish.blockNumber = block.number;
        EventMove(msg.sender, fishId, _fromPos, BASE_POS, fish.weight);
        return;
    }
    
    function MoveFish(uint _fromPos, uint _toPos) isActive external {
        // check valid _x, _y
        if (_toPos >= maxPos && _fromPos != _toPos)
            revert();
        if (_fromPos == BASE_POS || _toPos == BASE_POS)
            revert();
        
        uint fishId = players[msg.sender];
        Fish storage fish = fishMap[fishId];
        if (fish.weight == 0)
            revert();
        if (!fish.active || ocean[_fromPos] != fishId)
            revert();
        
        // check valid move
        uint tempX = DeductABS(_fromPos / HIGH, _toPos / HIGH);
        uint tempY = DeductABS(_fromPos % HIGH, _toPos % HIGH);
        uint squareLength = maxJumps[fish.weight / ONE_EMONT];
        if (squareLength == 0) squareLength = minJump;
        
        if (tempX * tempX + tempY * tempY > squareLength)
            revert();
        
        // move 
        ocean[_fromPos] = 0;
        if (fish.weight >= minWeightDeduct) {
            tempX = (moveCharge * fish.weight) / 100;
            bonus[_fromPos] += tempX;
            fish.weight -= tempX;
        }

        tempX = ocean[_toPos]; // target fish id
        // no fish at that location
        if (tempX == 0) {
            if (bonus[_toPos] > 0) {
                fish.weight += bonus[_toPos];
                bonus[_toPos] = 0;
            }
            
            // update location
            EventMove(msg.sender, fishId, _fromPos, _toPos, fish.weight);
            ocean[_toPos] = fishId;
        } else {
            Fish storage targetFish = fishMap[tempX];
            if (targetFish.weight + minEatable <= fish.weight) {
                // eat the target fish
                fish.weight += targetFish.weight;
                targetFish.weight = 0;
                
                // update location
                ocean[_toPos] = fishId;
                
                EventEat(msg.sender, targetFish.player, fishId, tempX, _fromPos, _toPos, fish.weight);
                Transfer(targetFish.player, address(0), tempX);
            } else if (targetFish.weight <= fish.weight) {
                // fight and win
                // bonus to others
                seed = getRandom(seed);
                tempY = seed % (maxPos - 1);
                if (tempY == BASE_POS) tempY += 1;
                bonus[tempY] += targetFish.weight * 2;
                
                EventBonus(tempY, bonus[tempY]);
                
                // fight 
                fish.weight -= targetFish.weight;
                targetFish.weight = 0;
                
                // update location
                if (fish.weight > 0) {
                    ocean[_toPos] = fishId;
                } else {
                    ocean[_toPos] = 0;
                    Transfer(msg.sender, address(0), fishId);
                }
                
                EventFight(msg.sender, targetFish.player, fishId, tempX, _fromPos, _toPos, fish.weight);
                Transfer(targetFish.player, address(0), tempX);
            } else {
                // bonus to others
                seed = getRandom(seed);
                tempY = seed % (maxPos - 1);
                if (tempY == BASE_POS) tempY += 1;
                bonus[tempY] += fish.weight * 2;
                
                EventBonus(tempY, bonus[tempY]);
                
                // suicide
                targetFish.weight -= fish.weight;
                fish.weight = 0;
                
                EventSuicide(msg.sender, targetFish.player, fishId, tempX, _fromPos, _toPos, targetFish.weight);
                Transfer(msg.sender, address(0), fishId);
            }
        }
    }
    
    function CashOut() isActive external {
        uint fishId = players[msg.sender];
        Fish storage fish = fishMap[fishId];
        
        // if fish at base, need to deduct 
        if (!fish.active) {
            // deduct weight
            if (fish.weight > minWeightPunish) {
                uint tempX = SafeDeduct(block.number, fish.blockNumber);
                tempX = SafeDeduct(fish.weight, tempX * basePunish);
                if (tempX < minWeightPunish) {
                    fish.weight = minWeightPunish;
                } else {
                    fish.weight = tempX;
                }
            }
            fish.blockNumber = block.number;
        }
        
        if (fish.weight < minCashout)
            revert();
        
        if (fish.weight < addWeight) 
            revert();
        
        uint _amount = fish.weight - addWeight;
        fish.weight = addWeight;
        
        ERC20Interface token = ERC20Interface(tokenContract);
        if (_amount > token.balanceOf(address(this))) {
            revert();
        }
        token.transfer(msg.sender, (_amount * cashOutRate) / 100);
        EventCashout(msg.sender, fishId, fish.weight);
    }
    
    // public get 
    function getFish(uint32 _fishId) constant public returns(address player, uint weight, bool active, uint blockNumber) {
        Fish storage fish = fishMap[_fishId];
        return (fish.player, fish.weight, fish.active, fish.blockNumber);
    }
    
    function getFishByAddress(address _player) constant public returns(uint fishId, address player, uint weight, bool active, uint blockNumber) {
        fishId = players[_player];
        Fish storage fish = fishMap[fishId];
        player = fish.player;
        weight =fish.weight;
        active = fish.active;
        blockNumber = fish.blockNumber;
    }
    
    function getFishIdByAddress(address _player) constant public returns(uint fishId) {
        return players[_player];
    }
    
    function getFishIdByPos(uint _pos) constant public returns(uint fishId) {
        return ocean[_pos];
    }
    
    function getFishByPos(uint _pos) constant public returns(uint fishId, address player, uint weight, uint blockNumber) {
        fishId = ocean[_pos];
        Fish storage fish = fishMap[fishId];
        return (fishId, fish.player, fish.weight, fish.blockNumber);
    }
    
    // cell has valid fish or bonus
    function getActiveFish(uint _fromPos, uint _toPos) constant public returns(uint pos, uint fishId, address player, uint weight, uint blockNumber) {
        for (uint index = _fromPos; index <= _toPos; index+=1) {
            if (ocean[index] > 0) {
                fishId = ocean[index];
                Fish storage fish = fishMap[fishId];
                return (index, fishId, fish.player, fish.weight, fish.blockNumber);
            }
        }
    }
    
    function getAllBonus(uint _fromPos, uint _toPos) constant public returns(uint pos, uint amount) {
        for (uint index = _fromPos; index <= _toPos; index+=1) {
            if (bonus[index] > 0) {
                return (index, bonus[index]);
            }
        }
    }
    
    function getStats() constant public returns(uint countFish, uint countBonus) {
        countFish = 0;
        countBonus = 0;
        for (uint index = 0; index < width * HIGH; index++) {
            if (ocean[index] > 0) {
                countFish += 1; 
            }
            if (bonus[index] > 0) {
                countBonus += 1;
            }
        }
    }
    
    function getFishAtBase(uint _fishId) constant public returns(uint fishId, address player, uint weight, uint blockNumber) {
        for (uint id = _fishId; id <= totalFish; id++) {
            Fish storage fish = fishMap[id];
            if (fish.weight > 0 && !fish.active) {
                return (id, fish.player, fish.weight, fish.blockNumber);
            }
        }
        
        return (0, address(0), 0, 0);
    }
    
    function countFishAtBase() constant public returns(uint count) {
        count = 0;
        for (uint id = 0; id <= totalFish; id++) {
            Fish storage fish = fishMap[id];
            if (fish.weight > 0 && !fish.active) {
                count += 1; 
            }
        }
    }
    
    function getMaxJump(uint _weight) constant public returns(uint) {
        return maxJumps[_weight];
    }
    
    // some meta data
    string public constant name = "EmontFrenzy";
    string public constant symbol = "EMONF";

    function totalSupply() public view returns (uint256) {
        return totalFish;
    }
    
    function balanceOf(address _owner) public view returns (uint256 _balance) {
        if (fishMap[players[_owner]].weight > 0)
            return 1;
        return 0;
    }
    
    function ownerOf(uint256 _tokenId) public view returns (address _owner) {
        Fish storage fish = fishMap[_tokenId];
        if (fish.weight > 0)
            return fish.player;
        return address(0);
    }
    
    function transfer(address _to, uint256 _tokenId) public{
        require(_to != address(0));
        
        uint fishId = players[msg.sender];
        Fish storage fish = fishMap[fishId];
        if (fishId == 0 || fish.weight == 0 || fishId != _tokenId)
            revert();
        
        if (balanceOf(_to) > 0)
            revert();
        
        fish.player = _to;
        players[msg.sender] = 0;
        players[_to] = fishId;
        
        Transfer(msg.sender, _to, _tokenId);
    }
    
}