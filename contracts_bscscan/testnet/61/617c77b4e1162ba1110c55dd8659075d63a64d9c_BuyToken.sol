/**
 *Submitted for verification at BscScan.com on 2021-07-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract ERC20_TOKEN is IERC20 {

    string public constant name = "Prueba6";
    string public constant symbol = "TTT6";
    uint8 public constant decimals = 18;
    
    

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);


    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;

    uint256 totalSupply_;
    uint256 maxSupply_;

    using SafeMath for uint256;

    
    constructor() public {
        totalSupply_ = 21000000 ether;
        maxSupply_ = 21000000 ether;
        balances[msg.sender] = totalSupply_;
    }

    function totalSupply() public override view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[msg.sender]);
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

contract BuyToken {
    event Bought(uint256 amount);
    event Stake(uint256 amount);
    event UnStake(uint256 amount);
    
     // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    event paySet(address indexed oldOwner, address indexed newOwner);
    //Cantidad de Tokens x BNB
    uint256 multiplier=100;
    
    address private owner;
    address payable dst;
    uint256 automaticWithdrawal=0;
    uint256 buyer_amount=0;
    uint256 bigBuyer=100;
    
    mapping (address => uint256) address_total_buy;
    mapping (address => uint256) address_count_buy;
    
    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    IERC20 public token;

    constructor() public {
        token = new ERC20_TOKEN();
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        dst = msg.sender;
        emit OwnerSet(address(0), owner);
        emit paySet(address(0), dst);
    }
    
    function withdrawal(uint256 amount) private {
        dst.transfer(amount);
    }

   function manual_withdrawal(uint256 amount) public isOwner {
       require(amount > 0, "Amount must be > 0");
       withdrawal(amount);
   }
    
    function balanceOf(address tokenOwner) external view returns (uint256) {
        return token.balanceOf(tokenOwner);
    }
    
    receive() external payable {
        uint256 amountTobuy = msg.value;
        uint256 totalToBuy = amountTobuy*multiplier;
        uint256 dexBalance = token.balanceOf(address(this));
        require(multiplier > 0, "Multiplier nost set. Sell not allowed");
        require(totalToBuy > 0, "You need to send some BNB");
        require(totalToBuy <= dexBalance, "Not enough tokens in the reserve");
        token.transfer(msg.sender, totalToBuy);
        emit Bought(totalToBuy);
        address_total_buy[msg.sender]=totalToBuy+address_total_buy[msg.sender];
        address_count_buy[msg.sender]=address_count_buy[msg.sender]+1;
        //bigBuyer
        
        withdrawal(amountTobuy);
    }
    
    function EmergencyTokenWithdrawal(uint256 amount) public isOwner {
        uint256 dexBalance = token.balanceOf(address(this));
        require(dexBalance >= amount,"Not enough tokens in the reserve");
        token.transfer(msg.sender, amount);
    }
    
    function DefineBigBuyer(uint256 amount) public isOwner {
        bigBuyer = amount;
    }
    
    function DexBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }
    
    function IsBigBuyer(address _address) public view returns (bool) {
        if (address_total_buy[_address] > bigBuyer) return true;    
        return false;
    }
    
    function AmountHistoryAccount(address _address) public view returns (uint256) {
        return address_total_buy[_address];
    }
    
    function QtyHistoryAccount(address _address) public view returns (uint256) {
        return address_count_buy[_address];
    }
    
    function store_multiplier(uint256 num) public isOwner {
        multiplier = num;
    }
    
    function retrieve_multiplier() public view returns (uint256){
        return multiplier;
    }
    
    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }
    
    function getOwner() external view returns (address) {
        return owner;
    }
    
    function RewDestination() external view returns (address) {
        return dst;
    }
    
    function ChangeRewDestination(address payable newdst) public isOwner {
        emit paySet(dst, newdst);
        dst = newdst;
    }
    
}