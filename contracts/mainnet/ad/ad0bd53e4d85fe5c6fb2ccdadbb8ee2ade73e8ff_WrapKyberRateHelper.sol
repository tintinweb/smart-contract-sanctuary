/**
 *Submitted for verification at Etherscan.io on 2020-09-30
*/

/**
 *Submitted for verification at Etherscan.io on 2020-07-28
*/

// File: contracts/sol6/IERC20.sol

pragma solidity 0.6.6;


interface IERC20 {
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function approve(address _spender, uint256 _value) external returns (bool success);

    function transfer(address _to, uint256 _value) external returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function decimals() external view returns (uint8 digits);

    function totalSupply() external view returns (uint256 supply);
}

// File: contracts/sol6/wrappers/IKyberRateHelper.sol

pragma solidity 0.6.6;



interface IKyberRateHelper {
    function getRatesForToken(
        IERC20 token,
        uint256 optionalBuyAmountWei,
        uint256 optionalSellAmountTwei
    )
        external
        view
        returns (
            bytes32[] memory buyReserves,
            uint256[] memory buyRates,
            bytes32[] memory sellReserves,
            uint256[] memory sellRates
        );

    function getPricesForToken(
        IERC20 token,
        uint256 optionalBuyAmountWei,
        uint256 optionalSellAmountTwei
    )
        external
        view
        returns (
            bytes32[] memory buyReserves,
            uint256[] memory buyRates,
            bytes32[] memory sellReserves,
            uint256[] memory sellRates
        );

    function getRatesForTokenWithCustomFee(
        IERC20 token,
        uint256 optionalBuyAmountWei,
        uint256 optionalSellAmountTwei,
        uint256 networkFeeBps
    )
        external
        view
        returns (
            bytes32[] memory buyReserves,
            uint256[] memory buyRates,
            bytes32[] memory sellReserves,
            uint256[] memory sellRates
        );

    function getReservesRates(IERC20 token, uint256 optionalAmountWei)
        external
        view
        returns (
            bytes32[] memory buyReserves,
            uint256[] memory buyRates,
            bytes32[] memory sellReserves,
            uint256[] memory sellRates
        );

    function getSpreadInfo(IERC20 token, uint256 optionalAmountWei)
        external
        view
        returns (bytes32[] memory reserves, int256[] memory spreads);

    function getSlippageRateInfo(
        IERC20 token,
        uint256 optionalAmountWei,
        uint256 optionalSlippageAmountWei
    )
        external
        view
        returns (
            bytes32[] memory buyReserves,
            int256[] memory buySlippageRateBps,
            bytes32[] memory sellReserves,
            int256[] memory sellSlippageRateBps
        );
}

pragma solidity 0.6.6;


contract PermissionGroups {
    address public admin;
    address public pendingAdmin;

    event AdminClaimed(address newAdmin, address previousAdmin);
    event TransferAdminPending(address pendingAdmin);

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin");
        _;
    }

    constructor(address _admin) public {
        require(_admin != address(0), "admin 0");
        admin = _admin;
    }

    /// @dev Allows the pendingAdmin address to finalize the change admin process.
    function claimAdmin() external {
        require(pendingAdmin == msg.sender, "not pending");
        emit AdminClaimed(pendingAdmin, admin);
        admin = pendingAdmin;
        pendingAdmin = address(0);
    }

    
    /// @dev Allows the current admin to set the pendingAdmin address
    /// @param newAdmin The address to transfer ownership to
    function transferAdmin(address newAdmin) onlyAdmin external {
        require(newAdmin != address(0), "new admin 0");
        emit TransferAdminPending(newAdmin);
        pendingAdmin = newAdmin;
    }

    /// @dev Allows the current admin to set the admin in one tx. Useful initial deployment.
    /// @param newAdmin The address to transfer ownership to.
    function transferAdminQuickly(address newAdmin) onlyAdmin external {
        require(newAdmin != address(0), "admin 0");
        emit TransferAdminPending(newAdmin);
        emit AdminClaimed(newAdmin, admin);
        admin = newAdmin;
    }

}

pragma solidity 0.6.6;




contract Withdrawable is PermissionGroups {
    constructor(address _admin) public PermissionGroups(_admin) {}

    event EtherWithdraw(uint256 amount, address sendTo);
    event TokenWithdraw(IERC20 token, uint256 amount, address sendTo);

    /// @dev Withdraw Ethers
    function withdrawEther(uint256 amount, address payable sendTo) onlyAdmin external {
        (bool success, ) = sendTo.call{value: amount}("");
        require(success);
        emit EtherWithdraw(amount, sendTo);
    }

    /// @dev Withdraw all IERC20 compatible tokens
    /// @param token IERC20 The address of the token contract
    function withdrawToken(
        IERC20 token,
        uint256 amount,
        address sendTo
    ) onlyAdmin external {
        token.transfer(sendTo, amount);
        emit TokenWithdraw(token, amount, sendTo);
    }
}

// File: contracts/sol6/IKyberDao.sol

pragma solidity 0.6.6;



interface IKyberDao {

    function getLatestNetworkFeeData()
        external
        view
        returns (uint256 feeInBps, uint256 expiryTimestamp);

}

// File: contracts/sol6/wrappers/KyberRateHelper.sol

pragma solidity 0.6.6;


contract WrapKyberRateHelper is Withdrawable {

    constructor() public Withdrawable(msg.sender) {}

    /// @dev function to cover backward compatible with old network interface
    /// @dev get rate from eth to token, use the best token amount to get rate from token to eth
    /// @param tokens Token to get rate
    /// @param optionalAmountWeis Eth amount to get rate (default: 0)
    function getReservesRates(IKyberRateHelper rateHelper, IERC20[] calldata tokens, uint256[] calldata optionalAmountWeis)
        external
        view
        returns (
            uint256[] memory buyLengths,
            bytes32[] memory buyReserves,
            uint256[] memory buyRates,
            uint256[] memory sellLengths,
            bytes32[] memory sellReserves,
            uint256[] memory sellRates
        )
    {
        buyLengths = new uint256[](tokens.length);
        sellLengths = new uint256[](tokens.length);

        uint256 buyCounter = 0;
        uint256 sellCounter = 0;
        for(uint256 i = 0; i < tokens.length; i++) {
            (buyReserves, , sellReserves,) = rateHelper.getReservesRates(tokens[i], optionalAmountWeis[i]);
            buyCounter += buyReserves.length;
            sellCounter += sellReserves.length;
            buyLengths[i] = buyReserves.length;
            sellLengths[i] = sellReserves.length;
        }

        (buyReserves, buyRates, sellReserves, sellRates) = getFinalReservesRates(
            rateHelper,
            tokens,
            optionalAmountWeis,
            buyCounter,
            sellCounter
        );
    }

    function getBestReservesRates(IKyberRateHelper rateHelper, IERC20[] calldata tokens, uint256[] calldata optionalAmountWeis)
        external
        view
        returns (
            bytes32[] memory buyReserves,
            uint256[] memory buyRates,
            bytes32[] memory sellReserves,
            uint256[] memory sellRates
        )
    {
        buyReserves = new bytes32[](tokens.length);
        buyRates = new uint256[](tokens.length);
        sellReserves = new bytes32[](tokens.length);
        sellRates = new uint256[](tokens.length);

        bytes32[] memory _buyReserves;
        uint256[] memory _buyRates;
        bytes32[] memory _sellReserves;
        uint256[] memory _sellRates;

        for(uint256 i = 0; i < tokens.length; i++) {
            (_buyReserves, _buyRates, _sellReserves, _sellRates) = rateHelper.getReservesRates(tokens[i], optionalAmountWeis[i]);
            for(uint256 j = 0; j < _buyReserves.length; j++) {
                if (_buyRates[j] > buyRates[i]) {
                    buyRates[i] = _buyRates[j];
                    buyReserves[i] = _buyReserves[j];
                }   
            }
            for(uint256 j = 0; j < _sellReserves.length; j++) {
                if (_sellRates[j] > sellRates[i]) {
                    sellRates[i] = _sellRates[j];
                    sellReserves[i] = _sellReserves[j];
                }   
            }
        }
    }

    function getRatesForTokens(
        IKyberRateHelper rateHelper,
        IERC20[] calldata tokens,
        uint256[] calldata optionalBuyAmountWeis,
        uint256[] calldata optionalSellAmountTweis
    )
        external
        view
        returns (
            uint256[] memory buyLengths,
            bytes32[] memory buyReserves,
            uint256[] memory buyRates,
            uint256[] memory sellLengths,
            bytes32[] memory sellReserves,
            uint256[] memory sellRates
        )
    {
        buyLengths = new uint256[](tokens.length);
        sellLengths = new uint256[](tokens.length);

        uint256 buyCounter;
        uint256 sellCounter;
        (buyLengths, sellLengths, buyCounter, sellCounter) = getRatesForTokensLengths(
            rateHelper,
            tokens,
            optionalBuyAmountWeis,
            optionalSellAmountTweis
        );

        (buyReserves, buyRates, sellReserves, sellRates) = getRatesForTokensData(
            rateHelper,
            tokens,
            optionalBuyAmountWeis,
            optionalSellAmountTweis,
            buyCounter,
            sellCounter
        );
    }

    function getBestReservesRates2(
        IKyberRateHelper rateHelper,
        IERC20[] calldata tokens,
        uint256[] calldata optionalBuyAmountWeis,
        uint256[] calldata optionalSellAmountTweis
    )
        external
        view
        returns (
            bytes32[] memory buyReserves,
            uint256[] memory buyRates,
            bytes32[] memory sellReserves,
            uint256[] memory sellRates
        )
    {
        buyReserves = new bytes32[](tokens.length);
        buyRates = new uint256[](tokens.length);
        sellReserves = new bytes32[](tokens.length);
        sellRates = new uint256[](tokens.length);

        for(uint256 i = 0; i < tokens.length; i++) {
            (
                buyReserves[i],
                buyRates[i],
                sellReserves[i],
                sellRates[i]
            ) = getBestReserveRateHelp(
                rateHelper,
                tokens[i],
                optionalBuyAmountWeis[i],
                optionalSellAmountTweis[i]
            );
        }
    }

    // avoid stake too deep
    function getBestReserveRateHelp(
        IKyberRateHelper rateHelper,
        IERC20 token,
        uint256 buyAmount,
        uint256 sellAmount
    )
        internal
        view
        returns (
            bytes32 buyReserve,
            uint256 buyRate,
            bytes32 sellReserve,
            uint256 sellRate
        )
    {
        bytes32[] memory _buyReserves;
        uint256[] memory _buyRates;
        bytes32[] memory _sellReserves;
        uint256[] memory _sellRates;

        (_buyReserves, _buyRates, _sellReserves, _sellRates) = rateHelper.getRatesForToken(
            token,
            buyAmount,
            sellAmount
        );
        for(uint256 i = 0; i < _buyReserves.length; i++) {
            if (_buyRates[i] > buyRate) {
                buyRate = _buyRates[i];
                buyReserve = _buyReserves[i];
            }   
        }
        for(uint256 i = 0; i < _sellReserves.length; i++) {
            if (_sellRates[i] > sellRate) {
                sellRate = _sellRates[i];
                sellReserve = _sellReserves[i];
            }   
        }
    }

    function getFinalReservesRates(
        IKyberRateHelper rateHelper,
        IERC20[] memory tokens,
        uint256[] memory optionalAmountWeis,
        uint256 buyCounter,
        uint256 sellCounter
    )
        internal
        view
        returns (
            bytes32[] memory buyReserves,
            uint256[] memory buyRates,
            bytes32[] memory sellReserves,
            uint256[] memory sellRates
        )
    {
        buyReserves = new bytes32[](buyCounter);
        buyRates = new uint256[](buyCounter);
        sellReserves = new bytes32[](sellCounter);
        sellRates = new uint256[](sellCounter);

        bytes32[] memory bReserves;
        uint256[] memory bRates;
        bytes32[] memory sReserves;
        uint256[] memory sRates;

        buyCounter = 0;
        sellCounter = 0;

        for(uint256 i = 0; i < tokens.length; i++) {
            (bReserves, bRates, sReserves, sRates) = rateHelper.getReservesRates(tokens[i], optionalAmountWeis[i]);
            for(uint256 j = buyCounter; j < buyCounter + bReserves.length; j++) {
                buyReserves[j] = bReserves[j - buyCounter];
                buyRates[j] = bRates[j - buyCounter];
            }
            for(uint256 j = sellCounter; j < sellCounter + sReserves.length; j++) {
                sellReserves[j] = sReserves[j - sellCounter];
                sellRates[j] = sRates[j - sellCounter];
            }
            buyCounter += bReserves.length;
            sellCounter += sReserves.length;
        }
    }

    function getRatesForTokensLengths(
        IKyberRateHelper rateHelper,
        IERC20[] memory tokens,
        uint256[] memory optionalBuyAmountWeis,
        uint256[] memory optionalSellAmountTweis
    )
        internal
        view
        returns (
            uint256[] memory buyLengths,
            uint256[] memory sellLengths,
            uint256 buyCounter,
            uint256 sellCounter
        )
    {
        buyLengths = new uint256[](tokens.length);
        sellLengths = new uint256[](tokens.length);

        bytes32[] memory buyReserves;
        bytes32[] memory sellReserves;
        for(uint256 i = 0; i < tokens.length; i++) {
            (buyReserves, , sellReserves,) = rateHelper.getRatesForToken(
                tokens[i],
                optionalBuyAmountWeis[i],
                optionalSellAmountTweis[i]
            );
            buyCounter += buyReserves.length;
            sellCounter += sellReserves.length;
            buyLengths[i] = buyReserves.length;
            sellLengths[i] = sellReserves.length;
        }
    }

    function getRatesForTokensData(
        IKyberRateHelper rateHelper,
        IERC20[] memory tokens,
        uint256[] memory optionalBuyAmountWeis,
        uint256[] memory optionalSellAmountTweis,
        uint256 buyCounter,
        uint256 sellCounter
    )
        internal
        view
        returns (
            bytes32[] memory buyReserves,
            uint256[] memory buyRates,
            bytes32[] memory sellReserves,
            uint256[] memory sellRates
        )
    {
        buyReserves = new bytes32[](buyCounter);
        buyRates = new uint256[](buyCounter);
        sellReserves = new bytes32[](sellCounter);
        sellRates = new uint256[](sellCounter);

        bytes32[] memory bReserves;
        uint256[] memory bRates;
        bytes32[] memory sReserves;
        uint256[] memory sRates;

        buyCounter = 0;
        sellCounter = 0;

        for(uint256 i = 0; i < tokens.length; i++) {
            (bReserves, bRates, sReserves, sRates) = rateHelper.getRatesForToken(
                tokens[i],
                optionalBuyAmountWeis[i],
                optionalSellAmountTweis[i]
            );
            for(uint256 j = buyCounter; j < buyCounter + bReserves.length; j++) {
                buyReserves[j] = bReserves[j - buyCounter];
                buyRates[j] = bRates[j - buyCounter];
            }
            for(uint256 j = sellCounter; j < sellCounter + sReserves.length; j++) {
                sellReserves[j] = sReserves[j - sellCounter];
                sellRates[j] = sRates[j - sellCounter];
            }
            buyCounter += bReserves.length;
            sellCounter += sReserves.length;
        }
    }
}