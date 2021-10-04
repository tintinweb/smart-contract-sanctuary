/**
 *Submitted for verification at polygonscan.com on 2021-10-03
*/

pragma solidity ^0.8.7;

contract Token {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 0;
    uint public tempPool = 0;
    string public name = "The Basement";
    string public symbol = "BSD";
    uint public decimals = 18;
    address payable public owner;
    address winner;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    constructor() payable {
        owner = payable(msg.sender);
    }
    
    function buy() public payable {
        require(msg.sender != address(0), "BEP20: mint to the zero address");
        uint amount = msg.value;
        uint eWalletBalancePre = sub(eWalletBalance(), msg.value);
        if(eWalletBalance() != 0 && totalSupply != 0)
        {
            amount = div((msg.value*totalSupply), eWalletBalancePre);
        }
        totalSupply = add(totalSupply, amount);
        balances[msg.sender] = add(balances[msg.sender], amount);
        emit Transfer(address(0), msg.sender, amount);
    }

    function withdrawAll() public {
        //This is in case something goes wrong we can still extract all the funds and return them manually
        require(msg.sender == owner, "Don't have permission for that");
        uint amount = address(this).balance;

        (bool success, ) = owner.call{value: amount}("");
        require(success, "Failed to send Ether");
    }
    
    function withdraw(address payable to, uint amount) public {
        require(msg.sender == to, "Can only withdraw to self");
        
        uint availableBalance = div(balanceOf(msg.sender)*address(this).balance, totalSupply);
        uint withdrawAmount = div(amount * availableBalance, balanceOf(msg.sender));
        
        require(availableBalance >= withdrawAmount, "Not enough funds");
        (bool success, ) = to.call{value: withdrawAmount}("");
        require(success, "Failed to send Ether");
        totalSupply -= amount;
        burn(to, amount, false);
        //balances[msg.sender] = sub(balances[msg.sender], burn(to, amount, false), "BEP20: burn amount exceeds balance");
        
    }
    
    //function payIntoPool(uint amount) public returns(bool){
    //    require(balanceOf(msg.sender) >= amount, 'balance too low');
    //    tempPool = add(tempPool, amount);
    //    balances[msg.sender] = sub(balances[msg.sender], amount);
    //    return true;
    //}
    //
    //function extractFromPool(address to) public returns(bool){
    //    require(to == winner, 'theif');
    //}
    
    function balanceOf(address _owner) public returns(uint) {
        return balances[_owner];
    }
    
    function eWalletBalance() public view returns(uint) {
        return address(this).balance;
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(value >= 1000, 'transfer too low');
        require(balanceOf(msg.sender) >= value, 'balance too low');
        uint moveAmount = burn(msg.sender, value, true);
        balances[to] = add(balances[to], moveAmount);
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;   
    }
    
    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }
    
    function mint(address account, uint256 amount) internal returns(bool) {
      //require(msg.sender == owner, "Don't have permission for that");
      require(account != address(0), "BEP20: mint to the zero address");
      totalSupply = add(totalSupply, amount);
      balances[account] = add(balances[account], amount);
      emit Transfer(address(0), account, amount);
      return true;
    }
    
    function burn(address account, uint256 amount, bool transfer) public returns(uint) {
      if(account != msg.sender){
      require(msg.sender == owner, "Don't have permission for that");
      }
      require(account != address(0), "BEP20: burn from the zero address");
      
      balances[account] = sub(balances[account], amount, "BEP20: burn amount exceeds balance");
      
      if(transfer){
          totalSupply = sub(totalSupply, amount/1000);
          return amount - amount/1000;
      }
      else{totalSupply = sub(totalSupply, amount);}
      emit Transfer(account, address(0), amount);
      return amount;
    }
    
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
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
      return mod(a, b, "SafeMath: modulo by zero");
    }
    
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
      require(b != 0, errorMessage);
      return a % b;
    }
}