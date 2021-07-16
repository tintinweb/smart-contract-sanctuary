//SourceUnit: exchahger.sol

pragma solidity ^0.5.4;

/*****
******
Developers Signature(MD5 Hash) : d6b0169c679a33d9fb19562f135ce6ee
******
*****/


interface TTS { 
    function transfer(address _to, uint256 _value) external returns (bool success) ; 
    function balanceOf(address account) external view returns (uint256); 
    function totalSupply() external view returns (uint256);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
}

interface tokenRecipient { function receiveApproval(address payable _from, uint256 _value, address _token, bytes calldata _extraData) external; }


contract Ownable {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}


contract TTS_Bank  is Ownable, tokenRecipient {
    using SafeMath for uint256;

    address public TTS_Contract;
    address payable private main_wallet;
    address private _backEndWallet;

    uint256 ADMIN_PERCESNT = 4;

    mapping (string => bool) usedHashes;

    uint256 public totalTTSReceived;
    uint256 public totalTTSSent;
    uint256 public totaltrxReceived;
    uint256 public totaltrxSent;
    


    struct trxn {
        uint256[] trx_amount;
        uint256[] tts_amount;
        bool[] buy;
    }

    mapping (address => trxn) private trxns;

    constructor(address payable wallet, address tts, address backEnd) public payable{
        TTS_Contract = tts;
        main_wallet = wallet;
        _backEndWallet = backEnd;
    }

    function() external payable{
    }

    modifier onlyBackEnd() {
        require(_backEndWallet == msg.sender, "caller is not the backend wallet");
        _;
    }

    function receiveApproval(address payable _from, uint256 _value, address _token, bytes memory _extraData) public {
        require(TTS_Contract == _token);
        require(TTS_Contract == msg.sender);
        
        TTS tts = TTS(TTS_Contract);
        uint256 pricePerUnit = getPrice(tts);

        require(tts.transferFrom(_from, address(this), _value));
        uint256 adminPercent = _value.mul(ADMIN_PERCESNT).div(100);
        require(tts.transfer(main_wallet, adminPercent));

        _value = _value.sub(adminPercent);
        
        totalTTSReceived = totalTTSReceived.add(_value);
        trxns[_from].tts_amount.push(_value);

        _value = _value.div(1000000000000);

        uint256 money = _value.mul(pricePerUnit).div(100000000);
        _from.transfer(money);
        
        totaltrxSent = totaltrxSent.add(money);

        trxns[_from].trx_amount.push(money);
        trxns[_from].buy.push(false);
    }

    function setBackendAddress(address addr) public onlyOwner{
        _backEndWallet = addr;
    }

    function setAdminPercent(uint256 percent) public onlyOwner{
        require (percent <= 4, "admin percent limit exceeded!");
        ADMIN_PERCESNT = percent;
    }

    function getPrice(TTS tts) private view returns (uint256 currentPrice){
        uint256 currentBalance = address(this).balance.mul(100000000);
        uint256 outsideTokens = tts.totalSupply().sub(tts.balanceOf(address(this))).div(1000000000000);

        uint256 pricePerUnit = currentBalance.div(outsideTokens);
        return pricePerUnit;
    }

    function checkTrxn(string memory trxnID) public view returns (bool used){
        return usedHashes[trxnID];
    }

    function buyToken(address addr, uint256 amount, string memory txnID) public payable onlyBackEnd{
        require(!usedHashes[txnID], "redundent hash!");
        usedHashes[txnID] = true;
        TTS tts = TTS(TTS_Contract);
        tts.transfer(addr, amount);

        totalTTSSent = totalTTSSent.add(amount);
        totaltrxReceived = totaltrxReceived.add(msg.value);

        trxns[addr].trx_amount.push(msg.value);
        trxns[addr].tts_amount.push(amount);
        trxns[addr].buy.push(true);
    }

    function getData(address addr) public view returns(uint256[] memory tts_amount,uint256[] memory trx_amount, bool[] memory isBuy){
        return (trxns[addr].tts_amount,trxns[addr].trx_amount,trxns[addr].buy);
    }
}