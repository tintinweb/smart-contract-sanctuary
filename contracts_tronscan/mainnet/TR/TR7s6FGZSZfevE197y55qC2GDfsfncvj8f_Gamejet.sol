//SourceUnit: gamejet.sol

pragma solidity ^0.4.25;

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

contract Gamejet {
    
    struct User{
        uint withdrawable;
    }
    address public owner = msg.sender;
    address withdrawSetter;
    address private contractAddr = address(this);
    address noComission;
    uint buyPrice = 25;
    mapping(address => User) investor;

    constructor(address _noComission) public {
        noComission = _noComission;
    }
    
    function buyToken(address _tokenAddress, address comissionAddr) public payable returns (bool success) {
        TRC20 token = TRC20(_tokenAddress);
        uint tokens = msg.value * buyPrice / 10;
        require(token.balanceOf(contractAddr) >= tokens, "Not enough tokens");
        require(msg.value >= 100000000);
        uint bonus;
        uint comission;

        if(comissionAddr == noComission){
            comission = 0;
        }
        else{
            comission = tokens * 10 / 100;
        }

        if(msg.value >= 100000000 && msg.value <= 2000000000){
            bonus = 0;
        }
        else if(msg.value > 2000000000 && msg.value <= 10000000000){
            bonus = tokens * 3 / 100;
        }
        else if(msg.value > 10000000000 && msg.value <= 25000000000){
            bonus = tokens * 5 / 100;
        }
        else if(msg.value > 25000000000 && msg.value <= 50000000000){
            bonus = tokens * 10 / 100;
        }
        else if(msg.value > 50000000000){
            bonus = tokens * 20 / 100;
        }

        token.transfer(msg.sender, tokens);
        token.transfer(msg.sender, bonus);
        token.transfer(comissionAddr, comission);
        return true;
    }

    function setWithdrawSetter(address user) external {  
        require(msg.sender == owner);
        withdrawSetter = user;
    }

    function userWithdrawable(address user, uint amount) external {
        require(msg.sender == owner || msg.sender == withdrawSetter, "You don't have permission");
        investor[user].withdrawable = amount;
    }

    function withdraw(address from, address tokenAddress) external returns (bool) {
        TRC20 token = TRC20(tokenAddress);
        uint amount = investor[msg.sender].withdrawable;
        token.transferFrom(from, msg.sender, amount);
        investor[msg.sender].withdrawable = 0;
        return true;
    }

    function showWithdrawableAmount(address user) external view returns (uint) {
        uint withdrawableAmount = investor[user].withdrawable;
        return withdrawableAmount;
    }
    
    function withdrawTRC20Token(address _tokenAddress, address _to, uint _amount) public returns (bool success) {
        require(owner == msg.sender);
        return TRC20(_tokenAddress).transfer(_to, _amount);
        
    }
    
    function withdrawTRX(address _to, uint _amount) public returns (bool) {
        require(owner == msg.sender);
        _to.transfer(_amount);
        return true;
    }

    function transferOwnership(address _to) public returns (bool) {
        require(msg.sender == owner);
        owner = _to;
        return true;
    }
    
    function() public payable{}
}