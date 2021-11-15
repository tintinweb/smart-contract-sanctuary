// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;



// Part: adventurable

interface adventurable {
    function adventure(uint) external;
}

// Part: rarity_gold

interface rarity_gold {
    function claim(uint) external;
}

// Part: rarity_cellar

interface rarity_cellar is adventurable {

}

// Part: rarity_manifested

interface rarity_manifested is adventurable {
    function level_up(uint) external;
    function approve(address, uint256) external;
    function getApproved(uint256) external view returns (address);
}

// File: rarity_daily.sol

contract rarity_daily {

    rarity_manifested constant _rm = rarity_manifested(0x4fb729BDb96d735692DCACD9640cF7e3aA859B25);
    rarity_gold constant       _gold = rarity_gold(0x7303E7a860DAFfE4d0b33615479648cb3496903b);
    rarity_cellar constant     _cellar = rarity_cellar(0xEF4C8E18c831cB7C937A0D17809102208570eC8F);


    function adventure(uint256[] calldata _ids) external {
        for (uint i = 0; i < _ids.length; i++) {
            _rm.adventure(_ids[i]);
        }
    }

    function level_up(uint256[] calldata _ids) external {
        for (uint i = 0; i < _ids.length; i++) {
            _rm.level_up(_ids[i]);
        }
    }

    // @dev Requires individual approvals...
    function cellar(uint256[] calldata _delvers, uint256[] calldata _need_approval) external {
        for (uint i = 0; i < _need_approval.length; i++) {
            _rm.approve(address(this), _need_approval[i]);
        }
        for (uint i = 0; i < _delvers.length; i++) {
            _cellar.adventure(_delvers[i]);
        }
    }

    // @dev Requires individual approvals...
    function claim_gold(uint256[] calldata _claimers, uint256[] calldata _need_approval) external {
        for (uint i = 0; i < _need_approval.length; i++) {
            _rm.approve(address(this), _need_approval[i]);
        }
        for (uint i = 0; i < _claimers.length; i++) {
            _gold.claim(_claimers[i]);
        }
    }

    // @dev Check if an array of summoners is approved
    function is_approved(uint256[] calldata _ids) external view returns (bool[] memory _is_approved) {
        _is_approved = new bool[](_ids.length);
        for (uint i = 0; i < _ids.length; i++) {
            _is_approved[i] = _rm.getApproved(_ids[i]) == address(this);
        }
    }

    // @dev Approve an array of summoners
    function approve_all(uint256[] calldata _ids) external {
        for (uint i = 0; i < _ids.length; i++) {
            _rm.approve(address(this), _ids[i]);
        }
    }

}

