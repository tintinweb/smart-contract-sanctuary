// solium-disable linebreak-style
pragma solidity ^0.4.24;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {

    // Owner&#39;s address
    address public owner;

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
    * @param _newOwner The address to transfer ownership to.
    */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        emit OwnerChanged(owner, _newOwner);
        owner = _newOwner;
    }

    event OwnerChanged(address indexed previousOwner,address indexed newOwner);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
      // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
      // benefit is lost if &#39;b&#39; is also tested.
      // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

        return c;
    }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract AoraTgeCoin is IERC20, Ownable {
    using SafeMath for uint256;

    // Name of the token
    string public constant name = "Aora TGE Coin"; 
    
    // Symbol of the token
    string public constant symbol = "AORATGE";

    // Number of decimals for the token
    uint8 public constant decimals = 18;
    
    uint constant private _totalSupply = 650000000 ether;

    // Contract deployment block
    uint256 public deploymentBlock;

    // Address of the convertContract
    address public convertContract = address(0);

    // Address of the crowdsaleContract
    address public crowdsaleContract = address(0);

    // Token balances 
    mapping (address => uint) balances;

    /**
    * @dev Sets the convertContract address. 
    *   In the future, there will be a need to convert Aora TGE Coins to Aora Coins. 
    *   That will be done using the Convert contract which will be deployed in the future.
    *   Convert contract will do the functions of converting Aora TGE Coins to Aora Coins
    *   and enforcing vesting rules. 
    * @param _convert address of the convert contract.
    */
    function setConvertContract(address _convert) external onlyOwner {
        require(address(0) != address(_convert));
        convertContract = _convert;
        emit OnConvertContractSet(_convert);
    }

    /** 
    * @dev Sets the crowdsaleContract address.
    *   transfer function is modified in a way that only owner and crowdsale can call it.
    *   That is done because crowdsale will sell the tokens, and owner will be allowed
    *   to assign AORATGE to addresses in a way that matches the Aora business model.
    * @param _crowdsale address of the crowdsale contract.
    */
    function setCrowdsaleContract(address _crowdsale) external onlyOwner {
        require(address(0) != address(_crowdsale));
        crowdsaleContract = _crowdsale;
        emit OnCrowdsaleContractSet(_crowdsale);
    }

    /**
    * @dev only convert contract can call the modified function
    */
    modifier onlyConvert {
        require(msg.sender == convertContract);
        _;
    }

    constructor() public {
        balances[msg.sender] = _totalSupply;
        deploymentBlock = block.number;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address who) external view returns (uint256) {
        return balances[who];
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        require(false);
        return 0;
    }

    /**
    * @dev Transfer token for a specified address.
    *   Only callable by the owner or crowdsale contract, to prevent token trading.
    *   AORA will be a tradable token. AORATGE will be exchanged for AORA in 1-1 ratio. 
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(msg.sender == owner || msg.sender == crowdsaleContract);

        require(_value <= balances[msg.sender]);
        require(_to != address(0));

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        require(false);
        return false;
    }

    /**
    * @dev Transfer tokens from one address to another. 
    *   Only callable by the convert contract. Used in the process of converting 
    *   AORATGE to AORA. Will be called from convert contracts convert() function.
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to. 
    *   Only 0x0 address, because of a need to prevent token recycling. 
    * @param _value uint256 the amount of tokens to be transferred
    */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) onlyConvert public returns (bool) {
        require(_value <= balances[_from]);
        require(_to == address(0));

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
    * @dev Fallback function. Can&#39;t send ether to this contract. 
    */
    function () external payable {
        revert();
    }

    /**
    * @dev This method can be used by the owner to extract mistakenly sent tokens
    * or Ether sent to this contract.
    * @param _token address The address of the token contract that you want to
    * recover set to 0 in case you want to extract ether. It can&#39;t be ElpisToken.
    */
    function claimTokens(address _token) public onlyOwner {
        if (_token == address(0)) {
            owner.transfer(address(this).balance);
            return;
        }

        IERC20 tokenReference = IERC20(_token);
        uint balance = tokenReference.balanceOf(address(this));
        tokenReference.transfer(owner, balance);
        emit OnClaimTokens(_token, owner, balance);
    }

    /**
    * @param crowdsaleAddress crowdsale contract address
    */
    event OnCrowdsaleContractSet(address indexed crowdsaleAddress);

    /**
    * @param convertAddress crowdsale contract address
    */
    event OnConvertContractSet(address indexed convertAddress);

    /**
    * @param token claimed token
    * @param owner who owns the contract
    * @param amount amount of the claimed token
    */
    event OnClaimTokens(address indexed token, address indexed owner, uint256 amount);
}