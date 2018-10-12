pragma solidity ^0.4.24;

/**
 * Website: www.project424.us
 *
 * Telegram: https://t.me/joinchat/AAAAAEs1qQpgna4DHacHlg
 *
 * RECOMMENDED GAS LIMIT: 200000
 * RECOMMENDED GAS PRICE: https://ethgasstation.info/
 *
 */

library SafeMath {

    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
        if (_a == 0) {
            return 0;
        }

        uint256 c = _a * _b;
        require(c / _a == _b);

        return c;
    }

    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b > 0);
        uint256 c = _a / _b;

        return c;
    }

    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a);
        uint256 c = _a - _b;

        return c;
    }

    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a);

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract InvestorsStorage {
    address private owner;

    mapping (address => Investor) private investors;

    struct Investor {
        uint deposit;
        uint checkpoint;
    }

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function updateInfo(address _address, uint _value) external onlyOwner {
        investors[_address].deposit += _value;
        investors[_address].checkpoint = block.timestamp;
    }

    function updateCheckpoint(address _address) external onlyOwner {
        investors[_address].checkpoint = block.timestamp;
    }

    function d(address _address) external view onlyOwner returns(uint) {
        return investors[_address].deposit;
    }

    function c(address _address) external view onlyOwner returns(uint) {
        return investors[_address].checkpoint;
    }

    function getInterest(address _address) external view onlyOwner returns(uint) {
        if (investors[_address].deposit < 4240000000000000000) {
            return 424;
        } else {
            return 600;
        }
    }
}

contract Project424 {
    using SafeMath for uint;

    address public owner;
    address admin;
    address marketing;

    uint waveStartUp;
    uint nextPayDay;

    event LogInvestment(address _addr, uint _value);
    event LogPayment(address _addr, uint _value);
    event LogReferralInvestment(address _referral, address _referrer, uint _value);
    event LogNewWave(uint _waveStartUp);

    InvestorsStorage private x;

    modifier notOnPause() {
        require(waveStartUp <= block.timestamp);
        _;
    }

    function renounceOwnership() external {
        require(msg.sender == owner);
        owner = 0x0;
    }

    function bytesToAddress(bytes _source) internal pure returns(address parsedReferrer) {
        assembly {
            parsedReferrer := mload(add(_source,0x14))
        }
        return parsedReferrer;
    }

    function toReferrer(uint _value) internal {
        address _referrer = bytesToAddress(bytes(msg.data));
        if (_referrer != msg.sender) {
            _referrer.transfer(_value / 20);
            emit LogReferralInvestment(msg.sender, _referrer, _value);
        }
    }

    constructor(address _admin, address _marketing) public {
        owner = msg.sender;
        admin = _admin;
        marketing = _marketing;
        x = new InvestorsStorage();
    }

    function getInfo(address _address) external view returns(uint deposit, uint amountToWithdraw) {
        deposit = x.d(_address);
        amountToWithdraw = block.timestamp.sub(x.c(_address)).div(1 days).mul(x.d(_address).mul(x.getInterest(_address)).div(10000));
    }

    function() external payable {
        if (msg.value == 0) {
            withdraw();
        } else {
            invest();
        }
    }

    function invest() notOnPause public payable {

        admin.transfer(msg.value * 5 / 100);
        marketing.transfer(msg.value / 10);

        if (x.d(msg.sender) > 0) {
            withdraw();
        }

        x.updateInfo(msg.sender, msg.value);

        if (msg.data.length == 20) {
            toReferrer(msg.value);
        }

        emit LogInvestment(msg.sender, msg.value);
    }

    function withdraw() notOnPause public {

        if (address(this).balance < 100000000000000000) {
            nextWave();
            return;
        }

        uint _payout = block.timestamp.sub(x.c(msg.sender)).div(1 days).mul(x.d(msg.sender).mul(x.getInterest(msg.sender)).div(10000));
        x.updateCheckpoint(msg.sender);

        if (_payout > 0) {
            msg.sender.transfer(_payout);
            emit LogPayment(msg.sender, _payout);
        }
    }

    function nextWave() private {
        x = new InvestorsStorage();
        waveStartUp = block.timestamp + 7 days;
        emit LogNewWave(waveStartUp);
    }
}