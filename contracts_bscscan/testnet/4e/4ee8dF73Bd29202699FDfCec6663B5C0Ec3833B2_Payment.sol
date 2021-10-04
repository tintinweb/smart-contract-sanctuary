/**
 *Submitted for verification at BscScan.com on 2021-10-03
*/

pragma solidity 0.6.6;

interface IERC20 {
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);
}

contract Payment {
  struct Item {
    uint256 amount;
    address recipient;
  }
  event Pay(address indexed from, uint256 indexed itemID, uint256 amount, uint256 indexed paymentID);

  address public admin;
  IERC20 public BUSD;
  mapping(uint256 => Item) public itemInfo;

  modifier onlyAdmin() {
    require(msg.sender == admin, "sender is not admin");
    _;
  }

  constructor(address _admin, address _BUSDAddr) public {
    require(_admin != address(0), "_admin is a address(0)");
    admin = _admin;
    BUSD = IERC20(_BUSDAddr);
  }

  function addItem(
    uint256 _itemID,
    uint256 _amount,
    address _recipient
  ) external onlyAdmin {
    require(_amount > 0, "_amount is not greater than 0");
    require(_recipient != address(0), "_recipient is a address(0)");
    require(itemInfo[_itemID].recipient == address(0), "item is already added");
    itemInfo[_itemID] = Item(_amount, _recipient);
  }

  function editItem(
    uint256 _itemID,
    uint256 _amount,
    address _recipient
  ) external onlyAdmin {
    require(_amount > 0, "_amount is not greater than 0");
    require(_recipient != address(0), "_recipient is a address(0)");
    require(itemInfo[_itemID].recipient != address(0), "item is not exist");
    itemInfo[_itemID].amount = _amount;
    itemInfo[_itemID].recipient = _recipient;
  }

  function pay(
    uint256 _itemID,
    uint256 _amount,
    uint256 _paymentID
  ) external {
    require(itemInfo[_itemID].amount == _amount, "_amount is not valid");
    BUSD.transferFrom(msg.sender, itemInfo[_itemID].recipient, _amount);
    emit Pay(msg.sender, _itemID, _amount, _paymentID);
  }
}