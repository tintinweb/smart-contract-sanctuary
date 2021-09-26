/**
 *Submitted for verification at Etherscan.io on 2021-09-25
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
    function wealth_by_level(uint) external pure returns (uint);
    function approve(uint, uint, uint) external returns (bool);
    function transferFrom(uint, uint, uint, uint) external returns (bool);
}

interface rarity_cellar is adventurable {
    function scout(uint) external view returns (uint);
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
    function transferFrom(address, address, uint256) external;
}

interface rarity_attributes {
    function point_buy(uint, uint32, uint32, uint32, uint32, uint32, uint32) external;
    function character_created(uint) external view returns (bool);
}

interface codex_base_random {
    function d6(uint _summoner) external view returns (uint);
}

contract rarity_automate {
    // rarity_manifested constant _rm = rarity_manifested(0xce761D788DF608BD21bdd59d6f4B54b2e27F25Bb);
    // rarity_gold constant       _gold = rarity_gold(0x2069B76Afe6b734Fb65D1d099E7ec64ee9CC76B2);
    // rarity_cellar constant     _cellar = rarity_cellar(0x2A0F1cB17680161cF255348dDFDeE94ea8Ca196A);
    // rarity_attributes constant _attributes = rarity_attributes(0xB5F5AF1087A8DA62A23b08C00C6ec9af21F397a1);
    // codex_base_random constant _random = codex_base_random(0x7426dBE5207C2b5DaC57d8e55F0959fcD99661D4);
    
    rarity_manifested constant _rm = rarity_manifested(0xd99d686F75Dfd6884a822b436eFf8CD0783A3889);
    rarity_gold constant       _gold = rarity_gold(0xcbAC902e66B964c7175F4173e7D48d20aCf50b18);
    rarity_cellar constant     _cellar = rarity_cellar(0x4E37f2A6Fb5F3C43FB64588043fFeb456c914a6B);
    rarity_attributes constant _attributes = rarity_attributes(0x6CBde08bD4B7B710305381B5c856ac74C1FC31DA);
    codex_base_random constant _random = codex_base_random(0x452DbCcE9eFB565A725b5C2Dbae0834BB70221Dc);
    
    
    struct Balance {
        uint256 summoner;
        uint balance;
    }
    
    struct Status {
        uint256 summoner;
        bool status;
    }
    
    event Adventure(uint count);
    event Cellar(uint count);
    event LevelUp(uint count);
    event ClaimGold(uint claimed);
    event Approval(uint count);
    event BulkTransferBalance(uint total);
    event BulkSummoned(uint256[] summoned);
     
    uint public immutable SUMMMONER_ID;
    uint8[6][50] public attributes;  

    constructor() {
        SUMMMONER_ID = _rm.next_summoner();
        _rm.summon(11);
        attributes = [
            [19, 12, 10, 10, 10, 10],
    		[18, 15, 10, 10, 10, 10],
    		[18, 14, 12, 10, 10, 10],
    		[18, 12, 12, 12, 10, 10],
    		[16, 16, 14, 10, 10, 10],
    		[16, 16, 12, 12, 10, 10],
    		[16, 15, 14, 12, 10, 10],
    		[16, 15, 12, 12, 12, 10],
    		[16, 14, 14, 14, 10, 10],
    		[16, 14, 14, 12, 12, 10],
    		[16, 14, 12, 12, 12, 12],
    		[15, 14, 14, 14, 12, 10],
    		[15, 14, 14, 12, 12, 12],
    		[14, 14, 14, 14, 14, 10],
    		[14, 14, 14, 14, 12, 12],
    		[18, 14, 14, 10, 10, 8],
    		[18, 14, 12, 12, 10, 8],
    		[18, 12, 12, 12, 12, 8],
    		[16, 16, 15, 10, 10, 8],
    		[20, 10, 10, 10, 10, 8],
    		[19, 14, 10, 10, 10, 8],
    		[19, 12, 12, 10, 10, 8],
    		[18, 16, 10, 10, 10, 8],
    		[18, 15, 12, 10, 10, 8],
    		[16, 16, 14, 12, 10, 8],
    		[16, 16, 12, 12, 12, 8],
    		[16, 15, 14, 14, 10, 8],
    		[16, 15, 14, 12, 12, 8],
    		[16, 14, 14, 14, 12, 8],
    		[15, 14, 14, 14, 14, 8],
    		[20, 12, 10, 10, 8, 8],
    		[19, 14, 12, 10, 8, 8],
    		[19, 12, 12, 12, 8, 8],
    		[18, 16, 12, 10, 8, 8],
    		[18, 15, 14, 10, 8, 8],
    		[18, 15, 12, 12, 8, 8],
    		[18, 14, 14, 12, 8, 8],
    		[16, 16, 16, 10, 8, 8],
    		[16, 16, 15, 12, 8, 8],
    		[16, 16, 14, 14, 8, 8],
    		[21, 10, 10, 8, 8, 8],
    		[20, 14, 10, 8, 8, 8],
    		[20, 12, 12, 8, 8, 8],
    		[19, 16, 10, 8, 8, 8],
    		[19, 14, 14, 8, 8, 8],
    		[18, 16, 14, 8, 8, 8],
    		[21, 12, 8, 8, 8, 8],
    		[20, 15, 8, 8, 8, 8],
    		[18, 18, 8, 8, 8, 8],
    		[22, 8, 8, 8, 8, 8]
    	];
    }
    
    function _isApprovedOrOwner(uint _summoner) internal view returns (bool) {
        return _rm.getApproved(_summoner) == msg.sender || _rm.ownerOf(_summoner) == msg.sender;
    }
    
    function approve_all_balance(uint256[] calldata _ids) external {
        for (uint i = 0; i < _ids.length; i++) {
            require(_isApprovedOrOwner(_ids[i]), "!owner");
            require(_ids[i] != SUMMMONER_ID, "hax0r");
            
            _gold.approve(_ids[i], SUMMMONER_ID, type(uint).max);
            _cellar.approve(_ids[i], SUMMMONER_ID, type(uint).max);
        }
    }
    
    function bulk_transfer_gold(uint256[] calldata _froms, uint256 to) external payable {
        uint transferred = 0;  
        for (uint i = 0; i < _froms.length; i++) {
            require(_isApprovedOrOwner(_froms[i]), "!owner");
            require(_froms[i] != SUMMMONER_ID, "hax0r");
            
            uint balance = _gold.balanceOf(_froms[i]);
            if (balance > 0 && _froms[i] != SUMMMONER_ID){
                transferred += balance;
                _gold.transferFrom(SUMMMONER_ID, _froms[i], to, balance);
            }
        }
    }
    
    function bulk_transfer_mats(uint256[] calldata _froms, uint256 to) external payable {
        uint transferred = 0;
        for (uint i = 0; i < _froms.length; i++) {
            require(_isApprovedOrOwner(_froms[i]), "!owner");
            require(_froms[i] != SUMMMONER_ID, "hax0r");
            
            uint balance = _cellar.balanceOf(_froms[i]);
            if (balance > 0 && _froms[i] != SUMMMONER_ID){
                transferred += balance;
                _cellar.transferFrom(SUMMMONER_ID, _froms[i], to, balance);
            }
        }
        emit BulkTransferBalance(transferred);
    }
    
    function bulk_summon(uint class, uint count) external payable{
        require(count < 100, 'Max 100 per call');
        uint256[] memory summoned = new uint256[](count);
        
        for (uint i = 0; i < count; i++) {
            uint summonerId = _rm.next_summoner();
            _rm.summon(class);
            _rm.transferFrom(address(this), msg.sender, summonerId);
            summoned[i] = summonerId;
        }
        
        emit BulkSummoned(summoned);
    }
    
    function bulk_assign_random_attributes(uint256[] calldata _ids) external payable{
        for (uint i = 0; i < _ids.length; i++) {
            require(_isApprovedOrOwner(_ids[i]), "!owner");
            require(_ids[i] != SUMMMONER_ID, "hax0r");
            
            if (!_attributes.character_created(_ids[i])) {
                uint index = _random.d6(_ids[i]);
                uint8[6] memory attr = attributes[index];
                _attributes.point_buy(_ids[i], attr[0], attr[1], attr[2], attr[3], attr[4], attr[5]);
            }
        }
    }
    
    function can_assign_attributes(uint256[] calldata _ids) external view returns (Status[] memory _cans) {
        _cans = new Status[](_ids.length);
        for (uint i = 0; i < _ids.length; i++) {
            _cans[i].summoner = _ids[i];
            _cans[i].status = !_attributes.character_created(_ids[i]);
        }
    }

    function get_mats_balance(uint256[] calldata _ids) external view returns (Balance[] memory _balances) {
        _balances = new Balance[](_ids.length);
        for (uint i = 0; i < _ids.length; i++) {
            _balances[i].summoner = _ids[i];
            _balances[i].balance = _cellar.balanceOf(_ids[i]);
        }
    }
    
    
    function get_gold_balance(uint256[] calldata _ids) external view returns (Balance[] memory _balances) {
        _balances = new Balance[](_ids.length);
        for (uint i = 0; i < _ids.length; i++) {
            _balances[i].summoner = _ids[i];
            _balances[i].balance = _gold.balanceOf(_ids[i]);
        }
    }
    
    function can_claim_gold(uint256[] calldata _ids) external view returns (Balance[] memory _cans) {
        _cans = new Balance[](_ids.length);
        for (uint i = 0; i < _ids.length; i++) {
            _cans[i].summoner = _ids[i];
            _cans[i].balance = _claimable_gold(_ids[i]);
        }
    }
    
    function can_adventure(uint256[] calldata _ids) external view returns (Status[] memory _cans) {
        _cans = new Status[](_ids.length);
        for (uint i = 0; i < _ids.length; i++) {
            _cans[i].summoner = _ids[i];
            _cans[i].status = _can_adventure(_ids[i]);
        }
        
    }
    
    function can_level_up(uint256[] calldata _ids) external view returns (Status[] memory _cans) {
        _cans = new Status[](_ids.length);
        for (uint i = 0; i < _ids.length; i++) {
            _cans[i].summoner = _ids[i];
            _cans[i].status = _can_level_up(_ids[i]);
        }
        
    }
    
    function can_cellar(uint256[] calldata _ids) external view returns (Status[] memory _cans) {
        _cans = new Status[](_ids.length);
        for (uint i = 0; i < _ids.length; i++) {
            _cans[i].status = _can_cellar(_ids[i]);
            _cans[i].summoner = _ids[i];
        }
    }
    
    function _can_cellar(uint256 _id) private view returns (bool _can) {
        _can = block.timestamp > _cellar.adventurers_log(_id) && _cellar.scout(_id) > 0;
    }
    
    function _can_adventure(uint256 _id) private view returns (bool _can) {
        _can = block.timestamp > _rm.adventurers_log(_id);
    }
    
    function _can_level_up(uint256 _id) private view returns (bool _can) {
        uint _level = _rm.level(_id);
        uint _xp_required = _rm.xp_required(_level);
        uint xp = _rm.xp(_id);
        _can = xp >= _xp_required;
    }
    
    function _claimable_gold(uint256 _id) private view returns (uint _claimable) {
        uint _current_level = _rm.level(_id);
        uint _claimed_for = _gold.claimed(_id)+1;
        for (uint i = _claimed_for; i <= _current_level; i++) {
            _claimable += _gold.wealth_by_level(i);
        }
    }
    
    function adventure(uint256[] calldata _ids) public payable {
        uint count = 0;
        for (uint i = 0; i < _ids.length; i++) {
            if (_can_adventure(_ids[i]) == true){
                _rm.adventure(_ids[i]);
                count += 1;
            }
        }
        
        emit Adventure(count);
    }

    function level_up(uint256[] calldata _ids) public payable {
        uint count = 0;
        for (uint i = 0; i < _ids.length; i++) {
            if (_can_level_up(_ids[i]) == true) {
                _rm.level_up(_ids[i]);
                count += 1;
            }
        }
        
        emit LevelUp(count);
    }

    function cellar(uint256[] calldata _ids) public payable {
        uint count = 0;
        for (uint i = 0; i < _ids.length; i++) {
            if (_can_cellar(_ids[i]) == true) {
                _cellar.adventure(_ids[i]);
                count += 1;
            }
        }
        
        emit Cellar(count);
    }

    function claim_gold(uint256[] calldata _ids) public payable {
        uint claimed = 0;
        for (uint i = 0; i < _ids.length; i++) {
            uint claimable = _claimable_gold(_ids[i]);
            if (claimable > 0){
                _gold.claim(_ids[i]);
                claimed += claimable;
            }
        }
        
        emit ClaimGold(claimed);
    }
    
    function is_approved(uint256[] calldata _ids) external view returns (Status[] memory _is_approved) {
        _is_approved = new Status[](_ids.length);
        for (uint i = 0; i < _ids.length; i++) {
            _is_approved[i].status = _rm.getApproved(_ids[i]) == address(this);
            _is_approved[i].summoner = _ids[i];
        }
    }
    
    function approve(uint256[] calldata _ids) external payable {
        uint count = 0;
        for (uint i = 0; i < _ids.length; i++) {
           bool _is_approved = _rm.getApproved(_ids[i]) == address(this);
            if (_is_approved == false){
                _rm.approve(address(this), _ids[i]);
                count += 1;
            }
        }
        emit Approval(count);
    }
    
    function automate(uint256[] calldata _ids) external payable {
        adventure(_ids);
        cellar(_ids);
        level_up(_ids);
        claim_gold(_ids);
    }

    // @dev We appreciate any tips you send to the automate contract
    receive() external payable {

    }

    function transfer_tips() external {
        address payable tip_jar = payable(0x078356069A990A093F029646DcEC5E320879Ba08);
        tip_jar.transfer(address(this).balance);
    }

}