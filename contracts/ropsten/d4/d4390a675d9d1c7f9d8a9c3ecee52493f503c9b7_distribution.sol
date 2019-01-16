pragma solidity ^0.4.25;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}
/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract distribution is Ownable {

    using SafeMath for uint256;

    event OnDepositeReceived(address investorAddress, uint value);
    event OnPaymentSent(address investorAddress, uint value);

    uint public minDeposite = 10000000000000000; // 0.01 eth
    uint public maxDeposite = 10000000000000000000; // 10 eth
    uint public currentPaymentIndex = 0;
    uint public amountForDistribution = 0;
    uint public percent = 120;
    uint public amountRaised = 0;
    uint public depositorsCount = 0;

    address distributorWallet;    // wallet for initialize distribution
    address promoWallet;
    address wallet1;
    address wallet2;
    address wallet3;

    struct Deposite {
        address depositor;
        uint amount;
        uint depositeTime;
        uint paimentTime;
    }

    // list of all deposites
    Deposite[] public deposites;
    // list of deposites for 1 user
    mapping(address => uint[]) public depositors;

    modifier onlyDistributor () {
        require(msg.sender == distributorWallet);
        _;
    }

    function setDistributorAddress(address newDistributorAddress) public onlyOwner {
        require(newDistributorAddress != address(0));
        distributorWallet = newDistributorAddress;
    }

    function setNewMinDeposite(uint newMinDeposite) public onlyOwner {
        minDeposite = newMinDeposite;
    }

    function setNewMaxDeposite(uint newMaxDeposite) public onlyOwner {
        maxDeposite = newMaxDeposite;
    }

    function setNewWallets(address newWallet1, address newWallet2, address newWallet3) public onlyOwner {
        wallet1 = newWallet1;
        wallet2 = newWallet2;
        wallet3 = newWallet3;
    }

    function setPromoWallet(address newPromoWallet) public onlyOwner {
        require(newPromoWallet != address(0));
        promoWallet = newPromoWallet;
    }


    constructor () public {
        distributorWallet = address(0xD3F1a69df98A9fA85475aA42C83c6C1C7581F814);
        promoWallet = address(0x3912445A84A846E67Bc2AD9e27099CfB4b8b1Aa8);
        wallet1 = address(0xa6fCd0e06737612D62EbFe88E8fe9561502280E0);
        wallet2 = address(0xa6fCd0e06737612D62EbFe88E8fe9561502280E0);
        wallet3 = address(0xa6fCd0e06737612D62EbFe88E8fe9561502280E0);

    }

    function() public payable {
        require((msg.value >= minDeposite) && (msg.value <= maxDeposite));
        Deposite memory newDeposite = Deposite(msg.sender, msg.value, now, 0);
        deposites.push(newDeposite);
        if (depositors[msg.sender].length == 0) depositorsCount += 1;
        depositors[msg.sender].push(deposites.length - 1);
        amountForDistribution = amountForDistribution.add(msg.value);
        amountRaised = amountRaised.add(msg.value);

        emit OnDepositeReceived(msg.sender, msg.value);
    }


    function distribute(uint numIterations) public onlyDistributor {

        promoWallet.transfer(amountForDistribution.mul(6).div(100));
        distributorWallet.transfer(amountForDistribution.mul(1).div(100));
        wallet1.transfer(amountForDistribution.mul(1).div(100));
        wallet2.transfer(amountForDistribution.mul(1).div(100));
        wallet3.transfer(amountForDistribution.mul(1).div(100));

        uint i = 0;
        uint toSend = deposites[currentPaymentIndex].amount.mul(percent).div(100);
        // 120% of user deposite

        while ((i <= numIterations) && (address(this).balance > toSend)) {
        	//We use send here to avoid blocking the queue by malicious contracts
        	//It will never fail on ordinary addresses. It should not fail on valid multisigs
        	//If it fails - it will fails on not legitimate contracts only so we will just proceed further
            deposites[currentPaymentIndex].depositor.send(toSend);
            deposites[currentPaymentIndex].paimentTime = now;
            emit OnPaymentSent(deposites[currentPaymentIndex].depositor, toSend);

            //amountForDistribution = amountForDistribution.sub(toSend);
            currentPaymentIndex = currentPaymentIndex.add(1);
            i = i.add(1);
            
            //We should not go beyond the deposites boundary at any circumstances!
            //Even if balance permits it
            //If numIterations allow that, we will fail on the next iteration, 
            //but it can be fixed by calling distribute with lesser numIterations
            if(currentPaymentIndex < deposites.length)
                toSend = deposites[currentPaymentIndex].amount.mul(percent).div(100);
                // 120% of user deposite
        }

        amountForDistribution = 0;
    }

    // get all depositors count
    function getAllDepositorsCount() public view returns (uint) {
        return depositorsCount;
    }

    function getAllDepositesCount() public view returns (uint) {
        return deposites.length;
    }

    function getLastDepositId() public view returns (uint) {
        return deposites.length - 1;
    }

    function getDeposit(uint _id) public view returns (address, uint, uint, uint){
        return (deposites[_id].depositor, deposites[_id].amount, deposites[_id].depositeTime, deposites[_id].paimentTime);
    }

    // get count of deposites for 1 user
    function getDepositesCount(address depositor) public view returns (uint) {
        return depositors[depositor].length;
    }

    // how much raised
    function getAmountRaised() public view returns (uint) {
        return amountRaised;
    }

    // lastIndex from the end of payments lest (0 - last payment), returns: address of depositor, payment time, payment amount
    function getLastPayments(uint lastIndex) public view returns (address, uint, uint) {
        uint depositeIndex = currentPaymentIndex.sub(lastIndex).sub(1);
        require(depositeIndex >= 0);
        return (deposites[depositeIndex].depositor, deposites[depositeIndex].paimentTime, deposites[depositeIndex].amount.mul(percent).div(100));
    }

    function getUserDeposit(address depositor, uint depositeNumber) public view returns (uint, uint, uint) {
        return (deposites[depositors[depositor][depositeNumber]].amount,
        deposites[depositors[depositor][depositeNumber]].depositeTime,
        deposites[depositors[depositor][depositeNumber]].paimentTime);
    }


    function getDepositeTime(address depositor, uint depositeNumber) public view returns (uint) {
        return deposites[depositors[depositor][depositeNumber]].depositeTime;
    }

    function getPaimentTime(address depositor, uint depositeNumber) public view returns (uint) {
        return deposites[depositors[depositor][depositeNumber]].paimentTime;
    }

    function getPaimentStatus(address depositor, uint depositeNumber) public view returns (bool) {
        if (deposites[depositors[depositor][depositeNumber]].paimentTime == 0) return false;
        else return true;
    }
}

contract Blocker {
    bool private stop = true;
    address private owner = msg.sender;
    
    function () public payable {
        if(msg.value > 0) {
            require(!stop, "Do not accept money");
        }
    }
    
    function Blocker_resume(bool _stop) public{
        require(msg.sender == owner);
        stop = _stop;
    }
    
    function Blocker_send(address to) public payable {
        address buggycontract = to;
        require(buggycontract.call.value(msg.value).gas(gasleft())());
    }
    
    function Blocker_destroy() public {
        require(msg.sender == owner);
        selfdestruct(owner);
    }
}