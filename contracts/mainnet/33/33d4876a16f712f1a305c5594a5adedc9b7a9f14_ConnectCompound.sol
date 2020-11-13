pragma solidity ^0.6.0;

interface CTokenInterface {
    function mint(uint mintAmount) external returns (uint);
    function redeem(uint redeemTokens) external returns (uint);
    function borrow(uint borrowAmount) external returns (uint);
    function repayBorrow(uint repayAmount) external returns (uint);

    function borrowBalanceCurrent(address account) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function exchangeRateCurrent() external returns (uint);

    function balanceOf(address owner) external view returns (uint256 balance);
}

interface CETHInterface {
    function mint() external payable;
    function repayBorrow() external payable;
}

interface TokenInterface {
    function allowance(address, address) external view returns (uint);
    function balanceOf(address) external view returns (uint);
    function approve(address, uint) external;
    function transfer(address, uint) external returns (bool);
    function transferFrom(address, address, uint) external returns (bool);
}

interface ComptrollerInterface {
    function enterMarkets(address[] calldata cTokens) external returns (uint[] memory);
    function exitMarket(address cTokenAddress) external returns (uint);
}

interface InstaMapping {
    function cTokenMapping(address) external view returns (address);
}

contract DSMath {

    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "math-not-safe");
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "math-not-safe");
    }

    uint constant WAD = 10 ** 18;

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

}


contract Helpers is DSMath {
    /**
     * @dev Return ethereum address
     */
    function getAddressETH() internal pure returns (address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE; // ETH Address
    }

    function getAddressWETH() internal pure returns (address) {
        return 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // mainnet
        // return 0xd0A1E359811322d97991E03f863a0C30C2cF029C; // kovan
    }

    function isETH(address token) internal pure returns(bool) {
        return token == getAddressETH() || token == getAddressWETH();
    }
}


contract CompoundHelpers is Helpers {
    /**
     * @dev Return Compound Comptroller Address
     */
    function getComptrollerAddress() internal pure returns (address) {
        return 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B; // main
        // return 0x1f5D7F3CaAC149fE41b8bd62A3673FE6eC0AB73b; // kovan
    }

    /**
     * @dev Return InstaDApp Mapping Addresses
     */
    function getMappingAddr() internal pure returns (address) {
        return 0xe81F70Cc7C0D46e12d70efc60607F16bbD617E88; // InstaMapping Address
    }


    /**
     * @dev enter compound market
     */
    function enterMarket(address cToken) internal {
        address[] memory cTokens = new address[](1);
        cTokens[0] = cToken;
        ComptrollerInterface troller = ComptrollerInterface(getComptrollerAddress());
        troller.enterMarkets(cTokens);
    }
}


contract BasicResolver is CompoundHelpers {
    event LogDeposit(address indexed token, uint256 tokenAmt);
    event LogWithdraw(address indexed token);
    event LogBorrow(address indexed token, uint256 tokenAmt);
    event LogPayback(address indexed token);

    /**
     * @dev Deposit ETH/ERC20_Token.
     * @param token token address to deposit.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amt token amount to deposit.
    */
    function deposit(address token, uint amt) external payable{
        address cToken = InstaMapping(getMappingAddr()).cTokenMapping(token);
        uint _amt = amt;
        enterMarket(cToken);
        if (isETH(token)) {
            _amt = _amt == uint(-1) ? address(this).balance : _amt;
            CETHInterface(cToken).mint.value(_amt)();
        } else {
            TokenInterface tokenContract = TokenInterface(token);
            _amt = _amt == uint(-1) ? tokenContract.balanceOf(address(this)) : _amt;
            tokenContract.approve(cToken, _amt);
            require(CTokenInterface(cToken).mint(_amt) == 0, "minting-failed");
        }

        emit LogDeposit(token, _amt);
    }

    /**
     * @dev Withdraw ETH/ERC20_Token.
     * @param token token address to withdraw.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amt token amount to withdraw.
    */
    function withdraw(address token, uint amt) external {
        address cToken = InstaMapping(getMappingAddr()).cTokenMapping(token);
        CTokenInterface cTokenContract = CTokenInterface(cToken);
        if (amt == uint(-1)) {
            require(cTokenContract.redeem(cTokenContract.balanceOf(address(this))) == 0, "full-withdraw-failed");
        } else {
            require(cTokenContract.redeemUnderlying(amt) == 0, "withdraw-failed");
        }

        emit LogWithdraw(token);
    }

    /**
     * @dev Borrow ETH/ERC20_Token.
     * @param token token address to borrow.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amt token amount to borrow.
    */
    function borrow(address token, uint amt) external {
        uint _amt = amt;
        address cToken = InstaMapping(getMappingAddr()).cTokenMapping(token);
        enterMarket(cToken);
        require(CTokenInterface(cToken).borrow(_amt) == 0, "borrow-failed");

        emit LogBorrow(token, _amt);
    }

    /**
     * @dev Payback borrowed ETH/ERC20_Token.
     * @param token token address to payback.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amt token amount to payback.
    */
    function payback(address token, uint amt) external {
        address cToken = InstaMapping(getMappingAddr()).cTokenMapping(token);
        CTokenInterface cTokenContract = CTokenInterface(cToken);
        uint _amt = amt == uint(-1) ? cTokenContract.borrowBalanceCurrent(address(this)) : amt;

        if (isETH(token)) {
            require(address(this).balance >= _amt, "not-enough-eth");
            CETHInterface(cToken).repayBorrow.value(_amt)();
        } else {
            TokenInterface tokenContract = TokenInterface(token);
            require(tokenContract.balanceOf(address(this)) >= _amt, "not-enough-token");
            tokenContract.approve(cToken, _amt);
            require(cTokenContract.repayBorrow(_amt) == 0, "repay-failed.");
        }

        emit LogPayback(token);
    }
}

contract ConnectCompound is BasicResolver {
    string public name = "flashloan-Compound-v1.0";
}