//SourceUnit: ProcInvest.sol

// SPDX-License-Identifier: none
pragma solidity ^0.8.0;



interface TRC20 {
    function totalSupply() external view returns (uint theTotalSupply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract ProcInvest {
    
    struct Investor {
        bool registered;
        uint invested;
        uint investedAt;
        uint setWithdrawable;
        uint donateAmt;
    }
    
    address public owner = msg.sender;
    address public withdrawSetter;
    address public tokenAddr;
    address contractAddr = address(this);
    uint public totalInvestors;
    mapping(address => Investor) investor;
    event PriceSetterChanged(address user);
    event OwnershipTransferred(address);
    event UserRegistered(address user);
    event Received(address, uint);

    function deposit(uint amount) public returns (bool) {
        TRC20 token = TRC20(tokenAddr);
        address user = msg.sender;
        require(token.allowance(user,contractAddr) >= amount,"Insufficient allowance");
        require(token.balanceOf(user) >= amount, "Insufficient contract balance");
        token.transferFrom(user, contractAddr, amount);
        investor[user].invested = amount;
        registerUser(user);
        return true;
    }
    
    
    function registerUser(address user) internal {
        if( !investor[user].registered ) {
            investor[msg.sender].registered = true;
            investor[msg.sender].investedAt = block.timestamp;
            totalInvestors++;   
        }
        emit UserRegistered(user);
    }
    
    function setTokenAddr(address tokenAddress) public {  
        require(msg.sender == owner);
        tokenAddr = tokenAddress;
    }
    
    function setWithdrawSetter(address user) public {  
        require(msg.sender == owner);
        withdrawSetter = user;
        emit PriceSetterChanged(withdrawSetter);
    }
    
    function userWithdrawable(address user, uint amount) public {
        require(msg.sender == owner || msg.sender == withdrawSetter, "You don't have permission");
        require(investor[user].registered = true, "User has not registered");
        investor[user].setWithdrawable = amount;
    }
    
    function withdraw(address to) public returns (bool) {
        TRC20 token = TRC20(tokenAddr);
        require(investor[msg.sender].registered = true, "User not registered yet");
        uint amount = investor[msg.sender].setWithdrawable;
        token.transfer(to,amount);
        investor[msg.sender].setWithdrawable = 0;
        return true;
    }
    
    function ownerTrxWithdraw(uint amount) public returns (bool) {
        require(msg.sender == owner, "Only owner");
        address payable to = payable(msg.sender);
        to.transfer(amount);
        return true;
    }
    
     function ownerTokenWithdraw(address tokenAddrs, uint amount) public returns (bool) {
        TRC20 token = TRC20(tokenAddrs);
        require(msg.sender == owner, "Only owner");
        token.transfer(msg.sender,amount);
        return true;
    }
    
    function showWithdrawableAmount(address user) public view returns (uint) {
        uint withdrawableAmount = investor[user].setWithdrawable;
        return withdrawableAmount;
    }
    
    function transferOwnership(address to) public {
        require(msg.sender == owner, "Only owner");
        owner = to;
        emit OwnershipTransferred(to);
    }
    
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}