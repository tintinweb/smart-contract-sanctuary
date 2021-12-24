// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import './IERC20.sol';
import './IUniswapV2Pair.sol';

import './Ownable.sol';
import './SafeMath.sol';
import './ERC20.sol';
import './Math.sol';

interface ITreasury {
    function deposit(
        uint256 _amount,
        address _token,
        uint256 _profit
    ) external returns (uint256 send_);

    function valueOfToken(address _token, uint256 _amount)
        external
        view
        returns (uint256 value_);
}

interface IStaking {
    function stake(uint256 _amount, address _recipient) external returns (bool);
}

contract NekoDaoIDO is Ownable, ERC20 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public NEKO;
    address public MIM = 0x130966628846BFd36ff31a822705796e8cb8C18D;
    address public addressToSendMIM;
    address public mimNekoLP;
    address public staking;

    uint256 public totalAmount;
    uint256 public salePrice;
    uint256 public openPrice;
    uint256 public totalWhiteListed;
    uint256 public startOfSale;
    uint256 public endOfSale;
    uint256 public maxAllotment = 40 * 1e9;

    bool public initialized;
    bool public whiteListEnabled;
    bool public cancelled;
    bool public finalized;

    mapping(address => bool) public boughtNEKO;
    mapping(address => bool) public whiteListed;

    address[] buyers;
    mapping(address => uint256) public purchasedAmounts;

    address treasury;

    constructor(uint256 initialSupply) ERC20("Neko Dao", "NEKO") {
        
        cancelled = false;
        finalized = false;

        _mint(msg.sender, initialSupply);
    }

    function saleStarted() public view returns (bool) {
        return initialized && startOfSale <= block.timestamp;
    }

    function whiteListBuyers(address[] memory _buyers)
        external
        onlyOwner
        returns (bool)
    {
        //require(saleStarted() == false, 'Already started');

        totalWhiteListed = totalWhiteListed.add(_buyers.length);

        for (uint256 i; i < _buyers.length; i++) {
            whiteListed[_buyers[i]] = true;
        }

        return true;
    }

    function initialize(
        uint256 _totalAmount,
        uint256 _salePrice,
        uint256 _saleLength,
        uint256 _startOfSale
    ) external onlyOwner returns (bool) {
        require(initialized == false, 'Already initialized');
        initialized = true;
        whiteListEnabled = true;
        totalAmount = _totalAmount;
        salePrice = _salePrice;
        startOfSale = _startOfSale;
        endOfSale = _startOfSale.add(_saleLength);
        return true;
    }

    function setAllotment(uint256 allotment) public onlyOwner {
        maxAllotment = allotment;
    }

    function setStaking(address _staking) public onlyOwner {
        staking = _staking;
    }

    function getAllotmentPerBuyer() public view returns (uint256) {
        if (whiteListEnabled) {
            return maxAllotment;
        } else {
            return Math.min(80 * 1e9, totalAmount);
        }
    }

    function purchaseNEKO(uint256 _amountMIM) external returns (bool) {
        require(saleStarted() == true, 'Not started');
        require(
            !whiteListEnabled || whiteListed[msg.sender] == true,
            'Not whitelisted'
        );
        //require(boughtNEKO[msg.sender] == false, 'Already participated');

        //boughtNEKO[msg.sender] = true;

        uint256 _purchaseAmount = _calculateSaleQuote(_amountMIM);

        require(_purchaseAmount <= (getAllotmentPerBuyer() - purchasedAmounts[msg.sender]), 'More than alloted');
        //if (whiteListEnabled) {
        //    totalWhiteListed = totalWhiteListed.sub(1);
        //}

        totalAmount = totalAmount.sub(_purchaseAmount);

        purchasedAmounts[msg.sender] = purchasedAmounts[msg.sender] + _purchaseAmount;
        //buyers.push(msg.sender);

        IERC20(MIM).safeTransferFrom(msg.sender, address(this), _amountMIM);

        return true;
    }

    function disableWhiteList() external onlyOwner {
        whiteListEnabled = false;
    }

    function _calculateSaleQuote(uint256 paymentAmount_)
        internal
        view
        returns (uint256)
    {
        return uint256(1e9).mul(paymentAmount_).div(salePrice);
    }

    function calculateSaleQuote(uint256 paymentAmount_)
        external
        view
        returns (uint256)
    {
        return _calculateSaleQuote(paymentAmount_);
    }

    /// @dev Only Emergency Use
    /// cancel the IDO and return the funds to all buyer
    function cancel() external onlyOwner {

        
        initialized = false;
        cancelled = true;
        startOfSale = 99999999999;
    }

    function withdraw() external {
        require(cancelled, 'ido is not cancelled');
        uint256 amount = purchasedAmounts[msg.sender];
        IERC20(MIM).transfer(msg.sender, (amount / 1e9) * salePrice);
    }

    function claim(address _recipient) public {
        require(finalized, 'only can claim after finalized');
        require(purchasedAmounts[_recipient] > 0, 'not purchased');
        IStaking(staking).stake(purchasedAmounts[_recipient], _recipient);
        purchasedAmounts[_recipient] = 0;
    }


    function finalize(address _receipt, uint256 amt) external onlyOwner {
        //require(totalAmount == 0, 'need all NEKOs to be sold');

        //require(nekoMinted == 250000 * 1e9);

        /** dev: create lp with 25 MIM per NEKO
        IERC20(MIM).transfer(mimNekoLP, 500000 * 1e18);
        IERC20(NEKO).transfer(mimNekoLP, 15000 * 1e9);
        uint256 lpBalance = IUniswapV2Pair(mimNekoLP).mint(address(this));
        uint256 valueOfToken = ITreasury(treasury).valueOfToken(
            mimNekoLP,
            lpBalance
        );

        IUniswapV2Pair(mimNekoLP).approve(treasury, lpBalance);
        uint256 zeroMinted = ITreasury(treasury).deposit(
            lpBalance,
            mimNekoLP,
            valueOfToken
        );
        require(zeroMinted == 0, 'should not mint any NEKO');
        IERC20(NEKO).approve(staking, nekoMinted); **/

        IERC20(MIM).transfer(_receipt, amt * 1e18);

        finalized = true;

        //claim(_receipt);
    }
}