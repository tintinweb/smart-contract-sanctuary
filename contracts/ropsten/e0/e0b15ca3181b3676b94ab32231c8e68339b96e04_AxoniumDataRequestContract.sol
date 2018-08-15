pragma solidity ^0.4.23;

/**
* @dev Using ERC20 tokens transfer and balanceOf functions
*/
interface ERC20 {
    function transfer(address _to,uint256 _value) external returns(bool);
    function balanceOf(address _owner) external view returns(uint256 balance);
}

/**
 * @title AxoniumDataRequestContract
*/
contract AxoniumDataRequestContract {

    // Owner of the Axonium Data Request contract
    address public owner;
    
    address public dataRequestor;
    
    mapping(address => bool) public dataApprover;
    
    uint256 public totalTokens;
    
    uint256 public tokensPerApproval;
    
    uint256 public approverCounts;
    
    address public tokenAddress;
    
    event RaisedDataRequestContract(address dataRequestor, uint256 totalTokens);
    event ApprovedDataRequest(address dataApprover);
    
    // Functions with this modifier can only be executed by the owner
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    // Constructor
    // @notice Create AxoniumDataRequestContract
    constructor(address _owner, address _tokenAddress, uint256 _totalTokens, uint256 _tokensPerApproval) public {
        require(ERC20(_tokenAddress).balanceOf(msg.sender) >= _totalTokens);
        
        owner = _owner;
        tokenAddress = _tokenAddress;
        dataRequestor = msg.sender;
        totalTokens = _totalTokens;
        tokensPerApproval = _tokensPerApproval;
        
        //ERC20(_tokenAddress).transfer(_owner, _totalTokens);
        emit RaisedDataRequestContract(msg.sender, _totalTokens);
    }
    
    function acceptRequest(address _dataApprover) onlyOwner public {
        require(ERC20(tokenAddress).balanceOf(this) >= tokensPerApproval && !dataApprover[_dataApprover]);
        
        dataApprover[_dataApprover] = true;
        approverCounts += 1;
        ERC20(tokenAddress).transfer(_dataApprover, tokensPerApproval);
        emit ApprovedDataRequest(_dataApprover);
    }
}