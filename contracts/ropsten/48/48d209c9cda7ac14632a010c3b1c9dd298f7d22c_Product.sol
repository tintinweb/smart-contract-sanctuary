pragma solidity ^0.4.13;

interface IProduct {
    function addPolicy(bytes32 _id, uint32 _utcStart, uint32 _utcEnd, uint _calculatedPayout, string _properties) public;
    function claim(bytes32 _policyId, string _properties) public;
}

interface IERC20 {
  function transfer(address _to, uint256 _amount) external returns (bool success);
  function transferFrom(address _from, address _to, uint256 _amount) external returns (bool success);
  function balanceOf(address _owner) constant external returns (uint256 balance);
  function approve(address _spender, uint256 _amount) external returns (bool success);
  function allowance(address _owner, address _spender) external constant returns (uint256 remaining);
  function approveAndCall(address _spender, uint256 _amount, bytes _extraData) external returns (bool success);
  function totalSupply() external constant returns (uint);
}

library BytesHelper {
    function bytesToBytes32(bytes memory source) pure internal returns (bytes32 result) {
        assembly {
            result := mload(add(source, 32))
        }
    }
}

contract Owned {
    address public owner;
    address public executor;
    address public newOwner;
  
    event OwnershipTransferred(address indexed _from, address indexed _to);
    event ExecutorTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
        executor = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "User is not owner");
        _;
    }

    modifier onlyAllowed {
        require(msg.sender == owner || msg.sender == executor, "Not allowed");
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function transferExecutorOwnership(address _newExecutor) public onlyOwner {
        emit ExecutorTransferred(executor, _newExecutor);
        executor = _newExecutor;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract Product is Owned, IProduct {
    using SafeMath for uint;
    using BytesHelper for bytes;

    event PolicyAdd(bytes32 indexed _policyId);
    event Claim(bytes32 indexed _policyId, uint _amount);    
    event Cancel(bytes32 indexed _policyId, uint _amount);    
    event PremiumCalculatorChange(address _old, address _new);
    event PaymentReceived(bytes32 indexed _policyId, uint _amount);
    event PolicyUpdatedManualy(bytes32 indexed _policyId);

    // TODO: limit policies or payouts amoun or others limits in code not contracts.    
    struct Policy {
        address owner;
        uint32 utcStart;
        uint32 utcEnd;
        uint32 utcPayoutDate;
        bool isCanceled;
        uint premium;
        uint calculatedPayout;
        string properties;
        // claim
        uint payout;
        string claimProperties;
    }
    
    address public token;
    address public premiumCalculator;
    uint public utcProductStartDate;
    uint public utcProductEndDate;

    bool public paused = true;
    
    uint public policiesCount;
    uint public policiesTotalCalculatedPayouts;
    uint public policiesPayoutsCount;
    uint public policiesTotalPayouts;
        
    mapping(bytes32 => Policy) public policies;

    modifier notPaused() {
        require(paused == false, "Contract is paused");
        _;
    }

    modifier senderIsToken() {
        require(msg.sender == address(token));
        _;
    }

     modifier policyValidForPayout(bytes32 _policyId) {
        require(policies[_policyId].owner != address(0), "Owner is not valid");       
        require(policies[_policyId].payout == 0, "Payout already done");
        require(policies[_policyId].isCanceled == false, "Policy already canceled");
        _;
    }
   
    function initialize(address _premiumCalculator, address _token, uint _utcProductStartDate, uint _utcProductEndDate) external onlyOwner {
        premiumCalculator = _premiumCalculator;
        token = _token;
        utcProductStartDate = _utcProductStartDate; 
        utcProductEndDate = _utcProductEndDate;
        paused = false;
    }

    function addPolicy(bytes32 _id, uint32 _utcStart, uint32 _utcEnd, uint _calculatedPayout, string _properties) 
            public 
            onlyAllowed 
            notPaused {
        require(policies[_id].premium > 0, "Policy is not payed");
        require(policies[_id].utcStart == 0, "Policy is already set");
        require(policies[_id].isCanceled == false, "Policy is already canceled");

        policies[_id].utcStart = _utcStart;
        policies[_id].utcEnd = _utcEnd;
        policies[_id].calculatedPayout = _calculatedPayout;
        policies[_id].properties = _properties;

        policiesCount++;
        policiesTotalCalculatedPayouts = policiesTotalCalculatedPayouts.add(_calculatedPayout);

        emit PolicyAdd(_id);
    }

    /// Called by token contract after Approval: this.TokenInstance.methods.approveAndCall()
    function receiveApproval(address _from, uint _amountOfTokens, address _token, bytes _data) 
            external 
            senderIsToken
            notPaused {
        require(_amountOfTokens > 0, "amount should be > 0");
        require(_from != address(0), "not valid from");

        bytes32 policyId = _data.bytesToBytes32();

        require(policies[policyId].premium == 0, "policy is paid and laready exist");

        // Transfer tokens from sender to this contract
        require(IERC20(token).transferFrom(_from, address(this), _amountOfTokens), "Tokens transfer failed.");
   
        policies[policyId].premium = _amountOfTokens;
        policies[policyId].owner = _from;

        emit PaymentReceived(policyId, _amountOfTokens);
    }
          
    function claim(bytes32 _policyId, string _properties) public 
            onlyAllowed 
            notPaused
            policyValidForPayout(_policyId) { 
      
        require(IERC20(token).balanceOf(this) >= policies[_policyId].calculatedPayout, "Contract balance is to low");

        policies[_policyId].utcPayoutDate = uint32(now);
        policies[_policyId].payout = policies[_policyId].calculatedPayout;
        policies[_policyId].claimProperties = _properties;

        policiesPayoutsCount++;
        policiesTotalPayouts = policiesTotalPayouts.add(policies[_policyId].payout);

        assert(IERC20(token).transfer(policies[_policyId].owner, policies[_policyId].payout));

        emit Claim(_policyId, policies[_policyId].payout);
    }

    function cancel(bytes32 _policyId) public 
            onlyAllowed 
            notPaused
            policyValidForPayout(_policyId) {
                
        policies[_policyId].isCanceled = true;
       
        emit Cancel(_policyId, policies[_policyId].payout);
    }

    function updatePremiumCalculator(address _newCalculator) public onlyOwner {
        emit PremiumCalculatorChange(premiumCalculator, _newCalculator);
        premiumCalculator = _newCalculator;
    }      

    //////////
    // Safety Methods
    //////////
    function () public payable {
        require(false);
    }

    function updatePolicy(
        bytes32 _policyId,
        address _owner,
        uint32 _utcStart,
        uint32 _utcEnd,
        uint _premium,
        uint _calculatedPayout,
        bool _isCanceled) 
            external 
            onlyOwner {
        
        policies[_policyId].owner = _owner;
        policies[_policyId].utcStart = _utcStart;
        policies[_policyId].utcEnd = _utcEnd;
        policies[_policyId].premium = _premium;
        policies[_policyId].calculatedPayout = _calculatedPayout;
        policies[_policyId].isCanceled = _isCanceled;

        emit PolicyUpdatedManualy(_policyId);
    }

    function updatePolicy2(
        bytes32 _policyId,
        string _properties,
        uint _payout,
        uint32 _utcPayoutDate,
        string _claimProperties) 
            external 
            onlyOwner {
        
        policies[_policyId].properties = _properties;
        policies[_policyId].payout = _payout;
        policies[_policyId].utcPayoutDate = _utcPayoutDate;
        policies[_policyId].claimProperties = _claimProperties;
  
        emit PolicyUpdatedManualy(_policyId);
    }


   function tokenBalance() public view returns (uint) {
         return IERC20(token).balanceOf(this);
    }

    function withdrawETH() external onlyOwner {
        owner.transfer(address(this).balance);
    }

    function withdrawTokens(uint _amount, address _token) external onlyOwner {
        IERC20(_token).transfer(owner, _amount);
    }

    function pause(bool _paused) external onlyOwner {
        paused = _paused;
    }
}

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}