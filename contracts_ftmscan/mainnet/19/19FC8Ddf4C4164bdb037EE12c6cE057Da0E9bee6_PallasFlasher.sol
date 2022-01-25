/**
 *Submitted for verification at FtmScan.com on 2022-01-25
*/

//  /$$$$$$$   /$$$$$$  /$$       /$$        /$$$$$$   /$$$$$$ 
// | $$__  $$ /$$__  $$| $$      | $$       /$$__  $$ /$$__  $$
// | $$  \ $$| $$  \ $$| $$      | $$      | $$  \ $$| $$  \__/
// | $$$$$$$/| $$$$$$$$| $$      | $$      | $$$$$$$$|  $$$$$$ 
// | $$____/ | $$__  $$| $$      | $$      | $$__  $$ \____  $$
// | $$      | $$  | $$| $$      | $$      | $$  | $$ /$$  \ $$
// | $$      | $$  | $$| $$$$$$$$| $$$$$$$$| $$  | $$|  $$$$$$/
// |__/      |__/  |__/|________/|________/|__/  |__/ \______/ 

// Next-gen Autostaking Mechanism - https://pallas.finance

pragma solidity 0.7.6;

interface IERC20 {
  function balanceOf(address who) external view returns (uint256);

  function transfer(address to, uint256 value) external;
}

contract Ownable {
    address private _owner;

    event OwnershipRenounced(address indexed previousOwner);

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
    }

    function owner() public virtual view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(_owner);
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract PallasFlasher is Ownable {
  address public pallas_token;
  uint256 public start_time = 1643132700;
  uint256 public end_time = 1643219100;
  uint256 public DECIMALS = 18;
  uint256 public price;
  uint256 public sold;

  constructor(address _pallas_token, uint256 _price) {
    pallas_token = _pallas_token;
    price = _price;
  }

  function buy() external payable {
    require(
      block.timestamp >= start_time && block.timestamp <= end_time,
      "Out time bounds!"
    );
    uint256 amount = msg.value * 10**DECIMALS / price;
    IERC20(pallas_token).transfer(msg.sender, amount);
    payable(owner()).transfer(address(this).balance);
    sold += amount;
  }

  function returnTokens() public {
    require(msg.sender == owner(), "You are not the deployer!");
    IERC20(pallas_token).transfer(owner(), IERC20(pallas_token).balanceOf(address(this)));
  }

  function resetSold() public onlyOwner {
      sold = 0;
  }

  function setPrice(uint256 newPrice) public onlyOwner {
    price = newPrice;
  }

  function setTimeBounds(uint256 start, uint256 end) public onlyOwner {
    start_time = start;
    end_time = end;
  }
}