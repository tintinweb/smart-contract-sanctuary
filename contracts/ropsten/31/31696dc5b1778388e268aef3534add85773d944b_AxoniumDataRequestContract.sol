pragma solidity ^0.4.23;

/**
* @dev Using ERC20 tokens transfer and balanceOf functions
*/
interface ERC20 {
    function transfer(address _to,uint256 _value) external returns(bool);
    function balanceOf(address _owner) external view returns(uint256 balance);
}

/**
 * @dev Math operations with safety checks that throw on error
 */
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

/**
 * @title AxoniumDataRequestContract
*/
contract AxoniumDataRequestContract {
    
    using SafeMath for uint256;

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
        require(ERC20(_tokenAddress).balanceOf(msg.sender) >= _totalTokens.mul(1 ether));
        
        owner = _owner;
        tokenAddress = _tokenAddress;
        dataRequestor = msg.sender;
        totalTokens = _totalTokens.mul(1 ether);
        tokensPerApproval = _tokensPerApproval.mul(1 ether);
        
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