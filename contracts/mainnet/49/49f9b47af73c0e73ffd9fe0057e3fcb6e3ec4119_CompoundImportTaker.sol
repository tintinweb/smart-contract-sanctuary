/**
 *Submitted for verification at Etherscan.io on 2020-06-09
*/

// File: localhost/interfaces/ERC20.sol

pragma solidity ^0.6.0;

interface ERC20 {
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
}



contract DSAuthEvents {
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
}
pragma solidity ^0.6.0;


contract DSNote {
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
}

// File: localhost/DS/DSProxy.sol

pragma solidity ^0.6.0;




abstract contract DSProxy is DSAuth, DSNote {
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
}

// File: localhost/DS/DSMath.sol

pragma solidity ^0.6.0;


contract DSMath {
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
}

// File: localhost/mcd/Discount.sol

pragma solidity ^0.6.0;


contract Discount {
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
}

// File: localhost/interfaces/ComptrollerInterface.sol

pragma solidity ^0.6.0;


abstract contract ComptrollerInterface {
    function enterMarkets(address[] calldata cTokens) external virtual returns (uint256[] memory);

    function exitMarket(address cToken) external virtual returns (uint256);

    function getAssetsIn(address account) external virtual view returns (address[] memory);

    function markets(address account) public virtual view returns (bool, uint256);

    function getAccountLiquidity(address account) external virtual view returns (uint256, uint256, uint256);
}

// File: localhost/interfaces/CompoundOracleInterface.sol

pragma solidity ^0.6.0;

abstract contract CompoundOracleInterface {
    function getUnderlyingPrice(address cToken) external view virtual returns (uint);
}

// File: localhost/interfaces/CEtherInterface.sol

pragma solidity ^0.6.0;

abstract contract CEtherInterface {
    function mint() external virtual payable;
    function repayBorrow() external virtual payable;
}

// File: localhost/compound/helpers/CompoundSaverHelper.sol

pragma solidity ^0.6.0;








/// @title Utlity functions for Compound contracts
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
}

// File: localhost/interfaces/DSProxyInterface.sol

pragma solidity ^0.6.0;


abstract contract DSProxyInterface {

    /// Truffle wont compile if this isn't commented
    // function execute(bytes memory _code, bytes memory _data)
    //     public virtual
    //     payable
    //     returns (address, bytes32);

    function execute(address _target, bytes memory _data) public virtual payable returns (bytes32);

    function setCache(address _cacheAddr) public virtual payable returns (bool);

    function owner() public virtual returns (address);
}

// File: localhost/interfaces/ProxyRegistryInterface.sol

pragma solidity ^0.6.0;


abstract contract ProxyRegistryInterface {
    function proxies(address _owner) public virtual view returns (address);
    function build(address) public virtual returns (address);
}

// File: localhost/interfaces/CTokenInterface.sol

pragma solidity ^0.6.0;


abstract contract CTokenInterface is ERC20 {
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
}

// File: localhost/interfaces/ILendingPool.sol

pragma solidity ^0.6.0;

abstract contract ILendingPool {
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
}

// File: localhost/loggers/FlashLoanLogger.sol

pragma solidity ^0.6.0;


contract FlashLoanLogger {
    event FlashLoan(string actionType, uint256 id, uint256 loanAmount, address sender);

    function logFlashLoan(
        string calldata _actionType,
        uint256 _id,
        uint256 _loanAmount,
        address _sender
    ) external {
        emit FlashLoan(_actionType, _loanAmount, _id, _sender);
    }
}

// File: localhost/DS/DSAuthority.sol

pragma solidity ^0.6.0;


abstract contract DSAuthority {
    function canCall(address src, address dst, bytes4 sig) public virtual view returns (bool);
}



// File: localhost/DS/DSGuard.sol

pragma solidity ^0.6.0;


abstract contract DSGuard {
    function canCall(address src_, address dst_, bytes4 sig) public view virtual returns (bool);

    function permit(bytes32 src, bytes32 dst, bytes32 sig) public virtual;

    function forbid(bytes32 src, bytes32 dst, bytes32 sig) public virtual;

    function permit(address src, address dst, bytes32 sig) public virtual;

    function forbid(address src, address dst, bytes32 sig) public virtual;
}


abstract contract DSGuardFactory {
    function newGuard() public virtual returns (DSGuard guard);
}

// File: localhost/auth/ProxyPermission.sol

pragma solidity ^0.6.0;



contract ProxyPermission {
    address public constant FACTORY_ADDRESS = 0x5a15566417e6C1c9546523066500bDDBc53F88C7;

    /// @notice Called in the context of DSProxy to authorize an address
    /// @param _contractAddr Address which will be authorized
    function givePermission(address _contractAddr) public {
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
    function removePermission(address _contractAddr) public {
        address currAuthority = address(DSAuth(address(this)).authority());
        
        // if there is no authority, that means that contract doesn't have permission
        if (currAuthority == address(0)) {
            return;
        }

        DSGuard guard = DSGuard(currAuthority);
        guard.forbid(_contractAddr, address(this), bytes4(keccak256("execute(address,bytes)")));
    }
}


// File: localhost/interfaces/GasTokenInterface.sol

pragma solidity ^0.6.0;


abstract contract GasTokenInterface is ERC20 {
    function free(uint256 value) public virtual returns (bool success);

    function freeUpTo(uint256 value) public virtual returns (uint256 freed);

    function freeFrom(address from, uint256 value) public virtual returns (bool success);

    function freeFromUpTo(address from, uint256 value) public virtual returns (uint256 freed);
}

// File: localhost/utils/GasBurner.sol

pragma solidity ^0.6.0;


contract GasBurner {
    // solhint-disable-next-line const-name-snakecase
    GasTokenInterface public constant gasToken = GasTokenInterface(0x0000000000b3F879cb30FE243b4Dfee438691c04);

    modifier burnGas(uint _amount) {
        uint gst2Amount = _amount;

        if (_amount == 0) {
            gst2Amount = (gasleft() + 14154) / (2 * 24000 - 6870);
            gst2Amount = gst2Amount - (gst2Amount / 3); // 33.3% less because of gaslimit != gas_used
        }

        if (gasToken.balanceOf(address(this)) >= gst2Amount) {
            gasToken.free(gst2Amount);
        }

        _;
    }
}

// File: localhost/compound/import/CompoundImportTaker.sol

pragma solidity ^0.6.0;








/// @title Imports Compound position from the account to DSProxy
contract CompoundImportTaker is CompoundSaverHelper, ProxyPermission, GasBurner {

    ILendingPool public constant lendingPool = ILendingPool(0x398eC7346DcD622eDc5ae82352F02bE94C62d119);

    address payable public constant COMPOUND_IMPORT_FLASH_LOAN = 0xfD7F89640fe62a4353cfC7521509FC5c4276F2a5;
    address public constant PROXY_REGISTRY_ADDRESS = 0x4678f0a6958e4D2Bc4F1BAF7Bc52E8F3564f3fE4;

    // solhint-disable-next-line const-name-snakecase
    FlashLoanLogger public constant logger = FlashLoanLogger(
        0xb9303686B0EE92F92f63973EF85f3105329D345c
    );

    /// @notice Starts the process to move users position 1 collateral and 1 borrow
    /// @dev User must approve COMPOUND_IMPORT_FLASH_LOAN to pull _cCollateralToken
    /// @param _cCollateralToken Collateral we are moving to DSProxy
    /// @param _cBorrowToken Borrow token we are moving to DSProxy
    function importLoan(address _cCollateralToken, address _cBorrowToken) external burnGas(20) {
        address proxy = getProxy();

        uint loanAmount = CTokenInterface(_cBorrowToken).borrowBalanceCurrent(msg.sender);
        bytes memory paramsData = abi.encode(_cCollateralToken, _cBorrowToken, msg.sender, proxy);

        givePermission(COMPOUND_IMPORT_FLASH_LOAN);

        lendingPool.flashLoan(COMPOUND_IMPORT_FLASH_LOAN, getUnderlyingAddr(_cBorrowToken), loanAmount, paramsData);

        removePermission(COMPOUND_IMPORT_FLASH_LOAN);

        logger.logFlashLoan("CompoundImport", loanAmount, 0, _cCollateralToken);
    }

    /// @notice Gets proxy address, if user doesn't has DSProxy build it
    /// @return proxy DsProxy address
    function getProxy() internal returns (address proxy) {
        proxy = ProxyRegistryInterface(PROXY_REGISTRY_ADDRESS).proxies(msg.sender);

        if (proxy == address(0)) {
            proxy = ProxyRegistryInterface(PROXY_REGISTRY_ADDRESS).build(msg.sender);
        }

    }
}