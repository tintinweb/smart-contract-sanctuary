/**
 *Submitted for verification at Etherscan.io on 2021-10-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract TokenSale is Ownable {
    address public sale = address(0x64470E5F5DD38e497194BbcAF8Daa7CA578926F6);
    IERC20 public fiat = IERC20(0x3F1a8a7C4ef4Cc131A41418e2775f186063f6fB3);
    address[] public businessAddresses = [address(0x64470E5F5DD38e497194BbcAF8Daa7CA578926F6)];
    uint256[] public prices = [500000000000000000000, 1000000000000000000000, 3000000000000000000000, 5000000000000000000000, 10000000000000000000000];
    mapping(uint256 => bool) public validPackages;
    mapping(address => bool) public userBlocks;

    event Deposit(uint256 _fiatAmount, address _from, IERC20 _token);

    modifier onlyManager() {
        require(msg.sender == owner || isBusiness());
        _;
    }

    constructor () {
      validPackages[500000000000000000000] = true;
      validPackages[1000000000000000000000] = true;
      validPackages[3000000000000000000000] = true;
      validPackages[5000000000000000000000] = true;
      validPackages[10000000000000000000000] = true;
    }

    function setBlockUser(address _user, bool _status) public onlyOwner {
        userBlocks[_user] = _status;
    }

    function isBusiness() public view returns (bool) {
        bool valid;
        for (uint256 i = 0; i < businessAddresses.length; i++) {
            if (businessAddresses[i] == msg.sender) valid = true;
        }
        return valid;
    }

    function validPrice(uint256 _price) public view returns (bool) {
        return validPackages[_price];
    }

    function validPrices(uint256[] memory _prices) public view returns (bool) {
        bool valid = true;
        for (uint256 i = 0; i < _prices.length; i++) {
            if (!validPackages[_prices[i]]) valid = false;
        }
        return valid;
    }

    function deposit(uint256[] memory _fiatAmounts, address _from) public onlyManager {
        require(validPrices(_fiatAmounts), "Invalid price !!!");
        for (uint256 j = 0; j < _fiatAmounts.length; j++) {
            fiat.transferFrom(sale, _from, _fiatAmounts[j]);
            emit Deposit(_fiatAmounts[j], _from, fiat);
        }
    }

    function setFiat(IERC20 _fiat) public onlyManager {
        fiat = _fiat;
    }

    function setSale(address _sale) public onlyManager {
        sale = _sale;
    }

    function setPrices(uint256[] memory _prices) public onlyManager {
        prices = _prices;
    }

    function setBusinessAdress(address[] memory _businessAddresses) public onlyOwner {
        businessAddresses = _businessAddresses;
    }
}