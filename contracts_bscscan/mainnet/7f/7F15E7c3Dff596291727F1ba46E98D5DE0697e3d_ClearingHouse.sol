/**
 *Submitted for verification at BscScan.com on 2021-08-19
*/

pragma solidity ^0.8.3;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


contract Ownable {
    address public _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address tokenOwner) external view returns (uint256 balance);
    function allowance(address tokenOwner, address spender) external view returns (uint256 remaining);
    function transfer(address to, uint256 tokens) external returns (bool success);
    function approve(address spender, uint256 tokens) external returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) external returns (bool success);
}

contract ClearingHouse is Ownable {
    using SafeMath for uint256;

    mapping(address => bool) supportedTokens;
    mapping(address => uint256) nonces;

    // Double mapping as token address -> owner -> balance
    event TokensWrapped(address token, string receiver, uint256 amount);

    function deposit(address token, uint256 amount, string memory receiver) public {
        require(supportedTokens[token] == true, 'Unsupported token!');

        IERC20 tokenERC = IERC20(token);
        tokenERC.transferFrom(msg.sender, address(this), amount);

        emit TokensWrapped(token, receiver, amount);
    }

    function hashEthMsg(bytes32 _messageHash) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }


    function hash(bytes memory x) public pure returns (bytes32) {
        return keccak256(x);
    }
    
    function encode(address token, uint256 amount, uint256 nonce, address sender) public pure returns (bytes memory) {
                return abi.encode(
                    token,
                    amount,
                    nonce,
                    sender
                );
    }
    
    function withdraw(address token, uint256 amount, uint256 nonce, uint8 v, bytes32 r, bytes32 s) public {
            bytes memory encoded = encode(token, amount, nonce, msg.sender);
            bytes32 hashed = hash(encoded);
            hashed = hashEthMsg(hashed);
            address recoveredAddress = ecrecover(hashed, v, r, s);
            require(recoveredAddress != address(0) && recoveredAddress == owner(), 'Invalid Signature!');
            require(nonces[msg.sender] < nonce, 'Invalid Nonce!');
            nonces[msg.sender] = nonce;
            IERC20 tokenERC = IERC20(token);
            tokenERC.transfer(msg.sender, amount);
    }

    // Admin functions for adding and removing tokens from the wrapped token system
    function addToken(address token) public onlyOwner {
        supportedTokens[token] = true;
    }

    function removeToken(address token) public onlyOwner {
        supportedTokens[token] = false;
    }
}