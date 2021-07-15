// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

library SafeMath {
  function mul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    require(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal pure returns (uint) {
    require(b > 0);
    uint c = a / b;
    require(a == b * c + a % b);
    return c;
  }

  function sub(uint a, uint b) internal pure returns (uint) {
    require(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    require(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}

// ---------------------------------------------------------------------
// ERC-20 Token Standard Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
// ---------------------------------------------------------------------
abstract contract IERC20 {
  /**
  Returns the name of the token - e.g. "MyToken"
   */
  string public name;
  /**
  Returns the symbol of the token. E.g. "HIX".
   */
  string public symbol;
  /**
  Returns the number of decimals the token uses - e. g. 8
   */
  uint8 public decimals;
  /**
  Returns the total token supply.
   */
  uint256 public totalSupply;
  /**
  Returns the account balance of another account with address _owner.
   */
  function balanceOf(address _owner) virtual public view returns (uint256 balance);
  /**
  Transfers _value amount of tokens to address _to, and MUST fire the Transfer event.
  The function SHOULD throw if the _from account balance does not have enough tokens to spend.
   */
  function transfer(address _to, uint256 _value) virtual public returns (bool success);
  /**
  Transfers _value amount of tokens from address _from to address _to, and MUST fire the Transfer event.
   */
  function transferFrom(address _from, address _to, uint256 _value) virtual public returns (bool success);
  /**
  Allows _spender to withdraw from your account multiple times, up to the _value amount.
  If this function is called again it overwrites the current allowance with _value.
   */
  function approve(address _spender, uint256 _value) virtual public returns (bool success);
  /**
  Returns the amount which _spender is still allowed to withdraw from _owner.
   */
  function allowance(address _owner, address _spender) virtual public view returns (uint256 remaining);
  /**
  MUST trigger when tokens are transferred, including zero value transfers.
   */
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  /**
  MUST trigger on any successful call to approve(address _spender, uint256 _value).
    */
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

/*
 * Owned contract
 */
abstract contract Ownable {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  function _msgSender() internal view virtual returns (address payable) {
    return payable(msg.sender);
  }

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor () {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view virtual returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(owner() == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public virtual onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract MultiSender is Ownable {

  using SafeMath for uint;

  event LogTokenBulkSent(address token, uint total);

  uint public txFee = 0 ether;
  uint public VIPFee = 0 ether;

  mapping(address => bool) public vipList;

  function registerVIP() payable public {
    require(msg.value >= VIPFee);
    require(_msgSender().send(msg.value));
    vipList[_msgSender()] = true;
  }

  function addToVIPList(address[] memory _vipList) onlyOwner public {
    for (uint i = 0; i < _vipList.length; i++) {
      vipList[_vipList[i]] = true;
    }
  }

  function removeFromVIPList(address[] memory _vipList) onlyOwner public {
    for (uint i = 0; i < _vipList.length; i++) {
      vipList[_vipList[i]] = false;
    }
  }

  function isVIP(address _addr) public view returns (bool) {
    return _addr == owner() || vipList[_addr];
  }

  function setVIPFee(uint _fee) onlyOwner public {
    VIPFee = _fee;
  }

  function setTxFee(uint _fee) onlyOwner public {
    txFee = _fee;
  }

  function ethSendSameValue(address[] memory _to, uint _value) payable public {
    require(_to.length <= 255);

    // Validate fee
    uint totalAmount = _to.length.mul(_value);
    uint totalEthValue = msg.value;
    if (isVIP(_msgSender())) {
      require(totalEthValue >= totalAmount);
    } else {
      require(totalEthValue >= totalAmount.add(txFee));
    }

    // Send
    for (uint8 i = 0; i < _to.length; i++) {
      require(payable(_to[i]).send(_value));
    }

    emit LogTokenBulkSent(address(0), msg.value);
  }

  function ethSendDifferentValue(address[] memory _to, uint[] memory _value) payable public {
    require(_to.length == _value.length);
    require(_to.length <= 255);

    uint totalEthValue = msg.value;

    // Validate fee
    uint totalAmount = 0;
    for (uint8 i = 0; i < _to.length; i++) {
      totalAmount = totalAmount.add(_value[i]);
    }

    if (isVIP(_msgSender())) {
      require(totalEthValue >= totalAmount);
    } else {
      require(totalEthValue >= totalAmount.add(txFee));
    }

    // Send
    for (uint8 i = 0; i < _to.length; i++) {
      require(payable(_to[i]).send(_value[i]));
    }

    emit LogTokenBulkSent(address(0), msg.value);

  }

  function coinSendSameValue(address _tokenAddress, address[] memory _to, uint _value) payable public {
    require(_to.length <= 255);

    // Validate fee
    uint totalEthValue = msg.value;
    if (!isVIP(_msgSender())) {
      require(totalEthValue >= txFee);
    }

    // Validate token balance
    IERC20 token = IERC20(_tokenAddress);
    uint tokenBalance = token.balanceOf(_msgSender());
    uint totalAmount = _to.length.mul(_value);
    require(tokenBalance >= totalAmount);

    // Send
    for (uint8 i = 0; i < _to.length; i++) {
      token.transferFrom(_msgSender(), _to[i], _value);
    }

    emit LogTokenBulkSent(_tokenAddress, totalAmount);

  }

  function coinSendDifferentValue(address _tokenAddress, address[] memory _to, uint[] memory _value) payable public {
    require(_to.length == _value.length);
    require(_to.length <= 255);

    // Validate fee
    uint totalEthValue = msg.value;
    if (!isVIP(_msgSender())) {
      require(totalEthValue >= txFee);
    }

    // Validate token balance
    IERC20 token = IERC20(_tokenAddress);
    uint tokenBalance = token.balanceOf(_msgSender());
    uint totalAmount = 0;
    for (uint8 i = 0; i < _to.length; i++) {
      totalAmount = totalAmount.add(_value[i]);
    }
    require(tokenBalance >= totalAmount);

    // Send
    for (uint8 i = 0; i < _to.length; i++) {
      token.transferFrom(_msgSender(), _to[i], _value[i]);
    }

    emit LogTokenBulkSent(_tokenAddress, totalAmount);

  }

  function getEthBalance() public view onlyOwner returns (uint) {
    return address(this).balance;
  }

  function withdrawEthBalance() external onlyOwner {
    payable(owner()).transfer(getEthBalance());
  }


  function getTokenBalance(address _tokenAddress) public view onlyOwner returns (uint) {
    IERC20 token = IERC20(_tokenAddress);
    return token.balanceOf(address(this));
  }

  function withdrawTokenBalance(address _tokenAddress) external onlyOwner {
    IERC20 token = IERC20(_tokenAddress);
    token.transfer(
      owner(),
      getTokenBalance(_tokenAddress)
    );
  }

}