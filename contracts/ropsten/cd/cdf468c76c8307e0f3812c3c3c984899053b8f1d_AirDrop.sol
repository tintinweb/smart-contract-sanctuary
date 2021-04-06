pragma solidity 0.6.12;

import "./Ownable.sol";
import './SafeERC20.sol';


contract AirDrop is Ownable {
  using SafeERC20 for IERC20;

  IERC20 public airDropToken;
  mapping (address => uint256) public whiteList;
  mapping (address => bool) public claimedList;

  constructor(
    IERC20 _tpt
  ) public {
    airDropToken = _tpt;
  }

  function setWhiteList(address[] calldata _list, uint256 amount) public onlyOwner {
    for (uint256 i = 0; i < _list.length; i++) {
      whiteList[_list[i]] = amount;
    }
  }

  function adminWithdraw(uint256 _amount) public onlyOwner {
    airDropToken.safeTransfer(address(msg.sender), _amount);
  }

  function pendingAmount(address _address) public view returns(uint256) {
    if (claimedList[msg.sender]) {
      return 0;
    }
    if(whiteList[_address] > 0) {
      return whiteList[_address];
    }
  }
  
  function claim() public {
    require (pendingAmount(msg.sender) > 0, 'nothing can been claimed');
    require (!claimedList[msg.sender], 'already claimed');
    airDropToken.safeTransfer(address(msg.sender), pendingAmount(msg.sender));
    claimedList[msg.sender] = true;
  }
}