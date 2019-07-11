/**
 *Submitted for verification at Etherscan.io on 2019-07-08
*/

pragma solidity ^0.5.0;

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