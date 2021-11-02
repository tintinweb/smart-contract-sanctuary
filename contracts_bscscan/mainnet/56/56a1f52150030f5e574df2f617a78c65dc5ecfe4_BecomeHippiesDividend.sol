/**
 *Submitted for verification at BscScan.com on 2021-11-02
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

interface AggregatorV3Interface {
    function latestRoundData() external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
}

contract BecomeHippiesDividend {
    
    AggregatorV3Interface private _feedBNBUSD;
    
    struct Dividend {
        uint amount;
        bytes32 hash;
    }
    
    struct FundingRound {
        uint price;
        uint supply;
    }
    
    struct Sponsorship {
        address account;
        uint amount;
        bool value;
    }
    
    uint public constant decimals = 18;
    string public constant name = "Become Hippies Dividend";
    string public constant symbol = "BHD";
    uint8 private constant _fundingStartPrice = 3;
    uint private constant _fundingPriceDecimals = 3;
    uint private constant _fundingPriceFactor = 10 ** _fundingPriceDecimals;
    uint8 private constant _fundingMaxIndex = 4;
    uint32 public constant sponsorshipPercentage = 25;
    uint32 public constant transferPercentage = 20;
    uint72 public constant fundingPercentage = 70;
    uint32 public constant fundingAddedPercentage = 30;
    uint public constant minValueDividend = 100 * 10 ** decimals;
    uint public constant airdropMaxSupply = 2500 * 10 ** decimals;
    uint public constant fundingRoundSupply = 12000 * 10 ** decimals;
    uint public constant fundingUSDtarget = 60000;
    uint public constant dividendBasePercentage = 10;
    
    mapping (address => bool) private _addresses;
    mapping (address => uint) private _balances;
    mapping (address => uint) private _dividends;
    mapping (address => Sponsorship) private _sponsorships;
    mapping (address => address[]) private _sponsorshipsAddresses;
    mapping (address => mapping (address => uint)) private _allowances;
    
    address[] private _beneficiaries;
    
    uint public dividend;
    uint private _fundingUSD;
    uint public totalSupply = 0;
    address public owner;
    bool public isFunding = true;
    uint8 private _fundingIndex = 0;
    FundingRound[] private _fundingRounds;
    uint public airdropSupply = 0;
    
    event Approval(address indexed owner, address indexed sender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    
    constructor () {
        _feedBNBUSD = AggregatorV3Interface(0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE);
        for (uint i = _fundingIndex; i <= _fundingMaxIndex; i++) {
            _fundingRounds.push(FundingRound(
                _fundingStartPrice + i, 
                fundingRoundSupply
            ));
        }
        owner = msg.sender;
    }
    
    receive() external payable {
        if (isFunding) {
            addFunding(msg.value, msg.sender, msg.sender);
        } else if (_isOwner()) {
            addDividend(msg.value);
        }
    }
    
    function balanceOf(address account) public view returns (uint) {
        return _balances[account];
    }
    
    function dividendOf(address account) public view returns (uint) {
        return _dividends[account];
    }
    
    function dividendRateOf(address account) public view returns (uint) {
        if (_balances[account] < minValueDividend) {
            return 0;
        }
        return _balances[account] * 10 ** decimals / beneficiariesSupply();
    }
    
    function sponsorshipOf(address account) public view returns (Sponsorship memory) {
        return _sponsorships[account];
    }
    
    function sponsorshipsOf(address account) public view returns (address[] memory) {
        return _sponsorshipsAddresses[account];
    }
    
    function dividendPercentage() public view returns (uint) {
        return _getFundingUSD() / fundingUSDtarget / dividendBasePercentage / 10 ** 8;
    }
    
    function fundingUSD() public view returns (uint) {
        return _getFundingUSD() / 10 ** 8;
    }
    
    function fundingStartPrice() public pure returns (uint) {
        return _fundingGetPrice(_fundingStartPrice);
    }
    
    function fundingMaxRound() public pure returns (uint) {
        return _fundingMaxIndex + 1;
    }
    
    function fundingSupplyOfCurrentRound() public view returns (uint) {
        return isFunding ? _fundingRounds[_fundingIndex].supply : 0;
    }
    
    function fundingPriceOfCurrentRound() public view returns (uint) {
        return isFunding ? _fundingGetPrice(_fundingRounds[_fundingIndex].price) : 0;
    }
    
    function fundingCurrentRound() public view returns (uint) {
        return isFunding ? _fundingIndex + 1 : 0;
    }
    
    function fundingValueFromBNB(uint value) public view returns (uint) {
        return isFunding ? _fundingValueFromBNB(value, _fundingIndex) : 0;
    }
    
    function fundingValue(uint value) public view returns (uint) {
        return isFunding ? _fundingValue(value, _fundingIndex) : 0;
    }
    
    function fundingMaxCurrentValue() public view returns (uint) {
        if (!isFunding) {
            return 0;
        }
        uint amount = 0;
        for (uint8 i = _fundingIndex; i <= _fundingMaxIndex; i++) {
            amount += _fundingSupply(i) * _fundingPrice(i) / _fundingPriceFactor;
        }
        return amount;
    }
    
    function fundingMaxValue() public view returns (uint) {
        uint amount = 0;
        for (uint8 i = 0; i <= _fundingMaxIndex; i++) {
            amount += fundingRoundSupply * _fundingPrice(i) / _fundingPriceFactor;
        }
        return amount;
    }
    
    function fundingMaxCurrentSupply() public view returns (uint) {
        if (!isFunding) {
            return 0;
        }
        uint supply = 0;
        for (uint8 i = _fundingIndex; i <= _fundingMaxIndex; i++) {
            supply += _fundingSupply(i);
        }
        return supply;
    }
    
    function fundingMaxSupply() public view returns (uint) {
        return _fundingRounds.length * fundingRoundSupply;
    }
    
    function sponsorshipMaxSupply() public view returns (uint) {
        uint value = fundingMaxSupply();
        return value * sponsorshipPercentage / 100;
    }
    
    function maxSupply() public view returns (uint) {
        uint supply = fundingMaxSupply() + sponsorshipMaxSupply();
        return supply + supply * fundingAddedPercentage / 100 + airdropMaxSupply;
    }
    
    function beneficiariesSupply() public view returns (uint) {
        return _beneficiariesSupply(minValueDividend);
    }
    
    function endOfFunding() public returns (bool) {
        require(isFunding, "Funding completed");
        require(_isOwner(), "Owner access");
        isFunding = false;
        airdropSupply = airdropMaxSupply * totalSupply / maxSupply();
        uint supply = totalSupply * fundingAddedPercentage / 100 + airdropSupply;
        _balances[owner] += supply;
        totalSupply += supply;
        uint value = _getCurrentFunding();
        _fundingUSD = _toUSD(value);
        payable(owner).transfer(value);
        withdraw();
        return true;
    }
    
    function addDividend(uint value) public payable {
        require(value > 0, "Value is empty");
        require(!isFunding, "Funding in progress");
        dividend += value;
        uint supply = beneficiariesSupply();
        for (uint i = 0; i < _beneficiaries.length; i++) {
            address user = _beneficiaries[i];
            if (_balances[user] >= minValueDividend) {
                uint amount = value * _balances[user] / supply;
                payable(user).transfer(amount);
                _dividends[user] += amount;
            }
        }
    }
    
    function addFunding(uint value, address sender, address account) public payable {
        require(isFunding, "Funding completed");
        require(value <= fundingMaxCurrentValue(), "Value exceeded");
        if (!_sponsorships[sender].value && sender != account && _addresses[account] && !_isContract(account) && account != owner) {
            _sponsorships[sender] = Sponsorship(account, 0, true);
            _sponsorshipsAddresses[account].push(sender);
        }
        uint amount = _setFunding(value, sender);
        totalSupply += amount;
        _setBalance(sender, amount);
    }
    
    function transfer(address to, uint value) public returns (bool) {
        require(balanceOf(msg.sender) >= value, "Insufficient balance");
        _setBalance(to, value);
        _balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns (bool) {
        require(allowance(from, msg.sender) >= value, "Insufficient allowance");
        require(balanceOf(from) >= value, "Insufficient balance");
        _balances[from] -= value;
        if (from != owner) {
            uint supply = _beneficiariesSupply(0) - _balances[from];
            uint amount = value * transferPercentage / 100;
            uint added = 0;
            for (uint i = 0; i < _beneficiaries.length; i++) {
                address user = _beneficiaries[i];
                if (user != from) {
                    uint add = amount * _balances[user] / supply;
                    _balances[user] += add;
                    added += add;
                }
            }
            value -= amount;
            totalSupply -= amount - added;
        }
        _setBalance(to, value);
        emit Transfer(from, to, value);
        return true;
    }
    
    function approve(address sender, uint value) public returns (bool) {
        _allowances[msg.sender][sender] = value;
        emit Approval(msg.sender, sender, value);
        return true;
    }
    
    function withdraw() public returns(bool) {
        require(_isOwner(), "Owner access");
        uint balance = address(this).balance;
        require(balance > 0, "Contract balance is empty");
        payable(owner).transfer(balance);
        return true;
    }
    
    function burn(uint value) public {
        require(_isOwner(), "Owner access");
        require(balanceOf(owner) >= value, "Insufficient balance");
        _balances[owner] -= value;
        totalSupply -= value;
    }
    
    function allowance(address from, address sender) public view returns (uint256) {
        return _allowances[from][sender];
    }
    
    function _toUSD(uint value) public view returns (uint) {
        (,int price,,,) = _feedBNBUSD.latestRoundData();
        return value * uint(price);
    }
    
    function _getFundingUSD() private view returns (uint) {
        return isFunding ? _toUSD(_getCurrentFunding()) : _fundingUSD;
    }
    
    function _getCurrentFunding() private view returns (uint) {
        return address(this).balance * fundingPercentage / 100;
    }
    
    function _isContract(address value) private view returns (bool){
        uint32 size;
        assembly { size := extcodesize(value) }
        return size > 0;
    }
    
    function _isOwner() private view returns (bool) {
        return msg.sender == owner;
    }
    
    function _fundingGetPrice(uint value) private pure returns (uint) {
        return value * 10 ** (18 - _fundingPriceDecimals);
    }
    
    function _fundingSupply(uint8 index) private view returns (uint) {
        return _fundingRounds[index].supply;
    }
    
    function _fundingPrice(uint8 index) private view returns (uint) {
        return _fundingRounds[index].price;
    }
    
    function _beneficiariesSupply(uint minValue) private view returns (uint) {
        uint supply = 0;
        for (uint i = 0; i < _beneficiaries.length; i++) {
            address user = _beneficiaries[i];
            if (_balances[user] >= minValue)
                supply += _balances[user];
        }
        return supply;
    }
    
    function _fundingValueFromBNB(uint value, uint8 index) private view returns (uint) {
        uint price = _fundingPrice(index);
        uint supply = _fundingSupply(index);
        uint amount = value * _fundingPriceFactor / price;
        if (amount > supply) {
            if (index == _fundingMaxIndex) {
                return supply;
            }
            value -= supply * price / _fundingPriceFactor;
            return supply + _fundingValueFromBNB(value, index + 1);
        }
        return amount;
    }
    
    function _fundingValue(uint value, uint8 index) private view returns (uint) {
        uint price = _fundingPrice(index);
        uint supply = _fundingSupply(index);
        if (value > supply) {
            uint amount = supply * price / _fundingPriceFactor;
            if (index == _fundingMaxIndex) {
                return amount;
            }
            return amount + _fundingValue(value - supply, index + 1);
        }
        return value * price / _fundingPriceFactor;
    }
    
    function _setBalance(address to, uint value) private {
        _balances[to] += value;
         if (!_addresses[to] && to != owner && !_isContract(to)) {
            _addresses[to] = true;
            _beneficiaries.push(to);
        }
    }
    
    function _sponsorship(uint amount, Sponsorship storage sponsorship) private {
        amount = amount * sponsorshipPercentage / 100;
        _balances[sponsorship.account] += amount;
        totalSupply += amount;
        sponsorship.amount += amount;
    }
    
    function _setFunding(uint value, address sender) private returns (uint) {
        uint price = _fundingRounds[_fundingIndex].price;
        uint supply = _fundingRounds[_fundingIndex].supply;
        uint amount = value * _fundingPriceFactor / price;
        Sponsorship storage sponsorship = _sponsorships[sender];
        FundingRound storage round = _fundingRounds[_fundingIndex];
        if (amount > supply) {
            if (sponsorship.value) {
                _sponsorship(supply, sponsorship);
            }
            round.supply -= supply;
            if (_fundingIndex == _fundingMaxIndex) {
                return supply;
            }
             value -= supply * price / _fundingPriceFactor;
            _fundingIndex++;
            return supply + _setFunding(value, sender);
        }
        if (sponsorship.value) {
            _sponsorship(amount, sponsorship);
        }
        round.supply -= amount;
        if (round.supply == 0) {
            _fundingIndex++;
        }
        return amount;
    }
}