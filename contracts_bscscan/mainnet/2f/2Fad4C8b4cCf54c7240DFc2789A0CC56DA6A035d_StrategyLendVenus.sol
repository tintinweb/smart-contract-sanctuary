/**
 *Submitted for verification at BscScan.com on 2021-07-14
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash =
            0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance =
            token.allowance(address(this), spender).sub(
                value,
                "SafeERC20: decreased allowance below zero"
            );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface IController {
    function withdraw(address, uint256) external;
    function balanceOf(address) external view returns (uint256);
    function earn(address, uint256) external;
    function want(address) external view returns (address);
    function rewards() external view returns (address);
    function vaults(address) external view returns (address);
    function strategies(address) external view returns (address);
}

interface Uni {
    function swapExactTokensForTokens(
        uint256,
        uint256,
        address[] calldata,
        address,
        uint256
    ) external;
}

interface ICBase {
    function balanceOfUnderlying(address owner) external returns (uint256);
    function getAccountSnapshot(address account) external view returns (uint256, uint256, uint256, uint256);
    function borrowBalanceCurrent(address account) external returns (uint256);
    function borrowBalanceStored(address account) external view returns (uint256);
    function getCash() external view returns (uint256);
    function redeem(uint redeemTokens) external returns (uint);
    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);
    function borrow(uint256 borrowAmount) external returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
}

interface CToken is ICBase {
    function underlying() external view returns (address);
    function repayBorrow(uint256 repayAmount) external returns (uint256);
    function mint(uint256 mintAmount) external returns (uint256);

}

interface CETH is ICBase {
    function mint() external payable;
    function repayBorrow() external payable;
}

interface IUnitroller {
    function claimVenus(address holder) external;
    function claimVenus(address holder, address[] calldata cTokens) external;
    function markets(address cTokenAddress) external view returns (bool, uint256);
}

interface IWETH {
    function deposit() external payable;
    function withdraw(uint256 amt) external;
}

contract StrategyLendVenus {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    // Require a 0.1 buffer between
    // market collateral factor and strategy's collateral factor
    // when leveraging
    uint256 colFactorLeverageBuffer = 150;
    uint256 colFactorLeverageBufferMax = 1000;

    // Allow a 0.05 buffer
    // between market collateral factor and strategy's collateral factor
    // until we have to deleverage
    // This is so we can hit max leverage and keep accruing interest
    uint256 colFactorSyncBuffer = 80;
    uint256 colFactorSyncBufferMax = 1000;

    address public constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public constant uniRouter = 0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F;

    uint256 public strategistReward = 3000;  // former: 2000
    uint256 public withdrawalFee = 0;
    uint256 public constant FEE_DENOMINATOR = 10000;

    address public constant comptrl = 0xfD36E2c2a6789Db23113685031d7F16329158384;
    address public comp = 0xcF6BB5389c92Bdda8a3747Ddb454cB7a64626C63;

    address public ctoken;
    address public want;

    address public governance;
    address public controller;
    address public strategist;

    mapping(address => bool) public farmers;

    bool public autoLeverage = false;  // former: true

    constructor(
        address _controller,
        address _ctoken,
        address _want
    ) {
        governance = msg.sender;
        strategist = msg.sender;
        controller = _controller;
        ctoken = _ctoken;
        want = _want;
        if (want != WBNB) {
            require(CToken(ctoken).underlying() == want, "mismatch");
        }
    }

    modifier auth {
        require(
            msg.sender == governance || msg.sender == strategist,
            "!authorized"
        );
        _;
    }

    function addFarmer(address f) public auth {
        farmers[f] = true;
    }

    function removeFarmer(address f) public auth {
        farmers[f] = false;
    }

    function toggerAutoLeverage(bool _b) public auth {
        autoLeverage = _b;
    }

    function setStrategist(address _strategist) external auth {
        strategist = _strategist;
    }

    function setWithdrawalFee(uint256 _withdrawalFee) external {
        require(msg.sender == governance, "!governance");
        withdrawalFee = _withdrawalFee;
    }

    function setStrategistReward(uint256 _strategistReward) external {
        require(msg.sender == governance, "!governance");
        strategistReward = _strategistReward;
    }

    function getSuppliedView() public view returns (uint256) {
        (, uint256 cTokenBal, , uint256 exchangeRate) =
            ICBase(ctoken).getAccountSnapshot(address(this));

        return cTokenBal.mul(exchangeRate).div(1e18);
    }

    function getBorrowedView() public view returns (uint256) {
        return ICBase(ctoken).borrowBalanceStored(address(this));
    }

    function balanceOfPool() public view returns (uint256) {
        uint256 supplied = getSuppliedView();
        uint256 borrowed = getBorrowedView();
        uint b = supplied.sub(borrowed);
        return b;
    }

    function balanceOfWant() public view returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }

    function balanceOf() public view returns (uint256) {
        return balanceOfWant().add(balanceOfPool());
    }

    function getLeveragedSupplyTarget(uint256 supplyBalance) public view returns (uint256) {
        uint256 leverage = getMaxLeverage();
        return supplyBalance.mul(leverage).div(1e18);
    }

    function getSafeLeverageColFactor() public view returns (uint256) {
        uint256 colFactor = getMarketColFactor();

        uint256 safeColFactor =
            colFactor.sub(
                colFactorLeverageBuffer.mul(1e18).div(
                    colFactorLeverageBufferMax
                )
            );

        return safeColFactor;
    }

    function getSafeSyncColFactor() public view returns (uint256) {
        uint256 colFactor = getMarketColFactor();

        // Collateral factor within the buffer
        uint256 safeColFactor =
            colFactor.sub(
                colFactorSyncBuffer.mul(1e18).div(colFactorSyncBufferMax)
            );

        return safeColFactor;
    }

    function getMarketColFactor() public view returns (uint256) {
        (, uint256 colFactor) = IUnitroller(comptrl).markets(ctoken);

        return colFactor;
    }

    // Max leverage we can go up to, w.r.t safe buffer
    function getMaxLeverage() public view returns (uint256) {
        uint256 safeLeverageColFactor = getSafeLeverageColFactor();

        // Infinite geometric series
        uint256 leverage = uint256(1e36).div(1e18 - safeLeverageColFactor);
        return leverage;
    }

    function getColFactor() public returns (uint256) {
        uint256 supplied = getSupplied();
        uint256 borrowed = getBorrowed();

        return borrowed.mul(1e18).div(supplied);
    }

    function getSuppliedUnleveraged() public returns (uint256) {
        uint256 supplied = getSupplied();
        uint256 borrowed = getBorrowed();

        return supplied.sub(borrowed);
    }

    function getSupplied() public returns (uint256) {
        return ICBase(ctoken).balanceOfUnderlying(address(this));
    }

    function getBorrowed() public returns (uint256) {
        return ICBase(ctoken).borrowBalanceCurrent(address(this));
    }

    function getBorrowable() public returns (uint256) {
        uint256 supplied = getSupplied();
        uint256 borrowed = getBorrowed();

        (, uint256 colFactor) = IUnitroller(comptrl).markets(ctoken);

        // 99.99% just in case some dust accumulates
        return
            supplied.mul(colFactor).div(1e18).sub(borrowed).mul(9990).div(
                10000
            );
    }

    function getCurrentLeverage() public returns (uint256) {
        uint256 supplied = getSupplied();
        uint256 borrowed = getBorrowed();

        return supplied.mul(1e18).div(supplied.sub(borrowed));
    }

    function setColFactorLeverageBuffer(uint256 _colFactorLeverageBuffer)
        public
    {
        require(
            msg.sender == governance || msg.sender == strategist,
            "!governance"
        );
        colFactorLeverageBuffer = _colFactorLeverageBuffer;
    }

    function setColFactorSyncBuffer(uint256 _colFactorSyncBuffer) public {
        require(
            msg.sender == governance || msg.sender == strategist,
            "!governance"
        );
        colFactorSyncBuffer = _colFactorSyncBuffer;
    }

    function sync() public returns (bool) {
        uint256 colFactor = getColFactor();
        uint256 safeSyncColFactor = getSafeSyncColFactor();

        // If we're not safe
        if (colFactor > safeSyncColFactor) {
            uint256 unleveragedSupply = getSuppliedUnleveraged();
            uint256 idealSupply = getLeveragedSupplyTarget(unleveragedSupply);

            deleverageUntil(idealSupply);

            return true;
        } else {
            leverageToMax();
            return true;
        }
    }

    function leverageToMax() public {
        uint256 unleveragedSupply = getSuppliedUnleveraged();
        uint256 idealSupply = getLeveragedSupplyTarget(unleveragedSupply);
        leverageUntil(idealSupply);
    }

    function leverageUntil(uint256 _supplyAmount) public {
        require(
            msg.sender == governance || msg.sender == controller,
            "!governance | controller"
        );
        uint256 leverage = getMaxLeverage();
        uint256 unleveragedSupply = getSuppliedUnleveraged();
        require(
            _supplyAmount >= unleveragedSupply &&
                _supplyAmount <= unleveragedSupply.mul(leverage).div(1e18),
            "!leverage"
        );

        uint256 _borrowAndSupply;
        uint256 supplied = getSupplied();
        while (supplied < _supplyAmount) {
            _borrowAndSupply = getBorrowable();

            if (supplied.add(_borrowAndSupply) > _supplyAmount) {
                _borrowAndSupply = _supplyAmount.sub(supplied);
            }

            require(ICBase(ctoken).borrow(_borrowAndSupply) == 0);
            _deposit();

            supplied = supplied.add(_borrowAndSupply);
        }
    }

    function deleverageToMin() public {
        uint256 unleveragedSupply = getSuppliedUnleveraged();
        deleverageUntil(unleveragedSupply);
    }

    function deleverageUntil(uint256 _supplyAmount) public {
        require(
            msg.sender == governance || msg.sender == controller,
            "!governance | controller"
        );
        uint256 unleveragedSupply = getSuppliedUnleveraged();
        uint256 supplied = getSupplied();
        require(
            _supplyAmount >= unleveragedSupply && _supplyAmount <= supplied,
            "!deleverage"
        );

        uint256 _redeemAndRepay = getBorrowable();
        IERC20(want).safeApprove(ctoken, 0);
        IERC20(want).safeApprove(ctoken, uint256(-1));
        do {
            if (supplied.sub(_redeemAndRepay) < _supplyAmount) {
                _redeemAndRepay = supplied.sub(_supplyAmount);
            }

            require(
                ICBase(ctoken).redeemUnderlying(_redeemAndRepay) == 0,
                "!redeem"
            );
            if (want == WBNB) {
                CETH(ctoken).repayBorrow{value: _redeemAndRepay}();
            } else {
                require(CToken(ctoken).repayBorrow(_redeemAndRepay) == 0, "!repay");
            }

            supplied = supplied.sub(_redeemAndRepay);
        } while (supplied > _supplyAmount);
        if (want == WBNB) {
            uint bl = address(this).balance;
            if (bl > 0) {
                IWETH(WBNB).deposit{value: bl}(); 
            }
        }
    }

    modifier onlyBenevolent {
        require(
            farmers[msg.sender] ||
                msg.sender == governance ||
                msg.sender == strategist
        );
        _;
    }

    function harvest() public onlyBenevolent {
        address[] memory markets = new address[](1);
        markets[0] = ctoken;
        IUnitroller(comptrl).claimVenus(address(this), markets);
        uint256 _comp = IERC20(comp).balanceOf(address(this));

        uint256 before = IERC20(want).balanceOf(address(this));

        if (_comp == 0) {
            return;
        }

        IERC20(comp).safeApprove(uniRouter, 0);
        IERC20(comp).safeApprove(uniRouter, uint256(-1));

        if (want == WBNB) {
            address[] memory path = new address[](2);
            path[0] = comp;
            path[1] = WBNB;
            Uni(uniRouter).swapExactTokensForTokens(
                _comp,
                uint256(0),
                path,
                address(this),
                block.timestamp.add(1800)
            );
        } else {
            address[] memory path = new address[](3);
            path[0] = comp;
            path[1] = WBNB;
            path[2] = want;
            Uni(uniRouter).swapExactTokensForTokens(
                _comp,
                uint256(0),
                path,
                address(this),
                block.timestamp.add(1800)
            );
        }

        uint256 gain = IERC20(want).balanceOf(address(this)).sub(before);
        if (gain > 0) {
            uint256 _reward = gain.mul(strategistReward).div(FEE_DENOMINATOR);
            IERC20(want).safeTransfer(IController(controller).rewards(), _reward);
            _deposit();
        }
    }

    function deposit() public {
        if (_deposit() > 0) {
            if (autoLeverage) {
                sync();
            }
        }
    }

    function _deposit() internal returns (uint) {
        uint bl = address(this).balance;
        if (bl > 0 && want == WBNB) {
            IWETH(WBNB).deposit{value: bl}(); 
        }
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want == 0) {
            return 0;
        }
        if (want == WBNB) {
            IWETH(WBNB).withdraw(_want);
            CETH(ctoken).mint{value: _want}();
        } else {
            IERC20(want).safeApprove(ctoken, 0);
            IERC20(want).safeApprove(ctoken, _want);
            require(CToken(ctoken).mint(_want) == 0, "!deposit");
        }
        return _want;
    }

    function _withdrawSome(uint256 _amount) internal returns (uint256) {
        uint256 _balance = balanceOfWant();
        uint256 _redeem = _amount;

        require(ICBase(ctoken).getCash() >= _redeem, "!cash-liquidity");

        uint256 borrowed = getBorrowed();
        uint256 supplied = getSupplied();
        if (_redeem > supplied.sub(borrowed)) {
            _redeem = supplied.sub(borrowed);
        }
        uint256 curLeverage = getCurrentLeverage();
        uint256 borrowedToBeFree = _redeem.mul(curLeverage).div(1e18);

        if (borrowedToBeFree > borrowed) {
            deleverageToMin();
        } else {
            deleverageUntil(supplied.sub(borrowedToBeFree));
        }

        if (_redeem > 0) {
            if (want == WBNB) {
                require(ICBase(ctoken).redeemUnderlying(_redeem) == 0, "!redeem");
                IWETH(WBNB).deposit{value: _redeem}();
            } else {
                require(ICBase(ctoken).redeemUnderlying(_redeem) == 0, "!redeem");
            }
        }

        uint256 _reedemed = balanceOfWant();
        _reedemed = _reedemed.sub(_balance);

        return _reedemed;
    }

    function withdrawAll() external returns (uint256 balance) {
        require(msg.sender == controller, "!controller");
        _withdrawAll();

        balance = IERC20(want).balanceOf(address(this));

        address _vault = IController(controller).vaults(address(want));
        require(_vault != address(0), "!vault"); 
        IERC20(want).safeTransfer(_vault, balance);
    }

    function _withdrawAll() internal {
        uint256 borrowed = getBorrowed();
        uint256 supplied = getSupplied();
        _withdrawSome(supplied.sub(borrowed));
    }

    function withdraw(uint256 _amount) external {
        require(msg.sender == controller, "!controller");
        uint256 _balance = IERC20(want).balanceOf(address(this));
        if (_balance < _amount) {
            _amount = _withdrawSome(_amount.sub(_balance));
            _amount = _amount.add(_balance);
        }

        uint256 _fee = _amount.mul(withdrawalFee).div(FEE_DENOMINATOR);

        if (_fee > 0) {
            IERC20(want).safeTransfer(IController(controller).rewards(), _fee);
        }
        address _vault = IController(controller).vaults(address(want));
        require(_vault != address(0), "!vault"); 
        IERC20(want).safeTransfer(_vault, _amount.sub(_fee));
    }

    function withdraw(IERC20 _asset) external returns (uint256 balance) {
        require(msg.sender == controller, "!controller");
        require(want != address(_asset), "want");
        require(ctoken != address(_asset), "want");
        require(comp != address(_asset), "want");
        balance = _asset.balanceOf(address(this));
        _asset.safeTransfer(controller, balance);
    }

    // emergency functions
    function e_exit() public {
        require(msg.sender == governance, "!governance");
        deleverageToMin();
        uint amt = ICBase(ctoken).balanceOf(address(this));
        if (amt > 0) {
            require(ICBase(ctoken).redeem(amt) == 0, "!e_redeem");
            if (want == WBNB && address(this).balance > 0) {
                IWETH(WBNB).deposit{value: address(this).balance}();
            }
        }
        
        uint balance = IERC20(want).balanceOf(address(this));
        if (balance > 0) {
            address _vault = IController(controller).vaults(address(want));
            require(_vault != address(0), "!vault"); 
            IERC20(want).safeTransfer(_vault, balance);
        }
    }

    function getDiv() public view returns (uint256) {
        uint256 supplied = getSuppliedView();
        uint256 borrowed = getBorrowedView();
        return borrowed.mul(10000).div(supplied);
    }

    receive() external payable {}
}