/**
 *Submitted for verification at Etherscan.io on 2021-03-06
*/

pragma solidity ^0.4.25;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0 uint256 c = a / b;
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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

interface token {function transfer(address receiver, uint amount) external;}

contract Crowdsale {
    using SafeMath for uint256;
    address public wallet;
    address public tokenAddress;
    uint256 public price = 1000;
    uint256 public constant ETHMin = 0.1 ether;
    uint256 public constant ETHMax = 50 ether;

    token tokenReward;

    uint256 public startSale = now;
    uint256 public ETHRaised;

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    constructor () public {
        wallet = 0xEF8938c2296E16d05a301a42F6e6Cb8f85a386c1;
        tokenAddress = address(this);
        tokenReward = token(tokenAddress);
    }

    bool public closed;

    function closeSale() public {
        require(msg.sender == wallet);
        require(!closed); closed = true;
    }

    function setPrice(uint256 _price) public {
        require(msg.sender == wallet);
        price = _price;
    }

    function () payable public {
        buyTokens(msg.sender);
    }
    // low level token purchase function
    function buyTokens(address beneficiary) payable public {
        require(beneficiary != 0x0);
        require((now >= startSale) && (startSale > 0));
        require(!closed);
        require(msg.value >= ETHMin && msg.value <= ETHMax);
        uint256 ETHAmount = msg.value;
        uint256 tokens = (ETHAmount) * price;
        ETHRaised = ETHRaised.add(ETHAmount);
        tokenReward.transfer(beneficiary, tokens);
        emit TokenPurchase(msg.sender, beneficiary, ETHAmount, tokens);
        forwardFunds();
    }

    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }
}