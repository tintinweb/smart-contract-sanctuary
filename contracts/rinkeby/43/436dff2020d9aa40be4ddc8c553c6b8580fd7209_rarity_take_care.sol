/**
 *Submitted for verification at Etherscan.io on 2021-09-29
*/

pragma solidity 0.8.7;
// SPDX-License-Identifier: MIT
interface adventurable {
    function adventure(uint) external;
    function adventurers_log(uint) external view returns (uint);
}

interface rarity_gold {
    function claim(uint) external;
    function claimable(uint) external view returns (uint);
    function balanceOf(uint) external view returns (uint);
    function claimed(uint) external view returns (uint);
    function allowance(uint, uint) external view returns (uint);
    function wealth_by_level(uint) external pure returns (uint);
    function approve(uint, uint, uint) external returns (bool);
    function transfer(uint, uint, uint) external returns (bool);
    
}

interface rarity_cellar is adventurable {
    function scout(uint) external view returns (uint);
    function allowance(uint, uint) external view returns (uint);
    function balanceOf(uint) external view returns (uint);
    function transfer(uint, uint, uint) view external returns(bool);
    function approve(uint, uint, uint) external returns (bool);
    function transferFrom(uint, uint, uint, uint) external returns (bool);
}

interface rarity_manifested is adventurable {
    function summon(uint) external;
    function next_summoner() external view returns (uint);
    function level_up(uint) external;
    function approve(address, uint256) external;
    function getApproved(uint256) external view returns (address);
    function ownerOf(uint) external view returns (address);
    function xp_required(uint) external pure returns (uint);
    function level(uint) external view returns (uint);
    function xp(uint) external view returns (uint);
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

contract rarity_take_care {
    rarity_manifested constant rm = rarity_manifested(0xB4A44ccb5E342bcb4aA83ff379E826E9B79beb15);
    rarity_gold constant       gold = rarity_gold(0x50b7A32312a6B4714c521509E43c1cbC103Ae344);
    rarity_cellar constant     cellar = rarity_cellar(0xA0f99C6075D9d2f526F8B2c2d1CD8b9A25d6Eb9d);
    
    mapping(address => mapping(uint256 => uint256)) ownedSummoners;
    mapping(address => uint) balanceOf;
    
    event Adventure(address owner, uint count);
    event Cellar(address owner, uint count);
    event ClaimGold(address owner, uint count, uint claimed);
    event TransferredGold(address owner, uint256 to, uint count, uint transferred);
    event LeveledUp(address owner, uint count);
    
    function send_summoners(uint256[] memory ids) external {
        for (uint i = 0; i < ids.length; i++){
            require(rm.ownerOf(ids[i]) != address(this), 'Invalid summoner!');
            rm.transferFrom(msg.sender, address(this), ids[i]);
            uint next = balanceOf[msg.sender];
            ownedSummoners[msg.sender][next] = ids[i];
            balanceOf[msg.sender]++;
        }
    }
    
    function summon_for_me(uint class, uint count) external {
        for (uint i = 0; i < count; i++) {
            uint nextSummoner = rm.next_summoner();
            rm.summon(class);
            uint next = balanceOf[msg.sender];
            ownedSummoners[msg.sender][next] = nextSummoner;
            balanceOf[msg.sender]++;
        }
    }
    
    function adventure_all() external returns (uint count){
        count = 0;
        require(balanceOf[msg.sender] > 0, "No summoners onwed!");
        for (uint i = 0; i < balanceOf[msg.sender]; i++){
            uint id = ownedSummoners[msg.sender][i];
            if (_can_adventure(id)){
                rm.adventure(id);
                count++;
            }
        }
        emit Adventure(msg.sender, count);
    }
    
    function cellar_all() external returns (uint count){
        count = 0;
        require(balanceOf[msg.sender] > 0, "No summoners onwed!");
        for (uint i = 0; i < balanceOf[msg.sender]; i++){
            uint id = ownedSummoners[msg.sender][i];
            if (_claimable_mats(id) > 0){
                cellar.adventure(id);
                count++;
            }
        }
        emit Cellar(msg.sender, count);
    }
    
    function claim_gold_all() external returns (uint count){
        count = 0;
        uint claimed = 0;
        require(balanceOf[msg.sender] > 0, "No summoners onwed!");
        for (uint i = 0; i < balanceOf[msg.sender]; i++){
            uint id = ownedSummoners[msg.sender][i];
            uint claimable = _claimable_gold(id);
            if (claimable > 0){
                cellar.adventure(id);
                count++;
                claimed += claimable;
            }
        }
        emit ClaimGold(msg.sender, count, claimed / 10**18);
    }
    
    function transfer_all_gold(uint256 to) external returns (uint count){
        uint transferred = 0;  
        count = 0;
        require(balanceOf[msg.sender] > 0, "No summoners onwed!");
        for (uint i = 0; i < balanceOf[msg.sender]; i++) {
            uint id = ownedSummoners[msg.sender][i];
            uint balance = gold.balanceOf(id);
            if (balance > 0){
                gold.transfer(id, to, balance);
                transferred += balance;
                count++;
            }
        }
        emit TransferredGold(msg.sender, to, count, transferred);
    }
    
    function transfer_all_mats(uint256 to) external {
        uint transferred = 0;  
        uint count = 0;
        require(balanceOf[msg.sender] > 0, "No summoners onwed!");
        for (uint i = 0; i < balanceOf[msg.sender]; i++) {
            uint id = ownedSummoners[msg.sender][i];
            uint balance = gold.balanceOf(id);
            if (balance > 0){
                gold.transfer(id, to, balance);
                transferred += balance;
                count++;
            }
        }
        emit TransferredGold(msg.sender, to, count, transferred);
    }
    
    function level_up_all() external returns (uint count) {
        count = 0;
        require(balanceOf[msg.sender] > 0, "No summoners onwed!");
        for (uint i = 0; i < balanceOf[msg.sender]; i++) {
            uint id = ownedSummoners[msg.sender][i];
            bool can = _can_level_up(id);
            if (can == true) {
                rm.level_up(id);
                count += 1;
            }
        }
        emit LeveledUp(msg.sender, count);
    }
    
    
    
    function withdraw_all_summoners() external {
        uint count = 0;
        uint balance = balanceOf[msg.sender];
        require(balance > 0, "No summoners onwed!");
        for (uint i = balance - 1; i >= 0; i--){
            uint id = ownedSummoners[msg.sender][i];
            rm.transferFrom(address(this), msg.sender, id);
            delete ownedSummoners[msg.sender][i];
            balanceOf[msg.sender]--;
        }
        emit LeveledUp(msg.sender, count);
    }
    
    function get_owned_summoners(address owner) external view returns (uint[] memory summoners) {
        uint balance = balanceOf[owner];
        summoners = new uint[](balance);
        for (uint i = 0; i < balance; i++){
            summoners[i] = ownedSummoners[msg.sender][i];
        }
    }
    
    function _can_level_up(uint256 _id) private view returns (bool _can) {
        uint _level = rm.level(_id);
        uint _xp_required = rm.xp_required(_level);
        uint xp = rm.xp(_id);
        _can = xp >= _xp_required;
    }
    
    function _claimable_gold(uint256 _id) private view returns (uint _claimable) {
        uint _current_level = rm.level(_id);
        uint _claimed_for = gold.claimed(_id)+1;
        for (uint i = _claimed_for; i <= _current_level; i++) {
            _claimable += gold.wealth_by_level(i);
        }
    }
    
    function _claimable_mats(uint256 _id) private view returns (uint _claimable) {
        bool _can = block.timestamp > cellar.adventurers_log(_id);
        _claimable = cellar.scout(_id);
        if (_can == false) {
            _claimable = 0;
        }
    }
    
    function _can_adventure(uint256 _id) private view returns (bool _can) {
        _can = block.timestamp > rm.adventurers_log(_id);
    }
}