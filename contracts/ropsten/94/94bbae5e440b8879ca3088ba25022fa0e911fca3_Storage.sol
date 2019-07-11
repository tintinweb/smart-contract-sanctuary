/**
 *Submitted for verification at Etherscan.io on 2019-07-11
*/

pragma solidity ^0.5.9;

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

// FOR ANOTHER TOKENS
contract ERC20 {
    function totalSupply() public  returns (uint);
    function balanceOf(address tokenOwner) public  returns (uint balance);
    function allowance(address tokenOwner, address spender) public  returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Storage is Ownable{
    
    address constant private ZERO_ADDRESS = address(0);
     
    struct Contract{
        bool isAdded;
        uint256 numberOfDeal;
        bool isBlocked;
    }
    
    mapping(address => Contract) public contractList;
    
    struct TokenDeal{
        uint tokenAmount;   // Transfered token Amount
        bool isPaid;
        bool isFailed; // Starts False, When it is failed, contract is ready for refund
        bool isRefundtoBuyer; // Starts False, When contract refunded to buyer, it ll be True   
        bool isCompleted; //Starts False, When token transfer is complated, it ll be True
    }
    
    struct TokenDealPayment{
        uint _amount;
        bool _type; //true => ETH false => TOKEN
        address _tokenAddress; // it is ZERO_ADDRESS for ETH, Depand Type 
    }
    
    struct TokenDealMembers{
        address payable seller;
        bytes32 sellerSignature; // Empty
        bool sellerConfirmation; // Starts False, if it is confirmated signature will be hash otherwise error hash
        address payable buyer;
        bytes32 buyerSignature; // Empty
        bool buyerConfirmation; // Starts False, if it is confirmated signature will be hash otherwise error hash
    }
    
    struct TokenDealBD{
        address brokerDealer;
        bytes32 brokerDealerSignature; // Empty
        bool brokerDealerConfirmation; // Starts False, if it is confirmated signature will be hash otherwise error hash
    }
    
    mapping(address => mapping(uint => TokenDeal)) private tokenDealList;
    mapping(address => mapping(uint => TokenDealMembers)) private tokenDealMembersList;
    mapping(address => mapping(uint => TokenDealBD)) private tokenDealBDList;
    mapping(address => mapping(uint => TokenDealPayment)) private tokenDealPaymentList;
    
    modifier isValidAddress(address addr) {
        require(addr != ZERO_ADDRESS);
        _;
    }
    
    modifier isContract(address addr){
        require(addr != ZERO_ADDRESS);
        require(AddressUtils.isContract(addr));
        _;
    }
    
    modifier isContractExist(address addr){
        require(addr != ZERO_ADDRESS);
        require(AddressUtils.isContract(addr));
        require(contractList[addr].isAdded); 
        _;
    }

    constructor () public {
    }
    
    function addContract(address _contractAddress) public returns(bool){
        require(!contractList[_contractAddress].isAdded);
        contractList[_contractAddress] = Contract(true, 0, false);
    }
    
    function setContractStatus(address _contractAddress, bool _status) public onlyOwner isContractExist(_contractAddress) returns(bool){
        Contract storage C = contractList[_contractAddress];
        C.isBlocked = _status;
        return true;
    }
    
    function getContract(address _contractAddress) public view isContractExist(_contractAddress) returns(address, uint256, bool){
        Contract memory C = contractList[_contractAddress];
        return (_contractAddress, C.numberOfDeal, C.isBlocked);
    }
    
    //BEGIN OF DEAL FUNCTIONS
    
    function setDeal(uint _tokenAmount, address payable[] memory addresses) public 
        isContractExist(msg.sender) returns(uint){
            Contract storage C = contractList[msg.sender];
            require(!C.isBlocked);
            C.numberOfDeal++;
            tokenDealList[msg.sender][C.numberOfDeal] = TokenDeal(_tokenAmount, false, false, false, false);
            tokenDealMembersList[msg.sender][C.numberOfDeal] = TokenDealMembers(addresses[0], "", false, addresses[1], "", false);
            tokenDealBDList[msg.sender][C.numberOfDeal] = TokenDealBD( addresses[2], "", false);
            return C.numberOfDeal;
    }
    
    function sellerApprove(address _seller, uint _index, bytes32 _signature) 
    public 
    isContractExist(msg.sender) {
        require(_signature.length > 0);
        Contract memory C = contractList[msg.sender];
        require(!C.isBlocked);
        require(_index >0 && _index <= C.numberOfDeal);
        TokenDeal memory TD = tokenDealList[msg.sender][_index];
        TokenDealMembers storage TDM = tokenDealMembersList[msg.sender][_index];
        require(_seller == TDM.seller);
        require(!TD.isFailed);
        require(!TDM.sellerConfirmation);
        TDM.sellerConfirmation = true;
        TDM.sellerSignature = _signature;
    }
    
    function buyerApprove(address _buyer, uint _index, bytes32 _signature) public isContractExist(msg.sender){
        require(_signature.length > 0);
        Contract memory C = contractList[msg.sender];
        require(_index >0 && _index <= C.numberOfDeal);
        TokenDeal memory TD = tokenDealList[msg.sender][_index];
        TokenDealMembers storage TDM = tokenDealMembersList[msg.sender][_index];
        require(TDM.buyer == _buyer);
        require(!TD.isFailed);
        //require(TD.isPaid);
        TDM.buyerConfirmation = true;
        TDM.buyerSignature = _signature;
    }
    
    
    /*
    If we deployed broker dealler contract use it...
    
    function setBDApprove(address _brokerDealer, uint _index, bytes32 _signature) public isContractExist(msg.sender) 
        returns(address, address, uint256){
            require(_signature.length > 0);
            Contract memory C = contractList[msg.sender];
            require(!C.isBlocked);
            require(_index >0 && _index <= C.numberOfDeal);
            TokenDeal memory TD = tokenDealList[msg.sender][_index];
            require(!TD.isFailed);
            TokenDealMembers memory TDM = tokenDealMembersList[msg.sender][_index];
            require(TDM.buyerConfirmation);
            TokenDealBD storage TDBD = tokenDealBDList[msg.sender][_index];
            //require(TDBD.brokerDealerCA.call(bytes4(keccak256("isValidBrokerDealer(address)")), _brokerDealer) );
            bytes memory payload = abi.encodeWithSignature("isValidBrokerDealer(address)", _brokerDealer);
            (bool success, bytes memory returnData) = _addr.staticcall(payload);
            require(success);
            require(!TDBD.brokerDealerConfirmation);
            TDBD.brokerDealerConfirmation = true;
            TDBD.brokerDealerSignature = _signature;
            TD.isCompleted = true;
            return (TDM.seller, TDM.buyer, TD.tokenAmount);
    }
    
    */
    
    function setBDApprove(address _brokerDealer, uint _index, bytes32 _signature) public isContractExist(msg.sender) 
        returns(address payable, address payable, uint256){
            require(_signature.length > 0);
            Contract memory C = contractList[msg.sender];
            require(!C.isBlocked);
            require(_index >0 && _index <= C.numberOfDeal);
            TokenDeal memory TD = tokenDealList[msg.sender][_index];
            require(!TD.isFailed);
            TokenDealMembers memory TDM = tokenDealMembersList[msg.sender][_index];
            require(TDM.buyerConfirmation && TDM.sellerConfirmation);
            TokenDealBD storage TDBD = tokenDealBDList[msg.sender][_index];
            require(TDBD.brokerDealer == _brokerDealer);
            require(!TDBD.brokerDealerConfirmation);
            TDBD.brokerDealerConfirmation = true;
            TDBD.brokerDealerSignature = _signature;
            TD.isCompleted = true;
            return (TDM.seller, TDM.buyer, TD.tokenAmount);
    }
    
    
    //END OF DEAL FUNCTIONS
    
    //START OF CREO FUNCTIONS
    
    function changedBrokerDealer( uint _index, address _brokerDealer) public isContractExist(msg.sender) returns(bool){
        Contract memory C = contractList[msg.sender];
        require(!C.isBlocked);
        require(_index > 0 && _index <=C.numberOfDeal);
        TokenDeal memory TD = tokenDealList[msg.sender][_index];
        require(!TD.isFailed && !TD.isCompleted && !TD.isRefundtoBuyer);
        TokenDealBD storage TDBD = tokenDealBDList[msg.sender][_index];
        require(!TDBD.brokerDealerConfirmation);
        TDBD.brokerDealer = _brokerDealer;
        return true;
    }
    
    function doFailedOffer(uint _index) public isContractExist(msg.sender) returns(address,uint256){
        Contract memory C = contractList[msg.sender];
        require(_index > 0 && _index <=C.numberOfDeal);
        TokenDeal storage TD = tokenDealList[msg.sender][_index];
        require(!TD.isCompleted);
        TD.isFailed = true;
        TokenDealMembers memory TDM = tokenDealMembersList[msg.sender][_index];
        return (TDM.seller,TD.tokenAmount);
    }
    
    function setPayment(uint _index, uint _amount, bool _type, address _tokenAddress) public isContractExist(msg.sender) returns(address){
        Contract memory C = contractList[msg.sender];
        require(!C.isBlocked);
        require(_index > 0 && _index <= C.numberOfDeal);
        TokenDeal storage TD = tokenDealList[msg.sender][_index];
        require(!TD.isCompleted);
        require(!TD.isPaid);
        require(!TD.isFailed);
        TD.isPaid = true;
        TokenDealMembers memory TDM = tokenDealMembersList[msg.sender][_index];
        tokenDealPaymentList[msg.sender][_index] = TokenDealPayment( _amount, _type, _tokenAddress);
        return TDM.buyer;
    }
    
    function getPaymentData(uint _index) public view isContractExist(msg.sender) returns(uint256, bool){
        TokenDealPayment memory TDP = tokenDealPaymentList[msg.sender][_index];
        return (TDP._amount, TDP._type); //TDP._tokenAddress
    }
    
    function startRefundProcess(uint256 _index) public isContractExist(msg.sender) returns(address payable){
        Contract memory C = contractList[msg.sender];
        require(_index > 0 && _index <= C.numberOfDeal);
        TokenDeal storage TD = tokenDealList[msg.sender][_index];
        require(!TD.isCompleted);
        require(TD.isPaid);
        TD.isRefundtoBuyer = true;
        TokenDealMembers memory TDM = tokenDealMembersList[msg.sender][_index];
        return TDM.buyer;
    }
    
    // BEGIN OF PAYABLE FUNCTIONS
    
    function() payable external{
        revert(); 
    }
    
    function tokenTransfer(address _address, address _tokenAddress, uint _tokenAmount) private onlyOwner isValidAddress(_address) 
        isContract(_tokenAddress) returns(bool){
            ERC20(_tokenAddress).transfer(_address, _tokenAmount);
            return true;
    }
    
    // END OF PAYABLE FUNCTIONS
}