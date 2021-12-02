/**
 *Submitted for verification at FtmScan.com on 2021-12-02
*/

/**
 *Submitted for verification at FtmScan.com on 2021-09-17
*/

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

    rarity_manifested constant _rm = rarity_manifested(0xce761D788DF608BD21bdd59d6f4B54b2e27F25Bb);
    rarity_gold constant       _gold = rarity_gold(0x2069B76Afe6b734Fb65D1d099E7ec64ee9CC76B2);
    rarity_cellar constant     _cellar = rarity_cellar(0x2A0F1cB17680161cF255348dDFDeE94ea8Ca196A);


    function adventure(uint256[] calldata _ids) external payable {
        for (uint i = 0; i < _ids.length; i++) {
            _rm.adventure(_ids[i]);
        }
    }

    function level_up(uint256[] calldata _ids) external payable {
        for (uint i = 0; i < _ids.length; i++) {
            _rm.level_up(_ids[i]);
        }
    }

    // @dev Requires individual approvals...
    function cellar(uint256[] calldata _delvers, uint256[] calldata _need_approval) external payable {
        for (uint i = 0; i < _need_approval.length; i++) {
            _rm.approve(address(this), _need_approval[i]);
        }
        for (uint i = 0; i < _delvers.length; i++) {
            _cellar.adventure(_delvers[i]);
        }
    }

    // @dev Requires individual approvals...
    function claim_gold(uint256[] calldata _claimers, uint256[] calldata _need_approval) external payable {
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
    function approve_all(uint256[] calldata _ids) external payable {
        for (uint i = 0; i < _ids.length; i++) {
            _rm.approve(address(this), _ids[i]);
        }
    }

    // @dev We appreciate any tips you send to the daily contract
    receive() external payable {

    }

    function transfer_tips() external {
        address payable tip_jar = payable(0xEEbb1f2f892655f456cF105593E465fB341aA51d);
        tip_jar.transfer(address(this).balance);
    }

}