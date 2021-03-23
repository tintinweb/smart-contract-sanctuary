/**
 *Submitted for verification at Etherscan.io on 2021-03-23
*/

pragma solidity =0.8.2;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Ownable {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed from, address indexed to);

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Ownable: Caller is not the owner");
        _;
    }

    function transferOwnership(address transferOwner) public onlyOwner {
        require(transferOwner != newOwner);
        newOwner = transferOwner;
    }

    function acceptOwnership() virtual public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

interface IReferralProgram {
    function userSponsorByAddress(address user) external view returns (uint);
    function userSponsor(uint user) external view returns (uint);
    function userAddressById(uint id) external view returns (address);
    function userIdByAddress(address user) external view returns (uint);
    function userSponsorAddressByAddress(address user) external view returns (address);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
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
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract UnicornReferralProgramLogic is Ownable {
    using SafeMath for uint;

    IERC20 public immutable UNIT;
    uint[] public levels;
    IReferralProgram public immutable unicornUsers;

    event DistributeFees(address user, uint amount);
    event UpdateLevels(uint[] newLevels);
   
    constructor(address unit, address unicornUsersReferral)  {
        levels = [50, 30, 20];
        UNIT = IERC20(unit);
        unicornUsers = IReferralProgram(unicornUsersReferral);
    }

    receive() payable external {
        revert();
    }

    function processFee(address user, uint amount) external {
        require(UNIT.balanceOf(address(this)) >= amount, "Unicorn Referral: Not correct amount");
        address sponsor = unicornUsers.userSponsorAddressByAddress(user);
        uint unspent = amount;
        for (uint i; i < levels.length; i++) {
            if (i != 0) sponsor = unicornUsers.userSponsorAddressByAddress(sponsor);
            if (sponsor == address(0)) {
                UNIT.transfer(unicornUsers.userAddressById(2), unspent);
                break;
            } else {
                uint transferAmount = amount.mul(levels[i]) / 100;
                UNIT.transfer(sponsor, transferAmount);
                unspent = unspent.sub(transferAmount);
            }
        }
        emit DistributeFees(user, amount);
    } 

    function updateLevels(uint[] memory newLevels) external onlyOwner {
        uint checkSum;
        for (uint i; i < newLevels.length; i++) {
            checkSum += newLevels[i];
        }
        require(checkSum == 100, "Unicorn Referral: Wrong levels amounts");
        levels = newLevels;
        emit UpdateLevels(newLevels);
    }
}