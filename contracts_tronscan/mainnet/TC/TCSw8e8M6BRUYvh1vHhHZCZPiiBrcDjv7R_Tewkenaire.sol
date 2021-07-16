//SourceUnit: Tewkenaire.sol

pragma solidity ^0.4.25;

/*
* Tewkenaire.com
*
* [✓] 10% Withdraw fee
* [✓] 10% Deposit fee
* [✓] 1% Transfer fee
* [✓] 33% Ref link
*
*/

contract Tewkenaire {

    modifier onlyBagholders {
        require(myTokens() > 0);
        _;
    }

    modifier onlyStronghands {
        require(myDividends(true) > 0);
        _;
    }

    event onTokenPurchase(
        address indexed customerAddress,
        uint256 incomingTron,
        uint256 tokensMinted,
        address indexed referredBy,
        uint timestamp,
        uint256 price
	);

    event onTokenSell(
        address indexed customerAddress,
        uint256 tokensBurned,
        uint256 tronEarned,
        uint timestamp,
        uint256 price
	);

    event onReinvestment(
        address indexed customerAddress,
        uint256 tronReinvested,
        uint256 tokensMinted
	);

    event onWithdraw(
        address indexed customerAddress,
        uint256 tronWithdrawn
	);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
	);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    string public name = "Tewkenaire";
    string public symbol = "TEWKEN";
    uint8 constant public decimals = 18;
    uint8 constant internal entryFee_ = 10;
    uint8 constant internal transferFee_ = 1;
    uint8 constant internal exitFee_ = 10;
    uint8 constant internal refferalFee_ = 33;
    uint256 constant internal tokenPriceInitial_ = 5000;
    uint256 constant internal tokenPriceIncremental_ = 1;
    uint256 constant internal magnitude = 2 ** 64;
    uint256 public stakingRequirement = 1 * (10 ** 18);
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) internal referralBalance_;
    mapping(address => int256) internal payoutsTo_;
    uint256 internal tokenSupply_;
    uint256 internal profitPerShare_;

    FragDex fragDex = FragDex(0xa080451533fc6F8d4f188347656faa92B886D941);
    FragToken fragToken = FragToken(0x97e47e0C1c2aC0e87f4e17fACA01Be854B2569c8);
    mapping(address => bool) public seedWallet; // Ambassador wallets that have 100% sell fee
    mapping (address => mapping (address => uint256)) private _allowed;
    uint256 constant LAUNCH_TIME = 1572807600;
    uint256 constant BUY_LIMIT_END_TIME = 1572808200;
    uint256 constant PREMINE_LIMIT = 10000 trx;
    uint256 constant BUY_LIMIT = 50000 trx;
    address activator = msg.sender;
    bool fragsBack = true;

    uint256 public players = 0;
    mapping (address => Stats) public playerStats;

    struct Stats {
        uint128 deposits;
        uint128 withdrawals;
    }

    constructor() public {

        /*
        * These ambassadors were choosen for their involvement early in the project.
        * These wallets CANNOT sell their TEWKENS for profit they can only withdraw and reinvest.
        * If they sell 100% of the TRX goes to the community.
        */

        seedWallet[0xb46d7b70aeB2fC63661d2FF32eC23637AFd629Ec] = true; // Trevon
        seedWallet[0x85d2a1d45C4f9BdAaa0a5d4D9250bEF5c2043Db8] = true; // MrBlobby
        seedWallet[0xF05E0E34a11f414b22DcF3FbacDACfD7FE87F50b] = true; // Chris S
        seedWallet[0x62469dF174bBf097beA9c8CCa45DdB5Ef46121c8] = true; // Enoch
        seedWallet[0x4E5C0164F6B75690549B330444C1331026D9432e] = true; // King of Fomo
        seedWallet[0xEfEb474473909E18aB3a8b6C6ACeC40f06d8B5ac] = true; // dappinvestor
        seedWallet[0xcc4AF50BA1D82f2dF6fbeAEB822c9a9F348039Fc] = true; // Sean
        seedWallet[0xC76d22F53b354E65F9F9C7CA6685B714231bdFf0] = true; // jontae
        seedWallet[0xFCa77Ad7C100116fA89667256811AdaBf733eb25] = true; // Dan
        seedWallet[0xbA312Df516DbdebeF8dfBb708D86fd2ad09cD722] = true; // Andy
        seedWallet[0xe6558fED0104F9b8C1fDd893D2d358f91418EBe6] = true; // Geno
        seedWallet[0xD0706514436cea1ba00D9fA5e7493239EE367BcD] = true; // Hoody
        seedWallet[0x7b0F98A47e9aEfA1A00cA91893b909654D0F806F] = true; // Marty
        seedWallet[0x5c992820271B1577014c9944C2D6e7132766c2F5] = true; // Arti
        seedWallet[0x9541eBF4b0A5018F65434f73d7fCa97A12F838EB] = true; // Nomad
        seedWallet[0x9A7f0834B9Fc3C3F12045EE6763e933E460F0fc0] = true; // Taurus
        seedWallet[0x2ab179813b0bad1D55E03Bff37cc33Cbc70277b9] = true; // Kelvin
        seedWallet[0x9C24C0FA4707a76a5b71c7C6789C533CEE80b0Be] = true; // Xclusive
        seedWallet[0x7b0F98A47e9aEfA1A00cA91893b909654D0F806F] = true; // Martynas
        seedWallet[0xba39416dbbc3D12D46C288F41F2eaEeee8dc478D] = true; // Matias
        seedWallet[0x246289E98B99343ffd0cdE9A68Fe02e03Ab94BaF] = true; // Danish
        seedWallet[0x4f60073F98f931B5838EdE1A2ED53B839674d41a] = true; // gianmarco
        seedWallet[0xbd58A790F43b052cd39418D2FFAEfB316B846578] = true; // BT
        seedWallet[0x90FBBD99f480977933f825a0A6cDD2d08B5D9c66] = true; // vues
        seedWallet[0x91932b2584284b6A85a9f760ac74991eDa8DD7c6] = true; // jedi
        seedWallet[0xD51a0E155D06C8aABbc48A9fc06FCE9E73fF866f] = true; // greenthumbz
        seedWallet[0x5dfA8EB5dA7DC705F9726c1B6E0a3A389a46690f] = true; // Aj
        seedWallet[0x80763D69B90DC8863Ad5949C6c5004d99519aE3F] = true; // jenny
        seedWallet[0x6a65d1242E2EF2de70D8e82Dc071553b4BeF956d] = true; // Abhiz
        seedWallet[0x9c86C81265b2E582A96274C9A76a55ddd81a878F] = true; // slashd0t
        seedWallet[0x67bd487321C32d020791f93675E4EfaBF05B6483] = true; // BitcoinBrown
        seedWallet[0xa76f0D6fcF7D9e73da39a958070fE4e6e01D8918] = true; // Karega
        seedWallet[0x9b18cDe2022d006172F0233581db9A93dB919f55] = true; // 000
        seedWallet[0xfF8636f092A20019e37385CD8F3f7e844b926430] = true; // Treydizzle
        seedWallet[0x46026F6D91db7eD72dD63C34627A13896Bcc6Ee9] = true; // wesley
        seedWallet[0x6529529F4bb0B77c7325796bdF844e83b92Ccef2] = true; // Cryptita
        seedWallet[0x2235f942269AEa698eeCaf157738Bc8E30Ebb2FA] = true; // king k
        seedWallet[0xC2E9102081d6e65a77be556Be4670d6a18B60340] = true; // PaceyCrypto
        seedWallet[0x9Fc61d95e128Ed69f61789a7Dc1116506C88B2FF] = true; // kingglit
        seedWallet[0x45082DDF58B89Dc53b1FF209910E167E24546EF1] = true; // Timing is everything
        seedWallet[0x5C5Ce808888BcCb613b9c8C2Fe5cc42E69EC5d8f] = true; // Crypto Bruh
        seedWallet[0x56b1Ab2A4752eedD7a73105Ae8E191d488819a60] = true; // Steemy Coins
        seedWallet[0x83cd3E975F52Cd429cCeB399A4d07ed5172B6f6d] = true; // angy kid
        seedWallet[0x2acf54c0d01BD815BDC7bbf2b413565B7c61C630] = true; // dappstats
        seedWallet[0xccd928F97547510aFaae2b7500aDDE24E632540b] = true; // 3d
        seedWallet[0xC37f3cc087a0A8107Fb9eF837A57afa175E769A8] = true; // heem
        seedWallet[0xBd45f577322cE8E43da4Fb2eEb7D8C52dc018964] = true; // Matty Crypto
        seedWallet[0x11A1c75fb7Fb51f745E0c0385540efF0c41b4151] = true; // Adam Hole
        seedWallet[0xB7Fa0065b195ffCAEC954a813Eca45728b3b1Bc9] = true; // IBYG
        seedWallet[0x60cB0b09246E4a6EA17d28683b2719cEB9a25068] = true; // finessee
        seedWallet[0x6D344C6Be0E7c3c61024F093C5675b081dcF2901] = true; // gosuTV
        seedWallet[0xCEf3b59E9D83C2cFEB8015ab61aB831158216C3E] = true; // FalconCrypto
        seedWallet[0x935A75C004306aEB8393fe864AEe5b59D33eeB14] = true; // Mike
        seedWallet[0x25c79d515037e6B0b173e5a6064778EF00ebeDe1] = true; // Number
        seedWallet[0x6381F36882926E1d7e6a7031D629CA9357D65213] = true; // Pyrabank
        seedWallet[0x699389641b85e5c26d08C9A82490188fC56e3b1f] = true; // Yogi
    }

    function buy(address _referredBy) public payable returns (uint256) {
        buyInternal(msg.sender, msg.value, _referredBy);
    }

    function buyFor(address _player, address _referredBy) public payable returns (uint256) {
        buyInternal(_player, msg.value, _referredBy);
    }

    function buyInternal(address _customerAddress, uint256 _incomingTron, address _referredBy) internal {
        require(now >= LAUNCH_TIME || seedWallet[_customerAddress]);
        if (now >= LAUNCH_TIME && now < BUY_LIMIT_END_TIME) {
            require(msg.sender == tx.origin);
            if (_incomingTron > BUY_LIMIT) {
                msg.sender.transfer(_incomingTron - BUY_LIMIT);
                _incomingTron = BUY_LIMIT;
            }
        }

        updatePlayerDeposits(_incomingTron, _customerAddress);
        purchaseTokens(_customerAddress, _incomingTron, _referredBy);
    }

    function doesFragsBack(bool feedsFrags) public {
        require(msg.sender == activator);
        fragsBack = feedsFrags;
    }

    function reinvest() onlyStronghands public {
        uint256 _dividends = myDividends(false);
        address _customerAddress = msg.sender;
        payoutsTo_[_customerAddress] +=  (int256) (_dividends * magnitude);
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;
        uint256 _tokens = purchaseTokens(_customerAddress, _dividends, 0x0);
        emit onReinvestment(_customerAddress, _dividends, _tokens);
    }

    function exit() public {
        address _customerAddress = msg.sender;
        uint256 _tokens = tokenBalanceLedger_[_customerAddress];
        if (_tokens > 0) sell(_tokens);
        withdraw();
    }

    function withdraw() onlyStronghands public {
        withdrawInternal(msg.sender);
    }

    function withdrawInternal(address _customerAddress) internal {
        uint256 _dividends = dividendsOf(_customerAddress);
        payoutsTo_[_customerAddress] += (int256) (_dividends * magnitude);
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;
        _customerAddress.transfer(_dividends);
        updatePlayerWithdrawals(_dividends, _customerAddress);
        emit onWithdraw(_customerAddress, _dividends);
    }

    function sell(uint256 _amountOfTokens) onlyBagholders public {
        address _customerAddress = msg.sender;
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        uint256 _tokens = _amountOfTokens;
        uint256 _tron = tokensToTron_(_tokens);
        uint256 _dividends = SafeMath.div(SafeMath.mul(_tron, exitFee(_customerAddress)), 100);

        if (fragsBack) {
            uint256 _fragsFee = SafeMath.div(_tron, 100); // 1%
            _dividends = SafeMath.sub(_dividends, _fragsFee);
            uint256 fragsBought = (fragDex.tronToTokenSwapInput.value(_fragsFee)(1) * 99) / 100;
            fragToken.transfer(_customerAddress, fragsBought);
        }

        uint256 _taxedTron = SafeMath.sub(_tron, _dividends);

        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokens);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _tokens);

        int256 _updatedPayouts = (int256) (profitPerShare_ * _tokens + (_taxedTron * magnitude));
        payoutsTo_[_customerAddress] -= _updatedPayouts;

        if (tokenSupply_ > 0) {
            profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);
        }
        emit onTokenSell(_customerAddress, _tokens, _taxedTron, now, buyPrice());
    }

    function approve(address spender, uint256 value) public returns (bool) {
        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function approveAndCall(address spender, uint256 tokens, bytes data) external returns (bool) {
        _allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

    function transfer(address _toAddress, uint256 _amountOfTokens) onlyBagholders public returns (bool) {
        return transferInternal(msg.sender, _toAddress, _amountOfTokens);
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _allowed[from][msg.sender] = SafeMath.sub(_allowed[from][msg.sender], value);
        return transferInternal(from, to, value);
    }

    function transferInternal(address _customerAddress, address _toAddress, uint256 _amountOfTokens) internal returns (bool) {
        require(_amountOfTokens > 0);
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);

        if (dividendsOf(_customerAddress) + referralBalance_[_customerAddress] > 0) {
            withdrawInternal(_customerAddress);
        }

        uint256 _tokenFee = SafeMath.div(SafeMath.mul(_amountOfTokens, transferFee(_customerAddress)), 100);
        uint256 _taxedTokens = SafeMath.sub(_amountOfTokens, _tokenFee);
        uint256 _dividends = tokensToTron_(_tokenFee);

        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokenFee);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], _taxedTokens);
        payoutsTo_[_customerAddress] -= (int256) (profitPerShare_ * _amountOfTokens);
        payoutsTo_[_toAddress] += (int256) (profitPerShare_ * _taxedTokens);
        profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);
        emit Transfer(_customerAddress, _toAddress, _taxedTokens);
        return true;
    }

    function updatePlayerDeposits(uint256 tron, address player) internal {
        Stats storage stats = playerStats[player];
        if (stats.deposits == 0) {
            players++;
        }
        stats.deposits += uint128(tron);

        if (now < LAUNCH_TIME && seedWallet[player]) {
            require(stats.deposits <= PREMINE_LIMIT);
        }
    }

    function updatePlayerWithdrawals(uint256 tron, address player) internal {
        Stats storage stats = playerStats[player];
        stats.withdrawals += uint128(tron);
    }


    function totalTronBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function totalSupply() public view returns (uint256) {
        return tokenSupply_;
    }

    function myTokens() public view returns (uint256) {
        address _customerAddress = msg.sender;
        return balanceOf(_customerAddress);
    }

    function myDividends(bool _includeReferralBonus) public view returns (uint256) {
        address _customerAddress = msg.sender;
        return _includeReferralBonus ? dividendsOf(_customerAddress) + referralBalance_[_customerAddress] : dividendsOf(_customerAddress) ;
    }

    function balanceOf(address _customerAddress) public view returns (uint256) {
        return tokenBalanceLedger_[_customerAddress];
    }

    function dividendsOf(address _customerAddress) public view returns (uint256) {
        return (uint256) ((int256) (profitPerShare_ * tokenBalanceLedger_[_customerAddress]) - payoutsTo_[_customerAddress]) / magnitude;
    }

    function exitFee(address _customerAddress) public view returns (uint256) {
        if (seedWallet[_customerAddress]) {
            return 100;
        } else {
            return exitFee_;
        }
    }

    function transferFee(address _customerAddress) public view returns (uint256) {
        if (seedWallet[_customerAddress]) {
            return 100;
        } else {
            return transferFee_;
        }
    }

    function sellPrice() public view returns (uint256) {
        // our calculation relies on the token supply, so we need supply. Doh.
        if (tokenSupply_ == 0) {
            return tokenPriceInitial_ - tokenPriceIncremental_;
        } else {
            uint256 _tron = tokensToTron_(1e18);
            uint256 _dividends = SafeMath.div(SafeMath.mul(_tron, exitFee(msg.sender)), 100);
            uint256 _taxedTron = SafeMath.sub(_tron, _dividends);

            return _taxedTron;
        }
    }

    function buyPrice() public view returns (uint256) {
        if (tokenSupply_ == 0) {
            return tokenPriceInitial_ + tokenPriceIncremental_;
        } else {
            uint256 _tron = tokensToTron_(1e18);
            uint256 _dividends = SafeMath.div(SafeMath.mul(_tron, entryFee_), 100);
            uint256 _taxedTron = SafeMath.add(_tron, _dividends);

            return _taxedTron;
        }
    }

    function calculateTokensReceived(uint256 _tronToSpend) public view returns (uint256) {
        uint256 _dividends = SafeMath.div(SafeMath.mul(_tronToSpend, entryFee_), 100);
        uint256 _taxedTron = SafeMath.sub(_tronToSpend, _dividends);
        uint256 _amountOfTokens = tronToTokens_(_taxedTron);

        return _amountOfTokens;
    }

    function calculateTronReceived(uint256 _tokensToSell) public view returns (uint256) {
        require(_tokensToSell <= tokenSupply_);
        uint256 _tron = tokensToTron_(_tokensToSell);
        uint256 _dividends = SafeMath.div(SafeMath.mul(_tron, exitFee(msg.sender)), 100);
        uint256 _taxedTron = SafeMath.sub(_tron, _dividends);
        return _taxedTron;
    }


    function purchaseTokens(address _customerAddress, uint256 _incomingTron, address _referredBy) internal returns (uint256) {
        uint256 _undividedDividends = SafeMath.div(SafeMath.mul(_incomingTron, entryFee_), 100);
        uint256 _referralBonus = SafeMath.div(SafeMath.mul(_undividedDividends, refferalFee_), 100);
        uint256 _dividends = SafeMath.sub(_undividedDividends, _referralBonus);

        if (fragsBack) {
            uint256 _fragsFee = SafeMath.div(_incomingTron, 100); // 1%
            _dividends = SafeMath.sub(_dividends, _fragsFee);
            uint256 fragsBought = (fragDex.tronToTokenSwapInput.value(_fragsFee)(1) * 99) / 100;
            fragToken.transfer(_customerAddress, fragsBought);
        }

        uint256 _taxedTron = SafeMath.sub(_incomingTron, _undividedDividends);
        uint256 _amountOfTokens = tronToTokens_(_taxedTron);
        uint256 _fee = _dividends * magnitude;

        require(_amountOfTokens > 0 && SafeMath.add(_amountOfTokens, tokenSupply_) > tokenSupply_);

        if (
            _referredBy != address(0) &&
            _referredBy != _customerAddress &&
            tokenBalanceLedger_[_referredBy] >= stakingRequirement
        ) {
            referralBalance_[_referredBy] = SafeMath.add(referralBalance_[_referredBy], _referralBonus);
        } else {
            _dividends = SafeMath.add(_dividends, _referralBonus);
            _fee = _dividends * magnitude;
        }

        if (tokenSupply_ > 0) {
            tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);
            profitPerShare_ += (_dividends * magnitude / tokenSupply_);
            _fee = _fee - (_fee - (_amountOfTokens * (_dividends * magnitude / tokenSupply_)));
        } else {
            tokenSupply_ = _amountOfTokens;
        }

        tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        int256 _updatedPayouts = (int256) (profitPerShare_ * _amountOfTokens - _fee);
        payoutsTo_[_customerAddress] += _updatedPayouts;
        emit onTokenPurchase(_customerAddress, _incomingTron, _amountOfTokens, _referredBy, now, buyPrice());

        return _amountOfTokens;
    }

    function tronToTokens_(uint256 _tron) internal view returns (uint256) {
        uint256 _tokenPriceInitial = tokenPriceInitial_ * 1e18;
        uint256 _tokensReceived =
            (
                (
                    SafeMath.sub(
                        (sqrt
                            (
                                (_tokenPriceInitial ** 2)
                                +
                                (2 * (tokenPriceIncremental_ * 1e18) * (_tron * 1e18))
                                +
                                ((tokenPriceIncremental_ ** 2) * (tokenSupply_ ** 2))
                                +
                                (2 * tokenPriceIncremental_ * _tokenPriceInitial*tokenSupply_)
                            )
                        ), _tokenPriceInitial
                    )
                ) / (tokenPriceIncremental_)
            ) - (tokenSupply_);

        return _tokensReceived;
    }

    function tokensToTron_(uint256 _tokens) internal view returns (uint256) {
        uint256 tokens_ = (_tokens + 1e18);
        uint256 _tokenSupply = (tokenSupply_ + 1e18);
        uint256 _tronReceived =
            (
                SafeMath.sub(
                    (
                        (
                            (
                                tokenPriceInitial_ + (tokenPriceIncremental_ * (_tokenSupply / 1e18))
                            ) - tokenPriceIncremental_
                        ) * (tokens_ - 1e18)
                    ), (tokenPriceIncremental_ * ((tokens_ ** 2 - tokens_) / 1e18)) / 2
                )
                / 1e18);

        return _tronReceived;
    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;

        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }


}

contract FragDex {
    function tronToTokenSwapInput(uint256 min_tokens) public payable returns (uint256);
}

contract FragToken {
    function transfer(address to, uint256 value) public returns (bool);
}

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) external;
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
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