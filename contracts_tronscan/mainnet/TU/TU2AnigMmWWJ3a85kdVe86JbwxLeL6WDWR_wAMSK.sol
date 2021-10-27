//SourceUnit: WAMSK.sol

pragma solidity ^0.5.8;

/**
 * @title TRC20 Interface
 * @author @VibraVid @lapits
 */
interface ITRC20 {
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Ownable
 * @dev Set & transfer owner
 */
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    /**
     * @dev Set contract deployer as owner
     */
    constructor() public {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnershipTransferred(owner, msg.sender);
    }
    
    // modifier to check if caller is owner
    modifier onlyOwner {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    /**
     * @dev Transfer Ownership
     * @param _newOwner address of new owner
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
}

/**
 * @title Wrapped NoleWater (wAMSK)
 * @author @VibraVid @LapitsTechnologies
 * @dev Implements a TRC20 wrapped token
 */
contract wAMSK is ITRC20, Ownable {
    using SafeMath for uint256;

    string public name = "Wrapped NoleWater"; // Token Name
    string public symbol = "wAMSK"; // Token Symbol
    uint256 public decimals = 0; // Token decimals
    uint256 internal _totalSupply;
    trcToken internal amskTokenId = trcToken(1001699); // TRC10 token ID (which is to be wrapped/unwrapped)

    mapping(address => uint256) private  _balanceOf;
    mapping(address => mapping(address => uint)) private  _allowance;
    
    event  Wrap(address indexed account, uint256 value);
    event  Unwrap(address indexed account, uint256 value);

    function() external payable {
        wrap();
    }

    /**
     * @dev Function to wrap AMSK
     */
    function wrap() public payable {
        require(msg.tokenid == amskTokenId, "Wrap only AMSK[1001699] tokens");
        _mint(msg.sender, msg.tokenvalue);
        emit Transfer(address(0x00), msg.sender, msg.tokenvalue);
        emit Wrap(msg.sender, msg.tokenvalue);
    }

    /**
     * @dev Function to unwrap wAMSK
     * @param _amount of wAMSK token to unwrap.
     */
    function unwrap(uint256 _amount) public {
        require(_balanceOf[msg.sender] >= _amount, "Not enough wAMSK balance");
        require(_totalSupply >= _amount, "Not enough wAMSK totalSupply");
        _burn(msg.sender, _amount);
        msg.sender.transferToken(_amount, amskTokenId);
        emit Transfer(msg.sender, address(0x00), _amount);
        emit Unwrap(msg.sender, _amount);
    }

    /**
     * @dev Burn tokens
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public onlyOwner returns (bool) {
        _burn(msg.sender, _value);
        return true;
    }

    /**
     * @dev Internal function
     * @param _account The account whose tokens will be burnt.
     * @param _amount The amount that will be burnt.
     */
    function _burn(address _account, uint256 _amount) internal {
        require(_account != address(0));
        require(_balanceOf[_account] >= _amount, "Insufficient balance to burn");

        _totalSupply = _totalSupply.sub(_amount);
        _balanceOf[_account] = _balanceOf[_account].sub(_amount);
        emit Transfer(_account, address(0), _amount);
    }

    /**
     * @dev Internal function
     * @param _account account to mint the tokens.
     * @param _amount The amount that will be minted.
     */
    function _mint(address _account, uint256 _amount) internal {
        require(_account != address(0));

        _totalSupply = _totalSupply.add(_amount);
        _balanceOf[_account] = _balanceOf[_account].add(_amount);
        emit Transfer(address(0), _account, _amount);
    }
    
    /**
     * @dev _totalSupply
     */
    function totalSupply() public view returns (uint256){
        return _totalSupply;
    }
    
    /**
     * @dev Check balance
     * @param _account to check balance for
     */
    function balanceOf(address _account) public view returns (uint256){
        return _balanceOf[_account];
    }

    /**
     * @dev Return the token a spender can 
     * @param _owner the amount of money to burn
     * @param _spender to be burned from
     */
    function allowance(address _owner, address _spender) public view returns (uint256){
        return _allowance[_owner][_spender];
    }

    /**
     * @dev Approve spend limit
     * @param _spender to check balance for
     * @param _amount spending limit
     */
    function approve(address _spender, uint256 _amount) public returns (bool) {
        _allowance[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    /**
     * @dev Transfer token
     * @param _to receiver address
     * @param _amount token value to send
     */
    function transfer(address _to, uint256 _amount) public returns (bool) {
        return transferFrom(msg.sender, _to, _amount);
    }

    /**
     * @dev Transfer token from address
     * @param _from sender address
     * @param _to receiver address
     * @param _amount token value to send
     */
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool) {
        require(_balanceOf[_from] >= _amount, "Insufficient balance");
        if (_from != msg.sender && _allowance[_from][msg.sender] != uint256(- 1)) {
            require(_allowance[_from][msg.sender] >= _amount, "Amount exceeds the allowed limit");
            _allowance[_from][msg.sender] = _allowance[_from][msg.sender].sub(_amount);
        }
        
        _balanceOf[_from] = _balanceOf[_from].sub(_amount);
        _balanceOf[_to] = _balanceOf[_to].add(_amount);

        emit Transfer(_from, _to, _amount);
        return true;
    }

    /**
     * @dev Withdraw TRX sent to the contract
     * @param _recipient receiver address
     */
    function withdrawTRX(address payable _recipient) external onlyOwner {
        require(_recipient != address(0), "Cannot withdraw the TRX balance to the zero address");
        require(address(this).balance > 0, "The TRX balance must be greater than 0");

        _recipient.transfer(address(this).balance);
    }

    /**
     * @dev Withdraw TRC20 tokens sent to the contract (NOT wAMSK)
     * @param _token token contract address
     * @param _recipient receiver address
     */
    function withdrawToken(address _token, address payable _recipient) external onlyOwner returns(bool) {
        require(_recipient != address(0), "Cannot withdraw the tokens to the zero address");
        require(_token != address(this), "Cannot withdraw the wAMSK balance");

        uint256 tokenBalance = ITRC20(_token).balanceOf(address(this));
        return ITRC20(_token).transfer(_recipient, tokenBalance);
    }
}