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

interface IResultStorage {
    function getResult(bytes32 _predictionId) external returns (uint8);
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
        owner = _newOwner;
    }

    function transferSuperOwnership(address _newOwner) public onlySuperOwner {
        superOwner = _newOwner;
    }

    function transferExecutorOwnership(address _newExecutor) public onlyOwnerOrSuperOwner {
        emit OwnershipTransferred(executor, _newExecutor);
        executor = _newExecutor;
    }
}

contract ResultStorage is Owned, IResultStorage {

    event ResultAssigned(bytes32 indexed _predictionId, uint8 _outcomeId);
    event Withdraw(uint _amount);

    struct Result {     
        uint8 outcomeId;
        bool resolved; 
    }

    uint8 public constant version = 1;
    bool public paused;
    mapping(bytes32 => Result) public results;  

    modifier notPaused() {
        require(paused == false, "Contract is paused");
        _;
    }

    modifier resolved(bytes32 _predictionId) {
        require(results[_predictionId].resolved == true, "Prediction is not resolved");
        _;
    }
 
    function setOutcome (bytes32 _predictionId, uint8 _outcomeId)
            public 
            onlyAllowed
            notPaused {        
        
        results[_predictionId].outcomeId = _outcomeId;
        results[_predictionId].resolved = true;
        
        emit ResultAssigned(_predictionId, _outcomeId);
    }

    function getResult(bytes32 _predictionId) 
            public 
            view 
            resolved(_predictionId)
            returns (uint8) {
        return results[_predictionId].outcomeId;
    }

    //////////
    // Safety Methods
    //////////
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
}