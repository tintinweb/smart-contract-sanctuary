pragma solidity ^0.4.25;

contract EscrowWallet {

  event Requested(address indexed _receiver, uint256 _amount, uint256 balance);
  event Approved(address indexed _receiver, uint256 _amount, uint256 balance);
  event Declined(address indexed _whom, address indexed _receiver);
  event Received(address indexed _payer, uint256 _amount);

  mapping (address => uint256) private requested;

  address private escrow;
  address private owner;

  constructor(address _escrow) public payable {
      escrow = _escrow;
      owner  = msg.sender;
  }

  function () external payable {
    emit Received(msg.sender, msg.value);
  }

  function Request(address _receiver, uint256 _amount) public {
    require(msg.sender == owner);
    require(_receiver != address(0) && _receiver != address(this));
    require(_amount > 0);
    require(requested[_receiver] == 0);

    requested[_receiver] = _amount;
    emit Requested(_receiver, _amount, address(this).balance);
  }

  function Approve(address _receiver, uint256 _amount) public {
    require(msg.sender == escrow);
    require(_amount > 0);
    require(requested[_receiver] == _amount);

    requested[_receiver] = 0;
    _receiver.transfer(_amount);
    emit Approved(_receiver, _amount, address(this).balance);
  }

  function Decline(address _receiver) public {
    require(msg.sender == escrow || msg.sender == owner);

    requested[_receiver] = 0;
    emit Declined(msg.sender, _receiver);
  }
}