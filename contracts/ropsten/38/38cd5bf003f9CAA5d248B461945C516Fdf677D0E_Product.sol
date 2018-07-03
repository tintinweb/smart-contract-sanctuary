pragma solidity ^0.4.23;

// File: contracts/utils/ExtendsOwnable.sol

contract ExtendsOwnable {

    mapping(address => bool) owners;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OwnershipExtended(address indexed host, address indexed guest);

    modifier onlyOwner() {
        require(owners[msg.sender]);
        _;
    }

    constructor() public {
        owners[msg.sender] = true;
    }

    function addOwner(address guest) public onlyOwner {
        require(guest != address(0));
        owners[guest] = true;
        emit OwnershipExtended(msg.sender, guest);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owners[newOwner] = true;
        delete owners[msg.sender];
        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// File: contracts/sale/Product.sol

/**
 * @title Product
 * @dev Simpler version of Product interface
 */
contract Product is ExtendsOwnable {
    string public name;
    uint256 public maxcap;
    uint256 public exceed;
    uint256 public minimum;
    uint256 public rate;
    uint256 public lockup;

    constructor (
        string _name,
        uint256 _maxcap,
        uint256 _exceed,
        uint256 _minimum,
        uint256 _rate,
        uint256 _lockup
    ) public {
        name = _name;
        maxcap = _maxcap;
        exceed = _exceed;
        minimum = _minimum;
        rate = _rate;
        lockup = _lockup;
    }

    function setName(string _name) external onlyOwner {
        name = _name;
    }

    function setMaxcap(uint256 _maxcap) external onlyOwner {
        maxcap = _maxcap;
    }

    function setExceed(uint256 _exceed) external onlyOwner {
        exceed = _exceed;
    }

    function setMinimum(uint256 _minimum) external onlyOwner {
        minimum = _minimum;
    }

    function setRate(uint256 _rate) external onlyOwner {
        rate = _rate;
    }

    function setLockup(uint256 _lockup) external onlyOwner {
        lockup = _lockup;
    }
}