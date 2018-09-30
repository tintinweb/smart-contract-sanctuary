pragma solidity ^0.4.23;

/***************************************************
Externally copied contracts and interfaces.
Source: https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/token/ERC20/ERC20Basic.sol
***************************************************/


/**** ERC20Basic.sol ****/
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
/**** ERC20Basic.sol ****/

/**** ERC20.sol ****/
/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender)
    public view returns (uint256);

    function transferFrom(address from, address to, uint256 value)
    public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}
/**** ERC20.sol ****/

/**** SafeMath.sol ****/
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
/**** SafeMath.sol ****/

/**** Ownable.sol ****/
/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;


    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );


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
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }


}
/**** Ownable.sol ****/




/***************************************************
 * Individually implemented code
 ***************************************************/

/**
 * @title UChain ERC20 Token
 */
contract UChainToken is ERC20 {
    using SafeMath for uint256;

    /* Constant variables of the token */
    string constant public name = &#39;UChain Token&#39;;
    string constant public symbol = &#39;UCN&#39;;
    uint8 constant public decimals = 18;
    uint256 constant public decimalFactor = 10 ** uint(decimals);

    uint256 public totalSupply;

    /* minting related state */
    bool public isMintingFinished = false;
    mapping(address => bool) public admins;

    /* vesting related state */
    struct Vesting {
        uint256 vestedUntil;
        uint256 vestedAmount;
    }

    mapping(address => Vesting) public vestingEntries;

    /* ERC20 related state */
    bool public isTransferEnabled = false;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowances;


    /* custom events */
    event MintFinished();
    event Mint(address indexed _beneficiary, uint256 _value);
    event MintVested(address indexed _beneficiary, uint256 _value);
    event AdminRemoved(address indexed _adminAddress);
    event AdminAdded(address indexed _adminAddress);

    /**
     * @dev contstructor.
     */
    constructor() public {
        admins[msg.sender] = true;
    }

    /***************************************************
     * View only methods
     ***************************************************/

    /**
      * @dev specified in the ERC20 interface, returns the total token supply. Burned tokens are not counted.
      */
    function totalSupply() public view returns (uint256) {
        return totalSupply - balances[address(0)];
    }

    /**
      * @dev Get the token balance for token owner
      * @param _tokenOwner The address of you want to query the balance for
      */
    function balanceOf(address _tokenOwner) public view returns (uint256) {
        return balances[_tokenOwner];
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _tokenOwner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address _tokenOwner, address _spender) public view returns (uint256) {
        return allowances[_tokenOwner][_spender];
    }

    /***************************************************
     * Admin permission related methods
     ***************************************************/

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyAdmin() {
        require(admins[msg.sender]);
        _;
    }

    /**
     * @dev remove admin rights
     * @param _adminAddress address to remove from admin list
     */
    function removeAdmin(address _adminAddress) public onlyAdmin {
        delete admins[_adminAddress];
        emit AdminRemoved(_adminAddress);
    }

    /**
     * @dev give admin rights to address
     * @param _adminAddress address to add to admin list
     */
    function addAdmin(address _adminAddress) public onlyAdmin {
        admins[_adminAddress] = true;
        emit AdminAdded(_adminAddress);
    }

    /**
     * @dev tells you whether a particular address has admin privileges or not
     * @param _adminAddress address to check whether it has admin privileges
     */
    function isAdmin(address _adminAddress) public view returns (bool) {
        return admins[_adminAddress];
    }

    /***************************************************
     * Minting related methods
     ***************************************************/

    function mint(address _beneficiary, uint256 _value) public onlyAdmin returns (bool)  {
        require(!isMintingFinished);
        totalSupply = totalSupply.add(_value);
        balances[_beneficiary] = balances[_beneficiary].add(_value);
        emit Mint(_beneficiary, _value);
        emit Transfer(address(0), _beneficiary, _value);
        return true;
    }

    function bulkMint(address[] _beneficiaries, uint256[] _values) public onlyAdmin returns (bool)  {
        require(_beneficiaries.length == _values.length);
        for (uint256 i = 0; i < _beneficiaries.length; i = i.add(1)) {
            require(mint(_beneficiaries[i], _values[i]));
        }
        return true;
    }

    function mintVested(uint256 _vestedUntil, address _beneficiary, uint256 _value) public onlyAdmin returns (bool) {
        require(mint(_beneficiary, _value));
        vestingEntries[_beneficiary] = Vesting(_vestedUntil, _value);
        emit MintVested(_beneficiary, _value);
        return true;
    }

    function bulkMintVested(uint256 _vestedUntil, address[] _beneficiaries, uint256[] _values) public onlyAdmin returns (bool)  {
        require(_beneficiaries.length == _values.length);
        for (uint256 i = 0; i < _beneficiaries.length; i = i.add(1)) {
            require(mintVested(_vestedUntil, _beneficiaries[i], _values[i]));
        }
        return true;
    }

    /**
     * @dev finishes the minting. After this call no more tokens can be minted.
     */
    function finishMinting() public onlyAdmin {
        isMintingFinished = true;
    }

    /***************************************************
     * Vesting related methods
     ***************************************************/
    function getNonVestedBalanceOf(address _tokenOwner) public view returns (uint256) {
        if (block.timestamp < vestingEntries[_tokenOwner].vestedUntil) {
            return balances[_tokenOwner].sub(vestingEntries[_tokenOwner].vestedAmount);
        } else {
            return balances[_tokenOwner];
        }
    }

    /***************************************************
     * Basic Token operations
     * Source: https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/token/ERC20/BasicToken.sol
     ***************************************************/

    /**
     * @dev Transfer token for a specified address
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(isTransferEnabled);
        require(_to != address(0));
        require(_value <= getNonVestedBalanceOf(msg.sender));

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        emit Transfer(msg.sender, _to, _value);
        return true;
    }


    /***************************************************
     * Standard Token operations
     * Source: https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/token/ERC20/StandardToken.sol
     ***************************************************/

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(isTransferEnabled);
        require(_to != address(0));
        require(_value <= getNonVestedBalanceOf(_from));
        require(_value <= allowances[_from][msg.sender]);

        allowances[_from][msg.sender] = allowances[_from][msg.sender].sub(_value);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);

        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     *
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev sets the right to transfer tokens or not.
     * @param _isTransferEnabled the new state to set
     */
    function setIsTransferEnabled(bool _isTransferEnabled) public onlyAdmin {
        isTransferEnabled = _isTransferEnabled;
    }
}