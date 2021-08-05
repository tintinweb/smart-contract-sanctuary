/**
 *Submitted for verification at Etherscan.io on 2020-07-10
*/

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;


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

// File: localhost/exchange/SaverExchangeHelper.sol

pragma solidity ^0.6.0;



contract SaverExchangeHelper {

    using SafeERC20 for ERC20;

    address public constant KYBER_ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant DGD_ADDRESS = 0xE0B7927c4aF23765Cb51314A0E0521A9645F0E2A;

    address payable public constant WALLET_ID = 0x322d58b9E75a6918f7e7849AEe0fF09369977e08;
    address public constant DISCOUNT_ADDRESS = 0x1b14E8D511c9A4395425314f849bD737BAF8208F;

    address public constant KYBER_WRAPPER = 0x3d1D4D6Bb405b2366434cb7387803c7B662b8d71;
    address public constant UNISWAP_WRAPPER = 0xFF92ADA50cDC8009686867b4a470C8769bEdB22d;
    address public constant OASIS_WRAPPER = 0x9C499376B41A91349Ff93F99462a65962653e104;
    address public constant ERC20_PROXY_0X = 0x95E6F48254609A6ee006F7D493c8e5fB97094ceF;
    address public constant ZRX_ALLOWLIST_ADDR = 0x019739e288973F92bDD3c1d87178E206E51fd911;


    function getDecimals(address _token) internal view returns (uint256) {
        if (_token == DGD_ADDRESS) return 9;
        if (_token == KYBER_ETH_ADDRESS) return 18;

        return ERC20(_token).decimals();
    }

    function getBalance(address _tokenAddr) internal view returns (uint balance) {
        if (_tokenAddr == KYBER_ETH_ADDRESS) {
            balance = address(this).balance;
        } else {
            balance = ERC20(_tokenAddr).balanceOf(address(this));
        }
    }

    function approve0xProxy(address _tokenAddr, uint _amount) internal {
        if (_tokenAddr != KYBER_ETH_ADDRESS) {
            ERC20(_tokenAddr).safeApprove(address(ERC20_PROXY_0X), _amount);
        }
    }

    function sendLeftover(address _srcAddr, address _destAddr, address payable _to) internal {
        // send back any leftover ether or tokens
        if (address(this).balance > 0) {
            _to.transfer(address(this).balance);
        }

        if (getBalance(_srcAddr) > 0) {
            ERC20(_srcAddr).safeTransfer(_to, getBalance(_srcAddr));
        }

        if (getBalance(_destAddr) > 0) {
            ERC20(_destAddr).safeTransfer(_to, getBalance(_destAddr));
        }
    }

    function sliceUint(bytes memory bs, uint256 start) internal pure returns (uint256) {
        require(bs.length >= start + 32, "slicing out of range");

        uint256 x;
        assembly {
            x := mload(add(bs, add(0x20, start)))
        }

        return x;
    }
}

// File: localhost/utils/ZrxAllowlist.sol

pragma solidity ^0.6.0;

contract AdminAuth {

    using SafeERC20 for ERC20;

    address public owner;
    address public admin;

    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    /// @notice Admin is set by owner first time, after that admin is super role and has permission to change owner
    /// @param _admin Address of multisig that becomes admin
    function setAdminByOwner(address _admin) public {
        require(msg.sender == owner);
        require(admin == address(0));

        admin = _admin;
    }

    /// @notice Admin is able to set new admin
    /// @param _admin Address of multisig that becomes new admin
    function setAdminByAdmin(address _admin) public {
        require(msg.sender == admin);

        admin = _admin;
    }

    /// @notice Admin is able to change owner
    /// @param _owner Address of new owner
    function setOwnerByAdmin(address _owner) public {
        require(msg.sender == admin);

        owner = _owner;
    }

    /// @notice Destroy the contract
    function kill() public onlyOwner {
        selfdestruct(payable(owner));
    }

    /// @notice  withdraw stuck funds
    function withdrawStuckFunds(address _token, uint _amount) public onlyOwner {
        if (_token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            payable(owner).transfer(_amount);
        } else {
            ERC20(_token).safeTransfer(owner, _amount);
        }
    }
}



contract ZrxAllowlist is AdminAuth {

    mapping (address => bool) public zrxAllowlist;

    function setAllowlistAddr(address _zrxAddr, bool _state) public onlyOwner {
        zrxAllowlist[_zrxAddr] = _state;
    }

    function isZrxAddr(address _zrxAddr) public view returns (bool) {
        return zrxAllowlist[_zrxAddr];
    }
}

// File: localhost/interfaces/ExchangeInterfaceV2.sol

pragma solidity ^0.6.0;

interface ExchangeInterfaceV2 {
    function sell(address _srcAddr, address _destAddr, uint _srcAmount) external payable returns (uint);

    function buy(address _srcAddr, address _destAddr, uint _destAmount) external payable returns(uint);

    function getSellRate(address _srcAddr, address _destAddr, uint _srcAmount) external view returns (uint);

    function getBuyRate(address _srcAddr, address _destAddr, uint _srcAmount) external view returns (uint);
}

// File: localhost/interfaces/TokenInterface.sol

pragma solidity ^0.6.0;

abstract contract TokenInterface {
    function allowance(address, address) public virtual returns (uint256);

    function balanceOf(address) public virtual returns (uint256);

    function approve(address, uint256) public virtual;

    function transfer(address, uint256) public virtual returns (bool);

    function transferFrom(address, address, uint256) public virtual returns (bool);

    function deposit() public virtual payable;

    function withdraw(uint256) public virtual;
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

// File: localhost/exchange/SaverExchangeCore.sol

pragma solidity ^0.6.0;






contract SaverExchangeCore is SaverExchangeHelper, DSMath {

    // first is empty to keep the legacy order in place
    enum ExchangeType { _, OASIS, KYBER, UNISWAP, ZEROX }

    enum ActionType { SELL, BUY }

    struct ExchangeData {
        address srcAddr;
        address destAddr;
        uint srcAmount;
        uint destAmount;
        uint minPrice;
        ExchangeType exchangeType;
        address exchangeAddr;
        bytes callData;
        uint256 price0x;
    }

    /// @notice Internal method that preforms a sell on 0x/on-chain
    /// @dev Usefull for other DFS contract to integrate for exchanging
    /// @param exData Exchange data struct
    /// @return (address, uint) Address of the wrapper used and destAmount
    function _sell(ExchangeData memory exData) internal returns (address, uint) {

        address wrapper;
        uint swapedTokens;
        bool success;
        uint tokensLeft = exData.srcAmount;

        // if 0x is selected try first the 0x order
        if (exData.exchangeType == ExchangeType.ZEROX) {
            approve0xProxy(exData.srcAddr, exData.srcAmount);

            (success, swapedTokens, tokensLeft) = takeOrder(exData, address(this).balance, ActionType.SELL);

            require(success, "0x order failed");

            wrapper = exData.exchangeAddr;
        }

        // check if we have already swapped with 0x, or tried swapping but failed
        if (tokensLeft > 0) {
            uint price;

            (wrapper, price)
                = getBestPrice(exData.srcAmount, exData.srcAddr, exData.destAddr, exData.exchangeType, ActionType.SELL);

            require(price > exData.minPrice || exData.price0x > exData.minPrice, "Slippage hit");

            // if 0x has better prices use 0x
            if (exData.price0x >= price && exData.exchangeType != ExchangeType.ZEROX) {
                approve0xProxy(exData.srcAddr, exData.srcAmount);

                (success, swapedTokens, tokensLeft) = takeOrder(exData, address(this).balance, ActionType.SELL);
            }

            // 0x either had worse price or we tried and order fill failed, so call on chain swap
            if (tokensLeft > 0) {
                require(price > exData.minPrice, "On chain slippage hit");

                swapedTokens = saverSwap(exData, wrapper, ActionType.SELL);
            }
        }

        require(getBalance(exData.destAddr) >= wmul(exData.minPrice, exData.srcAmount), "Double check min price");

        return (wrapper, swapedTokens);
    }

    /// @notice Internal method that preforms a buy on 0x/on-chain
    /// @dev Usefull for other DFS contract to integrate for exchanging
    /// @param exData Exchange data struct
    /// @return (address, uint) Address of the wrapper used and srcAmount
    function _buy(ExchangeData memory exData) internal returns (address, uint) {

        address wrapper;
        uint swapedTokens;
        bool success;

        require(exData.destAmount != 0, "Dest amount must be specified");

        // if 0x is selected try first the 0x order
        if (exData.exchangeType == ExchangeType.ZEROX) {
            approve0xProxy(exData.srcAddr, exData.srcAmount);

            (success, swapedTokens,) = takeOrder(exData, address(this).balance, ActionType.BUY);

            require(success, "0x order failed");

            wrapper = exData.exchangeAddr;
        }

        // check if we have already swapped with 0x, or tried swapping but failed
        if (getBalance(exData.destAddr) < exData.destAmount) {
            uint price;

            (wrapper, price)
                = getBestPrice(exData.destAmount, exData.srcAddr, exData.destAddr, exData.exchangeType, ActionType.BUY);

            require(price < exData.minPrice || exData.price0x < exData.minPrice, "Slippage hit");

            // if 0x has better prices use 0x
            if (exData.price0x != 0 && exData.price0x <= price && exData.exchangeType != ExchangeType.ZEROX) {
                approve0xProxy(exData.srcAddr, exData.srcAmount);

                (success, swapedTokens,) = takeOrder(exData, address(this).balance, ActionType.BUY);
            }

            // 0x either had worse price or we tried and order fill failed, so call on chain swap
            if (getBalance(exData.destAddr) < exData.destAmount) {
                require(price < exData.minPrice, "On chain slippage hit");

                swapedTokens = saverSwap(exData, wrapper, ActionType.BUY);
            }
        }

        require(getBalance(exData.destAddr) >= exData.destAmount, "Less then destAmount");

        return (wrapper, getBalance(exData.destAddr));
    }

    /// @notice Takes order from 0x and returns bool indicating if it is successful
    /// @param _exData Exchange data
    /// @param _ethAmount Ether fee needed for 0x order
    function takeOrder(
        ExchangeData memory _exData,
        uint256 _ethAmount,
        ActionType _type
    ) private returns (bool success, uint256, uint256) {

        // write in the exact amount we are selling/buing in an order
        if (_type == ActionType.SELL) {
            writeUint256(_exData.callData, 36, _exData.srcAmount);
        } else {
            writeUint256(_exData.callData, 36, _exData.destAmount);
        }

        if (ZrxAllowlist(ZRX_ALLOWLIST_ADDR).isZrxAddr(_exData.exchangeAddr)) {
            (success, ) = _exData.exchangeAddr.call{value: _ethAmount}(_exData.callData);
        } else {
            success = false;
        }

        uint256 tokensSwaped = 0;
        uint256 tokensLeft = _exData.srcAmount;

        if (success) {
            // check to see if any _src tokens are left over after exchange
            tokensLeft = getBalance(_exData.srcAddr);

            // convert weth -> eth if needed
            if (_exData.destAddr == KYBER_ETH_ADDRESS) {
                TokenInterface(WETH_ADDRESS).withdraw(
                    TokenInterface(WETH_ADDRESS).balanceOf(address(this))
                );
            }

            // get the current balance of the swaped tokens
            tokensSwaped = getBalance(_exData.destAddr);
        }

        return (success, tokensSwaped, tokensLeft);
    }

    /// @notice Returns the best estimated price from 2 exchanges
    /// @param _amount Amount of source tokens you want to exchange
    /// @param _srcToken Address of the source token
    /// @param _destToken Address of the destination token
    /// @param _exchangeType Which exchange will be used
    /// @param _type Type of action SELL|BUY
    /// @return (address, uint) The address of the best exchange and the exchange price
    function getBestPrice(
        uint256 _amount,
        address _srcToken,
        address _destToken,
        ExchangeType _exchangeType,
        ActionType _type
    ) public returns (address, uint256) {

        if (_exchangeType == ExchangeType.OASIS) {
            return (OASIS_WRAPPER, getExpectedRate(OASIS_WRAPPER, _srcToken, _destToken, _amount, _type));
        }

        if (_exchangeType == ExchangeType.KYBER) {
            return (KYBER_WRAPPER, getExpectedRate(KYBER_WRAPPER, _srcToken, _destToken, _amount, _type));
        }

        if (_exchangeType == ExchangeType.UNISWAP) {
            return (UNISWAP_WRAPPER, getExpectedRate(UNISWAP_WRAPPER, _srcToken, _destToken, _amount, _type));
        }

        uint expectedRateKyber = getExpectedRate(KYBER_WRAPPER, _srcToken, _destToken, _amount, _type);
        uint expectedRateUniswap = getExpectedRate(UNISWAP_WRAPPER, _srcToken, _destToken, _amount, _type);
        uint expectedRateOasis = getExpectedRate(OASIS_WRAPPER, _srcToken, _destToken, _amount, _type);

        if (_type == ActionType.SELL) {
            return getBiggestRate(expectedRateKyber, expectedRateUniswap, expectedRateOasis);
        } else {
            return getSmallestRate(expectedRateKyber, expectedRateUniswap, expectedRateOasis);
        }
    }

    /// @notice Return the expected rate from the exchange wrapper
    /// @dev In case of Oasis/Uniswap handles the different precision tokens
    /// @param _wrapper Address of exchange wrapper
    /// @param _srcToken From token
    /// @param _destToken To token
    /// @param _amount Amount to be exchanged
    /// @param _type Type of action SELL|BUY
    function getExpectedRate(
        address _wrapper,
        address _srcToken,
        address _destToken,
        uint256 _amount,
        ActionType _type
    ) public returns (uint256) {
        bool success;
        bytes memory result;

        if (_type == ActionType.SELL) {
            (success, result) = _wrapper.call(abi.encodeWithSignature(
                "getSellRate(address,address,uint256)",
                _srcToken,
                _destToken,
                _amount
            ));

        } else {
            (success, result) = _wrapper.call(abi.encodeWithSignature(
                "getBuyRate(address,address,uint256)",
                _srcToken,
                _destToken,
                _amount
            ));
        }

        if (success) {
            uint rate = sliceUint(result, 0);

            if (_wrapper != KYBER_WRAPPER) {
                rate = rate * (10**(18 - getDecimals(_destToken)));
            }

            return rate;
        }

        return 0;
    }

    /// @notice Calls wraper contract for exchage to preform an on-chain swap
    /// @param exData Exchange data struct
    /// @param _wrapper Address of exchange wrapper
    /// @param _type Type of action SELL|BUY
    /// @return swapedTokens For Sell that the destAmount, for Buy thats the srcAmount
    function saverSwap(ExchangeData memory exData, address _wrapper, ActionType _type) internal returns (uint swapedTokens) {
        uint ethValue = 0;

        if (exData.srcAddr == KYBER_ETH_ADDRESS) {
            ethValue = exData.srcAmount;
        } else {
            ERC20(exData.srcAddr).safeTransfer(_wrapper, ERC20(exData.srcAddr).balanceOf(address(this)));
        }

        if (_type == ActionType.SELL) {
            swapedTokens = ExchangeInterfaceV2(_wrapper).
                    sell{value: ethValue}(exData.srcAddr, exData.destAddr, exData.srcAmount);
        } else {
            swapedTokens = ExchangeInterfaceV2(_wrapper).
                    buy{value: ethValue}(exData.srcAddr, exData.destAddr, exData.destAmount);
        }
    }

    /// @notice Finds the biggest rate between exchanges, needed for sell rate
    /// @param _expectedRateKyber Kyber rate
    /// @param _expectedRateUniswap Uniswap rate
    /// @param _expectedRateOasis Oasis rate
    function getBiggestRate(
        uint _expectedRateKyber,
        uint _expectedRateUniswap,
        uint _expectedRateOasis
    ) internal pure returns (address, uint) {
        if (
            (_expectedRateUniswap >= _expectedRateKyber) && (_expectedRateUniswap >= _expectedRateOasis)
        ) {
            return (UNISWAP_WRAPPER, _expectedRateUniswap);
        }

        if (
            (_expectedRateKyber >= _expectedRateUniswap) && (_expectedRateKyber >= _expectedRateOasis)
        ) {
            return (KYBER_WRAPPER, _expectedRateKyber);
        }

        if (
            (_expectedRateOasis >= _expectedRateKyber) && (_expectedRateOasis >= _expectedRateUniswap)
        ) {
            return (OASIS_WRAPPER, _expectedRateOasis);
        }
    }

    /// @notice Finds the smallest rate between exchanges, needed for buy rate
    /// @param _expectedRateKyber Kyber rate
    /// @param _expectedRateUniswap Uniswap rate
    /// @param _expectedRateOasis Oasis rate
    function getSmallestRate(
        uint _expectedRateKyber,
        uint _expectedRateUniswap,
        uint _expectedRateOasis
    ) internal pure returns (address, uint) {
        if (
            (_expectedRateUniswap <= _expectedRateKyber) && (_expectedRateUniswap <= _expectedRateOasis)
        ) {
            return (UNISWAP_WRAPPER, _expectedRateUniswap);
        }

        if (
            (_expectedRateKyber <= _expectedRateUniswap) && (_expectedRateKyber <= _expectedRateOasis)
        ) {
            return (KYBER_WRAPPER, _expectedRateKyber);
        }

        if (
            (_expectedRateOasis <= _expectedRateKyber) && (_expectedRateOasis <= _expectedRateUniswap)
        ) {
            return (OASIS_WRAPPER, _expectedRateOasis);
        }
    }

    function writeUint256(bytes memory _b, uint256 _index, uint _input) internal pure {
        if (_b.length < _index + 32) {
            revert("Incorrent lengt while writting bytes32");
        }

        bytes32 input = bytes32(_input);

        _index += 32;

        // Read the bytes32 from array memory
        assembly {
            mstore(add(_b, _index), input)
        }
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external virtual payable {}
}

// File: localhost/utils/ExchangeDataParser.sol


contract ExchangeDataParser {
     function decodeExchangeData(
        SaverExchangeCore.ExchangeData memory exchangeData
    ) internal pure returns (address[3] memory, uint[5] memory, bytes memory) {
        return (
         [exchangeData.srcAddr, exchangeData.destAddr, exchangeData.exchangeAddr],
         [exchangeData.srcAmount, exchangeData.destAmount, exchangeData.minPrice, exchangeData.price0x, uint256(exchangeData.exchangeType)],
         exchangeData.callData
        );
    }

    function encodeExchangeData(
        address[3] memory exAddr, uint[5] memory exNum, bytes memory callData
    ) internal pure returns (SaverExchangeCore.ExchangeData memory) {
        return SaverExchangeCore.ExchangeData({
            srcAddr: exAddr[0],
            destAddr: exAddr[1],
            srcAmount: exNum[0],
            destAmount: exNum[1],
            minPrice: exNum[2],
            exchangeType: SaverExchangeCore.ExchangeType(exNum[4]),
            exchangeAddr: exAddr[2],
            callData: callData,
            price0x: exNum[3]
        });
    }
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

// File: localhost/DS/DSAuth.sol

pragma solidity ^0.6.0;



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

// File: localhost/utils/Address.sol

pragma solidity ^0.6.0;

library Address {
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

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: localhost/utils/SafeERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;



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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(ERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     */
    function safeApprove(ERC20 token, address spender, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(ERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(ERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(ERC20 token, bytes memory data) private {

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: localhost/auth/AdminAuth.sol

pragma solidity ^0.6.0;



// File: localhost/mcd/maker/Manager.sol

pragma solidity ^0.6.0;

abstract contract Manager {
    function last(address) virtual public returns (uint);
    function cdpCan(address, uint, address) virtual public view returns (uint);
    function ilks(uint) virtual public view returns (bytes32);
    function owns(uint) virtual public view returns (address);
    function urns(uint) virtual public view returns (address);
    function vat() virtual public view returns (address);
    function open(bytes32, address) virtual public returns (uint);
    function give(uint, address) virtual public;
    function cdpAllow(uint, address, uint) virtual public;
    function urnAllow(address, uint) virtual public;
    function frob(uint, int, int) virtual public;
    function flux(uint, address, uint) virtual public;
    function move(uint, address, uint) virtual public;
    function exit(address, uint, address, uint) virtual public;
    function quit(uint, address) virtual public;
    function enter(address, uint) virtual public;
    function shift(uint, uint) virtual public;
}

// File: localhost/mcd/maker/Vat.sol

pragma solidity ^0.6.0;

abstract contract Vat {

    struct Urn {
        uint256 ink;   // Locked Collateral  [wad]
        uint256 art;   // Normalised Debt    [wad]
    }

    struct Ilk {
        uint256 Art;   // Total Normalised Debt     [wad]
        uint256 rate;  // Accumulated Rates         [ray]
        uint256 spot;  // Price with Safety Margin  [ray]
        uint256 line;  // Debt Ceiling              [rad]
        uint256 dust;  // Urn Debt Floor            [rad]
    }

    mapping (bytes32 => mapping (address => Urn )) public urns;
    mapping (bytes32 => Ilk)                       public ilks;
    mapping (bytes32 => mapping (address => uint)) public gem;  // [wad]

    function can(address, address) virtual public view returns (uint);
    function dai(address) virtual public view returns (uint);
    function frob(bytes32, address, address, address, int, int) virtual public;
    function hope(address) virtual public;
    function move(address, address, uint) virtual public;
    function fork(bytes32, address, address, int, int) virtual public;
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

// File: localhost/interfaces/ILoanShifter.sol

pragma solidity ^0.6.0;

abstract contract ILoanShifter {
    function getLoanAmount(uint, address) public view virtual returns(uint);
    function getUnderlyingAsset(address _addr) public view virtual returns (address);
}

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

// File: localhost/interfaces/CTokenInterface.sol

pragma solidity ^0.6.0;


abstract contract CTokenInterface is ERC20 {
    function mint(uint256 mintAmount) external virtual returns (uint256);

    function mint() external virtual payable;

    function accrueInterest() public virtual returns (uint);

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

    function borrowBalanceCurrent(address account) external view virtual returns (uint256);

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
	function repay( address _reserve, uint256 _amount, address payable _onBehalfOf) external virtual payable;
	
    /// @param _reserve underlying token address
    function getReserveData(address _reserve)
        external virtual
        view
        returns (
            uint256 totalLiquidity,               // reserve total liquidity
            uint256 availableLiquidity,           // reserve available liquidity for borrowing
            uint256 totalBorrowsStable,           // total amount of outstanding borrows at Stable rate
            uint256 totalBorrowsVariable,         // total amount of outstanding borrows at Variable rate
            uint256 liquidityRate,                // current deposit APY of the reservefor depositors, in Ray units.
            uint256 variableBorrowRate,           // current variable rate APY of the reserve pool, in Ray units.
            uint256 stableBorrowRate,             // current stable rate APY of the reserve pool, in Ray units.
            uint256 averageStableBorrowRate,      // current average stable borrow rate
            uint256 utilizationRate,              // expressed as total borrows/total liquidity.
            uint256 liquidityIndex,               // cumulative liquidity index
            uint256 variableBorrowIndex,          // cumulative variable borrow index
            address aTokenAddress,                // aTokens contract address for the specific _reserve
            uint40 lastUpdateTimestamp            // timestamp of the last update of reserve data
        );

    /// @param _user users address
    function getUserAccountData(address _user)
        external virtual
        view
        returns (
            uint256 totalLiquidityETH,            // user aggregated deposits across all the reserves. In Wei
            uint256 totalCollateralETH,           // user aggregated collateral across all the reserves. In Wei
            uint256 totalBorrowsETH,              // user aggregated outstanding borrows across all the reserves. In Wei
            uint256 totalFeesETH,                 // user aggregated current outstanding fees in ETH. In Wei
            uint256 availableBorrowsETH,          // user available amount to borrow in ETH
            uint256 currentLiquidationThreshold,  // user current average liquidation threshold across all the collaterals deposited
            uint256 ltv,                          // user average Loan-to-Value between all the collaterals
            uint256 healthFactor                  // user current Health Factor
    );    

    /// @param _reserve underlying token address
    /// @param _user users address
    function getUserReserveData(address _reserve, address _user)
        external virtual
        view
        returns (
            uint256 currentATokenBalance,         // user current reserve aToken balance
            uint256 currentBorrowBalance,         // user current reserve outstanding borrow balance
            uint256 principalBorrowBalance,       // user balance of borrowed asset
            uint256 borrowRateMode,               // user borrow rate mode either Stable or Variable
            uint256 borrowRate,                   // user current borrow rate APY
            uint256 liquidityRate,                // user current earn rate on _reserve
            uint256 originationFee,               // user outstanding loan origination fee
            uint256 variableBorrowIndex,          // user variable cumulative index
            uint256 lastUpdateTimestamp,          // Timestamp of the last data update
            bool usageAsCollateralEnabled         // Whether the user's current reserve is enabled as a collateral
    );

    function getReserveConfigurationData(address _reserve)
        external virtual
        view
        returns (
            uint256 ltv,
            uint256 liquidationThreshold,
            uint256 liquidationBonus,
            address rateStrategyAddress,
            bool usageAsCollateralEnabled,
            bool borrowingEnabled,
            bool stableBorrowRateEnabled,
            bool isActive
    );

    // ------------------ LendingPoolCoreData ------------------------
    function getReserveATokenAddress(address _reserve) public virtual view returns (address);
    function getReserveConfiguration(address _reserve)
        external virtual
        view
        returns (uint256, uint256, uint256, bool);
    function getUserUnderlyingAssetBalance(address _reserve, address _user)
        public virtual
        view
        returns (uint256);

    // ---------------- LendingPoolDataProvider ---------------------
    function calculateUserGlobalData(address _user)
        public virtual
        view
        returns (
            uint256 totalLiquidityBalanceETH,
            uint256 totalCollateralBalanceETH,
            uint256 totalBorrowBalanceETH,
            uint256 totalFeesETH,
            uint256 currentLtv,
            uint256 currentLiquidationThreshold,
            uint256 healthFactor,
            bool healthFactorBelowThreshold
        );
}

// File: localhost/shifter/LoanShifterTaker.sol














/// @title LoanShifterTaker Entry point for using the shifting operation
contract LoanShifterTaker is AdminAuth, ProxyPermission {

    ILendingPool public constant lendingPool = ILendingPool(0x398eC7346DcD622eDc5ae82352F02bE94C62d119);

    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant CETH_ADDRESS = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;
    address public constant DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant cDAI_ADDRESS = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;

    address payable public constant LOAN_SHIFTER_RECEIVER = 0x56b789f78c3Aff880F873740490822a5da2D9851;

    address public constant MANAGER_ADDRESS = 0x5ef30b9986345249bc32d8928B7ee64DE9435E39;
    address public constant VAT_ADDRESS = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;

    Manager public constant manager = Manager(MANAGER_ADDRESS);

    enum Protocols { MCD, COMPOUND, AAVE }

    struct LoanShiftData {
        Protocols fromProtocol;
        Protocols toProtocol;
        bool wholeDebt;
        uint collAmount;
        uint debtAmount;
        address debtAddr;
        address addrLoan1;
        address addrLoan2;
        uint id1;
        uint id2;
    }

    mapping (Protocols => address) public contractAddresses;

    /// @notice Main entry point, it will move or transform a loan
    /// @dev If the operation doesn't require exchange send empty data
    function moveLoan(
        LoanShiftData memory _loanShift,
        SaverExchangeCore.ExchangeData memory _exchangeData
    ) public {
        if (_isSameTypeVaults(_loanShift)) {
            _forkVault(_loanShift);
            return;
        }

        _callCloseAndOpen(_loanShift, _exchangeData);
    }

    /// @notice An admin only function to add/change a protocols address
    function addProtocol(uint8 _protoType, address _protoAddr) public onlyOwner {
        contractAddresses[Protocols(_protoType)] = _protoAddr;
    }

    function getProtocolAddr(Protocols _proto) public view returns (address) {
        return contractAddresses[_proto];
    }

    //////////////////////// INTERNAL FUNCTIONS //////////////////////////

    function _callCloseAndOpen(
        LoanShiftData memory _loanShift,
        SaverExchangeCore.ExchangeData memory _exchangeData
    ) internal {
        address protoAddr = getProtocolAddr(_loanShift.fromProtocol);

        uint loanAmount = _loanShift.debtAmount;

        if (_loanShift.wholeDebt) {
            loanAmount = ILoanShifter(protoAddr).getLoanAmount(_loanShift.id1, _loanShift.addrLoan1);
        }

        (
            uint[8] memory numData,
            address[6] memory addrData,
            uint8[3] memory enumData,
            bytes memory callData
        )
        = _packData(_loanShift, _exchangeData);

        // encode data
        bytes memory paramsData = abi.encode(numData, addrData, enumData, callData, address(this));

        // call FL
        givePermission(LOAN_SHIFTER_RECEIVER);

        lendingPool.flashLoan(LOAN_SHIFTER_RECEIVER, _loanShift.debtAddr, loanAmount, paramsData);

        removePermission(LOAN_SHIFTER_RECEIVER);
    }

    function _forkVault(LoanShiftData memory _loanShift) internal {
        // Create new Vault to move to
        if (_loanShift.id2 == 0) {
            _loanShift.id2 = manager.open(manager.ilks(_loanShift.id1), address(this));
        }

        if (_loanShift.wholeDebt) {
            manager.shift(_loanShift.id1, _loanShift.id2);
        } else {
            // Vat(VAT_ADDRESS).fork(
            //     manager.ilks(_loanShift.id1),
            //     manager.urns(_loanShift.id1),
            //     manager.urns(_loanShift.id2),
            //     int(_loanShift.collAmount),
            //     int(_loanShift.debtAmount)
            // );
        }
    }

    function _isSameTypeVaults(LoanShiftData memory _loanShift) internal pure returns (bool) {
        return _loanShift.fromProtocol == Protocols.MCD && _loanShift.toProtocol == Protocols.MCD
                && _loanShift.addrLoan1 == _loanShift.addrLoan2;
    }

    function _packData(
        LoanShiftData memory _loanShift,
        SaverExchangeCore.ExchangeData memory exchangeData
    ) internal pure returns (uint[8] memory numData, address[6] memory addrData, uint8[3] memory enumData, bytes memory callData) {

        numData = [
            _loanShift.collAmount,
            _loanShift.debtAmount,
            _loanShift.id1,
            _loanShift.id2,
            exchangeData.srcAmount,
            exchangeData.destAmount,
            exchangeData.minPrice,
            exchangeData.price0x
        ];

        addrData = [
            _loanShift.addrLoan1,
            _loanShift.addrLoan2,
            _loanShift.debtAddr,
            exchangeData.srcAddr,
            exchangeData.destAddr,
            exchangeData.exchangeAddr
        ];

        enumData = [
            uint8(_loanShift.fromProtocol),
            uint8(_loanShift.toProtocol),
            uint8(exchangeData.exchangeType)
        ];

        callData = exchangeData.callData;
    }

}