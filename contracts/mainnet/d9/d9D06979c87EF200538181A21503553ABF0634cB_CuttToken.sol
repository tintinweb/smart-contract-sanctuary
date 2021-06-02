// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./ISwapRouter.sol";
import "./INonfungiblePositionManager.sol";

contract CuttToken is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcluded;
    mapping(address => bool) private _isExcludedFromMaxTxAmount;

    address[] private _excluded;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1000000000 * 10**6 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = "Cutt Token";
    string private _symbol = "CUTT";
    uint8 private _decimals = 9;

    uint256 public _taxFee = 5;
    uint256 private _previousTaxFee = _taxFee;

    uint256 public _liquidityFee = 5;
    uint256 private _previousLiquidityFee = _liquidityFee;

    uint256 public _liquidityPercent = 20;
    uint256 public _cuttiesPercent = 10;
    uint256 public _nftStakingPercent = 15;
    uint256 public _v3StakingPercent = 25;
    uint256 public _smartFarmingPercent = 25;
    uint256 public _treasuryPercent = 5;

    address public _liquidityAddress;
    address public _cuttiesAddress;
    address public _nftStakingAddress;
    address public _v3StakingAddress;
    address public _smartFarmingAddress;
    address public _treasuryAddress;

    bool public _liquidityLocked = false;
    bool public _cuttiesLocked = false;
    bool public _nftStakingLocked = false;
    bool public _v3StakingLocked = false;
    bool public _smartFarmingLocked = false;
    bool public _treasuryLocked = false;

    ISwapRouter public swapRouter;
    INonfungiblePositionManager public nonfungiblePositionManager;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;

    uint256 public _maxTxAmount = 5000000 * 10**6 * 10**9;
    uint256 private numTokensSellToAddToLiquidity = 500000 * 10**6 * 10**9;

    uint24 private _uniswapV3Fee = 500;
    int24 private _tickLower = -887270;
    int24 private _tickUpper = 887270;

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor() {
        swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
        nonfungiblePositionManager = INonfungiblePositionManager(
            0xC36442b4a4522E871399CD717aBDD847Ab11FE88
        );

        //exclude owner and this contract from fee
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromMaxTxAmount[address(this)] = true;

        _setExcludedAll(0xE592427A0AEce92De3Edee1F18E0157C05861564);
        _setExcludedAll(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function setSwapParam(
        uint24 fee,
        int24 tickLower,
        int24 tickUpper
    ) public onlyOwner {
        _uniswapV3Fee = fee;
        _tickLower = tickLower;
        _tickUpper = tickUpper;
    }

    function setTreasuryAddress(address treasuryAddress) public onlyOwner {
        _treasuryAddress = treasuryAddress;
        _setExcludedAll(_cuttiesAddress);
    }

    function setLiquidityAddress(address liquidityAddress) public onlyOwner {
        _liquidityAddress = liquidityAddress;
        _setExcludedAll(_cuttiesAddress);
    }

    function setNFTStakingAddress(address nftStakingAddress) public onlyOwner {
        _nftStakingAddress = nftStakingAddress;
        _setExcludedAll(_nftStakingAddress);
    }

    function setV3StakingAddress(address v3StakingAddress) public onlyOwner {
        _v3StakingAddress = v3StakingAddress;
        _setExcludedAll(_v3StakingAddress);
    }

    function setSmartFarmingAddress(address farmingAddress) public onlyOwner {
        _smartFarmingAddress = farmingAddress;
        _setExcludedAll(_smartFarmingAddress);
    }

    function setPoolAddress(address poolAddress) external {
        require(_msgSender() == _liquidityAddress);
        _setExcludedAll(poolAddress);
    }

    function setCuttiesAddress(address cuttiesAddress) public onlyOwner {
        _cuttiesAddress = cuttiesAddress;
        _setExcludedAll(_cuttiesAddress);
    }

    function _setExcludedAll(address settingAddress) private {
        _isExcludedFromFee[settingAddress] = true;
        _isExcluded[settingAddress] = true;
        _isExcludedFromMaxTxAmount[settingAddress] = true;
    }

    function mintTreasuryToken() external {
        require(_msgSender() == _treasuryAddress);
        require(!_treasuryLocked);

        _mint(_treasuryAddress, _treasuryPercent);
        _treasuryLocked = true;
    }

    function mintLiquidityToken() external {
        require(_msgSender() == _liquidityAddress);
        require(!_liquidityLocked);

        _mint(_liquidityAddress, _liquidityPercent);
        _liquidityLocked = true;
    }

    function mintNFTStakingToken() external {
        require(_msgSender() == _nftStakingAddress);
        require(!_nftStakingLocked);

        _mint(_nftStakingAddress, _nftStakingPercent);
        _nftStakingLocked = true;
    }

    function mintV3StakingToken() external {
        require(_msgSender() == _v3StakingAddress);
        require(!_v3StakingLocked);

        _mint(_v3StakingAddress, _v3StakingPercent);
        _v3StakingLocked = true;
    }

    function mintSmartFarmingToken() external {
        require(_msgSender() == _smartFarmingAddress);
        require(!_smartFarmingLocked);

        _mint(_smartFarmingAddress, _smartFarmingPercent);
        _smartFarmingLocked = true;
    }

    function mintCuttiesToken() external {
        require(_msgSender() == _cuttiesAddress);
        require(!_cuttiesLocked);

        _mint(_cuttiesAddress, _cuttiesPercent);
        _cuttiesLocked = true;
    }

    function _mint(address to, uint256 percent) private {
        uint256 tAmount = _tTotal.div(10**2).mul(percent);
        uint256 rAmount = _rTotal.div(10**2).mul(percent);

        _tOwned[to] = _tOwned[to].add(tAmount);
        _rOwned[to] = _rOwned[to].add(rAmount);
        emit Transfer(address(0), to, tAmount);
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(
            !_isExcluded[sender],
            "Excluded addresses cannot call this function"
        );
        (uint256 rAmount, , , , , ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee)
        public
        view
        returns (uint256)
    {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount, , , , , ) = _getValues(tAmount);
            return rAmount;
        } else {
            (, uint256 rTransferAmount, , , , ) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount)
        public
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function _transferBothExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function excludeFromMaxTxAmount(address account) public onlyOwner {
        _isExcludedFromMaxTxAmount[account] = true;
    }

    function includeInMaxTxAmount(address account) public onlyOwner {
        _isExcludedFromMaxTxAmount[account] = false;
    }

    function setTaxFeePercent(uint256 taxFee) external onlyOwner() {
        _taxFee = taxFee;
    }

    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner() {
        _liquidityFee = liquidityFee;
    }

    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(10**2);
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) =
            _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) =
            _getRValues(tAmount, tFee, tLiquidity, _getRate());
        return (
            rAmount,
            rTransferAmount,
            rFee,
            tTransferAmount,
            tFee,
            tLiquidity
        );
    }

    function _getTValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);
        return (tTransferAmount, tFee, tLiquidity);
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 tLiquidity,
        uint256 currentRate
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _rOwned[_excluded[i]] > rSupply ||
                _tOwned[_excluded[i]] > tSupply
            ) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate = _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if (_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(10**2);
    }

    function calculateLiquidityFee(uint256 _amount)
        private
        view
        returns (uint256)
    {
        return _amount.mul(_liquidityFee).div(10**2);
    }

    function removeAllFee() private {
        if (_taxFee == 0 && _liquidityFee == 0) return;

        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;

        _taxFee = 0;
        _liquidityFee = 0;
    }

    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function isExcludedFromMaxTxAmount(address account)
        public
        view
        returns (bool)
    {
        return _isExcludedFromMaxTxAmount[account];
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if (
            !_isExcludedFromMaxTxAmount[from] && !_isExcludedFromMaxTxAmount[to]
        )
            require(
                amount <= _maxTxAmount,
                "Transfer amount exceeds the maxTxAmount."
            );

        uint256 contractTokenBalance = balanceOf(address(this));

        if (contractTokenBalance >= _maxTxAmount) {
            contractTokenBalance = _maxTxAmount;
        }

        bool overMinTokenBalance =
            contractTokenBalance >= numTokensSellToAddToLiquidity;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != address(swapRouter) &&
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance = numTokensSellToAddToLiquidity;

            swapAndLiquify(contractTokenBalance);
        }

        bool takeFee = true;

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        _tokenTransfer(from, to, amount, takeFee);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        uint256 initialBalance =
            IERC20(nonfungiblePositionManager.WETH9()).balanceOf(address(this));

        swapTokensForEth(half);

        uint256 newBalance =
            IERC20(nonfungiblePositionManager.WETH9())
                .balanceOf(address(this))
                .sub(initialBalance);

        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        ISwapRouter.ExactInputSingleParams memory data =
            ISwapRouter.ExactInputSingleParams(
                address(this),
                nonfungiblePositionManager.WETH9(),
                500,
                address(this),
                (uint256)(block.timestamp).add(1000),
                tokenAmount,
                0,
                0
            );

        _approve(address(this), address(swapRouter), tokenAmount);

        swapRouter.exactInputSingle(data);
    }

    function getTokens() private view returns (address token0, address token1) {
        token0 = (nonfungiblePositionManager.WETH9() < address(this))
            ? nonfungiblePositionManager.WETH9()
            : address(this);
        token1 = (nonfungiblePositionManager.WETH9() > address(this))
            ? nonfungiblePositionManager.WETH9()
            : address(this);
    }

    function getTokenBalances(uint256 tokenAmount, uint256 ethAmount)
        private
        view
        returns (uint256 balance0, uint256 balance1)
    {
        balance0 = (nonfungiblePositionManager.WETH9() < address(this))
            ? ethAmount
            : tokenAmount;
        balance1 = (nonfungiblePositionManager.WETH9() > address(this))
            ? ethAmount
            : tokenAmount;
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        (address token0, address token1) = getTokens();
        (uint256 balance0, uint256 balance1) =
            getTokenBalances(tokenAmount, ethAmount);

        _approve(
            address(this),
            address(nonfungiblePositionManager),
            tokenAmount
        );
        IERC20(nonfungiblePositionManager.WETH9()).approve(
            address(nonfungiblePositionManager),
            ethAmount
        );

        INonfungiblePositionManager.MintParams memory data =
            INonfungiblePositionManager.MintParams(
                token0,
                token1,
                _uniswapV3Fee,
                _tickLower,
                _tickUpper,
                balance0,
                balance1,
                0,
                0,
                _cuttiesAddress,
                (uint256)(block.timestamp).add(1000)
            );

        nonfungiblePositionManager.mint(data);
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) removeAllFee();

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }

        if (!takeFee) restoreAllFee();
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function burn(uint256 amount) public returns (bool) {
        uint256 tAmount = amount;
        if (_isExcluded[_msgSender()]) {
            if (tAmount >= _tOwned[_msgSender()]) {
                tAmount = _tOwned[_msgSender()];
            }

            uint256 rAmount = tAmount.mul(_getRate());
            _tOwned[_msgSender()] = _tOwned[_msgSender()].sub(tAmount);
            _rOwned[_msgSender()] = _rOwned[_msgSender()].sub(rAmount);
            _tTotal = _tTotal.sub(tAmount);
            _rTotal = _rTotal.sub(rAmount);
        } else {
            uint256 rAmount = tAmount.mul(_getRate());
            if (rAmount >= _rOwned[_msgSender()]) {
                rAmount = _rOwned[_msgSender()];
            }
            _rOwned[_msgSender()] = _rOwned[_msgSender()].sub(rAmount);
            _tTotal = _tTotal.sub(tAmount);
            _rTotal = _rTotal.sub(rAmount);
        }
        return true;
    }
}