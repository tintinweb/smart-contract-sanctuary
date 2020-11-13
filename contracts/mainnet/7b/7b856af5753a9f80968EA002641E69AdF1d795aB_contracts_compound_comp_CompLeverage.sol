pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./CompBalance.sol";
import "../../exchangeV3/DFSExchangeCore.sol";
import "../../loggers/DefisaverLogger.sol";
import "../../interfaces/DSProxyInterface.sol";
import "../CompoundBasicProxy.sol";

contract CompLeverage is DFSExchangeCore, CompBalance {
    address public constant C_COMP_ADDR = 0x70e36f6BF80a52b3B46b3aF8e106CC0ed743E8e4;

    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant CETH_ADDRESS = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;
    address payable public constant WALLET_ADDR = 0x322d58b9E75a6918f7e7849AEe0fF09369977e08;
    address public constant DISCOUNT_ADDR = 0x1b14E8D511c9A4395425314f849bD737BAF8208F;
    address public constant COMPTROLLER_ADDR = 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;

    address public constant DEFISAVER_LOGGER = 0x5c55B921f590a89C1Ebe84dF170E655a82b62126;

    DefisaverLogger public constant logger = DefisaverLogger(0x5c55B921f590a89C1Ebe84dF170E655a82b62126);

    /// @notice Should claim COMP and sell it to the specified token and deposit it back
    /// @param exchangeData Standard Exchange struct
    /// @param _cTokensSupply List of cTokens user is supplying
    /// @param _cTokensBorrow List of cTokens user is borrowing
    /// @param _cDepositAddr The cToken address of the asset you want to deposit
    /// @param _inMarket Flag if the cToken is used as collateral
    function claimAndSell(
        ExchangeData memory exchangeData,
        address[] memory _cTokensSupply,
        address[] memory _cTokensBorrow,
        address _cDepositAddr,
        bool _inMarket
    ) public payable {
        // Claim COMP token
        _claim(address(this), _cTokensSupply, _cTokensBorrow);

        uint compBalance = ERC20(COMP_ADDR).balanceOf(address(this));
        uint depositAmount = 0;

        // Exchange COMP
        if (exchangeData.srcAddr != address(0)) {
            exchangeData.dfsFeeDivider = 400; // 0.25%
            exchangeData.srcAmount = compBalance;

            (, depositAmount) = _sell(exchangeData);

            // if we have no deposit after, send back tokens to the user
            if (_cDepositAddr == address(0)) {
                if (exchangeData.destAddr != ETH_ADDRESS) {
                    ERC20(exchangeData.destAddr).transfer(msg.sender, depositAmount);
                } else {
                    msg.sender.transfer(address(this).balance);
                }
            }
        }

        // Deposit back a token
        if (_cDepositAddr != address(0)) {
            // if we are just depositing COMP without a swap
            if (_cDepositAddr == C_COMP_ADDR) {
                depositAmount = compBalance;
            }

            address tokenAddr = getUnderlyingAddr(_cDepositAddr);
            deposit(tokenAddr, _cDepositAddr, depositAmount, _inMarket);
        }

        logger.Log(address(this), msg.sender, "CompLeverage", abi.encode(compBalance, depositAmount, _cDepositAddr, exchangeData.destAmount));
    }

    function getUnderlyingAddr(address _cTokenAddress) internal returns (address) {
        if (_cTokenAddress == CETH_ADDRESS) {
            return ETH_ADDRESS;
        } else {
            return CTokenInterface(_cTokenAddress).underlying();
        }
    }

    function deposit(address _tokenAddr, address _cTokenAddr, uint _amount, bool _inMarket) public burnGas(5) payable {
        approveToken(_tokenAddr, _cTokenAddr);

        if (!_inMarket) {
            enterMarket(_cTokenAddr);
        }

        if (_tokenAddr != ETH_ADDRESS) {
            require(CTokenInterface(_cTokenAddr).mint(_amount) == 0);
        } else {
            CEtherInterface(_cTokenAddr).mint{value: msg.value}(); // reverts on fail
        }
    }

     function enterMarket(address _cTokenAddr) public {
        address[] memory markets = new address[](1);
        markets[0] = _cTokenAddr;

        ComptrollerInterface(COMPTROLLER_ADDR).enterMarkets(markets);
    }

    function approveToken(address _tokenAddr, address _cTokenAddr) internal {
        if (_tokenAddr != ETH_ADDRESS) {
            ERC20(_tokenAddr).safeApprove(_cTokenAddr, uint(-1));
        }
    }
}
