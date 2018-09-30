pragma solidity ^0.4.13;

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
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract ResultStorage is Owned, IResultStorage {

    event ResultAssigned(bytes32 indexed _predictionId, uint8 _outcomeId);

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
            onlyOwner
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