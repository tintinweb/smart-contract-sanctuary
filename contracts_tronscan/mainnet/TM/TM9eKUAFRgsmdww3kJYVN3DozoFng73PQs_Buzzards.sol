//SourceUnit: buzzards_affiliate.sol

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

contract Ownable {
    address public owner;
	

    event onOwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        emit onOwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

contract Buzzards is Ownable {
  



using SafeMath for uint256;
event AddFundAmt(address indexed sender, uint256 _amount);
event SendFundAmt(address indexed sender,uint256 _amount);

function Addfunds(address payable owner,uint256 _amount) public payable {
		require(address(this).balance >= _amount, "Address: insufficient balance");
        owner.transfer(_amount);
		emit AddFundAmt(msg.sender,msg.value);
  }

function SendFunds(address payable _sender,uint256 _amount) public payable {
		require(address(this).balance >= _amount, "Address: insufficient balance");
        _sender.transfer(_amount);
		emit AddFundAmt(msg.sender,msg.value);
  } 
 
function withdrawalToAddress(address payable to,uint256 amount) public onlyOwner {
        require(msg.sender == owner);
        to.transfer(amount);
  }

}