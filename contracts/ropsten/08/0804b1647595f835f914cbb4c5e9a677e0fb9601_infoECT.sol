pragma solidity ^0.4.25;

/*
* https://ectoken.io
*
* Ethereum Captial Token concept
*
* [✓] 6% Withdraw fee (3% to dividends, 3% to owner). First 6 days 30%, next 24 days it will decrease to 6%
* [✓] 12% Deposit fee
* [✓] 1% Token transfer
* [✓] 5 lines referral system with 5 levels of rewards
*
*/

contract infoECT {


    uint8 constant public decimals = 18;

    /**
     * fees
     */
    uint8 constant internal entryFee_ = 12;
    uint8 constant internal ownerFee_ = 4;
    uint8 constant internal transferFee_ = 1;
    uint8 constant internal exitFeeD0_ = 30;
    uint8 constant internal exitFee_ = 6;
    uint8 constant internal refferalFee_ = 33;

    address internal _ownerAddress;

    /**
     * Initial token values
     */
    uint256 constant internal tokenPriceInitial_ = 0.0000001 ether;
    uint256 constant internal tokenPriceIncremental_ = 0.00000001 ether;

    uint256 constant internal magnitude = 2 ** 64;


    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) internal referralBalance_;
    mapping(address => int256) internal payoutsTo_;
    mapping(address => uint256) internal summaryReferralProfit_;
    mapping(address => uint256) internal dividendsUsed_;

    uint256 internal tokenSupply_;
    uint256 internal profitPerShare_;

    uint public blockCreation;

    function buyPriceAt(uint _supply) public view returns (uint256) {
        if (tokenSupply_ == 0) {
            return tokenPriceInitial_ + tokenPriceIncremental_;
        } else {
            uint256 _ethereum = tokensToEthereumAtSupply_(1e18, _supply);
            uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, entryFee_), 100);
            uint256 _taxedEthereum = SafeMath.add(_ethereum, _dividends);

            return _taxedEthereum;
        }
    }

    function sellPriceAt(uint256 _atSupply) public view returns (uint256) {
        if (_atSupply == 0) {
            return tokenPriceInitial_ - tokenPriceIncremental_;
        } else {
            uint256 _ethereum = tokensToEthereumAtSupply_(1e18, _atSupply);
            uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, exitFee_), 100);
            uint256 _taxedEthereum = SafeMath.sub(_ethereum, _dividends);

            return _taxedEthereum;
        }
    }

    function calculateTokensReceived(uint256 _incomingEthereum, uint256 supply) public view returns (uint256) {
        uint256 _dividends = SafeMath.div(SafeMath.mul(_incomingEthereum, entryFee_), 100);

        uint256 _taxedEthereum = SafeMath.sub(_incomingEthereum, _dividends);
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum, supply);

        return _amountOfTokens;
    }

    function calculateEthereumReceived(uint256 _tokensToSell, uint supply) public view returns (uint256) {
        require(_tokensToSell <= tokenSupply_);
        return tokensToEthereumAtSupply_(_tokensToSell, supply) * (100 - exitFee_) / 100;
    }

    function ethereumToTokens_(uint256 _ethereum, uint supply) internal view returns (uint256) {
        uint256 _tokenPriceInitial = tokenPriceInitial_ * 1e18;
        uint256 _tokensReceived =
            (
                (
                    SafeMath.sub(
                        (sqrt
                            (
                                (_tokenPriceInitial ** 2)
                                +
                                (2 * (tokenPriceIncremental_ * 1e18) * (_ethereum * 1e18))
                                +
                                ((tokenPriceIncremental_ ** 2) * (supply ** 2))
                                +
                                (2 * tokenPriceIncremental_ * _tokenPriceInitial*supply)
                            )
                        ), _tokenPriceInitial
                    )
                ) / (tokenPriceIncremental_)
            ) - (supply);

        return _tokensReceived;
    }


    function tokensToEthereumAtSupply_(uint256 _tokens, uint256 _atSupply) internal view returns (uint256) {
        if (_tokens < 0.00000001 ether) {
            return 0;
        }
        uint256 tokens_ = (_tokens + 1e18);
        uint256 _tokenSupply = (_atSupply + 1e18);
        uint256 _etherReceived =
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

        return _etherReceived;
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

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}