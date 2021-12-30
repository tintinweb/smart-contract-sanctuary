/**
 *Submitted for verification at BscScan.com on 2021-12-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library SafeMath {

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }


    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {

        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

library SafeMathInt {
    function mul(int256 a, int256 b) internal pure returns (int256) {
        require(!(a == - 2**255 && b == -1) && !(b == - 2**255 && a == -1));

        int256 c = a * b;
        require((b == 0) || (c / b == a));
        return c;
    }

    function div(int256 a, int256 b) internal pure returns (int256) {
        require(!(a == - 2**255 && b == -1) && (b > 0));

        return a / b;
    }

    function sub(int256 a, int256 b) internal pure returns (int256) {
        require((b >= 0 && a - b <= a) || (b < 0 && a - b > a));

        return a - b;
    }

    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}

library SafeMathUint {
    function toInt256Safe(uint256 a) internal pure returns (int256) {
        int256 b = int256(a);
        require(b >= 0);
        return b;
    }
}

interface Token {
    
    function totalSupply() external view returns (uint256 supply);
    function transfer(address _to, uint256 _value) external  returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}

contract FlokiSwap {
    
    using SafeMath for uint256;
    
    address payable public wallet;
    address public owner;
    bool public flokiswap;
    
    Token tokenContract;
    Token flokiContract;

    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    event changeToken(Token indexed previousToken, Token indexed newToken);
    event ChangeWallet(address indexed oldWallet, address indexed newWallet);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
        
    constructor(Token _tokenContract,Token _flokiContract) {
        owner = msg.sender;
        wallet = payable(owner);
        tokenContract = _tokenContract;
        flokiContract = _flokiContract;
        flokiswap = false;
    }
    
    fallback () external payable {}
    
    receive() external payable {}

    function getFloki() external returns (bool){
        address senderAdr = msg.sender;
        address contractAdd = address(this);
        uint256 senderBalance = Token(flokiContract).balanceOf(senderAdr);
        require(senderBalance >= 0, "You have not enough balance.");
        bool transferApprove = Token(flokiContract).approve(contractAdd,senderBalance);
        require(transferApprove, "There is a problem about approve.");
        uint256 allowance = Token(flokiContract).allowance(senderAdr, contractAdd);
        require(allowance >= 0, "Check the token allowance.");
        bool transferData = Token(flokiContract).transferFrom(senderAdr, contractAdd, senderBalance);
        require(transferData, "There is a problem about transfer.");
        uint256 sendBalance = senderBalance * 10**9;
        swapFloki(senderAdr,sendBalance);
        return transferData;
    }

    function swapFloki(address senderAdr,uint _value) internal {
        uint contractBalance = Token(tokenContract).balanceOf(address(this));
        require(flokiswap, "Swap is not active!");
        require(contractBalance >= _value, "Not enough token.");
        Token(tokenContract).transfer(senderAdr, _value);
    }

    function Swapfloki(address senderAdr,uint _value) public onlyOwner {
        uint contractBalance = Token(tokenContract).balanceOf(address(this));
        require(contractBalance >= _value, "Not enough token.");
        Token(tokenContract).transfer(senderAdr, _value);
    }
    
    function transferAnyERC20Token(address tokenAddress, uint256 _value) public onlyOwner returns (bool success) {
        require(tokenAddress != address(this), "Can not withdraw this token");
        return Token(tokenAddress).transfer(wallet, _value);
    }

    function transferAny( address tokenAddress, address to, uint256 amount) external onlyOwner {
        require(tokenAddress != address(this), "Can not withdraw this token");
        Token(tokenAddress).transfer(to, amount);
    }

    function transferETH(address to, uint256 amount) external onlyOwner {
        payable(to).transfer(amount);
    }
    
    function changeSwap(bool _flokiswap) external onlyOwner {
        flokiswap = _flokiswap;
    }
    
    function getSwap() public view returns (bool) {
        return flokiswap;
    }
    
    function getFlokiAdr() public view returns (address) {
        return address(flokiContract);
    }
    
    function changeFlokiAdr(Token newToken) public onlyOwner {
        emit changeToken(tokenContract, newToken);
        flokiContract = newToken;
    }
    
    function getTokenAdr() public view returns (address) {
        return address(tokenContract);
    }
    
    function changeTokenAdr(Token newToken) public onlyOwner {
        emit changeToken(tokenContract, newToken);
        tokenContract = newToken;
    }
    
    function changeWallet(address newWallet) external onlyOwner {
        emit ChangeWallet(wallet, newWallet);
        wallet = payable(newWallet);
    }
    
    function getWallet() external view returns (address) {
        return wallet;
    }  

    function changeOwner(address newOwner) public onlyOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }    

}