/**
 *Submitted for verification at Etherscan.io on 2019-07-09
*/

pragma solidity ^0.5.8;

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

library SafeMath {

  
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

 
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}



contract SGCMasterCard is Ownable {
    
    using SafeMath for uint256;
    
    uint256 masterCardCount;

    enum masterCardStatus { Inprocess, Issued, Returned }
    
    mapping(address => MasterCard) card;

    struct MasterCard {
        
        uint256 masterCardNumber;
        uint256 valueLocked;
        uint256 amountReturned;
        uint256 amountAdminWithdraw;
        uint256 utilizedFunds;
        uint256 amountLockTime;
        uint256 amountWithdrawTime;
        address masterCardHolderAddress;
        bool amountLockedStatus;
        masterCardStatus status;

    }
    
    constructor() public {
        
        masterCardCount = 1;
    
    }
    
    function getOrderCount() public view returns(uint256 _count){
        _count = masterCardCount - 1;
    }

    function masterCardEscrow() public payable {
        
        uint256 sgcAmount = msg.value;
        
        address _address = msg.sender;
        
        require(sgcAmount != 0);
        
        if (card[_address].amountLockedStatus != true){
        
            card[_address].valueLocked = sgcAmount;
            card[_address].amountLockTime = block.timestamp;
            card[_address].masterCardHolderAddress = msg.sender;
            card[_address].amountLockedStatus = true;
            card[_address].status = masterCardStatus.Inprocess;
            
            masterCardCount = masterCardCount.add(1);
            
        }
        
        else if (card[_address].amountLockedStatus == true){
            
            card[_address].valueLocked = card[_address].valueLocked.add(sgcAmount);
            card[_address].amountLockTime = block.timestamp;
            
        }
        
    }
    
   function getDetails(address _address) public view returns(uint256 _masterCardNumber,uint256 _valueLocked,uint256 _amountReturned, uint256 _amountAdminWithdraw, uint256 _utilizedFunds, uint256 _amountLockTime, uint256 _amountWithdrawTime,address _masterCardHolderAddress, bool _amountLockedStatus, masterCardStatus _status){
        
        _masterCardNumber = card[_address].masterCardNumber;
        _valueLocked = card[_address].valueLocked;
        _amountReturned = card[_address].amountReturned;
        _amountAdminWithdraw = card[_address].amountAdminWithdraw;
        _utilizedFunds = card[_address].utilizedFunds;
        _amountLockTime = card[_address].amountLockTime;
        _amountWithdrawTime = card[_address].amountWithdrawTime;
        _masterCardHolderAddress = card[_address].masterCardHolderAddress;
        _amountLockedStatus = card[_address].amountLockedStatus;
        _status = card[_address].status;
        
    }

    function updateUtilizedFundsByUser (address _address, uint256 _amount) public onlyOwner {

        require (card[_address].valueLocked >= _amount,"Invalid amount!");

        card[_address].valueLocked = card[_address].valueLocked.sub(_amount);
        card[_address].utilizedFunds = card[_address].utilizedFunds.add(_amount);

        if (card[_address].valueLocked == 0){

        card[_address].amountLockedStatus = false;
        
        }

    }
    
    function adminEscrowedFundsWithdraw(uint256 _amount, address payable _address, address _withdrawFrom) public onlyOwner{
        
        require(_amount <= card[_withdrawFrom].utilizedFunds,"Invalid amount!");

        card[_withdrawFrom].utilizedFunds = card[_withdrawFrom].utilizedFunds.sub(_amount);
        card[_withdrawFrom].amountAdminWithdraw = card[_withdrawFrom].amountAdminWithdraw.add(_amount);
        _address.transfer(_amount);
        
    }
    
    function issueMasterCardNumber(address _address, uint256 _number) public onlyOwner {
        
        card[_address].masterCardNumber = _number;
        card[_address].status = masterCardStatus.Issued;
    
    }
    
    function withdrawCard(uint256 _returnAmount, address payable _address) public onlyOwner {
        
        
        require(card[_address].status != masterCardStatus.Returned,"Already returned");
        
        require(card[_address].valueLocked >= _returnAmount,"Invalid amount!");

        require(_returnAmount != 0);
        
        card[_address].valueLocked = card[_address].valueLocked.sub(_returnAmount);
        card[_address].amountWithdrawTime = block.timestamp;
        card[_address].amountReturned = card[_address].amountReturned.add(_returnAmount);

        if (card[_address].valueLocked == 0){

            card[_address].amountLockedStatus = false;
        
        }
        
        if (card[_address].valueLocked == 0){

            card[_address].status = masterCardStatus.Returned;
        
        }
        
        _returnAmount = _returnAmount;
        
        _address.transfer(_returnAmount);
        
    }
    
}