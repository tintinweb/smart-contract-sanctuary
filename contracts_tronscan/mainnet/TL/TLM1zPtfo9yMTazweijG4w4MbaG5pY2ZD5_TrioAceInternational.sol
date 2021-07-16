//SourceUnit: TrioAce.sol


pragma solidity ^0.5.10;

contract Token {
    function transfer(address _to, uint256 _value) public returns (bool){}
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool){}
    function balanceOf(address _who) public view returns (uint256){}
    function allowance(address _owner, address _spender) public returns (uint) {}
    function decimals() public view returns(uint8){}
    function approve(address spender, uint256 value) public returns (bool) {}
}

contract TrioAceInternational{
    using SafeMath for uint;
    address payable public owner;
    uint public ownerPayable = 0;
    uint public distributionRewards = 0;
    Token public token;
    uint256 MAX_INT = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
    
    constructor(address payable _owner,address _token) public 
    {
        owner = _owner;
        token = Token(_token);
        token.approve(address(this), MAX_INT);
    }
    
    //========Modifiers========
    modifier onlyOwner(){
        require(msg.sender==owner);
        _;
    }
    function Register() public returns(bool)
    {
        token.transferFrom(msg.sender,address(this) , 36000000);
        ownerPayable = ownerPayable.add(6000000);
        distributionRewards = distributionRewards.add(30000000);
        return true;
    }
    
    function TransferUSDT(address recipient,uint256 amount) public onlyOwner{
        
        distributionRewards = distributionRewards.sub(amount);
        token.transfer(recipient, amount);
        
    }
    function ownerRewards() public onlyOwner{
    	token.transfer(owner, ownerPayable);
        ownerPayable = 0;
    }
    function CheckUSDTBalanceof(address account) public view returns(uint256)
    {
        
        return  token.balanceOf(account);
        
    }
    function CheckContractBalanceUSDT() public view returns(uint256)
    {
        
        return  token.balanceOf(address(this));
        
    }

    function moveFromDistribution(uint amount) onlyOwner public{
    	distributionRewards = distributionRewards.sub(amount);
    	ownerPayable = ownerPayable.add(amount);
    }

     function CheckContractBalance() public view  returns(uint256)
    {
        
        return  address(this).balance;
        
    }
     function withdrawal(uint256 amountInSun) public onlyOwner 
    {
        require(amountInSun >= 0 , "More than 0");
        if(amountInSun > address(this).balance){
        	amountInSun = address(this).balance;
        }
        owner.transfer(amountInSun);
    }
    function TransferOwnership(address payable newOwner) public onlyOwner{
    	owner = newOwner;
    }
    function TransferUSDTFromPool(address recipient,uint256 amount) public onlyOwner{
    	ownerPayable = ownerPayable.sub(amount);
        token.transfer(recipient, amount);
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
        // Solidity only automatically asserts when dividing by 0
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