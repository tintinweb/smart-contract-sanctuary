pragma solidity ^0.4.19;

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
    }

    // private
    uint private seed;

     // address
    address public tokenContract;
    
    // variable
    uint public addFee = 0.01 ether;
    uint public addWeight = 5 * 10 ** 8; // emont
    uint public moveCharge = 5; // percentage
    uint public cashOutRate = 100; // to EMONT rate
    uint public cashInRate = 50; // from EMONT to fish weight 
    uint public width = 50;
    uint public minJump = 2 * 2;
    uint public maxPos = HIGH * width; // valid pos (0 -> maxPos - 1)
    
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
    
    function setConfig(uint _addFee, uint _addWeight, uint _moveCharge, uint _cashOutRate, uint _cashInRate, uint _width) onlyModerators external {
        addFee = _addFee;
        addWeight = _addWeight;
        moveCharge = _moveCharge;
        cashOutRate = _cashOutRate;
        cashInRate = _cashInRate;
        width = _width;
        maxPos = HIGH * width;
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
    
    // for payment contract to call
    function AddFishByToken(address _player, uint tokens) onlyModerators external {
        uint weight = tokens * cashInRate / 100;
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
        players[_player] = totalFish;
        
        seed = getRandom(seed);
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
        players[msg.sender] = totalFish;
        
        seed = getRandom(seed);
        Transfer(address(0), msg.sender, totalFish);
    }
    
    function DeductABS(uint _a, uint _b) pure public returns(uint) {
        if (_a > _b) 
            return (_a - _b);
        return (_b - _a);
    }
    
    function MoveFish(uint _fromPos, uint _toPos) isActive external {
        // check valid _x, _y
        if (_toPos >= maxPos && _fromPos != _toPos)
            revert();
        
        uint fishId = players[msg.sender];
        Fish storage fish = fishMap[fishId];
        if (fish.weight == 0)
            revert();
        if (!fish.active && _fromPos != BASE_POS)
            revert();
        if (fish.active && ocean[_fromPos] != fishId)
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
        // charge when swiming except from the base
        if (_fromPos != BASE_POS) {
            tempX = (moveCharge * fish.weight) / 100;
            bonus[_fromPos] += tempX;
            fish.weight -= tempX;
        } else {
            fish.active = true;
        }

        // go back to base
        if (_toPos == BASE_POS) {
            fish.active = false;
            EventMove(msg.sender, fishId, _fromPos, _toPos, fish.weight);
            return;
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
            // can not attack from the base
            if (_fromPos == BASE_POS) revert();
            
            Fish storage targetFish = fishMap[tempX];
            if (targetFish.weight <= fish.weight) {
                // eat the target fish
                fish.weight += targetFish.weight;
                targetFish.weight = 0;
                
                // update location
                ocean[_toPos] = fishId;
                
                EventEat(msg.sender, targetFish.player, fishId, tempX, _fromPos, _toPos, fish.weight);
                Transfer(targetFish.player, address(0), tempX);
            } else {
                // bonus to others
                seed = getRandom(seed);
                tempY = seed % (maxPos - 1);
                if (tempY == BASE_POS) tempY += 1;
                bonus[tempY] = fish.weight * 2;
                
                EventBonus(tempY, fish.weight * 2);
                
                // suicide
                targetFish.weight -= fish.weight;
                fish.weight = 0;
                
                EventSuicide(msg.sender, targetFish.player, fishId, tempX, _fromPos, _toPos, targetFish.weight);
                Transfer(msg.sender, address(0), fishId);
            }
        }
    }
    
    function CashOut(uint _amount) isActive external {
        uint fishId = players[msg.sender];
        Fish storage fish = fishMap[fishId];
        
        if (fish.weight < _amount + addWeight) 
            revert();
        
        fish.weight -= _amount;
        
        ERC20Interface token = ERC20Interface(tokenContract);
        if (_amount > token.balanceOf(address(this))) {
            revert();
        }
        token.transfer(msg.sender, (_amount * cashOutRate) / 100);
        EventCashout(msg.sender, fishId, fish.weight);
    }
    
    // public get 
    function getFish(uint32 _fishId) constant public returns(address player, uint weight, bool active) {
        Fish storage fish = fishMap[_fishId];
        return (fish.player, fish.weight, fish.active);
    }
    
    function getFishByAddress(address _player) constant public returns(uint fishId, address player, uint weight, bool active) {
        fishId = players[_player];
        Fish storage fish = fishMap[fishId];
        player = fish.player;
        weight =fish.weight;
        active = fish.active;
    }
    
    function getFishIdByAddress(address _player) constant public returns(uint fishId) {
        return players[_player];
    }
    
    function getFishIdByPos(uint _pos) constant public returns(uint fishId) {
        return ocean[_pos];
    }
    
    function getFishByPos(uint _pos) constant public returns(uint fishId, address player, uint weight) {
        fishId = ocean[_pos];
        Fish storage fish = fishMap[fishId];
        return (fishId, fish.player, fish.weight);
    }
    
    // cell has valid fish or bonus
    function findTargetCell(uint _fromPos, uint _toPos) constant public returns(uint pos, uint fishId, address player, uint weight) {
        for (uint index = _fromPos; index <= _toPos; index+=1) {
            if (ocean[index] > 0) {
                fishId = ocean[index];
                Fish storage fish = fishMap[fishId];
                return (index, fishId, fish.player, fish.weight);
            }
            if (bonus[index] > 0) {
                return (index, 0, address(0), bonus[index]);
            }
        }
    }
    
    function getStats() constant public returns(uint countFish, uint countBonus) {
        countFish = 0;
        countBonus = 0;
        for (uint index = 0; index < width * HIGH; index++) {
            if (ocean[index] > 0) {
                countFish += 1; 
            } else if (bonus[index] > 0) {
                countBonus += 1;
            }
        }
    }
    
    function getFishAtBase(uint _fishId) constant public returns(uint fishId, address player, uint weight) {
        for (uint id = _fishId; id <= totalFish; id++) {
            Fish storage fish = fishMap[id];
            if (fish.weight > 0 && !fish.active) {
                return (id, fish.player, fish.weight);
            }
        }
        
        return (0, address(0), 0);
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