pragma solidity ^0.5.17;

import "./Ownable.sol";
import "./SafeMath.sol";

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract MultiSig is IERC20, Ownable {
    using SafeMath for uint256;

    address public address1;
    address public address2;
    address public address3;
    address public address4;
    address public address5;
    address public erc20Address;

    struct Permit {
        bool address1;
        bool address2;
        bool address3;
        bool address4;
        bool address5;
        uint256 expiredTime;
    }

    mapping (address => mapping (uint256 => Permit)) private permits;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    uint8 constant public decimals = 18;
    string constant public name = "mSIT";
    string constant public symbol = "mSIT";

    uint256 public threshold = 3;
    uint256 public expiredTime = 24 hours;

    function getPermits(address account, uint256 amount) public view returns (bool, bool, bool, bool, bool, uint256) {
        Permit memory item = permits[account][amount];
        return (item.address1, item.address2, item.address3, item.address4, item.address5, item.expiredTime);
    }

    constructor(address _addr1, address _addr2, address _addr3, address _addr4, address _addr5, address _erc20Address) public {
        address1 = _addr1;
        address2 = _addr2;
        address3 = _addr3;
        address4 = _addr4;
        address5 = _addr5;
        erc20Address = _erc20Address;
    }

    function setManager(address _addr1, address _addr2, address _addr3, address _addr4, address _addr5) public onlyOwner {
        address1 = _addr1;
        address2 = _addr2;
        address3 = _addr3;
        address4 = _addr4;
        address5 = _addr5;
    }

    function setExpiredTime(uint256 value) public onlyOwner {
        expiredTime = value;
    }

    function isManager(address account) internal view returns (bool) {
        return (account == address1 || account == address2 || account == address3 || account == address4 || account == address5);
    }

    function approve(address spender, uint256 value) external returns (bool) {
        return false;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        return false;
    }

    function totalSupply() external view returns (uint256){
        IERC20 token = IERC20(erc20Address);
        return token.totalSupply();
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return 0;
    }

    function canTransfer(address to, uint256 amount) public view returns (bool) {
        if (permits[to][amount].expiredTime <= block.timestamp) { // timeout
            return false;
        }

        uint256 c;
        if (permits[to][amount].address1) {
            c = c + 1;
        }
        if (permits[to][amount].address2) {
            c = c + 1;
        }
        if (permits[to][amount].address3) {
            c = c + 1;
        }
        if (permits[to][amount].address4) {
            c = c + 1;
        }
        if (permits[to][amount].address5) {
            c = c + 1;
        }
        return c >= threshold;
    }

    function transfer(address to,  uint amount) public returns (bool) {
        IERC20 token = IERC20(erc20Address);
        require(token.balanceOf(address(this)) >= amount, "transfer amount not good");

        // clear timetout permits
        if (permits[to][amount].expiredTime <= block.timestamp) { // timeout
            delete permits[to][amount];
        }

        if (msg.sender == address1) {
            permits[to][amount].address1 = true;
        } else if (msg.sender == address2) {
            permits[to][amount].address2 = true;
        } else if (msg.sender == address3) {
            permits[to][amount].address3 = true;
        } else if (msg.sender == address4) {
            permits[to][amount].address4 = true;
        } else if (msg.sender == address5) {
            permits[to][amount].address5 = true;
        } else {
            require(false, "not multi-sig member");
        }

        // clear timetout permits
        if (permits[to][amount].expiredTime == 0) { // timeout
            permits[to][amount].expiredTime = expiredTime.add(block.timestamp);
        }

        if (canTransfer(to, amount)) {
            token.transfer(to, amount);
            delete permits[to][amount];
        }
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        IERC20 token = IERC20(erc20Address);
        if (isManager(_owner)) {
            return token.balanceOf(address(this));
        }
        return 0;
    }
}