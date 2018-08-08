pragma solidity ^0.4.24;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
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
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}


contract ERC20 {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


contract Primacorp is Ownable {

    mapping (address => uint256) public allowance;
    uint256 public contributionInWei;
    address _tokenAddress = 0x2A22e5cCA00a3D63308fa39f29202eB1b39eEf52;
    address _wallet = 0x269D55Ef8AcFdf0B83cCd08278ab440f87f9E9D8;

    constructor(uint256 _contributionInWei) public {
        contributionInWei = _contributionInWei;
    }

    function() public payable {
        require(allowance[msg.sender] > 0);
        require(msg.value >= contributionInWei);
        ERC20(_tokenAddress).transfer(msg.sender, allowance[msg.sender]);
        allowance[msg.sender] = 0;
        _wallet.transfer(msg.value);
    }

    function withdraw(uint256 amount) external onlyOwner {
        ERC20(_tokenAddress).transfer(msg.sender, amount);
    }

    function changeAllowance(address _address, uint256 value) external onlyOwner {
        allowance[_address] = value;
    }

    function setWalletAddress(address newWalletAddress) external onlyOwner {
        _wallet = newWalletAddress;
    }

    function setContributionInWei(uint256 _valueInWei) external onlyOwner {
        contributionInWei = _valueInWei;
    }

}