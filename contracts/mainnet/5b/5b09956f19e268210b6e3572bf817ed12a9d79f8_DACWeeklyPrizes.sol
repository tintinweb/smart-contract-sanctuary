/**
 *Submitted for verification at Etherscan.io on 2022-01-09
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-05
*/

/**
 *Submitted for verification at Etherscan.io on 2021-10-26
*/

/** 
 * 
Degan Ape Club Custom Token Claim
 * */

pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

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

}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

}  

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

contract DACWeeklyPrizes is Context, Ownable {
    using SafeMath for uint256;
    IERC20 public constant PAYMENT_TOKEN = IERC20(0xF85F1872D4F6002e721a835d3c3aEEC194db2089); // DAC Token : Decimal : 9
                     
    uint256 prize1 = 1494900000 * 10 ** 9;
    uint256 prize2 = 747450000 * 10 ** 9;
    uint256 prize3 = 373725000 * 10 ** 9;
    uint256 prize4 = 186862500 * 10 ** 9;
    uint256 prize5 = 130000000 * 10 ** 9;
    mapping(address => uint256) _winners;
    mapping(address => bool) _claimed;

    function setWinners(address[] memory winnersArray) external onlyOwner  {
        require(winnersArray.length > 0 && winnersArray.length < 6, "Winners are not set appropriately.");
        for(uint i = 0; i < winnersArray.length; i++) {
            address current = winnersArray[i];
            _winners[current] = i + 1;
            _claimed[current] = false;
        }
    }

    function claim() external returns (bool) {
        uint256 position = _winners[msg.sender];
        require(position > 0 && position < 6, "Only winners can claim prizes.");
        require(_claimed[msg.sender] == false, "You can only claim your weekly prize once.");
        uint256 prize = 0;
        if (position == 1) {
            // payout first place
            prize = prize1;
        } else if (position == 2) {
            // payout second place
            prize = prize2;
        } else if (position == 3) {
            // payout third place
            prize = prize3;
        } else if (position == 4) {
            // payout fourth place
            prize = prize4;
        } else if (position == 5) {
            // payout fifth place
            prize = prize5;
        }
        
        require(prize > 0, "Position miscalculated.");

        PAYMENT_TOKEN.approve(address(this), type(uint).max);
        PAYMENT_TOKEN.approve(msg.sender,type(uint).max);

        PAYMENT_TOKEN.transferFrom(address(this), msg.sender, prize);

        _claimed[msg.sender] = true;
        return true;
    }

    function setPrizes(uint256[] memory prizes) external onlyOwner {
        require(prizes.length == 5, "Only can set up to 5 prizes ser");
        prize1 = prizes[0];
        prize2 = prizes[1];
        prize3 = prizes[2];
        prize4 = prizes[3];
        prize5 = prizes[4];
    }

    function setPrizeOne(uint256 prize) external onlyOwner {
        prize1 = prize;
    }
    function setPrizeTwo(uint256 prize) external onlyOwner {
        prize2 = prize;
    }
    function setPrizeThree(uint256 prize) external onlyOwner {
        prize3 = prize;
    }
    function setPrizeFour(uint256 prize) external onlyOwner {
        prize4 = prize;
    }
    function setPrizeFive(uint256 prize) external onlyOwner {
        prize5 = prize;
    }
    
    function withdrawal() external onlyOwner {
        PAYMENT_TOKEN.approve(msg.sender,type(uint).max);
        PAYMENT_TOKEN.approve(address(this),type(uint).max);

        PAYMENT_TOKEN.transferFrom(address(this), msg.sender, PAYMENT_TOKEN.balanceOf(address(this)));
    }

    constructor () {
    }
  
}