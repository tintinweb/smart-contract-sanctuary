pragma solidity ^0.4.19;

contract Engine {
    uint256 public VERSION;
    string public VERSION_NAME;

    enum Status { initial, lent, paid, destroyed }
    struct Approbation {
        bool approved;
        bytes data;
        bytes32 checksum;
    }

    function getTotalLoans() public view returns (uint256);
    function getOracle(uint index) public view returns (Oracle);
    function getBorrower(uint index) public view returns (address);
    function getCosigner(uint index) public view returns (address);
    function ownerOf(uint256) public view returns (address owner);
    function getCreator(uint index) public view returns (address);
    function getAmount(uint index) public view returns (uint256);
    function getPaid(uint index) public view returns (uint256);
    function getDueTime(uint index) public view returns (uint256);
    function getApprobation(uint index, address _address) public view returns (bool);
    function getStatus(uint index) public view returns (Status);
    function isApproved(uint index) public view returns (bool);
    function getPendingAmount(uint index) public returns (uint256);
    function getCurrency(uint index) public view returns (bytes32);
    function cosign(uint index, uint256 cost) external returns (bool);
    function approveLoan(uint index) public returns (bool);
    function transfer(address to, uint256 index) public returns (bool);
    function takeOwnership(uint256 index) public returns (bool);
    function withdrawal(uint index, address to, uint256 amount) public returns (bool);
}

/**
    @dev Defines the interface of a standard RCN cosigner.

    The cosigner is an agent that gives an insurance to the lender in the event of a defaulted loan, the confitions
    of the insurance and the cost of the given are defined by the cosigner. 

    The lender will decide what cosigner to use, if any; the address of the cosigner and the valid data provided by the
    agent should be passed as params when the lender calls the "lend" method on the engine.
    
    When the default conditions defined by the cosigner aligns with the status of the loan, the lender of the engine
    should be able to call the "claim" method to receive the benefit; the cosigner can define aditional requirements to
    call this method, like the transfer of the ownership of the loan.
*/
contract Cosigner {
    uint256 public constant VERSION = 2;
    
    /**
        @return the url of the endpoint that exposes the insurance offers.
    */
    function url() public view returns (string);
    
    /**
        @dev Retrieves the cost of a given insurance, this amount should be exact.

        @return the cost of the cosign, in RCN wei
    */
    function cost(address engine, uint256 index, bytes data, bytes oracleData) public view returns (uint256);
    
    /**
        @dev The engine calls this method for confirmation of the conditions, if the cosigner accepts the liability of
        the insurance it must call the method "cosign" of the engine. If the cosigner does not call that method, or
        does not return true to this method, the operation fails.

        @return true if the cosigner accepts the liability
    */
    function requestCosign(Engine engine, uint256 index, bytes data, bytes oracleData) public returns (bool);
    
    /**
        @dev Claims the benefit of the insurance if the loan is defaulted, this method should be only calleable by the
        current lender of the loan.

        @return true if the claim was done correctly.
    */
    function claim(address engine, uint256 index, bytes oracleData) public returns (bool);
}

contract ERC721 {
   // ERC20 compatible functions
   function name() public view returns (string _name);
   function symbol() public view returns (string _symbol);
   function totalSupply() public view returns (uint256 _totalSupply);
   function balanceOf(address _owner) public view returns (uint _balance);
   // Functions that define ownership
   function ownerOf(uint256) public view returns (address owner);
   function approve(address, uint256) public returns (bool);
   function takeOwnership(uint256) public returns (bool);
   function transfer(address, uint256) public returns (bool);
   function setApprovalForAll(address _operator, bool _approved) public returns (bool);
   function getApproved(uint256 _tokenId) public view returns (address);
   function isApprovedForAll(address _owner, address _operator) public view returns (bool);
   // Token metadata
   function tokenMetadata(uint256 _tokenId) public view returns (string info);
   // Events
   event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
   event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
   event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
}

contract Token {
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function increaseApproval (address _spender, uint _addedValue) public returns (bool success);
    function balanceOf(address _owner) public view returns (uint256 balance);
}

contract Ownable {
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function Ownable() public {
        owner = msg.sender; 
    }

    /**
        @dev Transfers the ownership of the contract.

        @param _to Address of the new owner
    */
    function transferTo(address _to) public onlyOwner returns (bool) {
        require(_to != address(0));
        owner = _to;
        return true;
    } 
} 

/**
    @dev Defines the interface of a standard RCN oracle.

    The oracle is an agent in the RCN network that supplies a convertion rate between RCN and any other currency,
    it&#39;s primarily used by the exchange but could be used by any other agent.
*/
contract Oracle is Ownable {
    uint256 public constant VERSION = 3;

    event NewSymbol(bytes32 _currency, string _ticker);
    
    struct Symbol {
        string ticker;
        bool supported;
    }

    mapping(bytes32 => Symbol) public currencies;

    /**
        @dev Returns the url where the oracle exposes a valid "oracleData" if needed
    */
    function url() public view returns (string);

    /**
        @dev Returns a valid convertion rate from the currency given to RCN

        @param symbol Symbol of the currency
        @param data Generic data field, could be used for off-chain signing
    */
    function getRate(bytes32 symbol, bytes data) public returns (uint256 rate, uint256 decimals);

    /**
        @dev Adds a currency to the oracle, once added it cannot be removed

        @param ticker Symbol of the currency

        @return the hash of the currency, calculated keccak256(ticker)
    */
    function addCurrency(string ticker) public onlyOwner returns (bytes32) {
        NewSymbol(currency, ticker);
        bytes32 currency = keccak256(ticker);
        currencies[currency] = Symbol(ticker, true);
        return currency;
    }

    /**
        @return true If the currency is supported
    */
    function supported(bytes32 symbol) public view returns (bool) {
        return currencies[symbol].supported;
    }
}

contract RpSafeMath {
    function safeAdd(uint256 x, uint256 y) internal pure returns(uint256) {
      uint256 z = x + y;
      require((z >= x) && (z >= y));
      return z;
    }

    function safeSubtract(uint256 x, uint256 y) internal pure returns(uint256) {
      require(x >= y);
      uint256 z = x - y;
      return z;
    }

    function safeMult(uint256 x, uint256 y) internal pure returns(uint256) {
      uint256 z = x * y;
      require((x == 0)||(z/x == y));
      return z;
    }

    function min(uint256 a, uint256 b) internal pure returns(uint256) {
        if (a < b) { 
          return a;
        } else { 
          return b; 
        }
    }
    
    function max(uint256 a, uint256 b) internal pure returns(uint256) {
        if (a > b) { 
          return a;
        } else { 
          return b; 
        }
    }
}

contract TokenLockable is RpSafeMath, Ownable {
    mapping(address => uint256) public lockedTokens;

    /**
        @dev Locked tokens cannot be withdrawn using the withdrawTokens function.
    */
    function lockTokens(address token, uint256 amount) internal {
        lockedTokens[token] = safeAdd(lockedTokens[token], amount);
    }

    /**
        @dev Unlocks previusly locked tokens.
    */
    function unlockTokens(address token, uint256 amount) internal {
        lockedTokens[token] = safeSubtract(lockedTokens[token], amount);
    }

    /**
        @dev Withdraws tokens from the contract.

        @param token Token to withdraw
        @param to Destination of the tokens
        @param amount Amount to withdraw 
    */
    function withdrawTokens(Token token, address to, uint256 amount) public onlyOwner returns (bool) {
        require(safeSubtract(token.balanceOf(this), lockedTokens[token]) >= amount);
        require(to != address(0));
        return token.transfer(to, amount);
    }
}

contract NanoLoanEngine is ERC721, Engine, Ownable, TokenLockable {
    uint256 constant internal PRECISION = (10**18);
    uint256 constant internal RCN_DECIMALS = 18;

    uint256 public constant VERSION = 232;
    string public constant VERSION_NAME = "Basalt";

    uint256 private activeLoans = 0;
    mapping(address => uint256) private lendersBalance;

    function name() public view returns (string _name) {
        _name = "RCN - Nano loan engine - Basalt 232";
    }

    function symbol() public view returns (string _symbol) {
        _symbol = "RCN-NLE-232";
    }

    /**
        @notice Returns the number of active loans in total, active loans are the loans with "lent" status.
        @dev Required for ERC-721 compliance

        @return _totalSupply Total amount of loans
    */
    function totalSupply() public view returns (uint _totalSupply) {
        _totalSupply = activeLoans;
    }

    /**
        @notice Returns the number of active loans that a lender possess; active loans are the loans with "lent" status.
        @dev Required for ERC-721 compliance

        @param _owner The owner address to search
        
        @return _balance Amount of loans  
    */
    function balanceOf(address _owner) public view returns (uint _balance) {
        _balance = lendersBalance[_owner];
    }

    /**
        @notice Returns all the loans that a lender possess
        @dev This method MUST NEVER be called by smart contract code; 
            it walks the entire loans array, and will probably create a transaction bigger than the gas limit.

        @param _owner The owner address

        @return ownerTokens List of all the loans of the _owner
    */
    function tokensOfOwner(address _owner) external view returns(uint256[] ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalLoans = loans.length - 1;
            uint256 resultIndex = 0;

            uint256 loanId;

            for (loanId = 0; loanId <= totalLoans; loanId++) {
                if (loans[loanId].lender == _owner && loans[loanId].status == Status.lent) {
                    result[resultIndex] = loanId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

    /**
        @notice Returns true if the _operator can transfer the loans of the _owner

        @dev Required for ERC-721 compliance 
    */
    function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
        return operators[_owner][_operator];
    }

    /**
        @notice Returns the loan metadata, this field can be set by the creator of the loan with his own criteria.

        @param index Index of the loan

        @return The string with the metadata
    */
    function tokenMetadata(uint256 index) public view returns (string) {
        return loans[index].metadata;
    }

    /**
        @notice Returns the loan metadata, hashed with keccak256.
        @dev This emthod is useful to evaluate metadata from a smart contract.

        @param index Index of the loan

        @return The metadata hashed with keccak256
    */
    function tokenMetadataHash(uint256 index) public view returns (bytes32) {
        return keccak256(loans[index].metadata);
    }

    Token public rcn;
    bool public deprecated;

    event CreatedLoan(uint _index, address _borrower, address _creator);
    event ApprovedBy(uint _index, address _address);
    event Lent(uint _index, address _lender, address _cosigner);
    event DestroyedBy(uint _index, address _address);
    event PartialPayment(uint _index, address _sender, address _from, uint256 _amount);
    event TotalPayment(uint _index);

    function NanoLoanEngine(Token _rcn) public {
        owner = msg.sender;
        rcn = _rcn;
        // The loan 0 is a Invalid loan
        loans.length++;
    }

    struct Loan {
        Status status;
        Oracle oracle;

        address borrower;
        address lender;
        address creator;
        address cosigner;
        
        uint256 amount;
        uint256 interest;
        uint256 punitoryInterest;
        uint256 interestTimestamp;
        uint256 paid;
        uint256 interestRate;
        uint256 interestRatePunitory;
        uint256 dueTime;
        uint256 duesIn;

        bytes32 currency;
        uint256 cancelableAt;
        uint256 lenderBalance;

        address approvedTransfer;
        uint256 expirationRequest;

        string metadata;
        mapping(address => bool) approbations;
    }

    mapping(address => mapping(address => bool)) private operators;

    mapping(bytes32 => uint256) public identifierToIndex;
    Loan[] private loans;

    /**
        @notice Creates a loan request, the loan can be generated with any borrower and conditions; if the borrower agrees
        it must call the "approve" function. If the creator of the loan is the borrower the approve is done automatically.

        @dev The creator of the loan is the caller of this function; this is useful to track which wallet created the loan.
            Two identical loans cannot exist, a clone of another loan will fail.

        @param _oracleContract Address of the Oracle contract, if the loan does not use any oracle, this field should be 0x0.
        @param _borrower Address of the borrower
        @param _currency The currency to use with the oracle, the currency code is generated with the following formula,
            keccak256(ticker), is always stored as the minimum divisible amount. (Ej: ETH Wei, USD Cents)
        @param _amount The requested amount; currency and unit are defined by the Oracle, if there is no Oracle present
            the currency is RCN, and the unit is wei.
        @param _interestRate The non-punitory interest rate by second, defined as a denominator of 10 000 000.
        @param _interestRatePunitory The punitory interest rate by second, defined as a denominator of 10 000 000.
            Ej: interestRate 11108571428571 = 28% Anual interest
        @param _duesIn The time in seconds that the borrower has in order to pay the debt after the lender lends the money.
        @param _cancelableAt Delta in seconds specifying how much interest should be added in advance, if the borrower pays 
        entirely or partially the loan before this term, no extra interest will be deducted.
        @param _expirationRequest Timestamp of when the loan request expires, if the loan is not filled before this date, 
            the request is no longer valid.
        @param _metadata String with loan metadata.
    */
    function createLoan(Oracle _oracleContract, address _borrower, bytes32 _currency, uint256 _amount, uint256 _interestRate,
        uint256 _interestRatePunitory, uint256 _duesIn, uint256 _cancelableAt, uint256 _expirationRequest, string _metadata) public returns (uint256) {

        require(!deprecated);
        require(_cancelableAt <= _duesIn);
        require(_oracleContract != address(0) || _currency == 0x0);
        require(_borrower != address(0));
        require(_amount != 0);
        require(_interestRatePunitory != 0);
        require(_interestRate != 0);
        require(_expirationRequest > block.timestamp);

        var loan = Loan(Status.initial, _oracleContract, _borrower, 0x0, msg.sender, 0x0, _amount, 0, 0, 0, 0, _interestRate,
            _interestRatePunitory, 0, _duesIn, _currency, _cancelableAt, 0, 0x0, _expirationRequest, _metadata);

        uint index = loans.push(loan) - 1;
        CreatedLoan(index, _borrower, msg.sender);

        bytes32 identifier = getIdentifier(index);
        require(identifierToIndex[identifier] == 0);
        identifierToIndex[identifier] = index;

        if (msg.sender == _borrower) {
            approveLoan(index);
        }

        return index;
    }
    
    function ownerOf(uint256 index) public view returns (address owner) { owner = loans[index].lender; }
    function getTotalLoans() public view returns (uint256) { return loans.length; }
    function getOracle(uint index) public view returns (Oracle) { return loans[index].oracle; }
    function getBorrower(uint index) public view returns (address) { return loans[index].borrower; }
    function getCosigner(uint index) public view returns (address) { return loans[index].cosigner; }
    function getCreator(uint index) public view returns (address) { return loans[index].creator; }
    function getAmount(uint index) public view returns (uint256) { return loans[index].amount; }
    function getPunitoryInterest(uint index) public view returns (uint256) { return loans[index].punitoryInterest; }
    function getInterestTimestamp(uint index) public view returns (uint256) { return loans[index].interestTimestamp; }
    function getPaid(uint index) public view returns (uint256) { return loans[index].paid; }
    function getInterestRate(uint index) public view returns (uint256) { return loans[index].interestRate; }
    function getInterestRatePunitory(uint index) public view returns (uint256) { return loans[index].interestRatePunitory; }
    function getDueTime(uint index) public view returns (uint256) { return loans[index].dueTime; }
    function getDuesIn(uint index) public view returns (uint256) { return loans[index].duesIn; }
    function getCancelableAt(uint index) public view returns (uint256) { return loans[index].cancelableAt; }
    function getApprobation(uint index, address _address) public view returns (bool) { return loans[index].approbations[_address]; }
    function getStatus(uint index) public view returns (Status) { return loans[index].status; }
    function getLenderBalance(uint index) public view returns (uint256) { return loans[index].lenderBalance; }
    function getApproved(uint index) public view returns (address) {return loans[index].approvedTransfer; }
    function getCurrency(uint index) public view returns (bytes32) { return loans[index].currency; }
    function getExpirationRequest(uint index) public view returns (uint256) { return loans[index].expirationRequest; }
    function getInterest(uint index) public view returns (uint256) { return loans[index].interest; }

    function getIdentifier(uint index) public view returns (bytes32) {
        Loan memory loan = loans[index];
        return buildIdentifier(loan.oracle, loan.borrower, loan.creator, loan.currency, loan.amount, loan.interestRate,
            loan.interestRatePunitory, loan.duesIn, loan.cancelableAt, loan.expirationRequest, loan.metadata);
    }

    /**
        @notice Used to reference a loan that is not yet created, and by that does not have an index

        @dev Two identical loans cannot exist, only one loan per signature is allowed

        @return The signature hash of the loan configuration
    */
    function buildIdentifier(Oracle oracle, address borrower, address creator, bytes32 currency, uint256 amount, uint256 interestRate,
        uint256 interestRatePunitory, uint256 duesIn, uint256 cancelableAt, uint256 expirationRequest, string metadata) view returns (bytes32) {
        return keccak256(this, oracle, borrower, creator, currency, amount, interestRate, interestRatePunitory, duesIn,
                        cancelableAt, expirationRequest, metadata); 
    }

    /**
        @notice Used to know if a loan is ready to lend

        @param index Index of the loan

        @return true if the loan has been approved by the borrower and cosigner.
    */
    function isApproved(uint index) public view returns (bool) {
        Loan storage loan = loans[index];
        return loan.approbations[loan.borrower];
    }

    /**
        @notice Called by the members of the loan to show that they agree with the terms of the loan; the borrower
        must call this method before any lender could call the method "lend".
            
        @dev Any address can call this method to be added to the "approbations" mapping.

        @param index Index of the loan

        @return true if the approve was done successfully
    */
    function approveLoan(uint index) public returns(bool) {
        Loan storage loan = loans[index];
        require(loan.status == Status.initial);
        loan.approbations[msg.sender] = true;
        ApprovedBy(index, msg.sender);
        return true;
    }

    /**
        @notice Approves a loan using the Identifier and not the index

        @param identifier Identifier of the loan

        @return true if the approve was done successfully
    */
    function approveLoanIdentifier(bytes32 identifier) public returns (bool) {
        uint256 index = identifierToIndex[identifier];
        require(index != 0);
        return approveLoan(index);
    }

    /**
        @notice Register an approvation made by a borrower in the past

        @dev The loan should exist and have an index

        @param identifier Identifier of the loan

        @return true if the approve was done successfully
    */
    function registerApprove(bytes32 identifier, uint8 v, bytes32 r, bytes32 s) public returns (bool) {
        uint256 index = identifierToIndex[identifier];
        require(index != 0);
        Loan storage loan = loans[index];
        require(loan.borrower == ecrecover(keccak256("\x19Ethereum Signed Message:\n32", identifier), v, r, s));
        loan.approbations[loan.borrower] = true;
        ApprovedBy(index, loan.borrower);
        return true;
    }

    /**
        @notice Performs the lend of the RCN equivalent to the requested amount, and transforms the msg.sender in the new lender.

        @dev The loan must be previously approved by the borrower; before calling this function, the lender candidate must 
        call the "approve" function on the RCN Token, specifying an amount sufficient enough to pay the equivalent of
        the requested amount, and the cosigner fee.
        
        @param index Index of the loan
        @param oracleData Data required by the oracle to return the rate, the content of this field must be provided
            by the url exposed in the url() method of the oracle.
        @param cosigner Address of the cosigner, 0x0 for lending without cosigner.
        @param cosignerData Data required by the cosigner to process the request.

        @return true if the lend was done successfully
    */
    function lend(uint index, bytes oracleData, Cosigner cosigner, bytes cosignerData) public returns (bool) {
        Loan storage loan = loans[index];

        require(loan.status == Status.initial);
        require(isApproved(index));
        require(block.timestamp <= loan.expirationRequest);

        loan.lender = msg.sender;
        loan.dueTime = safeAdd(block.timestamp, loan.duesIn);
        loan.interestTimestamp = block.timestamp;
        loan.status = Status.lent;

        // ERC721, create new loan and transfer it to the lender
        Transfer(0x0, loan.lender, index);
        activeLoans += 1;
        lendersBalance[loan.lender] += 1;
        
        if (loan.cancelableAt > 0)
            internalAddInterest(loan, safeAdd(block.timestamp, loan.cancelableAt));

        // Transfer the money to the borrower before handling the cosigner
        // so the cosigner could require a specific usage for that money.
        uint256 transferValue = convertRate(loan.oracle, loan.currency, oracleData, loan.amount);
        require(rcn.transferFrom(msg.sender, loan.borrower, transferValue));
        
        if (cosigner != address(0)) {
            // The cosigner it&#39;s temporary set to the next address (cosigner + 2), it&#39;s expected that the cosigner will
            // call the method "cosign" to accept the conditions; that method also sets the cosigner to the right
            // address. If that does not happen, the transaction fails.
            loan.cosigner = address(uint256(cosigner) + 2);
            require(cosigner.requestCosign(this, index, cosignerData, oracleData));
            require(loan.cosigner == address(cosigner));
        }
                
        Lent(index, loan.lender, cosigner);

        return true;
    }

    /**
        @notice The cosigner must call this method to accept the conditions of a loan, this method pays the cosigner his fee.
        
        @dev If the cosigner does not call this method the whole "lend" call fails.

        @param index Index of the loan
        @param cost Fee set by the cosigner

        @return true If the cosign was successfull
    */
    function cosign(uint index, uint256 cost) external returns (bool) {
        Loan storage loan = loans[index];
        require(loan.status == Status.lent && (loan.dueTime - loan.duesIn) == block.timestamp);
        require(loan.cosigner != address(0));
        require(loan.cosigner == address(uint256(msg.sender) + 2));
        loan.cosigner = msg.sender;
        require(rcn.transferFrom(loan.lender, msg.sender, cost));
        return true;
    }

    /**
        @notice Destroys a loan, the borrower could call this method if they performed an accidental or regretted 
        "approve" of the loan, this method only works for them if the loan is in "pending" status.

        The lender can call this method at any moment, in case of a loan with status "lent" the lender is pardoning 
        the debt. 

        @param index Index of the loan

        @return true if the destroy was done successfully
    */
    function destroy(uint index) public returns (bool) {
        Loan storage loan = loans[index];
        require(loan.status != Status.destroyed);
        require(msg.sender == loan.lender || (msg.sender == loan.borrower && loan.status == Status.initial));
        DestroyedBy(index, msg.sender);

        // ERC721, remove loan from circulation
        if (loan.status != Status.initial) {
            lendersBalance[loan.lender] -= 1;
            activeLoans -= 1;
            Transfer(loan.lender, 0x0, index);
        }

        loan.status = Status.destroyed;
        return true;
    }

    /**
        @notice Destroys a loan using the signature and not the Index

        @param identifier Identifier of the loan

        @return true if the destroy was done successfully
    */
    function destroyIdentifier(bytes32 identifier) public returns (bool) {
        uint256 index = identifierToIndex[identifier];
        require(index != 0);
        return destroy(index);
    }

    /**
        @notice Transfers a loan to a different lender, the caller must be the current lender or previously being
        approved with the method "approveTransfer"; only loans with the Status.lent status can be transfered.

        @dev Required for ERC-721 compliance

        @param index Index of the loan
        @param to New lender

        @return true if the transfer was done successfully
    */
    function transfer(address to, uint256 index) public returns (bool) {
        Loan storage loan = loans[index];
        
        require(msg.sender == loan.lender || msg.sender == loan.approvedTransfer || operators[loan.lender][msg.sender]);
        require(to != address(0));
        loan.lender = to;
        loan.approvedTransfer = address(0);

        // ERC721, transfer loan to another address
        lendersBalance[msg.sender] -= 1;
        lendersBalance[to] += 1;
        Transfer(loan.lender, to, index);

        return true;
    }

    /**
        @notice Transfers the loan to the msg.sender, the msg.sender must be approved using the "approve" method.

        @dev Required for ERC-721 compliance

        @param _index Index of the loan

        @return true if the transfer was successfull
    */
    function takeOwnership(uint256 _index) public returns (bool) {
        return transfer(msg.sender, _index);
    }

    /**
        @notice Transfers the loan to an address, only if the current owner is the "from" address

        @dev Required for ERC-721 compliance

        @param from Current owner of the loan
        @param to New owner of the loan
        @param index Index of the loan

        @return true if the transfer was successfull
    */
    function transferFrom(address from, address to, uint256 index) public returns (bool) {
        require(loans[index].lender == from);
        return transfer(to, index);
    }

    /**
        @notice Approves the transfer of a given loan in the name of the lender, the behavior of this function is similar to
        "approve" in the ERC20 standard, but only one approved address is allowed at a time.

        The same method can be called passing 0x0 as parameter "to" to erase a previously approved address.

        @dev Required for ERC-721 compliance

        @param to Address allowed to transfer the loan or 0x0 to delete
        @param index Index of the loan

        @return true if the approve was done successfully
    */
    function approve(address to, uint256 index) public returns (bool) {
        Loan storage loan = loans[index];
        require(msg.sender == loan.lender);
        loan.approvedTransfer = to;
        Approval(msg.sender, to, index);
        return true;
    }

    /**
        @notice Enable or disable approval for a third party ("operator") to manage

        @param _approved True if the operator is approved, false to revoke approval
        @param _operator Address to add to the set of authorized operators.
    */
    function setApprovalForAll(address _operator, bool _approved) public returns (bool) {
        operators[msg.sender][_operator] = _approved;
        ApprovalForAll(msg.sender, _operator, _approved);
        return true;
    }

    /**
        @notice Returns the pending amount to complete de payment of the loan, keep in mind that this number increases 
        every second.

        @dev This method also computes the interest and updates the loan

        @param index Index of the loan

        @return Aprox pending payment amount
    */
    function getPendingAmount(uint index) public returns (uint256) {
        addInterest(index);
        return getRawPendingAmount(index);
    }

    /**
        @notice Returns the pending amount up to the last time of the interest update. This is not the real pending amount

        @dev This method is exact only if "addInterest(loan)" was before and in the same block.

        @param index Index of the loan

        @return The past pending amount
    */
    function getRawPendingAmount(uint index) public view returns (uint256) {
        Loan memory loan = loans[index];
        return safeSubtract(safeAdd(safeAdd(loan.amount, loan.interest), loan.punitoryInterest), loan.paid);
    }

    /**
        @notice Calculates the interest of a given amount, interest rate and delta time.

        @param timeDelta Elapsed time
        @param interestRate Interest rate expressed as the denominator of 10 000 000.
        @param amount Amount to apply interest

        @return realDelta The real timeDelta applied
        @return interest The interest gained in the realDelta time
    */
    function calculateInterest(uint256 timeDelta, uint256 interestRate, uint256 amount) internal pure returns (uint256 realDelta, uint256 interest) {
        if (amount == 0) {
            interest = 0;
            realDelta = timeDelta;
        } else {
            interest = safeMult(safeMult(100000, amount), timeDelta) / interestRate;
            realDelta = safeMult(interest, interestRate) / (amount * 100000);
        }
    }

    /**
        @notice Computes loan interest

        Computes the punitory and non-punitory interest of a given loan and only applies the change.
        
        @param loan Loan to compute interest
        @param timestamp Target absolute unix time to calculate interest.
    */
    function internalAddInterest(Loan storage loan, uint256 timestamp) internal {
        if (timestamp > loan.interestTimestamp) {
            uint256 newInterest = loan.interest;
            uint256 newPunitoryInterest = loan.punitoryInterest;

            uint256 newTimestamp;
            uint256 realDelta;
            uint256 calculatedInterest;

            uint256 deltaTime;
            uint256 pending;

            uint256 endNonPunitory = min(timestamp, loan.dueTime);
            if (endNonPunitory > loan.interestTimestamp) {
                deltaTime = endNonPunitory - loan.interestTimestamp;

                if (loan.paid < loan.amount) {
                    pending = loan.amount - loan.paid;
                } else {
                    pending = 0;
                }

                (realDelta, calculatedInterest) = calculateInterest(deltaTime, loan.interestRate, pending);
                newInterest = safeAdd(calculatedInterest, newInterest);
                newTimestamp = loan.interestTimestamp + realDelta;
            }

            if (timestamp > loan.dueTime) {
                uint256 startPunitory = max(loan.dueTime, loan.interestTimestamp);
                deltaTime = timestamp - startPunitory;

                uint256 debt = safeAdd(loan.amount, newInterest);
                pending = min(debt, safeSubtract(safeAdd(debt, newPunitoryInterest), loan.paid));

                (realDelta, calculatedInterest) = calculateInterest(deltaTime, loan.interestRatePunitory, pending);
                newPunitoryInterest = safeAdd(newPunitoryInterest, calculatedInterest);
                newTimestamp = startPunitory + realDelta;
            }
            
            if (newInterest != loan.interest || newPunitoryInterest != loan.punitoryInterest) {
                loan.interestTimestamp = newTimestamp;
                loan.interest = newInterest;
                loan.punitoryInterest = newPunitoryInterest;
            }
        }
    }

    /**
        @notice Updates the loan accumulated interests up to the current Unix time.
        
        @param index Index of the loan
    
        @return true If the interest was updated
    */
    function addInterest(uint index) public returns (bool) {
        Loan storage loan = loans[index];
        require(loan.status == Status.lent);
        internalAddInterest(loan, block.timestamp);
    }
    
    /**
        @notice Pay loan

        Does a payment of a given Loan, before performing the payment the accumulated
        interest is computed and added to the total pending amount.

        Before calling this function, the msg.sender must call the "approve" function on the RCN Token, specifying an amount
        sufficient enough to pay the equivalent of the desired payment and the oracle fee.

        If the paid pending amount equals zero, the loan changes status to "paid" and it is considered closed.

        @dev Because it is difficult or even impossible to know in advance how much RCN are going to be spent on the
        transaction*, we recommend performing the "approve" using an amount 5% superior to the wallet estimated
        spending. If the RCN spent results to be less, the extra tokens are never debited from the msg.sender.

        * The RCN rate can fluctuate on the same block, and it is impossible to know in advance the exact time of the
        confirmation of the transaction. 

        @param index Index of the loan
        @param _amount Amount to pay, specified in the loan currency; or in RCN if the loan has no oracle
        @param _from The identity of the payer
        @param oracleData Data required by the oracle to return the rate, the content of this field must be provided
            by the url exposed in the url() method of the oracle.
            
        @return true if the payment was executed successfully
    */
    function pay(uint index, uint256 _amount, address _from, bytes oracleData) public returns (bool) {
        Loan storage loan = loans[index];

        require(loan.status == Status.lent);
        addInterest(index);
        uint256 toPay = min(getPendingAmount(index), _amount);
        PartialPayment(index, msg.sender, _from, toPay);

        loan.paid = safeAdd(loan.paid, toPay);

        if (getRawPendingAmount(index) == 0) {
            TotalPayment(index);
            loan.status = Status.paid;

            // ERC721, remove loan from circulation
            lendersBalance[loan.lender] -= 1;
            activeLoans -= 1;
            Transfer(loan.lender, 0x0, index);
        }

        uint256 transferValue = convertRate(loan.oracle, loan.currency, oracleData, toPay);
        require(transferValue > 0 || toPay < _amount);

        lockTokens(rcn, transferValue);
        require(rcn.transferFrom(msg.sender, this, transferValue));
        loan.lenderBalance = safeAdd(transferValue, loan.lenderBalance);

        return true;
    }

    /**
        @notice Converts an amount to RCN using the loan oracle.
        
        @dev If the loan has no oracle the currency must be RCN so the rate is 1

        @return The result of the convertion
    */
    function convertRate(Oracle oracle, bytes32 currency, bytes data, uint256 amount) public returns (uint256) {
        if (oracle == address(0)) {
            return amount;
        } else {
            uint256 rate;
            uint256 decimals;
            
            (rate, decimals) = oracle.getRate(currency, data);

            require(decimals <= RCN_DECIMALS);
            return (safeMult(safeMult(amount, rate), (10**(RCN_DECIMALS-decimals)))) / PRECISION;
        }
    }

    /**
        @notice Withdraw lender funds

        When a loan is paid, the funds are not transferred automatically to the lender, the funds are stored on the
        engine contract, and the lender must call this function specifying the amount desired to transfer and the 
        destination.

        @dev This behavior is defined to allow the temporary transfer of the loan to a smart contract, without worrying that
        the contract will receive tokens that are not traceable; and it allows the development of decentralized 
        autonomous organizations.

        @param index Index of the loan
        @param to Destination of the wiwthdraw funds
        @param amount Amount to withdraw, in RCN

        @return true if the withdraw was executed successfully
    */
    function withdrawal(uint index, address to, uint256 amount) public returns (bool) {
        Loan storage loan = loans[index];
        require(msg.sender == loan.lender);
        loan.lenderBalance = safeSubtract(loan.lenderBalance, amount);
        require(rcn.transfer(to, amount));
        unlockTokens(rcn, amount);
        return true;
    }

    /**
        @notice Withdraw lender funds in batch, it walks by all the loans passed to the function and withdraws all
        the funds stored on that loans.

        @dev This batch withdraw method can be expensive in gas, it must be used with care.

        @param loanIds Array of the loans to withdraw
        @param to Destination of the tokens

        @return the total withdrawed 
    */
    function withdrawalList(uint256[] memory loanIds, address to) public returns (uint256) {
        uint256 inputId;
        uint256 totalWithdraw = 0;

        for (inputId = 0; inputId < loanIds.length; inputId++) {
            Loan storage loan = loans[loanIds[inputId]];
            if (loan.lender == msg.sender) {
                totalWithdraw += loan.lenderBalance;
                loan.lenderBalance = 0;
            }
        }

        require(rcn.transfer(to, totalWithdraw));
        unlockTokens(rcn, totalWithdraw);

        return totalWithdraw;
    }

    /**
        @dev Deprecates the engine, locks the creation of new loans.
    */
    function setDeprecated(bool _deprecated) public onlyOwner {
        deprecated = _deprecated;
    }
}