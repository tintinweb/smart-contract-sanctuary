pragma solidity >=0.5.0;
import './SafeMath.sol';

contract DeathManSwitch {

    using SafeMath for uint;

    address payable public owner;
    uint256 public checkTime;
    uint256 public finalTime;

    constructor() public payable {
        owner = msg.sender;
        checkTime = now;
        uint256 targetTime = uint256(7).mul(uint256(86400));
        finalTime = now.add(targetTime);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier allowSteal() {
        uint256 offsetTime = uint256(3).mul(uint256(86400));
        uint256 minimumStealTime = checkTime.add(offsetTime);
        require(now > minimumStealTime);
        _;
    }

    modifier allowRecoverFounds() {
        require(now >= finalTime);
        _;
    }

    function ping() public onlyOwner {
        checkTime = now;
    }

    function recoverFunds() public payable onlyOwner allowRecoverFounds {
        owner.transfer(address(this).balance);
    }

    function stealFunds() public payable allowSteal {
        msg.sender.transfer(address(this).balance);
    }
}