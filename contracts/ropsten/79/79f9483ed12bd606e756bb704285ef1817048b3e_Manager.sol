pragma solidity ^0.4.24;

contract ERC20 {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);

    function mint(address to, uint256 amount) public returns (bool);
}

contract Ownable {
  address public owner;

  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}


contract Manager is Ownable {
    address public token;

    uint256 public dailyLimit;
    uint256 public lastDay;
    uint256 public spentToday;

    event DailyLimitChange(uint256 dailyLimit);

    constructor(address _token) public
    {
        token = _token;
    }

    function mint(address _recipient, uint256 _amount)
        public
        onlyOwner
    {
        require(isUnderLimit(_amount));

        spentToday += _amount;
        assert(spentToday > _amount);

        ERC20(token).mint(_recipient, _amount);
    }

    function changeDailyLimit(uint256 _dailyLimit)
        public
        onlyOwner
    {
        dailyLimit = _dailyLimit;
        emit DailyLimitChange(_dailyLimit);
    }

    function isUnderLimit(uint256 amount)
        internal
        returns (bool)
    {
        if (now > lastDay + 24 hours) {
            lastDay = now;
            spentToday = 0;
        }
        if (spentToday + amount > dailyLimit || spentToday + amount < spentToday)
            return false;

        return true;
    }

    function calcMaxWithdraw()
        public
        constant
        returns (uint)
    {
        if (now > lastDay + 24 hours)
            return dailyLimit;
        if (dailyLimit < spentToday)
            return 0;
        return dailyLimit - spentToday;
    }
}