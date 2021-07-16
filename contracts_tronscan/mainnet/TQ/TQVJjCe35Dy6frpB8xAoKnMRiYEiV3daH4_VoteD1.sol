//SourceUnit: ITRC20.sol

pragma solidity =0.5.4;

interface ITRC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


//SourceUnit: SafeMath.sol

pragma solidity =0.5.4;

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
 
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
 
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }
 
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
 
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }
 
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
    }
}

//SourceUnit: context.sol

pragma solidity =0.5.4;

contract Context {
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }
}


//SourceUnit: owner.sol

pragma solidity =0.5.4;

import "context.sol";

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

//SourceUnit: vote.sol

pragma solidity =0.5.4;

import "ITRC20.sol";
import "owner.sol";
import "SafeMath.sol";

contract Vote is Ownable {
  using SafeMath for uint256;

  uint256 public start;
  uint256 public end;
  bool public stoped;

  ITRC20 trc20;

  address[] public options;
  uint256 public length;
  uint256 public total;
  mapping(address=>uint256) public userVoteCount;
  mapping(uint256=>uint256) public proposalsVoteCount;

  constructor(address trc20Address, uint256 _start, uint256 duration, uint256 _length) public {
    start = _start;
    end = start + duration;
    trc20 = ITRC20(trc20Address);
    length = _length;
  }

  function stop() public onlyOwner returns (bool) {
    stoped = true;
    return true;
  }

  modifier whenStart {
    require(canVote(), "NOT START");
    _;
  }

  modifier whenEnd {
    uint256 _now = blocktime();
    require(stoped || _now >= end, "NOT END");
    _;
  }

  function canVote() public view returns (bool) {
    uint256 _now = blocktime();
    return !stoped && start <= _now && _now <= end;
  }

  function blocktime() private view returns (uint256) {
    return block.timestamp;
  }

  function vote(uint256 option, uint256 count) public whenStart returns (bool) {
    require(option < length, "INVALID OPTION");
    require(trc20.transferFrom(_msgSender(), address(this), count), "REQUIRE TRANSFER SUCCESS");
    uint256 voted = userVoteCount[_msgSender()];
    userVoteCount[_msgSender()] = voted.add(count);
    uint256 optionVoted = proposalsVoteCount[option];
    proposalsVoteCount[option] = optionVoted.add(count);
    total = total.add(count);
    return true;
  }

  function exit() public whenEnd returns (bool) {
    uint256 voted = userVoteCount[_msgSender()];
    require(trc20.transfer(_msgSender(), voted), "REQUIRE TRANSFER SUCCESS");
    userVoteCount[_msgSender()] = 0;
    return true;
  }
}


//SourceUnit: voted1.sol

pragma solidity =0.5.4;

import "vote.sol";

contract VoteD1 is Vote {
    constructor () Vote(address(0x41499E922079D0B4CC83F6E289C6C3812E210EE031), 1599745500, 7200, 7) public {}
}