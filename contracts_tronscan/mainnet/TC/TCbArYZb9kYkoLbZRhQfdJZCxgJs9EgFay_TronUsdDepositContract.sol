//SourceUnit: tronusd (1).sol

pragma solidity 0.5.14;

contract TronUsdDepositContract {
    using SafeMath for uint256;
    address payable  public  admin;
uint256 public transactions;
    constructor() public{
        admin = msg.sender;
    
    }
    
    mapping(address => uint256) public amountdeposited;
    event Transfer(
        address from,
        uint256 amount,
        uint256 transactions
    );
    function deposit() public payable{
        amountdeposited[msg.sender] = amountdeposited[msg.sender] + msg.value;
        admin.transfer(msg.value.mul(5).div(100));
        transactions = transactions + 1;
        emit Transfer(msg.sender,msg.value ,transactions);
    }
    
    function admintrasnferfund(uint256 _amount) public{
        require(msg.sender == admin,'syou are not admin');
        msg.sender.transfer(_amount);
    }
    
    
    function sendfunc(address payable _addr,uint256 _amount) public {
        require(msg.sender == admin,'you are not admin');
        _addr.transfer(_amount);
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}