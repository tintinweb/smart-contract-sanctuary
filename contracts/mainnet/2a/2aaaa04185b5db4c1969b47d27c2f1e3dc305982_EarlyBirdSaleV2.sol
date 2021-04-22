// SPDX-License-Identifier: MIT
pragma solidity =0.7.5;

// VokenTB (TeraByte) EarlyBird-Sale
//
// More info:
//   https://voken.io
//
// Contact us:
//   [email protected]


import "LibSafeMath.sol";
import "LibIERC20.sol";
import "LibIVesting.sol";
import "LibIVokenTB.sol";
import "LibAuthPause.sol";
import "EbWithVestingPermille.sol";


interface IUniswapV2Router02 {
    function WETH() external pure returns (address);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
}


/**
 * @dev EarlyBird-Sale v2
 */
contract EarlyBirdSaleV2 is AuthPause, IVesting, WithVestingPermille {
    using SafeMath for uint256;

    uint256 private immutable VOKEN_ISSUE_MAX = 21_000_000e9;  // 21 million for early-birds
    uint256 private immutable VOKEN_ISSUE_MID = 10_500_000e9;
    uint256 private immutable WEI_PAYMENT_MAX = 5.0 ether;
    uint256 private immutable WEI_PAYMENT_MID = 3.0 ether;
    uint256 private immutable WEI_PAYMENT_MIN = 0.1 ether;
    uint256 private immutable USD_PRICE_START = 0.5e6;  // $ 0.5 USD
    uint256 private immutable USD_PRICE_DISTA = 0.4e6;  // $ 0.4 USD = 0.9 - 0.5
    uint256 private _vokenIssued;
    uint256 private _vokenRandom;

    IUniswapV2Router02 private immutable UniswapV2Router02 = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IVokenTB private immutable VOKEN_TB = IVokenTB(0x1234567a022acaa848E7D6bC351d075dBfa76Dd4);
    IERC20 private immutable DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);

    struct Account {
        uint256 issued;
        uint256 bonuses;
        uint256 referred;
        uint256 rewards;
    }

    mapping (address => Account) private _accounts;

    event Payment(address indexed account, uint256 daiAmount, uint256 issued, uint256 random);
    event Reward(address indexed account, address indexed referrer, uint256 amount);
    

    constructor () {
        _vokenIssued = 344506165000000;
        _vokenRandom = 19157979970000;
    }

    receive()
        external
        payable
    {
        _swap();
    }

    function swap()
        external
        payable
    {
        _swap();
    }

    function status()
        public
        view
        returns (
            uint256 vokenCap,
            uint256 vokenTotalSupply,

            uint256 vokenIssued,
            uint256 vokenRandom,
            uint256 etherUSD,
            uint256 vokenUSD,
            uint256 weiMin,
            uint256 weiMax
        )
    {
        vokenCap = VOKEN_TB.cap();
        vokenTotalSupply = VOKEN_TB.totalSupply();

        vokenIssued = _vokenIssued;
        vokenRandom = _vokenRandom;
        etherUSD = etherUSDPrice();
        vokenUSD = vokenUSDPrice();

        weiMin = WEI_PAYMENT_MIN;
        weiMax = _vokenIssued < VOKEN_ISSUE_MID ? WEI_PAYMENT_MAX : WEI_PAYMENT_MID;
    }

    function getAccountStatus(address account)
        public
        view
        returns (
            uint256 issued,
            uint256 bonuses,
            uint256 referred,
            uint256 rewards,

            uint256 etherBalance,
            uint256 vokenBalance,

            uint160 voken,
            address referrer,
            uint160 referrerVoken
        )
    {
        issued = _accounts[account].issued;
        bonuses = _accounts[account].bonuses;
        referred = _accounts[account].referred;
        rewards = _accounts[account].referred;

        etherBalance = account.balance;
        vokenBalance = VOKEN_TB.balanceOf(account);
        
        voken = VOKEN_TB.address2voken(account);
        referrer = VOKEN_TB.referrer(account);

        if (referrer != address(0)) {
            referrerVoken = VOKEN_TB.address2voken(referrer);
        }
    }

    function vestingOf(address account)
        public
        override
        view
        returns (uint256 vesting)
    {
        vesting = vesting.add(_getVestingAmountForIssued(_accounts[account].issued));
        vesting = vesting.add(_getVestingAmountForBonuses(_accounts[account].bonuses));
        vesting = vesting.add(_getVestingAmountForRewards(_accounts[account].rewards));
    }

    function vokenUSDPrice()
        public
        view
        returns (uint256)
    {
        return USD_PRICE_START.add(USD_PRICE_DISTA.mul(_vokenIssued).div(VOKEN_ISSUE_MAX));
    }
    
    function daiTransfer(address to, uint256 amount)
        external
        onlyAgent
    {
        DAI.transfer(to, amount);
    }

    function _swap()
        private
        onlyNotPaused
    {
        require(msg.value >= WEI_PAYMENT_MIN, "Insufficient ether");
        require(_vokenIssued < VOKEN_ISSUE_MAX, "Early-Bird sale completed");
        require(_accounts[msg.sender].issued == 0, "Caller is already an early-bird");

        uint256 weiPayment = msg.value;
        uint256 weiPaymentMax = _vokenIssued < VOKEN_ISSUE_MID ? WEI_PAYMENT_MAX : WEI_PAYMENT_MID;

        // Limit the Payment and Refund (if needed)
        if (weiPayment > weiPaymentMax)
        {
            msg.sender.transfer(weiPayment.sub(weiPaymentMax));
            weiPayment = weiPaymentMax;
        }

        uint256 daiAmount = _swapExactETH2DAI(weiPayment);
        uint256 vokenIssued = daiAmount.div(1e3).div(vokenUSDPrice());
        uint256 vokenRandom;

        // Voken Bonus & Ether Rewards
        address payable referrer = VOKEN_TB.referrer(msg.sender);
        if (referrer != address(0))
        {
            // Reffer
            _accounts[referrer].referred = _accounts[referrer].referred.add(daiAmount);

            // Voken Random: 1% - 10%
            vokenRandom = vokenIssued.mul(uint256(blockhash(block.number - 1)).mod(10).add(1)).div(100);
            emit Reward(msg.sender, referrer, vokenRandom);

            _vokenRandom = _vokenRandom.add(vokenRandom.mul(2));
            _accounts[msg.sender].bonuses = _accounts[msg.sender].bonuses.add(vokenRandom);
            _accounts[referrer].rewards = _accounts[referrer].rewards.add(vokenRandom);

            // VOKEN_TB.mintWithVesting(msg.sender, vokenRandom, address(this));
            VOKEN_TB.mintWithVesting(referrer, vokenRandom, address(this));
        }

        _vokenIssued = _vokenIssued.add(vokenIssued);
        _accounts[msg.sender].issued = _accounts[msg.sender].issued.add(vokenIssued);
        
        // Issued + Random
        VOKEN_TB.mintWithVesting(msg.sender, vokenIssued.add(vokenRandom), address(this));

        // Payment Event
        emit Payment(msg.sender, daiAmount, vokenIssued, vokenRandom);
    }

    function etherUSDPrice()
        public
        view
        returns (uint256)
    {
        return UniswapV2Router02.getAmountsOut(1_000_000, _pathETH2DAI())[1];
    }

    function _swapExactETH2DAI(uint256 etherAmount)
        private
        returns (uint256)
    {
        uint256[] memory _result = UniswapV2Router02.swapExactETHForTokens{value: etherAmount}(0, _pathETH2DAI(), address(this), block.timestamp + 1 days);
        return _result[1];
    }

    function _pathETH2DAI()
        private
        view
        returns (address[] memory)
    {
        address[] memory path = new address[](2);
        path[0] = UniswapV2Router02.WETH();
        path[1] = address(DAI);
        return path;
    }
}