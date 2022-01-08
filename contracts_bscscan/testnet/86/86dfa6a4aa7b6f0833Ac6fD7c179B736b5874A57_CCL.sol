// SPDX-License-Identifier: UNLICENSED 
// CCL CONTRACT - The first verification service on Blockchain
// BY LOTUS NETWORK
// Addresses KYC - Crypto startups evaluation
// Users are able to link their wallets and deployed contracts with their info (KYC)
// To reduce scams and mantain privacy
// Designed to Link data to addresses
// Users are able to check the listed addresses 
// Through diffrent checkers on ltsfinance.com
// Addresses listed here will also be listed in 
// ltsccl.com explorer
// for projects and startups full reviews are published in CCL REPO
// Before apply read
// ltsccl.com/verification
// Our team is available for taking requests to analyze newly deployed contracts
// And warn about new rugpulls and scams at CCL TG 

pragma solidity ^0.8.9;

// OpenZeppelin
interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) { return msg.sender; }
    function _msgData() internal view virtual returns (bytes calldata) { return msg.data; }
}

// File: TransferHelper.sol
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }
    
    function safeTransferBaseToken(address token, address payable to, uint value, bool isERC20) internal {
        if (!isERC20) {
            to.transfer(value);
        } else {
            (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
            require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
        }
    }
}

library SafeMath {

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) { return a + b; }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) { return a - b; }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) { return a * b; }
    function div(uint256 a, uint256 b) internal pure returns (uint256) { return a / b; }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) { return a % b; }

    function sub(
        uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) { return _owner; }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract CCL is Context, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    IERC20 LTSToken = IERC20(address(0xDd1a6084e121C61D768Bf7450a373e49c7f025B5)); // LTS CONTRACT on BSC TEST
    IERC20 BNBToken = IERC20(address(0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd)); // WBNB CONTRACT on TEST NET
 //  uint256 private LTSCost; // Fees in LTS
 //  uint256 private BNBCost; // Fees in BNB
    uint256 private BNBCost = 1;
    uint256 private LTSCost = 1000;
    uint256 private MINIMUMLTS = 1000000; // MINIMUM LTS TO ACCSESS EXCLUSIVE FUNCTIONS [1 Million in deployment]

    struct Applications {
        uint256 ID;
        string NAME;
        string EMAIL;
        bool isCONTRACT; // User selection. For contracts verifications applicant will have to enter the contract address he which to verify. for wallets verification CCL contract will put a defult value of the wallet that had signed the transaction @note that in contracts verifications requestes, Applicant must sign the transaction from the deployer wallet. (Proof of ownership)
        address requestedADDRESS; // Applicant address
        address contractADDRESS; // For contract verifications 
        string CHAIN;
    }
        // Both fees paid in LTS and BNB will be used in marketing and liquidity refilling to ensure both price stability. 
        // And upwards movement.
        // @note Fees paid in LTS will be 25% less than BNB.
    address private constant ltsCCLTransactions = payable (0x9bfD837a4F7e8A0fB2E204d5740a62525321CE9D); // Company reserve wallet. Recieve fees paid in LTS TEST NET
    address private constant bnbCCLTransactions = payable (0x8997FeD0732d020b88647002E9B1657202E4Ba58); // CEO wallet. Recieve fees paid in BNB TEST NET
    address private constant CClAdministraton = 0x8997FeD0732d020b88647002E9B1657202E4Ba58;
    uint256 public totalRequests;  // Total Requestes

        // ARRAYS
    address[] private requestedAddrList;     // Applied addresses array [Public Access]
    address[] private verifiedWallets;   // Verified wallets array [Wallets verificaton only] [Public Access]
    address[] private verifiedContracts; // Verified contracts wallet [Contracts and businesses only] [Public Access]
    address[] private scamAddresses;     // Scam addresses list [Public Access]

        // MAPPINGS
    mapping(address => Applications) private Data;  // UserData Mapping
    mapping(address => bool) private isScam; // Indicates if address was/is involved in a scam or there is an ongoing case
    mapping(address => bool) private isSuspected; // Review of Newly deployed contracts [LTS HOLDER FEATURE]  
    mapping(address => bool) private isVerified; // WE need to check if the public address is verified or not 
    mapping(address => bool) private Requested;     // Indicates if user has an ongoing request
    mapping(address => uint256) private contractsEvaluation; // 

        // EVENTS
    event NewRequest(address indexed);      // Announce NewRequestes
    event NewWalletVerification(address indexed); // Announce NewVerified Addresses
    event NewContractVerification(address indexed); // Announce NewVerified Contracts
    event LTSFEEUPDATED(uint256 newFee);    // Announce FeeUpdate
    event BNBFEEUPDATED(uint256 newFee);    // Announce FeeUpdate
    event LTSPAYMENT(address indexed sender, address indexed CCLWallet, uint256 fee);
    event BNBPAYMENT(address indexed sender, address indexed BNBWallet, uint256 fee);
    event newSuspection(address indexed suspectedAddress); // Announce suspected addresses in blockchain
    event newScam(address indexed scamAddress); // Announce scam addresses in blockchain
    event SuspicionRemoved(address indexed suspectedAddress);

        //  Applicants requests section
    function newRequest (string memory _fullLegalName, string memory _email, bool payLTS, bool isContract, address _contract, string memory _Chain) external returns (bool) {
        Applications storage applications = Data[_msgSender()];
        applications.ID += 1;
        applications.NAME = _fullLegalName;
        applications.EMAIL = _email;
        applications.requestedADDRESS = _msgSender();
        applications.isCONTRACT = isContract;
        if(isContract) {
            applications.contractADDRESS = _contract;
        } else {
        applications.contractADDRESS = _msgSender(); }
        applications.CHAIN = _Chain;

        /* FEES DEDUCTION IN LTS OR WBNB
        if(payLTS) { 
            payInLTS();
        } else { 
            payInBNB();
        } */
        
        // Emittion
        totalRequests += 1;
        Requested[_msgSender()] = true;
        emit NewRequest(_msgSender());
        return true;
    }

        // 2 METHODS
    function lastApplications(address _addr) external view returns (string memory, string memory, address, bool, address, string memory) {
        if(CClAdministraton == _msgSender()) {
            string memory applicantName = Data[_addr].NAME;
            string memory applicantEmail = Data[_addr].EMAIL; 
            address requestedRAddress = Data[_addr].requestedADDRESS;
            bool isContract = Data[_addr].isCONTRACT;
            address contractAddress = Data[_addr].contractADDRESS;
            string memory _Chain = Data[_addr].CHAIN;
            return (applicantName, applicantEmail, requestedRAddress, isContract, contractAddress, _Chain);
             } else {
                 revert("This function only called through CCL"); 
             }
    }

        // PUBLIC CHECKERS
    function _isVerfiedAddress(address _addr) external view returns (bool) { return isVerified[_addr]; } // IF THIS ADDRESS IS VERIFIED BY THE CCL 
        // LTS HOLDERS CHECKERS
    function _isRequestedAddress(address _addr) private view returns (bool) { return Requested[_addr]; } // IF THIS ADDRESS HAS AN ONGOING REQUEST 
        // RETURNS SUSPECTED ADDRESSES/NEWLY DEPLOYED CONTRACTS INVESTIGATIONS
    function _isSusAddress(address _addr) private view returns (bool) { return(isSuspected[_addr]); }
    function getAddressState(address _addr, bool _condition) external LTSHOLDER nonReentrant returns(address ,bool) {
        require(_addr != address(0), "Address zero is not supported");
        if(_condition) { 
            bool ongoingRequest = _isRequestedAddress(_addr);
            return(_addr, ongoingRequest);
            // SUSPECTED ADDRESSES
        } else { 
            bool suspectedAdd = _isSusAddress(_addr);
            return(_addr, suspectedAdd);
        }
    }

        //  CCL ADMIN SECTION
        //  LTS HOLDER SHOULD SEND BOOL
        //  VERIFICATIONS & CCL MODIFIRES
    function verifyByCCL(address _addr, bool sContract) external nonReentrant() onlyOwner() { 
        require(!isScam[_addr], "Address belongs to scam addresses");
        require(!isVerified[_addr], "Address is already verified");
        require(!isSuspected[_addr], "Address is suspected");
        isVerified[_addr] = true;
        Requested[_addr] = false;
        if (sContract) { 
            verifiedContracts.push(_addr);
            emit NewContractVerification(_addr);
        } else { 
            verifiedWallets.push(_addr);
            emit NewWalletVerification(_addr);
        }
    }

        // Specially developed for newly deployed contracts
        // There is an impostor between Us, and this address is kinda sus [UwU]
    function newSUS(address _addr) external nonReentrant() onlyOwner() {
        require(!isSuspected[_addr], "Address is already in suspection list");
        require(!isVerified[_addr], "This address has completed the verification process");
        isSuspected[_addr] = true;
        emit newSuspection(_addr);
    }

        // SUSPICION REMOVE
        // Suspended state is the only state that can be removed
    function suspicionREMOVE(address _addr) external nonReentrant() onlyOwner() {
        require(isSuspected[_addr], "Address is not suspected");
        isSuspected[_addr] = false;
        emit SuspicionRemoved(_addr); 
    }

    function newSCAM(address _addr) external nonReentrant() onlyOwner() { 
        require(!isVerified[_addr], "Address is verified");
        require(!isScam[_addr], "Address is already Blacklisted");
        isScam[_addr] = true;
        scamAddresses.push(_addr);
        emit newScam(_addr);
    }

        // FEES MODIFIRES
    function ltsFEE(uint newFee) external nonReentrant() onlyOwner() {
        LTSCost = newFee;
        emit LTSFEEUPDATED(newFee);
    }

    function bnbFEE(uint newFee) external nonReentrant() onlyOwner() { 
        BNBCost = newFee;
        emit BNBFEEUPDATED(newFee);
    }

        // READ VALUES FROM CONTRACT 
    function bnbCosts() external view returns (uint256) { return BNBCost; }
    function ltsCosts() external view returns (uint256) { return LTSCost; }
    function minimumLTSToUnlockFeatures() external view returns (uint256) { return MINIMUMLTS; }

        // PAYMENT DEDUCTORS
    function payInLTS() private {
        require(LTSToken.balanceOf(_msgSender()) >= LTSCost * (10 ** 18), "Insufficient LTS Balance");
            TransferHelper.safeTransferFrom(address(LTSToken), _msgSender(), ltsCCLTransactions, LTSCost * (10 ** 18));
    }

    function payInBNB() private {
        require(BNBToken.balanceOf(_msgSender()) >= BNBCost * (10 ** 18), "Insufficient BNB Balance");
            TransferHelper.safeTransferFrom(address(BNBToken), _msgSender(), bnbCCLTransactions, BNBCost * (10 ** 18));
    } 

        //  LTS HOLDINGS CHECKERS 
        // LTS HOLDINGS CHECK [Modifier]
    modifier LTSHOLDER() {
        require(LTSToken.balanceOf(_msgSender()) >= MINIMUMLTS * (10 ** 18) , "THIS FEATURE REQUIRES LTS BALANCE TO BE UNLOCKED");
        _;
    }

        // LTS HOLDINGS INTERNAL CALCULATIONS
    function ltsHOLDINGS(address _addr) private view returns (bool) { 
        uint256 Balance = LTSToken.balanceOf(_addr);
        bool ltsHolder = Balance >= MINIMUMLTS * (10 ** 18);
        return(ltsHolder);
    } 
}