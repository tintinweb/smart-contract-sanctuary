/**
 *Submitted for verification at BscScan.com on 2021-09-30
*/

pragma solidity ^0.8.6;

//SPDX-License-Identifier: MIT Licensed

interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract LcpPreSale {
    IBEP20 public token;
    using SafeMath for uint256;

    address payable public owner;

    uint256 public tokenPerBnb;
    uint256 private minAmount;
    uint256 private maxAmount;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public amountRaised;
    uint256 public soldToken;
    uint256 public referralpercent;

    mapping(address => uint256) public preSaleBalance;

    modifier onlyOwner() {
        require(msg.sender == owner, "BEP20: Not an owner");
        _;
    }

    event BuyToken(address _user, uint256 _amount);

    constructor(address payable _owner, address _token) {
        owner = _owner;
        token = IBEP20(_token);
        tokenPerBnb = 50000;
        minAmount = 0.01 ether;
        maxAmount = 1 ether;
        startTime = block.timestamp;
        endTime = block.timestamp.add(20 days);
        referralpercent = 20;
    }

    receive() external payable {
        buyToken(owner);
    }

    // to buy token during preSale time => for web3 use
    function buyToken(address _referral) public payable {
        uint256 numberOfTokens = bnbToToken(msg.value);
        uint256 maxToken = bnbToToken(maxAmount);
        require(
            numberOfTokens.add(preSaleBalance[msg.sender]) <= maxToken,
            "PRESALE: Amount exceeded max limit"
        );
        require(
            msg.value >= minAmount && msg.value <= maxAmount,
            "PRESALE: Amount not correct"
        );
        require(
            block.timestamp >= startTime && block.timestamp < endTime,
            "PRESALE: PreSale over"
        );
        preSaleBalance[msg.sender] = preSaleBalance[msg.sender].add(
            numberOfTokens
        );

        token.transferFrom(owner, msg.sender, numberOfTokens);
        token.transferFrom(
            owner,
            _referral,
            numberOfTokens.mul(referralpercent).div(100)
        );
        amountRaised = amountRaised.add(msg.value);
        soldToken = soldToken.add(numberOfTokens);
        emit BuyToken(msg.sender, numberOfTokens);
    }

    // to check number of token for given BNB
    function bnbToToken(uint256 _amount) public view returns (uint256) {
        uint256 numberOfTokens = _amount.mul(tokenPerBnb).div(1e18);
        return numberOfTokens.mul(1e9);
    }

    function getCurrentTime() external view returns (uint256) {
        return block.timestamp;
    }

    // to change price
    function setPriceOfToken(uint256 _price) external onlyOwner {
        tokenPerBnb = _price;
    }

    // change presale limits
    function setPreSaletLimits(uint256 _minAmount, uint256 _maxAmount)
        external
        onlyOwner
    {
        minAmount = _minAmount;
        maxAmount = _maxAmount;
    }

    // to ref percent
    function setRefPercent(uint256 _percent) external onlyOwner {
        referralpercent = _percent;
    }

    // transfer ownership
    function changeOwner(address payable _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    //change token
    function setToken(address newtoken) public onlyOwner {
        token = IBEP20(newtoken);
    }

    // change presale time
    function changeTime(uint256 _startTime, uint256 _endTime) public onlyOwner {
        startTime = _startTime;
        endTime = _endTime;
    }

    // to draw funds for liquidity
    function migrateFunds(uint256 _value) external onlyOwner {
        owner.transfer(_value);
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getContractTokenBalance() external view returns (uint256) {
        return token.allowance(owner, address(this));
    }
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
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