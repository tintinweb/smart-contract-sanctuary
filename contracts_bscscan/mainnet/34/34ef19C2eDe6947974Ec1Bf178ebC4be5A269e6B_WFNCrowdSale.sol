/**
 *Submitted for verification at BscScan.com on 2021-11-29
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);
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
        require(c / a == b, "Multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {
    
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Recipient may have reverted");
    }

    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function toPayable(address account) internal pure returns (address payable) {
        return payable(address(uint160(account)));
    }
}

contract ReentrancyGuard {
    bool private _notEntered;

    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }

    constructor() {
        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;
    }
}

abstract contract Context {

    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId) external view returns ( uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound );

    function latestRoundData() external view returns ( uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound );
}

contract WFNCrowdSale is Context, ReentrancyGuard {
    using SafeMath for uint256;

    IERC20 private _token;
    address payable private _wallet;
    uint256 private constant _RATE = 5 * 10**13;
    uint256 private _weiRaised;

    address private _tokenWallet;

    AggregatorV3Interface internal priceFeed;

    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    constructor (address payable tempWallet, IERC20 tempToken, address tempTokenWallet) {
        require(tempWallet != address(0), "Wallet is the zero address");
        require(address(tempToken) != address(0), "Token is the zero address");
        require(tempTokenWallet != address(0), "Token wallet is the zero address");

        _wallet = tempWallet;
        _token = tempToken;
        _tokenWallet = tempTokenWallet;

        priceFeed = AggregatorV3Interface(0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE);
    }

    receive() external payable {
        buyTokens(_msgSender());
    }

    function buyTokens(address beneficiary) public nonReentrant payable {
        uint256 weiAmount = msg.value;
        _preValidatePurchase(beneficiary, weiAmount);

        _weiRaised = _weiRaised.add(weiAmount);
        
        uint256 tokens = _getTokenAmount(weiAmount);

        _deliverTokens(beneficiary, tokens);
        emit TokensPurchased(_msgSender(), beneficiary, weiAmount, tokens);

        _forwardFunds();
    }

    function token() public view returns (IERC20) {
        return _token;
    }

    function wallet() public view returns (address payable) {
        return _wallet;
    }

    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }

    function _getTokenAmount(uint256 weiAmount) public view returns (uint256) {
        (uint256 bnbAggregatedPrice) = getAggregatedPrice();

        uint256 tokenAmount = ((bnbAggregatedPrice/_RATE) * weiAmount)/(10**13);

        return tokenAmount;
    }

    function tokenWallet() public view returns (address) {
        return _tokenWallet;
    }

    function remainingTokens() public view returns (uint256) {
        return _min(token().balanceOf(_tokenWallet), token().allowance(_tokenWallet, address(this)));
    }

    function rate() public pure returns (uint256) {
        return _RATE;
    }

    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal {
        _token.transferFrom(_tokenWallet, beneficiary, tokenAmount);
    }

    function _forwardFunds() internal {
        _wallet.transfer(msg.value);
    }

    function getAggregatedPrice() internal view returns (uint256){
        ( , int price, , , ) = priceFeed.latestRoundData();
        uint8 decimals = priceFeed.decimals();

        uint256 priceWithDecimals = uint256(price) * (10**(18 - decimals));

        return priceWithDecimals;
    }

    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal pure {
        require(beneficiary != address(0), "Beneficiary is the zero address");
        require(weiAmount != 0, "weiAmount is 0");
    }

    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}