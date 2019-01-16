pragma solidity ^0.4.25;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns(address) {
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
  function isOwner() public view returns(bool) {
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

/**
 * Utility library of inline functions on addresses
 */
library AddressUtils {

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract,
   * as the code is not actually created until after the constructor finishes.
   * @param addr address to check
   * @return whether the target address is a contract
   */
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
    // XXX Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603
    // for more details about how this works.
    // TODO Check this again before the Serenity release, because all addresses will be
    // contracts then.
    // solium-disable-next-line security/no-inline-assembly
    assembly { size := extcodesize(addr) }
    return size > 0;
  }

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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
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

// FOR ANOTHER TOKENS
contract ERC20 {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20Basic {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract SafeContract is Ownable, IERC20Basic{
    using SafeMath for uint256;
    
    address constant private ZERO_ADDRESS = address(0);
    
    //address constant private TOKEN_ADDRESS = REPLACEIT;
    address private TOKEN_ADDRESS = 0x072Ea7c455e5f3D6F3c318A55aE55D805096bc1A;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint256 private _totalSupply;
    mapping (address => uint256) private _balances;
    mapping (address => uint256) private _freezedTokenBalances;
    
    address private mainSeller;
    
    bytes public DocumentHash;
    bytes public AgreementDocumentHash;
    uint256 public PurchaseAmount;
    uint256 public QualifiedFinancingAmount;
    
    uint256 public EarlyExitMultiple;
    uint256 public EarlyExitMultipleDecimal;
    
    bool public ROFR;
    bytes public signatureROFR;
    bytes public errorROFR;
    
    uint256 public totalRestrictionAmount;
    struct Restriction{
        bool hasError;
        bytes signature;
        uint amountofRest;
    }
    mapping(uint => Restriction) public RestrictionList;
    uint countRest;
    
    address public TransferAgentCA;
    
    uint private count;
    
    struct TokenDeal{
        bool isETHTransfer; // true => WEI and false => USDC
        uint amount;   // Waiting Amount
        uint tokenAmount;   // Transfered token Amount
        uint dealExpectedTime; // Expected Fee limit time
        bool isPaid;
        bool isFailed; // Starts False, When it is failed, contract is ready for refund
        bool isRefundtoBuyer; // Starts False, When contract refunded to buyer, it ll be True   
        bool isCompleted; //Starts False, When token transfer is complated, it ll be True
    }
    
    struct TokenDealMembers{
        address seller;
        bytes sellerSignature; // Empty
        bool sellerConfirmation; // Starts False, if it is confirmated signature will be hash otherwise error hash
        address buyer;
        bytes buyerSignature; // Empty
        bool buyerConfirmation; // Starts False, if it is confirmated signature will be hash otherwise error hash
    }
    
    struct TokenDealBD{
        address brokerDealerCA;
        bytes brokerDealerSignature; // Empty
        bool brokerDealerConfirmation; // Starts False, if it is confirmated signature will be hash otherwise error hash
        bool brokerDealerFailed; // Starts False, when BD rejected set true
    }
    
    mapping(uint => TokenDeal) private tokenDealList;
    mapping(uint => TokenDealMembers) private tokenDealMembersList;
    mapping(uint => TokenDealBD) private tokenDealBDList;
    
    modifier isValidAddress(address addr) {
        require(addr != ZERO_ADDRESS);
        _;
    }
    
    modifier isContract(address addr){
        require(addr != ZERO_ADDRESS);
        require(AddressUtils.isContract(addr));
        _;
    }
    
    modifier enoughToken(address addr, uint _tokenAmount){
        require(addr != ZERO_ADDRESS);
        uint256 totalFreezedAmount = _freezedTokenBalances[addr].add(_tokenAmount); 
        require(balanceOf(addr) >= totalFreezedAmount);
        _;
    }
    
    modifier isTransferAgent(address addr){
        require(addr != ZERO_ADDRESS);
        require(AddressUtils.isContract(addr));
        require(TransferAgentCA.call(bytes4(keccak256("isTransferAgentAddress(address)")), addr)); 
        _;
    }
    
    modifier isReqRestriction(address _seller, uint _tokenAmount){
        if(mainSeller == _seller && totalRestrictionAmount < _totalSupply){
            uint256 totalFreezedTokenAmount = _freezedTokenBalances[_seller].add(_tokenAmount);
            require(_totalSupply.sub(totalRestrictionAmount) > balanceOf(_seller).sub(totalFreezedTokenAmount));  
        }
        _;
    }
    
    modifier isSeller(address _seller, uint _index){
        require(_index >0 && _index < count);
        TokenDealMembers memory TDM = tokenDealMembersList[_index];
        require(_seller == TDM.seller);
        _;
    }
    
    modifier isBuyer(address _buyer, uint _index){
        require(_index >0 && _index < count);
        TokenDealMembers memory TDM = tokenDealMembersList[_index];
        require(_buyer == TDM.buyer);
        _;
    }
    
    modifier isBD(address _brokerDealer, uint _index){
        require(_index >0 && _index < count);
        TokenDealBD memory TDBD = tokenDealBDList[_index];
        require( TDBD.brokerDealerCA.call(bytes4(keccak256("isValidBrokerDealer(address)")), _brokerDealer) );
        _;
    }
    
    // BEGIN OF TRANSFER VALIDATIONS
    
    modifier isAvailableTokenBalance(uint tokenAmount) {
        require(tokenAmount > 0);
        require(ERC20(TOKEN_ADDRESS).balanceOf(this) >= tokenAmount);
        _;
    }
    
    modifier isAvailableETHBalance(uint amount) {
        require(amount > 0);
        require(address(this).balance > amount);
        _;
    }
    
    // END OF TRANSFER VALIDATIONS

    constructor (address _mainSeller, bytes _documentHash, bytes _agreementDocumentHash, uint256 _purchaseAmount, uint256 _qualifiedFinancingAmount,
        uint256 _earlyExitMultiple, uint256 _earlyExitMultipleDecimal, address _transferAgentCA, string _tokenSymbol,
        string _tokenName, bool _rofr) public isValidAddress(_mainSeller) isContract(_transferAgentCA){
            mainSeller = _mainSeller;
            DocumentHash = _documentHash;
            AgreementDocumentHash = _agreementDocumentHash;
            PurchaseAmount = _purchaseAmount;
            QualifiedFinancingAmount = _qualifiedFinancingAmount;
            EarlyExitMultiple = _earlyExitMultiple;
            EarlyExitMultipleDecimal = _earlyExitMultipleDecimal;
            TransferAgentCA = _transferAgentCA;
            symbol = _tokenSymbol;
            name = _tokenName;
            decimals = 0;
            _totalSupply = PurchaseAmount;
            _balances[mainSeller] = PurchaseAmount;
            emit Transfer(address(0), mainSeller, _totalSupply);
            _freezedTokenBalances[mainSeller] = 0;
            totalRestrictionAmount = 0;
            countRest = 0;
            count = 0;
            ROFR = _rofr;
    }
    //BEGIN OF ROFR FUNCTIONS
    
    function setSignatureROFR(bytes _signature) public isTransferAgent(msg.sender) returns(bool){
        require(!ROFR);
        signatureROFR = _signature;
        ROFR = true;
        return true;
    }
    
    function setErrorROFR(bytes _errorROFR) public isTransferAgent(msg.sender) returns(bool){
        require(!ROFR);
        errorROFR = _errorROFR;
        return true;
    }
    
    function getROFRStatus() public view returns(bool, bytes, bytes){
        return (ROFR, signatureROFR, errorROFR);
    }
    
    //END OF ROFR FUNCTIONS
    
    //BEGIN OF RESTRICTION FUNCTIONS
    
    function setSignatureRest(bytes _signature, uint _amountOfRest) public isTransferAgent(msg.sender) returns(bool){
        countRest++;
        RestrictionList[countRest] = Restriction(false, _signature, _amountOfRest);
        totalRestrictionAmount = totalRestrictionAmount.add(_amountOfRest);
        return true;
    }
    
    function setErrorRest(bytes _error, uint _amountOfRest) public isTransferAgent(msg.sender) returns(bool){
        countRest++;
        RestrictionList[countRest] = Restriction(true, _error, _amountOfRest);
        return true;
    }
    
    function getRestrictionStatus(uint _numberofRest) public view returns(uint, bool, bytes, uint){
        if(_numberofRest>countRest){
            return (totalRestrictionAmount, false, "", countRest);
        }else{
            Restriction memory R = RestrictionList[_numberofRest]; 
            return (totalRestrictionAmount, R.hasError, R.signature, countRest);    
        }
    }
    
    //END OF RESTRICTION FUNCTIONS
    
    //BEGIN OF DEAL FUNCTIONS
    
    function setDeal(address _seller, bool _isETHTransfer, uint _amount, uint _tokenAmount, uint _dealExpectedTime) public onlyOwner 
        enoughToken(_seller, _tokenAmount) isReqRestriction(_seller, _tokenAmount) returns(uint){
            require(ROFR);
            count++;
            tokenDealList[count] = TokenDeal(_isETHTransfer, _amount, _tokenAmount, _dealExpectedTime, false, false, false, false);
            _freezedTokenBalances[_seller] = _freezedTokenBalances[_seller].add(_tokenAmount);
            return count;
    }
    
    function setDealMembers(address _seller, address _buyer, address _brokerDealer, uint _count) public onlyOwner isValidAddress(_buyer) 
        isContract(_brokerDealer) {
            tokenDealMembersList[_count] = TokenDealMembers(_seller, "", false, _buyer, "", false);
            tokenDealBDList[_count] = TokenDealBD( _brokerDealer, "", false, false);
    }
    
    function sellerApprove(uint _index, bytes _signature) public isSeller(msg.sender, _index){
        require(_signature.length > 0);
        TokenDeal memory TD = tokenDealList[_index];
        TokenDealMembers storage TDM = tokenDealMembersList[_index];
        require(!TD.isFailed);
        require(TD.dealExpectedTime > now);
        require(!TDM.sellerConfirmation);
        TDM.sellerConfirmation = true;
        TDM.sellerSignature = _signature;
    }
    
    function buyerApprove(uint _index, bytes _signature) public isBuyer(msg.sender, _index){
        require(_signature.length > 0);
        TokenDeal memory TD = tokenDealList[_index];
        TokenDealMembers storage TDM = tokenDealMembersList[_index];
        require(!TD.isFailed);
        require(TD.dealExpectedTime > now);
        require(TD.isPaid);
        TDM.buyerConfirmation = true;
        TDM.buyerSignature = _signature;
    }
    
    
    function setBDApprove(uint _index, bytes _signature) public isBD(msg.sender, _index){
        require(_signature.length > 0);
        TokenDeal memory TD = tokenDealList[_index];
        require(!TD.isFailed);
        require(TD.dealExpectedTime > now);
        TokenDealMembers memory TDM = tokenDealMembersList[_index];
        require(TDM.buyerConfirmation);
        TokenDealBD storage TDBD = tokenDealBDList[_index];
        require(!TDBD.brokerDealerConfirmation);
        require(!TDBD.brokerDealerFailed);
        TDBD.brokerDealerConfirmation = true;
        TDBD.brokerDealerSignature = _signature;
        _startTokenTransfer(_index);
    }
    
    function setBDError(uint _index, bytes _error) public isBD(msg.sender, _index){
        TokenDeal storage TD = tokenDealList[_index];
        require(!TD.isFailed);
        require(TD.dealExpectedTime > now);
        TokenDealMembers memory TDM = tokenDealMembersList[_index];
        require(TDM.buyerConfirmation);
        TokenDealBD storage TDBD = tokenDealBDList[_index];
        require(!TDBD.brokerDealerConfirmation);
        TDBD.brokerDealerSignature = _error;
        TDBD.brokerDealerFailed = true;
    }
    
    function _startTokenTransfer(uint _index) internal{
        TokenDeal storage TD = tokenDealList[_index];
        TD.isCompleted = true;
        TokenDealMembers memory TDM = tokenDealMembersList[_index];
        _freezedTokenBalances[TDM.seller] = _freezedTokenBalances[TDM.seller].sub(TD.tokenAmount);
        _transfer(TDM.seller, TDM.buyer, TD.tokenAmount);
    }
    
    //END OF DEAL FUNCTIONS
    
    //START OF CREO FUNCTIONS
    
    function changedBrokerDealer(uint _index, address _brokerDealer) public onlyOwner isContract(_brokerDealer) returns(bool){
        require(_index > 0 && _index <=count);
        TokenDeal memory TD = tokenDealList[_index];
        require(!TD.isFailed && !TD.isCompleted && !TD.isRefundtoBuyer);
        TokenDealBD storage TDBD = tokenDealBDList[_index];
        require(!TDBD.brokerDealerConfirmation);
        TDBD.brokerDealerCA = _brokerDealer;
        return true;
    } 
    
    function changeOfferTime(uint _index, uint _offerTime) public onlyOwner returns(bool){
        require(_index > 0 && _index <=count);
        require(_offerTime > now);
        TokenDeal storage TD = tokenDealList[_index];
        require(!TD.isFailed && !TD.isCompleted && !TD.isRefundtoBuyer);
        TD.dealExpectedTime = _offerTime;
        return true;
    } 
    
    function changeTransferAgentCA(address _transferAgentCA) public onlyOwner isContract(_transferAgentCA) returns(bool){
        TransferAgentCA = _transferAgentCA;
        return true;
    }
    
    function doFailedOffer(uint _index) public onlyOwner returns(bool){
       require(_index > 0 && _index <=count);
       TokenDeal storage TD = tokenDealList[_index];
       require(!TD.isCompleted);
       TD.isFailed = true;
    }
    
    function startRefundPayment(uint _index, uint _refundAmount) public onlyOwner{
       require(_index > 0 && _index <=count);
       require(_refundAmount >0 );
       TokenDeal storage TD = tokenDealList[_index];
       require(!TD.isCompleted);
       require(TD.isPaid);
       if(TD.isETHTransfer){
           _refundWEICustomer(_index, _refundAmount);
       }else{
           _refundTokenCustomer(_index, _refundAmount);
       }
    }
    
    function setTokenContractAddress(address _tokenCA) public onlyOwner isContract(_tokenCA) returns(bool){
        TOKEN_ADDRESS = _tokenCA;
        return true;
    }
    
    //END OF CREO FUNCTIONS
    
    // BEGIN OF PAYABLE FUNCTIONS
    
    function() public payable {
        revert();
    }
    
    function pay(uint _index) public payable {
        require(msg.sender != ZERO_ADDRESS);
        require(msg.value > 0);
        require(_index > 0 && _index <= count);
        TokenDeal storage TD = tokenDealList[_index];
        require(!TD.isPaid);
        require(TD.isETHTransfer);
        require(TD.amount == msg.value);
        require(TD.dealExpectedTime > now);
        require(!TD.isFailed);
        TokenDealMembers memory TDM = tokenDealMembersList[_index];
        require(msg.sender == TDM.buyer);
        require(TDM.sellerConfirmation);
        TokenDealBD memory TDBD = tokenDealBDList[_index];
        require(!TDBD.brokerDealerFailed);
        TD.isPaid = true;
    }
    
    /*
    function setTokenPaymentCustomer(){
        
    }
    */

    function _refundWEICustomer(uint _index, uint _refundAmount) internal isAvailableETHBalance(_refundAmount) {
        TokenDeal storage TD = tokenDealList[_index];
        TokenDealMembers storage TDM = tokenDealMembersList[_index];
        TD.isRefundtoBuyer = true;
        TDM.buyer.transfer(_refundAmount);
    }
    
    function _refundTokenCustomer(uint _index, uint _refundAmount) internal isAvailableTokenBalance(_refundAmount){
        TokenDeal storage TD = tokenDealList[_index];
        TokenDealMembers storage TDM = tokenDealMembersList[_index];
        TD.isRefundtoBuyer = true;
        ERC20(TOKEN_ADDRESS).transfer(TDM.buyer, _refundAmount);
    }
    
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



}