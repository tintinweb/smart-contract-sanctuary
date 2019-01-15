pragma solidity 0.4.24;
pragma experimental "v0.5.0";

interface RTCoinInterface {
    

    /** Functions - ERC20 */
    function transfer(address _recipient, uint256 _amount) external returns (bool);

    function transferFrom(address _owner, address _recipient, uint256 _amount) external returns (bool);

    function approve(address _spender, uint256 _amount) external returns (bool approved);

    /** Getters - ERC20 */
    function totalSupply() external view returns (uint256);

    function balanceOf(address _holder) external view returns (uint256);

    function allowance(address _owner, address _spender) external view returns (uint256);

    /** Getters - Custom */
    function mint(address _recipient, uint256 _amount) external returns (bool);

    function stakeContractAddress() external view returns (address);

    function mergedMinerValidatorAddress() external view returns (address);
    
    /** Functions - Custom */
    function freezeTransfers() external returns (bool);

    function thawTransfers() external returns (bool);
}

library SafeMath {

  // We use `pure` bbecause it promises that the value for the function depends ONLY
  // on the function arguments
    function mul(uint256 a, uint256 b) internal pure  returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}

/// @title TEMPORAL Payment Contract
/// @author Postables, RTrade Technologies Ltd
/// @dev We able V5 for safety features, see https://solidity.readthedocs.io/en/v0.4.24/security-considerations.html#take-warnings-seriously
contract Payments {
    using SafeMath for uint256;    

    // we mark as constant private to save gas
    bytes constant private PREFIX = "\x19Ethereum Signed Message:\n32";
    // these addresses will need to be changed before deployment, and validated after deployment
    // we hardcode them for security reasons to avoid any possible risk of compromised accounts being able to change anything on this contract.
    // in the event that one of the addresses is compromised, the contract will be self destructed
    address constant private SIGNER = 0xa80cD01dD37c29116549AA879c44C824b703828A;
    address constant private TOKENADDRESS = 0xecc043b92834c1ebDE65F2181B59597a6588D616;
    address constant private HOTWALLET = 0x3eC6481365c2c2b37d7b939B5854BFB7e5e83C10;
    RTCoinInterface constant private RTI = RTCoinInterface(TOKENADDRESS);
    string constant public VERSION = "production";

    address public admin;

    // PaymentState will keep track of the state of a payment, nil means we havent seen th payment before
    enum PaymentState{ nil, paid }
    // How payments can be made, RTC or eth
    enum PaymentMethod{ RTC, ETH }

    struct PaymentStruct {
        uint256 paymentNumber;
        uint256 chargeAmountInWei;
        PaymentMethod method;
        PaymentState state;
    }

    mapping (address => uint256) public numPayments;
    mapping (address => mapping(uint256 => PaymentStruct)) public payments;

    event PaymentMade(address _payer, uint256 _paymentNumber, uint8 _paymentMethod, uint256 _paymentAmount);

    modifier validPayment(uint256 _paymentNumber) {
        require(payments[msg.sender][_paymentNumber].state == PaymentState.nil, "payment already made");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "sender must be admin");
        _;
    }

    constructor() public {
        admin = msg.sender;
    }

    /** @notice Used to submit a payment for TEMPORAL uploads
        * @dev Can use ERC191 or non ERC191 signed messages
        * @param _h This is the message hash that has been signed
        * @param _v This is pulled from the signature
        * @param _r This is pulled from the signature
        * @param _s This is pulled from the signature
        * @param _paymentNumber This is the current payments number (how many payments the user has submitted)
        * @param _paymentMethod This is the payment method (RTC, ETH) being used
        * @param _chargeAmountInWei This is how much the user is to be charged
        * @param _prefixed This indicates whether or not the signature was generated using ERC191 standards
     */
    function makePayment(
        bytes32 _h,
        uint8   _v,
        bytes32 _r,
        bytes32 _s,
        uint256 _paymentNumber,
        uint8   _paymentMethod,
        uint256 _chargeAmountInWei,
        bool   _prefixed) // this allows us to sign messages on our own, without prefix https://github.com/ethereum/EIPs/issues/191
        public
        payable
        validPayment(_paymentNumber)
        returns (bool)
    {
        require(_paymentMethod == 0 || _paymentMethod == 1, "invalid payment method");
        bytes32 image;
        if (_prefixed) {
            bytes32 preimage = generatePreimage(_paymentNumber, _chargeAmountInWei, _paymentMethod);
            image = generatePrefixedPreimage(preimage);
        } else {
            image = generatePreimage(_paymentNumber, _chargeAmountInWei, _paymentMethod);
        }
        // ensure that the preimages construct properly
        require(image == _h, "reconstructed preimage does not match");
        address signer = ecrecover(_h, _v, _r, _s);
        // ensure that we actually signed this message
        require(signer == SIGNER, "recovered signer does not match");
        PaymentStruct memory ps = PaymentStruct({
            paymentNumber: _paymentNumber,
            chargeAmountInWei: _chargeAmountInWei,
            method: PaymentMethod(_paymentMethod),
            state: PaymentState.paid
        });
        payments[msg.sender][_paymentNumber] = ps;
        numPayments[msg.sender] = numPayments[msg.sender].add(1);
        // if they are opting to pay in eth run this block of code, otherwise make the payment in RTC
        if (PaymentMethod(_paymentMethod) == PaymentMethod.ETH) {
            require(msg.value == _chargeAmountInWei, "msg.value does not equal charge amount");
            emit PaymentMade(msg.sender, _paymentNumber, _paymentMethod, _chargeAmountInWei);
            HOTWALLET.transfer(msg.value);
            return true;
        }
        emit PaymentMade(msg.sender, _paymentNumber, _paymentMethod, _chargeAmountInWei);
        require(RTI.transferFrom(msg.sender, HOTWALLET, _chargeAmountInWei), "trasferFrom failed, most likely needs approval");
        return true;
    }

    /** @notice This is a helper function used to verify whether or not the provided arguments can reconstruct the message hash
        * @param _h This is the message hash which is signed, and will be reconstructed
        * @param _paymentNumber This is the number of payment
        * @param _paymentMethod This is the payment method (RTC, ETH) being used
        * @param _chargeAmountInWei This is the amount the user is to be charged
        * @param _prefixed This indicates whether the message was signed according to ERC191
     */
    function verifyImages(
        bytes32 _h,
        uint256 _paymentNumber,
        uint8   _paymentMethod,
        uint256 _chargeAmountInWei,
        bool   _prefixed)
        public
        view
        returns (bool)
    {
        require(_paymentMethod == 0 || _paymentMethod == 1, "invalid payment method");
        bytes32 image;
        if (_prefixed) {
            bytes32 preimage = generatePreimage(_paymentNumber, _chargeAmountInWei, _paymentMethod);
            image = generatePrefixedPreimage(preimage);
        } else {
            image = generatePreimage(_paymentNumber, _chargeAmountInWei, _paymentMethod);
        }
        return image == _h;
    }

    /** @notice This is a helper function which can be used to verify the signer of a message
        * @param _h This is the message hash that is signed
        * @param _v This is pulled from the signature
        * @param _r This is pulled from the signature
        * @param _s This is pulled from the signature
        * @param _paymentNumber This is the payment number of this particular payment
        * @param _paymentMethod This is the payment method (RTC, ETH) being used
        * @param _chargeAmountInWei This is the amount hte user is to be charged
        * @param _prefixed This indicates whether or not the message was signed using ERC191
     */
    function verifySigner(
        bytes32 _h,
        uint8   _v,
        bytes32 _r,
        bytes32 _s,
        uint256 _paymentNumber,
        uint8   _paymentMethod,
        uint256 _chargeAmountInWei,
        bool   _prefixed)
        public
        view
        returns (bool)
    {
        require(_paymentMethod == 0 || _paymentMethod == 1, "invalid payment method");
        bytes32 image;
        if (_prefixed) {
            bytes32 preimage = generatePreimage(_paymentNumber, _chargeAmountInWei, _paymentMethod);
            image = generatePrefixedPreimage(preimage);
        } else {
            image = generatePreimage(_paymentNumber, _chargeAmountInWei, _paymentMethod);
        }
        require(image == _h, "failed to reconstruct preimages");
        return ecrecover(_h, _v, _r, _s) == SIGNER;
    }

    /** @notice This is a helper function used to generate a non ERC191 signed message hash
        * @param _paymentNumber This is the payment number of this payment
        * @param _chargeAmountInWei This is the amount the user is to be charged
        * @param _paymentMethod This is the payment method (RTC, ETH) being used
     */
    function generatePreimage(
        uint256 _paymentNumber,
        uint256 _chargeAmountInWei,
        uint8   _paymentMethod)
        internal
        view
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(msg.sender, _paymentNumber, _paymentMethod, _chargeAmountInWei));
    }

    /** @notice This is a helper function that prepends the ERC191 signed message prefix
        * @param _preimage This is the reconstructed message hash before being prepened with the ERC191 prefix
     */
    function generatePrefixedPreimage(bytes32 _preimage) internal pure returns (bytes32)  {
        return keccak256(abi.encodePacked(PREFIX, _preimage));
    }

    /** @notice Used to destroy the contract
     */
    function goodNightSweetPrince() public onlyAdmin returns (bool) {
        selfdestruct(msg.sender);
        return true;
    }
}