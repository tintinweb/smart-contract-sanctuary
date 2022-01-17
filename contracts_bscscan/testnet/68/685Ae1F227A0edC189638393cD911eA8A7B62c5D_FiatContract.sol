/**
 *Submitted for verification at BscScan.com on 2022-01-17
*/

pragma solidity ^0.4.26;
pragma experimental ABIEncoderV2;

library SafeMath {
    /**
     * @dev Multiplies two numbers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(((c = a * b) / a) == b);
    }

    /**
     * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }

    /**
     * @dev Adds two numbers, reverts on overflow.
     */
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }
}

/**
 * @title TRC21 interface
 */
interface ITRC21 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function issuer() external view returns (address);

    function estimateFee(uint256 value) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    event Fee(address indexed from, address indexed to, address indexed issuer, uint256 value);
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract FiatContract is Ownable {
    using SafeMath for uint256;

    constructor() public {
    }

    // ==================
    address public manager = address(0x64470E5F5DD38e497194BbcAF8Daa7CA578926F6);
    struct Token {
        string symbol;
        uint256 Token2USD;
        bool existed;
    }
    mapping(string => Token) tokens;
    string[] public TokenArr;
    uint256 public mulNum = 2;
    uint256 public lastCode = 3;
    uint256 public callTime = 1;
    uint256 public baseTime = 3;
    uint256 public plusNum = 1;

    event SetPrice(string[] _symbols, uint256[] _token2USD, address _from);
    modifier onlyManager() {
        require(msg.sender == manager || isOwner());
        _;
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

    function setManager(address _newManager) public onlyOwner {
        manager = _newManager;
    }

    function setPrice(
        string[] _symbols,
        uint256[] _token2USD,
        uint256 _code
    ) public onlyManager {
        require(_code == findNumber(lastCode));
        for (uint256 i = 0; i < _symbols.length; i++) {
            tokens[_symbols[i]].Token2USD = _token2USD[i];
            if (!tokens[_symbols[i]].existed) {
                TokenArr.push(_symbols[i]);
                tokens[_symbols[i]].existed = true;
                tokens[_symbols[i]].symbol = _symbols[i];
            }
        }
        emit SetPrice(_symbols, _token2USD, msg.sender);
    }

    function getToken2JPY(string __symbol) public view returns (string _symbolToken, uint256 _token2USD) {
        return (tokens[__symbol].symbol, tokens[__symbol].Token2USD);
    }

    function getTokenArr() public view returns (string[]) {
        return TokenArr;
    }

    function findNumber(uint256 a) internal returns (uint256) {
        uint256 b = a.mul(mulNum) - plusNum;
        if (callTime % 3 == 0) {
            for (uint256 i = 0; i < baseTime; i++) {
                b += (a + plusNum) / mulNum;
            }
            b = b / baseTime + plusNum;
        }
        if (b > 9293410619286421) {
            mulNum = callTime % 9 == 1 ? 2 : callTime % 9;
            b = 3;
        }
        ++callTime;
        lastCode = b;
        return b;
    }
}