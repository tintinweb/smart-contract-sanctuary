pragma solidity 0.4.19;


contract Ownable {
    
    address public owner;

    /**
     * The address whcih deploys this contrcat is automatically assgined ownership.
     * */
    function Ownable() public {
        owner = msg.sender;
    }

    /**
     * Functions with this modifier can only be executed by the owner of the contract. 
     * */
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    event OwnershipTransferred(address indexed from, address indexed to);

    /**
    * Transfers ownership to new Ethereum address. This function can only be called by the 
    * owner.
    * @param _newOwner the address to be granted ownership.
    **/
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != 0x0);
        OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}




contract ERC20TransferInterface {
    function transfer(address to, uint256 value) public returns (bool);
    function balanceOf(address who) constant public returns (uint256);
}




contract MultiSigWallet is Ownable {

    event AddressAuthorised(address indexed addr);
    event AddressUnauthorised(address indexed addr);
    event TransferOfEtherRequested(address indexed by, address indexed to, uint256 valueInWei);
    event EthTransactionConfirmed(address indexed by);
    event EthTransactionRejected(address indexed by);
    event TransferOfErc20Requested(address indexed by, address indexed to, address indexed token, uint256 value);
    event Erc20TransactionConfirmed(address indexed by);
    event Erc20TransactionRejected(address indexed by);

    /**
    * Struct exists to hold data associated with the requests of ETH transactions. 
    **/
    struct EthTransactionRequest {
        address _from;
        address _to;
        uint256 _valueInWei;
    }

    /**
    * Struct exists to hold data associated with the requests of ERC20 token transactions. 
    **/
    struct Erc20TransactionRequest {
        address _from;
        address _to;
        address _token;
        uint256 _value;
    }

    EthTransactionRequest public latestEthTxRequest;
    Erc20TransactionRequest public latestErc20TxRequest;

    mapping (address => bool) public isAuthorised;


    /**
    * Constructor initializes the isOwner mapping. 
    **/
    function MultiSigWallet() public {
 
        isAuthorised[0xF748D2322ADfE0E9f9b262Df6A2aD6CBF79A541A] = true; //account 1
        isAuthorised[0x4BbBbDd42c7aab36BeA6A70a0cB35d6C20Be474E] = true; //account 2
        isAuthorised[0x2E661Be8C26925DDAFc25EEe3971efb8754E6D90] = true; //account 3
        isAuthorised[0x1ee9b4b8c9cA6637eF5eeCEE62C9e56072165AAF] = true; //account 4

    }

    modifier onlyAuthorisedAddresses {
        require(isAuthorised[msg.sender] = true);
        _;
    }

    modifier validEthConfirmation {
        require(msg.sender != latestEthTxRequest._from);
        _;
    }

    modifier validErc20Confirmation {
        require(msg.sender != latestErc20TxRequest._from);
        _;
    }

    /**
    * Fallback function makes it possible for the contract to receive ETH. 
    **/
    function() public payable { }

    /**
    * Allows the owner to authorise an address to approve and request the transfer of ETH and
    * ERC20 tokens.
    **/
    function authoriseAddress(address _addr) public onlyOwner {
        require(_addr != 0x0 && !isAuthorised[_addr]);
        isAuthorised[_addr] = true;
        AddressAuthorised(_addr);
    }

    /**
    * Allows the owner to unauthorise an address from approving or requesting the transfer of ETH
    * and ERC20 tokens.
    **/
    function unauthoriseAddress(address _addr) public onlyOwner {
        require(isAuthorised[_addr] && _addr != owner);
        isAuthorised[_addr] = false;
        AddressUnauthorised(_addr);
    }

    /**
    * Creates an ETH transaction request which will be stored in the contract&#39;s state. The transaction
    * will only go through if it is confirmed by at least one more owner address. If this function is 
    * called before a previous ETH transaction request has been confirmed, then it will be overridden. This
    * function can only be called by one of the owner addresses. 
    * 
    * @param _to The address of the recipient
    * @param _valueInWei The amount of ETH to send specified in units of wei
    **/
    function requestTransferOfETH(address _to, uint256 _valueInWei) public onlyAuthorisedAddresses {
        require(_to != 0x0 && _valueInWei > 0);
        latestEthTxRequest = EthTransactionRequest(msg.sender, _to, _valueInWei);
        TransferOfEtherRequested(msg.sender, _to, _valueInWei);
    }

    /**
    * Creates an ERC20 transaction request which will be stored in the contract&#39;s state. The transaction
    * will only go through if it is confirmed by at least one more owner address. If this function is 
    * called before a previous ERC20 transaction request has been confirmed, then it will be overridden. This
    * function can only be called by one of the owner addresses. 
    * 
    * @param _token The address of the ERC20 token contract
    * @param _to The address of the recipient
    * @param _value The amount of tokens to be sent
    **/
    function requestErc20Transfer(address _token, address _to, uint256 _value) public onlyAuthorisedAddresses {
        ERC20TransferInterface token = ERC20TransferInterface(_token);
        require(_to != 0x0 && _value > 0 && token.balanceOf(address(this)) >= _value);
        latestErc20TxRequest = Erc20TransactionRequest(msg.sender, _to, _token, _value);
        TransferOfErc20Requested(msg.sender, _to, _token, _value);
    }

    /**
    * Confirms previously requested ETH transactions. This function can only be called by one of the owner addresses
    * excluding the address which initially made the request. 
    **/
    function confirmEthTransactionRequest() public onlyAuthorisedAddresses validEthConfirmation  {
        require(isAuthorised[latestEthTxRequest._from] && latestEthTxRequest._to != 0x0 && latestEthTxRequest._valueInWei > 0);
        latestEthTxRequest._to.transfer(latestEthTxRequest._valueInWei);
        latestEthTxRequest = EthTransactionRequest(0x0, 0x0, 0);
        EthTransactionConfirmed(msg.sender);
    }

    /**
    * Confirms previously requested ERC20 transactions. This function can only be called by one of the owner addresses
    * excluding the address which initially made the request. 
    **/
    function confirmErc20TransactionRequest() public onlyAuthorisedAddresses validErc20Confirmation {
        require(isAuthorised[latestErc20TxRequest._from] && latestErc20TxRequest._to != 0x0 && latestErc20TxRequest._value != 0 && latestErc20TxRequest._token != 0x0);
        ERC20TransferInterface token = ERC20TransferInterface(latestErc20TxRequest._token);
        token.transfer(latestErc20TxRequest._to,latestErc20TxRequest._value);
        latestErc20TxRequest = Erc20TransactionRequest(0x0, 0x0, 0x0, 0);
        Erc20TransactionConfirmed(msg.sender);
    }

    /**
    * Rejects ETH transaction requests and erases all data associated with the request. This function can only be called
    * by one of the owner addresses. 
    **/
    function rejectEthTransactionRequest() public onlyAuthorisedAddresses {
        latestEthTxRequest = EthTransactionRequest(0x0, 0x0, 0);
        EthTransactionRejected(msg.sender);
    }

    /**
    * Rejects ERC20 transaction requests and erases all data associated with the request. This function can only be called
    * by one of the owner addresses. 
    **/
    function rejectErx20TransactionRequest() public onlyAuthorisedAddresses {
        latestErc20TxRequest = Erc20TransactionRequest(0x0, 0x0, 0x0, 0);
        Erc20TransactionRejected(msg.sender);
    }

    /**
    * Returns the data associated with the latest ETH transaction request in the form of a touple. This data includes:
    * the owner address which requested the transfer, the address of the recipient and the value of the transfer 
    * specified in units of wei. 
    **/
    function viewLatestEthTransactionRequest() public view returns(address from, address to, uint256 valueInWei) {
        return (latestEthTxRequest._from, latestEthTxRequest._to, latestEthTxRequest._valueInWei);
    }

    /**
    * Returns the data associated with the latest ERC20 transaction request in the form of a touple. This data includes:
    * the owner address which requested the transfer, the address of the recipient, the address of the ERC20 token contract
    * and the amount of tokens to send. 
    **/
    function viewLatestErc20TransactionRequest() public view returns(address from, address to, address token, uint256 value) {
        return(latestErc20TxRequest._from, latestErc20TxRequest._to, latestErc20TxRequest._token, latestErc20TxRequest._value);
    }
}