// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./FotToken.sol";
import "./StandardToken.sol";

contract CloneFactory {
    function createClone(address target)
        internal
        returns (address payable result)
    {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(
                clone,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(clone, 0x14), targetBytes)
            mstore(
                add(clone, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            result := create(0, clone, 0x37)
        }
    }

    function isClone(address target, address query)
        internal
        view
        returns (bool result)
    {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(
                clone,
                0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000
            )
            mstore(add(clone, 0xa), targetBytes)
            mstore(
                add(clone, 0x1e),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )

            let other := add(clone, 0x40)
            extcodecopy(query, other, 0, 0x2d)
            result := and(
                eq(mload(clone), mload(other)),
                eq(mload(add(clone, 0xd)), mload(add(other, 0xd)))
            )
        }
    }
}

contract TokenFactory is CloneFactory {
    address payable private standardMasterContract;
    address payable private fotMasterContract;
    event FotTokenCreated(address id, string name, string symbol, uint256 basicSupply, string tokenType, address newTokenAddress);
    event StdTokenCreated(address id, string name, string symbol, uint256 basicSupply, string tokenType, bool isPool, address newTokenAddress);
    address payable public clone;
    constructor (address payable standardContractToClone, address payable fotContractToClone) {
        standardMasterContract = standardContractToClone;
        fotMasterContract = fotContractToClone;
    }
    function createToken(
        string memory name,
        string memory symbol,
        uint256 basicSupply,
        uint256 maxTxnAmount,
        uint256[4] memory fees,
        address charityAddress,
        address dexAddress
    ) public payable {
        clone = createClone(fotMasterContract);
        FotToken(clone).init(
            name,
            symbol,
            basicSupply,
            maxTxnAmount,
            fees,
            charityAddress,
            dexAddress,
            msg.sender
        );
        emit FotTokenCreated(msg.sender, name, symbol, basicSupply * (10**6), "fot",  clone);
    }

    function createStandardToken(
        string memory tokenName,
        string memory tokenSymbol,
        uint256 tokenInitialAmount,
        bool isPool,
        address dexAddress
    ) public payable {
        clone = createClone(standardMasterContract);
        StandardToken(clone).init(
            tokenName,
            tokenSymbol,
            tokenInitialAmount,
            msg.sender,
            isPool,
            dexAddress
        );
        emit StdTokenCreated(msg.sender, tokenName, tokenSymbol, tokenInitialAmount, "standard", isPool,  clone);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./StandardToken.sol";

/// @title an Initialized IERC20 Token
/// @author harshrpg
/// @notice It is the barebone of a FOT with an additional fee infrastructure
/// @dev Provide the appropriate init information for all the different fee types
contract FotToken is IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    string public _name;
    string private _symbol;
    uint256 private _totalTokenSupply;
    uint256 private _totalReflectionSupply;
    uint256 private _maxTxnAmount;
    uint256 private _taxFee;
    uint256 private _previousTaxFee;
    uint256 private _liquidityFee;
    uint256 private _previousLiquidityFee;
    uint256 private _charityFee;
    uint256 private _previousCharityFee;
    uint256 private _burnFee;
    uint256 private _previousBurnFee;
    uint256 private _totalFeeCharged;
    uint256 private _totalTokensBurned;
    uint256 private _totalCharityPaid;
    uint256 private _numTokensSellToAddToLiquidity;
    uint256 private _decimals;
    address private _charityAddress;

    mapping(address => uint256) _balance;
    mapping(address => uint256) _reflectionBalance;
    mapping(address => mapping(address => uint256)) _tokensAllowed;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcludedFromReward;
    address[] private _excludedAccounts;

    uint256 private constant MAX256 = ~uint256(0);

    IUniswapV2Router02 public router;
    address public pair;
    bool swapAndLiquifyEnabled = true;
    bool public inSwapAndLiquify;

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    event DexPairCreated(address thisContract, address pairAddress);

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    function init(
        string memory tokenName,
        string memory tokenSymbol,
        uint256 basicSupply,
        uint256 maxTxnAmount,
        uint256[4] memory fees,
        address charityAddress,
        address dexAddress,
        address newOwner
    ) public {
        uint256 _minTokenSellValue = 5;
        _decimals = 18;
        _name = tokenName;
        _symbol = tokenSymbol;
        _totalTokenSupply = basicSupply.mul(10**(_decimals)); // 1Q.10^9
        _totalReflectionSupply = (MAX256 - (MAX256 % _totalTokenSupply)); // Maximum possible number divisible by 1Q
        uint256 numMinTokensToSell = _minTokenSellValue.div(10**4).mul(basicSupply);
        _numTokensSellToAddToLiquidity =
            numMinTokensToSell.mul(10**(_decimals));
            // CHECK IF MAX TXN AMOUNT != 0
        _maxTxnAmount = maxTxnAmount.mul(10**(_decimals));
        transferOwnershipFromInitialized(newOwner);
        IUniswapV2Router02 _router = IUniswapV2Router02(dexAddress);
        pair = IUniswapV2Factory(_router.factory()).createPair(
            address(this),
            _router.WETH()
        );
        router = _router;
        _balance[newOwner] = _totalTokenSupply;
        _reflectionBalance[newOwner] = _totalReflectionSupply;
        _isExcludedFromFee[newOwner] = true;
        _isExcludedFromFee[address(this)] = true;
        _taxFee = fees[0];
        _liquidityFee = fees[1];
        _charityFee =  fees[3];
        _burnFee = fees[2];
        _charityAddress = charityAddress;
        emit DexPairCreated(address(this), pair);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function decimals() public view returns (uint256) {
        return _decimals;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalTokenSupply;
    }

    function pairAddress() public view returns (address) {
        return pair;
    }

    function amountOfNativeCoinsHeldByContract()
        external
        view
        
        returns (uint256)
    {
        return _balance[address(this)];
    }

    function burnTokens(uint256 amount) external  {
        _burn(_msgSender(), amount);
    }

    function _burn(address from, uint256 amount) private {
        _transfer(from, address(0), amount);
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcludedFromReward[account]) {
            return _balance[account];
        }
        return
            calculateTokenBalanceFromReflectionBalance(
                _reflectionBalance[account]
            );
    }

    function isExcludedFromReward(address account)
        external
        view
        returns (bool)
    {
        return _isExcludedFromReward[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        require(owner != spender, "Owner and spender cannot be the same");
        return _tokensAllowed[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        require(_balance[_msgSender()] >= amount, "Insufficient balance");
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address spender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(spender, recipient, amount);
        _approve(
            spender,
            _msgSender(),
            _tokensAllowed[spender][_msgSender()].sub(
                amount,
                "Transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _tokensAllowed[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _tokensAllowed[_msgSender()][spender].sub(
                subtractedValue,
                "Allowance below zero"
            )
        );
        return true;
    }

    function calculateReflectionBalanceFromTokenBalance(
        uint256 txnAmountRequested,
        bool deductTransferFee
    ) public view returns (uint256) {
        require(
            txnAmountRequested <= _totalTokenSupply,
            "Amount must be less than supply"
        );
        if (!deductTransferFee) {
            (
                ,
                ,
                ,
                ,
                ,
                uint256 reflections,
                ,

            ) = _calculateTransactionAndReflectionsAfterFees(
                    txnAmountRequested
                );
            return reflections;
        } else {
            (
                ,
                ,
                ,
                ,
                ,
                ,
                uint256 reflectionTransfer,

            ) = _calculateTransactionAndReflectionsAfterFees(
                    txnAmountRequested
                );
            return reflectionTransfer;
        }
    }

    function excludeFromReward(address account) public  {
        require(!_isExcludedFromReward[account], "Account is already excluded");
        if (_reflectionBalance[account] > 0) {
            _balance[account] = calculateTokenBalanceFromReflectionBalance(
                _reflectionBalance[account]
            );
        }
        _isExcludedFromReward[account] = true;
        _excludedAccounts.push(account);
    }

    function includeInReward(address account) public  {
        require(_isExcludedFromReward[account], "Account is already included");
        for (uint256 index = 0; index < _excludedAccounts.length; index++) {
            if (_excludedAccounts[index] == account) {
                _excludedAccounts[index] = _excludedAccounts[
                    _excludedAccounts.length - 1
                ];
                _balance[account] = 0;
                _isExcludedFromReward[account] = false;
                _excludedAccounts.pop();
                break;
            }
        }
    }

    function excludeFromFee(address account) external  {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) external  {
        _isExcludedFromFee[account] = false;
    }

    function setCharityAddress(address payable charityAddress)
        external
        
    {
        if (_charityFee > 0) {
            _charityAddress = charityAddress;
            _isExcludedFromFee[_charityAddress] = true;
        } else {
            _charityAddress = address(0);
        }
    }

    function setFees(uint256[] memory fees) external  {
        require(fees.length == 4, "Not enough elements in array");
        _taxFee = fees[0];
        _liquidityFee = fees[1];
        _charityFee =  fees[3];
        _burnFee = fees[2];
    }

    function setMaxTxAmount(uint256 maxTxnAmount) external  {
        _maxTxnAmount = maxTxnAmount.mul(10**_decimals);
    }

    function setSwapAndLiquifyEnabled(bool _enabled) external  {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function getAllFees() public view returns (uint256[4] memory) {
        uint256[4] memory fees = [
            _taxFee,
            _liquidityFee,
            _burnFee,
            _charityFee
        ];
        return fees;
    }

    function getAllFeesChargedBurnedAndCharitized()
        public
        view
        returns (uint256[3] memory)
    {
        uint256[3] memory feesCharged = [
            _totalFeeCharged,
            _totalTokensBurned,
            _totalCharityPaid
        ];
        return feesCharged;
    }

    function getCharityAddress() public view returns (address) {
        return _charityAddress;
    }

    function getWhaleProtection() public view returns (uint256) {
        return _maxTxnAmount;
    }

    // Private methods

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        if (_tokensAllowed[owner][spender] != 0) {
            _tokensAllowed[owner][spender] = 0;
        }
        _tokensAllowed[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != to, "Sender and recipient the same");
        if (from != owner() && to != owner() && _maxTxnAmount > 0) {
            require(
                amount <= _maxTxnAmount,
                "Transfer amount exceeds maximum transaction amount"
            );
        }
        // what is the contract's liquidity value?
        uint256 contractTokenBalance = balanceOf(address(this));
        if (
            contractTokenBalance >= _numTokensSellToAddToLiquidity &&
            !inSwapAndLiquify &&
            from != pair &&
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance = _numTokensSellToAddToLiquidity;
            swapAndLiquify(contractTokenBalance);
        }
        bool takeFee = true;
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }
        _transferTokens(from, to, amount, takeFee);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);
        uint256 initialEthBalance = address(this).balance;
        swapTokensForEth(half);
        uint256 newEthBalance = address(this).balance.sub(initialEthBalance);
        addLiquidity(otherHalf, newEthBalance);
        emit SwapAndLiquify(half, newEthBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokens) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokens);

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokens,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokens, uint256 eths) private {
        _approve(address(this), address(router), tokens);
        router.addLiquidityETH{value: eths}(
            address(this),
            tokens,
            0,
            0,
            owner(),
            block.timestamp
        );
    }

    function _transferTokens(
        address from,
        address to,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) {
            removeAllFee();
        }
        if (_isExcludedFromReward[from] && !_isExcludedFromReward[to]) {
            _transferFromExcludedAccount(from, to, amount);
        } else if (!_isExcludedFromReward[from] && _isExcludedFromReward[to]) {
            _transferToExcludedAccount(from, to, amount);
        } else if (_isExcludedFromReward[from] && _isExcludedFromReward[to]) {
            _transferBothExcludedAccount(from, to, amount);
        } else {
            _trasnferStandard(from, to, amount);
        }

        if (!takeFee) {
            restoreAllFees();
        }
    }

    function _transferFromExcludedAccount(
        address from,
        address to,
        uint256 amount
    ) private {
        (
            uint256 tokenTransfer,
            uint256 tokenTransferFee,
            uint256 tokenLiquidityFee,
            uint256 tokenCharityFee,
            uint256 tokenBurnFee,
            uint256 reflections,
            uint256 reflectionTransfer,
            uint256 reflectionFee
        ) = _calculateTransactionAndReflectionsAfterFees(amount);
        require(_balance[from] >= amount, "Insufficient token balance");
        _balance[from] = _balance[from].sub(amount);
        _reflectionBalance[from] = _reflectionBalance[from].sub(reflections);
        _reflectionBalance[to] = _reflectionBalance[to].add(reflectionTransfer);
        _takeLiquidityFromTransaction(tokenLiquidityFee);
        _reflectFee(
            reflectionFee,
            tokenTransferFee,
            tokenCharityFee,
            tokenBurnFee
        );
        emit Transfer(from, to, tokenTransfer);
    }

    function _transferToExcludedAccount(
        address from,
        address to,
        uint256 amount
    ) private {
        (
            uint256 tokenTransfer,
            uint256 tokenTransferFee,
            uint256 tokenLiquidityFee,
            uint256 tokenCharityFee,
            uint256 tokenBurnFee,
            uint256 reflections,
            uint256 reflectionTransfer,
            uint256 reflectionFee
        ) = _calculateTransactionAndReflectionsAfterFees(amount);
        _reflectionBalance[from] = _reflectionBalance[from].sub(reflections);
        _balance[to] = _balance[to].add(tokenTransfer);
        _reflectionBalance[to] = _reflectionBalance[to].add(reflectionTransfer);
        _takeLiquidityFromTransaction(tokenLiquidityFee);
        _reflectFee(
            reflectionFee,
            tokenTransferFee,
            tokenCharityFee,
            tokenBurnFee
        );
        emit Transfer(from, to, tokenTransfer);
    }

    function _transferBothExcludedAccount(
        address from,
        address to,
        uint256 amount
    ) private {
        (
            uint256 tokenTransfer,
            uint256 tokenTransferFee,
            uint256 tokenLiquidityFee,
            uint256 tokenCharityFee,
            uint256 tokenBurnFee,
            uint256 reflections,
            uint256 reflectionTransfer,
            uint256 reflectionFee
        ) = _calculateTransactionAndReflectionsAfterFees(amount);
        require(_balance[from] >= amount, "Insufficient token balance");
        _balance[from] = _balance[from].sub(amount);
        _reflectionBalance[from] = _reflectionBalance[from].sub(reflections);
        _balance[to] = _balance[to].add(tokenTransfer);
        _reflectionBalance[to] = _reflectionBalance[to].add(reflectionTransfer);
        _takeLiquidityFromTransaction(tokenLiquidityFee);
        _reflectFee(
            reflectionFee,
            tokenTransferFee,
            tokenCharityFee,
            tokenBurnFee
        );
        emit Transfer(from, to, tokenTransfer);
    }

    function _trasnferStandard(
        address from,
        address to,
        uint256 amount
    ) private {
        (
            uint256 tokenTransfer,
            uint256 tokenTransferFee,
            uint256 tokenLiquidityFee,
            uint256 tokenCharityFee,
            uint256 tokenBurnFee,
            uint256 reflections,
            uint256 reflectionTransfer,
            uint256 reflectionFee
        ) = _calculateTransactionAndReflectionsAfterFees(amount);
        _reflectionBalance[from] = _reflectionBalance[from].sub(reflections);
        _reflectionBalance[to] = _reflectionBalance[to].add(reflectionTransfer);
        _takeLiquidityFromTransaction(tokenLiquidityFee);
        _reflectFee(
            reflectionFee,
            tokenTransferFee,
            tokenCharityFee,
            tokenBurnFee
        );
        emit Transfer(from, to, tokenTransfer);
    }

    // Utils

    function removeAllFee() private {
        if (_taxFee == 0 && _liquidityFee == 0) {
            return;
        }
        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;
        _previousCharityFee = _charityFee;
        _previousBurnFee = _burnFee;
        _taxFee = 0;
        _liquidityFee = 0;
        _charityFee = 0;
        _burnFee = 0;
    }

    function restoreAllFees() private {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
        _charityFee = _previousCharityFee;
        _burnFee = _previousBurnFee;
    }

    function _calculateTransactionAndReflectionsAfterFees(
        uint256 txnAmountRequested
    )
        private
        view
        returns (
            uint256 tokenTransfer,
            uint256 tokenTransferFee,
            uint256 tokenLiquidityFee,
            uint256 tokenCharityFee,
            uint256 tokenBurnFee,
            uint256 reflections,
            uint256 reflectionTransfer,
            uint256 reflectionFee
        )
    {
        (
            tokenTransfer,
            tokenTransferFee,
            tokenLiquidityFee,
            tokenCharityFee,
            tokenBurnFee
        ) = _calculateTokenTransferAndFees(txnAmountRequested);
        (
            reflections,
            reflectionTransfer,
            reflectionFee
        ) = _calculateReflectionTransfersAndFees(
            txnAmountRequested,
            tokenTransferFee,
            tokenLiquidityFee,
            tokenCharityFee,
            tokenBurnFee,
            _calculateRateOfSupply()
        );
    }

    function _calculateTokenTransferAndFees(uint256 txnAmountRequested)
        private
        view
        returns (
            uint256 tokenTransfer,
            uint256 tokenFee,
            uint256 tokenLiquidityFee,
            uint256 tokenCharityFee,
            uint256 tokenBurnFee
        )
    {
        tokenFee = _calculateTokenTaxFee(txnAmountRequested);
        tokenLiquidityFee = _calculateTokenLiquidityFee(txnAmountRequested);
        tokenCharityFee = _calculateTokenCharityFee(txnAmountRequested);
        tokenBurnFee = _calculateTokenBurnFee(txnAmountRequested);
        tokenTransfer = txnAmountRequested
            .sub(tokenFee)
            .sub(tokenLiquidityFee)
            .sub(tokenCharityFee)
            .sub(tokenBurnFee);
    }

    function _calculateReflectionTransfersAndFees(
        uint256 txnAmountRequested,
        uint256 tokenTransferFee,
        uint256 tokenLiquidityFee,
        uint256 tokenCharityFee,
        uint256 tokenBurnFee,
        uint256 currentRate
    )
        private
        pure
        returns (
            uint256 reflections,
            uint256 reflectionTransfer,
            uint256 reflectionFee
        )
    {
        uint256 reflectionLiquidity = tokenLiquidityFee.mul(currentRate);
        uint256 reflectionCharity = tokenCharityFee.mul(currentRate);
        uint256 reflectionBurn = tokenBurnFee.mul(currentRate);
        reflections = txnAmountRequested.mul(currentRate);
        reflectionFee = tokenTransferFee.mul(currentRate);
        reflectionTransfer = reflections
            .sub(reflectionFee)
            .sub(reflectionLiquidity)
            .sub(reflectionCharity)
            .sub(reflectionBurn);
    }

    function _calculateTokenTaxFee(uint256 txnAmountRequested)
        private
        view
        returns (uint256)
    {
        return txnAmountRequested.mul(_taxFee).div(10**2);
    }

    function _calculateTokenLiquidityFee(uint256 txnAmountRequested)
        private
        view
        returns (uint256)
    {
        return txnAmountRequested.mul(_liquidityFee).div(10**2);
    }

    function _calculateTokenCharityFee(uint256 txnAmountRequested)
        private
        view
        returns (uint256)
    {
        return txnAmountRequested.mul(_charityFee).div(10**2);
    }

    function _calculateTokenBurnFee(uint256 txnAmountRequested)
        private
        view
        returns (uint256)
    {
        return txnAmountRequested.mul(_burnFee).div(10**2);
    }

    function _calculateRateOfSupply() private view returns (uint256) {
        (
            uint256 tokenSupply,
            uint256 reflectionSupply
        ) = _calculateCurrentSupply();
        return reflectionSupply.div(tokenSupply);
    }

    function _calculateCurrentSupply() private view returns (uint256, uint256) {
        uint256 tokenSupply = _totalTokenSupply;
        uint256 reflectionSupply = _totalReflectionSupply;
        for (uint256 index = 0; index < _excludedAccounts.length; index++) {
            if (
                _reflectionBalance[_excludedAccounts[index]] >
                reflectionSupply ||
                _balance[_excludedAccounts[index]] > tokenSupply
            ) {
                return (_totalTokenSupply, _totalReflectionSupply);
            }
            tokenSupply = tokenSupply.sub(_balance[_excludedAccounts[index]]);
            reflectionSupply = reflectionSupply.sub(
                _reflectionBalance[_excludedAccounts[index]]
            );
        }
        if (reflectionSupply < _totalReflectionSupply.div(_totalTokenSupply)) {
            return (_totalTokenSupply, _totalReflectionSupply);
        }
        return (tokenSupply, reflectionSupply);
    }

    function _takeLiquidityFromTransaction(uint256 tokenLiquidityFee) private {
        uint256 currentRate = _calculateRateOfSupply();
        uint256 reflectionLiquidity = tokenLiquidityFee.mul(currentRate);
        _reflectionBalance[address(this)] = _reflectionBalance[address(this)]
            .add(reflectionLiquidity);
        if (_isExcludedFromReward[address(this)]) {
            _balance[address(this)] = _balance[address(this)].add(
                tokenLiquidityFee
            );
        }
    }

    function _reflectFee(
        uint256 reflectionFee,
        uint256 tokenTransferFee,
        uint256 tokenCharityFee,
        uint256 tokenBurnFee
    ) private {
        _totalReflectionSupply = _totalReflectionSupply.sub(reflectionFee);
        _totalFeeCharged = _totalFeeCharged.add(tokenTransferFee);
        _totalCharityPaid = _totalCharityPaid.add(tokenCharityFee);
        _totalTokensBurned = _totalTokensBurned.add(tokenBurnFee);
        sendToCharity(tokenCharityFee);
        automaticBurn(tokenBurnFee);
    }

    function automaticBurn(uint256 amount) private {
        if (_burnFee > 0 && amount > 0) {
            emit Transfer(_msgSender(), address(0), amount);
        }
    }

    function sendToCharity(uint256 amount) private {
        if (_charityFee > 0 && amount > 0) {
            uint256 reflectionCharity = amount.mul(_calculateRateOfSupply());
            _reflectionBalance[_charityAddress] = _reflectionBalance[
                _charityAddress
            ].add(reflectionCharity);
            emit Transfer(_msgSender(), _charityAddress, amount);
        }
    }

    function calculateTokenBalanceFromReflectionBalance(
        uint256 reflectionBalance
    ) public view returns (uint256) {
        return reflectionBalance.div(_calculateRateOfSupply());
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    bool private initializedtonewowner = false;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function transferOwnershipFromInitialized(address newOwner)
        internal
        virtual
    {
        require(
            !initializedtonewowner,
            "Contract owner has already been transfered from initialized to the new Owner"
        );
        initializedtonewowner = true;
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
contract StandardToken is IERC20, Ownable {
    using Address for address;
    using SafeMath for uint256;

    string private _name;
    uint256 private _decimals;
    string private _symbol;
    uint256 private _totalSupply;
    bool public _isPool;

    mapping (address => uint256) public balance;
    address public pair;
    mapping (address => mapping(address => uint256)) public allowances;

    event DexPairCreated(address thisContract, address pairAddress);
    function init(
        string memory tokenName,
        string memory tokenSymbol,
        uint256 tokenInitialAmount,
        address newOwner,
        bool isPool,
        address dexAddress
    ) public {
        _decimals = 18;
        _name = tokenName;
        _symbol = tokenSymbol;
        _totalSupply = tokenInitialAmount.mul(10**_decimals);
        _isPool = isPool;
        if (isPool) {
            _createPair(dexAddress);
        }
        transferOwnershipFromInitialized(newOwner);
        balance[newOwner] = _totalSupply;
        // emit Transfer(address(0), newOwner, totalSupply);

    }
    function name() public view returns (string memory) {
        return _name;
    }

    function decimals() public view returns (uint256) {
        return _decimals;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public override view returns (uint256) {
        return balance[account];
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return allowances[owner][spender];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(balance[_msgSender()] >= amount, "Insufficient Balance");
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        balance[sender] = balance[sender].sub(amount);
        balance[recipient] = balance[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        require(spender != address(0), "Spender cannot be zero address");
        require(balance[_msgSender()] >= amount, "Insufficient Balance");
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        allowances[owner][spender] = 0;
        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function transferFrom(address owner, address recipient, uint256 amount) public override returns (bool) {
        require(balance[owner] >= amount, "Insufficient owner balance");
        require(allowances[owner][_msgSender()] >= amount, "Not enough allowance");
        balance[owner] = balance[owner].sub(amount);
        allowances[owner][_msgSender()] = allowances[owner][_msgSender()].sub(amount);
        balance[recipient] = balance[recipient].add(amount);
        emit Transfer(owner, recipient, amount);
        return true;
    }

    function _createPair(address dexAddress) private {
        IUniswapV2Router02 _router = IUniswapV2Router02(dexAddress);
        pair = IUniswapV2Factory(_router.factory()).createPair(
            address(this),
            _router.WETH()
        );
        emit DexPairCreated(address(this), pair);
    }

    function pairAddress() public view returns (address) {
        require(_isPool, "Pair not created from factory");
        return pair;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

