pragma solidity 0.4.24;

// File: contracts/zeppelin/erc20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: contracts/zeppelin/erc20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/zeppelin/erc20/ERC20Interface.sol

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// File: contracts/zeppelin/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

// File: contracts/zeppelin/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of &quot;user permissions&quot;.
 */
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
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

// File: contracts/Custodian.sol

/**
 * @title Custodian Contract for P2P Insurance
 * @author PolicypalNetwork
 * @notice Handles the transactions for P2P insurance
 */

pragma solidity 0.4.24;






// General helpers.
library Helpers {
    // returns whether `array` contains `value`.
    function addressArrayContains(address[] array, address value) internal pure returns (bool) {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == value) {
                return true;
            }
        }
        return false;
    }

    // returns the digits of `inputValue` as a string.
    // example: `uintToString(12345678)` returns `&quot;12345678&quot;`
    function uintToString(uint256 inputValue) internal pure returns (string) {
        // figure out the length of the resulting string
        uint256 length = 0;
        uint256 currentValue = inputValue;
        do {
            length++;
            currentValue /= 10;
        } while (currentValue != 0);

        // allocate enough memory
        bytes memory result = new bytes(length);

        // construct the string backwards
        uint256 i = length - 1;
        currentValue = inputValue;
        do {
            result[i--] = byte(48 + currentValue % 10);
            currentValue /= 10;
        } while (currentValue != 0);
        return string(result);
    }
}

// Helpers for message signing.
// `internal` so they get compiled into contracts using them.
library MessageSigning {
    function hashMessage(bytes message) internal pure returns (bytes32) {
        bytes memory prefix = &quot;\x19Ethereum Signed Message:\n&quot;;
        return keccak256(abi.encodePacked(prefix, Helpers.uintToString(message.length), message));
    }
}

library Message {
    // layout of message :: bytes:
    // offset  0: 20 bytes :: policy holder adress
    // offset 20: 20 bytes :: recipient address
    // offset 40: 32 bytes :: payout amount
    // offset 72: 32 bytes :: transaction hash
    
    function getPolicyHolder(bytes message) internal pure returns (address) {
        address policyHolder;
        assembly {
            policyHolder := mload(add(message, 20))
        }
        return policyHolder;
    }

    function getRecipient(bytes message) internal pure returns (address) {
        address recipient;
        assembly {
            recipient := mload(add(message, 40))
        }
        return recipient;
    }

    function getValue(bytes message) internal pure returns (uint256) {
        uint256 value;
        assembly {
            value := mload(add(message, 72))
        }
        return value;
    }

    function getTransactionHash(bytes message) internal pure returns (bytes32) {
        bytes32 hash;
        assembly {
            hash := mload(add(message, 104))
        }
        return hash;
    }
}

contract Custodian is Ownable {
    using SafeMath for uint256;

    // number of authorities signatures required to withdraw the money.
    // must be lesser than number of authorities.
    uint256 public requiredSignatures;
    uint256 public authorityCount;

    // used transaction hashes.
    mapping (bytes32 => bool) claims;
    mapping (address => uint256) claimStatus;

    ERC20Interface tokenInterface;

    // authorities State --
    // 1 - authorized
    // 2 - not authorized
    mapping(address => uint256) authorities;

    event TransactionSuccess(address indexed tokenOwner, uint256 indexed amount);
    event ClaimMade(address indexed policyOwner, address indexed claimer);
    event ClaimSuccess(address indexed policyHolder, address indexed recipient, uint256 indexed amount);
    event AuthorityAdded(address indexed authority);
    event AuthorityRemoved(address indexed authority);

    constructor(
        address _tokenContract,
        address _authority
    )
        public
    {
        tokenInterface = ERC20Interface(_tokenContract);
        authorities[_authority] = 1;
        authorityCount = 1;
        requiredSignatures = 1;
    }

    /**
     * @dev Modifier to check if a particular address is whitelisted
     */
    modifier onlyAuthority() {
        require(authorities[msg.sender] == 1 || msg.sender == owner);
        _;
    }

    /**
     * @dev Add Authority
     */
    function AddAuthority(address _addr) external
        onlyOwner
    {
        authorities[_addr] = 1;
        authorityCount += 1;

        emit AuthorityAdded(_addr);
    }

    /**
     * @dev Remove Authority
     */
    function RemoveAuthority(address _addr) external
        onlyOwner
    {
        require(requiredSignatures <= authorityCount-1);
        authorities[_addr] = 2;
        authorityCount -= 1;

        emit AuthorityRemoved(_addr);
    }
    
    /**
     * @dev Is Authority
     */
    function IsAuthority(address _addr) public view
        returns (bool)
    {
        return(authorities[_addr] == 1);
    }
    
    /**
     * @dev Is Claimed
     */
    function IsClaimed(bytes32 _hash) external view
        returns (bool)
    {
        return(claims[_hash]);
    }

    /**
     * @dev Claim Status
     */
    function ClaimedStatus(address _addr) external view
        returns (uint256)
    {
        return(claimStatus[_addr]);
    }
    
    /**
     * @dev Update Required Signatures
     */
    function UpdateRequiredSignatures(uint256 _newRequired) external
        onlyOwner
    {
        require(_newRequired <= authorityCount);
        requiredSignatures = _newRequired;
    }

    /**
     * @dev Make Transaction
     * make transaction using transferFrom
     */
    function MakeTransaction(address _tokenOwner, uint256 _amount, uint256 _rebate) external
        onlyAuthority
    {
        // check that token owner address has valid amount
        require(tokenInterface.balanceOf(_tokenOwner) >= _amount);
        require(tokenInterface.allowance(_tokenOwner, address(this)) >= _amount);

        uint256 amountPayable = _amount;
        
        // if there is rebate
        if (_rebate > 0) {
            uint256 rebate = (_rebate.mul(amountPayable)).div(100);
            amountPayable = amountPayable.sub(rebate);
        }
        
        // transfer amount
        assert(tokenInterface.transferFrom(_tokenOwner, address(this), amountPayable));
        
        emit TransactionSuccess(_tokenOwner, amountPayable);
    }

    /**
     * @dev Make Claim
     * policy holder submits a claim
     */
    function MakeClaim(address _addr) external
    {
        // claim is not pending (can claim again if rejected before)
        // allowing approved claim to resubmit in POC version
        // require(claimStatus[_addr] != 1);

        // 0 - default
        // 1 - pending
        // 2 - approved
        claimStatus[_addr] = 1;
        
        emit ClaimMade(_addr, msg.sender);
    }

    /**
     * @dev Claim Payout
     * payout claim after success
     * only the `authorities` can create these signatures.
     */
    function ClaimPayout(uint8[] _vs, bytes32[] _rs, bytes32[] _ss, bytes _message) external 
        onlyAuthority
    {
        require(_message.length == 104);

        // check that at least `requiredSignatures` `authorities` have signed `message`
        require(hasEnoughValidSignatures(_message, _vs, _rs, _ss));

        address policyHolder = Message.getPolicyHolder(_message);
        address recipient = Message.getRecipient(_message);
        uint256 amount = Message.getValue(_message);
        bytes32 hash = Message.getTransactionHash(_message);

        require(recipient != address(this));
        require(recipient != address(0));
        require(amount > 0);
        require(amount <= tokenInterface.balanceOf(address(this)));

        // Block duplicated claims and reentry
        require(!claims[hash]);
        claims[hash] = true;

        claimStatus[policyHolder] = 2;
        
        tokenInterface.transfer(recipient, amount);

        emit ClaimSuccess(policyHolder, recipient, amount);
    }

    /**
     * @dev Has Enough Valid Signatures
     * returns whether signatures (whose components are in `vs`, `rs`, `ss`)
     * contain `requiredSignatures` distinct correct signatures
     * where signer is in `authority` that signed `message`
     */
    function hasEnoughValidSignatures(bytes message, uint8[] _vs, bytes32[] _rs, bytes32[] _ss) internal view returns (bool) {
        if (_vs.length < requiredSignatures) {
            return false;
        }

        bytes32 hash = MessageSigning.hashMessage(message);
        address[] memory encountered_addresses = new address[](requiredSignatures);

        for (uint256 i = 0; i < requiredSignatures; i++) {
            address recovered_address = ecrecover(hash, _vs[i], _rs[i], _ss[i]);
            // only signatures by addresses in `addresses` are allowed
            if (authorities[recovered_address] != 1) {
                return false;
            }

            // duplicate signatures are not allowed
            if (Helpers.addressArrayContains(encountered_addresses, recovered_address)) {
                return false;
            }

            encountered_addresses[i] = recovered_address;
        }

        return true;
    }

    /**
     * @dev Emergency Drain
     * in case something went wrong and token is stuck in contract
     */
    function emergencyDrain(ERC20 _anyToken) public
        onlyOwner
        returns(bool)
    {
        if (address(this).balance > 0) {
            owner.transfer(address(this).balance);
        }
        
        if (_anyToken != address(0x0)) {
            assert(_anyToken.transfer(owner, _anyToken.balanceOf(this)));
        }
        return true;
    }
}