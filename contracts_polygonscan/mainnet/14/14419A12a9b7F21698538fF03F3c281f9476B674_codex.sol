// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract codex {
    string constant index = "Spells";
    string constant class = "Wizard";
    
    mapping(uint => mapping(uint => address)) public pages;
    address public loremaster;
    
    constructor() {
        loremaster = msg.sender;
    }
    
    modifier lm() {
        require(msg.sender == loremaster);
        _;
    }
    
    function setLoremaster(address _loremaster) external lm {
        loremaster = _loremaster;
    }
    
    function addPage(uint _school, uint _level, address _page) external lm {
        pages[_school][_level] = _page;
    }
    
    function school(uint id) external pure returns (string memory description) {
        if (id == 0) {
            return "Abjuration";
        } else if (id == 1) {
            return "Conjuration";
        } else if (id == 2) {
            return "Divination";
        } else if (id == 3) {
            return "Enchantment";
        } else if (id == 4) {
            return "Evocation";
        } else if (id == 5) {
            return "Illusion";
        } else if (id == 6) {
            return "Necromancy";
        } else if (id == 7) {
            return "Transmutation";
        } else if (id == 8) {
            return "Universal";
        }
    }
    
    function casting_time(uint id) external pure returns (string memory description) {
        if (id == 0) {
            return "1 free action";
        } else if (id == 1) {
            return "1 standard action";
        } else if (id == 2) {
            return "full-round action";
        } else if (id == 3) {
            return "10 full-round actions";
        }
    }
    
    function range(uint id) external pure returns (string memory description) {
        if (id == 0) {
            return "Personal";
        } else if (id == 1) {
            return "Touch";
        } else if (id == 2) {
            return "Close";
        } else if (id == 3) {
            return "Medium";
        } else if (id == 4) {
            return "Long";
        } else if (id == 5) {
            return "Unlimited";
        }
    }
    function saving_throw_type(uint id) external pure returns (string memory description) {
        if (id == 0) {
            return "None";
        } else if (id == 1) {
            return "Fortitude";
        } else if (id == 2) {
            return "Reflex";
        } else if (id == 3) {
            return "Will";
        }
    }
    
    function saving_throw_effect(uint id) external pure returns (string memory description) {
        if (id == 0) {
            return "None";
        } else if (id == 1) {
            return "Partial";
        } else if (id == 2) {
            return "Half";
        } else if (id == 3) {
            return "Negates";
        }
    }
}

