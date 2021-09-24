/**
 *Submitted for verification at BscScan.com on 2021-09-23
*/

/**

WPSmartContracts.com

Blockhain Made Easy

https://wpsmartcontracts.com/

*/

pragma solidity ^0.5.7;

contract IRC20Vanilla {
    /* This is a slight change to the ERC20 base standard.
    function totalSupply() constant returns (uint256 supply);
    is replaced with:
    uint256 public totalSupply;
    This automatically creates a getter function for the totalSupply.
    This is moved to the base contract since public getter functions are not
    currently recognised as an implementation of the matching abstract
    function by the compiler.
    */
    /// total amount of tokens
    uint256 public totalSupply;

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) public view returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) public returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) public returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    // solhint-disable-next-line no-simple-event-func-name
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract ERC20Vanilla is IRC20Vanilla {

    uint256 constant private MAX_UINT256 = 2**256 - 1;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    /*
    NOTE:
    The following variables are OPTIONAL vanities. One does not have to include them.
    They allow one to customise the token contract & in no way influences the core functionality.
    Some wallets/interfaces might not even bother to look at this information.
    */
    string public name;                   //fancy name: eg Simon Bucks
    uint8 public decimals;                //How many decimals to show.
    string public symbol;                 //An identifier: eg SBX

    constructor(address _manager, uint256 _initialAmount, string memory _tokenName, uint8 _decimalUnits, string memory _tokenSymbol
    ) public {
        balances[_manager] = _initialAmount;               // Give the creator all initial tokens
        totalSupply = _initialAmount;                        // Update total supply
        name = _tokenName;                                   // Set the name for display purposes
        decimals = _decimalUnits;                            // Amount of decimals for display purposes
        symbol = _tokenSymbol;                               // Set the symbol for display purposes
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {
    
    int256 constant private INT256_MIN = -2**255;

    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Multiplies two signed integers, reverts on overflow.
    */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == INT256_MIN)); // This is the only case of overflow not detected by the check below

        int256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Integer division of two signed integers truncating the quotient, reverts on division by zero.
    */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0); // Solidity only automatically asserts when dividing by 0
        require(!(b == -1 && a == INT256_MIN)); // This is the only case of overflow

        int256 c = a / b;

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Subtracts two signed integers, reverts on overflow.
    */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Adds two signed integers, reverts on overflow.
    */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

/**
 *
 * WPSmartContracts / Campaign Contract
 *
 * Contribution campaigns including the ability to approve the transfer of funds per request
 *
 */

contract CampaignMango {

    using SafeMath for uint256;
    
    // Request definition
    struct Request {
        string description;
        uint256 value;
        address payable recipient;
        bool complete;
        uint256 approvalCount;
        mapping(address => bool) approvals;
    }
    
    Request[] public requests; // requests instance
    address public manager; // the owner
    uint256 minimumContribution; // the... minimum contribution

    /*
        a factor to calculate minimum number of approvers by 100/factor
        the factor values are 2 and 10, factors that makes sense:
            2: meaning that the number or approvers required will be 50%
            3: 33.3%
            4: 25%
            5: 20%
            10: 10%
    */
    uint8 approversFactor;
    
    mapping(address => bool) public approvers;
    uint256 public approversCount;

    // function to add validation of the manager to run any function
    modifier restricted() {
        require(msg.sender == manager);
        _;
    }

    // Constructor function to create a Campaign
    constructor(address creator, uint256 minimum, uint8 factor) public {
        // validate factor number betweeb 2 and 10
        require(factor >= 2);
        require(factor <= 10);
        manager = creator;
        approversFactor = factor;
        minimumContribution = minimum;
    }
    
    // allows a contributions
    function contribute() public payable {
        // validate minimun contribution
        require(msg.value >= minimumContribution);

        // increment the number of approvers
        if (!approvers[msg.sender]) {
            approversCount++;
        }

        approvers[msg.sender] = true; // this maps this address with true

    }

    // create a request...
    function createRequest(string memory description, uint256 value, address payable recipient) public restricted {

        // create the struct, specifying memory as a holder
        Request memory newRequest = Request({
           description: description,
           value: value,
           recipient: recipient,
           complete: false,
           approvalCount: 0
        });

        requests.push(newRequest);

    }

    // contributors has the right to approve request
    function approveRequest(uint256 index) public {
        
        // this is to store in a local variable "request" the request[index] and avoid using it all the time
        Request storage request = requests[index];
        
        // if will require that the sender address is in the mapping of approvers
        require(approvers[msg.sender]);
        
        // it will require the contributor not to vote twice for the same request
        require(!request.approvals[msg.sender]);
        
        // add the voter to the approvals map
        request.approvals[msg.sender] = true;
        
        // increment the number of YES votes for the request
        request.approvalCount++;
        
    }

    // check if the sender already approved the request index
    function approved(uint256 index) public view returns (bool) {

        // if the msg.sender is an approver and also the msg.sender already approved the request “index” returns true
        if (approvers[msg.sender] && requests[index].approvals[msg.sender]) {
            return true;
        } else {
            return false;
        }

    }
    
    // send the money to the vendor if there are enough votes
    // only the creator is allowed to run this function
    function finalizeRequest(uint256 index) public restricted {
        
        // this is to store in a local variable "request" the request[index] and avoid using it all the time
        Request storage request = requests[index];

        // transfer the money if it has more than X% of approvals
        require(request.approvalCount >= approversCount.div(approversFactor));
        
        // we will require that the request in process is not completed yet
        require(!request.complete);
        
        // mark the request as completed
        request.complete = true;
        
        // transfer the money requested (value) from the contract to the vendor that created the request
        request.recipient.transfer(request.value);
        
    }

    // helper function to show basic info of a contract in the interface
    function getSummary() public view returns (
      uint256, uint256, uint256, uint256, address
      ) {
        return (
          minimumContribution,
          address(this).balance,
          requests.length,
          approversCount,
          manager
        );
    }

    function getRequestsCount() public view returns (uint256) {
        return requests.length;
    }

}