/**
 *Submitted for verification at BscScan.com on 2021-08-07
*/

pragma solidity ^0.7.6;


contract Parent {
    address private _owner;

    modifier onlyOwner() virtual {
        require(msg.sender == _owner, "invalid owner");
        _;
    }

    constructor() {
        _owner = msg.sender;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function setOwner() virtual public onlyOwner {
        _owner = msg.sender;
    }

    function data() virtual public view returns (uint256) {
        return 1;
    }
}


contract SubParent1 is Parent {
    function data() public virtual override view returns (uint256) {
        return 2;
    }
}


contract SubParent2 is Parent, SubParent1 {
    function data() public virtual override(Parent, SubParent1) view returns (uint256) {
        return 3;
    }
}


contract SubParent3 is Parent, SubParent1, SubParent2 {
    function data() public virtual override(Parent, SubParent1, SubParent2) view returns (uint256) {
        return 4;
    }
}


contract Child is Parent, SubParent1, SubParent2, SubParent3 {
    modifier onlyOwner() override {
        require(msg.sender != owner(), "modifier overriden");
        _;
    }

    function data() public virtual override(Parent, SubParent1, SubParent3, SubParent2) view returns (uint256) {
        return super.data();
    }

    function addr2uint() public view returns(uint256) {
        return uint256(msg.sender);
    }
    // function setOwner() override public onlyOwner {
    //     super.setOwner();
    // }
}