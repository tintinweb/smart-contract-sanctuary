/**
 *Submitted for verification at BscScan.com on 2021-09-27
*/

// SPDX-License-Identifier: GPL-3.0-or-later Or MIT
pragma solidity ^0.6.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
       
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IBEP20 {
    function balanceOf(address account) external view returns (uint256);

    function allowance(address _owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool ok);
}

contract PXSPrivateSale {
    using SafeMath for uint256;

    IBEP20 public PXS;
    
    address payable public owner;

    
    uint256 public totalTokensToSell = 81000000000 * 10**18;          // 81000000000 PXS tokens for sell
    uint256 public PXSPerBnb = 30000000 * 10**18;             // 1 BNB = 30000000 PXS
    uint256 public minPerTransaction = 3000000 * 10**18;         // min amount per transaction (0.1BNB)
    uint256 public maxPerUser = 150000000 * 10**18;                // max amount per user (5BNB)
    uint256 public totalSold;

    bool public saleEnded;
    
    mapping(address => uint256) public PXSPerAddresses;

    event tokensBought(address indexed user, uint256 amountSpent, uint256 amountBought, string tokenName, uint256 date);
    event tokensClaimed(address indexed user, uint256 amount, uint256 date);

    modifier checkSaleRequirements(uint256 buyAmount) {
        require(saleEnded == false, 'Sale ended');
        require(
            buyAmount > 0 && buyAmount <= unsoldTokens(),
            'Insufficient buy amount'
        );
        _;
    }

    constructor(
        address _PXS        
    ) public {
        owner = msg.sender;
        PXS = IBEP20(_PXS);
    }

    function buyWithBNB(uint256 buyAmount) public payable checkSaleRequirements(buyAmount) {
        uint256 amount = calculateBNBAmount(buyAmount);
        require(msg.value >= amount, 'Insufficient BNB balance');
        require(buyAmount >= minPerTransaction, 'Lower than the minimal transaction amount');
        
        uint256 sumSoFar = PXSPerAddresses[msg.sender].add(buyAmount);
        require(sumSoFar <= maxPerUser, 'Greater than the maximum purchase limit');

        PXSPerAddresses[msg.sender] = sumSoFar;
        totalSold = totalSold.add(buyAmount);
        
        PXS.transfer(msg.sender, buyAmount);
        emit tokensBought(msg.sender, amount, buyAmount, 'BNB', now);
    }

    function changeOwner(address payable _owner) public {
        require(msg.sender == owner);
        owner = _owner;
    }
   
    function setTotalTokensToSell(uint256 _totalTokensToSell) public {
        require(msg.sender == owner);
        totalTokensToSell = _totalTokensToSell;
    }

    function setMinPerTransaction(uint256 _minPerTransaction) public {
        require(msg.sender == owner);
        minPerTransaction = _minPerTransaction;
    }

    function setMaxPerUser(uint256 _maxPerUser) public {
        require(msg.sender == owner);
        maxPerUser = _maxPerUser;
    }

    function setTokenPricePerBNB(uint256 _PXSPerBnb) public {
        require(msg.sender == owner);
        require(_PXSPerBnb > 0, "Invalid PXS price per BNB");
        PXSPerBnb = _PXSPerBnb;
    }

    function endSale() public {
        require(msg.sender == owner && saleEnded == false);
        saleEnded = true;
    }


    function withdrawCollectedTokens() public {
        require(msg.sender == owner);
        require(address(this).balance > 0, "Insufficient balance");
        owner.transfer(address(this).balance);
    }

    function withdrawUnsoldTokens() public {
        require(msg.sender == owner);
        uint256 remainedTokens = unsoldTokens();
        require(remainedTokens > 0, "No remained tokens");
        PXS.transfer(owner, remainedTokens);
    }

    function unsoldTokens() public view returns (uint256) {
        return PXS.balanceOf(address(this));
    }

    function calculatePXSAmount(uint256 bnbAmount) public view returns (uint256) {
        uint256 PXSAmount = PXSPerBnb.mul(bnbAmount).div(10**18);
        return PXSAmount;
    }

    //function to calculate the quantity of bnb needed using its PXS price to buy `buyAmount` of PXS tokens.
    function calculateBNBAmount(uint256 PXSAmount) public view returns (uint256) {
        require(PXSPerBnb > 0, "PXS price per BNB should be greater than 0");
        uint256 bnbAmount = PXSAmount.mul(10**18).div(PXSPerBnb);
        return bnbAmount;
    }
}