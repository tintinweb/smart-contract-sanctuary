/**
 *Submitted for verification at BscScan.com on 2021-11-12
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

contract BecomeHippiesToken {
    
    AggregatorV3Interface private _feedBNBUSD;
    
    struct Dividend {
        uint256 amount;
        bytes32 hash;
    }
    
    struct FundingRound {
        uint8 price;
        uint256 supply;
    }
    
    struct Sponsorship {
        address account;
        uint256 value;
        bool active;
    }
    
    uint8 public constant decimals = 18;
    string public constant name = "Become Hippies Token";
    string public constant symbol = "BHT";
    
    uint8 private constant _fundingStartPrice = 30;
    uint8 private constant _fundingPriceDecimals = 4;
    uint8 private constant _fundingRoundMaxIndex = 2;
    
    uint8 public constant sponsorshipPercentage = 25;
    uint8 public constant transferPercentage = 20;
    uint8 public constant fundsPercentage = 70;
    uint8 public constant fundingAddPercentage = 30;
    uint8 public constant dividendBasePercentage = 10;
    uint32 public constant _fundingUSDtarget = 60000;
    
    uint256 private constant _fundingPriceFactor = 10 ** _fundingPriceDecimals;
    uint256 public constant minValueDividend = 100 * 10 ** decimals;
    uint256 public constant airdropSupply = 2500 * 10 ** decimals;
    uint256 public constant fundingRoundSupply = 20000 * 10 ** decimals;
    
    mapping (address => bool) private _addresses;
    mapping (address => uint256) private _balances;
    mapping (address => uint256) private _dividends;
    mapping (address => Sponsorship) private _sponsorships;
    mapping (address => address[]) private _sponsorshipsAddresses;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    address[] private _beneficiaries;
    
    uint256 private _fundsUSD;
    uint256 public totalSupply = 100000 * 10 ** 18;
    uint256 public dividend;
    uint256 public fundingAmount = 0;
    uint256 public airdropAmount = 0;
    uint8 private _fundingRoundIndex = 0;
    
    address public owner;
    bool public isFunding = true;
    
    FundingRound[] private _fundingRounds;
    
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    constructor () {
        _feedBNBUSD = AggregatorV3Interface(0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE);
        for (uint8 i = _fundingRoundIndex; i <= _fundingRoundMaxIndex; i++) {
            _fundingRounds.push(FundingRound(
                _fundingStartPrice + (5 * i), 
                fundingRoundSupply
            ));
        }
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner access");
        _;
    }
    
    modifier onlyFunding() {
        require(isFunding, "Funding completed");
        _;
    }
    
    receive() external payable {
        if (isFunding) {
            addFunds(msg.sender);
        } else if (msg.sender == owner) {
            addDividends();
        } else {
            revert("This contract does not accept BNB");
        }
    }
    
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    
    function dividendOf(address account) public view returns (uint256) {
        return _dividends[account];
    }
    
    function sponsorshipOf(address account) public view returns (uint256) {
        return _sponsorships[account].value;
    }
    
    function sponsorshipsOf(address account) public view returns (address[] memory) {
        return _sponsorshipsAddresses[account];
    }
    
    function dividendPercentage() public view returns (uint256) {
        return _getFundsUSD() / _fundingUSDtarget / dividendBasePercentage / 10 ** 8;
    }
    
    function fundingUSDtarget() public pure returns (uint256) {
        return _fundingUSDtarget * 10 ** decimals;
    }
    
    function fundsUSD() public view returns (uint256) {
        return _getFundsUSD() / 10 ** 8;
    }
    
    function fundingStartPrice() public pure returns (uint256) {
        return _fundingGetPrice(_fundingStartPrice);
    }
    
    function fundingMaxRound() public pure returns (uint8) {
        return _fundingRoundMaxIndex + 1;
    }
    
    function fundingSupplyOfCurrentRound() public view returns (uint256) {
        return isFunding ? _fundingRounds[_fundingRoundIndex].supply : 0;
    }
    
    function fundingPriceOfCurrentRound() public view returns (uint256) {
        return isFunding ? _fundingGetPrice(_fundingRounds[_fundingRoundIndex].price) : 0;
    }
    
    function fundingCurrentRound() public view returns (uint8) {
        return isFunding ? _fundingRoundIndex + 1 : 0;
    }
    
    function fundingValueFromBNB(uint256 value) public view returns (uint256) {
        return isFunding ? _fundingValueFromBNB(value, _fundingRoundIndex) : 0;
    }
    
    function fundingValue(uint256 value) public view returns (uint256) {
        return isFunding ? _fundingValue(value, _fundingRoundIndex) : 0;
    }
    
    function fundingMaxCurrentValue() public view returns (uint256) {
        if (!isFunding) {
            return 0;
        }
        uint256 amount = 0;
        for (uint8 i = _fundingRoundIndex; i <= _fundingRoundMaxIndex; i++) {
            amount += _fundingSupply(i) * _fundingPrice(i) / _fundingPriceFactor;
        }
        return amount;
    }
    
    function fundingMaxValue() public view returns (uint256) {
        uint256 amount = 0;
        for (uint8 i = 0; i <= _fundingRoundMaxIndex; i++) {
            amount += fundingRoundSupply * _fundingPrice(i) / _fundingPriceFactor;
        }
        return amount;
    }
    
    function fundingMaxAmount() public view returns (uint256) {
        if (!isFunding) {
            return 0;
        }
        uint supply = 0;
        for (uint8 i = _fundingRoundIndex; i <= _fundingRoundMaxIndex; i++) {
            supply += _fundingSupply(i);
        }
        return supply;
    }
    
    function fundingSupply() public view returns (uint256) {
        return _fundingRounds.length * fundingRoundSupply;
    }
    
    function sponsorshipMaxSupply() public view returns (uint256) {
        return fundingSupply() * sponsorshipPercentage / 100;
    }
    
    function beneficiariesAmount() public view returns (uint256) {
        return _beneficiariesAmount(minValueDividend);
    }
    
    function endOfFunding() public onlyOwner onlyFunding returns (bool) {
        uint256 value = _getCurrentFunds();
        payable(owner).transfer(value);
        airdropAmount = airdropSupply * fundingAmount / totalSupply;
        uint256 amount = fundingAmount * fundingAddPercentage / 100 + airdropAmount;
        _balances[owner] += amount;
        totalSupply = fundingAmount + amount;
        _fundsUSD = _toUSD(value);
        isFunding = false;
        return true;
    }
    
    function addDividends() public payable {
        require(msg.value > 0, "Value is empty");
        require(!isFunding, "Funding in progress");
        dividend += msg.value;
        uint256 amount = beneficiariesAmount();
        for (uint8 i = 0; i < _beneficiaries.length; i++) {
            address user = _beneficiaries[i];
            if (_balances[user] >= minValueDividend) {
                uint256 value = msg.value * _balances[user] / amount;
                payable(user).transfer(value);
                _dividends[user] += value;
            }
        }
    }
    
    function addFunds(address sponsorshipAddress) public onlyFunding payable {
        require(msg.value <= fundingMaxCurrentValue(), "Value exceeded");
        if (
            !_sponsorships[msg.sender].active && 
            msg.sender != sponsorshipAddress &&
            !_isContract(sponsorshipAddress) && 
            sponsorshipAddress != owner
        ) {
            _sponsorships[msg.sender] = Sponsorship(sponsorshipAddress, 0, true);
            _sponsorshipsAddresses[sponsorshipAddress].push(msg.sender);
        }
        uint256 amount = _setFunding(msg.value, msg.sender);
        fundingAmount += amount;
        _setBalance(msg.sender, amount);
    }
    
    function transfer(address to, uint256 value) public returns (bool) {
        require(balanceOf(msg.sender) >= value, "Insufficient balance");
        _setBalance(to, value);
        _balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(allowance(from, msg.sender) >= value, "Insufficient allowance");
        require(balanceOf(from) >= value, "Insufficient balance");
        if (_addresses[from]) {
            uint256 amount = value * transferPercentage / 100;
            require(balanceOf(from) >= value + amount, "Insufficient balance");
            uint256 total = _beneficiariesAmount(0) - _balances[from];
            uint256 added = 0;
            for (uint8 i = 0; i < _beneficiaries.length; i++) {
                address user = _beneficiaries[i];
                if (user != from && _balances[user] > 0) {
                    uint256 add = amount * _balances[user] / total;
                    _balances[user] += add;
                    added += add;
                }
            }
            _balances[from] -= added;
        }
        _balances[from] -= value;
        _setBalance(to, value);
        emit Transfer(from, to, value);
        return true;
    }
    
    function approve(address spender, uint256 value) public returns (bool) {
        _allowances[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    function withdraw() public onlyOwner returns(bool) {
        uint256 balance = address(this).balance;
        require(balance > 0, "Contract balance is empty");
        payable(owner).transfer(balance);
        return true;
    }
    
    function burn(uint256 amount) public {
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");
        _balances[msg.sender] -= amount;
        totalSupply -= amount;
    }
    
    function allowance(address from, address sender) public view returns (uint256) {
        return _allowances[from][sender];
    }
    
    function _toUSD(uint256 value) private view returns (uint256) {
        (,int price,,,) = _feedBNBUSD.latestRoundData();
        return value * uint256(price);
    }
    
    function _getFundsUSD() private view returns (uint256) {
        return isFunding ? _toUSD(_getCurrentFunds()) : _fundsUSD;
    }
    
    function _getCurrentFunds() private view returns (uint256) {
        return address(this).balance * fundsPercentage / 100;
    }
    
    function _isContract(address value) private view returns (bool){
        uint32 size;
        assembly { size := extcodesize(value) }
        return size > 0;
    }
    
    function _fundingGetPrice(uint8 value) private pure returns (uint256) {
        return value * 10 ** (18 - _fundingPriceDecimals);
    }
    
    function _fundingSupply(uint8 index) private view returns (uint256) {
        return _fundingRounds[index].supply;
    }
    
    function _fundingPrice(uint8 index) private view returns (uint8) {
        return _fundingRounds[index].price;
    }
    
    function _beneficiariesAmount(uint256 minValue) private view returns (uint256) {
        uint256 amount = 0;
        for (uint8 i = 0; i < _beneficiaries.length; i++) {
            address user = _beneficiaries[i];
            if (_balances[user] >= minValue)
                amount += _balances[user];
        }
        return amount;
    }
    
    function _fundingValueFromBNB(uint256 value, uint8 index) private view returns (uint256) {
        uint8 price = _fundingPrice(index);
        uint256 supply = _fundingSupply(index);
        uint256 amount = value * _fundingPriceFactor / price;
        if (amount > supply) {
            if (index == _fundingRoundMaxIndex) {
                return supply;
            }
            value -= supply * price / _fundingPriceFactor;
            return supply + _fundingValueFromBNB(value, index + 1);
        }
        return amount;
    }
    
    function _fundingValue(uint256 value, uint8 index) private view returns (uint256) {
        uint8 price = _fundingPrice(index);
        uint256 supply = _fundingSupply(index);
        if (value > supply) {
            uint256 amount = supply * price / _fundingPriceFactor;
            if (index == _fundingRoundMaxIndex) {
                return amount;
            }
            return amount + _fundingValue(value - supply, index + 1);
        }
        return value * price / _fundingPriceFactor;
    }
    
    function _setBalance(address to, uint256 value) private {
        _balances[to] += value;
         if (!_addresses[to] && to != owner && !_isContract(to)) {
            _addresses[to] = true;
            _beneficiaries.push(to);
        }
    }
    
    function _sponsorship(uint256 amount, Sponsorship storage sponsorship) private {
        uint256 value = amount * sponsorshipPercentage / 100;
        _balances[sponsorship.account] += value;
        fundingAmount += value;
        sponsorship.value += value;
    }
    
    function _setFunding(uint256 value, address sender) private returns (uint256) {
        uint8 price = _fundingRounds[_fundingRoundIndex].price;
        uint256 supply = _fundingRounds[_fundingRoundIndex].supply;
        uint256 amount = value * _fundingPriceFactor / price;
        Sponsorship storage sponsorship = _sponsorships[sender];
        FundingRound storage round = _fundingRounds[_fundingRoundIndex];
        if (amount > supply) {
            if (sponsorship.active) {
                _sponsorship(supply, sponsorship);
            }
            round.supply -= supply;
            if (_fundingRoundIndex == _fundingRoundMaxIndex) {
                return supply;
            }
             value -= supply * price / _fundingPriceFactor;
            _fundingRoundIndex++;
            return supply + _setFunding(value, sender);
        }
        if (sponsorship.active) {
            _sponsorship(amount, sponsorship);
        }
        round.supply -= amount;
        if (round.supply == 0) {
            _fundingRoundIndex++;
        }
        return amount;
    }
}