pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

// import files from common directory
interface TokenInterface {
    function allowance(address, address) external view returns (uint);
    function balanceOf(address) external view returns (uint);
    function approve(address, uint) external;
    function transfer(address, uint) external returns (bool);
    function transferFrom(address, address, uint) external returns (bool);
    function deposit() external payable;
    function withdraw(uint) external;
}

interface AaveInterface {
    function deposit(address _asset, uint256 _amount, address _onBehalfOf, uint16 _referralCode) external;
    function withdraw(address _asset, uint256 _amount, address _to) external;
    function borrow(
        address _asset,
        uint256 _amount,
        uint256 _interestRateMode,
        uint16 _referralCode,
        address _onBehalfOf
    ) external;
    function repay(address _asset, uint256 _amount, uint256 _rateMode, address _onBehalfOf) external;
    function setUserUseReserveAsCollateral(address _asset, bool _useAsCollateral) external;
}

interface AaveLendingPoolProviderInterface {
    function getLendingPool() external view returns (address);
}

// Aave Protocol Data Provider
interface AaveDataProviderInterface {
    function getReserveTokensAddresses(address _asset) external view returns (
        address aTokenAddress,
        address stableDebtTokenAddress,
        address variableDebtTokenAddress
    );
    function getUserReserveData(address _asset, address _user) external view returns (
        uint256 currentATokenBalance,
        uint256 currentStableDebt,
        uint256 currentVariableDebt,
        uint256 principalStableDebt,
        uint256 scaledVariableDebt,
        uint256 stableBorrowRate,
        uint256 liquidityRate,
        uint40 stableRateLastUpdated,
        bool usageAsCollateralEnabled
    );
}

interface AaveAddressProviderRegistryInterface {
    function getAddressesProvidersList() external view returns (address[] memory);
}

interface ATokenInterface {
    function balanceOf(address _user) external view returns(uint256);
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

contract Stores {

    /**
    * @dev Return ethereum address
    */
    address constant internal ethAddr = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /**
    * @dev Return Wrapped ETH address
    */
    address constant internal wethAddr = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
}

abstract contract AaveHelpers is DSMath, Stores {
    /**
     * @dev get Aave Lending Pool Provider
    */
    function getAaveProvider() internal pure returns (AaveLendingPoolProviderInterface) {
        return AaveLendingPoolProviderInterface(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5); //mainnet
    }

    /**
     * @dev get Aave Protocol Data Provider
    */
    function getAaveDataProvider() internal pure returns (AaveDataProviderInterface) {
        return AaveDataProviderInterface(0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d); //mainnet
    }

    /**
     * @dev Return Weth address
    */
    function getWethAddr() internal pure returns (address) {
        return 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // Mainnet WETH Address
    }

    /**
     * @dev get Referral Code
    */
    function getReferralCode() internal pure returns (uint16) {
        return 3228;
    }

    function getIsColl(AaveDataProviderInterface aaveData, address token, address user) internal view returns (bool isCol) {
        (, , , , , , , , isCol) = aaveData.getUserReserveData(token, user);
    }

    function convertEthToWeth(bool isEth, TokenInterface token, uint amount) internal {
        if(isEth) token.deposit{value: amount}();
    }

    function convertWethToEth(bool isEth, TokenInterface token, uint amount) internal {
       if(isEth) {
            token.approve(address(token), amount);
            token.withdraw(amount);
        }
    }

    function getPaybackBalance(AaveDataProviderInterface aaveData, address token, uint rateMode) internal view returns (uint) {
        (, uint stableDebt, uint variableDebt, , , , , , ) = aaveData.getUserReserveData(token, address(this));
        return rateMode == 1 ? stableDebt : variableDebt;
    }

    function getCollateralBalance(AaveDataProviderInterface aaveData, address token) internal view returns (uint bal) {
        (bal, , , , , , , ,) = aaveData.getUserReserveData(token, address(this));
    }
}

abstract contract BasicResolver is AaveHelpers {
    event LogDeposit(address indexed token, uint256 tokenAmt);
    event LogWithdraw(address indexed token, uint256 tokenAmt);
    event LogBorrow(address indexed token, uint256 tokenAmt, uint256 indexed rateMode);
    event LogPayback(address indexed token, uint256 tokenAmt, uint256 indexed rateMode);
    event LogEnableCollateral(address[] tokens);

    /**
     * @dev Deposit ETH/ERC20_Token.
     * @param token token address to deposit.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amt token amount to deposit.
    */
    function deposit(address token, uint amt) external payable {
        uint _amt = amt;

        AaveInterface aave = AaveInterface(getAaveProvider().getLendingPool());
        AaveDataProviderInterface aaveData = getAaveDataProvider();

        bool isEth = token == ethAddr;
        address _token = isEth ? getWethAddr() : token;

        TokenInterface tokenContract = TokenInterface(_token);

        if (isEth) {
            _amt = _amt == uint(-1) ? address(this).balance : _amt;
            convertEthToWeth(isEth, tokenContract, _amt);
        } else {
            _amt = _amt == uint(-1) ? tokenContract.balanceOf(address(this)) : _amt;
        }

        tokenContract.approve(address(aave), _amt);

        aave.deposit(_token, _amt, address(this), getReferralCode());

        if (!getIsColl(aaveData, _token, address(this))) {
            aave.setUserUseReserveAsCollateral(_token, true);
        }

        emit LogDeposit(token, _amt);
    }

    /**
     * @dev Withdraw ETH/ERC20_Token.
     * @param token token address to withdraw.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amt token amount to withdraw.
    */
    function withdraw(address token, uint amt) external payable {
        uint _amt = amt;

        AaveInterface aave = AaveInterface(getAaveProvider().getLendingPool());
        bool isEth = token == ethAddr;
        address _token = isEth ? getWethAddr() : token;

        TokenInterface tokenContract = TokenInterface(_token);

        uint initialBal = tokenContract.balanceOf(address(this));
        aave.withdraw(_token, _amt, address(this));
        uint finalBal = tokenContract.balanceOf(address(this));

        _amt = sub(finalBal, initialBal);

        convertWethToEth(isEth, tokenContract, _amt);

        emit LogWithdraw(token, _amt);
    }

    /**
     * @dev Borrow ETH/ERC20_Token.
     * @param token token address to borrow.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amt token amount to borrow.
     * @param rateMode type of borrow debt.(For Stable: 1, Variable: 2)
    */
    function borrow(address token, uint amt, uint rateMode) external payable {
        uint _amt = amt;

        AaveInterface aave = AaveInterface(getAaveProvider().getLendingPool());

        bool isEth = token == ethAddr;
        address _token = isEth ? getWethAddr() : token;

        aave.borrow(_token, _amt, rateMode, getReferralCode(), address(this));
        convertWethToEth(isEth, TokenInterface(_token), _amt);

        emit LogBorrow(token, _amt, rateMode);
    }

    /**
     * @dev Payback borrowed ETH/ERC20_Token.
     * @param token token address to payback.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     * @param amt token amount to payback.
     * @param rateMode type of borrow debt.(For Stable: 1, Variable: 2)
    */
    function payback(address token, uint amt, uint rateMode) external payable {
        uint _amt = amt;

        AaveInterface aave = AaveInterface(getAaveProvider().getLendingPool());
        AaveDataProviderInterface aaveData = getAaveDataProvider();

        bool isEth = token == ethAddr;
        address _token = isEth ? getWethAddr() : token;

        TokenInterface tokenContract = TokenInterface(_token);

        _amt = _amt == uint(-1) ? getPaybackBalance(aaveData, _token, rateMode) : _amt;

        if (isEth) convertEthToWeth(isEth, tokenContract, _amt);

        tokenContract.approve(address(aave), _amt);

        aave.repay(_token, _amt, rateMode, address(this));

        emit LogPayback(token, _amt, rateMode);
    }
}

contract ConnectAave is BasicResolver {
    string public name = "AaveV2-v1";
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}