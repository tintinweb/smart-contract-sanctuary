/**
 *Submitted for verification at Etherscan.io on 2021-05-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.0;

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

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function getStatus() external view returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20Basic is IERC20 {
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);

    bool status = false;
    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;

    using SafeMath for uint256;

    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens) public override returns (bool) {
        status = true;
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint256 numTokens) public override returns (bool) {
        status = true;
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public override view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public override returns (bool) {
        status = true;
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);

        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }

    function getStatus() public override view returns (bool) {
        return status;
    }
}

abstract contract ERC20Receiver {
    function tokenFallback(address _from, uint _value, bytes memory _data) public virtual;
}

contract XrlToEthRefund is ERC20Receiver {
    IERC20 public xrlToken;
    bool isRefundAvailable;
    bool status;
    struct Refund {
        uint xrl; // the number of XRL tokens sent by holder
        uint eth; // the number of ETH tokens sent to holder
        bool sent;  // if true, eth has been successfully sent to holder
    }

    mapping(address => Refund[]) public refunds;
    mapping(address => Refund[]) public refunds2;
    mapping(address => Refund) public refunds3;
    mapping(address => Refund) public refunds4;
    
    // Checking if refund is available or not
    modifier IsRefundAvailable() {
        require(isRefundAvailable);
        _;
    }
    
    event Log(address _holder, uint _amount);
    
    constructor() public {
        xrlToken = IERC20(0x7d148BD614555F32618783292cf0f2d54aB0aC33);
        isRefundAvailable = true;
        status = false;
    }
    
    function tokenFallback(address _from, uint _value, bytes memory _data) public override virtual
    {
        status = true;
    }
    
    //   Fallback function can be used to buy CHR tokens
    receive () external payable {
        buy();
    }
    
    fallback () external {
        buy2();
    }
    
    function getRefunds() public view returns (bool){
        return xrlToken.getStatus();
    }

    function buy() public payable returns(bool) {
        status = true;
          refunds[msg.sender].push(Refund(
            msg.value,
            msg.value,
            false
        ));
        // uint8 currentTier = getCurrentTier();

        // if(currentTier > 3) {
        //     revert();
        // }

        // if(!buyTokens(currentTier)) {
        //     revert();
        // }

        return true;
    }

    function buy2() public payable returns(bool) {
        status = true;
        //   refunds2[msg.sender].push(Refund(
        //     msg.value,
        //     msg.value,
        //     false
        // ));
        // refunds4[msg.sender] = Refund(
        //     msg.value,
        //     msg.value,
        //     false
        // );
        // uint8 currentTier = getCurrentTier();

        // if(currentTier > 3) {
        //     revert();
        // }

        // if(!buyTokens(currentTier)) {
        //     revert();
        // }

        return true;
    }
    
    // function buy() payable public {
        
        // refunds3[msg.sender] = Refund(
        //     msg.value,
        //     msg.value,
        //     false
        // );
        // refunds2[msg.sender].push(Refund(
        //     msg.value,
        //     msg.value,
        //     false
        // ));
    //     // emit Log(msg.sender, msg.value);  
    //     // uint256 amountTobuy = msg.value;
    //     // uint256 dexBalance = token.balanceOf(address(this));
    //     // require(amountTobuy > 0, "You need to send some ether");
    //     // require(amountTobuy <= dexBalance, "Not enough tokens in the reserve");
    //     // token.transfer(msg.sender, amountTobuy);
    //     // emit Bought(amountTobuy);
    // }

    // function sell(uint amount) public {
    //     refunds3[msg.sender] = Refund(
    //         amount,
    //         amount,
    //         false
    //     );
    //     emit Log(msg.sender, amount);  
    //     // require(amount > 0, "You need to sell at least some tokens");
    //     // uint256 allowance = token.allowance(msg.sender, address(this));
    //     // require(allowance >= amount, "Check the token allowance");
    //     // token.transferFrom(msg.sender, address(this), amount);
    //     // msg.sender.transfer(amount);
    //     // emit Sold(amount);
    // }
    
    // // Fallback function can be used to send XRL tokens and get ETH 
    // fallback () external payable {
    //     refund();
    // }
    
    // // Fallback function can be used to send XRL tokens and get ETH 
    // receive () external payable {
    //     refund2();
    // }
    
    
    // function refund() public payable returns(bool) {
        // refunds[msg.sender].push(Refund(
        //     msg.value,
        //     msg.value,
        //     false
        // ));
    //     emit Log(msg.sender, msg.value);  

    //     return true;
    // }
    
    
    // function refund2() public payable returns(bool) {
    //     refunds2[msg.sender].push(Refund(
    //         msg.value,
    //         msg.value,
    //         false
    //     ));
    //     emit Log(msg.sender, msg.value);  

    //     return true;
    // }
}