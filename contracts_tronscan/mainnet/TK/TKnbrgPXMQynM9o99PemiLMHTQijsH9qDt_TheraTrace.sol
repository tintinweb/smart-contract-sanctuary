//SourceUnit: TheraTrace.sol

pragma solidity 0.5.8;

contract Ownable {
    address payable private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address payable) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function transferOwnership(address payable newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address payable newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

contract MinterRole is Ownable {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender));
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyOwner {
        _addMinter(account);
    }

    function renounceMinter(address account) public onlyOwner {
        _removeMinter(account);
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

contract HomeTransaction {
    // Constants
    uint constant timeBetweenDepositAndFinalization = 5 minutes;
    uint constant depositPercentage = 10;

    enum ContractState {
        WaitingSellerSignature,
        WaitingBuyerSignature,
        WaitingDistributorReview,
        WaitingFinalization,
        Finalized,
        Rejected }
    ContractState public contractState = ContractState.WaitingSellerSignature;

    
    // Roles acting on contract
    address payable public distributor;
    address payable public seller;
    address payable public buyer;

    // Contract details
    string public homeAddress;
    string public zip;
    string public production;
    uint public distributorFee;
    uint public price;

    // Set when buyer signs and pays deposit
    uint public deposit;
    uint public finalizeDeadline;

    // Set when distributor reviews closing conditions
    enum ClosingConditionsReview { Pending, Accepted, Rejected }
    ClosingConditionsReview closingConditionsReview = ClosingConditionsReview.Pending;

    constructor(
        string memory _address,
        string memory _zip,
        string memory _production,
        uint _distributorFee,
        uint _price,
        address payable _distributor,
        address payable _seller,
        address payable _buyer) public {
        require(_price >= _distributorFee, "Price needs to be more than distributor fee!");

        distributor = _distributor;
        seller = _seller;
        buyer = _buyer;
        homeAddress = _address;
        zip = _zip;
        production = _production;
        price = _price;
        distributorFee = _distributorFee;
    }

    function sellerSignContract() public payable {
        require(seller == msg.sender, "Only seller can sign contract");

        require(contractState == ContractState.WaitingSellerSignature, "Wrong contract state");

        contractState = ContractState.WaitingBuyerSignature;
    }

    function buyerSignContractAndPayDeposit() public payable {
        require(buyer == msg.sender, "Only buyer can sign contract");

        require(contractState == ContractState.WaitingBuyerSignature, "Wrong contract state");
    
        require(msg.value >= price*depositPercentage/100 && msg.value <= price, "Buyer needs to deposit between 10% and 100% to sign contract");

        contractState = ContractState.WaitingDistributorReview;

        deposit = msg.value;
        finalizeDeadline = now + timeBetweenDepositAndFinalization;
    }

    function distributorReviewedClosingConditions(bool accepted) public {
        require(distributor == msg.sender, "Only distributor can review closing conditions");

        require(contractState == ContractState.WaitingDistributorReview, "Wrong contract state");
        
        if (accepted) {
            closingConditionsReview = ClosingConditionsReview.Accepted;
            contractState = ContractState.WaitingFinalization;
        } else {
            closingConditionsReview = ClosingConditionsReview.Rejected;
            contractState = ContractState.Rejected;
            
            buyer.transfer(deposit);
        }
    }

    function buyerFinalizeTransaction() public payable {
        require(buyer == msg.sender, "Only buyer can finalize transaction");

        require(contractState == ContractState.WaitingFinalization, "Wrong contract state");

        require(msg.value + deposit == price, "Buyer needs to pay the rest of the cost to finalize transaction");

        contractState = ContractState.Finalized;

        seller.transfer(price-distributorFee);
        distributor.transfer(distributorFee);
    }

    function anyWithdrawFromTransaction() public {
        require(buyer == msg.sender || finalizeDeadline <= now, "Only buyer can withdraw before transaction deadline");

        require(contractState == ContractState.WaitingFinalization, "Wrong contract state");

        contractState = ContractState.Rejected;

        seller.transfer(deposit-distributorFee);
        distributor.transfer(distributorFee);
    }
}

contract TheraTrace is MinterRole {
  HomeTransaction[] contracts;

  function create(
        string memory _address,
        string memory _zip,
        string memory _production,
        uint _distributorFee,
        uint _price,
        address payable _seller,
        address payable _buyer) public onlyMinter returns(HomeTransaction homeTransaction)  {
    homeTransaction = new HomeTransaction(
      _address,
      _zip,
      _production,
      _distributorFee,
      _price,
      msg.sender,
      _seller,
      _buyer);
    contracts.push(homeTransaction);
  }

  function getInstance(uint index) public view returns (HomeTransaction instance) {
    require(index < contracts.length, "index out of range");

    instance = contracts[index];
  }

  function getInstances() public view returns (HomeTransaction[] memory instances) {
    instances = contracts;
  }

  function getInstanceCount() public view returns (uint count) {
    count = contracts.length;
  }
}