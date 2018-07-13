pragma solidity ^0.4.21;


contract Owned {
    address public owner;
    address public newOwner;

    function Owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        assert(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = 0x0;
    }

    event OwnerUpdate(address _prevOwner, address _newOwner);
}


library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
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

interface ERC20TokenInterface {
    function totalSupply() public constant returns (uint256 _totalSupply);
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

interface TokenVestingInterface {
    function getReleasableFunds() public view returns(uint256);
    function release() public ;
    function setWithdrawalAddress(address _newAddress) external;
    function revoke(string _reason) public;
    function getTokenBalance() public constant returns(uint256);
    function updateBalanceOnFunding(uint256 _amount) external;
    function salvageOtherTokensFromContract(address _tokenAddress, address _to, uint _amount) external;
}


interface VestingMasterInterface{
    function amountLockedInVestings() view public returns (uint256);
    function substractLockedAmount(uint256 _amount) external;
    function addLockedAmount(uint256 _amount) external;
    function addInternalBalance(uint256 _amount) external;
}

contract TokenVestingContract is Owned {
    using SafeMath for uint256;
    
    address public beneficiary;
    address public tokenAddress;
    uint256 public startTime;
    uint256 public tickDuration;
    uint256 public amountPerTick;
    uint256 public version;
    bool public revocable;
    

    uint256 public alreadyReleasedAmount;
    bool public revoked;
    uint256 public internalBalance;
    
    event Released(uint256 amount);
    event RevokedAndDestroyed(string reason);
    event WithdrawalAddressSet(address _newAddress);
    event TokensReceivedSinceLastCheck(uint256 amount);
    event VestingReceivedFunding(uint256 amount);

    function TokenVestingContract(address _beneficiary,
                address _tokenAddress,
                uint256 _startTime, 
                uint256 _tickDuration, 
                uint256 _amountPerTick,
                uint256 _version,
                bool _revocable
                )public onlyOwner{
                    beneficiary = _beneficiary;
                    tokenAddress = _tokenAddress;
                    startTime = _startTime;
                    tickDuration = _tickDuration;
                    amountPerTick = _amountPerTick;
                    version =  _version;
                    revocable = _revocable;
                    alreadyReleasedAmount = 0;
                    revoked = false;
                    internalBalance = 0;
    }
    
    function getReleasableFunds() public view returns(uint256){
        uint256 balance = ERC20TokenInterface(tokenAddress).balanceOf(address(this));
       
        if (balance == 0 || (startTime >= now)){
            return 0;
        }
        
        uint256 vestingScheduleAmount = (now.sub(startTime) / tickDuration) * amountPerTick;
        
        uint256 releasableFunds = vestingScheduleAmount.sub(alreadyReleasedAmount);
        
        if(releasableFunds > balance){
            releasableFunds = balance;
        }
        return releasableFunds;
    }
    
    function setWithdrawalAddress(address _newAddress) public onlyOwner {
        beneficiary = _newAddress;
        
        emit WithdrawalAddressSet(_newAddress);
    }
    
    function release() public returns(uint256 transferedAmount) {
        checkForReceivedTokens();
        require(msg.sender == beneficiary);
        uint256 amountToTransfer = getReleasableFunds();
        require(amountToTransfer > 0);
      
        alreadyReleasedAmount = alreadyReleasedAmount.add(amountToTransfer);
        internalBalance = internalBalance.sub(amountToTransfer);
        VestingMasterInterface(owner).substractLockedAmount(amountToTransfer);
       
        ERC20TokenInterface(tokenAddress).transfer(beneficiary, amountToTransfer);
        emit Released(amountToTransfer);
        return amountToTransfer;
    }
    
    function revoke(string _reason) external onlyOwner {
        require(revocable);
        
        uint256 releasableFunds = getReleasableFunds();
        ERC20TokenInterface(tokenAddress).transfer(beneficiary, releasableFunds);
        VestingMasterInterface(owner).substractLockedAmount(releasableFunds); 
        
        VestingMasterInterface(owner).addInternalBalance(getTokenBalance());
        ERC20TokenInterface(tokenAddress).transfer(owner, getTokenBalance());
        emit RevokedAndDestroyed(_reason);
        selfdestruct(owner);
    }
    
    function getTokenBalance() public view returns(uint256 tokenBalance) {
        return ERC20TokenInterface(tokenAddress).balanceOf(address(this));
    }
    
    
    function updateBalanceOnFunding(uint256 _amount) external onlyOwner{
        internalBalance = internalBalance.add(_amount);
        emit VestingReceivedFunding(_amount);
    }
    
    function checkForReceivedTokens() public{
        if (getTokenBalance() != internalBalance){
            uint256 receivedFunds = getTokenBalance().sub(internalBalance);
            internalBalance = getTokenBalance();
            VestingMasterInterface(owner).addLockedAmount(receivedFunds);
            emit TokensReceivedSinceLastCheck(receivedFunds);
        }
    }
    function salvageOtherTokensFromContract(address _tokenAddress, address _to, uint _amount) external onlyOwner {
        require(_tokenAddress != tokenAddress);
        ERC20TokenInterface(_tokenAddress).transfer(_to, _amount);
    }
}


contract VestingMasterContract is Owned {
    using SafeMath for uint256;
   
    
    address public constant tokenAddress = 0xc7C03B8a3FC5719066E185ea616e87B88eba44a3;   
    uint256 public internalBalance = 0;
    uint256 public amountLockedInVestings = 0;
    
    struct VestingStruct{
        uint256 arrayPointer;
        string vestingType;
        uint256 version;
        
    }
    address[] public vestingAddresses;
    mapping (address => VestingStruct) public addressToVesting;
    
    event VestingContractFunded(address beneficiary, address tokenAddress, uint256 amount);
    event LockedAmountDecreased(uint256 amount);
    event LockedAmountIncreased(uint256 amount);
    event TokensReceivedSinceLastCheck(uint256 amount);

    
    function vestingExists(address _vestingAddress) public view returns(bool exists){
        if(vestingAddresses.length == 0) {return false;}
        return (vestingAddresses[addressToVesting[_vestingAddress].arrayPointer] == _vestingAddress);
    }
    
    function storeNewVesting(address _vestingAddress, string _vestingType, uint256 _version) public onlyOwner returns(uint256 vestingsLength) {
        require(!vestingExists(_vestingAddress));
        addressToVesting[_vestingAddress].version = _version;
        addressToVesting[_vestingAddress].vestingType = _vestingType ;
        addressToVesting[_vestingAddress].arrayPointer = vestingAddresses.push(_vestingAddress) - 1;
        return vestingAddresses.length;
    }

    function deleteVestingFromStorage(address _vestingAddress) public onlyOwner returns(uint256 vestingsLength) {
        require(vestingExists(_vestingAddress));
        uint256 indexToDelete = addressToVesting[_vestingAddress].arrayPointer;
        address keyToMove = vestingAddresses[vestingAddresses.length - 1];
        vestingAddresses[indexToDelete] = keyToMove;
        addressToVesting[keyToMove].arrayPointer = indexToDelete;
        vestingAddresses.length--;
        return vestingAddresses.length;
    }
    
    function createNewVesting(
        
        address _beneficiary,
        uint256 _startTime, 
        uint256 _tickDuration, 
        uint256 _amountPerTick,
        string _vestingType,
        uint256 _version,
        bool _revocable
        ) 
        
        public onlyOwner returns(address){
            TokenVestingContract newVesting = new TokenVestingContract(   
                _beneficiary,
                tokenAddress,
                _startTime, 
                _tickDuration, 
                _amountPerTick,
                _version,
                _revocable
                );
           
        storeNewVesting(newVesting, _vestingType, _version);
        return newVesting;
    }
    
    
    function fundVesting(address _vestingContract, uint256 _amount) public onlyOwner {
        
        checkForReceivedTokens();
        
        require((internalBalance >= _amount) && (getTokenBalance() >= _amount));
        
        require(vestingExists(_vestingContract)); 
        internalBalance = internalBalance.sub(_amount);
        ERC20TokenInterface(tokenAddress).transfer(_vestingContract, _amount);
        TokenVestingInterface(_vestingContract).updateBalanceOnFunding(_amount);
        emit VestingContractFunded(_vestingContract, tokenAddress, _amount);
    }
    
    function getTokenBalance() public constant returns(uint256) {
        return ERC20TokenInterface(tokenAddress).balanceOf(address(this));
    }
    
    function revokeVesting(address _vestingContract, string _reason) public onlyOwner{
        TokenVestingInterface subVestingContract = TokenVestingInterface(_vestingContract);
        subVestingContract.revoke(_reason);
        deleteVestingFromStorage(_vestingContract);
    }
    
    function addInternalBalance(uint256 _amount) external {
        require(vestingExists(msg.sender));
        internalBalance = internalBalance.add(_amount);
    }
    
    function addLockedAmount(uint256 _amount) external {
        require(vestingExists(msg.sender));
        amountLockedInVestings = amountLockedInVestings.add(_amount);
        emit LockedAmountIncreased(_amount);
    }
    
    function substractLockedAmount(uint256 _amount) external {
        require(vestingExists(msg.sender));
        amountLockedInVestings = amountLockedInVestings.sub(_amount);
        emit LockedAmountDecreased(_amount);
    }
    
    function checkForReceivedTokens() public{
        if (getTokenBalance() != internalBalance){
            uint256 receivedFunds = getTokenBalance().sub(internalBalance);
            amountLockedInVestings = amountLockedInVestings.add(receivedFunds);
            internalBalance = getTokenBalance();
            emit TokensReceivedSinceLastCheck(receivedFunds);
        }else{
        emit TokensReceivedSinceLastCheck(0);
        }
    }
    function salvageOtherTokensFromContract(address _tokenAddress, address _contractAddress, address _to, uint _amount) public onlyOwner {
        require(_tokenAddress != tokenAddress);
        if (_contractAddress == address(this)){
            ERC20TokenInterface(_tokenAddress).transfer(_to, _amount);
        }
        if (vestingExists(_contractAddress)){
            TokenVestingInterface(_contractAddress).salvageOtherTokensFromContract(_tokenAddress, _to, _amount);
        }
    }
    
    function killContract() public onlyOwner{
        require(vestingAddresses.length == 0);
        ERC20TokenInterface(tokenAddress).transfer(owner, getTokenBalance());
        selfdestruct(owner);
    }
    function setWithdrawalAddress(address _vestingContract, address _beneficiary) public onlyOwner{
        require(vestingExists(_vestingContract));
        TokenVestingInterface(_vestingContract).setWithdrawalAddress(_beneficiary);
    }
}


contract EligmaSupplyContract  is Owned {
    address public tokenAddress;
    address public vestingMasterAddress;
    
    function EligmaSupplyContract(address _tokenAddress, address _vestingMasterAddress) public onlyOwner{
        tokenAddress = _tokenAddress;
        vestingMasterAddress = _vestingMasterAddress;
    }
    
    function totalSupply() view public returns(uint256) {
        return ERC20TokenInterface(tokenAddress).totalSupply();
    }
    
    function lockedSupply() view public returns(uint256) {
        return VestingMasterInterface(vestingMasterAddress).amountLockedInVestings();
    }
    
    function avaliableSupply() view public returns(uint256) {
        return ERC20TokenInterface(tokenAddress).totalSupply() - VestingMasterInterface(vestingMasterAddress).amountLockedInVestings();
    }
    
    function setTokenAddress(address _tokenAddress) onlyOwner public {
        tokenAddress = _tokenAddress;
    }
    
    function setVestingMasterAddress(address _vestingMasterAddress) onlyOwner public {
        vestingMasterAddress = _vestingMasterAddress;
    }
}