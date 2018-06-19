pragma solidity ^0.4.21;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


contract Ownable {

    address public owner;

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }
}

interface smartContract {
    function transfer(address _to, uint256 _value) payable external;
    function approve(address _spender, uint256 _value) external returns (bool success);
}

contract Basic is Ownable {
    using SafeMath for uint256;

    // This creates an array with all balances
    mapping(address => uint256) public totalAmount;
    mapping(address => uint256) public availableAmount;
    mapping(address => uint256) public withdrawedAmount;
    uint[] public periods;
    uint256 public currentPeriod;
    smartContract public contractAddress;
    uint256 public ownerWithdrawalDate;

    // fix for short address attack
    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length == size + 4);
        _;
    }

    /**
     * Constructor function
     *
     * transfer tokens to the smart contract here
     */
    function Basic(address _contractAddress) public onlyOwner {
        contractAddress = smartContract(_contractAddress);
    }

    function _recalculateAvailable(address _addr) internal {
        _updateCurrentPeriod();
        uint256 available;
        uint256 calcPeriod = currentPeriod + 1;
        if (calcPeriod < periods.length) {
            available = totalAmount[_addr].div(periods.length).mul(calcPeriod);
            //you don&#39;t have anything to withdraw
            require(available > withdrawedAmount[_addr]);
            //remove already withdrawed tokens
            available = available.sub(withdrawedAmount[_addr]);
        } else {
            available = totalAmount[_addr].sub(withdrawedAmount[_addr]);
        }
        availableAmount[_addr] = available;
    }

    function addRecipient(address _from, uint256 _amount) external onlyOwner onlyPayloadSize(2 * 32) {
        require(_from != 0x0);
        require(totalAmount[_from] == 0);
        totalAmount[_from] = _amount;
        availableAmount[_from] = 0;
        withdrawedAmount[_from] = 0;
    }

    function withdraw() public payable {
        _withdraw(msg.sender);
    }

    function _withdraw(address _addr) internal {
        require(_addr != 0x0);
        require(totalAmount[_addr] > 0);

        //Recalculate available balance if time has come
        _recalculateAvailable(_addr);
        require(availableAmount[_addr] > 0);
        uint256 available = availableAmount[_addr];
        withdrawedAmount[_addr] = withdrawedAmount[_addr].add(available);
        availableAmount[_addr] = 0;

        contractAddress.transfer(_addr, available);
    }

    function triggerWithdraw(address _addr) public payable onlyOwner {
        _withdraw(_addr);
    }

    // owner may withdraw funds after some period of time
    function withdrawToOwner(uint256 _amount) external onlyOwner {
        // no need to create modifier for one case
        require(now > ownerWithdrawalDate);
        contractAddress.transfer(msg.sender, _amount);
    }

    function _updateCurrentPeriod() internal {
        require(periods.length >= 1);
        for (uint i = 0; i < periods.length; i++) {
            if (periods[i] <= now && i >= currentPeriod) {
                currentPeriod = i;
            }
        }
    }
}

contract Team is Basic{
    function Team(address _contractAddress) Basic(_contractAddress) public{
        periods = [
            now + 213 days,
            now + 244 days,
            now + 274 days,
            now + 305 days,
            now + 335 days,
            now + 365 days
        ];
        ownerWithdrawalDate = now + 395 days;
    }
}