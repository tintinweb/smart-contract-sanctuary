/**
 *Submitted for verification at polygonscan.com on 2022-01-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;

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

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }

    /**
     * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
     * @dev Adds two numbers, throws on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

interface ITRC21 {
    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

contract TokenSale is Ownable {
    event _register(address user, uint256 _tokenId);
    event Deposit(ITRC21 _fiat, uint256 _fiatAmount, address _to);
    
    struct Sale {
        ITRC21 fiat;
        address saler;
        bool existed;
    }

    mapping(address => Sale) public sales;
    
    ITRC21[] public fiats = [ITRC21(0x6edFA332F68B2ED045fe0e045554CeD910253784)];
    address[] public businessAddresses = [address(0x64470E5F5DD38e497194BbcAF8Daa7CA578926F6)];
    uint256[] public prices = [500000000000000000000, 1000000000000000000000, 3000000000000000000000, 5000000000000000000000, 10000000000000000000000];
    mapping(address => bool) public userBlocks;

    constructor()  {}

    modifier onlyManager() {
        require(msg.sender == owner || isBusiness());
        _;
    }

    modifier isValidFiatBuy(address _fiat) {
        require(sales[_fiat].existed);
        _;
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
        bool valid;
        for (uint256 i = 0; i < prices.length; i++) {
            if (prices[i] == _price) valid = true;
        }
        return valid;
    }

    function validPrices(uint256[] memory _prices) public view returns (bool) {
        bool valid = true;
        for (uint256 i = 0; i < _prices.length; i++) {
            if (!validPrice(_prices[i])) valid = false;
        }
        return valid;
    }

    function deposit(address _fiat, uint256[] memory _fiatAmounts, address _to) public onlyManager isValidFiatBuy(_fiat) {
        require(validPrices(_fiatAmounts), "Invalid price !!!");
        for (uint256 j = 0; j < _fiatAmounts.length; j++) {
            ITRC21 fiat = ITRC21(_fiat);
            fiat.transferFrom(sales[_fiat].saler, _to, _fiatAmounts[j]);
            emit Deposit(fiat, _fiatAmounts[j], _to);
        }
    }

    function setFiatToken(address _fiat, address _saler) public onlyManager {
        ITRC21 fiat = ITRC21(_fiat);
        if (sales[_fiat].existed) {
            sales[_fiat].saler = _saler;
        } else {
            Sale memory newSale = Sale({fiat: fiat, saler: _saler, existed: true});
            sales[_fiat] = newSale;
            fiats.push(fiat);
        }
        
    }

    function setPrices(uint256[] memory _prices) public onlyManager {
        prices = _prices;
    }

    function setBusinessAdress(address[] memory _businessAddresses) public onlyOwner {
        businessAddresses = _businessAddresses;
    }
}