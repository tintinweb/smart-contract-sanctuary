// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(msg.sender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract InspexSimulator is Ownable {
    uint256 public x = 0;
    address public y;
    bool public z;
    
    constructor(address admin) {
        transferOwnership(admin);
    }
    
    function setX(uint256 _x) external {
        x = _x;
    }
    
    event SetYZ(address indexed y, bool indexed z);
    function setYZ(address _y, bool _z) onlyOwner external {
        y = _y;
        z = _z;

        emit SetYZ(y, z);
    }
    
    event HelloWorld(uint256 indexed x, address indexed y, bytes data, string s, address[] addrs);
    function helloWorld() external {
        address[] memory addrs = new address[](3);
        addrs[0] = address(0);
        addrs[1] = address(this);
        addrs[2] = msg.sender;
        
        string memory s = "HelloWorld string";
        bytes memory b = "HelloWorld bytes";
        
        emit HelloWorld(x, y, b, s, addrs);
    }
    
}