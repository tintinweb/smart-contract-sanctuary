pragma solidity ^0.4.24;

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
        require(b > 0); // Solidity only automatically asserts when dividing by 0
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

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }


    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

}

/* Required code start */
contract MarketplaceProxy {
    function calculatePlatformCommission(uint256 weiAmount) public view returns (uint256);
    function payPlatformIncomingTransactionCommission(address clientAddress) public payable;
    function payPlatformOutgoingTransactionCommission() public payable;
    function isUserBlockedByContract(address contractAddress) public view returns (bool);
}
/* Required code end */

contract Deposit is Ownable {

    using SafeMath for uint256;

    struct ClientDeposit {
        uint256 balance;
        // We should reject incoming transactions on payable 
        // methods that not equals this variable
        uint256 nextPaymentTotalAmount;
        uint256 nextPaymentPlatformCommission;
        bool exists;
        bool isBlocked;
    }
    mapping(address => ClientDeposit) public depositsMap;

    /* Required code start */
    MarketplaceProxy public mp;
    event PlatformIncomingTransactionCommission(uint256 amount, address clientAddress);
    event PlatformOutgoingTransactionCommission(uint256 amount);
    event Blocked();
    /* Required code end */

    constructor () public {
        /* Required code start */
        // NOTE: CHANGE ADDRESS ON PRODUCTION
        mp = MarketplaceProxy(0x7b71342582610452641989D599a684501922Cb57);
        /* Required code end */
    }

    /**
     * @dev Handles direct clients transactions
     */
    function () public payable {
        handleIncomingPayment(msg.sender, msg.value);
    }

    /**
     * @dev Handles payment gateway transactions
     * @param clientAddress when payment method is fiat money
     */
    function fromPaymentGateway(address clientAddress) public payable {
        handleIncomingPayment(clientAddress, msg.value);
    }

    /**
     * @dev Send commission to marketplace and increases client balance
     * @param clientAddress client wallet for deposit
     * @param amount transaction value (msg.value)
     */
    function handleIncomingPayment(address clientAddress, uint256 amount) private {
        ClientDeposit storage clientDeposit = depositsMap[clientAddress];

        require(clientDeposit.exists);
        require(clientDeposit.nextPaymentTotalAmount == amount);

        /* Required code start */
        // Send all incoming eth if user blocked
        if (mp.isUserBlockedByContract(address(this))) {
            mp.payPlatformIncomingTransactionCommission.value(amount)(clientAddress);
            emit Blocked();
        } else {
            mp.payPlatformIncomingTransactionCommission.value(clientDeposit.nextPaymentPlatformCommission)(clientAddress);
            emit PlatformIncomingTransactionCommission(clientDeposit.nextPaymentPlatformCommission, clientAddress);
        }
        /* Required code end */

        // Virtually add ETH to client deposit (sended ETH subtract platform commission)
        clientDeposit.balance += amount.sub(clientDeposit.nextPaymentPlatformCommission);
    }

    /**
     * @dev Owner can add ETH to contract without commission
     */
    function addEth() public payable onlyOwner {

    }

    /**
     * @dev Owner can transfer ETH from contract to address
     * @param to address
     * @param amount 18 decimals (wei)
     */
    function transferEthTo(address to, uint256 amount) public onlyOwner {
        require(address(this).balance > amount);

        /* Required code start */
        // Get commission amount from marketplace
        uint256 commission = mp.calculatePlatformCommission(amount);

        require(address(this).balance > amount.add(commission));

        // Send commission to marketplace
        mp.payPlatformOutgoingTransactionCommission.value(commission)();
        emit PlatformOutgoingTransactionCommission(commission);
        /* Required code end */

        to.transfer(amount);
    }

    /**
     * @dev Send client&#39;s balance to some address on claim
     * @param from client address
     * @param to send ETH on this address
     * @param amount 18 decimals (wei)
     */
    function claim(address from, address to, uint256 amount) public onlyOwner{
        require(depositsMap[from].exists);

        /* Required code start */
        // Get commission amount from marketplace
        uint256 commission = mp.calculatePlatformCommission(amount);

        require(address(this).balance > amount.add(commission));
        require(depositsMap[from].balance > amount);

        // Send commission to marketplace
        mp.payPlatformOutgoingTransactionCommission.value(commission)();
        emit PlatformOutgoingTransactionCommission(commission);
        /* Required code end */

        // Virtually subtract amount from client deposit
        depositsMap[from].balance -= amount;

        to.transfer(amount);
    }

    /**
     * @return bool, client exist or not
     */
    function isClient(address clientAddress) public view onlyOwner returns(bool) {
        return depositsMap[clientAddress].exists;
    }

    /**
     * @dev Add new client to structure
     * @param clientAddress wallet
     * @param _nextPaymentTotalAmount reject next incoming payable transaction if it&#39;s amount not equal to this variable
     * @param _nextPaymentPlatformCommission marketplace commission to send
     */
    function addClient(address clientAddress, uint256 _nextPaymentTotalAmount, uint256 _nextPaymentPlatformCommission) public onlyOwner {
        require( (clientAddress != address(0)));

        // Can be called only once for address
        require(!depositsMap[clientAddress].exists);

        // Add new element to structure
        depositsMap[clientAddress] = ClientDeposit(
            0,                                  // balance
            _nextPaymentTotalAmount,            // nextPaymentTotalAmount
            _nextPaymentPlatformCommission,     // nextPaymentPlatformCommission
            true,                               // exists
            false                               // isBlocked
        );
    }

    /**
     * @return uint256 client balance
     */
    function getClientBalance(address clientAddress) public view returns(uint256) {
        return depositsMap[clientAddress].balance;
    }

    /**
     * @dev Update client payment details
     * @param clientAddress wallet
     * @param _nextPaymentTotalAmount reject next incoming payable transaction if it&#39;s amount not equal to this variable
     * @param _nextPaymentPlatformCommission marketplace commission to send
     */
    function repeatedPayment(address clientAddress, uint256 _nextPaymentTotalAmount, uint256 _nextPaymentPlatformCommission) public onlyOwner {
        ClientDeposit storage clientDeposit = depositsMap[clientAddress];

        require(clientAddress != address(0));
        require(clientDeposit.exists);

        clientDeposit.nextPaymentTotalAmount = _nextPaymentTotalAmount;
        clientDeposit.nextPaymentPlatformCommission = _nextPaymentPlatformCommission;
    }
}