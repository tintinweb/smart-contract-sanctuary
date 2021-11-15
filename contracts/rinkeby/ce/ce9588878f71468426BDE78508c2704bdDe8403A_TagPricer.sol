// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;

interface ITagPricer {

    struct Price {
        address token;
        uint96 amount;
    }

    function getMintPrice(uint _tokenId, address /*_preferredPaymentToken*/) external view returns (Price memory price);
    function isValidPrice(Price calldata _price, Price calldata _paid) external view returns (bool);
    function convert(Price calldata _paid, address _toToken) external returns (uint96);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;
import "./ITagPricer.sol";

contract TagPricer is ITagPricer {

    uint constant private A = 0x41;
    uint constant private Z = 0x5A;

    uint public immutable maxBuyoutRatio;
    address public immutable quoteToken;
    uint96 public immutable price1;
    uint96 public immutable price2;
    uint96 public immutable price3;

    constructor(uint _maxBuyoutRatio, address _quoteToken, uint96[3] memory _prices) {
        maxBuyoutRatio = _maxBuyoutRatio;
        quoteToken = _quoteToken;
        price1 = _prices[0];
        price2 = _prices[1];
        price3 = _prices[2];
    } 

    function getMintPrice(uint _tokenId, address /*_quoteToken*/) external view override returns (Price memory price) {
        uint96 amount;
        uint char1 = _tokenId & 0xff;
        if(char1 >= A && char1 <= Z) {
            uint char2 = (_tokenId >> 8) & 0xff;
            if(char2 >= A && char2 <= Z) {
                uint char3 = (_tokenId >> 16) & 0xff;
                if(char3 >= A && char3 <= Z) {
                    if((_tokenId >> 24) == 0) {
                        amount = price3;
                    }
                } else if((_tokenId >> 16) == 0) {
                    amount = price2;
                }
            } else if((_tokenId >> 8) == 0) {
                amount = price1;
            }
        }

        if(amount == 0) {
            revert("tokenId not for sale");
        }
        price = Price(quoteToken, amount);
    }

    function isValidPrice(Price calldata _price, Price calldata _paid) external view override returns (bool) {
        return _price.token == _paid.token &&
            _price.amount > _paid.amount &&
            _price.amount <= maxBuyoutRatio * _paid.amount;
    }

    function convert(Price calldata /*_paid*/, address /*_toToken*/) external override returns (uint96) {
        revert("Payment convertion is not yet supported");
    }
}

