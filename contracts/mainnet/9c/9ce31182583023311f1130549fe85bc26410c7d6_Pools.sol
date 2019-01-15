pragma solidity ^0.4.25;

interface IERC20 {
  function transfer(address _to, uint256 _amount) external returns (bool success);
  function transferFrom(address _from, address _to, uint256 _amount) external returns (bool success);
  function balanceOf(address _owner) constant external returns (uint256 balance);
  function approve(address _spender, uint256 _amount) external returns (bool success);
  function allowance(address _owner, address _spender) external constant returns (uint256 remaining);
  function approveAndCall(address _spender, uint256 _amount, bytes _extraData) external returns (bool success);
  function totalSupply() external constant returns (uint);
}

interface IPrizeCalculator {
    function calculatePrizeAmount(uint _predictionTotalTokens, uint _winOutputTotalTokens, uint _forecastTokens)
        pure
        external
        returns (uint);
}

contract Owned {
    address public owner;
    address public executor;
    address public superOwner;
  
    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        superOwner = msg.sender;
        owner = msg.sender;
        executor = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "User is not owner");
        _;
    }

    modifier onlySuperOwner {
        require(msg.sender == superOwner, "User is not owner");
        _;
    }

    modifier onlyOwnerOrSuperOwner {
        require(msg.sender == owner || msg.sender == superOwner, "User is not owner");
        _;
    }

    modifier onlyAllowed {
        require(msg.sender == owner || msg.sender == executor || msg.sender == superOwner, "Not allowed");
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwnerOrSuperOwner {
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    function transferSuperOwnership(address _newOwner) public onlySuperOwner {
        emit OwnershipTransferred(superOwner, _newOwner);
        superOwner = _newOwner;
    }

    function transferExecutorOwnership(address _newExecutor) public onlyOwnerOrSuperOwner {
        emit OwnershipTransferred(executor, _newExecutor);
        executor = _newExecutor;
    }
}

contract Pools is Owned {
    using SafeMath for uint;  

    event Initialize(address _token);
    event PoolAdded(bytes32 _id);
    event PoolDestinationUpdated(bytes32 _id);
    event ContributionAdded(bytes32 _poolId, bytes32 _contributionId);
    event PoolStatusChange(bytes32 _poolId, PoolStatus _oldStatus, PoolStatus _newStatus);
    event Paidout(bytes32 _poolId, bytes32 _contributionId);
    event Withdraw(uint _amount);
    
    struct Pool {  
        uint contributionStartUtc;
        uint contributionEndUtc;
        address destination;
        PoolStatus status;
        uint amountLimit;
        uint amountCollected;
        uint amountDistributing;
        uint paidout;
        address prizeCalculator;
        mapping(bytes32 => Contribution) contributions;
    }
    
    struct Contribution {  
        address owner;
        uint amount;
        uint paidout;
    }

    struct ContributionIndex {    
        bytes32 poolId;
        bytes32 contributionId;
    }
    
    enum PoolStatus {
        NotSet,       // 0
        Active,       // 1
        Distributing, // 2
        Funding,       // 3&#160;
        Paused,       // 4
        Canceled      // 5 
    }  

    uint8 public constant version = 1;
    bool public paused = true;
    address public token;
    uint public totalPools;
    
    mapping(bytes32 => Pool) public pools;
    mapping(address => ContributionIndex[]) public walletPools;

    modifier contractNotPaused() {
        require(paused == false, "Contract is paused");
        _;
    }

    modifier senderIsToken() {
        require(msg.sender == address(token));
        _;
    }

    function initialize(address _token) external onlyOwnerOrSuperOwner {
        token = _token;
        paused = false;
        emit Initialize(_token);
    }

    function addPool(bytes32 _id, 
            address _destination, 
            uint _contributionStartUtc, 
            uint _contributionEndUtc, 
            uint _amountLimit, 
            address _prizeCalculator) 
        external 
        onlyOwnerOrSuperOwner 
        contractNotPaused {
        
        if (pools[_id].status == PoolStatus.NotSet) { // do not increase if update
            totalPools++;
        } 
        
        pools[_id].contributionStartUtc = _contributionStartUtc;
        pools[_id].contributionEndUtc = _contributionEndUtc;
        pools[_id].destination = _destination;
        pools[_id].status = PoolStatus.Active;
        pools[_id].amountLimit = _amountLimit;
        pools[_id].prizeCalculator = _prizeCalculator;
        
        emit PoolAdded(_id);
    }

    function updateDestination(bytes32 _id, 
            address _destination) 
        external 
        onlyOwnerOrSuperOwner 
        contractNotPaused {

        pools[_id].destination = _destination;

        emit PoolDestinationUpdated(_id);
    }
    
    function setPoolStatus(bytes32 _poolId, PoolStatus _status) public onlyOwnerOrSuperOwner {
        require(pools[_poolId].status != PoolStatus.NotSet, "pool should be initialized");
        emit PoolStatusChange(_poolId,pools[_poolId].status, _status);
        pools[_poolId].status = _status;
    }
    
    // This method will be called for returning money when canceled or set everyone to take rewards by formula
    function setPoolAmountDistributing(bytes32 _poolId, PoolStatus _poolStatus, uint _amountDistributing) external onlyOwnerOrSuperOwner {
        setPoolStatus(_poolId, _poolStatus);
        pools[_poolId].amountDistributing = _amountDistributing;
    }

    /// Called by token contract after Approval: this.TokenInstance.methods.approveAndCall()
    // _data = poolId(32),contributionId(32)
    function receiveApproval(address _from, uint _amountOfTokens, address _token, bytes _data) 
            external 
            senderIsToken
            contractNotPaused {    
        require(_amountOfTokens > 0, "amount should be > 0");
        require(_from != address(0), "not valid from");
        require(_data.length == 64, "not valid _data length");
      
        bytes32 poolIdString = bytesToFixedBytes32(_data,0);
        bytes32 contributionIdString = bytesToFixedBytes32(_data,32);
        
        // Validate pool and Contribution
        require(pools[poolIdString].status == PoolStatus.Active, "Status should be active");
        require(pools[poolIdString].contributionStartUtc < now, "Contribution is not started");    
        require(pools[poolIdString].contributionEndUtc > now, "Contribution is ended"); 
        require(pools[poolIdString].contributions[contributionIdString].amount == 0, &#39;Contribution duplicated&#39;);
        require(pools[poolIdString].amountLimit == 0 ||
                pools[poolIdString].amountLimit >= pools[poolIdString].amountCollected.add(_amountOfTokens), "Contribution limit reached"); 
        
        // Transfer tokens from sender to this contract
        require(IERC20(_token).transferFrom(_from, address(this), _amountOfTokens), "Tokens transfer failed.");

        walletPools[_from].push(ContributionIndex(poolIdString, contributionIdString));
        pools[poolIdString].amountCollected = pools[poolIdString].amountCollected.add(_amountOfTokens); 
        pools[poolIdString].contributions[contributionIdString].owner = _from;
        pools[poolIdString].contributions[contributionIdString].amount = _amountOfTokens;

        emit ContributionAdded(poolIdString, contributionIdString);
    }
    
    function transferToDestination(bytes32 _poolId) external onlyOwnerOrSuperOwner {
        assert(IERC20(token).transfer(pools[_poolId].destination, pools[_poolId].amountCollected));
        setPoolStatus(_poolId,PoolStatus.Funding);
    }
    
    function payout(bytes32 _poolId, bytes32 _contributionId) public contractNotPaused {
        require(pools[_poolId].status == PoolStatus.Distributing, "Pool should be Distributing");
        require(pools[_poolId].amountDistributing > pools[_poolId].paidout, "Pool should be not empty");
        
        Contribution storage con = pools[_poolId].contributions[_contributionId];
        require(con.paidout == 0, "Contribution already paidout");
        
        IPrizeCalculator calculator = IPrizeCalculator(pools[_poolId].prizeCalculator);
    
        uint winAmount = calculator.calculatePrizeAmount(
            pools[_poolId].amountDistributing,
            pools[_poolId].amountCollected,  
            con.amount
        );
      
        assert(winAmount > 0);
        con.paidout = winAmount;
        pools[_poolId].paidout = pools[_poolId].paidout.add(winAmount);
        assert(IERC20(token).transfer(con.owner, winAmount));
        emit Paidout(_poolId, _contributionId);
    }

    function refund(bytes32 _poolId, bytes32 _contributionId) public contractNotPaused {
        require(pools[_poolId].status == PoolStatus.Canceled, "Pool should be canceled");
        require(pools[_poolId].amountDistributing > pools[_poolId].paidout, "Pool should be not empty");
        
        Contribution storage con = pools[_poolId].contributions[_contributionId];
        require(con.paidout == 0, "Contribution already paidout");        
        require(con.amount > 0, "Contribution not valid");   
        require(con.owner != address(0), "Owner not valid"); 

        con.paidout = con.amount;
        pools[_poolId].paidout = pools[_poolId].paidout.add(con.amount);
        assert(IERC20(token).transfer(con.owner, con.amount));

        emit Paidout(_poolId, _contributionId);
    }

    //////////
    // Views
    //////////
    function getContribution(bytes32 _poolId, bytes32 _contributionId) public view returns(address, uint, uint) {
        return (pools[_poolId].contributions[_contributionId].owner,
            pools[_poolId].contributions[_contributionId].amount,
            pools[_poolId].contributions[_contributionId].paidout);
    }

    // ////////
    // Safety Methods
    // ////////
    function () public payable {
        require(false);
    }

    function withdrawETH() external onlyOwnerOrSuperOwner {
        uint balance = address(this).balance;
        owner.transfer(balance);
        emit Withdraw(balance);
    }

    function withdrawTokens(uint _amount, address _token) external onlyOwnerOrSuperOwner {
        assert(IERC20(_token).transfer(owner, _amount));
        emit Withdraw(_amount);
    }

    function pause(bool _paused) external onlyOwnerOrSuperOwner {
        paused = _paused;
    }

    function bytesToFixedBytes32(bytes memory b, uint offset) internal pure returns (bytes32) {
        bytes32 out;

        for (uint i = 0; i < 32; i++) {
            out |= bytes32(b[offset + i] & 0xFF) >> (i * 8);
        }
        return out;
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