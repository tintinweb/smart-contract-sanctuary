/**
 *Submitted for verification at Etherscan.io on 2019-07-04
*/

pragma solidity ^0.5.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev give an account access to this role
     */
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

    /**
     * @dev remove an account&#39;s access to this role
     */
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

    /**
     * @dev check if an account has this role
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}




contract PauserRole {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(msg.sender);
    }

    modifier onlyPauser() {
        require(isPauser(msg.sender));
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(msg.sender);
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}









/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
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
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

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
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

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
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 * Originally based on code by FirstBlood:
 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 *
 * This implementation emits additional Approval events, allowing applications to reconstruct the allowance status for
 * all accounts just by listening to said events. Note that this isn&#39;t required by the specification, and other
 * compliant implementations may not do it.
 */
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;

    /**
    * @dev Total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param owner The address to query the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

    /**
    * @dev Transfer token for a specified address
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another.
     * Note that while this function emits an Approval event, this is not required as per the specification,
     * and other compliant implementations may not emit the event.
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(subtractedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    /**
    * @dev Transfer token for a specified addresses
    * @param from The address to transfer from.
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    /**
     * @dev Internal function that mints an amount of the token and assigns it to
     * an account. This encapsulates the modification of balances such that the
     * proper events are emitted.
     * @param account The account that will receive the created tokens.
     * @param value The amount that will be created.
     */
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account.
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account, deducting from the sender&#39;s allowance for said account. Uses the
     * internal burn function.
     * Emits an Approval event (reflecting the reduced allowance).
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burnFrom(address account, uint256 value) internal {
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(value);
        _burn(account, value);
        emit Approval(account, msg.sender, _allowed[account][msg.sender]);
    }
}





/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is PauserRole {
    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;

    constructor () internal {
        _paused = false;
    }

    /**
     * @return true if the contract is paused, false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}


/**
 * @title Pausable token
 * @dev ERC20 modified with pausable transfers.
 **/
contract ERC20Pausable is ERC20, Pausable {
    function transfer(address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transferFrom(from, to, value);
    }

    function approve(address spender, uint256 value) public whenNotPaused returns (bool) {
        return super.approve(spender, value);
    }

    function increaseAllowance(address spender, uint addedValue) public whenNotPaused returns (bool success) {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint subtractedValue) public whenNotPaused returns (bool success) {
        return super.decreaseAllowance(spender, subtractedValue);
    }
}





/**
 * @title ERC20Detailed token
 * @dev The decimals are only for visualization purposes.
 * All the operations are done using the smallest and indivisible token unit,
 * just as on Ethereum all the operations are done in wei.
 */
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @return the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @return the symbol of the token.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @return the number of decimals of the token.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}





/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


contract BNDESRegistry is Ownable() {

    /**
        The account of clients and suppliers are assigned to states. 
        Reserved accounts (e.g. from BNDES and ANCINE) do not have state.
        AVAILABLE - The account is not yet assigned any role (any of them - client, supplier or any reserved addresses).
        WAITING_VALIDATION - The account was linked to a legal entity but it still needs to be validated
        VALIDATED - The account was validated
        INVALIDATED_BY_VALIDATOR - The account was invalidated
        INVALIDATED_BY_CHANGE - The client or supplier changed the ethereum account so the original one must be invalidated.
     */
    enum BlockchainAccountState {AVAILABLE,WAITING_VALIDATION,VALIDATED,INVALIDATED_BY_VALIDATOR,INVALIDATED_BY_CHANGE} 
    BlockchainAccountState blockchainState; //Not used. Defined to create the enum type.

    address responsibleForSettlement;
    address responsibleForRegistryValidation;
    address responsibleForDisbursement;
    address redemptionAddress;
    address tokenAddress;

    /**
        Describes the Legal Entity - clients or suppliers
     */
    struct LegalEntityInfo {
        uint64 cnpj; //Brazilian identification of legal entity
        uint64 idFinancialSupportAgreement; //SCC contract
        uint32 salic; //ANCINE identifier
        string idProofHash; //hash of declaration
        BlockchainAccountState state;
    } 

    /**
        Links Ethereum addresses to LegalEntityInfo        
     */
    mapping(address => LegalEntityInfo) public legalEntitiesInfo;

    /**
        Links Legal Entity to Ethereum address. 
        cnpj => (idFinancialSupportAgreement => address)
     */
    mapping(uint64 => mapping(uint64 => address)) cnpjFSAddr; 


    /**
        Links Ethereum addresses to the possibility to change the account
        Since the Ethereum account can be changed once, it is not necessary to put the bool to false.
        TODO: Discuss later what is the best data structure
     */
    mapping(address => bool) public legalEntitiesChangeAccount;


    event AccountRegistration(address addr, uint64 cnpj, uint64 idFinancialSupportAgreement, uint32 salic, string idProofHash);
    event AccountChange(address oldAddr, address newAddr, uint64 cnpj, uint64 idFinancialSupportAgreement, uint32 salic, string idProofHash);
    event AccountValidation(address addr, uint64 cnpj, uint64 idFinancialSupportAgreement, uint32 salic);
    event AccountInvalidation(address addr, uint64 cnpj, uint64 idFinancialSupportAgreement, uint32 salic);

    /**
     * @dev Throws if called by any account other than the token address.
     */
    modifier onlyTokenAddress() {
        require(isTokenAddress());
        _;
    }

    constructor () public {
        responsibleForSettlement = msg.sender;
        responsibleForRegistryValidation = msg.sender;
        responsibleForDisbursement = msg.sender;
        redemptionAddress = msg.sender;
    }


   /**
    * Link blockchain address with CNPJ - It can be a cliente or a supplier
    * The link still needs to be validated by BNDES
    * This method can only be called by BNDESToken contract because BNDESToken can pause.
    * @param cnpj Brazilian identifier to legal entities
    * @param idFinancialSupportAgreement contract number of financial contract with BNDES. It assumes 0 if it is a supplier.
    * @param salic contract number of financial contract with ANCINE. It assumes 0 if it is a supplier.
    * @param addr the address to be associated with the legal entity.
    * @param idProofHash The legal entities have to send BNDES a PDF where it assumes as responsible for an Ethereum account. 
    *                   This PDF is signed with eCNPJ and send to BNDES. 
    */
    function registryLegalEntity(uint64 cnpj, uint64 idFinancialSupportAgreement, uint32 salic, 
        address addr, string memory idProofHash) onlyTokenAddress public { 

        // Endere&#231;o n&#227;o pode ter sido cadastrado anteriormente
        require (isAvailableAccount(addr), "Endere&#231;o n&#227;o pode ter sido cadastrado anteriormente");

        require (isValidHash(idProofHash), "O hash da declara&#231;&#227;o &#233; inv&#225;lido");

        legalEntitiesInfo[addr] = LegalEntityInfo(cnpj, idFinancialSupportAgreement, salic, idProofHash, BlockchainAccountState.WAITING_VALIDATION);
        
        // N&#227;o pode haver outro endere&#231;o cadastrado para esse mesmo subcr&#233;dito
        if (idFinancialSupportAgreement > 0) {
            address account = getBlockchainAccount(cnpj,idFinancialSupportAgreement);
            require (isAvailableAccount(account), "Cliente j&#225; est&#225; associado a outro endere&#231;o. Use a fun&#231;&#227;o Troca.");
        }
        else {
            address account = getBlockchainAccount(cnpj,0);
            require (isAvailableAccount(account), "Fornecedor j&#225; est&#225; associado a outro endere&#231;o. Use a fun&#231;&#227;o Troca.");
        }
        
        cnpjFSAddr[cnpj][idFinancialSupportAgreement] = addr;

        emit AccountRegistration(addr, cnpj, idFinancialSupportAgreement, salic, idProofHash);
    }

   /**
    * Changes the original link between CNPJ and Ethereum account. 
    * The new link still needs to be validated by BNDES.
    * This method can only be called by BNDESToken contract because BNDESToken can pause and because there are 
    * additional instructions there.
    * @param cnpj Brazilian identifier to legal entities
    * @param idFinancialSupportAgreement contract number of financial contract with BNDES. It assumes 0 if it is a supplier.
    * @param salic contract number of financial contract with ANCINE. It assumes 0 if it is a supplier.
    * @param newAddr the new address to be associated with the legal entity
    * @param idProofHash The legal entities have to send BNDES a PDF where it assumes as responsible for an Ethereum account. 
    *                   This PDF is signed with eCNPJ and send to BNDES. 
    */
    function changeAccountLegalEntity(uint64 cnpj, uint64 idFinancialSupportAgreement, uint32 salic, 
        address newAddr, string memory idProofHash) onlyTokenAddress public {

        address oldAddr = getBlockchainAccount(cnpj, idFinancialSupportAgreement);
    
        // Tem que haver um endere&#231;o associado a esse cnpj/subcr&#233;dito
        require(!isReservedAccount(oldAddr), "N&#227;o pode trocar endere&#231;o de conta reservada");

        require(!isAvailableAccount(oldAddr), "Tem que haver um endere&#231;o associado a esse cnpj/subcr&#233;dito");

        require(isAvailableAccount(newAddr), "Novo endere&#231;o n&#227;o est&#225; dispon&#237;vel");

        require (isChangeAccountEnabled(oldAddr), "A conta atual n&#227;o est&#225; habilitada para troca");

        require (isValidHash(idProofHash), "O hash da declara&#231;&#227;o &#233; inv&#225;lido");        

        require(legalEntitiesInfo[oldAddr].cnpj==cnpj 
                    && legalEntitiesInfo[oldAddr].idFinancialSupportAgreement ==idFinancialSupportAgreement, 
                    "Dados inconsistentes de cnpj ou subcr&#233;dito");

        // Aponta o novo endere&#231;o para o novo LegalEntityInfo
        legalEntitiesInfo[newAddr] = LegalEntityInfo(cnpj, idFinancialSupportAgreement, salic, idProofHash, BlockchainAccountState.WAITING_VALIDATION);

        // Apaga o mapping do endere&#231;o antigo
        legalEntitiesInfo[oldAddr].state = BlockchainAccountState.INVALIDATED_BY_CHANGE;

        // Aponta mapping CNPJ e Subcredito para newAddr
        cnpjFSAddr[cnpj][idFinancialSupportAgreement] = newAddr;

        emit AccountChange(oldAddr, newAddr, cnpj, idFinancialSupportAgreement, salic, idProofHash); 

    }

   /**
    * Validates the initial registry of a legal entity or the change of its registry
    * @param addr Ethereum address that needs to be validated
    * @param idProofHash The legal entities have to send BNDES a PDF where it assumes as responsible for an Ethereum account. 
    *                   This PDF is signed with eCNPJ and send to BNDES. 
    */
    function validateRegistryLegalEntity(address addr, string memory idProofHash) public {

        require(isResponsibleForRegistryValidation(msg.sender), "Somente o respons&#225;vel pela valida&#231;&#227;o pode validar contas");

        require(legalEntitiesInfo[addr].state == BlockchainAccountState.WAITING_VALIDATION, "A conta precisa estar no estado Aguardando Valida&#231;&#227;o");

        require(keccak256(abi.encodePacked(legalEntitiesInfo[addr].idProofHash)) == keccak256(abi.encodePacked(idProofHash)), "O hash recebido &#233; diferente do esperado");

        legalEntitiesInfo[addr].state = BlockchainAccountState.VALIDATED;

        emit AccountValidation(addr, legalEntitiesInfo[addr].cnpj, 
            legalEntitiesInfo[addr].idFinancialSupportAgreement,
            legalEntitiesInfo[addr].salic);
    }

   /**
    * Invalidates the initial registry of a legal entity or the change of its registry
    * The invalidation can be called at any time in the lifecycle of the address (not only when it is WAITING_VALIDATION)
    * @param addr Ethereum address that needs to be validated
    */
    function invalidateRegistryLegalEntity(address addr) public {

        require(isResponsibleForRegistryValidation(msg.sender), "Somente o respons&#225;vel pela valida&#231;&#227;o pode invalidar contas");

        require(!isReservedAccount(addr), "N&#227;o &#233; poss&#237;vel invalidar conta reservada");

        legalEntitiesInfo[addr].state = BlockchainAccountState.INVALIDATED_BY_VALIDATOR;
        
        emit AccountInvalidation(addr, legalEntitiesInfo[addr].cnpj, 
            legalEntitiesInfo[addr].idFinancialSupportAgreement,
            legalEntitiesInfo[addr].salic);
    }


   /**
    * By default, the owner is also the Responsible for Settlement. 
    * The owner can assign other address to be the Responsible for Settlement. 
    * @param rs Ethereum address to be assigned as Responsible for Settlement.
    */
    function setResponsibleForSettlement(address rs) onlyOwner public {
        responsibleForSettlement = rs;
    }

   /**
    * By default, the owner is also the Responsible for Validation. 
    * The owner can assign other address to be the Responsible for Validation. 
    * @param rs Ethereum address to be assigned as Responsible for Validation.
    */
    function setResponsibleForRegistryValidation(address rs) onlyOwner public {
        responsibleForRegistryValidation = rs;
    }

   /**
    * By default, the owner is also the Responsible for Disbursment. 
    * The owner can assign other address to be the Responsible for Disbursment. 
    * @param rs Ethereum address to be assigned as Responsible for Disbursment.
    */
    function setResponsibleForDisbursement(address rs) onlyOwner public {
        responsibleForDisbursement = rs;
    }

   /**
    * The supplier reedems the BNDESToken by transfering the tokens to a specific address, 
    * called Redemption address. 
    * By default, the redemption address is the address of the owner. 
    * The owner can change the redemption address using this function. 
    * @param rs new Redemption address
    */
    function setRedemptionAddress(address rs) onlyOwner public {
        redemptionAddress = rs;
    }

   /**
    * @param rs Ethereum address to be assigned to the token address.
    */
    function setTokenAddress(address rs) onlyOwner public {
        tokenAddress = rs;
    }

   /**
    * Enable the legal entity to change the account
    * @param rs account that can be changed.
    */
    function enableChangeAccount (address rs) public {
        require(isResponsibleForRegistryValidation(msg.sender), "Somente o respons&#225;vel pela valida&#231;&#227;o pode habilitar a troca de conta");
        legalEntitiesChangeAccount[rs] = true;
    }

    function isChangeAccountEnabled (address rs) view public returns (bool) {
        return legalEntitiesChangeAccount[rs] == true;
    }    

    function isTokenAddress() public view returns (bool) {
        return tokenAddress == msg.sender;
    } 
    function isResponsibleForSettlement(address addr) view public returns (bool) {
        return (addr == responsibleForSettlement);
    }
    function isResponsibleForRegistryValidation(address addr) view public returns (bool) {
        return (addr == responsibleForRegistryValidation);
    }
    function isResponsibleForDisbursement(address addr) view public returns (bool) {
        return (addr == responsibleForDisbursement);
    }
    function isRedemptionAddress(address addr) view public returns (bool) {
        return (addr == redemptionAddress);
    }

    function isReservedAccount(address addr) view public returns (bool) {

        if (isOwner(addr) || isResponsibleForSettlement(addr) 
                           || isResponsibleForRegistryValidation(addr)
                           || isResponsibleForDisbursement(addr)
                           || isRedemptionAddress(addr) ) {
            return true;
        }
        return false;
    }
    function isOwner(address addr) view public returns (bool) {
        return owner()==addr;
    }

    function isSupplier(address addr) view public returns (bool) {

        if (isReservedAccount(addr))
            return false;

        if (isAvailableAccount(addr))
            return false;

        return legalEntitiesInfo[addr].idFinancialSupportAgreement == 0;
    }

    function isValidatedSupplier (address addr) view public returns (bool) {
        return isSupplier(addr) && (legalEntitiesInfo[addr].state == BlockchainAccountState.VALIDATED);
    }

    function isClient (address addr) view public returns (bool) {
        if (isReservedAccount(addr)) {
            return false;
        }
        return legalEntitiesInfo[addr].idFinancialSupportAgreement != 0;
    }

    function isValidatedClient (address addr) view public returns (bool) {
        return isClient(addr) && (legalEntitiesInfo[addr].state == BlockchainAccountState.VALIDATED);
    }

    function isAvailableAccount(address addr) view public returns (bool) {
        if ( isReservedAccount(addr) ) {
            return false;
        } 
        return legalEntitiesInfo[addr].state == BlockchainAccountState.AVAILABLE;
    }

    function isWaitingValidationAccount(address addr) view public returns (bool) {
        return legalEntitiesInfo[addr].state == BlockchainAccountState.WAITING_VALIDATION;
    }

    function isValidatedAccount(address addr) view public returns (bool) {
        return legalEntitiesInfo[addr].state == BlockchainAccountState.VALIDATED;
    }

    function isInvalidatedByValidatorAccount(address addr) view public returns (bool) {
        return legalEntitiesInfo[addr].state == BlockchainAccountState.INVALIDATED_BY_VALIDATOR;
    }

    function isInvalidatedByChangeAccount(address addr) view public returns (bool) {
        return legalEntitiesInfo[addr].state == BlockchainAccountState.INVALIDATED_BY_CHANGE;
    }

    function getResponsibleForSettlement() view public returns (address) {
        return responsibleForSettlement;
    }
    function getResponsibleForRegistryValidation() view public returns (address) {
        return responsibleForRegistryValidation;
    }
    function getResponsibleForDisbursement() view public returns (address) {
        return responsibleForDisbursement;
    }
    function getRedemptionAddress() view public returns (address) {
        return redemptionAddress;
    }
    function getCNPJ(address addr) view public returns (uint64) {
        return legalEntitiesInfo[addr].cnpj;
    }

    function getIdLegalFinancialAgreement(address addr) view public returns (uint64) {
        return legalEntitiesInfo[addr].idFinancialSupportAgreement;
    }

    function getLegalEntityInfo (address addr) view public returns (uint64, uint64, uint32, string memory, uint, address) {
        return (legalEntitiesInfo[addr].cnpj, legalEntitiesInfo[addr].idFinancialSupportAgreement, 
             legalEntitiesInfo[addr].salic, legalEntitiesInfo[addr].idProofHash, (uint) (legalEntitiesInfo[addr].state),
             addr);
    }

    function getBlockchainAccount(uint64 cnpj, uint64 idFinancialSupportAgreement) view public returns (address) {
        return cnpjFSAddr[cnpj][idFinancialSupportAgreement];
    }

    function getLegalEntityInfoByCNPJ (uint64 cnpj, uint64 idFinancialSupportAgreement) 
        view public returns (uint64, uint64, uint32, string memory, uint, address) {
        
        address addr = getBlockchainAccount(cnpj,idFinancialSupportAgreement);
        return getLegalEntityInfo (addr);
    }

    function getAccountState(address addr) view public returns (int) {

        if ( isReservedAccount(addr) ) {
            return 100;
        } 
        else {
            return ((int) (legalEntitiesInfo[addr].state));
        }

    }


  function isValidHash(string memory str) pure public returns (bool)  {

    bytes memory b = bytes(str);
    if(b.length != 64) return false;

    for (uint i=0; i<64; i++) {
        if (b[i] < "0") return false;
        if (b[i] > "9" && b[i] <"a") return false;
        if (b[i] > "f") return false;
    }
        
    return true;
 }


}


contract BNDESToken is ERC20Pausable, ERC20Detailed("BNDESToken", "BND", 2) {

    uint private version = 20190517;

    BNDESRegistry registry;

    event BNDESTokenDisbursement(uint64 cnpj, uint64 idFinancialSupportAgreement, uint256 value);
    event BNDESTokenTransfer(uint64 fromCnpj, uint64 fromIdFinancialSupportAgreement, uint64 toCnpj, uint256 value);
    event BNDESTokenRedemption(uint64 cnpj, uint256 value);
    event BNDESTokenRedemptionSettlement(string redemptionTransactionHash, string receiptHash);
    event BNDESManualIntervention(string description);

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    constructor (address newRegistryAddr) public {
        registry = BNDESRegistry(newRegistryAddr);
    }


    function getVersion() view public returns (uint) {
        return version;
    }


   /**
    * The transfer funcion follows ERC20 token signature. 
    * Using them, it is possible to disburse money to the client, transfer from client to supplier and redeem.
    * @param to the Ethereum address to where the money should be sent
    * @param value how much BNDESToken the supplier wants to redeem
    */
    function transfer (address to, uint256 value) public whenNotPaused returns (bool) {

        address from = msg.sender;

        require(from != to, "N&#227;o pode transferir token para si mesmo");

        if (registry.isResponsibleForDisbursement(from)) {

            require(registry.isValidatedClient(to), "O endere&#231;o n&#227;o pertence a um cliente ou n&#227;o est&#225; validada");

            _mint(to, value);

            emit BNDESTokenDisbursement(registry.getCNPJ(to), registry.getIdLegalFinancialAgreement(to), value);

        } else { 

            if (registry.isRedemptionAddress(to)) { 

                require(registry.isValidatedSupplier(from), "A conta do endere&#231;o n&#227;o pertence a um fornecedor ou n&#227;o est&#225; validada");

                _burn(from, value);

                emit BNDESTokenRedemption(registry.getCNPJ(from), value);

            } else {

                // Se nem from nem to s&#227;o o Banco, eh transferencia normal

                require(registry.isValidatedClient(from), "O endere&#231;o n&#227;o pertence a um cliente ou n&#227;o est&#225; validada");
                require(registry.isValidatedSupplier(to), "A conta do endere&#231;o n&#227;o pertence a um fornecedor ou n&#227;o est&#225; validada");

                _transfer(msg.sender, to, value);

                emit BNDESTokenTransfer(registry.getCNPJ(from), registry.getIdLegalFinancialAgreement(from), 
                                registry.getCNPJ(to), value);
  
            }
        }

        return true;
    }

   /**
    * When redeeming, the supplier indicated to the Resposible for Settlement that he wants to receive 
    * the FIAT money.
    * @param value - how much BNDESToken the supplier wants to redeem
    */
    function redeem (uint256 value) public whenNotPaused returns (bool) {
        return transfer(registry.getRedemptionAddress(), value);
    }

   /**
    * Using this function, the Responsible for Settlement indicates that he has made the FIAT money transfer.
    * @param redemptionTransactionHash hash of the redeem transaction in which the FIAT money settlement occurred.
    * @param receiptHash hash that proof the FIAT money transfer
    */
    function notifyRedemptionSettlement(string memory redemptionTransactionHash, string memory receiptHash) 
        public whenNotPaused {
        require (registry.isResponsibleForSettlement(msg.sender), "A liquida&#231;&#227;o s&#243; n&#227;o pode ser realizada pelo endere&#231;o que submeteu a transa&#231;&#227;o"); 
        require (registry.isValidHash(receiptHash), "O hash do recibo &#233; inv&#225;lido");
        emit BNDESTokenRedemptionSettlement(redemptionTransactionHash, receiptHash);
    }


    function registryLegalEntity(uint64 cnpj, uint64 idFinancialSupportAgreement, uint32 salic, string memory idProofHash) 
        public whenNotPaused { 
        registry.registryLegalEntity(cnpj,  idFinancialSupportAgreement, salic, msg.sender, idProofHash);
    }

   /**
    * Changes the original link between CNPJ and Ethereum account. 
    * The new link still needs to be validated by BNDES.
    * IMPORTANT: The BNDESTOKENs are transfered from the original to the new Ethereum address 
    * @param cnpj Brazilian identifier to legal entities
    * @param idFinancialSupportAgreement contract number of financial contract with BNDES. It assumes 0 if it is a supplier.
    * @param salic contract number of financial contract with ANCINE. It assumes 0 if it is a supplier.
    * @param idProofHash The legal entities have to send BNDES a PDF where it assumes as responsible for an Ethereum account. 
    *                   This PDF is signed with eCNPJ and send to BNDES. 
    */
    function changeAccountLegalEntity(uint64 cnpj, uint64 idFinancialSupportAgreement, uint32 salic, string memory idProofHash) 
        public whenNotPaused {
        
        address oldAddr = registry.getBlockchainAccount(cnpj, idFinancialSupportAgreement);
        address newAddr = msg.sender;
        
        registry.changeAccountLegalEntity(cnpj, idFinancialSupportAgreement, salic, msg.sender, idProofHash);

        // Se h&#225; saldo no enderecoAntigo, precisa transferir
        if (balanceOf(oldAddr) > 0) {
            _transfer(oldAddr, newAddr, balanceOf(oldAddr));
        }

    }

    //These methods may be necessary to solve incidents.
    function burn(address from, uint256 value, string memory description) public onlyOwner {
        _burn(from, value);
        emit BNDESManualIntervention(description);        
    }

    //These methods may be necessary to solve incidents.
    function mint(address to, uint256 value, string memory description) public onlyOwner {
        _mint(to, value);
        emit BNDESManualIntervention(description);        
    }

    function isOwner() public view returns (bool) {
        return registry.owner() == msg.sender;
    } 

    //Unsupported methods - created to avoid call the lib functions by overriding them
    function transferFrom(address from, address to, uint256 value) public whenNotPaused returns (bool) {
        require(false, "Unsupported method - transferFrom");
    }

    //Unsupported methods - created to avoid call the lib functions by overriding them
    function approve(address spender, uint256 value) public whenNotPaused returns (bool) {
        require(false, "Unsupported method - approve");
    }

    //Unsupported methods - created to avoid call the lib functions by overriding them
    function increaseAllowance(address spender, uint addedValue) public whenNotPaused returns (bool success) {
        require(false, "Unsupported method - increaseAllowance");
    }

    //Unsupported methods - created to avoid call the lib functions by overriding them
    function decreaseAllowance(address spender, uint subtractedValue) public whenNotPaused returns (bool success) {
        require(false, "Unsupported method - decreaseAllowance");
    }



}