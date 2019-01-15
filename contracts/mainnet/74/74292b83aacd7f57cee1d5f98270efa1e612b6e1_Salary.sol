pragma solidity 0.4.25;

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

contract Salary {
  using SafeMath for uint256;
  address public admin;
  mapping(address => bool) public helperAddressTable;
  address[] public addressList;
  uint256 public deliveredId;
  // deliveredId is global index indicates the number of months that the company deliver tokens.
  // StaffAddress => ( deliveredId => monthlySalaryAmount )

  mapping(address => mapping(uint256 => uint256)) public staffSalaryData;
  // status: 0 (null) status: 1 (normal) status: 2 (terminated)
  mapping(address => uint256) public staffSalaryStatus;

  ERC20 token;

  event TerminatePackage(address indexed staff);
  event ChangeTokenContractAddress(address indexed newAddress);
  
  modifier onlyAdmin() {
    require(msg.sender == admin);
    _;
  }

  modifier onlyHelper() {
    require(msg.sender == admin || helperAddressTable[msg.sender] == true);
    _;
  }

  function getFullAddressList() view public returns(address[]) {
    return addressList;
  }

  /**
  * @dev This would distribute all salary of the month.
  */
  function distribute() public onlyAdmin {
    uint256 i;
    address receiverAddress;
    uint256 transferAmount;
    for(i = 0; i < addressList.length; i++) {
      receiverAddress = addressList[i];
      if (staffSalaryStatus[receiverAddress] == 1) {
        transferAmount = staffSalaryData[receiverAddress][deliveredId];
        if (transferAmount > 0) {
          require(token.transfer(receiverAddress, transferAmount));
        }
      }
    }
    deliveredId = deliveredId + 1;
  }

  /**
  * @dev The function should only be called from Admin.  This would require users approve
  * efficient amount of Token to the contract beforehead.
  * @param _staffAddress address The staff&#39;s wallet address where they would receive their salary.
  * @param _monthlySalary uint256[] every monthly salary start from next index
  */

  function newPackage(address _staffAddress, uint256[] _monthlySalary) external onlyHelper{
    uint256 i;
    uint256 packageTotalAmount = 0;
    require(staffSalaryStatus[_staffAddress] == 0);
    for (i = 0; i < _monthlySalary.length; i++) {
      staffSalaryData[_staffAddress][deliveredId + i] = _monthlySalary[i];
      packageTotalAmount = packageTotalAmount + _monthlySalary[i];
    }
    addressList.push(_staffAddress);
    staffSalaryStatus[_staffAddress] = 1;
    require(token.transferFrom(msg.sender, address(this), packageTotalAmount));
  }

  /**
  * @dev When there&#39;s a staff resign and terminate the package, admin can withdraw tokens
  * from the contract.  This would emit an event TerminatePackage which is the only event of this contract.
  * all staff should watch this event on Ethereum in order to protect their rights.
  * efficient amount of Token to the contract beforehead.
  * @param _staffAddress address The staff&#39;s wallet address where they would receive their salary.
  */
  function terminatePackage(address _staffAddress) external onlyAdmin {
    emit TerminatePackage(_staffAddress);
    staffSalaryStatus[_staffAddress] = 2;
  }

  function withdrawToken(uint256 amount) public onlyAdmin {
    require(token.transfer(admin, amount));
  }

  /**
  * @dev To facilitate the process of constructing salary system, we need an address that could
  * execute `newPacakge`.
  * @param _helperAddress the address that is to be assigned as a helper
  */
  function setHelper(address _helperAddress) external onlyAdmin {
    helperAddressTable[_helperAddress] = true;
  }

  /**
  * @dev A address controled by hotwallet that is
  * able to call newPackage is a risk to the system. We should remove helper after
  * the packages are properly set.
  * @param _helperAddress the address to be removed from helper.
  */
  function removeHelper(address _helperAddress) external onlyAdmin {
    require(helperAddressTable[_helperAddress] = true);
    helperAddressTable[_helperAddress] = false;
  }

  /**
   * @dev Change token address from BCNP to BCNT
   * @param _newAddress the new token contract address
  */ 
  function changeTokenContractAddress(address _newAddress) external onlyAdmin {
    require(_newAddress != address(0));
    token = ERC20(_newAddress);
    emit ChangeTokenContractAddress(_newAddress);
  }

  constructor (address _tokenAddress) public {
    admin = msg.sender;
    token = ERC20(_tokenAddress);
  }
}