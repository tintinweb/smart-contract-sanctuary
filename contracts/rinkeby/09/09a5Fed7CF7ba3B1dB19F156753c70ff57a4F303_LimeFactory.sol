/**
 *Submitted for verification at Etherscan.io on 2021-09-29
*/

pragma solidity ^0.7.0;// SPDX-License-Identifier: UNLICENSED


contract LimeFactory {

    event FreshLime(string name);

    struct Lime {
        string name;
        uint8 carbohydrates;
        uint8 fat;
        uint8 protein;
    }

    Lime[] public limes;

    function createLime(string memory _name, uint8 _carbohydrates, uint8 _fat, uint8 _protein) public {
        require(_carbohydrates != 0, "The carbohydrates cannot be 0");
        limes.push(Lime(_name, _carbohydrates, _fat, _protein));
        emit FreshLime(_name);
    }
}