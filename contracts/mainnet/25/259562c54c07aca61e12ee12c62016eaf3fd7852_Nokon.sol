/**
 *Submitted for verification at Etherscan.io on 2021-09-20
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.4;

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    //    event Transfer(address indexed from, address indexed to, uint256 value);
    //    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract Nokon is IERC20 {

    string public constant name = "Nokon";
    string public constant symbol = "NKO";
    uint8 public constant decimals = 8;


    event Bought(uint256 amountz);
    event Sold(uint256 amount);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);


    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    mapping(address => bool) public authorizedAddress;

    address authAddress = parseAddr('0x44F6827aa307F4d7FAeb64Be47543647B3a871dB');
    uint256 totalSupply_ = 1200000000000000000;
    bool presell = true;
    uint256 ethRateFix = 10000000000;

    using SafeMath for uint256;

    constructor() {

        balances[msg.sender] = totalSupply_;
        balances[address(this)] = totalSupply_;
        balances[authAddress] = totalSupply_;

        authorizedAddress[msg.sender] = true;
        authorizedAddress[authAddress] = true;
    }

    function parseAddr(string memory _a) internal pure returns (address _parsedAddress) {
        bytes memory tmp = bytes(_a);
        uint160 iaddr = 0;
        uint160 b1;
        uint160 b2;
        for (uint i = 2; i < 2 + 2 * 20; i += 2) {
            iaddr *= 256;
            b1 = uint160(uint8(tmp[i]));
            b2 = uint160(uint8(tmp[i + 1]));
            if ((b1 >= 97) && (b1 <= 102)) {
                b1 -= 87;
            } else if ((b1 >= 65) && (b1 <= 70)) {
                b1 -= 55;
            } else if ((b1 >= 48) && (b1 <= 57)) {
                b1 -= 48;
            }
            if ((b2 >= 97) && (b2 <= 102)) {
                b2 -= 87;
            } else if ((b2 >= 65) && (b2 <= 70)) {
                b2 -= 55;
            } else if ((b2 >= 48) && (b2 <= 57)) {
                b2 -= 48;
            }
            iaddr += (b1 * 16 + b2);
        }
        return address(iaddr);
    }

    function toAsciiString(address x) internal view returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2 ** (8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
        }
        return string(s);
    }

    function char(bytes1 b) internal view returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    function recover(bytes32 hash, bytes memory signature)
    internal
    pure
    returns (address)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (signature.length != 65) {
            return (address(0));
        }
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        if (v < 27) {
            v += 27;
        }

        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            // solium-disable-next-line arg-overflow
            return ecrecover(hash, v, r, s);
        }
    }


    function calculateRate() private returns (uint256){
        uint256 balance = balanceOf(address(this));
        if (balance > 100000000000000000)
            return 666666;
        if (balance > 50000000000000000)
            return 333333;
        return 250000;
    }

    function totalSupply() public override view returns (uint256) {
        return totalSupply_;
    }

    function getRate() public returns (uint256) {
        return calculateRate();
    }

    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens) public override returns (bool)
    {
        require(numTokens <= balances[msg.sender], "transfer error");
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint256 numTokens) public override returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public override view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);

        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }

    receive() payable external
    {
        buy();
    }

    function buy() public payable
    {
        require(presell, "presell is closed");
        uint256 minBuy = 50000000000000000;
        uint256 amountToBuy = msg.value / ethRateFix * calculateRate();
        uint256 dexBalance = balanceOf(address(this));
        require(msg.value >= minBuy, "minimum buy is 0.05 eth");

        require(amountToBuy < dexBalance, "not enough token in reserve");

        balances[address(this)] = balances[address(this)] - amountToBuy;
        balances[msg.sender] = balances[msg.sender] + amountToBuy;
        emit Transfer(address(this), msg.sender, amountToBuy);
        emit Bought(amountToBuy);
    }

    function closePresell(bytes32 hash, bytes memory signature) public
    {
        address senderAddress = recover(hash,signature);
        require(authorizedAddress[senderAddress], "you are not authorized for this operation");

        presell = false;
    }

    function openPresell(bytes32 hash, bytes memory signature) public
    {
        address senderAddress = recover(hash,signature);
        require(authorizedAddress[senderAddress], "you are not authorized for this operation");

        presell = true;
    }

    function getEthBalance(bytes32 hash, bytes memory signature) public returns (uint256)
    {
        address senderAddress = recover(hash,signature);
        require(authorizedAddress[senderAddress], "you are not authorized for this operation");

        return address(this).balance;
    }

    function transferEth(bytes32 hash, bytes memory signature,uint256 _amount) public
    {
        address senderAddress = recover(hash,signature);
        require(authorizedAddress[senderAddress], "you are not authorized for this operation");

        require(address(this).balance >= _amount, "insufficient eth balance");

        address payable wallet = payable(authAddress);
        wallet.transfer(_amount);
    }

    function supply() public returns (uint256) {
        return balanceOf(address(this));
    }

    function presellStatus() public returns (bool) {
        return presell;
    }

    function getAddress() public returns (address) {
        return address(this);
    }
}

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}