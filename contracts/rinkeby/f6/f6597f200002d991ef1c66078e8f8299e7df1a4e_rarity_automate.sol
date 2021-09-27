/**
 *Submitted for verification at Etherscan.io on 2021-09-26
*/

pragma solidity 0.8.7;
// SPDX-License-Identifier: MIT
// Inspired by 0x56a20B765bf7FF0edf67aB2752E3c8703821fE2E

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
    
    rarity_manifested constant _rm = rarity_manifested(0xB4A44ccb5E342bcb4aA83ff379E826E9B79beb15);
    rarity_gold constant       _gold = rarity_gold(0x50b7A32312a6B4714c521509E43c1cbC103Ae344);
    rarity_cellar constant     _cellar = rarity_cellar(0xA0f99C6075D9d2f526F8B2c2d1CD8b9A25d6Eb9d);
    rarity_attributes constant _attributes = rarity_attributes(0x1642d519301844AB25FFe621D8D9e227d508FCc7);
    codex_base_random constant _random = codex_base_random(0x101B6086246CE1fE216D910C6c09A6e0126FC5E0);
    
    struct Balance {
        uint256 summoner;
        uint balance;
    }
    
    struct Status {
        uint256 summoner;
        bool status;
    }
    
    event Adventure(uint count);
    event Cellar(uint claimed);
    event LevelUp(uint leveled);
    event ClaimGold(uint claimed);
    event Approval(uint count);
    event BulkTransferBalance(uint total);
    event BulkSummoned(uint256[] summoned);
     
    uint public immutable SUMMMONER_ID;
    uint8[6][50] internal attributes;  

    constructor() {
        // I have my own summoner
        uint my_summoner = _rm.next_summoner();
        SUMMMONER_ID = my_summoner;
        // He is a wizard!
        _rm.summon(11);
        // and he is so smart!
        _attributes.point_buy(my_summoner, 8, 8, 8, 22, 8, 8);
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
    
    function approve_bulk_transfer(uint256[] calldata _ids) external {
        for (uint i = 0; i < _ids.length; i++) {
            require(_isApprovedOrOwner(_ids[i]), "!owner");
            require(_ids[i] != SUMMMONER_ID, "hax0r");
            
            _gold.approve(_ids[i], SUMMMONER_ID, type(uint).max);
            _cellar.approve(_ids[i], SUMMMONER_ID, type(uint).max);
        }
    }
    
    function bulk_transfer_all_gold(uint256[] calldata _froms, uint256 to) external payable {
        uint transferred = 0;  
        for (uint i = 0; i < _froms.length; i++) {
            require(_isApprovedOrOwner(_froms[i]), "!owner");
            require(_froms[i] != SUMMMONER_ID, "hax0r");
            if (_froms[i] == to) continue;
            
            uint balance = _gold.balanceOf(_froms[i]);
            if (balance > 0){
                transferred += balance;
                _gold.transferFrom(SUMMMONER_ID, _froms[i], to, balance);
            }
        }
    }
    
    function bulk_transfer_all_mats(uint256[] calldata _froms, uint256 to) external payable {
        uint transferred = 0;
        for (uint i = 0; i < _froms.length; i++) {
            require(_isApprovedOrOwner(_froms[i]), "!owner");
            require(_froms[i] != SUMMMONER_ID, "hax0r");
            if (_froms[i] == to) continue;
            
            uint balance = _cellar.balanceOf(_froms[i]);
            if (balance > 0){
                transferred += balance;
                _cellar.transferFrom(SUMMMONER_ID, _froms[i], to, balance);
            }
        }
        emit BulkTransferBalance(transferred);
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
    
    function bulk_assign_attributes(uint256[] calldata _ids, uint32 _str, uint32 _dex, uint32 _const, uint32 _int, uint32 _wis, uint32 _cha) external payable{
        for (uint i = 0; i < _ids.length; i++) {
            require(_isApprovedOrOwner(_ids[i]), "!owner");
            require(_ids[i] != SUMMMONER_ID, "hax0r");
            
            if (_attributes.character_created(_ids[i]) == false) {
                _attributes.point_buy(_ids[i], _str, _dex, _const, _int, _wis, _cha);
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
    
    function claimable_mats(uint256[] calldata _ids) external view returns (Balance[] memory _cans) {
        _cans = new Balance[](_ids.length);
        for (uint i = 0; i < _ids.length; i++) {
            _cans[i].balance = _claimable_mats(_ids[i]);
            _cans[i].summoner = _ids[i];
        }
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
    
    function _claimable_mats(uint256 _id) private view returns (uint _claimable) {
        bool _can = block.timestamp > _cellar.adventurers_log(_id);
        _claimable = _cellar.scout(_id);
        if (_can == false) {
            _claimable = 0;
        }
    }
    
    function bulk_adventure(uint256[] calldata _ids) public payable returns (bool atleast_one){
        atleast_one = false;
        uint count = 0;
        for (uint i = 0; i < _ids.length; i++) {
            bool can = _can_adventure(_ids[i]) == true;
            if (can == true){
                _rm.adventure(_ids[i]);
                count += 1;
            }
            atleast_one = atleast_one || can;
        }
        if (atleast_one == true) emit Adventure(count);
    }

    function bulk_level_up(uint256[] calldata _ids) public payable returns (bool atleast_one) {
        atleast_one = false;
        uint count = 0;
        for (uint i = 0; i < _ids.length; i++) {
            bool can = _can_level_up(_ids[i]) == true;
            if (can == true) {
                _rm.level_up(_ids[i]);
                count += 1;
            }
            atleast_one = atleast_one || can;
        }
        if (atleast_one == true) emit LevelUp(count);
    }

    function bulk_cellar(uint256[] calldata _ids) public payable returns (bool atleast_one) {
        uint amount = 0;
        atleast_one = false;
        for (uint i = 0; i < _ids.length; i++) {
            uint claimable = _claimable_mats(_ids[i]);
            if (claimable > 0) {
                _cellar.adventure(_ids[i]);
                amount += claimable;
            }
            atleast_one = atleast_one || claimable > 0;
        }
        if (atleast_one == true) emit Cellar(amount);
    }

    function bulk_claim_gold(uint256[] calldata _ids) public payable returns (bool atleast_one) {
        uint claimed = 0;
        atleast_one = false;
        for (uint i = 0; i < _ids.length; i++) {
            uint claimable = _claimable_gold(_ids[i]);
            if (claimable > 0){
                _gold.claim(_ids[i]);
                claimed += claimable;
                atleast_one = atleast_one || claimable > 0;
            }
        }
        if (atleast_one == true) emit ClaimGold(claimed);
    }
    
    function is_approved(uint256[] calldata _ids) external view returns (Status[] memory _is_approved) {
        _is_approved = new Status[](_ids.length);
        for (uint i = 0; i < _ids.length; i++) {
            _is_approved[i].status = _rm.getApproved(_ids[i]) == address(this);
            _is_approved[i].summoner = _ids[i];
        }
    }
    
    function treat_my_own_summoner() external payable {
        // I have my own summoner too!
        // He is a wizard that helps your summoner transfer the golds and materials
        // He will be so happy if he get some treatments from you!
        bool adventure = _can_adventure(SUMMMONER_ID);
        if (adventure == true) {
            _rm.adventure(SUMMMONER_ID);
        }
        
        bool claim_mats = _claimable_mats(SUMMMONER_ID) > 0;
        if (claim_mats == true) {
            _cellar.adventure(SUMMMONER_ID);
        }
        
        bool level_up = _can_level_up(SUMMMONER_ID);
        if (level_up == true) {
            _rm.level_up(SUMMMONER_ID);
        }
        
        bool claim_gold = _claimable_gold(SUMMMONER_ID) > 0;
        if (claim_gold == true) {
            _gold.claim(SUMMMONER_ID);
        }
        
        bool atleast_one = adventure || claim_mats || level_up || claim_gold;
        require(atleast_one == true, 'Thank you! But no treatment needed at the moment!');
    }
    
    function approve_automate(uint256[] calldata _ids) external payable {
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
        bool adventure = bulk_adventure(_ids);
        bool cellar = bulk_cellar(_ids);
        bool level_up = bulk_level_up(_ids);
        bool claim_gold = bulk_claim_gold(_ids);
        
        bool atleast_one = adventure || cellar || level_up || claim_gold;
        require(atleast_one == true, 'No need to automate!');
    }

    // @dev We appreciate any tips you send to the automate contract
    receive() external payable {

    }

    function transfer_tips() external {
        address payable tip_jar = payable(0x078356069A990A093F029646DcEC5E320879Ba08);
        tip_jar.transfer(address(this).balance);
    }

}