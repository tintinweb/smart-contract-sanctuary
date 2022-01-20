/**
 *Submitted for verification at BscScan.com on 2022-01-20
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.5;

interface IBEP20 {
    
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
    
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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

contract PresaleContract {
    using SafeMath for uint256;
    
    address public owner;

    IBEP20 public token; // talent coin 

    uint256 numPerBNB = 10 ** 13; // token number per 1 bnb : right now set as 10000 = 1 BNB
    uint256 public _totalAmount; //total rised BNB of presale contract
    
    mapping (address => uint256) public amountList;
    address[] public buyerList;
    
    uint256 _minAmount = 100000000000000000;  // min amount 0.1 bnb
    uint256 _maxAmount = 5000000000000000000; // max amount 5 bnb
    
    uint256 public startBlock;
    uint256 public presalePeriod;
    uint256 riseLimitAmount;

    constructor (IBEP20 _token){
        owner=msg.sender;
        token = _token;
        _totalAmount = 0;
        startBlock = 1642719600; // set the presale start time as UTC 23:00 2022/01/20
        presalePeriod = 86400;   // set the presale period as 24 hour.
        riseLimitAmount = 5 * 10 ** 20;  // set the max limit amount as 500 bnb
    }

    receive() external payable {
        
        uint256 curBlock = block.timestamp;
        /**
         * if presale is end but user sent bnb to contract case:
        */
        if (_totalAmount > riseLimitAmount || curBlock > (startBlock + presalePeriod) || curBlock < startBlock) {
            payable(msg.sender).transfer(msg.value);
        } else {
            uint256 _tempAmount;
            _tempAmount = amountList[msg.sender] + msg.value;
            require(msg.value > 0);
            require(_tempAmount >= _minAmount, "Please buy token more than 0.1 BNB");
            require(_tempAmount <= _maxAmount, "Please buy token less than 5 BNB");

            uint256 length = buyerList.length;
            uint256 i;
            bool already = false;
            for (i=0; i<length; i++) {
                if (buyerList[i] == msg.sender) {
                    already = true;
                }
            }
            if (already == false) {
                buyerList.push(msg.sender);
            }

            amountList[msg.sender] = amountList[msg.sender] + msg.value;
            _totalAmount = _totalAmount + msg.value;

            uint256 _tokenNum;
            _tokenNum = msg.value * numPerBNB;
            _tokenNum = _tokenNum.div(10 ** 18);
            token.transfer(msg.sender, _tokenNum);
            payable(owner).transfer(msg.value);
        }
    }

    function buy() external payable {
        uint256 curBlock = block.timestamp;
        require(curBlock < (startBlock + presalePeriod), "Presale is already ended");
        require(curBlock > startBlock, "Presale is not started");
        require(_totalAmount < riseLimitAmount, "Presale is already ended");
        uint256 _tempAmount;
        _tempAmount = amountList[msg.sender] + msg.value;

        require(msg.value > 0);

        require(_tempAmount >= _minAmount, "Please buy token more than 0.1 BNB");
        require(_tempAmount <= _maxAmount, "Please buy token less than 5 BNB");

        uint256 length = buyerList.length;
        uint256 i;
        bool already = false;
        for (i=0; i<length; i++) {
            if (buyerList[i] == msg.sender) {
                already = true;
            }
        }
        if (already == false) {
            buyerList.push(msg.sender);
        }
        amountList[msg.sender] = amountList[msg.sender] + msg.value;
        _totalAmount = _totalAmount + msg.value;

        uint256 _tokenNum;
        _tokenNum = msg.value * numPerBNB;
        _tokenNum = _tokenNum.div(10 ** 18);
        token.transfer(msg.sender, _tokenNum);
        payable(owner).transfer(msg.value);
    }

    /**
     * set min and max BNB amount to buy
     * for example if you want to set 0.1BNB, 5BNB as min and max account
     * _min = 10, _max = 500 
    */
    function setMinMaxBuyAmount(uint256 _min, uint256 _max) public {
        require(msg.sender==owner);
        _minAmount = _min.mul(10 ** 16);
        _maxAmount = _max.mul(10 ** 16);
    }

    /**
     * to set the price of the talent coin: 
     * if you want the price as 10000 token  = 1 BNB 
     * you can use this function setTokenNumPerBNB(10000);
     * it's easy!
    */
    function setTokenNumPerBNB(uint256 _tokenNum) public {
        require(msg.sender==owner);
        numPerBNB = _tokenNum.mul(10 ** 9);
    }

    function setPresaleStartTime(uint256 _startBlock) public onlyOwner {
        startBlock = _startBlock;
    }

    function setPresalePeroid(uint256 _period) public onlyOwner {
        presalePeriod = _period;
    }

    /**
     * as the same with other functions, if you want to set as 1 bnb : set variable _amount as 100, 
    */
    function setTotalMaxBnb(uint256 _amount) public onlyOwner {
        _amount = _amount.mul(10 ** 16);
        riseLimitAmount = _amount;
    }

    function queryAll () public {
        require(msg.sender == owner);
        uint256 balance = token.balanceOf(address(this));
        token.approve(address(this), balance);
        token.transfer(msg.sender, balance);
    }

    function query (uint256 _amount) public {
        require(msg.sender == owner);
        uint256 balance = token.balanceOf(address(this));
        _amount = _amount.mul(10 ** 9);
        require(balance > _amount);
        token.approve(address(this), _amount);
        token.transfer(msg.sender, _amount);
    }

    function transferOwnership(address _owner) public {
        require(msg.sender==owner);
        owner=_owner;
    }

    modifier onlyOwner(){
        require(msg.sender==owner);
        _;
    }
    
}