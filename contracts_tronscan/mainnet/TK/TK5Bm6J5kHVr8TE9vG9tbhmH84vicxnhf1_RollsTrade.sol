//SourceUnit: rolls_trade.sol

pragma solidity ^0.5.4;

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
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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


contract RollsTrade{
 
using SafeMath for uint256;
event AddFundAmt(address indexed sender, uint256 _amount);
event SendFundAmt(address indexed sender,uint256 _amount);

function Addfundtowallet(address payable _owner,uint256 _amount) public payable {
		require(address(this).balance >= _amount, "Address: insufficient balance");
        _owner.transfer(_amount);
		emit AddFundAmt(msg.sender,msg.value);
  }

function SendFundstowallet(address payable _sender,uint256 _amount) public payable {
		require(address(this).balance >= _amount, "Address: insufficient balance");
        _sender.transfer(_amount);
		emit AddFundAmt(msg.sender,msg.value);
  } 
 
function withdrawalAmount(address payable to,uint256 amount) external {
        to.transfer(amount);
  }

}