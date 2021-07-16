//SourceUnit: Infinity.sol


pragma solidity ^0.5.4; 

contract SetupOwner 
{
    address payable public ownerWallet;
    address payable private newOwner;
    event OwnershipTransferredEv(address indexed previousOwner, address indexed newOwner);

    constructor() public 
    {
        ownerWallet = msg.sender;
        emit OwnershipTransferredEv(address(0), msg.sender);
    }

    function transferOwnership(address payable  _newOwner) public onlyOwner 
    {
        newOwner = _newOwner;
    }

    function acceptOwnership() public 
    {
        require(msg.sender == newOwner);
        emit OwnershipTransferredEv(ownerWallet, newOwner);
        ownerWallet = newOwner;
        newOwner = address(0);
    }

    modifier onlyOwner() 
    {
        require(msg.sender == ownerWallet);
        _;
    }

}


contract Infinity is SetupOwner {
  uint256 public price = 50000;
  trcToken token_id = 1002000;
    uint256 totalOutcome = 0;
    uint256 totalIncome = 0;
  uint reg_user;
  uint trans_id;

  mapping (address => bool) public mappedUsers;
  address[] public users;

  event Register(address addr, uint256 amount, uint256 ref);
  event Upgrade(address addr, uint256 amount, uint256 level);

  function getUpgradeByLevel(uint256 level) public pure returns (uint256) {
    uint256 level_up = (1000000000 * 1000000);
    uint256 to_token = 1000000;
    if(level == 1) {
	level_up = (50000 * to_token);
    } else if(level == 2) {
	level_up = (80000 * to_token);
    } else if(level == 3) {
	level_up = (360000 * to_token);
    } else if(level == 4) {
	level_up = (3240000 * to_token);
    } else {
	level_up = (100000000 * to_token);
    }
    return level_up;
  }

  function upgrade(uint256 level) payable public returns(bool success, address user, uint256 to_level, uint256 amount) {
    require(msg.tokenid == token_id, "Unknown token");
    uint256 level_up = getUpgradeByLevel(level);
    require(msg.tokenvalue == level_up, "Not enough wallet balance");

    trans_id = totalIncome;
    ownerWallet.transferToken(msg.tokenvalue, msg.tokenid);

     emit Upgrade(msg.sender, msg.tokenvalue, level);
     return (true, msg.sender, level, level_up);
  }

  function userRegister(uint256 _ref) payable public returns (bool success, uint tx_id, uint256 trans_type) {
    require(!mappedUsers[msg.sender], "This address already registered. Please try again later!");
    require(msg.tokenid == token_id, "Unknown token");
    require(msg.tokenvalue == (price * 1000000), "Not Enough BTT Balance in your wallet");

    trans_id = totalIncome;

    users.push(msg.sender);
    mappedUsers[msg.sender] = true;
    ownerWallet.transferToken(msg.tokenvalue, msg.tokenid);


    emit Register(msg.sender, msg.tokenvalue, _ref);

    return (true, trans_id, 1);
  }
  function emergencyExit() public returns(bool) {
    require(msg.sender == ownerWallet);
    ownerWallet.transfer(address(this).balance);
    return true;
  }

}