pragma solidity ^0.4.24;

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

contract Whitelist is Ownable {
    mapping(address => uint256) public whitelist;

    event Whitelisted(address indexed who);

    uint256 public nextUserId = 1;

    function addAddress(address who) external onlyOwner {
        require(who != address(0));
        require(whitelist[who] == 0);
        whitelist[who] = nextUserId;
        nextUserId++;
        emit Whitelisted(who); // solhint-disable-line
    }

    function addAddresses(address[] addresses) external onlyOwner {
        require(addresses.length <= 100);
        address who;
        uint256 userId = nextUserId;
        for (uint256 i = 0; i < addresses.length; i++) {
            who = addresses[i];
            require(whitelist[who] == 0);
            whitelist[who] = userId;
            userId++;
            emit Whitelisted(who); // solhint-disable-line
        }
        nextUserId = userId;
    }
}