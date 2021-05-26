/**
 *Submitted for verification at Etherscan.io on 2021-05-26
*/

pragma solidity 0.5.9;

/*
* @author Cryptonomica Ltd.(cryptonomica.net), 2019
* @version 2019-06-10
* Github: https://github.com/Cryptonomica/
*
* @section LEGAL:
* aim of this contract is to create a mechanism to draw, transfer and accept negotiable instruments
* that that will be recognized as 'bills of exchange' according at least to following regulations:
*
* 1) Convention providing a Uniform Law for Bills of Exchange and Promissory Notes (Geneva, 7 June 1930):
* https://www.jus.uio.no/lm/bills.of.exchange.and.promissory.notes.convention.1930/doc.html
* https://treaties.un.org/Pages/LONViewDetails.aspx?src=LON&id=552&chapter=30&clang=_en
*
* 2) U.K. Bills of Exchange Act 1882:
* http://www.legislation.gov.uk/ukpga/Vict/45-46/61/section/3
*
* and as a 'draft' according to
* U.S. Uniform Commercial Code
* https://www.law.cornell.edu/ucc/3/3-104
*
* see more on: https://github.com/Cryptonomica/cryptonomica/wiki/electronic-bills-of-exchange
*
* Bills of exchange created with this smart contract are payable to the bearer,
* and can be transferred using Ethereum blockchain (from one blockchain address to another)
*
*/

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 * source:
 * https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/math/SafeMath.sol
 * commit 67bca85 on Apr 25, 2019
 */
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

/**
* @title Contract that will work with ERC-677 tokens
* see:
* https://github.com/ethereum/EIPs/issues/677
* https://github.com/smartcontractkit/LinkToken/blob/master/contracts/ERC677Token.sol
*/
contract ERC677Receiver {
    /**
    * The function is added to contracts enabling them to react to receiving tokens within a single transaction.
    * The from parameter is the account which just transferred amount from the token contract. data is available to pass
    * additional parameters, i.e. to indicate what the intention of the transfer is if a contract allows transfers for multiple reasons.
    * @param from address sending tokens
    * @param amount of tokens
    * @param data to send to another contract
    */
    function onTokenTransfer(address from, uint256 amount, bytes calldata data) external returns (bool success);
}

/**
* @title Contract that will work with overloaded 'transfer' function
* see: https://github.com/ethereum/EIPs/issues/223
*/
contract ERC223ReceivingContract {
    /**
     * @dev Standard ERC223 function that will handle incoming token transfers.
     * @param _from  Token sender address.
     * @param _value Amount of tokens.
     * @param _data  Transaction metadata.
     */
    function tokenFallback(address _from, uint _value, bytes calldata _data) external;
}

/**
 * @title Contract that implements:
 * ERC-20  (https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md)
 * overloaded 'transfer' function (like in ERC-223 (https://github.com/ethereum/EIPs/issues/223 )
 * ERC-677 (https://github.com/ethereum/EIPs/issues/677)
 * overloaded 'approve' function (https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM/)
*/
contract Token {

    using SafeMath for uint256;

    /* --- ERC-20 variables */

    string public name;

    string public symbol;

    uint8 public constant decimals = 0;

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*
    * stored address that deployed this smart contract to blockchain
    * for bills of exchange smart contracts this will be 'BillsOfExchangeFactory' contract address
    */
    address public creator;

    /**
    * Constructor
    * no args constructor make possible to create contracts with code pre-verified on etherscan.io
    * (once we verify one contract, all next contracts with the same code and constructor args will be verified by etherscan)
    */
    constructor() public {
        /*
        * this will be 'BillsOfExchangeFactory' contract address
        */
        creator = msg.sender;
    }

    /*
    * initializes token: set initial values for erc20 variables
    * assigns all tokens ('totalSupply') to one address ('tokenOwner')
    * @param _name Name of the token
    * @param _symbol Symbol of the token
    * @param _totalSupply Amount of tokens to create
    * @param _tokenOwner Address that will initially hold all created tokens
    */
    function initToken(
        string calldata _name,
        string calldata _symbol,
        uint256 _totalSupply,
        address tokenOwner
    ) external {

        // creator is BillsOfExchangeFactory address
        require(msg.sender == creator, "Only creator can initialize token contract");

        name = _name;
        symbol = _symbol;
        totalSupply = _totalSupply;
        balanceOf[tokenOwner] = totalSupply;

        emit Transfer(address(0), tokenOwner, totalSupply);

    }

    /* --- ERC-20 events */

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed _owner, address indexed spender, uint256 value);

    /* --- Events for interaction with other smart contracts */

    /**
    * @param _from Address that sent transaction
    * @param _toContract Receiver (smart contract)
    * @param _extraData Data sent
    */
    event DataSentToAnotherContract(address indexed _from, address indexed _toContract, bytes indexed _extraData);

    /* --- ERC-20 Functions */

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool){

        // Transfers of 0 values MUST be treated as normal transfers and fire the Transfer event (ERC-20)
        // Variables of uint type cannot be negative. Thus, comparing uint variable with zero (greater than or equal) is redundant
        // require(_value >= 0);

        require(_to != address(0), "_to was 0x0 address");

        // The function SHOULD throw unless the _from account has deliberately authorized the sender of the message via some mechanism
        require(msg.sender == _from || _value <= allowance[_from][msg.sender], "Sender not authorized");

        // check if _from account have required amount
        require(_value <= balanceOf[_from], "Account doesn't have required amount");

        // Subtract from the sender
        balanceOf[_from] = balanceOf[_from].sub(_value);
        // Add the same to the recipient
        balanceOf[_to] = balanceOf[_to].add(_value);

        // If allowance used, change allowances correspondingly
        if (_from != msg.sender) {
            allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        }

        emit Transfer(_from, _to, _value);

        return true;
    } // end of transferFrom

    function transfer(address _to, uint256 _value) public returns (bool success){
        return transferFrom(msg.sender, _to, _value);
    }

    /**
    * overloaded transfer (like in ERC-223)
    * see: https://github.com/ethereum/EIPs/issues/223
    * https://github.com/Dexaran/ERC223-token-standard/blob/Recommended/ERC223_Token.sol
    */
    function transfer(address _to, uint _value, bytes calldata _data) external returns (bool success){
        if (transfer(_to, _value)) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
            emit DataSentToAnotherContract(msg.sender, _to, _data);
            return true;
        }
        return false;
    }

    /**
    * ERC-677
    * https://github.com/ethereum/EIPs/issues/677
    * transfer tokens with additional info to another smart contract, and calls its correspondent function
    * @param _to Another smart contract address (receiver)
    * @param _value Number of tokens to transfer
    * @param _extraData Data to send to another contract
    *
    * This function is a recommended method to send tokens to smart contracts.
    */
    function transferAndCall(address _to, uint256 _value, bytes memory _extraData) public returns (bool success){
        if (transferFrom(msg.sender, _to, _value)) {
            ERC677Receiver receiver = ERC677Receiver(_to);
            if (receiver.onTokenTransfer(msg.sender, _value, _extraData)) {
                emit DataSentToAnotherContract(msg.sender, _to, _extraData);
                return true;
            }
        }
        return false;
    }

    /**
    * the same as above ('transferAndCall'), but for all tokens on user account
    * for example for converting ALL tokens on user account to another tokens
    */
    function transferAllAndCall(address _to, bytes calldata _extraData) external returns (bool){
        return transferAndCall(_to, balanceOf[msg.sender], _extraData);
    }

    /*
    * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md#approve
    * there is an attack:
    * https://github.com/CORIONplatform/solidity/issues/6,
    * https://drive.google.com/file/d/0ByMtMw2hul0EN3NCaVFHSFdxRzA/view
    * but this function is required by ERC-20:
    * To prevent attack vectors like the one described on https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM/
    * and discussed on https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729 ,
    * clients SHOULD make sure to create user interfaces in such a way that they set the allowance first to 0 before
    * setting it to another value for the same spender.
    * THOUGH The contract itself shouldn’t enforce it, to allow backwards compatibility with contracts deployed before
    *
    * @param _spender The address which will spend the funds.
    * @param _value The amount of tokens to be spent.
    */
    function approve(address _spender, uint256 _value) public returns (bool success){
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
    * Overloaded approve function
    * see https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM/
    * @param _spender The address which will spend the funds.
    * @param _currentValue The current value of allowance for spender
    * @param _value The amount of tokens to be spent.
    */
    function approve(address _spender, uint256 _currentValue, uint256 _value) external returns (bool success){
        require(
            allowance[msg.sender][_spender] == _currentValue,
            "Current value in contract is different than provided current value"
        );
        return approve(_spender, _value);
    }

}

/*
* Token that can be burned by tokenholder
* see also: https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/token/ERC20/ERC20Burnable.sol
*/
contract BurnableToken is Token {

    /**
    * @param from Address of the tokenholder
    * @param value Amount of tokens burned
    * @param by Address who send transaction to burn tokens
    */
    event TokensBurned(address indexed from, uint256 value, address by);

    /*
    * @param _from Tokenholder address
    * @param _value Amount of tokens to burn
    *
    */
    function burnTokensFrom(address _from, uint256 _value) public returns (bool success){

        require(msg.sender == _from || _value <= allowance[_from][msg.sender], "Sender not authorized");
        require(_value <= balanceOf[_from], "Account doesn't have required amount");

        balanceOf[_from] = balanceOf[_from].sub(_value);
        totalSupply = totalSupply.sub(_value);

        // If allowance used, change allowances correspondingly
        if (_from != msg.sender) {
            allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        }

        emit Transfer(_from, address(0), _value);
        emit TokensBurned(_from, _value, msg.sender);

        return true;
    }

    function burnTokens(uint256 _value) external returns (bool success){
        return burnTokensFrom(msg.sender, _value);
    }

}

/**
* see: https://www.cryptonomica.net/#!/verifyEthAddress/
* in our bills of exchange smart contracts:
* 1) every new admin should have a verified identity on cryptonomica.net
* 2) every person that signs (draw or accept) a bill should be verified
*/
contract CryptonomicaVerification {

    /**
    * @param _address The address to check
    * @return 0 if key certificate is not revoked, or Unix time of revocation
    */
    function revokedOn(address _address) external view returns (uint unixTime);

    /**
    * @param _address The address to check
    * @return Unix time
    */
    function keyCertificateValidUntil(address _address) external view returns (uint unixTime);
}

/*
* Universal functions for smart contract management
*/
contract ManagedContract {

    /*
    * smart contract that provides information about person that owns given Ethereum address/key
    */
    CryptonomicaVerification public cryptonomicaVerification;

    /*
    * ledger of admins
    */
    mapping(address => bool) isAdmin;

    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "Only admin can do that");
        _;
    }

    /**
    * @param from Old address
    * @param to New address
    * @param by Who made a change
    */
    event CryptonomicaVerificationContractAddressChanged(address from, address to, address indexed by);

    /**
    * @param _newAddress address of new contract to be used to verify identity of new admins
    */
    function changeCryptonomicaVerificationContractAddress(address _newAddress) public onlyAdmin returns (bool success) {

        emit CryptonomicaVerificationContractAddressChanged(address(cryptonomicaVerification), _newAddress, msg.sender);

        cryptonomicaVerification = CryptonomicaVerification(_newAddress);

        return true;
    }

    /**
    * @param added New admin address
    * @param addedBy Who added new admin
    */
    event AdminAdded(
        address indexed added,
        address indexed addedBy
    );

    /**
    * @param _newAdmin Address of new admin
    */
    function addAdmin(address _newAdmin) public onlyAdmin returns (bool success){

        require(
            cryptonomicaVerification.keyCertificateValidUntil(_newAdmin) > now,
            "New admin has to be verified on Cryptonomica.net"
        );

        // revokedOn returns uint256 (unix time), it's 0 if verification is not revoked
        require(
            cryptonomicaVerification.revokedOn(_newAdmin) == 0,
            "Verification for this address was revoked, can not add"
        );

        isAdmin[_newAdmin] = true;

        emit AdminAdded(_newAdmin, msg.sender);

        return true;
    }

    /**
    * @param removed Removed admin address
    * @param removedBy Who removed admin
    */
    event AdminRemoved(
        address indexed removed,
        address indexed removedBy
    );

    /**
    * @param _oldAdmin Address to remove from admins
    */
    function removeAdmin(address _oldAdmin) external onlyAdmin returns (bool){

        require(msg.sender != _oldAdmin, "Admin can not remove himself");

        isAdmin[_oldAdmin] = false;

        emit AdminRemoved(_oldAdmin, msg.sender);

        return true;
    }

    /* --- financial management */

    /*
    * address to send Ether from this contract
    */
    address payable public withdrawalAddress;

    /*
    * withdrawal address can be fixed (protected from changes),
    */
    bool public withdrawalAddressFixed = false;

    /*
    * @param from Old address
    * @param to New address
    * @param changedBy Who made this change
    */
    event WithdrawalAddressChanged(address indexed from, address indexed to, address indexed changedBy);

    /*
    * @param _withdrawalAddress address to which funds from this contract will be sent
    */
    function setWithdrawalAddress(address payable _withdrawalAddress) public onlyAdmin returns (bool success) {

        require(!withdrawalAddressFixed, "Withdrawal address already fixed");
        require(_withdrawalAddress != address(0), "Wrong address: 0x0");
        require(_withdrawalAddress != address(this), "Wrong address: contract itself");

        emit WithdrawalAddressChanged(withdrawalAddress, _withdrawalAddress, msg.sender);

        withdrawalAddress = _withdrawalAddress;

        return true;
    }

    /*
    * @param withdrawalAddressFixedAs Address for withdrawal
    * @param fixedBy Address who made this change (msg.sender)
    *
    * This event can be fired one time only
    */
    event WithdrawalAddressFixed(address indexed withdrawalAddressFixedAs, address indexed fixedBy);

    /**
    * @param _withdrawalAddress Address to which funds from this contract will be sent
    * This function can be called one time only.
    */
    function fixWithdrawalAddress(address _withdrawalAddress) external onlyAdmin returns (bool success) {

        // prevents event if already fixed
        require(!withdrawalAddressFixed, "Can't change, address fixed");

        // check, to prevent fixing wrong address
        require(withdrawalAddress == _withdrawalAddress, "Wrong address in argument");

        withdrawalAddressFixed = true;

        emit WithdrawalAddressFixed(withdrawalAddress, msg.sender);

        return true;
    }

    /**
    * @param to address to which ETH was sent
    * @param sumInWei sum sent (in wei)
    * @param by who made withdrawal (msg.sender)
    * @param success if withdrawal was successful
    */
    event Withdrawal(
        address indexed to,
        uint sumInWei,
        address indexed by,
        bool indexed success
    );

    /**
    * !!! can be called by any user or contract
    * possible warning: check for reentrancy vulnerability http://solidity.readthedocs.io/en/develop/security-considerations.html#re-entrancy
    * >>> since we are making a withdrawal to our own contract/address only there is no possible attack using re-entrancy vulnerability
    */
    function withdrawAllToWithdrawalAddress() external returns (bool success) {

        // http://solidity.readthedocs.io/en/develop/security-considerations.html#sending-and-receiving-ether
        // about <address>.send(uint256 amount) and <address>.transfer(uint256 amount)
        // see: http://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=transfer#address-related
        // https://ethereum.stackexchange.com/questions/19341/address-send-vs-address-transfer-best-practice-usage

        uint sum = address(this).balance;

        if (!withdrawalAddress.send(sum)) {// makes withdrawal and returns true (success) or false

            emit Withdrawal(withdrawalAddress, sum, msg.sender, false);

            return false;
        }

        emit Withdrawal(withdrawalAddress, sum, msg.sender, true);

        return true;
    }

}

/*
* This is a model contract where some paid service provided and there is a price
* (in main function we can check if msg.value >= price)
*/
contract ManagedContractWithPaidService is ManagedContract {

    uint256 public price;

    /*
    * @param from The old price
    * @param to The new price
    * @param by Who changed the price
    */
    event PriceChanged(uint256 from, uint256 to, address indexed by);

    /*
    * @param _newPrice The new price for the service
    */
    function changePrice(uint256 _newPrice) public onlyAdmin returns (bool success){
        emit PriceChanged(price, _newPrice, msg.sender);
        price = _newPrice;
        return true;
    }

}

/**
 * This contract represents a bunch of bills of exchange issued by one person at the same time and on the same conditions
 */
contract BillsOfExchange is BurnableToken {

    /* ---- Bill of Exchange requisites: */

    /**
    * Number of this contract in the ledger maintained by factory contract
    */
    uint256 public billsOfExchangeContractNumber;

    /**
    * Legal name of a person who issues the bill (drawer)
    * This can be a name of a company/organization or of a physical person
    */
    string public drawerName;

    /**
    * Ethereum address of the signer
    * His/her identity has to be verified via Cryptonomica.net smart contract
    */
    address public drawerRepresentedBy;

    /**
    * Link to information about signer's authority to represent the drawer
    * This should be a proof that signer can represent drawer
    * It can be link to public register like Companies House in U.K., or other proof.
    * Whosoever puts his signature on a bill of exchange as representing a person for whom he had no power to act is
    * bound himself as a party to the bill. The same rule applies to a representative who has exceeded his powers.
    */
    string public linkToSignersAuthorityToRepresentTheDrawer;

    /**
    * The name of the person who is to pay (drawee)
    */
    string public drawee;

    /**
    * Ethereum address of a person who can represent the drawee
    * This address should be verified via Cryptonomica.net smart contract
    */
    address public draweeSignerAddress;

    /**
    * This should be a proof that signer can represent drawee.
    */
    string  public linkToSignersAuthorityToRepresentTheDrawee;

    /*
    * Legal conditions to be included
    */
    string public description;
    string public order;
    string public disputeResolutionAgreement;
    CryptonomicaVerification public cryptonomicaVerification;

    /*
    *  a statement of the time of payment
    *  we use string to make possible variants like: '01 Jan 2021', 'at sight', 'at sight but not before 2019-12-31'
    *  '10 days after sight' etc.,
    * see https://www.jus.uio.no/lm/bills.of.exchange.and.promissory.notes.convention.1930/doc.html#109
    */
    string public timeOfPayment;

    // A statement of the date and of the place where the bill is issued
    uint256 public issuedOnUnixTime;
    string public placeWhereTheBillIsIssued; //  i.e. "London, U.K.";

    // a statement of the place where payment is to be made;
    // usually it is an address of the payer
    string public placeWherePaymentIsToBeMade;

    // https://en.wikipedia.org/wiki/ISO_4217
    // or crypto currency
    string public currency; // for example: "EUR", "USD"

    uint256 public sumToBePaidForEveryToken; //

    /*
    * number of signatures under disputeResolution agreement
    */
    uint256 public disputeResolutionAgreementSignaturesCounter;

    /*
    * @param signatoryAddress Ethereum address of the person, that signed the agreement
    * @param signatoryName Legal name of the person that signed agreement. This can be a name of a legal or physical
    * person
    */
    struct Signature {
        address signatoryAddress;
        string signatoryName;
    }

    mapping(uint256 => Signature) public disputeResolutionAgreementSignatures;

    /*
    * Event to be emitted when disputeResolution agreement was signed by new person
    * @param signatureNumber Number of the signature (see 'disputeResolutionAgreementSignaturesCounter')
    * @param singedBy Name of the person who signed disputeResolution agreement
    * @param representedBy Ethereum address of the person who signed disputeResolution agreement
    * @param signedOn Timestamp (Unix time)
    */
    event disputeResolutionAgreementSigned(
        uint256 indexed signatureNumber,
        string signedBy,
        address indexed representedBy,
        uint256 signedOn
    );

    /*
       * @param _signatoryAddress Ethereum address of the person who signs agreement
       * @param _signatoryName Name of the person that signs dispute resolution agreement
       */
    function signDisputeResolutionAgreementFor(
        address _signatoryAddress,
        string memory _signatoryName
    ) public returns (bool success){

        require(
            msg.sender == _signatoryAddress ||
            msg.sender == creator,
            "Not authorized to sign dispute resolution agreement"
        );

        // ! signer should have valid identity verification in cryptonomica.net smart contract:

        require(
            cryptonomicaVerification.keyCertificateValidUntil(_signatoryAddress) > now,
            "Signer has to be verified on Cryptonomica.net"
        );

        // revokedOn returns uint256 (unix time), it's 0 if verification is not revoked
        require(
            cryptonomicaVerification.revokedOn(_signatoryAddress) == 0,
            "Verification for this address was revoked, can not sign"
        );

        disputeResolutionAgreementSignaturesCounter++;

        disputeResolutionAgreementSignatures[disputeResolutionAgreementSignaturesCounter].signatoryAddress = _signatoryAddress;
        disputeResolutionAgreementSignatures[disputeResolutionAgreementSignaturesCounter].signatoryName = _signatoryName;

        emit disputeResolutionAgreementSigned(disputeResolutionAgreementSignaturesCounter, _signatoryName, msg.sender, now);

        return true;
    }

    function signDisputeResolutionAgreement(string calldata _signatoryName) external returns (bool success){
        return signDisputeResolutionAgreementFor(msg.sender, _signatoryName);
    }

    /**
    * set up new bunch of bills of exchange and sign dispute resolution agreement
    *
    * @param _billsOfExchangeContractNumber A number of this contract in the ledger ('billsOfExchangeContractsCounter' from BillsOfExchangeFactory)
    * @param _currency Currency of the payment, for example: "EUR", "USD"
    * @param _sumToBePaidForEveryToken The amount in the above currency, that have to be paid for every token (bill of exchange)
    * @param _drawerName The person who issues the bill (drawer)
    * @param _drawerRepresentedBy The Ethereum address of the signer
    * @param _linkToSignersAuthorityToRepresentTheDrawer Link to information about signers authority to represent the drawer
    * @param  _drawee The name of the person who is to pay (can be the same as drawer)
    */
    function initBillsOfExchange(
        uint256 _billsOfExchangeContractNumber,
        string calldata _currency,
        uint256 _sumToBePaidForEveryToken,
        string calldata _drawerName,
        address _drawerRepresentedBy,
        string calldata _linkToSignersAuthorityToRepresentTheDrawer,
        string calldata _drawee,
        address _draweeSignerAddress
    ) external {

        require(msg.sender == creator, "Only contract creator can call 'initBillsOfExchange' function");

        billsOfExchangeContractNumber = _billsOfExchangeContractNumber;

        // https://en.wikipedia.org/wiki/ISO_4217
        // or crypto currency
        currency = _currency;

        sumToBePaidForEveryToken = _sumToBePaidForEveryToken;

        // person who issues the bill (drawer)
        drawerName = _drawerName;
        drawerRepresentedBy = _drawerRepresentedBy;
        linkToSignersAuthorityToRepresentTheDrawer = _linkToSignersAuthorityToRepresentTheDrawer;

        // order to
        // (the name of the person who is to pay)
        drawee = _drawee;
        draweeSignerAddress = _draweeSignerAddress;

    }

    /**
    * Set places and time
    * not included in 'init' because of exception: 'Stack too deep, try using fewer variables.'
    * @param _timeOfPayment The time when payment has to be made
    * @param  _placeWhereTheBillIsIssued Place where the bills were issued. Usually it's the address of the drawer.
    * @param _placeWherePaymentIsToBeMade Place where the payment has to be made. Usually it's the address of the drawee.
    */
    function setPlacesAndTime(
        string calldata _timeOfPayment,
        string calldata _placeWhereTheBillIsIssued,
        string calldata _placeWherePaymentIsToBeMade
    ) external {

        require(msg.sender == creator, "Only contract creator can call 'setPlacesAndTime' function");

        // require(issuedOnUnixTime == 0, "setPlacesAndTime can be called one time only");
        // (this can be ensured in factory contract)

        issuedOnUnixTime = now;
        timeOfPayment = _timeOfPayment;

        placeWhereTheBillIsIssued = _placeWhereTheBillIsIssued;
        placeWherePaymentIsToBeMade = _placeWherePaymentIsToBeMade;

    }

    /*
    * @param _description Legal description of bills of exchange created.
    * @param _order Order to pay (text or the order)
    * @param _disputeResolutionAgreement Agreement about dispute resolution (text)
    * this function should be called only once - when initializing smart contract
    */
    function setLegal(
        string calldata _description,
        string calldata _order,
        string calldata _disputeResolutionAgreement,
        address _cryptonomicaVerificationAddress

    ) external {

        require(msg.sender == creator, "Only contract creator can call 'setLegal' function");

        // require(address(cryptonomicaVerification) == address(0), "setLegal can be called one time only");
        // (this can be ensured in factory contract)

        description = _description;
        order = _order;
        disputeResolutionAgreement = _disputeResolutionAgreement;
        cryptonomicaVerification = CryptonomicaVerification(_cryptonomicaVerificationAddress);

    }

    uint256 public acceptedOnUnixTime;

    /**
    * Drawee can accept only all bills in the smart contract, or not accept at all
    * @param acceptedOnUnixTime Time when drawee accepted bills
    * @param drawee The name of the drawee
    * @param draweeRepresentedBy The Ethereum address of the drawee's representative
    * (or drawee himself if he is a physical person)
    */
    event Acceptance(
        uint256 acceptedOnUnixTime,
        string drawee,
        address draweeRepresentedBy
    );

    /**
    * function for drawee to accept bill of exchange
    * see:
    * http://www.legislation.gov.uk/ukpga/Vict/45-46/61/section/17
    * https://www.jus.uio.no/lm/bills.of.exchange.and.promissory.notes.convention.1930/doc.html#69
    *
    * @param _linkToSignersAuthorityToRepresentTheDrawee Link to information about signer's authority to represent the drawee
    */
    function accept(string calldata _linkToSignersAuthorityToRepresentTheDrawee) external returns (bool success) {

        /*
        * this should be called only by address, previously indicated as drawee's address by the drawer
        * or by BillsOfExchangeFactory address via 'createAndAcceptBillsOfExchange' function
        */
        require(
            msg.sender == draweeSignerAddress ||
            msg.sender == creator,
            "Not authorized to accept"
        );

        signDisputeResolutionAgreementFor(draweeSignerAddress, drawee);

        linkToSignersAuthorityToRepresentTheDrawee = _linkToSignersAuthorityToRepresentTheDrawee;

        acceptedOnUnixTime = now;

        emit Acceptance(acceptedOnUnixTime, drawee, msg.sender);

        return true;
    }

}

/*
BillsOfExchangeFactory :
https://ropsten.etherscan.io/address/0xa535386ffa1019a3816730960eef0f5a88ede4a2
*/
//contract BillsOfExchangeFactory is ManagedContractWithPaidService, ManagedContractUsingCryptonomicaServices {
contract BillsOfExchangeFactory is ManagedContractWithPaidService {

    // using SafeMath for uint256;

    /*
    * Legal conditions to be included
    */
    string public description = "Every token (ERC20) in this smart contract is a bill of exchange in blank - payable to bearer (bearer is the owner of the Ethereum address witch holds the tokens, or the person he/she represents), but not to order - that means no endorsement possible and the token holder can only transfer the token (bill of exchange in blank) itself.";
    // string public forkClause = "";
    string public order = "Pay to bearer (tokenholder), but not to order, the sum defined for every token in currency defined in 'currency' (according to ISO 4217 standard; or XAU for for one troy ounce of gold, XBT or BTC for Bitcoin, ETH for Ether, DASH for Dash, ZEC for Zcash, XRP for Ripple, XMR for Monero, xEUR for xEuro)";
    string public disputeResolutionAgreement =
    "Any dispute, controversy or claim arising out of or relating to this bill(s) of exchange, including invalidity thereof and payments based on this bill(s), shall be settled by arbitration in accordance with the Cryptonomica Arbitration Rules (https://github.com/Cryptonomica/arbitration-rules) in the version in effect at the time of the filing of the claim. In the case of the Ethereum blockchain fork, the blockchain that has the highest hashrate is considered valid, and all others are not considered a valid registry; bill payment settles bill even if valid blockchain (hashrate) changes after the payment. All Ethereum test networks are not valid registries.";

    /**
    *  Constructor
    */
    constructor() public {

        isAdmin[msg.sender] = true;

        changePrice(0.15 ether);

        // Ropsten: > verification always valid for any address
        // TODO: change in production to https://etherscan.io/address/0x846942953c3b2A898F10DF1e32763A823bf6b27f <<<<<<<<
        // require(changeCryptonomicaVerificationContractAddress(0xE48BC3dB5b512d4A3e3Cd388bE541Be7202285B5)); // Ropsten
        require(changeCryptonomicaVerificationContractAddress(0x846942953c3b2A898F10DF1e32763A823bf6b27f));

        require(setWithdrawalAddress(msg.sender));
    }

    /**
    * every bills of exchange contract will have a number
    */
    uint256 public billsOfExchangeContractsCounter;

    /**
    * ledger bills of exchange contract number => bills of exchange contract address
    */
    mapping(uint256 => address) public billsOfExchangeContractsLedger;

    /*
    * @param _name Name of the token, also will be used for erc20 'symbol' property (see billsOfExchange.initToken )
    * @param _totalSupply Number (amount) of bills of exchange to create
    * @param __currency A currency in which bill payments have to be made, for example: "EUR", "USD"
    * @param _sumToBePaidForEveryToken A sum of each bill of exchange
    * @param _drawerName The name of the person (legal or physical) who issues the bill (drawer)
    * @param _drawee The name of the person (legal or physical) who is to pay (drawee)
    * @param __draweeSignerAddress Ethereum address of the person who has to accept bills of exchange in the name of
    * the drawee. Drawer has to agree this address with the drawee (acceptor) in advance.
    * @param _timeOfPayment Time when bill payment has to be made
    * @param _placeWhereTheBillIsIssued A statement of the place where the bill is issued.
    * Usual it's the address of the drawer.
    * @param _placeWherePaymentIsToBeMadeA statement of the place where payment is to be made.
    * Usual it's the address of the drawee.
    *
    * arguments to test this function in remix:
    * "Test Company Ltd. bills of exchange, Series TST01", "TST01", 100000000, "EUR",1,"Test Company Ltd, 3 Main Street, London, XY1Z  1XZ, U.K.; company # 12345678","https://beta.companieshouse.gov.uk/company/12345678/officers","Test Company Ltd, 3 Main Street, London, XY1Z  1XZ, U.K.; company # 12345678",0x07BaD6bda22A830f58fDA19eBA45552C44168600,"at sight but not before 01 Sep 2021","London, U.K.", "London, U.K."
    */
    function createBillsOfExchange(
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply,
        string memory _currency,
        uint256 _sumToBePaidForEveryToken,
        string memory _drawerName,
    // address _drawerRepresentedBy, // <<< msg.sender
        string memory _linkToSignersAuthorityToRepresentTheDrawer,
        string memory _drawee,
        address _draweeSignerAddress,
        string memory _timeOfPayment,
        string memory _placeWhereTheBillIsIssued,
        string memory _placeWherePaymentIsToBeMade
    ) public payable returns (address newBillsOfExchangeContractAddress) {

        require(msg.value >= price, "Payment sent was lower than the price for creating Bills of Exchange");

        BillsOfExchange billsOfExchange = new BillsOfExchange();
        billsOfExchangeContractsCounter++;
        billsOfExchangeContractsLedger[billsOfExchangeContractsCounter] = address(billsOfExchange);

        billsOfExchange.initToken(
            _name, //
            _symbol, // symbol
            _totalSupply,
            msg.sender // tokenOwner (drawer or drawer representative)
        );

        billsOfExchange.initBillsOfExchange(
            billsOfExchangeContractsCounter,
            _currency,
            _sumToBePaidForEveryToken,
            _drawerName,
            msg.sender,
            _linkToSignersAuthorityToRepresentTheDrawer,
            _drawee,
            _draweeSignerAddress
        );

        billsOfExchange.setPlacesAndTime(
            _timeOfPayment,
            _placeWhereTheBillIsIssued,
            _placeWherePaymentIsToBeMade
        );

        billsOfExchange.setLegal(
            description,
            order,
            disputeResolutionAgreement,
            address(cryptonomicaVerification)
        );

        /*
        * (!) Here we check if msg.sender has valid verification from 'cryptonomicaVerification' contract
        */
        billsOfExchange.signDisputeResolutionAgreementFor(msg.sender, _drawerName);

        return address(billsOfExchange);
    }

    /*
    * As above, but the drawer and the drawee are the same person, and bills will be accepted instantly
    *
    * arguments to test this function in remix:
    * "Test Company Ltd. bills of exchange, Series TST01", "TST01", 100000000, "EUR",1,"Test Company Ltd, 3 Main Street, London, XY1Z  1XZ, U.K.; company # 12345678","https://beta.companieshouse.gov.uk/company/12345678/officers","at sight but not before 01 Sep 2021","London, U.K.", "London, U.K."
    */
    function createAndAcceptBillsOfExchange(
        string memory _name, // name of the token
        string memory _symbol,
        uint256 _totalSupply,
        string memory _currency,
        uint256 _sumToBePaidForEveryToken,
        string memory _drawerName,
    // address _drawerRepresentedBy, // <<< msg.sender
        string memory _linkToSignersAuthorityToRepresentTheDrawer,
    // string  _drawee, > the same as drawer
    // address _draweeSignerAddress, > the same as msg.sender
        string memory _timeOfPayment,
        string memory _placeWhereTheBillIsIssued,
        string memory _placeWherePaymentIsToBeMade

    ) public payable returns (address newBillsOfExchangeContractAddress) {// if 'external' > "Stack to deep ..." error

        require(msg.value >= price, "Payment sent was lower than the price for creating Bills of Exchange");

        BillsOfExchange billsOfExchange = new BillsOfExchange();
        billsOfExchangeContractsCounter++;
        billsOfExchangeContractsLedger[billsOfExchangeContractsCounter] = address(billsOfExchange);

        billsOfExchange.initToken(
            _name, //
            _symbol, // symbol
            _totalSupply,
            msg.sender // tokenOwner (drawer or drawer representative)
        );

        billsOfExchange.initBillsOfExchange(
            billsOfExchangeContractsCounter,
            _currency,
            _sumToBePaidForEveryToken,
            _drawerName,
            msg.sender,
            _linkToSignersAuthorityToRepresentTheDrawer,
            _drawerName, // < _drawee,
            msg.sender // < _draweeSignerAddress
        );

        billsOfExchange.setPlacesAndTime(
            _timeOfPayment,
            _placeWhereTheBillIsIssued,
            _placeWherePaymentIsToBeMade
        );

        billsOfExchange.setLegal(
            description,
            order,
            disputeResolutionAgreement,
            address(cryptonomicaVerification)
        );

        // not needed to sign dispute resolution agreement here because signature is required by 'accept' function

        billsOfExchange.accept(_linkToSignersAuthorityToRepresentTheDrawer);

        return address(billsOfExchange);

    }

}