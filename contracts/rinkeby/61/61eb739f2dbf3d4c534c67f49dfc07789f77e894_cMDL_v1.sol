/**
 *Submitted for verification at Etherscan.io on 2021-09-16
*/

/**
 *Submitted for verification at Etherscan.io on 2020-07-21
*/

pragma solidity ^0.4.19;


// The cMDL Token Contract
contract cMDL_v1 {    

    /** Paramaeters **/
    // Core
    //uint256 public maxSupply = 100000000000e18; // maximum cMDL in circulation 100 billion

    uint256 public emissionAmount; // amount of cMDLs distributed to each account during the emissionPeriod
    uint256 public emissionPeriod; // number of blocks between emissions
    uint256 public emissionParametersChangePeriod = 40320; // number of blocks between emission parameters change
    
    // Burn Fees
    uint256 public burnFee; // the burn fee proportion deducted from each cMDL transfer (1 = 1e18, 0.001 (0.1%) = 1e15 etc)
    
    // Operator
    address public operatorAccount; // account that changes the mintAccount and can block/unblock accounts, operator account also distributes Rinkeby ETH to all accounts to allow for free transfers
    address public mintAccount; // account that is allowed to mint initial payments
        
    
    // Transaction Fees
    uint256 public maxTxFee = 1e16; // maximum transaction fee 1%
    uint256 public txFee; // the transaction fee proportion deducted from each cMDL transfer (1 = 1e18, 0.001 (0.1%) = 1e15 etc)




    /** Events **/
    // Parameters
    event emissionParametersChanged(uint256 newEmissionAmount, uint256 newEmissionPeriod); // fired when emission parameters are changed
    event operatorChanged(address indexed newOperatorAccount); // fired when operatorAccount is modified
    event mintAccountChanged(address indexed newMintAccount); // fired when mint account is changed
    event chargedProposalFee(address indexed account, uint256 fee); // fired when a proposal fee is charged
   
    // Operator
    event registered(uint256 indexed id, address account); // fired when a new account is registered
    event userBlocked(uint256 indexed id, bool blocked); // fired when an account is blocked or unblocked
    event userSetInactive(address account); // fired when an account is marked as inactive
    
    // User
    event claimed(address indexed account, uint256 amount); // fired on each emission claim performed by user

    // Burn fee
    event burnFeeChanged(uint256 newBurnFee); // fired when the burnFee is changed
    
    // Transaction Fees
    event txFeeChanged(uint256 newTxFee); // fired when the taxProportion is changed



    /**
     * cMDL Functions
     * */

    /** Emission Functionality **/  
    // Internal parameters
    mapping (uint256 => uint256)    public lastEmissionClaimBlock; // mapping of user FB ids and their respective last emission claim blocks
    mapping (address => uint256)    public balance; // holds
    mapping (uint256 => address)    public accounts; // mapping of ID numbers (eg. Facebook UID) to account addresses 
    mapping (address => uint256)    public ids; // inverse mapping of accounts
    mapping (uint256 => bool)       public blocked; // keeps list of accounts blocked for emissions
    mapping (address => bool)       public proxyContract; // mapping of proxy contracts, funds sent to these contracts dont have a burn fee or tx fee
    mapping (bytes32 => bool)       public claimedHashes; // mapping of claim hashes that have been already used
    mapping (bytes32 => bool)       public transferred; // mapping of used transfer hashes

    uint256 public lastEmissionParameterChange; // the block number when the emission parameters were changed last time

    


    /** User Functions **/
    enum SignatureType {               
        /*  0 */RECURRING_PAYMENT_CREATE,                
        /*  1 */RECURRING_PAYMENT_CANCEL
    }

    // Claim emission function called by the holder once each emission period
    // function claimEmission() external {
    //     releaseEmission(msg.sender);
    // }

    // Claim emission function called by the mint account on behalf of the user
    function claimEmissionForUser(address account, uint256 nonce, uint8 v, bytes32 r, bytes32 s) external onlyMint {
        bytes32 claimHash = keccak256(this, account, nonce);
        require(ecrecover(keccak256("\x19Ethereum Signed Message:\n32", claimHash), v, r, s) == account, "cMDL Error: invalid signature");
        require(!claimedHashes[claimHash], "cMDL Error: claim hash already used");

        releaseEmission(account);
    }

    // Perform emission
    function releaseEmission(address account) internal {
        require(ids[account] > 0, "cMDL Error: account not registered");
        require(safeSub(block.number, lastEmissionClaimBlock[ids[account]]) > emissionPeriod, "cMDL Error: emission period did not pass yet");
        //require(safeAdd(totalSupply, emissionAmount) <= maxSupply, "cMDL Error: max supply reached");

        require(!blocked[ids[account]], "cMDL Error: account blocked");

        balanceOf[account] = safeAdd(balanceOf[account], emissionAmount);
        
        lastEmissionClaimBlock[ids[account]] = block.number;
        totalSupply = safeAdd(totalSupply, emissionAmount);

        emit claimed(account, emissionAmount);
        emit Transfer(address(0), account, emissionAmount);
    }
 
    
    
    /** Operator Functions **/
    // Register participant
    function register(address account, uint256 id) external onlyMint {
        require(ids[account] == 0, "cMDL Error: account already registered");
        require(mintAccount != account, "cMDL Error: cannot mint to mintAccount");

        accounts[id] = account;
        ids[account] = id;

        emit registered(id, account);  

        allocateEmission(account, id);    
    }

    function allocateEmission(address account, uint256 id) internal returns (uint256) {
        // if (safeAdd(totalSupply, emissionAmount) > maxSupply) {
        //     return 0;
        // }

        balanceOf[account] = safeAdd(balanceOf[account], emissionAmount);
        lastEmissionClaimBlock[id] = block.number;

        totalSupply = safeAdd(totalSupply, emissionAmount);

        emit claimed(account, emissionAmount);
        emit Transfer(address(0), account, emissionAmount); 

        return emissionAmount;
    }

    function reRegisterAccount(address account, uint256 id) external onlyMint {
        require(ids[account] == 0, "cMDL Error: address already used for another account");
        require(accounts[id] != address(0), "cMDL Error: account not registered");

        
        ids[account] = id;
        accounts[id] = account;

        emit registered(id, account);
    }
 
    // Block account, prevents account from claimin emissions
    function blockAccount(uint256 id) public onlyMint {
        blocked[id] = true;
        emit userBlocked(id, true);
    }

    // Unblock account, removes block from account
    function unBlockAccount(uint256 id) public onlyMint {
        blocked[id] = false;
        emit userBlocked(id, false);
    }










    /** Parameter Functionality **/    
    // the function called by the operator to change the cMDL emission parameters
    function changeEmissionParameters(uint256 emissionAmount_, uint256 emissionPeriod_) external onlyOperator returns (bool success) {
        //require(emissionAmount_ < safeMul(emissionAmount, 1328)/1000 && emissionAmount_ > safeMul(emissionAmount, 618)/1000, "cMDL Error: emissionSize out of bounds");
        require(lastEmissionParameterChange < safeSub(block.number, emissionParametersChangePeriod), "cMDL Error: emission parameters cannot be changed yet");
        //require(emissionPeriod_ >= emissionPeriod, "cMDL Error: emission period can only be increased");

        emissionAmount = emissionAmount_;
        emissionPeriod = emissionPeriod_;

        lastEmissionParameterChange = block.number;

        emit emissionParametersChanged(emissionAmount, emissionPeriod);
        return true;
    }

    // function called by the operator to change the cMDL operatorAccount
    function changeOperatorAccount(address operatorAccount_) external onlyOperator returns (bool success)  {
        operatorAccount = operatorAccount_;

        emit operatorChanged(operatorAccount);
        return true;
    }

    // function called by the operatorAccount to change the mint account address
    function changeMintAccount(address mintAccount_) external onlyOperator  {
        mintAccount = mintAccount_;

        emit mintAccountChanged(mintAccount);
    }

    // function called to set a contract as a proxy contract by the operatorAccount
    function setProxyContract(address contractAddress, bool isProxy) external onlyOperator {
        proxyContract[contractAddress] = isProxy;
    }
        

    /** Transaction Burn Fee Functionality **/
    // Transaction burn fee is the fee taken during each transfer from the transferred amount and burnt.
    // This is necessary to combat inflation, through the burn fee, the total supply of cMDL is decreased 
    // as the transferred volume increases
    
    // the function called by the operator to change the burnFee
    function changeBurnFee(uint256 burnFee_) external onlyOperator {
        require(burnFee_ < 5e16, "cMDL Error: burn fee cannot be higher than 5%");

        burnFee = burnFee_;
        emit burnFeeChanged(burnFee);
    }
    



    /** Transaction Fee Functionality **/
    // Transaction fee account is the account receiving the transaction fee from each cMDL transfer
    // This functionality is optional to mitigate network congestion that could lead to high network fees
    // Can also be used to collect additional taxes from users
    // Transaction fee is paid by the receiver

    // the function called by the operator to change the txFee
    function changeTxFee(uint256 txFee_) external onlyOperator {
        require(txFee_ < maxTxFee, "cMDL Error: txFee cannot be higher than maxTxFee");

        txFee = txFee_;
        emit txFeeChanged(txFee);
    }
    
    


    /** Internal Functionality **/

    /** Constructor **/
    // Constructor function, called once when deploying the contract
    constructor(
        string memory name_,
        string memory symbol_,

        uint256 initialEmissionAmount, 
        uint256 initialEmissionPeriod, 
        uint256 initialBurnFee,
        uint256 initialTxFee,
        
        address initialOperatorAccount, 
        address initialMintAccount
    ) public
    {
        name = name_;
        symbol = symbol_;

        emissionAmount  = initialEmissionAmount;
        emissionPeriod  = initialEmissionPeriod;
        burnFee         = initialBurnFee;
        txFee           = initialTxFee;

        operatorAccount = initialOperatorAccount;
        mintAccount     = initialMintAccount;
    }




    /** Modifiers **/
    // a modifier that allows only the mintAccount to access a function
    modifier onlyMint {
        require(msg.sender == mintAccount || msg.sender == operatorAccount, "cMDL Error: accesses denied");
        _;
    }

    // a modifier that allows only the operatorAccount to access a function
    modifier onlyOperator {
        require(msg.sender == operatorAccount, "cMDL Error: accesses denied");
        _;
    }


    /** Helpers **/
    // Returns the smaller of two values
    function min(uint a, uint b) private pure returns (uint) {
        return a < b ? a : b;
    }

    // Returns the largest of the two values
    function max(uint a, uint b) private pure returns (uint) {
        return a > b ? a : b;
    }
    
    
    // Returns true if the account is registered
    function isRegistered(address account) public view returns (bool registered)
    {
        if (lastEmissionClaimBlock[ids[account]] > 0)
        {
            return true;
        }
        else
        {
            return false;
        }
    }














    /** ERC20 Implementation 
    * https://eips.ethereum.org/EIPS/eip-20
    **/
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply = 0;

    mapping (address => uint256) public balanceOf; // keeps the balances of all accounts
    mapping (address => mapping (address => uint256)) public allowance; // keeps allowences for all accounts (implementation of the ERC20 interface)

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value); // This generates a public event on the blockchain that will notify clients (ERC20 interface)
    
    // This generates a public event on the blockchain that will notify clients
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(address(_to) != address(0));        

        uint256 burnFeeAmount = safeMul(_value, burnFee)/1e18;
        uint256 txFeeAmount = safeMul(_value, txFee)/1e18;

        if (proxyContract[_to])
        {
            burnFeeAmount = 0;
            txFeeAmount = 0;
        }

        // Subtract from the sender
        balanceOf[_from] = safeSub(balanceOf[_from], safeAdd(_value, txFeeAmount));
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);
        balanceOf[operatorAccount] = safeAdd(balanceOf[operatorAccount], txFeeAmount);
        burnForUser(_to, burnFeeAmount);

        emit Transfer(_from, _to, _value);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * Signed Transfer
     *
     * Send `_value` tokens to `_to` from `_account`
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function signedTransfer(address _to, uint256 _value, address _account, uint256 nonce, uint8 v, bytes32 r, bytes32 s) public returns (bool success) {
        bytes32 transferHash = keccak256(this, _account, _to, _value, nonce);
        require(ecrecover(keccak256("\x19Ethereum Signed Message:\n32", transferHash), v, r, s) == _account, "cMDL Error: invalid signature");
        require(!transferred[transferHash], "cMDL Error: transfer hash already used");

        transferred[transferHash] = true;

        _transfer(_account, _to, _value);
        return true;
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` on behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }

    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burnForUser(address account, uint256 _value) internal returns (bool success) {
        require(balanceOf[account] >= _value);   // Check if the sender has enough
        balanceOf[account] -= _value;            // Subtract from the sender
        totalSupply -= _value;                   // Updates totalSupply
        //emit Burn(account, _value);
        return true;
    }



    /** Safe Math **/

    // Safe Multiply Function - prevents integer overflow 
    function safeMul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    // Safe Subtraction Function - prevents integer overflow 
    function safeSub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    // Safe Addition Function - prevents integer overflow 
    function safeAdd(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c>=a && c>=b);
        return c;
    }
}