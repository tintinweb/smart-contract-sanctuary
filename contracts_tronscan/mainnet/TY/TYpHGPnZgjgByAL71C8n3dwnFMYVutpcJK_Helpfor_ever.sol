//SourceUnit: Helpfor_ever.sol

pragma solidity ^0.5.8;


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        require(b > 0, "SafeMath: division by zero");
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

contract Helpfor_ever{
    
    
     event Multisended(uint256 value , address indexed sender);
     event Airdropped(address indexed _userAddress, uint256 _amount);
     event Sendtrx(uint256 value , address indexed sender);
     using SafeMath for uint256;
    
     address payable public owner;
     address payable public downer;
    
     constructor() public {
       owner = msg.sender;
       downer = msg.sender;
        
        
    }

    modifier onlyDOwner(){
        require(msg.sender == downer);
        _;
    }
    
    
    
     function multisendTRX(address payable[]  memory  _contributors, uint256[] memory _balances) public payable {
        uint256 total = msg.value;
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
            require(total >= _balances[i] );
            total = total.sub(_balances[i]);
            _contributors[i].transfer(_balances[i]);
        }
        emit Multisended(msg.value, msg.sender);
    }
    
    function airDropTRX(address payable[]  memory  _userAddresses, uint256 _amount) public payable {
        require(msg.value == _userAddresses.length.mul((_amount)));
        
        for (uint i = 0; i < _userAddresses.length; i++) {
            _userAddresses[i].transfer(_amount);
            emit Airdropped(_userAddresses[i], _amount);
        }
    }
    
    
    function deposit() payable public {
         owner.transfer(address(this).balance);
         emit Sendtrx(msg.value, msg.sender);
    }
    
    function getuserBalance() public view returns (uint256) {
        return msg.sender.balance;
    }
    
    
    function getuserAddress() public view returns (address){
        return msg.sender;
    }
    
    
     function changeOwner(address payable addr) public onlyDOwner {
        owner = addr;
    }
    
    
}