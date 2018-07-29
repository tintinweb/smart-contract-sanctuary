pragma solidity ^0.4.16;


contract ERC20 {
    function balanceOf(address tokenOwner) public constant returns (uint256 balance);
    function transfer(address to, uint256 tokens) public returns (bool success);
}


contract owned {
    function owned() public { owner = msg.sender; }
    address owner;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}


contract PublicSaleManager is owned {

    mapping (address => bool) _earlyList;
    mapping (address => bool) _whiteList;
    mapping (address => uint256) _bonus;
    mapping (address => uint256) _contributedETH;

    address _tokenAddress = 0xAF815e887b039Fc06a8ddDcC7Ec4f57757616Cd2;
    address _deadAddress = 0x000000000000000000000000000000000000dead;
    uint256 _conversionRate = 0;
    uint256 _startTime = 0;

    uint256 _totalSold = 0;
    uint256 _totalBonus = 0;

    uint256 _regularPersonalCap = 1e20; // 100 ETH
    uint256 _higherPersonalCap = 2e20; // 200 ETH
    uint256 _minimumAmount = 2e17; // 0.2 ETH

    bool _is_stopped = false;

    function addWhitelist(address[] addressList) public onlyOwner {
        // Whitelist is managed manually and addresses are added in batch.
        for (uint i = 0; i < addressList.length; i++) {
            _whiteList[addressList[i]] = true;
        }
    }
    
    function addEarlylist(address[] addressList) public onlyOwner {
        // Whitelist is managed manually and addresses are added in batch.
        for (uint i = 0; i < addressList.length; i++) {
            _earlyList[addressList[i]] = true;
        }
    }

    function start(uint32 conversionRate) public onlyOwner {
        require(_startTime == 0);
        require(conversionRate > 1);

        // Starts the public sale.
        _startTime = now;

        // Sets the conversion rate.
        _conversionRate = conversionRate;
    }

    function stop() public onlyOwner {
        _is_stopped = true;
    }

    function burnUnsold() public onlyOwner {
        require(now >= _startTime + (31 days));

        // Transfers all un-sold tokens to 0x000...dead.
        ERC20(_tokenAddress).transfer(_deadAddress, ERC20(_tokenAddress).balanceOf(this) - _totalBonus);
    }

    function withdrawEther(address toAddress, uint256 amount) public onlyOwner {
        toAddress.transfer(amount);
    }

    function buyTokens() payable public {
        require(_is_stopped == false);

        // Validates whitelist.
        require(_whiteList[msg.sender] == true || _earlyList[msg.sender] == true);

        if (_earlyList[msg.sender]) {
            require(msg.value + _contributedETH[msg.sender] <= _higherPersonalCap);
        } else {
            require(msg.value + _contributedETH[msg.sender] <= _regularPersonalCap);
        }

        require(msg.value >= _minimumAmount);

        // Validates time.
        require(now > _startTime);
        require(now < _startTime + (31 days));

        // Calculates the purchase amount.
        uint256 purchaseAmount = msg.value * _conversionRate;
        require(_conversionRate > 0 && purchaseAmount / _conversionRate == msg.value);

        // Calculates the bonus amount.
        uint256 bonus = 0;
        if (_totalSold + purchaseAmount < 5e26) {
            // 10% bonus for the first 500 million OGT.
            bonus = purchaseAmount / 10;
        } else if (_totalSold + purchaseAmount < 10e26) {
            // 5% bonus for the first 1 billion OGT.
            bonus = purchaseAmount / 20;
        }

        // Checks that we still have enough balance.
        require(ERC20(_tokenAddress).balanceOf(this) >= _totalBonus + purchaseAmount + bonus);

        // Transfers the non-bonus part.
        ERC20(_tokenAddress).transfer(msg.sender, purchaseAmount);
        _contributedETH[msg.sender] += msg.value;

        // Records the bonus.
        _bonus[msg.sender] += bonus;

        _totalBonus += bonus;
        _totalSold += (purchaseAmount + bonus);
    }

    function claimBonus() public {
        // Validates whitelist.
        require(_whiteList[msg.sender] == true || _earlyList[msg.sender] == true);
        
        // Validates bonus.
        require(_bonus[msg.sender] > 0);

        // Transfers the bonus if it&#39;s after 90 days.
        if (now > _startTime + (90 days)) {
            ERC20(_tokenAddress).transfer(msg.sender, _bonus[msg.sender]);
            _bonus[msg.sender] = 0;
        }
    }

    function checkBonus(address purchaser) public constant returns (uint256 balance) {
        return _bonus[purchaser];
    }

    function checkTotalSold() public constant returns (uint256 balance) {
        return _totalSold;
    }

    function checkContributedETH(address purchaser) public constant returns (uint256 balance) {
        return _contributedETH[purchaser];
    }

    function checkPersonalRemaining(address purchaser) public constant returns (uint256 balance) {
        if (_earlyList[purchaser]) {
            return _higherPersonalCap - _contributedETH[purchaser];
        } else if (_whiteList[purchaser]) {
            return _regularPersonalCap - _contributedETH[purchaser];
        } else {
            return 0;
        }
    }
}