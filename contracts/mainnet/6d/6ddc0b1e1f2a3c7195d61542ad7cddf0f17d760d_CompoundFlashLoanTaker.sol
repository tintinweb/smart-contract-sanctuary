/**
 *Submitted for verification at Etherscan.io on 2020-05-29
*/

pragma solidity ^0.6.0; interface ERC20 {
    function totalSupply() external view returns (uint256 supply);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transfer(address _to, uint256 _value) external returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value)
        external
        returns (bool success);

    function approve(address _spender, uint256 _value) external returns (bool success);

    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    function decimals() external view returns (uint256 digits);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
} abstract contract GasTokenInterface is ERC20 {
    function free(uint256 value) public virtual returns (bool success);

    function freeUpTo(uint256 value) public virtual returns (uint256 freed);

    function freeFrom(address from, uint256 value) public virtual returns (bool success);

    function freeFromUpTo(address from, uint256 value) public virtual returns (uint256 freed);
} contract GasBurner {
    // solhint-disable-next-line const-name-snakecase
    GasTokenInterface public constant gasToken = GasTokenInterface(0x0000000000b3F879cb30FE243b4Dfee438691c04);

    modifier burnGas(uint _amount) {
        uint gst2Amount = _amount;

        if (_amount == 0) {
            gst2Amount = (gasleft() + 14154) / (2 * 24000 - 6870);
            gst2Amount = gst2Amount - (gst2Amount / 8); // 12.5% less because of gaslimit != gas_used
        }

        if (gasToken.balanceOf(address(this)) >= gst2Amount) {
            gasToken.free(gst2Amount);
        }

        _;
    }
} abstract contract ILendingPool {
    function flashLoan( address payable _receiver, address _reserve, uint _amount, bytes calldata _params) external virtual;
    function deposit(address _reserve, uint256 _amount, uint16 _referralCode) external virtual payable;
	function setUserUseReserveAsCollateral(address _reserve, bool _useAsCollateral) external virtual;
	function borrow(address _reserve, uint256 _amount, uint256 _interestRateMode, uint16 _referralCode) external virtual;
	function repay( address _reserve, uint256 _amount, address payable _onBehalfOf) external virtual;
	function getReserveData(address _reserve)
        external virtual
        view
        returns (
            uint256 totalLiquidity,
            uint256 availableLiquidity,
            uint256 totalBorrowsStable,
            uint256 totalBorrowsVariable,
            uint256 liquidityRate,
            uint256 variableBorrowRate,
            uint256 stableBorrowRate,
            uint256 averageStableBorrowRate,
            uint256 utilizationRate,
            uint256 liquidityIndex,
            uint256 variableBorrowIndex,
            address aTokenAddress,
            uint40 lastUpdateTimestamp
        );
} //TODO: currenlty only adjusted to kyber, but should be genric interfaces for more dec. exchanges
interface ExchangeInterface {
    function swapEtherToToken(uint256 _ethAmount, address _tokenAddress, uint256 _maxAmount)
        external
        payable
        returns (uint256, uint256);

    function swapTokenToEther(address _tokenAddress, uint256 _amount, uint256 _maxAmount)
        external
        returns (uint256);

    function swapTokenToToken(address _src, address _dest, uint256 _amount)
        external
        payable
        returns (uint256);

    function getExpectedRate(address src, address dest, uint256 srcQty)
        external
        view
        returns (uint256 expectedRate);
} abstract contract TokenInterface {
    function allowance(address, address) public virtual returns (uint256);

    function balanceOf(address) public virtual returns (uint256);

    function approve(address, uint256) public virtual;

    function transfer(address, uint256) public virtual returns (bool);

    function transferFrom(address, address, uint256) public virtual returns (bool);

    function deposit() public virtual payable;

    function withdraw(uint256) public virtual;
} abstract contract SaverExchangeInterface {
    function getBestPrice(
        uint256 _amount,
        address _srcToken,
        address _destToken,
        uint256 _exchangeType
    ) public view virtual returns (address, uint256);
} contract ConstantAddressesExchangeMainnet {
    address public constant MAKER_DAI_ADDRESS = 0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359;
    address public constant KYBER_ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant MKR_ADDRESS = 0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2;
    address public constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address payable public constant WALLET_ID = 0x322d58b9E75a6918f7e7849AEe0fF09369977e08;
    address public constant LOGGER_ADDRESS = 0xeCf88e1ceC2D2894A0295DB3D86Fe7CE4991E6dF;
    address public constant DISCOUNT_ADDRESS = 0x1b14E8D511c9A4395425314f849bD737BAF8208F;

    address public constant GAS_TOKEN_INTERFACE_ADDRESS = 0x0000000000b3F879cb30FE243b4Dfee438691c04;
    address public constant SAVER_EXCHANGE_ADDRESS = 0x862F3dcF1104b8a9468fBb8B843C37C31B41eF09;

    // new MCD contracts
    address public constant MANAGER_ADDRESS = 0x5ef30b9986345249bc32d8928B7ee64DE9435E39;
    address public constant VAT_ADDRESS = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;
    address public constant SPOTTER_ADDRESS = 0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3;
    address public constant PROXY_ACTIONS = 0x82ecD135Dce65Fbc6DbdD0e4237E0AF93FFD5038;

    address public constant JUG_ADDRESS = 0x19c0976f590D67707E62397C87829d896Dc0f1F1;
    address public constant DAI_JOIN_ADDRESS = 0x9759A6Ac90977b93B58547b4A71c78317f391A28;
    address public constant ETH_JOIN_ADDRESS = 0x2F0b23f53734252Bda2277357e97e1517d6B042A;
    address public constant MIGRATION_ACTIONS_PROXY = 0xe4B22D484958E582098A98229A24e8A43801b674;

    address public constant SAI_ADDRESS = 0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359;
    address public constant DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    address payable public constant SCD_MCD_MIGRATION = 0xc73e0383F3Aff3215E6f04B0331D58CeCf0Ab849;

    // Our contracts
    address public constant ERC20_PROXY_0X = 0x95E6F48254609A6ee006F7D493c8e5fB97094ceF;
    address public constant NEW_IDAI_ADDRESS = 0x6c1E2B0f67e00c06c8e2BE7Dc681Ab785163fF4D;
} contract ConstantAddressesExchangeKovan {
    address public constant MAKER_DAI_ADDRESS = 0xC4375B7De8af5a38a93548eb8453a498222C4fF2;
    address public constant KYBER_ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant MKR_ADDRESS = 0xAaF64BFCC32d0F15873a02163e7E500671a4ffcD;
    address public constant WETH_ADDRESS = 0xd0A1E359811322d97991E03f863a0C30C2cF029C;
    address payable public constant WALLET_ID = 0x54b44C6B18fc0b4A1010B21d524c338D1f8065F6;
    address public constant LOGGER_ADDRESS = 0x32d0e18f988F952Eb3524aCE762042381a2c39E5;
    address public constant DISCOUNT_ADDRESS = 0x1297c1105FEDf45E0CF6C102934f32C4EB780929;

    address public constant GAS_TOKEN_INTERFACE_ADDRESS = 0x0000000000170CcC93903185bE5A2094C870Df62;
    address public constant SAVER_EXCHANGE_ADDRESS = 0xACA7d11e3f482418C324aAC8e90AaD0431f692A6;

    // new MCD contracts
    address public constant MANAGER_ADDRESS = 0x1476483dD8C35F25e568113C5f70249D3976ba21;
    address public constant VAT_ADDRESS = 0xbA987bDB501d131f766fEe8180Da5d81b34b69d9;
    address public constant SPOTTER_ADDRESS = 0x3a042de6413eDB15F2784f2f97cC68C7E9750b2D;
    address public constant PROXY_ACTIONS = 0xd1D24637b9109B7f61459176EdcfF9Be56283a7B;

    address public constant JUG_ADDRESS = 0xcbB7718c9F39d05aEEDE1c472ca8Bf804b2f1EaD;
    address public constant DAI_JOIN_ADDRESS = 0x5AA71a3ae1C0bd6ac27A1f28e1415fFFB6F15B8c;
    address public constant ETH_JOIN_ADDRESS = 0x775787933e92b709f2a3C70aa87999696e74A9F8;
    address public constant MIGRATION_ACTIONS_PROXY = 0x433870076aBd08865f0e038dcC4Ac6450e313Bd8;

    address public constant SAI_ADDRESS = 0xC4375B7De8af5a38a93548eb8453a498222C4fF2;
    address public constant DAI_ADDRESS = 0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa;

    address payable public constant SCD_MCD_MIGRATION = 0x411B2Faa662C8e3E5cF8f01dFdae0aeE482ca7b0;

    // Our contracts
    address public constant ERC20_PROXY_0X = 0x95E6F48254609A6ee006F7D493c8e5fB97094ceF;
    address public constant NEW_IDAI_ADDRESS = 0x6c1E2B0f67e00c06c8e2BE7Dc681Ab785163fF4D;
} // solhint-disable-next-line no-empty-blocks
contract ConstantAddressesExchange is ConstantAddressesExchangeMainnet {} /// @title Helper methods for integration with SaverExchange
contract ExchangeHelper is ConstantAddressesExchange {

    /// @notice Swaps 2 tokens on the Saver Exchange
    /// @dev ETH is sent with Weth address
    /// @param _data [amount, minPrice, exchangeType, 0xPrice]
    /// @param _src Token address of the source token
    /// @param _dest Token address of the destination token
    /// @param _exchangeAddress Address of 0x exchange that should be called
    /// @param _callData data to call 0x exchange with
    function swap(uint[4] memory _data, address _src, address _dest, address _exchangeAddress, bytes memory _callData) internal returns (uint) {
        address wrapper;
        uint price;
        // [tokensReturned, tokensLeft]
        uint[2] memory tokens;
        bool success;

        // tokensLeft is equal to amount at the beginning
        tokens[1] = _data[0];

        _src = wethToKyberEth(_src);
        _dest = wethToKyberEth(_dest);

        // use this to avoid stack too deep error
        address[3] memory orderAddresses = [_exchangeAddress, _src, _dest];

        // if _data[2] == 4 use 0x if possible
        if (_data[2] == 4) {
            if (orderAddresses[1] != KYBER_ETH_ADDRESS) {
                ERC20(orderAddresses[1]).approve(address(ERC20_PROXY_0X), _data[0]);
            }

            (success, tokens[0], ) = takeOrder(orderAddresses, _callData, address(this).balance, _data[0]);

            // if specifically 4, then require it to be successfull
            require(success && tokens[0] > 0, "0x transaction failed");
        }

        // no 0x
        // if (_data[2] == 5) {
        //     (wrapper, price) = SaverExchangeInterface(SAVER_EXCHANGE_ADDRESS).getBestPrice(tokens[1], orderAddresses[1], orderAddresses[2], _data[2]);

        //     require(price > _data[1], "Slippage hit onchain price");

        //     if (orderAddresses[1] == KYBER_ETH_ADDRESS) {
        //         uint tRet;
        //         (tRet,) = ExchangeInterface(wrapper).swapEtherToToken.value(tokens[1])(tokens[1], orderAddresses[2], uint(-1));
        //         tokens[0] += tRet;
        //     } else {
        //         ERC20(orderAddresses[1]).transfer(wrapper, tokens[1]);

        //         if (orderAddresses[2] == KYBER_ETH_ADDRESS) {
        //             tokens[0] += ExchangeInterface(wrapper).swapTokenToEther(orderAddresses[1], tokens[1], uint(-1));
        //         } else {
        //             tokens[0] += ExchangeInterface(wrapper).swapTokenToToken(orderAddresses[1], orderAddresses[2], tokens[1]);
        //         }
        //     }

        //     return tokens[0];
        // }

        if (tokens[0] == 0) {
            (wrapper, price) = SaverExchangeInterface(SAVER_EXCHANGE_ADDRESS).getBestPrice(_data[0], orderAddresses[1], orderAddresses[2], _data[2]);

            require(price > _data[1] || _data[3] > _data[1], "Slippage hit");

            // handle 0x exchange, if equal price, try 0x to use less gas
            if (_data[3] >= price) {
                if (orderAddresses[1] != KYBER_ETH_ADDRESS) {
                    ERC20(orderAddresses[1]).approve(address(ERC20_PROXY_0X), _data[0]);
                }

                // when selling eth its possible that some eth isn't sold and it is returned back
                (success, tokens[0], tokens[1]) = takeOrder(orderAddresses, _callData, address(this).balance, _data[0]);
            }

            // if there are more tokens left, try to sell them on other exchanges
            if (tokens[1] > 0) {
                // as it stands today, this can happend only when selling ETH
                if (tokens[1] != _data[0]) {
                    (wrapper, price) = SaverExchangeInterface(SAVER_EXCHANGE_ADDRESS).getBestPrice(tokens[1], orderAddresses[1], orderAddresses[2], _data[2]);
                }

                require(price > _data[1], "Slippage hit onchain price");

                if (orderAddresses[1] == KYBER_ETH_ADDRESS) {
                    uint tRet;
                    (tRet,) = ExchangeInterface(wrapper).swapEtherToToken{value: tokens[1]}(tokens[1], orderAddresses[2], uint(-1));
                    tokens[0] += tRet;
                } else {
                    ERC20(orderAddresses[1]).transfer(wrapper, tokens[1]);

                    if (orderAddresses[2] == KYBER_ETH_ADDRESS) {
                        tokens[0] += ExchangeInterface(wrapper).swapTokenToEther(orderAddresses[1], tokens[1], uint(-1));
                    } else {
                        tokens[0] += ExchangeInterface(wrapper).swapTokenToToken(orderAddresses[1], orderAddresses[2], tokens[1]);
                    }
                }
            }
        }

        return tokens[0];
    }

    // @notice Takes order from 0x and returns bool indicating if it is successful
    // @param _addresses [exchange, src, dst]
    // @param _data Data to send with call
    // @param _value Value to send with call
    // @param _amount Amount to sell
    function takeOrder(address[3] memory _addresses, bytes memory _data, uint _value, uint _amount) private returns(bool, uint, uint) {
        bool success;

        (success, ) = _addresses[0].call{value: _value}(_data);

        uint tokensLeft = _amount;
        uint tokensReturned = 0;
        if (success){
            // check how many tokens left from _src
            if (_addresses[1] == KYBER_ETH_ADDRESS) {
                tokensLeft = address(this).balance;
            } else {
                tokensLeft = ERC20(_addresses[1]).balanceOf(address(this));
            }

            // check how many tokens are returned
            if (_addresses[2] == KYBER_ETH_ADDRESS) {
                TokenInterface(WETH_ADDRESS).withdraw(TokenInterface(WETH_ADDRESS).balanceOf(address(this)));
                tokensReturned = address(this).balance;
            } else {
                tokensReturned = ERC20(_addresses[2]).balanceOf(address(this));
            }
        }

        return (success, tokensReturned, tokensLeft);
    }

    /// @notice Converts WETH -> Kybers Eth address
    /// @param _src Input address
    function wethToKyberEth(address _src) internal pure returns (address) {
        return _src == WETH_ADDRESS ? KYBER_ETH_ADDRESS : _src;
    }
} contract CompoundLogger {
    event Repay(
        address indexed owner,
        uint256 collateralAmount,
        uint256 borrowAmount,
        address collAddr,
        address borrowAddr
    );

    event Boost(
        address indexed owner,
        uint256 borrowAmount,
        uint256 collateralAmount,
        address collAddr,
        address borrowAddr
    );

    // solhint-disable-next-line func-name-mixedcase
    function LogRepay(address _owner, uint256 _collateralAmount, uint256 _borrowAmount, address _collAddr, address _borrowAddr)
        public
    {
        emit Repay(_owner, _collateralAmount, _borrowAmount, _collAddr, _borrowAddr);
    }

    // solhint-disable-next-line func-name-mixedcase
    function LogBoost(address _owner, uint256 _borrowAmount, uint256 _collateralAmount, address _collAddr, address _borrowAddr)
        public
    {
        emit Boost(_owner, _borrowAmount, _collateralAmount, _collAddr, _borrowAddr);
    }
} abstract contract CEtherInterface {
    function mint() external virtual payable;
    function repayBorrow() external virtual payable;
} abstract contract CompoundOracleInterface {
    function getUnderlyingPrice(address cToken) external view virtual returns (uint);
} abstract contract CTokenInterface is ERC20 {
    function mint(uint256 mintAmount) external virtual returns (uint256);

    function mint() external virtual payable;

    function redeem(uint256 redeemTokens) external virtual returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external virtual returns (uint256);

    function borrow(uint256 borrowAmount) external virtual returns (uint256);

    function repayBorrow(uint256 repayAmount) external virtual returns (uint256);

    function repayBorrow() external virtual payable;

    function repayBorrowBehalf(address borrower, uint256 repayAmount) external virtual returns (uint256);

    function repayBorrowBehalf(address borrower) external virtual payable;

    function liquidateBorrow(address borrower, uint256 repayAmount, address cTokenCollateral)
        external virtual
        returns (uint256);

    function liquidateBorrow(address borrower, address cTokenCollateral) external virtual payable;

    function exchangeRateCurrent() external virtual returns (uint256);

    function supplyRatePerBlock() external virtual returns (uint256);

    function borrowRatePerBlock() external virtual returns (uint256);

    function totalReserves() external virtual returns (uint256);

    function reserveFactorMantissa() external virtual returns (uint256);

    function borrowBalanceCurrent(address account) external virtual returns (uint256);

    function totalBorrowsCurrent() external virtual returns (uint256);

    function getCash() external virtual returns (uint256);

    function balanceOfUnderlying(address owner) external virtual returns (uint256);

    function underlying() external virtual returns (address);

    function getAccountSnapshot(address account) external virtual view returns (uint, uint, uint, uint);
} abstract contract ComptrollerInterface {
    function enterMarkets(address[] calldata cTokens) external virtual returns (uint256[] memory);

    function exitMarket(address cToken) external virtual returns (uint256);

    function getAssetsIn(address account) external virtual view returns (address[] memory);

    function markets(address account) public virtual view returns (bool, uint256);

    function getAccountLiquidity(address account) external virtual view returns (uint256, uint256, uint256);
} contract Discount {
    address public owner;
    mapping(address => CustomServiceFee) public serviceFees;

    uint256 constant MAX_SERVICE_FEE = 400;

    struct CustomServiceFee {
        bool active;
        uint256 amount;
    }

    constructor() public {
        owner = msg.sender;
    }

    function isCustomFeeSet(address _user) public view returns (bool) {
        return serviceFees[_user].active;
    }

    function getCustomServiceFee(address _user) public view returns (uint256) {
        return serviceFees[_user].amount;
    }

    function setServiceFee(address _user, uint256 _fee) public {
        require(msg.sender == owner, "Only owner");
        require(_fee >= MAX_SERVICE_FEE || _fee == 0);

        serviceFees[_user] = CustomServiceFee({active: true, amount: _fee});
    }

    function disableServiceFee(address _user) public {
        require(msg.sender == owner, "Only owner");

        serviceFees[_user] = CustomServiceFee({active: false, amount: 0});
    }
} contract DSMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function div(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x / y;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x <= y ? x : y;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x >= y ? x : y;
    }

    function imin(int256 x, int256 y) internal pure returns (int256 z) {
        return x <= y ? x : y;
    }

    function imax(int256 x, int256 y) internal pure returns (int256 z) {
        return x >= y ? x : y;
    }

    uint256 constant WAD = 10**18;
    uint256 constant RAY = 10**27;

    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }

    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    function rpow(uint256 x, uint256 n) internal pure returns (uint256 z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
} abstract contract DSAuthority {
    function canCall(address src, address dst, bytes4 sig) public virtual view returns (bool);
} contract DSAuthEvents {
    event LogSetAuthority(address indexed authority);
    event LogSetOwner(address indexed owner);
}


contract DSAuth is DSAuthEvents {
    DSAuthority public authority;
    address public owner;

    constructor() public {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
    }

    function setOwner(address owner_) public auth {
        owner = owner_;
        emit LogSetOwner(owner);
    }

    function setAuthority(DSAuthority authority_) public auth {
        authority = authority_;
        emit LogSetAuthority(address(authority));
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig));
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (authority == DSAuthority(0)) {
            return false;
        } else {
            return authority.canCall(src, address(this), sig);
        }
    }
} contract DSNote {
    event LogNote(
        bytes4 indexed sig,
        address indexed guy,
        bytes32 indexed foo,
        bytes32 indexed bar,
        uint256 wad,
        bytes fax
    ) anonymous;

    modifier note {
        bytes32 foo;
        bytes32 bar;

        assembly {
            foo := calldataload(4)
            bar := calldataload(36)
        }

        emit LogNote(msg.sig, msg.sender, foo, bar, msg.value, msg.data);

        _;
    }
} abstract contract DSProxy is DSAuth, DSNote {
    DSProxyCache public cache; // global cache for contracts

    constructor(address _cacheAddr) public {
        require(setCache(_cacheAddr));
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    // use the proxy to execute calldata _data on contract _code
    function execute(bytes memory _code, bytes memory _data)
        public
        payable
        virtual
        returns (address target, bytes32 response);

    function execute(address _target, bytes memory _data)
        public
        payable
        virtual
        returns (bytes32 response);

    //set new cache
    function setCache(address _cacheAddr) public virtual payable returns (bool);
}


contract DSProxyCache {
    mapping(bytes32 => address) cache;

    function read(bytes memory _code) public view returns (address) {
        bytes32 hash = keccak256(_code);
        return cache[hash];
    }

    function write(bytes memory _code) public returns (address target) {
        assembly {
            target := create(0, add(_code, 0x20), mload(_code))
            switch iszero(extcodesize(target))
                case 1 {
                    // throw if contract failed to deploy
                    revert(0, 0)
                }
        }
        bytes32 hash = keccak256(_code);
        cache[hash] = target;
    }
} /// @title Utlity functions for Compound contracts
contract CompoundSaverHelper is DSMath {

    address payable public constant WALLET_ADDR = 0x322d58b9E75a6918f7e7849AEe0fF09369977e08;
    address public constant DISCOUNT_ADDR = 0x1b14E8D511c9A4395425314f849bD737BAF8208F;

    uint public constant SERVICE_FEE = 400; // 0.25% Fee
    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant CETH_ADDRESS = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;
    address public constant COMPTROLLER = 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;

    address public constant COMPOUND_LOGGER = 0x3DD0CDf5fFA28C6847B4B276e2fD256046a44bb7;
    address public constant COMPOUND_ORACLE = 0xDDc46a3B076aec7ab3Fc37420A8eDd2959764Ec4;

    /// @notice Helper method to payback the Compound debt
    /// @dev If amount is bigger it will repay the whole debt and send the extra to the _user
    /// @param _amount Amount of tokens we want to repay
    /// @param _cBorrowToken Ctoken address we are repaying
    /// @param _borrowToken Token address we are repaying
    /// @param _user Owner of the compound position we are paying back
    function paybackDebt(uint _amount, address _cBorrowToken, address _borrowToken, address payable _user) internal {
        uint wholeDebt = CTokenInterface(_cBorrowToken).borrowBalanceCurrent(address(this));

        if (_amount > wholeDebt) {
            if (_borrowToken == ETH_ADDRESS) {
                _user.transfer((_amount - wholeDebt));
            } else {
                ERC20(_borrowToken).transfer(_user, (_amount - wholeDebt));
            }

            _amount = wholeDebt;
        }

        approveCToken(_borrowToken, _cBorrowToken);

        if (_borrowToken == ETH_ADDRESS) {
            CEtherInterface(_cBorrowToken).repayBorrow{value: _amount}();
        } else {
            require(CTokenInterface(_cBorrowToken).repayBorrow(_amount) == 0);
        }
    }

    /// @notice Calculates the fee amount
    /// @param _amount Amount that is converted
    /// @param _user Actuall user addr not DSProxy
    /// @param _gasCost Ether amount of gas we are spending for tx
    /// @param _cTokenAddr CToken addr. of token we are getting for the fee
    /// @return feeAmount The amount we took for the fee
    function getFee(uint _amount, address _user, uint _gasCost, address _cTokenAddr) internal returns (uint feeAmount) {
        uint fee = SERVICE_FEE;

        address tokenAddr = getUnderlyingAddr(_cTokenAddr);

        if (Discount(DISCOUNT_ADDR).isCustomFeeSet(_user)) {
            fee = Discount(DISCOUNT_ADDR).getCustomServiceFee(_user);
        }

        feeAmount = (fee == 0) ? 0 : (_amount / fee);

        if (_gasCost != 0) {
            uint ethTokenPrice = CompoundOracleInterface(COMPOUND_ORACLE).getUnderlyingPrice(_cTokenAddr);
            _gasCost = rmul(_gasCost, ethTokenPrice);

            feeAmount = add(feeAmount, _gasCost);
        }

        // fee can't go over 20% of the whole amount
        if (feeAmount > (_amount / 5)) {
            feeAmount = _amount / 5;
        }

        if (tokenAddr == ETH_ADDRESS) {
            WALLET_ADDR.transfer(feeAmount);
        } else {
            ERC20(tokenAddr).transfer(WALLET_ADDR, feeAmount);
        }
    }

    /// @notice Enters the market for the collatera and borrow tokens
    /// @param _cTokenAddrColl Collateral address we are entering the market in
    /// @param _cTokenAddrBorrow Borrow address we are entering the market in
    function enterMarket(address _cTokenAddrColl, address _cTokenAddrBorrow) internal {
        address[] memory markets = new address[](2);
        markets[0] = _cTokenAddrColl;
        markets[1] = _cTokenAddrBorrow;

        ComptrollerInterface(COMPTROLLER).enterMarkets(markets);
    }

    /// @notice Approves CToken contract to pull underlying tokens from the DSProxy
    /// @param _tokenAddr Token we are trying to approve
    /// @param _cTokenAddr Address which will gain the approval
    function approveCToken(address _tokenAddr, address _cTokenAddr) internal {
        if (_tokenAddr != ETH_ADDRESS) {
            ERC20(_tokenAddr).approve(_cTokenAddr, uint(-1));
        }
    }

    /// @notice Returns the underlying address of the cToken asset
    /// @param _cTokenAddress cToken address
    /// @return Token address of the cToken specified
    function getUnderlyingAddr(address _cTokenAddress) internal returns (address) {
        if (_cTokenAddress == CETH_ADDRESS) {
            return ETH_ADDRESS;
        } else {
            return CTokenInterface(_cTokenAddress).underlying();
        }
    }

    /// @notice Returns the owner of the DSProxy that called the contract
    function getUserAddress() internal view returns (address) {
        DSProxy proxy = DSProxy(uint160(address(this)));

        return proxy.owner();
    }

    /// @notice Returns the maximum amount of collateral available to withdraw
    /// @dev Due to rounding errors the result is - 1% wei from the exact amount
    /// @param _cCollAddress Collateral we are getting the max value of
    /// @param _account Users account
    /// @return Returns the max. collateral amount in that token
    function getMaxCollateral(address _cCollAddress, address _account) public returns (uint) {
        (, uint liquidityInEth, ) = ComptrollerInterface(COMPTROLLER).getAccountLiquidity(_account);
        uint usersBalance = CTokenInterface(_cCollAddress).balanceOfUnderlying(_account);

        if (liquidityInEth == 0) return usersBalance;

        if (_cCollAddress == CETH_ADDRESS) {
            if (liquidityInEth > usersBalance) return usersBalance;

            return liquidityInEth;
        }

        uint ethPrice = CompoundOracleInterface(COMPOUND_ORACLE).getUnderlyingPrice(_cCollAddress);
        uint liquidityInToken = wdiv(liquidityInEth, ethPrice);

        if (liquidityInToken > usersBalance) return usersBalance;

        return sub(liquidityInToken, (liquidityInToken / 100)); // cut off 1% due to rounding issues
    }

    /// @notice Returns the maximum amount of borrow amount available
    /// @dev Due to rounding errors the result is - 1% wei from the exact amount
    /// @param _cBorrowAddress Borrow token we are getting the max value of
    /// @param _account Users account
    /// @return Returns the max. borrow amount in that token
    function getMaxBorrow(address _cBorrowAddress, address _account) public view returns (uint) {
        (, uint liquidityInEth, ) = ComptrollerInterface(COMPTROLLER).getAccountLiquidity(_account);

        if (_cBorrowAddress == CETH_ADDRESS) return liquidityInEth;

        uint ethPrice = CompoundOracleInterface(COMPOUND_ORACLE).getUnderlyingPrice(_cBorrowAddress);
        uint liquidityInToken = wdiv(liquidityInEth, ethPrice);

        return sub(liquidityInToken, (liquidityInToken / 100)); // cut off 1% due to rounding issues
    }
} /// @title Contract that implements repay/boost functionality
contract CompoundSaverProxy is CompoundSaverHelper, ExchangeHelper {

    /// @notice Withdraws collateral, converts to borrowed token and repays debt
    /// @dev Called through the DSProxy
    /// @param _data Amount and exchange data for the repay [amount, minPrice, exchangeType, gasCost, 0xPrice]
    /// @param _addrData Coll/Debt addresses [cCollAddress, cBorrowAddress, exchangeAddress]
    /// @param _callData 0x calldata info
    function repay(
        uint[5] memory _data, // amount, minPrice, exchangeType, gasCost, 0xPrice
        address[3] memory _addrData, // cCollAddress, cBorrowAddress, exchangeAddress
        bytes memory _callData
    ) public payable {
        enterMarket(_addrData[0], _addrData[1]);

        address payable user = address(uint160(getUserAddress()));

        uint maxColl = getMaxCollateral(_addrData[0], address(this));

        uint collAmount = (_data[0] > maxColl) ? maxColl : _data[0];

        require(CTokenInterface(_addrData[0]).redeemUnderlying(collAmount) == 0);

        address collToken = getUnderlyingAddr(_addrData[0]);
        address borrowToken = getUnderlyingAddr(_addrData[1]);

        uint swapAmount = swap(
            [collAmount, _data[1], _data[2], _data[4]], // collAmount, minPrice, exchangeType, 0xPrice
            collToken,
            borrowToken,
            _addrData[2],
            _callData
        );

        swapAmount -= getFee(swapAmount, user, _data[3], _addrData[1]);

        paybackDebt(swapAmount, _addrData[1], borrowToken, user);

        // handle 0x fee
        user.transfer(address(this).balance);

        CompoundLogger(COMPOUND_LOGGER).LogRepay(user, _data[0], swapAmount, collToken, borrowToken);
    }

    /// @notice Borrows token, converts to collateral, and adds to position
    /// @dev Called through the DSProxy
    /// @param _data Amount and exchange data for the boost [amount, minPrice, exchangeType, gasCost, 0xPrice]
    /// @param _addrData Coll/Debt addresses [cCollAddress, cBorrowAddress, exchangeAddress]
    /// @param _callData 0x calldata info
    function boost(
        uint[5] memory _data, // amount, minPrice, exchangeType, gasCost, 0xPrice
        address[3] memory _addrData, // cCollAddress, cBorrowAddress, exchangeAddress
        bytes memory _callData
    ) public payable {
        enterMarket(_addrData[0], _addrData[1]);

        address payable user = address(uint160(getUserAddress()));

        uint maxBorrow = getMaxBorrow(_addrData[1], address(this));
        uint borrowAmount = (_data[0] > maxBorrow) ? maxBorrow : _data[0];

        require(CTokenInterface(_addrData[1]).borrow(borrowAmount) == 0);

        address collToken = getUnderlyingAddr(_addrData[0]);
        address borrowToken = getUnderlyingAddr(_addrData[1]);

        borrowAmount -= getFee(borrowAmount, user, _data[3], _addrData[1]);

        uint swapAmount = swap(
            [borrowAmount, _data[1], _data[2], _data[4]], // collAmount, minPrice, exchangeType, 0xPrice
            borrowToken,
            collToken,
            _addrData[2],
            _callData
        );

        approveCToken(collToken, _addrData[0]);

        if (collToken != ETH_ADDRESS) {
            require(CTokenInterface(_addrData[0]).mint(swapAmount) == 0);
        } else {
            CEtherInterface(_addrData[0]).mint{value: swapAmount}(); // reverts on fail
        }

        // handle 0x fee
        user.transfer(address(this).balance);

        CompoundLogger(COMPOUND_LOGGER).LogBoost(user, _data[0], swapAmount, collToken, borrowToken);
    }

} contract FlashLoanLogger {
    event FlashLoan(string actionType, uint256 id, uint256 loanAmount, address sender);

    function logFlashLoan(
        string calldata _actionType,
        uint256 _id,
        uint256 _loanAmount,
        address _sender
    ) external {
        emit FlashLoan(_actionType, _loanAmount, _id, _sender);
    }
} abstract contract DSGuard {
    function canCall(address src_, address dst_, bytes4 sig) public view virtual returns (bool);

    function permit(bytes32 src, bytes32 dst, bytes32 sig) public virtual;

    function forbid(bytes32 src, bytes32 dst, bytes32 sig) public virtual;

    function permit(address src, address dst, bytes32 sig) public virtual;

    function forbid(address src, address dst, bytes32 sig) public virtual;
}


abstract contract DSGuardFactory {
    function newGuard() public virtual returns (DSGuard guard);
} contract ProxyPermission {
    address public constant FACTORY_ADDRESS = 0x5a15566417e6C1c9546523066500bDDBc53F88C7;

    /// @notice Called in the context of DSProxy to authorize an address
    /// @param _contractAddr Address which will be authorized
    function givePermission(address _contractAddr) internal {
        address currAuthority = address(DSAuth(address(this)).authority());
        DSGuard guard = DSGuard(currAuthority);

        if (currAuthority == address(0)) {
            guard = DSGuardFactory(FACTORY_ADDRESS).newGuard();
            DSAuth(address(this)).setAuthority(DSAuthority(address(guard)));
        }

        guard.permit(_contractAddr, address(this), bytes4(keccak256("execute(address,bytes)")));
    }

    /// @notice Called in the context of DSProxy to remove authority of an address
    /// @param _contractAddr Auth address which will be removed from authority list
    function removePermission(address _contractAddr) internal {
        address currAuthority = address(DSAuth(address(this)).authority());
        DSGuard guard = DSGuard(currAuthority);

        guard.forbid(_contractAddr, address(this), bytes4(keccak256("execute(address,bytes)")));
    }
} /// @title Entry point for the FL Repay Boosts, called by DSProxy
contract CompoundFlashLoanTaker is CompoundSaverProxy, ProxyPermission, GasBurner {
    ILendingPool public constant lendingPool = ILendingPool(0x398eC7346DcD622eDc5ae82352F02bE94C62d119);

    address payable public constant COMPOUND_SAVER_FLASH_LOAN = 0x632cfd9245B7A4692F03b3D562Ed01E5cff94898;

    // solhint-disable-next-line const-name-snakecase
    FlashLoanLogger public constant logger = FlashLoanLogger(
        0xb9303686B0EE92F92f63973EF85f3105329D345c
    );

    /// @notice Repays the position with it's own fund or with FL if needed
    /// @param _data Amount and exchange data [amount, minPrice, exchangeType, gasCost, 0xPrice]
    /// @param _addrData cTokens addreses and exchange [cCollAddress, cBorrowAddress, exchangeAddress]
    /// @param _callData 0x callData
    function repayWithLoan(
        uint[5] calldata _data, // amount, minPrice, exchangeType, gasCost, 0xPrice
        address[3] calldata _addrData, // cCollAddress, cBorrowAddress, exchangeAddress
        bytes calldata _callData
    ) external payable burnGas(0) {
        uint maxColl = getMaxCollateral(_addrData[0], address(this));

        if (_data[0] <= maxColl) {
            repay(_data, _addrData, _callData);
        } else {
            // 0x fee
            COMPOUND_SAVER_FLASH_LOAN.transfer(msg.value);

            uint loanAmount = (_data[0] - maxColl);
            bytes memory paramsData = abi.encode(_data, _addrData, _callData, true, address(this));

            givePermission(COMPOUND_SAVER_FLASH_LOAN);

            lendingPool.flashLoan(COMPOUND_SAVER_FLASH_LOAN, getUnderlyingAddr(_addrData[0]), loanAmount, paramsData);

            removePermission(COMPOUND_SAVER_FLASH_LOAN);

            logger.logFlashLoan("CompoundFlashRepay", loanAmount, _data[0], _addrData[0]);
        }
    }

    /// @notice Boosts the position with it's own fund or with FL if needed
    /// @param _data Amount and exchange data [amount, minPrice, exchangeType, gasCost, 0xPrice]
    /// @param _addrData cTokens addreses and exchange [cCollAddress, cBorrowAddress, exchangeAddress]
    /// @param _callData 0x callData
    function boostWithLoan(
        uint[5] calldata _data, // amount, minPrice, exchangeType, gasCost, 0xPrice
        address[3] calldata _addrData, // cCollAddress, cBorrowAddress, exchangeAddress
        bytes calldata _callData
    ) external payable burnGas(0) {
        uint maxBorrow = getMaxBorrow(_addrData[1], address(this));

        if (_data[0] <= maxBorrow) {
            boost(_data, _addrData, _callData);
        } else {
            // 0x fee
            COMPOUND_SAVER_FLASH_LOAN.transfer(msg.value);

            uint loanAmount = (_data[0] - maxBorrow);
            bytes memory paramsData = abi.encode(_data, _addrData, _callData, false, address(this));

            givePermission(COMPOUND_SAVER_FLASH_LOAN);

            lendingPool.flashLoan(COMPOUND_SAVER_FLASH_LOAN, getUnderlyingAddr(_addrData[1]), loanAmount, paramsData);

            removePermission(COMPOUND_SAVER_FLASH_LOAN);

            logger.logFlashLoan("CompoundFlashBoost", loanAmount, _data[0], _addrData[1]);
        }

    }

}