//SourceUnit: supplementary.sol

pragma solidity ^0.5.4;

interface TTS { 
    function balanceOf(address account) external view returns (uint256); 
    function totalSupply() external view returns (uint256);
    function mint(address account, uint256 value) external;
}

interface BankContract {
    function buyToken(address addr, uint256 amount, string calldata trxID) external payable;
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}


contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
 
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner; 
    }
}



contract Supplementary is Ownable {
    using SafeMath for uint256;
    address public BankAddress;
    address public TTS_Contract;
    address payable public backend;

    uint256 _cap = 70000000 * 1e18;
    uint256 ADMIN_PERCENT = 10;
    uint256 counter = 0;

    mapping (address => bool) private hasAccess;

    event AddToAccessList (address addr);

    constructor (address tts_Contract, address payable backEndAddr, address bank_address) public{
        BankAddress = bank_address;
        TTS_Contract = tts_Contract;
        backend = backEndAddr;
    }    

    function buyToken(address addr, uint256 amount, string memory trxID) public payable onlyAccessor {
        TTS tts = TTS(TTS_Contract);     
        uint256 balance = tts.balanceOf(BankAddress);
        if (balance < amount) {
            _product(amount);
        }
        BankContract bank = BankContract(BankAddress);
        bank.buyToken.value(msg.value)(addr, amount, trxID);
    }

    function buyTokenWithEconomicValue(address payable addr, string memory trxID) public payable onlyAccessor returns(uint256, uint256) {
        TTS tts = TTS(TTS_Contract);     
        uint256 pricePerUnit = getEconomicValue();

        uint256 trxAmount = msg.value;
        uint256 adminPercent = trxAmount.mul(ADMIN_PERCENT).div(1000);

        uint256 ttsAmount = trxAmount.sub(adminPercent).mul(1e16).div(pricePerUnit);
        uint256 payBackTRX;
        
        uint256 balance = tts.balanceOf(BankAddress);
        if (balance < ttsAmount) {
            balance = balance.add(_product(ttsAmount));
            if (balance < ttsAmount) {
                ttsAmount = balance;
                uint256 trxa = ttsAmount.mul(pricePerUnit).div(1e16);
                adminPercent = trxa.mul(ADMIN_PERCENT).div(1000);
                payBackTRX = trxAmount;
                trxAmount = trxa.add(adminPercent);
                payBackTRX = payBackTRX.sub(trxAmount);
            }
        }
         
        if (payBackTRX > 0) {
            addr.transfer(payBackTRX);
        }

        adminPercent = trxAmount.mul(ADMIN_PERCENT).div(1000);
        backend.transfer(adminPercent);
        trxAmount = trxAmount.sub(adminPercent);
        BankContract bank = BankContract(BankAddress);   
        bank.buyToken.value(trxAmount)(addr, ttsAmount, trxID);
        return (ttsAmount, payBackTRX);
    }
    

    function _product(uint256 amount) private returns (uint256) {
        TTS tts = TTS(TTS_Contract);     
        uint256 totalSupply = tts.totalSupply();
        
        if (totalSupply.add(amount) > _cap)
            amount = _cap.sub(totalSupply);
        if (amount == 0)
            return 0;

        tts.mint(BankAddress, amount);
        return amount;
    }

    function setAdminPercent(uint256 percent) public onlyOwner{
        require (percent <= 40, "admin percent limit exceeded!");
        ADMIN_PERCENT = percent;
    }
    
    function getIntrinsicValue() public view returns (uint256 currentPrice) {
        TTS tts = TTS(TTS_Contract);
        uint256 currentBalance = BankAddress.balance.mul(1000000);
        uint256 outsideTokens = tts.totalSupply().sub(tts.balanceOf(BankAddress)).div(10000000000);

        uint256 pricePerUnit = currentBalance.div(outsideTokens);
        return pricePerUnit;
    }

    function getEconomicValue() public view returns (uint256 currentPrice) {
        TTS tts = TTS(TTS_Contract);
        uint256 currentBalance = BankAddress.balance.mul(1000000);
        uint256 outsideTokens = tts.totalSupply().sub(tts.balanceOf(BankAddress)).div(10000000000);

        uint256 pricePerUnit = currentBalance.div(outsideTokens).mul(107).div(100);
        return pricePerUnit;
    }

    function addAddress(address addr) public onlyOwner {
        hasAccess[addr] = true;
        emit AddToAccessList(addr);
    }

    modifier onlyAccessor() {
        require(hasAccess[msg.sender], "caller cannot access this function!");
        _;
    }  
}