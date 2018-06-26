pragma solidity 0.4.24;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

 function div(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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
 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


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
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


contract IdleGame is Ownable{
    
    using SafeMath for uint256;
    uint counter = 0;
    InvestmentPackage pkg;
    InvestmentOwnership pkgowner;
    InvestmentOwnership[] packagesOwner;
    
    mapping(address=>uint) public dividends;
    mapping(address=>uint) public amountInvestedByUser;
    
    uint public ownerPercentage;
    uint public investorsPercentage;
    uint public dividendFee;
    uint public totalInvestmentAmount;
    
    modifier isActivated(uint id) {
    require(packages[id].active == true);
    _;
    }
    
    modifier isDeactivated(uint id) {
    require(packages[id].active == false);
    _;
    }
    
    event Information(string message, uint number);
    event Information2(string message, uint[] numbers);
    
    constructor(address _owner) public {
        owner = _owner;
        dividendFee = 10;
        ownerPercentage = 25;
        investorsPercentage = 75;
    }
    
    struct InvestmentPackage {
        uint investmentId;
        string investmentName;
        uint investmentAmount;
        bool active;
    }
    
    struct InvestmentOwnership {
        uint investmentOptionId;
        uint investmentOptionNumber;
    }
    
    mapping (uint=>InvestmentPackage) packages;
    mapping (address=>InvestmentOwnership[]) packagesOwnerByUser;
    address[] investors;
    
    uint[] allPackageIds;
    uint[] idsOwnedByAUser;
    
    function addInvestmentPackage(string _investmentName, uint _investmentAmount) public onlyOwner {
        counter = counter + 1;
        pkg = InvestmentPackage({investmentId:counter,investmentName:_investmentName, investmentAmount:_investmentAmount,active:true});
        packages[counter] = pkg;
        allPackageIds.push(counter);
    }
    
    function removeInvestmentPackage(uint id) public onlyOwner {
        packages[id].active = false;
    }
    
    function getInvestmentPackageInformation(uint id) public constant returns (string,uint,bool){
        return (packages[id].investmentName,packages[id].investmentAmount,packages[id].active);
    }
    
    function getAllMyPackageIds() public returns (uint[]) {
        packagesOwner = packagesOwnerByUser[msg.sender];
        delete idsOwnedByAUser;
        for (uint i=0;i<packagesOwner.length;i++)
        {
            idsOwnedByAUser.push(packagesOwner[i].investmentOptionId);
        }
        emit Information2(&quot;Ids owner by user&quot;,idsOwnedByAUser);
        return idsOwnedByAUser;
    }
    
    function getMyInstancesOfAPackage(uint id) public returns(uint) {
        packagesOwner = packagesOwnerByUser[msg.sender];
        for (uint i=0;i<packagesOwner.length;i++)
        {
            if (packagesOwner[i].investmentOptionId == id)
            {
                emit Information(&quot;The number of instances of a package that user holds&quot;,packagesOwner[i].investmentOptionNumber);
                return packagesOwner[i].investmentOptionNumber;
            }
        }
    }
    
    function getAllInvestmentPackageIds() public constant returns(uint[]) {
        return allPackageIds;
    }
    
    function buyInvestmentPackage(uint id) public payable 
    {
        require(packages[id].active == true);
        
        if (packagesOwnerByUser[msg.sender].length == 0)
            investors.push(msg.sender);
        
        uint amount = packages[id].investmentAmount;
        uint sentAmount = msg.value;
        uint fee = sentAmount.mul(dividendFee).div(100);
        sentAmount = sentAmount.sub(fee);
        uint totalPackages = sentAmount.div(amount);
        uint usedAmt = totalPackages.mul(amount);
        uint remainderAmt = sentAmount.sub(usedAmt);
        
        totalInvestmentAmount = totalInvestmentAmount.add(usedAmt);
        
        pkgowner = InvestmentOwnership({investmentOptionId:id,investmentOptionNumber:totalPackages});
        packagesOwner = packagesOwnerByUser[msg.sender];
        
        for (uint i=0;i<packagesOwner.length;i++)
        {
            if (packagesOwner[i].investmentOptionId == id)
            {
                packagesOwner[i].investmentOptionNumber = packagesOwner[i].investmentOptionNumber.add(1);        
                packagesOwnerByUser[msg.sender] = packagesOwner;
                return;
            }
        }
        
        packagesOwner.push(pkgowner);
        packagesOwnerByUser[msg.sender] = packagesOwner;
        amountInvestedByUser[msg.sender] = amountInvestedByUser[msg.sender].add(usedAmt);
        
        uint cutForOwner = fee.mul(ownerPercentage).div(100);
        uint cutForInvestors = fee.mul(investorsPercentage).div(100);
        
        distributeFees(cutForInvestors);
        
        msg.sender.transfer(remainderAmt);
        owner.transfer(cutForOwner);
    }
    
    function distributeFees(uint fees) internal 
    {
        for (uint i=0;i<investors.length;i++)
        {
            uint shareOfUser = amountInvestedByUser[investors[i]].mul(fees);
            shareOfUser = shareOfUser.div(totalInvestmentAmount);
            dividends[investors[i]] =  dividends[investors[i]].add(shareOfUser);
        }
    }
    
    function exit() public {
        uint investedAmt = amountInvestedByUser[msg.sender];
        uint fee = investedAmt.mul(dividendFee).div(100);
        investedAmt = investedAmt.sub(fee);
        uint cutForOwner = fee.mul(ownerPercentage).div(100);
        uint cutForInvestors = fee.mul(investorsPercentage).div(100);
        distributeFees(cutForInvestors);
        owner.transfer(cutForOwner);
        uint valueToReturn = investedAmt.add(dividends[msg.sender]); 
        msg.sender.transfer(valueToReturn);
        delete packagesOwnerByUser[msg.sender];
        amountInvestedByUser[msg.sender] = 0;
        dividends[msg.sender]= 0;
        totalInvestmentAmount = totalInvestmentAmount.sub(investedAmt);
    }
    
    function deactivatePackage(uint id) public onlyOwner isActivated(id) {
        packages[id].active = false;
    }
    
    function activatePackage(uint id) public onlyOwner isDeactivated(id) {
        packages[id].active = true;
    }
    
    function setOwnerPercentage(uint percentage) public onlyOwner {
        require(percentage>0 && percentage<100);
        ownerPercentage = percentage;
    }
    
    function setInvestorsPercentage(uint percentage) public onlyOwner {
        require(percentage>0 && percentage<100);
        investorsPercentage = percentage;
    }
    
    function setDividendFee(uint percentage) public onlyOwner {
        require(percentage>0 && percentage<100);
        dividendFee = percentage;
    }
}