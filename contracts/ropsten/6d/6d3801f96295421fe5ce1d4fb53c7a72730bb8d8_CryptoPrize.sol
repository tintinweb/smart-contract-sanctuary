pragma solidity ^0.4.23;

/*
    CryptoPrize(address _token_address)   // this will unlock the prize and send yum to user
  @author Yumerium Ltd
*/
// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

contract YUM {
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    mapping (address => uint256) public balanceOf;
    function transfer(address _to, uint256 _value) public;
}


contract CryptoPrize {
    using SafeMath for uint256;
    uint256 public budget;
    uint256 public totalUnlocked;
    uint256 public startYum;
    uint256 public count;
    address public creator;
    YUM public Token;

    event UnlockPrize(address to, uint256 amount);
    event CalcNextPrize(uint256 count, uint256 amount);
    event Retrieve(address to, uint256 amount);
    event AddBudget(uint256 budget, uint256 startYum);

    constructor(address _token_address) public {
        budget = 0;
        startYum = 0;
        count = 0;
        creator = msg.sender;
        Token = YUM(_token_address);
    }

    function calcNextPrize() public returns (uint256) {
        uint256 amount = startYum / (count + 1);
        emit CalcNextPrize(count, amount);
        return amount;
    }
    
    function sendyum(address to) external {
        require(msg.sender==creator);
        uint256 amount = calcNextPrize();
        require(amount > 0);
        uint256 total = totalUnlocked + amount;
        require(total<=budget);
        Token.transfer(to, amount);
        count++;
        totalUnlocked = total;
        emit UnlockPrize(to, amount);
    }

    // change creator address
    function changeCreator(address _creator) external {
        require(msg.sender==creator);
        creator = _creator;
    }

    // change creator address
    function changeYumAddress(address _token_address) external {
        require(msg.sender==creator);
        Token = YUM(_token_address);
    }

    function retrieveAll() external {
        require(msg.sender==creator);
        uint256 amount = Token.balanceOf(this);
        Token.transfer(creator, amount);     
        emit Retrieve(creator, amount);   
    }

    // add more budget and reset startYum and count
    function addBudget(uint256 _budget, uint256 _startYum) external {
        require(msg.sender==creator);
        require(Token.transferFrom(msg.sender, this, _budget));
        budget = budget.add(_budget);
        startYum = _startYum;
        count = 0;
        emit AddBudget(budget, startYum);
    }

}