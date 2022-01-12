/**
 *Submitted for verification at polygonscan.com on 2022-01-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

library SafeMath {
    /**
     * @dev Multiplies two numbers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two numbers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

//
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

contract FiatJPY is Ownable {
    event SetPrice(string[] _symbols, uint256[] _token2JPY, address _from);

    using SafeMath for uint256;
    struct Token {
        string symbol;
        uint256 Token2JPY;
        bool existed;
    }
    
    string[] public tokenArr;
    mapping(string => Token) public tokens;

    struct Asset {
        string symbol;
        address asset;
        AggregatorV3Interface priceFeed;
    }
    mapping(string => Asset) public assets;
    
    uint256 public USD2JPY = 114;

    uint256 public mulNum = 2;
    uint256 public lastCode = 3;
    uint256 public callTime = 1;
    uint256 public baseTime = 3;
    uint256 public plusNum = 1;

    constructor() {
        assets["MATIC"] = Asset("MATIC", address(0), AggregatorV3Interface(0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada));
        assets["ETH"] = Asset("ETH", 0x39ca63B52780130cF91ceDd5a3E37Ed4D604b0bC, AggregatorV3Interface(0x0715A7794a1dc8e42615F059dD6e406A6594651A));
        assets["USDT"] = Asset("USDT", 0x569AafF8F90A5E48B27C154249eE5A08eD0C44E2, AggregatorV3Interface(0x92C09849638959196E976289418e5973CC96d645));
        _setPrice("F", 1 ether);
    }

    function getLatestPrice(string memory _symbol) public view returns (int256) {
        (, int256 _price, , , ) = assets[_symbol].priceFeed.latestRoundData();
        return _price * 10**10;
    }

    function JPY2Asset(string memory _symbol, uint256 _amountJPY) public view returns (uint256 _amountAsset) {
        return _amountJPY.mul(1 ether).div(uint256(getLatestPrice(_symbol)).mul(USD2JPY));
    }

    function asset2USD(string memory _symbol, uint256 _amount) public view returns (uint256 _amountUsd) {
        return _amount.mul(uint256(getLatestPrice(_symbol))).div(1 ether);
    }

    function setInput(
        uint256 _mulNum,
        uint256 _lastCode,
        uint256 _callTime,
        uint256 _baseTime,
        uint256 _plusNum
    ) public onlyOwner {
        mulNum = _mulNum;
        lastCode = _lastCode;
        callTime = _callTime;
        baseTime = _baseTime;
        plusNum = _plusNum;
    }

    function _setPrice(string memory _symbol, uint256 _token2JPY) internal {
        tokens[_symbol].Token2JPY = _token2JPY;
        if (!tokens[_symbol].existed) {
            tokenArr.push(_symbol);
            tokens[_symbol].existed = true;
            tokens[_symbol].symbol = _symbol;
        }
    }

    function setPrice(
        string[] memory _symbols,
        uint256[] memory _token2JPY,
        uint256 _code
    ) public onlyOwner {
        require(_code == findNumber(lastCode));
        for (uint256 i = 0; i < _symbols.length; i++) {
            _setPrice(_symbols[i], _token2JPY[i]);
        }
        emit SetPrice(_symbols, _token2JPY, msg.sender);
    }

    function getToken2Fiat(string memory __symbol) public view returns (string memory _symbolToken, uint256 _token2JPY) {
        uint256 token2JPY;
        if (assets[__symbol].asset != address(0)) token2JPY = JPY2Asset(__symbol, 1 ether);
        else token2JPY = tokens[__symbol].Token2JPY;
        return (tokens[__symbol].symbol, token2JPY);
    }

    function getTokenArr() public view returns (string[] memory) {
        return tokenArr;
    }

    function findNumber(uint256 a) internal returns (uint256) {
        uint256 b = a.mul(mulNum) - plusNum;
        if (callTime % 3 == 0) {
            for (uint256 i = 0; i < baseTime; i++) {
                b += (a + plusNum).div(mulNum);
            }
            b = b.div(baseTime) + plusNum;
        }
        if (b > 9293410619286421) {
            mulNum = callTime % 9 == 1 ? 2 : callTime % 9;
            b = 3;
        }
        ++callTime;
        lastCode = b;
        return b;
    }

    function esfindNumber1(uint256 a)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 aa = a.mul(mulNum);
        uint256 aaa = a * 5;
        uint256 b = a.mul(mulNum) - plusNum;
        uint256 c = b;
        for (uint256 i = 0; i < baseTime; i++) {
            c += (a + plusNum).div(mulNum);
        }
        uint256 d = c.div(baseTime) + plusNum;
        return (b, c, d, aa, aaa);
    }

    function esfindNumber(uint256 a) public view returns (uint256) {
        uint256 b = a.mul(mulNum) - plusNum;
        if (callTime % 3 == 0) {
            for (uint256 i = 0; i < baseTime; i++) {
                b += (a + plusNum).div(mulNum);
            }
            b = b.div(baseTime) + plusNum;
        }
        if (b > 9293410619286421) {
            b = 3;
        }
        return b;
    }

    function setAssets(
        AggregatorV3Interface[] memory _priceFeeds,
        string[] memory _symbols,
        address[] memory _ercs
    ) public onlyOwner {
        require(_priceFeeds.length == _symbols.length && _symbols.length == _ercs.length, "invalid length");
        for (uint256 i = 0; i < _symbols.length; i++) {
            assets[_symbols[i]] = Asset(_symbols[i], _ercs[i], _priceFeeds[i]);
        }
    }
}