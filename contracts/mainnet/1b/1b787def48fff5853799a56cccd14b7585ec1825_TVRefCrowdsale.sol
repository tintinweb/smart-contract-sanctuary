pragma solidity ^0.4.13;

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract TVCrowdsale {
    uint256 public currentRate;
    function buyTokens(address _beneficiary) public payable;
}

contract TVToken {
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function balanceOf(address _owner) public view returns (uint256);
    function allowance(address _owner, address _spender) public view returns (uint256);
}

contract TVRefCrowdsale is Ownable {
    TVToken public TVContract;
    TVCrowdsale public TVCrowdsaleContract;
    uint256 public refPercentage;
    uint256 public TVThreshold;
    address public holder;
    mapping(address => bool) public exceptAddresses;

    event TransferRefTVs(address holder, address sender, address referer, uint256 amount, uint256 TVThreshold, uint256 balance);
    event BuyTokens(address sender, uint256 amount);

    constructor(
        address _TVTokenContract,
        address _TVCrowdsaleContract,
        uint256 _refPercentage,
        uint256 _TVThreshold,
        address _holder
    ) public {
        TVContract = TVToken(_TVTokenContract);
        TVCrowdsaleContract = TVCrowdsale(_TVCrowdsaleContract);
        refPercentage = _refPercentage;
        TVThreshold = _TVThreshold;
        holder = _holder;
    }

    function buyTokens(address refAddress) public payable {
        TVCrowdsaleContract.buyTokens.value(msg.value)(msg.sender);
        emit BuyTokens(msg.sender, msg.value);
        sendRefTVs(refAddress);
    }

    function sendRefTVs(address refAddress) internal returns(bool) {
        uint256 balance = TVContract.balanceOf(refAddress);
        uint256 allowance = TVContract.allowance(holder, this);
        uint256 amount = (msg.value * TVCrowdsaleContract.currentRate()) * refPercentage / 100;
        if ((exceptAddresses[refAddress] || balance >= TVThreshold) && allowance >= amount) {
            bool successful = TVContract.transferFrom(holder, refAddress, amount);
            if (!successful) revert("Transfer refTVs failed.");
            emit TransferRefTVs(holder, msg.sender, refAddress, amount, TVThreshold, balance);
            return true;
        }
        return true;
    }

    function changeRefPercentage(uint256 percentage) onlyOwner public {
        require(percentage > 0);
        refPercentage = percentage;
    }

    function addExceptAddress(address exceptAddress) onlyOwner public {
        exceptAddresses[exceptAddress] = true;
    }

    function changeThreshold(uint256 threshold) onlyOwner public {
        require(threshold > 0);
        TVThreshold = threshold;
    }
}