pragma solidity 0.4.24;
/**
* @title Vivalid Token Contract
* @dev ViV is an ERC-20 Standar Compliant Token
* For more info https://vivalid.io
*/

/**
 * @title SafeMath by OpenZeppelin (partially)
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

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
* @title Admin parameters
* @dev Define administration parameters for this contract
*/
contract admined { //This token contract is administered
    address public admin; //Admin address is public
    bool public lockSupply; //Burn Lock flag

    /**
    * @dev Contract constructor
    * define initial administrator
    */
    constructor() internal {
        admin = msg.sender; //Set initial admin to contract creator
        emit Admined(admin);
    }

    modifier onlyAdmin() { //A modifier to define admin-only functions
        require(msg.sender == admin);
        _;
    }

    modifier supplyLock() { //A modifier to lock mint and burn transactions
        require(lockSupply == false);
        _;
    }

    /**
    * @dev Function to set new admin address
    * @param _newAdmin The address to transfer administration to
    */
    function transferAdminship(address _newAdmin) onlyAdmin public { //Admin can be transfered
        require(_newAdmin != 0);
        admin = _newAdmin;
        emit TransferAdminship(admin);
    }

    /**
    * @dev Function to set burn lock
    * This function will be used after the burn process finish
    */
    function setSupplyLock(bool _flag) onlyAdmin public { //Only the admin can set a lock on supply
        lockSupply = _flag;
        emit SetSupplyLock(lockSupply);
    }

    //All admin actions have a log for public review
    event SetSupplyLock(bool _set);
    event TransferAdminship(address newAdminister);
    event Admined(address administer);

}

/**
* @title ERC20 interface
* @dev see https://github.com/ethereum/EIPs/issues/20
*/
contract ERC20 {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
* @title ERC20Token
* @notice Token definition contract
*/
contract ERC20Token is admined, ERC20 { //Standar definition of an ERC20Token
    using SafeMath for uint256; //SafeMath is used for uint256 operations
    mapping (address => uint256) internal balances; //A mapping of all balances per address
    mapping (address => mapping (address => uint256)) internal allowed; //A mapping of all allowances
    uint256 internal totalSupply_;

    /**
    * A mapping of frozen accounts and unfreeze dates
    *
    * In case your account balance is fronzen and you 
    * think it&#39;s an error please contact the support team
    *
    * This function is only intended to lock specific wallets
    * as explained on project white paper
    */
    mapping (address => bool) frozen;
    mapping (address => uint256) unfreezeDate;

    /**
    * @dev total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }
    
    /**
    * @notice Get the balance of an _who address.
    * @param _who The address to be query.
    */
    function balanceOf(address _who) public view returns (uint256) {
        return balances[_who];
    }

    /**
    * @notice transfer _value tokens to address _to
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    * @return success with boolean value true if done
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0)); //Invalid transfer
        require(frozen[msg.sender]==false);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
    * @notice Get the allowance of an specified address to use another address balance.
    * @param _owner The address of the owner of the tokens.
    * @param _spender The address of the allowed spender.
    * @return remaining with the allowance value
    */
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    /**
    * @notice Transfer _value tokens from address _from to address _to using allowance msg.sender allowance on _from
    * @param _from The address where tokens comes.
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    * @return success with boolean value true if done
    */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0)); //Invalid transfer
        require(frozen[_from]==false);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
    * @notice Assign allowance _value to _spender address to use the msg.sender balance
    * @param _spender The address to be allowed to spend.
    * @param _value The amount to be allowed.
    * @return success with boolean value true
    */
    function approve(address _spender, uint256 _value) public returns (bool) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0)); //exploit mitigation
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
    * @dev Burn token of an specified address.
    * @param _burnedAmount amount to burn.
    */
    function burnToken(uint256 _burnedAmount) onlyAdmin supplyLock public {
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], _burnedAmount);
        totalSupply_ = SafeMath.sub(totalSupply_, _burnedAmount);
        emit Burned(msg.sender, _burnedAmount);
    }

    /**
    * @dev Frozen account handler
    * @param _target The address to being frozen.
    * @param _flag The status of the frozen
    * @param _timeInDays The amount of time the account becomes locked
    */
    function setFrozen(address _target,bool _flag,uint256 _timeInDays) public {
        if(_flag == true){
            require(msg.sender == admin); //Only admin
            require(frozen[_target] == false); //Not already frozen
            frozen[_target] = _flag;
            unfreezeDate[_target] = now.add(_timeInDays * 1 days);

            emit FrozenStatus(_target,_flag,unfreezeDate[_target]);

        } else {
            require(now >= unfreezeDate[_target]);
            frozen[_target] = _flag;

            emit FrozenStatus(_target,_flag,unfreezeDate[_target]);
        }
    }

    event Burned(address indexed _target, uint256 _value);
    event FrozenStatus(address indexed _target,bool _flag,uint256 _unfreezeDate);

}

/**
* @title AssetViV
* @notice ViV Token creation.
* @dev ERC20 Token compliant
*/
contract AssetViV is ERC20Token {
    string public name = &#39;VIVALID&#39;;
    uint8 public decimals = 18;
    string public symbol = &#39;ViV&#39;;
    string public version = &#39;1&#39;;

    /**
    * @notice token contructor.
    */
    constructor() public {
        totalSupply_ = 200000000 * 10 ** uint256(decimals); //Initial tokens supply 200M;
        balances[msg.sender] = totalSupply_;
        emit Transfer(0, this, totalSupply_);
        emit Transfer(this, msg.sender, totalSupply_);       
    }

    /**
    * @notice Function to claim ANY token accidentally stuck on contract
    * In case of claim of stuck tokens please contact contract owners
    * Tokens to be claimed has to been strictly erc20 compliant
    * We use the ERC20 interface declared before
    */
    function claimTokens(ERC20 _address, address _to) onlyAdmin public{
        require(_to != address(0));
        uint256 remainder = _address.balanceOf(this); //Check remainder tokens
        _address.transfer(_to,remainder); //Transfer tokens to creator
    }

    
    /**
    * @notice this contract will revert on direct non-function calls, also it&#39;s not payable
    * @dev Function to handle callback calls to contract
    */
    function() public {
        revert();
    }

}