pragma solidity ^0.4.24;

contract Subscribers {

    address public owner;

    uint256 public monthlyPrice = 0.01 ether;
    uint256 public annualPrice = 0.1 ether;

    struct Subscriber {
        uint256 expires;
        address addy;
    }

    mapping (bytes32 => Subscriber) public subs;

    event Subscribed(bytes32 emailHash, uint8 mode, address subber);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function changeOwner(address _owner) onlyOwner external {
        withdraw();
        owner = _owner;
    }

    function setMonthlyPrice(uint256 _price) onlyOwner external {
        monthlyPrice = _price;
    }

    function setAnnualPrice(uint256 _price) onlyOwner external {
        annualPrice = _price;
    }

    function subscribeMe(uint8 _monthOrYear, bytes32 _email) external payable {
        subscribe(msg.sender, _monthOrYear, _email);
    }

    function subscribe(address _subscriber, uint8 _monthOrYear, bytes32 _email) public payable {
        
        // Extend sub if already subbed
        uint256 from = subs[_email].expires;
        if (from == 0) {
            from = now;
        }

        uint256 requiredPrice = (_monthOrYear == 1) ? monthlyPrice : annualPrice;
        require(msg.value >= requiredPrice);
        
        uint256 requiredDuration = (_monthOrYear == 1) ? 2629746 : 31556952;
        subs[_email] = Subscriber(from + requiredDuration, _subscriber);

        emit Subscribed(_email, _monthOrYear, _subscriber);
    }

    function withdraw() onlyOwner public {
        address(owner).transfer(address(this).balance);
    }

    function freeSub(address _subscriber, uint8 _monthOrYear, bytes32 _email) onlyOwner external {
        uint256 requiredDuration = (_monthOrYear == 1) ? 2629746 : 31556952;
        subs[_email] = Subscriber(now + requiredDuration, _subscriber);

        emit Subscribed(_email, _monthOrYear, _subscriber);
    }

    function checkExpires(bytes32 _email) public view returns (uint256) {
        return subs[_email].expires;
    }

}