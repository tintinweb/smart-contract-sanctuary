pragma solidity ^0.4.18;

contract ERC20 {

    uint256 public totalSupply;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);

    function allowance(address owner, address spender) public view returns (uint256);
    function approve(address spender, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);

}

contract Ownable {
    address public owner;

    event OwnerChanged(address oldOwner, address newOwner);

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != owner && newOwner != address(0x0));
        address oldOwner = owner;
        owner = newOwner;
        OwnerChanged(oldOwner, newOwner);
    }
}

contract TeamTokenLock is Ownable {

    ERC20 public token;

    // address where receives funds when unlock period
    address public beneficiary;

    uint public startTime = 1513728000;  // About time at 2018-1-1
    uint public firstLockTime = 365 days;
    uint public secondLockTime = 2 * 365 days;

    uint public firstLockAmount = 120000000 * (10 ** 18);
    uint public secondLockAmount = 120000000 * (10 ** 18);

    modifier onlyOfficial {
        require(msg.sender == owner || msg.sender == beneficiary);
        _;
    }

    modifier firstLockTimeEnd {
        require(isFirstLockTimeEnd());
        _;
    }

    modifier secondLockTimeEnd {
        require(isSecondLockTimeEnd());
        _;
    }

    function TeamTokenLock(address _beneficiary, address _token) public {
        require(_beneficiary != address(0));
        require(_token != address(0));

        beneficiary = _beneficiary;
        token = ERC20(_token);
    }

    function getTokenBalance() public view returns(uint) {
        return token.balanceOf(address(this));
    }

    function isFirstLockTimeEnd() public view returns(bool) {
        return now > startTime + firstLockTime;
    }

    function isSecondLockTimeEnd() public view returns(bool) {
        return now > startTime + secondLockTime;
    }

    function unlockFirstTokens() public onlyOfficial firstLockTimeEnd {
        require(firstLockAmount > 0);

        uint unlockAmount = firstLockAmount < getTokenBalance() ? firstLockAmount : getTokenBalance();
        require(unlockAmount <= firstLockAmount);
        firstLockAmount = firstLockAmount - unlockAmount;
        require(token.transfer(beneficiary, unlockAmount));
    }

    function unlockSecondTokens() public onlyOfficial secondLockTimeEnd {
        require(secondLockAmount > 0);

        uint unlockAmount = secondLockAmount < getTokenBalance() ? secondLockAmount : getTokenBalance();
        require(unlockAmount <= secondLockAmount);
        secondLockAmount = secondLockAmount - unlockAmount;
        require(token.transfer(beneficiary, unlockAmount));
    }

    function changeBeneficiary(address _beneficiary) public onlyOwner {
        require(_beneficiary != address(0));
        beneficiary = _beneficiary;
    }
}