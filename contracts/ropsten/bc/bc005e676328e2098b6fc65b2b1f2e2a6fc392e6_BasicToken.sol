/**
 *Submitted for verification at Etherscan.io on 2019-07-04
*/

/**
 *Submitted for verification at Etherscan.io on 2018-03-26
*/

pragma solidity ^0.4.18;

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

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
    uint256 c = a / b;
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

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

contract Multiownable {

    address[] public owners;
    mapping(address => uint) ownersIndices; // Starts from 1
    uint256 public howManyOwnersDecide; 
    address insideOnlyManyOwners;

    bytes32[] private allOperations; // private <=> public debugging
    mapping(bytes32 => uint) allOperationsIndicies;
    mapping(bytes32 => uint256) private votesMaskByOperation; // private <=> public debugging
    mapping(bytes32 => uint256) private votesCountByOperation; // private <=> public debugging

    event OwnershipTransferred(address[] previousOwners, address[] newOwners);

    function isOwner(address wallet) public constant returns(bool) {
        return ownersIndices[wallet] > 0;
    }

    function ownersCount() public constant returns(uint) {
        return owners.length;
    }

    // private <=> public debugging
    function allOperationsCount() private constant returns(uint)  {
        return allOperations.length;
    }

    modifier onlyAnyOwner {
        require(isOwner(msg.sender));
        _;
    }

    modifier onlyManyOwners {
        
        if (insideOnlyManyOwners == msg.sender) {
            _;
            return;
        }
        require(isOwner(msg.sender));

        uint ownerIndex = ownersIndices[msg.sender] - 1;
        bytes32 operation = keccak256(msg.data);
        
        if (votesMaskByOperation[operation] == 0) {
            allOperationsIndicies[operation] = allOperations.length;
            allOperations.push(operation);
        }
        require((votesMaskByOperation[operation] & (2 ** ownerIndex)) == 0);
        votesMaskByOperation[operation] |= (2 ** ownerIndex);
        votesCountByOperation[operation] += 1;

        if (votesCountByOperation[operation] == howManyOwnersDecide) {
            deleteOperation(operation);
            insideOnlyManyOwners = msg.sender;
            _;
            insideOnlyManyOwners = address(0);
        }
    }

    function Multiownable() public {
        owners.push(msg.sender);
        ownersIndices[msg.sender] = 1;
        howManyOwnersDecide = 1;
    }

    function deleteOperation(bytes32 operation) internal {
        uint index = allOperationsIndicies[operation];
        if (allOperations.length > 1) {
            allOperations[index] = allOperations[allOperations.length - 1];
            allOperationsIndicies[allOperations[index]] = index;
        }
        allOperations.length--;
        
        delete votesMaskByOperation[operation];
        delete votesCountByOperation[operation];
        delete allOperationsIndicies[operation];
    }

    function cancelPending(bytes32 operation) public onlyAnyOwner {
        uint ownerIndex = ownersIndices[msg.sender] - 1;
        require((votesMaskByOperation[operation] & (2 ** ownerIndex)) != 0);
        
        votesMaskByOperation[operation] &= ~(2 ** ownerIndex);
        votesCountByOperation[operation]--;
        if (votesCountByOperation[operation] == 0) {
            deleteOperation(operation);
        }
    }

    function transferOwnership(address[] newOwners) public {
        transferOwnershipWithHowMany(newOwners, newOwners.length);
    }

    function transferOwnershipWithHowMany(address[] newOwners, uint256 newHowManyOwnersDecide) public onlyManyOwners {
        
        require(newOwners.length > 0);
        require(newOwners.length <= 256);
        require(newHowManyOwnersDecide > 0);
        require(newHowManyOwnersDecide <= newOwners.length);
        for (uint i = 0; i < newOwners.length; i++) {
            require(newOwners[i] != address(0));
        }

        OwnershipTransferred(owners, newOwners);

        for (i = 0; i < owners.length; i++) {
            delete ownersIndices[owners[i]];
        }
        for (i = 0; i < newOwners.length; i++) {
            require(ownersIndices[newOwners[i]] == 0);
            ownersIndices[newOwners[i]] = i + 1;
        }
        owners = newOwners;
        howManyOwnersDecide = newHowManyOwnersDecide;

        for (i = 0; i < allOperations.length; i++) {
            delete votesMaskByOperation[allOperations[i]];
            delete votesCountByOperation[allOperations[i]];
            delete allOperationsIndicies[allOperations[i]];
        }
        allOperations.length = 0;
    }

}
        
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

contract ContractOwnable is Multiownable{

  address public contractOwner; 

  event ContractOwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  function ContractOwnable() public {
    contractOwner = msg.sender;
  }

  modifier onlyContractOwner() {
    require(msg.sender == contractOwner);
    _;
  }

  function contractTransferOwnership(address newOwner) public onlyManyOwners {
    require(newOwner != address(0));
    ContractOwnershipTransferred(contractOwner, newOwner);
    contractOwner = newOwner;
  }
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

contract BasicToken {

  using SafeMath for uint256;

  uint256 totalSupply_;
  mapping(address => uint256) balances;

  uint256 totalReserve_;
  address[] allInvestors; 
  mapping(address => uint) allInvestorsIndicies;     
  mapping(address => uint256) reserveBalances;

  event Transfer(address indexed from, address indexed to, uint256 value);

  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  function totalReserve() public view returns (uint256) {
    return totalReserve_;
  }

  function transfer(address _to, uint256 _value) public returns (bool) {

    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

  function reserveBalanceOf(address _owner) public view returns (uint256 balance) {
    return reserveBalances[_owner];
  }


}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

contract MintableToken is BasicToken, ContractOwnable {
  
  uint256 totalTokens  = 30000000;

  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;

  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  function mint(address _to, uint256 _amount) onlyContractOwner canMint public returns (bool) {
  
    require(totalSupply_.add(_amount).add(totalReserve_) <= totalTokens);
  
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }
  
  function reserve(address _to, uint256 _amount) onlyContractOwner canMint public returns (bool) {
  
    require(totalSupply_.add(_amount).add(totalReserve_) <= totalTokens);
  
    totalReserve_ = totalReserve_.add(_amount);
    reserveBalances[_to] = reserveBalances[_to].add(_amount);

        if (allInvestorsIndicies[_to] == 0){
        
               allInvestors.push(_to);        
               allInvestorsIndicies[_to] = allInvestors.length;
        }

   return true;
  }  

  function refund(address _to) onlyContractOwner canMint public returns (uint256) {
  
  
        uint256 _tokenAmount = reserveBalances[_to];
        require(_tokenAmount > 0);
  
        reserveBalances[_to] = 0;
        totalReserve_ = totalReserve_.sub(_tokenAmount);
        

        uint investorIndex = allInvestorsIndicies[_to];
        if (investorIndex > 0){

               allInvestors[investorIndex-1] = allInvestors[allInvestors.length - 1];
               allInvestors.length = allInvestors.length - 1;
               allInvestorsIndicies[allInvestors[investorIndex-1]] = investorIndex;
               
               delete allInvestorsIndicies[_to];                                    
               delete reserveBalances[_to];
        }

    return _tokenAmount;
  }  

  function confirm(address _to) onlyContractOwner canMint public returns (bool) {
  
        uint256 _tokenAmount = reserveBalances[_to];
        require(_tokenAmount > 0);
        
        reserveBalances[_to] = 0;
        totalReserve_ = totalReserve_.sub(_tokenAmount);      
        
    totalSupply_ = totalSupply_.add(_tokenAmount);
    balances[_to] = balances[_to].add(_tokenAmount); 
        
    return true;
  }  


  function finishMinting() onlyManyOwners canMint public returns (bool) {

        for (uint i = 0; i < allInvestors.length; i++) {
        
               totalSupply_ = totalSupply_.add(reserveBalances[allInvestors[i]]);
            balances[allInvestors[i]] = balances[allInvestors[i]].add(reserveBalances[allInvestors[i]]);
               
               delete reserveBalances[allInvestors[i]];
               delete allInvestorsIndicies[allInvestors[i]];
        }

    allInvestors.length = 0;
        totalReserve_ = 0;
  
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

contract CrownPreSaleToken is MintableToken {

  string public constant name = "Crown pre-sale token";
  string public constant symbol = "CRW";
  uint32 public constant decimals = 0;
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

contract CrownPreSale is ContractOwnable {

  using SafeMath for uint256;

  uint256 public endTime;
  address public wallet;

  bool public isFinalized = false;
  
  uint256 public weiTotal; // total amount
  uint256 public weiRaised; // amount of raised money in wei

  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  event Finalized();

  CrownPreSaleToken public token;

  function CrownPreSale(uint256 _endTime, address _wallet, CrownPreSaleToken _token) public {
    
    require(_wallet != address(0));

    endTime = _endTime;
    wallet = _wallet;
        token = _token;
  }

  function () external payable {

    buyTokens(msg.sender);
  }

  function buyTokens(address beneficiary) public payable {

    require(beneficiary != address(0));
    require(validPurchase());

    uint256 weiAmount = msg.value;
    uint256 tokens = getTokenAmount(beneficiary, weiAmount); // calculate token amount to be created
        require(tokens > 0);

    weiTotal = weiTotal.add(weiAmount);
    token.mint(beneficiary, tokens);

    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
  }
  
   function holdTokens(address buyer) public payable {

    require(buyer != address(0));
    require(validPurchase());

    uint256 weiAmount = msg.value;
    uint256 tokens = getTokenAmount(buyer, weiAmount); // calculate token amount to be created
        require(tokens > 0);

    weiRaised = weiRaised.add(weiAmount);

        token.reserve(buyer, tokens);
  } 
  
  function refundTokens(address buyer) public {

    require(buyer != address(0));
    require(validPurchase());

        uint256 _tokenAmount = token.refund(buyer);
        uint256 _amount = _tokenAmount * 4760000000000000;

        buyer.transfer(_amount);

  } 
  
  function confirmTokens(address buyer) public {

    require(buyer != address(0));
    require(validPurchase());

        token.confirm(buyer);
  } 
  

  function hasEnded() public view returns (bool) {
  
    return now > endTime;
  }


  function getTokenAmount(address _beneficiary, uint256 weiAmount) internal view returns(uint256) {
  
        uint256 existsTokens = token.balanceOf(_beneficiary);
        uint256 futureTokens = weiAmount / 5000000000000000;

        if (existsTokens + futureTokens < 1247) {
               return weiAmount / 5600000000000000;
        }
  
        if (existsTokens + futureTokens < 2625) {
               return weiAmount / 5320000000000000;
        }  
        
        if (existsTokens + futureTokens < 13409) {
               return weiAmount / 5208000000000000;
        }       
        
        if (existsTokens + futureTokens < 41567) {
               return weiAmount / 5040000000000000;
        }              
  
        return weiAmount / 4760000000000000;
   }

  function validPurchase() internal view returns (bool) {
  
    bool withinPeriod = now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }
  
  function finalize() onlyManyOwners public {

    require(!isFinalized);
    require(hasEnded());

    finalization();
    Finalized();

    isFinalized = true;
  }

  function finalization() internal {
  
        wallet.transfer(weiRaised);
        wallet.transfer(weiTotal);
        weiRaised = 0; 
        weiTotal = 0;
  }
  
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

contract CrownDeposit is ContractOwnable {

        using SafeMath for uint256;

        address commissionAddress;
        CrownPreSale investmentAddress;
        uint256 commissionPercentage = 1;
        
    function CrownDeposit(CrownPreSale _investmentAddress, address _commissionAddress, uint256 _commissionPercentage) public {
        
            require(_commissionAddress != address(0));
            require(_investmentAddress != address(0));
               require(_commissionPercentage > 0);                   

               commissionPercentage = _commissionPercentage;
               commissionAddress = _commissionAddress;
               investmentAddress = _investmentAddress;
    }


    function invest() public payable {
        
               require(msg.sender != address(0));
               
               uint256 commissionAmount = msg.value.mul(commissionPercentage).div(100);
               uint256 investAmount     = msg.value.sub(commissionAmount);
               
               require(commissionAmount > 0);

               investmentAddress.holdTokens.value(investAmount)(msg.sender);
               commissionAddress.transfer(commissionAmount);
  }


    function refund() public{

               require(msg.sender != address(0));
               investmentAddress.refundTokens(msg.sender);
    }

    function confirm() public{

               require(msg.sender != address(0));
               investmentAddress.confirmTokens(msg.sender);
    }

}


contract ExternalAccountsBase {

        using SafeMath for uint256;
        
        mapping(address => mapping(int => string)) _database;
        
    function ExternalAccountsBase() public {
    }

        function additionalCurrency(address _owner, int _currencyType) public view returns (string linkAddress) {
               return _database[_owner][_currencyType];
        }

    function editAddress(int _addressType, string _address) public{
        
            require(msg.sender != address(0));
            require(_addressType == 0 || _addressType == 1);
               
               _database[msg.sender][_addressType] = _address;
    }
}