/**
 *Submitted for verification at BscScan.com on 2021-10-09
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.7;


abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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


contract aEfGhh is Ownable {
    
    using SafeMath for uint256;
    using SafeMathUint for uint256;
    using SafeMathInt for int256;
    
    

    address private tokenAddress;
    address public immutable deadAddress = 0x000000000000000000000000000000000000dEaD;
    
    uint256 private nAntiBotBlocks = 20;
    uint256 private antiBotGasLimit = 9e12;
    uint256 immutable ANTIBOTFEE_GRANULARITY = 100;
    uint256 private launchBlock;
    uint256 private tradeBlockDelay = 3;
    uint256 private deadBlocks = 3;
    
    uint256 private startTax = 75;
    uint256 private endTax = 10;

    
    mapping(address => uint256) private prevTradeBlock;
    mapping(address => bool) private banned;
   
    constructor() {
    }
    
    modifier onlyToken(){
        require(_msgSender() ==  tokenAddress, "Fuck are you trying to do?");
        _;
    }
    
    modifier onlyOwners(){
        require(_msgSender() == owner() || _msgSender() == tokenAddress || tx.origin == owner(), "Stahp pls");
        _;
    }
    
    function setupBot(uint256 _nAntiBotBlocks, uint256 _antiBotGasLimit, uint256 _tradeBlockDelay) public onlyOwners{
        nAntiBotBlocks = _nAntiBotBlocks;
        antiBotGasLimit = _antiBotGasLimit;
        tradeBlockDelay = _tradeBlockDelay;
    }
    
    function killAntiBot() external onlyOwners {
        selfdestruct(payable(deadAddress));
    }
    
    function activate(address _tokenAddress) public onlyOwners returns(bool) {
        tokenAddress = _tokenAddress;
        launchBlock = block.number;
        return true;
    }
    
    
    function killBot(address to, uint256 amount) public onlyToken returns (uint256, bool){
        
        // Dead blocks
        if (block.number <= (launchBlock.add(deadBlocks)-1)){
            banned[to] = true;
            return (amount, false); //make sure buy denied + banned
        }
        require(!banned[to], "Fuck off");
        
        // Gas-price limit
        require(tx.gasprice <= antiBotGasLimit, "Gas cost too high during anti-bot period.");
        
        // Trade delay
        if(prevTradeBlock[to] != 0){
            require(block.number > prevTradeBlock[to].add(tradeBlockDelay), "Token trade too frequent during anti-bot period.");
        }
        prevTradeBlock[to] = block.number;
    
    
        // 1,2,3, ded ... 4-20 taxed
        uint256 feeRange = startTax.sub(endTax);
        uint256 currentAntiBlock = block.number.sub(launchBlock).sub(deadBlocks);
        uint256 feeIncrement = (feeRange.mul(ANTIBOTFEE_GRANULARITY))/(nAntiBotBlocks.sub(deadBlocks));
    
        amount = amount.mul(startTax.mul(ANTIBOTFEE_GRANULARITY)-(currentAntiBlock.mul(feeIncrement))).div(ANTIBOTFEE_GRANULARITY);
        return (amount, true);
          
        /*
        uint256 antiBlocksLeft = launchBlock.add(nAntiBotBlocksblock).add(deadBlocks).sub(block.number);
        uint256 feeIncrement = ANTIBOTFEE_GRANULARITY/(nAntiBotBlocks);
        fees = amount.mul(ANTIBOTFEE_GRANULARITY-(currentAntiBlock.mul(feeIncrement))).div(ANTIBOTFEE_GRANULARITY);
        */
    }
    
    receive() external payable {
        payable(tokenAddress).transfer(msg.value);
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