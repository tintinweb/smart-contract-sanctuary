// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
import "./SLDInterfaces.sol";

interface Formula {
    function getMargin(
        uint256 amount,
        uint256 openPrice,
        uint256 poolType
    ) external view returns (uint256 marginFee, uint256 liquidateFee);
}

contract SLDPublicPool is ISLDLiquidityPool, Ownable, BEP20 {
    uint256 internal constant PRICE_DECIMALS = 1e18;
    uint256 public appendRate = (70 * 1e18) / 100; // Margin append rate

    address public tokenAddress; // Fiat token address
    uint256 public minMintAmount = 1e18;

    uint256 public lockupPeriod = 14 days; // Lock period: 14 Days

    LiquidityMarket[] public lockedLiquidity; //Market Order

    P1AmountInfo public plAmountInfo;

    mapping(address => bool) public addressExist;

    mapping(address => uint256) public lastProvideTm; // Latest provide time, using for calculate lock period
    mapping(address => uint256) public lpAccount;
    mapping(address => uint256) public addressIndex;
    mapping(uint256 => uint256) public matchIds;

    Formula public formula; // Formula contract address

    address public riskFundAddr;
    address public keeper;
    address public lp2Keeper;

    // Function selectors for BEP20
    bytes4 private constant SELECTOR_TRANSFER_FROM =
        bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));
    bytes4 private constant SELECTOR_TRANSFER =
        bytes4(keccak256(bytes("transfer(address,uint256)")));

    modifier onlyKeeeper() {
        require(keeper == msg.sender, "caller not keeper");
        _;
    }
    modifier onlyLP2Keeeper() {
        require(lp2Keeper == msg.sender, "caller not lp2keeper");
        _;
    }

    /**
     * @dev Contract constructor.
     * @param _name Public pool token name. (e.g. Shield reDAI Token)
     * @param _symbol Public pool token symbol. (e.g. reDAI)
     * @param _riskFundAddr Risk fund address.
     * @param _tokenAddress Fiat token address(DAI/USDT/USDC).
     * @param _formula Formula contract address.
     */
    constructor(
        string memory _name,
        string memory _symbol,
        address _riskFundAddr,
        address _tokenAddress,
        address _formula
    ) public BEP20(_name, _symbol) {
        riskFundAddr = _riskFundAddr;
        tokenAddress = _tokenAddress;
        formula = Formula(_formula);
    }

    /**
     * @dev Provide liquidity to public pool.
     * @param _mintAmount Amount of fiat token to provide.
     */
    function provide(uint256 _mintAmount) public {
        require(_mintAmount >= minMintAmount, "Mint Amount is too small");

        lastProvideTm[msg.sender] = block.timestamp;

        _safeTransferFrom(tokenAddress, msg.sender, address(this), _mintAmount);

        uint256 reDaitokenAmount = getMintReDaiAmount(_mintAmount);
        lpAccount[msg.sender] = lpAccount[msg.sender].add(reDaitokenAmount);
        _mint(msg.sender, reDaitokenAmount);

        P1AmountInfo storage pl1AmountInfo = plAmountInfo;
        pl1AmountInfo.plDepositTotal = pl1AmountInfo.plDepositTotal.add(
            _mintAmount
        );
        pl1AmountInfo.pl1AvailAmount = pl1AmountInfo.pl1AvailAmount.add(
            _mintAmount
        );

        emit Provide(msg.sender, _mintAmount, reDaitokenAmount);
    }

    /**
     * @dev Withdraw liquidity from public pool.
     * @param _reTokenAmount Amount of fiat token to withdraw.
     */
    function withdraw(uint256 _reTokenAmount)
        public
        returns (uint256 _reAmount)
    {
        require(
            lastProvideTm[msg.sender].add(lockupPeriod) <= block.timestamp,
            "Withdraw is locked up"
        );
        require(_reTokenAmount > 0, "Pool: Amount is too small");
        require(
            _reTokenAmount <= lpAccount[msg.sender],
            "Pool:Please lower the amount."
        );

        _reAmount = getTokenAmountByreToken(_reTokenAmount);
        P1AmountInfo storage pl1AmountInfo = plAmountInfo;
        require(
            pl1AmountInfo.pl1AvailAmount >= _reAmount,
            "Pool1:availabe amount not enough"
        );

        _burn(msg.sender, _reTokenAmount);
        _safeTransfer(tokenAddress, msg.sender, _reAmount);

        emit Withdraw(msg.sender, _reAmount);

        pl1AmountInfo.plDepositTotal = pl1AmountInfo.plDepositTotal.sub(
            _reAmount
        );
        pl1AmountInfo.pl1AvailAmount = pl1AmountInfo.pl1AvailAmount.sub(
            _reAmount
        );
        lpAccount[msg.sender] = lpAccount[msg.sender].sub(_reTokenAmount);
    }

    /**
     * @dev Match taker's order with public pool.
     * @param _id Order id.
     * @param _marginAmount Margin amount.
     * @param _marginFee Margin fee amount.
     */
    function lock(
        uint256 _id,
        uint256 _marginAmount,
        uint256 _marginFee
    ) public onlyKeeeper returns (bool) {
        // Reject take order if amount exceed public pool's liquidity
        P1AmountInfo storage pl1AmountInfo = plAmountInfo;
        require(
            _marginAmount.add(_marginFee) < pl1AmountInfo.pl1AvailAmount,
            "lp1 amount is not enought"
        );

        matchIds[_id] = lockedLiquidity.length + 1;

        lockedLiquidity.push(
            LiquidityMarket(
                _id,
                _marginAmount,
                _marginFee,
                uint256(PoolFlag.PUBLIC),
                0,
                address(this),
                true
            )
        );

        pl1AmountInfo.pl1lockedAmount = pl1AmountInfo.pl1lockedAmount.add(
            _marginAmount.add(_marginFee)
        );
        pl1AmountInfo.pl1AvailAmount = pl1AmountInfo.pl1AvailAmount.sub(
            _marginAmount.add(_marginFee)
        );

        emit LockInPublicPool(
            _id,
            lockedLiquidity.length,
            _marginAmount,
            _marginFee
        );

        emit BalanceofPublic(
            pl1AmountInfo.plDepositTotal,
            pl1AmountInfo.pl1lockedAmount,
            pl1AmountInfo.pl1AvailAmount
        );

        return true;
    }

    /**
     * @dev Move private pool's order into public pool when the corresponding maker order is forced closed.
     * @param _orderID Taker's order id.
     * @param _profit Order profit.
     * @param _moveProfit Profit move from private pool.
     * @param _number Order amount.
     * @param _openPrice Open price of this order.
     * @param _movePrice Move price of this order.
     */
    function moveLp1Fund(
        uint256 _orderID,
        uint256 _profit,
        uint256 _moveProfit,
        uint256 _number,
        uint256 _openPrice,
        uint256 _movePrice
    ) public onlyLP2Keeeper returns (bool) {
        P1AmountInfo storage pl1AmountInfo = plAmountInfo;
        if (_profit > pl1AmountInfo.pl1AvailAmount.add(_moveProfit)) {
            return false;
        }

        (uint256 marginAmount, uint256 marginFee) = getLockedAmount(
            _number,
            _openPrice,
            1
        );

        if (
            pl1AmountInfo.pl1AvailAmount.add(_moveProfit) <
            marginAmount.add(marginFee)
        ) {
            return false;
        }

        matchIds[_orderID] = lockedLiquidity.length + 1;
        lockedLiquidity.push(
            LiquidityMarket(
                _orderID,
                marginAmount,
                marginFee,
                uint256(PoolFlag.PUBLIC),
                _movePrice,
                address(this),
                true
            )
        );

        pl1AmountInfo.plDepositTotal = pl1AmountInfo.plDepositTotal.add(
            _moveProfit
        );
        pl1AmountInfo.pl1lockedAmount = pl1AmountInfo.pl1lockedAmount.add(
            marginAmount.add(marginFee)
        );
        pl1AmountInfo.pl1AvailAmount = pl1AmountInfo
            .pl1AvailAmount
            .add(_moveProfit)
            .sub(marginAmount.add(marginFee));

        emit MoveToPublic(
            _orderID,
            _profit,
            _moveProfit,
            _openPrice,
            _movePrice
        );

        emit BalanceofPublic(
            pl1AmountInfo.plDepositTotal,
            pl1AmountInfo.pl1lockedAmount,
            pl1AmountInfo.pl1AvailAmount
        );

        return true;
    }

    /**
     * @dev Close an order taken by public pool.
     * @param _id Taker's order id.
     * @param _profit Order's profit
     * @param _fundingFee Order's funding fee.
     */
    function close(
        uint256 _id,
        uint256 _profit,
        uint256 _fundingFee
    ) public onlyKeeeper returns (uint256 _userProfit, bool _isAgreement) {
        // move funding fee to lps user
        uint256 lpId = matchIds[_id] - 1;
        lockedLiquidity[lpId].locked = false;

        P1AmountInfo storage pl1AmountInfo = plAmountInfo;
        uint256 pl1D = pl1AmountInfo.plDepositTotal.add(_fundingFee);
        uint256 pl1A = pl1AmountInfo.pl1AvailAmount.add(_fundingFee);
        uint256 marginAmount = lockedLiquidity[lpId].marginAmount;
        uint256 marginFee = lockedLiquidity[lpId].marginFee;

        if (_profit > 0) {
            if (marginAmount >= _profit) {
                _userProfit = _profit;

                pl1D = pl1D.sub(_userProfit);
                pl1A = pl1A.add(marginFee).add(marginAmount.sub(_userProfit));
            } else if (marginAmount.add(marginFee) >= _profit) {
                // Force close
                _userProfit = _profit;

                uint256 riskFundAmount = marginAmount.add(marginFee).sub(
                    _profit
                );

                pl1D = pl1D.sub(marginAmount.add(marginFee));

                _safeTransfer(tokenAddress, riskFundAddr, riskFundAmount);
            } else {
                uint256 fixAmount = _profit.sub(marginAmount.add(marginFee));
                if (pl1A >= fixAmount) {
                    _userProfit = _profit;

                    pl1D = pl1D.sub(fixAmount).sub(marginAmount.add(marginFee));
                    pl1A = pl1A.sub(fixAmount);
                } else {
                    uint256 newFixAmount = fixAmount.sub(pl1A);
                    uint256 riskFund = getRiskFundAmount();
                    if (riskFund >= newFixAmount) {
                        _userProfit = _profit;

                        _safeTransferFrom(
                            tokenAddress,
                            riskFundAddr,
                            address(this),
                            newFixAmount
                        );
                        riskFund = riskFund.sub(newFixAmount);
                    } else {
                        // Agreement liquidation
                        _userProfit = marginAmount.add(marginFee).add(pl1A).add(
                                riskFund
                            );

                        _safeTransferFrom(
                            tokenAddress,
                            riskFundAddr,
                            address(this),
                            riskFund
                        );
                        riskFund = 0;
                        _isAgreement = true;
                    }

                    pl1D = pl1D.sub(marginAmount.add(marginFee)).sub(pl1A);
                    pl1A = 0;
                }
            }
        } else {
            pl1A = pl1A.add(marginAmount.add(marginFee));
        }

        pl1AmountInfo.plDepositTotal = pl1D;
        pl1AmountInfo.pl1lockedAmount = pl1AmountInfo.pl1lockedAmount.sub(
            marginAmount.add(marginFee)
        );
        pl1AmountInfo.pl1AvailAmount = pl1A;

        _safeTransferFrom(tokenAddress, msg.sender, address(this), _fundingFee);
        _safeTransfer(tokenAddress, msg.sender, _userProfit);

        emit CloseInPublicPool(lpId, _id, _userProfit);

        emit BalanceofPublic(pl1D, pl1AmountInfo.pl1lockedAmount, pl1A);
    }

    /**
     * @dev Trigger risk control.
     * @param _id The order id need to be risk controlled.
     * @param _profit Order profit.
     * @param _fundingFee Order's funding fee.
     */
    function riskClose(
        uint256 _id,
        uint256 _profit,
        uint256 _fundingFee
    )
        public
        onlyKeeeper
        returns (
            bool _flag,
            uint256 _userProfit,
            bool _isAgreement
        )
    {
        // When the order has made profits and the available balance from public pool is not enough,
        // pay taker with the assets in risk fund address.
        uint256 lpId = matchIds[_id] - 1;
        P1AmountInfo storage pl1AmountInfo = plAmountInfo;
        uint256 pl1D = pl1AmountInfo.plDepositTotal;
        uint256 pl1L = pl1AmountInfo.pl1lockedAmount;
        uint256 pl1A = pl1AmountInfo.pl1AvailAmount;
        uint256 marginAmount = lockedLiquidity[lpId].marginAmount;

        if (_profit > marginAmount.mul(appendRate).div(PRICE_DECIMALS)) {
            if (
                plAmountInfo.pl1AvailAmount >= _profit.mul(2).sub(marginAmount)
            ) {
                pl1A = pl1A.sub(_profit.mul(2).sub(marginAmount));
                pl1L = pl1L.add(_profit.mul(2).sub(marginAmount));
                lockedLiquidity[lpId].marginAmount = _profit.mul(2);
                pl1AmountInfo.pl1lockedAmount = pl1L;
                pl1AmountInfo.pl1AvailAmount = pl1A;
                return (false, 0, false);
            } else {
                // Append margin failed, use fund in availble amount
                pl1L = pl1L.add(pl1A);
                lockedLiquidity[lpId].marginAmount = marginAmount.add(pl1A);
                pl1A = 0;
            }
        }

        if (_profit > lockedLiquidity[lpId].marginAmount) {
            lockedLiquidity[lpId].locked = false;
            _flag = true;
            marginAmount = lockedLiquidity[lpId].marginAmount;
            uint256 marginFee = lockedLiquidity[lpId].marginFee;
            pl1D = pl1D.add(_fundingFee);
            pl1A = pl1A.add(_fundingFee);
            if (marginAmount.add(marginFee) >= _profit) {
                // Force liquidation
                _userProfit = _profit;
                // riskFund
                uint256 riskFundAmount = marginAmount.add(marginFee).sub(
                    _profit
                );

                pl1D = pl1D.sub(marginAmount.add(marginFee));

                _safeTransfer(tokenAddress, riskFundAddr, riskFundAmount);
            } else {
                uint256 fixAmount = _profit.sub(marginAmount.add(marginFee));
                if (pl1A >= fixAmount) {
                    _userProfit = _profit;

                    pl1D = pl1D.sub(fixAmount).sub(marginAmount.add(marginFee));
                    pl1A = pl1A.sub(fixAmount);
                } else {
                    uint256 newFixAmount = fixAmount.sub(pl1A);
                    uint256 riskFund = getRiskFundAmount();
                    if (riskFund >= newFixAmount) {
                        _userProfit = _profit;

                        _safeTransferFrom(
                            tokenAddress,
                            riskFundAddr,
                            address(this),
                            newFixAmount
                        );
                    } else {
                        // Agreement liquidation
                        _userProfit = marginAmount.add(marginFee).add(pl1A).add(
                                riskFund
                            );

                        _safeTransferFrom(
                            tokenAddress,
                            riskFundAddr,
                            address(this),
                            riskFund
                        );
                        _isAgreement = true;
                    }
                    pl1D = pl1D.sub(marginAmount.add(marginFee)).sub(pl1A);
                    pl1A = 0;
                }
            }
            pl1L = pl1L.sub(marginAmount.add(marginFee));

            _safeTransferFrom(
                tokenAddress,
                msg.sender,
                address(this),
                _fundingFee
            );
            _safeTransfer(tokenAddress, msg.sender, _userProfit);
        }

        pl1AmountInfo.plDepositTotal = pl1D;
        pl1AmountInfo.pl1lockedAmount = pl1L;
        pl1AmountInfo.pl1AvailAmount = pl1A;

        emit RiskInPubicPool(lpId, _id, _userProfit);

        emit BalanceofPublic(pl1D, pl1L, pl1A);
    }

    function setLockupPeriod(uint256 _period) public onlyOwner {
        lockupPeriod = _period;
    }

    function setAppendRate(uint256 _appendRate) public onlyOwner {
        require(_appendRate > 0, "INVALID");
        appendRate = _appendRate;
    }

    function totalBalance() public view override returns (uint256 amount) {
        return balanceOf(address(this));
    }

    function getTotalSupply() public view returns (uint256 amount) {
        return totalSupply();
    }

    function getLockedAmount(
        uint256 _amount,
        uint256 _currentPrice,
        uint256 _poolType
    ) public view returns (uint256 marginFee, uint256 forceFee) {
        (marginFee, forceFee) = formula.getMargin(
            _amount,
            _currentPrice,
            _poolType
        );
    }

    function getMintReDaiAmount(uint256 _mintAmount)
        public
        view
        returns (uint256 mintOtoken)
    {
        require(_mintAmount > 0, "mintAmount is zero");

        if (getTotalSupply() == 0 || plAmountInfo.plDepositTotal == 0) {
            mintOtoken = _mintAmount;
        } else {
            mintOtoken = getTotalSupply().mul(_mintAmount).div(
                plAmountInfo.plDepositTotal
            );
        }
    }

    function getTokenAmountByreToken(uint256 _reTokenAmount)
        public
        view
        returns (uint256 tokenAmount)
    {
        require(_reTokenAmount > 0, "reTokenAmount is zero");
        tokenAmount = _reTokenAmount.mul(plAmountInfo.plDepositTotal).div(
            getTotalSupply()
        );
        if (tokenAmount == 0) {
            //TODO DDS need to return;need to do
            revert();
        }
    }

    function getReTokenAmountByToken(uint256 _tokenAmount)
        public
        view
        returns (uint256 retokenAmount)
    {
        require(_tokenAmount > 0, "reTokenAmount is zero");
        retokenAmount = _tokenAmount.mul(getTotalSupply()).div(
            plAmountInfo.plDepositTotal
        );
        if (retokenAmount == 0) {
            revert();
        }
    }

    function getMatchID(uint256 _orderID)
        public
        view
        returns (
            uint256 lpID /*,uint256 lpFlag*/
        )
    {
        if (matchIds[_orderID] == 0) {
            return (0);
        } else {
            lpID = matchIds[_orderID] - 1;
        }
    }

    function getMarginAmount(uint256 _orderID)
        public
        view
        returns (uint256 marginAmount, uint256 marginFee)
    {
        if (matchIds[_orderID] == 0) {
            return (0, 0);
        } else {
            uint256 lpID = matchIds[_orderID] - 1;
            marginAmount = lockedLiquidity[lpID].marginAmount;
            marginFee = lockedLiquidity[lpID].marginFee;
        }
    }

    function getlockedLiquidityLen() public view returns (uint256 lpLen) {
        lpLen = lockedLiquidity.length;
    }

    function getLP2ToLp1MovePrice(uint256 _takerOrderId)
        public
        view
        returns (bool, uint256)
    {
        uint256 lpID = matchIds[_takerOrderId] - 1;
        uint256 changePrice = lockedLiquidity[lpID].changePrice;
        if (changePrice > 0) {
            return (true, changePrice);
        } else {
            return (false, 0);
        }
    }

    function getRiskFundAmount() public view returns (uint256) {
        return IBEP20(tokenAddress).balanceOf(riskFundAddr);
    }

    function getLPAmountInfo()
        public
        view
        returns (
            uint256 deposit,
            uint256 availabe,
            uint256 locked
        )
    {
        deposit = plAmountInfo.plDepositTotal;
        availabe = plAmountInfo.pl1AvailAmount;
        locked = plAmountInfo.pl1lockedAmount;
    }

    function getUserReTokenInfo(address addr)
        public
        view
        returns (uint256 selfReToken, uint256 total)
    {
        selfReToken = lpAccount[addr];
        total = getTotalSupply();
    }

    function _safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(SELECTOR_TRANSFER_FROM, from, to, value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function _safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(SELECTOR_TRANSFER, to, value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function isEqual(string memory a, string memory b)
        public
        pure
        returns (bool)
    {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    function setMinMintAmount(uint256 _minMintAmount) public onlyOwner {
        require(_minMintAmount > 0, "INVALID");
        minMintAmount = _minMintAmount;
    }

    function setFormula(address _formula) public onlyOwner {
        require(address(_formula) != address(0x0), "ADDRESS_ZERO");
        formula = Formula(_formula);
    }

    function setPoolTokenAddr(address _tokenAddr) public onlyOwner {
        require(_tokenAddr != address(0x0), "ADDRESS_ZERO");
        tokenAddress = _tokenAddr;
    }

    function setRiskFundAddr(address _riskFundAddr) public onlyOwner {
        require(_riskFundAddr != address(0x0), "ADDRESS_ZERO");
        riskFundAddr = _riskFundAddr;
    }

    function setKeeper(address _keeperAddr) public onlyOwner {
        require(_keeperAddr != address(0x0), "ADDRESS_ZERO");
        keeper = _keeperAddr;
    }

    function setLP2Keeper(address _lp2KeeperAddr) public onlyOwner {
        require(_lp2KeeperAddr != address(0x0), "ADDRESS_ZERO");
        lp2Keeper = _lp2KeeperAddr;
    }
}