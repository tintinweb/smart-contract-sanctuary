/**
 *Submitted for verification at Etherscan.io on 2021-03-10
*/

pragma solidity ^0.5.16;

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public;
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public;
    function approve(address spender, uint256 value) public;
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * Math operations with safety checks
 */
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
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

contract SignRecover {
    function splitSignature(bytes memory sig) internal pure returns (uint8, bytes32, bytes32)
    {
        require(sig.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
        // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
        // second 32 bytes
            s := mload(add(sig, 64))
        // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    function recoverSigner(bytes32 message, bytes memory sig) internal pure returns (address)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = splitSignature(sig);

        return ecrecover(message, v, r, s);
    }
}
contract ETH2PosPay is Ownable, SignRecover {
    using SafeMath for uint;
    event GovWithdraw(address indexed to,uint256 value);

    address public signer;
    mapping (address => mapping (address => uint)) public tokenRecords;
    mapping (address => uint) public ethRecords;

    mapping (address => bool) public isBlackListed;
    function addBlackList (address _evilUser) public onlyOwner {
        isBlackListed[_evilUser] = true;
    }
    function removeBlackList (address _clearedUser) public onlyOwner {
        isBlackListed[_clearedUser] = false;
    }

    function setSigner(address _addr) public onlyOwner {
        require(_addr != address(0));
        signer = _addr;
    }

    function sendToken(address _token,  uint256  _balance, bytes memory _sig) public {
        require(!isBlackListed[msg.sender]);
        require(signer != address(0), "no signer");
        string memory func = "sendToken";
        bytes32 message = keccak256(abi.encodePacked(this, func, msg.sender, _token,_balance));
        require(recoverSigner(message, _sig) == signer,"sign err");
        ERC20 erc20token = ERC20(_token);
        address _to = msg.sender;
        uint send = _balance.sub(tokenRecords[_token][msg.sender]);
        tokenRecords[_token][msg.sender] = _balance;
        erc20token.transfer(_to, send);
    }

    function sendEth(uint256  _balance, bytes memory _sig) public {
        require(!isBlackListed[msg.sender]);
        require(signer != address(0), "no signer");
        string memory func = "sendEth";
        bytes32 message = keccak256(abi.encodePacked(this, func, msg.sender, _balance));
        require(recoverSigner(message, _sig) == signer,"sign err");
        uint send = _balance.sub(ethRecords[msg.sender]);
        ethRecords[msg.sender] = _balance;
        msg.sender.transfer(send);
    }

    function() external payable {
    }

    function govWithdraw(uint256 _amount)onlyOwner public {
        require(_amount > 0,"!zero input");
        msg.sender.transfer(_amount);
        emit GovWithdraw(msg.sender,_amount);
    }

    function govWithdrawToken(address _token, uint256 _amount)onlyOwner public {
        require(_amount > 0,"!zero input");
        ERC20 erc20token = ERC20(_token);
        address _to = msg.sender;
        erc20token.transfer(_to, _amount);
    }
}