/**
 * ┌───┐░░░┌┐░┌─┐┌─┐░░░░░┌┐░░░░░
 * │┌──┘░░░││░││└┘││░░░░┌┘└┐░░░░
 * │└──┬┐┌┬┤│░│┌┐┌┐├──┬─┼┐┌┼┐░┌┐
 * │┌──┤└┘├┤│░││││││┌┐│┌┘││││░││
 * │└──┼┐┌┤│└┐││││││└┘││░│└┤└─┘│
 * └───┘└┘└┴─┘└┘└┘└┴──┴┘░└─┴─┐┌┘
 * ░░░░░░░░░░░░░░░░░░░░░░░░┌─┘│░
 * ░░░░░░░░░░░░░░░░░░░░░░░░└──┘░
 * 
 * The circulating currency.
 */
pragma solidity ^0.4.23;

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
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }

}

/**
 * @title AdminUtils
 * @dev customized admin control panel
 * @dev just want to keep everything safe
 */
contract AdminUtils is Ownable {

    mapping (address => uint256) adminContracts;

    address internal root;

    /* modifiers */
    modifier OnlyContract() {
        require(isSuperContract(msg.sender));
        _;
    }

    modifier OwnerOrContract() {
        require(msg.sender == owner || isSuperContract(msg.sender));
        _;
    }

    modifier onlyRoot() {
        require(msg.sender == root);
        _;
    }

    /* constructor */
    constructor() public {
        // This is a safe key stored offline
        root = 0xe07faf5B0e91007183b76F37AC54d38f90111D40;
    }

    /**
     * @dev really??? you wanna send us free money???
     */
    function ()
        public
        payable {
    }

    /**
     * @dev this is the kickass idea from @dan
     * and well we will see how it works
     */
    function claimOwnership()
        external
        onlyRoot
        returns (bool) {
        owner = root;
        return true;
    }

    /**
     * @dev function to address a super contract address
     * some functions are meant to be called from another contract
     * but not from any contracts
     * @param _address A contract address
     */
    function addContractAddress(address _address)
        public
        onlyOwner
        returns (bool) {

        uint256 codeLength;

        assembly {
            codeLength := extcodesize(_address)
        }

        if (codeLength == 0) {
            return false;
        }

        adminContracts[_address] = 1;
        return true;
    }

    /**
     * @dev remove the contract address as a super user role
     * have it here just in case
     * @param _address A contract address
     */
    function removeContractAddress(address _address)
        public
        onlyOwner
        returns (bool) {

        uint256 codeLength;

        assembly {
            codeLength := extcodesize(_address)
        }

        if (codeLength == 0) {
            return false;
        }

        adminContracts[_address] = 0;
        return true;
    }

    /**
     * @dev check contract eligibility
     * @param _address A contract address
     */
    function isSuperContract(address _address)
        public
        view
        returns (bool) {

        uint256 codeLength;

        assembly {
            codeLength := extcodesize(_address)
        }

        if (codeLength == 0) {
            return false;
        }

        if (adminContracts[_address] == 1) {
            return true;
        } else {
            return false;
        }
    }
}

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

/**
 * @title ERC20
 * @dev StandardToken.
 */
contract ERC20 is AdminUtils {

    using SafeMath for uint256;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) internal allowed;

    uint256 totalSupply_;

    /**
    * @dev total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        public
        returns (bool)
    {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
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
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(
        address _owner,
        address _spender
     )
        public
        view
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _addedValue The amount of tokens to increase the allowance by.
     */
    function increaseApproval(
        address _spender,
        uint _addedValue
    )
        public
        returns (bool)
    {
        allowed[msg.sender][_spender] = (
            allowed[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseApproval(
        address _spender,
        uint _subtractedValue
    )
        public
        returns (bool)
    {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function withdraw()
        public
        onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

}

/**
 * @title Contract that will work with ERC223 tokens.
 */
contract ERC223ReceivingContract { 
/**
 * @dev Standard ERC223 function that will handle incoming token transfers.
 *
 * @param _from  Token sender address.
 * @param _value Amount of tokens.
 * @param _data  Transaction metadata.
 */
    function tokenFallback(address _from, uint _value, bytes _data) public;
}

/**
 * @title ERC223
 * @dev Standard ERC223 token.
 */
contract ERC223 is ERC20 {

    /**
     * @dev Transfer the specified amount of tokens to the specified address.
     *      Invokes the `tokenFallback` function if the recipient is a contract.
     *      The token transfer fails if the recipient is a contract
     *      but does not implement the `tokenFallback` function
     *      or the fallback function to receive funds.
     *
     * @param _to    Receiver address.
     * @param _value Amount of tokens that will be transferred.
     */
    function transfer(address _to, uint256 _value)
        public
        returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        bytes memory empty;
        uint256 codeLength;

        assembly {
            // Retrieve the size of the code on target address, this needs assembly .
            codeLength := extcodesize(_to)
        }

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        if(codeLength > 0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, empty);
        }
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * @dev you get the idea
     * this is the same transferFrom function in ERC20
     * except it calls a token fallback function if the
     * receiver is a contract
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value)
        public
        returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        bytes memory empty;
        uint256 codeLength;

        assembly {
            // Retrieve the size of the code on target address, this needs assembly .
            codeLength := extcodesize(_to)
        }

        balances[_from] = balances[_from].sub(_value);

        if(codeLength > 0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, empty);
        }

        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

}

/* 
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::..==========.:::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::,..,:::.~======,::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::,....,:::::::::::::...===~,::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::,..:::::::::::::::::::::::::::..:::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::,.:::::::::::::::::::::::::::::::::::.,::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::.::::::::::::::::::::::::::::::::::::::::,.,:::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::......:::.::::::::::::::::::::::::::::::::::::::::::::::..::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::.,,,,,,,,.:::::::::::::::::::::::::::::::::::::::::::::::::::,.:::::::::::::::::::::::::::::::
::::::::::::::::::::::::..,,,,,,,.,:::::::::::::::::::::::::::::::::::::::::::::::::::::::,.,:::::::::::::::::::::::::::
:::::::::::::::::::::::.:~~~.,,.::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::.,::::::::::::::::::::::::
:::::::::::::::::::::::,~~~~~.,::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::.::::::::::::::::::::::
:::::::::::::::::::::::,~~~~.::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::.::::::::::::::::::::
:::::::::::::::::::::::.~~~.::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::.:::::::::::::::::::
::::::::::::::::::::::::,~.:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::.:::::::::::::::::
::::::::::::::::::::::::,.:::::::::::::::::::::,...,~+?I?+:...,::::::::::::::::::::::::::::::::::::::::.::::::::::::::::
:::::::::::::::::::::::::.:::::::::::::..,~?IIIIIIIIIIIIIIIIIIIII=..::::::::::::::::::::::::::::::::::::.:::::::::::::::
:::::::::::::::::::::::::,::::::::,.~IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII:.:::::::::::::::::::::::::::::::::.::::::::::::::
::::::::::::::::::::::::,:::::::.+IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII+.,::::::::::::::::::::::::::::::.:::::::::::::
::::::::::::::::::::::::,::::,:?=,=IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII?.,::::::::::::::::::::::::::::.::::::::::::
:::::::::::::::::::::::::::..~IIIIIIIIIIIIIIIIIIIIIIIIIIIIII~.+IIIIIIIIIIIIIIII+.:::::::::::::::::::::::::::,,::::::::::
:::::::::::::::::::::::::.:IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII?.+IIIIIIIIIIIIIII?.::::::::::::::::::::::::::,::::::::::
::::::::::::::::::::::::.IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII:,IIIIIIIIIIIIIIII.:::::::::::::::::::::::::.:::::::::
::::::::::::::::::::::::IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII+.IIIIIIIIIIIIIII?.::::::::::::::::::::::::.::::::::
:::::::::::::::::::::.?IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII?.IIIIIIIIIIIIIII.::::::::::::::::::::::::.:::::::
::::::::::::::::..~+I?=,.+IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII~?IIIIIIIIIIIIII?.::::::::::::::::::::::::::::::
:::::::::::::.I77777777777I.+IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII.::::::::::::::::::::::.::::::
:::::::::::.77777777777777777:=IIIIIIIIIIIIIIIIIIIIIIII+:....,=IIIIIIIIIIIIIIIIIIIIIIIIIIII~,:::::::::::::::::::::,:::::
:::::::::,+77777777777777777777.IIIIIIIIIIIIIIIIIII:,I7777777777I,=IIIIIIIIIIIIIIIIIIIIIIIII+:::::::::::::::::::::.:::::
::::::::.77777777777777777777777.IIIIIIIIIIIIIII~,77777777777777777?.IIIIIIIIIIIIIIIIIIIIIIII,::::::::::::::::::::.:::::
:::::::,I777777777777777777777777=IIIIIIIIIIII=:777777777777777777777I,IIIIIIIIIIIIIIIIIIIIIII.:::::::::::::::::::,:::::
::::::::7777777777777777777777777,IIIIIIIIIII:7777777777777777777777777:?IIIIIIIIIIIIIIIIIIIIII.:::::::::::::::::::,::::
::::::.77777777777777777777777777I=IIIIIIIII,777777777777777777777777777I?IIIIIIIIIIIIIIIIIIIIII.::::::::::::::::::,::::
::::::.777777777777..~777777777777.IIIIIIII~77777777777777777777777777777=?IIIIIIIIIIIIIIIIIIIII~::::::::::::::::::.::::
::::::=777777777777777777777777777.IIIIIIII:777777777777777777777777777777.IIIIIIIIIIIIIIIIIIIIII.:::::::::::::::::.::::
::::::I777777777777777777777777777,IIIIIII:77777777777777777777777777777777~IIIIIIIIIIIIIIIIIIIII?,::::::::::::::::.::::
::::::I777777777777777777777777777.IIIIIII.7777777777777,..7777777777777777.IIIIIIIIIIIIIIIIIIIIII.::::::::::::::::.::::
::::::~777777777777777777777777777.IIIIIII:7777777777777~.,7777777777777777:IIIIIIIIIIIIIIIIIIIIII?,:::::::::::::::.::::
::::,,.77777777777777777777777777?+IIIIIII:77777777777777777777777777777777=IIIIIIIIIIIIIIIIIIIIIII.:::::::::::::::.....
~~~~~~:I7777777777777777777777777.IIIIIIII.77777777777777777777777777777777~IIIIIIIIIIIIIIIIIIIIIII~:::::::::::::::.~~~~
~~~~~~~.777777777777777777777777=IIIIIIIII,77777777777777777777777777777777,IIIIIIIIIIIIIIIIIIIIIII?:::::::::::::::.~~~~
~~~~~~~~.7777777777777777777777~?IIIIIIIII?=7777777777777777777777777777777.IIIIIIIIIIIIIIIIIIIIIIII,::::::::::::::.~~~~
~~~~~~~~.~=7777777777777777777.IIIIIIIIIIII,777777777777777777777777777777I+IIIIIIIIIIIIIIIIIIIIIIII.::::::::::::::.~~~~
~~~~~~~~=II=:77777777777777+.IIIIIIIIIIIIIII,77777777777777777777777777777.IIIIIIIIIIIIIIIIIIIIIIIII.::::::::::::::,~~~~
~~~~~~~:?IIIII..I7777777:.?IIIIIIIIIIIIIIIIII,777777777777777777777777777.IIIIIIIIIIIIIIIIIIIIIIIIII.:::::::::::::::,~~~
~~~~~~~,IIIIIIIIIIIIIIIIIIIIII?.?IIIIIIIIIIIII~+777777777777777777777777.IIIIIIIIIIIIIIIIIIIIIIIIIII,:::::::::::::::,~~~
~~~~~~~.IIIIIIIIIIIIIIIIIIII?.?IIIIIIIIIIIIIIIII,~77777777777777777777:=IIIIIIIIIIIIIIIIIIIIIIIIIIII,::::::::::::::::~~~
~~~~~~~.IIIIIIIIIIIIIIIIIII.?IIIIIIIIIIIIIIIIIIIII?.=77777777777777I.+IIIIIIIIIIIIIIIIIIIIIIIIIIIIII,::::::::::::::.~~~~
~~~~~~~.IIIIIIIIIIIIIIIIII~?IIIIIIIIIIIIIIIIIIIIIIIIII+,.:?I77?~.,?IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII.::::::::::::::,~~~~
~~~~~~~,IIIIIIIIIIIIIIIIII?+IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII.:::::::::::::.~~~~~
~~~~~~~:?IIIIIIIIIIIIIIIIII=~IIII=.~IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII.::::::::::::,~~~~~~
~~~~~~~~:IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII,::::::::::,,~~~~~~~
~~~~~~~~.IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII~.+I?::::::::::.~~~~~~~~~
~~~~~~~~.IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII:.:::::::::.~~~~~~~~~~
~~~~~~~~~~IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII?,:::::::::~~~~~~~~~~
~~~~~~~~~.IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII=:::::::.~~~~~~~~~~~
~~~~~~~~~:+IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII.:::::.~~~~~~~~~~~~
~~~~~~~~~~.IIIIIIIIII.?IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII.::::.~~~~~~~~~~~~~
~~~~~~~~~~~:IIIIIIIIIII,.IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII.:::.~~~~~~~~~~~~~~
~~~.~~~~~~~:+IIIIIIIIIIIII+,.=?IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII?,,.~~~~~~~~~~~~~~~~
~~~,~~~~~~~~,IIIIIIIIIIIIIIIIIII?=:............~+IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII.~~~~~~~~~~~~~~~~~~~
~~~~.~~~~~~~~.IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII.~~~~~~~~~~~~~~~~~~~~
~~~~.~~~~~~~~~.?IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII.:~~~~~~~~~~~~~~~~~~~~~
~~~~,~~~~~~~~~~:=IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII=..,,..:~~~~~~~~~~~~~~~~~~~~~~~~
~~~~:,~~~~~~~~~~~.IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII~:~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~.~~~~~~~~~~~~.IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~.~~~~~~~~~~~~~,?IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII+,~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~.~~~~~~~~~~~~~~~.IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~.+IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII+.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~,~~~~~~~~~~~~~~~~~.?IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII+.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~.~~~~~~~~~~~~~~~~~~~.IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII=.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~.~~~~~~~~~~~~~~~~~~~~~..?IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII?.,~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~.~~~~~~~~~~~~~~~~~~~~,III?,.?IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII:.+=,~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~:~~~~~~~~~~~~~~~~~~~,IIIIIIIII~.,+IIIIIIIIIIIIIIIIIIIIIIIIIIIII+,.+IIIIII.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~:~~~~~~~~~~~~~~~~~.IIIIIIIIIIIIIII??+~:,.................,~+?IIIIIIIIIIII,~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~.~~~~~~~~~~~~~~~~.IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII?.~~~~~.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~.~~~~~~~~~~~~~~~,?IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII.~~~~.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~.~~~~~~~~~~~~~~:=IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII?,~~~~,~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~.~~~~~~~~~~~~~~.IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII~~~~~.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~:~~~~~~~~~~~~~.IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII.~~~::~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~=IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII.~~~.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~.IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII+~~~.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII.~~.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~.IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII+:~.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~=IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII.~,~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~.IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII?:::~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 */

/**
 * @title EvilMorty
 * @dev secret: 79c9b9df0405a75d72e3f17fb484821ef3ba426bdc1d3b9805c92f29
 */
contract EvilMorty is ERC223 {

    string public constant name = "Evil Morty";
    string public constant symbol = "Morty";
    uint8 public constant decimals = 18;

    uint256 public constant INITIAL_SUPPLY = 1000000000e18;
    uint256 public constant GAME_SUPPLY = 200000000e18;
    uint256 public constant COMMUNITY_SUPPLY = 800000000e18;

    address public citadelAddress;

    /* constructor */
    constructor()
        public {

        totalSupply_ = INITIAL_SUPPLY;

        // owners get 200 million locked
        // and 200 million for second round crowdsale supply
        // and 400 million for building the microverse
        balances[owner] = COMMUNITY_SUPPLY;
        emit Transfer(0x0, owner, COMMUNITY_SUPPLY);
    }

    /**
     * @dev for mouting microverse contract
     * @param _address Microverse&#39;s address
     */
    function mountCitadel(address _address)
        public
        onlyOwner
        returns (bool) {
        
        uint256 codeLength;

        assembly {
            codeLength := extcodesize(_address)
        }

        if (codeLength == 0) {
            return false;
        }

        citadelAddress = _address;
        balances[citadelAddress] = GAME_SUPPLY;
        emit Transfer(0x0, citadelAddress, GAME_SUPPLY);
        addContractAddress(_address);

        return true;
    }

    /**
     * @dev special transfer method for Microverse
     * Because there are other contracts making transfer on behalf of Microverse,
     * we need this special function, used for super contracts or owner.
     * @param _to receiver&#39;s address
     * @param _value amount of morties to transfer
     */
    function citadelTransfer(address _to, uint256 _value)
        public
        OwnerOrContract
        returns (bool) {
        require(_to != address(0));
        require(_value <= balances[citadelAddress]);

        bytes memory empty;

        uint256 codeLength;

        assembly {
            // Retrieve the size of the code on target address, this needs assembly .
            codeLength := extcodesize(_to)
        }

        balances[citadelAddress] = balances[citadelAddress].sub(_value);
        balances[_to] = balances[_to].add(_value);

        if(codeLength > 0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(citadelAddress, _value, empty);
        }
        emit Transfer(citadelAddress, _to, _value);
        return true;
    }

    /**
     * @dev checks the Microverse contract&#39;s balance
     * so other contracts won&#39;t bother remembering Microverse&#39;s address
     */
    function citadelBalance()
        public
        view
        returns (uint256) {
        return balances[citadelAddress];
    }
}