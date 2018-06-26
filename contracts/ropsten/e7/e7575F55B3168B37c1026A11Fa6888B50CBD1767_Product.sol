pragma solidity ^0.4.23;

// File: contracts/utils/Ownable.sol

contract Ownable {

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
 * @title ProductBasic
 * @dev Simpler version of Product interface
 */
contract Product is Ownable {

    string public name;
    uint256 public maxcap;
    uint256 public weiRaised;
    uint256 public exceed;
    uint256 public minimum;
    uint256 public rate;

    constructor (
        string _name,
        uint256 _maxcap,
        uint256 _exceed,
        uint256 _minimum,
        uint256 _rate
    ) public {
        require(_maxcap > _minimum);

        name = _name;
        maxcap = _maxcap;
        exceed = _exceed;
        minimum = _minimum;
        rate = _rate;
    }

    function setWeiRaised(uint256 _weiRaised) public onlyOwner {
        require(weiRaised <= _weiRaised);

        weiRaised = _weiRaised;
    }
}