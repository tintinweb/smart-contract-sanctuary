pragma solidity 0.4.24;


/**
 * @title Alfa Pet Token
 *
 * @dev Implementation of the ERC223 token.
 */
contract AlfaPetToken {

    /**
    * @dev Contract settings
    */
    string public constant name = "ALFA.PET.223.abcd";
    string public constant symbol = "APET";
    uint8 public constant decimals = 18;

    address public adminAddress;
    address public auditAddress;
    address public marketMakerAddress;

    //Fee em valor absoluto do token, com 18 casas decimais
    uint256 public mintFee;
    uint256 public transferFee;
    uint256 public burnFee;

    address public mintFeeReceiver;
    address public transferFeeReceiver;
    address public burnFeeReceiver;

    bool public mintAdminApprove;
    bool public mintAuditApprove;
    bool public mintMarketMakerApprove;

    bool public burnAdminApprove;
    bool public burnAuditApprove;
    bool public burnMarketMakerApprove;


    constructor() public {
        owner = msg.sender;
    }



/***********************************************
* @dev AlfaPetToken functions
************************************************/


    /**
    * @notice Transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    * @return A boolean that indicates if the operation was successful.
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
        uint256 toValue = safeSub(_value, transferFee);
        _transfer(transferFeeReceiver, transferFee);
        _transfer(_to, toValue);
        return true;
    }

    /**
    * @notice Transfer tokens from one address to another
    * @dev Not implemented
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint256 the amount of tokens to be transferred
    * @return A boolean that indicates if the operation was successful.
    */
    function transferFrom(address _from, address _to, uint256 _value) public pure returns (bool) {
        return false;
    }

    /**
    * @notice Function to mint tokens
    * @param _to The address that will receive the minted tokens.
    * @param _amount The amount of tokens to mint.
    * @return A boolean that indicates if the operation was successful.
    */
    function mint(address _to, uint256 _amount) public hasMintPermission canMint returns (bool) {
        uint256 toValue = safeSub(_amount, mintFee);
        _mint(mintFeeReceiver, mintFee);
        _mint(_to, toValue);

        mintAdminApprove = false;
        mintAuditApprove = false;
        mintMarketMakerApprove = false;
        return true;
    }

    /**
    * @notice Burns a specific amount of tokens.
    * @param _amount The amount of tokens to be burned.
    * @return A boolean that indicates if the operation was successful.    
    */
    function burn(uint256 _amount) public hasBurnPermission returns (bool) {
        uint256 fromValue = safeSub(_amount, burnFee);
        _transfer(burnFeeReceiver, burnFee);
        _burn(msg.sender, fromValue);

        burnAdminApprove = false;
        burnAuditApprove = false;
        burnMarketMakerApprove = false;
        return true;
    }

    /**
    * @notice Burns a specific amount of tokens from the target address and decrements allowance
    * @param _from address The address which you want to send tokens from
    * @param _amount uint256 The amount of token to be burned
    * @return A boolean that indicates if the operation was successful.
    */    
    function burnFrom(address _from, uint256 _amount) public hasBurnPermission returns (bool) {
        uint256 fromValue = safeSub(_amount, burnFee);
        _transferFrom(_from, burnFeeReceiver, burnFee);
        _burn(_from, fromValue);

        burnAdminApprove = false;
        burnAuditApprove = false;
        burnMarketMakerApprove = false;
        return true;
    }


    /* Address approvals */
    /**
    * @dev Set address approval: admin
    * @param _address address to be set
    * @return The address definied.
    */
    function setAdmin(address _address) public onlyOwner returns (address) {
        adminAddress = _address;
        return adminAddress;
    }    

    /**
    * @dev Set address approval: audit
    * @param _address address to be set
    * @return The address definied.
    */
    function setAudit(address _address) public onlyOwner returns (address) {
        auditAddress = _address;
        return auditAddress;
    }    

    /**
    * @dev Set address approval: market maker
    * @param _address address to be set
    * @return The address definied.
    */
    function setMarketMaker(address _address) public onlyOwner returns (address) {
        marketMakerAddress = _address;    
        return marketMakerAddress;
    }


    /* Fees */
    /**
    * @dev Set fee to mint
    * @param _value value to be set
    * @return The fee definied.
    */    
    function setMintFee(uint256 _value) public onlyOwner returns (uint256) {
        mintFee = _value;
        return mintFee;
    }

    /**
    * @dev Set fee to tranfer
    * @param _value value to be set
    * @return The fee definied.
    */  
    function setTransferFee(uint256 _value) public onlyOwner returns (uint256) {
        transferFee = _value;
        return transferFee;
    }    

    /**
    * @dev Set fee to burn
    * @param _value value to be set
    * @return The fee definied.
    */ 
    function setBurnFee(uint256 _value) public onlyOwner returns (uint256) {
        burnFee = _value;
        return burnFee;
    }


    /* Fees receivers  */
    /**
    * @dev Set the fee receiver to mint
    * @param _address address to be set
    * @return The address definied.
    */
    function setMintFeeReceiver(address _address) public onlyOwner returns (address) {
        mintFeeReceiver = _address;
        return mintFeeReceiver;
    }

    /**
    * @dev Set the fee receiver to transfer
    * @param _address address to be set
    * @return The address definied.
    */
    function setTransferFeeReceiver(address _address) public onlyOwner returns (address) {
        transferFeeReceiver = _address;
        return transferFeeReceiver;
    }    

    /**
    * @dev Set the fee receiver to burn
    * @param _address address to be set
    * @return The address definied.
    */
    function setBurnFeeReceiver(address _address) public onlyOwner returns (address) {
        burnFeeReceiver = _address;
        return burnFeeReceiver;
    }


    /* Approvals */
    /**
    * @dev Do mint approval: admin
    * @return A boolean that indicates if the operation was successful.
    */    
    function mintAdminApproval() public returns (bool) {
        require(msg.sender == adminAddress, "Only admin can approve mint");
        mintAdminApprove = true;
        return mintAdminApprove;
    }

    /**
    * @dev Do mint approval: audit
    * @return A boolean that indicates if the operation was successful.
    */    
    function mintAuditApproval() public returns (bool) {
        require(msg.sender == auditAddress, "Only audit can approve mint");
        mintAuditApprove = true;
        return mintAuditApprove;
    }

    /**
    * @dev Do mint approval: market maker
    * @return A boolean that indicates if the operation was successful.
    */
    function mintMarketMakerApproval() public returns (bool) {
        require(msg.sender == marketMakerAddress, "Only market maker can approve mint");
        mintMarketMakerApprove = true;
        return mintMarketMakerApprove;
    }

    /**
    * @dev Do burn approval: admin
    * @return A boolean that indicates if the operation was successful.
    */ 
    function burnAdminApproval() public returns (bool) {
        require(msg.sender == adminAddress, "Only admin can approve burn");
        burnAdminApprove = true;
        return burnAdminApprove;
    }

    /**
    * @dev Do burn approval: audit
    * @return A boolean that indicates if the operation was successful.
    */
    function burnAuditApproval() public returns (bool) {
        require(msg.sender == auditAddress, "Only audit can approve burn");
        burnAuditApprove = true;
        return burnAuditApprove;
    }

    /**
    * @dev Do burn approval: market maker
    * @return A boolean that indicates if the operation was successful.
    */
    function burnMarketMakerApproval() public returns (bool) {
        require(msg.sender == marketMakerAddress, "Only market maker can approve burn");
        burnMarketMakerApprove = true;
        return burnMarketMakerApprove;
    }



/**
 * @dev Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 */
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private allowed;
    uint256 private totalSupply_;


    /**
    * @dev Total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
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
    * @dev Function to check the amount of tokens that an owner allowed to a spender.
    * @param _owner address The address which owns the funds.
    * @param _spender address The address which will spend the funds.
    * @return A uint256 specifying the amount of tokens still available for the spender.
    */
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    /**
    * @dev Transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    /* customized
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_value <= balances[msg.sender]);
        require(_to != address(0));

        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to],_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    */

    /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    * @param _spender The address which will spend the funds.
    * @param _value The amount of tokens to be spent.
    */
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
    * @dev Transfer tokens from one address to another
    * Change to internal
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint256 the amount of tokens to be transferred
    */
    function _transferFrom(address _from, address _to, uint256 _value) internal returns (bool) {
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        require(_to != address(0));

        balances[_from] = safeSub(balances[_from], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
    * @dev Increase the amount of tokens that an owner allowed to a spender.
    * approve should be called when allowed[_spender] == 0. To increment
    * allowed value is better to use this function to avoid 2 calls (and wait until
    * the first transaction is mined)
    * @param _spender The address which will spend the funds.
    * @param _addedValue The amount of tokens to increase the allowance by.
    */
    function increaseApproval(address _spender, uint256 _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = (
            safeAdd(allowed[msg.sender][_spender], _addedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
    * @dev Decrease the amount of tokens that an owner allowed to a spender.
    * approve should be called when allowed[_spender] == 0. To decrement
    * allowed value is better to use this function to avoid 2 calls (and wait until
    * the first transaction is mined)
    * @param _spender The address which will spend the funds.
    * @param _subtractedValue The amount of tokens to decrease the allowance by.
    */
    function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool) {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue >= oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = safeSub(oldValue, _subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
    * @dev Internal function that mints an amount of the token and assigns it to
    * an account. This encapsulates the modification of balances such that the
    * proper events are emitted.
    * @param _account The account that will receive the created tokens.
    * @param _amount The amount that will be created.
    */
    function _mint(address _account, uint256 _amount) internal {
        require(_account != 0);
        totalSupply_ = safeAdd(totalSupply_, _amount);
        balances[_account] = safeAdd(balances[_account], _amount);
        emit Transfer(address(0), _account, _amount);
        emit Mint(_account, _amount);
    }

    /**
    * @dev Internal function that burns an amount of the token of a given
    * account, deducting from the sender&#39;s allowance for said account. Uses the
    * internal _burn function.
    * @param _account The account which tokens will be burnt.
    * @param _amount The amount that will be burnt.
    */
    /* N&#195;o UTILIZADO
    function _burnFrom(address _account, uint256 _amount) internal {
        require(_amount <= allowed[_account][msg.sender]);

        allowed[_account][msg.sender] = safeSub(allowed[_account][msg.sender], _amount);
        _burn(_account, _amount);
    }
    */


/**
 * @dev Mintable token
 */
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished = false;

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    modifier hasMintPermission() {
        require(msg.sender == owner, "Only owner");
        require(mintAdminApprove, "Require admin approval");
        require(mintAuditApprove, "Require audit approval");
        require(mintMarketMakerApprove, "Require market maker approval");        
        _;
    }

    /**
    * @dev Function to stop minting new tokens.
    * @return True if the operation was successful.
    */
    function finishMinting() public onlyOwner canMint returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }



/**
 * @dev Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
    event Burn(address indexed burner, uint256 value);

    modifier hasBurnPermission() {
        //require(msg.sender == owner, "Only owner");
        require(burnAdminApprove, "Require admin approval");
        require(burnAuditApprove, "Require audit approval");
        require(burnMarketMakerApprove, "Require market maker approval");        
        _;
    }

    /**
    * @dev Internal function that burns an amount of the token of a given account.
    * @dev Overrides StandardToken._burn in order for burn and burnFrom to emit an additional Burn event.
    * @param _account The account whose tokens will be burnt.
    * @param _amount The amount that will be burnt.
    */
    function _burn(address _account, uint256 _amount) internal {
        require(_account != 0);
        require(_amount <= balances[_account]);

        totalSupply_ = safeSub(totalSupply_, _amount);
        balances[_account] = safeSub(balances[_account], _amount);
        emit Transfer(_account, address(0), _amount);
        emit Burn(_account, _amount);
    }



/**
 * @dev ERC223 token
 */
    event Transfer(address indexed from, address indexed to, uint256 value, bytes data);
    //event Transfer(address indexed from, address indexed to, uint256 value, bytes data);
  
    // Function that is called when a user or another contract wants to transfer funds.
    function _transfer(address _to, uint256 _value, bytes _data, string _custom_fallback) private returns (bool success) {
        
        if(isContract(_to)) {
            if (balanceOf(msg.sender) < _value) revert();
            balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
            balances[_to] = safeAdd(balanceOf(_to), _value);

            assert(_to.call.value(0)(bytes4(keccak256(abi.encodePacked(_custom_fallback))), msg.sender, _value, _data));
            
            emit Transfer(msg.sender, _to, _value, _data);
            return true;
        }
        else {
            return transferToAddress(_to, _value, _data);
        }
    }

    // Function that is called when a user or another contract wants to transfer funds.
    function _transfer(address _to, uint256 _value, bytes _data) private returns (bool success) {
            
        if(isContract(_to)) {
            return transferToContract(_to, _value, _data);
        }
        else {
            return transferToAddress(_to, _value, _data);
        }
    }

    /**
    * @dev Transfer token for a specified address
    * Standard function transfer similar to ERC20 transfer with no _data.
    * Added due to backwards compatibility reasons.
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function _transfer(address _to, uint256 _value) private returns (bool success) {            
        //standard function transfer similar to ERC20 transfer with no _data
        //added due to backwards compatibility reasons
        bytes memory empty;
        if(isContract(_to)) {
            return transferToContract(_to, _value, empty);
        }
        else {
            return transferToAddress(_to, _value, empty);
        }
    }


    //assemble the given address bytecode. If bytecode exists then the _addr is a contract.
    function isContract(address _addr) private view returns (bool is_contract) {
        uint codeLength;
        assembly {
            //retrieve the size of the code on target address, this needs assembly
            codeLength := extcodesize(_addr)
        }
        return (codeLength>0);
    }

    //function that is called when transaction target is an address
    function transferToAddress(address _to, uint256 _value, bytes _data) private returns (bool success) {
        if (balanceOf(msg.sender) < _value) revert();
        balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
        balances[_to] = safeAdd(balanceOf(_to), _value);        
        emit Transfer(msg.sender, _to, _value, _data);
        return true;
    }
  
    //function that is called when transaction target is a contract
    function transferToContract(address _to, uint256 _value, bytes _data) private returns (bool success) {
        if (balanceOf(msg.sender) < _value) revert();
        balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
        balances[_to] = safeAdd(balanceOf(_to), _value);
        ContractReceiver receiver = ContractReceiver(_to);
        receiver.tokenFallback(msg.sender, _value, _data);
        emit Transfer(msg.sender, _to, _value, _data);
        return true;
    }



/**
 * @dev Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);    

    address public owner;

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



/**
 * @dev SafeMath
 * @dev Math operations with safety checks that revert on error
 */

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function safeMul(uint256 _a, uint256 _b) internal pure returns (uint256) {
        if (_a == 0) {
            return 0;
        }

        uint256 c = _a * _b;
        require(c / _a == _b);
        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function safeDiv(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b > 0); // Solidity only automatically asserts when dividing by 0
        uint256 c = _a / _b;
        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    //function safeSub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    function safeSub(uint256 _a, uint256 _b) public pure returns (uint256) {
        require(_b <= _a);
        uint256 c = _a - _b;
        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function safeAdd(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a);
        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function safeMod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }

}



/**
* @dev Contract that is working with ERC223 tokens.
*/
contract ContractReceiver {
     
    struct TKN {
        address sender;
        uint256 value;
        bytes data;
        bytes4 sig;
    }    
    
    function tokenFallback(address _from, uint256 _value, bytes _data) public pure {
        TKN memory tkn;
        tkn.sender = _from;
        tkn.value = _value;
        tkn.data = _data;
        uint32 u = uint32(_data[3]) + (uint32(_data[2]) << 8) + (uint32(_data[1]) << 16) + (uint32(_data[0]) << 24);
        tkn.sig = bytes4(u);

    }
}