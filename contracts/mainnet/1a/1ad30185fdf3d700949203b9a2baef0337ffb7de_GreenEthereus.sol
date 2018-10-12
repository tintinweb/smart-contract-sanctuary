pragma solidity 0.4.25;


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

contract GreenEthereus {
    using SafeMath for uint;

    address public owner;
    address marketing;
    address admin;

    mapping (address => uint) index;
    mapping (address => mapping (uint => uint)) deposit;
    mapping (address => mapping (uint => uint)) finish;
    mapping (address => uint) checkpoint;

    mapping (address => address) referrers;
    mapping (address => uint) refBonus;

    event LogInvestment(address _addr, uint _value);
    event LogPayment(address _addr, uint _value);
    event LogNewReferrer(address _referral, address _referrer);
    event LogReferralInvestment(address _referral, uint _value);

    constructor(address _marketing, address _admin) public {
        owner = msg.sender;
        marketing = _marketing;
        admin = _admin;
    }

    function renounceOwnership() external {
        require(msg.sender == owner);
        owner = 0x0;
    }

    function bytesToAddress(bytes _source) internal pure returns(address parsedreferrer) {
        assembly {
            parsedreferrer := mload(add(_source,0x14))
        }
        return parsedreferrer;
    }

    function setRef(uint _value) internal {
        address _referrer = bytesToAddress(bytes(msg.data));
        if (_referrer != msg.sender) {
            referrers[msg.sender] = _referrer;
            refBonus[msg.sender] += _value * 3 / 100;
            refBonus[_referrer] += _value / 10;

            emit LogNewReferrer(msg.sender, _referrer);
            emit LogReferralInvestment(msg.sender, msg.value);
        }
    }

    function() external payable {
        if (msg.value == 0) {
            withdraw();
        } else {
            invest();
        }
    }

    function invest() public payable {

        require(msg.value >= 50000000000000000);
        admin.transfer(msg.value * 3 / 100);

        if (deposit[msg.sender][0] > 0 || refBonus[msg.sender] > 0) {
            withdraw();
            if (deposit[msg.sender][0] > 0) {
                index[msg.sender] += 1;
            }
        }

        checkpoint[msg.sender] = block.timestamp;
        finish[msg.sender][index[msg.sender]] = block.timestamp + (40 * 1 days);
        deposit[msg.sender][index[msg.sender]] = msg.value;

        if (referrers[msg.sender] != 0x0) {
            marketing.transfer(msg.value * 7 / 50);
            refBonus[referrers[msg.sender]] += msg.value / 10;
            emit LogReferralInvestment(msg.sender, msg.value);
        } else if (msg.data.length == 20) {
            marketing.transfer(msg.value * 7 / 50);
            setRef(msg.value);
        } else {
            marketing.transfer(msg.value * 6 / 25);
        }

        emit LogInvestment(msg.sender, msg.value);
    }

    function withdraw() public {

        uint _payout = refBonus[msg.sender];
        refBonus[msg.sender] = 0;

        for (uint i = 0; i <= index[msg.sender]; i++) {
            if (checkpoint[msg.sender] < finish[msg.sender][i]) {
                if (block.timestamp > finish[msg.sender][i]) {
                    _payout = _payout.add((deposit[msg.sender][i].div(20)).mul(finish[msg.sender][i].sub(checkpoint[msg.sender])).div(1 days));
                    checkpoint[msg.sender] = block.timestamp;
                } else {
                    _payout = _payout.add((deposit[msg.sender][i].div(20)).mul(block.timestamp.sub(checkpoint[msg.sender])).div(1 days));
                    checkpoint[msg.sender] = block.timestamp;
                }
            }
        }

        if (_payout > 0) {
            msg.sender.transfer(_payout);

            emit LogPayment(msg.sender, _payout);
        }
    }

    function getInfo1(address _address) public view returns(uint Invested) {
        uint _sum;
        for (uint i = 0; i <= index[_address]; i++) {
            if (block.timestamp < finish[_address][i]) {
                _sum += deposit[_address][i];
            }
        }
        Invested = _sum;
    }

    function getInfo2(address _address, uint _number) public view returns(uint Deposit_N) {
        if (block.timestamp < finish[_address][_number - 1]) {
            Deposit_N = deposit[_address][_number - 1];
        } else {
            Deposit_N = 0;
        }
    }

    function getInfo3(address _address) public view returns(uint Dividends, uint Bonuses) {
        uint _payout;
        for (uint i = 0; i <= index[_address]; i++) {
            if (checkpoint[_address] < finish[_address][i]) {
                if (block.timestamp > finish[_address][i]) {
                    _payout = _payout.add((deposit[_address][i].div(20)).mul(finish[_address][i].sub(checkpoint[_address])).div(1 days));
                } else {
                    _payout = _payout.add((deposit[_address][i].div(20)).mul(block.timestamp.sub(checkpoint[_address])).div(1 days));
                }
            }
        }
        Dividends = _payout;
        Bonuses = refBonus[_address];
    }
}